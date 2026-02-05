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

func _ready() -> void:
	super._ready()
	home_position = grid_position

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

# ============================================================================
# AI
# ============================================================================

func take_turn() -> void:
	if not is_alive or never_moves:
		return

	# Check if monster has energy to act (energy consumed by TurnSystem)
	if not can_act():
		return

	EventBus.turn_started.emit(self)

	# Update AI state
	_update_ai_state()

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
	# Perception roll: monster_perception vs player_stealth
	# Result < 0: monster loses alertness

	if has_los:
		# Always gain alertness when player in LOS
		var alertness_gain := 1
		if distance <= 3:
			alertness_gain = 5  # Close = very obvious
		elif distance <= 6:
			alertness_gain = 3

		alertness = mini(alertness + alertness_gain, Constants.ALERTNESS_MAX)

		# Wake up if sleeping and player very close
		if is_sleeping and distance <= 2:
			_wake_up()
	else:
		# Perception roll to detect unseen player
		var perception_roll := randi_range(1, 20) + perception
		var stealth_roll := randi_range(1, 20) + _get_player_stealth(player)
		var result := perception_roll - stealth_roll

		if result < 0:
			# Failed perception - lose alertness
			alertness = maxi(alertness - 1, Constants.ALERTNESS_MIN)
		elif result > 5:
			# Strong perception - gain alertness (heard something)
			alertness = mini(alertness + 1, Constants.ALERTNESS_MAX)

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
		GameManager.log_message("The %s wakes up!" % entity_name, Color.YELLOW)

func _get_player_stealth(player: Player) -> int:
	# Get player's stealth skill value
	if "stealth" in player.skills:
		return player.skills["stealth"]
	return 0

func _count_nearby_allies(range_tiles: int) -> int:
	var count := 0
	if not GameManager.current_level:
		return 0

	for entity in GameManager.current_level.entities:
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

	# Attack if adjacent
	if _grid_distance(grid_position, target.grid_position) <= 1:
		attack_entity(target)
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
			return false

	# Check for blocking entities (but not the player - we attack them)
	if GameManager.current_level.has_method("get_entity_at"):
		var blocker = GameManager.current_level.get_entity_at(target)
		if blocker and blocker != self:
			# Don't block on player - that's handled in hunt
			if blocker is Player:
				return false  # Will attack instead
			return false

	return true

# ============================================================================
# DEATH
# ============================================================================

func die(killer: Entity = null) -> void:
	super.die(killer)

	# Grant experience to player and track stats
	if killer is Player:
		var was_silent := alertness < Constants.ALERTNESS_ALERT  # Monster wasn't fully aware
		killer.gain_experience(experience_value, "kill")

		# Track in run stats
		killer.run_stats.record_kill(entity_name, experience_value, was_silent)

		if was_silent:
			GameManager.log_message("You silently dispatch the %s! (+%d XP)" % [entity_name, experience_value], Color.GREEN)
		else:
			GameManager.log_message("You have slain the %s! (+%d XP)" % [entity_name, experience_value], Color.GREEN)

		# Check for special achievements
		if entity_name.begins_with("Nazgul") or "Ringwraith" in entity_name:
			killer.run_stats.killed_nazgul = true
		if entity_name == "Sauron" or entity_name == "The Necromancer":
			killer.run_stats.necromancer_defeated = true

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
