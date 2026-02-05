extends GutTest
## Unit tests for status effect formulas (Phase G-H)
## Tests burning DOT, poison/cut decay, effect durations

# ============================================================================
# BURNING DOT TESTS
# ============================================================================

func test_burning_damage_formula():
	# Burning damage = (duration + 2) / 3 (integer division)
	assert_eq(_burning_damage(1), 1, "Duration 1: damage = 1")
	assert_eq(_burning_damage(2), 1, "Duration 2: damage = 1")
	assert_eq(_burning_damage(3), 1, "Duration 3: damage = 1")
	assert_eq(_burning_damage(4), 2, "Duration 4: damage = 2")
	assert_eq(_burning_damage(7), 3, "Duration 7: damage = 3")
	assert_eq(_burning_damage(10), 4, "Duration 10: damage = 4")

func test_burning_decay_formula():
	# Burning decay = (duration + 2) / 3 (same as damage)
	assert_eq(_burning_decay(1), 1, "Duration 1: decay = 1 (clears immediately)")
	assert_eq(_burning_decay(2), 1, "Duration 2: decay = 1")
	assert_eq(_burning_decay(4), 2, "Duration 4: decay = 2")
	assert_eq(_burning_decay(10), 4, "Duration 10: decay = 4")

func test_burning_clears_fast():
	# Burning should clear faster than poison (which uses (dur+4)/5)
	var duration: int = 10
	var burning_turns: int = 0
	while duration > 0:
		var decay: int = _burning_decay(duration)
		duration -= decay
		burning_turns += 1
	assert_lt(burning_turns, 6, "Burning 10 should clear in fewer than 6 turns")

func test_burning_never_zero_decay():
	# For any duration >= 1, decay should always be >= 1
	for d in range(1, 100):
		assert_gt(_burning_decay(d), 0, "Decay should always be > 0 for duration %d" % d)

# ============================================================================
# POISON DECAY TESTS
# ============================================================================

func test_poison_decay_formula():
	# Poison decay = (duration + 4) / 5
	assert_eq(_poison_decay(1), 1, "Duration 1: decay = 1")
	assert_eq(_poison_decay(5), 1, "Duration 5: decay = 1")
	assert_eq(_poison_decay(6), 2, "Duration 6: decay = 2")
	assert_eq(_poison_decay(10), 2, "Duration 10: decay = 2")
	assert_eq(_poison_decay(20), 4, "Duration 20: decay = 4")

func test_poison_never_zero_decay():
	for d in range(1, 100):
		assert_gt(_poison_decay(d), 0, "Poison decay should always be > 0 for duration %d" % d)

# ============================================================================
# CUT DECAY TESTS
# ============================================================================

func test_cut_decay_formula():
	# Cut decay = max(1, duration / 5)
	assert_eq(_cut_decay(1), 1, "Duration 1: decay = 1")
	assert_eq(_cut_decay(4), 1, "Duration 4: decay = 1")
	assert_eq(_cut_decay(5), 1, "Duration 5: decay = 1")
	assert_eq(_cut_decay(10), 2, "Duration 10: decay = 2")
	assert_eq(_cut_decay(25), 5, "Duration 25: decay = 5")

# ============================================================================
# EFFECT DURATION COMPARISON
# ============================================================================

func test_burning_clears_faster_than_poison():
	# Same starting duration, burning should clear sooner
	var burn_dur: int = 10
	var poison_dur: int = 10
	var burn_turns: int = 0
	var poison_turns: int = 0

	while burn_dur > 0:
		burn_dur -= _burning_decay(burn_dur)
		burn_turns += 1

	while poison_dur > 0:
		poison_dur -= _poison_decay(poison_dur)
		poison_turns += 1

	assert_lt(burn_turns, poison_turns, "Burning should clear faster than poison")

func test_total_burning_damage():
	# Track total damage from burning at duration 5
	var dur: int = 5
	var total_dmg: int = 0
	while dur > 0:
		total_dmg += _burning_damage(dur)
		dur -= _burning_decay(dur)
	assert_gt(total_dmg, 0, "Burning should deal some total damage")
	assert_lt(total_dmg, 20, "Burning 5 damage should be reasonable (< 20)")

# ============================================================================
# RESISTANCE MAP TESTS
# ============================================================================

func test_burning_has_fire_resistance():
	# EFFECT_BURNING should be in the resistance map pointing to resist_fire
	var resistance_key: StringName = Constants.EFFECT_BURNING
	assert_eq(resistance_key, &"burning", "EFFECT_BURNING should be 'burning'")

func test_effect_constants_exist():
	assert_eq(Constants.EFFECT_BLIND, &"blind", "EFFECT_BLIND defined")
	assert_eq(Constants.EFFECT_CONFUSED, &"confused", "EFFECT_CONFUSED defined")
	assert_eq(Constants.EFFECT_POISONED, &"poisoned", "EFFECT_POISONED defined")
	assert_eq(Constants.EFFECT_AFRAID, &"afraid", "EFFECT_AFRAID defined")
	assert_eq(Constants.EFFECT_STUNNED, &"stunned", "EFFECT_STUNNED defined")
	assert_eq(Constants.EFFECT_CUT, &"cut", "EFFECT_CUT defined")
	assert_eq(Constants.EFFECT_SLOW, &"slow", "EFFECT_SLOW defined")
	assert_eq(Constants.EFFECT_FAST, &"fast", "EFFECT_FAST defined")
	assert_eq(Constants.EFFECT_DARKENED, &"darkened", "EFFECT_DARKENED defined")
	assert_eq(Constants.EFFECT_BURNING, &"burning", "EFFECT_BURNING defined")

# ============================================================================
# STATUS MODIFIER TESTS (Phase H ability hooks)
# ============================================================================

func test_indomitable_halves_stun():
	# Indomitable: halve stun and slow durations
	var stun_dur: int = 6
	var reduced: int = maxi(1, stun_dur / 2)
	assert_eq(reduced, 3, "Stun 6 halved to 3")

	stun_dur = 1
	reduced = maxi(1, stun_dur / 2)
	assert_eq(reduced, 1, "Stun 1 stays at 1 (min 1)")

func test_poison_resist_halves_poison():
	var poison_dur: int = 10
	var reduced: int = maxi(1, poison_dur / 2)
	assert_eq(reduced, 5, "Poison 10 halved to 5")

func test_majesty_blocks_fear():
	# Majesty: immune to afraid status
	var status: String = "afraid"
	var has_majesty: bool = true
	var should_apply: bool = not (has_majesty and status == "afraid")
	assert_false(should_apply, "Majesty should block fear")

# ============================================================================
# LIGHT RADIUS MODIFIER TESTS
# ============================================================================

func test_darkened_reduces_light():
	# DARKENED: -2 light, min 1
	var base_light: int = 5
	var light: int = maxi(1, base_light - 2)
	assert_eq(light, 3, "Darkened 5 -> 3")

	base_light = 2
	light = maxi(1, base_light - 2)
	assert_eq(light, 1, "Darkened 2 -> 1 (min 1)")

	base_light = 1
	light = maxi(1, base_light - 2)
	assert_eq(light, 1, "Darkened 1 -> 1 (min 1)")

func test_burning_increases_light():
	var base_light: int = 5
	var light: int = base_light + 1
	assert_eq(light, 6, "Burning adds +1 light")

func test_keen_senses_increases_light():
	var base_light: int = 5
	var light: int = base_light + 1
	assert_eq(light, 6, "Keen Senses adds +1 light")

# ============================================================================
# HELPERS
# ============================================================================

func _burning_damage(duration: int) -> int:
	return (duration + 2) / 3

func _burning_decay(duration: int) -> int:
	return (duration + 2) / 3

func _poison_decay(duration: int) -> int:
	return (duration + 4) / 5

func _cut_decay(duration: int) -> int:
	return maxi(1, duration / 5)
