extends RefCounted
class_name DungeonGenerator
## Procedural dungeon generation for The Necromancer.
## Based on classic roguelike room-and-corridor generation.

# Default values (overridden by LayerConfig per depth)
const DEFAULT_MIN_ROOM_SIZE := 4
const DEFAULT_MAX_ROOM_SIZE := 12
const DEFAULT_MAX_ROOMS := 30
const ROOM_PLACEMENT_ATTEMPTS := 100

# Layer-based generation parameters (set per level)
var min_room_size := DEFAULT_MIN_ROOM_SIZE
var max_room_size := DEFAULT_MAX_ROOM_SIZE
var max_rooms := DEFAULT_MAX_ROOMS
var corridor_width := 1
var vault_chance := 0.1

var level: Level
var rooms: Array[Rect2i] = []

class Room:
	var rect: Rect2i
	var is_connected: bool = false

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

func generate(target_level: Level, depth: int) -> void:
	level = target_level
	rooms.clear()

	# Get layer-specific generation parameters
	_apply_layer_params(depth)

	# Fill with walls
	for y in range(level.height):
		for x in range(level.width):
			level.set_tile(Vector2i(x, y), Level.Tile.WALL)

	# Generate rooms
	_generate_rooms()

	# Connect rooms with corridors
	_connect_rooms()

	# Try to place vaults (special pre-designed rooms)
	_try_place_vaults(depth)

	# Place stairs
	_place_stairs(depth)

	# Add features based on depth
	_add_features(depth)

	# Spawn monsters
	_spawn_monsters(depth)

	# Spawn items
	_spawn_items(depth)

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

	for _attempt in range(ROOM_PLACEMENT_ATTEMPTS):
		if room_list.size() >= max_rooms:
			break

		var room_width := randi_range(min_room_size, max_room_size)
		var room_height := randi_range(min_room_size, max_room_size)
		var room_x := randi_range(1, level.width - room_width - 1)
		var room_y := randi_range(1, level.height - room_height - 1)

		var new_room := Room.new(Rect2i(room_x, room_y, room_width, room_height))

		# Check for overlap
		var overlaps := false
		for existing in room_list:
			if new_room.intersects(existing, 2):
				overlaps = true
				break

		if not overlaps:
			_carve_room(new_room)
			room_list.append(new_room)
			rooms.append(new_room.rect)

func _carve_room(room: Room) -> void:
	for y in range(room.rect.position.y, room.rect.position.y + room.rect.size.y):
		for x in range(room.rect.position.x, room.rect.position.x + room.rect.size.x):
			level.set_tile(Vector2i(x, y), Level.Tile.FLOOR)

func _connect_rooms() -> void:
	if rooms.size() < 2:
		return

	# Connect each room to the next one
	for i in range(rooms.size() - 1):
		var room_a := rooms[i]
		var room_b := rooms[i + 1]

		var center_a := Vector2i(room_a.position.x + room_a.size.x / 2,
								room_a.position.y + room_a.size.y / 2)
		var center_b := Vector2i(room_b.position.x + room_b.size.x / 2,
								room_b.position.y + room_b.size.y / 2)

		# Randomly choose horizontal-first or vertical-first
		if randf() < 0.5:
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

			if randf() < 0.5:
				_carve_h_corridor(center_a.x, center_b.x, center_a.y)
				_carve_v_corridor(center_a.y, center_b.y, center_b.x)
			else:
				_carve_v_corridor(center_a.y, center_b.y, center_a.x)
				_carve_h_corridor(center_a.x, center_b.x, center_b.y)

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
	# Add doors at corridor junctions
	for y in range(1, level.height - 1):
		for x in range(1, level.width - 1):
			var pos := Vector2i(x, y)
			if level.get_tile(pos) == Level.Tile.FLOOR:
				if _is_door_candidate(pos):
					if randf() < 0.3:  # 30% chance for doors
						var door_type: int = _pick_door_type(depth)
						level.set_tile(pos, door_type)

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

	# Add a forge on certain levels
	if depth % 4 == 0 and rooms.size() > 2:
		var forge_room := rooms[randi() % rooms.size()]
		var forge_pos := Vector2i(
			forge_room.position.x + forge_room.size.x / 2,
			forge_room.position.y + forge_room.size.y / 2
		)
		level.set_tile(forge_pos, Level.Tile.FORGE)

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

	# Boss room on certain depths
	if depth > 0 and depth % 5 == 0:
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

func _add_boss_room(depth: int) -> void:
	# Create a special room with a guaranteed boss monster
	if rooms.size() < 3:
		return

	# Pick a room that isn't first or last (not near stairs)
	var boss_room_idx: int = randi_range(1, rooms.size() - 2)
	var boss_room: Rect2i = rooms[boss_room_idx]

	# Spawn a stronger monster
	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var boss_data := DataManager.get_random_monster_for_depth(depth + 3)
	if boss_data:
		var boss_pos := Vector2i(
			boss_room.position.x + boss_room.size.x / 2,
			boss_room.position.y + boss_room.size.y / 2
		)
		if level.get_tile(boss_pos) == Level.Tile.FLOOR and level.get_entity_at(boss_pos) == null:
			var boss: Monster = monster_scene.instantiate()
			boss.grid_position = boss_pos
			boss.initialize_from_data(boss_data)
			# Make boss tougher
			boss.max_health = int(boss.max_health * 1.5)
			boss.current_health = boss.max_health
			boss.experience_value = int(boss.experience_value * 2)
			level.add_entity(boss)

			# Add some treasure near the boss
			var item_scene := preload("res://scenes/entities/item.tscn")
			var item_data := DataManager.get_random_item_for_depth(depth + 2)
			if item_data:
				var item_pos := Vector2i(boss_pos.x + 1, boss_pos.y)
				if level.is_in_bounds(item_pos) and level.get_tile(item_pos) == Level.Tile.FLOOR:
					var item: Item = item_scene.instantiate()
					item.grid_position = item_pos
					item.initialize_from_item_data(item_data)
					level.add_item(item)

func _is_door_candidate(pos: Vector2i) -> bool:
	# A position is a door candidate if it connects two areas
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

	for y in range(vault.map_lines.size()):
		if y >= vault.height:
			break
		var line: String = vault.map_lines[y]
		for x in range(line.length()):
			if x >= vault.width:
				break

			var ch: String = line[x]
			var tile_pos := Vector2i(pos.x + x, pos.y + y)

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
				"*":
					# Treasure
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					var item_data := DataManager.get_random_item_for_depth(depth)
					if item_data:
						var item: Item = item_scene.instantiate()
						item.grid_position = tile_pos
						item.initialize_from_item_data(item_data)
						level.add_item(item)
				"&":
					# Good treasure (higher depth items)
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					var item_data := DataManager.get_random_item_for_depth(depth + 3)
					if item_data:
						var item: Item = item_scene.instantiate()
						item.grid_position = tile_pos
						item.initialize_from_item_data(item_data)
						level.add_item(item)
				"1", "2", "3", "4":
					# Monster at depth + N
					level.set_tile(tile_pos, Level.Tile.FLOOR)
					var monster_depth := depth + int(ch)
					var monster_data := DataManager.get_random_monster_for_depth(monster_depth)
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
	rooms.append(Rect2i(pos.x, pos.y, vault.width, vault.height))

func _spawn_monsters(depth: int) -> void:
	# Number of monsters scales with depth
	var monster_count := randi_range(3 + depth, 5 + depth * 2)
	monster_count = mini(monster_count, 20)  # Cap

	var monster_scene := preload("res://scenes/entities/monster.tscn")
	var spawned := 0

	for _i in range(monster_count):
		var spawn_pos := level.find_random_floor()
		if spawn_pos == Vector2i(-1, -1):
			continue

		# Don't spawn too close to stairs up
		var stairs_up := level.find_stairs_up()
		if stairs_up != Vector2i(-1, -1):
			var dist: int = max(abs(spawn_pos.x - stairs_up.x), abs(spawn_pos.y - stairs_up.y))
			if dist < 5:
				continue

		var monster_data := DataManager.get_random_monster_for_depth(depth)
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
				var escort_data := DataManager.get_random_monster_for_depth(maxi(1, depth - 2))
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
	# Number of items scales with depth (fewer items than monsters)
	var item_count := randi_range(2 + depth / 2, 4 + depth)
	item_count = mini(item_count, 15)

	var item_scene := preload("res://scenes/entities/item.tscn")
	var spawned := 0

	for _i in range(item_count):
		var spawn_pos := level.find_random_floor()
		if spawn_pos == Vector2i(-1, -1):
			continue

		var item_data := DataManager.get_random_item_for_depth(depth)
		if item_data:
			var item: Item = item_scene.instantiate()
			item.grid_position = spawn_pos
			item.initialize_from_item_data(item_data)
			level.add_item(item)
			spawned += 1

	print("Spawned %d items at depth %d" % [spawned, depth])

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
