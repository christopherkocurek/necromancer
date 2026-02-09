class_name HornSystem
## Handles horn and flute item effects (tval 66).
## Horns produce cone-based effects in a direction.
## Challenge horn and Fairy flute are self-targeted/area effects.

# ============================================================================
# MAIN DISPATCH
# ============================================================================

## Use a horn/flute item. Direction is ignored for self-targeted items.
## Returns true if the horn was successfully used.
static func use_horn(player: Player, item_data: Variant, direction: Vector2i) -> bool:
	var sval: int = item_data.sval if "sval" in item_data else -1
	match sval:
		Constants.HORN_TERROR:
			return _horn_of_terror(player, direction)
		Constants.HORN_THUNDER:
			return _horn_of_thunder(player, direction)
		Constants.HORN_FORCE:
			return _horn_of_force(player, direction)
		Constants.HORN_BLASTING:
			return _horn_of_blasting(player, direction)
		Constants.HORN_CHALLENGE:
			return _horn_of_challenge(player)
		Constants.FLUTE_FAIRY:
			return _flute_of_fairy(player)
	GameManager.log_message("Nothing happens.", ThemeColors.MSG_SYSTEM)
	return false

# ============================================================================
# HORN OF TERROR (sval 0) - Fear cone
# ============================================================================

## 90-degree fear cone, radius 3. Player Will vs monster Will.
static func _horn_of_terror(player: Player, direction: Vector2i) -> bool:
	GameManager.log_message("You blow a blast of terror on the horn!", ThemeColors.MSG_WARNING)
	player.vfx_flash(ThemeColors.STATUS_AFRAID, 0.08, 0.2)

	var level: Level = GameManager.current_level
	if not level:
		return true

	var cone_positions: Array[Vector2i] = _get_cone_positions(
		player.grid_position, direction,
		Constants.HORN_CONE_RADIUS, Constants.HORN_CONE_ANGLE
	)

	var player_will: int = player.get_effective_skill("will")
	var affected_count: int = 0

	for pos: Vector2i in cone_positions:
		var entity: Entity = level.get_entity_at(pos)
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		var monster: Monster = entity as Monster

		# Check fear immunity
		if monster.monster_data and monster.monster_data.has_flag("NO_FEAR"):
			GameManager.log_message("The %s is immune to fear!" % monster.entity_name, ThemeColors.MSG_SYSTEM)
			continue

		# Opposed roll: player Will vs monster Will
		var player_roll: int = randi_range(1, 20) + player_will
		var monster_will: int = monster.monster_data.will if monster.monster_data else 5
		var monster_roll: int = randi_range(1, 20) + monster_will

		if player_roll >= monster_roll:
			monster.apply_status(Constants.EFFECT_AFRAID, Constants.HORN_TERROR_FEAR_DURATION)
			GameManager.log_message("The %s flees in terror!" % monster.entity_name, ThemeColors.STATUS_AFRAID)
			monster.vfx_flash(ThemeColors.STATUS_AFRAID, 0.06, 0.15)
			affected_count += 1
		else:
			GameManager.log_message("The %s resists the fear!" % monster.entity_name, ThemeColors.MSG_SYSTEM)

	if affected_count == 0:
		GameManager.log_message("The horn echoes, but nothing is affected.", ThemeColors.MSG_SYSTEM)

	_apply_floor_noise(level, Constants.HORN_NOISE_TERROR)
	return true

# ============================================================================
# HORN OF THUNDER (sval 1) - Sound damage cone
# ============================================================================

## 90-degree damage cone, radius 3. 10d4 sound damage + stun.
static func _horn_of_thunder(player: Player, direction: Vector2i) -> bool:
	GameManager.log_message("You blow a deafening blast of thunder!", ThemeColors.COMBAT_CRIT)
	player.vfx_flash(Color(1.0, 1.0, 0.6), 0.08, 0.2)

	var level: Level = GameManager.current_level
	if not level:
		return true

	var cone_positions: Array[Vector2i] = _get_cone_positions(
		player.grid_position, direction,
		Constants.HORN_CONE_RADIUS, Constants.HORN_CONE_ANGLE
	)

	var affected_count: int = 0

	for pos: Vector2i in cone_positions:
		var entity: Entity = level.get_entity_at(pos)
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		var monster: Monster = entity as Monster

		# Roll 10d4 sound damage
		var damage: int = DataManager.roll_dice(Constants.HORN_THUNDER_DAMAGE_DICE)
		GameManager.log_message("The %s is blasted by thunder! (%d damage)" % [monster.entity_name, damage], ThemeColors.COMBAT_HIT)
		monster.take_damage(damage, "sound", player)

		# Apply stun if still alive (stun immunity check handled by status system)
		if is_instance_valid(monster) and monster.is_alive:
			if monster.monster_data and monster.monster_data.has_flag("NO_STUN"):
				GameManager.log_message("The %s shakes off the stun!" % monster.entity_name, ThemeColors.MSG_SYSTEM)
			else:
				monster.apply_status(Constants.EFFECT_STUNNED, Constants.HORN_THUNDER_STUN_DURATION)
			monster.vfx_flash(Color(1.0, 1.0, 0.6), 0.06, 0.15)

		affected_count += 1

	if affected_count == 0:
		GameManager.log_message("The thunderous blast echoes through empty halls.", ThemeColors.MSG_SYSTEM)

	_apply_floor_noise(level, Constants.HORN_NOISE_THUNDER)
	return true

# ============================================================================
# HORN OF FORCE (sval 2) - Knockback cone
# ============================================================================

## 90-degree knockback cone, radius 3. Will+10 vs Con*2. Push 1-3 tiles.
static func _horn_of_force(player: Player, direction: Vector2i) -> bool:
	GameManager.log_message("You blow a mighty blast of force!", ThemeColors.MSG_WARNING)
	player.vfx_flash(Color(0.6, 0.8, 1.0), 0.08, 0.2)

	var level: Level = GameManager.current_level
	if not level:
		return true

	var cone_positions: Array[Vector2i] = _get_cone_positions(
		player.grid_position, direction,
		Constants.HORN_CONE_RADIUS, Constants.HORN_CONE_ANGLE
	)

	var player_will: int = player.get_effective_skill("will")
	var affected_count: int = 0

	# Sort positions from farthest to nearest so knockback doesn't collide
	cone_positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var dist_a: int = maxi(absi(a.x - player.grid_position.x), absi(a.y - player.grid_position.y))
		var dist_b: int = maxi(absi(b.x - player.grid_position.x), absi(b.y - player.grid_position.y))
		return dist_a > dist_b
	)

	for pos: Vector2i in cone_positions:
		var entity: Entity = level.get_entity_at(pos)
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		var monster: Monster = entity as Monster

		# Opposed roll: (player Will + 10) vs (monster Con * 2)
		var player_roll: int = randi_range(1, 20) + player_will + 10
		var monster_con: int = monster.constitution * 2
		var monster_roll: int = randi_range(1, 20) + monster_con

		if player_roll >= monster_roll:
			# Knockback 1-3 tiles
			var knockback_dist: int = randi_range(Constants.HORN_FORCE_KNOCKBACK_MIN, Constants.HORN_FORCE_KNOCKBACK_MAX)
			var push_dir: Vector2i = _get_push_direction(player.grid_position, monster.grid_position)
			var pushed: int = _push_entity(level, monster, push_dir, knockback_dist)
			if pushed > 0:
				GameManager.log_message("The %s is hurled back %d tiles!" % [monster.entity_name, pushed], ThemeColors.MSG_WARNING)
				monster.vfx_flash(Color(0.6, 0.8, 1.0), 0.06, 0.15)
			else:
				GameManager.log_message("The %s staggers but holds ground!" % monster.entity_name, ThemeColors.MSG_SYSTEM)
			affected_count += 1
		else:
			# Failed: stagger (lose next turn via stun 1 turn)
			GameManager.log_message("The %s resists the force but staggers!" % monster.entity_name, ThemeColors.MSG_SYSTEM)
			if not (monster.monster_data and monster.monster_data.has_flag("NO_STUN")):
				monster.apply_status(Constants.EFFECT_STUNNED, 1)
			affected_count += 1

	if affected_count == 0:
		GameManager.log_message("The forceful blast finds no targets.", ThemeColors.MSG_SYSTEM)

	_apply_floor_noise(level, Constants.HORN_NOISE_FORCE)
	return true

# ============================================================================
# HORN OF BLASTING (sval 3) - Wall-breaking
# ============================================================================

## Destroy walls in chosen direction, up to 3 tiles deep.
static func _horn_of_blasting(player: Player, direction: Vector2i) -> bool:
	GameManager.log_message("You blow a shattering blast!", ThemeColors.COMBAT_CRIT)
	player.vfx_flash(Color(1.0, 0.8, 0.4), 0.1, 0.25)

	var level: Level = GameManager.current_level
	if not level:
		return true

	var walls_broken: int = 0
	var current_pos: Vector2i = player.grid_position

	for i in range(Constants.HORN_BLASTING_RANGE):
		current_pos += direction
		if not level.is_in_bounds(current_pos):
			break

		var tile: int = level.get_tile(current_pos)

		# Check if tile is breakable
		var broke_something: bool = false
		match tile:
			Level.Tile.WALL:
				level.set_tile(current_pos, Level.Tile.RUBBLE)
				walls_broken += 1
				broke_something = true
			Level.Tile.DOOR_CLOSED, Level.Tile.DOOR_LOCKED, Level.Tile.DOOR_JAMMED, Level.Tile.DOOR_SECRET:
				level.set_tile(current_pos, Level.Tile.DOOR_OPEN)
				walls_broken += 1
				broke_something = true
			Level.Tile.RUBBLE:
				level.set_tile(current_pos, Level.Tile.FLOOR)
				walls_broken += 1
				broke_something = true

		# Check for monsters at this position
		var hit_entity: Entity = level.get_entity_at(current_pos)
		if broke_something:
			# Damage monsters standing in broken tiles
			if is_instance_valid(hit_entity) and hit_entity is Monster and hit_entity.is_alive:
				var crush_damage: int = randi_range(8, 20)
				GameManager.log_message("The %s is crushed by collapsing stone! (%d damage)" % [hit_entity.entity_name, crush_damage], ThemeColors.COMBAT_HIT)
				hit_entity.take_damage(crush_damage, "physical", player)
		else:
			# Hit open space or unbreakable tile: damage monster with debris, then stop
			if is_instance_valid(hit_entity) and hit_entity is Monster and hit_entity.is_alive:
				var debris_damage: int = randi_range(5, 15)
				GameManager.log_message("The %s is struck by flying debris! (%d damage)" % [hit_entity.entity_name, debris_damage], ThemeColors.COMBAT_HIT)
				hit_entity.take_damage(debris_damage, "physical", player)
			break

	if walls_broken > 0:
		GameManager.log_message("Stone shatters! %d tiles destroyed." % walls_broken, ThemeColors.MSG_WARNING)
		# Refresh FOV after terrain change
		_refresh_fov(player, level)
	else:
		GameManager.log_message("The blast echoes but finds nothing to break.", ThemeColors.MSG_SYSTEM)

	_apply_floor_noise(level, Constants.HORN_NOISE_BLASTING)
	return true

# ============================================================================
# HORN OF CHALLENGE (sval 4) - Battle-fury buff
# ============================================================================

## Self-buff: +1 STR/CON, -1 DEX/GRA for 20 turns. Aggro all nearby monsters.
static func _horn_of_challenge(player: Player) -> bool:
	GameManager.log_message("You blow a defiant challenge! Battle-fury surges through you!", ThemeColors.COMBAT_CRIT)
	player.vfx_flash(ThemeColors.STATUS_RAGE, 0.1, 0.25)
	player.vfx_particles(ThemeColors.STATUS_RAGE, 8, 40.0, 0.5)

	# Stat modifications (stored as metadata for reversal on expiry)
	player.strength += 1
	player.constitution += 1
	player.dexterity = maxi(0, player.dexterity - 1)
	player.grace = maxi(0, player.grace - 1)

	# Store bonuses for reversal when battle_fury expires (see status_effects.gd)
	player.set_meta("battle_fury_str", 1)
	player.set_meta("battle_fury_con", 1)
	player.set_meta("battle_fury_dex", 1)
	player.set_meta("battle_fury_gra", 1)

	# Apply battle-fury status (after metadata is set)
	player.apply_status(Constants.EFFECT_BATTLE_FURY, Constants.HORN_CHALLENGE_DURATION)
	player._recalculate_stats()

	GameManager.log_message("+1 Str, +1 Con, -1 Dex, -1 Gra for %d turns." % Constants.HORN_CHALLENGE_DURATION, ThemeColors.STATUS_BUFF)

	# Aggro all monsters within radius 5
	var level: Level = GameManager.current_level
	if level:
		var aggro_count: int = 0
		var nearby: Array[Entity] = level.get_entities_in_radius(player.grid_position, Constants.HORN_CHALLENGE_AGGRO_RADIUS)
		for entity: Entity in nearby:
			if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
				continue
			var monster: Monster = entity as Monster
			monster.alertness = Constants.ALERTNESS_MAX
			monster.target = player
			monster.ai_state = Monster.AIState.HUNTING
			if monster.is_sleeping:
				monster.is_sleeping = false
			aggro_count += 1

		if aggro_count > 0:
			GameManager.log_message("%d nearby monsters are drawn to the challenge!" % aggro_count, ThemeColors.MSG_WARNING)

		_apply_floor_noise(level, Constants.HORN_NOISE_CHALLENGE)

	return true

# ============================================================================
# FLUTE OF THE FAIRY (sval 5) - Area darkness
# ============================================================================

## Darken all tiles in radius 3 around player. Blocks LOS. Lasts 10 turns.
static func _flute_of_fairy(player: Player) -> bool:
	GameManager.log_message("You play a haunting melody on the fairy flute...", ThemeColors.MSG_STEALTH)
	player.vfx_flash(ThemeColors.STATUS_DARKENED, 0.1, 0.25)
	player.vfx_particles(ThemeColors.DMG_DARK, 6, 35.0, 0.5)

	var level: Level = GameManager.current_level
	if not level:
		return true

	# Apply fairy mist status to player (tracks duration for cleanup)
	player.apply_status(Constants.EFFECT_FAIRY_MIST, Constants.FLUTE_FAIRY_DURATION)

	# Store mist center and metadata so the mist can be tracked
	player.set_meta("fairy_mist_center", player.grid_position)
	player.set_meta("fairy_mist_radius", Constants.FLUTE_FAIRY_RADIUS)

	# Darken tiles in radius
	var darkened_count: int = 0
	var center: Vector2i = player.grid_position
	for dx: int in range(-Constants.FLUTE_FAIRY_RADIUS, Constants.FLUTE_FAIRY_RADIUS + 1):
		for dy: int in range(-Constants.FLUTE_FAIRY_RADIUS, Constants.FLUTE_FAIRY_RADIUS + 1):
			var pos: Vector2i = center + Vector2i(dx, dy)
			if not level.is_in_bounds(pos):
				continue
			var dist: int = maxi(absi(dx), absi(dy))
			if dist > Constants.FLUTE_FAIRY_RADIUS:
				continue
			# Darken the tile
			var idx: int = pos.y * level.width + pos.x
			level.tile_lit[idx] = false
			level.tile_visibility[idx] = false
			darkened_count += 1

	# Refresh display
	level.apply_fov_to_tilemap()

	GameManager.log_message("A shroud of magical darkness spreads around you! (%d tiles)" % darkened_count, ThemeColors.MSG_STEALTH)
	GameManager.log_message("Monsters in the mist cannot see you.", ThemeColors.MSG_INFO)

	_apply_floor_noise(level, Constants.HORN_NOISE_FLUTE)
	return true

# ============================================================================
# CONE GEOMETRY
# ============================================================================

## Get all positions within a cone from origin in the given direction.
## angle_degrees is the full cone angle (90 = 45 on each side of center).
static func _get_cone_positions(origin: Vector2i, direction: Vector2i, radius: int, angle_degrees: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var level: Level = GameManager.current_level

	# Normalize direction to a float vector for angle calculation
	var dir_vec: Vector2 = Vector2(direction).normalized()
	if dir_vec.length_squared() < 0.01:
		# Fallback: if no direction, return empty
		return positions

	var half_angle_rad: float = deg_to_rad(angle_degrees / 2.0)

	for r: int in range(1, radius + 1):
		for dx: int in range(-r, r + 1):
			for dy: int in range(-r, r + 1):
				var offset: Vector2i = Vector2i(dx, dy)
				var pos: Vector2i = origin + offset

				# Skip origin
				if pos == origin:
					continue

				# Skip out of bounds
				if level and not level.is_in_bounds(pos):
					continue

				# Check distance (Chebyshev)
				var dist: int = maxi(absi(dx), absi(dy))
				if dist > radius or dist == 0:
					continue

				# Check if already added
				if pos in positions:
					continue

				# Check angle from direction vector
				var offset_vec: Vector2 = Vector2(offset).normalized()
				var angle: float = dir_vec.angle_to(offset_vec)
				if absf(angle) > half_angle_rad:
					continue

				# Check line of sight from origin
				if level and not level.has_los_to(origin, pos):
					continue

				positions.append(pos)

	return positions

# ============================================================================
# KNOCKBACK HELPER
# ============================================================================

## Get the push direction from source to target (normalized to adjacent step).
static func _get_push_direction(source: Vector2i, target: Vector2i) -> Vector2i:
	var diff: Vector2i = target - source
	return Vector2i(signi(diff.x), signi(diff.y))

## Push an entity in a direction, up to max_dist tiles.
## Returns number of tiles actually pushed.
static func _push_entity(level: Level, entity: Entity, push_dir: Vector2i, max_dist: int) -> int:
	var pushed: int = 0
	for i: int in range(max_dist):
		var next_pos: Vector2i = entity.grid_position + push_dir
		if not level.is_in_bounds(next_pos):
			break
		if not level.is_passable(next_pos):
			break
		# Check for blocking entities at target
		var blocker: Entity = level.get_entity_at(next_pos)
		if is_instance_valid(blocker) and blocker != entity:
			break
		entity.grid_position = next_pos
		pushed += 1
	return pushed

# ============================================================================
# UTILITY
# ============================================================================

## Add noise to the floor alertness system.
static func _apply_floor_noise(level: Level, amount: int) -> void:
	if level and level.has_method("add_floor_noise"):
		level.add_floor_noise(amount)

## Refresh FOV after terrain changes (e.g., wall destruction).
static func _refresh_fov(player: Player, level: Level) -> void:
	if not level or not player:
		return
	var fov_radius: int = level.get_fov_radius()
	var light_radius: int = player.get_light_radius()
	level.update_fov(player.grid_position, fov_radius)
	level.apply_lighting(player.grid_position, light_radius)
	level.update_entity_visibility()
	level.apply_fov_to_tilemap()
