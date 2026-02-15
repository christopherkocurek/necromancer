extends Node
## Central game state manager.
## Coordinates turn flow, game state, and high-level game logic.

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER, INVENTORY, DIALOGUE }

enum Difficulty {
	EASY = 0,     # +50% XP, -25% monster damage, +25% item spawns, traps revealed
	NORMAL = 1,   # Standard balance
	HARD = 2,     # -20% items, +25% monster perception, no pity spawns
	IRONMAN = 3,  # Hard + no rest healing, faster hunger
}

# Difficulty modifier tables
const DIFFICULTY_MODIFIERS: Dictionary = {
	Difficulty.EASY: {
		"xp_multiplier": 1.5,
		"monster_damage_multiplier": 0.75,
		"item_spawn_multiplier": 1.25,
		"monster_perception_bonus": 0,
		"reveal_traps": true,
		"rest_healing": true,
		"label": "Easy",
		"description": "A gentler descent. More experience, weaker foes, and revealed traps.",
	},
	Difficulty.NORMAL: {
		"xp_multiplier": 1.0,
		"monster_damage_multiplier": 1.0,
		"item_spawn_multiplier": 1.0,
		"monster_perception_bonus": 0,
		"reveal_traps": false,
		"rest_healing": true,
		"label": "Normal",
		"description": "The standard challenge of Dol Guldur.",
	},
	Difficulty.HARD: {
		"xp_multiplier": 1.0,
		"monster_damage_multiplier": 1.0,
		"item_spawn_multiplier": 0.80,
		"monster_perception_bonus": 3,
		"reveal_traps": false,
		"rest_healing": true,
		"label": "Hard",
		"description": "Fewer supplies, sharper-eyed foes. True Sil-Q difficulty.",
	},
	Difficulty.IRONMAN: {
		"xp_multiplier": 1.0,
		"monster_damage_multiplier": 1.0,
		"item_spawn_multiplier": 0.80,
		"monster_perception_bonus": 3,
		"reveal_traps": false,
		"rest_healing": false,
		"label": "Ironman",
		"description": "Hard mode. No rest healing. Every wound matters.",
	},
}

var current_state: GameState = GameState.MAIN_MENU
var current_depth: int = 1
var turn_count: int = 0
var is_player_turn: bool = true
var current_difficulty: int = Difficulty.NORMAL

# References set during gameplay
var player: Node = null
var current_level: Node = null

# Game configuration
const TILE_SIZE: int = 64
const ZOOM_LEVELS: Array[float] = [0.5, 1.0, 1.5, 2.0, 3.0]
var current_zoom_index: int = 3  # Default to 2.0x zoom

# Identification system (Phase D)
# Tracks which item types (tval:sval) have been globally identified this game
var identified_types: Dictionary = {}  # "tval:sval" -> true
# Flavor names for unidentified consumables (randomized per game)
var flavor_names: Dictionary = {}  # "tval:sval" -> String

# Artifact tracking - each artifact can only spawn once per game
var spawned_artifacts: Array[int] = []  # artifact indices that have been spawned

# Greater vault tracking - each greater vault can only appear once per run
var used_greater_vaults: Array[int] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_new_game() -> void:
	current_depth = 1
	turn_count = 0
	is_player_turn = true
	current_state = GameState.PLAYING
	identified_types.clear()
	spawned_artifacts.clear()
	used_greater_vaults.clear()
	_randomize_flavor_names()
	EventBus.game_started.emit()

func reset_game() -> void:
	# Clear references
	player = null
	current_level = null
	# Reset state
	current_depth = 1
	turn_count = 0
	identified_types.clear()
	flavor_names.clear()
	spawned_artifacts.clear()
	used_greater_vaults.clear()
	is_player_turn = true
	current_state = GameState.MAIN_MENU
	current_zoom_index = 1
	current_difficulty = Difficulty.NORMAL

# ============================================================================
# DIFFICULTY SYSTEM
# ============================================================================

func set_difficulty(diff: int) -> void:
	current_difficulty = diff
	var label: String = get_difficulty_label()
	print("Difficulty set to: %s" % label)

func get_difficulty_label() -> String:
	var mods: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, DIFFICULTY_MODIFIERS[Difficulty.NORMAL])
	return mods.get("label", "Normal")

func get_difficulty_description() -> String:
	var mods: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, DIFFICULTY_MODIFIERS[Difficulty.NORMAL])
	return mods.get("description", "")

func is_hardcore_mode() -> bool:
	return current_difficulty == Difficulty.IRONMAN

func get_xp_multiplier() -> float:
	var mods: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, DIFFICULTY_MODIFIERS[Difficulty.NORMAL])
	return mods.get("xp_multiplier", 1.0)

func get_monster_damage_multiplier() -> float:
	var mods: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, DIFFICULTY_MODIFIERS[Difficulty.NORMAL])
	return mods.get("monster_damage_multiplier", 1.0)

func get_item_spawn_multiplier() -> float:
	var mods: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, DIFFICULTY_MODIFIERS[Difficulty.NORMAL])
	return mods.get("item_spawn_multiplier", 1.0)

func get_monster_perception_bonus() -> int:
	var mods: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, DIFFICULTY_MODIFIERS[Difficulty.NORMAL])
	return mods.get("monster_perception_bonus", 0)

func should_reveal_traps() -> bool:
	var mods: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, DIFFICULTY_MODIFIERS[Difficulty.NORMAL])
	return mods.get("reveal_traps", false)

func allows_rest_healing() -> bool:
	var mods: Dictionary = DIFFICULTY_MODIFIERS.get(current_difficulty, DIFFICULTY_MODIFIERS[Difficulty.NORMAL])
	return mods.get("rest_healing", true)

func change_state(new_state: GameState) -> void:
	var old_state := current_state
	current_state = new_state

	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
			EventBus.game_paused.emit()
		GameState.PLAYING:
			get_tree().paused = false
			if old_state == GameState.PAUSED:
				EventBus.game_resumed.emit()
		GameState.GAME_OVER:
			pass

func end_player_turn() -> void:
	is_player_turn = false
	EventBus.turn_ended.emit(player)
	EventBus.enemy_turn_started.emit()

func end_enemy_turn() -> void:
	turn_count += 1
	is_player_turn = true
	EventBus.round_completed.emit(turn_count)
	EventBus.player_turn_started.emit()

func descend_level() -> void:
	current_depth += 1
	EventBus.level_entered.emit(current_depth)

func ascend_level() -> void:
	if current_depth > 1:
		current_depth -= 1
		EventBus.level_entered.emit(current_depth)

func game_over(victory: bool, reason: String = "") -> void:
	current_state = GameState.GAME_OVER
	EventBus.game_over.emit(victory, reason)

func cycle_zoom() -> void:
	current_zoom_index = (current_zoom_index + 1) % ZOOM_LEVELS.size()

func cycle_zoom_reverse() -> void:
	current_zoom_index = (current_zoom_index - 1 + ZOOM_LEVELS.size()) % ZOOM_LEVELS.size()

func get_current_zoom() -> float:
	return ZOOM_LEVELS[current_zoom_index]

func log_message(text: String, color: Color = ThemeColors.TEXT_PRIMARY) -> void:
	EventBus.message_logged.emit(text, color)

# ============================================================================
# IDENTIFICATION SYSTEM (Phase D)
# ============================================================================

## Tvals that require identification
const IDENT_TVALS: Array[int] = [39, 40, 45, 55, 75, 80]  # Lights, Amulets, Rings, Scrolls, Potions, Food/Herbs

## Food svals that are always identified (basic food, not herbs)
const ALWAYS_IDENTIFIED_FOOD_SVALS: Array[int] = [1, 35, 36, 37, 38, 39, 40]  # Waymeal, Travel Bread, Dried Meat, Lembas, Cram, etc.

## Check if an item type needs identification
func needs_identification(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	# Artifacts are always identified
	if item is DataManager.ArtifactData:
		return false
	if "artifact_data" in item and item.artifact_data != null:
		return false
	# Check tval
	if item.tval not in IDENT_TVALS:
		return false
	# Exempt basic food items (bread, waymeal, etc.)
	if item.tval == 80 and "sval" in item and item.sval in ALWAYS_IDENTIFIED_FOOD_SVALS:
		return false
	return true

## Check if a specific item type (tval:sval) has been globally identified
func is_type_identified(tval: int, sval: int) -> bool:
	var key: String = "%d:%d" % [tval, sval]
	return identified_types.has(key)

## Check if an item is identified (either individually or by type)
func is_item_identified(item: Variant) -> bool:
	if item == null:
		return false
	if not needs_identification(item):
		return true  # Non-consumables are always "identified"
	# Check individual identification
	if "identified" in item and item.identified:
		return true
	# Check global type identification
	if "tval" in item and "sval" in item:
		return is_type_identified(item.tval, item.sval)
	return false

## Identify a specific item and its type globally
func identify_item(item: Variant) -> void:
	if item == null:
		return
	# Check if this is a first-time type identification (for XP)
	var first_time: bool = false
	if "tval" in item and "sval" in item:
		var key: String = "%d:%d" % [item.tval, item.sval]
		if not identified_types.has(key):
			first_time = true
		identified_types[key] = true
	if "identified" in item:
		item.identified = true
	log_message("You identify: %s" % _get_real_name(item), ThemeColors.MSG_INFO)
	# Emit signal for other systems
	EventBus.item_identified.emit(item)
	# Grant XP for first-time identification
	if first_time and player:
		var xp_amount: int = _get_identify_xp(item)
		player.gain_experience(xp_amount, "identify")

## Get the display name for an item (respects identification)
func get_item_display_name(item: Variant) -> String:
	if item == null:
		return "Unknown Item"
	if is_item_identified(item):
		return _get_real_name(item)
	# Unidentified — use flavor name
	return _get_unidentified_name(item)

func _get_real_name(item: Variant) -> String:
	if "name" in item:
		return _format_item_category_name(item, item.name)
	return "Unknown Item"

func _format_item_category_name(item: Variant, raw_name: String) -> String:
	if item == null or not "tval" in item:
		return raw_name
	var name: String = raw_name.strip_edges()
	var lower_name: String = name.to_lower()
	var prefix_parts: Dictionary = _extract_quality_prefix(name)
	var quality_prefix: String = str(prefix_parts.get("prefix", ""))
	var base_name: String = str(prefix_parts.get("name", name))
	var base_lower: String = base_name.to_lower()
	match int(item.tval):
		39:
			if lower_name.begins_with("ring of ") or lower_name.begins_with("amulet of ") or lower_name.begins_with("scroll of "):
				return name
			if base_lower.contains("torch") or base_lower.contains("lantern") or base_lower.contains("lamp") or base_lower.contains("light"):
				return name
			return "%sLight of %s" % [quality_prefix, base_name]
		40:
			if base_lower.begins_with("amulet of "):
				return name
			return "%sAmulet of %s" % [quality_prefix, base_name]
		45:
			if base_lower.begins_with("ring of "):
				return name
			return "%sRing of %s" % [quality_prefix, base_name]
		55:
			if base_lower.begins_with("scroll of "):
				return name
			return "%sScroll of %s" % [quality_prefix, base_name]
	return name

func _extract_quality_prefix(name: String) -> Dictionary:
	var prefixes: Array[String] = ["Improved ", "Fine ", "Flawless ", "Masterwork ", "Mithril "]
	for prefix in prefixes:
		if name.begins_with(prefix):
			return {"prefix": prefix, "name": name.substr(prefix.length())}
	return {"prefix": "", "name": name}

func _get_identify_xp(item: Variant) -> int:
	var base: int = 12
	if item != null and "tval" in item:
		match int(item.tval):
			39:
				base = 30
			40, 45:
				base = 36
			55:
				base = 20
			75:
				base = 16
			80:
				base = 12
			_:
				base = 12
	if item != null and "cost" in item:
		base += clampi(int(item.cost) / 250, 0, 20)
	return clampi(base, 8, 80)

func get_valid_dice_string(dice_str: String) -> String:
	if dice_str.is_empty():
		return ""
	var parts: PackedStringArray = dice_str.to_lower().split("d")
	if parts.size() != 2:
		return ""
	if not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return ""
	var dice: int = int(parts[0])
	var sides: int = int(parts[1])
	if dice < 1 or sides < 1:
		return ""
	return "%dd%d" % [dice, sides]

func _get_unidentified_name(item: Variant) -> String:
	if not "tval" in item or not "sval" in item:
		return "Unknown Item"
	var key: String = "%d:%d" % [item.tval, item.sval]
	if flavor_names.has(key):
		return flavor_names[key]
	# Fallback generic names
	match item.tval:
		39: return "Unknown Light"
		40: return "Unknown Amulet"
		45: return "Unknown Ring"
		55: return "Unknown Scroll"
		75: return "Unknown Potion"
		80: return "Unknown Herb"
	return "Unknown Item"

## Randomize flavor names for all identifiable categories at game start
func _randomize_flavor_names() -> void:
	flavor_names.clear()
	var potion_flavors: Array[String] = [
		"Murky Potion", "Emerald Potion", "Opalescent Potion", "Crimson Potion",
		"Azure Potion", "Amber Potion", "Silvery Potion", "Midnight Potion",
		"Pearlescent Potion", "Ochre Potion", "Violet Potion", "Jade Potion",
		"Russet Potion", "Sapphire Potion", "Golden Potion", "Indigo Potion",
		"Scarlet Potion", "Tawny Potion", "Bone-white Potion", "Smoky Potion",
		"Phosphorescent Potion", "Swirling Potion", "Cloudy Potion",
		"Shimmering Potion", "Bubbling Potion", "Thick Potion",
		"Tar-black Potion", "Rose Potion", "Chalky Potion", "Iron-gray Potion",
	]
	var scroll_flavors: Array[String] = [
		"\"DWAR KAZAD\"", "\"GALAD ENNOR\"", "\"NAUR AMBAR\"", "\"GURTH GOTHRIM\"",
		"\"AMON EITHEL\"", "\"THALION ITHIL\"", "\"MELLON ARDA\"", "\"CURUNIR ANOR\"",
		"\"DAGNIR BEREN\"", "\"HAUDH NARGOTH\"", "\"RINGIL TAUR\"", "\"FEANOR SILME\"",
		"\"NIMPHELOS GAUR\"", "\"NOLDOR AGLAR\"", "\"GONDOLIN ERED\"",
		"\"THANGORODRIM\"", "\"CELEBRIMBOR\"", "\"NEVRAST FALATH\"",
		"\"MAEDHROS SIRION\"", "\"ANGBAND MORGUL\"",
	]
	var herb_flavors: Array[String] = [
		"a Black Herb", "a Spotted Mushroom", "a Thorny Sprig", "a Waxy Leaf",
		"a Fragrant Root", "a Bitter Berry", "a Silver Moss", "a Gnarled Twig",
		"a Luminous Lichen", "a Dried Flower", "a Pungent Bulb", "a Fuzzy Cap",
		"a Crimson Seed", "a Pale Stalk", "a Twisted Vine", "a Dusty Pod",
		"a Blue Petal", "a Oily Nut", "a Withered Frond", "a Ashen Bark",
	]
	var ring_flavors: Array[String] = [
		"a Twisted Ring", "a Mithril Ring", "a Bone Ring", "an Iron Ring",
		"a Copper Ring", "a Silver Ring", "a Gold Ring", "a Bronze Ring",
		"a Stone Ring", "a Wooden Ring", "a Glass Ring", "a Onyx Ring",
		"a Pearl Ring", "a Jade Ring", "a Ruby Ring", "an Obsidian Ring",
	]
	var amulet_flavors: Array[String] = [
		"a Crystal Amulet", "an Amber Amulet", "a Moonstone Amulet",
		"a Silver Amulet", "a Bone Amulet", "a Jade Amulet",
		"an Ivory Amulet", "a Sapphire Amulet", "an Obsidian Amulet",
		"a Coral Amulet", "a Garnet Amulet", "an Opal Amulet",
	]
	potion_flavors.shuffle()
	scroll_flavors.shuffle()
	herb_flavors.shuffle()
	ring_flavors.shuffle()
	amulet_flavors.shuffle()

	# Assign flavor names to all known identifiable svals
	var potion_idx: int = 0
	var scroll_idx: int = 0
	var herb_idx: int = 0
	var ring_idx: int = 0
	var amulet_idx: int = 0
	for item_data in DataManager.items.values():
		if item_data is DataManager.ItemData:
			var key: String = "%d:%d" % [item_data.tval, item_data.sval]
			if item_data.tval == 75 and potion_idx < potion_flavors.size():
				flavor_names[key] = potion_flavors[potion_idx]
				potion_idx += 1
			elif item_data.tval == 55 and scroll_idx < scroll_flavors.size():
				flavor_names[key] = scroll_flavors[scroll_idx]
				scroll_idx += 1
			elif item_data.tval == 80 and item_data.sval not in ALWAYS_IDENTIFIED_FOOD_SVALS and herb_idx < herb_flavors.size():
				flavor_names[key] = herb_flavors[herb_idx]
				herb_idx += 1
			elif item_data.tval == 45 and ring_idx < ring_flavors.size():
				flavor_names[key] = ring_flavors[ring_idx]
				ring_idx += 1
			elif item_data.tval == 40 and amulet_idx < amulet_flavors.size():
				flavor_names[key] = amulet_flavors[amulet_idx]
				amulet_idx += 1
