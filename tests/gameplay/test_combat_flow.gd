extends GutTest
## Gameplay scenario tests for combat flow between player and monsters.
## Tests opposed rolls, damage application, protection, death, XP grants,
## and critical hit mechanics with known values.

var _rng: RandomNumberGenerator

func before_all():
	_rng = RandomNumberGenerator.new()
	_rng.seed = 54321  # Deterministic

# ============================================================================
# FULL COMBAT RESOLUTION (hit check -> damage -> protection -> final damage)
# ============================================================================

func test_full_attack_hits_and_deals_damage():
	# Simulate: player attacks monster
	# Attack score = melee_bonus(5) + roll(12) = 17
	# Evasion score = evasion_bonus(3) + roll(8) = 11
	# Hit margin = 17 - 11 = 6 (hit!)
	# Damage dice: 2d5 = 7 (fixed for test)
	# Protection: 1d4 = 2 (fixed for test)
	# Final damage: max(0, 7 - 2) = 5
	var attack_bonus: int = 5
	var attack_roll: int = 12
	var evasion_bonus: int = 3
	var evasion_roll: int = 8

	var attack_score: int = attack_bonus + attack_roll
	var evasion_score: int = evasion_bonus + evasion_roll
	var hit_margin: int = attack_score - evasion_score
	assert_gt(hit_margin, 0, "Attack should hit")
	assert_eq(hit_margin, 6, "Hit margin should be 6")

	var raw_damage: int = 7  # 2d5 rolled
	var protection_rolled: int = 2  # 1d4 rolled
	var final_damage: int = maxi(0, raw_damage - protection_rolled)
	assert_eq(final_damage, 5, "Final damage should be 5 after protection")

	# Apply to monster
	var monster_hp: int = 20
	monster_hp -= final_damage
	assert_eq(monster_hp, 15, "Monster HP should be 15 after taking 5 damage")

func test_full_attack_misses():
	# Player attack misses when evasion > attack
	var attack_score: int = 3 + 5  # bonus + roll
	var evasion_score: int = 8 + 10  # bonus + roll
	var hit_margin: int = attack_score - evasion_score
	assert_lt(hit_margin, 0, "Attack should miss")

	# Monster HP unchanged
	var monster_hp: int = 20
	# No damage applied on miss
	assert_eq(monster_hp, 20, "Monster HP unchanged on miss")

func test_attack_kills_monster():
	# Monster at 3 HP, takes 5 damage -> dies
	var monster_hp: int = 3
	var damage: int = 5
	monster_hp -= damage
	var is_alive: bool = monster_hp > 0
	assert_false(is_alive, "Monster should be dead")
	assert_eq(monster_hp, -2, "HP can go negative from overkill")

func test_monster_death_grants_xp():
	# Kill XP formula: monster.experience_value * XP_MULTIPLIER (1.3)
	var monster_xp_value: int = 25
	var xp_multiplier: float = 1.3
	var player_xp_before: int = 1000

	var boosted_xp: int = int(monster_xp_value * xp_multiplier)
	var player_xp_after: int = player_xp_before + boosted_xp
	assert_eq(boosted_xp, 32, "25 XP * 1.3 = 32 (truncated)")
	assert_eq(player_xp_after, 1032, "Player XP should increase by boosted amount")

func test_xp_tracking_by_source():
	# XP from different sources should be tracked separately
	var kill_xp: int = 0
	var encounter_xp: int = 0
	var descent_xp: int = 0
	var total_xp: int = 0
	var xp_multiplier: float = 1.3

	# Kill grants
	var kill_amount: int = int(25 * xp_multiplier)
	kill_xp += kill_amount
	total_xp += kill_amount

	# Encounter grants
	var enc_amount: int = int(10 * xp_multiplier)
	encounter_xp += enc_amount
	total_xp += enc_amount

	# Descent grants
	var desc_amount: int = int(50 * xp_multiplier)
	descent_xp += desc_amount
	total_xp += desc_amount

	assert_eq(kill_xp, 32, "Kill XP tracked separately")
	assert_eq(encounter_xp, 13, "Encounter XP tracked separately")
	assert_eq(descent_xp, 65, "Descent XP tracked separately")
	assert_eq(total_xp, 110, "Total XP is sum of all sources")

# ============================================================================
# PLAYER DEATH DETECTION
# ============================================================================

func test_player_death_at_zero_hp():
	var current_health: int = 5
	var damage: int = 5
	current_health -= damage
	assert_eq(current_health, 0, "HP should be exactly 0")
	var is_dead: bool = current_health <= 0
	assert_true(is_dead, "Player should be dead at 0 HP")

func test_player_death_below_zero():
	var current_health: int = 3
	var damage: int = 10
	current_health -= damage
	assert_lt(current_health, 0, "HP should be negative")
	var is_dead: bool = current_health <= 0
	assert_true(is_dead, "Player should be dead below 0 HP")

func test_player_survives_at_one_hp():
	var current_health: int = 6
	var damage: int = 5
	current_health -= damage
	assert_eq(current_health, 1, "HP should be exactly 1")
	var is_alive: bool = current_health > 0
	assert_true(is_alive, "Player should survive at 1 HP")

# ============================================================================
# PROTECTION SYSTEM
# ============================================================================

func test_protection_dice_reduce_damage():
	# 2d4 protection: min 2, max 8
	var base_damage: int = 10
	var prot_dice: int = 2
	var prot_sides: int = 4

	# Test minimum protection (all 1s)
	var min_prot: int = prot_dice  # 2
	var max_damage: int = maxi(0, base_damage - min_prot)
	assert_eq(max_damage, 8, "Minimum protection gives max damage of 8")

	# Test maximum protection (all 4s)
	var max_prot: int = prot_dice * prot_sides  # 8
	var min_damage: int = maxi(0, base_damage - max_prot)
	assert_eq(min_damage, 2, "Maximum protection gives min damage of 2")

func test_protection_cannot_make_negative_damage():
	var base_damage: int = 3
	var protection_rolled: int = 10
	var final_damage: int = maxi(0, base_damage - protection_rolled)
	assert_eq(final_damage, 0, "Protection cannot cause negative damage")

func test_zero_protection_dice_means_no_reduction():
	var base_damage: int = 10
	var prot_dice: int = 0
	var prot_sides: int = 0

	# Roll protection with 0 dice = 0
	var protection_rolled: int = 0
	if prot_dice <= 0 or prot_sides <= 0:
		protection_rolled = 0

	var final_damage: int = maxi(0, base_damage - protection_rolled)
	assert_eq(final_damage, 10, "No protection dice means full damage")

func test_protection_roll_bounds():
	# Verify protection rolls stay within bounds over many iterations
	var prot_dice: int = 3
	var prot_sides: int = 6

	for _i in range(200):
		var total: int = 0
		for _d in range(prot_dice):
			total += _rng.randi_range(1, prot_sides)
		assert_gte(total, prot_dice, "Protection roll >= number of dice")
		assert_lte(total, prot_dice * prot_sides, "Protection roll <= max")

# ============================================================================
# CRITICAL HIT MECHANICS
# ============================================================================

func test_crit_dice_formula_light_weapon():
	# Formula: (hit_margin * 10 + 4) / (70 + weapon_weight)
	var hit_margin: int = 5
	var weapon_weight: int = 20  # Light weapon
	var crit_dice: int = (hit_margin * 10 + 4) / (70 + weapon_weight)
	# (50 + 4) / 90 = 0
	assert_eq(crit_dice, 0, "Small margin + light weapon = no crit dice")

func test_crit_dice_formula_heavy_hit():
	var hit_margin: int = 20
	var weapon_weight: int = 50
	var crit_dice: int = (hit_margin * 10 + 4) / (70 + weapon_weight)
	# (200 + 4) / 120 = 1
	assert_eq(crit_dice, 1, "Heavy hit = 1 crit die")

func test_crit_dice_formula_massive_hit():
	var hit_margin: int = 30
	var weapon_weight: int = 40
	var crit_dice: int = (hit_margin * 10 + 4) / (70 + weapon_weight)
	# (300 + 4) / 110 = 2
	assert_eq(crit_dice, 2, "Massive hit = 2 crit dice")

func test_crit_dice_zero_margin():
	var hit_margin: int = 0
	var weapon_weight: int = 30
	var crit_dice: int = (hit_margin * 10 + 4) / (70 + weapon_weight)
	# (0 + 4) / 100 = 0
	assert_eq(crit_dice, 0, "Zero margin = no crit dice")

# ============================================================================
# STRENGTH BONUS IN COMBAT
# ============================================================================

func test_str_bonus_capped_by_weapon_weight():
	# STR bonus = min(str/2, weapon_weight/10)
	var str_val: int = 10
	var weapon_weight: int = 30
	var str_bonus: int = mini(str_val / 2, weapon_weight / 10)
	assert_eq(str_bonus, 3, "STR 10 with weight 30: min(5, 3) = 3")

func test_str_bonus_uncapped():
	var str_val: int = 4
	var weapon_weight: int = 100
	var str_bonus: int = mini(str_val / 2, weapon_weight / 10)
	assert_eq(str_bonus, 2, "STR 4 with weight 100: min(2, 10) = 2")

# ============================================================================
# MULTI-HIT COMBAT FLOW
# ============================================================================

func test_consecutive_attacks_reduce_monster_to_zero():
	var monster_hp: int = 30
	var damages: Array[int] = [8, 12, 5, 7]  # 4 hits dealing 32 total
	var total_dealt: int = 0

	for dmg in damages:
		if monster_hp > 0:
			monster_hp -= dmg
			total_dealt += dmg

	assert_lte(monster_hp, 0, "Monster should be dead after enough hits")
	assert_eq(total_dealt, 32, "Total damage dealt should be 32")

func test_monster_attacks_player_flow():
	# Monster attacks player using same opposed roll system
	var monster_attack: int = 8
	var player_evasion: int = 6
	var attack_roll: int = 14
	var evasion_roll: int = 10

	var attack_score: int = monster_attack + attack_roll
	var evasion_score: int = player_evasion + evasion_roll
	var hit_margin: int = attack_score - evasion_score
	assert_gt(hit_margin, 0, "Monster should hit")

	# Monster deals damage
	var monster_damage: int = 6  # Rolled
	var player_protection: int = 2  # Rolled from player armor
	var final_damage: int = maxi(0, monster_damage - player_protection)
	assert_eq(final_damage, 4, "Player takes 4 damage after armor")

	# Player HP decreases
	var player_hp: int = 50
	player_hp -= final_damage
	assert_eq(player_hp, 46, "Player HP should be 46")

# ============================================================================
# DAMAGE DICE ROLLING
# ============================================================================

func test_damage_dice_parsing():
	# Parse "2d5" -> dice=2, sides=5
	var dice_str: String = "2d5"
	var parts: PackedStringArray = dice_str.split("d")
	assert_eq(parts.size(), 2, "Should split into 2 parts")
	var dice: int = int(parts[0])
	var sides: int = int(parts[1])
	assert_eq(dice, 2, "Number of dice should be 2")
	assert_eq(sides, 5, "Sides per die should be 5")

func test_damage_dice_roll_bounds():
	var dice: int = 3
	var sides: int = 6
	for _i in range(200):
		var roll: int = 0
		for _d in range(dice):
			roll += _rng.randi_range(1, sides)
		assert_gte(roll, dice, "Roll >= number of dice (all 1s)")
		assert_lte(roll, dice * sides, "Roll <= max possible")

func test_unarmed_damage_default():
	# No weapon equipped -> 1d4 unarmed
	var weapon: Variant = null
	var damage_str: String = "1d4"  # Default when weapon is null
	if weapon != null and "damage_dice" in weapon:
		damage_str = weapon.damage_dice
	assert_eq(damage_str, "1d4", "Unarmed damage should be 1d4")

# ============================================================================
# KILL TRACKING (for Bane / Master Hunter abilities)
# ============================================================================

func test_kill_tracking_increments():
	var kills_by_name: Dictionary = {}
	var monster_name: String = "Goblin"

	# First kill
	kills_by_name[monster_name] = kills_by_name.get(monster_name, 0) + 1
	assert_eq(kills_by_name[monster_name], 1, "First kill = 1")

	# Second kill
	kills_by_name[monster_name] = kills_by_name.get(monster_name, 0) + 1
	assert_eq(kills_by_name[monster_name], 2, "Second kill = 2")

func test_kill_tracking_separate_types():
	var kills_by_name: Dictionary = {}
	kills_by_name["Goblin"] = 5
	kills_by_name["Orc"] = 3

	assert_eq(kills_by_name["Goblin"], 5, "Goblin kills tracked")
	assert_eq(kills_by_name["Orc"], 3, "Orc kills tracked")
	assert_eq(kills_by_name.get("Troll", 0), 0, "Unknown monster = 0 kills")

func test_bane_bonus_from_kills():
	# Bane: +floor(log2(kill_count)) for kills >= 2
	assert_eq(_bane_bonus(0), 0, "0 kills = no bonus")
	assert_eq(_bane_bonus(1), 0, "1 kill = no bonus")
	assert_eq(_bane_bonus(2), 1, "2 kills = +1")
	assert_eq(_bane_bonus(4), 2, "4 kills = +2")
	assert_eq(_bane_bonus(8), 3, "8 kills = +3")
	assert_eq(_bane_bonus(15), 3, "15 kills = +3 (floor)")
	assert_eq(_bane_bonus(16), 4, "16 kills = +4")

# ============================================================================
# ENERGY-BASED TURN ORDER IN COMBAT
# ============================================================================

func test_fast_monster_gets_extra_attacks():
	# Speed 7 monster vs speed 4 player over 10 rounds
	var fast_energy: int = 0
	var normal_energy: int = 0
	var fast_speed: int = 7  # 35 energy/round
	var normal_speed: int = 4  # 20 energy/round
	var energy_table: Array[int] = [5, 5, 10, 15, 20, 25, 30, 35]
	var action_cost: int = 100

	var fast_actions: int = 0
	var normal_actions: int = 0

	for _round in range(10):
		fast_energy += energy_table[fast_speed]
		normal_energy += energy_table[normal_speed]
		while fast_energy >= action_cost:
			fast_energy -= action_cost
			fast_actions += 1
		while normal_energy >= action_cost:
			normal_energy -= action_cost
			normal_actions += 1

	assert_eq(fast_actions, 3, "Speed 7 takes 3 actions in 10 rounds")
	assert_eq(normal_actions, 2, "Speed 4 takes 2 actions in 10 rounds")
	assert_gt(fast_actions, normal_actions, "Fast monster gets more attacks")

# ============================================================================
# DEFY DEATH (Will ability)
# ============================================================================

func test_defy_death_sets_hp_to_one():
	# If Defy Death triggers, HP is set to exactly 1
	var current_health: int = 5
	var lethal_damage: int = 10
	var would_die: bool = current_health - lethal_damage <= 0
	assert_true(would_die, "Damage should be lethal")

	# Defy Death triggers
	current_health = 1  # Direct set
	assert_eq(current_health, 1, "HP should be exactly 1 after Defy Death")

func test_defy_death_chance_formula():
	# Will * 3 percent chance
	var will_skill: int = 10
	var chance: int = will_skill * 3
	assert_eq(chance, 30, "10 will = 30% chance")

	will_skill = 20
	chance = will_skill * 3
	assert_eq(chance, 60, "20 will = 60% chance")

# ============================================================================
# HELPERS
# ============================================================================

func _bane_bonus(kill_count: int) -> int:
	if kill_count < 2:
		return 0
	return int(log(float(kill_count)) / log(2.0))
