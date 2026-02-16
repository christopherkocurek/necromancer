extends RefCounted
class_name DungeonGenerator
## Procedural dungeon generation for The Necromancer.
## Based on classic roguelike room-and-corridor generation.

# Default values (overridden by LayerConfig per depth)
const DEFAULT_MIN_ROOM_SIZE := 4
const DEFAULT_MAX_ROOM_SIZE := 12
const DEFAULT_MAX_ROOMS := 30
const ROOM_PLACEMENT_ATTEMPTS := 100
const MAX_FORGES_PER_FLOOR := 2

enum RoomType {
	STANDARD = 0,
	CROSS = 1,
	L_SHAPE = 2,
	CIRCULAR = 3,
	CAVE = 4,         # Cellular automata irregular shape (Outer Pits)
	ALCOVE = 5,       # Rectangle with wall alcoves (Necropolis)
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
var _vault_room_ids: Dictionary = {}
var _vault_rects: Array[Rect2i] = []

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
	# Layer-weighted room type selection
	var layer_name: String = LayerConfig.get_layer_name(depth)

	# Layer-specific room shape preferences (checked first)
	match layer_name:
		"outer_pits":
			# 30% chance of natural cave rooms
			if randf() < 0.30:
				return RoomType.CAVE
		"necropolis":
			# 25% chance of alcove/crypt rooms
			if randf() < 0.25:
				return RoomType.ALCOVE
		"pits_of_despair":
			# 15% cave rooms (irregular chasms)
			if randf() < 0.15:
				return RoomType.CAVE

	# Standard depth-weighted selection (C version logic)
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
	_vault_room_ids.clear()
	_vault_rects.clear()

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
		_vault_room_ids.clear()
		_vault_rects.clear()

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

	# Place baseline forges before features so later decoration works around them.
	_ensure_forges(depth)

	# Add features based on depth (rubble/traps avoid forge tiles)
	_add_features(depth)

	# Place themed guards near doors
	_place_door_guards(depth)

	# Apply layer-specific decoration
	_apply_layer_decoration(depth)
	_finalize_forges(depth)

	# Spawn smithing materials near forges LAST (finds passable tiles after all decoration)
	_spawn_forge_materials(depth)

	# Scatter environmental storytelling (flavor messages on tiles)
	_scatter_storytelling(depth)

	# Post-decoration: ensure stairs remain connected (decoration can break paths)
	_ensure_stairs_connectivity(depth)
	_sanitize_doors_after_decoration()

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

	# Final safety sweep: clear monsters near stairs (catches everything including vaults/guards)
	var stairs_up: Vector2i = level.find_stairs_up()
	_clear_monsters_near_stairs(stairs_up)

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
					_vault_room_ids[rooms.size() - 1] = true
					_vault_rects.append(vault_room.rect)
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
			RoomType.CAVE:
				new_room = _generate_cave_room(room_x, room_y, room_width, room_height)
			RoomType.ALCOVE:
				new_room = _generate_alcove_room(room_x, room_y, room_width, room_height)
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
			# Cross, circular, cave, and alcove rooms are carved during generation
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

## Generate a cave room using cellular automata (natural irregular shapes).
## Used primarily in Outer Pits for organic cave feeling.
func _generate_cave_room(pos_x: int, pos_y: int, w: int, h: int) -> Room:
	# Ensure minimum size for cellular automata to produce interesting shapes
	w = maxi(w, 6)
	h = maxi(h, 6)

	# Clamp to level bounds
	if pos_x + w >= level.width - 1:
		w = level.width - pos_x - 2
	if pos_y + h >= level.height - 1:
		h = level.height - pos_y - 2

	var room := Room.new(Rect2i(pos_x, pos_y, w, h))
	room.room_type = RoomType.CAVE

	# Step 1: Random fill — 45% chance each cell starts as floor
	var grid: Array[bool] = []  # true = floor, false = wall
	grid.resize(w * h)
	for i in range(w * h):
		grid[i] = randf() < 0.45

	# Ensure edges are walls
	for x in range(w):
		grid[x] = false              # top row
		grid[(h - 1) * w + x] = false  # bottom row
	for y in range(h):
		grid[y * w] = false              # left column
		grid[y * w + (w - 1)] = false    # right column

	# Step 2: Cellular automata smoothing (4 iterations, 4-5 rule)
	for _iteration in range(4):
		var new_grid: Array[bool] = grid.duplicate()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var wall_neighbors: int = 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx < 0 or nx >= w or ny < 0 or ny >= h or not grid[ny * w + nx]:
							wall_neighbors += 1
				# 4-5 rule: become wall if 5+ wall neighbors, floor if <4
				if wall_neighbors >= 5:
					new_grid[y * w + x] = false
				elif wall_neighbors < 4:
					new_grid[y * w + x] = true
		grid = new_grid

	# Step 3: Ensure center is always floor (connectivity anchor)
	var center_x: int = w / 2
	var center_y: int = h / 2
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var ci: int = (center_y + dy) * w + (center_x + dx)
			if ci >= 0 and ci < grid.size():
				grid[ci] = true

	# Step 4: Carve the result into the level
	for y in range(h):
		for x in range(w):
			if grid[y * w + x]:
				var pos := Vector2i(pos_x + x, pos_y + y)
				if level.is_in_bounds(pos):
					level.set_tile(pos, Level.Tile.FLOOR)
					room.tiles.append(pos)

	return room

## Generate a room with wall alcoves (crypt-like recesses).
## Used primarily in the Necropolis layer.
func _generate_alcove_room(pos_x: int, pos_y: int, w: int, h: int) -> Room:
	w = maxi(w, 6)
	h = maxi(h, 6)

	# Clamp to level bounds
	if pos_x + w >= level.width - 1:
		w = level.width - pos_x - 2
	if pos_y + h >= level.height - 1:
		h = level.height - pos_y - 2

	var room := Room.new(Rect2i(pos_x, pos_y, w, h))
	room.room_type = RoomType.ALCOVE

	# Carve the base rectangle
	for y in range(pos_y, pos_y + h):
		for x in range(pos_x, pos_x + w):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.Tile.FLOOR)
				room.tiles.append(pos)

	# Add 2-4 alcoves jutting outward from walls
	var alcove_count: int = randi_range(2, 4)
	var sides: Array[int] = [0, 1, 2, 3]  # top, right, bottom, left
	sides.shuffle()

	for i in range(mini(alcove_count, sides.size())):
		var side: int = sides[i]
		var alcove_depth: int = randi_range(2, 3)
		var alcove_width: int = randi_range(2, 3)

		match side:
			0:  # Top alcove
				var ax: int = pos_x + randi_range(2, w - alcove_width - 2)
				var ay: int = pos_y - alcove_depth
				_carve_alcove(room, ax, ay, alcove_width, alcove_depth)
			1:  # Right alcove
				var ax: int = pos_x + w
				var ay: int = pos_y + randi_range(2, h - alcove_width - 2)
				_carve_alcove(room, ax, ay, alcove_depth, alcove_width)
			2:  # Bottom alcove
				var ax: int = pos_x + randi_range(2, w - alcove_width - 2)
				var ay: int = pos_y + h
				_carve_alcove(room, ax, ay, alcove_width, alcove_depth)
			3:  # Left alcove
				var ax: int = pos_x - alcove_depth
				var ay: int = pos_y + randi_range(2, h - alcove_width - 2)
				_carve_alcove(room, ax, ay, alcove_depth, alcove_width)

	return room

## Helper: carve a small alcove rectangle into the level.
func _carve_alcove(room: Room, ax: int, ay: int, aw: int, ah: int) -> void:
	for y in range(ay, ay + ah):
		for x in range(ax, ax + aw):
			var pos := Vector2i(x, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.Tile.FLOOR)
				room.tiles.append(pos)

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
	level.vault_room_ids = _vault_room_ids.duplicate()
	level.vault_rects = _vault_rects.duplicate()
	for room_idx in range(rooms.size()):
		var room: Rect2i = rooms[room_idx]
		level.set_room_id_by_rect(room, room_idx)
		var tags: Array[String] = _build_room_tags(room_idx, room, depth)
		var event_seed: int = int(depth * 100000 + room_idx * 97 + room.position.x * 31 + room.position.y * 17)
		level.set_room_metadata(room_idx, tags, event_seed)
		if EventBus:
			EventBus.room_event_seeded.emit(depth, room_idx, event_seed, tags)

	# Room lighting probability (Sil-Q style: shallow=lit, deep=dark)
	var lit_chance: float = clampf(0.80 - depth * 0.04, 0.10, 0.80)
	for room_idx in range(rooms.size()):
		if randf() < lit_chance:
			level.set_room_lit_by_rect(rooms[room_idx], true)

	# Dark zones: at depth 10+, some rooms become dark zones (no ambient light)
	# Capped to avoid over-suppressing player light economy in deep floors.
	if depth >= 10:
		var dark_zone_chance: float = clampf(0.15 + (depth - 10) * 0.04, 0.15, 0.55)
		for room_idx in range(rooms.size()):
			if randf() < dark_zone_chance:
				level.set_dark_zone(room_idx)

func _build_room_tags(room_idx: int, room: Rect2i, depth: int) -> Array[String]:
	var tags: Array[String] = []
	var area: int = room.size.x * room.size.y
	var layer: String = LayerConfig.get_layer_name(depth)
	tags.append("layer:%s" % layer)
	if room_idx == 0:
		tags.append("entry")
	if room_idx == rooms.size() - 1:
		tags.append("exit")
	if _vault_room_ids.has(room_idx):
		tags.append("vault")
	if area <= 36:
		tags.append("compact")
	elif area >= 120:
		tags.append("grand")
	else:
		tags.append("standard")
	if depth >= 10:
		tags.append("deep")
	if depth >= 15:
		tags.append("terror")
	return tags

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

	# Add extra staircases on larger levels to create alternate routes.
	# Keep first/last rooms as primary entry/exit anchors.
	var candidate_rooms: Array[int] = []
	for room_idx in range(1, rooms.size() - 1):
		candidate_rooms.append(room_idx)
	if candidate_rooms.is_empty():
		return

	var extra_down: int = 0
	var extra_up: int = 0
	if rooms.size() >= 6:
		extra_down = 1
	if depth > 1 and rooms.size() >= 8:
		extra_up = 1

	_place_extra_stairs(candidate_rooms, Level.Tile.STAIRS_DOWN, extra_down)
	if depth > 1:
		_place_extra_stairs(candidate_rooms, Level.Tile.STAIRS_UP, extra_up)

func _place_extra_stairs(candidate_rooms: Array[int], stair_tile: int, count: int) -> void:
	if count <= 0 or candidate_rooms.is_empty():
		return
	for _i in range(count):
		for _attempt in range(24):
			var room_idx: int = candidate_rooms[randi() % candidate_rooms.size()]
			var room: Rect2i = rooms[room_idx]
			var pos := Vector2i(
				randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
				randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
			)
			if not level.is_in_bounds(pos):
				continue
			if level.get_tile(pos) != Level.Tile.FLOOR:
				continue
			if level.get_entity_at(pos) != null:
				continue
			level.set_tile(pos, stair_tile)
			break

func _add_features(depth: int) -> void:
	# Place doors at room-corridor junctions and rare mid-corridor spots
	_place_doors(depth)

	# Add rubble in some rooms based on depth (rubble is impassable, skip narrow corridors)
	if depth > 3:
		for room in rooms:
			if randf() < 0.2:
				var rubble_count := randi_range(1, 3)
				for _i in range(rubble_count):
					var rubble_pos := Vector2i(
						randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
						randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
					)
					if level.get_tile(rubble_pos) == Level.Tile.FLOOR and _count_passable_neighbors(rubble_pos) >= 3:
						level.set_tile(rubble_pos, Level.Tile.RUBBLE)

	# Forges are guaranteed by _ensure_forges() - no random placement here

	# Add water pools (depth > 4)
	if depth > 4:
		_add_water_pools(depth)

	# Add lava in deep zones except inner sanctum depths 16-18 (thematic request).
	if depth > 12 and not (depth >= 16 and depth <= 18):
		_add_lava_pools(depth)

	# Add traps with variety
	_add_traps(depth)

	# Easy mode: reveal all traps
	if GameManager and GameManager.should_reveal_traps():
		level.reveal_all_traps()

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
		var too_close_to_stairs: bool = false
		for stairs_up: Vector2i in level.find_all_stairs_up():
			var up_dist: int = max(abs(trap_pos.x - stairs_up.x), abs(trap_pos.y - stairs_up.y))
			if up_dist < 3:
				too_close_to_stairs = true
				break
		if too_close_to_stairs:
			continue
		for stairs_down: Vector2i in level.find_all_stairs_down():
			var down_dist: int = max(abs(trap_pos.x - stairs_down.x), abs(trap_pos.y - stairs_down.y))
			if down_dist < 3:
				too_close_to_stairs = true
				break
		if too_close_to_stairs:
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
	if depth >= 8 and depth != 15:
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
		{"title": "Ungoliant's Broodmother", "hp_mult": 1.45, "xp_mult": 3},
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
		{"title": "Sauron, the Necromancer", "hp_mult": 1.5, "xp_mult": 4},
	],
}

const TRANSITION_BOSS_BASES: Dictionary = {
	3: ["Broodmother"],
}
const UNGOLIANT_BROODMOTHER_TITLE: String = "Ungoliant's Broodmother"

func _get_reserved_transition_bases(depth: int) -> Array[String]:
	if not LayerConfig.is_boss_level(depth):
		return []
	var raw_reserved: Array = TRANSITION_BOSS_BASES.get(depth, [])
	var reserved: Array[String] = []
	for name in raw_reserved:
		reserved.append(str(name))
	return reserved

func _is_reserved_transition_monster(data: DataManager.MonsterData, depth: int) -> bool:
	if data == null:
		return false
	var reserved: Array[String] = _get_reserved_transition_bases(depth)
	if reserved.is_empty():
		return false
	return data.name in reserved

func _transition_boss_spawn_key(depth: int) -> String:
	return "transition_boss_depth_%d" % depth

func _add_boss_room(depth: int) -> void:
	if rooms.size() < 3:
		return

	var transition_key: String = _transition_boss_spawn_key(depth)
	if DataManager.is_unique_already_spawned(transition_key):
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
	var boss_data: DataManager.MonsterData = null
	var reserved_bases: Array[String] = _get_reserved_transition_bases(depth)
	if not reserved_bases.is_empty():
		boss_data = DataManager.get_monster(reserved_bases[0])
	if boss_info.get("title", "") == UNGOLIANT_BROODMOTHER_TITLE:
		boss_data = DataManager.get_monster("Broodmother")
	if not boss_data:
		boss_data = DataManager.get_themed_monster_for_depth(depth + 3)
	if not boss_data:
		boss_data = DataManager.get_random_monster_for_depth(depth + 2)
	if not boss_data:
		return

	var boss_pos := Vector2i(
		boss_room.position.x + boss_room.size.x / 2,
		boss_room.position.y + boss_room.size.y / 2
	)
	if not level.is_in_bounds(boss_pos) or level.get_tile(boss_pos) != Level.Tile.FLOOR or level.get_entity_at(boss_pos) != null:
		boss_pos = level.find_random_floor_in_room(boss_room, 80)
		if boss_pos == Vector2i(-1, -1):
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
	boss.set_meta("is_transition_boss", true)
	boss.set_meta("transition_boss_depth", depth)
	if boss_info.get("title", "") == UNGOLIANT_BROODMOTHER_TITLE:
		boss.set_meta("ungoliant_broodmother", true)
		boss.set_sprite_from_monster_id(22)
		var sprite: Sprite2D = boss.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			# Darker palette touch variant for Ungoliant's brood while retaining base Broodmother silhouette.
			sprite.modulate = Color(0.44, 0.38, 0.50, 1.0)
	level.add_entity(boss)
	DataManager.mark_unique_spawned(transition_key)
	DataManager.mark_unique_spawned(boss_info.title)

	# Guaranteed quality treasure near boss (2 items)
	var item_scene := preload("res://scenes/entities/item.tscn")
	var boss_drops: int = 2

	for i in range(boss_drops):
		var item_data := DataManager.get_random_item_for_depth(depth + 3)
		if not item_data:
			continue
		var boss_item: DataManager.ItemData = DataManager.duplicate_item_data(item_data)

		# Boss loot tier based on floor depth — NEVER cursed
		if depth >= 12:
			# Deep bosses: guaranteed artifact attempt
			var art: DataManager.ArtifactData = DataManager.get_random_artifact()
			if art:
				boss_item = DataManager.duplicate_artifact_as_item(art)
			else:
				_apply_floor_ego(boss_item, depth + 5, true)
				boss_item.attack_bonus += 2
				boss_item.evasion_bonus += 1
		elif depth >= 9:
			# Mid-deep bosses: 50% artifact, 50% major ego
			if randf() < 0.5:
				var art: DataManager.ArtifactData = DataManager.get_random_artifact()
				if art:
					boss_item = DataManager.duplicate_artifact_as_item(art)
				else:
					_apply_floor_ego(boss_item, depth + 5, true)
			else:
				_apply_floor_ego(boss_item, depth + 5, true)
				boss_item.attack_bonus += 1
		elif depth >= 6:
			# Mid bosses: guaranteed major ego
			_apply_floor_ego(boss_item, depth + 5, true)
			boss_item.attack_bonus += 1
			boss_item.evasion_bonus += 1
		else:
			# Early bosses: guaranteed minor ego (no cursed)
			_apply_floor_ego(boss_item, depth + 3, true)

		var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		var item_pos: Vector2i = boss_pos + offsets[i % offsets.size()]
		if level.is_in_bounds(item_pos) and level.get_tile(item_pos) == Level.Tile.FLOOR:
			var item: Item = item_scene.instantiate()
			item.grid_position = item_pos
			item.initialize_from_item_data(boss_item)
			level.add_item(item)

func _is_door_candidate(pos: Vector2i) -> bool:
	# A position is a door candidate if it connects two areas (walls on two opposite sides, floor on the other two)
	if not level.is_in_bounds(pos):
		return false
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

func _get_door_passage_dirs(pos: Vector2i) -> Array[Vector2i]:
	# Returns the two opposite directions that represent passage flow through a door.
	var north: int = level.get_tile(pos + Vector2i(0, -1))
	var south: int = level.get_tile(pos + Vector2i(0, 1))
	var east: int = level.get_tile(pos + Vector2i(1, 0))
	var west: int = level.get_tile(pos + Vector2i(-1, 0))
	if north == Level.Tile.WALL and south == Level.Tile.WALL and east == Level.Tile.FLOOR and west == Level.Tile.FLOOR:
		return [Vector2i(1, 0), Vector2i(-1, 0)]
	if east == Level.Tile.WALL and west == Level.Tile.WALL and north == Level.Tile.FLOOR and south == Level.Tile.FLOOR:
		return [Vector2i(0, -1), Vector2i(0, 1)]
	return []

func _count_floor_neighbors(pos: Vector2i) -> int:
	var count: int = 0
	var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]
	for dir: Vector2i in dirs:
		var next: Vector2i = pos + dir
		if not level.is_in_bounds(next):
			continue
		if level.get_tile(next) == Level.Tile.FLOOR:
			count += 1
	return count

func _corridor_run_length(start: Vector2i, dir: Vector2i, max_steps: int = 8) -> int:
	# Count contiguous corridor floor tiles before hitting a room/junction/end.
	var length: int = 0
	for step in range(1, max_steps + 1):
		var pos: Vector2i = start + dir * step
		if not level.is_in_bounds(pos):
			break
		if level.get_tile(pos) != Level.Tile.FLOOR:
			break
		# Mid-corridor doors should stay in corridor space, not room borders.
		if level.get_room_id(pos) >= 0:
			break
		length += 1
		# Stop at a junction/end; this keeps doors off tiny stubs and odd protrusions.
		if _count_floor_neighbors(pos) != 2:
			break
	return length

func _is_valid_mid_corridor_door(pos: Vector2i) -> bool:
	if not _is_door_candidate(pos):
		return false
	if _is_room_entrance(pos):
		return false
	var dirs: Array[Vector2i] = _get_door_passage_dirs(pos)
	if dirs.size() != 2:
		return false
	# Require meaningful corridor on both sides to avoid "goes nowhere" doorway stubs.
	var len_a: int = _corridor_run_length(pos, dirs[0], 8)
	var len_b: int = _corridor_run_length(pos, dirs[1], 8)
	if len_a < 2 or len_b < 2:
		return false
	# Never place a decorative mid-corridor door next to stairs.
	for dir: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var n: Vector2i = pos + dir
		if not level.is_in_bounds(n):
			continue
		var tile: int = level.get_tile(n)
		if tile == Level.Tile.STAIRS_UP or tile == Level.Tile.STAIRS_DOWN:
			return false
	return true

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

	# Phase 2: Rare mid-corridor doors (2% chance, min 4-tile spacing, strict validity).
	for y in range(1, level.height - 1):
		for x in range(1, level.width - 1):
			var pos := Vector2i(x, y)
			if level.get_tile(pos) != Level.Tile.FLOOR:
				continue
			# Must be a structurally valid corridor door candidate.
			if not _is_valid_mid_corridor_door(pos):
				continue
			if randf() >= 0.02:
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
			# Final structural gate: allow room entrances, but keep corridor doors sane.
			if _is_room_entrance(door_pos) or _is_valid_mid_corridor_door(door_pos):
				valid_doors.append(door_pos)

	# Phase 4: Actually place door tiles
	for door_pos: Vector2i in valid_doors:
		var door_type: int = _pick_door_type(depth)
		level.set_tile(door_pos, door_type)

func _is_in_vault_rect(pos: Vector2i) -> bool:
	for rect: Rect2i in _vault_rects:
		if rect.has_point(pos):
			return true
	return false

func _sanitize_doors_after_decoration() -> void:
	# Later generation passes (water/lava/vault decoration/connectivity repairs) can
	# mutate corridor geometry after doors are placed. Clean up any now-nonsensical
	# non-vault visible doors to avoid dead-end/protrusion door artifacts.
	for y in range(1, level.height - 1):
		for x in range(1, level.width - 1):
			var pos: Vector2i = Vector2i(x, y)
			var tile: int = level.get_tile(pos)
			if tile != Level.Tile.DOOR_OPEN \
				and tile != Level.Tile.DOOR_CLOSED \
				and tile != Level.Tile.DOOR_LOCKED \
				and tile != Level.Tile.DOOR_JAMMED:
				continue
			if _is_in_vault_rect(pos):
				continue
			if _is_room_entrance(pos) or _is_valid_mid_corridor_door(pos):
				continue
			level.set_tile(pos, Level.Tile.FLOOR)

## Try to place a vault room of the specified type. Returns Room or null.
func _try_place_vault_room(room_type: int, depth: int) -> Room:
	# Select a vault that matches the requested vault type and depth rating.
	var vault: DataManager.VaultData = DataManager.get_weighted_vault(room_type, depth)
	if vault == null:
		return null

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

	# Only use "interesting" vaults for the random vault pass.
	var vault := DataManager.get_weighted_vault(RoomType.VAULT_INTERESTING, depth)
	if not vault or vault.map_lines.is_empty():
		return

	# Find a suitable position (try to fit within map bounds)
	var max_attempts := 20
	for _attempt in range(max_attempts):
		var start_x := randi_range(2, level.width - vault.width - 2)
		var start_y := randi_range(2, level.height - vault.height - 2)

		if _can_place_vault_at(Vector2i(start_x, start_y), vault):
			_carve_vault(Vector2i(start_x, start_y), vault, depth)
			_vault_rects.append(Rect2i(start_x, start_y, vault.width, vault.height))
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

## Place a vault monster with proper alertness (sleeping by default, awake in greater vaults).
func _place_vault_monster(monster_scene: PackedScene, pos: Vector2i, data: DataManager.MonsterData, is_greater_vault: bool, depth: int) -> void:
	# Don't stack monsters on occupied tiles
	if level.get_entity_at(pos) != null:
		return
	if not _can_place_pre_spawn_monster(depth, data):
		return
	if _is_reserved_transition_monster(data, depth):
		return
	# Unique cap check
	if data.has_flag("UNIQUE"):
		if DataManager.is_unique_already_spawned(data.name):
			return
		DataManager.mark_unique_spawned(data.name)
	var monster: Monster = monster_scene.instantiate()
	monster.grid_position = pos
	monster.initialize_from_data(data)
	if is_greater_vault:
		monster.alertness = Constants.ALERTNESS_ALERT
		monster.is_sleeping = false
	else:
		monster.alertness = Constants.ALERTNESS_MIN
		monster.is_sleeping = true
	level.add_entity(monster)

func _carve_vault(pos: Vector2i, vault: DataManager.VaultData, depth: int) -> void:
	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var item_scene := preload("res://scenes/entities/item.tscn")

	# Compute effective vault depth based on vault type
	var is_greater: bool = vault.has_flag("GREATER") or vault.rating >= 10
	var vault_depth_bonus: int = 0
	if is_greater:
		vault_depth_bonus = Constants.VAULT_DEPTH_BONUS_GREATER
	elif vault.has_flag("LESSER"):
		vault_depth_bonus = Constants.VAULT_DEPTH_BONUS_LESSER
	else:
		vault_depth_bonus = Constants.VAULT_DEPTH_BONUS_INTERESTING
	var effective_vault_depth: int = mini(depth + vault_depth_bonus, 20)

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
					# Sil-Q d3 distribution: 33% monster, 33% both, 33% item
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					var d3_roll: int = randi_range(1, 3)
					if d3_roll <= 2:  # 1=monster only, 2=both
						var m_data := DataManager.get_themed_monster_for_depth(effective_vault_depth)
						if m_data:
							_place_vault_monster(monster_scene, tile_pos, m_data, is_greater, depth)
					if d3_roll >= 2:  # 2=both, 3=item only
						var i_data := DataManager.get_themed_item_for_depth(effective_vault_depth)
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
					# Monster at effective vault depth + N
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					var monster_depth: int = mini(effective_vault_depth + int(ch), 20)
					var monster_data := DataManager.get_themed_monster_for_depth(monster_depth)
					if monster_data:
						_place_vault_monster(monster_scene, tile_pos, monster_data, is_greater, depth)
				_:
					# Check for named monster characters
					if ch.to_upper() == ch and ch != ch.to_lower():
						# Uppercase letter - potentially a named monster
						level.set_tile(tile_pos, Level.Tile.FLOOR)
						var monster_data := DataManager.get_monster_by_char(ch, effective_vault_depth)
						if monster_data:
							_place_vault_monster(monster_scene, tile_pos, monster_data, is_greater, depth)
					elif ch.to_lower() == ch and ch != ch.to_upper():
						# Lowercase letter - potentially a monster
						level.set_tile(tile_pos, Level.Tile.FLOOR)
						var monster_data := DataManager.get_monster_by_char(ch, effective_vault_depth)
						if monster_data:
							_place_vault_monster(monster_scene, tile_pos, monster_data, is_greater, depth)
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

	# BFS flood fill (index-based to avoid O(n) pop_front)
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	var queue_idx: int = 0
	visited[start] = true
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while queue_idx < queue.size():
		var current: Vector2i = queue[queue_idx]
		queue_idx += 1
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

	# Allow up to 5% disconnected tiles (large rooms can create small pockets)
	var reachable: int = visited.size()
	var max_disconnected: int = maxi(10, total_passable / 20)
	if total_passable - reachable > max_disconnected:
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

	# BFS from stairs_up to check if stairs_down is reachable (index-based)
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [stairs_up]
	var qi: int = 0
	visited[stairs_up] = true
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while qi < queue.size():
		var current: Vector2i = queue[qi]
		qi += 1
		if current == stairs_down:
			return  # Already connected, nothing to do
		for dir: Vector2i in dirs:
			var next: Vector2i = current + dir
			if level.is_in_bounds(next) and level.is_passable(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)

	# stairs_down is NOT reachable — carve a rescue corridor
	# Use BFS through ALL tiles (including walls) to find the shortest path (index-based)
	var parent: Dictionary = {}
	var repair_queue: Array[Vector2i] = [stairs_up]
	var ri: int = 0
	parent[stairs_up] = stairs_up

	while ri < repair_queue.size():
		var current: Vector2i = repair_queue[ri]
		ri += 1
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

## Find the nearest passable tile to a given position using BFS (index-based).
func _find_nearest_passable(from: Vector2i) -> Vector2i:
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [from]
	var qi: int = 0
	visited[from] = true
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while qi < queue.size():
		var current: Vector2i = queue[qi]
		qi += 1
		if current != from and level.is_passable(current) and level.get_entity_at(current) == null:
			return current
		for dir: Vector2i in dirs:
			var next: Vector2i = current + dir
			if level.is_in_bounds(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)

	return Vector2i(-1, -1)

## Place baseline forges:
## - guaranteed 1 forge on depths 2/4/6/8/10
## - additional per-floor scarcity roll can add a second forge
## - hard cap is enforced in _finalize_forges() after decoration/vault passes
func _ensure_forges(depth: int) -> void:
	var guaranteed_min: int = 1 if _is_guaranteed_forge_depth(depth) else 0
	var target_count: int = guaranteed_min
	if randf() < _get_additional_forge_roll_chance(depth):
		target_count += 1
	target_count = clampi(target_count, guaranteed_min, MAX_FORGES_PER_FLOOR)

	var existing: Array[Vector2i] = _collect_forge_positions()
	var needed: int = maxi(0, target_count - existing.size())
	for _i in range(needed):
		if not _place_random_forge(depth):
			break

func _finalize_forges(depth: int) -> void:
	var forge_positions: Array[Vector2i] = _collect_forge_positions()
	if forge_positions.size() > MAX_FORGES_PER_FLOOR:
		var to_remove: int = forge_positions.size() - MAX_FORGES_PER_FLOOR
		for _i in range(to_remove):
			if forge_positions.is_empty():
				break
			var remove_pos: Vector2i = forge_positions.pop_back()
			level.set_tile(remove_pos, Level.Tile.FLOOR)
			level.forge_uses.erase(remove_pos)

	# If decoration removed guaranteed forge placement, restore it.
	forge_positions = _collect_forge_positions()
	if forge_positions.is_empty() and _is_guaranteed_forge_depth(depth):
		_place_random_forge(depth)
		forge_positions = _collect_forge_positions()

	# Ensure every retained forge has usable charges.
	for forge_pos: Vector2i in forge_positions:
		var tile: int = level.get_tile(forge_pos)
		if level.get_forge_uses(forge_pos) <= 0:
			level.init_forge_uses(forge_pos, _roll_forge_uses(depth, tile))

func _collect_forge_positions() -> Array[Vector2i]:
	var forge_positions: Array[Vector2i] = []
	for y in range(level.height):
		for x in range(level.width):
			var pos := Vector2i(x, y)
			if level.is_forge_tile(pos):
				forge_positions.append(pos)
	return forge_positions

func _is_guaranteed_forge_depth(depth: int) -> bool:
	return (depth <= 10 and depth % 2 == 0) or depth == 20

func _get_additional_forge_roll_chance(depth: int) -> float:
	if depth <= 10:
		return 0.15
	if depth <= 14:
		return 0.25
	if depth <= 17:
		return 0.30
	return 0.50

func _roll_forge_tile(depth: int) -> int:
	var roll: int = randi_range(0, 999)
	if depth >= 12 and roll >= 996:
		return Level.Tile.FORGE_UNIQUE
	if roll >= 960:
		return Level.Tile.FORGE_ENCHANTED
	return Level.Tile.FORGE

func _roll_forge_uses(depth: int, forge_tile: int) -> int:
	match forge_tile:
		Level.Tile.FORGE_UNIQUE:
			return 3
		Level.Tile.FORGE_ENCHANTED:
			return randi_range(3, 4)
		_:
			if depth <= 4:
				return 3
			return randi_range(2, 4)

func _place_random_forge(depth: int) -> bool:
	if rooms.is_empty():
		return false
	var room_order: Array = range(rooms.size())
	room_order.shuffle()
	for idx in room_order:
		var room: Rect2i = rooms[idx]
		var forge_pos := Vector2i(
			room.position.x + room.size.x / 2,
			room.position.y + room.size.y / 2
		)
		if not level.is_in_bounds(forge_pos):
			continue
		if level.get_tile(forge_pos) != Level.Tile.FLOOR:
			continue
		var forge_tile: int = _roll_forge_tile(depth)
		var forge_uses: int = _roll_forge_uses(depth, forge_tile)
		level.set_tile(forge_pos, forge_tile)
		level.init_forge_uses(forge_pos, forge_uses)
		_spawn_forge_guardian(forge_pos, depth, forge_tile)
		return true
	return false

## Spawn guardian monsters adjacent to a forge based on forge type.
func _spawn_forge_guardian(forge_pos: Vector2i, depth: int, forge_tile: int) -> void:
	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var guard_count: int = 1
	var guard_depth: int = mini(depth + 1, 20)
	var guard_alertness: int = Constants.ALERTNESS_QUITE_ALERT

	match forge_tile:
		Level.Tile.FORGE_ENCHANTED:
			guard_count = randi_range(2, 3)
			guard_depth = mini(depth + 2, 20)
		Level.Tile.FORGE_UNIQUE:
			guard_count = randi_range(3, 4)
			guard_depth = mini(depth + 4, 20)
			guard_alertness = Constants.ALERTNESS_VERY_ALERT

	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	dirs.shuffle()
	var placed: int = 0
	for dir: Vector2i in dirs:
		if placed >= guard_count:
			break
		var pos: Vector2i = forge_pos + dir
		if level.is_in_bounds(pos) and level.is_passable(pos) and level.get_entity_at(pos) == null:
			var guard_data: DataManager.MonsterData = DataManager.get_themed_monster_for_depth(guard_depth)
			if guard_data and _can_place_pre_spawn_monster(depth, guard_data):
				var guard: Monster = monster_scene.instantiate()
				guard.grid_position = pos
				guard.initialize_from_data(guard_data)
				guard.alertness = guard_alertness
				guard.is_sleeping = false
				level.add_entity(guard)
				placed += 1

## Spawn 3 smithing materials per forge.
## Early forges (depth 1-5) are Broken Glowing only.
## From depth 6+, each spawn rolls Broken Glowing vs Broken Strange
## using a depth-scaled curve so deeper floors reward higher-tier smithing loops.
func _spawn_forge_materials(depth: int) -> void:
	var forge_positions: Array[Vector2i] = _collect_forge_positions()

	if forge_positions.is_empty():
		return

	var item_scene := preload("res://scenes/entities/item.tscn")

	var glowing_by_category: Dictionary = {
		"weapon": SmithingSystem.BROKEN_GLOWING_WEAPON_ID,
		"armor": SmithingSystem.BROKEN_GLOWING_ARMOR_ID,
		"jewelry": SmithingSystem.BROKEN_GLOWING_JEWELRY_ID,
	}
	var strange_by_category: Dictionary = {
		"weapon": SmithingSystem.BROKEN_STRANGE_WEAPON_ID,
		"armor": SmithingSystem.BROKEN_STRANGE_ARMOR_ID,
		"jewelry": SmithingSystem.BROKEN_STRANGE_JEWELRY_ID,
	}
	# Only keep categories that exist in both glowing and strange sets.
	var categories: Array[String] = []
	for cat in ["weapon", "armor", "jewelry"]:
		var glow_id: int = int(glowing_by_category.get(cat, -1))
		var strange_id: int = int(strange_by_category.get(cat, -1))
		if DataManager.get_item_by_index(glow_id) != null and DataManager.get_item_by_index(strange_id) != null:
			categories.append(cat)
	if categories.is_empty():
		return

	for forge_pos: Vector2i in forge_positions:
		# Collect valid passable tiles within 3 tiles of forge (not just FLOOR)
		var nearby_floors: Array[Vector2i] = []
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var pos := Vector2i(forge_pos.x + dx, forge_pos.y + dy)
				if pos == forge_pos:
					continue
				if level.is_in_bounds(pos) and level.is_passable(pos):
					nearby_floors.append(pos)

		nearby_floors.shuffle()
		if nearby_floors.size() < 3:
			continue

		var spawned_names: Array[String] = []
		var spawn_ids: Array[int] = []
		var strange_chance: float = _get_forge_strange_spawn_chance(depth)
		for _j in range(3):
			var category: String = categories.pick_random()  # 33/33/33 when all 3 categories are present.
			var roll_strange: bool = depth >= 6 and randf() < strange_chance
			var chosen_id: int = int(
				strange_by_category.get(category, -1) if roll_strange else glowing_by_category.get(category, -1)
			)
			if chosen_id >= 0:
				spawn_ids.append(chosen_id)

		for i in range(spawn_ids.size()):
			var mat_id: int = spawn_ids[i]
			var mat_template: DataManager.ItemData = DataManager.get_item_by_index(mat_id)
			if mat_template == null:
				push_warning("Forge material ID %d not found" % mat_id)
				continue

			var mat_copy: DataManager.ItemData = DataManager.duplicate_item_data(mat_template)
			var mat_item: Item = item_scene.instantiate()
			mat_item.grid_position = nearby_floors[i]
			mat_item.initialize_from_item_data(mat_copy)
			level.add_item(mat_item)
			spawned_names.append(mat_copy.name.replace("& ", "").replace("~", ""))
		if not spawned_names.is_empty():
			print("Forge materials at depth %d: %s" % [depth, ", ".join(spawned_names)])

## Broken Strange materials are reserved for deeper floors.
## Depths <=10: all Broken Glowing.
## Depths >=11: all Broken Strange.
func _get_forge_strange_spawn_chance(depth: int) -> float:
	return 1.0 if depth >= 11 else 0.0

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
	# Count existing monsters already on the level (from vaults + door guards)
	var existing_monsters: int = level.get_monsters().size()

	# Density formula: based on passable tiles, scales with depth
	var max_total: int = _get_floor_monster_budget(depth)

	# Layer transition smoothing: reduce effective depth by 1 at boundaries
	var spawn_depth: int = depth
	if LayerConfig.is_layer_boundary(depth):
		spawn_depth = maxi(1, depth - 1)

	# Subtract existing monsters from spawn budget
	var target_count: int = maxi(0, max_total - existing_monsters)

	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var spawned: int = 0
	var stairs_up: Vector2i = level.find_stairs_up()

	# On floor 1 there's no stairs_up — use first room center as safe zone
	if stairs_up == Vector2i(-1, -1) and not rooms.is_empty():
		var first_room: Rect2i = rooms[0]
		stairs_up = Vector2i(
			first_room.position.x + first_room.size.x / 2,
			first_room.position.y + first_room.size.y / 2
		)

	# Get FOV radius for LOS placement check
	var fov_radius: int = LayerConfig.get_fov_radius(depth)

	# Try to spawn a unique lair before main loop
	if depth >= Constants.UNIQUE_LAIR_MIN_DEPTH and randf() < Constants.UNIQUE_LAIR_CHANCE:
		var lair_placed: int = _try_spawn_unique_lair(spawn_depth, monster_scene, stairs_up, fov_radius)
		spawned += lair_placed

	# Layer boundary telegraphing
	if LayerConfig.is_layer_boundary(depth) and stairs_up != Vector2i(-1, -1):
		_telegraph_layer_entry(depth, stairs_up)

	if target_count == 0:
		print("Spawned 0 monsters at depth %d (already %d from vaults/guards, cap %d)" % [depth, existing_monsters, max_total])
	else:
		# Phase 1: Room spawning (70% of budget)
		var room_budget: int = int(target_count * 0.7)
		# Distribute budget across rooms proportional to area
		var room_areas: Array[int] = []
		var total_area: int = 0
		for room: Rect2i in rooms:
			var area: int = room.size.x * room.size.y
			room_areas.append(area)
			total_area += area

		var room_order: Array = range(rooms.size())
		room_order.shuffle()

		for room_idx in room_order:
			if spawned >= room_budget:
				break
			var room: Rect2i = rooms[room_idx]
			var room_share: int = maxi(1, int(float(room_areas[room_idx]) / maxf(float(total_area), 1.0) * room_budget))
			room_share = mini(room_share, room_budget - spawned)

			for _j in range(room_share):
				if spawned >= room_budget:
					break
				var spawn_pos: Vector2i = level.find_random_floor_in_room(room)
				if spawn_pos == Vector2i(-1, -1):
					break

				# 5-tile safe zone around stairs
				if stairs_up != Vector2i(-1, -1):
					var dist: int = maxi(absi(spawn_pos.x - stairs_up.x), absi(spawn_pos.y - stairs_up.y))
					if dist < 7:
						continue

				# LOS check: no monsters visible from stairs_up at start
				if stairs_up != Vector2i(-1, -1) and _is_in_starting_fov(spawn_pos, stairs_up, fov_radius):
					continue

				spawned += _place_monster_with_entourage(monster_scene, spawn_pos, spawn_depth, target_count - spawned)

		# Phase 2: Corridor spawning (remaining budget)
		var corridor_budget: int = target_count - spawned
		for _i in range(corridor_budget * 3):  # Extra attempts since corridors are sparse
			if spawned >= target_count:
				break
			var spawn_pos: Vector2i = level.find_random_corridor_floor()
			if spawn_pos == Vector2i(-1, -1):
				continue

			# 5-tile safe zone
			if stairs_up != Vector2i(-1, -1):
				var dist: int = maxi(absi(spawn_pos.x - stairs_up.x), absi(spawn_pos.y - stairs_up.y))
				if dist < 7:
					continue

			# LOS check
			if stairs_up != Vector2i(-1, -1) and _is_in_starting_fov(spawn_pos, stairs_up, fov_radius):
				continue

			spawned += _place_monster_with_entourage(monster_scene, spawn_pos, spawn_depth, target_count - spawned)

	# Post-placement: clear ALL monsters too close to stairs_up (catches vault/door guard monsters too)
	_clear_monsters_near_stairs(stairs_up)

	# Post-placement alertness pass
	_apply_location_alertness(depth, stairs_up)

	# Encounter type classification
	_apply_encounter_types()

	# Hard safety cap: prevent runaway vault/guard spawns.
	var pre_trim_count: int = level.get_monsters().size()
	var hard_cap: int = _get_runtime_monster_hard_cap(max_total)
	_trim_monsters_to_cap(hard_cap)
	if pre_trim_count > hard_cap:
		print("Monster cap applied at depth %d: %d -> %d (cap %d)" % [
			depth, pre_trim_count, level.get_monsters().size(), hard_cap
		])

	var final_count: int = 0
	for e in level.entities:
		if is_instance_valid(e) and e is Monster:
			final_count += 1
	print("Spawned %d monsters at depth %d (cap %d)" % [final_count, depth, max_total])

func _get_runtime_monster_hard_cap(floor_budget: int = -1) -> int:
	var hard_cap: int = Constants.PERIODIC_SPAWN_MAX_MONSTERS
	if floor_budget > 0:
		hard_cap = mini(hard_cap, floor_budget)
	if GameManager and GameManager.has_meta("advisory_monster_cap_override"):
		var override_val: int = int(GameManager.get_meta("advisory_monster_cap_override"))
		if override_val > 0:
			hard_cap = override_val
	return hard_cap

func _get_floor_monster_budget(depth: int) -> int:
	var passable: int = maxi(level.count_passable_tiles(), 1)
	var divisor: float = lerpf(35.0, 25.0, clampf(float(depth - 1) / 19.0, 0.0, 1.0))
	var max_total: int = clampi(int(passable / divisor), 4, 20)
	if level.is_ascent:
		max_total = mini(int(max_total * Constants.ASCENT_SPAWN_MULTIPLIER), 40)
	return max_total

func _can_place_pre_spawn_monster(depth: int, monster_data: DataManager.MonsterData = null) -> bool:
	if monster_data and (monster_data.has_flag("UNIQUE") or _is_reserved_transition_monster(monster_data, depth)):
		return true
	return level.get_monsters().size() < _get_floor_monster_budget(depth)

## Enforce a hard cap on total monsters (vaults/guards can exceed spawn budget).
func _trim_monsters_to_cap(cap: int) -> void:
	if cap <= 0:
		return
	var monsters: Array[Monster] = level.get_monsters()
	if monsters.size() <= cap:
		return

	var keep: Array[Monster] = []
	var removable: Array[Monster] = []
	for m in monsters:
		if m.is_unique or (m.monster_data and m.monster_data.has_flag("UNIQUE")) or m.has_meta("is_transition_boss"):
			keep.append(m)
		else:
			removable.append(m)

	removable.shuffle()
	var to_remove: int = monsters.size() - cap
	var removed: int = 0
	for m in removable:
		if removed >= to_remove:
			break
		level.remove_entity(m)
		m.queue_free()
		removed += 1
	if removed > 0:
		print("Trimmed %d monsters to enforce cap %d" % [removed, cap])

## Remove ALL monsters within safe zone of stairs_up (catches vault/guard spawns too).
func _clear_monsters_near_stairs(stairs_up: Vector2i) -> void:
	if stairs_up == Vector2i(-1, -1):
		return
	const SAFE_RADIUS: int = 7
	var to_remove: Array = []
	for entity in level.entities:
		if not is_instance_valid(entity) or not entity is Monster:
			continue
		var dist: int = maxi(absi(entity.grid_position.x - stairs_up.x), absi(entity.grid_position.y - stairs_up.y))
		if dist < SAFE_RADIUS:
			to_remove.append(entity)
	for monster in to_remove:
		level.remove_entity(monster)
		monster.queue_free()
	if not to_remove.is_empty():
		print("Cleared %d monsters within %d tiles of stairs_up" % [to_remove.size(), SAFE_RADIUS])

## Check if a position is within starting FOV from stairs_up (LOS + radius).
func _is_in_starting_fov(pos: Vector2i, stairs_up: Vector2i, fov_radius: int) -> bool:
	var dist: int = maxi(absi(pos.x - stairs_up.x), absi(pos.y - stairs_up.y))
	if dist > fov_radius:
		return false
	return level.has_los_to(stairs_up, pos)

## Place a single monster with FRIENDS/ESCORT expansion. Returns total placed.
func _place_monster_with_entourage(monster_scene: PackedScene, pos: Vector2i, depth: int, budget: int) -> int:
	if budget <= 0:
		return 0
	# Safety: don't place on occupied or stair tiles
	if level.get_entity_at(pos) != null:
		return 0
	var tile: int = level.get_tile(pos)
	if tile == Level.Tile.STAIRS_UP or tile == Level.Tile.STAIRS_DOWN:
		return 0

	# Apply OOD variance for random spawns
	var effective_depth: int = DataManager.get_effective_monster_depth(depth)

	# 70% themed, 30% random
	var monster_data: DataManager.MonsterData = null
	if randf() < 0.70:
		monster_data = DataManager.get_themed_monster_for_depth(effective_depth)
	else:
		monster_data = DataManager.get_random_monster_for_depth(effective_depth, true)

	if not monster_data:
		return 0

	# Reserve transition boss species for dedicated boss spawns/titles and keep early floors safe.
	for _retry in range(8):
		if not _is_reserved_transition_monster(monster_data, depth) and not _is_disallowed_monster_for_floor(monster_data, depth):
			break
		monster_data = DataManager.get_random_monster_for_depth(effective_depth, true)
		if not monster_data:
			return 0
	if _is_reserved_transition_monster(monster_data, depth) or _is_disallowed_monster_for_floor(monster_data, depth):
		return 0

	# Unique cap check
	if monster_data.has_flag("UNIQUE"):
		if DataManager.is_unique_already_spawned(monster_data.name):
			# Try again without uniques
			monster_data = DataManager.get_random_monster_for_depth(effective_depth, true)
			if not monster_data:
				return 0
		else:
			DataManager.mark_unique_spawned(monster_data.name)

	var monster: Monster = monster_scene.instantiate()
	monster.grid_position = pos
	monster.initialize_from_data(monster_data)
	level.add_entity(monster)
	var spawned: int = 1

	# FRIENDS pack expansion (BFS puddle)
	if monster_data.has_flag("FRIENDS") and budget > spawned:
		var pack_size: int = _get_friends_pack_size(monster_data)
		var group_budget: int = mini(pack_size, budget - spawned)
		spawned += _spawn_group_bfs(monster_scene, pos, monster_data, group_budget)
	elif monster_data.has_flag("FRIEND") and budget > spawned:
		var group_budget: int = mini(randi_range(1, 2), budget - spawned)
		spawned += _spawn_group_bfs(monster_scene, pos, monster_data, group_budget)

	# ESCORT expansion (type-aware)
	if monster_data.has_flag("ESCORTS") and budget > spawned:
		var escort_count: int = mini(randi_range(2, 4), budget - spawned)
		spawned += _spawn_escort_group(monster_scene, pos, monster_data, depth, escort_count)
	elif monster_data.has_flag("ESCORT") and budget > spawned:
		var escort_count: int = mini(randi_range(1, 2), budget - spawned)
		spawned += _spawn_escort_group(monster_scene, pos, monster_data, depth, escort_count)

	return spawned

func _is_disallowed_monster_for_floor(monster_data: DataManager.MonsterData, floor_depth: int) -> bool:
	if monster_data == null:
		return true
	# Layer-1 safety gate: Broodmother (and all title variants based on it) must not appear before depth 3.
	if monster_data.name == "Broodmother" and floor_depth < 3:
		return true
	return false

## Get FRIENDS pack size by monster type.
func _get_friends_pack_size(data: DataManager.MonsterData) -> int:
	var ch: String = data.display_char
	if ch == "r" or ch == "I":  # rats, insects
		return randi_range(2, 4)
	if ch == "o" or ch == "O":  # orcs
		return randi_range(2, 3)
	if data.has_flag("UNDEAD") or ch == "z" or ch == "w":  # undead, wights, wolves
		return randi_range(2, 3)
	if ch == "G" or data.has_flag("SHADOW"):  # shadows
		return randi_range(1, 2)
	return randi_range(1, 2)  # default

## BFS outward placement for pack monsters. Frontier shuffled for organic spread.
func _spawn_group_bfs(monster_scene: PackedScene, center: Vector2i, data: DataManager.MonsterData, count: int) -> int:
	var spawned: int = 0
	var visited: Dictionary = {center: true}
	var frontier: Array[Vector2i] = []

	# Seed frontier with adjacent tiles
	var dirs: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	for dir: Vector2i in dirs:
		var next: Vector2i = center + dir
		if level.is_in_bounds(next) and not visited.has(next):
			frontier.append(next)
			visited[next] = true
	frontier.shuffle()

	while spawned < count and not frontier.is_empty():
		var pos: Vector2i = frontier.pop_front()
		var btile: int = level.get_tile(pos)
		if level.is_passable(pos) and level.get_entity_at(pos) == null and btile != Level.Tile.STAIRS_UP and btile != Level.Tile.STAIRS_DOWN:
			var monster: Monster = monster_scene.instantiate()
			monster.grid_position = pos
			monster.initialize_from_data(data)
			level.add_entity(monster)
			spawned += 1

			# Expand frontier
			for dir: Vector2i in dirs:
				var next: Vector2i = pos + dir
				if level.is_in_bounds(next) and not visited.has(next):
					frontier.append(next)
					visited[next] = true
			frontier.shuffle()

	return spawned

## Spawn type-aware escorts matching the leader's race/type.
func _spawn_escort_group(monster_scene: PackedScene, leader_pos: Vector2i, leader_data: DataManager.MonsterData, depth: int, count: int) -> int:
	var escort_depth: int = maxi(1, depth - 2)
	var predicate: Callable = _get_escort_predicate(leader_data)

	var spawned: int = 0
	var dirs: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	dirs.shuffle()

	# BFS outward from leader
	var visited: Dictionary = {leader_pos: true}
	var frontier: Array[Vector2i] = []
	for dir: Vector2i in dirs:
		var next: Vector2i = leader_pos + dir
		if level.is_in_bounds(next):
			frontier.append(next)
			visited[next] = true
	frontier.shuffle()

	while spawned < count and not frontier.is_empty():
		var pos: Vector2i = frontier.pop_front()
		var etile: int = level.get_tile(pos)
		if level.is_passable(pos) and level.get_entity_at(pos) == null and etile != Level.Tile.STAIRS_UP and etile != Level.Tile.STAIRS_DOWN:
			var escort_data: DataManager.MonsterData = DataManager._pick_monster_matching(escort_depth, predicate, true)
			if escort_data:
				var escort: Monster = monster_scene.instantiate()
				escort.grid_position = pos
				escort.initialize_from_data(escort_data)
				level.add_entity(escort)
				spawned += 1

		# Expand frontier
		for dir: Vector2i in dirs:
			var next: Vector2i = pos + dir
			if level.is_in_bounds(next) and not visited.has(next):
				frontier.append(next)
				visited[next] = true
		frontier.shuffle()

	return spawned

## Get escort predicate matching leader's race/type.
func _get_escort_predicate(leader_data: DataManager.MonsterData) -> Callable:
	var ch: String = leader_data.display_char
	if leader_data.has_flag("ORC") or ch == "o" or ch == "O":
		return func(m: DataManager.MonsterData) -> bool: return m.has_flag("ORC") or m.display_char == "o"
	if leader_data.has_flag("TROLL") or ch == "T" or ch == "t":
		return func(m: DataManager.MonsterData) -> bool: return m.has_flag("TROLL") or m.display_char == "T" or m.display_char == "t"
	if leader_data.has_flag("UNDEAD") or ch == "z" or ch == "Z" or ch == "w":
		return func(m: DataManager.MonsterData) -> bool: return m.has_flag("UNDEAD") or m.display_char == "z" or m.display_char == "w"
	if leader_data.has_flag("SPIDER") or ch == "s" or ch == "S":
		return func(m: DataManager.MonsterData) -> bool: return m.has_flag("SPIDER") or m.display_char == "s"
	if leader_data.has_flag("WOLF") or ch == "w" or ch == "W":
		return func(m: DataManager.MonsterData) -> bool: return m.has_flag("WOLF") or m.display_char == "w"
	if leader_data.has_flag("MAN") or ch == "p" or ch == "P" or ch == "h":
		return func(m: DataManager.MonsterData) -> bool: return m.has_flag("MAN") or m.display_char == "p" or m.display_char == "h"
	# Fallback: same display char
	return func(m: DataManager.MonsterData) -> bool: return m.display_char == ch

## Post-placement pass: adjust alertness based on location context.
func _apply_location_alertness(depth: int, stairs_up: Vector2i) -> void:
	var stairs_down: Vector2i = level.find_stairs_down()

	for entity: Entity in level.entities:
		if not is_instance_valid(entity) or not entity is Monster:
			continue
		var monster: Monster = entity as Monster
		var pos: Vector2i = monster.grid_position
		var idx: int = pos.y * level.width + pos.x

		# Check room_id for corridor/room classification
		var rid: int = -1
		if idx >= 0 and idx < level.room_id.size():
			rid = level.room_id[idx]

		# Corridor monsters: more alert, wake up
		if rid == -1:
			monster.alertness = maxi(monster.alertness + Constants.ALERTNESS_CORRIDOR_BONUS, Constants.ALERTNESS_ALERT)
			monster.is_sleeping = false

		# Near stairs: sentries are quite alert and never sleeping
		var near_stairs: bool = false
		if stairs_up != Vector2i(-1, -1):
			var dist_up: int = maxi(absi(pos.x - stairs_up.x), absi(pos.y - stairs_up.y))
			if dist_up <= Constants.ALERTNESS_STAIRS_RADIUS:
				near_stairs = true
		if stairs_down != Vector2i(-1, -1):
			var dist_down: int = maxi(absi(pos.x - stairs_down.x), absi(pos.y - stairs_down.y))
			if dist_down <= Constants.ALERTNESS_STAIRS_RADIUS:
				near_stairs = true
		if near_stairs:
			monster.alertness = maxi(monster.alertness, Constants.ALERTNESS_QUITE_ALERT)
			monster.is_sleeping = false

		# Back room: far from any stair, sleep deeper
		if not near_stairs and rid >= 0:
			var min_stair_dist: int = 999
			if stairs_up != Vector2i(-1, -1):
				min_stair_dist = mini(min_stair_dist, maxi(absi(pos.x - stairs_up.x), absi(pos.y - stairs_up.y)))
			if stairs_down != Vector2i(-1, -1):
				min_stair_dist = mini(min_stair_dist, maxi(absi(pos.x - stairs_down.x), absi(pos.y - stairs_down.y)))
			if min_stair_dist > 15:
				monster.alertness += Constants.ALERTNESS_BACK_ROOM_PENALTY

## Classify monsters by encounter type based on their spawn location and context.
func _apply_encounter_types() -> void:
	for entity: Entity in level.entities:
		if not is_instance_valid(entity) or not entity is Monster:
			continue
		var monster: Monster = entity as Monster
		var pos: Vector2i = monster.grid_position
		var idx: int = pos.y * level.width + pos.x
		var rid: int = -1
		if idx >= 0 and idx < level.room_id.size():
			rid = level.room_id[idx]
		var is_corridor: bool = (rid == -1)

		if is_corridor:
			if _is_near_door(pos):
				monster.encounter_type = Constants.EncounterType.AMBUSH
			elif monster.monster_data and monster.monster_data.speed >= 3:
				monster.encounter_type = Constants.EncounterType.HUNTER
			else:
				monster.encounter_type = Constants.EncounterType.PATROL
		else:
			# In a room
			if _is_near_special_tile(pos):
				monster.encounter_type = Constants.EncounterType.GUARDIAN
			elif _is_near_door(pos):
				monster.encounter_type = Constants.EncounterType.WARDEN
			elif _count_same_type_nearby(monster, 3) >= 3:
				monster.encounter_type = Constants.EncounterType.NEST
			else:
				monster.encounter_type = Constants.EncounterType.WANDERER

## Check if a position is adjacent to a door (any type).
func _is_near_door(pos: Vector2i) -> bool:
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	for dir: Vector2i in dirs:
		var check: Vector2i = pos + dir
		if level.is_in_bounds(check):
			var tile: int = level.get_tile(check)
			if tile == Level.Tile.DOOR_CLOSED or tile == Level.Tile.DOOR_LOCKED or tile == Level.Tile.DOOR_JAMMED or tile == Level.Tile.DOOR_OPEN:
				return true
	return false

## Check if a position is near a special tile (forge, stairs).
func _is_near_special_tile(pos: Vector2i) -> bool:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var check: Vector2i = pos + Vector2i(dx, dy)
			if not level.is_in_bounds(check):
				continue
			var tile: int = level.get_tile(check)
			if tile == Level.Tile.FORGE or tile == Level.Tile.FORGE_ENCHANTED or tile == Level.Tile.FORGE_UNIQUE:
				return true
			if tile == Level.Tile.STAIRS_DOWN or tile == Level.Tile.STAIRS_UP:
				return true
	return false

## Count same-type monsters within a radius (by display_char).
func _count_same_type_nearby(monster: Monster, radius: int) -> int:
	if not monster.monster_data:
		return 0
	var ch: String = monster.monster_data.display_char
	var count: int = 0
	for entity: Entity in level.entities:
		if not is_instance_valid(entity) or entity == monster or not entity is Monster:
			continue
		var other: Monster = entity as Monster
		if other.monster_data and other.monster_data.display_char == ch:
			var dist: int = maxi(absi(other.grid_position.x - monster.grid_position.x), absi(other.grid_position.y - monster.grid_position.y))
			if dist <= radius:
				count += 1
	return count

## Try to spawn a unique monster lair in a large room. Returns monsters placed.
func _try_spawn_unique_lair(depth: int, monster_scene: PackedScene, stairs_up: Vector2i, fov_radius: int) -> int:
	# Find a large room (6x6+)
	var large_rooms: Array[int] = []
	for i in range(rooms.size()):
		var room: Rect2i = rooms[i]
		if room.size.x >= Constants.UNIQUE_LAIR_MIN_ROOM_SIZE and room.size.y >= Constants.UNIQUE_LAIR_MIN_ROOM_SIZE:
			large_rooms.append(i)
	if large_rooms.is_empty():
		return 0

	large_rooms.shuffle()
	var room_idx: int = large_rooms[0]
	var room: Rect2i = rooms[room_idx]
	var center: Vector2i = Vector2i(room.position.x + room.size.x / 2, room.position.y + room.size.y / 2)

	# Don't place lair in starting FOV
	if stairs_up != Vector2i(-1, -1) and _is_in_starting_fov(center, stairs_up, fov_radius):
		return 0

	# Pick a unique monster for this depth
	var unique_data: DataManager.MonsterData = null
	for m in DataManager.monsters.values():
		if m.has_flag("UNIQUE") and m.depth <= depth and m.depth >= maxi(1, depth - 4):
			if not DataManager.is_unique_already_spawned(m.name):
				unique_data = m
				break
	if not unique_data:
		return 0

	DataManager.mark_unique_spawned(unique_data.name)

	# Place unique at room center
	if level.get_entity_at(center) != null:
		center = level.find_random_floor_in_room(room)
		if center == Vector2i(-1, -1):
			return 0

	var unique_monster: Monster = monster_scene.instantiate()
	unique_monster.grid_position = center
	unique_monster.initialize_from_data(unique_data)
	unique_monster.alertness = Constants.ALERTNESS_VERY_ALERT
	unique_monster.is_sleeping = false
	level.add_entity(unique_monster)
	var spawned: int = 1

	# Spawn thematic escorts
	var escort_count: int = randi_range(2, 4)
	var predicate: Callable = _get_escort_predicate(unique_data)
	spawned += _spawn_escort_group(monster_scene, center, unique_data, depth, escort_count)

	# Telegraph the lair with a flavor message
	_telegraph_unique_presence(unique_data.name, center, stairs_up)

	print("Spawned unique lair: %s with %d escorts at depth %d" % [unique_data.name, spawned - 1, depth])
	return spawned

## Place a flavor message between stairs and a unique's lair position.
func _telegraph_unique_presence(monster_name: String, lair_pos: Vector2i, stairs_up: Vector2i) -> void:
	if stairs_up == Vector2i(-1, -1):
		return
	# Place message roughly 1/3 of the way from stairs to lair
	var mid: Vector2i = Vector2i(
		stairs_up.x + (lair_pos.x - stairs_up.x) / 3,
		stairs_up.y + (lair_pos.y - stairs_up.y) / 3
	)
	# Find nearest passable tile to midpoint
	var msg_pos: Vector2i = _find_nearest_passable(mid)
	if msg_pos != Vector2i(-1, -1):
		level.flavor_messages[msg_pos] = "You sense a powerful presence nearby... (%s)" % monster_name

## Place thematic layer entry flavor messages near stairs.
func _telegraph_layer_entry(depth: int, stairs_up: Vector2i) -> void:
	var layer_name: String = LayerConfig.get_layer_name(depth)
	var messages: Dictionary = {
		"lower_halls": "The tunnels widen into worked stone. Orc-marks scar the walls.",
		"dark_halls": "An unnatural chill settles over you. The air tastes of old magic.",
		"necropolis": "The stench of death grows overwhelming. Bones crunch underfoot.",
		"pits_of_despair": "Shadows writhe at the edges of your vision. Despair gnaws at your will.",
		"inner_sanctum": "Golden light flickers from deep within. The heart of Dol Guldur draws near.",
		"throne_room": "The air burns with dark power. You stand at the threshold of Sauron's domain.",
	}
	var msg: String = messages.get(layer_name, "")
	if msg.is_empty():
		return
	# Place 2 tiles from stairs_up (any direction that's passable)
	var dirs: Array[Vector2i] = [Vector2i(0, 2), Vector2i(2, 0), Vector2i(0, -2), Vector2i(-2, 0)]
	dirs.shuffle()
	for dir: Vector2i in dirs:
		var pos: Vector2i = stairs_up + dir
		if level.is_in_bounds(pos) and level.is_passable(pos) and not level.flavor_messages.has(pos):
			level.flavor_messages[pos] = msg
			return

func _spawn_items(depth: int) -> void:
	# Item count: 75% of monster target formula, capped at 15
	var monster_target: int = (rooms.size() + randi_range(1, maxi(1, rooms.size()))) / 2 + depth / 3
	var base_item_count: int = mini(int(monster_target * 0.75), 15)
	# Apply difficulty item spawn multiplier
	var spawn_mult: float = GameManager.get_item_spawn_multiplier() if GameManager else 1.0
	var item_count: int = maxi(1, int(base_item_count * spawn_mult))

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
			# Tiered loot curve based on depth
			var loot_tier: String = _roll_loot_tier(depth)
			match loot_tier:
				"minor":
					_apply_floor_ego(item_copy, depth)
				"major":
					_apply_floor_ego(item_copy, depth)
					# Major items also get "fine" quality boost
					item_copy.attack_bonus += 1
					item_copy.evasion_bonus += 1
				"artifact":
					# Try to replace with a real artifact from artefact.txt
					var art: DataManager.ArtifactData = DataManager.get_random_artifact()
					if art:
						var art_item: DataManager.ItemData = DataManager.duplicate_artifact_as_item(art)
						# Use the artifact copy instead
						item_copy = art_item
			# Ensure ammo spawns as useful stacks.
			if "tval" in item_copy and (item_copy.tval == 16 or item_copy.tval == 17):
				var ammo_count: int = randi_range(8, 16) + int(depth / 4)
				ammo_count = clampi(ammo_count, 8, 24)
				item_copy.pval = ammo_count
				item_copy.stack_count = ammo_count
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

	# Guaranteed bow + arrows on floor 1 (archers need starting equipment)
	if depth == 1:
		var bow_data: DataManager.ItemData = DataManager.get_item_by_tval_sval(19, 12)  # Silvan Bow
		var arrow_data: DataManager.ItemData = DataManager.get_item_by_tval_sval(17, 1)  # Arrow
		var stairs_up_pos: Vector2i = level.find_stairs_up()
		if stairs_up_pos == Vector2i(-1, -1):
			stairs_up_pos = level.find_random_floor()

		if bow_data:
			var bow_copy: DataManager.ItemData = DataManager.duplicate_item_data(bow_data)
			var bow_pos: Vector2i = _find_floor_near(stairs_up_pos, 3)
			var bow_item: Item = item_scene.instantiate()
			bow_item.grid_position = bow_pos
			bow_item.initialize_from_item_data(bow_copy)
			level.add_item(bow_item)
			spawned += 1

		if arrow_data:
			var arrow_copy: DataManager.ItemData = DataManager.duplicate_item_data(arrow_data)
			if "pval" in arrow_copy:
				arrow_copy.pval = 24  # 24 arrows
				arrow_copy.stack_count = 24
			elif "stack_count" in arrow_copy:
				arrow_copy.stack_count = 24
			var arrow_pos: Vector2i = _find_floor_near(stairs_up_pos, 3)
			var arrow_item: Item = item_scene.instantiate()
			arrow_item.grid_position = arrow_pos
			arrow_item.initialize_from_item_data(arrow_copy)
			level.add_item(arrow_item)
			spawned += 1

	print("Spawned %d items at depth %d" % [spawned, depth])

## Find a passable floor tile near the given position within max_radius.
func _find_floor_near(center: Vector2i, max_radius: int) -> Vector2i:
	for radius in range(1, max_radius + 1):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var pos := Vector2i(center.x + dx, center.y + dy)
				if level.is_in_bounds(pos) and level.is_passable(pos):
					if level.get_entity_at(pos) == null:
						# Check no item already here
						var items_here: Array[Item] = level.get_items_at(pos)
						if items_here.is_empty():
							return pos
	return level.find_random_floor()

## Place themed guards adjacent to doors.
## Chance scales with depth: (15 + 2*depth)%, capped at 50%. Max 2 per level.
func _place_door_guards(depth: int) -> void:
	var guard_chance: float = minf(0.15 + 0.02 * depth, 0.50)
	var max_guards: int = 2
	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var guards_placed: int = 0
	var cardinal_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for y in range(1, level.height - 1):
		if guards_placed >= max_guards:
			break
		for x in range(1, level.width - 1):
			if guards_placed >= max_guards:
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
					if guard_data and _can_place_pre_spawn_monster(depth, guard_data):
						var guard: Monster = monster_scene.instantiate()
						guard.grid_position = guard_pos
						guard.initialize_from_data(guard_data)
						guard.alertness = Constants.ALERTNESS_QUITE_ALERT
						guard.is_sleeping = false
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
## Safety: impassable scatter tiles (e.g. RUBBLE) are not placed in 1-wide corridors.
func _scatter_terrain(depth: int, params: Dictionary) -> void:
	var density: float = params.get("scatter_density", 0.0)
	if density <= 0.0:
		return

	var layer_name: String = LayerConfig.get_layer_name(depth)
	var scatter_tile: int = _get_scatter_tile_for_layer(layer_name)
	var tile_is_impassable: bool = not _is_scatter_tile_passable(scatter_tile)
	var scattered: int = 0

	for y in range(1, level.height - 1):
		for x in range(1, level.width - 1):
			var pos := Vector2i(x, y)
			if level.get_tile(pos) == Level.Tile.FLOOR and randf() < density:
				# Don't place impassable scatter in narrow corridors
				if tile_is_impassable and _count_passable_neighbors(pos) < 3:
					continue
				level.set_tile(pos, scatter_tile)
				scattered += 1

	if scattered > 0:
		print("Scattered %d terrain tiles at depth %d" % [scattered, depth])

## Check if a scatter tile type is passable (walkable).
func _is_scatter_tile_passable(tile: int) -> bool:
	match tile:
		Level.Tile.RUBBLE:
			return false
		_:
			return true

## Count passable neighbors around a position (8-directional).
func _count_passable_neighbors(pos: Vector2i) -> int:
	var count: int = 0
	var dirs: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	for dir: Vector2i in dirs:
		var neighbor: Vector2i = pos + dir
		if level.is_in_bounds(neighbor) and level.is_passable(neighbor):
			count += 1
	return count

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
			# Do not overwrite themed vine/web floor; poison streams should be visually and mechanically distinct.
			if tile == Level.Tile.FLOOR:
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
				var pool_chance: float = 0.15 if level and level.depth == 15 else 0.25
				_place_shadow_gallery(room_rect, pool_chance)
			"chasm_bridge":
				# Chasm across room with 1-tile-wide floor bridge
				var bridge_y: int = cy
				for y in range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 1):
					for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
						var pos := Vector2i(x, y)
						if y != bridge_y and _is_safe_floor(pos):
							level.set_tile(pos, Level.Tile.CHASM)

## Helper: place shadow gallery pattern (brazier rows + dark pools between).
func _place_shadow_gallery(room_rect: Rect2i, dark_pool_chance: float = 0.30) -> void:
	for y in range(room_rect.position.y + 1, room_rect.position.y + room_rect.size.y - 1):
		for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
			var local_x: int = x - room_rect.position.x
			var local_y: int = y - room_rect.position.y
			var pos := Vector2i(x, y)
			if local_x % 4 == 0 and local_y % 3 == 0:
				if _is_safe_floor(pos):
					level.set_tile(pos, Level.Tile.SHADOW_BRAZIER)
			elif local_x % 4 == 2 and _is_safe_floor(pos) and randf() < dark_pool_chance:
				level.set_tile(pos, Level.Tile.DARK_POOL)

## Inner Sanctum (depths 16-18): Grand halls and guard posts (no lava theme).
func _decorate_inner_sanctum(params: Dictionary) -> void:
	var themed_chance: float = params.get("themed_room_chance", 0.80)
	var subtypes: Array[String] = ["grand_hall", "guard_post"]

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
				# Rubble barricade near door + shadow floor accents in corners
				# Barricade: rubble row across the room's narrower axis
				var barricade_y: int = cy - 1
				for x in range(room_rect.position.x + 1, room_rect.position.x + room_rect.size.x - 1):
					var pos := Vector2i(x, barricade_y)
					if _is_safe_floor(pos) and randf() < 0.60:
						level.set_tile(pos, Level.Tile.RUBBLE)
				# Shadow floor in corners
				var corners: Array[Vector2i] = [
					Vector2i(room_rect.position.x + 1, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + 1),
					Vector2i(room_rect.position.x + 1, room_rect.position.y + room_rect.size.y - 2),
					Vector2i(room_rect.position.x + room_rect.size.x - 2, room_rect.position.y + room_rect.size.y - 2)
				]
				for corner: Vector2i in corners:
					if _is_safe_floor(corner):
						level.set_tile(corner, Level.Tile.SHADOW_FLOOR)

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
# ENVIRONMENTAL STORYTELLING
# ============================================================================

## Per-layer flavor messages for environmental storytelling.
## Each message is displayed once when the player steps on the tile.
const STORYTELLING_MESSAGES: Dictionary = {
	"outer_pits": [
		"Crude orc scratches on the wall: three slashes. A warning.",
		"A broken elven arrow juts from the stone, ancient and forgotten.",
		"You notice boot prints in the dust — they lead deeper.",
		"A faded carving reads: 'Beware the pits below.'",
		"Claw marks gouge the wall at shoulder height.",
		"A crude map is scratched into the floor. Most paths end in skulls.",
		"You find a torn scrap of cloth caught on a jagged stone.",
		"The faint smell of old campfires lingers here.",
	],
	"lower_halls": [
		"Orcish graffiti covers this wall: crude boasts and kill counts.",
		"A rusted weapon rack stands empty, its contents long looted.",
		"You notice orc banners hanging in tatters from iron hooks.",
		"A crude trophy — bones wired together — hangs from the ceiling.",
		"The stone here is worn smooth by countless marching feet.",
		"Old bloodstains darken the floor in a wide arc.",
		"A discarded whetstone lies amid metal shavings.",
		"The walls are scarred with practice sword cuts.",
	],
	"dark_halls": [
		"Elvish script, barely legible: 'Turn back, mortal.'",
		"Strange symbols pulse faintly in the stone, then fade.",
		"A circle of melted candles surrounds a dark stain on the floor.",
		"The air here tastes of iron and old magic.",
		"You feel a chill that has nothing to do with temperature.",
		"Faint screams echo from somewhere far below — or is it the wind?",
		"A shattered crystal lies in a perfect circle of scorched stone.",
		"The walls here seem to breathe. You tell yourself it's a draft.",
	],
	"necropolis": [
		"An inscription reads: 'Here lies one who sought the Ring.'",
		"Empty sarcophagi line the walls, their lids cast aside.",
		"You notice fingernail scratches on the inside of a stone coffin.",
		"A withered funeral wreath crumbles at your touch.",
		"Names are carved into every surface — hundreds of the dead.",
		"Cold breath seems to exhale from the walls themselves.",
		"A half-open tomb reveals nothing but dust and shadow.",
		"The air reeks of embalming spices and ancient decay.",
	],
	"pits_of_despair": [
		"Chains hang from the ceiling, still swaying slightly.",
		"A desperate message carved with bare fingers: 'NO ESCAPE.'",
		"The stone is warm to the touch. Something burns below.",
		"You hear weeping from the depths — distant, inconsolable.",
		"Scorch marks in the shape of a hand are burned into the wall.",
		"A pile of shattered shackles lies discarded in the corner.",
		"The shadows here seem to reach toward you, then retreat.",
		"A faint red glow pulses from cracks in the floor.",
	],
	"inner_sanctum": [
		"Gold-inlaid script reads: 'All who enter serve the Necromancer.'",
		"An ancient mural depicts the fall of a great elven city.",
		"The stone here is black as night and cold as winter.",
		"You sense a vast intelligence pressing against your thoughts.",
		"A shattered mirror reflects a face that is not your own.",
		"Dark flames flicker in wall sconces, casting no warmth.",
		"The floor bears the sigil of Sauron, worn smooth by supplicants.",
		"A whisper promises power beyond imagining. You ignore it.",
	],
	"throne_room": [
		"The walls radiate malevolence. This is the heart of darkness.",
		"Ancient script proclaims: 'The Lord of the Rings shall return.'",
		"The air crackles with power barely contained.",
		"Every shadow seems to watch. Every silence seems to listen.",
	],
}

## Scatter environmental storytelling flavor messages across the level.
## Places 2-5 messages per floor in high-impact rooms first, then fallback.
func _scatter_storytelling(depth: int) -> void:
	var layer_name: String = LayerConfig.get_layer_name(depth)
	if layer_name not in STORYTELLING_MESSAGES:
		return

	var messages: Array = STORYTELLING_MESSAGES[layer_name]
	if messages.is_empty():
		return

	# Scale message count with depth: 2-3 shallow, 3-5 deep
	var msg_count: int = randi_range(2, 3)
	if depth >= 7:
		msg_count = randi_range(3, 4)
	if depth >= 13:
		msg_count = randi_range(3, 5)

	# Shuffle messages and pick unique ones
	var available: Array = messages.duplicate()
	available.shuffle()

	# Build preferred room order: vault/terror/deep/grand/exit, then everything else.
	var preferred_rooms: Array[int] = _get_storytelling_room_order()
	var placed: int = 0
	for i in range(mini(msg_count, available.size())):
		var pos: Vector2i = _find_storytelling_position(preferred_rooms)
		if pos == Vector2i(-1, -1):
			continue
		level.set_tile(pos, Level.Tile.INSCRIPTION)
		level.flavor_messages[pos] = available[i]
		placed += 1

	if placed > 0:
		print("Placed %d storytelling messages at depth %d" % [placed, depth])

func _get_storytelling_room_order() -> Array[int]:
	var weighted: Array[Dictionary] = []
	for room_idx in range(rooms.size()):
		var tags_raw: Variant = level.room_tags.get(room_idx, [])
		var tags: Array[String] = []
		if tags_raw is Array:
			for tag in tags_raw:
				tags.append(str(tag))
		var score: int = 0
		if "vault" in tags:
			score += 5
		if "terror" in tags:
			score += 4
		if "deep" in tags:
			score += 3
		if "grand" in tags:
			score += 2
		if "exit" in tags:
			score += 1
		weighted.append({"room": room_idx, "score": score + randi_range(0, 2)})
	weighted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.score) > int(b.score)
	)
	var out: Array[int] = []
	for w in weighted:
		out.append(int(w.room))
	return out

func _find_storytelling_position(room_order: Array[int]) -> Vector2i:
	var stairs_up: Vector2i = level.find_stairs_up()
	var stairs_down: Vector2i = level.find_stairs_down()

	for room_idx in room_order:
		if room_idx < 0 or room_idx >= rooms.size():
			continue
		var room: Rect2i = rooms[room_idx]
		for _attempt in range(20):
			var x: int = randi_range(room.position.x + 1, room.end.x - 2)
			var y: int = randi_range(room.position.y + 1, room.end.y - 2)
			var pos := Vector2i(x, y)
			if not level.is_in_bounds(pos):
				continue
			if not level.is_passable(pos):
				continue
			if level.get_entity_at(pos) != null:
				continue
			if level.flavor_messages.has(pos):
				continue
			if stairs_up != Vector2i(-1, -1) and pos.distance_to(stairs_up) < 4.0:
				continue
			if stairs_down != Vector2i(-1, -1) and pos.distance_to(stairs_down) < 4.0:
				continue
			return pos

	# Fallback to generic random floor if no room-qualified tile found.
	for _i in range(20):
		var fallback: Vector2i = level.find_random_floor()
		if fallback == Vector2i(-1, -1):
			continue
		if not level.flavor_messages.has(fallback):
			return fallback
	return Vector2i(-1, -1)

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

	var spawn_pos := Vector2i(-1, -1)
	var stairs_up: Vector2i = level.find_stairs_up()
	var stairs_down: Vector2i = level.find_stairs_down()

	# Depth 20: deterministic placement 2 tiles north of Sauron.
	if depth >= 20:
		spawn_pos = _find_depth20_thrain_near_sauron_position()

	# Prefer a middle room when possible, but don't hard-fail on small room counts
	# (depth 20 throne generation often has <3 rooms).
	if spawn_pos == Vector2i(-1, -1) and rooms.size() >= 3:
		var room_index := randi_range(1, rooms.size() - 2)
		var thrain_room := rooms[room_index]
		spawn_pos = Vector2i(
			thrain_room.position.x + thrain_room.size.x / 2,
			thrain_room.position.y + thrain_room.size.y / 2
		)
	elif spawn_pos == Vector2i(-1, -1) and not rooms.is_empty():
		var room_index := randi_range(0, rooms.size() - 1)
		var thrain_room := rooms[room_index]
		spawn_pos = Vector2i(
			thrain_room.position.x + thrain_room.size.x / 2,
			thrain_room.position.y + thrain_room.size.y / 2
		)

	# Make sure the position is valid
	if spawn_pos == Vector2i(-1, -1) or level.get_tile(spawn_pos) != Level.Tile.FLOOR or level.get_entity_at(spawn_pos) != null:
		# Room center failed; fallback to random floor.
		spawn_pos = level.find_random_floor()
		if spawn_pos == Vector2i(-1, -1):
			return false

	# Don't place Thrain directly on stairs.
	if spawn_pos == stairs_up or spawn_pos == stairs_down:
		var alt_pos: Vector2i = level.find_random_floor()
		if alt_pos != Vector2i(-1, -1):
			spawn_pos = alt_pos

	# Load ThrainNPC script at runtime to avoid circular dependency issues
	var thrain_script: GDScript = load("res://scripts/entities/thrain_npc.gd")
	if thrain_script == null:
		push_error("Failed to load thrain_npc.gd")
		return false

	# Create Thrain using the static factory method
	var thrain: Node = thrain_script.create_at_position(spawn_pos, quest_system)
	# Set identifying fields immediately so callers can detect him before _ready runs.
	if thrain.has_method("set"):
		thrain.set("npc_id", "thrain_ii")
		thrain.set("entity_name", "Thrain II, Son of Thror")
	level.add_entity(thrain)

	quest_system.mark_thrain_spawned()
	print("Spawned Thrain II at depth %d, position %s" % [depth, spawn_pos])

	return true

func _find_depth20_thrain_near_sauron_position() -> Vector2i:
	var sauron_pos: Vector2i = _find_depth20_sauron_position()
	if sauron_pos == Vector2i(-1, -1):
		return Vector2i(-1, -1)
	var target := sauron_pos + Vector2i(0, -2)
	return _force_or_find_valid_thrain_tile(target)

func _find_depth20_sauron_position() -> Vector2i:
	const SAURON_ID: int = 135
	for entity in level.entities:
		if not is_instance_valid(entity) or not entity is Monster:
			continue
		var m: Monster = entity as Monster
		if m.monster_data and m.monster_data.index == SAURON_ID:
			return m.grid_position
	# Fallback to throne-boss target if entity not yet instantiated.
	return _find_throne_boss_position()

func _force_or_find_valid_thrain_tile(target: Vector2i) -> Vector2i:
	if level.is_in_bounds(target):
		var tile: int = level.get_tile(target)
		if tile != Level.Tile.STAIRS_UP and tile != Level.Tile.STAIRS_DOWN and tile != Level.Tile.THRONE_DAIS and not level.is_passable(target):
			level.set_tile(target, Level.Tile.FLOOR)

		var blocker: Entity = level.get_entity_at(target)
		if blocker != null:
			var moved: bool = false
			for r in range(1, 13):
				for y in range(target.y - r, target.y + r + 1):
					for x in range(target.x - r, target.x + r + 1):
						var pos := Vector2i(x, y)
						if not _is_valid_thrain_spawn_tile(pos):
							continue
						blocker.grid_position = pos
						moved = true
						break
					if moved:
						break
				if moved:
					break
			if not moved:
				level.remove_entity(blocker)
				blocker.queue_free()
		if _is_valid_thrain_spawn_tile(target):
			return target

	# Nearby fallback if exact target can't be made valid.
	for r in range(1, 13):
		for y in range(target.y - r, target.y + r + 1):
			for x in range(target.x - r, target.x + r + 1):
				var pos := Vector2i(x, y)
				if _is_valid_thrain_spawn_tile(pos):
					return pos
	return Vector2i(-1, -1)

func _is_valid_thrain_spawn_tile(pos: Vector2i) -> bool:
	if not level.is_in_bounds(pos):
		return false
	if not level.is_passable(pos):
		return false
	var tile: int = level.get_tile(pos)
	if tile == Level.Tile.STAIRS_UP or tile == Level.Tile.STAIRS_DOWN or tile == Level.Tile.THRONE_DAIS:
		return false
	return level.get_entity_at(pos) == null

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
			_vault_rects.append(Rect2i(vault_pos.x, vault_pos.y, throne_vault.width, throne_vault.height))
			print("Placed Sauron's throne vault at depth %d" % depth)
		else:
			# Vault doesn't fit — fall through to normal generation
			_fallback_throne_room(depth)
	else:
		# No throne vault found — generate a basic large room
		_fallback_throne_room(depth)

	# Check if the vault already placed stairs_up (<)
	var existing_stairs: Vector2i = level.find_stairs_up()
	if existing_stairs == Vector2i(-1, -1):
		# No stairs from vault — find a floor tile to place them
		var up_pos := Vector2i(-1, -1)
		for y in range(1, level.height - 1):
			for x in range(1, level.width - 1):
				var pos := Vector2i(x, y)
				if level.is_in_bounds(pos) and level.get_tile(pos) == Level.Tile.FLOOR:
					up_pos = pos
					break
			if up_pos != Vector2i(-1, -1):
				break
		if up_pos != Vector2i(-1, -1):
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

	# Final safety sweep
	var stairs_up: Vector2i = level.find_stairs_up()
	_clear_monsters_near_stairs(stairs_up)
	_ensure_final_boss_sauron()

	level.generation_complete.emit(level.width, level.height)

## Depth-20 guarantee: ensure Sauron (ID 135) is present on/near the throne dais.
## If multiple Saurons exist, keep one and remove extras.
func _ensure_final_boss_sauron() -> void:
	const SAURON_ID: int = 135
	var sauron_data: DataManager.MonsterData = _get_monster_data_by_index(SAURON_ID)
	if sauron_data == null:
		push_warning("Depth 20: could not find monster data for Sauron (ID 135)")
		return

	var target_pos: Vector2i = _find_throne_boss_position()
	if target_pos == Vector2i(-1, -1):
		push_warning("Depth 20: could not find valid spawn tile for Sauron")
		return

	var existing: Array[Monster] = []
	for entity in level.entities:
		if not is_instance_valid(entity) or not entity is Monster:
			continue
		var m: Monster = entity as Monster
		if m.monster_data and m.monster_data.index == SAURON_ID:
			existing.append(m)

	var keeper: Monster = null
	if not existing.is_empty():
		keeper = existing[0]
		# Remove duplicate Saurons if they somehow spawned via random/vault flow.
		for i in range(1, existing.size()):
			var dup: Monster = existing[i]
			level.remove_entity(dup)
			dup.queue_free()

	if keeper == null:
		var monster_scene := preload("res://scenes/entities/monster.tscn")
		keeper = monster_scene.instantiate()
		keeper.grid_position = target_pos
		keeper.initialize_from_data(sauron_data)
		level.add_entity(keeper)
	else:
		keeper.grid_position = target_pos

	# Hard-set final boss posture/flags.
	keeper.alertness = Constants.ALERTNESS_VERY_ALERT
	keeper.is_sleeping = false
	keeper.is_unique = true
	keeper.is_brave = true
	DataManager.mark_unique_spawned(sauron_data.name)
	print("Depth 20: ensured Sauron at %s" % [target_pos])

## Find throne-boss position: prefer THRONE_DAIS nearest map center, else nearest floor.
func _find_throne_boss_position() -> Vector2i:
	var center := Vector2i(level.width / 2, level.height / 2)
	var dais_tiles: Array[Vector2i] = []
	for y in range(level.height):
		for x in range(level.width):
			var pos := Vector2i(x, y)
			if level.get_tile(pos) == Level.Tile.THRONE_DAIS:
				dais_tiles.append(pos)

	# Preferred: open throne dais tile closest to center.
	if not dais_tiles.is_empty():
		dais_tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var da: int = maxi(absi(a.x - center.x), absi(a.y - center.y))
			var db: int = maxi(absi(b.x - center.x), absi(b.y - center.y))
			return da < db
		)
		for p in dais_tiles:
			if _is_valid_final_boss_tile(p):
				return p
		# Dais exists but occupied/invalid: use nearest valid tile around dais center.
		var dais_center := dais_tiles[0]
		var near := _find_nearest_valid_boss_tile(dais_center, 8)
		if near != Vector2i(-1, -1):
			return near

	# Fallback: nearest valid floor around map center.
	return _find_nearest_valid_boss_tile(center, 12)

func _find_nearest_valid_boss_tile(origin: Vector2i, max_radius: int) -> Vector2i:
	for r in range(0, max_radius + 1):
		for y in range(origin.y - r, origin.y + r + 1):
			for x in range(origin.x - r, origin.x + r + 1):
				var pos := Vector2i(x, y)
				if not level.is_in_bounds(pos):
					continue
				if _is_valid_final_boss_tile(pos):
					return pos
	return Vector2i(-1, -1)

func _is_valid_final_boss_tile(pos: Vector2i) -> bool:
	if not level.is_in_bounds(pos):
		return false
	var tile: int = level.get_tile(pos)
	if tile == Level.Tile.STAIRS_UP or tile == Level.Tile.STAIRS_DOWN:
		return false
	if not level.is_passable(pos):
		return false
	var occupant: Entity = level.get_entity_at(pos)
	return occupant == null

func _get_monster_data_by_index(monster_id: int) -> DataManager.MonsterData:
	for m in DataManager.monsters.values():
		if m.index == monster_id:
			return m
	return null

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
			_vault_room_ids[rooms.size() - 1] = true
			_vault_rects.append(Rect2i(pos.x, pos.y, vault.width, vault.height))
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
# LOOT TIER ROLLER
# ============================================================================

## Roll a loot tier based on floor depth
func _roll_loot_tier(depth: int) -> String:
	var roll: int = randi_range(1, 100)
	# Tier probabilities: [mundane, minor, major, artifact]
	var mundane: int
	var minor: int
	var major: int
	# var artifact is the remainder

	if depth <= 3:
		mundane = 90; minor = 8; major = 2  # artifact = 0
	elif depth <= 6:
		mundane = 85; minor = 10; major = 5  # artifact = 0
	elif depth <= 9:
		mundane = 78; minor = 12; major = 8  # artifact = 2
	elif depth <= 12:
		mundane = 70; minor = 12; major = 12  # artifact = 6
	elif depth <= 15:
		mundane = 62; minor = 8; major = 20  # artifact = 10
	elif depth <= 18:
		mundane = 50; minor = 10; major = 25  # artifact = 15
	else:
		mundane = 35; minor = 5; major = 40  # artifact = 20

	if roll <= mundane:
		return "mundane"
	elif roll <= mundane + minor:
		return "minor"
	elif roll <= mundane + minor + major:
		return "major"
	else:
		return "artifact"

# ============================================================================
# EGO ENCHANTMENT FOR FLOOR ITEMS
# ============================================================================

## Apply random ego enchantment to a floor-spawned item based on depth
func _apply_floor_ego(item: DataManager.ItemData, depth: int, exclude_cursed: bool = false) -> void:
	var ego: DataManager.EgoData = DataManager.select_ego_for_item(item.tval, item.sval, depth, exclude_cursed)
	if ego:
		DataManager.apply_ego_to_item(item, ego)
	else:
		# Fallback: just add a quality bonus if no matching ego found
		var quality: int = 1 if depth < 10 else 2
		item.attack_bonus += quality
		item.name = "Fine %s" % item.name
