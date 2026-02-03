extends Node2D
## Main game scene - coordinates level generation, player spawning, and turn flow.

@onready var level_container: Node2D = $LevelContainer
@onready var hud: HUD = $HUD
@onready var turn_system: TurnSystem = $TurnSystem
@onready var floater_manager: Node = $FloaterManager

var current_level: Level = null
var player: Player = null

const LEVEL_SCENE := preload("res://scenes/levels/level.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")

func _ready() -> void:
	# Start new game
	_start_new_game()

func _start_new_game() -> void:
	GameManager.start_new_game()

	# Generate first level
	_generate_level(1)

	# Spawn player
	_spawn_player()

	# Set up systems
	turn_system.set_level(current_level)
	turn_system.set_player(player)
	floater_manager.set_container(current_level.get_node("Effects"))

	# Initial FOV update
	current_level.update_fov(player.grid_position, 10)

	# Welcome message
	GameManager.log_message("Welcome, Necromancer. You awaken in the depths...", Color.CYAN)
	GameManager.log_message("Use WASD/HJKL/arrows to move. Press ? for help.", Color.GRAY)

func _generate_level(depth: int) -> void:
	# Clean up old level
	if current_level:
		current_level.queue_free()

	# Create new level
	current_level = LEVEL_SCENE.instantiate()
	current_level.depth = depth
	level_container.add_child(current_level)

	# Generate dungeon
	var generator := DungeonGenerator.new()
	generator.generate(current_level, depth)

	# Store reference
	GameManager.current_level = current_level

	EventBus.level_entered.emit(depth)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()

	# Find starting position (stairs up or random floor)
	var start_pos := current_level.find_stairs_up()
	if start_pos == Vector2i(-1, -1):
		start_pos = current_level.find_random_floor()

	player.grid_position = start_pos
	current_level.add_entity(player)

	# Store reference
	GameManager.player = player

	# Update HUD
	hud.update_player_stats(player)

func _process(_delta: float) -> void:
	# Update HUD every frame (could optimize to event-based)
	if player and player.is_alive:
		hud.update_player_stats(player)

	# Check for level transitions
	_check_stairs()

	# Handle zoom
	if Input.is_action_just_pressed("zoom_in") or Input.is_action_just_pressed("zoom_out"):
		_update_camera_zoom()

func _check_stairs() -> void:
	if not player or not current_level:
		return

	var tile := current_level.get_tile(player.grid_position)

	# Check for input to use stairs
	if Input.is_action_just_pressed("ui_accept"):  # Enter key
		match tile:
			Level.Tile.STAIRS_DOWN:
				_descend()
			Level.Tile.STAIRS_UP:
				if GameManager.current_depth > 1:
					_ascend()

func _descend() -> void:
	GameManager.descend_level()

	# Remove player from current level
	current_level.remove_entity(player)

	# Generate new level
	_generate_level(GameManager.current_depth)

	# Place player at stairs up
	var start_pos := current_level.find_stairs_up()
	if start_pos == Vector2i(-1, -1):
		start_pos = current_level.find_random_floor()

	player.grid_position = start_pos
	current_level.add_entity(player)

	# Update systems
	turn_system.set_level(current_level)
	floater_manager.set_container(current_level.get_node("Effects"))

	# Update FOV
	current_level.update_fov(player.grid_position, 10)

	GameManager.log_message("You descend deeper into the darkness...", Color.CYAN)

func _ascend() -> void:
	GameManager.ascend_level()

	# For now, just regenerate (in full game, would cache levels)
	current_level.remove_entity(player)

	_generate_level(GameManager.current_depth)

	var start_pos := current_level.find_stairs_down()
	if start_pos == Vector2i(-1, -1):
		start_pos = current_level.find_random_floor()

	player.grid_position = start_pos
	current_level.add_entity(player)

	turn_system.set_level(current_level)
	floater_manager.set_container(current_level.get_node("Effects"))
	current_level.update_fov(player.grid_position, 10)

	GameManager.log_message("You climb back up...", Color.CYAN)

func _update_camera_zoom() -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	if camera:
		camera.zoom = Vector2.ONE * GameManager.get_current_zoom()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Pause menu (to be implemented)
		pass
