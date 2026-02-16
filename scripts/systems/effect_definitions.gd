class_name EffectDefinitions
extends RefCounted
## Defines all status effect behaviors using lookup tables instead of Callables.
## This allows effects to be serialized properly.

# ============================================================================
# EFFECT METADATA
# ============================================================================

const EFFECT_DATA: Dictionary = {
	Constants.EFFECT_BLIND: {
		"name": "Blind",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You are blind!",
		"recovery_message": "You can see again.",
	},
	Constants.EFFECT_CONFUSED: {
		"name": "Confused",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You are confused!",
		"recovery_message": "You feel less confused now.",
	},
	Constants.EFFECT_POISONED: {
		"name": "Poisoned",
		"max_duration": Constants.EFFECT_MAX_POISON,
		"decay_rate": 0,  # Special: decay = (v+4)/5
		"has_damage": true,
		"onset_message": "You have been poisoned.",
		"recovery_message": "You recover from the poisoning.",
		"severity_messages": {
			10: "You have been badly poisoned!",
			20: "You have been severely poisoned!",
		}
	},
	Constants.EFFECT_AFRAID: {
		"name": "Afraid",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You are terrified!",
		"recovery_message": "You feel bolder now.",
	},
	Constants.EFFECT_STUNNED: {
		"name": "Stunned",
		"max_duration": Constants.STUN_MAX,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You have been stunned.",
		"recovery_message": "You are no longer stunned.",
		"severity_messages": {
			Constants.STUN_THRESHOLD_HEAVY: "You have been heavily stunned!",
			Constants.STUN_THRESHOLD_KNOCKOUT: "You have been knocked out!",
		},
		"recovery_severity_messages": {
			Constants.STUN_THRESHOLD_KNOCKOUT: "You wake up.",
		}
	},
	Constants.EFFECT_CUT: {
		"name": "Cut",
		"max_duration": Constants.EFFECT_MAX_CUT,
		"decay_rate": 0,  # Special: decay = (v+4)/5
		"has_damage": true,
		"onset_message": "You have been given a cut.",
		"recovery_message": "The bleeding stops.",
		"severity_messages": {
			20: "You have been given a deep cut!",
			50: "You have been given a severe cut!",
		}
	},
	Constants.EFFECT_SLOW: {
		"name": "Slow",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You feel yourself moving slower!",
		"recovery_message": "You feel yourself speed up.",
	},
	Constants.EFFECT_FAST: {
		"name": "Fast",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You feel yourself moving faster!",
		"recovery_message": "You feel yourself slow down.",
	},
	Constants.EFFECT_ENTRANCED: {
		"name": "Entranced",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You fall into a deep trance!",
		"recovery_message": "The trance is broken!",
	},
	Constants.EFFECT_IMAGE: {
		"name": "Hallucinating",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "Fantastic visions appear before your eyes.",
		"recovery_message": "You can see clearly again.",
	},
	Constants.EFFECT_RAGE: {
		"name": "Rage",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You enter a battle rage!",
		"recovery_message": "Your rage subsides.",
	},
	Constants.EFFECT_DARKENED: {
		"name": "Darkened",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "Darkness surrounds you!",
		"recovery_message": "The darkness lifts.",
	},
	Constants.EFFECT_BURNING: {
		"name": "Burning",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 0,  # Special: decay = (v+4)/5
		"has_damage": true,
		"onset_message": "You catch on fire!",
		"recovery_message": "The flames die out.",
		"severity_messages": {
			5: "You are engulfed in flames!",
		}
	},
	&"true_sight": {
		"name": "True Sight",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "Your vision pierces all illusion!",
		"recovery_message": "Your enhanced sight fades.",
	},
	&"spider_bane": {
		"name": "Spider-bane",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "Your blood becomes toxic to spiders!",
		"recovery_message": "The spider-bane toxin fades from your blood.",
	},
	&"grace_boost": {
		"name": "Grace Boost",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "You feel a surge of grace!",
		"recovery_message": "The grace boost fades.",
	},
	&"thornvine": {
		"name": "Thornvine Protection",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "Thorny vines harden your skin!",
		"recovery_message": "The thornvine protection fades.",
	},
	Constants.EFFECT_BATTLE_FURY: {
		"name": "Battle Fury",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "Battle-fury surges through you!",
		"recovery_message": "Your battle-fury subsides.",
	},
	Constants.EFFECT_FAIRY_MIST: {
		"name": "Fairy Mist",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "A shroud of magical darkness envelops you.",
		"recovery_message": "The fairy mist dissipates.",
	},
	Constants.EFFECT_ENDURANCE_WILL: {
		"name": "Endurance",
		"max_duration": Constants.EFFECT_MAX_GENERAL,
		"decay_rate": 1,
		"has_damage": false,
		"onset_message": "Endurance steadies your spirit.",
		"recovery_message": "Your surge of endurance fades.",
	},
}

# ============================================================================
# DAMAGE FORMULAS
# ============================================================================

## Calculate damage for poison effect: (duration + 4) / 5
static func calculate_poison_damage(duration: int) -> int:
	return maxi(1, (duration + 7) / 8)

## Calculate damage for cut/bleeding effect: (duration + 4) / 5
static func calculate_cut_damage(duration: int) -> int:
	return (duration + 4) / 5

## Calculate decay for poison effect: same as damage formula
static func calculate_poison_decay(duration: int) -> int:
	return maxi(1, (duration + 9) / 10)

## Calculate decay for cut effect: same as damage formula
static func calculate_cut_decay(duration: int) -> int:
	return (duration + 4) / 5

## Calculate damage for burning effect: (duration + 2) / 3
static func calculate_burning_damage(duration: int) -> int:
	return (duration + 2) / 3

## Calculate decay for burning effect: same as damage formula
static func calculate_burning_decay(duration: int) -> int:
	return (duration + 2) / 3

# ============================================================================
# EFFECT QUERIES
# ============================================================================

static func get_effect_data(effect_id: StringName) -> Dictionary:
	return EFFECT_DATA.get(effect_id, {})

static func get_max_duration(effect_id: StringName) -> int:
	var data: Dictionary = get_effect_data(effect_id)
	return data.get("max_duration", Constants.EFFECT_MAX_GENERAL)

static func get_decay_rate(effect_id: StringName) -> int:
	var data: Dictionary = get_effect_data(effect_id)
	return data.get("decay_rate", 1)

static func has_damage(effect_id: StringName) -> bool:
	var data: Dictionary = get_effect_data(effect_id)
	return data.get("has_damage", false)

static func get_onset_message(effect_id: StringName, severity: int = 0) -> String:
	var data: Dictionary = get_effect_data(effect_id)
	if severity > 0 and data.has("severity_messages"):
		# Find highest severity threshold that's <= current severity
		var severity_msgs: Dictionary = data.severity_messages
		var best_msg: String = data.get("onset_message", "")
		var best_threshold: int = 0
		for threshold in severity_msgs:
			if threshold <= severity and threshold > best_threshold:
				best_threshold = threshold
				best_msg = severity_msgs[threshold]
		return best_msg
	return data.get("onset_message", "")

static func get_recovery_message(effect_id: StringName, old_severity: int = 0) -> String:
	var data: Dictionary = get_effect_data(effect_id)
	if old_severity > 0 and data.has("recovery_severity_messages"):
		var recovery_msgs: Dictionary = data.recovery_severity_messages
		for threshold in recovery_msgs:
			if old_severity >= threshold:
				return recovery_msgs[threshold]
	return data.get("recovery_message", "")

# ============================================================================
# RESISTANCE TYPES
# ============================================================================

const RESISTANCE_MAP: Dictionary = {
	Constants.EFFECT_BLIND: "resist_blind",
	Constants.EFFECT_CONFUSED: "resist_confu",
	Constants.EFFECT_POISONED: "resist_pois",
	Constants.EFFECT_AFRAID: "resist_fear",
	Constants.EFFECT_STUNNED: "resist_stun",
	Constants.EFFECT_SLOW: "free_act",
	Constants.EFFECT_ENTRANCED: "free_act",
	Constants.EFFECT_IMAGE: "resist_hallu",
	Constants.EFFECT_BURNING: "resist_fire",
}

static func get_resistance_property(effect_id: StringName) -> String:
	return RESISTANCE_MAP.get(effect_id, "")
