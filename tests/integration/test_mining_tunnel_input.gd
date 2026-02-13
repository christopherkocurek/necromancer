extends GutTest

var _game_scene: PackedScene
var _main: Node

func before_all() -> void:
	if ResourceLoader.exists("res://scenes/main.tscn"):
		_game_scene = load("res://scenes/main.tscn")

func before_each() -> void:
	if _game_scene:
		_main = _game_scene.instantiate()
		add_child(_main)
		await get_tree().process_frame
		_main._start_new_game({"name": "TunnelTester"})
		await get_tree().process_frame

func after_each() -> void:
	if _main:
		_main.queue_free()
		_main = null
		await get_tree().process_frame

func _press_key(keycode: Key, shift: bool = false, physical_keycode: Key = KEY_NONE) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.echo = false
	ev.keycode = keycode
	ev.shift_pressed = shift
	ev.physical_keycode = physical_keycode
	return ev

func _find_cardinal_target(level: Level, origin: Vector2i) -> Dictionary:
	var options: Array[Dictionary] = [
		{"dir": Vector2i(0, -1), "physical": KEY_W},
		{"dir": Vector2i(0, 1), "physical": KEY_S},
		{"dir": Vector2i(-1, 0), "physical": KEY_A},
		{"dir": Vector2i(1, 0), "physical": KEY_D},
	]
	for opt: Dictionary in options:
		var pos: Vector2i = origin + opt["dir"]
		if level.is_in_bounds(pos):
			return {"target": pos, "dir": opt["dir"], "physical": int(opt["physical"])}
	return {}

func test_shift_t_then_physical_direction_starts_mining_on_rubble() -> void:
	if not _main:
		pending("Main scene failed to load")
		return
	if _main.player == null or _main.current_level == null:
		pending("Game world not initialized")
		return

	# Ensure tunnel capability and player turn.
	_main.player.equip_flags["TUNNEL"] = true
	GameManager.is_player_turn = true

	var choice: Dictionary = _find_cardinal_target(_main.current_level, _main.player.grid_position)
	if choice.is_empty():
		pending("No adjacent in-bounds tile found for tunneling test")
		return

	var target: Vector2i = choice["target"]
	_main.current_level.set_tile(target, Level.Tile.RUBBLE)

	# Step 1: enter tunneling prompt.
	var tunnel_event: InputEventKey = _press_key(KEY_T, true, KEY_T)
	_main._unhandled_input(tunnel_event)
	assert_true(_main._pending_tunnel, "Shift+T should enter tunnel direction prompt")

	# Step 2: provide direction via physical-key-only event (the regression case).
	var dir_event: InputEventKey = _press_key(KEY_NONE, true, choice["physical"])
	_main._unhandled_input(dir_event)

	assert_false(_main._pending_tunnel, "Directional input should close tunnel prompt")
	assert_true(_main._mining, "Directional input should start mining when rubble is adjacent")
	assert_eq(_main._mining_target, target, "Mining target should be the selected adjacent rubble tile")

