extends Node
## Survival Bot - Intelligent auto-play bot that attempts to descend through all 20 dungeon floors.
##
## Architecture: Extends Node, attaches to the main scene via test_runner.
## Bypasses character creation, then runs a decision loop per floor using direct game state reads.
##
## Usage (standalone): godot --path . --headless --script res://test_runner.gd -- --bot-only
## Usage (wired in):   Attach as child of main scene; call nothing else.

# ============================================================================
# CONFIGURATION
# ============================================================================

const MAX_TURNS_PER_FLOOR: int = 200
const MAX_TOTAL_TURNS: int = 5000
const STUCK_THRESHOLD: int = 20       ## Abort floor if no position change for this many turns
const RANDOM_MOVE_THRESHOLD: int = 30 ## Try random movement after this many stuck turns
const HP_CRITICAL_PCT: float = 0.10   ## Below 10% HP: flee
const HP_LOW_PCT: float = 0.25        ## Below 25% HP: try healing urgently
const HP_HEAL_PCT: float = 0.50       ## Below 50% HP: quaff potion if available
const HP_REST_PCT: float = 0.75       ## Below 75% HP: rest if safe
const TARGET_DEPTH: int = 20          ## Goal: descend to floor 20
const TICK_DELAY: float = 0.05        ## Seconds between bot ticks (let engine process)

# ============================================================================
# NODE REFERENCES
# ============================================================================

var _main: Node2D = null
var _player: Player = null
var _level: Level = null
var _turn_system: TurnSystem = null

# ============================================================================
# RUN STATE
# ============================================================================

var _current_depth: int = 0
var _total_turns: int = 0
var _run_active: bool = false
var _cause_of_end: String = "UNKNOWN"

# Per-floor tracking
var _floor_turn: int = 0
var _stuck_counter: int = 0
var _last_position: Vector2i = Vector2i(-1, -1)
var _descended_this_floor: bool = false
var _floor_hp_at_start: int = 0

# ============================================================================
# TELEMETRY
# ============================================================================

var _floor_stats: Dictionary = {}
var _all_floor_stats: Array[Dictionary] = []

# Run-level accumulators
var _total_kills: int = 0
var _total_items: int = 0
var _total_damage_taken: int = 0
var _total_healing_done: int = 0
var _deepest_floor: int = 0
var _total_errors: int = 0

# ============================================================================
# READY / ENTRY POINT
# ============================================================================

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("[SURVIVAL BOT] Starting intelligent 20-floor auto-play...")
	print("=".repeat(60) + "\n")

	# Wait for the main scene to initialize
	await get_tree().create_timer(0.5).timeout

	_find_main_node()

	if not _main:
		_log_error("Could not find Main node. Aborting.")
		_finish_run("SETUP_FAILURE")
		return

	# Bypass character creation by calling _on_character_created directly
	_bypass_character_creation()

	# Wait for game to start
	await get_tree().create_timer(0.5).timeout

	# Grab references after game starts
	_refresh_references()

	if not _player or not _level:
		_log_error("Could not find Player or Level after game start. Aborting.")
		_finish_run("SETUP_FAILURE")
		return

	print("[SURVIVAL BOT] Game started. Player: %s | Depth: %d | HP: %d/%d" % [
		_player.entity_name, GameManager.current_depth,
		_player.current_health, _player.max_health
	])

	# Run the main loop
	_run_active = true
	await _run_main_loop()

# ============================================================================
# SETUP HELPERS
# ============================================================================

func _find_main_node() -> void:
	## Find the main game node (parent or in tree).
	# The bot is added as a child of the main scene by test_runner
	_main = get_parent()
	if not _main or not _main.has_method("_start_new_game"):
		# Search the tree
		_main = _find_node_by_script("main")
	if _main:
		print("[SURVIVAL BOT] Found Main node: %s" % _main.name)

func _bypass_character_creation() -> void:
	## Skip character creation and start a game with a default character.
	var default_char: Dictionary = {
		"name": "SurvivalBot",
		"race": "Man",
		"house": "House of Beor",
		"trait": "Resilient",
		"gender": "male",
		"base_stats": {"str": 4, "dex": 3, "con": 4, "gra": 2},
	}
	print("[SURVIVAL BOT] Bypassing character creation with default character...")

	# Remove character creation screen if present
	if _main.has_method("_on_character_created"):
		_main._on_character_created(default_char)
	elif _main.has_method("_start_new_game"):
		_main._start_new_game(default_char)
	else:
		_log_error("Main node has no _on_character_created or _start_new_game method")

func _refresh_references() -> void:
	## Update references to player, level, and turn system.
	if _main:
		if "player" in _main:
			_player = _main.player
		if "current_level" in _main:
			_level = _main.current_level
		if "turn_system" in _main:
			_turn_system = _main.turn_system

	# Fallback: search tree
	if not _player:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Player:
			_player = players[0] as Player
	if not _level and _main and "current_level" in _main:
		_level = _main.current_level

func _find_node_by_script(script_name: String) -> Node:
	return _search_tree(get_tree().root, script_name)

func _search_tree(node: Node, script_name: String) -> Node:
	var script: Script = node.get_script()
	if script:
		var path: String = script.resource_path
		if script_name.to_lower() in path.to_lower():
			return node
	for child in node.get_children():
		var found: Node = _search_tree(child, script_name)
		if found:
			return found
	return null

# ============================================================================
# MAIN LOOP
# ============================================================================

func _run_main_loop() -> void:
	## Outer loop: iterate through floors 1-20.
	for target_floor in range(1, TARGET_DEPTH + 1):
		if not _run_active:
			break

		_current_depth = GameManager.current_depth
		_deepest_floor = maxi(_deepest_floor, _current_depth)
		_reset_floor_stats()

		print("\n[SURVIVAL BOT] === FLOOR %d ===" % _current_depth)

		await _run_floor_loop()

		# Record floor stats
		_finalize_floor_stats()
		_print_floor_summary()
		_all_floor_stats.append(_floor_stats.duplicate(true))

		# Check if player died
		if not _is_player_alive():
			_finish_run("DEATH")
			return

		# Check total turn limit
		if _total_turns >= MAX_TOTAL_TURNS:
			_finish_run("TOTAL_TIMEOUT")
			return

		# If we descended, continue; otherwise we timed out on this floor
		if not _descended_this_floor:
			# Try one more time to find and use stairs
			if not _run_active:
				break

		# Refresh references for new floor
		_refresh_references()

		# Safety: if we're on the last floor and descended, we won
		if _current_depth >= TARGET_DEPTH and _descended_this_floor:
			_finish_run("COMPLETED")
			return

	# Reached end of loop
	if _is_player_alive():
		_finish_run("COMPLETED")
	else:
		_finish_run("DEATH")

func _run_floor_loop() -> void:
	## Inner loop: play through a single floor.
	_floor_turn = 0
	_stuck_counter = 0
	_descended_this_floor = false
	_last_position = _player.grid_position if _player else Vector2i(-1, -1)
	_floor_hp_at_start = _player.current_health if _player else 0

	while _floor_turn < MAX_TURNS_PER_FLOOR and _run_active:
		# Safety checks
		if not _is_player_alive():
			return
		if _total_turns >= MAX_TOTAL_TURNS:
			return

		# Refresh level reference (may change on descent)
		if _main and "current_level" in _main:
			_level = _main.current_level

		# Wait for player turn
		var waited: int = 0
		while not _is_player_turn() and waited < 100:
			await get_tree().create_timer(TICK_DELAY).timeout
			waited += 1
			if not _is_player_alive():
				return

		if not _is_player_turn():
			# Timed out waiting for player turn
			_floor_stats["errors"].append("Timeout waiting for player turn at turn %d" % _floor_turn)
			_total_errors += 1
			await get_tree().create_timer(TICK_DELAY).timeout
			continue

		# Decide and execute action
		var action_taken: bool = await _decide_and_act()

		if action_taken:
			_floor_turn += 1
			_total_turns += 1
			_floor_stats["turns_taken"] = _floor_turn

		# Track stuck detection
		_update_stuck_detection()

		# Check if we descended
		if _main and "current_level" in _main:
			var new_depth: int = GameManager.current_depth
			if new_depth > _current_depth:
				_descended_this_floor = true
				return

		# Stuck abort
		if _stuck_counter >= RANDOM_MOVE_THRESHOLD + 10:
			print("[SURVIVAL BOT] Stuck for %d turns. Aborting floor." % _stuck_counter)
			_floor_stats["errors"].append("Stuck abort after %d turns" % _stuck_counter)
			_total_errors += 1
			# Try to find stairs and go directly
			await _attempt_emergency_descent()
			return

		await get_tree().create_timer(TICK_DELAY).timeout

	# Turn limit reached
	if not _descended_this_floor:
		print("[SURVIVAL BOT] Turn limit reached on floor %d. Attempting emergency descent." % _current_depth)
		await _attempt_emergency_descent()

# ============================================================================
# DECISION ENGINE
# ============================================================================

func _decide_and_act() -> bool:
	## Main decision function. Returns true if an action was taken (turn consumed).
	if not _player or not _player.is_alive:
		return false
	if not _level:
		return false

	# Priority 1: CRITICAL HP - try to heal or flee
	var hp_pct: float = float(_player.current_health) / float(maxi(_player.max_health, 1))

	if hp_pct < HP_CRITICAL_PCT:
		# Extremely low HP - try healing first, then flee
		if _try_heal():
			return true
		if _try_flee_from_monster():
			return true
		# If no healing and no monster, rest
		if not _has_adjacent_monster() and not _has_visible_monster():
			return await _do_rest()
		# Last resort: try to move away from danger
		return _do_random_move()

	if hp_pct < HP_LOW_PCT:
		# Low HP - try healing urgently
		if _try_heal():
			return true
		# If monster adjacent, fight (we have to)
		if _has_adjacent_monster():
			return _attack_adjacent_monster()
		# If no threats, rest
		if not _has_visible_monster():
			return await _do_rest()

	# Priority 2: COMBAT - fight adjacent monsters
	if _has_adjacent_monster():
		return _attack_adjacent_monster()

	# Priority 3: HEAL if moderately wounded and safe
	if hp_pct < HP_HEAL_PCT and _has_healing_potion():
		if not _has_visible_monster():
			if _try_heal():
				return true

	# Priority 4: LOOT - pick up items on ground
	if _has_items_on_ground():
		return _pickup_item()

	# Priority 5: ON STAIRS - descend
	if _is_on_stairs_down():
		return await _do_descend()

	# Priority 6: REST if wounded and safe
	if hp_pct < HP_REST_PCT and not _has_visible_monster():
		if not _has_adjacent_monster():
			return await _do_rest()

	# Priority 7: EXPLORE - find stairs
	# If we know where stairs are, pathfind there
	var stairs_pos: Vector2i = _level.find_stairs_down()
	if stairs_pos != Vector2i(-1, -1) and _level.is_explored(stairs_pos):
		# We know where stairs are - pathfind to them
		var path_to_stairs: Array[Vector2i] = _level.find_path_through_doors(
			_player.grid_position, stairs_pos
		)
		if path_to_stairs.size() > 1:
			# Move toward stairs (skip index 0 which is current position)
			var next_step: Vector2i = path_to_stairs[1] if path_to_stairs[0] == _player.grid_position else path_to_stairs[0]
			return _move_to_position(next_step)
		elif path_to_stairs.size() == 1:
			var next_step: Vector2i = path_to_stairs[0]
			if next_step != _player.grid_position:
				return _move_to_position(next_step)

	# Auto-explore to find stairs (or explore the map)
	if _stuck_counter < RANDOM_MOVE_THRESHOLD:
		return _do_auto_explore_step()
	else:
		# We're stuck - try random movement to unstick
		return _do_random_move()

# ============================================================================
# STATE QUERIES
# ============================================================================

func _is_player_alive() -> bool:
	if not _player:
		return false
	if not is_instance_valid(_player):
		return false
	return _player.is_alive

func _is_player_turn() -> bool:
	if not _turn_system:
		if _main and "turn_system" in _main:
			_turn_system = _main.turn_system
	if _turn_system:
		return _turn_system.current_state == TurnSystem.TurnState.PLAYER_INPUT
	return GameManager.is_player_turn

func _has_adjacent_monster() -> bool:
	## Check if any monster is adjacent (1 tile away, Chebyshev distance).
	if not _level:
		return false
	var pp: Vector2i = _player.grid_position
	for entity in _level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			var dist: int = maxi(absi(entity.grid_position.x - pp.x),
								 absi(entity.grid_position.y - pp.y))
			if dist <= 1:
				return true
	return false

func _get_nearest_adjacent_monster() -> Monster:
	## Return the nearest adjacent monster, or null.
	if not _level:
		return null
	var pp: Vector2i = _player.grid_position
	var best_monster: Monster = null
	var best_hp: int = 999999
	for entity in _level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			var dist: int = maxi(absi(entity.grid_position.x - pp.x),
								 absi(entity.grid_position.y - pp.y))
			if dist <= 1:
				# Prefer lowest HP target
				if entity.current_health < best_hp:
					best_hp = entity.current_health
					best_monster = entity
	return best_monster

func _get_nearest_visible_monster() -> Monster:
	## Return the nearest visible monster, or null.
	if not _level:
		return null
	var pp: Vector2i = _player.grid_position
	var best_monster: Monster = null
	var best_dist: int = 999
	for entity in _level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			if _level.is_tile_visible(entity.grid_position):
				var dist: int = maxi(absi(entity.grid_position.x - pp.x),
									 absi(entity.grid_position.y - pp.y))
				if dist < best_dist:
					best_dist = dist
					best_monster = entity
	return best_monster

func _has_visible_monster() -> bool:
	return _get_nearest_visible_monster() != null

func _has_items_on_ground() -> bool:
	if not _level:
		return false
	var items_here: Array[Item] = _level.get_items_at(_player.grid_position)
	return not items_here.is_empty()

func _is_on_stairs_down() -> bool:
	if not _level:
		return false
	return _level.get_tile(_player.grid_position) == Level.Tile.STAIRS_DOWN

func _has_healing_potion() -> bool:
	## Check if player has any potion (tval 75) in inventory.
	for item in _player.inventory:
		if item != null and "tval" in item and item.tval == 75:
			return true
	return false

func _has_food() -> bool:
	## Check if player has any food/herb (tval 80) in inventory.
	for item in _player.inventory:
		if item != null and "tval" in item and item.tval == 80:
			return true
	return false

func _count_healing_items() -> int:
	## Count total healing items (potions + food).
	var count: int = 0
	for item in _player.inventory:
		if item != null and "tval" in item:
			if item.tval == 75 or item.tval == 80:
				var stack: int = item.stack_count if "stack_count" in item else 1
				count += stack
	return count

# ============================================================================
# ACTIONS
# ============================================================================

func _attack_adjacent_monster() -> bool:
	## Move toward (attack) the nearest adjacent monster.
	var monster: Monster = _get_nearest_adjacent_monster()
	if not monster:
		return false

	var direction: Vector2i = monster.grid_position - _player.grid_position
	_player.moved_this_turn = true
	_player.attacked_this_turn = true
	_player.record_action(_player.direction_to_action(direction))

	# try_move handles attack-on-bump via can_move_to (entity collision) but
	# actually, in this game, movement into a monster triggers attack via
	# the entity's move logic. Let's use try_move which handles combat.
	var prev_hp: int = monster.current_health
	_player.try_move(direction)
	var move_cost: int = _level.get_movement_cost(_player.grid_position) if _level else 100
	_player.consume_energy(move_cost)

	if _turn_system:
		_turn_system._after_player_action()

	# Track kills
	if not is_instance_valid(monster) or not monster.is_alive:
		_floor_stats["monsters_killed"] += 1
		_total_kills += 1

	_track_damage()
	return true

func _try_heal() -> bool:
	## Try to use a healing potion (tval 75). Returns true if healing action taken.
	if not _player:
		return false

	# Try potions first (tval 75)
	for item in _player.inventory:
		if item != null and "tval" in item and item.tval == 75:
			var hp_before: int = _player.current_health
			_use_consumable_item(item)
			var healed: int = maxi(0, _player.current_health - hp_before)
			_floor_stats["healing_done"] += healed
			_total_healing_done += healed
			return true

	# Try food (tval 80) - some herbs heal
	for item in _player.inventory:
		if item != null and "tval" in item and item.tval == 80:
			var hp_before: int = _player.current_health
			_use_consumable_item(item)
			var healed: int = maxi(0, _player.current_health - hp_before)
			_floor_stats["healing_done"] += healed
			_total_healing_done += healed
			return true

	return false

func _use_consumable_item(item: Variant) -> void:
	## Use a consumable item from inventory, decrement stack or remove, and end turn.
	if item == null or not _player:
		return

	# Use the item via ConsumableSystem (same as main.gd does)
	if ConsumableSystem.use_item(_player, item):
		# Decrement stack or remove
		var count: int = item.stack_count if "stack_count" in item else 1
		if count > 1:
			item.stack_count = count - 1
		else:
			var idx: int = _player.inventory.find(item)
			if idx >= 0:
				_player.inventory.remove_at(idx)

		# Consume turn
		_player.consume_energy()
		if _turn_system:
			_turn_system._after_player_action()

func _try_flee_from_monster() -> bool:
	## Move away from the nearest visible monster.
	var monster: Monster = _get_nearest_visible_monster()
	if not monster:
		return false

	var pp: Vector2i = _player.grid_position
	var mp: Vector2i = monster.grid_position
	var flee_dir: Vector2i = pp - mp  # Direction away from monster

	# Normalize to unit direction
	flee_dir.x = clampi(flee_dir.x, -1, 1)
	flee_dir.y = clampi(flee_dir.y, -1, 1)

	# Try flee direction, then perpendicular alternatives
	var directions: Array[Vector2i] = [flee_dir]

	# Add perpendicular options
	if flee_dir.x != 0 and flee_dir.y != 0:
		directions.append(Vector2i(flee_dir.x, 0))
		directions.append(Vector2i(0, flee_dir.y))
	elif flee_dir.x != 0:
		directions.append(Vector2i(flee_dir.x, 1))
		directions.append(Vector2i(flee_dir.x, -1))
	elif flee_dir.y != 0:
		directions.append(Vector2i(1, flee_dir.y))
		directions.append(Vector2i(-1, flee_dir.y))

	for dir in directions:
		if dir == Vector2i.ZERO:
			continue
		var target: Vector2i = pp + dir
		if _level and _level.is_passable(target):
			var entity_at: Entity = _level.get_entity_at(target)
			if entity_at == null or entity_at == _player:
				return _move_in_direction(dir)

	return false

func _pickup_item() -> bool:
	## Pick up items at the player's position directly.
	if not _level or not _player:
		return false

	var floor_items: Array[Item] = _level.get_items_at(_player.grid_position)
	if floor_items.is_empty():
		return false

	# Pick up the first item
	var item_node: Item = floor_items[0]
	if not is_instance_valid(item_node):
		return false

	var item_data: Variant = item_node.get_data() if item_node.has_method("get_data") else null
	if item_data == null:
		return false

	if _player.pick_up_item(item_data):
		_level.remove_item(item_node)
		item_node.queue_free()
		_floor_stats["items_found"] += 1
		_total_items += 1

		# Consume turn
		_player.consume_energy()
		if _turn_system:
			_turn_system._after_player_action()
		return true

	return false

func _do_rest() -> bool:
	## Rest for up to 50 turns, healing 1 HP per 4 turns (matches main.gd rest logic).
	## Stops early if: monsters visible, took damage, or fully healed.
	if _has_visible_monster():
		return false

	if not _player or not _player.is_alive:
		return false

	# Already at full HP and voice?
	if _player.current_health >= _player.max_health:
		return false

	var hp_before_rest: int = _player.current_health
	var rest_turns: int = 0
	var max_rest: int = 50

	while rest_turns < max_rest:
		# Interrupt conditions
		if _has_visible_monster():
			break
		if not _is_player_alive():
			break
		if _player.current_health >= _player.max_health:
			break

		# Simulate one rest turn: HP regen + process game tick
		rest_turns += 1

		# HP regen during rest: +1 HP every 4 rest turns (same as main.gd)
		if rest_turns % 4 == 0 and _player.current_health < _player.max_health:
			_player.current_health = mini(_player.current_health + 1, _player.max_health)

		# Consume turn
		_player.consume_energy()
		if _turn_system:
			_turn_system._after_player_action()

		# Check if took damage from monsters acting during our rest
		if _player.current_health < hp_before_rest:
			break
		hp_before_rest = _player.current_health

		await get_tree().create_timer(TICK_DELAY).timeout

	# Track healing
	var total_healed: int = maxi(0, _player.current_health - (_floor_hp_at_start if rest_turns > 0 else _player.current_health))
	if _player.current_health > hp_before_rest - rest_turns:
		# Calculate actual healing done during rest
		var heal_amount: int = rest_turns / 4  # Approximate
		_floor_stats["healing_done"] += heal_amount
		_total_healing_done += heal_amount

	# Count rest turns in floor total
	_floor_turn += rest_turns
	_total_turns += rest_turns
	_floor_stats["turns_taken"] = _floor_turn

	return rest_turns > 0

func _do_descend() -> bool:
	## Descend stairs by calling main._descend() directly.
	if not _main:
		return false

	print("[SURVIVAL BOT] Descending stairs at depth %d..." % _current_depth)

	if _main.has_method("_descend"):
		await _main._descend()
	else:
		# Fallback: simulate Enter key
		_simulate_key(KEY_ENTER)
		await get_tree().create_timer(0.5).timeout

	# Refresh references for the new floor
	_refresh_references()
	_descended_this_floor = true
	return true

func _do_auto_explore_step() -> bool:
	## Take one step of auto-exploration.
	## Uses the game's built-in auto-explore system.
	if not _main or not "auto_explore" in _main:
		return _do_manual_explore()

	var auto_explore: RefCounted = _main.auto_explore
	if not auto_explore:
		return _do_manual_explore()

	# Set up auto-explore if not already exploring
	auto_explore.set_level(_level)
	auto_explore.set_player(_player)

	# Try to find a path to unexplored area
	var target: Vector2i = auto_explore.find_nearest_unexplored()
	if target == Vector2i(-1, -1):
		# No unexplored areas - try to reach stairs
		var stairs_pos: Vector2i = _level.find_stairs_down()
		if stairs_pos != Vector2i(-1, -1):
			return _move_toward_target(stairs_pos)
		# Truly stuck
		return _do_random_move()

	# Pathfind to target
	return _move_toward_target(target)

func _do_manual_explore() -> bool:
	## Fallback exploration: move toward unexplored areas or stairs.
	var stairs_pos: Vector2i = _level.find_stairs_down()
	if stairs_pos != Vector2i(-1, -1):
		return _move_toward_target(stairs_pos)
	return _do_random_move()

func _move_toward_target(target: Vector2i) -> bool:
	## Pathfind toward a target position and take one step.
	if not _level:
		return _do_random_move()

	var path: Array[Vector2i] = _level.find_path_through_doors(
		_player.grid_position, target
	)

	if path.is_empty():
		return _do_random_move()

	# Find the first step that isn't our current position
	var next_step: Vector2i = Vector2i(-1, -1)
	for step in path:
		if step != _player.grid_position:
			next_step = step
			break

	if next_step == Vector2i(-1, -1):
		return _do_random_move()

	return _move_to_position(next_step)

func _move_to_position(target: Vector2i) -> bool:
	## Move to an adjacent position.
	var direction: Vector2i = target - _player.grid_position

	# Validate it's an adjacent tile (distance 1 in Chebyshev)
	if absi(direction.x) > 1 or absi(direction.y) > 1:
		# Not adjacent - this shouldn't happen with proper pathfinding
		return _do_random_move()

	return _move_in_direction(direction)

func _move_in_direction(direction: Vector2i) -> bool:
	## Execute a movement in the given direction.
	if direction == Vector2i.ZERO:
		return false
	if not _player or not _level:
		return false

	# Check if there's a monster at the target (attack it)
	var target_pos: Vector2i = _player.grid_position + direction
	var entity_at: Entity = _level.get_entity_at(target_pos)
	if entity_at != null and entity_at != _player and entity_at is Monster:
		_player.attacked_this_turn = true

	# Check for closed door
	var tile_at_target: int = _level.get_tile(target_pos)
	if tile_at_target == Level.Tile.DOOR_CLOSED:
		# Open the door (try_move handles this)
		pass

	_player.moved_this_turn = true
	_player.record_action(_player.direction_to_action(direction))

	var moved: bool = _player.try_move(direction)

	# Consume energy regardless (opening door also costs energy)
	var cost: int = _level.get_movement_cost(_player.grid_position) if moved else 100
	_player.consume_energy(cost)

	if _turn_system:
		_turn_system._after_player_action()

	# Track combat results
	if entity_at != null and entity_at is Monster:
		if not is_instance_valid(entity_at) or not entity_at.is_alive:
			_floor_stats["monsters_killed"] += 1
			_total_kills += 1

	_track_damage()
	return true

func _do_random_move() -> bool:
	## Try moving in a random passable direction.
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0),                   Vector2i(1, 0),
		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1),
	]
	directions.shuffle()

	for dir in directions:
		var target: Vector2i = _player.grid_position + dir
		if _level and _level.is_passable(target):
			# Avoid moving into non-adjacent monsters unless we want to fight
			var entity_at: Entity = _level.get_entity_at(target)
			if entity_at == null or entity_at == _player:
				return _move_in_direction(dir)
			elif entity_at is Monster and entity_at.is_alive:
				# Only attack if we're healthy enough
				var hp_pct: float = float(_player.current_health) / float(maxi(_player.max_health, 1))
				if hp_pct > HP_CRITICAL_PCT:
					return _move_in_direction(dir)

	# Completely stuck - wait a turn
	_player.consume_energy()
	if _turn_system:
		_turn_system._after_player_action()
	return true

func _attempt_emergency_descent() -> void:
	## Last-ditch attempt to find and use stairs.
	if not _level or not _player:
		return

	var stairs_pos: Vector2i = _level.find_stairs_down()
	if stairs_pos == Vector2i(-1, -1):
		print("[SURVIVAL BOT] No stairs found on this floor!")
		return

	# Try to pathfind to stairs
	var max_emergency_turns: int = 50
	var emergency_turn: int = 0
	while emergency_turn < max_emergency_turns and _is_player_alive():
		# Wait for player turn
		var waited: int = 0
		while not _is_player_turn() and waited < 50:
			await get_tree().create_timer(TICK_DELAY).timeout
			waited += 1
			if not _is_player_alive():
				return

		if not _is_player_turn():
			break

		if _player.grid_position == stairs_pos or _is_on_stairs_down():
			await _do_descend()
			return

		var moved: bool = _move_toward_target(stairs_pos)
		if not moved:
			moved = _do_random_move()

		emergency_turn += 1
		_total_turns += 1
		_floor_turn += 1

		await get_tree().create_timer(TICK_DELAY).timeout

# ============================================================================
# INPUT SIMULATION
# ============================================================================

func _simulate_key(keycode: int) -> void:
	## Send a keypress event to the engine.
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)

	# Brief delay then release
	# (We can't await here in all contexts, so use a short process delay)
	var release: InputEventKey = InputEventKey.new()
	release.keycode = keycode
	release.pressed = false
	# Queue release for next frame
	Input.parse_input_event.call_deferred(release)

# ============================================================================
# TRACKING / TELEMETRY
# ============================================================================

func _reset_floor_stats() -> void:
	_floor_stats = {
		"depth": _current_depth,
		"turns_taken": 0,
		"monsters_killed": 0,
		"items_found": 0,
		"damage_taken": 0,
		"healing_done": 0,
		"auto_explore_uses": 0,
		"errors": [],
	}
	_floor_hp_at_start = _player.current_health if _player else 0

func _finalize_floor_stats() -> void:
	## Calculate final damage taken for this floor.
	if _player:
		var hp_lost: int = maxi(0, _floor_hp_at_start - _player.current_health)
		# This is approximate; actual damage tracking would need event hooks
		_floor_stats["damage_taken"] = hp_lost
		_total_damage_taken += hp_lost

func _track_damage() -> void:
	## Update damage tracking after an action.
	if not _player:
		return
	# We track damage as HP loss from start of floor
	# The finalize step handles the overall calculation

func _update_stuck_detection() -> void:
	## Increment stuck counter if player hasn't moved.
	if not _player:
		return
	if _player.grid_position == _last_position:
		_stuck_counter += 1
	else:
		_stuck_counter = 0
		_last_position = _player.grid_position

func _print_floor_summary() -> void:
	var errors_count: int = _floor_stats["errors"].size() if _floor_stats.has("errors") else 0
	print("[FLOOR %d] Turns: %d | Kills: %d | Items: %d | Damage: %d | Healed: %d | Errors: %d" % [
		_floor_stats.get("depth", 0),
		_floor_stats.get("turns_taken", 0),
		_floor_stats.get("monsters_killed", 0),
		_floor_stats.get("items_found", 0),
		_floor_stats.get("damage_taken", 0),
		_floor_stats.get("healing_done", 0),
		errors_count,
	])
	# Print any errors
	for err in _floor_stats.get("errors", []):
		print("  [ERROR] %s" % err)

func _finish_run(cause: String) -> void:
	_cause_of_end = cause
	_run_active = false
	_deepest_floor = maxi(_deepest_floor, GameManager.current_depth)

	print("\n" + "=".repeat(60))
	print("=== SURVIVAL BOT RUN COMPLETE ===")
	print("=".repeat(60))
	print("Floors cleared: %d/%d" % [maxi(0, _deepest_floor - 1), TARGET_DEPTH])
	print("Deepest floor reached: %d" % _deepest_floor)
	print("Total turns: %d" % _total_turns)
	print("Total kills: %d" % _total_kills)
	print("Total items: %d" % _total_items)
	print("Total damage taken: %d" % _total_damage_taken)
	print("Total healing done: %d" % _total_healing_done)
	print("Cause of end: %s" % _cause_of_end)
	print("Errors encountered: %d" % _total_errors)

	# Per-floor breakdown
	if not _all_floor_stats.is_empty():
		print("\n--- Per-Floor Breakdown ---")
		for fs in _all_floor_stats:
			var err_count: int = fs["errors"].size() if fs.has("errors") else 0
			print("  Floor %2d: %3d turns, %2d kills, %2d items, %3d dmg, %3d heal%s" % [
				fs.get("depth", 0),
				fs.get("turns_taken", 0),
				fs.get("monsters_killed", 0),
				fs.get("items_found", 0),
				fs.get("damage_taken", 0),
				fs.get("healing_done", 0),
				" [%d errors]" % err_count if err_count > 0 else "",
			])

	print("=".repeat(60) + "\n")

	# Exit
	if cause == "COMPLETED":
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func _log_error(message: String) -> void:
	print("[SURVIVAL BOT ERROR] %s" % message)
	_total_errors += 1
	if _floor_stats.has("errors"):
		_floor_stats["errors"].append(message)
