extends RefCounted
class_name AutoExplore
## Auto-exploration system for roguelike exploration.
## Uses BFS to find nearest unexplored tiles and pathfinds to them.

signal exploration_started
signal exploration_stopped(reason: String)
signal step_taken(from: Vector2i, to: Vector2i)

var level: Level = null
var player: Player = null
var is_exploring: bool = false
var path: Array[Vector2i] = []
var stop_reason: String = ""

# Stop condition tracking
var last_visible_items: Array = []
var last_visible_monsters: Array = []
var last_player_health: int = 0

func _init() -> void:
	pass

func set_level(l: Level) -> void:
	level = l

func set_player(p: Player) -> void:
	player = p

# ============================================================================
# MAIN EXPLORATION API
# ============================================================================

func start_explore() -> bool:
	if not level or not player:
		return false

	if is_exploring:
		return false

	# Check for immediate stop conditions
	if _check_stop_conditions():
		return false

	is_exploring = true
	last_player_health = player.current_health
	_cache_visible_state()

	# Find initial path
	if not _find_new_path():
		stop_explore("No unexplored areas reachable")
		return false

	exploration_started.emit()
	GameManager.log_message("Auto-exploring... (press any key to stop)", ThemeColors.MSG_SYSTEM)
	return true

func stop_explore(reason: String = "Manual stop") -> void:
	if not is_exploring:
		return

	is_exploring = false
	stop_reason = reason
	path.clear()
	exploration_stopped.emit(reason)
	GameManager.log_message("Exploration stopped: %s" % reason, ThemeColors.MSG_WARNING)

func get_next_step() -> Vector2i:
	# Returns the next position to move to, or Vector2i(-1, -1) if no valid step
	if not is_exploring or path.is_empty():
		return Vector2i(-1, -1)

	# Check stop conditions before taking step
	if _check_stop_conditions():
		return Vector2i(-1, -1)

	# Get next position from path
	var next_pos: Vector2i = path[0]

	# Validate the path is still clear
	if not level.is_passable(next_pos):
		# Path blocked, try to find new path
		if not _find_new_path():
			stop_explore("Path blocked")
			return Vector2i(-1, -1)
		if path.is_empty():
			return Vector2i(-1, -1)
		next_pos = path[0]

	# Check if there's an entity blocking
	var entity = level.get_entity_at(next_pos)
	if is_instance_valid(entity) and entity != player:
		if entity is Monster:
			stop_explore("Monster encountered")
			return Vector2i(-1, -1)
		# Other entity blocking - find new path
		if not _find_new_path():
			stop_explore("Path blocked by entity")
			return Vector2i(-1, -1)
		if path.is_empty():
			return Vector2i(-1, -1)
		next_pos = path[0]

	return next_pos

func take_step() -> bool:
	# Actually take the next exploration step
	# Returns true if a step was taken, false otherwise
	if not is_exploring:
		return false

	var next_pos: Vector2i = get_next_step()
	if next_pos == Vector2i(-1, -1):
		return false

	# Record the move
	var from_pos: Vector2i = player.grid_position
	step_taken.emit(from_pos, next_pos)

	# Remove this step from path
	path.remove_at(0)

	# Check if we've reached destination
	if path.is_empty():
		# Find new unexplored area
		if not _find_new_path():
			stop_explore("Exploration complete")
			return false

	return true

func confirm_step_taken() -> void:
	# Called after player actually moves to update state
	if not is_exploring:
		return

	# Remove the step we just took from the path
	if not path.is_empty():
		path.remove_at(0)

	# Update cached state
	last_player_health = player.current_health
	_cache_visible_state()

	# Recheck stop conditions after move
	if _check_stop_conditions():
		return

	# Check if path is still valid after move
	if path.is_empty():
		if not _find_new_path():
			stop_explore("Exploration complete")

# ============================================================================
# STOP CONDITIONS
# ============================================================================

func _check_stop_conditions() -> bool:
	# Check all stop conditions and stop exploration if any are met
	# Returns true if exploration should stop

	if not player or not player.is_alive:
		stop_explore("Player died")
		return true

	# 1. Enemy visible
	if _has_visible_monster():
		stop_explore("Monster spotted")
		return true

	# 2. Player took damage
	if player.current_health < last_player_health:
		stop_explore("Took damage")
		return true

	# 3. Player on stairs
	var tile: int = level.get_tile(player.grid_position)
	if tile == Level.Tile.STAIRS_DOWN or tile == Level.Tile.STAIRS_UP:
		stop_explore("Reached stairs")
		return true

	# 4. Player on forge
	if tile == Level.Tile.FORGE:
		stop_explore("Found forge")
		return true

	return false

func _has_visible_monster() -> bool:
	# Check if any monster is visible to the player
	if not level:
		return false

	for entity in level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			if level.is_tile_visible(entity.grid_position):
				return true
	return false

func _has_new_visible_item() -> bool:
	# Check if any new item is visible (not in our cached list)
	if not level:
		return false

	for item in level.items:
		if not is_instance_valid(item):
			continue
		if level.is_tile_visible(item.grid_position):
			if item not in last_visible_items:
				return true
	return false

func _cache_visible_state() -> void:
	# Cache current visible items for comparison
	last_visible_items.clear()
	last_visible_monsters.clear()

	if not level:
		return

	for item in level.items:
		if is_instance_valid(item) and level.is_tile_visible(item.grid_position):
			last_visible_items.append(item)

	for entity in level.entities:
		if is_instance_valid(entity) and entity is Monster:
			if level.is_tile_visible(entity.grid_position):
				last_visible_monsters.append(entity)

# ============================================================================
# PATHFINDING
# ============================================================================

func _find_new_path() -> bool:
	# Find path to nearest unexplored tile using BFS
	path.clear()

	var target: Vector2i = find_nearest_unexplored()
	if target == Vector2i(-1, -1):
		return false

	# Use level's A* pathfinding
	var found_path: Array[Vector2i] = level.find_path(player.grid_position, target)

	if found_path.is_empty():
		return false

	# Remove the starting position (player is already there)
	if found_path.size() > 0 and found_path[0] == player.grid_position:
		found_path.remove_at(0)

	path = found_path
	return not path.is_empty()

func find_nearest_unexplored() -> Vector2i:
	# BFS to find nearest unexplored but reachable tile
	if not level or not player:
		return Vector2i(-1, -1)

	var start: Vector2i = player.grid_position
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true

	# 8-directional movement
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0),                   Vector2i(1, 0),
		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
	]

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()

		# Check adjacent tiles for unexplored
		for dir in directions:
			var neighbor: Vector2i = current + dir

			if visited.has(neighbor):
				continue

			if not level.is_in_bounds(neighbor):
				continue

			visited[neighbor] = true

			# If this tile is unexplored and visible from an adjacent explored tile
			if not level.is_explored(neighbor):
				# Make sure there's a path to current (which is adjacent)
				# We want to go to the explored tile adjacent to unexplored
				if level.is_passable(current) and current != start:
					return current
				# Or if the unexplored tile itself is passable, go there
				if level.is_passable(neighbor):
					return neighbor

			# Add to queue if passable for further exploration
			if level.is_passable(neighbor):
				queue.append(neighbor)

	return Vector2i(-1, -1)

# ============================================================================
# INPUT CHECK
# ============================================================================

func should_stop_on_input() -> bool:
	# Check if any input was received that should stop exploration
	# Called by main game loop
	if not is_exploring:
		return false

	# Any movement key or other action should stop
	if Input.is_action_just_pressed("move_up") or \
	   Input.is_action_just_pressed("move_down") or \
	   Input.is_action_just_pressed("move_left") or \
	   Input.is_action_just_pressed("move_right") or \
	   Input.is_action_just_pressed("move_up_left") or \
	   Input.is_action_just_pressed("move_up_right") or \
	   Input.is_action_just_pressed("move_down_left") or \
	   Input.is_action_just_pressed("move_down_right") or \
	   Input.is_action_just_pressed("wait") or \
	   Input.is_action_just_pressed("inventory") or \
	   Input.is_action_just_pressed("skills") or \
	   Input.is_action_just_pressed("abilities") or \
	   Input.is_action_just_pressed("look") or \
	   Input.is_action_just_pressed("rest") or \
	   Input.is_action_just_pressed("rest_n") or \
	   Input.is_action_just_pressed("ui_cancel"):
		stop_explore("Cancelled")
		return true

	return false
