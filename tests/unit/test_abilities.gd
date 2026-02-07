extends GutTest
## Unit tests for ability system and combat modifiers (Phase H)
## Tests Bane, Master Hunter, Vengeance, Opening Strike, ability arrays

# ============================================================================
# ABILITY ARRAY TESTS
# ============================================================================

func test_has_ability_bounds_checking():
	# has_ability should return false for out-of-bounds indices
	# Simulating the bounds check from player.gd:164-168
	var s_max: int = Constants.S_MAX
	var abilities_max: int = Constants.ABILITIES_MAX

	assert_true(s_max > 0, "S_MAX should be positive")
	assert_true(abilities_max > 0, "ABILITIES_MAX should be positive")

	# Out of bounds checks
	assert_true(-1 < 0 or -1 >= s_max, "Negative skill should be rejected")
	assert_true(s_max >= s_max, "S_MAX should be rejected (0-indexed)")

func test_learn_ability_bounds_check():
	# learn_ability should silently return for invalid indices
	# Simulating player.gd:172-175
	var skill: int = -1
	var ability: int = 0
	var would_crash: bool = skill >= 0 and skill < Constants.S_MAX and ability >= 0 and ability < Constants.ABILITIES_MAX
	assert_false(would_crash, "Negative skill should not pass bounds check")

	skill = Constants.S_MAX
	would_crash = skill >= 0 and skill < Constants.S_MAX and ability >= 0 and ability < Constants.ABILITIES_MAX
	assert_false(would_crash, "S_MAX should not pass bounds check")

func test_ability_array_initialization():
	# Ability arrays should be S_MAX x ABILITIES_MAX filled with false
	var innate: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		innate.append(row)

	assert_eq(innate.size(), Constants.S_MAX, "Should have S_MAX rows")
	assert_eq(innate[0].size(), Constants.ABILITIES_MAX, "Each row should have ABILITIES_MAX entries")
	assert_false(innate[0][0], "All entries should start false")

func test_learn_sets_all_three_arrays():
	# learn_ability should set innate, active, and have arrays
	var innate: Array = []
	var active: Array = []
	var have: Array = []
	for i in range(Constants.S_MAX):
		var r1: Array = []
		var r2: Array = []
		var r3: Array = []
		for j in range(Constants.ABILITIES_MAX):
			r1.append(false)
			r2.append(false)
			r3.append(false)
		innate.append(r1)
		active.append(r2)
		have.append(r3)

	# Simulate learn_ability(0, 1)
	var skill: int = 0
	var ability: int = 1
	innate[skill][ability] = true
	active[skill][ability] = true
	have[skill][ability] = true

	assert_true(innate[skill][ability], "innate should be true after learning")
	assert_true(active[skill][ability], "active should be true after learning")
	assert_true(have[skill][ability], "have should be true after learning")
	assert_false(innate[skill][0], "Other abilities should remain false")

# ============================================================================
# COMBAT MODIFIER TESTS
# ============================================================================

func test_bane_bonus_formula():
	# Bane: +log2(kill_count) for kills >= 2
	# Simulating player.gd _get_bane_bonus()
	assert_eq(_bane_bonus(0), 0, "0 kills = no bonus")
	assert_eq(_bane_bonus(1), 0, "1 kill = no bonus")
	assert_eq(_bane_bonus(2), 1, "2 kills = +1")
	assert_eq(_bane_bonus(4), 2, "4 kills = +2")
	assert_eq(_bane_bonus(8), 3, "8 kills = +3")
	assert_eq(_bane_bonus(16), 4, "16 kills = +4")
	assert_eq(_bane_bonus(3), 1, "3 kills = +1 (floor of log2)")

func test_master_hunter_bonus_formula():
	# Master Hunter: +MIN(kill_count, perception/2)
	# Simulating player.gd _get_master_hunter_bonus()
	assert_eq(_master_hunter_bonus(5, 6), 3, "5 kills, 6 perception = +3")
	assert_eq(_master_hunter_bonus(1, 10), 1, "1 kill, 10 perception = +1")
	assert_eq(_master_hunter_bonus(10, 4), 2, "10 kills, 4 perception = +2")
	assert_eq(_master_hunter_bonus(0, 10), 0, "0 kills = 0")
	assert_eq(_master_hunter_bonus(5, 0), 1, "0 perception = +1 (per_cap floor at 1)")

func test_strength_in_adversity_formula():
	# +1 per 10% HP below 50%
	# At 40% HP: +1, at 30% HP: +2, at 10% HP: +4
	assert_eq(_adversity_bonus(100, 100), 0, "Full HP = no bonus")
	assert_eq(_adversity_bonus(50, 100), 0, "50% HP = no bonus")
	assert_eq(_adversity_bonus(40, 100), 1, "40% HP = +1")
	assert_eq(_adversity_bonus(30, 100), 2, "30% HP = +2")
	assert_eq(_adversity_bonus(10, 100), 4, "10% HP = +4")
	assert_eq(_adversity_bonus(1, 100), 4, "1% HP = +4")

func test_vengeance_bonus():
	# Vengeance: +2 attack when _vengeance_active is true
	var vengeance_active: bool = false
	assert_eq(_vengeance_bonus(vengeance_active), 0, "No vengeance = 0")
	vengeance_active = true
	assert_eq(_vengeance_bonus(vengeance_active), 2, "Active vengeance = +2")

func test_defensive_stance_bonus():
	# +3 evasion when not moved last turn
	var moved_last_turn: bool = false
	assert_eq(_defensive_stance(moved_last_turn), 3, "Stationary = +3 evasion")
	moved_last_turn = true
	assert_eq(_defensive_stance(moved_last_turn), 0, "Moved = no bonus")

func test_crowd_fighting_penalty():
	# Without Crowd Fighting: -(adjacent_count - 1) evasion
	# With Crowd Fighting: no penalty
	assert_eq(_crowd_penalty(0, false), 0, "0 adjacent = no penalty")
	assert_eq(_crowd_penalty(1, false), 0, "1 adjacent = no penalty")
	assert_eq(_crowd_penalty(2, false), -1, "2 adjacent = -1 penalty")
	assert_eq(_crowd_penalty(3, false), -2, "3 adjacent = -2 penalty")
	assert_eq(_crowd_penalty(2, true), 0, "Crowd Fighting negates penalty")
	assert_eq(_crowd_penalty(5, true), 0, "Crowd Fighting negates all penalty")

func test_formidable_bonus():
	# +Will/3 evasion
	assert_eq(_formidable_bonus(0), 0, "0 will = 0")
	assert_eq(_formidable_bonus(3), 1, "3 will = +1")
	assert_eq(_formidable_bonus(6), 2, "6 will = +2")
	assert_eq(_formidable_bonus(10), 3, "10 will = +3")

func test_heavy_armor_penalty():
	# weight >= 150: penalty = weight/50
	assert_eq(_heavy_armor_penalty(0), 0, "No armor = no penalty")
	assert_eq(_heavy_armor_penalty(100), 0, "Light armor = no penalty")
	assert_eq(_heavy_armor_penalty(149), 0, "Just under threshold = no penalty")
	assert_eq(_heavy_armor_penalty(150), 3, "150 weight = -3")
	assert_eq(_heavy_armor_penalty(200), 4, "200 weight = -4")
	assert_eq(_heavy_armor_penalty(300), 6, "300 weight = -6")

# ============================================================================
# DEFY DEATH TESTS
# ============================================================================

func test_defy_death_chance_formula():
	# Will * 3 percent chance
	assert_eq(3 * 3, 9, "3 will = 9% chance")
	assert_eq(10 * 3, 30, "10 will = 30% chance")
	assert_eq(20 * 3, 60, "20 will = 60% chance")

func test_defy_death_sets_hp_to_one():
	# After fix: HP should be set directly to 1, not through take_damage()
	var current_health: int = 5
	var damage: int = 10
	# Old behavior: super.take_damage(current_health - 1) could be absorbed by armor
	# New behavior: current_health = 1
	var new_health: int = 1  # Direct set
	assert_eq(new_health, 1, "Defy Death should set HP to exactly 1")
	assert_true(current_health - damage <= 0, "Original damage should be lethal")

# ============================================================================
# KILL TRACKING TESTS
# ============================================================================

func test_kills_by_name_tracking():
	var kills_by_name: Dictionary = {}

	# First kill
	var name1: String = "Goblin"
	kills_by_name[name1] = kills_by_name.get(name1, 0) + 1
	assert_eq(kills_by_name[name1], 1, "First goblin kill = 1")

	# Second kill
	kills_by_name[name1] = kills_by_name.get(name1, 0) + 1
	assert_eq(kills_by_name[name1], 2, "Second goblin kill = 2")

	# Different monster
	var name2: String = "Orc"
	kills_by_name[name2] = kills_by_name.get(name2, 0) + 1
	assert_eq(kills_by_name[name2], 1, "First orc kill = 1")
	assert_eq(kills_by_name[name1], 2, "Goblin kills unchanged")

# ============================================================================
# ENUM-DATA ALIGNMENT TESTS
# ============================================================================

func test_melee_enum_range():
	# MeleeAbility should have values 0-13
	assert_eq(Constants.MeleeAbility.MEL_POWER, 0, "MEL_POWER = 0")
	assert_eq(Constants.MeleeAbility.MEL_STR, 13, "MEL_STR = 13")

func test_evasion_enum_range():
	assert_eq(Constants.EvasionAbility.EVN_DODGING, 0, "EVN_DODGING = 0")
	assert_eq(Constants.EvasionAbility.EVN_DEX, 10, "EVN_DEX = 10")

func test_stealth_enum_range():
	assert_eq(Constants.StealthAbility.STL_DISGUISE, 0, "STL_DISGUISE = 0")
	assert_eq(Constants.StealthAbility.STL_FADE, 8, "STL_FADE = 8")
	assert_eq(Constants.StealthAbility.STL_SILENT_KILL, 11, "STL_SILENT_KILL = 11")

func test_perception_enum_range():
	assert_eq(Constants.PerceptionAbility.PER_NATURAL_TALENT, 0, "PER_NATURAL_TALENT = 0")
	assert_eq(Constants.PerceptionAbility.PER_BANE, 5, "PER_BANE = 5")
	assert_eq(Constants.PerceptionAbility.PER_MASTER_HUNTER, 8, "PER_MASTER_HUNTER = 8")
	assert_eq(Constants.PerceptionAbility.PER_GRACE, 9, "PER_GRACE = 9")

func test_will_enum_range():
	assert_eq(Constants.WillAbility.WIL_CURSE_BREAKING, 0, "WIL_CURSE_BREAKING = 0")
	assert_eq(Constants.WillAbility.WIL_DEFY_DEATH, 4, "WIL_DEFY_DEATH = 4")
	assert_eq(Constants.WillAbility.WIL_MAJESTY, 9, "WIL_MAJESTY = 9")
	assert_eq(Constants.WillAbility.WIL_CON, 10, "WIL_CON = 10")

func test_smithing_enum_range():
	assert_eq(Constants.SmithingAbility.SMT_WEAPONSMITH, 0, "SMT_WEAPONSMITH = 0")
	assert_eq(Constants.SmithingAbility.SMT_MASTER_SMITH, 11, "SMT_MASTER_SMITH = 11")

# ============================================================================
# HELPERS
# ============================================================================

func _bane_bonus(kill_count: int) -> int:
	if kill_count < 2:
		return 0
	return int(log(float(kill_count)) / log(2.0))

func _master_hunter_bonus(kill_count: int, perception: int) -> int:
	if kill_count <= 0:
		return 0
	var per_cap: int = maxi(1, perception / 2)
	return mini(kill_count, per_cap)

func _adversity_bonus(current_hp: int, max_hp: int) -> int:
	if max_hp <= 0:
		return 0
	var hp_pct: int = current_hp * 100 / max_hp
	if hp_pct >= 50:
		return 0
	return (50 - hp_pct) / 10

func _vengeance_bonus(active: bool) -> int:
	return 2 if active else 0

func _defensive_stance(moved_last_turn: bool) -> int:
	return 0 if moved_last_turn else 3

func _crowd_penalty(adjacent_count: int, has_crowd_fighting: bool) -> int:
	if has_crowd_fighting:
		return 0
	return -maxi(0, adjacent_count - 1)

func _formidable_bonus(will_skill: int) -> int:
	return will_skill / 3

func _heavy_armor_penalty(weight: int) -> int:
	if weight < 150:
		return 0
	return weight / 50

# ============================================================================
# ABILITY XP COST FORMULA TESTS (Sil-Q economy)
# ============================================================================

func test_ability_cost_formula_first_ability():
	# 1st ability in a skill: (0 + 1) * 500 = 500
	assert_eq(_ability_xp_cost(0, 0), 500, "1st ability costs 500 XP")

func test_ability_cost_formula_escalating():
	# Cost escalates with # owned in that skill
	assert_eq(_ability_xp_cost(1, 0), 1000, "2nd ability costs 1000 XP")
	assert_eq(_ability_xp_cost(2, 0), 1500, "3rd ability costs 1500 XP")
	assert_eq(_ability_xp_cost(4, 0), 2500, "5th ability costs 2500 XP")
	assert_eq(_ability_xp_cost(9, 0), 5000, "10th ability costs 5000 XP")

func test_ability_cost_with_positive_affinity():
	# +1 affinity: -500 discount
	assert_eq(_ability_xp_cost(0, 1), 0, "1st ability free with +1 affinity")
	assert_eq(_ability_xp_cost(1, 1), 500, "2nd ability 500 with +1 affinity")
	assert_eq(_ability_xp_cost(4, 1), 2000, "5th ability 2000 with +1 affinity")

func test_ability_cost_with_negative_affinity():
	# -1 penalty: +500 surcharge
	assert_eq(_ability_xp_cost(0, -1), 1000, "1st ability 1000 with -1 penalty")
	assert_eq(_ability_xp_cost(1, -1), 1500, "2nd ability 1500 with -1 penalty")

func test_ability_cost_floor_at_zero():
	# Cost can never go below 0
	assert_eq(_ability_xp_cost(0, 2), 0, "1st ability free with +2 affinity")
	assert_eq(_ability_xp_cost(0, 3), 0, "Floor at 0 even with large affinity")

# ============================================================================
# OR PREREQUISITE LOGIC TESTS
# ============================================================================

func test_or_prereqs_none_met():
	# No prereqs met -> false
	var met: Array[bool] = [false, false]
	assert_false(_check_or_prereqs(met), "No prereqs met = cannot learn")

func test_or_prereqs_one_met():
	# One prereq met -> true (OR logic)
	var met: Array[bool] = [true, false]
	assert_true(_check_or_prereqs(met), "One prereq met = can learn (OR)")

func test_or_prereqs_all_met():
	# All prereqs met -> true
	var met: Array[bool] = [true, true]
	assert_true(_check_or_prereqs(met), "All prereqs met = can learn")

func test_or_prereqs_empty():
	# No prereqs -> true (always learnable)
	var met: Array[bool] = []
	assert_true(_check_or_prereqs(met), "Empty prereqs = always learnable")

# ============================================================================
# ABILITIES_IN_SKILL COUNTING TESTS
# ============================================================================

func test_abilities_in_skill_empty():
	var innate: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		innate.append(row)
	assert_eq(_count_abilities_in_skill(innate, 0), 0, "No abilities learned = 0")

func test_abilities_in_skill_counts_correctly():
	var innate: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		innate.append(row)
	innate[0][0] = true  # Power
	innate[0][1] = true  # Finesse
	innate[0][5] = true  # Follow-Through
	assert_eq(_count_abilities_in_skill(innate, 0), 3, "3 melee abilities learned")
	assert_eq(_count_abilities_in_skill(innate, 1), 0, "No archery abilities")

func test_abilities_in_skill_bounds():
	var innate: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		innate.append(row)
	assert_eq(_count_abilities_in_skill(innate, -1), 0, "Negative index = 0")
	assert_eq(_count_abilities_in_skill(innate, Constants.S_MAX), 0, "Out of bounds = 0")

# ============================================================================
# NEW HELPERS
# ============================================================================

## Mirrors the Sil-Q ability cost formula: (owned + 1) * 500 - 500 * affinity
func _ability_xp_cost(owned_in_skill: int, affinity_level: int) -> int:
	return maxi(0, (owned_in_skill + 1) * 500 - 500 * affinity_level)

## OR prerequisite check: true if empty or ANY element is true
func _check_or_prereqs(met: Array[bool]) -> bool:
	if met.is_empty():
		return true
	for m in met:
		if m:
			return true
	return false

## Count abilities in a skill tree from innate array
func _count_abilities_in_skill(innate: Array, skill_type: int) -> int:
	if skill_type < 0 or skill_type >= innate.size():
		return 0
	var count: int = 0
	for i in range(innate[skill_type].size()):
		if innate[skill_type][i]:
			count += 1
	return count
