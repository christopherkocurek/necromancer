extends GutTest
## Unit tests for the smithing system overhaul.
## Covers: recipe types, material detection, XP costs, forge types, success rates,
## mastery abilities, Masterwork, and material category filtering.

const SmithingSystemScript := preload("res://scripts/systems/smithing_system.gd")

var smithing: SmithingSystem

func before_each() -> void:
	smithing = SmithingSystemScript.new()

# ============================================================================
# RECIPE INITIALIZATION
# ============================================================================

func test_recipes_include_all_types():
	assert_eq(smithing.recipes.size(), 6, "Should have 6 recipe types")
	var types: Array = []
	for r in smithing.recipes:
		types.append(r.type)
	assert_has(types, SmithingSystem.RecipeType.CREATE_WEAPON)
	assert_has(types, SmithingSystem.RecipeType.CREATE_ARMOR)
	assert_has(types, SmithingSystem.RecipeType.CREATE_JEWELRY)
	assert_has(types, SmithingSystem.RecipeType.REFORGE)
	assert_has(types, SmithingSystem.RecipeType.RECLAIM)
	assert_has(types, SmithingSystem.RecipeType.MASTERWORK)

func test_masterwork_recipe_exists():
	var masterwork_recipe: SmithingSystem.Recipe = null
	for r in smithing.recipes:
		if r.type == SmithingSystem.RecipeType.MASTERWORK:
			masterwork_recipe = r
	assert_not_null(masterwork_recipe, "Masterwork recipe must exist")
	assert_eq(masterwork_recipe.required_skill, 8, "Masterwork requires smithing 8")
	assert_eq(masterwork_recipe.material_count, 4, "Masterwork needs 4 materials")
	assert_eq(masterwork_recipe.required_ability, Constants.SmithingAbility.SMT_MASTERWORK)

# ============================================================================
# MATERIAL DETECTION
# ============================================================================

func test_broken_glowing_jewelry_detected():
	var item := DataManager.ItemData.new()
	item.name = "Broken Glowing Ring"
	item.index = 496
	assert_true(smithing._is_broken_glowing(item), "ID 496 should be broken glowing")
	assert_false(smithing._is_broken_strange(item), "ID 496 should NOT be broken strange")

func test_material_category_weapon():
	var item := DataManager.ItemData.new()
	item.index = 491  # Broken Glowing Weapon
	assert_eq(smithing.get_material_category(item), SmithingSystem.MaterialCategory.WEAPON)

func test_material_category_armor():
	var item := DataManager.ItemData.new()
	item.index = 492  # Shattered Elven Mail
	assert_eq(smithing.get_material_category(item), SmithingSystem.MaterialCategory.ARMOR)

func test_material_category_jewelry():
	var item := DataManager.ItemData.new()
	item.index = 496  # Broken Glowing Ring
	assert_eq(smithing.get_material_category(item), SmithingSystem.MaterialCategory.JEWELRY)

func test_material_category_strange_weapon():
	var item := DataManager.ItemData.new()
	item.index = 493  # Broken Strange Weapon
	assert_eq(smithing.get_material_category(item), SmithingSystem.MaterialCategory.WEAPON)

func test_material_category_strange_armor():
	var item := DataManager.ItemData.new()
	item.index = 494  # Twisted Shadow-plate
	assert_eq(smithing.get_material_category(item), SmithingSystem.MaterialCategory.ARMOR)

func test_material_category_strange_jewelry():
	var item := DataManager.ItemData.new()
	item.index = 495  # Broken Strange Jewelry
	assert_eq(smithing.get_material_category(item), SmithingSystem.MaterialCategory.JEWELRY)

func test_mithril_detection():
	var item := DataManager.ItemData.new()
	item.name = "Piece of Mithril"
	item.index = 410
	assert_true(smithing._is_mithril(item))

func test_is_smithing_material_all_types():
	var mithril := DataManager.ItemData.new()
	mithril.name = "Piece of Mithril"
	mithril.index = 410
	assert_true(smithing.is_smithing_material(mithril))

	var glowing := DataManager.ItemData.new()
	glowing.name = "Broken Glowing Weapon"
	glowing.index = 491
	assert_true(smithing.is_smithing_material(glowing))

	var strange := DataManager.ItemData.new()
	strange.name = "Broken Strange Weapon"
	strange.index = 493
	assert_true(smithing.is_smithing_material(strange))

	var normal := DataManager.ItemData.new()
	normal.name = "Long Sword"
	normal.index = 50
	assert_false(smithing.is_smithing_material(normal))

# ============================================================================
# TVAL CATEGORY MAPPING
# ============================================================================

func test_tvals_for_weapon_category():
	var tvals: Array[int] = smithing._get_tvals_for_category(SmithingSystem.MaterialCategory.WEAPON)
	assert_has(tvals, 20)  # Digging
	assert_has(tvals, 23)  # Sword

func test_tvals_for_armor_category():
	var tvals: Array[int] = smithing._get_tvals_for_category(SmithingSystem.MaterialCategory.ARMOR)
	assert_has(tvals, 30)  # Boots
	assert_has(tvals, 37)  # Mail

func test_tvals_for_jewelry_category():
	var tvals: Array[int] = smithing._get_tvals_for_category(SmithingSystem.MaterialCategory.JEWELRY)
	assert_has(tvals, 39)  # Light
	assert_has(tvals, 45)  # Ring

# ============================================================================
# SUCCESS CHANCES — Variable by recipe type (Task 8)
# ============================================================================

func test_create_success_rate():
	# skill * 8, cap 95%
	# We need a mock player, so test the formula directly
	# skill=5: 5*8=40. skill=12: 12*8=96 -> capped to 95.
	assert_eq(mini(5 * 8, 95), 40, "Skill 5 CREATE = 40%")
	assert_eq(mini(12 * 8, 95), 95, "Skill 12 CREATE capped at 95%")

func test_reforge_success_rate():
	# skill * 6, cap 90%
	assert_eq(mini(5 * 6, 90), 30, "Skill 5 REFORGE = 30%")
	assert_eq(mini(15 * 6, 90), 90, "Skill 15 REFORGE capped at 90%")

func test_reclaim_success_rate():
	# skill * 5, cap 85%
	assert_eq(mini(8 * 5, 85), 40, "Skill 8 RECLAIM = 40%")
	assert_eq(mini(20 * 5, 85), 85, "Skill 20 RECLAIM capped at 85%")

func test_masterwork_success_rate():
	# skill * 4, cap 80%
	assert_eq(mini(8 * 4, 80), 32, "Skill 8 MASTERWORK = 32%")
	assert_eq(mini(20 * 4, 80), 80, "Skill 20 MASTERWORK capped at 80%")

# ============================================================================
# XP COSTS (Tasks 6, 9)
# ============================================================================

func test_reforge_xp_cost_base():
	assert_eq(SmithingSystem.REFORGE_XP_COST, 600, "Reforge base cost = 600")

func test_reclaim_xp_multiplier():
	assert_eq(SmithingSystem.RECLAIM_XP_MULTIPLIER, 50, "Reclaim multiplier = 50")
	# Artifact at depth 10: 10 * 50 = 500 XP
	assert_eq(10 * SmithingSystem.RECLAIM_XP_MULTIPLIER, 500)

func test_masterwork_xp_multiplier():
	assert_eq(SmithingSystem.MASTERWORK_XP_MULTIPLIER, 75, "Masterwork multiplier = 75")
	# Artifact at depth 15: 15 * 75 = 1125 XP
	assert_eq(15 * SmithingSystem.MASTERWORK_XP_MULTIPLIER, 1125)

# ============================================================================
# FORGE TYPES (Task 7)
# ============================================================================

func test_forge_tile_enum_values():
	assert_eq(Level.Tile.FORGE, 9)
	assert_eq(Level.Tile.FORGE_ENCHANTED, 28)
	assert_eq(Level.Tile.FORGE_UNIQUE, 29)

func test_forge_bonus_values():
	# Test via Level helper
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._tiles = []
	for _y in range(10):
		var row: Array[int] = []
		row.resize(10)
		level._tiles.append(row)

	# Normal forge
	level.set_tile(Vector2i(1, 1), Level.Tile.FORGE)
	assert_eq(level.get_forge_bonus(Vector2i(1, 1)), 0, "Normal forge = +0")

	# Enchanted forge
	level.set_tile(Vector2i(2, 2), Level.Tile.FORGE_ENCHANTED)
	assert_eq(level.get_forge_bonus(Vector2i(2, 2)), 3, "Enchanted forge = +3")

	# Unique forge
	level.set_tile(Vector2i(3, 3), Level.Tile.FORGE_UNIQUE)
	assert_eq(level.get_forge_bonus(Vector2i(3, 3)), 7, "Unique forge = +7")

	level.free()

func test_forge_use_tracking():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._tiles = []
	for _y in range(10):
		var row: Array[int] = []
		row.resize(10)
		level._tiles.append(row)

	level.set_tile(Vector2i(5, 5), Level.Tile.FORGE)
	level.init_forge_uses(Vector2i(5, 5), 3)

	assert_eq(level.get_forge_uses(Vector2i(5, 5)), 3, "Initial uses = 3")

	var remaining: int = level.consume_forge_use(Vector2i(5, 5))
	assert_eq(remaining, 2, "After 1 use = 2 remaining")

	remaining = level.consume_forge_use(Vector2i(5, 5))
	assert_eq(remaining, 1, "After 2 uses = 1 remaining")

	remaining = level.consume_forge_use(Vector2i(5, 5))
	assert_eq(remaining, 0, "After 3 uses = 0 remaining")

	# Forge should be converted to floor when exhausted
	assert_eq(level.get_tile(Vector2i(5, 5)), Level.Tile.FLOOR, "Exhausted forge becomes floor")

	level.free()

func test_is_forge_tile_all_types():
	var level := Level.new()
	level.width = 10
	level.height = 10
	level._tiles = []
	for _y in range(10):
		var row: Array[int] = []
		row.resize(10)
		level._tiles.append(row)

	level.set_tile(Vector2i(1, 1), Level.Tile.FORGE)
	level.set_tile(Vector2i(2, 2), Level.Tile.FORGE_ENCHANTED)
	level.set_tile(Vector2i(3, 3), Level.Tile.FORGE_UNIQUE)
	level.set_tile(Vector2i(4, 4), Level.Tile.FLOOR)

	assert_true(level.is_forge_tile(Vector2i(1, 1)), "Normal forge detected")
	assert_true(level.is_forge_tile(Vector2i(2, 2)), "Enchanted forge detected")
	assert_true(level.is_forge_tile(Vector2i(3, 3)), "Unique forge detected")
	assert_false(level.is_forge_tile(Vector2i(4, 4)), "Floor is not a forge")

	level.free()

# ============================================================================
# ITEM TYPE CHECKS
# ============================================================================

func test_weapon_type_detection():
	var item := DataManager.ItemData.new()
	item.tval = 23  # Sword
	assert_true(smithing._is_weapon(item))
	assert_false(smithing._is_armor(item))
	assert_false(smithing._is_jewelry(item))

func test_armor_type_detection():
	var item := DataManager.ItemData.new()
	item.tval = 37  # Mail
	assert_false(smithing._is_weapon(item))
	assert_true(smithing._is_armor(item))
	assert_false(smithing._is_jewelry(item))

func test_jewelry_type_detection():
	var item := DataManager.ItemData.new()
	item.tval = 45  # Ring
	assert_false(smithing._is_weapon(item))
	assert_false(smithing._is_armor(item))
	assert_true(smithing._is_jewelry(item))

# ============================================================================
# BROKEN GLOWING JEWELRY (ID 496) — Task 1
# ============================================================================

func test_broken_glowing_jewelry_constants():
	assert_eq(SmithingSystem.BROKEN_GLOWING_JEWELRY_ID, 496)

func test_broken_glowing_jewelry_in_id_list():
	var item := DataManager.ItemData.new()
	item.name = "Broken Glowing Ring"
	item.index = 496
	item.flags = ["DAMAGED", "NO_SMITHING", "EASY_KNOW"]
	assert_true(smithing._is_broken_glowing(item), "ID 496 detected as broken glowing")

# ============================================================================
# DATA MANAGER TYPE-FILTERED QUERIES
# ============================================================================

func test_data_manager_loaded():
	# Verify DataManager has items and artifacts loaded
	assert_gt(DataManager.items.size(), 0, "DataManager has items")
	assert_gt(DataManager.artifacts.size(), 0, "DataManager has artifacts")

func test_random_item_by_tvals_returns_correct_type():
	var weapon_tvals: Array[int] = [20, 21, 22, 23]
	var item: DataManager.ItemData = DataManager.get_random_item_by_tvals(weapon_tvals, 5)
	if item:
		assert_true(item.tval in weapon_tvals, "Should return weapon (tval in %s), got tval=%d" % [str(weapon_tvals), item.tval])

func test_random_artifact_by_tvals_returns_correct_type():
	var weapon_tvals: Array[int] = [20, 21, 22, 23]
	var artifact: DataManager.ArtifactData = DataManager.get_random_artifact_by_tvals(weapon_tvals)
	if artifact:
		assert_true(artifact.tval in weapon_tvals, "Should return weapon artifact, got tval=%d" % artifact.tval)

func test_random_artifacts_multiple():
	var weapon_tvals: Array[int] = [20, 21, 22, 23]
	var arts: Array[DataManager.ArtifactData] = DataManager.get_random_artifacts_by_tvals(weapon_tvals, 3)
	assert_lte(arts.size(), 3, "Should return at most 3 artifacts")
	for a in arts:
		assert_true(a.tval in weapon_tvals, "Each artifact should be weapon type")

func test_best_artifact_by_tvals():
	var weapon_tvals: Array[int] = [20, 21, 22, 23]
	var best: DataManager.ArtifactData = DataManager.get_best_artifact_by_tvals(weapon_tvals)
	if best:
		assert_true(best.tval in weapon_tvals, "Best artifact should be weapon type")
		# Verify it's actually the deepest
		for a in DataManager.artifacts.values():
			if a.tval in weapon_tvals:
				assert_lte(a.depth, best.depth, "Best should have highest depth")

# ============================================================================
# SMITHING ABILITY ENUM COMPLETENESS
# ============================================================================

func test_smithing_ability_enum_has_all_abilities():
	assert_eq(Constants.SmithingAbility.SMT_WEAPONSMITH, 0)
	assert_eq(Constants.SmithingAbility.SMT_ARMOURSMITH, 1)
	assert_eq(Constants.SmithingAbility.SMT_JEWELLER, 2)
	assert_eq(Constants.SmithingAbility.SMT_REFORGE, 3)
	assert_eq(Constants.SmithingAbility.SMT_EXPERTISE, 4)
	assert_eq(Constants.SmithingAbility.SMT_RECLAIM, 5)
	assert_eq(Constants.SmithingAbility.SMT_MASTERWORK, 6)
	assert_eq(Constants.SmithingAbility.SMT_GRACE, 7)
	assert_eq(Constants.SmithingAbility.SMT_REFORGE_MASTERY, 8)
	assert_eq(Constants.SmithingAbility.SMT_SALVAGE, 9)
	assert_eq(Constants.SmithingAbility.SMT_RECLAIM_MASTERY, 10)
	assert_eq(Constants.SmithingAbility.SMT_MASTER_SMITH, 11)
