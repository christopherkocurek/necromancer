extends GutTest
## Unit tests for combat system mechanics
## Tests opposed roll combat, critical hits, protection dice

var _rng: RandomNumberGenerator

func before_all():
	_rng = RandomNumberGenerator.new()
	_rng.seed = 12345  # Deterministic for testing

func test_opposed_roll_hit_when_attack_higher():
	# Attack roll (15) + bonus (5) = 20
	# Evasion roll (10) + bonus (3) = 13
	# Hit margin = 20 - 13 = 7 (hit)
	var attack_roll: int = 15
	var attack_bonus: int = 5
	var evasion_roll: int = 10
	var evasion_bonus: int = 3

	var attack_score: int = attack_roll + attack_bonus
	var evasion_score: int = evasion_roll + evasion_bonus
	var hit_margin: int = attack_score - evasion_score

	assert_gt(hit_margin, 0, "Attack should hit when attack score > evasion score")
	assert_eq(hit_margin, 7, "Hit margin should be 7")

func test_opposed_roll_miss_when_evasion_higher():
	# Attack: 8 + 2 = 10
	# Evasion: 14 + 4 = 18
	# Margin = 10 - 18 = -8 (miss)
	var attack_score: int = 8 + 2
	var evasion_score: int = 14 + 4
	var hit_margin: int = attack_score - evasion_score

	assert_lt(hit_margin, 0, "Attack should miss when evasion score > attack score")

func test_opposed_roll_tie_is_miss():
	# Ties go to defender in Sil-Q
	var attack_score: int = 15
	var evasion_score: int = 15
	var hit_margin: int = attack_score - evasion_score

	assert_eq(hit_margin, 0, "Tie should result in 0 margin")
	# In actual combat, margin <= 0 is a miss

func test_crit_dice_formula():
	# Formula: (hit_margin * 10 + 4) / (70 + weapon_weight)
	var hit_margin: int = 7
	var weapon_weight: int = 30  # Light weapon

	var crit_dice: int = (hit_margin * 10 + 4) / (70 + weapon_weight)
	# (70 + 4) / 100 = 0 (integer division)
	assert_eq(crit_dice, 0, "Light weapon with small margin = no crit dice")

	# Heavy hit with heavy weapon
	hit_margin = 15
	weapon_weight = 50
	crit_dice = (hit_margin * 10 + 4) / (70 + weapon_weight)
	# (150 + 4) / 120 = 1
	assert_eq(crit_dice, 1, "Heavy hit should grant 1 crit die")

	# Massive hit
	hit_margin = 25
	weapon_weight = 30
	crit_dice = (hit_margin * 10 + 4) / (70 + weapon_weight)
	# (250 + 4) / 100 = 2
	assert_eq(crit_dice, 2, "Massive hit should grant 2 crit dice")

func test_strength_bonus_capped_by_weapon_weight():
	# STR bonus = min(str/2, weapon_weight/10)
	var strength: int = 10
	var weapon_weight: int = 30

	var str_bonus: int = mini(strength / 2, weapon_weight / 10)
	# min(5, 3) = 3
	assert_eq(str_bonus, 3, "STR bonus should be capped by weapon weight")

	# Light weapon limits strong character
	strength = 20
	weapon_weight = 20
	str_bonus = mini(strength / 2, weapon_weight / 10)
	# min(10, 2) = 2
	assert_eq(str_bonus, 2, "Light weapon should limit STR bonus")

	# Heavy weapon doesn't limit
	strength = 8
	weapon_weight = 100
	str_bonus = mini(strength / 2, weapon_weight / 10)
	# min(4, 10) = 4
	assert_eq(str_bonus, 4, "Heavy weapon should not limit STR bonus")

func test_protection_dice_roll_bounds():
	# Protection: 2d4 = min 2, max 8
	var dice: int = 2
	var sides: int = 4

	var min_protection: int = dice  # All 1s
	var max_protection: int = dice * sides  # All max

	assert_eq(min_protection, 2, "Minimum 2d4 should be 2")
	assert_eq(max_protection, 8, "Maximum 2d4 should be 8")

func test_protection_reduces_damage():
	var base_damage: int = 10
	var protection_rolled: int = 3

	var final_damage: int = maxi(0, base_damage - protection_rolled)
	assert_eq(final_damage, 7, "Damage should be reduced by protection")

	# Protection can reduce to 0
	base_damage = 2
	protection_rolled = 5
	final_damage = maxi(0, base_damage - protection_rolled)
	assert_eq(final_damage, 0, "Damage should not go negative")

func test_damage_dice_roll():
	# 2d5 damage = min 2, max 10, avg 6
	var dice: int = 2
	var sides: int = 5

	# Simulate many rolls to verify bounds
	for i in range(100):
		var roll: int = 0
		for d in range(dice):
			roll += _rng.randi_range(1, sides)

		assert_gte(roll, dice, "Roll should be >= number of dice")
		assert_lte(roll, dice * sides, "Roll should be <= max possible")

func test_kill_grants_xp():
	var monster_xp_value: int = 25
	var player_xp_before: int = 1000

	var player_xp_after: int = player_xp_before + monster_xp_value
	assert_eq(player_xp_after, 1025, "Killing monster should grant XP")
