extends Entity
class_name Monster
## Base class for all monsters.

enum AIState { IDLE, WANDERING, HUNTING, FLEEING }

@export var monster_data: Resource = null
var ai_state: AIState = AIState.IDLE
var target: Entity = null
var home_position: Vector2i = Vector2i.ZERO
var alertness: int = 5
var perception_range: int = 10
var experience_value: int = 10

# Monster-specific flags
var is_unique: bool = false
var is_undead: bool = false
var is_dragon: bool = false
var can_open_doors: bool = false
var never_moves: bool = false
var is_invisible: bool = false

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
	alertness = data.alertness
	experience_value = data.experience

	# Parse protection dice (e.g., "1d4" -> dice=1, sides=4)
	if not data.protection_dice.is_empty():
		var prot_parts := data.protection_dice.split("d")
		if prot_parts.size() >= 2:
			protection_dice = int(prot_parts[0])
			protection_sides = int(prot_parts[1])

	# Give monster initial energy based on speed
	energy = randi_range(0, Constants.ACTION_COST - 1)  # Stagger initial energy

	# Set sprite based on monster display character using TileMapper
	var atlas_coords := TileMapper.get_monster_coords_for_char(data.display_char)
	print("Monster %s (char=%s) using atlas coords %s" % [data.name, data.display_char, atlas_coords])
	set_sprite_from_atlas_coords(atlas_coords)

	# Parse flags using has_flag (works with both legacy array and bitflags)
	is_unique = data.has_flag("UNIQUE")
	is_undead = data.has_flag("UNDEAD")
	is_dragon = data.has_flag("DRAGON")
	can_open_doors = data.has_flag("OPEN_DOOR")
	never_moves = data.has_flag("NEVER_MOVE")
	is_invisible = data.has_flag("INVISIBLE")

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

	# Check if we can perceive the player
	var can_see_player := distance_to_player <= perception_range
	if can_see_player and GameManager.current_level:
		can_see_player = GameManager.current_level.has_los_to(grid_position, player.grid_position)

	if can_see_player:
		# Check health for fleeing
		if current_health < max_health * 0.2 and not is_unique:
			ai_state = AIState.FLEEING
		else:
			ai_state = AIState.HUNTING
			target = player
	elif ai_state == AIState.HUNTING:
		# Lost sight, keep hunting toward last known position for a bit
		if randf() < 0.3:
			ai_state = AIState.WANDERING
	else:
		if ai_state == AIState.IDLE and randf() < 0.1:
			ai_state = AIState.WANDERING
		elif ai_state == AIState.WANDERING and randf() < 0.1:
			ai_state = AIState.IDLE

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

	# Stop fleeing if far enough
	if _grid_distance(grid_position, player.grid_position) > perception_range * 2:
		ai_state = AIState.WANDERING
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

	# Grant experience to player
	if killer is Player:
		killer.gain_experience(experience_value)
		GameManager.log_message("You have slain the %s! (+%d XP)" % [entity_name, experience_value], Color.GREEN)
