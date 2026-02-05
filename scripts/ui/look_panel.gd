extends Control
class_name LookPanel
## Look mode UI - displays information about entities and terrain at cursor position.

signal closed

var look_cursor: Vector2i = Vector2i.ZERO
var player: Player = null
var level: Level = null

@onready var info_label: RichTextLabel = $Panel/VBox/InfoLabel
@onready var cursor_sprite: Sprite2D = null

const TILE_SIZE: int = 64

func _ready() -> void:
	visible = false
	# Create cursor sprite
	cursor_sprite = Sprite2D.new()
	cursor_sprite.name = "LookCursor"
	cursor_sprite.z_index = 100
	# We'll set texture in open()

func open(player_ref: Player, level_ref: Level) -> void:
	player = player_ref
	level = level_ref
	look_cursor = player.grid_position
	visible = true

	# Create yellow selection box cursor
	_setup_cursor()
	_update_cursor_position()
	_update_info()
	grab_focus()

func close() -> void:
	visible = false
	if cursor_sprite and cursor_sprite.get_parent():
		cursor_sprite.get_parent().remove_child(cursor_sprite)
	closed.emit()

func _setup_cursor() -> void:
	# Create a simple colored square as cursor
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Draw yellow border
	for x in range(TILE_SIZE):
		img.set_pixel(x, 0, Color.YELLOW)
		img.set_pixel(x, 1, Color.YELLOW)
		img.set_pixel(x, TILE_SIZE - 1, Color.YELLOW)
		img.set_pixel(x, TILE_SIZE - 2, Color.YELLOW)
	for y in range(TILE_SIZE):
		img.set_pixel(0, y, Color.YELLOW)
		img.set_pixel(1, y, Color.YELLOW)
		img.set_pixel(TILE_SIZE - 1, y, Color.YELLOW)
		img.set_pixel(TILE_SIZE - 2, y, Color.YELLOW)

	cursor_sprite.texture = ImageTexture.create_from_image(img)
	cursor_sprite.centered = false

	# Add to level if not already
	if level and not cursor_sprite.get_parent():
		level.add_child(cursor_sprite)

func _update_cursor_position() -> void:
	if cursor_sprite:
		cursor_sprite.position = Vector2(look_cursor) * TILE_SIZE

func _update_info() -> void:
	if not level:
		info_label.text = "No level loaded."
		return

	var lines: Array[String] = []
	lines.append("[b]Look Mode[/b] (X to exit, arrows/WASD to move cursor)")
	lines.append("")

	# Position info
	lines.append("Position: (%d, %d)" % [look_cursor.x, look_cursor.y])

	# Check for entity at position
	var entity = level.get_entity_at(look_cursor)
	if entity:
		lines.append("")
		if entity is Player:
			lines.append("[color=cyan]You (%s)[/color]" % entity.entity_name)
			lines.append("HP: %d/%d" % [entity.current_health, entity.max_health])
		elif entity is Monster:
			_add_monster_info(entity, lines)

	# Check for items at position
	var items = level.get_items_at(look_cursor)
	if not items.is_empty():
		lines.append("")
		lines.append("[color=yellow]Items here:[/color]")
		for item in items:
			lines.append("  - %s" % item.get_display_name())

	# Terrain info
	var tile = level.get_tile(look_cursor)
	lines.append("")
	lines.append("[color=gray]Terrain: %s[/color]" % _get_terrain_name(tile))

	info_label.bbcode_enabled = true
	info_label.text = "\n".join(lines)

func _add_monster_info(monster: Monster, lines: Array[String]) -> void:
	# Try to get monster memory from main scene for knowledge-based display
	var main_scene = get_tree().current_scene
	var memory: RefCounted = null  # MonsterMemory
	if main_scene and main_scene.has_method("get_monster_memory"):
		memory = main_scene.get_monster_memory()

	# Get player's lore skill for bonus
	var player_lore: int = 0
	if player:
		player_lore = player.skills.get("lore", 0)

	# If we have monster memory, use knowledge-based display
	if memory:
		var info_lines: Array[String] = memory.format_monster_info_for_look(monster, player_lore)
		for line in info_lines:
			lines.append(line)
		return

	# Fallback to full info display (legacy behavior)
	_add_monster_info_full(monster, lines)

func _add_monster_info_full(monster: Monster, lines: Array[String]) -> void:
	# Monster name with color based on stance
	var color: String = "white"
	match monster.stance:
		Constants.Stance.AGGRESSIVE:
			color = "red"
		Constants.Stance.CONFIDENT:
			color = "orange"
		Constants.Stance.FLEEING:
			color = "gray"

	lines.append("[color=%s]%s[/color]" % [color, monster.entity_name])

	# Health bar
	var health_pct: float = float(monster.current_health) / float(monster.max_health)
	var health_color: String = "green"
	if health_pct < 0.3:
		health_color = "red"
	elif health_pct < 0.6:
		health_color = "yellow"
	lines.append("[color=%s]HP: %d/%d (%.0f%%)[/color]" % [health_color, monster.current_health, monster.max_health, health_pct * 100])

	# Alertness state
	var alert_str: String = "Unknown"
	var alert_color: String = "white"
	if monster.is_sleeping:
		alert_str = "Sleeping"
		alert_color = "blue"
	elif monster.alertness < Constants.ALERTNESS_UNWARY:
		alert_str = "Unwary"
		alert_color = "blue"
	elif monster.alertness >= Constants.ALERTNESS_ALERT:
		alert_str = "Alert"
		alert_color = "red"
	else:
		alert_str = "Cautious"
		alert_color = "yellow"
	lines.append("Alertness: [color=%s]%s[/color] (%d)" % [alert_color, alert_str, monster.alertness])

	# Stance/Morale
	lines.append("Stance: [color=%s]%s[/color] (morale: %d)" % [color, monster.get_stance_string(), monster.current_morale])

	# Combat stats
	lines.append("Speed: %d  |  Evasion: %+d  |  Melee: %+d" % [monster.speed, monster.evasion_bonus, monster.melee_bonus])

	# Protection
	if monster.protection_dice > 0:
		lines.append("Protection: %dd%d" % [monster.protection_dice, monster.protection_sides])

	# Damage
	if monster.damage_dice != "":
		lines.append("Damage: %s" % monster.damage_dice)

	# Flags of interest
	var flags: Array[String] = []
	if monster.is_unique:
		flags.append("UNIQUE")
	if monster.is_undead:
		flags.append("UNDEAD")
	if monster.is_dragon:
		flags.append("DRAGON")
	if monster.is_invisible:
		flags.append("INVISIBLE")
	if monster.is_mindless:
		flags.append("MINDLESS")
	if monster.is_cowardly:
		flags.append("COWARD")
	if monster.is_brave:
		flags.append("BRAVE")

	if not flags.is_empty():
		lines.append("Traits: %s" % ", ".join(flags))

func _get_terrain_name(tile: int) -> String:
	match tile:
		Level.Tile.VOID:
			return "Void"
		Level.Tile.FLOOR:
			return "Stone Floor"
		Level.Tile.WALL:
			return "Wall"
		Level.Tile.DOOR_CLOSED:
			return "Closed Door"
		Level.Tile.DOOR_OPEN:
			return "Open Door"
		Level.Tile.STAIRS_UP:
			return "Stairs Up"
		Level.Tile.STAIRS_DOWN:
			return "Stairs Down"
		Level.Tile.CHASM:
			return "Chasm"
		Level.Tile.RUBBLE:
			return "Rubble"
		Level.Tile.FORGE:
			return "Forge"
	return "Unknown"

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Close on X or Escape
	if event.is_action_pressed("look") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return

	# Move cursor with movement keys
	var moved: bool = false
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		look_cursor.y -= 1
		moved = true
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		look_cursor.y += 1
		moved = true
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		look_cursor.x -= 1
		moved = true
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		look_cursor.x += 1
		moved = true
	elif event.is_action_pressed("move_up_left"):
		look_cursor += Vector2i(-1, -1)
		moved = true
	elif event.is_action_pressed("move_up_right"):
		look_cursor += Vector2i(1, -1)
		moved = true
	elif event.is_action_pressed("move_down_left"):
		look_cursor += Vector2i(-1, 1)
		moved = true
	elif event.is_action_pressed("move_down_right"):
		look_cursor += Vector2i(1, 1)
		moved = true

	if moved:
		# Clamp to level bounds
		if level:
			look_cursor.x = clampi(look_cursor.x, 0, level.width - 1)
			look_cursor.y = clampi(look_cursor.y, 0, level.height - 1)
		_update_cursor_position()
		_update_info()
		get_viewport().set_input_as_handled()
