extends Node
class_name AbilitySystem
## Manages ability activation, cooldowns, and voice charge consumption.
## Handles both active abilities (require activation) and passive abilities (always active).
## v4 Lore Redesign: 20 abilities (IDs 140-159), song noise mechanic, dual sustained songs.

signal ability_activated(ability_id: int, ability_name: String)
signal ability_failed(ability_id: int, reason: String)
signal ability_cooldown_started(ability_id: int, duration: int)
signal ability_cooldown_ended(ability_id: int)
signal voice_charges_changed(current: int, max_charges: int)

# Lore ability IDs (from data/ability.txt, v4 redesign)
# Local index = ability_id - 140
enum LoreAbility {
	HIDDEN_WAYS = 140,       # Lore 1: Status-based perception drain
	WORD_OF_OPENING = 141,   # Lore 1: Unlock doors, clear rubble
	DEEP_MEMORY = 142,       # Lore 2: Map reveal
	HERBCRAFT = 143,         # Lore 2: Sustained — bleeding/regen/herbs
	LORE_OF_NAMING = 144,    # Lore 3: +2 Will vs known types
	LIGHT_OF_ELDAR = 145,    # Lore 3: Light + shadow penalty
	WORD_OF_COMMAND = 146,   # Lore 4: AOE fear/stun, 12-turn CD
	SONG_OF_FREEDOM = 147,   # Lore 4: Sustained +3 evasion + status resist
	SONG_OF_LORIEN = 148,    # Lore 5: Sustained alertness drain -> sleep
	LORE_OF_ENDURANCE = 149, # Lore 5: +Will, +prot, temp Will on damage
	SONG_OF_BANISHMENT = 150, # Lore 6: Undead damage + flee
	WORD_OF_DOMINATION = 151, # Lore 6: Charm monster
	SONG_OF_AULE = 152,      # Lore 7: Sustained +1 dmg/prot, +3 smithing
	SONG_OF_HEALING = 153,   # Lore 7: Sustained heal lore/2 HP/turn
	WORD_OF_WARDING = 154,   # Lore 8: Impassable sigil tiles
	WORD_OF_AUTHORITY = 155,  # Lore 8: AOE stun via presence
	WORD_OF_UNMAKING = 156,  # Lore 9: Dispel + terrain + undead dmg
	MASTERY_OF_THEMES = 157, # Lore 10: Dual sustained songs
	GRACE = 158,             # Lore 12: +1 GRA
	SONG_OF_THE_TREES = 159, # Lore 3: Sustained +5 stealth
}

# Ability types
enum AbilityType {
	PASSIVE,   # Always active when learned
	ACTIVE,    # Requires activation, may cost voice charges
	TRIGGERED, # Activates automatically on certain conditions
	SUSTAINED, # Toggle: drains voice each turn while active
}

# Cooldowns: ability_id -> turns remaining
var cooldowns: Dictionary = {}

# Per-floor usage tracking
var _unmaking_used_this_floor: bool = false

# Warding sigil tracking: [{pos: Vector2i, turns_remaining: int}]
var active_sigils: Array[Dictionary] = []

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

const VOICE_REGEN_PERIOD: float = 150.0  # Sil-Q: full voice pool recovers over 150 turns

func regenerate_voice() -> void:
	if not player or player.voice_charges >= player.max_voice:
		return
	var regen_rate: float = float(player.max_voice) / VOICE_REGEN_PERIOD
	player._voice_regen_accumulator += regen_rate
	if player._voice_regen_accumulator >= 1.0:
		var gain: int = int(player._voice_regen_accumulator)
		player._voice_regen_accumulator -= float(gain)
		player.voice_charges = mini(player.voice_charges + gain, player.max_voice)
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

	# Tick sustained songs (drain voice, apply effects)
	_tick_active_song()

	# Tick warding sigils
	_tick_sigils()

	# Apply song noise to nearby monsters
	_apply_song_noise()

	# Tick Light of the Eldar passive (wraith damage)
	_tick_light_of_eldar()

	# Regenerate voice (reduced while singing)
	regenerate_voice()

func _on_level_entered(_depth: int) -> void:
	# Reset per-floor abilities
	_unmaking_used_this_floor = false
	# Clear old sigils
	active_sigils.clear()
	# Reset Song of Banishment per-floor CD
	if cooldowns.has(LoreAbility.SONG_OF_BANISHMENT):
		cooldowns.erase(LoreAbility.SONG_OF_BANISHMENT)
		ability_cooldown_ended.emit(LoreAbility.SONG_OF_BANISHMENT)
	if cooldowns.has(LoreAbility.WORD_OF_UNMAKING):
		cooldowns.erase(LoreAbility.WORD_OF_UNMAKING)
		ability_cooldown_ended.emit(LoreAbility.WORD_OF_UNMAKING)

# ============================================================================
# SUSTAINED SONG SYSTEM (v4: dual song support via Mastery of Themes)
# ============================================================================

## Toggle a sustained song on/off
func _toggle_song(ability_id: int) -> bool:
	if not player:
		return false

	# If same song is already active in slot 1, stop it
	if player.active_song_id == ability_id:
		stop_song()
		return true

	# If same song in slot 2, stop slot 2
	if player.active_song_id_2 == ability_id:
		stop_song_2()
		return true

	# Check if player knows this ability
	if not has_ability(ability_id):
		GameManager.log_message("You don't know this song.", ThemeColors.MSG_ERROR)
		return false

	# Need at least 1 voice charge to start
	var cost: int = get_effective_voice_cost(ability_id)
	if get_voice_charges() < cost:
		GameManager.log_message("Not enough voice to sustain a song.", ThemeColors.MSG_ERROR)
		return false

	# If slot 1 is occupied, check for Mastery of Themes (dual song)
	if player.active_song_id >= 0:
		if has_ability(LoreAbility.MASTERY_OF_THEMES) and player.active_song_id_2 < 0:
			# Start in second slot
			player.active_song_id_2 = ability_id
			player.song_voice_drain_2 = cost
			var song_name: String = _get_ability_name(ability_id)
			GameManager.log_message("You weave a second theme: %s." % song_name, ThemeColors.MSG_INFO)
			ability_activated.emit(ability_id, song_name)
			return true
		else:
			# Replace slot 1
			stop_song()

	# Start new song in slot 1
	player.active_song_id = ability_id
	player.song_voice_drain = cost
	var song_name: String = _get_ability_name(ability_id)
	GameManager.log_message("You begin singing %s." % song_name, ThemeColors.MSG_INFO)
	ability_activated.emit(ability_id, song_name)
	return true

## Stop the currently active sustained song (slot 1)
func stop_song() -> void:
	if not player or player.active_song_id < 0:
		return
	var song_name: String = _get_ability_name(player.active_song_id)
	GameManager.log_message("You stop singing %s." % song_name, ThemeColors.TEXT_SECONDARY)
	player.active_song_id = -1
	player.song_voice_drain = 1

## Stop second sustained song (slot 2, Mastery of Themes)
func stop_song_2() -> void:
	if not player or player.active_song_id_2 < 0:
		return
	var song_name: String = _get_ability_name(player.active_song_id_2)
	GameManager.log_message("You stop singing %s." % song_name, ThemeColors.TEXT_SECONDARY)
	player.active_song_id_2 = -1
	player.song_voice_drain_2 = 0

## Tick the active songs: drain voice, cancel if depleted
func _tick_active_song() -> void:
	if not player:
		return

	# Tick slot 1
	if player.active_song_id >= 0:
		var cost: int = player.song_voice_drain
		if player.voice_charges >= cost:
			player.voice_charges -= cost
			voice_charges_changed.emit(player.voice_charges, player.max_voice)
			# Apply per-tick effects for slot 1 song
			_apply_song_tick_effect(player.active_song_id)
		else:
			GameManager.log_message("Your voice falters and the song fades.", ThemeColors.MSG_WARNING)
			stop_song()

	# Tick slot 2 (Mastery of Themes)
	if player.active_song_id_2 >= 0:
		var cost: int = player.song_voice_drain_2
		if player.voice_charges >= cost:
			player.voice_charges -= cost
			voice_charges_changed.emit(player.voice_charges, player.max_voice)
			_apply_song_tick_effect(player.active_song_id_2)
		else:
			GameManager.log_message("Your second theme fades.", ThemeColors.MSG_WARNING)
			stop_song_2()

## Apply per-tick effects for a sustained song
func _apply_song_tick_effect(song_id: int) -> void:
	match song_id:
		LoreAbility.HERBCRAFT:
			_tick_herbcraft()
		LoreAbility.SONG_OF_LORIEN:
			_tick_song_of_lorien()
		LoreAbility.SONG_OF_HEALING:
			_tick_song_of_healing()

## Get song combat bonuses for the active song(s)
func get_song_evasion_bonus() -> int:
	if not player:
		return 0
	var bonus: int = 0
	if player.active_song_id == LoreAbility.SONG_OF_FREEDOM:
		bonus += 3
	if player.active_song_id_2 == LoreAbility.SONG_OF_FREEDOM:
		bonus += 3
	return bonus

func get_song_stealth_bonus() -> int:
	if not player:
		return 0
	var bonus: int = 0
	if player.active_song_id == LoreAbility.SONG_OF_THE_TREES:
		bonus += 5
	if player.active_song_id_2 == LoreAbility.SONG_OF_THE_TREES:
		bonus += 5
	return bonus

func get_song_melee_bonus() -> int:
	if not player:
		return 0
	var bonus: int = 0
	if player.active_song_id == LoreAbility.SONG_OF_AULE:
		bonus += 1  # +1 damage die (was +2 melee)
	if player.active_song_id_2 == LoreAbility.SONG_OF_AULE:
		bonus += 1
	return bonus

func get_song_smithing_bonus() -> int:
	if not player:
		return 0
	var bonus: int = 0
	if player.active_song_id == LoreAbility.SONG_OF_AULE or player.active_song_id_2 == LoreAbility.SONG_OF_AULE:
		bonus += 3  # +3 smithing at forge
	return bonus

func get_song_healing() -> int:
	## Returns HP healed per turn from Song of Healing
	if not player:
		return 0
	var healing: int = 0
	if player.active_song_id == LoreAbility.SONG_OF_HEALING or player.active_song_id_2 == LoreAbility.SONG_OF_HEALING:
		healing = maxi(1, player.get_effective_skill("lore") / 2)
	return healing

func is_singing() -> bool:
	return player != null and player.active_song_id >= 0

func is_singing_song(song_id: int) -> bool:
	if not player:
		return false
	return player.active_song_id == song_id or player.active_song_id_2 == song_id

func get_active_song_name() -> String:
	if not player or player.active_song_id < 0:
		return ""
	var name1: String = _get_ability_name(player.active_song_id)
	if player.active_song_id_2 >= 0:
		name1 += " + " + _get_ability_name(player.active_song_id_2)
	return name1

# ============================================================================
# SONG NOISE MECHANIC (v4)
# ============================================================================

## Apply perception bonus to nearby monsters while singing
func _apply_song_noise() -> void:
	if not player or not GameManager.current_level:
		return
	if player.active_song_id < 0:
		return

	var total_voice_cost: int = player.song_voice_drain
	if player.active_song_id_2 >= 0:
		total_voice_cost += player.song_voice_drain_2

	var noise_bonus: int = total_voice_cost * 3
	if noise_bonus <= 0:
		return

	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, 5)
	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if entity is Monster:
			var monster: Monster = entity
			monster.song_noise_perception_bonus = noise_bonus

# ============================================================================
# ABILITY CHECKS
# ============================================================================

func has_ability(ability_id: int) -> bool:
	if not player:
		return false
	var skill_index: int = _get_skill_for_ability(ability_id)
	var ability_index: int = _get_ability_index(ability_id)
	return player.has_ability(skill_index, ability_index)

func can_use_ability(ability_id: int) -> Dictionary:
	if not has_ability(ability_id):
		return {"can_use": false, "reason": "You don't know this ability."}

	if is_on_cooldown(ability_id):
		var remaining: int = get_cooldown_remaining(ability_id)
		return {"can_use": false, "reason": "On cooldown (%d turns remaining)." % remaining}

	# Per-floor check for Word of Unmaking
	if ability_id == LoreAbility.WORD_OF_UNMAKING and _unmaking_used_this_floor:
		return {"can_use": false, "reason": "Already used this floor."}

	var cost: int = get_effective_voice_cost(ability_id)
	if cost > 0 and get_voice_charges() < cost:
		return {"can_use": false, "reason": "Not enough voice charges (%d required, %d available)." % [cost, get_voice_charges()]}

	return {"can_use": true, "reason": ""}

func get_voice_cost(ability_id: int) -> int:
	match ability_id:
		LoreAbility.HIDDEN_WAYS: return 2
		LoreAbility.WORD_OF_OPENING: return 2
		LoreAbility.DEEP_MEMORY: return 2
		LoreAbility.HERBCRAFT: return 1       # Sustained: 1/turn
		LoreAbility.WORD_OF_COMMAND: return 3
		LoreAbility.SONG_OF_FREEDOM: return 1  # Sustained: 1/turn
		LoreAbility.SONG_OF_LORIEN: return 1   # Sustained: 1/turn
		LoreAbility.SONG_OF_BANISHMENT: return 3
		LoreAbility.WORD_OF_DOMINATION: return 4
		LoreAbility.SONG_OF_AULE: return 2     # Sustained: 2/turn
		LoreAbility.SONG_OF_HEALING: return 1   # Sustained: 1/turn
		LoreAbility.WORD_OF_WARDING: return 3
		LoreAbility.WORD_OF_AUTHORITY: return 4
		LoreAbility.WORD_OF_UNMAKING: return 5
		LoreAbility.SONG_OF_THE_TREES: return 1 # Sustained: 1/turn
		_: return 0  # Passive or no cost

func get_effective_voice_cost(ability_id: int) -> int:
	var cost: int = get_voice_cost(ability_id)
	if cost > 0 and player and player.trait_effect_id == "echoes_firstborn":
		if ability_id >= 140 and ability_id <= 159:
			cost = maxi(1, cost - 1)
	return cost

func get_ability_type(ability_id: int) -> AbilityType:
	match ability_id:
		LoreAbility.HERBCRAFT, LoreAbility.SONG_OF_FREEDOM, \
		LoreAbility.SONG_OF_LORIEN, LoreAbility.SONG_OF_AULE, \
		LoreAbility.SONG_OF_HEALING, LoreAbility.SONG_OF_THE_TREES:
			return AbilityType.SUSTAINED
		LoreAbility.LORE_OF_NAMING, LoreAbility.LIGHT_OF_ELDAR, \
		LoreAbility.LORE_OF_ENDURANCE, LoreAbility.MASTERY_OF_THEMES, \
		LoreAbility.GRACE:
			return AbilityType.PASSIVE
		_:
			return AbilityType.ACTIVE

# ============================================================================
# ABILITY ACTIVATION
# ============================================================================

func activate_ability(ability_id: int, target: Variant = null) -> bool:
	# Handle sustained song toggle
	if get_ability_type(ability_id) == AbilityType.SUSTAINED:
		return _toggle_song(ability_id)

	var check: Dictionary = can_use_ability(ability_id)
	if not check.can_use:
		GameManager.log_message(check.reason, ThemeColors.MSG_ERROR)
		ability_failed.emit(ability_id, check.reason)
		return false

	# Consume voice charges
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
		LoreAbility.HIDDEN_WAYS:
			return _hidden_ways()
		LoreAbility.WORD_OF_OPENING:
			return _word_of_opening()
		LoreAbility.DEEP_MEMORY:
			return _deep_memory()
		LoreAbility.WORD_OF_COMMAND:
			return _word_of_command()
		LoreAbility.SONG_OF_BANISHMENT:
			return _song_of_banishment()
		LoreAbility.WORD_OF_DOMINATION:
			return _word_of_domination(target)
		LoreAbility.WORD_OF_WARDING:
			return _word_of_warding(target)
		LoreAbility.WORD_OF_AUTHORITY:
			return _word_of_authority()
		LoreAbility.WORD_OF_UNMAKING:
			return _word_of_unmaking(target)
		_:
			GameManager.log_message("Ability not implemented.", ThemeColors.MSG_SYSTEM)
			return false

# ============================================================================
# ACTIVE ABILITY IMPLEMENTATIONS
# ============================================================================

## Lore of Hidden Ways (140): Status-based perception drain — BUG FIX
## Uses apply_status so perception restores on expiry (no permanent drain)
func _hidden_ways() -> bool:
	if not player or not GameManager.current_level:
		return false

	var lore_skill: int = player.get_effective_skill("lore")
	var radius: int = 4 + (lore_skill / 3)
	var duration: int = 5 + (lore_skill / 2)
	var drain_amount: int = maxi(1, lore_skill / 2)

	var affected: int = 0
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, radius)

	GameManager.log_message("A blanket of silence falls around you.", ThemeColors.MSG_INFO)

	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue

		var monster: Monster = entity
		# Status-based drain: perception restores when status expires
		monster.apply_status(Constants.EFFECT_PERCEPTION_DRAINED, duration)
		monster.set_meta("perception_drain_amount", drain_amount)
		monster.perception = maxi(0, monster.perception - drain_amount)
		affected += 1

	if affected > 0:
		GameManager.log_message("Enemies struggle to perceive you.", ThemeColors.ABILITY_LEARNED)

	start_cooldown(LoreAbility.HIDDEN_WAYS, 12)
	return true

## Word of Opening (141): Unlock doors, clear rubble in radius
func _word_of_opening() -> bool:
	if not player or not GameManager.current_level:
		return false

	var level: Level = GameManager.current_level
	var lore_skill: int = player.get_effective_skill("lore")
	var radius: int = 3 + (lore_skill / 3)
	var opened: int = 0

	GameManager.log_message("You speak words of unbinding!", ThemeColors.MSG_INFO)

	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos: Vector2i = player.grid_position + Vector2i(dx, dy)
			if not level.is_in_bounds(pos):
				continue

			var dist: int = maxi(absi(dx), absi(dy))
			if dist > radius:
				continue

			var tile: int = level.get_tile(pos)
			if tile == Level.Tile.DOOR_CLOSED:
				level.set_tile(pos, Level.Tile.DOOR_OPEN)
				opened += 1
			elif tile == Level.Tile.RUBBLE:
				level.set_tile(pos, Level.Tile.FLOOR)
				opened += 1

	if opened > 0:
		GameManager.log_message("The way is opened! (%d barriers cleared)" % opened, ThemeColors.ABILITY_LEARNED)
	else:
		GameManager.log_message("There is nothing to open nearby.", ThemeColors.MSG_SYSTEM)

	start_cooldown(LoreAbility.WORD_OF_OPENING, 8)
	return true

## Deep Memory (142): Reveal nearby dungeon layout
func _deep_memory() -> bool:
	if not player:
		return false
	var level: Level = GameManager.current_level
	if not level:
		return false

	var lore_skill: int = player.get_effective_skill("lore")
	var radius: int = clampi(lore_skill * 3, 5, 30)
	var center: Vector2i = player.grid_position
	var revealed: int = 0

	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos := Vector2i(center.x + dx, center.y + dy)
			if not level.is_in_bounds(pos):
				continue
			var idx: int = pos.y * level.width + pos.x
			if not level.explored[idx]:
				level.explored[idx] = true
				revealed += 1

	if revealed > 0:
		level.apply_fov_to_tilemap()
		GameManager.log_message("Ancient knowledge floods your mind... the dungeon layout becomes clear.", ThemeColors.ABILITY_LEARNED)
	else:
		GameManager.log_message("You focus your deep memory, but the surroundings are already known to you.", ThemeColors.MSG_SYSTEM)
	return true

## Word of Command (146): AOE fear/stun, 12-turn CD, NO +5 advantage
func _word_of_command() -> bool:
	if not player or not GameManager.current_level:
		return false

	var lore_skill: int = player.get_effective_skill("lore")
	var radius: int = 2 + (lore_skill / 4)
	var fear_duration: int = 5 + lore_skill

	var affected: int = 0
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, radius)

	GameManager.log_message("You speak a word of terrible power!", ThemeColors.MSG_INFO)

	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue

		var monster: Monster = entity
		var monster_will: int = monster.monster_data.will if monster.monster_data else 5

		# Immunity check: monsters with Will > player Lore + 10 are immune
		if monster_will > lore_skill + 10:
			GameManager.log_message("%s is too powerful to command!" % monster.entity_name, ThemeColors.MSG_WARNING)
			continue

		# No +5 advantage (v4 change)
		var player_roll: int = randi_range(1, 20) + lore_skill
		var monster_roll: int = randi_range(1, 20) + monster_will

		if player_roll > monster_roll:
			monster.apply_status(Constants.EFFECT_AFRAID, fear_duration)
			monster.set_meta("word_of_command_fear", true)
			monster.set_meta("word_of_command_save_dc", 10 + lore_skill)
			var no_resist_turns: int = 3 + lore_skill / 4
			monster.set_meta("word_of_command_no_resist", no_resist_turns)

			if lore_skill >= 8:
				var stun_duration: int = lore_skill / 3
				if stun_duration > 0:
					monster.apply_status(Constants.EFFECT_STUNNED, stun_duration)
					GameManager.log_message("The %s is stunned and paralyzed with fear!" % monster.entity_name, ThemeColors.MSG_WARNING)
				else:
					GameManager.log_message("The %s cowers in fear!" % monster.entity_name, ThemeColors.MSG_WARNING)
			else:
				GameManager.log_message("The %s cowers in fear!" % monster.entity_name, ThemeColors.MSG_WARNING)

			monster.current_morale -= (40 + lore_skill * 2)
			affected += 1
		else:
			GameManager.log_message("The %s resists your word." % monster.entity_name, ThemeColors.MSG_SYSTEM)

	if affected == 0:
		GameManager.log_message("No enemies were affected.", ThemeColors.MSG_SYSTEM)

	start_cooldown(LoreAbility.WORD_OF_COMMAND, 12)
	return true

## Song of Banishment (150): [lore/2]d6 undead damage + 5-turn flee, 1/floor
func _song_of_banishment() -> bool:
	if not player or not GameManager.current_level:
		return false

	var lore_skill: int = player.get_effective_skill("lore")
	var grace: int = player.grace if player.grace else 0
	var radius: int = 3
	var damage_dice: int = maxi(1, lore_skill / 2)

	var affected: int = 0
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, radius)

	GameManager.log_message("You sing a song of banishment against the dead!", ThemeColors.MSG_INFO)

	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue

		var monster: Monster = entity
		if not monster.monster_data or not monster.monster_data.has_flag("UNDEAD"):
			continue

		var monster_will: int = monster.monster_data.will if monster.monster_data else 5
		var player_roll: int = randi_range(1, 20) + grace + lore_skill
		var monster_roll: int = randi_range(1, 20) + monster_will

		if player_roll > monster_roll:
			# Deal [lore/2]d6 damage
			var total_damage: int = 0
			for _i in range(damage_dice):
				total_damage += randi_range(1, 6)
			if total_damage > 0:
				monster.take_damage(total_damage, "holy", player)
				GameManager.log_message("The %s is seared by holy light! (%d damage)" % [monster.entity_name, total_damage], ThemeColors.COMBAT_HIT_COLOR)

			# Force flee for 5 turns (ignores NO_FEAR)
			monster.current_morale = -100
			monster.apply_status(Constants.EFFECT_AFRAID, 5)
			affected += 1
			GameManager.log_message("The %s is driven back by your song!" % monster.entity_name, ThemeColors.MSG_WARNING)
		else:
			GameManager.log_message("The %s resists the banishment." % monster.entity_name, ThemeColors.MSG_SYSTEM)

	if affected == 0:
		GameManager.log_message("No undead were affected.", ThemeColors.MSG_SYSTEM)
	else:
		GameManager.log_message("%d undead banished!" % affected, ThemeColors.ABILITY_LEARNED)

	start_cooldown(LoreAbility.SONG_OF_BANISHMENT, 9999)
	return true

## Word of Domination (151): Charm monster for lore/2 turns
func _word_of_domination(target: Variant) -> bool:
	if not player or not target:
		GameManager.log_message("Select a target for Word of Domination.", ThemeColors.MSG_WARNING)
		return false

	if not target is Monster:
		GameManager.log_message("Invalid target.", ThemeColors.MSG_ERROR)
		return false

	var monster: Monster = target
	var lore_skill: int = player.get_effective_skill("lore")

	# Uniques immune
	if monster.is_unique:
		GameManager.log_message("The %s is too powerful to dominate!" % monster.entity_name, ThemeColors.MSG_ERROR)
		return false

	# Will contest
	var monster_will: int = monster.monster_data.will if monster.monster_data else 5
	var player_roll: int = randi_range(1, 20) + lore_skill
	var monster_roll: int = randi_range(1, 20) + monster_will

	if player_roll > monster_roll:
		var duration: int = maxi(2, lore_skill / 2)
		monster.dominate(player, duration)
		monster.apply_status(Constants.EFFECT_DOMINATED, duration)
		if not player.dominated_monsters.has(monster):
			player.dominated_monsters.append(monster)
		return true
	else:
		GameManager.log_message("The %s shakes off your command!" % monster.entity_name, ThemeColors.MSG_SYSTEM)
		return false

## Word of Warding (154): Place impassable sigil at target tile
func _word_of_warding(target: Variant) -> bool:
	if not player or not GameManager.current_level:
		return false

	var level: Level = GameManager.current_level
	var lore_skill: int = player.get_effective_skill("lore")

	# Max 3 sigils
	if active_sigils.size() >= 3:
		GameManager.log_message("You cannot maintain more than 3 warding sigils.", ThemeColors.MSG_ERROR)
		return false

	# Target must be an adjacent floor tile
	var target_pos: Vector2i
	if target is Vector2i:
		target_pos = target
	else:
		# Default to player position (will fail if not floor)
		target_pos = player.grid_position
		GameManager.log_message("Select a floor tile for the warding sigil.", ThemeColors.MSG_WARNING)
		return false

	var dist: int = maxi(absi(target_pos.x - player.grid_position.x), absi(target_pos.y - player.grid_position.y))
	if dist > 1:
		GameManager.log_message("Target is too far away.", ThemeColors.MSG_ERROR)
		return false

	var tile: int = level.get_tile(target_pos)
	if tile != Level.Tile.FLOOR:
		GameManager.log_message("You can only place a sigil on open floor.", ThemeColors.MSG_ERROR)
		return false

	# Place sigil
	var duration: int = lore_skill * 3
	level.set_tile(target_pos, Level.Tile.GLYPH_OF_WARDING)
	active_sigils.append({"pos": target_pos, "turns_remaining": duration})
	GameManager.log_message("You inscribe a warding sigil on the floor.", ThemeColors.ABILITY_LEARNED)
	return true

## Word of Authority (155): AOE stun via commanding presence
func _word_of_authority() -> bool:
	if not player or not GameManager.current_level:
		return false

	var lore_skill: int = player.get_effective_skill("lore")
	var radius: int = 2 + (lore_skill / 4)
	var stun_duration: int = 2 + (lore_skill / 4)

	var affected: int = 0
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, radius)

	GameManager.log_message("You speak with absolute authority!", ThemeColors.MSG_INFO)

	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue

		var monster: Monster = entity
		var monster_will: int = monster.monster_data.will if monster.monster_data else 5

		var player_roll: int = randi_range(1, 20) + lore_skill
		var monster_roll: int = randi_range(1, 20) + monster_will

		if player_roll > monster_roll:
			monster.apply_status(Constants.EFFECT_STUNNED, stun_duration)
			affected += 1
			GameManager.log_message("The %s is stunned by your authority!" % monster.entity_name, ThemeColors.MSG_WARNING)
		else:
			GameManager.log_message("The %s resists your authority." % monster.entity_name, ThemeColors.MSG_SYSTEM)

	if affected == 0:
		GameManager.log_message("No enemies were affected.", ThemeColors.MSG_SYSTEM)

	start_cooldown(LoreAbility.WORD_OF_AUTHORITY, 20)
	return true

## Word of Unmaking (156): Dispel + terrain + undead dmg, 50% -1 max voice, 1/floor
func _word_of_unmaking(target: Variant) -> bool:
	if not player or not GameManager.current_level:
		return false

	var level: Level = GameManager.current_level
	var lore_skill: int = player.get_effective_skill("lore")

	GameManager.log_message("You speak a Word of terrible Unmaking!", ThemeColors.MSG_ERROR)

	# Destroy rubble/walls in radius 2 -> floor
	var terrain_radius: int = 2
	for dy in range(-terrain_radius, terrain_radius + 1):
		for dx in range(-terrain_radius, terrain_radius + 1):
			var pos: Vector2i = player.grid_position + Vector2i(dx, dy)
			if not level.is_in_bounds(pos):
				continue
			var dist: int = maxi(absi(dx), absi(dy))
			if dist > terrain_radius:
				continue
			var tile: int = level.get_tile(pos)
			if tile == Level.Tile.RUBBLE or tile == Level.Tile.WALL:
				level.set_tile(pos, Level.Tile.FLOOR)

	# [lore]d6 damage to undead in radius 3, stun living 2 turns
	var damage_radius: int = 3
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, damage_radius)
	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue
		var monster: Monster = entity
		if monster.monster_data and monster.monster_data.has_flag("UNDEAD"):
			var total_damage: int = 0
			for _i in range(lore_skill):
				total_damage += randi_range(1, 6)
			if total_damage > 0:
				monster.take_damage(total_damage, "unmaking", player)
				GameManager.log_message("The %s is torn apart by unmaking! (%d damage)" % [monster.entity_name, total_damage], ThemeColors.COMBAT_HIT_COLOR)
		else:
			monster.apply_status(Constants.EFFECT_STUNNED, 2)
			GameManager.log_message("The %s is stunned by the unmaking!" % monster.entity_name, ThemeColors.MSG_WARNING)

	# 50% chance to lose 1 max voice permanently
	if randi_range(0, 1) == 0:
		player.max_voice = maxi(1, player.max_voice - 1)
		player.voice_charges = mini(player.voice_charges, player.max_voice)
		voice_charges_changed.emit(player.voice_charges, player.max_voice)
		GameManager.log_message("The Word of Unmaking tears at your very spirit! (-1 max voice)", ThemeColors.MSG_ERROR)
	else:
		GameManager.log_message("You endure the strain of the Unmaking.", ThemeColors.MSG_WARNING)

	_unmaking_used_this_floor = true
	start_cooldown(LoreAbility.WORD_OF_UNMAKING, 9999)
	return true

# ============================================================================
# SUSTAINED SONG TICK IMPLEMENTATIONS
# ============================================================================

## Herbcraft (143): Remove bleeding, flag for +50% rest regen
func _tick_herbcraft() -> void:
	if not player:
		return
	# Stop bleeding
	if player.status_fx and player.status_fx.has_effect("cut"):
		player.status_fx.remove_effect("cut")
		GameManager.log_message("Your herbcraft knowledge staunches the bleeding.", ThemeColors.ABILITY_LEARNED)

## Song of Lorien (148): Drain alertness of nearby monsters -> sleep
func _tick_song_of_lorien() -> void:
	if not player or not GameManager.current_level:
		return

	var lore_skill: int = player.get_effective_skill("lore")
	var alertness_drain: int = maxi(1, lore_skill / 3)
	var radius: int = 5

	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, radius)
	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue

		var monster: Monster = entity
		# Skip sleep-immune monsters
		if monster.monster_data and monster.monster_data.has_flag("NO_SLEEP"):
			continue

		monster.alertness -= alertness_drain
		if monster.alertness <= Constants.ALERTNESS_MIN and not monster.is_sleeping:
			monster.is_sleeping = true
			monster.ai_state = Monster.AIState.IDLE
			GameManager.log_message("The %s drifts into slumber." % monster.entity_name, ThemeColors.MSG_INFO)

## Song of Healing (153): Heal lore/2 HP per turn
func _tick_song_of_healing() -> void:
	if not player:
		return

	var lore_skill: int = player.get_effective_skill("lore")
	var heal_amount: int = maxi(1, lore_skill / 2)

	if player.current_health < player.max_health:
		player.current_health = mini(player.current_health + heal_amount, player.max_health)
		if heal_amount > 0:
			GameManager.log_message("Your healing song restores %d health." % heal_amount, ThemeColors.ABILITY_LEARNED)

	# Also heal dominated monsters in radius 3
	if not player.dominated_monsters.is_empty() and GameManager.current_level:
		for monster in player.dominated_monsters:
			if is_instance_valid(monster) and monster.is_dominated:
				var dist: int = maxi(absi(monster.grid_position.x - player.grid_position.x), absi(monster.grid_position.y - player.grid_position.y))
				if dist <= 3 and monster.current_health < monster.max_health:
					monster.current_health = mini(monster.current_health + heal_amount, monster.max_health)

# ============================================================================
# WARDING SIGIL TICK
# ============================================================================

func _tick_sigils() -> void:
	if active_sigils.is_empty():
		return
	var level: Level = GameManager.current_level
	if not level:
		return

	var expired: Array[int] = []
	for i in range(active_sigils.size()):
		active_sigils[i].turns_remaining -= 1
		if active_sigils[i].turns_remaining <= 0:
			expired.append(i)

	# Remove expired sigils in reverse order
	for i in range(expired.size() - 1, -1, -1):
		var idx: int = expired[i]
		var pos: Vector2i = active_sigils[idx].pos
		# Restore to floor
		if level.is_in_bounds(pos) and level.get_tile(pos) == Level.Tile.GLYPH_OF_WARDING:
			level.set_tile(pos, Level.Tile.FLOOR)
		active_sigils.remove_at(idx)
		GameManager.log_message("A warding sigil fades.", ThemeColors.TEXT_SECONDARY)

# ============================================================================
# LIGHT OF THE ELDAR PASSIVE TICK
# ============================================================================

func _tick_light_of_eldar() -> void:
	if not player or not has_ability(LoreAbility.LIGHT_OF_ELDAR):
		return
	if not GameManager.current_level:
		return

	var light_radius: int = player.get_light_radius()
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(player.grid_position, light_radius)

	for entity in entities:
		if entity == player or not is_instance_valid(entity):
			continue
		if not entity is Monster:
			continue
		var monster: Monster = entity
		# Wraiths (SHADOW + UNDEAD) take 1 damage per turn
		if monster.monster_data and monster.monster_data.has_flag("SHADOW") and monster.monster_data.has_flag("UNDEAD"):
			monster.take_damage(1, "light", player)

# ============================================================================
# PASSIVE ABILITY CHECKS (called from other systems)
# ============================================================================

## Herbcraft (143): Double healing from herbs — called when using healing items
func apply_herbcraft_bonus(base_heal: int) -> int:
	if is_singing_song(LoreAbility.HERBCRAFT):
		GameManager.log_message("Your knowledge of herbs enhances the healing!", ThemeColors.ABILITY_LEARNED)
		return base_heal * 2
	return base_heal

## Lore of Endurance (149): +Will/2, +2d2 protection — returns bonus values
func get_endurance_bonuses() -> Dictionary:
	if not has_ability(LoreAbility.LORE_OF_ENDURANCE):
		return {"will_bonus": 0, "protection_dice": 0, "protection_sides": 0}

	if not player:
		return {"will_bonus": 0, "protection_dice": 0, "protection_sides": 0}

	var lore_skill: int = player.get_effective_skill("lore")
	return {
		"will_bonus": lore_skill / 2,
		"protection_dice": 2,
		"protection_sides": 2
	}

## Lore of Naming (144): +2 Will bonus vs known monster types
func get_naming_will_bonus(monster: Monster) -> int:
	if not has_ability(LoreAbility.LORE_OF_NAMING) or not player:
		return 0
	if not monster or not monster.monster_data:
		return 0
	# Check if player has killed this type before
	var monster_name: String = monster.entity_name
	if player.kills_by_name.has(monster_name) and player.kills_by_name[monster_name] > 0:
		return 2
	return 0

## Light of the Eldar (145): Shadow creature combat penalties
func get_light_of_eldar_attack_penalty(monster: Monster) -> int:
	if not has_ability(LoreAbility.LIGHT_OF_ELDAR):
		return 0
	if monster.monster_data and monster.monster_data.has_flag("SHADOW"):
		return -2  # -2 attack for shadow creatures
	return 0

func get_light_of_eldar_evasion_penalty(monster: Monster) -> int:
	if not has_ability(LoreAbility.LIGHT_OF_ELDAR):
		return 0
	if monster.monster_data and monster.monster_data.has_flag("SHADOW"):
		return -2  # -2 evasion for shadow creatures
	return 0

## Song of Freedom (147): Will contest to resist incoming status
func try_freedom_resist(effect_power: int) -> bool:
	if not is_singing_song(LoreAbility.SONG_OF_FREEDOM) or not player:
		return false

	var lore_skill: int = player.get_effective_skill("lore")
	var player_roll: int = randi_range(1, 20) + lore_skill
	var effect_roll: int = randi_range(1, 20) + effect_power / 2

	if player_roll > effect_roll:
		GameManager.log_message("Your Song of Freedom shields you from the effect!", ThemeColors.ABILITY_LEARNED)
		return true
	else:
		# Song disrupted on failure
		GameManager.log_message("Your Song of Freedom falters as the effect takes hold!", ThemeColors.MSG_WARNING)
		if player.active_song_id == LoreAbility.SONG_OF_FREEDOM:
			stop_song()
		elif player.active_song_id_2 == LoreAbility.SONG_OF_FREEDOM:
			stop_song_2()
		return false

## Grace (158): Passive +1 Grace stat — called on ability learn
func apply_grace_bonus() -> void:
	if has_ability(LoreAbility.GRACE) and player:
		if not player.has_meta("grace_ability_applied"):
			player.grace += 1
			player.set_meta("grace_ability_applied", true)
			GameManager.log_message("Your grace increases from ancient wisdom.", ThemeColors.ABILITY_LEARNED)

## Lore of Endurance (149): Apply temp +2 Will after taking damage
func apply_endurance_will_boost() -> void:
	if not has_ability(LoreAbility.LORE_OF_ENDURANCE) or not player:
		return
	player.apply_status(Constants.EFFECT_ENDURANCE_WILL, 3)
	player.set_meta("endurance_will_bonus", 2)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _get_skill_for_ability(ability_id: int) -> int:
	if ability_id >= 140 and ability_id <= 159:
		return Constants.Skill.S_LOR
	return -1

func _get_ability_index(ability_id: int) -> int:
	if ability_id >= 140 and ability_id <= 159:
		return ability_id - 140
	return -1

func _get_ability_name(ability_id: int) -> String:
	match ability_id:
		LoreAbility.HIDDEN_WAYS: return "Lore of Hidden Ways"
		LoreAbility.WORD_OF_OPENING: return "Word of Opening"
		LoreAbility.DEEP_MEMORY: return "Deep Memory"
		LoreAbility.HERBCRAFT: return "Herbcraft"
		LoreAbility.LORE_OF_NAMING: return "Lore of Naming"
		LoreAbility.LIGHT_OF_ELDAR: return "Light of the Eldar"
		LoreAbility.WORD_OF_COMMAND: return "Word of Command"
		LoreAbility.SONG_OF_FREEDOM: return "Song of Freedom"
		LoreAbility.SONG_OF_LORIEN: return "Song of Lorien"
		LoreAbility.LORE_OF_ENDURANCE: return "Lore of Endurance"
		LoreAbility.SONG_OF_BANISHMENT: return "Song of Banishment"
		LoreAbility.WORD_OF_DOMINATION: return "Word of Domination"
		LoreAbility.SONG_OF_AULE: return "Song of Aule"
		LoreAbility.SONG_OF_HEALING: return "Song of Healing"
		LoreAbility.WORD_OF_WARDING: return "Word of Warding"
		LoreAbility.WORD_OF_AUTHORITY: return "Word of Authority"
		LoreAbility.WORD_OF_UNMAKING: return "Word of Unmaking"
		LoreAbility.MASTERY_OF_THEMES: return "Mastery of Themes"
		LoreAbility.GRACE: return "Grace"
		LoreAbility.SONG_OF_THE_TREES: return "Song of the Trees"
		_: return "Unknown Ability"

## Get list of all implemented Lore abilities
func get_lore_abilities() -> Array[int]:
	return [
		LoreAbility.HIDDEN_WAYS,
		LoreAbility.WORD_OF_OPENING,
		LoreAbility.DEEP_MEMORY,
		LoreAbility.HERBCRAFT,
		LoreAbility.LORE_OF_NAMING,
		LoreAbility.LIGHT_OF_ELDAR,
		LoreAbility.WORD_OF_COMMAND,
		LoreAbility.SONG_OF_FREEDOM,
		LoreAbility.SONG_OF_LORIEN,
		LoreAbility.LORE_OF_ENDURANCE,
		LoreAbility.SONG_OF_BANISHMENT,
		LoreAbility.WORD_OF_DOMINATION,
		LoreAbility.SONG_OF_AULE,
		LoreAbility.SONG_OF_HEALING,
		LoreAbility.WORD_OF_WARDING,
		LoreAbility.WORD_OF_AUTHORITY,
		LoreAbility.WORD_OF_UNMAKING,
		LoreAbility.MASTERY_OF_THEMES,
		LoreAbility.GRACE,
		LoreAbility.SONG_OF_THE_TREES,
	]

## Get learned ACTIVE lore abilities the player can invoke via the voice menu
func get_learned_active_abilities() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var active_ids: Array[int] = [
		LoreAbility.HIDDEN_WAYS,
		LoreAbility.WORD_OF_OPENING,
		LoreAbility.DEEP_MEMORY,
		LoreAbility.WORD_OF_COMMAND,
		LoreAbility.SONG_OF_BANISHMENT,
		LoreAbility.WORD_OF_DOMINATION,
		LoreAbility.WORD_OF_WARDING,
		LoreAbility.WORD_OF_AUTHORITY,
		LoreAbility.WORD_OF_UNMAKING,
		# Sustained songs (toggleable from menu)
		LoreAbility.HERBCRAFT,
		LoreAbility.SONG_OF_FREEDOM,
		LoreAbility.SONG_OF_LORIEN,
		LoreAbility.SONG_OF_AULE,
		LoreAbility.SONG_OF_HEALING,
		LoreAbility.SONG_OF_THE_TREES,
	]
	for id in active_ids:
		if has_ability(id):
			var check: Dictionary = can_use_ability(id)
			var is_sustained: bool = get_ability_type(id) == AbilityType.SUSTAINED
			var is_active_song: bool = player != null and (player.active_song_id == id or player.active_song_id_2 == id)
			var display_name: String = _get_ability_name(id)
			if is_active_song:
				display_name += " [SINGING]"
			result.append({
				"id": id,
				"name": display_name,
				"cost": get_effective_voice_cost(id),
				"can_use": check.can_use if not is_active_song else true,
				"reason": check.reason if not is_active_song else "Stop singing",
				"needs_target": _ability_needs_target(id),
				"is_sustained": is_sustained,
			})
	return result

## Whether an ability requires a monster target
func _ability_needs_target(ability_id: int) -> bool:
	match ability_id:
		LoreAbility.WORD_OF_DOMINATION:
			return true
		LoreAbility.WORD_OF_WARDING:
			return true  # Needs tile target
		_:
			return false
