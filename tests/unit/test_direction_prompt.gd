extends GutTest

func _key_event(physical: int, shift: bool = false) -> InputEventKey:
	var ev: InputEventKey = InputEventKey.new()
	ev.pressed = true
	ev.echo = false
	ev.keycode = KEY_NONE
	ev.physical_keycode = physical
	ev.shift_pressed = shift
	return ev

func test_direction_prompt_uses_action_map_physical_keys() -> void:
	var up_event: InputEventKey = _key_event(KEY_W)
	var down_event: InputEventKey = _key_event(KEY_S)
	var left_event: InputEventKey = _key_event(KEY_A)
	var right_event: InputEventKey = _key_event(KEY_D)

	assert_eq(DirectionPrompt.get_direction_from_event(up_event), Vector2i(0, -1))
	assert_eq(DirectionPrompt.get_direction_from_event(down_event), Vector2i(0, 1))
	assert_eq(DirectionPrompt.get_direction_from_event(left_event), Vector2i(-1, 0))
	assert_eq(DirectionPrompt.get_direction_from_event(right_event), Vector2i(1, 0))

func test_direction_prompt_allows_shifted_movement_keys() -> void:
	var shifted_up_event: InputEventKey = _key_event(KEY_W, true)
	assert_eq(DirectionPrompt.get_direction_from_event(shifted_up_event), Vector2i(0, -1))

