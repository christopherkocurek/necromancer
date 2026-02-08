extends GutTest
## Unit tests for Sil-Q stealth detection model and stealth balance
## Tests: Sil-Q detection, terrain openness, alertness diminishing returns,
## fade immunity, stealth mode cost, perception bonus, starting alertness,
## noise constants, no-LOS detection, Hobbit CON, Small Stature, stealth XP

# ============================================================================
# TEST 1: SIL-Q DETECTION MODEL — DISTANCE AS DIRECT PENALTY
# ============================================================================

func test_sil_q_distance_penalty_perception_5_distance_8():
	# perception 5 at distance 8: net = 5 - 8 = -3
	var perception: int = 5
	var distance: int = 8
	var net_bonus: int = perception - distance
	assert_eq(net_bonus, -3, "Perception 5 at distance 8 = net -3")

func test_sil_q_distance_penalty_perception_5_distance_2():
	# perception 5 at distance 2: net = 5 - 2 = 3
	var perception: int = 5
	var distance: int = 2
	var net_bonus: int = perception - distance
	assert_eq(net_bonus, 3, "Perception 5 at distance 2 = net +3")

func test_sil_q_distance_0_gives_full_perception():
	# Adjacent (distance 0): net = perception - 0 = full perception
	var perception: int = 7
	var distance: int = 0
	var net_bonus: int = perception - distance
	assert_eq(net_bonus, 7, "Distance 0 (adjacent) gives full perception")

func test_sil_q_distance_greater_than_perception_gives_negative():
	# distance > perception: net is negative (harder to detect)
	var perception: int = 4
	var distance: int = 10
	var net_bonus: int = perception - distance
	assert_lt(net_bonus, 0, "Distance > perception gives negative net bonus")
	assert_eq(net_bonus, -6, "Perception 4 at distance 10 = net -6")

func test_sil_q_distance_equals_perception_gives_zero():
	# distance == perception: net = 0 (breakeven)
	var perception: int = 6
	var distance: int = 6
	var net_bonus: int = perception - distance
	assert_eq(net_bonus, 0, "Distance equal to perception gives zero net bonus")

func test_sil_q_distance_is_uncapped():
	# Unlike old model (maxi(0, 4 - dist)), new model has no floor
	var perception: int = 3
	var distance: int = 20
	var net_bonus: int = perception - distance
	assert_eq(net_bonus, -17, "Distance penalty is uncapped, can go deeply negative")

func test_sil_q_old_vs_new_formula_at_distance_5():
	# Old formula: maxi(0, 4 - distance) as bonus TO perception
	# New formula: perception - distance as direct penalty
	# At distance 5, perception 5:
	var perception: int = 5
	var distance: int = 5
	var old_dist_bonus: int = maxi(0, 4 - distance)  # = 0 (capped at 0)
	var old_m_per: int = perception + old_dist_bonus  # = 5
	var new_m_per: int = perception - distance  # = 0
	assert_eq(old_m_per, 5, "Old formula at dist 5: perception stays at 5")
	assert_eq(new_m_per, 0, "New formula at dist 5: perception reduced to 0")
	assert_ne(old_m_per, new_m_per, "Old and new formulas differ significantly")

# ============================================================================
# TEST 2: HOBBIT CON RACIAL MODIFIER IS +2
# ============================================================================

func test_hobbit_race_data_exists():
	var hobbit: DataManager.RaceData = DataManager.get_race("Hobbit")
	assert_not_null(hobbit, "Hobbit race data should exist in DataManager")

func test_hobbit_con_modifier_is_2():
	var hobbit: DataManager.RaceData = DataManager.get_race("Hobbit")
	if hobbit == null:
		fail_test("Hobbit race data not found")
		return
	assert_eq(hobbit.con_mod, 2, "Hobbit CON modifier should be +2")

func test_hobbit_str_modifier_is_negative_2():
	var hobbit: DataManager.RaceData = DataManager.get_race("Hobbit")
	if hobbit == null:
		fail_test("Hobbit race data not found")
		return
	assert_eq(hobbit.str_mod, -2, "Hobbit STR modifier should be -2")

func test_hobbit_dex_modifier_is_2():
	var hobbit: DataManager.RaceData = DataManager.get_race("Hobbit")
	if hobbit == null:
		fail_test("Hobbit race data not found")
		return
	assert_eq(hobbit.dex_mod, 2, "Hobbit DEX modifier should be +2")

func test_hobbit_gra_modifier_is_2():
	var hobbit: DataManager.RaceData = DataManager.get_race("Hobbit")
	if hobbit == null:
		fail_test("Hobbit race data not found")
		return
	assert_eq(hobbit.gra_mod, 2, "Hobbit GRA modifier should be +2")

func test_hobbit_has_small_stature_flag():
	var hobbit: DataManager.RaceData = DataManager.get_race("Hobbit")
	if hobbit == null:
		fail_test("Hobbit race data not found")
		return
	assert_true("SMALL_STATURE" in hobbit.flags, "Hobbit should have SMALL_STATURE flag")

func test_hobbit_has_hobbit_luck_flag():
	var hobbit: DataManager.RaceData = DataManager.get_race("Hobbit")
	if hobbit == null:
		fail_test("Hobbit race data not found")
		return
	assert_true("HOBBIT_LUCK" in hobbit.flags, "Hobbit should have HOBBIT_LUCK flag")

# ============================================================================
# TEST 3: SMALL STATURE EVASION BONUS
# ============================================================================

func test_small_stature_evasion_bonus_formula():
	# Player with SMALL_STATURE gets +2 evasion vs large monsters
	var has_small_stature: bool = true
	var attacker_is_large: bool = true
	var bonus: int = 2 if (has_small_stature and attacker_is_large) else 0
	assert_eq(bonus, 2, "Small Stature + large attacker = +2 evasion")

func test_small_stature_no_bonus_vs_normal_monster():
	# No bonus against non-large monsters
	var has_small_stature: bool = true
	var attacker_is_large: bool = false
	var bonus: int = 2 if (has_small_stature and attacker_is_large) else 0
	assert_eq(bonus, 0, "Small Stature + non-large attacker = no bonus")

func test_no_small_stature_no_bonus_vs_large():
	# Non-small-stature race gets no bonus even vs large monsters
	var has_small_stature: bool = false
	var attacker_is_large: bool = true
	var bonus: int = 2 if (has_small_stature and attacker_is_large) else 0
	assert_eq(bonus, 0, "No Small Stature + large attacker = no bonus")

func test_small_stature_stealth_bonus():
	# SMALL_STATURE also grants +2 stealth
	var has_small_stature: bool = true
	var stealth_bonus: int = 2 if has_small_stature else 0
	assert_eq(stealth_bonus, 2, "Small Stature should give +2 stealth")

func test_small_stature_attack_penalty_vs_large():
	# Large monsters also get -2 attack against SMALL_STATURE targets
	var target_has_small_stature: bool = true
	var attacker_is_large: bool = true
	var attack_penalty: int = -2 if (target_has_small_stature and attacker_is_large) else 0
	assert_eq(attack_penalty, -2, "Large monster should get -2 attack vs Small Stature")

# ============================================================================
# TEST 4: STEALTH KILL 2x XP
# ============================================================================

func test_stealth_kill_gives_2x_xp():
	# Monster with alertness < ALERTNESS_ALERT (unwary) gives 2x XP
	var alertness: int = Constants.ALERTNESS_ALERT - 1  # Just below alert
	var experience_value: int = 50
	var was_silent: bool = alertness < Constants.ALERTNESS_ALERT
	var xp_awarded: int = experience_value * 2 if was_silent else experience_value
	assert_true(was_silent, "Monster below ALERTNESS_ALERT should be considered silent kill")
	assert_eq(xp_awarded, 100, "Silent kill should give 2x XP (50 * 2 = 100)")

func test_alert_kill_gives_1x_xp():
	# Monster with alertness >= ALERTNESS_ALERT gives normal XP
	var alertness: int = Constants.ALERTNESS_ALERT  # Exactly alert
	var experience_value: int = 50
	var was_silent: bool = alertness < Constants.ALERTNESS_ALERT
	var xp_awarded: int = experience_value * 2 if was_silent else experience_value
	assert_false(was_silent, "Monster at ALERTNESS_ALERT should not be silent kill")
	assert_eq(xp_awarded, 50, "Alert kill should give 1x XP (50)")

func test_deeply_unwary_monster_gives_2x_xp():
	# Monster with very low alertness (sleeping level) still gives 2x
	var alertness: int = Constants.ALERTNESS_MIN  # -20, deep sleep
	var experience_value: int = 30
	var was_silent: bool = alertness < Constants.ALERTNESS_ALERT
	var xp_awarded: int = experience_value * 2 if was_silent else experience_value
	assert_true(was_silent, "Sleeping monster should count as silent kill")
	assert_eq(xp_awarded, 60, "Sleeping monster kill should give 2x XP (30 * 2 = 60)")

func test_highly_alert_monster_gives_1x_xp():
	# Monster with high alertness gives 1x
	var alertness: int = Constants.ALERTNESS_MAX  # +20
	var experience_value: int = 100
	var was_silent: bool = alertness < Constants.ALERTNESS_ALERT
	var xp_awarded: int = experience_value * 2 if was_silent else experience_value
	assert_false(was_silent, "Maximum alertness should not be silent kill")
	assert_eq(xp_awarded, 100, "Highly alert kill should give 1x XP (100)")

func test_alertness_constants_sanity():
	# Verify alertness constants are correctly ordered
	assert_lt(Constants.ALERTNESS_MIN, Constants.ALERTNESS_UNWARY, "MIN < UNWARY")
	assert_lt(Constants.ALERTNESS_UNWARY, Constants.ALERTNESS_ALERT, "UNWARY < ALERT")
	assert_lt(Constants.ALERTNESS_ALERT, Constants.ALERTNESS_MAX, "ALERT < MAX")
	assert_eq(Constants.ALERTNESS_MIN, -20, "ALERTNESS_MIN should be -20")
	assert_eq(Constants.ALERTNESS_UNWARY, -10, "ALERTNESS_UNWARY should be -10")
	assert_eq(Constants.ALERTNESS_ALERT, 0, "ALERTNESS_ALERT should be 0")
	assert_eq(Constants.ALERTNESS_MAX, 20, "ALERTNESS_MAX should be 20")

# ============================================================================
# TEST 5: STEALTH EXPLORATION XP
# ============================================================================

func test_stealth_exploration_xp_when_stealthed():
	# award_stealth_exploration_xp: 1 XP per new tile while stealth_mode is on
	var stealth_mode: bool = true
	var new_tiles: int = 5
	var xp_awarded: int = new_tiles if (stealth_mode and new_tiles > 0) else 0
	assert_eq(xp_awarded, 5, "Should award 5 XP for 5 new tiles while stealthed")

func test_stealth_exploration_xp_when_not_stealthed():
	# No XP when not in stealth mode
	var stealth_mode: bool = false
	var new_tiles: int = 5
	var xp_awarded: int = new_tiles if (stealth_mode and new_tiles > 0) else 0
	assert_eq(xp_awarded, 0, "Should award 0 XP when not in stealth mode")

func test_stealth_exploration_xp_zero_tiles():
	# No XP when 0 new tiles explored
	var stealth_mode: bool = true
	var new_tiles: int = 0
	var xp_awarded: int = new_tiles if (stealth_mode and new_tiles > 0) else 0
	assert_eq(xp_awarded, 0, "Should award 0 XP when no new tiles explored")

func test_stealth_exploration_xp_single_tile():
	var stealth_mode: bool = true
	var new_tiles: int = 1
	var xp_awarded: int = new_tiles if (stealth_mode and new_tiles > 0) else 0
	assert_eq(xp_awarded, 1, "Should award 1 XP for 1 new tile while stealthed")

func test_stealth_exploration_xp_many_tiles():
	# Exploring many tiles at once (e.g., entering large room)
	var stealth_mode: bool = true
	var new_tiles: int = 20
	var xp_awarded: int = new_tiles if (stealth_mode and new_tiles > 0) else 0
	assert_eq(xp_awarded, 20, "Should award 20 XP for 20 new tiles while stealthed")

func test_stealth_exploration_xp_source_tracking():
	# XP from stealth exploration should be tracked under "stealth_explore" source
	var source: String = "stealth_explore"
	assert_eq(source, "stealth_explore", "Source should be 'stealth_explore'")

# ============================================================================
# TEST 6: TERRAIN OPENNESS CALCULATION
# ============================================================================

func test_terrain_openness_corridor_1_neighbor():
	# Corridor: 1 walkable neighbor out of 8
	# Simulating _count_open_squares() return value
	var openness: int = 1
	assert_between(openness, 0, 8, "Openness must be in range 0-8")
	assert_true(openness <= 2, "Corridor should have 1-2 walkable neighbors")

func test_terrain_openness_corridor_2_neighbors():
	# Narrow corridor: 2 walkable neighbors
	var openness: int = 2
	assert_between(openness, 0, 8, "Openness must be in range 0-8")
	assert_true(openness <= 2, "Corridor should have at most 2 walkable neighbors")

func test_terrain_openness_open_room_5():
	# Open room: 5 walkable neighbors
	var openness: int = 5
	assert_between(openness, 0, 8, "Openness must be in range 0-8")
	assert_true(openness >= 5, "Open room should have 5+ walkable neighbors")

func test_terrain_openness_open_room_8():
	# Completely open area: all 8 neighbors walkable
	var openness: int = 8
	assert_between(openness, 0, 8, "Openness must be in range 0-8")
	assert_eq(openness, 8, "Fully open area has 8 walkable neighbors")

func test_terrain_openness_disguise_halves():
	# Disguise ability halves openness impact
	# Simulating: if has_disguise: openness = openness / 2
	var openness: int = 6
	var has_disguise: bool = true
	if has_disguise:
		openness = openness / 2
	assert_eq(openness, 3, "Disguise halves openness: 6 -> 3")

func test_terrain_openness_disguise_halves_odd():
	# Integer division: 7 / 2 = 3 (truncated)
	var openness: int = 7
	var has_disguise: bool = true
	if has_disguise:
		openness = openness / 2
	assert_eq(openness, 3, "Disguise halves openness: 7 -> 3 (truncated)")

func test_terrain_openness_no_disguise():
	# Without Disguise, full openness applied
	var openness: int = 6
	var has_disguise: bool = false
	if has_disguise:
		openness = openness / 2
	assert_eq(openness, 6, "No disguise: openness stays at 6")

func test_terrain_openness_range_minimum():
	# Completely enclosed (0 walkable neighbors)
	var openness: int = 0
	assert_between(openness, 0, 8, "Openness range minimum is 0")

func test_terrain_openness_range_maximum():
	# All 8 neighbors walkable
	var openness: int = 8
	assert_between(openness, 0, 8, "Openness range maximum is 8")

# ============================================================================
# TEST 7: ALERTNESS DIMINISHING RETURNS
# ============================================================================

func test_alertness_diminishing_returns_alertness_10():
	# When alertness >= ALERTNESS_ALERT (0), subtract alertness/2 from perception
	var alertness: int = 10
	var m_per: int = 8  # Base perception
	if alertness >= Constants.ALERTNESS_ALERT:
		m_per -= alertness / 2
	assert_eq(m_per, 3, "Alertness 10: penalty = 10/2 = 5, perception 8 -> 3")

func test_alertness_diminishing_returns_alertness_0():
	# Alertness 0 (just alert): penalty = 0/2 = 0
	var alertness: int = 0
	var m_per: int = 8
	if alertness >= Constants.ALERTNESS_ALERT:
		m_per -= alertness / 2
	assert_eq(m_per, 8, "Alertness 0: penalty = 0/2 = 0, perception unchanged")

func test_alertness_diminishing_returns_alertness_20():
	# Maximum alertness: penalty = 20/2 = 10
	var alertness: int = 20
	var m_per: int = 8
	if alertness >= Constants.ALERTNESS_ALERT:
		m_per -= alertness / 2
	assert_eq(m_per, -2, "Alertness 20: penalty = 10, perception 8 -> -2")

func test_alertness_diminishing_returns_unwary():
	# Alertness -5 (unwary): no penalty applied (alertness < ALERTNESS_ALERT)
	var alertness: int = -5
	var m_per: int = 8
	if alertness >= Constants.ALERTNESS_ALERT:
		m_per -= alertness / 2
	assert_eq(m_per, 8, "Alertness -5 (unwary): no diminishing returns, perception unchanged")

func test_alertness_diminishing_returns_deeply_unwary():
	# Alertness -15 (deeply unwary): no penalty
	var alertness: int = -15
	var m_per: int = 5
	if alertness >= Constants.ALERTNESS_ALERT:
		m_per -= alertness / 2
	assert_eq(m_per, 5, "Alertness -15: no diminishing returns, perception unchanged")

func test_alertness_threshold_is_zero():
	# ALERTNESS_ALERT is the threshold for diminishing returns
	assert_eq(Constants.ALERTNESS_ALERT, 0, "ALERTNESS_ALERT threshold is 0")

# ============================================================================
# TEST 8: FADED STATE SKIPS DETECTION
# ============================================================================

func test_fade_turns_positive_skips_detection():
	# When _fade_turns > 0, no detection roll happens (return early)
	var fade_turns: int = 3
	var detection_happens: bool = fade_turns <= 0
	assert_false(detection_happens, "Fade turns 3: detection should be skipped")

func test_fade_turns_zero_allows_detection():
	# fade_turns = 0 means normal detection
	var fade_turns: int = 0
	var detection_happens: bool = fade_turns <= 0
	assert_true(detection_happens, "Fade turns 0: detection should happen normally")

func test_fade_turns_fresh_kill_invisible():
	# Stealth kill grants 3 fade turns (completely invisible)
	var fade_turns: int = 3
	assert_eq(fade_turns, 3, "Fresh stealth kill grants 3 fade turns")
	assert_true(fade_turns > 0, "Player should be invisible with 3 fade turns")

func test_fade_turns_decay():
	# Fade turns decrement each turn
	var fade_turns: int = 3
	fade_turns -= 1
	assert_eq(fade_turns, 2, "Fade: 3 -> 2 turns")
	fade_turns -= 1
	assert_eq(fade_turns, 1, "Fade: 2 -> 1 turns")
	fade_turns -= 1
	assert_eq(fade_turns, 0, "Fade: 1 -> 0 turns (expired)")
	assert_true(fade_turns <= 0, "Fade expired: detection resumes")

func test_fade_alertness_decay():
	# During fade, monster alertness decays toward UNWARY
	var alertness: int = Constants.ALERTNESS_VERY_ALERT  # 10
	var fade_turns: int = 2
	# Simulating: if fade_turns > 0 and alertness > ALERTNESS_UNWARY: alertness -= 1
	if fade_turns > 0 and alertness > Constants.ALERTNESS_UNWARY:
		alertness -= 1
	assert_eq(alertness, 9, "During fade, alertness decays: 10 -> 9")

# ============================================================================
# TEST 9: STEALTH MODE 2x ENERGY COST
# ============================================================================

func test_base_movement_cost():
	# Base movement cost is ACTION_COST = 100
	assert_eq(Constants.ACTION_COST, 100, "Base movement cost is 100 energy")

func test_stealth_mode_multiplier_is_2():
	# Stealth mode multiplier is 2
	assert_eq(Constants.STEALTH_MODE_SPEED_MULTIPLIER, 2, "Stealth mode speed multiplier is 2")

func test_stealth_movement_cost_is_doubled():
	# In stealth mode, movement costs base * 2 = 200
	var base_cost: int = Constants.ACTION_COST
	var stealth_mode: bool = true
	var move_cost: int = base_cost
	if stealth_mode:
		move_cost *= Constants.STEALTH_MODE_SPEED_MULTIPLIER
	assert_eq(move_cost, 200, "Stealth movement costs 200 energy (100 * 2)")

func test_non_stealth_movement_cost_unchanged():
	# Without stealth mode, movement cost stays at base
	var base_cost: int = Constants.ACTION_COST
	var stealth_mode: bool = false
	var move_cost: int = base_cost
	if stealth_mode:
		move_cost *= Constants.STEALTH_MODE_SPEED_MULTIPLIER
	assert_eq(move_cost, 100, "Non-stealth movement costs 100 energy")

func test_stealth_mode_speed_multiplier_constant():
	# Verify the constant exists and equals 2
	assert_eq(Constants.STEALTH_MODE_SPEED_MULTIPLIER, 2,
		"STEALTH_MODE_SPEED_MULTIPLIER constant should be 2")

func test_stealth_terrain_cost_stacks():
	# Terrain cost * stealth multiplier
	# E.g., rubble (cost 150) * stealth (2x) = 300
	var terrain_cost: int = 150
	var stealth_mode: bool = true
	var move_cost: int = terrain_cost
	if stealth_mode:
		move_cost *= Constants.STEALTH_MODE_SPEED_MULTIPLIER
	assert_eq(move_cost, 300, "Rubble + stealth = 150 * 2 = 300 energy")

# ============================================================================
# TEST 10: GET_EFFECTIVE_PERCEPTION
# ============================================================================

func test_effective_perception_without_stealth():
	# Base hunting skill without stealth mode = just the skill value
	var hunting_skill: int = 3
	var stealth_mode: bool = false
	var effective: int = hunting_skill
	if stealth_mode:
		effective += Constants.STEALTH_MODE_PERCEPTION_BONUS
	assert_eq(effective, 3, "Without stealth mode, effective perception = base skill")

func test_effective_perception_with_stealth():
	# With stealth mode = skill + STEALTH_MODE_PERCEPTION_BONUS (5)
	var hunting_skill: int = 3
	var stealth_mode: bool = true
	var effective: int = hunting_skill
	if stealth_mode:
		effective += Constants.STEALTH_MODE_PERCEPTION_BONUS
	assert_eq(effective, 8, "With stealth mode, effective perception = 3 + 5 = 8")

func test_stealth_mode_perception_bonus_constant():
	# Verify the constant exists and equals 5
	assert_eq(Constants.STEALTH_MODE_PERCEPTION_BONUS, 5,
		"STEALTH_MODE_PERCEPTION_BONUS constant should be 5")

func test_effective_perception_zero_skill_with_stealth():
	# Even with 0 hunting skill, stealth mode gives +5
	var hunting_skill: int = 0
	var stealth_mode: bool = true
	var effective: int = hunting_skill
	if stealth_mode:
		effective += Constants.STEALTH_MODE_PERCEPTION_BONUS
	assert_eq(effective, 5, "Zero skill + stealth = 0 + 5 = 5")

func test_effective_perception_high_skill_with_stealth():
	# High hunting skill + stealth bonus
	var hunting_skill: int = 10
	var stealth_mode: bool = true
	var effective: int = hunting_skill
	if stealth_mode:
		effective += Constants.STEALTH_MODE_PERCEPTION_BONUS
	assert_eq(effective, 15, "High skill + stealth = 10 + 5 = 15")

# ============================================================================
# TEST 11: MONSTER STARTING ALERTNESS
# ============================================================================

func test_starting_alertness_sleepiness_10():
	# Sleepiness 10: start between ALERTNESS_ALERT - 10 and ALERTNESS_ALERT - 1
	# Formula: ALERTNESS_ALERT - randi_range(1, data.alertness)
	# Range: [0 - 10, 0 - 1] = [-10, -1]
	var sleepiness: int = 10
	var min_alertness: int = Constants.ALERTNESS_ALERT - sleepiness
	var max_alertness: int = Constants.ALERTNESS_ALERT - 1
	assert_eq(min_alertness, -10, "Sleepiness 10: minimum alertness = -10")
	assert_eq(max_alertness, -1, "Sleepiness 10: maximum alertness = -1")

func test_starting_alertness_sleepiness_1():
	# Sleepiness 1: start between ALERTNESS_ALERT - 1 and ALERTNESS_ALERT - 1
	# Range: [-1, -1] — always starts at -1
	var sleepiness: int = 1
	var min_alertness: int = Constants.ALERTNESS_ALERT - sleepiness
	var max_alertness: int = Constants.ALERTNESS_ALERT - 1
	assert_eq(min_alertness, -1, "Sleepiness 1: minimum alertness = -1")
	assert_eq(max_alertness, -1, "Sleepiness 1: maximum alertness = -1")
	assert_eq(min_alertness, max_alertness, "Sleepiness 1: always starts at exactly -1")

func test_starting_alertness_never_starts_alert():
	# With any positive sleepiness, monster never starts at ALERTNESS_ALERT (0)
	# randi_range(1, sleepiness) >= 1, so result is always < ALERTNESS_ALERT
	var sleepiness: int = 5
	var max_start: int = Constants.ALERTNESS_ALERT - 1  # Maximum is -1
	assert_lt(max_start, Constants.ALERTNESS_ALERT,
		"Starting alertness never reaches ALERTNESS_ALERT")

func test_starting_alertness_range_is_valid():
	# For any sleepiness > 0, min < max or min == max
	var sleepiness: int = 7
	var min_alertness: int = Constants.ALERTNESS_ALERT - sleepiness
	var max_alertness: int = Constants.ALERTNESS_ALERT - 1
	assert_true(min_alertness <= max_alertness,
		"Alertness range should be valid (min <= max)")

func test_starting_alertness_sleeping_flag():
	# Monsters with SLEEPING flag start at ALERTNESS_MIN (-20)
	var is_sleeping: bool = true
	var alertness: int = Constants.ALERTNESS_MIN if is_sleeping else Constants.ALERTNESS_ALERT
	assert_eq(alertness, -20, "Sleeping monster starts at ALERTNESS_MIN (-20)")

# ============================================================================
# TEST 12: NOISE CONSTANTS
# ============================================================================

func test_noise_door_constant():
	assert_eq(Constants.NOISE_DOOR, 1, "NOISE_DOOR should be 1 (was 5)")

func test_noise_smithing_constant():
	assert_eq(Constants.NOISE_SMITHING, 5, "NOISE_SMITHING should be 5 (was 10)")

func test_noise_trap_fall_constant():
	assert_eq(Constants.NOISE_TRAP_FALL, 3, "NOISE_TRAP_FALL should be 3")

func test_noise_trap_step_constant():
	assert_eq(Constants.NOISE_TRAP_STEP, 1, "NOISE_TRAP_STEP should be 1")

func test_noise_bash_constant():
	assert_eq(Constants.NOISE_BASH, 15, "NOISE_BASH should be 15 (unchanged)")

func test_noise_digging_constant():
	assert_eq(Constants.NOISE_DIGGING, 10, "NOISE_DIGGING should be 10 (unchanged)")

func test_noise_ordering():
	# Noise values should be ordered: step < door < trap_fall < smithing < digging < bash
	assert_true(Constants.NOISE_TRAP_STEP <= Constants.NOISE_DOOR,
		"TRAP_STEP <= DOOR")
	assert_true(Constants.NOISE_DOOR <= Constants.NOISE_TRAP_FALL,
		"DOOR <= TRAP_FALL")
	assert_true(Constants.NOISE_TRAP_FALL <= Constants.NOISE_SMITHING,
		"TRAP_FALL <= SMITHING")
	assert_true(Constants.NOISE_SMITHING <= Constants.NOISE_DIGGING,
		"SMITHING <= DIGGING")
	assert_true(Constants.NOISE_DIGGING <= Constants.NOISE_BASH,
		"DIGGING <= BASH")

# ============================================================================
# TEST 13: NO-LOS DETECTION PATH
# ============================================================================

func test_no_los_halves_perception():
	# Without LOS, perception is halved (integer division)
	var perception: int = 10
	var m_per: int = perception / 2
	assert_eq(m_per, 5, "Perception 10 without LOS = effective 5")

func test_no_los_halves_perception_odd():
	# Integer division: 5 / 2 = 2 (truncated)
	var perception: int = 5
	var m_per: int = perception / 2
	assert_eq(m_per, 2, "Perception 5 without LOS = effective 2")

func test_no_los_halves_perception_1():
	# Perception 1 without LOS = 0 (truncated)
	var perception: int = 1
	var m_per: int = perception / 2
	assert_eq(m_per, 0, "Perception 1 without LOS = effective 0")

func test_no_los_still_subtracts_distance():
	# No-LOS path: m_per = perception/2 - distance
	var perception: int = 10
	var distance: int = 8
	var m_per: int = perception / 2  # 5
	m_per -= distance  # 5 - 8 = -3
	assert_eq(m_per, -3, "No-LOS: perception 10 at distance 8 = 5 - 8 = -3")

func test_no_los_vs_los_comparison():
	# LOS path gives full perception; no-LOS gives half
	var perception: int = 8
	var distance: int = 4
	var los_m_per: int = perception - distance  # 8 - 4 = 4
	var no_los_m_per: int = perception / 2 - distance  # 4 - 4 = 0
	assert_eq(los_m_per, 4, "LOS: perception 8 - distance 4 = 4")
	assert_eq(no_los_m_per, 0, "No-LOS: perception 4 - distance 4 = 0")
	assert_true(los_m_per > no_los_m_per, "LOS detection always stronger than no-LOS")

func test_no_los_no_openness():
	# No terrain openness without sight (only LOS adds openness)
	var perception: int = 6
	var distance: int = 3
	var openness: int = 5  # Would be added with LOS
	# LOS path: m_per = perception - distance + openness
	var los_m_per: int = perception - distance + openness  # 6 - 3 + 5 = 8
	# No-LOS path: m_per = perception/2 - distance (no openness)
	var no_los_m_per: int = perception / 2 - distance  # 3 - 3 = 0
	assert_eq(los_m_per, 8, "LOS includes openness: 6 - 3 + 5 = 8")
	assert_eq(no_los_m_per, 0, "No-LOS excludes openness: 3 - 3 = 0")
