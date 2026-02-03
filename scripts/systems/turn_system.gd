extends Node
class_name TurnSystem
## Manages turn-based gameplay with visual feedback delays.
## Ensures animations complete before the next turn begins.

signal turn_started(entity: Entity)
signal turn_ended(entity: Entity)
signal round_completed(round_number: int)

enum TurnState { PLAYER_INPUT, PLAYER_ACTING, ENEMY_TURN, ANIMATING }

var current_state: TurnState = TurnState.PLAYER_INPUT
var current_round: int = 0
var animation_delay: float = 0.15  # Seconds to wait for animations

var pending_actions: Array = []
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

func _process(_delta: float) -> void:
	match current_state:
		TurnState.PLAYER_INPUT:
			_handle_player_input()
		TurnState.PLAYER_ACTING:
			pass  # Waiting for action to complete
		TurnState.ENEMY_TURN:
			_process_enemy_turns()
		TurnState.ANIMATING:
			pass  # Waiting for animations

func _handle_player_input() -> void:
	if not player or not player.is_alive:
		return

	if player.handle_input():
		# Player took an action
		current_state = TurnState.PLAYER_ACTING
		await _wait_for_animation()
		_end_player_turn()

func _end_player_turn() -> void:
	if current_level:
		current_level.update_fov(player.grid_position, 10)
		current_level.update_entity_visibility()

	EventBus.turn_ended.emit(player)
	current_state = TurnState.ENEMY_TURN

func _process_enemy_turns() -> void:
	if not current_level:
		current_state = TurnState.PLAYER_INPUT
		return

	var monsters := current_level.get_monsters()

	for monster in monsters:
		if monster.is_alive:
			monster.take_turn()
			await _wait_for_animation()

	_end_round()

func _end_round() -> void:
	current_round += 1
	EventBus.round_completed.emit(current_round)

	# Tick player status effects
	if player:
		player.tick_status_effects()

	current_state = TurnState.PLAYER_INPUT
	EventBus.player_turn_started.emit()

func _wait_for_animation() -> void:
	current_state = TurnState.ANIMATING
	await get_tree().create_timer(animation_delay).timeout

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_entity_moved(_entity: Entity, _from: Vector2i, _to: Vector2i) -> void:
	# Could add movement animation delay here
	pass

func _on_entity_damaged(_entity: Entity, _damage: int, _type: String, _source: Entity) -> void:
	# Could add hit animation delay here
	pass

func _on_entity_died(entity: Entity, _killer: Entity) -> void:
	if entity == player:
		_handle_player_death()

func _handle_player_death() -> void:
	GameManager.game_over(false, "You have perished in the depths.")
