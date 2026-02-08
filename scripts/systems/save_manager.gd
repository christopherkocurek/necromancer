extends Node
## SaveManager autoload - handles game save/load operations.
## Handles game save/load operations with optional permadeath mode.
## Implements save-on-action pattern to prevent save scumming.

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_deleted(slot: int)

const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".sav"
const HEADER_VERSION := 1

# Game modes
enum GameMode { PERMADEATH, CASUAL }

# Save metadata (stored separately for quick listing)
var save_metadata: Dictionary = {}  # slot_idx -> metadata dict

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_ensure_save_directory()
	_load_all_metadata()

func _ensure_save_directory() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _load_all_metadata() -> void:
	save_metadata.clear()
	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if filename.ends_with(SAVE_EXTENSION):
			var slot := _get_slot_from_filename(filename)
			if slot >= 0:
				var meta := _load_metadata_for_slot(slot)
				if not meta.is_empty():
					save_metadata[slot] = meta
		filename = dir.get_next()
	dir.list_dir_end()

# ============================================================================
# PUBLIC API
# ============================================================================

## Save the current game to a slot (0-9)
func save_game(slot: int, player: Player, level: Level, game_mode: GameMode = GameMode.PERMADEATH) -> bool:
	if slot < 0 or slot > 9:
		push_error("SaveManager: Invalid save slot %d" % slot)
		save_completed.emit(slot, false)
		return false

	var save_data := _serialize_game(player, level, game_mode)
	var json_string := JSON.stringify(save_data, "\t")

	var path := _get_save_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Could not open %s for writing: %s" % [path, FileAccess.get_open_error()])
		save_completed.emit(slot, false)
		return false

	file.store_string(json_string)
	file.close()

	# Update metadata cache
	save_metadata[slot] = _extract_metadata(save_data)

	GameManager.log_message("Game saved to slot %d." % slot, ThemeColors.ABILITY_LEARNED)
	save_completed.emit(slot, true)
	return true

## Load a game from a slot - returns the save data dictionary or empty dict on failure
func load_game(slot: int) -> Dictionary:
	if slot < 0 or slot > 9:
		push_error("SaveManager: Invalid load slot %d" % slot)
		load_completed.emit(slot, false)
		return {}

	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: No save file at slot %d" % slot)
		load_completed.emit(slot, false)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Could not open %s for reading" % path)
		load_completed.emit(slot, false)
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("SaveManager: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		load_completed.emit(slot, false)
		return {}

	var save_data: Dictionary = json.data
	if not _validate_save_data(save_data):
		push_error("SaveManager: Invalid save data format")
		load_completed.emit(slot, false)
		return {}

	GameManager.log_message("Game loaded from slot %d." % slot, ThemeColors.ABILITY_LEARNED)
	load_completed.emit(slot, true)
	return save_data

## Delete a save file
func delete_save(slot: int) -> bool:
	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false

	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("SaveManager: Could not delete save at slot %d" % slot)
		return false

	save_metadata.erase(slot)
	save_deleted.emit(slot)
	return true

## Delete save on death (permadeath mode)
func delete_save_on_death(slot: int) -> void:
	if has_save(slot):
		var meta: Dictionary = save_metadata.get(slot, {})
		if meta.get("game_mode", GameMode.PERMADEATH) == GameMode.PERMADEATH:
			delete_save(slot)
			GameManager.log_message("Permadeath: Save file deleted.", ThemeColors.MSG_ERROR)

## Check if a slot has a save
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))

## Get list of all saved slots with metadata
func get_all_saves() -> Dictionary:
	return save_metadata.duplicate()

## Get metadata for a specific slot
func get_save_metadata(slot: int) -> Dictionary:
	return save_metadata.get(slot, {})

# ============================================================================
# SERIALIZATION
# ============================================================================

func _serialize_game(player: Player, level: Level, game_mode: GameMode) -> Dictionary:
	return {
		"header": {
			"version": HEADER_VERSION,
			"timestamp": Time.get_unix_time_from_system(),
			"datetime": Time.get_datetime_string_from_system(),
			"game_mode": game_mode,
		},
		"game_state": _serialize_game_state(),
		"player": _serialize_player(player),
		"level": _serialize_level(level),
	}

func _serialize_game_state() -> Dictionary:
	return {
		"current_depth": GameManager.current_depth,
		"turn_count": GameManager.turn_count,
		"identified_types": GameManager.identified_types.duplicate(),
		"flavor_names": GameManager.flavor_names.duplicate(),
	}

func _serialize_player(player: Player) -> Dictionary:
	var data := {
		# Identity
		"entity_name": player.entity_name,
		"race_name": player.race_name,
		"house_name": player.house_name,
		"trait_name": player.trait_name,
		"trait_effect_id": player.trait_effect_id,
		"gender": player.gender,
		"age": player.age,
		"history": player.history,
		"trait_undying_used": player._trait_undying_used,
		"hobbit_luck_used": player._hobbit_luck_used,
		"oath_target_type": player._oath_target_type,
		"whisper_used": player._whisper_used,
		"stalker_turns": player._stalker_turns,
		# Position
		"grid_position": {"x": player.grid_position.x, "y": player.grid_position.y},
		# Core stats
		"max_health": player.max_health,
		"current_health": player.current_health,
		"strength": player.strength,
		"dexterity": player.dexterity,
		"constitution": player.constitution,
		"grace": player.grace,
		"armor_class": player.armor_class,
		"speed": player.speed,
		# Combat stats
		"melee_bonus": player.melee_bonus,
		"evasion_bonus": player.evasion_bonus,
		"damage_dice": player.damage_dice,
		"protection_dice": player.protection_dice,
		"protection_sides": player.protection_sides,
		# XP
		"total_xp_earned": player.total_xp_earned,
		"xp_available": player.xp_available,
		"kill_xp": player.kill_xp,
		"encounter_xp": player.encounter_xp,
		"descent_xp": player.descent_xp,
		"identify_xp": player.identify_xp,
		"kills_by_name": player.kills_by_name.duplicate() if player.kills_by_name else {},
		# Skills
		"skills": player.skills.duplicate(),
		# Abilities
		"innate_ability": player.innate_ability.duplicate(true),
		"active_ability": player.active_ability.duplicate(true),
		"have_ability": player.have_ability.duplicate(true),
		"learned_abilities": player.get_meta("learned_abilities") if player.has_meta("learned_abilities") else [],
		# Voice
		"voice_charges": player.voice_charges,
		"max_voice": player.max_voice,
		# Hunger
		"hunger": player.hunger,
		"starving_turns": player._starving_turns,
		# Inventory & equipment
		"inventory": _serialize_inventory(player.inventory),
		"equipment": _serialize_equipment(player.equipment),
		# Status effects
		"status_effects": player.status_effects.duplicate(),
		# Run stats
		"run_stats": player.run_stats.to_dict(),
		# Ability hotkeys
		"ability_hotkeys": player.ability_hotkeys.duplicate(),
	}
	return data

func _serialize_inventory(inventory: Array) -> Array:
	var serialized := []
	for item in inventory:
		if item is Dictionary:
			serialized.append(item.duplicate())
		else:
			# Item is probably an object, serialize its properties
			serialized.append(_serialize_item_object(item))
	return serialized

func _serialize_equipment(equipment: Dictionary) -> Dictionary:
	var serialized := {}
	for slot_name in equipment:
		var item = equipment[slot_name]
		if item == null:
			serialized[slot_name] = null
		elif item is Dictionary:
			serialized[slot_name] = item.duplicate()
		else:
			serialized[slot_name] = _serialize_item_object(item)
	return serialized

func _serialize_item_object(item) -> Dictionary:
	# For item objects, extract relevant properties
	if item == null:
		return {}
	var data := {}
	if "id" in item:
		data["id"] = item.id
	if "name" in item:
		data["name"] = item.name
	if "type" in item:
		data["type"] = item.type
	if "quantity" in item:
		data["quantity"] = item.quantity
	if "stack_count" in item:
		data["stack_count"] = item.stack_count
	# Serialize ItemData fields for full roundtrip
	if "index" in item:
		data["index"] = item.index
	if "tval" in item:
		data["tval"] = item.tval
	if "sval" in item:
		data["sval"] = item.sval
	if "pval" in item:
		data["pval"] = item.pval
	if "weight" in item:
		data["weight"] = item.weight
	if "attack_bonus" in item:
		data["attack_bonus"] = item.attack_bonus
	if "damage_dice" in item:
		data["damage_dice"] = item.damage_dice
	if "evasion_bonus" in item:
		data["evasion_bonus"] = item.evasion_bonus
	if "protection_dice" in item:
		data["protection_dice"] = item.protection_dice
	if "display_char" in item:
		data["display_char"] = item.display_char
	if "color" in item:
		data["color"] = item.color
	if "description" in item:
		data["description"] = item.description
	if "flags" in item:
		data["flags"] = item.flags.duplicate() if item.flags is Array else item.flags
	if "fuel" in item:
		data["fuel"] = item.fuel
	if "identified" in item:
		data["identified"] = item.identified
	return data

func _serialize_level(level: Level) -> Dictionary:
	# Serialize level state (explored tiles, items on ground, etc.)
	var data := {
		"depth": level.depth,
		"width": level.width,
		"height": level.height,
		"seed": level.get("generation_seed") if "generation_seed" in level else 0,
	}

	# Serialize tile data (only explored/visible states, not full map)
	# The map itself will be regenerated from seed
	if level.has_method("get_explored_tiles"):
		data["explored_tiles"] = level.get_explored_tiles()
	elif "explored" in level:
		data["explored_tiles"] = _serialize_2d_array(level.explored)

	# Serialize items on the floor
	if level.has_method("get_floor_items"):
		data["floor_items"] = level.get_floor_items()

	# Serialize monsters (for later restoration)
	data["monsters"] = _serialize_monsters(level)

	return data

func _serialize_monsters(level: Level) -> Array:
	var monsters := []
	for child in level.get_children():
		if not is_instance_valid(child):
			continue
		if child is Entity and not child is Player:
			monsters.append({
				"type": child.entity_name,
				"position": {"x": child.grid_position.x, "y": child.grid_position.y},
				"health": child.current_health,
				"max_health": child.max_health,
				# Add monster-specific data as needed
			})
	return monsters

func _serialize_2d_array(arr: Array) -> Array:
	var result := []
	for row in arr:
		if row is Array:
			result.append(row.duplicate())
		else:
			result.append(row)
	return result

# ============================================================================
# DESERIALIZATION
# ============================================================================

## Apply loaded save data to the game
func apply_save_data(save_data: Dictionary, player: Player, level: Level) -> bool:
	if not _validate_save_data(save_data):
		return false

	# Apply game state
	var game_state: Dictionary = save_data.get("game_state", {})
	GameManager.current_depth = game_state.get("current_depth", 1)
	GameManager.turn_count = game_state.get("turn_count", 0)

	# Restore identification state
	if "identified_types" in game_state:
		GameManager.identified_types = game_state.identified_types.duplicate()
	else:
		GameManager.identified_types.clear()
	if "flavor_names" in game_state:
		GameManager.flavor_names = game_state.flavor_names.duplicate()
	else:
		# Old save without flavor data: randomize fresh
		GameManager._randomize_flavor_names()

	# Apply player data
	var player_data: Dictionary = save_data.get("player", {})
	_deserialize_player(player, player_data)

	# Level will be regenerated, then we apply saved state
	# (This should be called after level generation)
	var level_data: Dictionary = save_data.get("level", {})
	_apply_level_state(level, level_data)

	return true

func _deserialize_player(player: Player, data: Dictionary) -> void:
	# Identity
	player.entity_name = data.get("entity_name", "Adventurer")
	player.race_name = data.get("race_name", "Man")
	player.house_name = data.get("house_name", "")
	player.trait_name = data.get("trait_name", "")
	player.trait_effect_id = data.get("trait_effect_id", "")
	player.gender = data.get("gender", "male")
	player.age = data.get("age", 0)
	player.history = data.get("history", "")
	player._trait_undying_used = data.get("trait_undying_used", false)
	player._hobbit_luck_used = data.get("hobbit_luck_used", false)
	player._oath_target_type = data.get("oath_target_type", "")
	player._whisper_used = data.get("whisper_used", false)
	player._stalker_turns = data.get("stalker_turns", 0)

	# Position
	var pos: Dictionary = data.get("grid_position", {"x": 0, "y": 0})
	player.grid_position = Vector2i(int(pos.x), int(pos.y))

	# Core stats
	player.max_health = data.get("max_health", 10)
	player.current_health = data.get("current_health", 10)
	player.strength = data.get("strength", 0)
	player.dexterity = data.get("dexterity", 0)
	player.constitution = data.get("constitution", 0)
	player.grace = data.get("grace", 0)
	player.armor_class = data.get("armor_class", 0)
	player.speed = data.get("speed", 2)

	# Combat stats
	player.melee_bonus = data.get("melee_bonus", 0)
	player.evasion_bonus = data.get("evasion_bonus", 0)
	player.damage_dice = data.get("damage_dice", "1d4")
	player.protection_dice = data.get("protection_dice", 0)
	player.protection_sides = data.get("protection_sides", 0)

	# XP
	player.total_xp_earned = data.get("total_xp_earned", 0)
	player.xp_available = data.get("xp_available", 5000)
	player.kill_xp = data.get("kill_xp", 0)
	player.encounter_xp = data.get("encounter_xp", 0)
	player.descent_xp = data.get("descent_xp", 0)
	player.identify_xp = data.get("identify_xp", 0)
	player.kills_by_name = data.get("kills_by_name", {})

	# Skills
	if "skills" in data:
		for skill_name in data.skills:
			if skill_name in player.skills:
				player.skills[skill_name] = data.skills[skill_name]

	# Abilities
	player.innate_ability = data.get("innate_ability", []).duplicate(true)
	player.active_ability = data.get("active_ability", []).duplicate(true)
	player.have_ability = data.get("have_ability", []).duplicate(true)
	var loaded_abilities: Array = data.get("learned_abilities", [])
	if not loaded_abilities.is_empty():
		player.set_meta("learned_abilities", loaded_abilities)

	# Voice
	player.voice_charges = data.get("voice_charges", 0)
	player.max_voice = data.get("max_voice", 10)

	# Hunger
	player.hunger = data.get("hunger", Player.HUNGER_MAX)
	player._starving_turns = data.get("starving_turns", 0)
	player._last_hunger_state = player.get_hunger_state()

	# Inventory & equipment
	player.inventory = data.get("inventory", []).duplicate()
	if "equipment" in data:
		for slot_name in data.equipment:
			if slot_name in player.equipment:
				player.equipment[slot_name] = data.equipment[slot_name]

	# Status effects
	player.status_effects = data.get("status_effects", {}).duplicate()

	# Run stats
	if "run_stats" in data:
		player.run_stats = RunStats.from_dict(data.run_stats)

	# Ability hotkeys
	if "ability_hotkeys" in data:
		var loaded_hotkeys: Array = data.ability_hotkeys
		for i in range(mini(loaded_hotkeys.size(), 4)):
			player.ability_hotkeys[i] = int(loaded_hotkeys[i])

func _apply_level_state(level: Level, data: Dictionary) -> void:
	# Apply explored tiles (Level uses flat array: index = y * width + x)
	if "explored_tiles" in data and level.has_method("set_explored_tiles"):
		level.set_explored_tiles(data.explored_tiles)
	elif "explored_tiles" in data and "explored" in level:
		var explored_data: Array = data.explored_tiles
		# Handle flat array format
		var size := mini(explored_data.size(), level.explored.size())
		for i in range(size):
			level.explored[i] = explored_data[i]

	# Floor items would need to be restored here
	# Monsters would need to be respawned here based on saved data

# ============================================================================
# VALIDATION & HELPERS
# ============================================================================

func _validate_save_data(data: Dictionary) -> bool:
	if not "header" in data:
		return false
	if not "version" in data.header:
		return false
	if data.header.version > HEADER_VERSION:
		push_warning("SaveManager: Save file from newer version (%d > %d)" % [data.header.version, HEADER_VERSION])
		# Allow loading newer saves for now, but warn
	return "player" in data and "game_state" in data

func _extract_metadata(save_data: Dictionary) -> Dictionary:
	var header: Dictionary = save_data.get("header", {})
	var player: Dictionary = save_data.get("player", {})
	var game_state: Dictionary = save_data.get("game_state", {})

	return {
		"character_name": player.get("entity_name", "Unknown"),
		"race": player.get("race_name", "Unknown"),
		"house": player.get("house_name", ""),
		"depth": game_state.get("current_depth", 1),
		"turn_count": game_state.get("turn_count", 0),
		"health": player.get("current_health", 0),
		"max_health": player.get("max_health", 0),
		"timestamp": header.get("timestamp", 0),
		"datetime": header.get("datetime", ""),
		"game_mode": header.get("game_mode", GameMode.PERMADEATH),
	}

func _load_metadata_for_slot(slot: int) -> Dictionary:
	var path := _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var save_data: Dictionary = json.data
	return _extract_metadata(save_data)

func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]

func _get_slot_from_filename(filename: String) -> int:
	# Extract slot number from "slot_X.sav"
	var regex := RegEx.new()
	regex.compile("slot_(\\d+)\\.sav")
	var result := regex.search(filename)
	if result:
		return int(result.get_string(1))
	return -1
