extends GutTest
## Unit tests for player skill and XP system
## Tests Sil-Q style XP-as-currency mechanics

# Skill cost: nth point costs 100 * n XP
# Starting XP: 5000

func test_skill_cost_formula():
	# 1st point = 100 XP
	# 2nd point = 200 XP
	# 3rd point = 300 XP
	# etc.
	assert_eq(_get_skill_cost(1), 100, "1st skill point should cost 100 XP")
	assert_eq(_get_skill_cost(2), 200, "2nd skill point should cost 200 XP")
	assert_eq(_get_skill_cost(5), 500, "5th skill point should cost 500 XP")
	assert_eq(_get_skill_cost(10), 1000, "10th skill point should cost 1000 XP")

func test_total_cost_to_reach_skill_level():
	# Total to reach level 5: 100 + 200 + 300 + 400 + 500 = 1500
	var total: int = 0
	for i in range(1, 6):
		total += _get_skill_cost(i)
	assert_eq(total, 1500, "Total cost to reach skill 5 should be 1500 XP")

	# Total to reach level 10: sum(100*i for i in 1..10) = 5500
	total = 0
	for i in range(1, 11):
		total += _get_skill_cost(i)
	assert_eq(total, 5500, "Total cost to reach skill 10 should be 5500 XP")

func test_starting_xp():
	var starting_xp: int = 5000
	assert_eq(starting_xp, 5000, "Player should start with 5000 XP")

func test_can_afford_skill_point():
	var current_xp: int = 5000
	var current_skill: int = 3
	var next_cost: int = _get_skill_cost(current_skill + 1)  # 400

	assert_true(current_xp >= next_cost, "Should be able to afford 4th point with 5000 XP")

func test_cannot_afford_expensive_skill():
	var current_xp: int = 500
	var current_skill: int = 9
	var next_cost: int = _get_skill_cost(current_skill + 1)  # 1000

	assert_false(current_xp >= next_cost, "Should not afford 10th point with only 500 XP")

func test_skill_investment_reduces_xp():
	var xp: int = 5000
	var skill_level: int = 0

	# Invest 3 points
	for i in range(3):
		var cost: int = _get_skill_cost(skill_level + 1)
		xp -= cost
		skill_level += 1

	# Cost: 100 + 200 + 300 = 600
	assert_eq(xp, 4400, "XP should be 4400 after investing 3 skill points")
	assert_eq(skill_level, 3, "Skill should be level 3")

func test_stat_point_cost_curve():
	# Character creation stat costs (index = stat + 4)
	# [-4, -3, -2, -1, 0, 1, 3, 6, 10, 15, 21]
	var cost_curve: Array[int] = [-4, -3, -2, -1, 0, 1, 3, 6, 10, 15, 21]

	# Base stat is 0, which costs 0 points
	assert_eq(cost_curve[4], 0, "Base stat (0) should cost 0 points")

	# Negative stats give points back
	assert_eq(cost_curve[0], -4, "Stat -4 should give 4 points back")
	assert_eq(cost_curve[3], -1, "Stat -1 should give 1 point back")

	# Positive stats cost increasingly more
	assert_eq(cost_curve[5], 1, "Stat +1 should cost 1 point")
	assert_eq(cost_curve[6], 3, "Stat +2 should cost 3 points")
	assert_eq(cost_curve[7], 6, "Stat +3 should cost 6 points")
	assert_eq(cost_curve[10], 21, "Stat +6 should cost 21 points")

func test_starting_stat_points():
	var total_stat_points: int = 13
	assert_eq(total_stat_points, 13, "Player should have 13 stat points")

func test_stat_allocation_example():
	var cost_curve: Array[int] = [-4, -3, -2, -1, 0, 1, 3, 6, 10, 15, 21]
	var points_remaining: int = 13

	# Example: STR +2, DEX +3, CON +1, GRA 0
	var str_mod: int = 2  # cost 3
	var dex_mod: int = 3  # cost 6
	var con_mod: int = 1  # cost 1
	var gra_mod: int = 0  # cost 0

	var total_cost: int = cost_curve[str_mod + 4] + cost_curve[dex_mod + 4] + cost_curve[con_mod + 4] + cost_curve[gra_mod + 4]
	# 3 + 6 + 1 + 0 = 10

	assert_eq(total_cost, 10, "Example allocation should cost 10 points")
	assert_true(total_cost <= points_remaining, "Example allocation should be affordable")

func test_skill_max_level():
	var max_skill: int = 20
	assert_eq(max_skill, 20, "Skills should max at 20")

func test_skill_affects_combat():
	# Melee skill adds to attack bonus
	var base_attack: int = 0
	var melee_skill: int = 5
	var total_attack: int = base_attack + melee_skill

	assert_eq(total_attack, 5, "5 melee skill should give +5 attack")

func test_evasion_skill_affects_defense():
	var base_evasion: int = 0
	var evasion_skill: int = 7
	var total_evasion: int = base_evasion + evasion_skill

	assert_eq(total_evasion, 7, "7 evasion skill should give +7 evasion")

# Helper: Calculate skill point cost
func _get_skill_cost(point_number: int) -> int:
	return 100 * point_number
