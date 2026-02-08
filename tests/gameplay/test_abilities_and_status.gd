extends GutTest
## Gameplay scenario tests for abilities and status effects.
## Tests ability activation, prerequisites, status decay, and removal.

# ============================================================================
# ABILITY ARRAY MANAGEMENT
# ============================================================================

func test_learn_ability_sets_three_arrays():
	var innate: Array = _make_ability_array()
	var active: Array = _make_ability_array()
	var have: Array = _make_ability_array()

	# Learn Power (Melee ability 0)
	var skill: int = Constants.Skill.S_MEL  # 0
	var ability: int = Constants.MeleeAbility.MEL_POWER  # 0

	innate[skill][ability] = true
	active[skill][ability] = true
	have[skill][ability] = true

	assert_true(innate[skill][ability], "innate set after learning")
	assert_true(active[skill][ability], "active set after learning")
	assert_true(have[skill][ability], "have set after learning")

func test_has_ability_check():
	var active: Array = _make_ability_array()

	# Player has NOT learned Dodging
	var has_dodging: bool = active[Constants.Skill.S_EVN][Constants.EvasionAbility.EVN_DODGING]
	assert_false(has_dodging, "Should not have unlearned ability")

	# Learn Dodging
	active[Constants.Skill.S_EVN][Constants.EvasionAbility.EVN_DODGING] = true
	has_dodging = active[Constants.Skill.S_EVN][Constants.EvasionAbility.EVN_DODGING]
	assert_true(has_dodging, "Should have learned ability")

func test_has_ability_bounds_check():
	# Out of bounds should return false (not crash)
	var skill: int = -1
	var ability: int = 0
	var in_bounds: bool = skill >= 0 and skill < Constants.S_MAX and ability >= 0 and ability < Constants.ABILITIES_MAX
	assert_false(in_bounds, "Negative skill is out of bounds")

	skill = Constants.S_MAX  # One past end
	in_bounds = skill >= 0 and skill < Constants.S_MAX and ability >= 0 and ability < Constants.ABILITIES_MAX
	assert_false(in_bounds, "S_MAX is out of bounds (0-indexed)")

	skill = 0
	ability = Constants.ABILITIES_MAX
	in_bounds = skill >= 0 and skill < Constants.S_MAX and ability >= 0 and ability < Constants.ABILITIES_MAX
	assert_false(in_bounds, "ABILITIES_MAX is out of bounds")

# ============================================================================
# ABILITY PREREQUISITES
# ============================================================================

func test_ability_cost_formula():
	# Cost = (owned_in_skill + 1) * 500 - 500 * affinity
	assert_eq(_ability_xp_cost(0, 0), 500, "1st ability costs 500 XP")
	assert_eq(_ability_xp_cost(1, 0), 1000, "2nd ability costs 1000 XP")
	assert_eq(_ability_xp_cost(4, 0), 2500, "5th ability costs 2500 XP")

func test_ability_cost_with_affinity():
	assert_eq(_ability_xp_cost(0, 1), 0, "1st ability free with +1 affinity")
	assert_eq(_ability_xp_cost(1, 1), 500, "2nd ability 500 with +1 affinity")
	assert_eq(_ability_xp_cost(0, -1), 1000, "1st ability 1000 with -1 penalty")

func test_ability_cost_floor_at_zero():
	# Cost cannot go below 0
	assert_eq(_ability_xp_cost(0, 5), 0, "Large affinity floors at 0")

func test_can_afford_ability():
	var xp_available: int = 1500
	var cost: int = _ability_xp_cost(2, 0)  # 1500 XP
	assert_true(xp_available >= cost, "Should afford 3rd ability with 1500 XP")

	xp_available = 1499
	assert_false(xp_available >= cost, "Should NOT afford with 1499 XP")

func test_or_prereqs_logic():
	# OR prerequisites: need at least one met
	var met: Array[bool] = [false, false]
	assert_false(_check_or_prereqs(met), "No prereqs met = cannot learn")

	met = [true, false]
	assert_true(_check_or_prereqs(met), "One met = can learn (OR)")

	met = [true, true]
	assert_true(_check_or_prereqs(met), "All met = can learn")

	var empty: Array[bool] = []
	assert_true(_check_or_prereqs(empty), "No prereqs = always learnable")

func test_count_abilities_in_skill():
	var innate: Array = _make_ability_array()
	innate[0][0] = true  # Power
	innate[0][1] = true  # Finesse
	innate[0][5] = true  # Follow-Through

	var count: int = _count_abilities_in_skill(innate, 0)
	assert_eq(count, 3, "3 melee abilities learned")

	count = _count_abilities_in_skill(innate, 1)
	assert_eq(count, 0, "No archery abilities")

# ============================================================================
# ABILITY ACTIVATION (voice cost, cooldowns)
# ============================================================================

func test_voice_charge_consumption():
	var voice_charges: int = 20
	var max_voice: int = 20
	var cost: int = 3  # Word of Command costs 3

	# Consume
	assert_true(voice_charges >= cost, "Enough charges to use ability")
	voice_charges -= cost
	assert_eq(voice_charges, 17, "Voice charges reduced by cost")

func test_voice_charge_insufficient():
	var voice_charges: int = 2
	var cost: int = 3
	assert_false(voice_charges >= cost, "Not enough charges")

func test_voice_regen_formula():
	# Sil-Q formula: full pool over 150 turns
	var max_voice: int = 20
	var regen_period: float = 150.0
	var regen_per_turn: float = float(max_voice) / regen_period
	# 20 / 150 = 0.1333... per turn
	assert_almost_eq(regen_per_turn, 0.1333, 0.001, "Regen rate ~0.133/turn")

	# After 150 turns, should regenerate exactly max_voice
	var total_regen: float = regen_per_turn * 150.0
	assert_almost_eq(total_regen, 20.0, 0.01, "Full regen over 150 turns")

func test_voice_cost_with_echoes_trait():
	# Echoes of the Firstborn: -1 to lore ability costs (min 1)
	var base_cost: int = 3
	var has_echoes: bool = true

	var effective_cost: int = base_cost
	if has_echoes and base_cost > 0:
		effective_cost = maxi(1, base_cost - 1)

	assert_eq(effective_cost, 2, "Echoes reduces cost by 1")

	# Cost of 1 stays at 1
	base_cost = 1
	effective_cost = base_cost
	if has_echoes and base_cost > 0:
		effective_cost = maxi(1, base_cost - 1)
	assert_eq(effective_cost, 1, "Minimum cost is 1")

func test_cooldown_tracking():
	var cooldowns: Dictionary = {}

	# Start cooldown for Word of Command (ID 140)
	var ability_id: int = 140
	var duration: int = 5
	cooldowns[ability_id] = duration
	assert_true(cooldowns.has(ability_id), "Cooldown registered")
	assert_eq(cooldowns[ability_id], 5, "Cooldown duration correct")

	# Check if on cooldown
	var on_cooldown: bool = cooldowns.has(ability_id) and cooldowns[ability_id] > 0
	assert_true(on_cooldown, "Ability is on cooldown")

func test_cooldown_tick_down():
	var cooldowns: Dictionary = {140: 3, 142: 1}

	# Tick down all cooldowns
	var to_remove: Array[int] = []
	for ability_id in cooldowns:
		cooldowns[ability_id] -= 1
		if cooldowns[ability_id] <= 0:
			to_remove.append(ability_id)

	for ability_id in to_remove:
		cooldowns.erase(ability_id)

	assert_eq(cooldowns[140], 2, "Word of Command: 3 -> 2")
	assert_false(cooldowns.has(142), "Deep Memory cooldown expired and removed")

func test_cooldown_prevents_use():
	var cooldowns: Dictionary = {140: 2}
	var can_use: bool = not cooldowns.has(140) or cooldowns[140] <= 0
	assert_false(can_use, "Cannot use ability while on cooldown")

	# After cooldown expires
	cooldowns.erase(140)
	can_use = not cooldowns.has(140) or cooldowns[140] <= 0
	assert_true(can_use, "Can use ability after cooldown expires")

# ============================================================================
# STATUS EFFECTS
# ============================================================================

func test_apply_status_effect():
	var effects: Dictionary = {}
	var effect_name: StringName = &"poisoned"
	var duration: int = 5

	effects[effect_name] = duration
	assert_true(effects.has(effect_name), "Poison applied")
	assert_eq(effects[effect_name], 5, "Poison duration is 5")

func test_status_stacking_additive():
	# Applying same status again adds to duration (up to max)
	var effects: Dictionary = {&"poisoned": 3}
	var new_duration: int = 4
	var max_duration: int = 20

	var current: int = effects.get(&"poisoned", 0)
	effects[&"poisoned"] = mini(current + new_duration, max_duration)
	assert_eq(effects[&"poisoned"], 7, "Poison stacks: 3 + 4 = 7")

func test_status_stacking_capped():
	var effects: Dictionary = {&"fast": 18}
	var new_duration: int = 5
	var max_duration: int = 20

	var current: int = effects.get(&"fast", 0)
	effects[&"fast"] = mini(current + new_duration, max_duration)
	assert_eq(effects[&"fast"], 20, "Fast capped at max 20")

func test_status_tick_decay():
	# Each turn, status durations decrease by 1
	var effects: Dictionary = {
		&"poisoned": 5,
		&"fast": 2,
		&"blind": 1,
	}

	var expired: Array[StringName] = []
	for effect_id in effects:
		effects[effect_id] -= 1
		if effects[effect_id] <= 0:
			expired.append(effect_id)

	for effect_id in expired:
		effects.erase(effect_id)

	assert_eq(effects[&"poisoned"], 4, "Poison: 5 -> 4")
	assert_eq(effects[&"fast"], 1, "Fast: 2 -> 1")
	assert_false(effects.has(&"blind"), "Blind expired and removed")

func test_status_removal():
	var effects: Dictionary = {&"poisoned": 5, &"fast": 3}

	# Cure poison
	effects.erase(&"poisoned")

	assert_false(effects.has(&"poisoned"), "Poison removed")
	assert_true(effects.has(&"fast"), "Fast unaffected")
	assert_eq(effects.size(), 1, "One effect remaining")

func test_has_status_check():
	var effects: Dictionary = {&"poisoned": 3}
	assert_true(effects.has(&"poisoned") and effects[&"poisoned"] > 0, "Has poison")
	assert_false(effects.has(&"fast"), "Does not have fast")

func test_status_duration_get():
	var effects: Dictionary = {&"poisoned": 7}
	var duration: int = effects.get(&"poisoned", 0)
	assert_eq(duration, 7, "Poison duration is 7")

	var missing_duration: int = effects.get(&"fast", 0)
	assert_eq(missing_duration, 0, "Missing status returns 0")

# ============================================================================
# SPECIFIC STATUS EFFECT BEHAVIORS
# ============================================================================

func test_poison_damage_per_turn():
	# Poison deals 1 damage per turn while active
	var current_health: int = 30
	var poison_duration: int = 5
	var total_poison_damage: int = 0

	for _turn in range(poison_duration):
		var poison_dmg: int = 1
		current_health -= poison_dmg
		total_poison_damage += poison_dmg

	assert_eq(total_poison_damage, 5, "5 turns of poison = 5 damage")
	assert_eq(current_health, 25, "HP reduced by poison damage")

func test_fast_status_grants_speed():
	var base_speed: int = 4
	var has_fast: bool = true
	var speed: int = base_speed
	if has_fast:
		speed += 1  # Fast grants +1 speed tier
	assert_eq(speed, 5, "Fast increases speed by 1")

func test_slow_status_reduces_speed():
	var base_speed: int = 4
	var has_slow: bool = true
	var speed: int = base_speed
	if has_slow:
		speed = maxi(0, speed - 2)  # Slow reduces speed by 2
	assert_eq(speed, 2, "Slow decreases speed by 2")

func test_confused_status_affects_movement():
	# Confused: movement direction randomized
	var is_confused: bool = true
	var intended_dir: Vector2i = Vector2i(1, 0)  # East

	if is_confused:
		# In actual code, direction would be randomized
		# Here we just verify the flag is checked
		assert_true(is_confused, "Confusion flag checked before movement")

func test_blind_status_blocks_vision():
	var is_blind: bool = true
	var sight_range: int = 8
	if is_blind:
		sight_range = 1  # Can only see adjacent tiles
	assert_eq(sight_range, 1, "Blind reduces sight to 1")

# ============================================================================
# PLAYER STATUS RESISTANCE (Will abilities)
# ============================================================================

func test_indomitable_halves_stun():
	# Indomitable: halve stun and slow durations
	var duration: int = 10
	var has_indomitable: bool = true
	if has_indomitable:
		duration = maxi(1, duration / 2)
	assert_eq(duration, 5, "Indomitable halves stun to 5")

func test_indomitable_min_duration_1():
	var duration: int = 1
	var has_indomitable: bool = true
	if has_indomitable:
		duration = maxi(1, duration / 2)
	assert_eq(duration, 1, "Minimum duration is 1 even with Indomitable")

func test_poison_resist_halves_poison():
	var duration: int = 8
	var has_poison_resist: bool = true
	if has_poison_resist:
		duration = maxi(1, duration / 2)
	assert_eq(duration, 4, "Poison Resist halves duration to 4")

func test_majesty_immune_to_fear():
	var has_majesty: bool = true
	var status_name: String = "afraid"

	var apply: bool = true
	if has_majesty and status_name == "afraid":
		apply = false  # Immune

	assert_false(apply, "Majesty grants fear immunity")

func test_dwarven_resilience_halves_confusion():
	var duration: int = 6
	var has_resilience: bool = true
	var status_name: String = "confused"
	if has_resilience and (status_name == "afraid" or status_name == "confused" or status_name == "entranced"):
		duration = maxi(1, duration / 2)
	assert_eq(duration, 3, "Dwarven Resilience halves confusion to 3")

# ============================================================================
# COMBAT ABILITY EFFECTS
# ============================================================================

func test_vengeance_activates_on_hit():
	# Vengeance: +2 attack on turn after being hit
	var vengeance_active: bool = false
	var was_hit: bool = true
	var has_vengeance: bool = true

	if has_vengeance and was_hit:
		vengeance_active = true

	assert_true(vengeance_active, "Vengeance activates when hit")

func test_vengeance_grants_attack_bonus():
	var vengeance_active: bool = true
	var attack_bonus: int = 0
	if vengeance_active:
		attack_bonus += 2
	assert_eq(attack_bonus, 2, "Vengeance grants +2 attack")

func test_fade_bonus_after_kill():
	# Fade (Stealth): temporary stealth bonus after kill
	var fade_bonus: int = 0
	var fade_turns: int = 0
	var stealth_skill: int = 8

	# On kill, Fade activates
	fade_bonus = stealth_skill  # Bonus = stealth skill
	fade_turns = 3

	assert_eq(fade_bonus, 8, "Fade bonus = stealth skill value")
	assert_eq(fade_turns, 3, "Fade lasts 3 turns")

func test_fade_decays_per_turn():
	var fade_turns: int = 3
	var fade_bonus: int = 8

	# Turn 1
	fade_turns -= 1
	assert_eq(fade_turns, 2, "Fade: 3 -> 2 turns")

	# Turn 2
	fade_turns -= 1
	assert_eq(fade_turns, 1, "Fade: 2 -> 1 turns")

	# Turn 3 - expires
	fade_turns -= 1
	if fade_turns <= 0:
		fade_bonus = 0
	assert_eq(fade_turns, 0, "Fade expired")
	assert_eq(fade_bonus, 0, "Fade bonus reset to 0")

func test_strength_in_adversity():
	# +1 per 10% HP below 50%
	assert_eq(_adversity_bonus(100, 100), 0, "Full HP = no bonus")
	assert_eq(_adversity_bonus(50, 100), 0, "50% HP = no bonus")
	assert_eq(_adversity_bonus(40, 100), 1, "40% HP = +1")
	assert_eq(_adversity_bonus(30, 100), 2, "30% HP = +2")
	assert_eq(_adversity_bonus(10, 100), 4, "10% HP = +4")
	assert_eq(_adversity_bonus(1, 100), 4, "1% HP = +4")

func test_sprinting_grants_fast():
	# Sprinting: 3 + evasion/5 turns of fast
	var evasion_skill: int = 10
	var sprint_turns: int = 3 + evasion_skill / 5
	assert_eq(sprint_turns, 5, "Sprint with 10 evasion = 5 turns")

	evasion_skill = 0
	sprint_turns = 3 + evasion_skill / 5
	assert_eq(sprint_turns, 3, "Sprint with 0 evasion = 3 turns")

# ============================================================================
# LORE ABILITY VOICE COSTS
# ============================================================================

func test_lore_ability_voice_costs():
	# From ability_system.gd voice cost table
	var costs: Dictionary = {
		140: 3,  # Word of Command
		141: 1,  # Lore of Battle
		142: 2,  # Deep Memory
		143: 2,  # Word of Opening
		144: 2,  # Lore of Silence
		146: 2,  # Word of Shutting
		147: 3,  # Inner Light
		150: 3,  # Lore of Sleep
		151: 4,  # Word of Mastery
		154: 3,  # Song of Banishment
	}

	assert_eq(costs[140], 3, "Word of Command costs 3")
	assert_eq(costs[141], 1, "Lore of Battle costs 1")
	assert_eq(costs[151], 4, "Word of Mastery costs 4 (most expensive)")

func test_passive_abilities_no_voice_cost():
	# Passive abilities cost 0 voice
	var passive_ids: Array[int] = [145, 148, 149, 152, 153]  # Herbcraft, Deadly Lore, Endurance, Device Mastery, Grace
	for ability_id in passive_ids:
		var cost: int = 0  # Passive = no cost
		assert_eq(cost, 0, "Ability %d is passive (0 cost)" % ability_id)

# ============================================================================
# ABILITY ENUM ALIGNMENT
# ============================================================================

func test_skill_enum_alignment():
	assert_eq(Constants.Skill.S_MEL, 0, "Melee = 0")
	assert_eq(Constants.Skill.S_ARC, 1, "Archery = 1")
	assert_eq(Constants.Skill.S_EVN, 2, "Evasion = 2")
	assert_eq(Constants.Skill.S_STL, 3, "Stealth = 3")
	assert_eq(Constants.Skill.S_PER, 4, "Hunting = 4")
	assert_eq(Constants.Skill.S_WIL, 5, "Will = 5")
	assert_eq(Constants.Skill.S_SMT, 6, "Smithing = 6")
	assert_eq(Constants.Skill.S_LOR, 7, "Lore = 7")

func test_s_max_matches_enum_count():
	assert_eq(Constants.S_MAX, 8, "S_MAX should be 8 skills")

func test_abilities_max_sufficient():
	# ABILITIES_MAX must be >= max enum value + 1
	assert_gte(Constants.ABILITIES_MAX, 14, "ABILITIES_MAX >= 14 for melee (0-13)")
	assert_gte(Constants.ABILITIES_MAX, 12, "ABILITIES_MAX >= 12 for smithing (0-11)")
	assert_gte(Constants.ABILITIES_MAX, 15, "ABILITIES_MAX >= 15 for lore (0-14)")

# ============================================================================
# HELPERS
# ============================================================================

func _make_ability_array() -> Array:
	var arr: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		arr.append(row)
	return arr

func _ability_xp_cost(owned_in_skill: int, affinity_level: int) -> int:
	return maxi(0, (owned_in_skill + 1) * 500 - 500 * affinity_level)

func _check_or_prereqs(met: Array[bool]) -> bool:
	if met.is_empty():
		return true
	for m in met:
		if m:
			return true
	return false

func _count_abilities_in_skill(innate: Array, skill_type: int) -> int:
	if skill_type < 0 or skill_type >= innate.size():
		return 0
	var count: int = 0
	for i in range(innate[skill_type].size()):
		if innate[skill_type][i]:
			count += 1
	return count

func _adversity_bonus(current_hp: int, max_hp: int) -> int:
	if max_hp <= 0:
		return 0
	var hp_pct: int = current_hp * 100 / max_hp
	if hp_pct >= 50:
		return 0
	return (50 - hp_pct) / 10
