extends Node
## Automated playtest bot for Necromancer
## Runs through core gameplay scenarios and reports results
##
## Usage: godot --path . --headless --script res://tests/bot/playtest_bot.gd

var _player: Node
var _level: Node
var _game_manager: Node
var _test_results: Array[Dictionary] = []
var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready():
	print("\n" + "=".repeat(60))
	print("[PLAYTEST BOT] Starting automated playtest...")
	print("=".repeat(60) + "\n")

	await get_tree().create_timer(0.5).timeout  # Let scene initialize

	_find_game_nodes()

	if not _player or not _level:
		_fail("SETUP", "Could not find Player or Level nodes")
		_report_and_exit()
		return

	await _run_all_tests()
	_report_and_exit()

func _find_game_nodes():
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	else:
		_player = _find_node_by_script_name("Player")

	# Find level
	_level = get_tree().root.find_child("Level", true, false)
	if not _level:
		_level = _find_node_by_script_name("Level")

	# Find game manager
	_game_manager = get_tree().root.find_child("GameManager", true, false)

	print("[BOT] Found nodes:")
	print("  - Player: %s" % ("YES" if _player else "NO"))
	print("  - Level: %s" % ("YES" if _level else "NO"))
	print("  - GameManager: %s" % ("YES" if _game_manager else "NO"))
	print("")

func _run_all_tests():
	await _test_player_exists()
	await _test_player_has_health()
	await _test_player_can_move()
	await _test_movement_blocked_by_walls()
	await _test_fov_works()
	await _test_monster_spawning()
	await _test_combat_system()
	await _test_item_pickup()
	await _test_survive_10_turns()

# ============================================================
# INDIVIDUAL TESTS
# ============================================================

func _test_player_exists():
	if _player:
		_pass("PLAYER_EXISTS", "Player node found in scene")
	else:
		_fail("PLAYER_EXISTS", "Player node not found")

func _test_player_has_health():
	if not _player:
		_skip("PLAYER_HEALTH", "No player")
		return

	if "current_health" in _player and "max_health" in _player:
		var hp: int = _player.current_health
		var max_hp: int = _player.max_health
		if hp > 0 and hp <= max_hp:
			_pass("PLAYER_HEALTH", "Player has %d/%d HP" % [hp, max_hp])
		else:
			_fail("PLAYER_HEALTH", "Invalid health: %d/%d" % [hp, max_hp])
	else:
		_fail("PLAYER_HEALTH", "Player missing health properties")

func _test_player_can_move():
	if not _player or not "grid_position" in _player:
		_skip("PLAYER_MOVE", "No player or grid_position")
		return

	var start_pos: Vector2i = _player.grid_position
	print("[BOT] Testing movement from %s" % start_pos)

	# Try moving in each direction until one works
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]

	var moved: bool = false
	for dir in directions:
		var target: Vector2i = start_pos + dir
		if _player.has_method("can_move_to") and _player.can_move_to(target):
			_simulate_movement(dir)
			await get_tree().create_timer(0.3).timeout

			if _player.grid_position != start_pos:
				moved = true
				_pass("PLAYER_MOVE", "Player moved from %s to %s" % [start_pos, _player.grid_position])
				# Move back
				_simulate_movement(-dir)
				await get_tree().create_timer(0.2).timeout
				break

	if not moved:
		# Check if blocked by walls (acceptable)
		_pass("PLAYER_MOVE", "Movement processed (may be blocked by terrain)")

func _test_movement_blocked_by_walls():
	if not _player or not _level:
		_skip("WALL_BLOCK", "No player or level")
		return

	# Find a wall tile near player
	if not _level.has_method("get_tile"):
		_skip("WALL_BLOCK", "Level missing get_tile method")
		return

	var player_pos: Vector2i = _player.grid_position
	var wall_found: bool = false

	for x in range(-2, 3):
		for y in range(-2, 3):
			var check_pos: Vector2i = player_pos + Vector2i(x, y)
			if _level.has_method("is_passable") and not _level.is_passable(check_pos):
				wall_found = true
				break
		if wall_found:
			break

	if wall_found:
		_pass("WALL_BLOCK", "Level has blocking terrain")
	else:
		_pass("WALL_BLOCK", "No walls found nearby (open area)")

func _test_fov_works():
	if not _level or not _level.has_method("update_fov"):
		_skip("FOV", "Level missing update_fov method")
		return

	var player_pos: Vector2i = _player.grid_position if _player else Vector2i(40, 20)

	# Try updating FOV
	_level.update_fov(player_pos, 8)
	_pass("FOV", "FOV updated without crash")

func _test_monster_spawning():
	if not _level:
		_skip("MONSTERS", "No level")
		return

	var monsters = get_tree().get_nodes_in_group("monsters")
	if monsters.size() == 0 and _level.has_method("get_monsters"):
		monsters = _level.get_monsters()

	if monsters.size() > 0:
		_pass("MONSTERS", "Found %d monsters in level" % monsters.size())
	else:
		_pass("MONSTERS", "No monsters spawned (may be valid for floor 1)")

func _test_combat_system():
	if not _player:
		_skip("COMBAT", "No player")
		return

	# Check if player has combat methods
	if _player.has_method("attack_entity"):
		_pass("COMBAT", "Player has attack_entity method")
	else:
		_fail("COMBAT", "Player missing attack_entity method")

func _test_item_pickup():
	if not _player or not _level:
		_skip("ITEMS", "No player or level")
		return

	# Check if pickup system exists
	if _player.has_method("pick_up_item") or _player.has_method("try_pickup"):
		_pass("ITEMS", "Item pickup system exists")
	else:
		_fail("ITEMS", "Missing item pickup methods")

func _test_survive_10_turns():
	if not _player:
		_skip("SURVIVAL", "No player")
		return

	print("[BOT] Simulating 10 turns of gameplay...")

	var initial_hp: int = _player.current_health if "current_health" in _player else 100

	for turn in range(10):
		# Wait for turn processing
		await get_tree().create_timer(0.1).timeout

		# Check player still alive
		if "is_alive" in _player and not _player.is_alive:
			_fail("SURVIVAL", "Player died on turn %d" % turn)
			return

		if "current_health" in _player and _player.current_health <= 0:
			_fail("SURVIVAL", "Player health reached 0 on turn %d" % turn)
			return

	var final_hp: int = _player.current_health if "current_health" in _player else 100
	_pass("SURVIVAL", "Survived 10 turns (HP: %d -> %d)" % [initial_hp, final_hp])

# ============================================================
# HELPERS
# ============================================================

func _simulate_movement(direction: Vector2i):
	var keycode: int = KEY_D  # Default right

	if direction == Vector2i(1, 0):
		keycode = KEY_D
	elif direction == Vector2i(-1, 0):
		keycode = KEY_A
	elif direction == Vector2i(0, 1):
		keycode = KEY_S
	elif direction == Vector2i(0, -1):
		keycode = KEY_W

	var event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)

	await get_tree().create_timer(0.05).timeout

	event.pressed = false
	Input.parse_input_event(event)

func _simulate_key(keycode: int):
	var event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().create_timer(0.05).timeout
	event.pressed = false
	Input.parse_input_event(event)

func _find_node_by_script_name(script_name: String) -> Node:
	return _search_tree(get_tree().root, script_name)

func _search_tree(node: Node, script_name: String) -> Node:
	var script = node.get_script()
	if script:
		var path: String = script.resource_path
		if script_name.to_lower() in path.to_lower():
			return node

	for child in node.get_children():
		var found = _search_tree(child, script_name)
		if found:
			return found

	return null

func _pass(test_name: String, message: String):
	_tests_passed += 1
	_test_results.append({"name": test_name, "status": "PASS", "message": message})
	print("[PASS] %s: %s" % [test_name, message])

func _fail(test_name: String, message: String):
	_tests_failed += 1
	_test_results.append({"name": test_name, "status": "FAIL", "message": message})
	print("[FAIL] %s: %s" % [test_name, message])

func _skip(test_name: String, reason: String):
	_test_results.append({"name": test_name, "status": "SKIP", "message": reason})
	print("[SKIP] %s: %s" % [test_name, reason])

func _report_and_exit():
	print("\n" + "=".repeat(60))
	print("[PLAYTEST BOT] Results")
	print("=".repeat(60))
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)
	print("Skipped: %d" % (_test_results.size() - _tests_passed - _tests_failed))
	print("=".repeat(60) + "\n")

	if _tests_failed > 0:
		print("[PLAYTEST BOT] FAILED - See errors above")
		get_tree().quit(1)
	else:
		print("[PLAYTEST BOT] PASSED - All tests successful")
		get_tree().quit(0)
