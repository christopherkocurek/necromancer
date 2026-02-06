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
var death_screen: Control = null
var look_panel: Control = null
var dialogue_panel: Control = null  # DialoguePanel - using Control to avoid load order issues
var smithing_panel: Control = null
var target_panel: Control = null    # TargetPanel for archery/wand targeting
var bestiary_panel: Control = null   # BestiaryPanel for monster lore
var settings_panel: Control = null   # SettingsPanel for accessibility/display/controls

var current_level: Level = null
var player: Player = null
var transition_overlay: ColorRect = null

# Quest system (using Node type to avoid load order issues)
var quest_system: Node = null

# Systems (Phase 8C) - using Node/RefCounted to avoid load order issues
var auto_explore: RefCounted = null  # AutoExplore
var monster_memory: RefCounted = null

const LEVEL_SCENE := preload("res://scenes/levels/level.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")
const CHARACTER_CREATION_SCENE := preload("res://scenes/ui/character_creation.tscn")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const SKILLS_PANEL_SCENE := preload("res://scenes/ui/skills_panel.tscn")
const ABILITIES_PANEL_SCENE := preload("res://scenes/ui/abilities_panel.tscn")
const DEATH_SCREEN_SCENE := preload("res://scenes/ui/death_screen.tscn")
const LOOK_PANEL_SCENE := preload("res://scenes/ui/look_panel.tscn")
const DIALOGUE_PANEL_SCENE := preload("res://scenes/ui/dialogue_panel.tscn")
const SMITHING_PANEL_SCENE := preload("res://scenes/ui/smithing_panel.tscn")
const TARGET_PANEL_SCENE := preload("res://scenes/ui/target_panel.tscn")
const QuestSystemScript := preload("res://scripts/systems/quest_system.gd")
const AutoExploreScript := preload("res://scripts/systems/auto_explore.gd")
const MonsterMemoryScript := preload("res://scripts/systems/monster_memory.gd")
const BestiaryPanelScript := preload("res://scripts/ui/bestiary_panel.gd")
const SETTINGS_PANEL_SCENE := preload("res://scenes/ui/settings_panel.tscn")

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

	# Instantiate death screen (hidden by default)
	death_screen = DEATH_SCREEN_SCENE.instantiate()
	death_screen.new_game_requested.connect(_on_new_game_requested)
	death_screen.quit_requested.connect(_on_quit_requested)
	ui_layer.add_child(death_screen)

	# Instantiate look panel (hidden by default)
	look_panel = LOOK_PANEL_SCENE.instantiate()
	look_panel.closed.connect(_on_look_closed)
	ui_layer.add_child(look_panel)

	# Instantiate target panel (hidden by default)
	target_panel = TARGET_PANEL_SCENE.instantiate()
	target_panel.target_selected.connect(_on_target_selected)
	target_panel.cancelled.connect(_on_target_cancelled)
	ui_layer.add_child(target_panel)

	# Instantiate dialogue panel (hidden by default)
	dialogue_panel = DIALOGUE_PANEL_SCENE.instantiate()
	dialogue_panel.dialogue_closed.connect(_on_dialogue_closed)
	ui_layer.add_child(dialogue_panel)

	# Instantiate smithing panel (hidden by default)
	smithing_panel = SMITHING_PANEL_SCENE.instantiate()
	smithing_panel.closed.connect(_on_smithing_closed)
	ui_layer.add_child(smithing_panel)

	# Instantiate bestiary panel (hidden by default, script-only - no scene needed)
	bestiary_panel = BestiaryPanelScript.new()
	bestiary_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bestiary_panel.closed.connect(_on_bestiary_closed)
	ui_layer.add_child(bestiary_panel)

	# Instantiate settings panel (hidden by default)
	settings_panel = SETTINGS_PANEL_SCENE.instantiate()
	settings_panel.closed.connect(_on_settings_closed)
	ui_layer.add_child(settings_panel)

	# Initialize Phase 8C systems (using preloaded scripts)
	auto_explore = AutoExploreScript.new()
	monster_memory = MonsterMemoryScript.new()

	# Create quest system using preloaded script
	quest_system = QuestSystemScript.new()
	add_child(quest_system)

	# Transition overlay (full screen black, initially transparent)
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.anchors_preset = Control.PRESET_FULL_RECT
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(transition_overlay)

	# Connect NPC interaction event
	EventBus.npc_interacted.connect(_on_npc_interacted)

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

	# Initial FOV update: geometry → lighting → entity visibility → tilemap
	var fov_radius: int = current_level.get_fov_radius()
	var light_radius: int = player.get_light_radius()
	current_level.update_fov(player.grid_position, fov_radius)
	current_level.apply_lighting(player.grid_position, light_radius)
	current_level.update_entity_visibility()
	current_level.apply_fov_to_tilemap()

	# Show HUD
	hud.visible = true
	hud.update_player_stats(player)

	# Welcome message
	var name_str: String = character_data.get("name", "Necromancer")
	GameManager.log_message("Welcome, %s. You descend into Dol Guldur..." % name_str, ThemeColors.MSG_INFO)
	GameManager.log_message("Move: WASD/HJKL  Inventory: I  Skills: @  Pickup: G", ThemeColors.MSG_SYSTEM)

	# Show layer entry message
	var entry_msg := LayerConfig.get_entry_message(1, 0)
	if not entry_msg.is_empty():
		GameManager.log_message(entry_msg, ThemeColors.MSG_WARNING)

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

	# Try to spawn Thrain on appropriate depths
	if quest_system:
		generator.spawn_thrain_if_appropriate(depth, quest_system)

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

	# Connect player death signal
	player.player_died.connect(_on_player_died)

	# Find starting position (stairs up or random floor)
	var start_pos := current_level.find_stairs_up()
	if start_pos == Vector2i(-1, -1):
		start_pos = current_level.find_random_floor()

	player.grid_position = start_pos
	current_level.add_entity(player)

	# Store reference
	GameManager.player = player

	# Set player on quest system
	if quest_system:
		quest_system.set_player(player)

func _process(_delta: float) -> void:
	if current_state != GameState.PLAYING:
		return

	# Update HUD every frame
	if player and player.is_alive:
		hud.update_player_stats(player)

	# Check for level transitions
	_check_stairs()

	# Tutorial hints (self-throttles via _is_showing check)
	if player and player.is_alive:
		TutorialManager.check_hints(player)
		if current_level:
			var hint_tile: int = current_level.get_tile(player.grid_position)
			TutorialManager.check_tile_hints(player, hint_tile)

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

func _fade_to_black(duration: float = 0.15) -> void:
	if not transition_overlay:
		return
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, duration)
	await tween.finished

func _fade_from_black(duration: float = 0.3) -> void:
	if not transition_overlay:
		return
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 0.0, duration)
	await tween.finished

func _descend() -> void:
	await _fade_to_black(0.15)

	var previous_depth := GameManager.current_depth
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

	# Update FOV: geometry → lighting → entity visibility → tilemap
	var fov_radius: int = current_level.get_fov_radius()
	var light_radius: int = player.get_light_radius()
	current_level.update_fov(player.grid_position, fov_radius)
	current_level.apply_lighting(player.grid_position, light_radius)
	current_level.update_entity_visibility()
	current_level.apply_fov_to_tilemap()

	GameManager.log_message("You descend deeper into the darkness... (Depth %d)" % GameManager.current_depth, ThemeColors.MSG_INFO)

	# Show layer entry message if entering a new layer
	var entry_msg := LayerConfig.get_entry_message(GameManager.current_depth, previous_depth)
	if not entry_msg.is_empty():
		GameManager.log_message(entry_msg, ThemeColors.MSG_WARNING)

	await _fade_from_black(0.3)

func _ascend() -> void:
	await _fade_to_black(0.15)

	var previous_depth := GameManager.current_depth
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

	# Update FOV: geometry → lighting → entity visibility → tilemap
	var fov_radius: int = current_level.get_fov_radius()
	var light_radius: int = player.get_light_radius()
	current_level.update_fov(player.grid_position, fov_radius)
	current_level.apply_lighting(player.grid_position, light_radius)
	current_level.update_entity_visibility()
	current_level.apply_fov_to_tilemap()

	GameManager.log_message("You climb back up... (Depth %d)" % GameManager.current_depth, ThemeColors.MSG_INFO)

	# Show layer entry message if entering a new layer (when ascending)
	var entry_msg := LayerConfig.get_entry_message(GameManager.current_depth, previous_depth)
	if not entry_msg.is_empty():
		GameManager.log_message(entry_msg, ThemeColors.MSG_WARNING)

	await _fade_from_black(0.3)

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

	# Look mode toggle (X key)
	if event.is_action_pressed("look"):
		_toggle_look()
		get_viewport().set_input_as_handled()

	# Auto-explore (O key)
	if event.is_action_pressed("auto_explore"):
		_start_auto_explore()
		get_viewport().set_input_as_handled()

	# F key: Fire (archery) if bow equipped, else forge if on forge tile
	if event.is_action_pressed("forge"):
		if player and player.can_fire_ranged():
			_open_targeting()
		else:
			_try_use_forge()
		get_viewport().set_input_as_handled()

	# Help overlay (? key = Shift+/)
	if event.is_action_pressed("help_overlay"):
		HelpOverlay.toggle()
		get_viewport().set_input_as_handled()

	# Escape: open settings panel when no other panel is open
	if event.is_action_pressed("ui_cancel"):
		_toggle_settings()
		get_viewport().set_input_as_handled()

# ============================================================================
# UI PANEL MANAGEMENT
# ============================================================================

func _is_ui_open() -> bool:
	return (inventory_panel and inventory_panel.visible) or \
		   (skills_panel and skills_panel.visible) or \
		   (abilities_panel and abilities_panel.visible) or \
		   (look_panel and look_panel.visible) or \
		   (dialogue_panel and dialogue_panel.visible) or \
		   (smithing_panel and smithing_panel.visible) or \
		   (bestiary_panel and bestiary_panel.visible) or \
		   (settings_panel and settings_panel.visible)

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

func _toggle_look() -> void:
	if look_panel.visible:
		look_panel.close()
	else:
		# Close other panels first
		if inventory_panel and inventory_panel.visible:
			inventory_panel.close()
		if skills_panel and skills_panel.visible:
			skills_panel.close()
		if abilities_panel and abilities_panel.visible:
			abilities_panel.close()
		look_panel.open(player, current_level)
		GameManager.is_player_turn = false  # Pause game while in look mode

func _on_look_closed() -> void:
	GameManager.is_player_turn = true

func _on_npc_interacted(_player_node: Node, npc: Node) -> void:
	"""Handle NPC interaction - open dialogue panel."""
	if dialogue_panel and npc:
		dialogue_panel.open_dialogue(npc)

func _on_dialogue_closed() -> void:
	"""Handle dialogue panel closing."""
	GameManager.is_player_turn = true

## Open targeting mode for archery
func _open_targeting() -> void:
	if not player or not player.is_alive:
		return
	if not player.can_fire_ranged():
		GameManager.log_message("You need a bow and arrows to fire.", ThemeColors.MSG_SYSTEM)
		return
	# Close other panels
	if look_panel and look_panel.visible:
		look_panel.close()
	target_panel.open(player, current_level)
	GameManager.is_player_turn = false

func _on_target_selected(target_pos: Vector2i) -> void:
	GameManager.is_player_turn = true
	if not player or not player.is_alive:
		return
	# Fire arrow at target
	var target_entity: Entity = current_level.get_entity_at(target_pos)
	if target_entity and is_instance_valid(target_entity) and target_entity.is_alive:
		var dist: int = max(abs(target_pos.x - player.grid_position.x),
						   abs(target_pos.y - player.grid_position.y))
		if player.consume_arrow():
			player.attacked_this_turn = true
			player.ranged_attack(target_entity, dist)
			player.consume_energy()
	else:
		GameManager.log_message("Nothing to hit there.", ThemeColors.MSG_SYSTEM)

func _on_target_cancelled() -> void:
	GameManager.is_player_turn = true

# ============================================================================
# SETTINGS PANEL
# ============================================================================

func _toggle_settings() -> void:
	if settings_panel and settings_panel.visible:
		settings_panel.close()
	else:
		# Close other panels first
		if inventory_panel and inventory_panel.visible:
			inventory_panel.close()
		if skills_panel and skills_panel.visible:
			skills_panel.close()
		if abilities_panel and abilities_panel.visible:
			abilities_panel.close()
		if look_panel and look_panel.visible:
			look_panel.close()
		if bestiary_panel and bestiary_panel.visible:
			bestiary_panel.close()
		if settings_panel:
			settings_panel.open()
			GameManager.is_player_turn = false

func _on_settings_closed() -> void:
	GameManager.is_player_turn = true

# ============================================================================
# DEATH HANDLING
# ============================================================================

func _on_player_died(cause: String, killer_name: String) -> void:
	current_state = GameState.GAME_OVER

	# Record death for god mode scaling
	AccessibilityManager.record_death()

	# Update run stats with final info
	player.run_stats.died_from = cause
	player.run_stats.killer_name = killer_name
	player.run_stats.max_depth_reached = maxi(player.run_stats.max_depth_reached, GameManager.current_depth)
	player.run_stats.total_turns = GameManager.turn_count

	# Show death screen
	death_screen.show_death(player, player.run_stats)

	# Log the death
	if killer_name.is_empty():
		GameManager.log_message("You have died. %s" % cause, ThemeColors.MSG_ERROR)
	else:
		GameManager.log_message("You have been slain by %s." % killer_name, ThemeColors.MSG_ERROR)

func _on_new_game_requested() -> void:
	# Clean up current game
	if current_level:
		current_level.queue_free()
		current_level = null
	if player:
		player.queue_free()
		player = null

	# Reset game manager
	GameManager.reset_game()

	# Show character creation for new game
	_show_character_creation()

func _on_quit_requested() -> void:
	get_tree().quit()


# ============================================================================
# SMITHING SYSTEM (Phase 8C)
# ============================================================================

func _try_use_forge() -> void:
	if not player or not current_level:
		return

	var tile: int = current_level.get_tile(player.grid_position)
	if tile != Level.Tile.FORGE:
		GameManager.log_message("You need to be standing on a forge to use it.", ThemeColors.MSG_WARNING)
		return

	_open_smithing_panel()

func _open_smithing_panel() -> void:
	if not smithing_panel:
		return

	# Close other panels first
	if inventory_panel and inventory_panel.visible:
		inventory_panel.close()
	if skills_panel and skills_panel.visible:
		skills_panel.close()
	if abilities_panel and abilities_panel.visible:
		abilities_panel.close()
	if look_panel and look_panel.visible:
		look_panel.close()

	smithing_panel.open(player, current_level)
	GameManager.is_player_turn = false

func _on_smithing_closed() -> void:
	GameManager.is_player_turn = true
	hud.update_player_stats(player)

# ============================================================================
# AUTO-EXPLORE (Phase 8C)
# ============================================================================

func _start_auto_explore() -> void:
	if not auto_explore or not player or not current_level:
		return

	# Set up auto-explore
	auto_explore.set_level(current_level)
	auto_explore.set_player(player)

	if auto_explore.start_explore():
		# Process auto-explore turns
		_process_auto_explore()

func _process_auto_explore() -> void:
	if not auto_explore or not auto_explore.is_exploring:
		return

	# Check for manual input to stop
	if auto_explore.should_stop_on_input():
		return

	# Get next step
	var next_pos: Vector2i = auto_explore.get_next_step()
	if next_pos == Vector2i(-1, -1):
		return

	# Calculate direction
	var direction: Vector2i = next_pos - player.grid_position

	# Move the player
	if player.try_move(direction):
		player.consume_energy()
		auto_explore.confirm_step_taken()

		# Update FOV: geometry → lighting → entity visibility → tilemap
		var fov_radius: int = current_level.get_fov_radius()
		var light_radius: int = player.get_light_radius()
		current_level.update_fov(player.grid_position, fov_radius)
		current_level.apply_lighting(player.grid_position, light_radius)
		current_level.update_entity_visibility()
		current_level.apply_fov_to_tilemap()

		# Record monster observations
		_observe_visible_monsters()

		# Process game tick
		turn_system._process_game_tick()

		# Continue auto-explore on next frame if still exploring
		if auto_explore.is_exploring:
			await get_tree().create_timer(0.05).timeout
			_process_auto_explore()

# ============================================================================
# MONSTER MEMORY (Phase 8C)
# ============================================================================

func _observe_visible_monsters() -> void:
	if not monster_memory or not current_level:
		return

	# Record observations for all visible monsters
	for entity in current_level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			if current_level.is_tile_visible(entity.grid_position):
				monster_memory.record_observation(entity)

func get_monster_memory() -> RefCounted:
	return monster_memory

# ============================================================================
# BESTIARY (Phase 9)
# ============================================================================

func _toggle_bestiary() -> void:
	if bestiary_panel and bestiary_panel.visible:
		bestiary_panel.close()
	else:
		# Close other panels first
		if inventory_panel and inventory_panel.visible:
			inventory_panel.close()
		if skills_panel and skills_panel.visible:
			skills_panel.close()
		if abilities_panel and abilities_panel.visible:
			abilities_panel.close()
		if look_panel and look_panel.visible:
			look_panel.close()
		if bestiary_panel and monster_memory:
			bestiary_panel.open(monster_memory)
			GameManager.is_player_turn = false

func _on_bestiary_closed() -> void:
	GameManager.is_player_turn = true
