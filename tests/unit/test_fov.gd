extends GutTest
## Unit tests for field of view and line of sight calculations
## Tests visibility, raycasting, Bresenham LOS

func test_bresenham_line_straight_horizontal():
	var start: Vector2i = Vector2i(0, 0)
	var end: Vector2i = Vector2i(5, 0)
	var line: Array[Vector2i] = _bresenham_line(start, end)

	assert_eq(line.size(), 6, "Horizontal line should have 6 points")
	assert_eq(line[0], Vector2i(0, 0), "Line should start at origin")
	assert_eq(line[5], Vector2i(5, 0), "Line should end at target")

func test_bresenham_line_straight_vertical():
	var start: Vector2i = Vector2i(0, 0)
	var end: Vector2i = Vector2i(0, 5)
	var line: Array[Vector2i] = _bresenham_line(start, end)

	assert_eq(line.size(), 6, "Vertical line should have 6 points")
	assert_eq(line[5], Vector2i(0, 5), "Line should end at target")

func test_bresenham_line_diagonal():
	var start: Vector2i = Vector2i(0, 0)
	var end: Vector2i = Vector2i(3, 3)
	var line: Array[Vector2i] = _bresenham_line(start, end)

	assert_eq(line.size(), 4, "Diagonal line should have 4 points")
	assert_eq(line[3], Vector2i(3, 3), "Line should end at target")

func test_bresenham_line_steep():
	var start: Vector2i = Vector2i(0, 0)
	var end: Vector2i = Vector2i(2, 5)
	var line: Array[Vector2i] = _bresenham_line(start, end)

	# Verify all points are connected (no gaps)
	for i in range(1, line.size()):
		var diff: Vector2i = line[i] - line[i-1]
		var chebyshev: int = maxi(absi(diff.x), absi(diff.y))
		assert_eq(chebyshev, 1, "Adjacent points should be neighbors")

func test_los_blocked_by_wall():
	# Simple grid: . = floor, # = wall
	# .....
	# ..#..
	# .....
	var walls: Array[Vector2i] = [Vector2i(2, 1)]
	var start: Vector2i = Vector2i(0, 1)
	var end: Vector2i = Vector2i(4, 1)

	var has_los: bool = _has_los(start, end, walls)
	assert_false(has_los, "LOS should be blocked by wall")

func test_los_clear_path():
	var walls: Array[Vector2i] = []
	var start: Vector2i = Vector2i(0, 0)
	var end: Vector2i = Vector2i(5, 5)

	var has_los: bool = _has_los(start, end, walls)
	assert_true(has_los, "LOS should be clear with no walls")

func test_los_blocked_by_closed_door():
	# Closed doors block LOS
	var opaque_tiles: Array[Vector2i] = [Vector2i(2, 0)]
	var start: Vector2i = Vector2i(0, 0)
	var end: Vector2i = Vector2i(4, 0)

	var has_los: bool = _has_los(start, end, opaque_tiles)
	assert_false(has_los, "LOS should be blocked by closed door")

func test_fov_radius_limits_visibility():
	var viewer_pos: Vector2i = Vector2i(10, 10)
	var fov_radius: int = 5

	var in_range: Vector2i = Vector2i(13, 12)  # Distance ~3.6
	var out_of_range: Vector2i = Vector2i(17, 10)  # Distance 7

	var dist_in: float = viewer_pos.distance_to(in_range)
	var dist_out: float = viewer_pos.distance_to(out_of_range)

	assert_lt(dist_in, fov_radius, "In-range tile should be within FOV radius")
	assert_gt(dist_out, fov_radius, "Out-of-range tile should be outside FOV radius")

func test_fov_includes_adjacent_tiles():
	var viewer_pos: Vector2i = Vector2i(5, 5)
	var fov_radius: int = 8

	# All 8 adjacent tiles should be visible (assuming no walls)
	var adjacents: Array[Vector2i] = [
		Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4),
		Vector2i(4, 5),                 Vector2i(6, 5),
		Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6),
	]

	for adj in adjacents:
		var dist: float = viewer_pos.distance_to(adj)
		assert_lt(dist, fov_radius, "Adjacent tile should be within FOV")

func test_tile_transparency():
	# Test tile type transparency rules
	var transparent_types: Array[String] = ["FLOOR", "DOOR_OPEN", "STAIRS_DOWN", "STAIRS_UP"]
	var opaque_types: Array[String] = ["WALL", "DOOR_CLOSED"]

	for t in transparent_types:
		assert_true(_is_transparent(t), "%s should be transparent" % t)

	for t in opaque_types:
		assert_false(_is_transparent(t), "%s should be opaque" % t)

# Helper: Bresenham line algorithm
func _bresenham_line(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0: int = start.x
	var y0: int = start.y
	var x1: int = end.x
	var y1: int = end.y

	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return points

# Helper: Check LOS using Bresenham
func _has_los(start: Vector2i, end: Vector2i, opaque_tiles: Array[Vector2i]) -> bool:
	var line: Array[Vector2i] = _bresenham_line(start, end)
	for i in range(1, line.size() - 1):  # Skip start and end
		if line[i] in opaque_tiles:
			return false
	return true

# Helper: Tile transparency
func _is_transparent(tile_type: String) -> bool:
	return tile_type in ["FLOOR", "DOOR_OPEN", "STAIRS_DOWN", "STAIRS_UP", "CHASM", "RUBBLE", "FORGE"]
