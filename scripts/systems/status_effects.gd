class_name StatusEffects
extends RefCounted
## Manages status effects for an entity using the Sil-Q system.
## Uses lookup tables for effect behaviors to enable serialization.

# Active effects: effect_id -> duration
var effects: Dictionary = {}

# Reference to owning entity
var owner: Entity = null

func _init(entity: Entity = null) -> void:
	owner = entity

# ============================================================================
# EFFECT APPLICATION
# ============================================================================

## Apply a status effect. Returns true if successfully applied.
func apply_effect(effect_id: StringName, duration: int, show_message: bool = true) -> bool:
	# Check resistance
	if owner and _check_resistance(effect_id):
		if show_message:
			GameManager.log_message("%s resists!" % owner.entity_name, ThemeColors.MSG_SYSTEM)
		return false

	# Get effect metadata
	var max_dur: int = EffectDefinitions.get_max_duration(effect_id)

	# Handle stun anti-stacking: if stun > 100 and new value > current, reject
	if effect_id == Constants.EFFECT_STUNNED:
		var current: int = effects.get(effect_id, 0)
		if current > Constants.STUN_THRESHOLD_KNOCKOUT:
			var new_total: int = current + duration
			if new_total > current:
				return false  # Anti-stacking at knockout level

	# Calculate new duration (additive)
	var current_dur: int = effects.get(effect_id, 0)
	var new_dur: int = mini(current_dur + duration, max_dur)

	# Determine severity for message
	var old_dur: int = current_dur
	var is_new: bool = (old_dur == 0)

	# Apply effect
	effects[effect_id] = new_dur

	# Show message
	if show_message and owner:
		if is_new:
			var msg: String = EffectDefinitions.get_onset_message(effect_id, new_dur)
			if not msg.is_empty():
				GameManager.log_message(msg, ThemeColors.MSG_ERROR)

	# Special handling for knockout blindness
	if effect_id == Constants.EFFECT_STUNNED and new_dur > Constants.STUN_THRESHOLD_KNOCKOUT:
		if not has_effect(Constants.EFFECT_BLIND) or effects[Constants.EFFECT_BLIND] < 2:
			effects[Constants.EFFECT_BLIND] = 2

	# Emit signal
	if owner:
		EventBus.status_applied.emit(owner, effect_id, new_dur)

	return true

## Remove a status effect immediately.
func remove_effect(effect_id: StringName, show_message: bool = true) -> void:
	if not effects.has(effect_id):
		return

	var old_dur: int = effects[effect_id]
	effects.erase(effect_id)

	if show_message and owner:
		var msg: String = EffectDefinitions.get_recovery_message(effect_id, old_dur)
		if not msg.is_empty():
			GameManager.log_message(msg, ThemeColors.ABILITY_LEARNED)

	if owner:
		EventBus.status_removed.emit(owner, effect_id)

## Check if entity has a specific effect.
func has_effect(effect_id: StringName) -> bool:
	return effects.has(effect_id) and effects[effect_id] > 0

## Get duration of an effect (0 if not present).
func get_duration(effect_id: StringName) -> int:
	return effects.get(effect_id, 0)

# ============================================================================
# TURN PROCESSING
# ============================================================================

## Process all effects for one turn. Call at start of entity's turn.
func tick_effects() -> void:
	var to_remove: Array[StringName] = []

	for effect_id in effects:
		# Stop processing if owner died from a previous DOT effect
		if owner and not owner.is_alive:
			break

		var duration: int = effects[effect_id]

		# Apply damage effects first (before decay)
		_apply_damage(effect_id, duration)

		# Calculate decay
		var decay: int = _calculate_decay(effect_id, duration)
		var new_dur: int = duration - decay

		# Update or mark for removal
		if new_dur <= 0:
			to_remove.append(effect_id)
		else:
			effects[effect_id] = new_dur

		# Emit tick signal
		if owner:
			EventBus.status_tick.emit(owner, effect_id, new_dur)

	# Remove expired effects
	for effect_id in to_remove:
		remove_effect(effect_id, true)

## Apply damage from damage-over-time effects.
func _apply_damage(effect_id: StringName, duration: int) -> void:
	if not owner:
		return

	if not EffectDefinitions.has_damage(effect_id):
		return

	var damage: int = 0
	var damage_type: String = "effect"

	match effect_id:
		Constants.EFFECT_POISONED:
			damage = EffectDefinitions.calculate_poison_damage(duration)
			damage_type = "poison"
		Constants.EFFECT_CUT:
			damage = EffectDefinitions.calculate_cut_damage(duration)
			damage_type = "bleeding"
		Constants.EFFECT_BURNING:
			damage = EffectDefinitions.calculate_burning_damage(duration)
			damage_type = "fire"

	if damage > 0:
		owner.take_damage(damage, damage_type, null)

## Calculate decay amount for an effect.
func _calculate_decay(effect_id: StringName, duration: int) -> int:
	var base_decay: int = EffectDefinitions.get_decay_rate(effect_id)

	# Special decay formulas
	match effect_id:
		Constants.EFFECT_POISONED:
			return EffectDefinitions.calculate_poison_decay(duration)
		Constants.EFFECT_CUT:
			return EffectDefinitions.calculate_cut_decay(duration)
		Constants.EFFECT_BURNING:
			return EffectDefinitions.calculate_burning_decay(duration)

	return base_decay

# ============================================================================
# RESISTANCE CHECKS
# ============================================================================

func _check_resistance(effect_id: StringName) -> bool:
	if not owner:
		return false

	var resist_prop: String = EffectDefinitions.get_resistance_property(effect_id)
	if resist_prop.is_empty():
		return false

	# Check if entity has resistance property
	if owner.has_method("get") and owner.get(resist_prop):
		return true

	# For Player, also check equipment flags
	if owner is Player:
		# TODO: Check equipment for resistance flags
		pass

	# Rage immunity to fear
	if effect_id == Constants.EFFECT_AFRAID and has_effect(Constants.EFFECT_RAGE):
		return true

	return false

# ============================================================================
# QUERIES
# ============================================================================

## Check if entity is incapacitated (can't act).
func is_incapacitated() -> bool:
	if has_effect(Constants.EFFECT_STUNNED):
		return effects[Constants.EFFECT_STUNNED] > Constants.STUN_THRESHOLD_KNOCKOUT
	if has_effect(Constants.EFFECT_ENTRANCED):
		return true
	return false

## Get movement speed modifier.
func get_speed_modifier() -> int:
	var modifier: int = 0
	if has_effect(Constants.EFFECT_SLOW):
		modifier -= 1
	if has_effect(Constants.EFFECT_FAST):
		modifier += 1
	return modifier

## Check if vision is impaired.
func is_blind() -> bool:
	return has_effect(Constants.EFFECT_BLIND)

## Check if confused.
func is_confused() -> bool:
	return has_effect(Constants.EFFECT_CONFUSED)

## Check if afraid.
func is_afraid() -> bool:
	return has_effect(Constants.EFFECT_AFRAID)

func is_burning() -> bool:
	return has_effect(Constants.EFFECT_BURNING)

## Get list of all active effect IDs.
func get_active_effects() -> Array[StringName]:
	var result: Array[StringName] = []
	for effect_id in effects:
		result.append(effect_id)
	return result

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for effect_id in effects:
		result[effect_id] = effects[effect_id]
	return result

func from_dict(data: Dictionary) -> void:
	effects.clear()
	for effect_id in data:
		effects[StringName(effect_id)] = data[effect_id]
