extends Node
## Central game state manager.
## Coordinates turn flow, game state, and high-level game logic.

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER, INVENTORY, DIALOGUE }

var current_state: GameState = GameState.MAIN_MENU
var current_depth: int = 1
var turn_count: int = 0
var is_player_turn: bool = true

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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_new_game() -> void:
	current_depth = 1
	turn_count = 0
	is_player_turn = true
	current_state = GameState.PLAYING
	identified_types.clear()
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
	is_player_turn = true
	current_state = GameState.MAIN_MENU
	current_zoom_index = 1

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

func log_message(text: String, color: Color = Color.WHITE) -> void:
	EventBus.message_logged.emit(text, color)

# ============================================================================
# IDENTIFICATION SYSTEM (Phase D)
# ============================================================================

## Consumable tvals that require identification
const IDENT_TVALS: Array[int] = [55, 75, 80]  # Scrolls, Potions, Food/Herbs

## Check if an item type needs identification
func needs_identification(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	return item.tval in IDENT_TVALS

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
	if "identified" in item:
		item.identified = true
	if "tval" in item and "sval" in item:
		var key: String = "%d:%d" % [item.tval, item.sval]
		identified_types[key] = true
	log_message("You identify: %s" % _get_real_name(item), Color.CYAN)

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
		return item.name
	return "Unknown Item"

func _get_unidentified_name(item: Variant) -> String:
	if not "tval" in item or not "sval" in item:
		return "Unknown Item"
	var key: String = "%d:%d" % [item.tval, item.sval]
	if flavor_names.has(key):
		return flavor_names[key]
	# Fallback generic names
	match item.tval:
		55: return "Unknown Scroll"
		75: return "Unknown Potion"
		80: return "Unknown Herb"
	return "Unknown Item"

## Randomize flavor names for consumables at game start
func _randomize_flavor_names() -> void:
	flavor_names.clear()
	var potion_flavors: Array[String] = [
		"Murky Potion", "Cloudy Potion", "Dark Potion", "Glowing Potion",
		"Shimmering Potion", "Bubbling Potion", "Viscous Potion", "Clear Potion",
		"Green Potion", "Red Potion", "Blue Potion", "Golden Potion",
		"Silver Potion", "Purple Potion", "Black Potion", "White Potion",
		"Amber Potion", "Crimson Potion", "Turquoise Potion", "Smoky Potion",
	]
	var scroll_flavors: Array[String] = [
		"Faded Scroll", "Crumpled Scroll", "Dusty Scroll", "Yellowed Scroll",
		"Torn Scroll", "Sealed Scroll", "Ornate Scroll", "Charred Scroll",
		"Wax-sealed Scroll", "Rune-marked Scroll", "Stained Scroll", "Ancient Scroll",
		"Rolled Scroll", "Worn Scroll", "Gilded Scroll", "Dark Scroll",
	]
	var herb_flavors: Array[String] = [
		"Pale Herb", "Dark Herb", "Fragrant Herb", "Bitter Herb",
		"Dried Herb", "Fresh Herb", "Pungent Herb", "Sweet Herb",
		"Fibrous Root", "Tiny Mushroom", "Brown Lichen", "Spotted Fungus",
	]
	potion_flavors.shuffle()
	scroll_flavors.shuffle()
	herb_flavors.shuffle()

	# Assign flavor names to all known consumable svals
	var potion_idx: int = 0
	var scroll_idx: int = 0
	var herb_idx: int = 0
	for item_data in DataManager.items.values():
		if item_data is DataManager.ItemData:
			var key: String = "%d:%d" % [item_data.tval, item_data.sval]
			if item_data.tval == 75 and potion_idx < potion_flavors.size():
				flavor_names[key] = potion_flavors[potion_idx]
				potion_idx += 1
			elif item_data.tval == 55 and scroll_idx < scroll_flavors.size():
				flavor_names[key] = scroll_flavors[scroll_idx]
				scroll_idx += 1
			elif item_data.tval == 80 and herb_idx < herb_flavors.size():
				flavor_names[key] = herb_flavors[herb_idx]
				herb_idx += 1
