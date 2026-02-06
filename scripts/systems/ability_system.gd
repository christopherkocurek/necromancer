extends Node
class_name AbilitySystem
## Manages ability activation, cooldowns, and voice charge consumption.
## Handles both active abilities (require activation) and passive abilities (always active).

signal ability_activated(ability_id: int, ability_name: String)
signal ability_failed(ability_id: int, reason: String)
signal ability_cooldown_started(ability_id: int, duration: int)
signal ability_cooldown_ended(ability_id: int)
signal voice_charges_changed(current: int, max_charges: int)

# Lore ability IDs (from data/ability.txt)
enum LoreAbility {
	WORD_OF_COMMAND = 140,
	LORE_OF_BATTLE = 141,
	DEEP_MEMORY = 142,
	WORD_OF_OPENING = 143,
	LORE_OF_SILENCE = 144,
	HERBCRAFT = 145,
	WORD_OF_SHUTTING = 146,
	INNER_LIGHT = 147,
	DEADLY_LORE = 148,
	LORE_OF_ENDURANCE = 149,
	LORE_OF_SLEEP = 150,
	WORD_OF_MASTERY = 151,
	DEVICE_MASTERY = 152,
	GRACE = 153,
	SONG_OF_BANISHMENT = 154,
}

# Ability types
enum AbilityType {
	PASSIVE,   # Always active when learned
	ACTIVE,    # Requires activation, may cost voice charges
	TRIGGERED, # Activates automatically on certain conditions
}

# Cooldowns: ability_id -> turns remaining
var cooldowns: Dictionary = {}

# Reference to player
var player: Player = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.level_entered.connect(_on_level_entered)

func set_player(p: Player) -> void:
	player = p

# ============================================================================
# VOICE CHARGE SYSTEM
# ============================================================================

func get_voice_charges() -> int:
	if not player:
		return 0
	return player.voice_charges

func get_max_voice() -> int:
	if not player:
		return 10
	return player.max_voice

func consume_voice_charges(amount: int) -> bool:
	if not player:
		return false
	if player.voice_charges < amount:
		return false
	player.voice_charges -= amount
	voice_charges_changed.emit(player.voice_charges, player.max_voice)
	return true

func restore_voice_charges(amount: int) -> void:
	if not player:
		return
	player.voice_charges = mini(player.voice_charges + amount, player.max_voice)
	voice_charges_changed.emit(player.voice_charges, player.max_voice)

func regenerate_voice() -> void:
	# Called each turn - regenerate 1 voice charge if below max
	if player and player.voice_charges < player.max_voice:
		player.voice_charges += 1
		voice_charges_changed.emit(player.voice_charges, player.max_voice)

# ============================================================================
# COOLDOWN SYSTEM
# ============================================================================

func start_cooldown(ability_id: int, duration: int) -> void:
	cooldowns[ability_id] = duration
	ability_cooldown_started.emit(ability_id, duration)

func is_on_cooldown(ability_id: int) -> bool:
	return cooldowns.has(ability_id) and cooldowns[ability_id] > 0

func get_cooldown_remaining(ability_id: int) -> int:
	return cooldowns.get(ability_id, 0)

func _on_round_completed(_round: int) -> void:
	# Tick down cooldowns
	var to_remove: Array[int] = []
	for ability_id in cooldowns:
		cooldowns[ability_id] -= 1
		if cooldowns[ability_id] <= 0:
			to_remove.append(ability_id)

	for ability_id in to_remove:
		cooldowns.erase(ability_id)
		ability_cooldown_ended.emit(ability_id)

	# Regenerate voice
	regenerate_voice()

func _on_level_entered(_depth: int) -> void:
	# Reset per-floor abilities (Song of Banishment)
	if cooldowns.has(LoreAbility.SONG_OF_BANISHMENT):
		cooldowns.erase(LoreAbility.SONG_OF_BANISHMENT)
		ability_cooldown_ended.emit(LoreAbility.SONG_OF_BANISHMENT)

# ============================================================================
# ABILITY CHECKS
# ============================================================================

func has_ability(ability_id: int) -> bool:
	if not player:
		return false
	# Map ability ID to skill and ability index
	var skill_index: int = _get_skill_for_ability(ability_id)
	var ability_index: int = _get_ability_index(ability_id)
	return player.has_ability(skill_index, ability_index)

func can_use_ability(ability_id: int) -> Dictionary:
	# Returns {can_use: bool, reason: String}
	if not has_ability(ability_id):
		return {"can_use": false, "reason": "You don't know this ability."}

	if is_on_cooldown(ability_id):
		var remaining: int = get_cooldown_remaining(ability_id)
		return {"can_use": false, "reason": "On cooldown (%d turns remaining)." % remaining}

	var cost: int = get_effective_voice_cost(ability_id)
	if cost > 0 and get_voice_charges() < cost:
		return {"can_use": false, "reason": "Not enough voice charges (%d required, %d available)." % [cost, get_voice_charges()]}

	return {"can_use": true, "reason": ""}

func get_voice_cost(ability_id: int) -> int:
	# Voice costs for abilities (Word abilities cost voice)
	match ability_id:
		LoreAbility.WORD_OF_COMMAND:
			return 3
		LoreAbility.WORD_OF_OPENING:
			return 2
		LoreAbility.WORD_OF_SHUTTING:
			return 2
		LoreAbility.WORD_OF_MASTERY:
			return 4
		LoreAbility.LORE_OF_SLEEP:
			return 3
		LoreAbility.LORE_OF_SILENCE:
			return 2
		LoreAbility.LORE_OF_BATTLE:
			return 1
		LoreAbility.SONG_OF_BANISHMENT:
			return 3
		_:
			return 0  # Passive or no cost

## Get the effective voice cost after trait discounts (Echoes of the Firstborn)
func get_effective_voice_cost(ability_id: int) -> int:
	var cost: int = get_voice_cost(ability_id)
	if cost > 0 and player and player.trait_effect_id == "echoes_firstborn":
		if ability_id >= 140 and ability_id <= 154:  # Lore ability range
			cost = maxi(1, cost - 1)
	return cost

func get_ability_type(ability_id: int) -> AbilityType:
	match ability_id:
		LoreAbility.WORD_OF_COMMAND, LoreAbility.WORD_OF_OPENING, \
		LoreAbility.WORD_OF_SHUTTING, LoreAbility.WORD_OF_MASTERY, \
		LoreAbility.LORE_OF_SLEEP, LoreAbility.LORE_OF_SILENCE, \
		LoreAbility.LORE_OF_BATTLE, LoreAbility.SONG_OF_BANISHMENT:
			return AbilityType.ACTIVE
		LoreAbility.DEADLY_LORE:
			return AbilityType.TRIGGERED  # Triggers on crit
		_:
			return AbilityType.PASSIVE

# ============================================================================
# ABILITY ACTIVATION
# ============================================================================

func activate_ability(ability_id: int, target: Variant = null) -> bool:
	var check: Dictionary = can_use_ability(ability_id)
	if not check.can_use:
		GameManager.log_message(check.reason, ThemeColors.MSG_ERROR)
		ability_failed.emit(ability_id, check.reason)
		return false

	# Consume voice charges (applies Echoes of the Firstborn discount if applicable)
	var cost: int = get_effective_voice_cost(ability_id)
	if cost > 0:
		consume_voice_charges(cost)

	# Execute ability
	var success: bool = _execute_ability(ability_id, target)

	if success:
		var ability_name: String = _get_ability_name(ability_id)
		ability_activated.emit(ability_id, ability_name)
		EventBus.ability_used.emit(player, null, [target] if target else [])

	return success

func _execute_ability(ability_id: int, target: Variant) -> bool:
	match ability_id:
		LoreAbility.WORD_OF_COMMAND:
			return _word_of_command()
		LoreAbility.LORE_OF_BATTLE:
			return _lore_of_battle(target)
		LoreAbility.WORD_OF_OPENING:
			return _word_of_opening()
		LoreAbility.LORE_OF_SILENCE:
			return _lore_of_silence()
		LoreAbility.WORD_OF_SHUTTING:
			return _word_of_shutting()
		LoreAbility.LORE_OF_SLEEP:
			return _lore_of_sleep(target)
		LoreAbility.WORD_OF_MASTERY:
			return _word_of_mastery(target)
		LoreAbility.SONG_OF_BANISHMENT:
			return _song_of_banishment()
		_:
			GameManager.log_message("Ability not implemented.", ThemeColors.MSG_SYSTEM)
			return false

# ============================================================================
# LORE ABILITY IMPLEMENTATIONS
# ============================================================================

## Word of Command (140): AOE fear/stun in radius
func _word_of_command() -> bool:
	if not player or not GameManager.current_level:
		return false

	var lore_skill: int = player.get_skill("lore")
	var radius: int = 2 + (lore_skill / 4)  # Base 2, +1 per 4 Lore

	var affected: int = 0
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, radius)

	GameManager.log_message("You speak a word of terrible power!", ThemeColors.MSG_INFO)

	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue

		var monster: Monster = entity

		# Will save: monster Will vs player Lore
		var monster_will: int = monster.monster_data.will if monster.monster_data else 5
		var player_roll: int = randi_range(1, 20) + lore_skill
		var monster_roll: int = randi_range(1, 20) + monster_will

		if player_roll > monster_roll:
			# Apply fear
			monster.apply_status(Constants.EFFECT_AFRAID, 3 + (lore_skill / 3))
			monster.current_morale -= 30
			affected += 1
			GameManager.log_message("The %s cowers in fear!" % monster.entity_name, ThemeColors.MSG_WARNING)
		else:
			GameManager.log_message("The %s resists your word." % monster.entity_name, ThemeColors.MSG_SYSTEM)

	if affected == 0:
		GameManager.log_message("No enemies were affected.", ThemeColors.MSG_SYSTEM)

	start_cooldown(LoreAbility.WORD_OF_COMMAND, 10)
	return true

## Lore of Battle (141): Provoke target (-evasion, +damage)
func _lore_of_battle(target: Variant) -> bool:
	if not player or not target:
		GameManager.log_message("Select a target for Lore of Battle.", ThemeColors.MSG_WARNING)
		return false

	if not target is Monster:
		GameManager.log_message("Invalid target.", ThemeColors.MSG_ERROR)
		return false

	var monster: Monster = target
	var lore_skill: int = player.get_skill("lore")

	# Will save
	var monster_will: int = monster.monster_data.will if monster.monster_data else 5
	var player_roll: int = randi_range(1, 20) + lore_skill
	var monster_roll: int = randi_range(1, 20) + monster_will

	if player_roll > monster_roll:
		# Provoke: Monster takes -2 evasion, deals +2 damage when it attacks
		# Implemented as a status effect
		monster.apply_status(&"provoked", 3 + (lore_skill / 4))
		monster.evasion_bonus -= 2  # Direct penalty
		GameManager.log_message("You provoke the %s into reckless attacks!" % monster.entity_name, ThemeColors.MSG_INFO)
		return true
	else:
		GameManager.log_message("The %s ignores your taunts." % monster.entity_name, ThemeColors.MSG_SYSTEM)
		return false

## Word of Opening (143): Unlock doors, reveal traps in radius
func _word_of_opening() -> bool:
	if not player or not GameManager.current_level:
		return false

	var level: Level = GameManager.current_level
	var lore_skill: int = player.get_skill("lore")
	var radius: int = 3 + (lore_skill / 3)
	var opened: int = 0

	GameManager.log_message("You speak words of unbinding!", ThemeColors.MSG_INFO)

	# Find and open all closed doors in radius
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos: Vector2i = player.grid_position + Vector2i(dx, dy)
			if not level.is_in_bounds(pos):
				continue

			var dist: int = max(abs(dx), abs(dy))
			if dist > radius:
				continue

			var tile: int = level.get_tile(pos)
			if tile == Level.Tile.DOOR_CLOSED:
				level.set_tile(pos, Level.Tile.DOOR_OPEN)
				opened += 1
			elif tile == Level.Tile.RUBBLE:
				# Clear rubble
				level.set_tile(pos, Level.Tile.FLOOR)
				opened += 1

	# TODO: Reveal traps when trap system is implemented

	if opened > 0:
		GameManager.log_message("The way is opened! (%d barriers cleared)" % opened, ThemeColors.ABILITY_LEARNED)
	else:
		GameManager.log_message("There is nothing to open nearby.", ThemeColors.MSG_SYSTEM)

	start_cooldown(LoreAbility.WORD_OF_OPENING, 8)
	return true

## Lore of Silence (144): Reduce monster perception in radius
func _lore_of_silence() -> bool:
	if not player or not GameManager.current_level:
		return false

	var lore_skill: int = player.get_skill("lore")
	var radius: int = 4 + (lore_skill / 3)
	var duration: int = 5 + (lore_skill / 2)

	var affected: int = 0
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, radius)

	GameManager.log_message("A blanket of silence falls around you.", ThemeColors.MSG_INFO)

	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue

		var monster: Monster = entity
		# Apply silence: reduces perception temporarily
		monster.apply_status(&"silenced", duration)
		monster.perception = max(0, monster.perception - (lore_skill / 2))
		affected += 1

	if affected > 0:
		GameManager.log_message("Enemies struggle to perceive you.", ThemeColors.ABILITY_LEARNED)

	start_cooldown(LoreAbility.LORE_OF_SILENCE, 12)
	return true

## Word of Shutting (146): Lock doors permanently
func _word_of_shutting() -> bool:
	if not player or not GameManager.current_level:
		return false

	var level: Level = GameManager.current_level
	var lore_skill: int = player.get_skill("lore")
	var radius: int = 2 + (lore_skill / 4)
	var shut: int = 0

	GameManager.log_message("You speak words of warding!", ThemeColors.MSG_INFO)

	# Find and seal all open doors in radius
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos: Vector2i = player.grid_position + Vector2i(dx, dy)
			if not level.is_in_bounds(pos):
				continue

			var dist: int = max(abs(dx), abs(dy))
			if dist > radius:
				continue

			var tile: int = level.get_tile(pos)
			if tile == Level.Tile.DOOR_OPEN:
				# Convert to sealed door (impassable wall for monsters)
				# We'll use DOOR_CLOSED but mark it as sealed
				level.set_tile(pos, Level.Tile.DOOR_CLOSED)
				# TODO: Add sealed door flag to prevent monsters from opening
				shut += 1

	if shut > 0:
		GameManager.log_message("Doors seal shut with arcane power! (%d sealed)" % shut, ThemeColors.ABILITY_LEARNED)
	else:
		GameManager.log_message("There are no doors to seal nearby.", ThemeColors.MSG_SYSTEM)

	start_cooldown(LoreAbility.WORD_OF_SHUTTING, 15)
	return true

## Lore of Sleep (150): Put target to sleep (Will check)
func _lore_of_sleep(target: Variant) -> bool:
	if not player or not target:
		GameManager.log_message("Select a target for Lore of Sleep.", ThemeColors.MSG_WARNING)
		return false

	if not target is Monster:
		GameManager.log_message("Invalid target.", ThemeColors.MSG_ERROR)
		return false

	var monster: Monster = target
	var lore_skill: int = player.get_skill("lore")

	# Check if monster can be put to sleep
	if monster.monster_data and monster.monster_data.has_flag("NO_SLEEP"):
		GameManager.log_message("The %s cannot be put to sleep." % monster.entity_name, ThemeColors.MSG_ERROR)
		return false

	# Will save
	var monster_will: int = monster.monster_data.will if monster.monster_data else 5
	var player_roll: int = randi_range(1, 20) + lore_skill
	var monster_roll: int = randi_range(1, 20) + monster_will

	if player_roll > monster_roll:
		# Put to sleep
		monster.is_sleeping = true
		monster.alertness = Constants.ALERTNESS_MIN
		monster.ai_state = Monster.AIState.IDLE
		GameManager.log_message("The %s falls into a deep slumber!" % monster.entity_name, ThemeColors.MSG_INFO)
		start_cooldown(LoreAbility.LORE_OF_SLEEP, 8)
		return true
	else:
		GameManager.log_message("The %s resists your lullaby." % monster.entity_name, ThemeColors.MSG_SYSTEM)
		return false

## Word of Mastery (151): Paralyze target
func _word_of_mastery(target: Variant) -> bool:
	if not player or not target:
		GameManager.log_message("Select a target for Word of Mastery.", ThemeColors.MSG_WARNING)
		return false

	if not target is Monster:
		GameManager.log_message("Invalid target.", ThemeColors.MSG_ERROR)
		return false

	var monster: Monster = target
	var lore_skill: int = player.get_skill("lore")

	# Strong Will save (harder to paralyze)
	var monster_will: int = monster.monster_data.will if monster.monster_data else 5
	var player_roll: int = randi_range(1, 20) + lore_skill
	var monster_roll: int = randi_range(1, 20) + monster_will + 5  # +5 bonus for strong effect

	if player_roll > monster_roll:
		# Paralyze (heavy stun)
		var duration: int = 2 + (lore_skill / 5)
		monster.apply_status(Constants.EFFECT_STUNNED, Constants.STUN_THRESHOLD_KNOCKOUT + 10)
		GameManager.log_message("The %s is frozen by your command!" % monster.entity_name, ThemeColors.MSG_INFO)
		start_cooldown(LoreAbility.WORD_OF_MASTERY, 20)
		return true
	else:
		GameManager.log_message("The %s shakes off your command!" % monster.entity_name, ThemeColors.MSG_SYSTEM)
		return false

## Song of Banishment (154): AOE undead flee, ignores NO_FEAR, 1/floor
func _song_of_banishment() -> bool:
	if not player or not GameManager.current_level:
		return false

	var lore_skill: int = player.get_skill("lore")
	var grace: int = player.grace if player.grace else 0
	var radius: int = 3

	var affected: int = 0
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, radius)

	GameManager.log_message("You sing a song of banishment against the dead!", ThemeColors.MSG_INFO)

	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue

		var monster: Monster = entity

		# Only affects undead
		if not monster.monster_data or not monster.monster_data.has_flag("UNDEAD"):
			continue

		# Save: monster Will vs player Grace + Lore
		var monster_will: int = monster.monster_data.will if monster.monster_data else 5
		var player_roll: int = randi_range(1, 20) + grace + lore_skill
		var monster_roll: int = randi_range(1, 20) + monster_will

		if player_roll > monster_roll:
			# Force flee - ignores NO_FEAR by directly setting morale and status
			monster.current_morale = -100
			monster.apply_status(Constants.EFFECT_AFRAID, 3)
			affected += 1
			GameManager.log_message("The %s is driven back by your song!" % monster.entity_name, ThemeColors.MSG_WARNING)
		else:
			GameManager.log_message("The %s resists the banishment." % monster.entity_name, ThemeColors.MSG_SYSTEM)

	if affected == 0:
		GameManager.log_message("No undead were affected.", ThemeColors.MSG_SYSTEM)
	else:
		GameManager.log_message("%d undead banished!" % affected, ThemeColors.ABILITY_LEARNED)

	# 1/floor cooldown (very high cooldown = effectively once per floor)
	start_cooldown(LoreAbility.SONG_OF_BANISHMENT, 9999)
	return true

# ============================================================================
# PASSIVE ABILITY CHECKS (called from other systems)
# ============================================================================

## Herbcraft (145): Double healing from potions - called when using healing items
func apply_herbcraft_bonus(base_heal: int) -> int:
	if has_ability(LoreAbility.HERBCRAFT):
		GameManager.log_message("Your knowledge of herbs enhances the healing!", ThemeColors.ABILITY_LEARNED)
		return base_heal * 2
	return base_heal

## Deadly Lore (148): Instant kill if HP <= 2x Lore - called on crit
func check_deadly_lore(target: Monster) -> bool:
	if not has_ability(LoreAbility.DEADLY_LORE):
		return false

	if not player:
		return false

	var lore_skill: int = player.get_skill("lore")
	var threshold: int = lore_skill * 2

	if target.current_health <= threshold:
		GameManager.log_message("Your deadly knowledge finds a vital point!", ThemeColors.MSG_ERROR)
		target.die(player)
		return true
	return false

## Lore of Endurance (149): +Will/2, +2d2 protection - returns bonus values
func get_endurance_bonuses() -> Dictionary:
	if not has_ability(LoreAbility.LORE_OF_ENDURANCE):
		return {"will_bonus": 0, "protection_dice": 0, "protection_sides": 0}

	if not player:
		return {"will_bonus": 0, "protection_dice": 0, "protection_sides": 0}

	var lore_skill: int = player.get_skill("lore")
	return {
		"will_bonus": lore_skill / 2,
		"protection_dice": 2,
		"protection_sides": 2
	}

## Device Mastery (152): +50% wand/staff charges - called when using devices
func apply_device_mastery_bonus(base_charges: int) -> int:
	if has_ability(LoreAbility.DEVICE_MASTERY):
		return int(base_charges * 1.5)
	return base_charges

## Grace (153): Passive +1 Grace stat - called on ability learn
func apply_grace_bonus() -> void:
	if has_ability(LoreAbility.GRACE) and player:
		# Check if bonus already applied (to prevent double-application)
		if not player.has_meta("grace_ability_applied"):
			player.grace += 1
			player.set_meta("grace_ability_applied", true)
			GameManager.log_message("Your grace increases from ancient wisdom.", ThemeColors.ABILITY_LEARNED)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _get_skill_for_ability(ability_id: int) -> int:
	# All Lore abilities are in skill 7 (S_LOR)
	if ability_id >= 140 and ability_id <= 154:
		return Constants.Skill.S_LOR
	return -1

func _get_ability_index(ability_id: int) -> int:
	# Convert global ability ID to skill-local index
	# Lore abilities: 140 -> 0, 141 -> 1, etc.
	if ability_id >= 140 and ability_id <= 154:
		return ability_id - 140
	return -1

func _get_ability_name(ability_id: int) -> String:
	match ability_id:
		LoreAbility.WORD_OF_COMMAND: return "Word of Command"
		LoreAbility.LORE_OF_BATTLE: return "Lore of Battle"
		LoreAbility.DEEP_MEMORY: return "Deep Memory"
		LoreAbility.WORD_OF_OPENING: return "Word of Opening"
		LoreAbility.LORE_OF_SILENCE: return "Lore of Silence"
		LoreAbility.HERBCRAFT: return "Herbcraft"
		LoreAbility.WORD_OF_SHUTTING: return "Word of Shutting"
		LoreAbility.INNER_LIGHT: return "Inner Light"
		LoreAbility.DEADLY_LORE: return "Deadly Lore"
		LoreAbility.LORE_OF_ENDURANCE: return "Lore of Endurance"
		LoreAbility.LORE_OF_SLEEP: return "Lore of Sleep"
		LoreAbility.WORD_OF_MASTERY: return "Word of Mastery"
		LoreAbility.DEVICE_MASTERY: return "Device Mastery"
		LoreAbility.GRACE: return "Grace"
		LoreAbility.SONG_OF_BANISHMENT: return "Song of Banishment"
		_: return "Unknown Ability"

## Get list of all implemented Lore abilities
func get_lore_abilities() -> Array[int]:
	return [
		LoreAbility.WORD_OF_COMMAND,
		LoreAbility.LORE_OF_BATTLE,
		LoreAbility.DEEP_MEMORY,
		LoreAbility.WORD_OF_OPENING,
		LoreAbility.LORE_OF_SILENCE,
		LoreAbility.HERBCRAFT,
		LoreAbility.WORD_OF_SHUTTING,
		LoreAbility.INNER_LIGHT,
		LoreAbility.DEADLY_LORE,
		LoreAbility.LORE_OF_ENDURANCE,
		LoreAbility.LORE_OF_SLEEP,
		LoreAbility.WORD_OF_MASTERY,
		LoreAbility.DEVICE_MASTERY,
		LoreAbility.GRACE,
		LoreAbility.SONG_OF_BANISHMENT,
	]
