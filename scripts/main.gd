extends Node2D
## Main game scene - coordinates level generation, player spawning, UI, and turn flow.

enum GameState { CHARACTER_CREATION, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.CHARACTER_CREATION

@onready var level_container: Node2D = $LevelContainer
@onready var hud: CanvasLayer = $HUD  # HUD class - using CanvasLayer to avoid load order issues
@onready var turn_system: TurnSystem = $TurnSystem
@onready var floater_manager: Node = $FloaterManager
@onready var ui_layer: CanvasLayer = $UILayer

# UI Panels (instantiated dynamically)
# Note: Using Control type to avoid load-order issues with class_name registration
var character_creation: Control = null
var inventory_panel: Control = null
var tome_panel: Control = null
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

# Voice ability menu
var voice_menu: PopupMenu = null
var _voice_menu_abilities: Array[Dictionary] = []  # Cached list from ability_system
var _pending_voice_ability_id: int = -1  # Ability waiting for target selection

# Resting state (Z / Shift+Z)
var _resting: bool = false
var _rest_turns_taken: int = 0
var _rest_max_turns: int = 0  # 0 = rest until full, >0 = rest N turns
var _rest_hp_before: int = 0  # Track HP for damage interrupt

# Auto-explore state (flag-based loop)
var _auto_exploring: bool = false

# Systems (Phase 8C) - using Node/RefCounted to avoid load order issues
var auto_explore: RefCounted = null  # AutoExplore
var monster_memory: RefCounted = null
var ability_system: AbilitySystem = null

const LEVEL_SCENE := preload("res://scenes/levels/level.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")
const CHARACTER_CREATION_SCENE := preload("res://scenes/ui/character_creation.tscn")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const TOME_PANEL_SCENE := preload("res://scenes/ui/tome_panel.tscn")
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

	# Instantiate Tome panel (replaces skills + abilities panels)
	tome_panel = TOME_PANEL_SCENE.instantiate()
	tome_panel.closed.connect(_on_tome_closed)
	ui_layer.add_child(tome_panel)

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
	ability_system = AbilitySystem.new()
	add_child(ability_system)

	# Create quest system using preloaded script
	quest_system = QuestSystemScript.new()
	add_child(quest_system)

	# Transition overlay (full screen black, initially transparent)
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.anchors_preset = Control.PRESET_FULL_RECT
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(transition_overlay)

	# Voice ability quick-select menu (V key)
	voice_menu = PopupMenu.new()
	voice_menu.name = "VoiceMenu"
	voice_menu.id_pressed.connect(_on_voice_menu_selected)
	ui_layer.add_child(voice_menu)

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
	ability_system.set_player(player)
	floater_manager.set_container(current_level.get_node("Effects"))
	floater_manager.connect_ability_system(ability_system)

	# Initial FOV update: geometry → lighting → entity visibility → tilemap
	var fov_radius: int = current_level.get_fov_radius()
	var light_radius: int = player.get_light_radius()
	current_level.update_fov(player.grid_position, fov_radius)
	current_level.apply_lighting(player.grid_position, light_radius)
	current_level.update_entity_visibility()
	current_level.apply_fov_to_tilemap()

	# Show HUD and wire minimap
	hud.visible = true
	hud.set_level(current_level)
	hud.set_player(player)
	hud.update_player_stats(player)
	hud.refresh_minimap()

	# Wayfarer's Instinct: reveal traps/doors/stairs near player on floor entry
	if player and player.trait_effect_id == "wayfarers_instinct":
		current_level.reveal_for_wayfarer(player.grid_position, 3, 8)

	# Welcome message
	var name_str: String = character_data.get("name", "Necromancer")
	GameManager.log_message("Welcome, %s. You descend into Dol Guldur..." % name_str, ThemeColors.MSG_INFO)
	GameManager.log_message("Move: WASD/HJKL  Inventory: I  Tome: T  Pickup: G", ThemeColors.MSG_SYSTEM)

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
		player.trait_name = character_data.get("trait", "")
		player.gender = character_data.get("gender", "male")
		player.age = character_data.get("age", 0)
		player.history = character_data.get("history", "")
		player._apply_trait()

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

	# Grant starting equipment from race data
	_grant_starting_equipment(player)

	# Store reference
	GameManager.player = player

	# Set player on quest system
	if quest_system:
		quest_system.set_player(player)

# ============================================================================
# STARTING EQUIPMENT
# ============================================================================

func _grant_starting_equipment(p: Player) -> void:
	## Grant starting items based on race data E: lines (tval:sval:min:max).
	var race_data: DataManager.RaceData = DataManager.get_race(p.race_name)
	if not race_data:
		return

	for entry in race_data.starting_equipment:
		var tval: int = entry["tval"]
		var sval: int = entry["sval"]
		var min_qty: int = entry["min_qty"]
		var max_qty: int = entry["max_qty"]
		var qty: int = randi_range(min_qty, max_qty)

		var item_data: DataManager.ItemData = DataManager.get_item_by_tval_sval(tval, sval)
		if not item_data:
			push_warning("Starting equipment not found: tval=%d sval=%d" % [tval, sval])
			continue

		for i in range(qty):
			var item_copy: DataManager.ItemData = _duplicate_item_data(item_data)
			item_copy.identified = true  # Starting equipment is always identified

			# Set fuel for light sources
			if tval == 39 and item_copy.fuel < 0:
				item_copy.fuel = 5000  # Standard torch fuel

			# Try auto-equipping to an appropriate slot
			var equipped: bool = false

			# Melee/ranged weapons -> weapon slot
			if tval in [18, 21, 22, 23] and p.equipment["weapon"] == null:
				p.equipment["weapon"] = item_copy
				equipped = true
			# Light sources -> light slot
			elif tval == 39 and p.equipment["light"] == null:
				p.equipment["light"] = item_copy
				equipped = true
			# Ammo -> quiver slot
			elif tval == 16 and p.equipment["quiver"] == null:
				p.equipment["quiver"] = item_copy
				equipped = true

			# If not equipped, add to inventory
			if not equipped:
				p.inventory.append(item_copy)

func _duplicate_item_data(source: DataManager.ItemData) -> DataManager.ItemData:
	## Create a deep copy of an ItemData for inventory use.
	var copy := DataManager.ItemData.new()
	copy.index = source.index
	copy.name = source.name
	copy.display_char = source.display_char
	copy.color = source.color
	copy.tval = source.tval
	copy.sval = source.sval
	copy.pval = source.pval
	copy.depth = source.depth
	copy.rarity = source.rarity
	copy.weight = source.weight
	copy.cost = source.cost
	copy.allocation = source.allocation
	copy.attack_bonus = source.attack_bonus
	copy.damage_dice = source.damage_dice
	copy.evasion_bonus = source.evasion_bonus
	copy.protection_dice = source.protection_dice
	copy.flags = source.flags.duplicate()
	copy.description = source.description
	copy.identified = source.identified
	copy.fuel = source.fuel
	return copy

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

	# Process resting / auto-exploring when it's the player's turn
	if player and player.is_alive and turn_system.current_state == TurnSystem.TurnState.PLAYER_INPUT:
		if _resting:
			_process_rest_step()
		elif _auto_exploring:
			_process_auto_explore_step()

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
	hud.set_level(current_level)

	# Update FOV: geometry → lighting → entity visibility → tilemap
	var fov_radius: int = current_level.get_fov_radius()
	var light_radius: int = player.get_light_radius()
	current_level.update_fov(player.grid_position, fov_radius)
	current_level.apply_lighting(player.grid_position, light_radius)
	current_level.update_entity_visibility()
	current_level.apply_fov_to_tilemap()

	GameManager.log_message("You descend deeper into the darkness... (Depth %d)" % GameManager.current_depth, ThemeColors.MSG_INFO)

	# Wayfarer's Instinct: reveal traps/doors/stairs near player on floor entry
	if player and player.trait_effect_id == "wayfarers_instinct":
		current_level.reveal_for_wayfarer(player.grid_position, 3, 8)

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
	hud.set_level(current_level)

	# Update FOV: geometry → lighting → entity visibility → tilemap
	var fov_radius: int = current_level.get_fov_radius()
	var light_radius: int = player.get_light_radius()
	current_level.update_fov(player.grid_position, fov_radius)
	current_level.apply_lighting(player.grid_position, light_radius)
	current_level.update_entity_visibility()
	current_level.apply_fov_to_tilemap()

	GameManager.log_message("You climb back up... (Depth %d)" % GameManager.current_depth, ThemeColors.MSG_INFO)

	# Wayfarer's Instinct: reveal traps/doors/stairs near player on floor entry
	if player and player.trait_effect_id == "wayfarers_instinct":
		current_level.reveal_for_wayfarer(player.grid_position, 3, 8)

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

	# Horn directional prompt intercept (must come before UI/movement checks)
	if ConsumableSystem.has_pending_horn():
		if event is InputEventKey and event.pressed and not event.echo:
			var horn_dir: Vector2i = DirectionPrompt.get_direction_from_event(event)
			if horn_dir != Vector2i.ZERO:
				if ConsumableSystem.complete_horn_use(horn_dir):
					player.consume_energy()
					turn_system._after_player_action()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_ESCAPE:
				ConsumableSystem.cancel_horn_use()
				get_viewport().set_input_as_handled()
				return
		return  # Block all other input while awaiting direction

	# Don't process game input if UI is open
	if _is_ui_open():
		return

	# Interrupt resting or auto-exploring on any key press
	if (_resting or _auto_exploring) and event is InputEventKey and event.pressed and not event.echo:
		if _resting:
			_stop_rest("Interrupted")
		if _auto_exploring:
			_stop_auto_explore_flag("Interrupted")
		get_viewport().set_input_as_handled()
		return

	# Inventory toggle
	if event.is_action_pressed("inventory"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()

	# Skills toggle (@ key → opens Tome)
	if event.is_action_pressed("skills"):
		_toggle_tome()
		get_viewport().set_input_as_handled()

	# Abilities toggle (A key → opens Tome)
	if event.is_action_pressed("abilities"):
		_toggle_tome()
		get_viewport().set_input_as_handled()

	# Tome toggle (T key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T and not event.shift_pressed and not event.echo:
		_toggle_tome()
		get_viewport().set_input_as_handled()

	# Look mode toggle (X key)
	if event.is_action_pressed("look"):
		_toggle_look()
		get_viewport().set_input_as_handled()

	# Auto-explore (O key)
	if event.is_action_pressed("auto_explore"):
		_start_auto_explore()
		get_viewport().set_input_as_handled()

	# Rest (Z key) - rest until full
	if event.is_action_pressed("rest"):
		_start_rest(0)
		get_viewport().set_input_as_handled()

	# Rest N turns (Shift+Z) - rest for 20 turns
	if event.is_action_pressed("rest_n"):
		_start_rest(20)
		get_viewport().set_input_as_handled()

	# F key: Fire (archery) if bow equipped, else forge if on forge tile
	if event.is_action_pressed("forge"):
		if player and player.can_fire_ranged():
			_open_targeting()
		else:
			_try_use_forge()
		get_viewport().set_input_as_handled()

	# Stealth toggle (; key) - direct keycode check, bypasses action system for macOS compatibility
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SEMICOLON or event.unicode == 59:
			if player and GameManager.is_player_turn:
				player.toggle_stealth_mode()
				player._skip_input_this_frame = true
			get_viewport().set_input_as_handled()
			return

	# Voice ability menu (V key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_V and not event.shift_pressed and not event.echo:
		_open_voice_menu()
		get_viewport().set_input_as_handled()
		return

	# Minimap toggle (M key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_M and not event.shift_pressed:
		hud.toggle_minimap()
		get_viewport().set_input_as_handled()

	# Bottom bar expand/collapse (Tab key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		hud.toggle_bottom_bar()
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
		   (tome_panel and tome_panel.visible) or \
		   (look_panel and look_panel.visible) or \
		   (dialogue_panel and dialogue_panel.visible) or \
		   (smithing_panel and smithing_panel.visible) or \
		   (bestiary_panel and bestiary_panel.visible) or \
		   (settings_panel and settings_panel.visible) or \
		   (voice_menu and voice_menu.visible)

func _toggle_inventory() -> void:
	if inventory_panel.visible:
		inventory_panel.close()
	else:
		# Close other panels first
		if tome_panel and tome_panel.visible:
			tome_panel.close()
		inventory_panel.open(player)
		GameManager.is_player_turn = false  # Pause game while in menu

func _toggle_tome() -> void:
	if tome_panel.visible:
		tome_panel.close()
	else:
		# Close other panels first
		if inventory_panel and inventory_panel.visible:
			inventory_panel.close()
		tome_panel.open(player)
		GameManager.is_player_turn = false

func _on_inventory_closed() -> void:
	GameManager.is_player_turn = true
	hud.update_player_stats(player)

func _on_tome_closed() -> void:
	GameManager.is_player_turn = true
	hud.update_player_stats(player)

func _toggle_look() -> void:
	if look_panel.visible:
		look_panel.close()
	else:
		# Close other panels first
		if inventory_panel and inventory_panel.visible:
			inventory_panel.close()
		if tome_panel and tome_panel.visible:
			tome_panel.close()
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
		GameManager.log_message("You need a ranged weapon and ammo to fire.", ThemeColors.MSG_SYSTEM)
		return
	# Close other panels
	if look_panel and look_panel.visible:
		look_panel.close()
	target_panel.open(player, current_level)
	GameManager.is_player_turn = false

func _on_target_selected(target_pos: Vector2i) -> void:
	GameManager.is_player_turn = true
	if not player or not player.is_alive:
		_pending_voice_ability_id = -1
		return

	# Voice ability targeting
	if _pending_voice_ability_id >= 0:
		var ability_id: int = _pending_voice_ability_id
		_pending_voice_ability_id = -1
		var target_entity: Entity = current_level.get_entity_at(target_pos)
		if target_entity and is_instance_valid(target_entity) and target_entity is Monster and target_entity.is_alive:
			if ability_system:
				ability_system.activate_ability(ability_id, target_entity)
				player.consume_energy()
		else:
			GameManager.log_message("No valid target there.", ThemeColors.MSG_SYSTEM)
		return

	# Archery targeting
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
	_pending_voice_ability_id = -1
	GameManager.is_player_turn = true

# ============================================================================
# VOICE ABILITY MENU (V key)
# ============================================================================

func _open_voice_menu() -> void:
	if not player or not player.is_alive or not GameManager.is_player_turn:
		return

	if not ability_system:
		GameManager.log_message("No lore abilities available.", ThemeColors.MSG_SYSTEM)
		return

	_voice_menu_abilities = ability_system.get_learned_active_abilities()
	if _voice_menu_abilities.is_empty():
		GameManager.log_message("You have no active voice abilities.", ThemeColors.MSG_SYSTEM)
		return

	# Build popup menu
	voice_menu.clear()
	for i in range(_voice_menu_abilities.size()):
		var ab: Dictionary = _voice_menu_abilities[i]
		var label: String = ab.name
		if ab.cost > 0:
			label += " (%d voice)" % ab.cost
		if not ab.can_use:
			label += " [%s]" % ab.reason
		voice_menu.add_item(label, i)
		voice_menu.set_item_disabled(i, not ab.can_use)

	# Show centered on screen
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	voice_menu.popup_centered()
	GameManager.is_player_turn = false

func _on_voice_menu_selected(index: int) -> void:
	GameManager.is_player_turn = true
	if index < 0 or index >= _voice_menu_abilities.size():
		return

	var ab: Dictionary = _voice_menu_abilities[index]
	if not ab.can_use:
		return

	if ab.needs_target:
		# Open targeting mode for this ability
		_pending_voice_ability_id = ab.id
		GameManager.log_message("Select a target for %s..." % ab.name, ThemeColors.MSG_INFO)
		target_panel.open(player, current_level)
		GameManager.is_player_turn = false
	else:
		# Activate immediately (no target needed)
		if ability_system:
			var success: bool = ability_system.activate_ability(ab.id)
			if success:
				player.consume_energy()

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
		if tome_panel and tome_panel.visible:
			tome_panel.close()
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
	if tome_panel and tome_panel.visible:
		tome_panel.close()
	if look_panel and look_panel.visible:
		look_panel.close()

	smithing_panel.open(player, current_level)
	GameManager.is_player_turn = false

func _on_smithing_closed() -> void:
	GameManager.is_player_turn = true
	hud.update_player_stats(player)

# ============================================================================
# RESTING (Z / Shift+Z)
# ============================================================================

func _start_rest(max_turns: int) -> void:
	if not player or not player.is_alive:
		return

	# Don't rest if a monster is visible
	if _has_visible_monster():
		GameManager.log_message("You cannot rest with enemies in sight!", ThemeColors.MSG_WARNING)
		return

	# Check if already at full HP and voice
	if max_turns == 0 and player.current_health >= player.max_health and player.voice_charges >= player.max_voice:
		GameManager.log_message("You are already at full health and voice.", ThemeColors.MSG_SYSTEM)
		return

	_resting = true
	_rest_turns_taken = 0
	_rest_max_turns = max_turns
	_rest_hp_before = player.current_health
	GameManager.log_message("Resting... (press any key to stop)", ThemeColors.MSG_SYSTEM)

func _process_rest_step() -> void:
	if not _resting or not player or not player.is_alive:
		_stop_rest("Invalid state")
		return

	# Check interrupt conditions BEFORE taking a turn
	# 1. Monster visible
	if _has_visible_monster():
		_stop_rest("Monster spotted!")
		return

	# 2. Took damage since last check
	if player.current_health < _rest_hp_before:
		_stop_rest("Took damage!")
		return

	# 3. Reached max turns (if set)
	if _rest_max_turns > 0 and _rest_turns_taken >= _rest_max_turns:
		_stop_rest("Rested for %d turns" % _rest_turns_taken)
		return

	# 4. Fully rested (if resting until full)
	if _rest_max_turns == 0 and player.current_health >= player.max_health and player.voice_charges >= player.max_voice:
		_stop_rest("Fully rested (%d turns)" % _rest_turns_taken)
		return

	# Take a rest turn (equivalent to waiting)
	_rest_turns_taken += 1

	# Slow HP regen during rest: +1 HP every 10 rest turns
	if _rest_turns_taken % 10 == 0 and player.current_health < player.max_health:
		player.current_health = mini(player.current_health + 1, player.max_health)

	# Simulate player consuming energy and processing the game tick
	player.consume_energy()
	turn_system._after_player_action()

	# Update HP tracker for damage detection
	_rest_hp_before = player.current_health

	# Show progress every 10 turns
	if _rest_turns_taken % 10 == 0:
		GameManager.log_message("Resting... (turn %d)" % _rest_turns_taken, ThemeColors.MSG_SYSTEM)

func _stop_rest(reason: String) -> void:
	if not _resting:
		return
	_resting = false
	if _rest_turns_taken > 0:
		GameManager.log_message("Rest ended: %s" % reason, ThemeColors.MSG_SYSTEM)
	else:
		GameManager.log_message(reason, ThemeColors.MSG_WARNING)

func _has_visible_monster() -> bool:
	if not current_level:
		return false
	for entity in current_level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			if current_level.is_tile_visible(entity.grid_position):
				return true
	return false

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
		_auto_exploring = true

func _process_auto_explore_step() -> void:
	if not _auto_exploring or not auto_explore or not auto_explore.is_exploring:
		_stop_auto_explore_flag("Invalid state")
		return

	if not player or not player.is_alive:
		_stop_auto_explore_flag("Player died")
		return

	# Get next step (handles stop conditions internally)
	var next_pos: Vector2i = auto_explore.get_next_step()
	if next_pos == Vector2i(-1, -1):
		# auto_explore already called stop_explore with the reason
		_auto_exploring = false
		return

	# Calculate direction
	var direction: Vector2i = next_pos - player.grid_position

	# Move the player
	if player.try_move(direction):
		player.consume_energy()
		auto_explore.confirm_step_taken()

		# Record monster observations
		_observe_visible_monsters()

		# Process the full game tick via the turn system
		turn_system._after_player_action()

		# Check if auto_explore stopped itself during the tick
		if not auto_explore.is_exploring:
			_auto_exploring = false
	else:
		# Move failed (blocked), try to find a new path
		auto_explore.path.clear()
		if not auto_explore._find_new_path():
			_stop_auto_explore_flag("Path blocked")

func _stop_auto_explore_flag(reason: String) -> void:
	if not _auto_exploring:
		return
	_auto_exploring = false
	if auto_explore and auto_explore.is_exploring:
		auto_explore.stop_explore(reason)

# ============================================================================
# MONSTER MEMORY (Phase 8C)
# ============================================================================

func _observe_visible_monsters() -> void:
	if not monster_memory or not current_level:
		return

	# Deep Memory: grant bonus observations on first sighting
	var has_deep_memory: bool = player != null and player.has_ability(Constants.Skill.S_LOR, Constants.LoreAbility.LOR_DEEP_MEMORY)
	var player_lore: int = player.get_skill("lore") if player != null else 0

	# Whisper of the Valar: check if player has active whisper reveals
	var has_whisper: bool = player != null and "_whisper_turns" in player and player._whisper_turns > 0
	var whisper_revealed: Array = player._whisper_revealed if has_whisper and "_whisper_revealed" in player else []

	# Record observations for all visible monsters and update health bars
	for entity in current_level.entities:
		if not is_instance_valid(entity):
			continue
		if entity is Monster and entity.is_alive:
			var is_visible: bool = current_level.is_tile_visible(entity.grid_position)

			# Whisper of the Valar: treat whisper-revealed monsters as visible
			if not is_visible and has_whisper:
				if entity.get_instance_id() in whisper_revealed:
					is_visible = true
					# Make entity sprite visible so player can see it
					entity.visible = true

			if is_visible:
				# Deep Memory: on first sighting, grant Lore/3 bonus observations
				if has_deep_memory and entity.monster_data and "index" in entity.monster_data:
					var monster_id: int = entity.monster_data.index
					if monster_memory.get_observation_count(monster_id) == 0:
						var bonus: int = maxi(1, player_lore / 3)
						for i in range(bonus):
							monster_memory.record_observation(entity)
				monster_memory.record_observation(entity)
				# Update health bar based on knowledge tier (use effective tier with lore bonus)
				if entity.monster_data and "index" in entity.monster_data:
					var tier: int = monster_memory.get_effective_tier(entity.monster_data.index, player_lore)
					entity.update_health_bar(tier)

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
		if tome_panel and tome_panel.visible:
			tome_panel.close()
		if look_panel and look_panel.visible:
			look_panel.close()
		if bestiary_panel and monster_memory:
			bestiary_panel.open(monster_memory)
			GameManager.is_player_turn = false

func _on_bestiary_closed() -> void:
	GameManager.is_player_turn = true
