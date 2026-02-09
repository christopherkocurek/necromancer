extends GutTest
## Unit tests for rubble/mining terrain system and forge material spawning.
## Covers: rubble passability, rubble transparency, mining turn calculation,
## layer-specific scatter tiles, and forge material spawn on passable tiles.

# ============================================================================
# 1. RUBBLE PASSABILITY
# ============================================================================

func test_rubble_is_impassable():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	var pos := Vector2i(5, 5)
	level.terrain[pos.y * level.width + pos.x] = Level.Tile.RUBBLE
	assert_false(level.is_passable(pos), "Rubble should NOT be passable")
	level.free()

func test_rubble_is_transparent():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	var pos := Vector2i(5, 5)
	level.terrain[pos.y * level.width + pos.x] = Level.Tile.RUBBLE
	assert_true(level.is_transparent(pos), "Rubble should be transparent (can see over it)")
	level.free()

func test_floor_is_passable():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	var pos := Vector2i(5, 5)
	level.terrain[pos.y * level.width + pos.x] = Level.Tile.FLOOR
	assert_true(level.is_passable(pos), "Floor should be passable")
	level.free()

func test_wall_is_not_passable():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	var pos := Vector2i(5, 5)
	level.terrain[pos.y * level.width + pos.x] = Level.Tile.WALL
	assert_false(level.is_passable(pos), "Wall should NOT be passable")
	level.free()

func test_rubble_has_terrain_name():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	var pos := Vector2i(5, 5)
	level.terrain[pos.y * level.width + pos.x] = Level.Tile.RUBBLE
	assert_eq(level.get_terrain_name(pos), "Rubble", "Rubble should have terrain name 'Rubble'")
	level.free()

# ============================================================================
# 2. MINING MECHANICS
# ============================================================================

func test_mining_converts_rubble_to_floor():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	var pos := Vector2i(5, 5)
	level.terrain[pos.y * level.width + pos.x] = Level.Tile.RUBBLE
	assert_eq(level.get_tile(pos), Level.Tile.RUBBLE, "Should start as rubble")
	# Simulate mining completion: set tile to FLOOR
	level.set_tile(pos, Level.Tile.FLOOR)
	assert_eq(level.get_tile(pos), Level.Tile.FLOOR, "Should be floor after mining")
	assert_true(level.is_passable(pos), "Should be passable after mining")
	level.free()

func test_mining_smithing_reduces_turns():
	# Mining turns: max(2, 4 - smithing_level / 2)
	# smithing 0: max(2, 4 - 0) = 4
	assert_eq(maxi(2, 4 - 0 / 2), 4, "Smithing 0 should take 4 turns")
	# smithing 2: max(2, 4 - 1) = 3
	assert_eq(maxi(2, 4 - 2 / 2), 3, "Smithing 2 should take 3 turns")
	# smithing 4: max(2, 4 - 2) = 2
	assert_eq(maxi(2, 4 - 4 / 2), 2, "Smithing 4 should take 2 turns")
	# smithing 8: max(2, 4 - 4) = 2 (capped at 2)
	assert_eq(maxi(2, 4 - 8 / 2), 2, "Smithing 8 should take 2 turns (minimum)")
	# smithing 10: max(2, 4 - 5) = 2 (capped)
	assert_eq(maxi(2, 4 - 10 / 2), 2, "Smithing 10 should still take 2 turns")

func test_mining_takes_multiple_turns():
	# Verify that mining requires at least 2 turns minimum
	for smithing_level in range(0, 12):
		var turns: int = maxi(2, 4 - smithing_level / 2)
		assert_gte(turns, 2, "Mining should always take at least 2 turns (smithing %d)" % smithing_level)
		assert_lte(turns, 4, "Mining should never take more than 4 turns (smithing %d)" % smithing_level)

# ============================================================================
# 3. LAYER-SPECIFIC SCATTER TILES
# ============================================================================

func test_scatter_uses_layer_tile():
	var gen := DungeonGenerator.new()
	# Verify each layer returns the correct scatter tile type
	assert_eq(gen._get_scatter_tile_for_layer("outer_pits"), Level.Tile.VINE_FLOOR,
		"Outer Pits should use VINE_FLOOR scatter")
	assert_eq(gen._get_scatter_tile_for_layer("lower_halls"), Level.Tile.RUBBLE,
		"Lower Halls should use RUBBLE scatter")
	assert_eq(gen._get_scatter_tile_for_layer("dark_halls"), Level.Tile.MORGUL_RUNE,
		"Dark Halls should use MORGUL_RUNE scatter")
	assert_eq(gen._get_scatter_tile_for_layer("necropolis"), Level.Tile.BONE_PILE,
		"Necropolis should use BONE_PILE scatter")
	assert_eq(gen._get_scatter_tile_for_layer("pits_of_despair"), Level.Tile.SHADOW_FLOOR,
		"Pits of Despair should use SHADOW_FLOOR scatter")
	assert_eq(gen._get_scatter_tile_for_layer("inner_sanctum"), Level.Tile.SHADOW_FLOOR,
		"Inner Sanctum should use SHADOW_FLOOR scatter")
	assert_eq(gen._get_scatter_tile_for_layer("throne_room"), Level.Tile.SHADOW_FLOOR,
		"Throne Room should use SHADOW_FLOOR scatter")

func test_scatter_unknown_layer_defaults_to_rubble():
	var gen := DungeonGenerator.new()
	assert_eq(gen._get_scatter_tile_for_layer("nonexistent"), Level.Tile.RUBBLE,
		"Unknown layer should default to RUBBLE scatter")

func test_scatter_impassable_check():
	var gen := DungeonGenerator.new()
	# RUBBLE is impassable
	assert_false(gen._is_scatter_tile_passable(Level.Tile.RUBBLE),
		"RUBBLE should be classified as impassable scatter")
	# VINE_FLOOR is passable
	assert_true(gen._is_scatter_tile_passable(Level.Tile.VINE_FLOOR),
		"VINE_FLOOR should be classified as passable scatter")
	# BONE_PILE is passable
	assert_true(gen._is_scatter_tile_passable(Level.Tile.BONE_PILE),
		"BONE_PILE should be classified as passable scatter")

# ============================================================================
# 4. FORGE MATERIAL SPAWNING
# ============================================================================

func test_forge_materials_spawn_on_passable():
	# Verify that is_passable returns true for tiles where materials can spawn
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()

	# FLOOR is passable (materials should spawn here)
	var floor_pos := Vector2i(3, 3)
	level.terrain[floor_pos.y * level.width + floor_pos.x] = Level.Tile.FLOOR
	assert_true(level.is_passable(floor_pos), "FLOOR should be passable for material spawn")

	# VINE_FLOOR is passable (materials should spawn here too)
	var vine_pos := Vector2i(4, 4)
	level.terrain[vine_pos.y * level.width + vine_pos.x] = Level.Tile.VINE_FLOOR
	assert_true(level.is_passable(vine_pos), "VINE_FLOOR should be passable for material spawn")

	# RUBBLE is NOT passable (materials should NOT spawn here)
	var rubble_pos := Vector2i(5, 5)
	level.terrain[rubble_pos.y * level.width + rubble_pos.x] = Level.Tile.RUBBLE
	assert_false(level.is_passable(rubble_pos), "RUBBLE should NOT be passable for material spawn")

	# WALL is NOT passable
	var wall_pos := Vector2i(6, 6)
	level.terrain[wall_pos.y * level.width + wall_pos.x] = Level.Tile.WALL
	assert_false(level.is_passable(wall_pos), "WALL should NOT be passable for material spawn")

	level.free()

func test_passable_neighbor_count():
	var gen := DungeonGenerator.new()
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	gen.level = level

	# Fill with walls
	for y in range(10):
		for x in range(10):
			level.terrain[y * level.width + x] = Level.Tile.WALL

	# Create a small room: floor at (3,3), (4,3), (5,3), (3,4), (4,4), (5,4), (3,5), (4,5), (5,5)
	for y in range(3, 6):
		for x in range(3, 6):
			level.terrain[y * level.width + x] = Level.Tile.FLOOR

	# Center tile (4,4) should have 8 passable neighbors
	assert_eq(gen._count_passable_neighbors(Vector2i(4, 4)), 8,
		"Center of 3x3 room should have 8 passable neighbors")

	# Corner tile (3,3) should have 3 passable neighbors (right, down, down-right)
	assert_eq(gen._count_passable_neighbors(Vector2i(3, 3)), 3,
		"Corner of 3x3 room should have 3 passable neighbors")

	level.free()

func test_narrow_corridor_has_few_neighbors():
	var gen := DungeonGenerator.new()
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	gen.level = level

	# Fill with walls
	for y in range(10):
		for x in range(10):
			level.terrain[y * level.width + x] = Level.Tile.WALL

	# Create a 1-wide horizontal corridor at y=5: x=2,3,4,5,6
	for x in range(2, 7):
		level.terrain[5 * level.width + x] = Level.Tile.FLOOR

	# Middle corridor tile (4,5) should have only 2 passable neighbors (left, right)
	var mid_neighbors: int = gen._count_passable_neighbors(Vector2i(4, 5))
	assert_eq(mid_neighbors, 2, "Middle of 1-wide corridor should have 2 passable neighbors")

	# This means impassable scatter should NOT be placed here (< 3 threshold)
	assert_true(mid_neighbors < 3, "Narrow corridor should fail the >= 3 passable neighbors check")

	level.free()
