extends RefCounted
class_name DungeonGenerator
## Procedural dungeon generation for The Necromancer.
## Based on classic roguelike room-and-corridor generation.

# Default values (overridden by LayerConfig per depth)
const DEFAULT_MIN_ROOM_SIZE := 4
const DEFAULT_MAX_ROOM_SIZE := 12
const DEFAULT_MAX_ROOMS := 30
const ROOM_PLACEMENT_ATTEMPTS := 100

enum RoomType {
	STANDARD = 0,
	CROSS = 1,
	L_SHAPE = 2,
	CIRCULAR = 3,
	VAULT_INTERESTING = 6,
	VAULT_LESSER = 7,
	VAULT_GREATER = 8,
}

# Layer-based generation parameters (set per level)
var min_room_size := DEFAULT_MIN_ROOM_SIZE
var max_room_size := DEFAULT_MAX_ROOM_SIZE
var max_rooms := DEFAULT_MAX_ROOMS
var corridor_width := 1
var vault_chance := 0.1

var level: Level
var rooms: Array[Rect2i] = []
var _vault_connection_points: Array[Vector2i] = []

class Room:
	var rect: Rect2i
	var is_connected: bool = false
	var room_type: int = RoomType.STANDARD
	var vault_data: DataManager.VaultData = null
	var tiles: Array[Vector2i] = []

	func _init(r: Rect2i) -> void:
		rect = r

	func center() -> Vector2i:
		return Vector2i(rect.position.x + rect.size.x / 2,
					   rect.position.y + rect.size.y / 2)

	func intersects(other: Room, margin: int = 1) -> bool:
		var expanded := Rect2i(
			rect.position - Vector2i(margin, margin),
			rect.size + Vector2i(margin * 2, margin * 2)
		)
		return expanded.intersects(other.rect)

func _select_room_type(depth: int) -> int:
	# Depth-weighted room type selection (mirrors C version logic)
	var r: int = randi_range(1, depth + 5) + randi_range(0, 4)
	if r < 5:
		return RoomType.STANDARD
	elif r < 8:
		return RoomType.CROSS
	elif r < 10:
		if randf() < 0.5:
			return RoomType.L_SHAPE
		return RoomType.CIRCULAR
	elif r < 13:
		return RoomType.VAULT_INTERESTING
	elif r < 18:
		return RoomType.VAULT_LESSER
	else:
		return RoomType.VAULT_GREATER

func generate(target_level: Level, depth: int) -> void:
	level = target_level
	rooms.clear()
	_vault_connection_points.clear()

	# Special levels override normal generation
	if depth == 20:
		_generate_throne_room_level(depth)
		return

	# Get layer-specific generation parameters
	_apply_layer_params(depth)

	# Retry generation if connectivity fails (up to 10 attempts)
	var generation_valid: bool = false
	for _gen_attempt in range(10):
		rooms.clear()
		_vault_connection_points.clear()

		# Fill with walls
		for y in range(level.height):
			for x in range(level.width):
				level.set_tile(Vector2i(x, y), Level.Tile.WALL)

		# Generate rooms
		_generate_rooms()

		# Connect rooms with corridors
		_connect_rooms()

		if _validate_connectivity():
			generation_valid = true
			break
		else:
			print("Generation attempt %d failed connectivity check, retrying..." % [_gen_attempt + 1])

	if not generation_valid:
		print("WARNING: Could not generate fully connected level after 10 attempts")

	# Assign room lighting data (must be after rooms exist, before vaults)
	_assign_room_data(depth)

	# Try to place vaults (special pre-designed rooms)
	_try_place_vaults(depth)

	# Force-place transition vaults at layer boundaries
	_try_place_transition_vault(depth)

	# Connect vault corridor points
	_connect_vault_corridor_points()

	# Place stairs
	_place_stairs(depth)

	# Add features based on depth
	_add_features(depth)

	# Place themed guards near doors
	_place_door_guards(depth)

	# Ensure forges on appropriate levels
	_ensure_forges(depth)

	# Spawn smithing materials near forges (Sil-Q: 1-3 items within 3 tiles)
	_spawn_forge_materials(depth)

	# Apply layer-specific decoration
	_apply_layer_decoration(depth)

	# Post-decoration: ensure stairs remain connected (decoration can break paths)
	_ensure_stairs_connectivity(depth)

	# Post-decoration: relocate any vault-placed entities stranded on non-passable tiles
	_relocate_stranded_entities()

	# Spawn monsters
	_spawn_monsters(depth)

	# Spawn items
	_spawn_items(depth)

	# Spawn artifacts (unique, depth-gated)
	_spawn_artifacts(depth)

	# Spawn lore objects
	_spawn_lore_objects(depth)

	level.generation_complete.emit(level.width, level.height)

func _apply_layer_params(depth: int) -> void:
	var params := LayerConfig.get_generation_params(depth)
	min_room_size = params.get("room_size_min", DEFAULT_MIN_ROOM_SIZE)
	max_room_size = params.get("room_size_max", DEFAULT_MAX_ROOM_SIZE)
	max_rooms = randi_range(params.get("room_count_min", 6), params.get("room_count_max", 12))
	corridor_width = params.get("corridor_width", 1)
	vault_chance = params.get("vault_chance", 0.1)

	var layer_name := LayerConfig.get_layer_name(depth)
	print("Generating %s (depth %d): rooms=%d, size=%d-%d, corridors=%d" % [
		layer_name, depth, max_rooms, min_room_size, max_room_size, corridor_width
	])

func _generate_rooms() -> void:
	var room_list: Array[Room] = []
	var greater_vault_placed: bool = false

	for _attempt in range(ROOM_PLACEMENT_ATTEMPTS):
		if room_list.size() >= max_rooms:
			break

		var room_type: int = _select_room_type(level.depth if level else 1)

		# Greater vaults: max 1 per floor, check uniqueness
		if room_type == RoomType.VAULT_GREATER:
			if greater_vault_placed:
				room_type = RoomType.STANDARD

		# For vault types, try to place a vault room
		if room_type >= RoomType.VAULT_INTERESTING:
			var vault_room: Room = _try_place_vault_room(room_type, level.depth if level else 1)
			if vault_room:
				# Check overlap with existing rooms
				var overlaps: bool = false
				for existing in room_list:
					if vault_room.intersects(existing, 2):
						overlaps = true
						break
				if not overlaps:
					room_list.append(vault_room)
					rooms.append(vault_room.rect)
					if room_type == RoomType.VAULT_GREATER:
						greater_vault_placed = true
			continue

		# Standard shape generation
		var room_width: int = randi_range(min_room_size, max_room_size)
		var room_height: int = randi_range(min_room_size, max_room_size)
		var room_x: int = randi_range(1, level.width - room_width - 1)
		var room_y: int = randi_range(1, level.height - room_height - 1)

		var new_room: Room
		match room_type:
			RoomType.CROSS:
				var cx: int = room_x + room_width / 2
				var cy: int = room_y + room_height / 2
				new_room = _generate_cross_room(cx, cy)
			RoomType.L_SHAPE:
				new_room = _generate_l_room(room_x, room_y)
			RoomType.CIRCULAR:
				var cx2: int = room_x + room_width / 2
				var cy2: int = room_y + room_height / 2
				new_room = _generate_circular_room(cx2, cy2)
			_:  # STANDARD
				new_room = Room.new(Rect2i(room_x, room_y, room_width, room_height))

		# Check for overlap
		var overlaps: bool = false
		for existing in room_list:
			if new_room.intersects(existing, 2):
				overlaps = true
				break

		if not overlaps:
			if room_type == RoomType.STANDARD or room_type == RoomType.L_SHAPE:
				_carve_room(new_room)
			# Cross and circular rooms are carved during generation
			room_list.append(new_room)
			rooms.append(new_room.rect)

func _carve_room(room: Room) -> void:
	for y in range(room.rect.position.y, room.rect.position.y + room.rect.size.y):
		for x in range(room.rect.position.x, room.rect.position.x + room.rect.size.x):
			level.set_tile(Vector2i(x, y), Level.Tile.FLOOR)

## Generate a cross-shaped room (two overlapping rectangles)
func _generate_cross_room(center_x: int, center_y: int) -> Room:
	# Horizontal bar
	var h_width: int = randi_range(max_room_size / 2, max_room_size)
	var h_height: int = randi_range(min_room_size, min_room_size + 2)
	# Vertical bar
	var v_width: int = randi_range(min_room_size, min_room_size + 2)
	var v_height: int = randi_range(max_room_size / 2, max_room_size)

	# Bounding rect
	var bw: int = maxi(h_width, v_width)
	var bh: int = maxi(h_height, v_height)
	var bx: int = center_x - bw / 2
	var by: int = center_y - bh / 2

	var room := Room.new(Rect2i(bx, by, bw, bh))
	room.room_type = RoomType.CROSS

	# Carve horizontal bar
	var hx: int = center_x - h_width / 2
	var hy: int = center_y - h_height / 2
	for y in range(hy, hy + h_height):
		for x in range(hx, hx + h_width):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.Tile.FLOOR)
				room.tiles.append(pos)

	# Carve vertical bar
	var vx: int = center_x - v_width / 2
	var vy: int = center_y - v_height / 2
	for y in range(vy, vy + v_height):
		for x in range(vx, vx + v_width):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos) and level.get_tile(pos) != Level.Tile.FLOOR:
				level.set_tile(pos, Level.Tile.FLOOR)
				room.tiles.append(pos)

	return room

## Generate an L-shaped room (rectangle with corner cut out)
func _generate_l_room(pos_x: int, pos_y: int) -> Room:
	var full_w: int = randi_range(min_room_size + 2, max_room_size)
	var full_h: int = randi_range(min_room_size + 2, max_room_size)

	var room := Room.new(Rect2i(pos_x, pos_y, full_w, full_h))
	room.room_type = RoomType.L_SHAPE

	# Carve full rectangle first
	for y in range(pos_y, pos_y + full_h):
		for x in range(pos_x, pos_x + full_w):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.Tile.FLOOR)
				room.tiles.append(pos)

	# Cut out a corner quadrant (random corner)
	var cut_w: int = full_w / 2
	var cut_h: int = full_h / 2
	var corner: int = randi() % 4
	var cut_x: int = pos_x
	var cut_y: int = pos_y
	match corner:
		0: pass  # top-left (default)
		1: cut_x = pos_x + full_w - cut_w  # top-right
		2: cut_y = pos_y + full_h - cut_h  # bottom-left
		3:  # bottom-right
			cut_x = pos_x + full_w - cut_w
			cut_y = pos_y + full_h - cut_h

	for y in range(cut_y, cut_y + cut_h):
		for x in range(cut_x, cut_x + cut_w):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.Tile.WALL)
				room.tiles.erase(pos)

	return room

## Generate a circular room using midpoint circle algorithm
func _generate_circular_room(center_x: int, center_y: int) -> Room:
	var radius: int = randi_range(min_room_size / 2, max_room_size / 2)
	radius = maxi(radius, 3)  # Minimum radius of 3

	var bx: int = center_x - radius
	var by: int = center_y - radius
	var room := Room.new(Rect2i(bx, by, radius * 2, radius * 2))
	room.room_type = RoomType.CIRCULAR

	# Fill circle using distance check
	for y in range(center_y - radius, center_y + radius + 1):
		for x in range(center_x - radius, center_x + radius + 1):
			var dx: float = float(x - center_x)
			var dy: float = float(y - center_y)
			if dx * dx + dy * dy <= float(radius * radius):
				var pos := Vector2i(x, y)
				if level.is_in_bounds(pos):
					level.set_tile(pos, Level.Tile.FLOOR)
					room.tiles.append(pos)

	return room

func _connect_rooms() -> void:
	if rooms.size() < 2:
		return

	var current_depth: int = level.depth if level else 1
	var winding_chance: float = 0.20 if current_depth >= 5 else 0.0

	# Connect each room to the next one
	for i in range(rooms.size() - 1):
		var room_a := rooms[i]
		var room_b := rooms[i + 1]

		var center_a := Vector2i(room_a.position.x + room_a.size.x / 2,
								room_a.position.y + room_a.size.y / 2)
		var center_b := Vector2i(room_b.position.x + room_b.size.x / 2,
								room_b.position.y + room_b.size.y / 2)

		if winding_chance > 0.0 and randf() < winding_chance:
			_carve_winding_corridor(center_a, center_b)
		elif randf() < 0.5:
			_carve_h_corridor(center_a.x, center_b.x, center_a.y)
			_carve_v_corridor(center_a.y, center_b.y, center_b.x)
		else:
			_carve_v_corridor(center_a.y, center_b.y, center_a.x)
			_carve_h_corridor(center_a.x, center_b.x, center_b.y)

	# Add some extra connections for loops
	var extra_connections := randi_range(1, rooms.size() / 4)
	for _i in range(extra_connections):
		var idx_a := randi() % rooms.size()
		var idx_b := randi() % rooms.size()
		if idx_a != idx_b:
			var room_a := rooms[idx_a]
			var room_b := rooms[idx_b]
			var center_a := Vector2i(room_a.position.x + room_a.size.x / 2,
									room_a.position.y + room_a.size.y / 2)
			var center_b := Vector2i(room_b.position.x + room_b.size.x / 2,
									room_b.position.y + room_b.size.y / 2)

			if winding_chance > 0.0 and randf() < winding_chance:
				_carve_winding_corridor(center_a, center_b)
			elif randf() < 0.5:
				_carve_h_corridor(center_a.x, center_b.x, center_a.y)
				_carve_v_corridor(center_a.y, center_b.y, center_b.x)
			else:
				_carve_v_corridor(center_a.y, center_b.y, center_a.x)
				_carve_h_corridor(center_a.x, center_b.x, center_b.y)

func _assign_room_data(depth: int) -> void:
	level.rooms = rooms.duplicate()
	for room_idx in range(rooms.size()):
		var room: Rect2i = rooms[room_idx]
		level.set_room_id_by_rect(room, room_idx)

	# Room lighting probability (Sil-Q style: shallow=lit, deep=dark)
	var lit_chance: float = clampf(0.80 - depth * 0.04, 0.10, 0.80)
	for room_idx in range(rooms.size()):
		if randf() < lit_chance:
			level.set_room_lit_by_rect(rooms[room_idx], true)

	# Dark zones: at depth 10+, some rooms become dark zones (no ambient light)
	# Frequency increases with depth: 20% at depth 10, 50% at depth 15, 80% at depth 20
	if depth >= 10:
		var dark_zone_chance: float = clampf(0.20 + (depth - 10) * 0.06, 0.20, 0.80)
		for room_idx in range(rooms.size()):
			if randf() < dark_zone_chance:
				level.set_dark_zone(room_idx)

func _carve_h_corridor(x1: int, x2: int, y: int) -> void:
	var start := mini(x1, x2)
	var end := maxi(x1, x2)
	# Carve corridor with layer-based width
	var half_width := corridor_width / 2
	for x in range(start, end + 1):
		for dy in range(-half_width, half_width + 1):
			var pos := Vector2i(x, y + dy)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.Tile.FLOOR)

func _carve_v_corridor(y1: int, y2: int, x: int) -> void:
	var start := mini(y1, y2)
	var end := maxi(y1, y2)
	# Carve corridor with layer-based width
	var half_width := corridor_width / 2
	for y in range(start, end + 1):
		for dx in range(-half_width, half_width + 1):
			var pos := Vector2i(x + dx, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.Tile.FLOOR)

func _place_stairs(depth: int) -> void:
	if rooms.is_empty():
		return

	# Place stairs up in first room (except on first level)
	if depth > 1:
		var first_room := rooms[0]
		var up_pos := Vector2i(
			first_room.position.x + first_room.size.x / 2,
			first_room.position.y + first_room.size.y / 2
		)
		level.set_tile(up_pos, Level.Tile.STAIRS_UP)

	# Place stairs down in last room
	var last_room := rooms[rooms.size() - 1]
	var down_pos := Vector2i(
		last_room.position.x + last_room.size.x / 2,
		last_room.position.y + last_room.size.y / 2
	)
	level.set_tile(down_pos, Level.Tile.STAIRS_DOWN)

func _add_features(depth: int) -> void:
	# Place doors at room-corridor junctions and rare mid-corridor spots
	_place_doors(depth)

	# Add rubble in some rooms based on depth
	if depth > 3:
		for room in rooms:
			if randf() < 0.2:
				var rubble_count := randi_range(1, 3)
				for _i in range(rubble_count):
					var rubble_pos := Vector2i(
						randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
						randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
					)
					if level.get_tile(rubble_pos) == Level.Tile.FLOOR:
						level.set_tile(rubble_pos, Level.Tile.RUBBLE)

	# Forges are guaranteed by _ensure_forges() - no random placement here

	# Add water pools (depth > 4)
	if depth > 4:
		_add_water_pools(depth)

	# Add lava (depth > 12)
	if depth > 12:
		_add_lava_pools(depth)

	# Add traps with variety
	_add_traps(depth)

	# Add secret doors (depth > 2)
	if depth > 2:
		_add_secret_doors(depth)

	# Boss room at layer transitions (every 3 floors) and final boss at 20
	if depth in [3, 6, 9, 12, 15, 18, 20]:
		_add_boss_room(depth)

func _pick_door_type(depth: int) -> int:
	# Deeper levels have more locked/jammed doors
	var roll: float = randf()
	if depth > 8 and roll < 0.10:
		return Level.Tile.DOOR_LOCKED  # 10% locked at depth 9+
	elif depth > 4 and roll < 0.15:
		return Level.Tile.DOOR_JAMMED  # 15% jammed at depth 5+
	return Level.Tile.DOOR_CLOSED

func _add_water_pools(depth: int) -> void:
	# Place water in 1-2 rooms
	var pool_count: int = randi_range(1, 2)
	for _i in range(pool_count):
		if rooms.is_empty():
			break
		var room: Rect2i = rooms[randi() % rooms.size()]
		# Small water patch (3-6 tiles)
		var center := Vector2i(
			randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
			randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
		)
		if level.get_tile(center) == Level.Tile.FLOOR:
			level.set_tile(center, Level.Tile.WATER)
			# Spread to adjacent floor tiles
			var spread_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for dir: Vector2i in spread_dirs:
				if randf() < 0.5:
					var adj: Vector2i = center + dir
					if level.is_in_bounds(adj) and level.get_tile(adj) == Level.Tile.FLOOR:
						level.set_tile(adj, Level.Tile.WATER)

func _add_lava_pools(depth: int) -> void:
	# Place lava in 1 room
	if rooms.is_empty():
		return
	var room: Rect2i = rooms[randi() % rooms.size()]
	var center := Vector2i(
		randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
		randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
	)
	if level.get_tile(center) == Level.Tile.FLOOR:
		level.set_tile(center, Level.Tile.LAVA)
		# Small spread
		var spread_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for dir: Vector2i in spread_dirs:
			if randf() < 0.3:
				var adj: Vector2i = center + dir
				if level.is_in_bounds(adj) and level.get_tile(adj) == Level.Tile.FLOOR:
					level.set_tile(adj, Level.Tile.LAVA)

func _add_traps(depth: int) -> void:
	# Number of traps scales with depth
	var trap_count: int = randi_range(1 + depth / 3, 2 + depth / 2)
	trap_count = mini(trap_count, 10)
	var available_types: Array[int] = _get_trap_types_for_depth(depth)

	for _i in range(trap_count):
		var trap_pos: Vector2i = level.find_random_floor()
		if trap_pos == Vector2i(-1, -1):
			continue
		# Don't place too close to stairs
		var stairs_up: Vector2i = level.find_stairs_up()
		if stairs_up != Vector2i(-1, -1):
			var dist: int = max(abs(trap_pos.x - stairs_up.x), abs(trap_pos.y - stairs_up.y))
			if dist < 3:
				continue
		var trap_type: int = available_types[randi() % available_types.size()]
		level.place_trap(trap_pos, trap_type)

func _get_trap_types_for_depth(depth: int) -> Array[int]:
	var types: Array[int] = [Level.TrapType.BASIC, Level.TrapType.CALTROPS]
	if depth >= 3:
		types.append(Level.TrapType.DART)
		types.append(Level.TrapType.ALARM)
	if depth >= 5:
		types.append(Level.TrapType.PIT)
		types.append(Level.TrapType.GAS)
		types.append(Level.TrapType.WEB)
	if depth >= 8:
		types.append(Level.TrapType.FLASH)
		types.append(Level.TrapType.TELEPORT)
	return types

func _add_secret_doors(depth: int) -> void:
	# 1-2 secret doors per level
	var secret_count: int = randi_range(1, mini(2, depth / 3))
	for _i in range(secret_count):
		# Find a wall tile adjacent to a room that could be a shortcut
		for _attempt in range(50):
			var room_a_idx: int = randi() % rooms.size()
			var room_a: Rect2i = rooms[room_a_idx]
			# Pick a wall on the edge of the room
			var side: int = randi() % 4
			var wall_pos: Vector2i
			match side:
				0:  # North wall
					wall_pos = Vector2i(
						randi_range(room_a.position.x, room_a.position.x + room_a.size.x - 1),
						room_a.position.y - 1
					)
				1:  # South wall
					wall_pos = Vector2i(
						randi_range(room_a.position.x, room_a.position.x + room_a.size.x - 1),
						room_a.position.y + room_a.size.y
					)
				2:  # West wall
					wall_pos = Vector2i(
						room_a.position.x - 1,
						randi_range(room_a.position.y, room_a.position.y + room_a.size.y - 1)
					)
				_:  # East wall
					wall_pos = Vector2i(
						room_a.position.x + room_a.size.x,
						randi_range(room_a.position.y, room_a.position.y + room_a.size.y - 1)
					)

			if level.is_in_bounds(wall_pos) and level.get_tile(wall_pos) == Level.Tile.WALL:
				# Determine direction away from room based on which side
				var outward_dir: Vector2i
				match side:
					0: outward_dir = Vector2i(0, -1)   # North wall → check north
					1: outward_dir = Vector2i(0, 1)    # South wall → check south
					2: outward_dir = Vector2i(-1, 0)   # West wall → check west
					_: outward_dir = Vector2i(1, 0)    # East wall → check east
				var other_side: Vector2i = wall_pos + outward_dir
				if level.is_in_bounds(other_side) and level.get_tile(other_side) == Level.Tile.FLOOR:
					level.set_tile(wall_pos, Level.Tile.DOOR_SECRET)
					level.secret_doors[wall_pos] = true
					break

## Boss pool: 3 named Tolkien bosses per layer transition, randomly selected each run
## Boss names override the base monster name for flavor
const BOSS_POOL: Dictionary = {
	3: [  # Forest Breach → Orc Warrens
		{"title": "Ungoliant's Broodmother", "hp_mult": 1.8, "xp_mult": 3},
		{"title": "Shelob's Daughter", "hp_mult": 1.6, "xp_mult": 3},
		{"title": "The Tanglethorn Ancient", "hp_mult": 2.0, "xp_mult": 3},
	],
	6: [  # Orc Warrens → Torture Halls
		{"title": "Bolg, Son of Azog", "hp_mult": 1.8, "xp_mult": 3},
		{"title": "Gothmog, Orc-captain", "hp_mult": 2.0, "xp_mult": 3},
		{"title": "Shagrat the Tracker", "hp_mult": 1.6, "xp_mult": 3},
	],
	9: [  # Torture Halls → Necropolis
		{"title": "The Mouth of Sauron", "hp_mult": 2.0, "xp_mult": 3},
		{"title": "Karvag the Torturer", "hp_mult": 1.8, "xp_mult": 3},
		{"title": "Herumor, Dark Sorcerer", "hp_mult": 1.7, "xp_mult": 3},
	],
	12: [  # Necropolis → Wraith Domain
		{"title": "Grishnakh, Crypt Lord", "hp_mult": 2.0, "xp_mult": 3},
		{"title": "The Barrow-wight King", "hp_mult": 2.2, "xp_mult": 3},
		{"title": "Thuringwethil, Vampire", "hp_mult": 1.8, "xp_mult": 3},
	],
	15: [  # Wraith Domain → Inner Sanctum
		{"title": "Uvatha the Horseman", "hp_mult": 2.0, "xp_mult": 3},
		{"title": "Adunaphel, the Quiet", "hp_mult": 2.2, "xp_mult": 3},
		{"title": "Dwar of Waw", "hp_mult": 1.8, "xp_mult": 3},
	],
	18: [  # Inner Sanctum → Throne Room
		{"title": "Khamul, Shadow of the East", "hp_mult": 2.5, "xp_mult": 3},
		{"title": "The Witch-king's Herald", "hp_mult": 2.2, "xp_mult": 3},
		{"title": "Ren the Unclean", "hp_mult": 2.0, "xp_mult": 3},
	],
	20: [  # Final boss
		{"title": "Sauron, the Necromancer", "hp_mult": 3.0, "xp_mult": 5},
	],
}

func _add_boss_room(depth: int) -> void:
	if rooms.size() < 3:
		return

	# Pick a room that isn't first or last (not near stairs)
	var boss_room_idx: int = randi_range(1, rooms.size() - 2)
	var boss_room: Rect2i = rooms[boss_room_idx]

	# Get boss from pool
	var pool: Array = BOSS_POOL.get(depth, [])
	if pool.is_empty():
		return
	var boss_info: Dictionary = pool.pick_random()

	# Spawn using themed monster for depth+3 as the base
	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var boss_data := DataManager.get_themed_monster_for_depth(depth + 3)
	if not boss_data:
		boss_data = DataManager.get_random_monster_for_depth(depth + 2)
	if not boss_data:
		return

	var boss_pos := Vector2i(
		boss_room.position.x + boss_room.size.x / 2,
		boss_room.position.y + boss_room.size.y / 2
	)
	if not level.is_in_bounds(boss_pos) or level.get_tile(boss_pos) != Level.Tile.FLOOR:
		return
	if level.get_entity_at(boss_pos) != null:
		return

	var boss: Monster = monster_scene.instantiate()
	boss.grid_position = boss_pos
	boss.initialize_from_data(boss_data)

	# Override with boss pool stats
	boss.entity_name = boss_info.title
	boss.max_health = int(boss.max_health * boss_info.hp_mult)
	boss.current_health = boss.max_health
	boss.experience_value = int(boss.experience_value * boss_info.xp_mult)
	boss.is_unique = true
	boss.is_brave = true
	level.add_entity(boss)

	# Guaranteed quality treasure near boss (2 items)
	var item_scene := preload("res://scenes/entities/item.tscn")
	for i in range(2):
		var item_data := DataManager.get_random_item_for_depth(depth + 3)
		if not item_data:
			continue
		var boss_item: DataManager.ItemData = DataManager.duplicate_item_data(item_data)
		# Boss drops are always ego quality
		_apply_floor_ego(boss_item, depth + 5)

		var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		var item_pos: Vector2i = boss_pos + offsets[i % offsets.size()]
		if level.is_in_bounds(item_pos) and level.get_tile(item_pos) == Level.Tile.FLOOR:
			var item: Item = item_scene.instantiate()
			item.grid_position = item_pos
			item.initialize_from_item_data(boss_item)
			level.add_item(item)

func _is_door_candidate(pos: Vector2i) -> bool:
	# A position is a door candidate if it connects two areas (walls on two opposite sides, floor on the other two)
	var north := level.get_tile(pos + Vector2i(0, -1))
	var south := level.get_tile(pos + Vector2i(0, 1))
	var east := level.get_tile(pos + Vector2i(1, 0))
	var west := level.get_tile(pos + Vector2i(-1, 0))

	# Horizontal corridor (walls north/south, floor east/west)
	if (north == Level.Tile.WALL and south == Level.Tile.WALL and
		east == Level.Tile.FLOOR and west == Level.Tile.FLOOR):
		return true

	# Vertical corridor (floor north/south, walls east/west)
	if (north == Level.Tile.FLOOR and south == Level.Tile.FLOOR and
		east == Level.Tile.WALL and west == Level.Tile.WALL):
		return true

	return false

## Check if a floor tile is a room entrance (connects a room to a corridor).
## Returns true if the tile is on a room border with a corridor on the opposite side.
func _is_room_entrance(pos: Vector2i) -> bool:
	if level.get_tile(pos) != Level.Tile.FLOOR:
		return false

	# Must be a chokepoint: walls on two opposite sides (door candidate shape)
	if not _is_door_candidate(pos):
		return false

	# Check if one side is inside a room and the other side is corridor (room_id == -1)
	var pos_room: int = level.get_room_id(pos)
	var cardinal_dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	var has_room_neighbor: bool = false
	var has_corridor_neighbor: bool = false

	for dir: Vector2i in cardinal_dirs:
		var neighbor: Vector2i = pos + dir
		if not level.is_in_bounds(neighbor):
			continue
		var n_tile: int = level.get_tile(neighbor)
		if n_tile == Level.Tile.WALL or n_tile == Level.Tile.VOID:
			continue
		var n_room: int = level.get_room_id(neighbor)
		if n_room >= 0:
			has_room_neighbor = true
		else:
			has_corridor_neighbor = true

	return has_room_neighbor and has_corridor_neighbor

## Place doors intelligently: room-corridor junctions (60%), rare mid-corridor (5%),
## then validate no two doors are adjacent.
func _place_doors(depth: int) -> void:
	var door_positions: Array[Vector2i] = []

	# Phase 1: Room-corridor junction doors (60% chance per valid junction)
	for y in range(1, level.height - 1):
		for x in range(1, level.width - 1):
			var pos := Vector2i(x, y)
			if level.get_tile(pos) == Level.Tile.FLOOR and _is_room_entrance(pos):
				if randf() < 0.60:
					door_positions.append(pos)

	# Phase 2: Rare mid-corridor doors (5% chance, min 4-tile spacing from any door)
	for y in range(1, level.height - 1):
		for x in range(1, level.width - 1):
			var pos := Vector2i(x, y)
			if level.get_tile(pos) != Level.Tile.FLOOR:
				continue
			# Must be a corridor chokepoint but NOT a room entrance
			if not _is_door_candidate(pos):
				continue
			if _is_room_entrance(pos):
				continue
			if randf() >= 0.05:
				continue
			# Check minimum 4-tile spacing from any existing door
			var too_close: bool = false
			for existing_door: Vector2i in door_positions:
				var dist: int = abs(pos.x - existing_door.x) + abs(pos.y - existing_door.y)
				if dist < 4:
					too_close = true
					break
			if not too_close:
				door_positions.append(pos)

	# Phase 3: Validation — remove any door that is adjacent to another door
	var valid_doors: Array[Vector2i] = []
	var door_set: Dictionary = {}
	for door_pos: Vector2i in door_positions:
		door_set[door_pos] = true

	for door_pos: Vector2i in door_positions:
		var has_adjacent_door: bool = false
		var adj_dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
		for dir: Vector2i in adj_dirs:
			var neighbor: Vector2i = door_pos + dir
			if neighbor != door_pos and door_set.has(neighbor):
				# If the neighbor was already placed in valid_doors, remove this one
				if neighbor in valid_doors:
					has_adjacent_door = true
					break
		if not has_adjacent_door:
			valid_doors.append(door_pos)

	# Phase 4: Actually place door tiles
	for door_pos: Vector2i in valid_doors:
		var door_type: int = _pick_door_type(depth)
		level.set_tile(door_pos, door_type)

## Try to place a vault room of the specified type. Returns Room or null.
func _try_place_vault_room(room_type: int, depth: int) -> Room:
	# Get all vaults valid for this depth
	var matching: Array[DataManager.VaultData] = DataManager.get_vaults_for_depth(depth)
	if matching.is_empty():
		return null

	# Weighted random selection by inverse rarity
	var total_weight: float = 0.0
	var weights: Array[float] = []
	for v: DataManager.VaultData in matching:
		var w: float = 1.0 / maxf(float(v.rarity), 1.0)
		weights.append(w)
		total_weight += w

	if total_weight <= 0.0:
		return null

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	var vault: DataManager.VaultData = matching[0]
	for i in range(matching.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			vault = matching[i]
			break

	if vault.map_lines.is_empty():
		return null

	# Check uniqueness for greater vaults
	if room_type == RoomType.VAULT_GREATER:
		if vault.index in GameManager.used_greater_vaults:
			return null

	# Try to find placement position
	for _attempt in range(20):
		var start_x: int = randi_range(2, level.width - vault.width - 2)
		var start_y: int = randi_range(2, level.height - vault.height - 2)
		var pos := Vector2i(start_x, start_y)

		if _can_place_vault_at(pos, vault):
			var room := Room.new(Rect2i(pos.x, pos.y, vault.width, vault.height))
			room.room_type = room_type
			room.vault_data = vault

			# Carve the vault
			_carve_vault(pos, vault, depth)

			# Track greater vaults
			if room_type == RoomType.VAULT_GREATER:
				GameManager.used_greater_vaults.append(vault.index)

			return room

	return null

func _try_place_vaults(depth: int) -> void:
	# Use layer-configured vault chance
	if randf() > vault_chance:
		return

	var vault := DataManager.get_random_vault_for_depth(depth)
	if not vault or vault.map_lines.is_empty():
		return

	# Find a suitable position (try to fit within map bounds)
	var max_attempts := 20
	for _attempt in range(max_attempts):
		var start_x := randi_range(2, level.width - vault.width - 2)
		var start_y := randi_range(2, level.height - vault.height - 2)

		if _can_place_vault_at(Vector2i(start_x, start_y), vault):
			_carve_vault(Vector2i(start_x, start_y), vault, depth)
			return

func _can_place_vault_at(pos: Vector2i, vault: DataManager.VaultData) -> bool:
	# Check if the vault fits and doesn't overlap stairs
	for y in range(vault.height):
		for x in range(vault.width):
			var check_pos := Vector2i(pos.x + x, pos.y + y)
			if not level.is_in_bounds(check_pos):
				return false
			# Don't overwrite stairs
			var tile := level.get_tile(check_pos)
			if tile == Level.Tile.STAIRS_DOWN or tile == Level.Tile.STAIRS_UP:
				return false
	return true

func _carve_vault(pos: Vector2i, vault: DataManager.VaultData, depth: int) -> void:
	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var item_scene := preload("res://scenes/entities/item.tscn")

	# Apply random rotation/flipping
	var transformed_lines: Array[String] = _transform_vault(vault)

	# Recalculate dimensions after transformation
	var actual_height: int = transformed_lines.size()
	var actual_width: int = 0
	for line in transformed_lines:
		actual_width = maxi(actual_width, line.length())

	for y in range(transformed_lines.size()):
		var line: String = transformed_lines[y]
		for x in range(line.length()):
			var ch: String = line[x]
			var tile_pos := Vector2i(pos.x + x, pos.y + y)
			if not level.is_in_bounds(tile_pos):
				continue

			# Parse vault symbol
			match ch:
				"#":
					level.set_tile(tile_pos, Level.Tile.WALL)
				".", " ":
					level.set_tile(tile_pos, Level.Tile.FLOOR)
				"+":
					level.set_tile(tile_pos, Level.Tile.DOOR_CLOSED)
				">":
					level.set_tile(tile_pos, Level.Tile.STAIRS_DOWN)
				"<":
					level.set_tile(tile_pos, Level.Tile.STAIRS_UP)
				"^":
					# Trap - triggers when stepped on
					level.set_tile(tile_pos, Level.Tile.TRAP)
				"s":
					# Secret door
					level.set_tile(tile_pos, Level.Tile.DOOR_SECRET)
					level.secret_doors[tile_pos] = true
				"0":
					# Forge
					level.set_tile(tile_pos, Level.Tile.FORGE)
				"7":
					# Chasm
					level.set_tile(tile_pos, Level.Tile.CHASM)
				":":
					# Rubble
					level.set_tile(tile_pos, Level.Tile.RUBBLE)
				";":
					# Glyph of warding
					level.set_tile(tile_pos, Level.Tile.GLYPH_OF_WARDING)
				",":
					# Sunlit floor (permanently lit)
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					# Mark as lit if level supports it
					if level.is_in_bounds(tile_pos):
						var idx: int = tile_pos.y * level.width + tile_pos.x
						if idx < level.room_lit.size():
							level.room_lit[idx] = true
				"=":
					# Poison stream
					level.set_tile(tile_pos, Level.Tile.POISON_STREAM)
				"-":
					# Vine floor
					level.set_tile(tile_pos, Level.Tile.VINE_FLOOR)
				"|":
					# Tangled roots (vine floor variant)
					level.set_tile(tile_pos, Level.Tile.VINE_FLOOR)
				"_":
					# Forest floor
					level.set_tile(tile_pos, Level.Tile.FLOOR)
				"~":
					# Water
					level.set_tile(tile_pos, Level.Tile.WATER)
				"%":
					# Quartz wall (treated as wall)
					level.set_tile(tile_pos, Level.Tile.WALL)
				"$":
					# Corridor connection point - track for later connection
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					_vault_connection_points.append(tile_pos)
				"?":
					# Random monster or item (50/50)
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					if randf() < 0.5:
						var m_data := DataManager.get_themed_monster_for_depth(depth)
						if m_data:
							var m: Monster = monster_scene.instantiate()
							m.grid_position = tile_pos
							m.initialize_from_data(m_data)
							level.add_entity(m)
					else:
						var i_data := DataManager.get_themed_item_for_depth(depth)
						if i_data:
							var i_copy: DataManager.ItemData = DataManager.duplicate_item_data(i_data)
							var itm: Item = item_scene.instantiate()
							itm.grid_position = tile_pos
							itm.initialize_from_item_data(i_copy)
							level.add_item(itm)
				"*":
					# Treasure
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					var item_data := DataManager.get_themed_item_for_depth(depth)
					if item_data:
						var star_copy: DataManager.ItemData = DataManager.duplicate_item_data(item_data)
						var item: Item = item_scene.instantiate()
						item.grid_position = tile_pos
						item.initialize_from_item_data(star_copy)
						level.add_item(item)
				"&":
					# Good treasure (higher depth items)
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					var item_data := DataManager.get_themed_item_for_depth(depth + 3)
					if item_data:
						var amp_copy: DataManager.ItemData = DataManager.duplicate_item_data(item_data)
						var item: Item = item_scene.instantiate()
						item.grid_position = tile_pos
						item.initialize_from_item_data(amp_copy)
						level.add_item(item)
				"1", "2", "3", "4":
					# Monster at depth + N
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					var monster_depth: int = depth + int(ch)
					var monster_data := DataManager.get_themed_monster_for_depth(monster_depth)
					if monster_data:
						var monster: Monster = monster_scene.instantiate()
						monster.grid_position = tile_pos
						monster.initialize_from_data(monster_data)
						level.add_entity(monster)
				_:
					# Check for named monster characters
					if ch.to_upper() == ch and ch != ch.to_lower():
						# Uppercase letter - potentially a named monster
						level.set_tile(tile_pos, Level.Tile.FLOOR)
						var monster_data := DataManager.get_monster_by_char(ch, depth)
						if monster_data:
							var monster: Monster = monster_scene.instantiate()
							monster.grid_position = tile_pos
							monster.initialize_from_data(monster_data)
							level.add_entity(monster)
					elif ch.to_lower() == ch and ch != ch.to_upper():
						# Lowercase letter - potentially a monster
						level.set_tile(tile_pos, Level.Tile.FLOOR)
						var monster_data := DataManager.get_monster_by_char(ch, depth)
						if monster_data:
							var monster: Monster = monster_scene.instantiate()
							monster.grid_position = tile_pos
							monster.initialize_from_data(monster_data)
							level.add_entity(monster)
					else:
						# Unknown symbol, treat as floor
						level.set_tile(tile_pos, Level.Tile.FLOOR)

	# Track this as a room
	rooms.append(Rect2i(pos.x, pos.y, actual_width, actual_height))

	# Apply vault flags
	var vault_rect := Rect2i(pos.x, pos.y, actual_width, actual_height)
	_apply_vault_flags(vault, vault_rect)

## Rotate vault map lines 90 degrees clockwise
func _rotate_vault_90(map_lines: Array[String]) -> Array[String]:
	if map_lines.is_empty():
		return map_lines
	var h: int = map_lines.size()
	var w: int = 0
	for line in map_lines:
		w = maxi(w, line.length())

	var rotated: Array[String] = []
	for x in range(w):
		var new_line: String = ""
		for y in range(h - 1, -1, -1):
			if x < map_lines[y].length():
				new_line += map_lines[y][x]
			else:
				new_line += " "
		rotated.append(new_line)
	return rotated

## Flip vault map lines horizontally (mirror left-right)
func _flip_vault_h(map_lines: Array[String]) -> Array[String]:
	var flipped: Array[String] = []
	for line in map_lines:
		var reversed: String = ""
		for i in range(line.length() - 1, -1, -1):
			reversed += line[i]
		flipped.append(reversed)
	return flipped

## Flip vault map lines vertically (mirror top-bottom)
func _flip_vault_v(map_lines: Array[String]) -> Array[String]:
	var flipped: Array[String] = []
	for i in range(map_lines.size() - 1, -1, -1):
		flipped.append(map_lines[i])
	return flipped

## Apply random transformations to vault map lines (respects NO_ROTATION flag)
func _transform_vault(vault: DataManager.VaultData) -> Array[String]:
	var lines: Array[String] = vault.map_lines.duplicate()

	# Skip rotation if NO_ROTATION flag is set
	if not vault.has_flag("NO_ROTATION"):
		# 33% chance of 90-degree rotation
		if randf() < 0.33:
			lines = _rotate_vault_90(lines)

	# 50% chance horizontal flip
	if randf() < 0.5:
		lines = _flip_vault_h(lines)

	# 50% chance vertical flip
	if randf() < 0.5:
		lines = _flip_vault_v(lines)

	return lines

## Apply vault flags after carving
func _apply_vault_flags(vault: DataManager.VaultData, vault_rect: Rect2i) -> void:
	if vault.has_flag("WEBS"):
		# 5% web terrain on empty floor squares
		for y in range(vault_rect.position.y, vault_rect.end.y):
			for x in range(vault_rect.position.x, vault_rect.end.x):
				var pos := Vector2i(x, y)
				if level.is_in_bounds(pos) and level.get_tile(pos) == Level.Tile.FLOOR:
					if randf() < 0.05:
						level.set_tile(pos, Level.Tile.WEB)

	if vault.has_flag("TRAPS"):
		# Double trap density in vault area
		var trap_count: int = randi_range(2, 6)
		for _i in range(trap_count):
			var tx: int = randi_range(vault_rect.position.x, vault_rect.end.x - 1)
			var ty: int = randi_range(vault_rect.position.y, vault_rect.end.y - 1)
			var tpos := Vector2i(tx, ty)
			if level.is_in_bounds(tpos) and level.get_tile(tpos) == Level.Tile.FLOOR:
				level.place_trap(tpos, Level.TrapType.BASIC)

	if vault.has_flag("LIGHT"):
		# Permanently lit room
		for y in range(vault_rect.position.y, vault_rect.end.y):
			for x in range(vault_rect.position.x, vault_rect.end.x):
				var pos := Vector2i(x, y)
				if level.is_in_bounds(pos):
					var idx: int = pos.y * level.width + pos.x
					if idx < level.room_lit.size():
						level.room_lit[idx] = true

## Validate that all walkable tiles are reachable from the first floor tile via BFS
func _validate_connectivity() -> bool:
	# Find first floor tile
	var start: Vector2i = Vector2i(-1, -1)
	for y in range(level.height):
		for x in range(level.width):
			if level.is_passable(Vector2i(x, y)):
				start = Vector2i(x, y)
				break
		if start != Vector2i(-1, -1):
			break

	if start == Vector2i(-1, -1):
		return false

	# BFS flood fill
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for dir: Vector2i in dirs:
			var next: Vector2i = current + dir
			if level.is_in_bounds(next) and level.is_passable(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)

	# Count total passable tiles
	var total_passable: int = 0
	for y in range(level.height):
		for x in range(level.width):
			if level.is_passable(Vector2i(x, y)):
				total_passable += 1

	# Allow small discrepancy (isolated 1-2 tile areas from decoration)
	var reachable: int = visited.size()
	if total_passable - reachable > 2:
		print("Connectivity check failed: %d reachable of %d passable" % [reachable, total_passable])
		return false
	return true

## Post-decoration connectivity repair: ensure stairs_down is BFS-reachable from stairs_up.
## Decoration passes (chasms, scatter terrain, themed rooms) can overwrite FLOOR tiles and
## sever the path between stairs. If stairs are disconnected, carve a 1-wide rescue corridor.
func _ensure_stairs_connectivity(depth: int) -> void:
	var stairs_up: Vector2i = level.find_stairs_up()
	var stairs_down: Vector2i = level.find_stairs_down()

	# Depth 1 has no stairs_up; depth 20 may have no stairs_down
	if stairs_up == Vector2i(-1, -1) and depth == 1:
		# Use first passable tile as start
		for y in range(level.height):
			for x in range(level.width):
				if level.is_passable(Vector2i(x, y)):
					stairs_up = Vector2i(x, y)
					break
			if stairs_up != Vector2i(-1, -1):
				break

	if stairs_up == Vector2i(-1, -1) or stairs_down == Vector2i(-1, -1):
		return

	# BFS from stairs_up to check if stairs_down is reachable
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [stairs_up]
	visited[stairs_up] = true
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == stairs_down:
			return  # Already connected, nothing to do
		for dir: Vector2i in dirs:
			var next: Vector2i = current + dir
			if level.is_in_bounds(next) and level.is_passable(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)

	# stairs_down is NOT reachable — carve a rescue corridor
	# Use BFS through ALL tiles (including walls) to find the shortest path
	var parent: Dictionary = {}
	var repair_queue: Array[Vector2i] = [stairs_up]
	parent[stairs_up] = stairs_up

	while not repair_queue.is_empty():
		var current: Vector2i = repair_queue.pop_front()
		if current == stairs_down:
			break
		for dir: Vector2i in dirs:
			var next: Vector2i = current + dir
			if level.is_in_bounds(next) and not parent.has(next):
				parent[next] = current
				repair_queue.append(next)

	# Trace path back from stairs_down and carve FLOOR tiles
	if parent.has(stairs_down):
		var carve_count: int = 0
		var pos: Vector2i = stairs_down
		while pos != stairs_up:
			if not level.is_passable(pos) and level.get_tile(pos) != Level.Tile.STAIRS_DOWN:
				level.set_tile(pos, Level.Tile.FLOOR)
				carve_count += 1
			pos = parent[pos]
		if carve_count > 0:
			print("Post-decoration: carved %d-tile rescue corridor at depth %d" % [carve_count, depth])

## Relocate vault-placed entities that ended up on non-passable tiles after decoration.
## Vault carving places items/monsters during _carve_vault(), but decoration passes can
## overwrite the FLOOR tile underneath. Move stranded entities to the nearest passable tile.
func _relocate_stranded_entities() -> void:
	var relocated_monsters: int = 0
	var relocated_items: int = 0

	# Relocate stranded monsters
	for entity in level.entities:
		if not is_instance_valid(entity):
			continue
		if not level.is_passable(entity.grid_position):
			var new_pos: Vector2i = _find_nearest_passable(entity.grid_position)
			if new_pos != Vector2i(-1, -1):
				entity.grid_position = new_pos
				relocated_monsters += 1

	# Relocate stranded items
	for item in level.items:
		if not is_instance_valid(item):
			continue
		if not level.is_passable(item.grid_position):
			var new_pos: Vector2i = _find_nearest_passable(item.grid_position)
			if new_pos != Vector2i(-1, -1):
				item.grid_position = new_pos
				relocated_items += 1

	if relocated_monsters > 0 or relocated_items > 0:
		print("Post-decoration: relocated %d monsters, %d items from non-passable tiles" % [
			relocated_monsters, relocated_items])

## Find the nearest passable tile to a given position using BFS.
func _find_nearest_passable(from: Vector2i) -> Vector2i:
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [from]
	visited[from] = true
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current != from and level.is_passable(current) and level.get_entity_at(current) == null:
			return current
		for dir: Vector2i in dirs:
			var next: Vector2i = current + dir
			if level.is_in_bounds(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)

	return Vector2i(-1, -1)

## Guarantee forges every 2 floors up to depth 10 (Sil-Q style).
## After depth 10, forges appear with 25% chance per floor.
func _ensure_forges(depth: int) -> void:
	var should_have_forge: bool = false
	if depth <= 10 and depth % 2 == 0:
		should_have_forge = true  # Guaranteed: depths 2, 4, 6, 8, 10
	elif depth > 10 and randf() < 0.25:
		should_have_forge = true  # 25% chance after depth 10

	if not should_have_forge:
		return

	# Check if a forge already exists (placed by vaults or decoration)
	for y in range(level.height):
		for x in range(level.width):
			if level.get_tile(Vector2i(x, y)) == Level.Tile.FORGE:
				return  # Already have one

	# Place forge - try rooms in random order until successful
	if rooms.is_empty():
		return
	var room_order: Array = range(rooms.size())
	room_order.shuffle()
	for idx in room_order:
		var room: Rect2i = rooms[idx]
		var forge_pos := Vector2i(
			room.position.x + room.size.x / 2,
			room.position.y + room.size.y / 2
		)
		if level.is_in_bounds(forge_pos) and level.get_tile(forge_pos) == Level.Tile.FLOOR:
			level.set_tile(forge_pos, Level.Tile.FORGE)
			return

## Spawn 1-3 smithing materials within 3 tiles of each forge (Sil-Q forge_item_placement)
## Depth determines material type: Mithril on all floors, Broken Glowing mid+, Broken Strange deep
func _spawn_forge_materials(depth: int) -> void:
	# Find all forge positions
	var forge_positions: Array[Vector2i] = []
	for y in range(level.height):
		for x in range(level.width):
			if level.get_tile(Vector2i(x, y)) == Level.Tile.FORGE:
				forge_positions.append(Vector2i(x, y))

	if forge_positions.is_empty():
		return

	var item_scene := preload("res://scenes/entities/item.tscn")

	# Build pool of smithing material names based on depth
	var material_pool: Array[String] = ["Piece of Mithril"]
	if depth >= 3:
		material_pool.append("Broken Glowing Weapon")
	if depth >= 4:
		material_pool.append("Shattered Elven Mail")
	if depth >= 8:
		material_pool.append("Broken Strange Weapon")
	if depth >= 10:
		material_pool.append("Twisted Shadow-plate")
	if depth >= 12:
		material_pool.append("Broken Strange Jewelry")

	for forge_pos: Vector2i in forge_positions:
		var mat_count: int = randi_range(1, 3)
		var spawned: int = 0

		# Collect valid floor tiles within 3 tiles of forge
		var nearby_floors: Array[Vector2i] = []
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var pos := Vector2i(forge_pos.x + dx, forge_pos.y + dy)
				if pos == forge_pos:
					continue
				if level.is_in_bounds(pos) and level.get_tile(pos) == Level.Tile.FLOOR:
					nearby_floors.append(pos)

		nearby_floors.shuffle()

		for i in range(mini(mat_count, nearby_floors.size())):
			var mat_name: String = material_pool.pick_random()
			var mat_template: DataManager.ItemData = DataManager.get_item(mat_name)
			if mat_template == null:
				continue

			var mat_copy: DataManager.ItemData = DataManager.duplicate_item_data(mat_template)
			var mat_item: Item = item_scene.instantiate()
			mat_item.grid_position = nearby_floors[i]
			mat_item.initialize_from_item_data(mat_copy)
			level.add_item(mat_item)
			spawned += 1

## Connect vault corridor points ($) to nearest room centers
func _connect_vault_corridor_points() -> void:
	if _vault_connection_points.is_empty():
		return

	for point: Vector2i in _vault_connection_points:
		# Find nearest room center
		var best_dist: float = INF
		var best_target: Vector2i = point
		for room_rect: Rect2i in rooms:
			var center := Vector2i(room_rect.position.x + room_rect.size.x / 2,
								   room_rect.position.y + room_rect.size.y / 2)
			var dist: float = float(abs(center.x - point.x) + abs(center.y - point.y))
			if dist > 2.0 and dist < best_dist:
				best_dist = dist
				best_target = center

		# Carve corridor from connection point to nearest room
		if best_target != point:
			if randf() < 0.5:
				_carve_h_corridor(point.x, best_target.x, point.y)
				_carve_v_corridor(point.y, best_target.y, best_target.x)
			else:
				_carve_v_corridor(point.y, best_target.y, point.x)
				_carve_h_corridor(point.x, best_target.x, best_target.y)

	_vault_connection_points.clear()

func _spawn_monsters(depth: int) -> void:
	# Themed spawning: count based on room density + depth
	var target_count: int = (rooms.size() + randi_range(1, maxi(1, rooms.size()))) / 2 + depth / 3
	target_count = mini(target_count, 25)

	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var spawned: int = 0
	var stairs_up: Vector2i = level.find_stairs_up()

	for _i in range(target_count):
		var spawn_pos: Vector2i = level.find_random_floor()
		if spawn_pos == Vector2i(-1, -1):
			continue

		# Don't spawn too close to stairs up (5-tile buffer)
		if stairs_up != Vector2i(-1, -1):
			var dist: int = max(abs(spawn_pos.x - stairs_up.x), abs(spawn_pos.y - stairs_up.y))
			if dist < 5:
				continue

		# 70% themed, 30% random
		var monster_data: DataManager.MonsterData = null
		if randf() < 0.70:
			monster_data = DataManager.get_themed_monster_for_depth(depth)
		else:
			monster_data = DataManager.get_random_monster_for_depth(depth)

		if monster_data:
			var monster: Monster = monster_scene.instantiate()
			monster.grid_position = spawn_pos
			monster.initialize_from_data(monster_data)
			level.add_entity(monster)
			spawned += 1

			# Group spawning (FRIENDS flag): spawn 2-4 similar monsters nearby
			if monster_data.has_flag("FRIENDS"):
				spawned += _spawn_group(monster_scene, spawn_pos, monster_data, randi_range(2, 4))

			# Escort spawning (ESCORT flag): spawn 1-2 weaker escorts
			if monster_data.has_flag("ESCORT") or monster_data.has_flag("ESCORTS"):
				var escort_data: DataManager.MonsterData = DataManager.get_random_monster_for_depth(maxi(1, depth - 2))
				if escort_data:
					spawned += _spawn_group(monster_scene, spawn_pos, escort_data, randi_range(1, 2))

	print("Spawned %d monsters at depth %d" % [spawned, depth])

func _spawn_group(monster_scene: PackedScene, center: Vector2i, data: DataManager.MonsterData, count: int) -> int:
	var spawned: int = 0
	var offsets: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	offsets.shuffle()
	for i in range(mini(count, offsets.size())):
		var pos: Vector2i = center + offsets[i]
		if level.is_in_bounds(pos) and level.get_tile(pos) == Level.Tile.FLOOR and level.get_entity_at(pos) == null:
			var monster: Monster = monster_scene.instantiate()
			monster.grid_position = pos
			monster.initialize_from_data(data)
			level.add_entity(monster)
			spawned += 1
	return spawned

func _spawn_items(depth: int) -> void:
	# Item count: 75% of monster target formula, capped at 15
	var monster_target: int = (rooms.size() + randi_range(1, maxi(1, rooms.size()))) / 2 + depth / 3
	var item_count: int = mini(int(monster_target * 0.75), 15)

	var item_scene := preload("res://scenes/entities/item.tscn")
	var spawned: int = 0

	for _i in range(item_count):
		var spawn_pos: Vector2i = level.find_random_floor()
		if spawn_pos == Vector2i(-1, -1):
			continue

		# 70% themed, 30% random
		var item_data: DataManager.ItemData = null
		if randf() < 0.70:
			item_data = DataManager.get_themed_item_for_depth(depth)
		else:
			item_data = DataManager.get_random_item_for_depth(depth)

		if item_data:
			var item_copy: DataManager.ItemData = DataManager.duplicate_item_data(item_data)
			# Ego enchantment chance: 10% base + 1% per depth (max ~30% at depth 20)
			var ego_chance: float = 0.10 + depth * 0.01
			if randf() < ego_chance:
				_apply_floor_ego(item_copy, depth)
			var item: Item = item_scene.instantiate()
			item.grid_position = spawn_pos
			item.initialize_from_item_data(item_copy)
			level.add_item(item)
			spawned += 1

	# Spawn actual food items (depth-scaled, separate from herbs)
	# Upper levels (1-5): 1-2, mid (6-10): 1-2, deep (11+): 0-1
	var food_count: int = 0
	if depth <= 5:
		food_count = randi_range(1, 2)
	elif depth <= 10:
		food_count = randi_range(1, 2)
	else:
		food_count = randi_range(0, 1)

	for _i in range(food_count):
		var spawn_pos: Vector2i = level.find_random_floor()
		if spawn_pos == Vector2i(-1, -1):
			continue

		var food_data: DataManager.ItemData = DataManager.get_random_actual_food(depth)
		if food_data:
			var food_copy: DataManager.ItemData = DataManager.duplicate_item_data(food_data)
			var item: Item = item_scene.instantiate()
			item.grid_position = spawn_pos
			item.initialize_from_item_data(food_copy)
			level.add_item(item)
			spawned += 1

	# Spawn herbs separately (capped to avoid herb flooding)
	# Shallow (1-6): 1-2, deep (7+): 0-1
	var herb_count: int = 0
	if depth <= 6:
		herb_count = randi_range(1, 2)
	else:
		herb_count = randi_range(0, 1)

	for _i in range(herb_count):
		var spawn_pos: Vector2i = level.find_random_floor()
		if spawn_pos == Vector2i(-1, -1):
			continue

		var herb_data: DataManager.ItemData = DataManager.get_random_herb_for_depth(depth)
		if herb_data:
			var herb_copy: DataManager.ItemData = DataManager.duplicate_item_data(herb_data)
			var item: Item = item_scene.instantiate()
			item.grid_position = spawn_pos
			item.initialize_from_item_data(herb_copy)
			level.add_item(item)
			spawned += 1

	print("Spawned %d items at depth %d" % [spawned, depth])

## Place themed guards adjacent to doors.
## Chance scales with depth: (15 + 2*depth)%, capped at 50%. Max 4 per level.
func _place_door_guards(depth: int) -> void:
	var guard_chance: float = minf(0.15 + 0.02 * depth, 0.50)
	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var guards_placed: int = 0
	var cardinal_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for y in range(1, level.height - 1):
		if guards_placed >= 4:
			break
		for x in range(1, level.width - 1):
			if guards_placed >= 4:
				break
			var pos := Vector2i(x, y)
			var tile: int = level.get_tile(pos)
			if tile != Level.Tile.DOOR_CLOSED and tile != Level.Tile.DOOR_LOCKED and tile != Level.Tile.DOOR_JAMMED:
				continue
			if randf() > guard_chance:
				continue

			# Find adjacent floor tile for the guard
			var placed: bool = false
			var shuffled_dirs: Array[Vector2i] = cardinal_dirs.duplicate()
			shuffled_dirs.shuffle()
			for dir: Vector2i in shuffled_dirs:
				var guard_pos: Vector2i = pos + dir
				if level.is_in_bounds(guard_pos) and level.get_tile(guard_pos) == Level.Tile.FLOOR and level.get_entity_at(guard_pos) == null:
					var guard_data: DataManager.MonsterData = DataManager.get_themed_monster_for_depth(depth)
					if guard_data:
						var guard: Monster = monster_scene.instantiate()
						guard.grid_position = guard_pos
						guard.initialize_from_data(guard_data)
						level.add_entity(guard)
						guards_placed += 1
						placed = true
					break

	if guards_placed > 0:
		print("Placed %d door guards at depth %d" % [guards_placed, depth])

# ============================================================================
# LAYER DECORATION SYSTEM
# ============================================================================

## Unified layer decoration dispatcher. Replaces _apply_forest_terrain,
## _apply_themed_rooms, and _generate_poison_streams with a per-layer system.
func _apply_layer_decoration(depth: int) -> void:
	var params: Dictionary = LayerConfig.get_decoration_params(depth)
	var layer_name: String = LayerConfig.get_layer_name(depth)

	# Dispatch to per-layer decorator
	match layer_name:
		"outer_pits":
			_decorate_outer_pits(params)
		"lower_halls":
			_decorate_orc_warrens(params)
		"dark_halls":
			_decorate_torture_halls(params)
		"necropolis":
			_decorate_necropolis(params)
		"pits_of_despair":
			_decorate_wraith_domain(params)
		"inner_sanctum":
			_decorate_inner_sanctum(params)
		"throne_room":
			_decorate_throne_room(params)

	# Scatter layer-themed terrain features on floor tiles
	_scatter_terrain(depth, params)

	# Generate chasms if the layer supports them
	var chasm_min: int = params.get("chasm_count_min", 0)
	var chasm_max: int = params.get("chasm_count_max", 0)
	if chasm_max > 0:
		_generate_chasms(depth, chasm_min, chasm_max)

	print("Applied %s decorations at depth %d" % [layer_name, depth])

## Scatter density-based terrain features on random floor tiles.
func _scatter_terrain(depth: int, params: Dictionary) -> void:
	var density: float = params.get("scatter_density", 0.0)
	if density <= 0.0:
		return

	var layer_name: String = LayerConfig.get_layer_name(depth)
	var scatter_tile: int = _get_scatter_tile_for_layer(layer_name)
	var scattered: int = 0

	for y in range(1, level.height - 1):
		for x in range(1, level.width - 1):
			var pos := Vector2i(x, y)
			if level.get_tile(pos) == Level.Tile.FLOOR and randf() < density:
				level.set_tile(pos, scatter_tile)
				scattered += 1

	if scattered > 0:
		print("Scattered %d terrain tiles at depth %d" % [scattered, depth])

## Get the scatter terrain tile type for a layer.
func _get_scatter_tile_for_layer(layer_name: String) -> int:
	match layer_name:
		"outer_pits": return Level.Tile.VINE_FLOOR
		"lower_halls": return Level.Tile.RUBBLE
		"dark_halls": return Level.Tile.MORGUL_RUNE
		"necropolis": return Level.Tile.BONE_PILE
		"pits_of_despair": return Level.Tile.SHADOW_FLOOR
		"inner_sanctum": return Level.Tile.SHADOW_FLOOR
		"throne_room": return Level.Tile.SHADOW_FLOOR
		_: return Level.Tile.RUBBLE

## Generate chasms using random walk algorithm.
## Safety: only place chasm if 2+ adjacent passable tiles remain.
func _generate_chasms(_depth: int, count_min: int, count_max: int) -> void:
	var chasm_count: int = randi_range(count_min, count_max)
	var total_tiles: int = 0
	var cardinal_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for _c in range(chasm_count):
		var start: Vector2i = level.find_random_floor()
		if start == Vector2i(-1, -1):
			continue

		var walk_len: int = randi_range(4, 10)
		var pos: Vector2i = start
		var walk_dir: Vector2i = cardinal_dirs[randi() % cardinal_dirs.size()]

		for _step in range(walk_len):
			if not level.is_in_bounds(pos):
				break
			if level.get_tile(pos) != Level.Tile.FLOOR:
				break

			# Safety check: ensure 2+ adjacent tiles remain passable after placement
			var adj_passable: int = 0
			for dir: Vector2i in cardinal_dirs:
				var adj: Vector2i = pos + dir
				if level.is_in_bounds(adj) and level.is_passable(adj) and adj != pos:
					adj_passable += 1
			if adj_passable < 2:
				break

			level.set_tile(pos, Level.Tile.CHASM)
			total_tiles += 1

			# 30% chance to change direction
			if randf() < 0.30:
				walk_dir = cardinal_dirs[randi() % cardinal_dirs.size()]
			pos += walk_dir

	if total_tiles > 0:
		print("Generated %d chasm tiles" % total_tiles)

## Helper: check if a tile is safe to overwrite (floor only, not stairs/doors).
func _is_safe_floor(pos: Vector2i) -> bool:
	if not level.is_in_bounds(pos):
		return false
	var tile: int = level.get_tile(pos)
	return tile == Level.Tile.FLOOR

# ============================================================================
# LAYER DECORATORS
# ============================================================================

## Outer Pits (depths 1-3): Forest rooms, tower rooms, web clusters, poison streams.
func _decorate_outer_pits(params: Dictionary) -> void:
	var themed_chance: float = params.get("themed_room_chance", 0.60)
	var web_chance: float = params.get("web_chance", 0.15)

	for room_rect: Rect2i in rooms:
		if room_rect.size.x < 4 or room_rect.size.y < 4:
			continue
		if randf() > themed_chance:
			continue

		# Pick decoration: 40% forest, 30% tower, 30% web cluster
		var roll: float = randf()
		if roll < 0.40:
			_decorate_forest_room(room_rect)
		elif roll < 0.70:
			_decorate_tower_room(room_rect)
		else:
			# Web cluster: place 3-6 WEB tiles in a cluster
			_place_web_cluster(room_rect)

	# Scatter poison streams (1-2 winding streams)
	_scatter_poison_streams()

## Forest room: scatter tree pillars (wall tiles) inside, convert 40% floor to vine floor.
func _decorate_forest_room(room_rect: Rect2i) -> void:
	var area: int = room_rect.size.x * room_rect.size.y
	var tree_count: int = maxi(1, area / 12)

	for _i in range(tree_count):
		var tx: int = randi_range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 2)
		var ty: int = randi_range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 2)
		var tpos := Vector2i(tx, ty)
		if _is_safe_floor(tpos):
			level.set_tile(tpos, Level.Tile.WALL)

	for y in range(room_rect.position.y, room_rect.position.y + room_rect.size.y):
		for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
			var pos := Vector2i(x, y)
			if level.get_tile(pos) == Level.Tile.FLOOR and randf() < 0.40:
				level.set_tile(pos, Level.Tile.VINE_FLOOR)

## Tower room: stone pillar grid (every 3rd tile), rubble near walls.
func _decorate_tower_room(room_rect: Rect2i) -> void:
	for y in range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 1):
		for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
			var local_x: int = x - room_rect.position.x
			var local_y: int = y - room_rect.position.y
			if local_x % 3 == 0 and local_y % 3 == 0:
				var pos := Vector2i(x, y)
				if _is_safe_floor(pos):
					level.set_tile(pos, Level.Tile.WALL)

	for y in range(room_rect.position.y, room_rect.position.y + room_rect.size.y):
		for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
			var local_x: int = x - room_rect.position.x
			var local_y: int = y - room_rect.position.y
			var near_edge: bool = (local_x <= 1 or local_x >= room_rect.size.x - 2 or
								   local_y <= 1 or local_y >= room_rect.size.y - 2)
			if near_edge:
				var pos := Vector2i(x, y)
				if _is_safe_floor(pos) and randf() < 0.25:
					level.set_tile(pos, Level.Tile.RUBBLE)

## Place a cluster of 3-6 WEB tiles in a room.
func _place_web_cluster(room_rect: Rect2i) -> void:
	var center := Vector2i(
		randi_range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 2),
		randi_range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 2)
	)
	var count: int = randi_range(3, 6)
	var placed: int = 0
	if _is_safe_floor(center):
		level.set_tile(center, Level.Tile.WEB)
		placed += 1

	var offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	offsets.shuffle()
	for i in range(mini(count - 1, offsets.size())):
		var web_pos: Vector2i = center + offsets[i]
		if _is_safe_floor(web_pos):
			level.set_tile(web_pos, Level.Tile.WEB)
			placed += 1

## Scatter 1-2 winding poison streams through rooms.
func _scatter_poison_streams() -> void:
	if rooms.is_empty():
		return
	var stream_count: int = randi_range(1, 2)
	var cardinal_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for _s in range(stream_count):
		var start_room: Rect2i = rooms[randi() % rooms.size()]
		var pos := Vector2i(
			randi_range(start_room.position.x + 1, start_room.position.x + start_room.size.x - 2),
			randi_range(start_room.position.y + 1, start_room.position.y + start_room.size.y - 2)
		)
		if not level.is_in_bounds(pos):
			continue

		var walk_length: int = randi_range(8, 15)
		var current_dir: Vector2i = cardinal_dirs[randi() % cardinal_dirs.size()]

		for _step in range(walk_length):
			if not level.is_in_bounds(pos):
				break
			var tile: int = level.get_tile(pos)
			if tile == Level.Tile.FLOOR or tile == Level.Tile.VINE_FLOOR:
				level.set_tile(pos, Level.Tile.POISON_STREAM)
			if randf() < 0.40:
				current_dir = cardinal_dirs[randi() % cardinal_dirs.size()]
			pos += current_dir

## Orc Warrens (depths 4-6): Barracks, armories, kennels.
func _decorate_orc_warrens(params: Dictionary) -> void:
	var themed_chance: float = params.get("themed_room_chance", 0.50)
	var subtypes: Array[String] = ["barracks", "armory", "kennel"]

	for room_rect: Rect2i in rooms:
		if room_rect.size.x < 4 or room_rect.size.y < 4:
			continue
		if randf() > themed_chance:
			continue

		var subtype: String = subtypes[randi() % subtypes.size()]
		match subtype:
			"barracks":
				# Rubble bunk rows along walls
				for y in range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 1):
					for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
						var local_x: int = x - room_rect.position.x
						if local_x <= 1 or local_x >= room_rect.size.x - 2:
							var pos := Vector2i(x, y)
							if _is_safe_floor(pos) and randf() < 0.50:
								level.set_tile(pos, Level.Tile.RUBBLE)
			"armory":
				# Central forge + rubble corner racks
				var cx: int = room_rect.position.x + room_rect.size.x / 2
				var cy: int = room_rect.position.y + room_rect.size.y / 2
				var forge_pos := Vector2i(cx, cy)
				if _is_safe_floor(forge_pos):
					level.set_tile(forge_pos, Level.Tile.FORGE)
				# Rubble in corners
				var corners: Array[Vector2i] = [
					Vector2i(room_rect.position.x + 1, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + 1, room_rect.position.y + room_rect.size.y - 2),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + room_rect.size.y - 2)
				]
				for corner: Vector2i in corners:
					if _is_safe_floor(corner):
						level.set_tile(corner, Level.Tile.RUBBLE)
			"kennel":
				# Water tiles in center + bone piles around edges
				var cx: int = room_rect.position.x + room_rect.size.x / 2
				var cy: int = room_rect.position.y + room_rect.size.y / 2
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var wpos := Vector2i(cx + dx, cy + dy)
						if _is_safe_floor(wpos):
							level.set_tile(wpos, Level.Tile.WATER)
				# Bone piles near edges
				for y in range(room_rect.position.y, room_rect.position.y + room_rect.size.y):
					for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
						var local_x: int = x - room_rect.position.x
						var local_y: int = y - room_rect.position.y
						var near_edge: bool = (local_x == 0 or local_x == room_rect.size.x - 1 or
											   local_y == 0 or local_y == room_rect.size.y - 1)
						if near_edge:
							var pos := Vector2i(x, y)
							if _is_safe_floor(pos) and randf() < 0.30:
								level.set_tile(pos, Level.Tile.BONE_PILE)

## Torture Halls (depths 7-9): Ritual chambers, torture rooms, rune corridors.
func _decorate_torture_halls(params: Dictionary) -> void:
	var themed_chance: float = params.get("themed_room_chance", 0.55)
	var subtypes: Array[String] = ["ritual_chamber", "torture_room", "rune_corridor"]

	for room_rect: Rect2i in rooms:
		if room_rect.size.x < 4 or room_rect.size.y < 4:
			continue
		if randf() > themed_chance:
			continue

		var subtype: String = subtypes[randi() % subtypes.size()]
		var cx: int = room_rect.position.x + room_rect.size.x / 2
		var cy: int = room_rect.position.y + room_rect.size.y / 2
		match subtype:
			"ritual_chamber":
				# Dark pool center
				if _is_safe_floor(Vector2i(cx, cy)):
					level.set_tile(Vector2i(cx, cy), Level.Tile.DARK_POOL)
				# Morgul rune ring (cross pattern around center)
				var rune_offsets: Array[Vector2i] = [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)]
				for off: Vector2i in rune_offsets:
					var rpos := Vector2i(cx + off.x, cy + off.y)
					if _is_safe_floor(rpos):
						level.set_tile(rpos, Level.Tile.MORGUL_RUNE)
				# Shadow braziers in corners
				var corners: Array[Vector2i] = [
					Vector2i(room_rect.position.x + 1, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + 1, room_rect.position.y + room_rect.size.y - 2),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + room_rect.size.y - 2)
				]
				for corner: Vector2i in corners:
					if _is_safe_floor(corner):
						level.set_tile(corner, Level.Tile.SHADOW_BRAZIER)
			"torture_room":
				# Scattered rubble + dark pools
				for y in range(room_rect.position.y, room_rect.position.y + room_rect.size.y):
					for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
						var pos := Vector2i(x, y)
						if _is_safe_floor(pos):
							if randf() < 0.15:
								level.set_tile(pos, Level.Tile.RUBBLE)
							elif randf() < 0.08:
								level.set_tile(pos, Level.Tile.DARK_POOL)
			"rune_corridor":
				# Morgul runes along corridor tiles every 3rd tile
				for y in range(room_rect.position.y, room_rect.position.y + room_rect.size.y):
					for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
						var local_x: int = x - room_rect.position.x
						var local_y: int = y - room_rect.position.y
						if (local_x % 3 == 0 or local_y % 3 == 0) and (local_x % 3 == 0 and local_y % 3 == 0):
							var pos := Vector2i(x, y)
							if _is_safe_floor(pos):
								level.set_tile(pos, Level.Tile.MORGUL_RUNE)

## Necropolis (depths 10-12): Crypts, bone chambers, ritual circles.
func _decorate_necropolis(params: Dictionary) -> void:
	var themed_chance: float = params.get("themed_room_chance", 0.65)
	var subtypes: Array[String] = ["crypt", "bone_chamber", "ritual_circle"]

	for room_rect: Rect2i in rooms:
		if room_rect.size.x < 4 or room_rect.size.y < 4:
			continue
		if randf() > themed_chance:
			continue

		var subtype: String = subtypes[randi() % subtypes.size()]
		var cx: int = room_rect.position.x + room_rect.size.x / 2
		var cy: int = room_rect.position.y + room_rect.size.y / 2
		match subtype:
			"crypt":
				# Pillar grid (every 3 tiles) + bone piles between pillars
				for y in range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 1):
					for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
						var local_x: int = x - room_rect.position.x
						var local_y: int = y - room_rect.position.y
						var pos := Vector2i(x, y)
						if local_x % 3 == 0 and local_y % 3 == 0:
							if _is_safe_floor(pos):
								level.set_tile(pos, Level.Tile.WALL)
						elif _is_safe_floor(pos) and randf() < 0.20:
							level.set_tile(pos, Level.Tile.BONE_PILE)
			"bone_chamber":
				# 40% of floor becomes bone pile tiles
				for y in range(room_rect.position.y, room_rect.position.y + room_rect.size.y):
					for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
						var pos := Vector2i(x, y)
						if _is_safe_floor(pos) and randf() < 0.40:
							level.set_tile(pos, Level.Tile.BONE_PILE)
			"ritual_circle":
				# Glyph of warding tiles in a diamond pattern in room center
				var radius: int = mini(room_rect.size.x, room_rect.size.y) / 3
				radius = maxi(radius, 2)
				for dy in range(-radius, radius + 1):
					for dx in range(-radius, radius + 1):
						if abs(dx) + abs(dy) == radius:
							var gpos := Vector2i(cx + dx, cy + dy)
							if _is_safe_floor(gpos):
								level.set_tile(gpos, Level.Tile.GLYPH_OF_WARDING)

## Wraith Domain / Pits of Despair (depths 13-15): Void chambers, shadow galleries, chasm bridges.
func _decorate_wraith_domain(params: Dictionary) -> void:
	var themed_chance: float = params.get("themed_room_chance", 0.70)
	var subtypes: Array[String] = ["void_chamber", "shadow_gallery", "chasm_bridge"]

	for room_rect: Rect2i in rooms:
		if room_rect.size.x < 5 or room_rect.size.y < 5:
			continue
		if randf() > themed_chance:
			continue

		var subtype: String = subtypes[randi() % subtypes.size()]
		var cx: int = room_rect.position.x + room_rect.size.x / 2
		var cy: int = room_rect.position.y + room_rect.size.y / 2
		match subtype:
			"void_chamber":
				# Chasm ring around room edges + shadow floor inside
				for y in range(room_rect.position.y, room_rect.position.y + room_rect.size.y):
					for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
						var local_x: int = x - room_rect.position.x
						var local_y: int = y - room_rect.position.y
						var pos := Vector2i(x, y)
						var is_edge: bool = (local_x == 1 or local_x == room_rect.size.x - 2 or
											 local_y == 1 or local_y == room_rect.size.y - 2)
						var is_inner: bool = (local_x > 1 and local_x < room_rect.size.x - 2 and
											  local_y > 1 and local_y < room_rect.size.y - 2)
						if is_edge and _is_safe_floor(pos):
							level.set_tile(pos, Level.Tile.CHASM)
						elif is_inner and _is_safe_floor(pos):
							level.set_tile(pos, Level.Tile.SHADOW_FLOOR)
			"shadow_gallery":
				# Shadow brazier rows + dark pools between them
				_place_shadow_gallery(room_rect)
			"chasm_bridge":
				# Chasm across room with 1-tile-wide floor bridge
				var bridge_y: int = cy
				for y in range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 1):
					for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
						var pos := Vector2i(x, y)
						if y != bridge_y and _is_safe_floor(pos):
							level.set_tile(pos, Level.Tile.CHASM)

## Helper: place shadow gallery pattern (brazier rows + dark pools between).
func _place_shadow_gallery(room_rect: Rect2i) -> void:
	for y in range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 1):
		for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
			var local_x: int = x - room_rect.position.x
			var local_y: int = y - room_rect.position.y
			var pos := Vector2i(x, y)
			if local_x % 4 == 0 and local_y % 3 == 0:
				if _is_safe_floor(pos):
					level.set_tile(pos, Level.Tile.SHADOW_BRAZIER)
			elif local_x % 4 == 2 and _is_safe_floor(pos) and randf() < 0.30:
				level.set_tile(pos, Level.Tile.DARK_POOL)

## Inner Sanctum (depths 16-18): Grand halls, guard posts, lava chambers.
func _decorate_inner_sanctum(params: Dictionary) -> void:
	var themed_chance: float = params.get("themed_room_chance", 0.80)
	var subtypes: Array[String] = ["grand_hall", "guard_post", "lava_chamber"]

	for room_rect: Rect2i in rooms:
		if room_rect.size.x < 5 or room_rect.size.y < 5:
			continue
		if randf() > themed_chance:
			continue

		var subtype: String = subtypes[randi() % subtypes.size()]
		var cx: int = room_rect.position.x + room_rect.size.x / 2
		var cy: int = room_rect.position.y + room_rect.size.y / 2
		match subtype:
			"grand_hall":
				# Symmetric pillars (wall tiles) + dark pool center + shadow braziers at corners
				for y in range(room_rect.position.y + 2, room_rect.position.y + room_rect.size.y - 2):
					for x in range(room_rect.position.x + 2, room_rect.position.x + room_rect.size.x - 2):
						var local_x: int = x - room_rect.position.x
						var local_y: int = y - room_rect.position.y
						var pos := Vector2i(x, y)
						if local_x % 4 == 2 and (local_y == 2 or local_y == room_rect.size.y - 3):
							if _is_safe_floor(pos):
								level.set_tile(pos, Level.Tile.WALL)
				# Dark pool center
				if _is_safe_floor(Vector2i(cx, cy)):
					level.set_tile(Vector2i(cx, cy), Level.Tile.DARK_POOL)
				# Shadow braziers at corners
				var corners: Array[Vector2i] = [
					Vector2i(room_rect.position.x + 1, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + 1, room_rect.position.y + room_rect.size.y - 2),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + room_rect.size.y - 2)
				]
				for corner: Vector2i in corners:
					if _is_safe_floor(corner):
						level.set_tile(corner, Level.Tile.SHADOW_BRAZIER)
			"guard_post":
				# Rubble barricade near door + lava accents in corners
				# Barricade: rubble row across the room's narrower axis
				var barricade_y: int = cy - 1
				for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
					var pos := Vector2i(x, barricade_y)
					if _is_safe_floor(pos) and randf() < 0.60:
						level.set_tile(pos, Level.Tile.RUBBLE)
				# Lava in corners
				var corners: Array[Vector2i] = [
					Vector2i(room_rect.position.x + 1, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + 1, room_rect.position.y + room_rect.size.y - 2),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + room_rect.size.y - 2)
				]
				for corner: Vector2i in corners:
					if _is_safe_floor(corner):
						level.set_tile(corner, Level.Tile.LAVA)
			"lava_chamber":
				# Lava pool center with rubble ring
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var lpos := Vector2i(cx + dx, cy + dy)
						if _is_safe_floor(lpos):
							level.set_tile(lpos, Level.Tile.LAVA)
				# Rubble ring around lava
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if abs(dx) == 2 or abs(dy) == 2:
							var rpos := Vector2i(cx + dx, cy + dy)
							if _is_safe_floor(rpos):
								level.set_tile(rpos, Level.Tile.RUBBLE)

## Throne Room (depths 19-20): Throne chambers, antechambers, lava moats.
func _decorate_throne_room(params: Dictionary) -> void:
	var themed_chance: float = params.get("themed_room_chance", 1.0)
	var subtypes: Array[String] = ["throne_chamber", "antechamber", "lava_moat"]

	for room_rect: Rect2i in rooms:
		if room_rect.size.x < 5 or room_rect.size.y < 5:
			continue
		if randf() > themed_chance:
			continue

		var subtype: String = subtypes[randi() % subtypes.size()]
		var cx: int = room_rect.position.x + room_rect.size.x / 2
		var cy: int = room_rect.position.y + room_rect.size.y / 2
		match subtype:
			"throne_chamber":
				# 3x3 throne dais center
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var dpos := Vector2i(cx + dx, cy + dy)
						if _is_safe_floor(dpos):
							level.set_tile(dpos, Level.Tile.THRONE_DAIS)
				# Lava moat ring (2 tiles out from center)
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						if (abs(dx) == 3 or abs(dy) == 3) and abs(dx) <= 3 and abs(dy) <= 3:
							var mpos := Vector2i(cx + dx, cy + dy)
							if _is_safe_floor(mpos):
								level.set_tile(mpos, Level.Tile.LAVA)
				# Pillar rows flanking (2 columns of pillars)
				for y in range(room_rect.position.y + 2, room_rect.position.y + room_rect.size.y - 2):
					var local_y: int = y - room_rect.position.y
					if local_y % 3 == 0:
						var left_pos := Vector2i(room_rect.position.x + 2, y)
						var right_pos := Vector2i(room_rect.position.x + room_rect.size.x - 3, y)
						if _is_safe_floor(left_pos):
							level.set_tile(left_pos, Level.Tile.WALL)
						if _is_safe_floor(right_pos):
							level.set_tile(right_pos, Level.Tile.WALL)
			"antechamber":
				# Reuse shadow gallery pattern
				_place_shadow_gallery(room_rect)
			"lava_moat":
				# Lava ring around room perimeter (1 tile in from walls)
				for y in range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 1):
					for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
						var local_x: int = x - room_rect.position.x
						var local_y: int = y - room_rect.position.y
						var is_moat: bool = (local_x == 1 or local_x == room_rect.size.x - 2 or
											 local_y == 1 or local_y == room_rect.size.y - 2)
						if is_moat:
							var pos := Vector2i(x, y)
							if _is_safe_floor(pos):
								level.set_tile(pos, Level.Tile.LAVA)

# ============================================================================
# LORE OBJECT SPAWNING
# ============================================================================

## Spawn 1-3 lore objects (tval=2, IDs 500-557) per floor based on depth.
func _spawn_lore_objects(depth: int) -> void:
	var count: int = randi_range(1, 3)

	# Build list of eligible lore items by scanning DataManager's items
	var eligible: Array[DataManager.ItemData] = []
	for item_data: DataManager.ItemData in DataManager.items.values():
		if item_data.tval == 2 and item_data.index >= 500 and item_data.index <= 557:
			if item_data.depth <= depth:
				eligible.append(item_data)

	if eligible.is_empty():
		return

	var item_scene := preload("res://scenes/entities/item.tscn")
	var spawned: int = 0

	for _i in range(count):
		var lore_data: DataManager.ItemData = eligible.pick_random()
		var spawn_pos: Vector2i = level.find_random_floor()
		if spawn_pos == Vector2i(-1, -1):
			continue

		var lore_copy: DataManager.ItemData = DataManager.duplicate_item_data(lore_data)
		var item: Item = item_scene.instantiate()
		item.grid_position = spawn_pos
		item.initialize_from_item_data(lore_copy)
		level.add_item(item)
		spawned += 1

	if spawned > 0:
		print("Spawned %d lore objects at depth %d" % [spawned, depth])

# ============================================================================
# NPC SPAWNING
# ============================================================================

func spawn_thrain_if_appropriate(depth: int, quest_system: Node) -> bool:
	"""Spawn Thrain II if conditions are met. Returns true if spawned.
	   quest_system: Node with can_spawn_thrain() and mark_thrain_spawned() methods."""
	if not quest_system:
		return false

	if not quest_system.can_spawn_thrain(depth):
		return false

	# Find a good room for Thrain (preferably not the first or last room)
	if rooms.size() < 3:
		return false

	# Pick a room in the middle of the dungeon
	var room_index := randi_range(1, rooms.size() - 2)
	var thrain_room := rooms[room_index]

	# Find center of room
	var spawn_pos := Vector2i(
		thrain_room.position.x + thrain_room.size.x / 2,
		thrain_room.position.y + thrain_room.size.y / 2
	)

	# Make sure the position is valid
	if level.get_tile(spawn_pos) != Level.Tile.FLOOR:
		# Try to find a floor tile in the room
		for y in range(thrain_room.position.y, thrain_room.position.y + thrain_room.size.y):
			for x in range(thrain_room.position.x, thrain_room.position.x + thrain_room.size.x):
				var check_pos := Vector2i(x, y)
				if level.get_tile(check_pos) == Level.Tile.FLOOR and level.get_entity_at(check_pos) == null:
					spawn_pos = check_pos
					break

	# Load ThrainNPC script at runtime to avoid circular dependency issues
	var thrain_script: GDScript = load("res://scripts/entities/thrain_npc.gd")
	if thrain_script == null:
		push_error("Failed to load thrain_npc.gd")
		return false

	# Create Thrain using the static factory method
	var thrain: Node = thrain_script.create_at_position(spawn_pos, quest_system)
	level.add_entity(thrain)

	quest_system.mark_thrain_spawned()
	print("Spawned Thrain II at depth %d, position %s" % [depth, spawn_pos])

	return true

# ============================================================================
# ARTIFACT SPAWNING
# ============================================================================

## Depth-gated spawn chance for unique artifacts.
## Each artifact can only appear once per game run.
func _spawn_artifacts(depth: int) -> void:
	# Depth-gated spawn chance
	var spawn_chance: float = 0.0
	if depth >= 5 and depth <= 8:
		spawn_chance = 0.05
	elif depth >= 9 and depth <= 12:
		spawn_chance = 0.08
	elif depth >= 13 and depth <= 16:
		spawn_chance = 0.12
	elif depth >= 17:
		spawn_chance = 0.18

	if spawn_chance <= 0.0:
		return

	if randf() > spawn_chance:
		return

	# Build list of eligible artifacts
	var eligible: Array = []
	for artifact: DataManager.ArtifactData in DataManager.artifacts.values():
		# Skip quest artifacts (indices 175-198)
		if artifact.index >= 175 and artifact.index <= 198:
			continue
		# Skip already-spawned artifacts
		if artifact.index in GameManager.spawned_artifacts:
			continue
		# Depth eligibility: artifact.depth <= current_depth + 2
		if artifact.depth > depth + 2:
			continue
		eligible.append(artifact)

	if eligible.is_empty():
		return

	# Weighted random selection: weight = 1.0 / rarity
	var total_weight: float = 0.0
	var weights: Array[float] = []
	for a: DataManager.ArtifactData in eligible:
		var w: float = 1.0 / maxf(float(a.rarity), 1.0)
		weights.append(w)
		total_weight += w

	if total_weight <= 0.0:
		return

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	var chosen: DataManager.ArtifactData = eligible[0]
	for i in range(eligible.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			chosen = eligible[i]
			break

	# Find placement position: prefer last room (farthest from entry stairs)
	var spawn_pos: Vector2i = Vector2i(-1, -1)

	if rooms.size() > 2:
		# Use last room (usually farthest from stairs up which is in first room)
		var target_room: Rect2i = rooms[rooms.size() - 1]
		spawn_pos = Vector2i(
			target_room.position.x + target_room.size.x / 2,
			target_room.position.y + target_room.size.y / 2
		)
		if not level.is_in_bounds(spawn_pos) or level.get_tile(spawn_pos) != Level.Tile.FLOOR:
			spawn_pos = _find_floor_in_room(target_room)

	# Fallback: random floor tile
	if spawn_pos == Vector2i(-1, -1):
		spawn_pos = level.find_random_floor()

	if spawn_pos == Vector2i(-1, -1):
		return

	# Spawn the artifact
	var item_scene := preload("res://scenes/entities/item.tscn")
	var item: Item = item_scene.instantiate()
	item.grid_position = spawn_pos
	item.initialize_from_artifact_data(chosen)
	level.add_item(item)

	# Track that this artifact has been spawned
	GameManager.spawned_artifacts.append(chosen.index)

	print("Spawned artifact '%s' (idx %d) at depth %d, pos %s" % [
		chosen.name, chosen.index, depth, spawn_pos
	])

func _find_floor_in_room(room_rect: Rect2i) -> Vector2i:
	for y in range(room_rect.position.y, room_rect.position.y + room_rect.size.y):
		for x in range(room_rect.position.x, room_rect.position.x + room_rect.size.x):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos) and level.get_tile(pos) == Level.Tile.FLOOR:
				return pos
	return Vector2i(-1, -1)

# ============================================================================
# SPECIAL LEVELS (Stream F)
# ============================================================================

## Generate the Throne Room level (depth 20) — Sauron's final chamber.
## Attempts to place a special throne vault; falls back to normal generation.
func _generate_throne_room_level(depth: int) -> void:
	_apply_layer_params(depth)

	# Fill with walls
	for y in range(level.height):
		for x in range(level.width):
			level.set_tile(Vector2i(x, y), Level.Tile.WALL)

	# Try to find Sauron's throne vault (index 450, or vault_type 9)
	var throne_vault: DataManager.VaultData = null
	for vault: DataManager.VaultData in DataManager.vaults:
		if vault.index == 450:
			throne_vault = vault
			break

	# Fallback: search by vault_type 9
	if throne_vault == null:
		for vault: DataManager.VaultData in DataManager.vaults:
			if vault.vault_type == 9:
				throne_vault = vault
				break

	if throne_vault != null and not throne_vault.map_lines.is_empty():
		# Place vault centered in the map
		var vx: int = level.width / 2 - throne_vault.width / 2
		var vy: int = level.height / 2 - throne_vault.height / 2
		var vault_pos := Vector2i(vx, vy)

		if _can_place_vault_at(vault_pos, throne_vault):
			_carve_vault(vault_pos, throne_vault, depth)
			print("Placed Sauron's throne vault at depth %d" % depth)
		else:
			# Vault doesn't fit — fall through to normal generation
			_fallback_throne_room(depth)
	else:
		# No throne vault found — generate a basic large room
		_fallback_throne_room(depth)

	# Place stairs up in a corner — no stairs down on the final level
	var up_pos := Vector2i(2, 2)
	# Find a floor tile near corner
	for y in range(1, level.height / 4):
		for x in range(1, level.width / 4):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos) and level.get_tile(pos) == Level.Tile.FLOOR:
				up_pos = pos
				break
		if level.get_tile(up_pos) == Level.Tile.FLOOR:
			break

	if level.is_in_bounds(up_pos):
		level.set_tile(up_pos, Level.Tile.FLOOR)
		level.set_tile(up_pos, Level.Tile.STAIRS_UP)

	# Assign room data
	_assign_room_data(depth)

	# Apply decoration
	_apply_layer_decoration(depth)

	# Spawn themed content
	_spawn_monsters(depth)
	_spawn_items(depth)
	_spawn_artifacts(depth)
	_spawn_lore_objects(depth)

	level.generation_complete.emit(level.width, level.height)

## Fallback throne room when no vault is available.
func _fallback_throne_room(depth: int) -> void:
	# Create one large room in the center
	var room_w: int = mini(30, level.width - 4)
	var room_h: int = mini(20, level.height - 4)
	var room_x: int = (level.width - room_w) / 2
	var room_y: int = (level.height - room_h) / 2

	for y in range(room_y, room_y + room_h):
		for x in range(room_x, room_x + room_w):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.Tile.FLOOR)

	rooms.append(Rect2i(room_x, room_y, room_w, room_h))
	print("Generated fallback throne room at depth %d" % depth)

## Force-place transition vaults at layer boundaries.
## Boundary depths map to specific vault indices.
func _try_place_transition_vault(depth: int) -> void:
	var transition_vaults: Dictionary = {
		3: 200, 6: 201, 9: 202, 12: 203, 15: 204, 18: 205
	}

	if depth not in transition_vaults:
		return

	# 50% chance to place
	if randf() > 0.50:
		return

	var vault_index: int = transition_vaults[depth]

	# Find vault by index
	var vault: DataManager.VaultData = null
	for v: DataManager.VaultData in DataManager.vaults:
		if v.index == vault_index:
			vault = v
			break

	if vault == null or vault.map_lines.is_empty():
		return

	# Try to place at random position (20 attempts)
	for _attempt in range(20):
		var start_x: int = randi_range(2, level.width - vault.width - 2)
		var start_y: int = randi_range(2, level.height - vault.height - 2)
		var pos := Vector2i(start_x, start_y)

		if _can_place_vault_at(pos, vault):
			_carve_vault(pos, vault, depth)
			rooms.append(Rect2i(pos.x, pos.y, vault.width, vault.height))
			print("Placed transition vault %d at depth %d" % [vault_index, depth])
			return

# ============================================================================
# WINDING CORRIDORS (Stream F)
# ============================================================================

## Carve a winding corridor from one point to another using random walk
## with drift toward the target. 30% perpendicular deviation chance.
func _carve_winding_corridor(from: Vector2i, to: Vector2i) -> void:
	var pos: Vector2i = from
	var max_steps: int = abs(to.x - from.x) + abs(to.y - from.y) + 20  # budget
	var half_width: int = corridor_width / 2

	for _step in range(max_steps):
		# Carve at current position (with corridor width)
		for dy in range(-half_width, half_width + 1):
			for dx in range(-half_width, half_width + 1):
				var carve_pos := Vector2i(pos.x + dx, pos.y + dy)
				if level.is_in_bounds(carve_pos):
					level.set_tile(carve_pos, Level.Tile.FLOOR)

		# Check if we've reached the target
		if pos == to:
			break

		# Determine preferred direction toward target
		var diff: Vector2i = to - pos
		var move: Vector2i = Vector2i.ZERO

		if randf() < 0.30:
			# Perpendicular deviation
			if abs(diff.x) >= abs(diff.y):
				# Moving mostly horizontally — deviate vertically
				move = Vector2i(0, 1 if randf() < 0.5 else -1)
			else:
				# Moving mostly vertically — deviate horizontally
				move = Vector2i(1 if randf() < 0.5 else -1, 0)
		else:
			# Move toward target
			if abs(diff.x) > abs(diff.y):
				move = Vector2i(1 if diff.x > 0 else -1, 0)
			elif abs(diff.y) > 0:
				move = Vector2i(0, 1 if diff.y > 0 else -1)
			else:
				break  # Already at target

		pos += move

		# Safety: don't go out of bounds
		pos.x = clampi(pos.x, 1, level.width - 2)
		pos.y = clampi(pos.y, 1, level.height - 2)

# ============================================================================
# EGO ENCHANTMENT FOR FLOOR ITEMS
# ============================================================================

## Apply random ego enchantment to a floor-spawned item based on depth
func _apply_floor_ego(item: DataManager.ItemData, depth: int) -> void:
	var tval: int = item.tval
	var is_weapon: bool = tval >= 20 and tval <= 23
	var is_armor: bool = tval >= 30 and tval <= 37
	var is_jewelry: bool = tval == 39 or tval == 40 or tval == 45

	# Quality scales with depth: 1 for shallow, 2 for deep
	var quality: int = 1
	if depth >= 10:
		quality = 2

	if is_weapon:
		item.attack_bonus += quality
		var ego_names: Array[String] = ["Keen", "Sharp", "Deadly", "Vicious", "Bright"]
		if quality >= 2:
			ego_names = ["Masterwork", "Radiant", "Fell", "Elven", "Ancient"]
		item.name = "%s %s" % [ego_names.pick_random(), item.name]
	elif is_armor:
		item.evasion_bonus += quality
		var ego_names: Array[String] = ["Sturdy", "Reinforced", "Warded", "Tempered"]
		if quality >= 2:
			ego_names = ["Mithril-forged", "Enchanted", "Blessed", "Ancient"]
		item.name = "%s %s" % [ego_names.pick_random(), item.name]
	elif is_jewelry:
		item.pval += quality
		var ego_names: Array[String] = ["Gleaming", "Enchanted", "Elven", "Ancient"]
		item.name = "%s %s" % [ego_names.pick_random(), item.name]
