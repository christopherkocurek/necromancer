extends Entity
class_name Monster
## Base class for all monsters.
## Implements Sil-Q alertness/morale system.

enum AIState { IDLE, WANDERING, HUNTING, FLEEING }

@export var monster_data: Resource = null
var ai_state: AIState = AIState.IDLE
var target: Entity = null
var home_position: Vector2i = Vector2i.ZERO
var last_known_player_pos: Vector2i = Vector2i(-1, -1)

# Alertness system (Sil-Q: continuous spectrum from -20 to +20)
# < -10: Unwary (can be assassinated)
# >= 0: Alert (full combat awareness)
var alertness: int = Constants.ALERTNESS_ALERT  # Start alert
var perception: int = 5  # Base perception stat
var perception_range: int = 10
var experience_value: int = 10

# Morale system (Sil-Q style)
var base_morale: int = Constants.BASE_MORALE
var current_morale: int = Constants.BASE_MORALE
var rally_bonus: int = 0
var stance: Constants.Stance = Constants.Stance.CONFIDENT

# Monster-specific flags
var is_unique: bool = false
var is_undead: bool = false
var is_dragon: bool = false
var can_open_doors: bool = false
var never_moves: bool = false
var is_invisible: bool = false
var is_sleeping: bool = false
var is_mindless: bool = false
var is_territorial: bool = false  # Won't flee from home
var is_cowardly: bool = false  # Flees easier
var is_brave: bool = false  # Won't flee unless critical
var is_pack_leader: bool = false
var pack_id: int = -1  # For escort/pack morale bonuses

var health_bar: EntityHealthBar = null

func _ready() -> void:
	super._ready()
	home_position = grid_position
	_setup_health_bar()

func _setup_health_bar() -> void:
	health_bar = EntityHealthBar.new()
	health_bar.setup(self)
	health_bar.visible = false
	add_child(health_bar)

func update_health_bar(knowledge_tier: int) -> void:
	if health_bar:
		health_bar.update_display(knowledge_tier)

func initialize_from_data(data: DataManager.MonsterData) -> void:
	if not data:
		return

	entity_name = data.name
	current_health = data.roll_health()
	max_health = current_health
	evasion_bonus = data.evasion
	speed = data.speed
	perception = data.alertness  # Data's alertness is actually perception stat
	experience_value = data.experience

	# Initial alertness based on monster type
	if data.has_flag("SLEEPING"):
		alertness = Constants.ALERTNESS_MIN  # Deep sleep
		is_sleeping = true
	else:
		alertness = Constants.ALERTNESS_ALERT  # Start alert by default

	# Parse protection dice (e.g., "1d4" -> dice=1, sides=4)
	if not data.protection_dice.is_empty():
		var prot_parts := data.protection_dice.split("d")
		if prot_parts.size() >= 2:
			protection_dice = int(prot_parts[0])
			protection_sides = int(prot_parts[1])

	# Give monster initial energy based on speed
	energy = randi_range(0, Constants.ACTION_COST - 1)  # Stagger initial energy

	# Set sprite based on monster index directly (not display char, since multiple monsters share chars)
	var atlas_coords := TileMapper.get_monster_coords(data.index)
	set_sprite_from_atlas_coords(atlas_coords)

	# Parse flags using has_flag (works with both legacy array and bitflags)
	is_unique = data.has_flag("UNIQUE")
	is_undead = data.has_flag("UNDEAD")
	is_dragon = data.has_flag("DRAGON")
	can_open_doors = data.has_flag("OPEN_DOOR")
	never_moves = data.has_flag("NEVER_MOVE")
	is_invisible = data.has_flag("INVISIBLE")
	is_mindless = data.has_flag("MINDLESS") or data.has_flag("EMPTY_MIND")
	is_cowardly = data.has_flag("COWARD")
	is_brave = data.has_flag("BRAVE") or is_unique  # Uniques are brave

	# Morale modifiers from flags
	if is_cowardly:
		base_morale = Constants.BASE_MORALE / 2
	elif is_brave:
		base_morale = Constants.BASE_MORALE * 2
	current_morale = base_morale

	# Set up attacks from data
	if data.attacks.size() > 0:
		var primary_attack := data.attacks[0]
		if primary_attack.damage_dice:
			damage_dice = primary_attack.damage_dice
		# Set melee attack bonus from attack data
		melee_bonus = primary_attack.attack_bonus

# ============================================================================
# AI
# ============================================================================

func take_turn() -> void:
	if not is_alive or never_moves:
		return

	# Check if monster has energy to act (energy consumed by TurnSystem)
	if not can_act():
		return

	# STUNNED/ENTRANCED: Skip turn entirely
	if not can_take_turn():
		return

	EventBus.turn_started.emit(self)

	# CONFUSED: Random movement instead of normal AI
	if status_fx and status_fx.is_confused():
		_confused_behavior()
		EventBus.turn_ended.emit(self)
		return

	# AFRAID: Override to fleeing regardless of morale
	if status_fx and status_fx.is_afraid():
		_flee_behavior()
		EventBus.turn_ended.emit(self)
		return

	# Update AI state
	_update_ai_state()

	# BLIND: Can't see player, wander instead of hunt
	if status_fx and status_fx.is_blind():
		if ai_state == AIState.HUNTING:
			_wander_behavior()
			EventBus.turn_ended.emit(self)
			return

	# Act based on state
	match ai_state:
		AIState.IDLE:
			_idle_behavior()
		AIState.WANDERING:
			_wander_behavior()
		AIState.HUNTING:
			_hunt_behavior()
		AIState.FLEEING:
			_flee_behavior()

	EventBus.turn_ended.emit(self)

func _confused_behavior() -> void:
	# Random movement when confused
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	directions.shuffle()
	for dir: Vector2i in directions:
		if can_move_to(grid_position + dir):
			try_move(dir)
			return

func _update_ai_state() -> void:
	var player := GameManager.player
	if not player:
		return

	var distance_to_player := _grid_distance(grid_position, player.grid_position)

	# Check line of sight
	var has_los := false
	if distance_to_player <= perception_range and GameManager.current_level:
		has_los = GameManager.current_level.has_los_to(grid_position, player.grid_position)

	# Update alertness based on perception
	_update_alertness(player, has_los, distance_to_player)

	# Calculate current morale
	_update_morale()

	# Determine stance from morale
	_update_stance()

	# Set AI state based on alertness and stance
	if is_sleeping:
		ai_state = AIState.IDLE
	elif alertness < Constants.ALERTNESS_UNWARY:
		# Unwary - not aware of player
		if ai_state == AIState.IDLE and randf() < 0.1:
			ai_state = AIState.WANDERING
		elif ai_state == AIState.WANDERING and randf() < 0.1:
			ai_state = AIState.IDLE
	elif alertness >= Constants.ALERTNESS_ALERT:
		# Alert - aware of player
		if has_los:
			last_known_player_pos = player.grid_position
			target = player

			# Check stance for fleeing
			if stance == Constants.Stance.FLEEING:
				ai_state = AIState.FLEEING
			else:
				ai_state = AIState.HUNTING
		elif ai_state == AIState.HUNTING:
			# Lost LOS - hunt to last known position
			if last_known_player_pos != Vector2i(-1, -1):
				if grid_position == last_known_player_pos or randf() < 0.2:
					# Reached last known pos or giving up
					last_known_player_pos = Vector2i(-1, -1)
					ai_state = AIState.WANDERING
			else:
				ai_state = AIState.WANDERING
	else:
		# Between unwary and alert - cautious state
		if ai_state == AIState.HUNTING and randf() < 0.3:
			ai_state = AIState.WANDERING

func _update_alertness(player: Player, has_los: bool, distance: int) -> void:
	# Sil-Q alertness: continuous spectrum from -20 to +20
	# Canon section 2.3: d10 opposed rolls, not d20

	if has_los:
		# Player visible — perception roll with LOS bonuses
		var m_per: int = perception
		m_per += player.get_combat_noise()  # Combat noise bonus
		if alertness > Constants.ALERTNESS_ALERT:
			m_per += alertness  # Already alert = harder to hide
		var perception_roll: int = randi_range(1, 10) + m_per

		var difficulty_roll: int = randi_range(1, 10) + player.get_stealth_score()
		# Distance reduces stealth effectiveness (closer = easier to spot)
		difficulty_roll -= maxi(0, 6 - distance)  # Penalty at close range

		var result: int = perception_roll - difficulty_roll
		if result > 0:
			alertness = mini(alertness + result, Constants.ALERTNESS_MAX)
		else:
			alertness = maxi(alertness - 1, Constants.ALERTNESS_MIN)

		# Wake up if sleeping and player very close
		if is_sleeping and distance <= 2:
			_wake_up()
	else:
		# No LOS — opposed perception vs stealth
		var m_per: int = perception
		m_per += player.get_combat_noise()
		if alertness > Constants.ALERTNESS_ALERT:
			m_per += alertness / 2  # Reduced bonus without LOS
		# Distance penalty for hearing
		m_per -= distance / 2

		var perception_roll: int = randi_range(1, 10) + m_per
		var difficulty_roll: int = randi_range(1, 10) + player.get_stealth_score()

		var result: int = perception_roll - difficulty_roll
		if result > 0:
			alertness = mini(alertness + result, Constants.ALERTNESS_MAX)
		elif result < 0:
			alertness = maxi(alertness - 1, Constants.ALERTNESS_MIN)

	# Decay alertness over time when no stimulus
	if not has_los and alertness > Constants.ALERTNESS_ALERT:
		alertness -= 1

func _update_morale() -> void:
	# Sil-Q morale calculation
	current_morale = base_morale

	# Health penalty
	var health_pct := float(current_health) / float(max_health)
	if health_pct < 0.5:
		current_morale -= int((0.5 - health_pct) * 60)  # Up to -30 at 20% health

	# Escort bonus (4x multiplier for nearby allies)
	var escort_count := _count_nearby_allies(Constants.TURN_RANGE)
	current_morale += escort_count * Constants.ESCORT_MULTIPLIER

	# Rally bonus (applied temporarily)
	current_morale += rally_bonus

	# Territorial bonus (won't flee from home)
	if is_territorial:
		var dist_from_home := _grid_distance(grid_position, home_position)
		if dist_from_home <= 5:
			current_morale += 30

	# Mindless creatures don't flee
	if is_mindless:
		current_morale = Constants.BASE_MORALE * 3

func _update_stance() -> void:
	# Stance thresholds from Sil-Q
	if current_morale > 200:
		stance = Constants.Stance.AGGRESSIVE
	elif current_morale > 0:
		stance = Constants.Stance.CONFIDENT
	else:
		stance = Constants.Stance.FLEEING

	# Unique/brave monsters override fleeing
	if stance == Constants.Stance.FLEEING and is_brave:
		if current_health > max_health * 0.1:
			stance = Constants.Stance.CONFIDENT

func _wake_up() -> void:
	if is_sleeping:
		is_sleeping = false
		alertness = Constants.ALERTNESS_ALERT
		GameManager.log_message("The %s wakes up!" % entity_name, ThemeColors.MSG_WARNING)

func _get_player_stealth(player: Player) -> int:
	# Use player's full stealth score (includes mode bonus, noise penalty)
	return player.get_stealth_score()

func _count_nearby_allies(range_tiles: int) -> int:
	var count := 0
	if not GameManager.current_level:
		return 0

	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity):
			continue
		if entity == self or not entity is Monster:
			continue
		if not entity.is_alive:
			continue
		var dist := _grid_distance(grid_position, entity.grid_position)
		if dist <= range_tiles:
			count += 1
	return count

## Called when an ally rallies nearby monsters
func receive_rally(bonus: int = Constants.RALLY_BONUS) -> void:
	rally_bonus = bonus
	# Rally bonus decays each turn
	EventBus.turn_ended.connect(_decay_rally_bonus, CONNECT_ONE_SHOT)

func _decay_rally_bonus() -> void:
	rally_bonus = maxi(0, rally_bonus - 10)

func _idle_behavior() -> void:
	# Just wait
	pass

func _wander_behavior() -> void:
	# Random movement
	var directions := [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	directions.shuffle()

	for dir in directions:
		if can_move_to(grid_position + dir):
			try_move(dir)
			return

func _hunt_behavior() -> void:
	if not target:
		ai_state = AIState.WANDERING
		return

	var dist: int = _grid_distance(grid_position, target.grid_position)

	# Attack if adjacent
	if dist <= 1:
		attack_entity(target)
		return

	# Try to cast a spell if target is visible and in range
	if dist <= perception_range and _try_cast_spell(target, dist):
		return

	# Use A* pathfinding
	if GameManager.current_level:
		var path: Array[Vector2i] = GameManager.current_level.find_path(grid_position, target.grid_position)
		if path.size() > 1:
			var next_pos: Vector2i = path[1]  # path[0] is current position
			var dir: Vector2i = next_pos - grid_position
			if can_move_to(next_pos):
				try_move(dir)
				return

	# Fallback to direct movement
	var direction: Vector2i = _direction_toward(target.grid_position)
	try_move(direction)

func _flee_behavior() -> void:
	var player: Player = GameManager.player
	if not player:
		return

	var distance := _grid_distance(grid_position, player.grid_position)

	# Stop fleeing if far enough (FLEE_RANGE = MAX_SIGHT + 20 = 40)
	if distance > Constants.FLEE_RANGE:
		ai_state = AIState.WANDERING
		# Regain some morale when safe
		rally_bonus = maxi(rally_bonus, 20)
		return

	# Try all directions, pick one that maximizes distance
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]

	var best_dir: Vector2i = Vector2i.ZERO
	var best_dist: int = -1

	for dir: Vector2i in directions:
		var new_pos: Vector2i = grid_position + dir
		if can_move_to(new_pos):
			var dist: int = _grid_distance(new_pos, player.grid_position)
			if dist > best_dist:
				best_dist = dist
				best_dir = dir

	if best_dir != Vector2i.ZERO:
		try_move(best_dir)

# ============================================================================
# PATHFINDING HELPERS
# ============================================================================

## Check if this monster is a large creature (trolls, dragons, raukos, serpents, wargs)
func _is_large_monster() -> bool:
	if not monster_data:
		return false
	return monster_data.has_flag("TROLL") or monster_data.has_flag("DRAGON") or \
		monster_data.has_flag("RAUKO") or monster_data.has_flag("SERPENT") or \
		monster_data.has_flag("WOLF")

func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	# Chebyshev distance (8-directional)
	return max(abs(a.x - b.x), abs(a.y - b.y))

func _direction_toward(target_pos: Vector2i) -> Vector2i:
	var diff := target_pos - grid_position
	return Vector2i(sign(diff.x), sign(diff.y))

func _direction_away_from(target_pos: Vector2i) -> Vector2i:
	var diff := grid_position - target_pos
	return Vector2i(sign(diff.x), sign(diff.y))

func can_move_to(target: Vector2i) -> bool:
	if not GameManager.current_level:
		return false

	# Check terrain
	if GameManager.current_level.has_method("is_passable"):
		if not GameManager.current_level.is_passable(target):
			# Monster door interaction
			var tile: int = GameManager.current_level.get_tile(target)
			if tile == Level.Tile.DOOR_CLOSED and can_open_doors:
				GameManager.current_level.set_tile(target, Level.Tile.DOOR_OPEN)
				GameManager.log_message("The %s opens the door." % entity_name, ThemeColors.MSG_SYSTEM)
				if GameManager.current_level.has_method("add_floor_noise"):
					GameManager.current_level.add_floor_noise(Constants.NOISE_DOOR)
				return false  # Opening door costs move, doesn't move through
			if (tile == Level.Tile.DOOR_JAMMED or tile == Level.Tile.DOOR_LOCKED) and monster_data and monster_data.has_flag("BASH_DOOR"):
				if GameManager.current_level.bash_door(target, strength):
					GameManager.log_message("The %s bashes open the door!" % entity_name, ThemeColors.MSG_WARNING)
					if GameManager.current_level.has_method("add_floor_noise"):
						GameManager.current_level.add_floor_noise(Constants.NOISE_BASH)
				return false
			return false

	# Check for blocking entities (but not the player - we attack them)
	if GameManager.current_level.has_method("get_entity_at"):
		var blocker = GameManager.current_level.get_entity_at(target)
		if is_instance_valid(blocker) and blocker != self:
			# Don't block on player - that's handled in hunt
			if blocker is Player:
				return false  # Will attack instead
			return false

	return true

# ============================================================================
# COMBAT MODIFIERS (Phase A: Sil-Q modifier stack)
# ============================================================================

## Monster attack modifier stack per NECROMANCER_DESIGN_CANON section 1.3
func get_total_attack(target: Entity) -> int:
	var att: int = melee_bonus

	# Stunned: -2
	if status_fx and status_fx.has_effect(Constants.EFFECT_STUNNED):
		att -= 2

	# Overwhelming/Flanking: +1 per adjacent ally
	att += _count_nearby_allies(1)

	# SMALL_STATURE: large monsters get -2 attack vs small races (Hobbits)
	if is_instance_valid(target) and target is Player:
		var p: Player = target as Player
		if p.has_racial_flag("SMALL_STATURE") and _is_large_monster():
			att -= 2

	# Blind: halve attack
	if status_fx and status_fx.is_blind():
		att = att / 2

	return att

## Monster evasion modifier stack per NECROMANCER_DESIGN_CANON section 1.5
func get_total_evasion(attacker: Entity) -> int:
	var evn: int = evasion_bonus

	# Sleeping: evasion overridden to -5 (most severe, checked first)
	if alertness < Constants.ALERTNESS_UNWARY:
		return -5

	# Stunned: -2
	if status_fx and status_fx.has_effect(Constants.EFFECT_STUNNED):
		evn -= 2

	# Unwary (alertness < 0): halve evasion
	if alertness < Constants.ALERTNESS_ALERT:
		evn = evn / 2

	# Blind: halve evasion
	if status_fx and status_fx.is_blind():
		evn = evn / 2

	return evn

## Resolve monster attack special effects (FIRE, COLD, BLIND, etc.)
func _on_successful_hit(target: Entity, _hit_result: int, _damage: int) -> void:
	if not monster_data or monster_data.attacks.is_empty():
		return

	var attack: DataManager.AttackData = monster_data.attacks[0]
	_resolve_attack_effect(target, attack.effect)

func _resolve_attack_effect(target: Entity, effect: String) -> void:
	if not is_instance_valid(target):
		return
	match effect.to_upper():
		"HURT":
			pass  # Already handled by base damage
		"POISON":
			target.apply_status("poisoned", 5 + randi_range(1, 5))
		"FIRE":
			target.apply_status(Constants.EFFECT_BURNING, 3 + randi_range(1, 3))
			if target is Player:
				GameManager.log_message("You are engulfed in flames!", ThemeColors.COMBAT_CRIT)
		"COLD":
			target.apply_status("slow", 3 + randi_range(1, 3))
			if target is Player:
				GameManager.log_message("You feel a terrible chill!", ThemeColors.MSG_INFO)
		"BLIND":
			target.apply_status("blind", 3 + randi_range(1, 3))
		"CONFUSE":
			target.apply_status("confused", 3 + randi_range(1, 5))
		"FEAR":
			target.apply_status("afraid", 5 + randi_range(1, 5))
		"STUN":
			target.apply_status("stunned", 3 + randi_range(1, 3))
		"ENTRANCE":
			target.apply_status("entranced", 2 + randi_range(1, 3))
		"LOSE_STR":
			if target is Player:
				var player: Player = target as Player
				player.strength = maxi(0, player.strength - 1)
				player._recalculate_stats()
				GameManager.log_message("You feel your strength drain away!", ThemeColors.MSG_ERROR)
		"LOSE_CON":
			if target is Player:
				var player: Player = target as Player
				player.constitution = maxi(0, player.constitution - 1)
				player._recalculate_stats()
				player.health = mini(player.health, player.max_health)
				GameManager.log_message("You feel your vitality drain away!", ThemeColors.MSG_ERROR)
		"LOSE_GRA":
			if target is Player:
				var player: Player = target as Player
				player.grace = maxi(0, player.grace - 1)
				player._recalculate_stats()
				GameManager.log_message("You feel your spirit diminish!", ThemeColors.MSG_ERROR)
		"LOSE_STR_CON":
			if target is Player:
				var player: Player = target as Player
				player.strength = maxi(0, player.strength - 1)
				player.constitution = maxi(0, player.constitution - 1)
				player._recalculate_stats()
				player.health = mini(player.health, player.max_health)
				GameManager.log_message("You feel your body weaken!", ThemeColors.MSG_ERROR)
		"LOSE_ALL":
			if target is Player:
				var player: Player = target as Player
				player.strength = maxi(0, player.strength - 1)
				player.dexterity = maxi(0, player.dexterity - 1)
				player.constitution = maxi(0, player.constitution - 1)
				player.grace = maxi(0, player.grace - 1)
				player._recalculate_stats()
				player.health = mini(player.health, player.max_health)
				GameManager.log_message("You feel your very essence drain away!", ThemeColors.MSG_ERROR)
		"DARK":
			target.apply_status("darkened", 3 + randi_range(1, 3))
		_:
			pass  # Unknown effect, treat as HURT

# ============================================================================
# DEATH
# ============================================================================

func die(killer: Entity = null) -> void:
	# Process rewards BEFORE calling super.die() which triggers signals
	# Check validity before using 'is' operator to avoid freed instance errors
	if killer != null and is_instance_valid(killer) and killer is Player:
		var was_silent := alertness < Constants.ALERTNESS_ALERT  # Monster wasn't fully aware
		killer.gain_experience(experience_value, "kill")

		# Track in run stats
		killer.run_stats.record_kill(entity_name, experience_value, was_silent)
		# Track kills by name for Bane ability
		killer.kills_by_name[entity_name] = killer.kills_by_name.get(entity_name, 0) + 1

		if was_silent:
			GameManager.log_message("You silently dispatch the %s! (+%d XP)" % [entity_name, experience_value], ThemeColors.ABILITY_LEARNED)
		else:
			GameManager.log_message("You have slain the %s! (+%d XP)" % [entity_name, experience_value], ThemeColors.ABILITY_LEARNED)

		# Fade (Stealth ability): +10 stealth for 3 turns after kill
		if killer.has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_FADE):
			killer._fade_bonus = 10
			killer._fade_turns = 3

		# Check for special achievements
		if entity_name.begins_with("Nazgul") or "Ringwraith" in entity_name:
			killer.run_stats.killed_nazgul = true
		if entity_name == "Sauron" or entity_name == "The Necromancer":
			killer.run_stats.necromancer_defeated = true

	super.die(killer)

## Check if monster is currently unwary (can be assassinated)
func is_unwary() -> bool:
	return alertness < Constants.ALERTNESS_UNWARY

## Check if monster is currently alert
func is_alert() -> bool:
	return alertness >= Constants.ALERTNESS_ALERT

## Get monster's current stance as a string
func get_stance_string() -> String:
	match stance:
		Constants.Stance.AGGRESSIVE:
			return "aggressive"
		Constants.Stance.CONFIDENT:
			return "confident"
		Constants.Stance.FLEEING:
			return "fleeing"
	return "unknown"

# ============================================================================
# SPELL CASTING (Phase G)
# ============================================================================

## Try to cast a spell at the target. Returns true if a spell was cast.
func _try_cast_spell(cast_target: Entity, distance: int) -> bool:
	if not monster_data:
		return false

	# Check LOS
	if not GameManager.current_level or not GameManager.current_level.has_los_to(grid_position, cast_target.grid_position):
		return false

	# Build list of available spells
	var available_spells: Array[String] = _get_available_spells()
	if available_spells.is_empty():
		return false

	# Spell frequency: 33% chance to cast instead of melee/move (Sil-Q style)
	if randf() > 0.33:
		return false

	# Pick a random spell from available
	var spell: String = available_spells[randi() % available_spells.size()]
	return _cast_spell(spell, cast_target, distance)

func _get_available_spells() -> Array[String]:
	var spells: Array[String] = []
	if not monster_data:
		return spells

	if monster_data.has_flag("SHRIEK"):
		spells.append("SHRIEK")
	if monster_data.has_flag("DARKNESS"):
		spells.append("DARKNESS")
	if monster_data.has_flag("SLOW"):
		spells.append("SLOW")
	if monster_data.has_flag("BR_FIRE"):
		spells.append("BR_FIRE")
	if monster_data.has_flag("BR_COLD"):
		spells.append("BR_COLD")
	if monster_data.has_flag("BR_POIS"):
		spells.append("BR_POIS")
	if monster_data.has_flag("BR_DARK"):
		spells.append("BR_DARK")
	if monster_data.has_flag("ARROW1"):
		spells.append("ARROW1")
	if monster_data.has_flag("ARROW2"):
		spells.append("ARROW2")
	if monster_data.has_flag("BOULDER"):
		spells.append("BOULDER")
	if monster_data.has_flag("HOLD"):
		spells.append("HOLD")
	if monster_data.has_flag("SCARE"):
		spells.append("SCARE")
	if monster_data.has_flag("CONF"):
		spells.append("CONF")
	return spells

func _cast_spell(spell: String, cast_target: Entity, distance: int) -> bool:
	if not is_instance_valid(cast_target):
		return false

	match spell:
		"SHRIEK":
			return _spell_shriek()
		"DARKNESS":
			return _spell_darkness(cast_target)
		"SLOW":
			return _spell_slow(cast_target)
		"BR_FIRE":
			return _spell_breath(cast_target, "fire", distance)
		"BR_COLD":
			return _spell_breath(cast_target, "cold", distance)
		"BR_POIS":
			return _spell_breath(cast_target, "poison", distance)
		"BR_DARK":
			return _spell_breath(cast_target, "dark", distance)
		"ARROW1":
			return _spell_ranged_attack(cast_target, distance, 1)
		"ARROW2":
			return _spell_ranged_attack(cast_target, distance, 2)
		"BOULDER":
			return _spell_ranged_attack(cast_target, distance, 3)
		"HOLD":
			return _spell_hold(cast_target)
		"SCARE":
			return _spell_scare(cast_target)
		"CONF":
			return _spell_conf(cast_target)
	return false

func _spell_shriek() -> bool:
	# Raise floor alertness and wake nearby monsters
	GameManager.log_message("The %s shrieks!" % entity_name, ThemeColors.COMBAT_CRIT)
	if GameManager.current_level:
		GameManager.current_level.add_floor_noise(20)
		# Wake nearby sleeping monsters
		for entity in GameManager.current_level.entities:
			if not is_instance_valid(entity) or not entity is Monster or entity == self:
				continue
			if entity.is_sleeping:
				var dist: int = _grid_distance(grid_position, entity.grid_position)
				if dist <= 10:
					entity._wake_up()
	return true

func _spell_darkness(cast_target: Entity) -> bool:
	# Apply DARKENED status to player
	GameManager.log_message("The %s conjures darkness!" % entity_name, ThemeColors.TEXT_MUTED)
	cast_target.apply_status("darkened", 5 + randi_range(1, 5))
	return true

func _spell_slow(cast_target: Entity) -> bool:
	# Will save: d20 + Will vs d20 + monster perception
	var save_roll: int = 0
	if cast_target is Player:
		var p: Player = cast_target as Player
		save_roll = randi_range(1, 20) + p.get_skill("will")
	else:
		save_roll = randi_range(1, 20)
	var spell_roll: int = randi_range(1, 20) + perception

	if save_roll >= spell_roll:
		GameManager.log_message("The %s tries to slow you, but you resist!" % entity_name, ThemeColors.ABILITY_LEARNED)
		return true  # Spell attempted but resisted, still costs action

	GameManager.log_message("The %s slows you!" % entity_name, ThemeColors.MSG_ERROR)
	cast_target.apply_status("slow", 3 + randi_range(1, 3))
	return true

func _spell_hold(cast_target: Entity) -> bool:
	# Will save: d20 + Will vs d20 + monster perception
	var save_roll: int = 0
	if cast_target is Player:
		var p: Player = cast_target as Player
		save_roll = randi_range(1, 20) + p.get_skill("will")
	else:
		save_roll = randi_range(1, 20)
	var spell_roll: int = randi_range(1, 20) + perception

	if save_roll >= spell_roll:
		GameManager.log_message("The %s tries to hold you, but you resist!" % entity_name, ThemeColors.ABILITY_LEARNED)
		return true

	GameManager.log_message("The %s paralyzes you!" % entity_name, ThemeColors.MSG_ERROR)
	cast_target.apply_status("entranced", 2 + randi_range(1, 3))
	return true

func _spell_scare(cast_target: Entity) -> bool:
	# Will save: d20 + Will vs d20 + monster perception
	var save_roll: int = 0
	if cast_target is Player:
		var p: Player = cast_target as Player
		save_roll = randi_range(1, 20) + p.get_skill("will")
	else:
		save_roll = randi_range(1, 20)
	var spell_roll: int = randi_range(1, 20) + perception

	if save_roll >= spell_roll:
		GameManager.log_message("The %s tries to frighten you, but you resist!" % entity_name, ThemeColors.ABILITY_LEARNED)
		return true

	GameManager.log_message("The %s fills you with dread!" % entity_name, ThemeColors.MSG_ERROR)
	cast_target.apply_status("afraid", 3 + randi_range(1, 4))
	return true

func _spell_conf(cast_target: Entity) -> bool:
	# Will save: d20 + Will vs d20 + monster perception
	var save_roll: int = 0
	if cast_target is Player:
		var p: Player = cast_target as Player
		save_roll = randi_range(1, 20) + p.get_skill("will")
	else:
		save_roll = randi_range(1, 20)
	var spell_roll: int = randi_range(1, 20) + perception

	if save_roll >= spell_roll:
		GameManager.log_message("The %s tries to confuse you, but you resist!" % entity_name, ThemeColors.ABILITY_LEARNED)
		return true

	GameManager.log_message("The %s bewilders your mind!" % entity_name, ThemeColors.MSG_ERROR)
	cast_target.apply_status("confused", 3 + randi_range(1, 4))
	return true

func _spell_breath(cast_target: Entity, element: String, distance: int) -> bool:
	# Breath weapon: damage based on monster health, reduced by distance
	var base_dmg: int = maxi(1, max_health / 3)
	var dmg: int = base_dmg - distance  # Reduced by range
	dmg = maxi(dmg, 1)

	var element_name: String = element.capitalize()
	GameManager.log_message("The %s breathes %s! (%d damage)" % [entity_name, element_name, dmg], ThemeColors.COMBAT_CRIT)
	cast_target.take_damage(dmg, element, self)

	# Target may have died from the damage
	if not is_instance_valid(cast_target) or not cast_target.is_alive:
		return true

	# Apply secondary effects
	match element:
		"fire":
			cast_target.apply_status(Constants.EFFECT_BURNING, 2 + randi_range(0, 2))
		"cold":
			cast_target.apply_status("slow", 2 + randi_range(0, 2))
		"poison":
			cast_target.apply_status("poisoned", 5 + randi_range(1, 5))
		"dark":
			cast_target.apply_status("blind", 2 + randi_range(0, 2))

	return true

func _spell_ranged_attack(cast_target: Entity, distance: int, tier: int) -> bool:
	# Ranged physical attack (arrows, boulders)
	var att: int = get_total_attack(cast_target) - maxi(0, distance - 1)
	var evn: int = cast_target.get_total_evasion(self) / 2  # Halved at range

	var attack_score: int = randi_range(1, 20) + att
	var evasion_score: int = randi_range(1, 20) + evn

	if attack_score < evasion_score:
		var projectile_name: String = "arrow" if tier <= 2 else "boulder"
		GameManager.log_message("The %s's %s misses you." % [entity_name, projectile_name], ThemeColors.MSG_SYSTEM)
		return true

	# Damage scales with tier
	var dmg_dice: String = "1d5" if tier == 1 else ("1d7" if tier == 2 else "2d6")
	var dmg: int = DataManager.roll_dice(dmg_dice) + melee_bonus / 2

	var proj_name: String = "arrow" if tier == 1 else ("arrow" if tier == 2 else "boulder")
	GameManager.log_message("The %s hits you with a %s! (%d damage)" % [entity_name, proj_name, dmg], ThemeColors.MSG_ERROR)
	cast_target.take_damage(dmg, "physical", self)
	return true
