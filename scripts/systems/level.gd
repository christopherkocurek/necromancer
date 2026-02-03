extends Node2D
class_name Level
## Manages a dungeon level - terrain, entities, items, FOV.

signal generation_complete(width: int, height: int)

# Level dimensions
@export var width: int = 80
@export var height: int = 40
@export var depth: int = 1

# Tile data
var terrain: Array[int] = []  # Flat array, index = y * width + x
var explored: Array[bool] = []
var visible: Array[bool] = []

# Entities
var entities: Array[Entity] = []
var items_on_ground: Dictionary = {}  # Vector2i -> Array of items

# Tile types
enum Tile {
	VOID = 0,
	FLOOR = 1,
	WALL = 2,
	DOOR_CLOSED = 3,
	DOOR_OPEN = 4,
	STAIRS_DOWN = 5,
	STAIRS_UP = 6,
	CHASM = 7,
	RUBBLE = 8,
	FORGE = 9,
}

# Child nodes
@onready var terrain_layer: TileMapLayer = $TerrainLayer
@onready var entity_container: Node2D = $Entities
@onready var item_container: Node2D = $Items
@onready var effect_container: Node2D = $Effects

func _ready() -> void:
	_initialize_arrays()

func _initialize_arrays() -> void:
	var size := width * height
	terrain.resize(size)
	terrain.fill(Tile.VOID)
	explored.resize(size)
	explored.fill(false)
	visible.resize(size)
	visible.fill(false)

# ============================================================================
# TERRAIN ACCESS
# ============================================================================

func get_tile(pos: Vector2i) -> int:
	if not is_in_bounds(pos):
		return Tile.VOID
	return terrain[pos.y * width + pos.x]

func set_tile(pos: Vector2i, tile: int) -> void:
	if is_in_bounds(pos):
		terrain[pos.y * width + pos.x] = tile
		_update_tilemap_cell(pos, tile)

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func is_passable(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	match tile:
		Tile.FLOOR, Tile.DOOR_OPEN, Tile.STAIRS_DOWN, Tile.STAIRS_UP, Tile.RUBBLE:
			return true
		_:
			return false

func is_transparent(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	match tile:
		Tile.WALL, Tile.DOOR_CLOSED:
			return false
		_:
			return true

func is_explored(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	return explored[pos.y * width + pos.x]

func is_visible(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	return visible[pos.y * width + pos.x]

func set_explored(pos: Vector2i, value: bool = true) -> void:
	if is_in_bounds(pos):
		explored[pos.y * width + pos.x] = value

func set_visible(pos: Vector2i, value: bool) -> void:
	if is_in_bounds(pos):
		visible[pos.y * width + pos.x] = value
		if value:
			set_explored(pos, true)

# ============================================================================
# ENTITY MANAGEMENT
# ============================================================================

func add_entity(entity: Entity) -> void:
	entities.append(entity)
	entity_container.add_child(entity)

func remove_entity(entity: Entity) -> void:
	entities.erase(entity)
	if entity.get_parent() == entity_container:
		entity_container.remove_child(entity)

func get_entity_at(pos: Vector2i) -> Entity:
	for entity in entities:
		if entity.grid_position == pos and entity.is_alive:
			return entity
	return null

func get_entities_in_radius(center: Vector2i, radius: int) -> Array[Entity]:
	var result: Array[Entity] = []
	for entity in entities:
		if entity.is_alive:
			var dist := max(abs(entity.grid_position.x - center.x),
						   abs(entity.grid_position.y - center.y))
			if dist <= radius:
				result.append(entity)
	return result

func get_monsters() -> Array[Monster]:
	var monsters: Array[Monster] = []
	for entity in entities:
		if entity is Monster and entity.is_alive:
			monsters.append(entity)
	return monsters

# ============================================================================
# ITEM MANAGEMENT
# ============================================================================

func add_item_at(pos: Vector2i, item: Resource) -> void:
	if not items_on_ground.has(pos):
		items_on_ground[pos] = []
	items_on_ground[pos].append(item)

func get_items_at(pos: Vector2i) -> Array:
	return items_on_ground.get(pos, [])

func remove_item_at(pos: Vector2i, item: Resource) -> bool:
	if items_on_ground.has(pos):
		var items: Array = items_on_ground[pos]
		var idx := items.find(item)
		if idx >= 0:
			items.remove_at(idx)
			if items.is_empty():
				items_on_ground.erase(pos)
			return true
	return false

# ============================================================================
# TILEMAP RENDERING
# ============================================================================

func _update_tilemap_cell(pos: Vector2i, tile: int) -> void:
	if not terrain_layer:
		return

	# Map tile type to atlas coordinates
	var atlas_coords := _get_atlas_coords_for_tile(tile)
	terrain_layer.set_cell(pos, 0, atlas_coords)

func _get_atlas_coords_for_tile(tile: int) -> Vector2i:
	# Map tile types to positions in the 64x64 tileset
	# These will need to be adjusted based on your actual tileset layout
	match tile:
		Tile.VOID:
			return Vector2i(0, 0)
		Tile.FLOOR:
			return Vector2i(1, 2)  # Stone floor
		Tile.WALL:
			return Vector2i(0, 2)  # Stone wall
		Tile.DOOR_CLOSED:
			return Vector2i(2, 2)
		Tile.DOOR_OPEN:
			return Vector2i(3, 2)
		Tile.STAIRS_DOWN:
			return Vector2i(4, 2)
		Tile.STAIRS_UP:
			return Vector2i(5, 2)
		Tile.CHASM:
			return Vector2i(6, 2)
		Tile.RUBBLE:
			return Vector2i(7, 2)
		Tile.FORGE:
			return Vector2i(8, 2)
		_:
			return Vector2i(0, 0)

func rebuild_tilemap() -> void:
	if not terrain_layer:
		return

	terrain_layer.clear()
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var tile := get_tile(pos)
			_update_tilemap_cell(pos, tile)

# ============================================================================
# FOV
# ============================================================================

func update_fov(center: Vector2i, radius: int) -> void:
	# Clear visibility
	visible.fill(false)

	# Simple raycasting FOV
	for angle in range(360):
		var rad := deg_to_rad(angle)
		var dx := cos(rad)
		var dy := sin(rad)

		var x := float(center.x) + 0.5
		var y := float(center.y) + 0.5

		for _step in range(radius):
			var check_pos := Vector2i(int(x), int(y))

			if not is_in_bounds(check_pos):
				break

			set_visible(check_pos, true)

			if not is_transparent(check_pos):
				break

			x += dx
			y += dy

func update_entity_visibility() -> void:
	for entity in entities:
		if entity is Monster:
			entity.visible = is_visible(entity.grid_position)

# ============================================================================
# PATHFINDING
# ============================================================================

func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	# Simple A* implementation
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _heuristic(start, goal)}

	while not open_set.is_empty():
		# Find node with lowest f_score
		var current := open_set[0]
		var lowest_f := f_score.get(current, INF)
		for node in open_set:
			var f: float = f_score.get(node, INF)
			if f < lowest_f:
				current = node
				lowest_f = f

		if current == goal:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in _get_neighbors(current):
			var tentative_g: float = g_score.get(current, INF) + 1

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)

				if neighbor not in open_set:
					open_set.append(neighbor)

	return []  # No path found

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return float(max(abs(a.x - b.x), abs(a.y - b.y)))

func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions := [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]

	for dir in directions:
		var neighbor := pos + dir
		if is_passable(neighbor):
			neighbors.append(neighbor)

	return neighbors

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path

# ============================================================================
# FIND SPECIAL POSITIONS
# ============================================================================

func find_stairs_down() -> Vector2i:
	for y in range(height):
		for x in range(width):
			if get_tile(Vector2i(x, y)) == Tile.STAIRS_DOWN:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func find_stairs_up() -> Vector2i:
	for y in range(height):
		for x in range(width):
			if get_tile(Vector2i(x, y)) == Tile.STAIRS_UP:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func find_random_floor() -> Vector2i:
	var attempts := 1000
	while attempts > 0:
		var pos := Vector2i(randi_range(1, width - 2), randi_range(1, height - 2))
		if get_tile(pos) == Tile.FLOOR and get_entity_at(pos) == null:
			return pos
		attempts -= 1
	return Vector2i(-1, -1)
