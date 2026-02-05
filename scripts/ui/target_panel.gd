extends Control
class_name TargetPanel
## Target selection mode for archery, wands, and throwing.
## Moves a cursor on the map, confirms target with Enter.

signal target_selected(target_pos: Vector2i)
signal cancelled

var target_cursor: Vector2i = Vector2i.ZERO
var player: Player = null
var level: Level = null
var max_range: int = 20  # Maximum targeting range

@onready var info_label: RichTextLabel = $Panel/VBox/InfoLabel
var cursor_sprite: Sprite2D = null

const TILE_SIZE: int = 64

func _ready() -> void:
	visible = false
	cursor_sprite = Sprite2D.new()
	cursor_sprite.name = "TargetCursor"
	cursor_sprite.z_index = 100

func open(player_ref: Player, level_ref: Level, range_limit: int = 20) -> void:
	player = player_ref
	level = level_ref
	max_range = range_limit
	target_cursor = player.grid_position
	visible = true

	# Auto-target nearest visible monster
	_auto_target_nearest()

	_setup_cursor()
	_update_cursor_position()
	_update_info()
	grab_focus()

func close() -> void:
	visible = false
	if cursor_sprite and cursor_sprite.get_parent():
		cursor_sprite.get_parent().remove_child(cursor_sprite)

func _setup_cursor() -> void:
	# Create red targeting cursor (different from yellow look cursor)
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Draw red border with crosshair
	for x in range(TILE_SIZE):
		img.set_pixel(x, 0, Color.RED)
		img.set_pixel(x, 1, Color.RED)
		img.set_pixel(x, TILE_SIZE - 1, Color.RED)
		img.set_pixel(x, TILE_SIZE - 2, Color.RED)
	for y in range(TILE_SIZE):
		img.set_pixel(0, y, Color.RED)
		img.set_pixel(1, y, Color.RED)
		img.set_pixel(TILE_SIZE - 1, y, Color.RED)
		img.set_pixel(TILE_SIZE - 2, y, Color.RED)
	# Crosshair center lines
	var mid: int = TILE_SIZE / 2
	for x in range(TILE_SIZE / 4, 3 * TILE_SIZE / 4):
		img.set_pixel(x, mid, Color(1, 0, 0, 0.5))
	for y in range(TILE_SIZE / 4, 3 * TILE_SIZE / 4):
		img.set_pixel(mid, y, Color(1, 0, 0, 0.5))

	cursor_sprite.texture = ImageTexture.create_from_image(img)
	cursor_sprite.centered = false

	if level and not cursor_sprite.get_parent():
		level.add_child(cursor_sprite)

func _update_cursor_position() -> void:
	if cursor_sprite:
		cursor_sprite.position = Vector2(target_cursor) * TILE_SIZE

func _auto_target_nearest() -> void:
	if not level or not player:
		return
	var nearest: Entity = null
	var nearest_dist: int = 999
	for entity in level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		if not level.is_tile_visible(entity.grid_position):
			continue
		var dist: int = max(abs(entity.grid_position.x - player.grid_position.x),
						   abs(entity.grid_position.y - player.grid_position.y))
		if dist <= max_range and dist < nearest_dist:
			nearest = entity
			nearest_dist = dist
	if nearest:
		target_cursor = nearest.grid_position

func _update_info() -> void:
	if not level or not info_label:
		return

	var lines: Array[String] = []
	lines.append("[b]Target Mode[/b] (Enter=fire, Esc=cancel, arrows to aim)")
	lines.append("")

	# Distance
	var dist: int = max(abs(target_cursor.x - player.grid_position.x),
					   abs(target_cursor.y - player.grid_position.y))
	lines.append("Range: %d" % dist)

	# LOS check
	var has_los: bool = level.has_los_to(player.grid_position, target_cursor)
	if not has_los:
		lines.append("[color=red]No line of sight![/color]")

	# Entity at cursor
	var entity = level.get_entity_at(target_cursor)
	if is_instance_valid(entity) and entity is Monster:
		lines.append("")
		lines.append("[color=red]%s[/color]" % entity.entity_name)
		lines.append("HP: %d/%d" % [entity.current_health, entity.max_health])

	info_label.clear()
	info_label.append_text("\n".join(lines))

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		var dir := Vector2i.ZERO
		match event.keycode:
			KEY_UP, KEY_W, KEY_K: dir = Vector2i(0, -1)
			KEY_DOWN, KEY_S, KEY_J: dir = Vector2i(0, 1)
			KEY_LEFT, KEY_A, KEY_H: dir = Vector2i(-1, 0)
			KEY_RIGHT, KEY_D, KEY_L: dir = Vector2i(1, 0)
			KEY_Y: dir = Vector2i(-1, -1)
			KEY_U: dir = Vector2i(1, -1)
			KEY_B: dir = Vector2i(-1, 1)
			KEY_N: dir = Vector2i(1, 1)
			KEY_ENTER, KEY_KP_ENTER:
				_confirm_target()
				accept_event()
				return
			KEY_ESCAPE:
				close()
				cancelled.emit()
				accept_event()
				return
			KEY_TAB:
				_cycle_target()
				accept_event()
				return

		if dir != Vector2i.ZERO:
			var new_pos: Vector2i = target_cursor + dir
			var dist: int = max(abs(new_pos.x - player.grid_position.x),
							   abs(new_pos.y - player.grid_position.y))
			if level.is_in_bounds(new_pos) and dist <= max_range:
				target_cursor = new_pos
				_update_cursor_position()
				_update_info()
			accept_event()

func _confirm_target() -> void:
	# Verify LOS
	if not level.has_los_to(player.grid_position, target_cursor):
		GameManager.log_message("No line of sight to target!", Color.RED)
		return

	var dist: int = max(abs(target_cursor.x - player.grid_position.x),
					   abs(target_cursor.y - player.grid_position.y))
	if dist > max_range:
		GameManager.log_message("Target is out of range!", Color.RED)
		return

	close()
	target_selected.emit(target_cursor)

func _cycle_target() -> void:
	# Tab cycles through visible monsters
	if not level:
		return
	var monsters: Array = []
	for entity in level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		if level.is_tile_visible(entity.grid_position):
			monsters.append(entity)

	if monsters.is_empty():
		return

	# Find current target index and cycle to next
	var current_idx: int = -1
	for i in range(monsters.size()):
		if monsters[i].grid_position == target_cursor:
			current_idx = i
			break
	var next_idx: int = (current_idx + 1) % monsters.size()
	target_cursor = monsters[next_idx].grid_position
	_update_cursor_position()
	_update_info()
