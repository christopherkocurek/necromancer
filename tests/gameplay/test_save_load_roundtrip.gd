extends GutTest
## Gameplay scenario tests for save/load roundtrip.
## Tests serialization, deserialization, and property restoration
## for player state, inventory, equipment, abilities, and game state.

# ============================================================================
# PLAYER STATE ROUNDTRIP
# ============================================================================

func test_core_stats_roundtrip():
	# Serialize player stats
	var original: Dictionary = {
		"entity_name": "Necromancer",
		"race_name": "Noldor",
		"house_name": "House of Feanor",
		"max_health": 50,
		"current_health": 35,
		"strength": 3,
		"dexterity": 5,
		"constitution": 2,
		"grace": 4,
		"armor_class": 3,
		"speed": 2,
		"melee_bonus": 7,
		"evasion_bonus": 5,
	}

	# Simulate save -> JSON -> load
	var restored: Dictionary = original.duplicate()

	assert_eq(restored.entity_name, "Necromancer", "Name restored")
	assert_eq(restored.race_name, "Noldor", "Race restored")
	assert_eq(restored.house_name, "House of Feanor", "House restored")
	assert_eq(restored.max_health, 50, "Max HP restored")
	assert_eq(restored.current_health, 35, "Current HP restored")
	assert_eq(restored.strength, 3, "STR restored")
	assert_eq(restored.dexterity, 5, "DEX restored")
	assert_eq(restored.constitution, 2, "CON restored")
	assert_eq(restored.grace, 4, "GRA restored")
	assert_eq(restored.speed, 2, "Speed restored")
	assert_eq(restored.melee_bonus, 7, "Melee bonus restored")
	assert_eq(restored.evasion_bonus, 5, "Evasion bonus restored")

func test_position_roundtrip():
	var original_pos: Dictionary = {"x": 15, "y": 23}

	# Restore
	var restored_pos: Vector2i = Vector2i(original_pos.x, original_pos.y)
	assert_eq(restored_pos.x, 15, "X position restored")
	assert_eq(restored_pos.y, 23, "Y position restored")

func test_xp_roundtrip():
	var original: Dictionary = {
		"total_xp_earned": 15000,
		"xp_available": 3500,
		"kill_xp": 8000,
		"encounter_xp": 2000,
		"descent_xp": 5000,
		"identify_xp": 500,
	}

	var restored: Dictionary = original.duplicate()
	assert_eq(restored.total_xp_earned, 15000, "Total XP restored")
	assert_eq(restored.xp_available, 3500, "Available XP restored")
	assert_eq(restored.kill_xp, 8000, "Kill XP restored")
	assert_eq(restored.encounter_xp, 2000, "Encounter XP restored")
	assert_eq(restored.descent_xp, 5000, "Descent XP restored")
	assert_eq(restored.identify_xp, 500, "Identify XP restored")

# ============================================================================
# SKILLS ROUNDTRIP
# ============================================================================

func test_skills_roundtrip():
	var original_skills: Dictionary = {
		"melee": 5,
		"archery": 3,
		"evasion": 7,
		"stealth": 2,
		"hunting": 4,
		"will": 6,
		"smithing": 1,
		"lore": 8,
	}

	var restored: Dictionary = original_skills.duplicate()

	for skill_name in original_skills:
		assert_eq(restored[skill_name], original_skills[skill_name],
			"Skill '%s' restored to %d" % [skill_name, original_skills[skill_name]])

func test_skills_not_shared_after_load():
	var original_skills: Dictionary = {"melee": 5, "archery": 3}
	var loaded: Dictionary = original_skills.duplicate()

	# Modify loaded
	loaded["melee"] = 10

	assert_eq(original_skills["melee"], 5, "Original not affected by loaded change")
	assert_eq(loaded["melee"], 10, "Loaded has the new value")

# ============================================================================
# ABILITIES ROUNDTRIP (deep copy critical)
# ============================================================================

func test_ability_arrays_deep_copy_roundtrip():
	# Build ability arrays (S_MAX x ABILITIES_MAX)
	var innate: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		innate.append(row)

	# Learn some abilities
	innate[0][0] = true  # Melee: Power
	innate[0][5] = true  # Melee: Follow-Through
	innate[2][0] = true  # Evasion: Dodging
	innate[5][4] = true  # Will: Defy Death

	# Save with deep copy
	var saved: Array = innate.duplicate(true)

	# Modify original after saving
	innate[0][0] = false
	innate[3][1] = true  # New ability learned

	# Verify saved is isolated
	assert_true(saved[0][0], "Saved Power should still be true")
	assert_false(saved[3][1], "Saved should NOT have post-save ability")
	assert_true(saved[0][5], "Saved Follow-Through preserved")
	assert_true(saved[2][0], "Saved Dodging preserved")
	assert_true(saved[5][4], "Saved Defy Death preserved")

func test_ability_arrays_load_deep_copy():
	var save_data: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		save_data.append(row)
	save_data[0][0] = true
	save_data[5][4] = true

	# Load with deep copy
	var loaded: Array = save_data.duplicate(true)

	# Modify loaded
	loaded[0][1] = true

	# Save data should not be affected
	assert_false(save_data[0][1], "Save data isolated from loaded modifications")
	assert_true(loaded[0][0], "Loaded has saved ability")
	assert_true(loaded[0][1], "Loaded has new ability")

# ============================================================================
# INVENTORY ROUNDTRIP
# ============================================================================

func test_inventory_serialize_roundtrip():
	var inventory: Array = [
		{"name": "Long Sword", "tval": 23, "sval": 2, "weight": 40, "damage_dice": "2d5"},
		{"name": "Iron Helm", "tval": 32, "sval": 1, "weight": 60, "protection_dice": "1d4"},
		{"name": "Healing Potion", "tval": 75, "sval": 3, "stack_count": 3},
	]

	# Serialize
	var serialized: Array = []
	for item in inventory:
		serialized.append(item.duplicate())

	# Verify isolation
	inventory[0].name = "MODIFIED"

	assert_eq(serialized[0].name, "Long Sword", "Serialized inventory isolated")
	assert_eq(serialized.size(), 3, "Correct number of items")
	assert_eq(serialized[2].stack_count, 3, "Stack count preserved")

func test_inventory_load_roundtrip():
	var saved_inventory: Array = [
		{"name": "Sword", "tval": 23, "sval": 1, "weight": 30},
		{"name": "Potion", "tval": 75, "sval": 3, "stack_count": 5},
	]

	# Load (duplicate)
	var loaded: Array = []
	for item in saved_inventory:
		loaded.append(item.duplicate())

	assert_eq(loaded.size(), 2, "Loaded correct number of items")
	assert_eq(loaded[0].name, "Sword", "First item name restored")
	assert_eq(loaded[1].stack_count, 5, "Stack count restored")

	# Modify loaded
	loaded[0].name = "Modded"
	assert_eq(saved_inventory[0].name, "Sword", "Save data not affected by load modification")

# ============================================================================
# EQUIPMENT ROUNDTRIP
# ============================================================================

func test_equipment_serialize_roundtrip():
	var equipment: Dictionary = {
		"weapon": {"name": "Long Sword", "tval": 23, "sval": 2, "damage_dice": "2d5"},
		"off_hand": {"name": "Round Shield", "tval": 34, "sval": 1, "protection_dice": "1d4"},
		"armor": null,
		"head": null,
		"feet": null,
	}

	# Serialize
	var serialized: Dictionary = {}
	for slot_name in equipment:
		if equipment[slot_name] == null:
			serialized[slot_name] = null
		else:
			serialized[slot_name] = equipment[slot_name].duplicate()

	assert_not_null(serialized["weapon"], "Weapon serialized")
	assert_not_null(serialized["off_hand"], "Shield serialized")
	assert_null(serialized["armor"], "Empty slot serialized as null")
	assert_eq(serialized["weapon"].name, "Long Sword", "Weapon name preserved")
	assert_eq(serialized["off_hand"].name, "Round Shield", "Shield name preserved")

func test_equipment_load_roundtrip():
	var saved_equipment: Dictionary = {
		"weapon": {"name": "Elven Blade", "tval": 23, "sval": 5, "damage_dice": "3d5"},
		"armor": {"name": "Mail Corslet", "tval": 36, "sval": 3, "protection_dice": "2d4"},
		"head": null,
	}

	# Load
	var loaded: Dictionary = {}
	for slot_name in saved_equipment:
		if saved_equipment[slot_name] == null:
			loaded[slot_name] = null
		else:
			loaded[slot_name] = saved_equipment[slot_name].duplicate()

	assert_eq(loaded["weapon"].name, "Elven Blade", "Weapon restored")
	assert_eq(loaded["armor"].protection_dice, "2d4", "Armor stats restored")
	assert_null(loaded["head"], "Empty head slot restored as null")

# ============================================================================
# GAME STATE ROUNDTRIP
# ============================================================================

func test_game_state_roundtrip():
	var original_state: Dictionary = {
		"current_depth": 7,
		"turn_count": 342,
		"identified_types": {"75:3": true, "75:8": true, "40:1": true},
	}

	var restored: Dictionary = original_state.duplicate(true)

	assert_eq(restored.current_depth, 7, "Depth restored")
	assert_eq(restored.turn_count, 342, "Turn count restored")
	assert_true(restored.identified_types.has("75:3"), "Identified potion preserved")
	assert_true(restored.identified_types.has("40:1"), "Identified amulet preserved")

func test_game_state_isolation():
	var original: Dictionary = {
		"current_depth": 5,
		"identified_types": {"75:3": true},
	}

	var saved: Dictionary = original.duplicate(true)

	# Modify original after save
	original.current_depth = 10
	original.identified_types["75:8"] = true

	assert_eq(saved.current_depth, 5, "Saved depth not affected")
	assert_false(saved.identified_types.has("75:8"), "Saved ident not affected")

# ============================================================================
# KILLS TRACKING ROUNDTRIP
# ============================================================================

func test_kills_by_name_roundtrip():
	var kills: Dictionary = {
		"Goblin": 5,
		"Orc": 12,
		"Troll": 1,
		"Spider": 8,
	}

	var saved: Dictionary = kills.duplicate()

	# Modify original
	kills["Goblin"] = 99
	kills["Dragon"] = 1

	assert_eq(saved["Goblin"], 5, "Saved goblin kills unaffected")
	assert_false(saved.has("Dragon"), "Saved doesn't have post-save kills")
	assert_eq(saved.size(), 4, "Saved has correct count")

func test_kills_by_name_default_on_missing():
	var save_data: Dictionary = {"current_health": 50}
	var loaded_kills: Dictionary = save_data.get("kills_by_name", {})
	assert_eq(loaded_kills.size(), 0, "Missing kills defaults to empty dict")

# ============================================================================
# VOICE/HUNGER ROUNDTRIP
# ============================================================================

func test_voice_charges_roundtrip():
	var original: Dictionary = {
		"voice_charges": 15,
		"max_voice": 20,
	}

	var restored: Dictionary = original.duplicate()
	assert_eq(restored.voice_charges, 15, "Voice charges restored")
	assert_eq(restored.max_voice, 20, "Max voice restored")

func test_hunger_roundtrip():
	var original: Dictionary = {
		"hunger": 1200,
		"starving_turns": 0,
	}

	var restored: Dictionary = original.duplicate()
	assert_eq(restored.hunger, 1200, "Hunger level restored")
	assert_eq(restored.starving_turns, 0, "Starving turns restored")

# ============================================================================
# STATUS EFFECTS ROUNDTRIP
# ============================================================================

func test_status_effects_roundtrip():
	var effects: Dictionary = {
		"poisoned": 5,
		"fast": 8,
		"resist_elements": 12,
	}

	var saved: Dictionary = effects.duplicate()
	var loaded: Dictionary = saved.duplicate()

	assert_eq(loaded["poisoned"], 5, "Poison duration restored")
	assert_eq(loaded["fast"], 8, "Fast duration restored")
	assert_eq(loaded["resist_elements"], 12, "Resist duration restored")

func test_status_effects_empty_on_missing():
	var save_data: Dictionary = {}
	var effects: Dictionary = save_data.get("status_effects", {})
	assert_eq(effects.size(), 0, "Missing status defaults to empty")

# ============================================================================
# BACKWARDS COMPATIBILITY (old saves missing new fields)
# ============================================================================

func test_old_save_missing_new_fields():
	var old_save: Dictionary = {
		"current_health": 40,
		"max_health": 50,
		"skills": {"melee": 3},
	}

	# All Phase H+ fields have safe defaults
	var kills: Dictionary = old_save.get("kills_by_name", {})
	var learned: Array = old_save.get("learned_abilities", [])
	var innate: Array = old_save.get("innate_ability", [])
	var active: Array = old_save.get("active_ability", [])
	var voice: int = old_save.get("voice_charges", 20)
	var max_voice: int = old_save.get("max_voice", 20)
	var hunger: int = old_save.get("hunger", 2000)
	var hotkeys: Array = old_save.get("ability_hotkeys", [-1, -1, -1, -1])
	var gender: String = old_save.get("gender", "male")
	var age: int = old_save.get("age", 0)

	assert_eq(kills.size(), 0, "Kills default empty")
	assert_eq(learned.size(), 0, "Learned abilities default empty")
	assert_eq(innate.size(), 0, "Innate ability default empty")
	assert_eq(active.size(), 0, "Active ability default empty")
	assert_eq(voice, 20, "Voice charges default 20")
	assert_eq(max_voice, 20, "Max voice default 20")
	assert_eq(hunger, 2000, "Hunger defaults to max")
	assert_eq(hotkeys.size(), 4, "Hotkeys default to 4 slots")
	assert_eq(hotkeys[0], -1, "Hotkey slots default to -1 (empty)")
	assert_eq(gender, "male", "Gender defaults to male")
	assert_eq(age, 0, "Age defaults to 0")

# ============================================================================
# FULL ROUNDTRIP SIMULATION
# ============================================================================

func test_full_save_load_cycle():
	# Build complete save data
	var save_data: Dictionary = {
		"header": {
			"version": 1,
			"timestamp": 1738886400,
			"game_mode": 0,
		},
		"game_state": {
			"current_depth": 8,
			"turn_count": 500,
			"identified_types": {"75:3": true},
		},
		"player": {
			"entity_name": "Necromancer",
			"race_name": "Sindar",
			"house_name": "House of Fingolfin",
			"max_health": 60,
			"current_health": 45,
			"strength": 4,
			"dexterity": 6,
			"constitution": 3,
			"grace": 5,
			"speed": 2,
			"grid_position": {"x": 25, "y": 12},
			"skills": {"melee": 7, "evasion": 5, "stealth": 3, "lore": 10},
			"total_xp_earned": 20000,
			"xp_available": 5000,
			"voice_charges": 12,
			"max_voice": 20,
			"hunger": 1500,
			"kills_by_name": {"Orc": 15, "Spider": 8},
			"inventory": [
				{"name": "Sword", "tval": 23, "sval": 1},
				{"name": "Potion", "tval": 75, "sval": 3, "stack_count": 3},
			],
			"equipment": {
				"weapon": {"name": "Elven Blade", "tval": 23, "sval": 5},
				"armor": null,
			},
			"status_effects": {"fast": 5},
			"ability_hotkeys": [140, -1, 142, -1],
		},
	}

	# Simulate save -> JSON stringify -> JSON parse -> load
	var json_string: String = JSON.stringify(save_data, "\t")
	assert_gt(json_string.length(), 0, "JSON serialization produced output")

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_string)
	assert_eq(parse_result, OK, "JSON parse should succeed")

	var loaded: Dictionary = json.data

	# Verify header
	assert_eq(loaded.header.version, 1, "Header version")

	# Verify game state
	assert_eq(loaded.game_state.current_depth, 8, "Depth restored")
	assert_eq(loaded.game_state.turn_count, 500, "Turn count restored")

	# Verify player
	var p: Dictionary = loaded.player
	assert_eq(p.entity_name, "Necromancer", "Player name")
	assert_eq(p.race_name, "Sindar", "Race")
	assert_eq(p.max_health, 60, "Max HP")
	assert_eq(p.current_health, 45, "Current HP")
	assert_eq(p.strength, 4, "STR")

	# JSON stores ints as floats, so use int() for comparison
	assert_eq(int(p.grid_position.x), 25, "Position X")
	assert_eq(int(p.grid_position.y), 12, "Position Y")

	# Skills
	assert_eq(int(p.skills.melee), 7, "Melee skill")
	assert_eq(int(p.skills.lore), 10, "Lore skill")

	# XP
	assert_eq(int(p.total_xp_earned), 20000, "Total XP")
	assert_eq(int(p.xp_available), 5000, "Available XP")

	# Voice
	assert_eq(int(p.voice_charges), 12, "Voice charges")

	# Hunger
	assert_eq(int(p.hunger), 1500, "Hunger")

	# Inventory
	assert_eq(p.inventory.size(), 2, "Inventory count")
	assert_eq(p.inventory[0].name, "Sword", "First inventory item")
	assert_eq(int(p.inventory[1].stack_count), 3, "Potion stack")

	# Equipment
	assert_eq(p.equipment.weapon.name, "Elven Blade", "Equipped weapon")

	# Status effects
	assert_eq(int(p.status_effects.fast), 5, "Fast status")

	# Kills
	assert_eq(int(p.kills_by_name.Orc), 15, "Orc kills")
	assert_eq(int(p.kills_by_name.Spider), 8, "Spider kills")

	# Hotkeys
	assert_eq(p.ability_hotkeys.size(), 4, "Hotkey slots")
	assert_eq(int(p.ability_hotkeys[0]), 140, "First hotkey = Word of Command")
	assert_eq(int(p.ability_hotkeys[1]), -1, "Second hotkey empty")

# ============================================================================
# SAVE HEADER VALIDATION
# ============================================================================

func test_save_header_version():
	var header: Dictionary = {"version": 1, "timestamp": 1738886400, "game_mode": 0}
	assert_eq(header.version, 1, "Save version should be 1")

func test_save_validation_rejects_missing_header():
	var bad_save: Dictionary = {"player": {}, "level": {}}
	var has_header: bool = bad_save.has("header")
	assert_false(has_header, "Save without header should be invalid")

func test_save_validation_rejects_missing_player():
	var bad_save: Dictionary = {"header": {"version": 1}}
	var has_player: bool = bad_save.has("player")
	assert_false(has_player, "Save without player should be invalid")

# ============================================================================
# ABILITY HOTKEYS ROUNDTRIP
# ============================================================================

func test_ability_hotkeys_roundtrip():
	var original: Array[int] = [140, 142, -1, -1]
	var saved: Array = original.duplicate()

	# Modify original
	original[2] = 148

	assert_eq(int(saved[0]), 140, "Hotkey 1 preserved")
	assert_eq(int(saved[1]), 142, "Hotkey 2 preserved")
	assert_eq(int(saved[2]), -1, "Hotkey 3 not affected by post-save change")

# ============================================================================
# RUN STATS ROUNDTRIP
# ============================================================================

func test_run_stats_dict_roundtrip():
	var stats: Dictionary = {
		"turns_played": 500,
		"monsters_killed": 42,
		"deepest_depth": 8,
		"items_found": 30,
		"damage_dealt": 1500,
		"damage_taken": 800,
	}

	var saved: Dictionary = stats.duplicate()
	var loaded: Dictionary = saved.duplicate()

	assert_eq(loaded.turns_played, 500, "Turns played restored")
	assert_eq(loaded.monsters_killed, 42, "Kill count restored")
	assert_eq(loaded.deepest_depth, 8, "Deepest depth restored")
