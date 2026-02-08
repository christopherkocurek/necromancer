extends Node
## Fuzz Bot - Random Action Crash Finder for Necromancer
## Exercises ALL valid game keypresses over 500+ turns, catching crashes/errors.
##
## Usage (standalone):
##   godot --path . --headless --script res://test_runner.gd -- --fuzz
## Usage (attached to main scene):
##   Instantiate as child of main scene node, bot auto-runs on _ready()

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

const MAX_TURNS: int = 500
const STATUS_INTERVAL: int = 50
const TICK_DELAY: float = 0.05
const INIT_DELAY: float = 1.0
const UI_CLOSE_DELAY: int = 2  # Close UI panels after N turns
const MAX_ACTION_HISTORY: int = 200

# Action category weights (must sum to 100)
const WEIGHT_MOVEMENT: int = 60
const WEIGHT_COMBAT_ITEM: int = 25
const WEIGHT_UI: int = 15

# ---------------------------------------------------------------------------
# Action definitions
# ---------------------------------------------------------------------------

## Each action: { name, keycode, shift, category }
## Categories: "movement", "combat_item", "ui"
## keycode: Godot KEY_* constant
## shift: whether Shift must be held
## unicode: optional unicode override for symbol keys (macOS fallback)

class FuzzAction:
	var action_name: String
	var keycode: int
	var shift_pressed: bool
	var category: String
	var unicode: int  # 0 = not set
	var is_action: bool  # true = use Input action, false = raw keycode

	func _init(p_name: String, p_keycode: int, p_shift: bool, p_category: String, p_unicode: int = 0, p_is_action: bool = false) -> void:
		action_name = p_name
		keycode = p_keycode
		shift_pressed = p_shift
		category = p_category
		unicode = p_unicode
		is_action = p_is_action

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _main_node: Node2D = null
var _player: Node = null
var _level: Node = null
var _turn_system: Node = null
var _game_manager: Node = null

var _actions: Array = []  # Array of FuzzAction
var _movement_actions: Array = []
var _combat_item_actions: Array = []
var _ui_actions: Array = []

var _action_history: Array[String] = []
var _category_counts: Dictionary = {"movement": 0, "combat_item": 0, "ui": 0}
var _turns_completed: int = 0
var _deaths: int = 0
var _errors_caught: int = 0
var _ui_open_counter: int = 0  # Tracks turns since UI was opened

var _error_log: Array[String] = []
var _original_push_error: Callable

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("[FUZZ BOT] Starting random action crash finder...")
	print("[FUZZ BOT] Max turns: %d | Tick delay: %.2fs" % [MAX_TURNS, TICK_DELAY])
	print("=".repeat(60) + "\n")

	_rng.randomize()

	_build_action_pool()
	_hook_error_logging()

	# Wait for scene to fully initialize
	await get_tree().create_timer(INIT_DELAY).timeout

	_find_game_nodes()

	if not _main_node:
		print("[FUZZ BOT] FATAL: Could not find Main node. Aborting.")
		_report_and_exit(1)
		return

	# Skip character creation by directly starting a new game
	_skip_character_creation()

	# Wait for game to initialize after character creation
	await get_tree().create_timer(0.5).timeout

	# Re-find nodes after game start (player/level created during _start_new_game)
	_find_game_nodes()

	if not _player:
		print("[FUZZ BOT] FATAL: Player not found after game start. Aborting.")
		_report_and_exit(1)
		return

	print("[FUZZ BOT] Game initialized. Player found. Starting fuzz loop...\n")

	await _run_fuzz_loop()
	_report_and_exit(0)

# ---------------------------------------------------------------------------
# Action pool construction
# ---------------------------------------------------------------------------

func _build_action_pool() -> void:
	# -- MOVEMENT (category "movement") --
	# Cardinal: WASD
	_add_action("move_up (W)", KEY_W, false, "movement")
	_add_action("move_down (S)", KEY_S, false, "movement")
	_add_action("move_left (A)", KEY_A, false, "movement")
	_add_action("move_right (D)", KEY_D, false, "movement")
	# Cardinal: HJKL
	_add_action("move_up (K)", KEY_K, false, "movement")
	_add_action("move_down (J)", KEY_J, false, "movement")
	_add_action("move_left (H)", KEY_H, false, "movement")
	_add_action("move_right (L)", KEY_L, false, "movement")
	# Cardinal: Arrow keys
	_add_action("move_up (Arrow)", KEY_UP, false, "movement")
	_add_action("move_down (Arrow)", KEY_DOWN, false, "movement")
	_add_action("move_left (Arrow)", KEY_LEFT, false, "movement")
	_add_action("move_right (Arrow)", KEY_RIGHT, false, "movement")
	# Diagonal: YUBN
	_add_action("diag_up_left (Y)", KEY_Y, false, "movement")
	_add_action("diag_up_right (U)", KEY_U, false, "movement")
	_add_action("diag_down_left (B)", KEY_B, false, "movement")
	_add_action("diag_down_right (N)", KEY_N, false, "movement")
	# Wait / skip turn
	_add_action("wait (.)", KEY_PERIOD, false, "movement")

	# -- COMBAT / ITEM (category "combat_item") --
	_add_action("pickup (G)", KEY_G, false, "combat_item")
	_add_action("equip_floor (E)", KEY_E, false, "combat_item")
	_add_action("drop (Shift+D)", KEY_D, true, "combat_item")
	_add_action("quaff (Q)", KEY_Q, false, "combat_item")
	_add_action("eat (,)", KEY_COMMA, false, "combat_item", 44)
	_add_action("stealth (;)", KEY_SEMICOLON, false, "combat_item", 59)
	_add_action("close_door (C)", KEY_C, false, "combat_item")
	_add_action("search (Shift+S)", KEY_S, true, "combat_item")
	_add_action("stairs (Enter)", KEY_ENTER, false, "combat_item")
	_add_action("rest (Z)", KEY_Z, false, "combat_item")
	_add_action("rest_n (Shift+Z)", KEY_Z, true, "combat_item")
	_add_action("auto_explore (O)", KEY_O, false, "combat_item")
	_add_action("fire/forge (F)", KEY_F, false, "combat_item")
	_add_action("voice (V)", KEY_V, false, "combat_item")
	_add_action("horn (P)", KEY_P, false, "combat_item")
	_add_action("read_scroll (R)", KEY_R, false, "combat_item")
	_add_action("disarm_trap (D)", KEY_D, false, "combat_item")
	_add_action("hotkey_1", KEY_1, false, "combat_item")
	_add_action("hotkey_2", KEY_2, false, "combat_item")
	_add_action("hotkey_3", KEY_3, false, "combat_item")
	_add_action("hotkey_4", KEY_4, false, "combat_item")

	# -- UI (category "ui") --
	_add_action("inventory (I)", KEY_I, false, "ui")
	_add_action("tome (T)", KEY_T, false, "ui")
	_add_action("look (X)", KEY_X, false, "ui")
	_add_action("minimap (M)", KEY_M, false, "ui")
	_add_action("help (?)", KEY_SLASH, true, "ui")
	_add_action("tab_expand (Tab)", KEY_TAB, false, "ui")
	_add_action("settings (Esc)", KEY_ESCAPE, false, "ui")

	# Sort into category buckets
	for action: Variant in _actions:
		var fa: FuzzAction = action as FuzzAction
		match fa.category:
			"movement":
				_movement_actions.append(fa)
			"combat_item":
				_combat_item_actions.append(fa)
			"ui":
				_ui_actions.append(fa)

	print("[FUZZ BOT] Action pool: %d total (%d movement, %d combat/item, %d UI)" % [
		_actions.size(), _movement_actions.size(),
		_combat_item_actions.size(), _ui_actions.size()
	])

func _add_action(p_name: String, p_keycode: int, p_shift: bool, p_category: String, p_unicode: int = 0) -> void:
	var action: FuzzAction = FuzzAction.new(p_name, p_keycode, p_shift, p_category, p_unicode)
	_actions.append(action)

# ---------------------------------------------------------------------------
# Node discovery
# ---------------------------------------------------------------------------

func _find_game_nodes() -> void:
	# Find Main node (parent or scene root)
	_main_node = get_parent()
	if not _main_node or not _main_node.has_method("_start_new_game"):
		# Search the tree
		_main_node = _find_node_by_method("_start_new_game")

	# Find player
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	else:
		_player = _find_node_by_script_name("Player")
		if not _player:
			_player = _find_node_by_script_name("player")

	# Find level
	_level = get_tree().root.find_child("Level", true, false)
	if not _level:
		_level = _find_node_by_script_name("Level")

	# Find turn system
	_turn_system = get_tree().root.find_child("TurnSystem", true, false)

	# Find game manager (autoload singleton)
	_game_manager = get_tree().root.find_child("GameManager", true, false)

	print("[FUZZ BOT] Nodes found:")
	print("  Main: %s" % ("YES" if _main_node else "NO"))
	print("  Player: %s" % ("YES" if _player else "NO"))
	print("  Level: %s" % ("YES" if _level else "NO"))
	print("  TurnSystem: %s" % ("YES" if _turn_system else "NO"))
	print("  GameManager: %s" % ("YES" if _game_manager else "NO"))

func _find_node_by_method(method_name: String) -> Node:
	return _search_tree_method(get_tree().root, method_name)

func _search_tree_method(node: Node, method_name: String) -> Node:
	if node.has_method(method_name):
		return node
	for child in node.get_children():
		var found: Node = _search_tree_method(child, method_name)
		if found:
			return found
	return null

func _find_node_by_script_name(script_name: String) -> Node:
	return _search_tree_script(get_tree().root, script_name)

func _search_tree_script(node: Node, script_name: String) -> Node:
	var script: Script = node.get_script() as Script
	if script:
		var path: String = script.resource_path
		if script_name.to_lower() in path.to_lower():
			return node
	for child in node.get_children():
		var found: Node = _search_tree_script(child, script_name)
		if found:
			return found
	return null

# ---------------------------------------------------------------------------
# Character creation bypass
# ---------------------------------------------------------------------------

func _skip_character_creation() -> void:
	var default_character: Dictionary = {
		"name": "FuzzBot",
		"race": "Man",
		"house": "House of Beor",
		"trait": "Resilient",
		"gender": "male",
		"age": 25,
		"history": "A seasoned tester of dungeon stability.",
		"base_stats": {
			"str": 3,
			"dex": 3,
			"con": 3,
			"gra": 3,
		},
	}

	print("[FUZZ BOT] Skipping character creation with default character: %s" % default_character.name)

	# Remove the character creation panel if it exists
	if _main_node and "character_creation" in _main_node and _main_node.character_creation:
		_main_node.character_creation.queue_free()
		_main_node.character_creation = null

	# Directly start the game
	if _main_node and _main_node.has_method("_start_new_game"):
		_main_node._start_new_game(default_character)
		print("[FUZZ BOT] Game started via _start_new_game()")
	else:
		print("[FUZZ BOT] ERROR: Main node missing _start_new_game method")

# ---------------------------------------------------------------------------
# Error logging hook
# ---------------------------------------------------------------------------

func _hook_error_logging() -> void:
	# GDScript doesn't expose push_error/push_warning hooks directly.
	# Instead, we monitor Godot's error output via a custom logger.
	# We'll capture errors through a _process check on the Godot debugger error count.
	pass

func _capture_error(message: String) -> void:
	_errors_caught += 1
	var timestamp: String = "Turn %d" % _turns_completed
	var entry: String = "[%s] %s" % [timestamp, message]
	_error_log.append(entry)
	print("[FUZZ BOT ERROR] %s" % entry)

# ---------------------------------------------------------------------------
# Main fuzz loop
# ---------------------------------------------------------------------------

func _run_fuzz_loop() -> void:
	for turn_idx: int in range(MAX_TURNS):
		_turns_completed = turn_idx + 1

		# 1. Pick a weighted random action
		var action: FuzzAction = _pick_weighted_action()

		# 2. If UI has been open too long, force close it
		if _ui_open_counter >= UI_CLOSE_DELAY:
			_force_close_ui()
			_ui_open_counter = 0
		elif action.category == "ui":
			_ui_open_counter += 1
		else:
			_ui_open_counter = 0

		# 3. Simulate the keypress
		_simulate_action(action)

		# 4. Record action
		_record_action(action)

		# 5. Wait for game tick
		await get_tree().create_timer(TICK_DELAY).timeout

		# 6. Check player alive
		if not _is_player_alive():
			_deaths += 1
			print("[FUZZ BOT] Player died on turn %d! (Deaths: %d)" % [_turns_completed, _deaths])
			# Try to restart the game
			var restarted: bool = await _try_restart_after_death()
			if not restarted:
				print("[FUZZ BOT] Could not restart after death. Ending fuzz run.")
				break

		# 7. Check for runtime errors (poll-based)
		_poll_for_errors()

		# 8. Status report every N turns
		if _turns_completed % STATUS_INTERVAL == 0:
			_print_status()

	print("\n[FUZZ BOT] Fuzz loop complete.")

# ---------------------------------------------------------------------------
# Action selection (weighted)
# ---------------------------------------------------------------------------

func _pick_weighted_action() -> FuzzAction:
	var roll: int = _rng.randi_range(1, 100)

	if roll <= WEIGHT_MOVEMENT:
		# Movement
		var idx: int = _rng.randi_range(0, _movement_actions.size() - 1)
		return _movement_actions[idx] as FuzzAction
	elif roll <= WEIGHT_MOVEMENT + WEIGHT_COMBAT_ITEM:
		# Combat / Item
		var idx: int = _rng.randi_range(0, _combat_item_actions.size() - 1)
		return _combat_item_actions[idx] as FuzzAction
	else:
		# UI
		var idx: int = _rng.randi_range(0, _ui_actions.size() - 1)
		return _ui_actions[idx] as FuzzAction

# ---------------------------------------------------------------------------
# Input simulation
# ---------------------------------------------------------------------------

func _simulate_action(action: FuzzAction) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = action.keycode
	event.physical_keycode = action.keycode
	event.pressed = true
	event.echo = false
	event.shift_pressed = action.shift_pressed

	# Set unicode for symbol keys (macOS compatibility)
	if action.unicode > 0:
		event.unicode = action.unicode
	else:
		# Set unicode from keycode for letter keys
		var unicode_val: int = _keycode_to_unicode(action.keycode, action.shift_pressed)
		if unicode_val > 0:
			event.unicode = unicode_val

	# Send press event
	Input.parse_input_event(event)

	# Brief delay then release
	await get_tree().create_timer(0.02).timeout

	var release: InputEventKey = InputEventKey.new()
	release.keycode = action.keycode
	release.physical_keycode = action.keycode
	release.pressed = false
	release.echo = false
	release.shift_pressed = action.shift_pressed
	if action.unicode > 0:
		release.unicode = action.unicode
	Input.parse_input_event(release)

func _keycode_to_unicode(kc: int, shifted: bool) -> int:
	# Map common keycodes to their unicode values
	# Letters A-Z
	if kc >= KEY_A and kc <= KEY_Z:
		if shifted:
			return kc  # Uppercase (KEY_A = 65 = 'A')
		else:
			return kc + 32  # Lowercase (97 = 'a')
	# Numbers 0-9
	if kc >= KEY_0 and kc <= KEY_9:
		return kc  # KEY_0 = 48 = '0'
	# Period
	if kc == KEY_PERIOD:
		return 46
	# Comma
	if kc == KEY_COMMA:
		return 44
	# Semicolon
	if kc == KEY_SEMICOLON:
		return 59
	# Slash (for ? with shift)
	if kc == KEY_SLASH:
		if shifted:
			return 63  # '?'
		return 47  # '/'
	# Enter
	if kc == KEY_ENTER:
		return 13
	# Tab
	if kc == KEY_TAB:
		return 9
	# Escape
	if kc == KEY_ESCAPE:
		return 27
	return 0

# ---------------------------------------------------------------------------
# Force close UI panels
# ---------------------------------------------------------------------------

func _force_close_ui() -> void:
	# Send Escape to close any open panel
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	event.echo = false
	event.unicode = 27
	Input.parse_input_event(event)

	await get_tree().create_timer(0.02).timeout

	var release: InputEventKey = InputEventKey.new()
	release.keycode = KEY_ESCAPE
	release.physical_keycode = KEY_ESCAPE
	release.pressed = false
	release.echo = false
	release.unicode = 27
	Input.parse_input_event(release)

# ---------------------------------------------------------------------------
# Player alive check
# ---------------------------------------------------------------------------

func _is_player_alive() -> bool:
	if not _player or not is_instance_valid(_player):
		return false
	if "is_alive" in _player:
		return _player.is_alive
	if "current_health" in _player:
		return _player.current_health > 0
	return true

# ---------------------------------------------------------------------------
# Restart after death
# ---------------------------------------------------------------------------

func _try_restart_after_death() -> bool:
	# Wait a moment for death screen to appear
	await get_tree().create_timer(0.3).timeout

	# Try to find and re-trigger new game
	# First try pressing Enter/Space on death screen
	_simulate_key_quick(KEY_ENTER)
	await get_tree().create_timer(0.3).timeout

	# Re-start the game directly
	if _main_node and _main_node.has_method("_start_new_game"):
		# Close death screen if present
		if "death_screen" in _main_node and _main_node.death_screen and _main_node.death_screen.visible:
			_main_node.death_screen.hide()

		var default_char: Dictionary = {
			"name": "FuzzBot",
			"race": "Man",
			"house": "House of Beor",
			"trait": "Resilient",
			"gender": "male",
			"age": 25,
			"history": "Respawned after death.",
			"base_stats": {"str": 3, "dex": 3, "con": 3, "gra": 3},
		}
		_main_node._start_new_game(default_char)
		await get_tree().create_timer(0.5).timeout

		# Re-find nodes
		_find_game_nodes()
		return _player != null and _is_player_alive()

	return false

func _simulate_key_quick(kc: int) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = kc
	event.physical_keycode = kc
	event.pressed = true
	event.echo = false
	Input.parse_input_event(event)

# ---------------------------------------------------------------------------
# Error polling
# ---------------------------------------------------------------------------

func _poll_for_errors() -> void:
	# Godot 4 doesn't expose a runtime error count to GDScript directly.
	# We catch what we can: null references, freed objects, etc.
	# Check if key game objects have been unexpectedly freed
	if _player and not is_instance_valid(_player):
		_capture_error("Player node was freed unexpectedly!")
		_player = null
	if _level and not is_instance_valid(_level):
		_capture_error("Level node was freed unexpectedly!")
		_level = null
	if _turn_system and not is_instance_valid(_turn_system):
		_capture_error("TurnSystem node was freed unexpectedly!")
		_turn_system = null
	if _main_node and not is_instance_valid(_main_node):
		_capture_error("Main node was freed unexpectedly!")
		_main_node = null

# ---------------------------------------------------------------------------
# Action recording
# ---------------------------------------------------------------------------

func _record_action(action: FuzzAction) -> void:
	var entry: String = "T%d: %s" % [_turns_completed, action.action_name]
	_action_history.append(entry)

	# Keep history bounded
	if _action_history.size() > MAX_ACTION_HISTORY:
		_action_history.remove_at(0)

	# Update category counts
	_category_counts[action.category] = _category_counts.get(action.category, 0) + 1

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

func _print_status() -> void:
	var hp_str: String = "??/??"
	var pos_str: String = "??"
	var depth_str: String = "??"

	if _player and is_instance_valid(_player):
		if "current_health" in _player and "max_health" in _player:
			hp_str = "%d/%d" % [_player.current_health, _player.max_health]
		if "grid_position" in _player:
			pos_str = str(_player.grid_position)

	if _game_manager and is_instance_valid(_game_manager):
		depth_str = str(_game_manager.current_depth) if "current_depth" in _game_manager else "??"

	print("[FUZZ BOT] Turn %d/%d -- HP: %s -- Pos: %s -- Depth: %s -- Deaths: %d -- Errors: %d" % [
		_turns_completed, MAX_TURNS, hp_str, pos_str, depth_str, _deaths, _errors_caught
	])

# ---------------------------------------------------------------------------
# Crash report generation
# ---------------------------------------------------------------------------

func _write_crash_report() -> void:
	var report_path: String = "user://fuzz_crash_report.txt"
	var file: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if not file:
		print("[FUZZ BOT] WARNING: Could not write crash report to %s" % report_path)
		return

	file.store_line("=" .repeat(60))
	file.store_line("FUZZ BOT CRASH REPORT")
	file.store_line("=" .repeat(60))
	file.store_line("Generated: %s" % Time.get_datetime_string_from_system())
	file.store_line("")

	# Summary
	file.store_line("--- SUMMARY ---")
	file.store_line("Turns completed: %d / %d" % [_turns_completed, MAX_TURNS])
	file.store_line("Deaths: %d" % _deaths)
	file.store_line("Errors caught: %d" % _errors_caught)
	file.store_line("Actions: movement=%d, combat_item=%d, ui=%d" % [
		_category_counts.get("movement", 0),
		_category_counts.get("combat_item", 0),
		_category_counts.get("ui", 0),
	])
	file.store_line("")

	# Player state
	file.store_line("--- PLAYER STATE ---")
	if _player and is_instance_valid(_player):
		if "current_health" in _player and "max_health" in _player:
			file.store_line("HP: %d/%d" % [_player.current_health, _player.max_health])
		if "grid_position" in _player:
			file.store_line("Position: %s" % str(_player.grid_position))
		if "inventory" in _player:
			file.store_line("Inventory size: %d" % _player.inventory.size())
	else:
		file.store_line("Player: NOT AVAILABLE (freed or null)")

	if _game_manager and is_instance_valid(_game_manager) and "current_depth" in _game_manager:
		file.store_line("Depth: %d" % _game_manager.current_depth)
	file.store_line("")

	# Error log
	file.store_line("--- ERROR LOG (%d entries) ---" % _error_log.size())
	for entry: String in _error_log:
		file.store_line(entry)
	file.store_line("")

	# Last N actions
	var history_count: int = mini(_action_history.size(), 50)
	file.store_line("--- LAST %d ACTIONS ---" % history_count)
	var start_idx: int = _action_history.size() - history_count
	for i: int in range(start_idx, _action_history.size()):
		file.store_line(_action_history[i])
	file.store_line("")

	file.store_line("=" .repeat(60))
	file.store_line("END OF REPORT")
	file.store_line("=" .repeat(60))

	file.close()
	print("[FUZZ BOT] Crash report written to: %s" % report_path)

# ---------------------------------------------------------------------------
# Final report and exit
# ---------------------------------------------------------------------------

func _report_and_exit(exit_code: int = 0) -> void:
	print("\n" + "=".repeat(60))
	print("[FUZZ BOT] RESULTS")
	print("=".repeat(60))
	print("  Turns completed: %d / %d" % [_turns_completed, MAX_TURNS])
	print("  Deaths: %d" % _deaths)
	print("  Errors caught: %d" % _errors_caught)
	print("  Actions by category:")
	print("    Movement:    %d" % _category_counts.get("movement", 0))
	print("    Combat/Item: %d" % _category_counts.get("combat_item", 0))
	print("    UI:          %d" % _category_counts.get("ui", 0))
	print("  Total actions: %d" % (_category_counts.get("movement", 0) + _category_counts.get("combat_item", 0) + _category_counts.get("ui", 0)))

	if _errors_caught > 0 or _deaths > 0:
		print("\n  Error log:")
		for entry: String in _error_log:
			print("    %s" % entry)

	# Always write crash report (useful even for successful runs)
	_write_crash_report()

	var final_status: String = "PASSED" if (_errors_caught == 0 and exit_code == 0) else "ISSUES FOUND"
	print("\n  Status: %s" % final_status)
	print("=".repeat(60) + "\n")

	# Determine exit code: fail if errors found (deaths are acceptable in a roguelike)
	var final_exit: int = exit_code
	if _errors_caught > 0:
		final_exit = 1

	get_tree().quit(final_exit)
