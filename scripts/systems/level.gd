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
var tile_visibility: Array[bool] = []
var room_lit: Array[bool] = []       # True if tile is in a lit room (CAVE_GLOW equivalent)
var room_id: Array[int] = []         # Which room each tile belongs to (-1 = none/corridor)
var rooms: Array[Rect2i] = []        # Room rectangles from generation
var tile_in_fov: Array[bool] = []    # Geometric line of sight (FOV only, before lighting)
var tile_lit: Array[bool] = []       # Has light (player torch + room glow)

# Entities
var entities: Array[Entity] = []
var items: Array = []  # Item nodes on the ground

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
	TRAP = 10,           # Generic trap - deals damage when stepped on
	TRAP_TRIGGERED = 11,  # Trap that has already been triggered
	DOOR_LOCKED = 12,    # Locked door - requires key or lockpicking
	DOOR_JAMMED = 13,    # Jammed/stuck door - requires STR check to bash
	DOOR_SECRET = 14,    # Secret door - looks like wall until discovered
	WATER = 15,          # Shallow water - passable, slows movement
	LAVA = 16,           # Lava - passable but deals fire damage on step
}

# Track which traps have been triggered (to avoid re-triggering)
var triggered_traps: Dictionary = {}  # Vector2i -> bool

# Trap types stored per position
enum TrapType {
	BASIC = 0,      # 1d4+depth/3 damage
	PIT = 1,        # 2d4 damage, stuck 1 turn
	DART = 2,       # 1d6 + poison
	GAS = 3,        # Confusion 3-5 turns
	ALARM = 4,      # Raises floor alertness +15
	TELEPORT = 5,   # Random teleport
	FLASH = 6,      # Blind 3-5 turns
	CALTROPS = 7,   # 1d4 + slow 3 turns
	WEB = 8,        # Slow 5 turns
}
var trap_types: Dictionary = {}  # Vector2i -> TrapType

# Secret door tracking
var secret_doors: Dictionary = {}  # Vector2i -> bool (true if still hidden)

# Floor-wide alertness (Phase B: Stealth)
var floor_alertness: int = 0  # 0-50+, rises with noise, decays over time

# Child nodes
@onready var terrain_layer: TileMapLayer = $TerrainLayer
@onready var entity_container: Node2D = $Entities
@onready var item_container: Node2D = $Items
@onready var effect_container: Node2D = $Effects

func _ready() -> void:
	_initialize_arrays()
	_apply_layer_tint_shader()

func _initialize_arrays() -> void:
	var size := width * height
	terrain.resize(size)
	terrain.fill(Tile.VOID)
	explored.resize(size)
	explored.fill(false)
	tile_visibility.resize(size)
	tile_visibility.fill(false)
	room_lit.resize(size)
	room_lit.fill(false)
	room_id.resize(size)
	room_id.fill(-1)
	tile_in_fov.resize(size)
	tile_in_fov.fill(false)
	tile_lit.resize(size)
	tile_lit.fill(false)

func _apply_layer_tint_shader() -> void:
	if terrain_layer:
		# Use layer tint shader which includes magenta transparency
		var shader_material: ShaderMaterial = load("res://assets/shaders/layer_tint.tres")
		# Clone the material so each level can have its own tint settings
		shader_material = shader_material.duplicate()
		terrain_layer.material = shader_material
		# Apply initial tint based on depth
		update_layer_tint()

## Update the layer tint based on current depth
func update_layer_tint() -> void:
	if not terrain_layer or not terrain_layer.material:
		return

	var shader_mat := terrain_layer.material as ShaderMaterial
	if shader_mat:
		var tint_color := LayerConfig.get_tint_color(depth)
		var tint_strength := LayerConfig.get_tint_strength(depth)
		shader_mat.set_shader_parameter("tint_color", tint_color)
		shader_mat.set_shader_parameter("tint_strength", tint_strength)

## Get the max FOV radius for this level's depth (layer-based cap)
func get_fov_radius() -> int:
	return LayerConfig.get_fov_radius(depth)

## Get effective FOV radius - always returns geometric max; lighting handled separately
func get_effective_fov_radius(_player_light: int) -> int:
	return get_fov_radius()

# ============================================================================
# TERRAIN ACCESS
# ============================================================================

func get_tile(pos: Vector2i) -> int:
	if not is_in_bounds(pos):
		return Tile.VOID
	return terrain[pos.y * width + pos.x]

var _set_tile_debug_count := 0

func set_tile(pos: Vector2i, tile: int) -> void:
	if is_in_bounds(pos):
		terrain[pos.y * width + pos.x] = tile
		if _set_tile_debug_count < 10:
			var atlas_coords := TileMapper.get_terrain_coords(tile)
			print("set_tile: pos=", pos, " tile=", Tile.keys()[tile], " atlas=", atlas_coords)
			_set_tile_debug_count += 1
		_update_tilemap_cell(pos, tile)

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func is_passable(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	match tile:
		Tile.FLOOR, Tile.DOOR_OPEN, Tile.STAIRS_DOWN, Tile.STAIRS_UP, Tile.RUBBLE, Tile.TRAP, Tile.TRAP_TRIGGERED, Tile.WATER, Tile.LAVA, Tile.FORGE:
			return true
		_:
			return false

## Get movement energy cost for a tile (water costs double)
func get_movement_cost(pos: Vector2i) -> int:
	var tile := get_tile(pos)
	if tile == Tile.WATER:
		return Constants.ACTION_COST * 2  # Double energy cost to wade
	return Constants.ACTION_COST

## Called when an entity steps on a tile. Returns true if something happened.
func on_entity_step(entity: Entity, pos: Vector2i) -> bool:
	var tile := get_tile(pos)

	if tile == Tile.TRAP and not triggered_traps.has(pos):
		return _trigger_trap(entity, pos)

	if tile == Tile.LAVA:
		return _lava_damage(entity, pos)

	if tile == Tile.WATER and entity is Player:
		GameManager.log_message("You wade through shallow water.", ThemeColors.SECONDARY)

	return false

func _trigger_trap(entity: Entity, pos: Vector2i) -> bool:
	# Check for Perception to potentially spot and avoid (50% + Per*5%)
	var avoid_chance: int = 50
	if is_instance_valid(entity) and entity.has_method("get_skill"):
		var perception: int = entity.get_skill("perception")
		avoid_chance += perception * 5

	# Roll to avoid — trap stays active if avoided
	if randi_range(1, 100) <= avoid_chance:
		if entity == GameManager.player:
			GameManager.log_message("You notice a trap and step carefully over it.", ThemeColors.MSG_WARNING)
		return true

	# Mark trap as triggered only after failing to avoid
	triggered_traps[pos] = true
	set_tile(pos, Tile.TRAP_TRIGGERED)

	# Get trap type for this position
	var trap_type: int = trap_types.get(pos, TrapType.BASIC)
	_resolve_trap_effect(entity, trap_type, pos)
	return true

func _resolve_trap_effect(entity: Entity, trap_type: int, _pos: Vector2i) -> void:
	if not is_instance_valid(entity):
		return

	var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
	var verb: String = "trigger" if entity == GameManager.player else "triggers"

	match trap_type:
		TrapType.BASIC:
			var dmg: int = randi_range(1, 4) + depth / 3
			entity.take_damage(dmg, "physical", null)
			GameManager.log_message("%s %s a trap! (%d damage)" % [entity_name, verb, dmg], ThemeColors.MSG_ERROR)

		TrapType.PIT:
			var dmg: int = randi_range(2, 8)  # 2d4
			entity.take_damage(dmg, "physical", null)
			entity.apply_status("stunned", 1)
			GameManager.log_message("%s %s into a pit! (%d damage)" % [entity_name, "fall" if entity == GameManager.player else "falls", dmg], ThemeColors.MSG_ERROR)

		TrapType.DART:
			var dmg: int = randi_range(1, 6)
			entity.take_damage(dmg, "physical", null)
			entity.apply_status("poisoned", 5 + randi_range(1, 5))
			GameManager.log_message("%s %s a dart trap! (%d damage, poisoned)" % [entity_name, verb, dmg], ThemeColors.MSG_ERROR)

		TrapType.GAS:
			entity.apply_status("confused", 3 + randi_range(0, 2))
			GameManager.log_message("A cloud of gas engulfs %s!" % entity_name.to_lower(), ThemeColors.STATUS_CONFUSED)

		TrapType.ALARM:
			add_floor_noise(15)
			GameManager.log_message("An alarm sounds! The dungeon stirs...", ThemeColors.COMBAT_CRIT)

		TrapType.TELEPORT:
			var new_pos: Vector2i = find_random_floor()
			if new_pos != Vector2i(-1, -1) and entity.has_method("teleport_to"):
				entity.teleport_to(new_pos)
				GameManager.log_message("%s %s teleported!" % [entity_name, "are" if entity == GameManager.player else "is"], ThemeColors.MSG_INFO)

		TrapType.FLASH:
			entity.apply_status("blind", 3 + randi_range(0, 2))
			GameManager.log_message("A blinding flash of light!", ThemeColors.MSG_WARNING)

		TrapType.CALTROPS:
			var dmg: int = randi_range(1, 4)
			entity.take_damage(dmg, "physical", null)
			entity.apply_status("slow", 3)
			GameManager.log_message("%s %s caltrops! (%d damage, slowed)" % [entity_name, "step on" if entity == GameManager.player else "steps on", dmg], ThemeColors.MSG_ERROR)

		TrapType.WEB:
			entity.apply_status("slow", 5)
			GameManager.log_message("%s %s caught in a web!" % [entity_name, "are" if entity == GameManager.player else "is"], ThemeColors.MSG_WARNING)

func _lava_damage(entity: Entity, _pos: Vector2i) -> bool:
	if not is_instance_valid(entity):
		return false
	var dmg: int = randi_range(2, 8) + depth / 2  # 2d4 + depth/2
	entity.take_damage(dmg, "fire", null)
	var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
	var verb: String = "burn" if entity == GameManager.player else "burns"
	GameManager.log_message("%s %s in the lava! (%d fire damage)" % [entity_name, verb, dmg], ThemeColors.COMBAT_CRIT)
	return true

func is_transparent(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	match tile:
		Tile.WALL, Tile.DOOR_CLOSED, Tile.DOOR_LOCKED, Tile.DOOR_JAMMED, Tile.DOOR_SECRET:
			return false
		_:
			return true

func is_explored(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	return explored[pos.y * width + pos.x]

func is_tile_visible(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	return tile_visibility[pos.y * width + pos.x]

func set_explored(pos: Vector2i, value: bool = true) -> void:
	if is_in_bounds(pos):
		explored[pos.y * width + pos.x] = value

func set_tile_visible(pos: Vector2i, value: bool) -> void:
	if is_in_bounds(pos):
		tile_visibility[pos.y * width + pos.x] = value
		if value:
			set_explored(pos, true)

func is_room_lit(pos: Vector2i) -> bool:
	if not is_in_bounds(pos): return false
	return room_lit[pos.y * width + pos.x]

func get_room_id(pos: Vector2i) -> int:
	if not is_in_bounds(pos): return -1
	return room_id[pos.y * width + pos.x]

func set_room_lit_by_rect(rect: Rect2i, lit: bool) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if is_in_bounds(Vector2i(x, y)):
				room_lit[y * width + x] = lit

func set_room_id_by_rect(rect: Rect2i, id: int) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if is_in_bounds(Vector2i(x, y)):
				room_id[y * width + x] = id

# ============================================================================
# ENTITY MANAGEMENT
# ============================================================================

func add_entity(entity: Entity) -> void:
	entities.append(entity)
	entity_container.add_child(entity)
	# Auto-remove from entities array when entity dies
	if not entity.died.is_connected(_on_entity_died):
		entity.died.connect(_on_entity_died.bind(entity))

func remove_entity(entity: Entity) -> void:
	entities.erase(entity)
	if entity.get_parent() == entity_container:
		entity_container.remove_child(entity)

func _on_entity_died(killer: Entity, entity: Entity) -> void:
	# Remove from entities array immediately when entity dies
	# This prevents "freed instance" errors when iterating entities
	if is_instance_valid(entity) and entity in entities:
		entities.erase(entity)

func get_entity_at(pos: Vector2i) -> Entity:
	for entity in entities:
		if is_instance_valid(entity) and entity.grid_position == pos and entity.is_alive:
			return entity
	return null

func get_entities_in_radius(center: Vector2i, radius: int) -> Array[Entity]:
	var result: Array[Entity] = []
	for entity in entities:
		if is_instance_valid(entity) and entity.is_alive:
			var dist: int = max(abs(entity.grid_position.x - center.x),
						   abs(entity.grid_position.y - center.y))
			if dist <= radius:
				result.append(entity)
	return result

func get_monsters() -> Array[Monster]:
	var monsters: Array[Monster] = []
	for entity in entities:
		if is_instance_valid(entity) and entity is Monster and entity.is_alive:
			monsters.append(entity)
	return monsters

# ============================================================================
# ITEM MANAGEMENT
# ============================================================================

func add_item(item: Item) -> void:
	items.append(item)
	item_container.add_child(item)

func remove_item(item: Item) -> void:
	items.erase(item)
	if item.get_parent() == item_container:
		item_container.remove_child(item)

func get_items_at(pos: Vector2i) -> Array[Item]:
	var result: Array[Item] = []
	for item in items:
		if item.grid_position == pos:
			result.append(item)
	return result

func remove_item_at(pos: Vector2i, item: Item) -> bool:
	if item in items and item.grid_position == pos:
		remove_item(item)
		return true
	return false

# ============================================================================
# TILEMAP RENDERING
# ============================================================================

func _update_tilemap_cell(pos: Vector2i, tile: int) -> void:
	if not terrain_layer:
		return

	# Map tile type to atlas coordinates (default to lit for set_tile calls)
	var atlas_coords := _get_atlas_coords_for_tile(tile, true)
	terrain_layer.set_cell(pos, 0, atlas_coords)

func _get_atlas_coords_for_tile(tile: int, lit: bool = true) -> Vector2i:
	# Use TileMapper to get atlas coordinates directly from tile enum
	return TileMapper.get_terrain_coords(tile, lit)

func rebuild_tilemap() -> void:
	if not terrain_layer:
		return

	terrain_layer.clear()
	var debug_count := 0
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var tile := get_tile(pos)
			if debug_count < 5:
				var atlas_coords := TileMapper.get_terrain_coords(tile)
				print("Tile at ", pos, ": ", Tile.keys()[tile], " atlas=", atlas_coords)
				debug_count += 1
			_update_tilemap_cell(pos, tile)

# ============================================================================
# FOV
# ============================================================================

func update_fov(center: Vector2i, radius: int) -> void:
	# Clear visibility and FOV arrays
	tile_visibility.fill(false)
	tile_in_fov.fill(false)
	tile_lit.fill(false)

	# Geometric raycasting FOV - writes to tile_in_fov only
	for angle in range(360):
		var rad := deg_to_rad(angle)
		var dx := cos(rad)
		var dy := sin(rad)

		var x := float(center.x) + 0.5
		var y := float(center.y) + 0.5

		for _step in range(radius + 1):  # +1: range(8) only reaches 7 tiles
			var check_pos := Vector2i(int(x), int(y))

			if not is_in_bounds(check_pos):
				break

			var idx: int = check_pos.y * width + check_pos.x
			tile_in_fov[idx] = true

			if not is_transparent(check_pos):
				break

			x += dx
			y += dy

## Apply lighting pass: combines player torch radius with room glow
func apply_lighting(center: Vector2i, player_light_radius: int) -> void:
	var arr_size: int = width * height

	# Step 1: Find which lit rooms are visible in FOV
	var lit_rooms_seen: Dictionary = {}
	for i in range(arr_size):
		if tile_in_fov[i] and room_lit[i]:
			var rid: int = room_id[i]
			if rid >= 0:
				lit_rooms_seen[rid] = true

	# Step 2: Single pass - determine lighting and final visibility
	for i in range(arr_size):
		if not tile_in_fov[i]:
			continue

		var tx: int = i % width
		var ty: int = i / width
		var dist: int = maxi(absi(tx - center.x), absi(ty - center.y))

		# Lit by player torch?
		var is_lit: bool = dist <= player_light_radius
		# Lit by room glow?
		if not is_lit:
			var rid: int = room_id[i]
			if rid >= 0 and lit_rooms_seen.has(rid):
				is_lit = true

		tile_lit[i] = is_lit
		if is_lit:
			tile_visibility[i] = true
			explored[i] = true

func update_entity_visibility() -> void:
	for entity in entities:
		if is_instance_valid(entity) and entity is Monster:
			entity.visible = is_tile_visible(entity.grid_position)
	for item in items:
		if is_instance_valid(item):
			item.visible = is_tile_visible(item.grid_position)

## Refresh tilemap after FOV update: lit tiles use light atlas, explored use dark, unexplored = darkness tile
func apply_fov_to_tilemap() -> void:
	if not terrain_layer:
		return
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var idx: int = y * width + x
			var tile: int = terrain[idx]
			if tile == Tile.VOID:
				terrain_layer.erase_cell(pos)
				continue
			if tile_visibility[idx]:
				# Currently visible — lit variant
				var atlas_coords := _get_atlas_coords_for_tile(tile, true)
				terrain_layer.set_cell(pos, 0, atlas_coords)
			elif explored[idx]:
				# Explored but not visible — dark/remembered variant
				var atlas_coords := _get_atlas_coords_for_tile(tile, false)
				terrain_layer.set_cell(pos, 0, atlas_coords)
			else:
				# Unexplored: erase cell so black background shows through
				terrain_layer.erase_cell(pos)

func has_los_to(from: Vector2i, to: Vector2i) -> bool:
	# Bresenham line check for transparency
	var x0: int = from.x
	var y0: int = from.y
	var x1: int = to.x
	var y1: int = to.y

	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy

	while true:
		if Vector2i(x0, y0) != from:
			if not is_transparent(Vector2i(x0, y0)):
				return false

		if x0 == x1 and y0 == y1:
			break

		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return true

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
		var lowest_f: float = f_score.get(current, INF)
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
		var neighbor: Vector2i = pos + dir
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

# ============================================================================
# FLOOR-WIDE ALERTNESS (Phase B: Stealth)
# ============================================================================

## Add noise to floor alertness (from combat, doors, smithing, etc.)
func add_floor_noise(amount: int) -> void:
	floor_alertness = mini(floor_alertness + amount, 50)

## Decay floor alertness by 1 per round (called from turn system)
func tick_floor_alertness() -> void:
	if floor_alertness > 0:
		floor_alertness -= 1

## Get floor alertness for spawning/door locking decisions
func get_floor_alertness() -> int:
	return floor_alertness

# ============================================================================
# DOOR MECHANICS (Phase F)
# ============================================================================

## Try to close an open door at pos. Returns true if closed.
func close_door(pos: Vector2i) -> bool:
	if get_tile(pos) != Tile.DOOR_OPEN:
		return false
	# Check if an entity is standing in the doorway
	if get_entity_at(pos) != null:
		return false
	# Check if items are blocking the doorway
	if not get_items_at(pos).is_empty():
		return false
	set_tile(pos, Tile.DOOR_CLOSED)
	return true

## Try to bash a jammed/locked door. Returns true if bashed open.
func bash_door(pos: Vector2i, str_bonus: int) -> bool:
	var tile := get_tile(pos)
	if tile != Tile.DOOR_JAMMED and tile != Tile.DOOR_LOCKED:
		return false
	# STR check: 30% base + STR*5%
	var chance: int = 30 + str_bonus * 5
	if randi_range(1, 100) <= chance:
		set_tile(pos, Tile.DOOR_OPEN)
		return true
	return false

## Reveal a secret door at pos
func reveal_secret_door(pos: Vector2i) -> void:
	if get_tile(pos) == Tile.DOOR_SECRET:
		secret_doors.erase(pos)
		set_tile(pos, Tile.DOOR_CLOSED)

## Search adjacent tiles for secret doors (Perception check per tile)
func search_for_secrets(center: Vector2i, perception: int) -> int:
	var found: int = 0
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	for dir: Vector2i in directions:
		var check_pos: Vector2i = center + dir
		if get_tile(check_pos) == Tile.DOOR_SECRET:
			# Perception check: 20% + perception*10%
			var chance: int = 20 + perception * 10
			if randi_range(1, 100) <= chance:
				reveal_secret_door(check_pos)
				found += 1
	return found

## Place a trap with a specific type at a position
func place_trap(pos: Vector2i, trap_type: int) -> void:
	set_tile(pos, Tile.TRAP)
	trap_types[pos] = trap_type

# ============================================================================
# WAYFARER'S INSTINCT (Trait: reveal nearby traps, doors, stairs on floor entry)
# ============================================================================

## Reveal traps within trap_radius and doors/stairs within feature_radius of center.
func reveal_for_wayfarer(center: Vector2i, trap_radius: int, feature_radius: int) -> void:
	var max_radius: int = maxi(trap_radius, feature_radius)
	var traps_found: int = 0
	var features_found: int = 0

	for dy in range(-max_radius, max_radius + 1):
		for dx in range(-max_radius, max_radius + 1):
			var pos: Vector2i = center + Vector2i(dx, dy)
			if not is_in_bounds(pos):
				continue

			var dist: int = maxi(absi(dx), absi(dy))  # Chebyshev distance
			var tile: int = get_tile(pos)

			# Reveal traps within trap_radius
			if dist <= trap_radius:
				if tile == Tile.TRAP:
					set_explored(pos, true)
					set_tile_visible(pos, true)
					traps_found += 1

			# Reveal doors and stairs within feature_radius
			if dist <= feature_radius:
				if tile in [Tile.DOOR_CLOSED, Tile.DOOR_OPEN, Tile.DOOR_LOCKED, Tile.DOOR_JAMMED, Tile.DOOR_SECRET, Tile.STAIRS_DOWN, Tile.STAIRS_UP]:
					set_explored(pos, true)
					set_tile_visible(pos, true)
					# Reveal secret doors as closed doors
					if tile == Tile.DOOR_SECRET:
						reveal_secret_door(pos)
					features_found += 1

	if traps_found > 0 or features_found > 0:
		var parts: Array[String] = []
		if traps_found > 0:
			parts.append("%d trap%s" % [traps_found, "s" if traps_found != 1 else ""])
		if features_found > 0:
			parts.append("%d feature%s" % [features_found, "s" if features_found != 1 else ""])
		GameManager.log_message("Your wayfarer's instinct reveals %s nearby." % ", ".join(parts), ThemeColors.ABILITY_LEARNED)
