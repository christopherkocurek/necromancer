extends Node
class_name TurnSystem
## Manages turn-based gameplay with energy system.
## Entities act when they have >= 100 energy.
## Faster entities accumulate energy more quickly.

signal turn_started(entity: Entity)
signal turn_ended(entity: Entity)
signal round_completed(round_number: int)

enum TurnState {
	PROCESSING,
	PLAYER_INPUT,
	PLAYER_ACTING,
	MONSTER_ACTING,
	ANIMATING,
	ROUND_END
}

var current_state: TurnState = TurnState.PROCESSING
var current_round: int = 0
# DO NOT EDIT: Animation delay tuned for instant responsive gameplay
var animation_delay: float = 0.001

var pending_monsters: Array[Monster] = []
var current_level: Level = null
var player: Player = null

func _ready() -> void:
	EventBus.entity_moved.connect(_on_entity_moved)
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.attack_missed.connect(_on_attack_missed)

func set_level(level: Level) -> void:
	current_level = level

func set_player(p: Player) -> void:
	player = p
	# Give player initial energy to act first
	if player:
		player.energy = Constants.ACTION_COST

func _process(_delta: float) -> void:
	match current_state:
		TurnState.PROCESSING:
			_determine_next_actor()
		TurnState.PLAYER_INPUT:
			_handle_player_input()
		TurnState.PLAYER_ACTING:
			pass  # Waiting for action to complete
		TurnState.MONSTER_ACTING:
			_process_monster_turn()
		TurnState.ANIMATING:
			pass  # Waiting for animations
		TurnState.ROUND_END:
			_end_round()

func _determine_next_actor() -> void:
	if not player or not player.is_alive:
		return

	if player.can_act():
		# Find monsters with MORE energy than player
		var priority_monsters := _get_monsters_above_energy(player.energy + 1)

		if priority_monsters.is_empty():
			current_state = TurnState.PLAYER_INPUT
			EventBus.player_turn_started.emit()
		else:
			pending_monsters = priority_monsters
			current_state = TurnState.MONSTER_ACTING
	else:
		# Player can't act - process remaining monsters
		var acting_monsters := _get_monsters_above_energy(Constants.ACTION_COST)

		if acting_monsters.is_empty():
			current_state = TurnState.ROUND_END
		else:
			pending_monsters = acting_monsters
			current_state = TurnState.MONSTER_ACTING

func _get_monsters_above_energy(threshold: int) -> Array[Monster]:
	var result: Array[Monster] = []
	if not current_level:
		return result

	for monster in current_level.get_monsters():
		if monster.is_alive and monster.energy >= threshold:
			result.append(monster)

	# Sort by energy (highest first)
	result.sort_custom(func(a: Monster, b: Monster) -> bool:
		return a.energy > b.energy
	)
	return result

func _handle_player_input() -> void:
	if not player or not player.is_alive:
		return

	if player.handle_input():
		# Player took an action - consume energy
		# DO NOT EDIT: No await here - immediate response to player input
		player.consume_energy()
		_after_player_action()

func _after_player_action() -> void:
	if current_level:
		# Refresh glowing items before lighting pass
		current_level.refresh_glowing_items()
		# Update FOV: geometry → lighting → entity visibility → tilemap
		var fov_radius: int = current_level.get_fov_radius()
		var light_radius: int = player.get_light_radius()
		current_level.update_fov(player.grid_position, fov_radius)
		current_level.apply_lighting(player.grid_position, light_radius)
		current_level.update_entity_visibility()
		current_level.apply_fov_to_tilemap()

		# Light ecology: check light-sensitive monsters near player
		_check_light_recoil()

	EventBus.turn_ended.emit(player)

	# Process game tick - all entities gain energy based on speed
	_process_game_tick()

	# Check for ambient messages (layer atmosphere)
	_check_ambient_message()

	# Check if player can act again, otherwise wait for monsters
	current_state = TurnState.PROCESSING

## Check light-sensitive monsters near the player and trigger recoil effects
func _check_light_recoil() -> void:
	if not player or not current_level:
		return
	for entity in current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		if entity.is_light_sensitive:
			entity.check_light_recoil(player)

func _check_ambient_message() -> void:
	# Occasionally show atmospheric messages based on current layer
	var ambient_msg := LayerConfig.get_ambient_message(GameManager.current_depth)
	if not ambient_msg.is_empty():
		GameManager.log_message(ambient_msg, ThemeColors.TEXT_MUTED)

func _process_game_tick() -> void:
	# Grant energy to all entities based on their speed
	# This is called after each player action
	if not current_level:
		return

	# Grant energy to player
	if player and player.is_alive:
		player.grant_energy()

	# Grant energy to all monsters
	for monster in current_level.get_monsters():
		if monster.is_alive:
			monster.grant_energy()

	# Process monster turns - monsters with enough energy act
	for monster in current_level.get_monsters():
		if monster.is_alive and monster.can_act():
			monster.take_turn()
			monster.consume_energy()

	# Refresh entity visibility after all monsters have moved
	current_level.update_entity_visibility()

	# Increment round counter
	current_round += 1

	# Tick status effects
	if player and player.is_alive:
		player.tick_status_effects()
		player.reset_turn_state()

		# Hunger decay (1 per turn)
		player.tick_hunger()

		# Check hunger penalties for regen suppression
		var hunger_penalties: Dictionary = player.get_hunger_penalties()
		var no_regen: bool = hunger_penalties.get("no_regen", false)

		# HP regeneration: 1 HP every (20 - Con) turns, minimum every 5 turns
		# Suppressed when famished or starving
		var regen_interval: int = maxi(5, 20 - player.constitution)
		if not no_regen and current_round % regen_interval == 0 and player.current_health < player.max_health:
			player.current_health = mini(player.current_health + 1, player.max_health)
		# Voice regeneration: 1 charge every 3 turns
		# Suppressed when famished or starving
		if not no_regen and current_round % 3 == 0 and player.voice_charges < player.max_voice:
			player.voice_charges += 1

		# Starvation damage
		player.apply_starvation_damage(current_round)

	for monster in current_level.get_monsters():
		if monster.is_alive:
			monster.tick_status_effects()

func _process_monster_turn() -> void:
	if pending_monsters.is_empty():
		current_state = TurnState.PROCESSING
		return

	var monster: Monster = pending_monsters.pop_front()
	if monster.is_alive and monster.can_act():
		monster.reset_light_recoil()  # Allow recoil message next player action
		monster.take_turn()
		monster.consume_energy()

		# Refresh entity visibility after monster moved
		if current_level:
			current_level.update_entity_visibility()

		# Only wait for visible monsters to keep things snappy
		if monster.visible:
			await _wait_for_animation()

	# Continue processing or go back to determine next actor
	if pending_monsters.is_empty():
		current_state = TurnState.PROCESSING
	# else stay in MONSTER_ACTING to process next

func _end_round() -> void:
	current_round += 1
	EventBus.round_completed.emit(current_round)

	# Grant energy to all entities
	if player and player.is_alive:
		player.grant_energy()
		player.tick_status_effects()
		player.tick_light_fuel()
		player.tick_hunger()
		player.apply_starvation_damage(current_round)
		player.reset_turn_state()

	if current_level:
		for monster in current_level.get_monsters():
			if monster.is_alive:
				monster.grant_energy()
				monster.tick_status_effects()
		# Decay floor-wide alertness
		current_level.tick_floor_alertness()

	current_state = TurnState.PROCESSING

func _wait_for_animation() -> void:
	var prev_state := current_state
	current_state = TurnState.ANIMATING
	await get_tree().create_timer(animation_delay).timeout
	current_state = prev_state

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_entity_moved(entity: Entity, from: Vector2i, to: Vector2i) -> void:
	# Zone of Control: player gets free attack when monster enters adjacent tile
	if not player or not is_instance_valid(player):
		return
	if not entity is Monster:
		return
	if not player.has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_ZONE_OF_CONTROL):
		return
	# Check if monster moved INTO an adjacent tile to the player (wasn't adjacent before)
	var was_adjacent: bool = absi(from.x - player.grid_position.x) <= 1 and absi(from.y - player.grid_position.y) <= 1
	var now_adjacent: bool = absi(to.x - player.grid_position.x) <= 1 and absi(to.y - player.grid_position.y) <= 1
	if now_adjacent and not was_adjacent and is_instance_valid(entity) and entity.is_alive:
		GameManager.log_message("Zone of control!", ThemeColors.MSG_WARNING)
		# Defer to avoid re-entrant combat during monster's turn
		call_deferred("_execute_zone_of_control", entity)

func _on_entity_damaged(_entity: Entity, _damage: int, _type: String, _source: Entity) -> void:
	pass

func _on_attack_missed(attacker: Node, defender: Node) -> void:
	# Riposte: player gets free counterattack when a monster misses them
	if not player or not is_instance_valid(player):
		return
	if defender != player:
		return
	if not attacker is Monster or not is_instance_valid(attacker):
		return
	if not player.has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_RIPOSTE):
		return
	# Must be adjacent
	var dist: Vector2i = attacker.grid_position - player.grid_position
	if absi(dist.x) > 1 or absi(dist.y) > 1:
		return
	# Limit to 1 riposte per turn
	if player.ripostes_this_turn >= 1:
		return
	player.ripostes_this_turn += 1
	GameManager.log_message("Riposte!", ThemeColors.MSG_WARNING)
	# Defer to avoid re-entrant combat during monster's attack
	call_deferred("_execute_riposte", attacker)

func _execute_zone_of_control(target: Entity) -> void:
	if is_instance_valid(target) and target.is_alive and player and is_instance_valid(player) and player.is_alive:
		player.attack_entity(target)

func _execute_riposte(target: Entity) -> void:
	if is_instance_valid(target) and target.is_alive and player and is_instance_valid(player) and player.is_alive:
		player.attack_entity(target)

func _on_entity_died(entity: Entity, _killer: Entity) -> void:
	if entity == player:
		_handle_player_death()

func _handle_player_death() -> void:
	GameManager.game_over(false, "You have perished in the depths.")
