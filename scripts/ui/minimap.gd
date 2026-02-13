extends TextureRect
class_name Minimap
## Minimap renderer - generates a 2px-per-tile overhead view of the dungeon.
## Shows walls, floors, doors, stairs, player (white), monsters (red), items (yellow).
## Updated once per turn, not per frame.

signal minimap_clicked

const TILE_PX: int = 2  # Pixels per tile

var level: Level = null
var player: Player = null
var _image: Image = null
var _dirty: bool = true

# Color palette
const COL_VOID := Color(0, 0, 0, 0)
const COL_WALL := Color(0.35, 0.35, 0.4, 1.0)
const COL_FLOOR := Color(0.18, 0.18, 0.22, 1.0)
const COL_FLOOR_EXPLORED := Color(0.12, 0.12, 0.15, 1.0)
const COL_DOOR := Color(0.55, 0.40, 0.25, 1.0)
const COL_STAIRS_DOWN := Color(0.3, 0.5, 0.8, 1.0)
const COL_STAIRS_UP := Color(0.3, 0.8, 0.5, 1.0)
const COL_PLAYER := Color(1, 1, 1, 1)
const COL_MONSTER := Color(0.9, 0.2, 0.2, 1.0)
const COL_ITEM := Color(0.9, 0.8, 0.2, 1.0)
const COL_WATER := Color(0.2, 0.3, 0.6, 0.8)
const COL_LAVA := Color(0.8, 0.3, 0.1, 0.9)
const COL_FORGE := Color(0.8, 0.5, 0.2, 1.0)
const COL_TRAP := Color(0.7, 0.2, 0.5, 0.8)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	custom_minimum_size = Vector2(160, 80)
	visible = false  # Hidden until set_level is called

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			minimap_clicked.emit()
			accept_event()

func set_display_size(size_px: Vector2) -> void:
	custom_minimum_size = size_px
	size = size_px

func set_level(new_level: Level) -> void:
	level = new_level
	if level:
		_image = Image.create(level.width * TILE_PX, level.height * TILE_PX, false, Image.FORMAT_RGBA8)
		_dirty = true
		visible = true
	else:
		visible = false

func set_player(new_player: Player) -> void:
	player = new_player

func mark_dirty() -> void:
	_dirty = true

func refresh() -> void:
	if not _dirty or not level or not _image:
		return
	_dirty = false

	_image.fill(COL_VOID)

	# Draw terrain
	for y in range(level.height):
		for x in range(level.width):
			var pos := Vector2i(x, y)
			if not level.is_explored(pos):
				continue

			var tile: int = level.get_tile(pos)
			var is_visible: bool = level.is_tile_visible(pos)
			var col: Color = _tile_color(pos, tile, is_visible)

			# Draw 2x2 pixel block
			var px: int = x * TILE_PX
			var py: int = y * TILE_PX
			for dx in range(TILE_PX):
				for dy in range(TILE_PX):
					_image.set_pixel(px + dx, py + dy, col)

	# Draw items (visible only)
	for item_node in level.items:
		if not is_instance_valid(item_node):
			continue
		var ipos: Vector2i = item_node.grid_position if "grid_position" in item_node else Vector2i(-1, -1)
		if ipos.x >= 0 and level.is_tile_visible(ipos):
			_draw_dot(ipos, COL_ITEM)

	# Draw entities (visible monsters)
	for entity in level.entities:
		if not is_instance_valid(entity) or not entity.is_alive:
			continue
		if entity is Player:
			continue
		if level.is_tile_visible(entity.grid_position):
			_draw_dot(entity.grid_position, COL_MONSTER)

	# Draw player on top
	if player and is_instance_valid(player):
		_draw_dot(player.grid_position, COL_PLAYER)

	# Update texture
	texture = ImageTexture.create_from_image(_image)

func _draw_dot(pos: Vector2i, col: Color) -> void:
	var px: int = pos.x * TILE_PX
	var py: int = pos.y * TILE_PX
	for dx in range(TILE_PX):
		for dy in range(TILE_PX):
			if px + dx < _image.get_width() and py + dy < _image.get_height():
				_image.set_pixel(px + dx, py + dy, col)

func _tile_color(pos: Vector2i, tile: int, is_visible: bool) -> Color:
	match tile:
		Level.Tile.VOID:
			return COL_VOID
		Level.Tile.WALL:
			return COL_WALL if is_visible else COL_WALL * Color(0.5, 0.5, 0.5, 1.0)
		Level.Tile.FLOOR:
			return COL_FLOOR if is_visible else COL_FLOOR_EXPLORED
		Level.Tile.DOOR_CLOSED, Level.Tile.DOOR_OPEN, Level.Tile.DOOR_LOCKED, Level.Tile.DOOR_JAMMED, Level.Tile.DOOR_SECRET:
			return COL_DOOR if is_visible else COL_DOOR * Color(0.5, 0.5, 0.5, 1.0)
		Level.Tile.STAIRS_DOWN:
			return COL_STAIRS_DOWN
		Level.Tile.STAIRS_UP:
			return COL_STAIRS_UP
		Level.Tile.WATER:
			return COL_WATER
		Level.Tile.LAVA:
			return COL_LAVA
		Level.Tile.FORGE, Level.Tile.FORGE_ENCHANTED, Level.Tile.FORGE_UNIQUE:
			return COL_FORGE
		Level.Tile.TRAP:
			if level and level.has_method("is_trap_revealed") and bool(level.is_trap_revealed(pos)):
				return COL_TRAP if is_visible else COL_FLOOR_EXPLORED
			return COL_FLOOR if is_visible else COL_FLOOR_EXPLORED
		Level.Tile.TRAP_TRIGGERED:
			return COL_TRAP if is_visible else COL_FLOOR_EXPLORED
		Level.Tile.RUBBLE:
			return COL_FLOOR if is_visible else COL_FLOOR_EXPLORED
		Level.Tile.CHASM:
			return COL_VOID
		_:
			return COL_FLOOR if is_visible else COL_FLOOR_EXPLORED
