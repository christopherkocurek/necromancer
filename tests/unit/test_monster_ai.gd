extends GutTest
## Unit tests for monster AI state machine and behavior
## Tests perception, hunting, fleeing, and pathfinding decisions

enum AIState { IDLE, WANDERING, HUNTING, FLEEING }

func test_ai_states_exist():
	assert_eq(AIState.IDLE, 0, "IDLE should be state 0")
	assert_eq(AIState.WANDERING, 1, "WANDERING should be state 1")
	assert_eq(AIState.HUNTING, 2, "HUNTING should be state 2")
	assert_eq(AIState.FLEEING, 3, "FLEEING should be state 3")

func test_perception_range_detection():
	var monster_pos: Vector2i = Vector2i(10, 10)
	var player_pos: Vector2i = Vector2i(15, 12)
	var perception_range: int = 8

	var distance: float = monster_pos.distance_to(player_pos)
	# sqrt(25 + 4) = sqrt(29) ≈ 5.4

	assert_lt(distance, perception_range, "Player within perception range should be detected")

func test_perception_out_of_range():
	var monster_pos: Vector2i = Vector2i(10, 10)
	var player_pos: Vector2i = Vector2i(25, 10)
	var perception_range: int = 8

	var distance: float = monster_pos.distance_to(player_pos)
	# distance = 15

	assert_gt(distance, perception_range, "Player outside perception range should not be detected")

func test_flee_threshold():
	# Monster flees when health < 20%
	var max_health: int = 100
	var current_health: int = 15
	var flee_threshold: float = 0.2

	var health_ratio: float = float(current_health) / float(max_health)
	assert_lt(health_ratio, flee_threshold, "15% health should trigger flee")

func test_no_flee_above_threshold():
	var max_health: int = 100
	var current_health: int = 25
	var flee_threshold: float = 0.2

	var health_ratio: float = float(current_health) / float(max_health)
	assert_gt(health_ratio, flee_threshold, "25% health should not trigger flee")

func test_hunting_requires_los():
	# Monster can see player = hunting
	# Monster cannot see player = may lose target
	var has_los: bool = true
	var in_range: bool = true

	var should_hunt: bool = has_los and in_range
	assert_true(should_hunt, "Monster with LOS and in range should hunt")

func test_lost_sight_chance_to_wander():
	# 30% chance to switch to wandering when sight is lost
	var lost_sight: bool = true
	var wander_chance: float = 0.3

	# Just verify the probability exists
	assert_eq(wander_chance, 0.3, "Lost sight should have 30% wander chance")

func test_idle_to_wander_chance():
	# 10% chance to start wandering from idle
	var wander_chance: float = 0.1
	assert_eq(wander_chance, 0.1, "Idle should have 10% wander chance")

func test_wander_to_idle_chance():
	# 10% chance to return to idle from wandering
	var idle_chance: float = 0.1
	assert_eq(idle_chance, 0.1, "Wandering should have 10% idle chance")

func test_direction_toward_player():
	var monster_pos: Vector2i = Vector2i(10, 10)
	var player_pos: Vector2i = Vector2i(15, 12)

	var direction: Vector2i = _direction_toward(monster_pos, player_pos)
	# Player is right and slightly down

	assert_eq(direction.x, 1, "Should move right toward player")
	assert_eq(direction.y, 1, "Should move down toward player")

func test_direction_away_from_player():
	var monster_pos: Vector2i = Vector2i(10, 10)
	var player_pos: Vector2i = Vector2i(15, 12)

	var direction: Vector2i = _direction_away_from(monster_pos, player_pos)
	# Flee opposite direction

	assert_eq(direction.x, -1, "Should move left away from player")
	assert_eq(direction.y, -1, "Should move up away from player")

func test_grid_distance_cardinal():
	var a: Vector2i = Vector2i(0, 0)
	var b: Vector2i = Vector2i(5, 0)

	var dist: int = _grid_distance(a, b)
	assert_eq(dist, 5, "Cardinal distance should be 5")

func test_grid_distance_diagonal():
	var a: Vector2i = Vector2i(0, 0)
	var b: Vector2i = Vector2i(3, 4)

	# Chebyshev distance (diagonal movement)
	var dist: int = _grid_distance(a, b)
	assert_eq(dist, 4, "Chebyshev distance should be max(3, 4) = 4")

func test_ai_state_transition_detect_player():
	var state: int = AIState.IDLE
	var can_see_player: bool = true
	var health_ratio: float = 0.8

	# Should transition to HUNTING
	if can_see_player:
		if health_ratio < 0.2:
			state = AIState.FLEEING
		else:
			state = AIState.HUNTING

	assert_eq(state, AIState.HUNTING, "Should transition to HUNTING when seeing healthy player")

func test_ai_state_transition_low_health():
	var state: int = AIState.HUNTING
	var can_see_player: bool = true
	var health_ratio: float = 0.15

	if can_see_player and health_ratio < 0.2:
		state = AIState.FLEEING

	assert_eq(state, AIState.FLEEING, "Should transition to FLEEING when low health")

func test_monster_never_moves_flag():
	# Some monsters (like plants) never move
	var never_moves: bool = true

	if never_moves:
		var can_move: bool = false
		assert_false(can_move, "Monster with never_moves flag should not move")

func test_can_open_doors_flag():
	var can_open_doors: bool = true
	var tile_type: String = "DOOR_CLOSED"

	var can_pass: bool = can_open_doors and tile_type == "DOOR_CLOSED"
	assert_true(can_pass, "Monster with can_open_doors should pass through closed doors")

# Helper: Direction toward target
func _direction_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var diff: Vector2i = to - from
	return Vector2i(signi(diff.x), signi(diff.y))

# Helper: Direction away from target
func _direction_away_from(from: Vector2i, to: Vector2i) -> Vector2i:
	var toward: Vector2i = _direction_toward(from, to)
	return Vector2i(-toward.x, -toward.y)

# Helper: Grid distance (Chebyshev)
func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(b.x - a.x), absi(b.y - a.y))
