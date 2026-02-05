extends Node2D
## Main game scene - coordinates level generation, player spawning, UI, and turn flow.

enum GameState { CHARACTER_CREATION, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.CHARACTER_CREATION

@onready var level_container: Node2D = $LevelContainer
@onready var hud: HUD = $HUD
@onready var turn_system: TurnSystem = $TurnSystem
@onready var floater_manager: Node = $FloaterManager
@onready var ui_layer: CanvasLayer = $UILayer

# UI Panels (instantiated dynamically)
# Note: Using Control type to avoid load-order issues with class_name registration
var character_creation: Control = null
var inventory_panel: Control = null
var skills_panel: Control = null
var abilities_panel: Control = null

var current_level: Level = null
var player: Player = null

const LEVEL_SCENE := preload("res://scenes/levels/level.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")
const CHARACTER_CREATION_SCENE := preload("res://scenes/ui/character_creation.tscn")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const SKILLS_PANEL_SCENE := preload("res://scenes/ui/skills_panel.tscn")
const ABILITIES_PANEL_SCENE := preload("res://scenes/ui/abilities_panel.tscn")

func _ready() -> void:
	_setup_ui_panels()
	_show_character_creation()

func _setup_ui_panels() -> void:
	# Create UI layer if it doesn't exist
	if not ui_layer:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UILayer"
		ui_layer.layer = 10
		add_child(ui_layer)

	# Instantiate inventory panel (hidden by default)
	inventory_panel = INVENTORY_PANEL_SCENE.instantiate()
	inventory_panel.closed.connect(_on_inventory_closed)
	ui_layer.add_child(inventory_panel)

	# Instantiate skills panel (hidden by default)
	skills_panel = SKILLS_PANEL_SCENE.instantiate()
	skills_panel.closed.connect(_on_skills_closed)
	ui_layer.add_child(skills_panel)

	# Instantiate abilities panel (hidden by default)
	abilities_panel = ABILITIES_PANEL_SCENE.instantiate()
	abilities_panel.closed.connect(_on_abilities_closed)
	ui_layer.add_child(abilities_panel)

func _show_character_creation() -> void:
	current_state = GameState.CHARACTER_CREATION

	character_creation = CHARACTER_CREATION_SCENE.instantiate()
	character_creation.creation_complete.connect(_on_character_created)
	character_creation.creation_cancelled.connect(_on_creation_cancelled)
	ui_layer.add_child(character_creation)

	# Hide HUD during creation
	hud.visible = false

func _on_character_created(character_data: Dictionary) -> void:
	# Remove character creation screen
	if character_creation:
		character_creation.queue_free()
		character_creation = null

	# Start the game with created character
	_start_new_game(character_data)

func _on_creation_cancelled() -> void:
	# For now, just restart character creation
	# In full game, could return to main menu
	pass

func _start_new_game(character_data: Dictionary = {}) -> void:
	current_state = GameState.PLAYING
	GameManager.start_new_game()

	# Generate first level
	_generate_level(1)

	# Spawn player with character data
	_spawn_player(character_data)

	# Set up systems
	turn_system.set_level(current_level)
	turn_system.set_player(player)
	floater_manager.set_container(current_level.get_node("Effects"))

	# Initial FOV update
	current_level.update_fov(player.grid_position, 10)
	current_level.update_entity_visibility()

	# Show HUD
	hud.visible = true
	hud.update_player_stats(player)

	# Welcome message
	var name_str: String = character_data.get("name", "Necromancer")
	GameManager.log_message("Welcome, %s. You descend into Dol Guldur..." % name_str, Color.CYAN)
	GameManager.log_message("Move: WASD/HJKL  Inventory: I  Skills: @  Pickup: G", Color.GRAY)

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

func _spawn_player(character_data: Dictionary = {}) -> void:
	player = PLAYER_SCENE.instantiate()

	# Apply character creation data
	if not character_data.is_empty():
		player.entity_name = character_data.get("name", "Necromancer")
		player.race_name = character_data.get("race", "Man")
		player.house_name = character_data.get("house", "")

		# Apply base stat allocation
		var base_stats: Dictionary = character_data.get("base_stats", {})
		player.strength += base_stats.get("str", 0)
		player.dexterity += base_stats.get("dex", 0)
		player.constitution += base_stats.get("con", 0)
		player.grace += base_stats.get("gra", 0)

	# Find starting position (stairs up or random floor)
	var start_pos := current_level.find_stairs_up()
	if start_pos == Vector2i(-1, -1):
		start_pos = current_level.find_random_floor()

	player.grid_position = start_pos
	current_level.add_entity(player)

	# Store reference
	GameManager.player = player

func _process(_delta: float) -> void:
	if current_state != GameState.PLAYING:
		return

	# Update HUD every frame
	if player and player.is_alive:
		hud.update_player_stats(player)

	# Check for level transitions
	_check_stairs()

	# Handle zoom
	if Input.is_action_just_pressed("zoom_in"):
		GameManager.cycle_zoom()
		_update_camera_zoom()
	elif Input.is_action_just_pressed("zoom_out"):
		GameManager.cycle_zoom_reverse()
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

	# Award descent XP
	var descent_xp: int = GameManager.current_depth * 50
	player.gain_experience(descent_xp, "descent")

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
	current_level.update_entity_visibility()

	GameManager.log_message("You descend deeper into the darkness... (Depth %d)" % GameManager.current_depth, Color.CYAN)

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
	current_level.update_entity_visibility()

	GameManager.log_message("You climb back up... (Depth %d)" % GameManager.current_depth, Color.CYAN)

func _update_camera_zoom() -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	if camera:
		camera.zoom = Vector2.ONE * GameManager.get_current_zoom()

func _unhandled_input(event: InputEvent) -> void:
	if current_state != GameState.PLAYING:
		return

	# Don't process game input if UI is open
	if _is_ui_open():
		return

	# Inventory toggle
	if event.is_action_pressed("inventory"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()

	# Skills toggle
	if event.is_action_pressed("skills"):
		_toggle_skills()
		get_viewport().set_input_as_handled()

	# Abilities toggle (A key)
	if event.is_action_pressed("abilities"):
		_toggle_abilities()
		get_viewport().set_input_as_handled()

	# Pause/menu
	if event.is_action_pressed("ui_cancel"):
		# Pause menu (to be implemented)
		pass

# ============================================================================
# UI PANEL MANAGEMENT
# ============================================================================

func _is_ui_open() -> bool:
	return (inventory_panel and inventory_panel.visible) or \
		   (skills_panel and skills_panel.visible) or \
		   (abilities_panel and abilities_panel.visible)

func _toggle_inventory() -> void:
	if inventory_panel.visible:
		inventory_panel.close()
	else:
		# Close other panels first
		if skills_panel and skills_panel.visible:
			skills_panel.close()
		if abilities_panel and abilities_panel.visible:
			abilities_panel.close()
		inventory_panel.open(player)
		GameManager.is_player_turn = false  # Pause game while in menu

func _toggle_skills() -> void:
	if skills_panel.visible:
		skills_panel.close()
	else:
		# Close other panels first
		if inventory_panel and inventory_panel.visible:
			inventory_panel.close()
		if abilities_panel and abilities_panel.visible:
			abilities_panel.close()
		skills_panel.open(player)
		GameManager.is_player_turn = false  # Pause game while in menu

func _toggle_abilities() -> void:
	if abilities_panel.visible:
		abilities_panel.close()
	else:
		# Close other panels first
		if inventory_panel and inventory_panel.visible:
			inventory_panel.close()
		if skills_panel and skills_panel.visible:
			skills_panel.close()
		abilities_panel.open(player)
		GameManager.is_player_turn = false  # Pause game while in menu

func _on_inventory_closed() -> void:
	GameManager.is_player_turn = true
	hud.update_player_stats(player)

func _on_skills_closed() -> void:
	GameManager.is_player_turn = true
	hud.update_player_stats(player)

func _on_abilities_closed() -> void:
	GameManager.is_player_turn = true
	hud.update_player_stats(player)
