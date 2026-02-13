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
var _marker_monster: Monster = null

@onready var info_label: RichTextLabel = $Panel/VBox/InfoLabel
var cursor_sprite: Sprite2D = null

const TILE_SIZE: int = 64

func _ready() -> void:
	visible = false
	cursor_sprite = Sprite2D.new()
	cursor_sprite.name = "TargetCursor"
	cursor_sprite.z_index = 100

	if has_node("Panel"):
		var p: Control = $Panel
		var style: StyleBox
		if ThemeColors.has_textures():
			style = ThemeColors.create_textured_panel("panel_iron", 8.0)
		else:
			style = ThemeColors.create_panel_stylebox(ThemeColors.IRON_DARK, ThemeColors.IRON_HIGHLIGHT, 2, 4)
		p.add_theme_stylebox_override("panel", style)
	if info_label:
		ThemeColors.apply_rich_body_font(info_label)

func open(player_ref: Player, level_ref: Level, range_limit: int = 20) -> void:
	player = player_ref
	level = level_ref
	max_range = range_limit
	target_cursor = player.grid_position
	PanelTransition.open_panel(self)

	# Auto-target nearest visible monster
	_auto_target_nearest()

	_setup_cursor()
	_update_cursor_position()
	_update_info()
	grab_focus()

func close() -> void:
	_clear_marker()
	if cursor_sprite and cursor_sprite.get_parent():
		cursor_sprite.get_parent().remove_child(cursor_sprite)
	PanelTransition.close_panel(self)

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
	lines.append("[b]Target Mode[/b] (Enter/F=fire, Esc=cancel, arrows to aim)")
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
	_update_marker_for_entity(entity)
	if is_instance_valid(entity) and entity is Monster:
		lines.append("")
		lines.append("[color=red]%s[/color]" % entity.entity_name)
		lines.append("HP: %d/%d" % [entity.current_health, entity.max_health])
		if player and entity.has_method("get_intent_readout_for_viewer"):
			var intent: Dictionary = entity.get_intent_readout_for_viewer(player)
			var intent_type: String = str(intent.get("type", "uncertain"))
			var attack_type: String = _intent_type_label(intent_type)
			var summary: String = str(intent.get("summary", "Unknown"))
			var detail: String = str(intent.get("detail", ""))
			var targets_player: bool = bool(intent.get("targets_player", false))
			var eta: int = int(intent.get("eta", 1))
			lines.append("[color=#FCD34D][b]TACTICAL READ[/b][/color]")
			lines.append("[color=#FCD34D]Attack type:[/color] %s" % attack_type)
			lines.append("[color=#F59E0B]Intent:[/color] %s" % summary)
			lines.append("[color=#D1D5DB]Target:[/color] %s  [color=#D1D5DB]ETA:[/color] %s" % [
				"You" if targets_player else "Other",
				"Now" if eta <= 0 else str(eta)
			])
			if not detail.is_empty():
				lines.append("[color=#9CA3AF]%s[/color]" % detail)
			lines.append(_format_threat_line(intent))
	else:
		lines.append("")
		lines.append("[color=#9CA3AF]No hostile target selected.[/color]")

	info_label.clear()
	info_label.append_text("\n".join(lines))

func _update_marker_for_entity(entity: Entity) -> void:
	if _marker_monster and is_instance_valid(_marker_monster):
		_marker_monster.clear_intent_marker()
	_marker_monster = null
	if not entity or not entity is Monster:
		return
	var mon: Monster = entity as Monster
	if not mon.has_method("get_intent_readout_for_viewer") or not mon.has_method("set_intent_marker_from_readout"):
		return
	var intent: Dictionary = mon.get_intent_readout_for_viewer(player)
	mon.set_intent_marker_from_readout(intent)
	_marker_monster = mon

func _clear_marker() -> void:
	if _marker_monster and is_instance_valid(_marker_monster):
		_marker_monster.clear_intent_marker()
	_marker_monster = null

func _format_threat_line(intent: Dictionary) -> String:
	var intent_type: String = str(intent.get("type", "uncertain"))
	var eta: int = int(intent.get("eta", 1))
	var targets_player: bool = bool(intent.get("targets_player", false))
	var level_str: String = "Low"
	var color: String = "#6B7280"

	if targets_player and eta <= 0:
		if intent_type == "cast" or intent_type == "ranged":
			level_str = "Severe"
			color = "#EF4444"
		elif intent_type == "melee":
			level_str = "High"
			color = "#F97316"
	elif targets_player:
		level_str = "Elevated"
		color = "#F59E0B"

	return "[color=%s]Threat: %s[/color]" % [color, level_str]

func _intent_type_label(intent_type: String) -> String:
	match intent_type:
		"melee":
			return "Melee"
		"ranged":
			return "Ranged"
		"cast":
			return "Spell"
		"move":
			return "Movement pressure"
		"flee":
			return "Retreat"
		"idle":
			return "Idle"
		_:
			return "Unknown"

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
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
			KEY_ENTER, KEY_KP_ENTER, KEY_F:
				_confirm_target()
				get_viewport().set_input_as_handled()
				return
			KEY_ESCAPE:
				close()
				cancelled.emit()
				get_viewport().set_input_as_handled()
				return
			KEY_TAB:
				_cycle_target()
				get_viewport().set_input_as_handled()
				return

		if dir != Vector2i.ZERO:
			var new_pos: Vector2i = target_cursor + dir
			var dist: int = max(abs(new_pos.x - player.grid_position.x),
							   abs(new_pos.y - player.grid_position.y))
			if level.is_in_bounds(new_pos) and dist <= max_range:
				target_cursor = new_pos
				_update_cursor_position()
				_update_info()
			get_viewport().set_input_as_handled()

func _confirm_target() -> void:
	# Verify LOS
	if not level.has_los_to(player.grid_position, target_cursor):
		GameManager.log_message("No line of sight to target!", ThemeColors.MSG_ERROR)
		return

	var dist: int = max(abs(target_cursor.x - player.grid_position.x),
					   abs(target_cursor.y - player.grid_position.y))
	if dist > max_range:
		GameManager.log_message("Target is out of range!", ThemeColors.MSG_ERROR)
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
