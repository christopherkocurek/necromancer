extends GutTest
## Unit tests for the energy-based turn system
## Tests energy accumulation, turn order, speed mechanics

# Energy table from constants.gd
const ENERGY_TABLE: Array[int] = [5, 5, 10, 15, 20, 25, 30, 35]
const ACTION_COST: int = 100

func test_energy_table_values():
	assert_eq(ENERGY_TABLE[0], 5, "Speed 0 should grant 5 energy")
	assert_eq(ENERGY_TABLE[1], 5, "Speed 1 should grant 5 energy")
	assert_eq(ENERGY_TABLE[2], 10, "Speed 2 should grant 10 energy")
	assert_eq(ENERGY_TABLE[3], 15, "Speed 3 should grant 15 energy")
	assert_eq(ENERGY_TABLE[4], 20, "Speed 4 should grant 20 energy (normal)")
	assert_eq(ENERGY_TABLE[5], 25, "Speed 5 should grant 25 energy")
	assert_eq(ENERGY_TABLE[6], 30, "Speed 6 should grant 30 energy")
	assert_eq(ENERGY_TABLE[7], 35, "Speed 7 should grant 35 energy (fast)")

func test_action_cost_is_100():
	assert_eq(ACTION_COST, 100, "Action cost should be 100 energy")

func test_entity_can_act_at_100_energy():
	var energy: int = 100
	var can_act: bool = energy >= ACTION_COST
	assert_true(can_act, "Entity with 100 energy should be able to act")

func test_entity_cannot_act_below_100():
	var energy: int = 99
	var can_act: bool = energy >= ACTION_COST
	assert_false(can_act, "Entity with 99 energy should not be able to act")

func test_normal_speed_needs_5_rounds_to_act():
	# Speed 4 grants 20 energy per round
	var energy: int = 0
	var speed: int = 4
	var rounds: int = 0

	while energy < ACTION_COST:
		energy += ENERGY_TABLE[speed]
		rounds += 1

	assert_eq(rounds, 5, "Speed 4 entity needs 5 rounds to accumulate 100 energy")

func test_fast_monster_acts_more_often():
	# Speed 7 grants 35 energy per round
	var energy: int = 0
	var speed: int = 7
	var rounds: int = 0

	while energy < ACTION_COST:
		energy += ENERGY_TABLE[speed]
		rounds += 1

	assert_eq(rounds, 3, "Speed 7 entity needs only 3 rounds to act")

func test_slow_monster_acts_less_often():
	# Speed 0 grants 5 energy per round
	var energy: int = 0
	var speed: int = 0
	var rounds: int = 0

	while energy < ACTION_COST:
		energy += ENERGY_TABLE[speed]
		rounds += 1

	assert_eq(rounds, 20, "Speed 0 entity needs 20 rounds to act")

func test_energy_consumed_on_action():
	var energy: int = 120
	energy -= ACTION_COST
	assert_eq(energy, 20, "Energy should be reduced by action cost")

func test_excess_energy_carries_over():
	# Entity with 120 energy acts, should have 20 left
	var energy: int = 0
	var speed: int = 7  # 35 per round

	# Accumulate: 35, 70, 105
	for i in range(3):
		energy += ENERGY_TABLE[speed]

	assert_eq(energy, 105, "Should have 105 energy after 3 rounds")

	# Act
	energy -= ACTION_COST
	assert_eq(energy, 5, "Should have 5 energy left after acting")

func test_turn_order_by_energy():
	# Simulate turn order determination
	var entities: Array[Dictionary] = [
		{"name": "player", "energy": 100, "speed": 4},
		{"name": "fast_monster", "energy": 105, "speed": 7},
		{"name": "slow_monster", "energy": 80, "speed": 2},
	]

	# Filter who can act
	var can_act: Array[Dictionary] = []
	for e in entities:
		if e.energy >= ACTION_COST:
			can_act.append(e)

	assert_eq(can_act.size(), 2, "Two entities should be able to act")

	# Sort by energy (highest first)
	can_act.sort_custom(func(a, b): return a.energy > b.energy)

	assert_eq(can_act[0].name, "fast_monster", "Fast monster should act first (higher energy)")
	assert_eq(can_act[1].name, "player", "Player should act second")

func test_multiple_actions_per_round_for_fast_entity():
	# Very fast entity might act twice before slow entity acts once
	var fast_energy: int = 0
	var slow_energy: int = 0
	var fast_speed: int = 7  # 35/round
	var slow_speed: int = 2  # 10/round

	var fast_actions: int = 0
	var slow_actions: int = 0

	# Simulate 10 rounds
	for round in range(10):
		fast_energy += ENERGY_TABLE[fast_speed]
		slow_energy += ENERGY_TABLE[slow_speed]

		while fast_energy >= ACTION_COST:
			fast_energy -= ACTION_COST
			fast_actions += 1

		while slow_energy >= ACTION_COST:
			slow_energy -= ACTION_COST
			slow_actions += 1

	# Fast: 350 energy / 100 = 3.5 actions (3 with leftover)
	# Slow: 100 energy / 100 = 1 action
	assert_eq(fast_actions, 3, "Fast entity should take 3 actions in 10 rounds")
	assert_eq(slow_actions, 1, "Slow entity should take 1 action in 10 rounds")
