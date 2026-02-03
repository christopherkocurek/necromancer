extends Node
## Central game state manager.
## Coordinates turn flow, game state, and high-level game logic.

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER, INVENTORY, DIALOGUE }

var current_state: GameState = GameState.MAIN_MENU
var current_depth: int = 1
var turn_count: int = 0
var is_player_turn: bool = true

# References set during gameplay
var player: Node = null
var current_level: Node = null

# Game configuration
const TILE_SIZE: int = 64
const ZOOM_LEVELS: Array[float] = [0.5, 1.0, 2.0]
var current_zoom_index: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_new_game() -> void:
	current_depth = 1
	turn_count = 0
	is_player_turn = true
	current_state = GameState.PLAYING
	EventBus.game_started.emit()

func change_state(new_state: GameState) -> void:
	var old_state := current_state
	current_state = new_state

	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
			EventBus.game_paused.emit()
		GameState.PLAYING:
			get_tree().paused = false
			if old_state == GameState.PAUSED:
				EventBus.game_resumed.emit()
		GameState.GAME_OVER:
			pass

func end_player_turn() -> void:
	is_player_turn = false
	EventBus.turn_ended.emit(player)
	EventBus.enemy_turn_started.emit()

func end_enemy_turn() -> void:
	turn_count += 1
	is_player_turn = true
	EventBus.round_completed.emit(turn_count)
	EventBus.player_turn_started.emit()

func descend_level() -> void:
	current_depth += 1
	EventBus.level_entered.emit(current_depth)

func ascend_level() -> void:
	if current_depth > 1:
		current_depth -= 1
		EventBus.level_entered.emit(current_depth)

func game_over(victory: bool, reason: String = "") -> void:
	current_state = GameState.GAME_OVER
	EventBus.game_over.emit(victory, reason)

func cycle_zoom() -> void:
	current_zoom_index = (current_zoom_index + 1) % ZOOM_LEVELS.size()

func get_current_zoom() -> float:
	return ZOOM_LEVELS[current_zoom_index]

func log_message(text: String, color: Color = Color.WHITE) -> void:
	EventBus.message_logged.emit(text, color)
