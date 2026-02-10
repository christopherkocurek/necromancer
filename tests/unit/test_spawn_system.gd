extends GutTest
## Tests for the Monster Spawn System Rewrite (Streams A-F).

# ============================================================================
# STREAM A: Data Layer Foundation
# ============================================================================

func test_rarity_weighting_prefers_common_monsters():
	# Spawn 1000 monsters at depth 5, verify rarity-1 appear more than rarity-3
	var counts: Dictionary = {}  # name -> count
	for _i in range(1000):
		var m: DataManager.MonsterData = DataManager.get_random_monster_for_depth(5)
		if m:
			counts[m.name] = counts.get(m.name, 0) + 1

	# Find a rarity-1 and rarity-3+ monster to compare
	var low_rarity_total: int = 0
	var high_rarity_total: int = 0
	for m in DataManager.monsters.values():
		if m.depth <= 5 and m.depth >= 2:
			var count: int = counts.get(m.name, 0)
			if m.rarity <= 1:
				low_rarity_total += count
			elif m.rarity >= 3:
				high_rarity_total += count

	# Low rarity monsters should appear significantly more often
	assert_gt(low_rarity_total, high_rarity_total, "Rarity-1 monsters should appear more than rarity-3+")

func test_ood_depth_stays_in_range():
	# get_effective_monster_depth(10) x1000: OOD stays in [10,15], never >15
	for _i in range(1000):
		var effective: int = DataManager.get_effective_monster_depth(10)
		assert_gte(effective, 10, "OOD depth should be >= base depth")
		assert_lte(effective, 15, "OOD depth should be <= base + 5")

func test_ood_never_exceeds_20():
	for _i in range(1000):
		var effective: int = DataManager.get_effective_monster_depth(19)
		assert_lte(effective, 20, "OOD depth should never exceed 20")

func test_ood_sometimes_increases_depth():
	# With 12% chance, some should be higher
	var increased: int = 0
	for _i in range(1000):
		var effective: int = DataManager.get_effective_monster_depth(10)
		if effective > 10:
			increased += 1
	# Expect ~120, allow wide range
	assert_gt(increased, 30, "OOD should sometimes increase depth")
	assert_lt(increased, 300, "OOD should not always increase depth")

func test_unique_population_cap():
	DataManager.reset_spawned_uniques()
	assert_false(DataManager.is_unique_already_spawned("Gorgol"), "Should not be spawned yet")
	DataManager.mark_unique_spawned("Gorgol")
	assert_true(DataManager.is_unique_already_spawned("Gorgol"), "Should be marked as spawned")
	DataManager.reset_spawned_uniques()
	assert_false(DataManager.is_unique_already_spawned("Gorgol"), "Should be cleared after reset")

func test_exclude_uniques_parameter():
	# Spawn many monsters with exclude_uniques=true, none should be unique
	for _i in range(200):
		var m: DataManager.MonsterData = DataManager.get_random_monster_for_depth(15, true)
		if m:
			assert_false(m.has_flag("UNIQUE"), "Should not get unique with exclude_uniques=true: %s" % m.name)

# ============================================================================
# STREAM B: Spatial Distribution Core
# ============================================================================

func test_level_count_passable_tiles():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	# All VOID by default
	assert_eq(level.count_passable_tiles(), 0, "All void = 0 passable")
	# Set some floor tiles
	level.terrain[11] = Level.Tile.FLOOR  # (1,1)
	level.terrain[12] = Level.Tile.FLOOR  # (2,1)
	level.terrain[13] = Level.Tile.STAIRS_DOWN
	assert_eq(level.count_passable_tiles(), 3, "3 passable tiles")
	level.free()

func test_level_find_random_floor_in_room():
	var level := Level.new()
	level.width = 20
	level.height = 20
	level._initialize_arrays()
	# Create a 5x5 room at (5,5)
	for y in range(5, 10):
		for x in range(5, 10):
			level.terrain[y * 20 + x] = Level.Tile.FLOOR
	var room := Rect2i(5, 5, 5, 5)
	var pos: Vector2i = level.find_random_floor_in_room(room)
	assert_ne(pos, Vector2i(-1, -1), "Should find a floor tile")
	assert_gte(pos.x, 5, "X should be in room")
	assert_lt(pos.x, 10, "X should be in room")
	assert_gte(pos.y, 5, "Y should be in room")
	assert_lt(pos.y, 10, "Y should be in room")
	level.free()

func test_level_find_random_corridor_floor():
	var level := Level.new()
	level.width = 20
	level.height = 20
	level._initialize_arrays()
	# Create corridor tile (room_id == -1) at (3,3)
	level.terrain[3 * 20 + 3] = Level.Tile.FLOOR
	level.room_id[3 * 20 + 3] = -1
	# Create room tile at (10,10)
	level.terrain[10 * 20 + 10] = Level.Tile.FLOOR
	level.room_id[10 * 20 + 10] = 0
	var found: bool = false
	for _attempt in range(200):
		var pos: Vector2i = level.find_random_corridor_floor()
		if pos != Vector2i(-1, -1):
			var idx: int = pos.y * 20 + pos.x
			assert_eq(level.room_id[idx], -1, "Found tile should be in corridor")
			found = true
			break
	assert_true(found, "Should eventually find the corridor floor tile")
	level.free()

func test_friends_pack_size_by_type():
	# Test that different monster types get different pack sizes
	var gen := DungeonGenerator.new()
	var orc_data := DataManager.MonsterData.new()
	orc_data.display_char = "o"
	var rat_data := DataManager.MonsterData.new()
	rat_data.display_char = "r"
	var shadow_data := DataManager.MonsterData.new()
	shadow_data.display_char = "G"

	# Test ranges over multiple calls
	var orc_sizes: Array[int] = []
	var rat_sizes: Array[int] = []
	for _i in range(50):
		orc_sizes.append(gen._get_friends_pack_size(orc_data))
		rat_sizes.append(gen._get_friends_pack_size(rat_data))

	# Orc packs should be 2-3
	for s: int in orc_sizes:
		assert_gte(s, 2, "Orc pack >= 2")
		assert_lte(s, 3, "Orc pack <= 3")

	# Rat packs should be 2-4
	for s: int in rat_sizes:
		assert_gte(s, 2, "Rat pack >= 2")
		assert_lte(s, 4, "Rat pack <= 4")

# ============================================================================
# STREAM C: Vault and Forge Improvements
# ============================================================================

func test_vault_depth_bonus_constants():
	assert_eq(Constants.VAULT_DEPTH_BONUS_LESSER, 1, "Lesser vault bonus = 1")
	assert_eq(Constants.VAULT_DEPTH_BONUS_GREATER, 3, "Greater vault bonus = 3")
	assert_eq(Constants.VAULT_DEPTH_BONUS_INTERESTING, 2, "Interesting vault bonus = 2")

# ============================================================================
# STREAM D: Alertness and Location Modifiers
# ============================================================================

func test_alertness_constants():
	assert_eq(Constants.ALERTNESS_CORRIDOR_BONUS, 5, "Corridor bonus = 5")
	assert_eq(Constants.ALERTNESS_BACK_ROOM_PENALTY, -5, "Back room penalty = -5")
	assert_eq(Constants.ALERTNESS_STAIRS_RADIUS, 3, "Stairs radius = 3")

# ============================================================================
# STREAM E: Periodic Spawning and Encounter Types
# ============================================================================

func test_periodic_spawn_constants():
	assert_eq(Constants.PERIODIC_SPAWN_INTERVAL, 150, "Periodic interval = 150")
	assert_eq(Constants.PERIODIC_SPAWN_MAX_MONSTERS, 40, "Max monsters = 40")
	assert_eq(Constants.PERIODIC_SPAWN_MIN_PLAYER_DIST, 8, "Min player dist = 8")

func test_encounter_type_enum():
	assert_eq(Constants.EncounterType.WANDERER, 0)
	assert_eq(Constants.EncounterType.PATROL, 1)
	assert_eq(Constants.EncounterType.NEST, 2)
	assert_eq(Constants.EncounterType.AMBUSH, 3)
	assert_eq(Constants.EncounterType.GUARDIAN, 4)
	assert_eq(Constants.EncounterType.WARDEN, 5)
	assert_eq(Constants.EncounterType.HUNTER, 6)

func test_monster_encounter_type_default():
	var monster := Monster.new()
	assert_eq(monster.encounter_type, Constants.EncounterType.WANDERER, "Default encounter type should be WANDERER")
	monster.free()

# ============================================================================
# STREAM F: Polish — Lairs, Ascent, Transitions
# ============================================================================

func test_ascent_constants():
	assert_eq(Constants.ASCENT_MONSTER_DEPTH_BONUS, 5, "Ascent depth bonus = 5")
	assert_eq(Constants.ASCENT_SPAWN_MULTIPLIER, 2.0, "Ascent spawn multiplier = 2x")
	assert_eq(Constants.UNIQUE_LAIR_CHANCE, 0.15, "Lair chance = 15%")
	assert_eq(Constants.UNIQUE_LAIR_MIN_DEPTH, 6, "Lair min depth = 6")
	assert_eq(Constants.UNIQUE_LAIR_MIN_ROOM_SIZE, 6, "Lair min room size = 6")

func test_layer_boundary_detection():
	# Depths 1-3 are outer_pits, 4-6 are lower_halls
	assert_false(LayerConfig.is_layer_boundary(1), "Depth 1 is not a boundary")
	assert_false(LayerConfig.is_layer_boundary(2), "Depth 2 is not a boundary")
	assert_false(LayerConfig.is_layer_boundary(3), "Depth 3 is not a boundary")
	assert_true(LayerConfig.is_layer_boundary(4), "Depth 4 IS a boundary (outer_pits -> lower_halls)")
	assert_false(LayerConfig.is_layer_boundary(5), "Depth 5 is not a boundary")
	assert_true(LayerConfig.is_layer_boundary(7), "Depth 7 IS a boundary (lower_halls -> dark_halls)")
	assert_true(LayerConfig.is_layer_boundary(10), "Depth 10 IS a boundary (dark_halls -> necropolis)")
	assert_true(LayerConfig.is_layer_boundary(13), "Depth 13 IS a boundary")
	assert_true(LayerConfig.is_layer_boundary(16), "Depth 16 IS a boundary")
	assert_true(LayerConfig.is_layer_boundary(19), "Depth 19 IS a boundary")

func test_level_is_ascent_default():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._initialize_arrays()
	assert_false(level.is_ascent, "Default is_ascent should be false")
	level.free()

func test_weighted_pick_monster_returns_valid():
	# Just verify the function doesn't crash and returns a valid monster
	var candidates: Array[DataManager.MonsterData] = []
	for m in DataManager.monsters.values():
		if m.depth <= 5:
			candidates.append(m)
		if candidates.size() >= 10:
			break
	if candidates.size() > 0:
		var picked: DataManager.MonsterData = DataManager._weighted_pick_monster(candidates)
		assert_not_null(picked, "Should return a monster")
		assert_true(picked in candidates, "Should return one of the candidates")

func test_weighted_pick_monster_empty():
	var empty: Array[DataManager.MonsterData] = []
	var result: DataManager.MonsterData = DataManager._weighted_pick_monster(empty)
	assert_null(result, "Empty candidates should return null")

func test_weighted_pick_monster_single():
	var single: Array[DataManager.MonsterData] = []
	for m in DataManager.monsters.values():
		single.append(m)
		break
	if single.size() == 1:
		var result: DataManager.MonsterData = DataManager._weighted_pick_monster(single)
		assert_eq(result, single[0], "Single candidate should return that candidate")
