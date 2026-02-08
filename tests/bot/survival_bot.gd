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
const HP_CRITICAL_PCT: float = 0.10   ## Below 10% HP: flee (legacy, see FLEE_HP_PCT)
const HP_LOW_PCT: float = 0.25        ## Below 25% HP: try healing urgently
const HP_HEAL_PCT: float = 0.50       ## Below 50% HP: quaff potion if available
const HP_REST_PCT: float = 0.75       ## Below 75% HP: rest if safe
const TARGET_DEPTH: int = 20          ## Goal: descend to floor 20
const TICK_DELAY: float = 0.05        ## Seconds between bot ticks (let engine process)

# --- v2 upgrades ---
const FLEE_HP_PCT: float = 0.30        ## Flee at 30% HP (was 10%)
const FLEE_DISTANCE: int = 4           ## Multi-step flee: move 4 tiles away from threats
const REST_TARGET_HP_PCT: float = 0.80 ## Rest until 80% HP (was 50 turn cap)
const REST_TARGET_VOICE_PCT: float = 0.50  ## Casters rest until 50% voice
const FLOOR_EXPLORE_PCT: float = 0.70  ## Explore 70% of floor before descending
const ITEM_SEEK_RANGE: int = 5         ## Pathfind to visible items within 5 tiles
const KITE_OPTIMAL_RANGE: int = 4      ## Optimal range for ranged kiting
const KITE_MIN_RANGE: int = 3          ## Minimum range before retreating
const VOICE_EMERGENCY_RESERVE: float = 0.30  ## Reserve 30% voice for emergencies

# ============================================================================
# NODE REFERENCES
# ============================================================================

var _main: Node2D = null
var _player: Player = null
var _level: Level = null
var _turn_system: TurnSystem = null

# ============================================================================
# ARCHETYPE CONFIGURATION (set externally by test_runner before _ready)
# ============================================================================

var archetype_config: Dictionary = {}   ## Set externally before _ready()
var run_index: int = -1                  ## Run number within archetype
var run_seed: int = -1                   ## Deterministic seed (-1 = random)

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

# Enhanced bot — skill usage tracking
var _total_abilities_used: int = 0
var _total_ranged_attacks: int = 0
var _total_items_equipped: int = 0
var _total_forges_used: int = 0
var _total_stealth_toggles: int = 0
var _total_skills_bought: int = 0
var _total_abilities_learned: int = 0
var _total_songs_started: int = 0

# v2 telemetry — detailed tracking
var _total_flee_attempts: int = 0
var _total_consumables_used: int = 0
var _total_items_sought: int = 0
var _total_kite_attempts: int = 0
var _total_kite_shots: int = 0
var _total_combats_avoided: int = 0       ## Stealth: fights skipped
var _total_stealth_kills: int = 0          ## Assassin: surprise kills
var _total_detections: int = 0             ## Times stealth was broken
var _total_forges_visited: int = 0         ## Distinct forge tiles visited
var _total_forge_successes: int = 0        ## Successful forges
var _total_word_of_command: int = 0        ## Specific ability counts
var _total_lore_of_sleep: int = 0
var _total_deep_memory: int = 0
var _total_rest_turns: int = 0             ## Total turns spent resting
var _explored_tiles: int = 0               ## Floor exploration tracking
var _total_tiles: int = 0

# ============================================================================
# ENHANCED BOT — SKILL SYSTEM REFERENCES
# ============================================================================

var _ability_system: Node = null    ## AbilitySystem autoload
var _skill_priorities: Array[String] = []  ## Skill names in priority order for XP spending
var _ability_wishlist: Array[Dictionary] = []  ## [{skill: int, ability: int, name: String}]
var _archetype_id: String = ""      ## Cached archetype identifier

# ============================================================================
# READY / ENTRY POINT
# ============================================================================

func _ready() -> void:
	# Apply deterministic seed if set
	if run_seed >= 0:
		seed(run_seed)

	var archetype_label: String = archetype_config.get("archetype_id", "DEFAULT")
	print("\n" + "=".repeat(60))
	print("[SURVIVAL BOT] Starting intelligent 20-floor auto-play...")
	print("[SURVIVAL BOT] Archetype: %s | Run: %d | Seed: %d" % [archetype_label, run_index, run_seed])
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

	# Find AbilitySystem — it's a property of main, not an autoload
	if _main and "ability_system" in _main:
		_ability_system = _main.ability_system
	if not _ability_system:
		# Fallback: search autoloads
		_ability_system = get_tree().root.get_node_or_null("AbilitySystem")

	# Initialize archetype-specific strategy
	_init_archetype_strategy()

	print("[SURVIVAL BOT] Game started. Player: %s | Depth: %d | HP: %d/%d | Voice: %d/%d" % [
		_player.entity_name, GameManager.current_depth,
		_player.current_health, _player.max_health,
		_player.voice_charges, _player.max_voice,
	])
	if _ability_system:
		print("[SURVIVAL BOT] AbilitySystem: FOUND | Skills: %s" % str(_skill_priorities))
	else:
		print("[SURVIVAL BOT] AbilitySystem: NOT FOUND — abilities disabled")

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
	## Skip character creation and start a game with a default or archetype character.
	var default_char: Dictionary = {
		"name": "SurvivalBot",
		"race": "Man",
		"house": "House of Beor",
		"trait": "Resilient",
		"gender": "male",
		"base_stats": {"str": 4, "dex": 3, "con": 4, "gra": 2},
	}

	# Use archetype config if provided, otherwise fall back to default
	if not archetype_config.is_empty():
		default_char = {
			"name": archetype_config.get("name", "SurvivalBot"),
			"race": archetype_config.get("race", "Man"),
			"house": archetype_config.get("house", "House of Beor"),
			"trait": archetype_config.get("trait", "Resilient"),
			"gender": archetype_config.get("gender", "male"),
			"base_stats": archetype_config.get("base_stats", {"str": 4, "dex": 3, "con": 4, "gra": 2}),
		}

	print("[SURVIVAL BOT] Bypassing character creation with: %s (%s %s)" % [
		default_char["name"], default_char["race"], default_char["house"]])

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
# ARCHETYPE STRATEGY
# ============================================================================

func _init_archetype_strategy() -> void:
	## Set skill priorities and ability wishlist based on archetype.
	_archetype_id = archetype_config.get("archetype_id", "DEFAULT")

	match _archetype_id:
		"WARRIOR":
			_skill_priorities = ["melee", "evasion", "will", "stealth"]
			_ability_wishlist = [
				{"skill": Constants.Skill.S_MEL, "ability": 0, "name": "Power"},
				{"skill": Constants.Skill.S_EVN, "ability": 0, "name": "Dodging"},
				{"skill": Constants.Skill.S_MEL, "ability": 1, "name": "Finesse"},
				{"skill": Constants.Skill.S_EVN, "ability": 1, "name": "Blocking"},
			]
		"STEALTH", "STEALTH_PURE":
			_skill_priorities = ["stealth", "evasion", "will", "lore"]
			_ability_wishlist = [
				{"skill": Constants.Skill.S_STL, "ability": 0, "name": "Disguise"},
				{"skill": Constants.Skill.S_EVN, "ability": 0, "name": "Dodging"},
				{"skill": Constants.Skill.S_STL, "ability": 1, "name": "Assassination"},
				{"skill": Constants.Skill.S_LOR, "ability": 15, "name": "Song of the Trees"},
			]
		"STEALTH_ASSASSIN":
			_skill_priorities = ["stealth", "melee", "evasion", "will"]
			_ability_wishlist = [
				{"skill": Constants.Skill.S_STL, "ability": 0, "name": "Disguise"},
				{"skill": Constants.Skill.S_STL, "ability": 1, "name": "Assassination"},
				{"skill": Constants.Skill.S_MEL, "ability": 0, "name": "Power"},
				{"skill": Constants.Skill.S_EVN, "ability": 0, "name": "Dodging"},
			]
		"LORE_MAGE":
			_skill_priorities = ["lore", "will", "evasion", "stealth"]
			_ability_wishlist = [
				{"skill": Constants.Skill.S_LOR, "ability": 0, "name": "Word of Command"},
				{"skill": Constants.Skill.S_LOR, "ability": 15, "name": "Song of Freedom"},
				{"skill": Constants.Skill.S_LOR, "ability": 2, "name": "Deep Memory"},
				{"skill": Constants.Skill.S_LOR, "ability": 10, "name": "Lore of Sleep"},
				{"skill": Constants.Skill.S_WIL, "ability": 0, "name": "Curse Breaking"},
			]
		"RANGER", "RANGER_MARKSMAN":
			_skill_priorities = ["archery", "evasion", "hunting", "stealth"]
			_ability_wishlist = [
				{"skill": Constants.Skill.S_ARC, "ability": 1, "name": "Fletchery"},
				{"skill": Constants.Skill.S_ARC, "ability": 2, "name": "Point Blank"},
				{"skill": Constants.Skill.S_EVN, "ability": 0, "name": "Dodging"},
				{"skill": Constants.Skill.S_PER, "ability": 0, "name": "Natural Talent"},
			]
		"RANGER_STEALTH_ARCHER":
			_skill_priorities = ["archery", "stealth", "evasion", "hunting"]
			_ability_wishlist = [
				{"skill": Constants.Skill.S_ARC, "ability": 1, "name": "Fletchery"},
				{"skill": Constants.Skill.S_STL, "ability": 0, "name": "Disguise"},
				{"skill": Constants.Skill.S_ARC, "ability": 2, "name": "Point Blank"},
				{"skill": Constants.Skill.S_EVN, "ability": 0, "name": "Dodging"},
			]
		"TANK":
			_skill_priorities = ["evasion", "melee", "will", "smithing"]
			_ability_wishlist = [
				{"skill": Constants.Skill.S_EVN, "ability": 0, "name": "Dodging"},
				{"skill": Constants.Skill.S_EVN, "ability": 1, "name": "Blocking"},
				{"skill": Constants.Skill.S_MEL, "ability": 0, "name": "Power"},
				{"skill": Constants.Skill.S_WIL, "ability": 0, "name": "Curse Breaking"},
			]
		"SMITH":
			_skill_priorities = ["smithing", "melee", "evasion", "will"]
			_ability_wishlist = [
				{"skill": Constants.Skill.S_SMT, "ability": 0, "name": "Weaponsmith"},
				{"skill": Constants.Skill.S_SMT, "ability": 1, "name": "Armoursmith"},
				{"skill": Constants.Skill.S_LOR, "ability": 15, "name": "Song of Aule"},
				{"skill": Constants.Skill.S_MEL, "ability": 0, "name": "Power"},
				{"skill": Constants.Skill.S_EVN, "ability": 0, "name": "Dodging"},
			]
		_:
			_skill_priorities = ["melee", "evasion", "will", "stealth"]
			_ability_wishlist = []

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
	## Main decision function with comprehensive skill usage.
	## Returns true if an action was taken (turn consumed).
	if not _player or not _player.is_alive:
		return false
	if not _level:
		return false

	# --- FREE ACTIONS (no turn cost) ---
	_manage_stealth()       # Toggle stealth mode based on context
	_try_buy_skills()       # Invest XP in skill priorities
	_try_learn_abilities()  # Learn abilities when prerequisites met
	_try_equip_from_inventory()  # Auto-equip better gear

	var hp_pct: float = float(_player.current_health) / float(maxi(_player.max_health, 1))
	var voice_pct: float = float(_player.voice_charges) / float(maxi(_player.max_voice, 1))
	var adj_count: int = _count_adjacent_monsters()
	var vis_count: int = _count_visible_monsters()

	# --- STEALTH_PURE: avoid all combat, pathfind around monsters ---
	if _archetype_id == "STEALTH_PURE":
		return await _stealth_pure_decide(hp_pct, adj_count, vis_count)

	# --- STEALTH_ASSASSIN: hunt unwary targets from stealth ---
	if _archetype_id == "STEALTH_ASSASSIN":
		return await _stealth_assassin_decide(hp_pct, adj_count, vis_count)

	# Priority 0: EMERGENCY — overwhelmed by multiple adjacent enemies
	if adj_count >= 2:
		if _try_emergency_ability():
			return true

	# Priority 1: FLEE at 30% HP (upgraded from 10%)
	if hp_pct < FLEE_HP_PCT:
		# Use consumables in combat first
		if adj_count > 0 and hp_pct < HP_HEAL_PCT:
			if _try_use_consumable():
				return true
		if _try_heal():
			return true
		if _try_emergency_ability():
			return true
		if _try_multi_step_flee():
			_total_flee_attempts += 1
			return true
		if not _has_adjacent_monster() and not _has_visible_monster():
			return await _do_rest()
		# Cornered — fight
		if _has_adjacent_monster():
			_try_start_combat_song()
			return _attack_adjacent_monster()
		return _do_random_move()

	# Priority 2: LOW HP — heal urgently, use consumables
	if hp_pct < HP_LOW_PCT:
		if _try_use_consumable():
			return true
		if _try_heal():
			return true
		if _has_adjacent_monster():
			_try_start_combat_song()
			return _attack_adjacent_monster()
		if not _has_visible_monster():
			return await _do_rest()

	# Priority 3: LORE_MAGE proactive abilities (before combat starts)
	if _archetype_id == "LORE_MAGE" and vis_count > 0 and not _has_adjacent_monster():
		if _try_proactive_lore_abilities(vis_count, voice_pct):
			return true

	# Priority 4: KITING — ranged archetypes maintain distance and fire
	if _is_ranged_archetype() and not _has_adjacent_monster() and vis_count > 0:
		if _try_kite_and_shoot():
			return true

	# Priority 5: RANGED ATTACK — shoot visible monsters at range
	if not _has_adjacent_monster() and vis_count > 0:
		if _try_ranged_attack():
			return true

	# Priority 6: VOICE OFFENSIVE — use abilities on visible threats
	if vis_count > 0 and not _has_adjacent_monster():
		if _try_offensive_ability():
			return true

	# Priority 7: COMBAT — fight adjacent monsters
	if _has_adjacent_monster():
		# Use consumable mid-combat if HP < 50%
		if hp_pct < HP_HEAL_PCT:
			if _try_use_consumable():
				return true
		_try_start_combat_song()
		return _attack_adjacent_monster()

	# Priority 8: HEAL if moderately wounded and safe
	if hp_pct < HP_HEAL_PCT and not _has_visible_monster():
		if _try_heal():
			return true

	# Priority 9: LOOT — pick up items on ground
	if _has_items_on_ground():
		return _pickup_item()

	# Priority 10: SEEK ITEMS — pathfind to visible items when safe
	if not _has_visible_monster() and _try_seek_nearby_item():
		return true

	# Priority 11: FORGE — use forge if standing on one
	if _is_on_forge() and _try_use_forge():
		return true

	# Priority 12: SMITH forge-seeking — pathfind to forge tiles
	if _archetype_id == "SMITH" and not _has_visible_monster():
		if _try_seek_forge():
			return true

	# Priority 13: LORE_MAGE — Deep Memory when stairs not found
	if _archetype_id == "LORE_MAGE" and not _has_visible_monster():
		if _try_use_deep_memory():
			return true

	# Priority 14: EXPLORATION SONG — start if safe and not singing
	if not _has_visible_monster() and not _has_adjacent_monster():
		if _try_start_exploration_song():
			return true

	# Priority 15: ON STAIRS — descend (with floor clearing logic)
	if _is_on_stairs_down():
		if _should_descend():
			return await _do_descend()

	# Priority 16: REST if wounded or low voice (casters) and safe
	if not _has_visible_monster() and not _has_adjacent_monster():
		if hp_pct < REST_TARGET_HP_PCT:
			return await _do_rest()
		# Casters rest for voice too
		if _is_caster_archetype() and voice_pct < REST_TARGET_VOICE_PCT:
			return await _do_rest()

	# Priority 17: EXPLORE — find stairs or continue exploring
	var stairs_pos: Vector2i = _level.find_stairs_down()
	if stairs_pos != Vector2i(-1, -1) and _level.is_explored(stairs_pos):
		if _should_descend():
			var path_to_stairs: Array[Vector2i] = _level.find_path_through_doors(
				_player.grid_position, stairs_pos
			)
			if path_to_stairs.size() > 1:
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

func _count_adjacent_monsters() -> int:
	## Count monsters within Chebyshev distance 1.
	if not _level:
		return 0
	var count: int = 0
	var pp: Vector2i = _player.grid_position
	for entity in _level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			var dist: int = maxi(absi(entity.grid_position.x - pp.x),
								 absi(entity.grid_position.y - pp.y))
			if dist <= 1:
				count += 1
	return count

func _count_visible_monsters() -> int:
	## Count all visible alive monsters.
	if not _level:
		return 0
	var count: int = 0
	for entity in _level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			if _level.is_tile_visible(entity.grid_position):
				count += 1
	return count

func _get_visible_monsters() -> Array[Monster]:
	## Return all visible alive monsters sorted by distance.
	var monsters: Array[Monster] = []
	if not _level:
		return monsters
	var pp: Vector2i = _player.grid_position
	for entity in _level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			if _level.is_tile_visible(entity.grid_position):
				monsters.append(entity as Monster)
	# Sort by distance (closest first)
	monsters.sort_custom(func(a: Monster, b: Monster) -> bool:
		var da: int = maxi(absi(a.grid_position.x - pp.x), absi(a.grid_position.y - pp.y))
		var db: int = maxi(absi(b.grid_position.x - pp.x), absi(b.grid_position.y - pp.y))
		return da < db
	)
	return monsters

func _is_on_forge() -> bool:
	## Check if player is standing on a forge tile.
	if not _level:
		return false
	return _level.get_tile(_player.grid_position) == Level.Tile.FORGE

func _get_chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))

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
	## Move away from the nearest visible monster (single step).
	return _flee_one_step()

func _try_multi_step_flee() -> bool:
	## Flee multiple tiles away from nearest threat. Returns true if at least one step taken.
	var monster: Monster = _get_nearest_visible_monster()
	if not monster:
		return false

	var pp: Vector2i = _player.grid_position
	var mp: Vector2i = monster.grid_position
	var dist: int = _get_chebyshev_distance(pp, mp)

	# Already far enough
	if dist >= FLEE_DISTANCE:
		return false

	return _flee_one_step()

func _flee_one_step() -> bool:
	## Move one step away from the nearest visible monster.
	var monster: Monster = _get_nearest_visible_monster()
	if not monster:
		return false

	var pp: Vector2i = _player.grid_position
	var mp: Vector2i = monster.grid_position
	var flee_dir: Vector2i = pp - mp

	flee_dir.x = clampi(flee_dir.x, -1, 1)
	flee_dir.y = clampi(flee_dir.y, -1, 1)

	var directions: Array[Vector2i] = [flee_dir]
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

		# Auto-equip if it's equippable and better than current
		_try_auto_equip(item_data)

		# Consume turn
		_player.consume_energy()
		if _turn_system:
			_turn_system._after_player_action()
		return true

	return false

func _do_rest() -> bool:
	## Rest until HP >= 80% of max (or voice >= 50% for casters).
	## Stops early if: monsters visible, took damage, or targets reached.
	if _has_visible_monster():
		return false

	if not _player or not _player.is_alive:
		return false

	var hp_target: int = int(_player.max_health * REST_TARGET_HP_PCT)
	var voice_target: int = int(_player.max_voice * REST_TARGET_VOICE_PCT) if _is_caster_archetype() else 0

	# Already at targets?
	var hp_ok: bool = _player.current_health >= hp_target
	var voice_ok: bool = not _is_caster_archetype() or _player.voice_charges >= voice_target
	if hp_ok and voice_ok:
		return false

	var hp_before_rest: int = _player.current_health
	var rest_turns: int = 0
	var max_rest: int = 150  # Allow longer rests to reach 80%

	while rest_turns < max_rest:
		# Interrupt conditions
		if _has_visible_monster():
			break
		if not _is_player_alive():
			break

		# Check targets
		hp_ok = _player.current_health >= hp_target
		voice_ok = not _is_caster_archetype() or _player.voice_charges >= voice_target
		if hp_ok and voice_ok:
			break

		rest_turns += 1

		# HP regen during rest: +1 HP every 4 rest turns
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
	var heal_amount: int = rest_turns / 4
	_floor_stats["healing_done"] += heal_amount
	_total_healing_done += heal_amount
	_total_rest_turns += rest_turns

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
# ENHANCED BOT — STEALTH MANAGEMENT
# ============================================================================

func _manage_stealth() -> void:
	## Toggle stealth mode based on context. This is a FREE action (no turn cost).
	if not _player:
		return

	var should_stealth: bool = false

	match _archetype_id:
		"STEALTH_PURE":
			# Always stealth — only drop for emergencies
			should_stealth = true
		"STEALTH_ASSASSIN":
			# Stealth ON when exploring, OFF when adjacent and ready to strike
			should_stealth = not _has_adjacent_monster()
		"STEALTH", "RANGER_STEALTH_ARCHER":
			# Stealth ON when: no adjacent monsters
			should_stealth = not _has_adjacent_monster()
		"LORE_MAGE":
			# Stealth ON when: no visible monsters
			should_stealth = not _has_visible_monster()
		"RANGER", "RANGER_MARKSMAN":
			# Stealth ON when exploring, OFF for ranged combat
			should_stealth = not _has_visible_monster()
		_:
			# Other archetypes: stealth when wounded and no adjacent threats
			var hp_pct: float = float(_player.current_health) / float(maxi(_player.max_health, 1))
			should_stealth = hp_pct < HP_HEAL_PCT and not _has_adjacent_monster()

	if _player.stealth_mode != should_stealth:
		_player.toggle_stealth_mode()
		_total_stealth_toggles += 1

# ============================================================================
# v2 — FLOOR CLEARING / DESCENT DECISION
# ============================================================================

func _should_descend() -> bool:
	## Decide whether to descend stairs. Don't rush — clear the floor first.
	var hp_pct: float = float(_player.current_health) / float(maxi(_player.max_health, 1))

	# Always descend if HP critically low (survival priority)
	if hp_pct < FLEE_HP_PCT:
		return true

	# Always descend if stuck for too long
	if _stuck_counter >= RANDOM_MOVE_THRESHOLD:
		return true

	# Always descend if floor turn limit is close
	if _floor_turn >= MAX_TURNS_PER_FLOOR - 20:
		return true

	# Check floor exploration percentage
	var explore_pct: float = _get_floor_explore_pct()
	if explore_pct >= FLOOR_EXPLORE_PCT:
		return true  # Floor sufficiently explored

	# Not enough explored yet — keep exploring
	return false

func _get_floor_explore_pct() -> float:
	## Estimate what percentage of the floor has been explored.
	if not _level:
		return 1.0
	var explored: int = 0
	var total_floor: int = 0
	for y in range(_level.height):
		for x in range(_level.width):
			var pos := Vector2i(x, y)
			if _level.is_passable(pos):
				total_floor += 1
				if _level.is_explored(pos):
					explored += 1
	_explored_tiles = explored
	_total_tiles = total_floor
	if total_floor == 0:
		return 1.0
	return float(explored) / float(total_floor)

func _is_ranged_archetype() -> bool:
	return _archetype_id in ["RANGER", "RANGER_MARKSMAN", "RANGER_STEALTH_ARCHER"]

func _is_caster_archetype() -> bool:
	return _archetype_id in ["LORE_MAGE"]

func _is_stealth_archetype() -> bool:
	return _archetype_id in ["STEALTH", "STEALTH_PURE", "STEALTH_ASSASSIN", "RANGER_STEALTH_ARCHER"]

# ============================================================================
# v2 — CONSUMABLE USAGE
# ============================================================================

func _try_use_consumable() -> bool:
	## Use a healing herb/potion when HP < 50% in combat.
	if not _player:
		return false
	var hp_pct: float = float(_player.current_health) / float(maxi(_player.max_health, 1))
	if hp_pct >= HP_HEAL_PCT:
		return false

	# Try healing potions first (tval 75), then herbs (tval 80)
	for tval_target in [75, 80]:
		for item in _player.inventory:
			if item != null and "tval" in item and item.tval == tval_target:
				var hp_before: int = _player.current_health
				_use_consumable_item(item)
				var healed: int = maxi(0, _player.current_health - hp_before)
				_floor_stats["healing_done"] += healed
				_total_healing_done += healed
				_total_consumables_used += 1
				return true

	return false

# ============================================================================
# v2 — ITEM SEEKING
# ============================================================================

func _try_seek_nearby_item() -> bool:
	## Pathfind to visible items within ITEM_SEEK_RANGE when safe.
	if not _level or not _player:
		return false
	if _has_visible_monster():
		return false

	var pp: Vector2i = _player.grid_position
	var best_item: Item = null
	var best_score: int = -1
	var best_dist: int = 999

	for item_node in _level.items:
		if not is_instance_valid(item_node):
			continue
		var dist: int = _get_chebyshev_distance(pp, item_node.grid_position)
		if dist > ITEM_SEEK_RANGE or dist == 0:
			continue
		if not _level.is_tile_visible(item_node.grid_position):
			continue

		# Score items: healing > equipment > ammo > other
		var score: int = 1
		var item_data: Variant = item_node.get_data() if item_node.has_method("get_data") else null
		if item_data != null and "tval" in item_data:
			if item_data.tval == 75 or item_data.tval == 80:  # Potions/herbs
				score = 10
			elif item_data.tval in [20, 21, 22, 23, 24, 25, 26, 27, 28, 30, 31, 32, 33, 34, 35, 36, 37]:
				score = 5  # Equipment
			elif item_data.tval == 17 or item_data.tval == 16:  # Ammo
				score = 7

		if score > best_score or (score == best_score and dist < best_dist):
			best_score = score
			best_dist = dist
			best_item = item_node

	if best_item:
		_total_items_sought += 1
		return _move_toward_target(best_item.grid_position)

	return false

# ============================================================================
# v2 — STEALTH BEHAVIOR OVERHAUL
# ============================================================================

func _stealth_pure_decide(hp_pct: float, adj_count: int, vis_count: int) -> bool:
	## STEALTH_PURE: Avoid all combat. Pathfind around monsters. Only fight if cornered.
	# Emergency: heal and flee if low HP
	if hp_pct < FLEE_HP_PCT:
		if _try_use_consumable():
			return true
		if _try_heal():
			return true
		if _try_multi_step_flee():
			_total_flee_attempts += 1
			return true
		# Cornered, forced to fight
		if adj_count > 0:
			return _attack_adjacent_monster()
		return _do_random_move()

	# If adjacent monster, flee rather than fight
	if adj_count > 0:
		_total_flee_attempts += 1
		if _try_multi_step_flee():
			return true
		# Truly cornered — fight
		return _attack_adjacent_monster()

	# Visible but not adjacent monsters — avoid them
	if vis_count > 0:
		_total_combats_avoided += 1
		# Move away from visible monsters toward unexplored/stairs
		return _move_avoiding_monsters()

	# Safe — explore
	if _has_items_on_ground():
		return _pickup_item()
	if not _has_visible_monster() and _try_seek_nearby_item():
		return true

	# Rest if needed
	if hp_pct < REST_TARGET_HP_PCT:
		return await _do_rest()

	# Navigate to stairs avoiding monster LOS
	if _is_on_stairs_down() and _should_descend():
		return await _do_descend()

	# Explore
	if _stuck_counter < RANDOM_MOVE_THRESHOLD:
		return _do_auto_explore_step()
	return _do_random_move()

func _stealth_assassin_decide(hp_pct: float, adj_count: int, vis_count: int) -> bool:
	## STEALTH_ASSASSIN: Hunt unwary monsters from stealth for surprise attacks.
	# Emergency
	if hp_pct < FLEE_HP_PCT:
		if _try_use_consumable():
			return true
		if _try_heal():
			return true
		if _try_multi_step_flee():
			_total_flee_attempts += 1
			return true
		if adj_count > 0:
			return _attack_adjacent_monster()
		return _do_random_move()

	# Adjacent monster: finish it off
	if adj_count > 0:
		_try_start_combat_song()
		var monster: Monster = _get_nearest_adjacent_monster()
		if monster and not monster.is_alive:
			pass
		return _attack_adjacent_monster()

	# Visible monster: approach while stealthed for surprise attack
	if vis_count > 0 and _player.stealth_mode:
		var target: Monster = _get_weakest_visible_monster()
		if target:
			var dist: int = _get_chebyshev_distance(_player.grid_position, target.grid_position)
			if dist <= 2:
				# Close enough — move in for the kill
				return _move_toward_target(target.grid_position)
			elif dist <= 5:
				# Approach stealthily
				return _move_toward_target(target.grid_position)

	# Visible monster but not stealthed — flee and re-stealth
	if vis_count > 0 and not _player.stealth_mode:
		if _try_multi_step_flee():
			return true

	# Safe — loot, heal, explore
	if _has_items_on_ground():
		return _pickup_item()
	if not _has_visible_monster() and _try_seek_nearby_item():
		return true
	if hp_pct < REST_TARGET_HP_PCT:
		return await _do_rest()
	if _is_on_stairs_down() and _should_descend():
		return await _do_descend()
	if _stuck_counter < RANDOM_MOVE_THRESHOLD:
		return _do_auto_explore_step()
	return _do_random_move()

func _get_weakest_visible_monster() -> Monster:
	## Return the visible monster with lowest HP (best assassination target).
	var monsters: Array[Monster] = _get_visible_monsters()
	if monsters.is_empty():
		return null
	var weakest: Monster = monsters[0]
	for m in monsters:
		if m.current_health < weakest.current_health:
			weakest = m
	return weakest

func _move_avoiding_monsters() -> bool:
	## Move toward stairs or unexplored area while avoiding monster line of sight.
	if not _level or not _player:
		return _do_random_move()

	var pp: Vector2i = _player.grid_position
	var visible_monsters: Array[Monster] = _get_visible_monsters()

	# Try each adjacent tile, pick the one farthest from all visible monsters
	var best_dir: Vector2i = Vector2i.ZERO
	var best_score: float = -999.0

	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0),                   Vector2i(1, 0),
		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1),
	]

	for dir in directions:
		var target: Vector2i = pp + dir
		if not _level.is_passable(target):
			continue
		var entity_at: Entity = _level.get_entity_at(target)
		if entity_at != null and entity_at != _player:
			continue

		# Score: sum of distances from all visible monsters (higher = safer)
		var score: float = 0.0
		for m in visible_monsters:
			score += float(_get_chebyshev_distance(target, m.grid_position))

		# Bonus for moving toward stairs
		var stairs_pos: Vector2i = _level.find_stairs_down()
		if stairs_pos != Vector2i(-1, -1):
			var stairs_dist: int = _get_chebyshev_distance(target, stairs_pos)
			score += (20.0 - float(stairs_dist)) * 0.5  # Slight pull toward stairs

		# Bonus for unexplored tiles
		if not _level.is_explored(target):
			score += 2.0

		if score > best_score:
			best_score = score
			best_dir = dir

	if best_dir != Vector2i.ZERO:
		return _move_in_direction(best_dir)
	return _do_random_move()

# ============================================================================
# v2 — KITING LOGIC (Ranged Archetypes)
# ============================================================================

func _try_kite_and_shoot() -> bool:
	## Kiting: fire ranged attack, then retreat to maintain optimal range.
	if not _player or not _player.can_fire_ranged():
		return false

	var visible_monsters: Array[Monster] = _get_visible_monsters()
	if visible_monsters.is_empty():
		return false

	var pp: Vector2i = _player.grid_position
	var target: Monster = null
	var target_dist: int = 0

	# Find best target at range
	for monster in visible_monsters:
		var dist: int = _get_chebyshev_distance(pp, monster.grid_position)
		if dist < 2 or dist > 8:
			continue
		if _level.has_los_to(pp, monster.grid_position):
			target = monster
			target_dist = dist
			break

	if not target:
		return false

	# If too close, retreat first (kite step)
	if target_dist < KITE_MIN_RANGE:
		_total_kite_attempts += 1
		# Move away from target
		var flee_dir: Vector2i = pp - target.grid_position
		flee_dir.x = clampi(flee_dir.x, -1, 1)
		flee_dir.y = clampi(flee_dir.y, -1, 1)
		if flee_dir != Vector2i.ZERO:
			var flee_target: Vector2i = pp + flee_dir
			if _level.is_passable(flee_target):
				var entity_at: Entity = _level.get_entity_at(flee_target)
				if entity_at == null or entity_at == _player:
					return _move_in_direction(flee_dir)

	# In optimal range — fire
	if _player.consume_arrow():
		_player.attacked_this_turn = true
		_player.ranged_attack(target, target_dist)
		_player.consume_energy()
		if _turn_system:
			_turn_system._after_player_action()
		_total_ranged_attacks += 1
		_total_kite_shots += 1

		if not is_instance_valid(target) or not target.is_alive:
			_floor_stats["monsters_killed"] += 1
			_total_kills += 1

		_track_damage()
		return true

	return false

# ============================================================================
# v2 — SMITH FORGE-SEEKING
# ============================================================================

func _try_seek_forge() -> bool:
	## SMITH archetype: pathfind to forge tiles when none nearby.
	if not _level or not _player:
		return false
	if _archetype_id != "SMITH":
		return false

	# Scan for forge tiles
	var pp: Vector2i = _player.grid_position
	var best_forge: Vector2i = Vector2i(-1, -1)
	var best_dist: int = 999

	for y in range(_level.height):
		for x in range(_level.width):
			var pos := Vector2i(x, y)
			if _level.get_tile(pos) == Level.Tile.FORGE:
				if _level.is_explored(pos):
					var dist: int = _get_chebyshev_distance(pp, pos)
					if dist < best_dist:
						best_dist = dist
						best_forge = pos

	if best_forge != Vector2i(-1, -1) and best_dist > 0:
		_total_forges_visited += 1
		return _move_toward_target(best_forge)

	return false

# ============================================================================
# v2 — LORE MAGE PROACTIVE ABILITIES
# ============================================================================

func _try_proactive_lore_abilities(vis_count: int, voice_pct: float) -> bool:
	## Lore Mage: use abilities proactively before combat starts.
	if not _ability_system or not _player:
		return false

	# Don't spend voice if below emergency reserve (unless many threats)
	if voice_pct < VOICE_EMERGENCY_RESERVE and vis_count < 3:
		return false

	# Lore of Sleep on approaching monster BEFORE melee range
	if vis_count >= 1 and _ability_system.has_ability(150):
		var check: Dictionary = _ability_system.can_use_ability(150)
		if check.get("can_use", false):
			var visible_monsters: Array[Monster] = _get_visible_monsters()
			if not visible_monsters.is_empty():
				# Target strongest approaching monster
				var target: Monster = visible_monsters[0]
				for m in visible_monsters:
					if m.max_health > target.max_health:
						target = m
				var dist: int = _get_chebyshev_distance(_player.grid_position, target.grid_position)
				if dist >= 2 and dist <= 5:  # Pre-emptive range
					if _ability_system.activate_ability(150, target):
						_total_abilities_used += 1
						_total_lore_of_sleep += 1
						_player.consume_energy()
						if _turn_system:
							_turn_system._after_player_action()
						return true

	# Word of Command when 2+ visible (pre-emptive AOE)
	if vis_count >= 2 and _ability_system.has_ability(140):
		var check: Dictionary = _ability_system.can_use_ability(140)
		if check.get("can_use", false):
			if _ability_system.activate_ability(140):
				_total_abilities_used += 1
				_total_word_of_command += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	return false

func _try_use_deep_memory() -> bool:
	## Use Deep Memory to reveal map when stairs haven't been found.
	if not _ability_system or not _player:
		return false
	if not _ability_system.has_ability(142):
		return false

	var stairs_pos: Vector2i = _level.find_stairs_down()
	if stairs_pos != Vector2i(-1, -1) and _level.is_explored(stairs_pos):
		return false  # Already know where stairs are

	var check: Dictionary = _ability_system.can_use_ability(142)
	if not check.get("can_use", false):
		return false

	if _ability_system.activate_ability(142):
		_total_abilities_used += 1
		_total_deep_memory += 1
		_player.consume_energy()
		if _turn_system:
			_turn_system._after_player_action()
		return true

	return false

# ============================================================================
# ENHANCED BOT — SONG MANAGEMENT
# ============================================================================

func _try_start_combat_song() -> bool:
	## Start a combat-appropriate sustained song. Costs a turn.
	if not _ability_system or not _player:
		return false
	# Already singing a combat song?
	if _player.active_song_id in [155, 157]:  # Freedom or Aule
		return false
	# Need voice to sustain
	if _player.voice_charges < 5:
		return false

	# Song of Aule (+2 melee) — best for melee archetypes
	if _ability_system.has_ability(157):  # SONG_OF_AULE
		var check: Dictionary = _ability_system.can_use_ability(157)
		if check.get("can_use", false):
			if _ability_system.activate_ability(157):
				_total_songs_started += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	# Song of Freedom (+3 evasion) — good for anyone in combat
	if _ability_system.has_ability(155):  # SONG_OF_FREEDOM
		var check: Dictionary = _ability_system.can_use_ability(155)
		if check.get("can_use", false):
			if _ability_system.activate_ability(155):
				_total_songs_started += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	return false

func _try_start_exploration_song() -> bool:
	## Start an exploration-appropriate sustained song. Costs a turn.
	if not _ability_system or not _player:
		return false
	# Already singing?
	if _player.active_song_id >= 0:
		return false
	# Need voice to sustain
	if _player.voice_charges < 10:
		return false

	# Song of the Trees (+5 stealth) — great for exploration
	if _archetype_id in ["STEALTH", "STEALTH_PURE", "STEALTH_ASSASSIN", "LORE_MAGE", "RANGER", "RANGER_STEALTH_ARCHER"]:
		if _ability_system.has_ability(156):  # SONG_OF_THE_TREES
			var check: Dictionary = _ability_system.can_use_ability(156)
			if check.get("can_use", false):
				if _ability_system.activate_ability(156):
					_total_songs_started += 1
					_player.consume_energy()
					if _turn_system:
						_turn_system._after_player_action()
					return true

	# Song of Freedom (+3 evasion) for defensive exploration
	if _ability_system.has_ability(155):  # SONG_OF_FREEDOM
		var check: Dictionary = _ability_system.can_use_ability(155)
		if check.get("can_use", false):
			if _ability_system.activate_ability(155):
				_total_songs_started += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	return false

# ============================================================================
# ENHANCED BOT — VOICE ABILITIES
# ============================================================================

func _try_emergency_ability() -> bool:
	## Use emergency AOE ability when overwhelmed. Costs a turn.
	if not _ability_system or not _player:
		return false

	# Word of Command (140) — AOE fear+stun, best emergency ability
	if _ability_system.has_ability(140):
		var check: Dictionary = _ability_system.can_use_ability(140)
		if check.get("can_use", false):
			if _ability_system.activate_ability(140):
				_total_abilities_used += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	# Song of Banishment (154) — AOE undead flee (once per floor)
	if _ability_system.has_ability(154):
		var check: Dictionary = _ability_system.can_use_ability(154)
		if check.get("can_use", false):
			if _ability_system.activate_ability(154):
				_total_abilities_used += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	return false

func _try_offensive_ability() -> bool:
	## Use offensive voice abilities against visible targets. Costs a turn.
	if not _ability_system or not _player:
		return false
	if _player.voice_charges < 3:
		return false

	var visible_monsters: Array[Monster] = _get_visible_monsters()
	if visible_monsters.is_empty():
		return false

	# Lore of Sleep (150) — single target sleep (great for strong enemies)
	if _ability_system.has_ability(150):
		var check: Dictionary = _ability_system.can_use_ability(150)
		if check.get("can_use", false):
			# Target the strongest visible monster
			var target: Monster = visible_monsters[0]
			for m in visible_monsters:
				if m.max_health > target.max_health:
					target = m
			if _ability_system.activate_ability(150, target):
				_total_abilities_used += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	# Word of Command (140) — AOE when 2+ visible enemies
	if visible_monsters.size() >= 2 and _ability_system.has_ability(140):
		var check: Dictionary = _ability_system.can_use_ability(140)
		if check.get("can_use", false):
			if _ability_system.activate_ability(140):
				_total_abilities_used += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	# Lore of Silence (144) — reduce perception in radius
	if visible_monsters.size() >= 2 and _ability_system.has_ability(144):
		var check: Dictionary = _ability_system.can_use_ability(144)
		if check.get("can_use", false):
			if _ability_system.activate_ability(144):
				_total_abilities_used += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	# Inner Light (147) — damage light-sensitive monsters
	if _ability_system.has_ability(147):
		var check: Dictionary = _ability_system.can_use_ability(147)
		if check.get("can_use", false):
			if _ability_system.activate_ability(147):
				_total_abilities_used += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	# Deep Memory (142) — reveal map (useful if no stairs found)
	if _ability_system.has_ability(142):
		var stairs_pos: Vector2i = _level.find_stairs_down()
		if stairs_pos == Vector2i(-1, -1) or not _level.is_explored(stairs_pos):
			var check: Dictionary = _ability_system.can_use_ability(142)
			if check.get("can_use", false):
				if _ability_system.activate_ability(142):
					_total_abilities_used += 1
					_player.consume_energy()
					if _turn_system:
						_turn_system._after_player_action()
					return true

	return false

# ============================================================================
# ENHANCED BOT — RANGED ATTACKS
# ============================================================================

func _try_ranged_attack() -> bool:
	## Fire at the nearest visible monster if have bow + ammo. Costs a turn.
	if not _player or not _player.can_fire_ranged():
		return false

	var visible_monsters: Array[Monster] = _get_visible_monsters()
	if visible_monsters.is_empty():
		return false

	# Find best ranged target (closest non-adjacent)
	var pp: Vector2i = _player.grid_position
	for monster in visible_monsters:
		var dist: int = _get_chebyshev_distance(pp, monster.grid_position)
		if dist < 2:
			continue  # Skip adjacent — melee is better
		if dist > 8:
			continue  # Too far, low accuracy

		# Check line of sight
		if _level.has_los_to(pp, monster.grid_position):
			if _player.consume_arrow():
				_player.attacked_this_turn = true
				_player.ranged_attack(monster, dist)
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				_total_ranged_attacks += 1

				# Track kills
				if not is_instance_valid(monster) or not monster.is_alive:
					_floor_stats["monsters_killed"] += 1
					_total_kills += 1

				_track_damage()
				return true

	return false

# ============================================================================
# ENHANCED BOT — EQUIPMENT MANAGEMENT
# ============================================================================

func _try_auto_equip(item_data: Variant) -> void:
	## Try to equip a newly picked up item if it's better than current gear.
	if item_data == null or not _player:
		return
	if "tval" not in item_data:
		return

	var tval: int = item_data.tval
	if not Constants.TVAL_TO_SLOT.has(tval):
		return  # Not equippable

	var slot_id: int = Constants.TVAL_TO_SLOT[tval]
	var slot_key: String = _equip_slot_key(slot_id)
	if slot_key.is_empty():
		return

	var current_item: Variant = _player.equipment.get(slot_key)

	# Always equip if slot is empty
	if current_item == null:
		if _player.equip_item(item_data, slot_key):
			_total_items_equipped += 1
		return

	# Compare items: prefer higher attack bonus for weapons, higher evasion for armor
	if _is_item_upgrade(item_data, current_item, slot_key):
		if _player.equip_item(item_data, slot_key):
			_total_items_equipped += 1

func _try_equip_from_inventory() -> void:
	## Scan inventory for equippable items better than current gear. FREE action.
	if not _player:
		return

	for item in _player.inventory:
		if item == null or "tval" not in item:
			continue
		var tval: int = item.tval
		if not Constants.TVAL_TO_SLOT.has(tval):
			continue

		var slot_id: int = Constants.TVAL_TO_SLOT[tval]
		var slot_key: String = _equip_slot_key(slot_id)
		if slot_key.is_empty():
			continue

		var current_item: Variant = _player.equipment.get(slot_key)
		if current_item == null:
			if _player.equip_item(item, slot_key):
				_total_items_equipped += 1
		elif _is_item_upgrade(item, current_item, slot_key):
			if _player.equip_item(item, slot_key):
				_total_items_equipped += 1

func _is_item_upgrade(new_item: Variant, current_item: Variant, slot_key: String) -> bool:
	## Compare two items for the same slot. Returns true if new_item is better.
	var new_score: int = _item_score(new_item, slot_key)
	var old_score: int = _item_score(current_item, slot_key)
	return new_score > old_score

func _item_score(item: Variant, slot_key: String) -> int:
	## Score an item for comparison. Higher = better.
	if item == null:
		return -999
	var score: int = 0

	# Weapon slots: prefer attack bonus + damage dice
	if slot_key in ["weapon", "bow"]:
		score += item.attack if "attack" in item else 0
		score += item.dd * item.ds if ("dd" in item and "ds" in item) else 0
		score += item.to_h * 2 if "to_h" in item else 0

	# Armor slots: prefer evasion + protection
	elif slot_key in ["armor", "head", "cloak", "hands", "feet", "off_hand"]:
		score += item.evasion if "evasion" in item else 0
		score += item.pd * item.ps if ("pd" in item and "ps" in item) else 0
		score += item.to_a * 2 if "to_a" in item else 0

	# Jewelry: prefer any bonus
	elif slot_key in ["ring_left", "ring_right", "amulet"]:
		score += item.to_h if "to_h" in item else 0
		score += item.to_a if "to_a" in item else 0
		score += item.pval if "pval" in item else 0

	# Light: prefer higher pval (brighter/longer)
	elif slot_key == "light":
		score += item.pval if "pval" in item else 0

	# Quiver: prefer more ammo
	elif slot_key == "quiver":
		score += item.pval if "pval" in item else 0

	return score

func _equip_slot_key(slot_id: int) -> String:
	## Map EquipSlot enum to equipment dictionary key.
	match slot_id:
		Constants.EquipSlot.WEAPON: return "weapon"
		Constants.EquipSlot.OFF_HAND: return "off_hand"
		Constants.EquipSlot.BOW: return "bow"
		Constants.EquipSlot.QUIVER: return "quiver"
		Constants.EquipSlot.HEAD: return "head"
		Constants.EquipSlot.BODY: return "armor"
		Constants.EquipSlot.CLOAK: return "cloak"
		Constants.EquipSlot.HANDS: return "hands"
		Constants.EquipSlot.FEET: return "feet"
		Constants.EquipSlot.NECK: return "amulet"
		Constants.EquipSlot.RING_L: return "ring_left"
		Constants.EquipSlot.RING_R: return "ring_right"
		Constants.EquipSlot.LIGHT: return "light"
	return ""

# ============================================================================
# ENHANCED BOT — SMITHING
# ============================================================================

func _try_use_forge() -> bool:
	## Try to forge at the current forge tile. Costs a turn.
	if not _player or not _is_on_forge():
		return false

	# Start Song of Aule if available (for +1 smithing bonus)
	if _ability_system and _player.active_song_id != 157:
		if _ability_system.has_ability(157):
			var check: Dictionary = _ability_system.can_use_ability(157)
			if check.get("can_use", false):
				_ability_system.activate_ability(157)
				_total_songs_started += 1
				_player.consume_energy()
				if _turn_system:
					_turn_system._after_player_action()
				return true

	# Check smithing skill — need at least 1
	var smithing_level: int = _player.skills.get("smithing", 0)
	if smithing_level < 1:
		return false

	var smithing_system: RefCounted = SmithingSystem.new() if ClassDB.class_exists("SmithingSystem") else null
	if smithing_system == null:
		# Try loading the script
		var script: GDScript = load("res://scripts/systems/smithing_system.gd") as GDScript
		if script:
			smithing_system = script.new()
	if smithing_system == null:
		return false

	# Check for available recipes
	var recipes: Array = smithing_system.get_available_recipes(_player)
	if recipes.is_empty():
		return false

	# Try the first available recipe
	var recipe: Variant = recipes[0]
	var success: bool = false

	# Get mithril materials
	var mithril: Array = smithing_system.get_mithril_materials(_player)
	if not mithril.is_empty() and recipe.has("type"):
		var templates: Array = smithing_system.get_creatable_items(recipe.type, GameManager.current_depth)
		if not templates.is_empty():
			var result: Variant = smithing_system.create_item(_player, templates[0], mithril[0])
			if result:
				_total_forges_used += 1
				success = true

	if success:
		_player.consume_energy()
		if _turn_system:
			_turn_system._after_player_action()
		return true

	return false

# ============================================================================
# ENHANCED BOT — SKILL INVESTMENT
# ============================================================================

func _try_buy_skills() -> void:
	## Invest XP in skill priorities. FREE action (no turn cost).
	if not _player or _skill_priorities.is_empty():
		return

	# Try to buy one skill point per decision cycle (avoid spending all XP at once)
	for skill_name in _skill_priorities:
		if _player.can_afford_skill(skill_name):
			if _player.invest_skill(skill_name):
				_total_skills_bought += 1
				return  # Only buy one per cycle

func _try_learn_abilities() -> void:
	## Learn abilities from wishlist when prerequisites are met. FREE action.
	if not _player or _ability_wishlist.is_empty():
		return

	for entry in _ability_wishlist:
		var skill_type: int = entry.get("skill", -1)
		var ability_num: int = entry.get("ability", -1)
		if skill_type < 0 or ability_num < 0:
			continue

		# Already learned?
		if _player.has_ability(skill_type, ability_num):
			continue

		# Check if ability data exists and we meet requirements
		var abilities: Array = DataManager.get_abilities_for_skill(skill_type) if DataManager else []
		for ability_data in abilities:
			if ability_data.ability_num == ability_num:
				# Check skill level requirement
				var skill_names: Array[String] = ["melee", "archery", "evasion", "stealth", "hunting", "will", "smithing", "lore"]
				var skill_key: String = skill_names[skill_type] if skill_type < skill_names.size() else ""
				var player_level: int = _player.skills.get(skill_key, 0)
				if player_level < ability_data.level_requirement:
					break  # Not high enough skill

				# Check XP cost
				var owned: int = _player.abilities_in_skill(skill_type)
				var affinity: int = _player.get_ability_affinity_level(skill_key) if _player.has_method("get_ability_affinity_level") else 0
				var xp_cost: int = maxi(0, (owned + 1) * 500 - 500 * affinity)
				if _player.xp_available < xp_cost:
					break  # Can't afford

				# Learn it
				_player.xp_available -= xp_cost
				_player.learn_ability(skill_type, ability_num)
				if not _player.has_meta("learned_abilities"):
					_player.set_meta("learned_abilities", [])
				var learned: Array = _player.get_meta("learned_abilities")
				learned.append(entry.get("name", "Unknown"))
				_player.set_meta("learned_abilities", learned)
				_total_abilities_learned += 1
				print("[SURVIVAL BOT] Learned ability: %s (-%d XP)" % [entry.get("name", "Unknown"), xp_cost])
				return  # Only learn one per cycle

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
		"abilities_used": 0,
		"ranged_attacks": 0,
		"items_equipped": 0,
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

	# Emit structured JSON result line for harness capture
	var result_json: Dictionary = {
		"archetype": archetype_config.get("archetype_id", "DEFAULT"),
		"run_index": run_index,
		"seed": run_seed,
		"outcome": cause,
		"deepest_floor": _deepest_floor,
		"total_turns": _total_turns,
		"total_kills": _total_kills,
		"total_items": _total_items,
		"total_damage_taken": _total_damage_taken,
		"total_healing_done": _total_healing_done,
		"total_errors": _total_errors,
		"total_abilities_used": _total_abilities_used,
		"total_ranged_attacks": _total_ranged_attacks,
		"total_items_equipped": _total_items_equipped,
		"total_forges_used": _total_forges_used,
		"total_stealth_toggles": _total_stealth_toggles,
		"total_skills_bought": _total_skills_bought,
		"total_abilities_learned": _total_abilities_learned,
		"total_songs_started": _total_songs_started,
		# v2 telemetry
		"total_flee_attempts": _total_flee_attempts,
		"total_consumables_used": _total_consumables_used,
		"total_items_sought": _total_items_sought,
		"total_kite_attempts": _total_kite_attempts,
		"total_kite_shots": _total_kite_shots,
		"total_combats_avoided": _total_combats_avoided,
		"total_stealth_kills": _total_stealth_kills,
		"total_detections": _total_detections,
		"total_forges_visited": _total_forges_visited,
		"total_forge_successes": _total_forge_successes,
		"total_word_of_command": _total_word_of_command,
		"total_lore_of_sleep": _total_lore_of_sleep,
		"total_deep_memory": _total_deep_memory,
		"total_rest_turns": _total_rest_turns,
		"per_floor_stats": _all_floor_stats,
		"timestamp": Time.get_datetime_string_from_system(),
	}
	print("JSON_RESULT:" + JSON.stringify(result_json))

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
	print("Abilities used: %d | Ranged: %d | Equipped: %d | Forged: %d" % [
		_total_abilities_used, _total_ranged_attacks, _total_items_equipped, _total_forges_used])
	print("Stealth toggles: %d | Skills bought: %d | Abilities learned: %d | Songs: %d" % [
		_total_stealth_toggles, _total_skills_bought, _total_abilities_learned, _total_songs_started])
	print("Flee attempts: %d | Consumables: %d | Items sought: %d | Kite shots: %d" % [
		_total_flee_attempts, _total_consumables_used, _total_items_sought, _total_kite_shots])
	print("Combats avoided: %d | Stealth kills: %d | Detections: %d | Rest turns: %d" % [
		_total_combats_avoided, _total_stealth_kills, _total_detections, _total_rest_turns])
	print("WoC: %d | Sleep: %d | Deep Memory: %d | Forges visited: %d" % [
		_total_word_of_command, _total_lore_of_sleep, _total_deep_memory, _total_forges_visited])
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
