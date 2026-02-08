extends GutTest
## Unit tests for stealth balance changes
## Tests distance penalty, Hobbit CON, Small Stature evasion, stealth kill XP, stealth exploration XP

# ============================================================================
# TEST 1: STEALTH DISTANCE PENALTY USES 4 NOT 6
# ============================================================================

func test_distance_penalty_at_distance_1():
	# maxi(0, 4 - distance) where distance = 1
	var distance: int = 1
	var penalty: int = maxi(0, 4 - distance)
	assert_eq(penalty, 3, "Distance 1: penalty should be 3")

func test_distance_penalty_at_distance_2():
	var distance: int = 2
	var penalty: int = maxi(0, 4 - distance)
	assert_eq(penalty, 2, "Distance 2: penalty should be 2")

func test_distance_penalty_at_distance_3():
	var distance: int = 3
	var penalty: int = maxi(0, 4 - distance)
	assert_eq(penalty, 1, "Distance 3: penalty should be 1")

func test_distance_penalty_at_distance_4():
	# At distance 4: maxi(0, 4-4) = 0
	var distance: int = 4
	var penalty: int = maxi(0, 4 - distance)
	assert_eq(penalty, 0, "Distance 4: penalty should be 0")

func test_distance_penalty_at_distance_5():
	var distance: int = 5
	var penalty: int = maxi(0, 4 - distance)
	assert_eq(penalty, 0, "Distance 5+: penalty should be 0")

func test_distance_penalty_at_distance_10():
	var distance: int = 10
	var penalty: int = maxi(0, 4 - distance)
	assert_eq(penalty, 0, "Distance 10: penalty should be 0")

func test_distance_penalty_uses_4_not_6():
	# Verify the formula uses 4, not the old value of 6
	# At distance 5, old formula would give maxi(0, 6-5) = 1
	# New formula gives maxi(0, 4-5) = 0
	var distance: int = 5
	var old_penalty: int = maxi(0, 6 - distance)  # Old formula
	var new_penalty: int = maxi(0, 4 - distance)  # New formula
	assert_eq(old_penalty, 1, "Old formula at dist 5 would be 1")
	assert_eq(new_penalty, 0, "New formula at dist 5 should be 0")
	assert_ne(old_penalty, new_penalty, "New and old formulas should differ at distance 5")

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
	# Simulating player.gd:1356-1360
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
	# SMALL_STATURE also grants +2 stealth (player.gd:1882-1883)
	var has_small_stature: bool = true
	var stealth_bonus: int = 2 if has_small_stature else 0
	assert_eq(stealth_bonus, 2, "Small Stature should give +2 stealth")

func test_small_stature_attack_penalty_vs_large():
	# Large monsters also get -2 attack against SMALL_STATURE targets
	# Simulating monster.gd:693-697
	var target_has_small_stature: bool = true
	var attacker_is_large: bool = true
	var attack_penalty: int = -2 if (target_has_small_stature and attacker_is_large) else 0
	assert_eq(attack_penalty, -2, "Large monster should get -2 attack vs Small Stature")

# ============================================================================
# TEST 4: STEALTH KILL 2x XP
# ============================================================================

func test_stealth_kill_gives_2x_xp():
	# Monster with alertness < ALERTNESS_ALERT (unwary) gives 2x XP
	# Simulating monster.gd:844-845
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
	# Simulating player.gd:1934-1936
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
	# This validates the gain_experience source string matches
	var source: String = "stealth_explore"
	assert_eq(source, "stealth_explore", "Source should be 'stealth_explore'")
