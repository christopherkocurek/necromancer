class_name DirectionPrompt
extends RefCounted
## Handles directional input prompts for horns and other items that
## need the player to choose a direction before activating.
##
## Integration guide for main.gd:
##   In _unhandled_input(), BEFORE normal movement handling and BEFORE
##   the _is_ui_open() check, add this block:
##
##   # Horn directional prompt intercept
##   if ConsumableSystem.has_pending_horn():
##       if event is InputEventKey and event.pressed and not event.echo:
##           var horn_dir: Vector2i = DirectionPrompt.get_direction_from_event(event)
##           if horn_dir != Vector2i.ZERO:
##               if ConsumableSystem.complete_horn_use(horn_dir):
##                   player.consume_energy()
##               get_viewport().set_input_as_handled()
##               return
##           elif event.keycode == KEY_ESCAPE:
##               ConsumableSystem.cancel_horn_use()
##               get_viewport().set_input_as_handled()
##               return
##       return  # Block all other input while awaiting direction

## Map an InputEventKey to a direction vector. Returns Vector2i.ZERO if
## the key is not a recognized direction key.
static func get_direction_from_event(event: InputEventKey) -> Vector2i:
	if not event.pressed or event.echo:
		return Vector2i.ZERO

	# Check standard movement keys (matches the game's input bindings)
	match event.keycode:
		# Up / North
		KEY_W, KEY_K, KEY_UP, KEY_KP_8:
			return Vector2i(0, -1)
		# Down / South
		KEY_S, KEY_J, KEY_DOWN, KEY_KP_2:
			return Vector2i(0, 1)
		# Left / West
		KEY_A, KEY_H, KEY_LEFT, KEY_KP_4:
			return Vector2i(-1, 0)
		# Right / East
		KEY_D, KEY_L, KEY_RIGHT, KEY_KP_6:
			return Vector2i(1, 0)
		# Diagonals - NW
		KEY_Y, KEY_KP_7:
			return Vector2i(-1, -1)
		# NE
		KEY_U, KEY_KP_9:
			return Vector2i(1, -1)
		# SW
		KEY_B, KEY_KP_1:
			return Vector2i(-1, 1)
		# SE
		KEY_N, KEY_KP_3:
			return Vector2i(1, 1)

	return Vector2i.ZERO

## Get a human-readable name for a direction vector.
static func direction_name(dir: Vector2i) -> String:
	match dir:
		Vector2i(0, -1): return "north"
		Vector2i(0, 1): return "south"
		Vector2i(-1, 0): return "west"
		Vector2i(1, 0): return "east"
		Vector2i(-1, -1): return "northwest"
		Vector2i(1, -1): return "northeast"
		Vector2i(-1, 1): return "southwest"
		Vector2i(1, 1): return "southeast"
	return "unknown"
