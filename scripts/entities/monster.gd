extends Entity
class_name Monster
## Base class for all monsters.
## Implements Sil-Q alertness/morale system.

enum AIState { IDLE, WANDERING, HUNTING, FLEEING }

var monster_data: Variant = null  # DataManager.MonsterData (set in initialize_from_data)
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
var has_friends_flag: bool = false  # Pack monster (Crebain, wolves, etc.) — uses surround AI
var is_pack_leader: bool = false
var pack_id: int = -1  # For escort/pack morale bonuses
var is_light_sensitive: bool = false  # Penalized in lit tiles
var is_dark_aura: bool = false  # Suppresses player light when adjacent
var is_shadow: bool = false  # Shadow creature (affected by Light of the Eldar)
var _light_recoil_shown: bool = false  # Track if we showed the recoil message this turn

# Domination (Word of Domination, ability 151)
var is_dominated: bool = false
var domination_owner: Entity = null  # Player who dominated this monster
var domination_turns: int = 0  # Remaining turns of domination

# Song noise perception bonus (applied by ability_system.gd each turn)
var song_noise_perception_bonus: int = 0

# Encounter type (spawn system classification)
var encounter_type: int = Constants.EncounterType.WANDERER

# Werewolf shapeshifting
var werewolf_form: String = "human"  # "human" or "wolf"
var _shift_cooldown: int = 0  # Turns until can shift again
var _wolf_speed_bonus: int = 0  # Temporary speed bonus applied in wolf form
var _wolf_attack_bonus: int = 0  # Temporary attack bonus applied in wolf form
var last_attack_effect: String = ""

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

	monster_data = data
	entity_name = data.name
	current_health = data.roll_health()
	max_health = current_health
	evasion_bonus = data.evasion
	speed = data.speed
	perception = data.perception  # Monster's perception stat (from A: line)
	# Scale XP by depth/rarity if data file doesn't specify (default is 10)
	if data.experience <= 10:
		# Formula: depth * 5 + rarity * 10, minimum 10
		experience_value = maxi(10, data.depth * 5 + data.rarity * 10)
		# Unique/boss monsters get 3x
		if data.has_flag("UNIQUE"):
			experience_value *= 3
	else:
		experience_value = data.experience

	# Initial alertness based on monster type (Sil-Q model)
	if data.has_flag("SLEEPING"):
		alertness = Constants.ALERTNESS_MIN  # Deep sleep
		is_sleeping = true
	else:
		# Sleepiness determines starting unwaryness: high sleepiness = deeply unwary
		# Warg (sleepiness 1) starts at -1 to 0; Orc Scout (sleepiness 10) starts at -10 to -1
		alertness = Constants.ALERTNESS_ALERT - randi_range(1, data.alertness)

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
	is_light_sensitive = data.has_flag("LIGHT_SENSITIVE")
	is_dark_aura = data.has_flag("DARK_AURA")
	is_shadow = data.has_flag("SHADOW")
	has_friends_flag = data.has_flag("FRIENDS")

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

	# DOMINATED: Act on behalf of the player
	if is_dominated:
		_dominated_behavior()
		_tick_domination()  # Decrement + break-free AFTER acting
		EventBus.turn_ended.emit(self)
		return

	# Werewolf shapeshifting AI
	_werewolf_ai_update()

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
	# New model: distance is direct penalty on monster side, terrain openness matters

	# Faded state (after stealth kill): completely invisible
	if player._fade_turns > 0:
		# Decay alertness while player is faded
		if alertness > Constants.ALERTNESS_UNWARY:
			alertness -= 1
		return

	if has_los:
		# --- LOS detection roll ---
		var m_per: int = perception
		# Depth scaling: deeper floors are more vigilant (+1 per 2 floors)
		var depth_bonus: int = GameManager.current_depth / 2 if GameManager else 0
		m_per += depth_bonus
		# Distance is a direct penalty (uncapped)
		m_per -= distance
		# Terrain openness: open areas are harder to hide in
		var openness: int = _count_open_squares(player.grid_position)
		# Disguise halves terrain openness impact
		if player.has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_DISGUISE):
			openness = openness / 2
		m_per += openness
		# Combat noise bonus
		m_per += player.get_combat_noise()
		# Song noise bonus (from ability_system singing detection)
		m_per += song_noise_perception_bonus
		# Alertness diminishing returns: already alert monsters lose focus
		if alertness >= Constants.ALERTNESS_ALERT:
			m_per -= alertness / 2
		# Difficulty modifier
		if GameManager:
			m_per += GameManager.get_monster_perception_bonus()

		var perception_roll: int = randi_range(1, 10) + m_per
		var difficulty_roll: int = randi_range(1, 10) + player.get_stealth_score()

		var result: int = perception_roll - difficulty_roll
		if result > 0:
			alertness = mini(alertness + result, Constants.ALERTNESS_MAX)
		else:
			alertness = maxi(alertness - 1, Constants.ALERTNESS_MIN)

		# Wake up if sleeping and player very close
		if is_sleeping and distance <= 2:
			_wake_up()
	else:
		# --- No-LOS detection (hearing/sensing) ---
		var m_per: int = perception / 2  # Halved without line of sight
		# Depth scaling: deeper floors are more vigilant (+1 per 2 floors)
		var depth_bonus: int = GameManager.current_depth / 2 if GameManager else 0
		m_per += depth_bonus
		m_per -= distance
		m_per += player.get_combat_noise()
		# Song noise bonus (from ability_system singing detection)
		m_per += song_noise_perception_bonus
		# No terrain openness without sight
		# Alertness diminishing returns
		if alertness >= Constants.ALERTNESS_ALERT:
			m_per -= alertness / 2

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

## Count walkable tiles in the 8 neighbors around a position (terrain openness)
func _count_open_squares(pos: Vector2i) -> int:
	var count: int = 0
	if not GameManager.current_level:
		return 0
	var dirs: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	for dir: Vector2i in dirs:
		var check: Vector2i = pos + dir
		if GameManager.current_level.is_in_bounds(check) and GameManager.current_level.is_passable(check):
			count += 1
	return count

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

	# Light sensitivity: -20 morale in lit tiles
	current_morale += get_light_sensitivity_morale_mod()

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

	# Pack surround AI: FRIENDS monsters try to flank the player instead of beelining
	if has_friends_flag and dist <= 6:
		var surround_pos: Vector2i = _pick_surround_tile(target.grid_position)
		if surround_pos != Vector2i(-1, -1):
			if GameManager.current_level:
				var path: Array[Vector2i] = GameManager.current_level.find_path(grid_position, surround_pos)
				if path.size() > 1:
					var next_pos: Vector2i = path[1]
					var dir: Vector2i = next_pos - grid_position
					if can_move_to(next_pos):
						try_move(dir)
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
	var best_score: int = -999

	for dir: Vector2i in directions:
		var new_pos: Vector2i = grid_position + dir
		if can_move_to(new_pos):
			var dist: int = _grid_distance(new_pos, player.grid_position)
			var score: int = dist
			# Light-sensitive monsters strongly prefer dark tiles when fleeing
			if is_light_sensitive and GameManager.current_level:
				if not GameManager.current_level.is_tile_lit(new_pos):
					score += 5  # Strong preference for dark tiles
			if score > best_score:
				best_score = score
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

## Public accessor for large monster check (used by player Small Stature evasion bonus)
func is_large() -> bool:
	return _is_large_monster()

func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	# Chebyshev distance (8-directional)
	return max(abs(a.x - b.x), abs(a.y - b.y))

## Pick an adjacent tile around the target that is unoccupied and opposite from allies.
## Returns Vector2i(-1, -1) if no suitable surround tile found.
func _pick_surround_tile(target_pos: Vector2i) -> Vector2i:
	var offsets: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]

	# Find which tiles around the target are occupied by allies
	var ally_offsets: Array[Vector2i] = []
	if GameManager.current_level:
		for off: Vector2i in offsets:
			var check_pos: Vector2i = target_pos + off
			var entity = GameManager.current_level.get_entity_at(check_pos)
			if is_instance_valid(entity) and entity is Monster and entity != self and entity.is_alive:
				ally_offsets.append(off)

	# Score each position: prefer tiles opposite from allies (flanking)
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_score: int = -999

	for off: Vector2i in offsets:
		var pos: Vector2i = target_pos + off
		if pos == grid_position:
			# Already here — score it highly
			return Vector2i(-1, -1)  # We're already adjacent, let normal attack handle it

		if not GameManager.current_level:
			continue
		if not GameManager.current_level.is_in_bounds(pos):
			continue

		# Must be walkable and unoccupied
		var tile: int = GameManager.current_level.get_tile(pos)
		if not GameManager.current_level.is_passable(pos):
			continue
		var occupant = GameManager.current_level.get_entity_at(pos)
		if occupant != null and occupant != self:
			continue

		# Score: bonus for being opposite an ally (flanking position)
		var score: int = 0
		var opposite: Vector2i = Vector2i(-off.x, -off.y)
		for ally_off: Vector2i in ally_offsets:
			if ally_off == opposite:
				score += 5  # Strong flanking bonus
			elif ally_off.x == -off.x or ally_off.y == -off.y:
				score += 2  # Partial flanking

		# Prefer closer tiles (shorter path)
		var dist_to_tile: int = _grid_distance(grid_position, pos)
		score -= dist_to_tile

		if score > best_score:
			best_score = score
			best_pos = pos

	return best_pos

## Check if this monster has an ally on the opposite side of the target (flanking).
## Returns true if any same-type or FRIENDS ally occupies the tile opposite this monster.
func _is_flanking(target_pos: Vector2i) -> bool:
	if not GameManager.current_level:
		return false
	var my_offset: Vector2i = grid_position - target_pos
	var opposite_pos: Vector2i = target_pos - my_offset
	if not GameManager.current_level.is_in_bounds(opposite_pos):
		return false
	var entity = GameManager.current_level.get_entity_at(opposite_pos)
	if not is_instance_valid(entity) or not entity is Monster:
		return false
	if entity == self or not entity.is_alive:
		return false
	return true

func _direction_toward(target_pos: Vector2i) -> Vector2i:
	var diff := target_pos - grid_position
	return Vector2i(sign(diff.x), sign(diff.y))

func _direction_away_from(target_pos: Vector2i) -> Vector2i:
	var diff := grid_position - target_pos
	return Vector2i(sign(diff.x), sign(diff.y))

func can_move_to(target: Vector2i) -> bool:
	if not GameManager.current_level:
		return false

	# Warding sigils: impassable to monsters (Word of Warding, ability 154)
	var tile_check: int = GameManager.current_level.get_tile(target)
	if tile_check == Level.Tile.GLYPH_OF_WARDING:
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
# LIGHT ECOLOGY
# ============================================================================

## Check if this monster is currently in a lit tile
func is_in_lit_tile() -> bool:
	if not GameManager.current_level:
		return false
	return GameManager.current_level.is_tile_lit(grid_position)

## Check light sensitivity effects and show recoil message when player moves adjacent with light
func check_light_recoil(player: Player) -> void:
	if not is_light_sensitive or not is_alive:
		return
	if _light_recoil_shown:
		return
	var dist: int = maxi(absi(grid_position.x - player.grid_position.x),
					absi(grid_position.y - player.grid_position.y))
	if dist <= 1 and player.has_light():
		_light_recoil_shown = true
		GameManager.log_message("The %s recoils from the light!" % entity_name, ThemeColors.MSG_WARNING)
		# Flash yellow via sprite tint
		if sprite:
			var orig: Color = sprite.modulate
			sprite.modulate = Color.YELLOW
			var flash_tween := create_tween()
			flash_tween.tween_property(sprite, "modulate", orig, 0.4)

## Reset the recoil flag each turn so the message can trigger again next turn
func reset_light_recoil() -> void:
	_light_recoil_shown = false

## Get the light sensitivity morale penalty (applied in morale calc)
func get_light_sensitivity_morale_mod() -> int:
	if not is_light_sensitive:
		return 0
	if is_in_lit_tile():
		return -20
	return 0

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

	# Pack flanking bonus: +2 when ally on opposite side of target (FRIENDS flag)
	if has_friends_flag and is_instance_valid(target) and _is_flanking(target.grid_position):
		att += 2

	# SMALL_STATURE: large monsters get -2 attack vs small races (Hobbits)
	if is_instance_valid(target) and target is Player:
		var p: Player = target as Player
		if p.has_racial_flag("SMALL_STATURE") and _is_large_monster():
			att -= 2

	# Blind: halve attack
	if status_fx and status_fx.is_blind():
		att = att / 2

	# Light sensitive: -2 attack in lit tiles
	if is_light_sensitive and is_in_lit_tile():
		att -= 2

	# Werewolf form bonuses
	att += _wolf_attack_bonus

	# Shadow creatures: Light of the Eldar penalty (applied by ability_system)
	if is_shadow and is_in_lit_tile():
		var eldar_penalty: int = _get_light_of_eldar_penalty()
		att -= eldar_penalty

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

	# Light sensitive: -2 evasion in lit tiles
	if is_light_sensitive and is_in_lit_tile():
		evn -= 2

	# Werewolf wolf form: -1 evasion (more aggressive, less defensive)
	if _is_werewolf() and werewolf_form == "wolf":
		evn -= 1

	# Shadow creatures: Light of the Eldar penalty
	if is_shadow and is_in_lit_tile():
		var eldar_penalty: int = _get_light_of_eldar_penalty()
		evn -= eldar_penalty

	# Shield Brother: player with shield_brother trait and a shield reduces adjacent monster evasion by 1
	var sb_player: Player = GameManager.player
	if is_instance_valid(sb_player) and sb_player.trait_effect_id == "shield_brother":
		var dist_to_player: int = _grid_distance(grid_position, sb_player.grid_position)
		if dist_to_player <= 1:
			var off_hand_item = sb_player.equipment.get("off_hand")
			if off_hand_item != null and "tval" in off_hand_item and off_hand_item.tval == 34:
				evn -= 1

	return evn

## Override damage dice for werewolf human form (reduced to 1d6 unarmed)
func _get_attack_damage_dice() -> String:
	if _is_werewolf() and werewolf_form == "human":
		return "1d6"
	return damage_dice

## Resolve monster attack special effects (FIRE, COLD, BLIND, etc.)
func _on_successful_hit(target: Entity, _hit_result: int, _damage: int) -> void:
	if not monster_data or monster_data.attacks.is_empty():
		return

	# Werewolf human form: no special attack effects (just basic unarmed)
	if _is_werewolf() and werewolf_form == "human":
		return

	var attack: DataManager.AttackData = monster_data.attacks[0]
	last_attack_effect = attack.effect if "effect" in attack else "HURT"
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
# DOMINATION AI (Word of Domination, ability 151)
# ============================================================================

## Tick domination duration. Break free on expiry or Will check.
func _tick_domination() -> void:
	domination_turns -= 1
	if domination_turns <= 0:
		_break_domination()
		return
	# Break-free check: d20 vs d20 + remaining_turns/2 (harder to break early)
	var break_roll: int = randi_range(1, 20)
	var hold_roll: int = randi_range(1, 20) + domination_turns / 2
	if break_roll > hold_roll:
		_break_domination()

## Break free from domination
func _break_domination() -> void:
	is_dominated = false
	domination_turns = 0
	if is_instance_valid(domination_owner) and domination_owner is Player:
		var p: Player = domination_owner as Player
		p.dominated_monsters.erase(self)
	domination_owner = null
	GameManager.log_message("The %s breaks free from your control!" % entity_name, ThemeColors.MSG_WARNING)
	# Become alert and hostile
	alertness = Constants.ALERTNESS_MAX
	ai_state = AIState.HUNTING

## Dominated behavior: attack nearest non-dominated monster
func _dominated_behavior() -> void:
	var nearest_enemy: Monster = null
	var nearest_dist: int = 999

	if GameManager.current_level:
		for entity in GameManager.current_level.entities:
			if not is_instance_valid(entity) or not entity is Monster or entity == self:
				continue
			if not entity.is_alive or entity.is_dominated:
				continue
			var dist: int = _grid_distance(grid_position, entity.grid_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_enemy = entity

	if nearest_enemy == null:
		# No enemies — follow the player
		var player: Player = GameManager.player
		if player and _grid_distance(grid_position, player.grid_position) > 2:
			var direction: Vector2i = _direction_toward(player.grid_position)
			if can_move_to(grid_position + direction):
				try_move(direction)
		return

	# Attack if adjacent
	if nearest_dist <= 1:
		attack_entity(nearest_enemy)
		return

	# Move toward nearest enemy
	if GameManager.current_level:
		var path: Array[Vector2i] = GameManager.current_level.find_path(grid_position, nearest_enemy.grid_position)
		if path.size() > 1:
			var next_pos: Vector2i = path[1]
			var dir: Vector2i = next_pos - grid_position
			if can_move_to(next_pos):
				try_move(dir)
				return

	var direction: Vector2i = _direction_toward(nearest_enemy.grid_position)
	if can_move_to(grid_position + direction):
		try_move(direction)

## Apply domination from Word of Domination
func dominate(owner: Entity, turns: int) -> void:
	is_dominated = true
	domination_owner = owner
	domination_turns = turns
	# Stop fleeing/hunting the player
	ai_state = AIState.IDLE
	target = null
	GameManager.log_message("The %s is under your control!" % entity_name, ThemeColors.ABILITY_LEARNED)

# ============================================================================
# LIGHT OF THE ELDAR / SHADOW CREATURE SUPPORT
# ============================================================================

## Get Light of the Eldar combat penalty for shadow creatures
func _get_light_of_eldar_penalty() -> int:
	var player: Player = GameManager.player
	if not is_instance_valid(player):
		return 0
	if not player.has_ability(Constants.Skill.S_LOR, Constants.LoreAbility.LOR_LIGHT_OF_ELDAR):
		return 0
	return 2  # -2 attack and -2 evasion for shadow creatures in lit tiles

## Reset song noise perception bonus (called each turn by ability_system)
func reset_song_noise_bonus() -> void:
	song_noise_perception_bonus = 0

# ============================================================================
# DEATH
# ============================================================================

func die(killer: Entity = null) -> void:
	# Clean up domination reference
	if is_dominated and is_instance_valid(domination_owner) and domination_owner is Player:
		var p: Player = domination_owner as Player
		p.dominated_monsters.erase(self)
		is_dominated = false

	# Process rewards BEFORE calling super.die() which triggers signals
	# Check validity before using 'is' operator to avoid freed instance errors
	if killer != null and is_instance_valid(killer) and killer is Player:
		var stealth_kill: bool = alertness < Constants.ALERTNESS_ALERT  # Monster wasn't fully aware
		var has_silent_kill_ability: bool = killer.has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_SILENT_KILL)
		var was_silent: bool = stealth_kill or has_silent_kill_ability
		var stealth_kill_xp: int = experience_value * 2 if stealth_kill else experience_value
		killer.gain_experience(stealth_kill_xp, "kill")

		# Track in run stats
		killer.run_stats.record_kill(entity_name, stealth_kill_xp, was_silent)
		# Track kills by name for Bane ability
		killer.kills_by_name[entity_name] = killer.kills_by_name.get(entity_name, 0) + 1

		# Record kill in monster memory for description system
		if monster_data:
			var main_scene: Node = killer.get_tree().current_scene if killer.get_tree() else null
			if main_scene and main_scene.has_method("get_monster_memory"):
				var memory: RefCounted = main_scene.get_monster_memory()
				if memory and memory.has_method("record_kill"):
					memory.record_kill(monster_data.index)

		if stealth_kill:
			GameManager.log_message("You silently dispatch the %s! (+%d XP, stealth bonus!)" % [entity_name, stealth_kill_xp], ThemeColors.ABILITY_LEARNED)
		elif was_silent:
			GameManager.log_message("You silently dispatch the %s! (+%d XP)" % [entity_name, stealth_kill_xp], ThemeColors.ABILITY_LEARNED)
		else:
			GameManager.log_message("You have slain the %s! (+%d XP)" % [entity_name, stealth_kill_xp], ThemeColors.ABILITY_LEARNED)
			if GameManager.current_level and GameManager.current_level.has_method("add_floor_noise"):
				GameManager.current_level.add_floor_noise(Constants.NOISE_COMBAT_KILL)

		# Fade (Stealth ability): +10 stealth for 3 turns after kill
		if killer.has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_FADE):
			killer._fade_bonus = 10
			killer._fade_turns = 3

		# Check for special achievements
		if entity_name.begins_with("Nazgul") or "Ringwraith" in entity_name:
			killer.run_stats.killed_nazgul = true
		if entity_name == "Sauron" or entity_name == "The Necromancer":
			killer.run_stats.necromancer_defeated = true

	# Drop loot based on DROP flags
	_drop_loot()

	super.die(killer)

## Drop loot based on monster DROP flags from data files
func _drop_loot() -> void:
	if monster_data == null:
		return

	var current_level: Level = GameManager.current_level
	if current_level == null:
		return

	# Determine drop chance from flags
	var drop_chance: int = 0
	if monster_data.has_flag("DROP_100"):
		drop_chance = 100
	elif monster_data.has_flag("DROP_66"):
		drop_chance = 66
	elif monster_data.has_flag("DROP_33"):
		drop_chance = 33

	if drop_chance == 0:
		return

	# Roll for drop
	if randi_range(1, 100) > drop_chance:
		return

	# Determine item quality
	var is_good: bool = monster_data.has_flag("DROP_GOOD")
	var is_great: bool = monster_data.has_flag("DROP_GREAT")

	# Determine depth for item selection (monster's native depth, not floor depth)
	var item_depth: int = monster_data.depth
	if is_great:
		item_depth += 5  # Great drops are deeper-quality
	elif is_good:
		item_depth += 2  # Good drops are slightly better

	# Generate the item
	var item_data: DataManager.ItemData = DataManager.get_random_item_for_depth(item_depth)
	if item_data == null:
		return

	var item_copy: DataManager.ItemData = DataManager.duplicate_item_data(item_data)

	# Apply ego enchantment for good/great drops
	if is_great:
		_apply_ego_enchantment(item_copy, 2)
	elif is_good:
		_apply_ego_enchantment(item_copy, 1)

	# Spawn the item at monster's position
	var item_scene := preload("res://scenes/entities/item.tscn")
	var dropped_item: Item = item_scene.instantiate()
	dropped_item.grid_position = grid_position
	dropped_item.initialize_from_item_data(item_copy)
	current_level.add_item(dropped_item)
	GameManager.log_message("The %s drops a %s." % [entity_name, item_copy.name], ThemeColors.TEXT_SECONDARY)

## Apply random ego enchantment to a monster drop (quality: 1=good, 2=great)
func _apply_ego_enchantment(item: DataManager.ItemData, quality: int) -> void:
	# Quality 2 (great) gets deeper ego pool and excludes cursed
	var effective_depth: int = monster_data.depth + quality * 3
	var exclude_cursed: bool = quality >= 2
	var ego: DataManager.EgoData = DataManager.select_ego_for_item(item.tval, item.sval, effective_depth, exclude_cursed)
	if ego:
		DataManager.apply_ego_to_item(item, ego)
	else:
		# Fallback: just add quality bonus
		item.attack_bonus += quality
		item.name = "Fine %s" % item.name

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

	# Spell frequency: use parsed spell_frequency from S: line (0-100 scale)
	# If spell_frequency is 0 or missing, monster never casts
	var freq: int = monster_data.spell_frequency if "spell_frequency" in monster_data else 0
	if freq <= 0:
		return false
	if randf() > (float(freq) / 100.0):
		return false

	# Pick a random spell from available
	var spell: String = available_spells[randi() % available_spells.size()]
	return _cast_spell(spell, cast_target, distance)

func _get_available_spells() -> Array[String]:
	var spells: Array[String] = []
	if not monster_data:
		return spells

	# Primary source: spell_types array from S: lines in monster.txt
	# Map CROSSBOW -> ARROW1 for compatibility with the spell execution system
	for spell_type: String in monster_data.spell_types:
		var mapped: String = spell_type
		match spell_type:
			"CROSSBOW":
				mapped = "ARROW1"
			"ARROW":
				mapped = "ARROW1"
		if mapped not in spells:
			spells.append(mapped)

	# Legacy fallback: also check flags array for older monsters that use F: lines for spells
	var flag_spell_map: Array[String] = [
		"SHRIEK", "DARKNESS", "SLOW", "BR_FIRE", "BR_COLD", "BR_POIS", "BR_DARK",
		"ARROW1", "ARROW2", "BOULDER", "HOLD", "SCARE", "CONF"
	]
	for spell_name: String in flag_spell_map:
		if monster_data.has_flag(spell_name) and spell_name not in spells:
			spells.append(spell_name)

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
		save_roll = randi_range(1, 20) + p.get_effective_skill("will")
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
		save_roll = randi_range(1, 20) + p.get_effective_skill("will")
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
		save_roll = randi_range(1, 20) + p.get_effective_skill("will")
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
		save_roll = randi_range(1, 20) + p.get_effective_skill("will")
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
	last_attack_effect = "BREATH_%s" % element.to_upper()
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
	last_attack_effect = "RANGED_%s" % proj_name.to_upper()
	cast_target.take_damage(dmg, "physical", self)
	return true

# ============================================================================
# WEREWOLF SHAPESHIFTING
# ============================================================================

## Check if this monster is a werewolf
func _is_werewolf() -> bool:
	return monster_data != null and monster_data.name == "Werewolf"

## Werewolf AI: decide whether to shift forms each turn
func _werewolf_ai_update() -> void:
	if not _is_werewolf():
		return

	_shift_cooldown = maxi(0, _shift_cooldown - 1)

	# Shift to wolf when alert and seeing the player
	if werewolf_form == "human" and _shift_cooldown == 0:
		if alertness >= Constants.ALERTNESS_ALERT and ai_state == AIState.HUNTING:
			_shift_to_wolf()

	# Shift back to human when fleeing or badly wounded
	elif werewolf_form == "wolf" and _shift_cooldown == 0:
		if current_morale < 20 or current_health < max_health / 4:
			_shift_to_human()

## Transform into wolf form: +2 attack, speed boost, full monster attacks
func _shift_to_wolf() -> void:
	werewolf_form = "wolf"
	_shift_cooldown = 5  # Can't shift again for 5 turns
	_wolf_attack_bonus = 2
	# Speed boost: temporarily increase speed tier by 1
	if speed < 7:
		speed += 1
		_wolf_speed_bonus = 1
	GameManager.log_message("The %s transforms into a savage wolf!" % entity_name, ThemeColors.BLOOD_RED)
	vfx_flash(Color(0.6, 0.6, 0.6), 0.1, 0.3)
	vfx_particles(Color(0.5, 0.5, 0.5), 6, 25.0, 0.5)
	_notify_pack_shift("wolf")

## Transform back to human form: remove wolf bonuses, more cautious
func _shift_to_human() -> void:
	werewolf_form = "human"
	_shift_cooldown = 5
	# Remove wolf form bonuses
	_wolf_attack_bonus = 0
	if _wolf_speed_bonus > 0:
		speed -= _wolf_speed_bonus
		_wolf_speed_bonus = 0
	GameManager.log_message("The %s shifts back to human form." % entity_name, ThemeColors.TEXT_DIM)
	vfx_flash(Color(0.3, 0.3, 0.5), 0.1, 0.3)

## Notify nearby werewolves to shift (pack mentality)
## When one werewolf transforms, nearby pack members shift on their next turn
func _notify_pack_shift(form: String) -> void:
	if not GameManager.current_level:
		return
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or entity == self:
			continue
		if not entity is Monster:
			continue
		var mon: Monster = entity as Monster
		if not mon.is_alive or not mon._is_werewolf():
			continue
		var dist: int = _grid_distance(grid_position, mon.grid_position)
		if dist > 5:
			continue
		if mon._shift_cooldown > 0:
			continue
		if form == "wolf" and mon.werewolf_form == "human":
			# Alert the pack member so it meets the shift condition next turn
			mon.alertness = maxi(mon.alertness, Constants.ALERTNESS_ALERT)
			# Force hunting state so the AI check passes
			mon.ai_state = AIState.HUNTING
		elif form == "human" and mon.werewolf_form == "wolf":
			# Reduce morale to trigger shift back on their turn
			mon.current_morale = mini(mon.current_morale, 15)
