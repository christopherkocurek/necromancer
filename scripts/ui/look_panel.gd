extends Control
class_name LookPanel
## Look mode UI - displays information about entities and terrain at cursor position.

signal closed

var look_cursor: Vector2i = Vector2i.ZERO
var player: Player = null
var level: Level = null
var _marker_monster: Monster = null

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

	# Apply Diablo theme to look panel
	if has_node("Panel"):
		var p: Control = $Panel
		var style: StyleBox
		if ThemeColors.has_textures():
			style = ThemeColors.create_textured_panel("panel_iron", 8.0)
		else:
			style = ThemeColors.create_panel_stylebox(ThemeColors.IRON_DARK, ThemeColors.IRON_HIGHLIGHT, 2, 4)
		p.add_theme_stylebox_override("panel", style)

func open(player_ref: Player, level_ref: Level) -> void:
	player = player_ref
	level = level_ref
	look_cursor = player.grid_position
	PanelTransition.open_panel(self)

	# Create yellow selection box cursor
	_setup_cursor()
	_update_cursor_position()
	_update_info()
	ThemeColors.apply_rich_body_font(info_label)
	grab_focus()

func close() -> void:
	_clear_marker()
	if cursor_sprite and cursor_sprite.get_parent():
		cursor_sprite.get_parent().remove_child(cursor_sprite)
	PanelTransition.close_panel(self, func(): closed.emit())

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

	# Check for entity at position
	var entity = level.get_entity_at(look_cursor)
	_update_marker_for_entity(entity)
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

	# Terrain info with depth-scaled procedural description
	var tile: int = level.get_tile(look_cursor)
	lines.append("")
	lines.append("[color=gray]Terrain: %s[/color]" % _get_terrain_name(level, look_cursor, tile))
	var current_depth: int = GameManager.current_depth if GameManager else 1
	var desc_tile: int = tile
	if tile == Level.Tile.TRAP and level and level.has_method("is_trap_revealed") and not bool(level.is_trap_revealed(look_cursor)):
		desc_tile = Level.Tile.FLOOR
	var terrain_desc: String = DescriptionGenerator.generate_terrain_description_for_depth(desc_tile, current_depth)
	lines.append("[color=#7D7668][i]%s[/i][/color]" % terrain_desc)

	info_label.bbcode_enabled = true
	info_label.text = "\n".join(lines)

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
		if not info_lines.is_empty():
			lines.append(info_lines[0])  # Start from monster name/title.
			_append_intent_readout(monster, lines)
			for i in range(1, info_lines.size()):
				lines.append(info_lines[i])
		else:
			_append_intent_readout(monster, lines)
		return

	# Fallback to full info display (legacy behavior)
	_add_monster_info_full(monster, lines)
	_append_intent_readout(monster, lines)

func _append_intent_readout(monster: Monster, lines: Array[String]) -> void:
	if not player or not monster or not monster.has_method("get_intent_readout_for_viewer"):
		return
	var intent: Dictionary = monster.get_intent_readout_for_viewer(player)
	if intent.is_empty():
		return

	var intent_type: String = str(intent.get("type", "uncertain"))
	var attack_type: String = _intent_type_label(intent_type)
	var summary: String = str(intent.get("summary", "Unknown"))
	var detail: String = str(intent.get("detail", ""))
	var certainty: String = str(intent.get("certainty", ""))
	var targets_player: bool = bool(intent.get("targets_player", false))
	var eta: int = int(intent.get("eta", 1))
	lines.append("")
	lines.append("[color=#FCD34D][b]TACTICAL READ[/b][/color]")
	lines.append("[color=#FCD34D]Attack type:[/color] %s" % attack_type)
	lines.append("[color=#F59E0B]Intent:[/color] %s" % summary)
	lines.append("[color=#D1D5DB]Target:[/color] %s  [color=#D1D5DB]ETA:[/color] %s" % [
		"You" if targets_player else "Other",
		"Now" if eta <= 0 else str(eta)
	])
	if not detail.is_empty():
		lines.append("[color=#9CA3AF]%s[/color]" % detail)
	if not certainty.is_empty():
		lines.append("[color=#6B7280]Read: %s[/color]" % certainty)

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

func _get_terrain_name(level: Level, pos: Vector2i, tile: int) -> String:
	if tile == Level.Tile.TRAP and level and level.has_method("is_trap_revealed") and not bool(level.is_trap_revealed(pos)):
		return "Stone Floor"
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
		Level.Tile.FORGE_ENCHANTED:
			return "Enchanted Forge"
		Level.Tile.FORGE_UNIQUE:
			return "Unique Forge"
		Level.Tile.TRAP:
			return "Trap"
		Level.Tile.TRAP_TRIGGERED:
			return "Triggered Trap"
		Level.Tile.DOOR_LOCKED:
			return "Locked Door"
		Level.Tile.DOOR_JAMMED:
			return "Jammed Door"
		Level.Tile.DOOR_SECRET:
			return "Secret Door"
		Level.Tile.WATER:
			return "Water"
		Level.Tile.LAVA:
			return "Lava"
		Level.Tile.VINE_FLOOR:
			return "Vine Floor"
		Level.Tile.POISON_STREAM:
			return "Poison Stream"
		Level.Tile.WEB:
			return "Spider Web"
		Level.Tile.DARK_POOL:
			return "Dark Pool"
		Level.Tile.MORGUL_RUNE:
			return "Morgul Rune"
		Level.Tile.SHADOW_BRAZIER:
			return "Shadow Brazier"
		Level.Tile.GLYPH_OF_WARDING:
			return "Glyph of Warding"
		Level.Tile.BONE_PILE:
			return "Bone Pile"
		Level.Tile.SHADOW_FLOOR:
			return "Shadow Floor"
		Level.Tile.THRONE_DAIS:
			return "Throne Dais"
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
