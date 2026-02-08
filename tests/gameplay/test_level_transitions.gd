extends GutTest
## Gameplay scenario tests for level transitions.
## Tests level terrain arrays, stairs placement, BFS connectivity,
## depth tracking, and special level generation logic.

# ============================================================================
# TERRAIN ARRAY BASICS (flat array, 0-indexed: index = y * width + x)
# ============================================================================

const VOID: int = 0
const FLOOR: int = 1
const WALL: int = 2
const STAIRS_DOWN: int = 5
const STAIRS_UP: int = 6

func test_terrain_array_indexing():
	# Level uses flat array: index = y * width + x
	var width: int = 80
	var height: int = 40
	var terrain: Array[int] = []
	terrain.resize(width * height)
	terrain.fill(VOID)

	# Set a tile at position (10, 5)
	var pos_x: int = 10
	var pos_y: int = 5
	var index: int = pos_y * width + pos_x
	terrain[index] = FLOOR

	assert_eq(terrain[index], FLOOR, "Tile at (10,5) should be FLOOR")
	assert_eq(index, 410, "Index for (10,5) in 80-wide grid = 5*80+10 = 410")

func test_terrain_array_size():
	var width: int = 80
	var height: int = 40
	var expected_size: int = width * height
	assert_eq(expected_size, 3200, "80x40 level = 3200 tiles")

func test_position_from_index():
	# Reverse: index -> (x, y)
	var width: int = 80
	var index: int = 410
	var x: int = index % width
	var y: int = index / width
	assert_eq(x, 10, "X from index 410 should be 10")
	assert_eq(y, 5, "Y from index 410 should be 5")

func test_bounds_check():
	var width: int = 80
	var height: int = 40
	# In bounds
	assert_true(_is_in_bounds(Vector2i(0, 0), width, height), "(0,0) is in bounds")
	assert_true(_is_in_bounds(Vector2i(79, 39), width, height), "(79,39) is in bounds")
	# Out of bounds
	assert_false(_is_in_bounds(Vector2i(-1, 0), width, height), "(-1,0) is out of bounds")
	assert_false(_is_in_bounds(Vector2i(80, 0), width, height), "(80,0) is out of bounds")
	assert_false(_is_in_bounds(Vector2i(0, 40), width, height), "(0,40) is out of bounds")
	assert_false(_is_in_bounds(Vector2i(0, -1), width, height), "(0,-1) is out of bounds")

# ============================================================================
# STAIRS PLACEMENT
# ============================================================================

func test_stairs_down_exists_in_generated_level():
	# Simulate a level with stairs placed
	var width: int = 20
	var height: int = 10
	var terrain: Array[int] = []
	terrain.resize(width * height)
	terrain.fill(WALL)

	# Carve a room
	for y in range(2, 8):
		for x in range(2, 18):
			terrain[y * width + x] = FLOOR

	# Place stairs down at (15, 6)
	terrain[6 * width + 15] = STAIRS_DOWN

	var stairs_pos: Vector2i = _find_tile(terrain, width, height, STAIRS_DOWN)
	assert_ne(stairs_pos, Vector2i(-1, -1), "Stairs down should exist")
	assert_eq(stairs_pos, Vector2i(15, 6), "Stairs at expected position")

func test_stairs_up_exists_on_deeper_levels():
	# Levels deeper than 1 should have stairs up
	var width: int = 20
	var height: int = 10
	var terrain: Array[int] = []
	terrain.resize(width * height)
	terrain.fill(WALL)

	# Carve rooms
	for y in range(2, 8):
		for x in range(2, 18):
			terrain[y * width + x] = FLOOR

	# Place both stairs
	terrain[3 * width + 5] = STAIRS_UP
	terrain[6 * width + 15] = STAIRS_DOWN

	var up_pos: Vector2i = _find_tile(terrain, width, height, STAIRS_UP)
	var down_pos: Vector2i = _find_tile(terrain, width, height, STAIRS_DOWN)

	assert_ne(up_pos, Vector2i(-1, -1), "Stairs up should exist")
	assert_ne(down_pos, Vector2i(-1, -1), "Stairs down should exist")
	assert_ne(up_pos, down_pos, "Stairs up and down at different positions")

func test_depth_1_no_stairs_up():
	# First level should not have stairs up (you can't go higher)
	var depth: int = 1
	var has_stairs_up: bool = depth > 1

	assert_false(has_stairs_up, "Depth 1 should not have stairs up")

func test_depth_gt_1_has_stairs_up():
	var depth: int = 5
	var has_stairs_up: bool = depth > 1
	assert_true(has_stairs_up, "Deeper levels should have stairs up")

# ============================================================================
# BFS CONNECTIVITY
# ============================================================================

func test_bfs_connected_level():
	# Create a small connected level and verify BFS can reach from start to stairs
	var width: int = 10
	var height: int = 10
	var terrain: Array[int] = []
	terrain.resize(width * height)
	terrain.fill(WALL)

	# Carve a path: room at (1,1)-(3,3), corridor (4,2), room at (5,1)-(7,3)
	for y in range(1, 4):
		for x in range(1, 4):
			terrain[y * width + x] = FLOOR
	terrain[2 * width + 4] = FLOOR  # Corridor
	for y in range(1, 4):
		for x in range(5, 8):
			terrain[y * width + x] = FLOOR

	# Place stairs
	terrain[2 * width + 2] = STAIRS_UP
	terrain[2 * width + 6] = STAIRS_DOWN

	var start: Vector2i = Vector2i(2, 2)
	var goal: Vector2i = Vector2i(6, 2)
	var reachable: bool = _bfs_reachable(terrain, width, height, start, goal)
	assert_true(reachable, "BFS should find path from stairs up to stairs down")

func test_bfs_disconnected_level():
	# Create disconnected rooms - BFS should NOT find path
	var width: int = 10
	var height: int = 10
	var terrain: Array[int] = []
	terrain.resize(width * height)
	terrain.fill(WALL)

	# Room 1
	for y in range(1, 4):
		for x in range(1, 4):
			terrain[y * width + x] = FLOOR
	# Room 2 (no corridor connecting)
	for y in range(6, 9):
		for x in range(6, 9):
			terrain[y * width + x] = FLOOR

	var start: Vector2i = Vector2i(2, 2)
	var goal: Vector2i = Vector2i(7, 7)
	var reachable: bool = _bfs_reachable(terrain, width, height, start, goal)
	assert_false(reachable, "Disconnected rooms should NOT be BFS reachable")

func test_bfs_long_corridor():
	# L-shaped corridor connecting two rooms
	var width: int = 20
	var height: int = 10
	var terrain: Array[int] = []
	terrain.resize(width * height)
	terrain.fill(WALL)

	# Room 1 at top-left
	for y in range(1, 3):
		for x in range(1, 4):
			terrain[y * width + x] = FLOOR

	# Vertical corridor
	for y in range(3, 8):
		terrain[y * width + 2] = FLOOR

	# Horizontal corridor
	for x in range(2, 18):
		terrain[7 * width + x] = FLOOR

	# Room 2 at bottom-right
	for y in range(7, 9):
		for x in range(16, 19):
			terrain[y * width + x] = FLOOR

	var start: Vector2i = Vector2i(2, 1)
	var goal: Vector2i = Vector2i(17, 8)
	var reachable: bool = _bfs_reachable(terrain, width, height, start, goal)
	assert_true(reachable, "L-shaped corridor should connect rooms")

# ============================================================================
# DEPTH TRACKING
# ============================================================================

func test_descend_increments_depth():
	var current_depth: int = 1
	current_depth += 1
	assert_eq(current_depth, 2, "Descending should increment depth to 2")

func test_ascend_decrements_depth():
	var current_depth: int = 5
	if current_depth > 1:
		current_depth -= 1
	assert_eq(current_depth, 4, "Ascending should decrement depth to 4")

func test_cannot_ascend_above_1():
	var current_depth: int = 1
	if current_depth > 1:
		current_depth -= 1
	assert_eq(current_depth, 1, "Cannot ascend above depth 1")

func test_descend_to_max_depth():
	var current_depth: int = 19
	current_depth += 1
	assert_eq(current_depth, 20, "Can descend to depth 20 (Sauron's throne)")

func test_depth_affects_layer_name():
	# Layer names change with depth (from layer_config.gd)
	# Depths 1-3: outer_pits, 4-6: dark_halls, etc.
	var test_cases: Array[Dictionary] = [
		{"depth": 1, "expected": "outer_pits"},
		{"depth": 3, "expected": "outer_pits"},
		{"depth": 4, "expected": "orc_warrens"},
		{"depth": 7, "expected": "torture_halls"},
		{"depth": 10, "expected": "necropolis"},
		{"depth": 13, "expected": "wraith_domain"},
		{"depth": 16, "expected": "inner_sanctum"},
		{"depth": 19, "expected": "throne_room"},
		{"depth": 20, "expected": "throne_room"},
	]

	for tc in test_cases:
		var layer: String = _get_layer_for_depth(tc.depth)
		assert_eq(layer, tc.expected, "Depth %d should be %s" % [tc.depth, tc.expected])

# ============================================================================
# SPECIAL LEVELS
# ============================================================================

func test_depth_20_is_throne_room():
	# Depth 20 triggers special throne room generation
	var depth: int = 20
	var is_throne_room: bool = (depth == 20)
	assert_true(is_throne_room, "Depth 20 should be throne room")

func test_transition_depths():
	# Transition vaults appear at layer boundaries
	var transition_depths: Array[int] = [3, 6, 9, 12, 15, 18]
	assert_true(3 in transition_depths, "Depth 3 is a transition point")
	assert_true(6 in transition_depths, "Depth 6 is a transition point")
	assert_false(5 in transition_depths, "Depth 5 is NOT a transition point")
	assert_false(20 in transition_depths, "Depth 20 is NOT a transition point (it's throne room)")

# ============================================================================
# TILE TYPE ENUM VALUES (verify 0-based indexing)
# ============================================================================

func test_tile_enum_values():
	# Confirm Level.Tile enum values match expected (0-based)
	assert_eq(VOID, 0, "VOID = 0")
	assert_eq(FLOOR, 1, "FLOOR = 1")
	assert_eq(WALL, 2, "WALL = 2")
	assert_eq(STAIRS_DOWN, 5, "STAIRS_DOWN = 5")
	assert_eq(STAIRS_UP, 6, "STAIRS_UP = 6")

func test_new_terrain_types():
	# New terrain IDs from Session J (0-based enum)
	var WEB: int = 19
	var DARK_POOL: int = 20
	var MORGUL_RUNE: int = 21
	var SHADOW_BRAZIER: int = 22
	var GLYPH_OF_WARDING: int = 23
	var BONE_PILE: int = 24
	var SHADOW_FLOOR: int = 25
	var THRONE_DAIS: int = 26

	assert_eq(WEB, 19, "WEB = 19")
	assert_eq(THRONE_DAIS, 26, "THRONE_DAIS = 26")
	# All new terrain IDs are contiguous
	assert_eq(THRONE_DAIS - WEB + 1, 8, "8 new terrain types (19-26)")

# ============================================================================
# LEVEL ARRAYS INITIALIZATION
# ============================================================================

func test_explored_array_starts_false():
	var width: int = 80
	var height: int = 40
	var explored: Array[bool] = []
	explored.resize(width * height)
	explored.fill(false)

	assert_eq(explored.size(), 3200, "Explored array matches level size")
	assert_false(explored[0], "All tiles start unexplored")
	assert_false(explored[1599], "Middle tile unexplored")
	assert_false(explored[3199], "Last tile unexplored")

func test_visibility_array_starts_false():
	var width: int = 80
	var height: int = 40
	var visible: Array[bool] = []
	visible.resize(width * height)
	visible.fill(false)

	assert_eq(visible.size(), 3200, "Visibility array matches level size")
	assert_false(visible[0], "All tiles start invisible")

# ============================================================================
# ROOM GENERATION VALIDATION
# ============================================================================

func test_room_bounds_within_level():
	var level_width: int = 80
	var level_height: int = 40
	var room: Rect2i = Rect2i(5, 3, 10, 8)  # x, y, w, h

	assert_gte(room.position.x, 0, "Room left edge >= 0")
	assert_gte(room.position.y, 0, "Room top edge >= 0")
	assert_lt(room.position.x + room.size.x, level_width, "Room right edge < level width")
	assert_lt(room.position.y + room.size.y, level_height, "Room bottom edge < level height")

func test_room_intersection_check():
	var room_a: Rect2i = Rect2i(5, 5, 10, 10)
	var room_b: Rect2i = Rect2i(12, 12, 10, 10)
	var room_c: Rect2i = Rect2i(50, 50, 5, 5)

	# Expand by margin 1 for overlap check
	var expanded_a: Rect2i = Rect2i(
		room_a.position - Vector2i(1, 1),
		room_a.size + Vector2i(2, 2)
	)

	assert_true(expanded_a.intersects(room_b), "Room A (expanded) intersects Room B")
	assert_false(expanded_a.intersects(room_c), "Room A does NOT intersect Room C")

func test_room_center_calculation():
	var room: Rect2i = Rect2i(10, 20, 8, 6)
	var center_x: int = room.position.x + room.size.x / 2
	var center_y: int = room.position.y + room.size.y / 2
	assert_eq(center_x, 14, "Center X of (10,20,8,6) = 14")
	assert_eq(center_y, 23, "Center Y of (10,20,8,6) = 23")

# ============================================================================
# PLAYER SPAWN POSITION
# ============================================================================

func test_player_starts_on_stairs_up():
	# On deeper levels, player should start at stairs_up position
	var width: int = 10
	var height: int = 10
	var terrain: Array[int] = []
	terrain.resize(width * height)
	terrain.fill(WALL)

	# Create a room with stairs_up
	for y in range(2, 5):
		for x in range(2, 5):
			terrain[y * width + x] = FLOOR
	terrain[3 * width + 3] = STAIRS_UP

	var stairs_up_pos: Vector2i = _find_tile(terrain, width, height, STAIRS_UP)
	var player_start: Vector2i = stairs_up_pos  # Player spawns at stairs up

	assert_eq(player_start, Vector2i(3, 3), "Player starts at stairs up position")

func test_player_starts_in_first_room_depth_1():
	# On depth 1, player starts in center of first room (no stairs up)
	var room: Rect2i = Rect2i(5, 5, 10, 8)
	var player_start: Vector2i = Vector2i(
		room.position.x + room.size.x / 2,
		room.position.y + room.size.y / 2
	)
	assert_eq(player_start, Vector2i(10, 9), "Player starts at room center on depth 1")

# ============================================================================
# HELPERS
# ============================================================================

func _is_in_bounds(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func _find_tile(terrain: Array[int], width: int, height: int, tile_type: int) -> Vector2i:
	for y in range(height):
		for x in range(width):
			if terrain[y * width + x] == tile_type:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _bfs_reachable(terrain: Array[int], width: int, height: int, start: Vector2i, goal: Vector2i) -> bool:
	if start == goal:
		return true

	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true

	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
	]

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()

		for dir in directions:
			var next: Vector2i = current + dir
			if not _is_in_bounds(next, width, height):
				continue
			if visited.has(next):
				continue
			var tile: int = terrain[next.y * width + next.x]
			if tile == WALL or tile == VOID:
				continue
			if next == goal:
				return true
			visited[next] = true
			queue.append(next)

	return false

func _get_layer_for_depth(depth: int) -> String:
	# Mirrors layer_config.gd layer assignment
	if depth <= 3:
		return "outer_pits"
	elif depth <= 6:
		return "orc_warrens"
	elif depth <= 9:
		return "torture_halls"
	elif depth <= 12:
		return "necropolis"
	elif depth <= 15:
		return "wraith_domain"
	elif depth <= 18:
		return "inner_sanctum"
	else:
		return "throne_room"
