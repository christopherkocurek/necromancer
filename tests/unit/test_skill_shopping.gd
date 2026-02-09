extends GutTest
## Unit tests for the pre-creation skill shopping system.
## Covers: skill cost calculation, affinity discounts, ability prerequisites,
## XP tracking accuracy, and race/house change resets.

const CharacterCreationScript := preload("res://scripts/ui/character_creation.gd")

# ============================================================================
# HELPERS
# ============================================================================

func _make_cc() -> CharacterCreation:
	## Create a CharacterCreation instance with minimal setup for testing cost math.
	## We don't call _ready() since that needs a full scene tree.
	var cc := CharacterCreation.new()
	# Set a valid race and house so affinity lookups work
	# "Of Gondor" has MEL_AFFINITY (melee)
	cc.selected_race = "Man"
	cc.selected_house = "Of Gondor"
	return cc

func _cleanup_cc(cc: CharacterCreation) -> void:
	cc.free()

# ============================================================================
# SKILL COST CALCULATION
# ============================================================================

func test_skill_cost_level_zero():
	var cc := _make_cc()
	# Cost to go from 0 to 1 = 100 * (0 + 1) = 100 (no affinity for Of Gondor on lore)
	var cost: int = cc._calc_skill_point_cost("lore", 0)
	assert_eq(cost, 100, "First skill point (no affinity) should cost 100 XP")
	_cleanup_cc(cc)

func test_skill_cost_scales_linearly():
	var cc := _make_cc()
	# Lore (no affinity for Of Gondor): Level 0->1 = 100, 1->2 = 200, 2->3 = 300
	assert_eq(cc._calc_skill_point_cost("lore", 0), 100)
	assert_eq(cc._calc_skill_point_cost("lore", 1), 200)
	assert_eq(cc._calc_skill_point_cost("lore", 2), 300)
	assert_eq(cc._calc_skill_point_cost("lore", 5), 600)
	_cleanup_cc(cc)

func test_skill_cost_total_multiple_points():
	var cc := _make_cc()
	# Invest 3 points in lore (no affinity): 100 + 200 + 300 = 600
	cc.skill_investments["lore"] = 3
	var total: int = cc._calc_total_skill_cost("lore")
	assert_eq(total, 600, "3 points in lore should cost 600 total")
	_cleanup_cc(cc)

# ============================================================================
# AFFINITY DISCOUNT
# ============================================================================

func test_affinity_discount_reduces_cost():
	var cc := _make_cc()
	# "Of Gondor" has MEL_AFFINITY — melee should get 100 XP discount per point
	var cost_with_affinity: int = cc._calc_skill_point_cost("melee", 0)
	# Level 0->1 = 100 * 1 - 100 = 0 (clamped to 0)
	assert_eq(cost_with_affinity, 0, "Melee level 0->1 with affinity should cost 0")

	var cost_level_1: int = cc._calc_skill_point_cost("melee", 1)
	# Level 1->2 = 100 * 2 - 100 = 100
	assert_eq(cost_level_1, 100, "Melee level 1->2 with affinity should cost 100")
	_cleanup_cc(cc)

func test_no_affinity_full_cost():
	var cc := _make_cc()
	# "Of Gondor" has MEL_AFFINITY, not LOR_AFFINITY. Lore should have full cost.
	var cost: int = cc._calc_skill_point_cost("lore", 0)
	assert_eq(cost, 100, "Lore without affinity should cost full 100")
	_cleanup_cc(cc)

func test_get_affinity_level_returns_correct_value():
	var cc := _make_cc()
	# "Of Gondor" has MEL_AFFINITY
	var melee_affinity: int = cc._get_affinity_level("melee")
	assert_true(melee_affinity > 0, "Of Gondor should have melee affinity")

	var lore_affinity: int = cc._get_affinity_level("lore")
	assert_eq(lore_affinity, 0, "Of Gondor should have no lore affinity")
	_cleanup_cc(cc)

# ============================================================================
# ABILITY PREREQUISITE CHAIN
# ============================================================================

func test_ability_cost_formula():
	var cc := _make_cc()
	# Ability cost = (position + 1) * 500 - affinity * 500
	# Lore has no affinity for "Of Gondor": first ability = 500, second = 1000
	var cost_1: int = cc._calc_ability_xp_cost("lore", 0)
	assert_eq(cost_1, 500, "First ability should cost 500 XP")
	var cost_2: int = cc._calc_ability_xp_cost("lore", 1)
	assert_eq(cost_2, 1000, "Second ability should cost 1000 XP")
	_cleanup_cc(cc)

func test_ability_cost_with_affinity():
	var cc := _make_cc()
	# "Of Gondor" has MEL_AFFINITY (level 1)
	# First melee ability: (0+1)*500 - 1*500 = 0
	var cost: int = cc._calc_ability_xp_cost("melee", 0)
	assert_eq(cost, 0, "First melee ability with affinity should cost 0")
	_cleanup_cc(cc)

# ============================================================================
# XP TRACKING ACCURACY
# ============================================================================

func test_xp_tracking_accurate():
	var cc := _make_cc()
	# "Of Gondor" has MEL_AFFINITY → melee gets -100 discount per point

	# Invest 2 points in melee (0 + 100 = 100 with affinity)
	cc.skill_investments["melee"] = 2
	cc._recalculate_precreation_xp()
	assert_eq(cc._precreation_xp_spent, 100, "2 melee points with affinity = 100 XP (0 + 100)")

	# Add 1 point in lore (no affinity: 100)
	cc.skill_investments["lore"] = 1
	cc._recalculate_precreation_xp()
	assert_eq(cc._precreation_xp_spent, 200, "melee 100 + lore 100 = 200")

	# Add 2 more lore points (100 + 200 + 300 = 600 for lore total)
	cc.skill_investments["lore"] = 3
	cc._recalculate_precreation_xp()
	assert_eq(cc._precreation_xp_spent, 700, "melee 100 + lore 600 = 700")

	# Remaining should be STARTING_XP - 700
	var remaining: int = cc._get_remaining_xp()
	assert_eq(remaining, Player.STARTING_XP - 700, "Remaining XP should be STARTING_XP - 700")
	_cleanup_cc(cc)

func test_ability_purchase_adds_to_xp():
	var cc := _make_cc()
	cc.ability_purchases.append({
		"skill_type": 0, "ability_num": 0, "skill_name": "melee",
		"name": "Test Ability", "xp_cost": 500,
	})
	cc._recalculate_precreation_xp()
	assert_eq(cc._precreation_xp_spent, 500, "One ability purchase should cost 500")
	_cleanup_cc(cc)

func test_combined_skill_and_ability_xp():
	var cc := _make_cc()
	cc.skill_investments["evasion"] = 2  # 100 + 200 = 300
	cc.ability_purchases.append({
		"skill_type": 2, "ability_num": 0, "skill_name": "evasion",
		"name": "Dodging", "xp_cost": 500,
	})
	cc._recalculate_precreation_xp()
	assert_eq(cc._precreation_xp_spent, 800, "300 skill + 500 ability = 800")
	_cleanup_cc(cc)

# ============================================================================
# RACE/HOUSE CHANGE RESETS
# ============================================================================

func test_race_change_resets_investments():
	var cc := _make_cc()
	cc.skill_investments["melee"] = 5
	cc.ability_purchases.append({
		"skill_type": 0, "ability_num": 0, "skill_name": "melee",
		"name": "Test", "xp_cost": 500,
	})
	cc._precreation_xp_spent = 2000

	cc._reset_skill_investments()

	assert_eq(cc.skill_investments["melee"], 0, "Melee should be reset to 0")
	assert_eq(cc.ability_purchases.size(), 0, "Ability purchases should be cleared")
	assert_eq(cc._precreation_xp_spent, 0, "XP spent should be reset to 0")
	_cleanup_cc(cc)

func test_all_skills_reset_to_zero():
	var cc := _make_cc()
	for skill_name in cc.skill_investments:
		cc.skill_investments[skill_name] = 3
	cc._reset_skill_investments()
	for skill_name in cc.skill_investments:
		assert_eq(cc.skill_investments[skill_name], 0, "%s should be 0 after reset" % skill_name)
	_cleanup_cc(cc)

# ============================================================================
# STAGE ENUM
# ============================================================================

func test_skills_stage_exists_between_stats_and_name():
	assert_true(CharacterCreation.Stage.SKILLS > CharacterCreation.Stage.STATS,
		"SKILLS should come after STATS")
	assert_true(CharacterCreation.Stage.SKILLS < CharacterCreation.Stage.NAME,
		"SKILLS should come before NAME")

func test_stage_count_is_nine():
	assert_eq(CharacterCreation.Stage.size(), 9,
		"Should have 9 stages: RACE, HOUSE, GENDER, TRAIT, STATS, SKILLS, NAME, DIFFICULTY, CONFIRM")
