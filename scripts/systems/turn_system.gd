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
		current_level.update_fov(player.grid_position, 10)
		current_level.update_entity_visibility()

	EventBus.turn_ended.emit(player)

	# DO NOT EDIT: Grant player energy back immediately for responsive input
	# Monsters still use energy system for speed differences
	player.energy = Constants.ACTION_COST

	# Process any monster turns, then back to player
	_process_all_monsters_sync()
	current_state = TurnState.PLAYER_INPUT
	EventBus.player_turn_started.emit()

func _process_all_monsters_sync() -> void:
	# Process all monster turns synchronously (no await) for instant response
	if not current_level:
		return

	for monster in current_level.get_monsters():
		if monster.is_alive and monster.can_act():
			monster.take_turn()
			monster.consume_energy()

	# End round - grant energy to monsters
	current_round += 1
	for monster in current_level.get_monsters():
		if monster.is_alive:
			monster.grant_energy()
			monster.tick_status_effects()

	# Tick player effects
	if player and player.is_alive:
		player.tick_status_effects()
		player.reset_turn_state()

func _process_monster_turn() -> void:
	if pending_monsters.is_empty():
		current_state = TurnState.PROCESSING
		return

	var monster: Monster = pending_monsters.pop_front()
	if monster.is_alive and monster.can_act():
		monster.take_turn()
		monster.consume_energy()

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
		player.reset_turn_state()

	if current_level:
		for monster in current_level.get_monsters():
			if monster.is_alive:
				monster.grant_energy()
				monster.tick_status_effects()

	current_state = TurnState.PROCESSING

func _wait_for_animation() -> void:
	var prev_state := current_state
	current_state = TurnState.ANIMATING
	await get_tree().create_timer(animation_delay).timeout
	current_state = prev_state

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_entity_moved(_entity: Entity, _from: Vector2i, _to: Vector2i) -> void:
	pass

func _on_entity_damaged(_entity: Entity, _damage: int, _type: String, _source: Entity) -> void:
	pass

func _on_entity_died(entity: Entity, _killer: Entity) -> void:
	if entity == player:
		_handle_player_death()

func _handle_player_death() -> void:
	GameManager.game_over(false, "You have perished in the depths.")
