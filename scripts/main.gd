extends Node2D
## Main game scene - coordinates level generation, player spawning, UI, and turn flow.

enum GameState { TITLE, CHARACTER_CREATION, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.TITLE

@onready var level_container: Node2D = $LevelContainer
@onready var hud: CanvasLayer = $HUD  # HUD class - using CanvasLayer to avoid load order issues
@onready var turn_system: TurnSystem = $TurnSystem
@onready var floater_manager: Node = $FloaterManager
@onready var ui_layer: CanvasLayer = $UILayer

# UI Panels (instantiated dynamically)
# Note: Using Control type to avoid load-order issues with class_name registration
var character_creation: Control = null
var title_screen: Control = null
var inventory_panel: Control = null
var tome_panel: Control = null
var death_screen: Control = null
var look_panel: Control = null
var dialogue_panel: Control = null  # DialoguePanel - using Control to avoid load order issues
var smithing_panel: Control = null
var target_panel: Control = null    # TargetPanel for archery/wand targeting
var bestiary_panel: Control = null   # BestiaryPanel for monster lore
var settings_panel: Control = null   # SettingsPanel for accessibility/display/controls
var character_panel: Control = null  # CharacterPanel for player stats (C key)

var current_level: Level = null
var player: Player = null
var transition_overlay: ColorRect = null
var _cleanup_done: bool = false
var _starting_new_game: bool = false

# Quest system (using Node type to avoid load order issues)
var quest_system: Node = null

# Voice ability menu
var voice_menu: PopupMenu = null
var _voice_menu_abilities: Array[Dictionary] = []  # Cached list from ability_system
var _pending_voice_ability_id: int = -1  # Ability waiting for target selection
var _pending_mark_quarry: bool = false
var _pending_ability_bind_slot: int = -1
var _voice_menu_targeting_requested: bool = false
var _pending_utility_bind_slot: int = -1
const TVAL_CHEST: int = 7

# Item selection menu (for consumable quick-use: comma/Q/R keys)
var item_menu: PopupMenu = null
var _item_menu_items: Array = []  # Cached list of matching inventory items
var _item_menu_tval: int = -1  # Which tval category the menu is showing

# Resting state (Z / Shift+Z)
var _resting: bool = false
var _rest_turns_taken: int = 0
var _rest_max_turns: int = 0  # 0 = rest until full, >0 = rest N turns
var _rest_hp_before: int = 0  # Track HP for damage interrupt

# Mining state (T key → tunnel rubble)
var _mining: bool = false
var _mining_turns_taken: int = 0
var _mining_turns_required: int = 4
var _mining_target: Vector2i = Vector2i(-1, -1)
var _mining_hp_before: int = 0
var _pending_tunnel: bool = false
var _pending_stairs_confirm: bool = false
var _pending_stairs_turn: int = -1
var _pending_stairs_dir: int = 0  # -1 up, +1 down

# Auto-explore state (flag-based loop)
var _auto_exploring: bool = false

# Wizard mode (Ctrl+W to toggle, then Ctrl+D/H/K/R/J/T for debug commands)
var wizard_mode: bool = false

# Free-camera pan mode (Shift+V to toggle)
var _pan_mode: bool = false
var _pan_offset: Vector2 = Vector2.ZERO
const PAN_STEP: float = 64.0 * 3  # 3 tiles per key press

# Systems (Phase 8C) - using Node/RefCounted to avoid load order issues
var auto_explore: RefCounted = null  # AutoExplore
var monster_memory: RefCounted = null
var ability_system: AbilitySystem = null

const LEVEL_SCENE := preload("res://scenes/levels/level.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")
const TITLE_SCREEN_SCENE := preload("res://scenes/ui/title_screen.tscn")
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
const CharacterPanelScript := preload("res://scripts/ui/character_panel.gd")
const SETTINGS_PANEL_SCENE := preload("res://scenes/ui/settings_panel.tscn")
const ITEM_SCENE := preload("res://scenes/entities/item.tscn")
const BASE_CONTENT_SIZE: Vector2i = Vector2i(1440, 810)
const HOTBAR_CAST_KEY_COUNT: int = 8

func _ready() -> void:
	# Scale all content uniformly when the game window is resized.
	get_window().set_flag(Window.FLAG_RESIZE_DISABLED, false)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_tree().root.content_scale_size = BASE_CONTENT_SIZE
	_setup_ui_panels()
	_show_title_screen()

func _show_title_screen() -> void:
	current_state = GameState.TITLE
	_starting_new_game = false

	if character_creation:
		character_creation.queue_free()
		character_creation = null
	if title_screen:
		title_screen.queue_free()
		title_screen = null

	title_screen = TITLE_SCREEN_SCENE.instantiate()
	title_screen.enter_dungeon_pressed.connect(_on_enter_dungeon_pressed)
	ui_layer.add_child(title_screen)

	# Hide HUD outside active gameplay.
	hud.visible = false

func _on_enter_dungeon_pressed() -> void:
	if title_screen:
		title_screen.queue_free()
		title_screen = null
	_show_character_creation()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cleanup_before_exit()
		get_tree().quit()

func _exit_tree() -> void:
	_cleanup_before_exit()

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
	inventory_panel.utility_bind_requested.connect(_on_utility_bind_requested)
	inventory_panel.item_selected.connect(_on_inventory_item_selected)
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

	# Instantiate character panel (hidden by default, script-only - no scene needed)
	character_panel = CharacterPanelScript.new()
	character_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	character_panel.closed.connect(_on_character_panel_closed)
	ui_layer.add_child(character_panel)

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
	voice_menu.popup_hide.connect(_on_voice_menu_closed)
	ui_layer.add_child(voice_menu)

	# Item selection menu (comma/Q/R quick-use)
	item_menu = PopupMenu.new()
	item_menu.name = "ItemMenu"
	item_menu.id_pressed.connect(_on_item_menu_selected)
	item_menu.popup_hide.connect(_on_item_menu_closed)
	ui_layer.add_child(item_menu)

	# Connect NPC interaction event
	EventBus.npc_interacted.connect(_on_npc_interacted)

	# Connect item drop event to spawn ground items
	EventBus.item_dropped.connect(_on_item_dropped_to_ground)

	# HUD utility belt interactions
	if hud:
		if hud.has_signal("utility_slot_activated"):
			hud.utility_slot_activated.connect(_on_hud_utility_slot_activated)
		if hud.has_signal("utility_slot_cleared"):
			hud.utility_slot_cleared.connect(_on_hud_utility_slot_cleared)
		if hud.has_signal("utility_equip_drop_requested"):
			hud.utility_equip_drop_requested.connect(_on_hud_utility_equip_drop_requested)
		if hud.has_signal("utility_slot_bind_requested"):
			hud.utility_slot_bind_requested.connect(_on_hud_utility_slot_bind_requested)
		if hud.has_signal("ability_slot_cast_requested"):
			hud.ability_slot_cast_requested.connect(_on_hud_ability_slot_cast_requested)
		if hud.has_signal("ability_slot_cleared"):
			hud.ability_slot_cleared.connect(_on_hud_ability_slot_cleared)
		if hud.has_signal("ability_slot_bind_requested"):
			hud.ability_slot_bind_requested.connect(_on_hud_ability_slot_bind_requested)

func _show_character_creation() -> void:
	current_state = GameState.CHARACTER_CREATION
	_starting_new_game = false

	character_creation = CHARACTER_CREATION_SCENE.instantiate()
	character_creation.creation_complete.connect(_on_character_created)
	character_creation.creation_cancelled.connect(_on_creation_cancelled)
	ui_layer.add_child(character_creation)

	# Hide HUD during creation
	hud.visible = false

func _on_character_created(character_data: Dictionary) -> void:
	if _starting_new_game or current_state == GameState.PLAYING:
		return
	_starting_new_game = true

	# Remove character creation screen
	if character_creation:
		character_creation.queue_free()
		character_creation = null

	# Start the game with created character
	call_deferred("_start_new_game", character_data)

func _on_creation_cancelled() -> void:
	# For now, just restart character creation
	# In full game, could return to main menu
	pass

func _start_new_game(character_data: Dictionary = {}) -> void:
	if current_state == GameState.PLAYING and player and is_instance_valid(player):
		_starting_new_game = false
		return

	current_state = GameState.PLAYING
	GameManager.start_new_game()
	DataManager.reset_spawned_uniques()

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
	hud._ability_system_ref = ability_system
	hud.update_player_stats(player)
	hud.refresh_minimap()

	# Wayfarer's Instinct: reveal traps/doors/stairs near player on floor entry
	if player and player.trait_effect_id == "wayfarers_instinct":
		current_level.reveal_for_wayfarer(player.grid_position, 3, 8)

	# Welcome message
	var name_str: String = character_data.get("name", "Necromancer")
	GameManager.log_message("Welcome, %s. You descend into Dol Guldur..." % name_str, ThemeColors.MSG_INFO)
	GameManager.log_message("Move: WASD/HJKL  Inventory: I  Tome: T/@/A  Tunnel: Shift+T  Pickup: G", ThemeColors.MSG_SYSTEM)

	# Show layer entry message
	var entry_msg := LayerConfig.get_entry_message(1, 0)
	if not entry_msg.is_empty():
		GameManager.log_message(entry_msg, ThemeColors.MSG_WARNING)

	_starting_new_game = false

func _generate_level(depth: int) -> void:
	# Clean up old level
	if current_level:
		current_level.queue_free()

	# Create new level
	current_level = LEVEL_SCENE.instantiate()
	current_level.depth = depth
	current_level.layer_name = LayerConfig.get_layer_name(depth)
	level_container.add_child(current_level)

	# Generate dungeon
	var generator := DungeonGenerator.new()
	generator.generate(current_level, depth)

	# Try to spawn Thrain on appropriate depths
	if quest_system:
		generator.spawn_thrain_if_appropriate(depth, quest_system)

	# Final safety: clear any entities that ended up near stairs_up (including Thrain escorts)
	var stairs_up: Vector2i = current_level.find_stairs_up()
	if stairs_up != Vector2i(-1, -1):
		var to_remove: Array = []
		for entity in current_level.entities:
			if not is_instance_valid(entity) or not entity is Monster:
				continue
			var dist: int = maxi(absi(entity.grid_position.x - stairs_up.x), absi(entity.grid_position.y - stairs_up.y))
			if dist < 7:
				to_remove.append(entity)
		for monster in to_remove:
			current_level.remove_entity(monster)
			monster.queue_free()

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

	# Apply pre-creation skill investments
	if character_data.has("skill_investments"):
		for skill_name in character_data.skill_investments:
			var invest: int = character_data.skill_investments[skill_name]
			if invest > 0:
				player.skills[skill_name] = player.skills.get(skill_name, 0) + invest

	# Deduct pre-creation XP
	if character_data.has("xp_spent_precreation"):
		player.xp_available -= character_data.xp_spent_precreation

	player._recalculate_stats()

	# Connect player death signal
	player.player_died.connect(_on_player_died)

	# Find starting position (stairs up, or first room center on floor 1)
	var start_pos := current_level.find_stairs_up()
	if start_pos == Vector2i(-1, -1):
		# Floor 1: spawn in first room center (matches monster exclusion zone)
		if not current_level.rooms.is_empty():
			var first_room: Rect2i = current_level.rooms[0]
			start_pos = Vector2i(
				first_room.position.x + first_room.size.x / 2,
				first_room.position.y + first_room.size.y / 2
			)
		else:
			start_pos = current_level.find_random_floor()

	player.grid_position = start_pos
	current_level.add_entity(player)

	# Apply entity name and ability purchases AFTER add_entity because
	# player._ready() calls _init_ability_arrays() which wipes abilities,
	# and unconditionally sets entity_name = "Necromancer"
	if not character_data.is_empty():
		player.entity_name = character_data.get("name", "Necromancer")
	if character_data.has("ability_purchases"):
		if not player.has_meta("learned_abilities"):
			player.set_meta("learned_abilities", [])
		var learned_meta: Array = player.get_meta("learned_abilities")
		for purchase in character_data.ability_purchases:
			player.learn_ability(purchase.skill_type, purchase.ability_num)
			var purchased_name: String = str(purchase.get("name", ""))
			if not purchased_name.is_empty() and not learned_meta.has(purchased_name):
				learned_meta.append(purchased_name)
			player.set_meta("learned_abilities", learned_meta)
			player._recalculate_stats()

	# Optional debug/playtest sprite override (e.g. Sauron tile for max test hero).
	if character_data.has("force_sprite_monster_id"):
		var override_monster_id: int = int(character_data.get("force_sprite_monster_id", -1))
		if override_monster_id > 0:
			player.set_sprite_from_monster_id(override_monster_id)

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
	## GDD baseline starter kit:
	## - 1 race/house-appropriate basic weapon
	## - 3-5 food
	## - 3 torches
	var race_data: DataManager.RaceData = DataManager.get_race(p.race_name)
	if not race_data:
		return

	var weapon_data: DataManager.ItemData = null
	var food_data: DataManager.ItemData = null
	for entry in race_data.starting_equipment:
		var tval: int = int(entry["tval"])
		var sval: int = int(entry["sval"])
		if weapon_data == null and tval in [20, 21, 22, 23]:
			weapon_data = DataManager.get_item_by_tval_sval(tval, sval)
		if food_data == null and tval == 80:
			food_data = DataManager.get_item_by_tval_sval(tval, sval)

	# Weapon: 1 copy, equipped if possible.
	if weapon_data:
		var weapon_copy: DataManager.ItemData = _duplicate_item_data(weapon_data)
		weapon_copy.identified = true
		weapon_copy.stack_count = 1
		if p.equipment["weapon"] == null:
			p.equipment["weapon"] = weapon_copy
		else:
			p.pick_up_item(weapon_copy)
	else:
		push_warning("No basic melee weapon found for race '%s' starter kit." % p.race_name)

	# Food: race-flavored food when available, otherwise dark bread fallback.
	if food_data == null:
		food_data = DataManager.get_item_by_tval_sval(80, 35)
	if food_data:
		var food_qty: int = randi_range(3, 5)
		for _i in range(food_qty):
			var food_copy: DataManager.ItemData = _duplicate_item_data(food_data)
			food_copy.identified = true
			food_copy.stack_count = 1
			p.pick_up_item(food_copy)

	# Torches: always 3 in inventory.
	var torch_data: DataManager.ItemData = DataManager.get_item_by_tval_sval(39, 0)
	if torch_data:
		for _j in range(3):
			var torch_copy: DataManager.ItemData = _duplicate_item_data(torch_data)
			torch_copy.identified = true
			torch_copy.stack_count = 1
			if torch_copy.fuel < 0:
				torch_copy.fuel = 5000
			if _j == 0 and p.equipment["light"] == null:
				p.equipment["light"] = torch_copy
			else:
				p.pick_up_item(torch_copy)

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
	copy.granted_abilities = source.granted_abilities.duplicate(true)
	copy.description = source.description
	copy.identified = source.identified
	copy.fuel = source.fuel
	copy.stack_count = source.stack_count if "stack_count" in source else 1
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
		if AccessibilityManager.is_assist_enabled():
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

	# Process resting / mining / auto-exploring when it's the player's turn
	if player and player.is_alive and turn_system.current_state == TurnSystem.TurnState.PLAYER_INPUT:
		# Failsafe: recover from stale UI turn-lock after popups/voice interactions.
		if not _is_ui_open() and not GameManager.is_player_turn and _pending_voice_ability_id < 0 and not _pending_mark_quarry:
			GameManager.is_player_turn = true
		if _resting:
			_process_rest_step()
		elif _mining:
			_process_mining_step()
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
				if _needs_stairs_confirmation(1):
					return
				_descend()
			Level.Tile.STAIRS_UP:
				if GameManager.current_depth > 1:
					if _needs_stairs_confirmation(-1):
						return
					_ascend()

func _needs_stairs_confirmation(direction: int) -> bool:
	# Safety confirm for high-risk transition at low HP.
	var hp_pct: float = float(player.current_health) / float(maxi(1, player.max_health))
	var risky: bool = hp_pct <= 0.25
	if not risky:
		_pending_stairs_confirm = false
		_pending_stairs_turn = -1
		_pending_stairs_dir = 0
		return false
	if _pending_stairs_confirm and _pending_stairs_turn == GameManager.turn_count and _pending_stairs_dir == direction:
		_pending_stairs_confirm = false
		_pending_stairs_turn = -1
		_pending_stairs_dir = 0
		return false
	_pending_stairs_confirm = true
	_pending_stairs_turn = GameManager.turn_count
	_pending_stairs_dir = direction
	var dir_text: String = "descend" if direction > 0 else "ascend"
	GameManager.log_message("You are badly wounded. Press Enter again to %s." % dir_text, ThemeColors.MSG_WARNING)
	return true

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
	if _pan_mode:
		_exit_pan_mode()
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
	var start_pos := current_level.find_random_stairs_up()
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
	if _pan_mode:
		_exit_pan_mode()
	await _fade_to_black(0.15)

	var previous_depth := GameManager.current_depth
	GameManager.ascend_level()

	# For now, just regenerate (in full game, would cache levels)
	current_level.remove_entity(player)

	_generate_level(GameManager.current_depth)

	# Ascent escalation: set flag when player has quest items and is going up
	if quest_system and quest_system.has_quest_items():
		current_level.is_ascent = true

	var start_pos := current_level.find_random_stairs_down()
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

func _update_camera_pan() -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	if camera:
		camera.offset = _pan_offset

func _exit_pan_mode() -> void:
	_pan_mode = false
	_pan_offset = Vector2.ZERO
	_update_camera_pan()
	GameManager.log_message("Free camera off.", ThemeColors.MSG_SYSTEM)

func _unhandled_input(event: InputEvent) -> void:
	# Wizard mode toggle (Ctrl+W) — works in any game state
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.keycode == KEY_W:
		wizard_mode = not wizard_mode
		var state_str: String = "ENABLED" if wizard_mode else "DISABLED"
		GameManager.log_message("[WIZARD MODE %s]" % state_str, Color.YELLOW)
		get_viewport().set_input_as_handled()
		return

	# Wizard mode commands (Ctrl+D/H/K/R/J/T) — works in any game state
	if wizard_mode and event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed:
		# macOS Ctrl+H sends backspace — check both keycode and physical_keycode
		var key: Key = event.keycode
		if key == KEY_BACKSPACE and event.physical_keycode == KEY_H:
			key = KEY_H
		match key:
			KEY_D:  # Descend
				_wizard_descend()
				get_viewport().set_input_as_handled()
				return
			KEY_H:  # Full heal / resurrect
				_wizard_heal()
				get_viewport().set_input_as_handled()
				return
			KEY_K:  # Kill all monsters
				_wizard_kill_all()
				get_viewport().set_input_as_handled()
				return
			KEY_R:  # Reveal map + all monsters
				_wizard_reveal()
				get_viewport().set_input_as_handled()
				return
			KEY_J:  # Give 100k XP
				_wizard_xp()
				get_viewport().set_input_as_handled()
				return
			KEY_T:  # Teleport to Thrain / endgame floor
				_wizard_teleport_to_thrain()
				get_viewport().set_input_as_handled()
				return

	# Keyboard zoom (+/- keys) — works in any game state
	if event is InputEventKey and event.pressed and not event.echo and not event.ctrl_pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:  # + / =
			GameManager.cycle_zoom()
			_update_camera_zoom()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:  # -
			GameManager.cycle_zoom_reverse()
			_update_camera_zoom()
			get_viewport().set_input_as_handled()
			return

	# Free-camera pan mode (Shift+V to toggle, movement keys to pan, Escape to exit)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V and not event.ctrl_pressed and event.shift_pressed:
			if _pan_mode:
				_exit_pan_mode()
			else:
				_pan_mode = true
				GameManager.log_message("Free camera on. WASD/HJKL to pan, Shift+V or Escape to exit.", ThemeColors.MSG_SYSTEM)
			get_viewport().set_input_as_handled()
			return

	if _pan_mode and event is InputEventKey and event.pressed:
		var pan_dir := Vector2.ZERO
		match event.keycode:
			KEY_W, KEY_K, KEY_UP, KEY_KP_8: pan_dir = Vector2(0, -1)
			KEY_S, KEY_J, KEY_DOWN, KEY_KP_2: pan_dir = Vector2(0, 1)
			KEY_A, KEY_H, KEY_LEFT, KEY_KP_4: pan_dir = Vector2(-1, 0)
			KEY_D, KEY_L, KEY_RIGHT, KEY_KP_6: pan_dir = Vector2(1, 0)
			KEY_ESCAPE, KEY_ENTER:
				_exit_pan_mode()
				get_viewport().set_input_as_handled()
				return
		if pan_dir != Vector2.ZERO:
			_pan_offset += pan_dir * PAN_STEP
			_update_camera_pan()
			get_viewport().set_input_as_handled()
			return

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

	# Tunnel directional prompt intercept (must come before UI/movement checks)
	if _pending_tunnel:
		if event is InputEventKey and event.pressed and not event.echo:
			var tunnel_dir: Vector2i = DirectionPrompt.get_direction_from_event(event)
			if tunnel_dir != Vector2i.ZERO:
				_try_mine_direction(tunnel_dir)
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_ESCAPE:
				_pending_tunnel = false
				GameManager.log_message("Tunnelling cancelled.", ThemeColors.MSG_SYSTEM)
				get_viewport().set_input_as_handled()
				return
		return  # Block all other input while awaiting direction

	# Don't process game input if UI is open
	if _is_ui_open():
		return

	# Interrupt resting, mining, or auto-exploring on any key press
	if (_resting or _auto_exploring or _mining) and event is InputEventKey and event.pressed and not event.echo:
		if _resting:
			_stop_rest("Interrupted")
		if _mining:
			_stop_mining("Interrupted")
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

	# Tome toggle (t key, lowercase only)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T and not event.shift_pressed and not event.echo:
		_toggle_tome()
		get_viewport().set_input_as_handled()

	# Tunnel / dig rubble (Shift+T key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T and event.shift_pressed and not event.echo:
		if player and player.is_alive and GameManager.is_player_turn:
			_try_start_tunnel()
		get_viewport().set_input_as_handled()

	# Character profile (Shift+C)
	if event is InputEventKey and event.pressed and event.keycode == KEY_C and event.shift_pressed and not event.echo:
		_toggle_character_panel()
		get_viewport().set_input_as_handled()

	# Look mode toggle (X key)
	if event.is_action_pressed("look"):
		_toggle_look()
		get_viewport().set_input_as_handled()

	# Auto-explore (O key)
	if event.is_action_pressed("auto_explore"):
		if not _try_open_chest():
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

	# F key: Forge if on forge tile, else fire (archery) if bow equipped
	if event.is_action_pressed("forge"):
		if player and current_level and current_level.is_forge_tile(player.grid_position):
			_try_use_forge()
		elif player and player.can_fire_ranged():
			_open_targeting()
		get_viewport().set_input_as_handled()

	# Equip from floor (E key when no panel is open)
	if event.is_action_pressed("equip"):
		if player and current_level and GameManager.is_player_turn:
			var floor_items: Array[Item] = current_level.get_items_at(player.grid_position)
			if not floor_items.is_empty():
				var item_node: Item = player.try_equip_from_floor(floor_items)
				if item_node != null:
					var item_data = item_node.get_data()
					var tval: int = item_data.tval
					var slot_id: int = Constants.TVAL_TO_SLOT[tval]
					var slot_key: String = player._equip_slot_id_to_key(slot_id)
					current_level.remove_item(item_node)
					item_node.queue_free()
					player.pick_up_item(item_data)
					player.equip_item(item_data, slot_key)
					var item_name: String = GameManager.get_item_display_name(item_data)
					GameManager.log_message("You pick up and equip the %s." % item_name, ThemeColors.MSG_LOOT)
					player.consume_energy()
					turn_system._after_player_action()
					hud.update_player_stats(player)
				else:
					GameManager.log_message("Nothing equippable here.", ThemeColors.MSG_SYSTEM)
		get_viewport().set_input_as_handled()

	# Stealth toggle (; key) - direct keycode check, bypasses action system for macOS compatibility
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SEMICOLON or event.unicode == 59:
			if player and GameManager.is_player_turn:
				player.toggle_stealth_mode()
				player._skip_input_this_frame = true
			get_viewport().set_input_as_handled()
			return

	# Diagonal movement fallbacks (YUBN) - direct keycode check for macOS compatibility
	# physical_keycode is unreliable for these keys on macOS, so we handle them directly
	if event is InputEventKey and event.pressed and not event.echo and not event.shift_pressed:
		if player and player.is_alive and turn_system.current_state == TurnSystem.TurnState.PLAYER_INPUT:
			var diag_dir: Vector2i = Vector2i.ZERO
			match event.keycode:
				KEY_Y: diag_dir = Vector2i(-1, -1)  # up-left
				KEY_U: diag_dir = Vector2i(1, -1)   # up-right
				KEY_B: diag_dir = Vector2i(-1, 1)   # down-left
				KEY_N: diag_dir = Vector2i(1, 1)    # down-right
			if diag_dir != Vector2i.ZERO:
				player.moved_this_turn = true
				player.record_action(player.direction_to_action(diag_dir))
				if player.try_move(diag_dir):
					var move_cost: int = current_level.get_movement_cost(player.grid_position) if current_level else Constants.ACTION_COST
					if player.stealth_mode:
						move_cost *= Constants.STEALTH_MODE_SPEED_MULTIPLIER
					player.consume_energy(move_cost)
					turn_system._after_player_action()
				get_viewport().set_input_as_handled()
				return

	# Ability hotkey quick-cast (1-8 number keys, no shift)
	if event is InputEventKey and event.pressed and not event.shift_pressed and not event.echo:
		var hotkey_slot: int = -1
		match event.keycode:
			KEY_1: hotkey_slot = 0
			KEY_2: hotkey_slot = 1
			KEY_3: hotkey_slot = 2
			KEY_4: hotkey_slot = 3
			KEY_5: hotkey_slot = 4
			KEY_6: hotkey_slot = 5
			KEY_7: hotkey_slot = 6
			KEY_8: hotkey_slot = 7
		if hotkey_slot >= 0 and hotkey_slot < HOTBAR_CAST_KEY_COUNT:
			_cast_hotbar_slot(hotkey_slot)
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

	# Eat food/herb (comma key) - macOS-safe dual check
	if event is InputEventKey and event.pressed and not event.echo and not event.shift_pressed:
		if event.keycode == KEY_COMMA or event.unicode == 44:
			if player and player.is_alive and GameManager.is_player_turn:
				_open_item_selection(80, "eat", "You have nothing to eat.")
			get_viewport().set_input_as_handled()
			return

	# Quaff potion (Q key)
	if event is InputEventKey and event.pressed and not event.echo and not event.shift_pressed:
		if event.keycode == KEY_Q:
			if player and player.is_alive and GameManager.is_player_turn:
				_open_item_selection(75, "quaff", "You have no potions.")
			get_viewport().set_input_as_handled()
			return

	# Read scroll (R key) - only when no UI panel is open (R is unequip in inventory)
	if event is InputEventKey and event.pressed and not event.echo and not event.shift_pressed:
		if event.keycode == KEY_R:
			if player and player.is_alive and GameManager.is_player_turn:
				_open_item_selection(55, "read", "You have no scrolls to read.")
			get_viewport().set_input_as_handled()
			return

	# Disarm trap (D key, no shift — Shift+D is drop)
	if event is InputEventKey and event.pressed and not event.echo and not event.shift_pressed:
		if event.keycode == KEY_D:
			if player and player.is_alive and GameManager.is_player_turn and current_level:
				var hunting_skill: int = player.get_effective_perception()
				var result: Dictionary = current_level.disarm_trap(player.grid_position, hunting_skill)
				if result.success:
					player.gain_experience(5, "disarm")
					GameManager.log_message(result.message, ThemeColors.MSG_INFO)
					player.consume_energy()
					turn_system._after_player_action()
				else:
					var tile: int = current_level.get_tile(player.grid_position)
					if tile == Level.Tile.TRAP or tile == Level.Tile.TRAP_TRIGGERED:
						# Failed disarm on a real trap — trigger it
						GameManager.log_message(result.message, ThemeColors.MSG_WARNING)
						current_level.on_entity_step(player, player.grid_position)
						player.consume_energy()
						turn_system._after_player_action()
					else:
						GameManager.log_message(result.message, ThemeColors.MSG_SYSTEM)
				hud.update_player_stats(player)
			get_viewport().set_input_as_handled()
			return

	# Blow horn/flute (P key)
	if event is InputEventKey and event.pressed and not event.echo and not event.shift_pressed:
		if event.keycode == KEY_P:
			if player and player.is_alive and GameManager.is_player_turn:
				_open_item_selection(Constants.TVAL_HORN, "blow", "You have no horns or flutes.")
			get_viewport().set_input_as_handled()
			return

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
		   (character_panel and character_panel.visible) or \
		   (settings_panel and settings_panel.visible) or \
		   (voice_menu and voice_menu.visible) or \
		   (item_menu and item_menu.visible) or \
		   (target_panel and target_panel.visible)

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
	_pending_utility_bind_slot = -1
	GameManager.is_player_turn = true
	hud.update_player_stats(player)

func _on_inventory_item_selected(item_data: Variant) -> void:
	if _pending_utility_bind_slot < 0 or item_data == null or not player:
		return
	var bind_slot: int = _pending_utility_bind_slot
	_pending_utility_bind_slot = -1
	if not player.bind_utility_item(bind_slot, item_data):
		GameManager.log_message("Failed to load utility slot %d." % (bind_slot + 1), ThemeColors.MSG_ERROR)
		return
	var item_name: String = GameManager.get_item_display_name(item_data)
	GameManager.log_message("Loaded %s into utility slot %d." % [item_name, bind_slot + 1], ThemeColors.MSG_INFO)
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

func _start_mark_quarry_targeting() -> void:
	if not player:
		return
	if not player.has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_FOCUSED_ATTACK):
		GameManager.log_message("You haven't learned Mark Quarry.", ThemeColors.MSG_ERROR)
		return
	if player.get_mark_quarry_cooldown_turns() > 0:
		GameManager.log_message("Mark Quarry is on cooldown (%d turns)." % player.get_mark_quarry_cooldown_turns(), ThemeColors.MSG_SYSTEM)
		return
	if look_panel and look_panel.visible:
		look_panel.close()
	_pending_mark_quarry = true
	GameManager.log_message("Select a quarry to mark...", ThemeColors.MSG_INFO)
	target_panel.open(player, current_level)
	GameManager.is_player_turn = false

func _on_target_selected(target_pos: Vector2i) -> void:
	GameManager.is_player_turn = true
	_voice_menu_targeting_requested = false
	if not player or not player.is_alive:
		_pending_voice_ability_id = -1
		_pending_mark_quarry = false
		return

	# Mark Quarry targeting
	if _pending_mark_quarry:
		_pending_mark_quarry = false
		var quarry: Entity = current_level.get_entity_at(target_pos)
		if quarry and is_instance_valid(quarry) and quarry is Monster and quarry.is_alive:
			if player.activate_mark_quarry_on_target(quarry):
				_consume_turn_for_ability()
		else:
			GameManager.log_message("No valid quarry there.", ThemeColors.MSG_SYSTEM)
		return

	# Voice ability targeting
	if _pending_voice_ability_id >= 0:
		var ability_id: int = _pending_voice_ability_id
		_pending_voice_ability_id = -1
		# Word of Warding targets empty floor tiles, not monsters.
		if ability_id == 154:
			if ability_system and ability_system.activate_ability(ability_id, target_pos):
				_consume_turn_for_ability()
			return
		var target_entity: Entity = current_level.get_entity_at(target_pos)
		if target_entity and is_instance_valid(target_entity) and target_entity is Monster and target_entity.is_alive:
			if ability_system:
				if ability_system.activate_ability(ability_id, target_entity):
					_consume_turn_for_ability()
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
			turn_system._after_player_action()
	else:
		GameManager.log_message("Nothing to hit there.", ThemeColors.MSG_SYSTEM)

func _on_target_cancelled() -> void:
	_pending_voice_ability_id = -1
	_pending_mark_quarry = false
	_voice_menu_targeting_requested = false
	GameManager.is_player_turn = true

# ============================================================================
# ABILITY MENU (V key)
# ============================================================================

func _open_voice_menu(bind_slot: int = -1) -> void:
	if not player or not player.is_alive or not GameManager.is_player_turn:
		return

	_voice_menu_targeting_requested = false
	_pending_ability_bind_slot = bind_slot
	voice_menu.set_meta("bind_slot", bind_slot)
	_voice_menu_abilities = _get_all_hotbar_bindable_abilities()
	if _voice_menu_abilities.is_empty():
		if bind_slot >= 0:
			GameManager.log_message("No learned abilities available to bind.", ThemeColors.MSG_SYSTEM)
		else:
			GameManager.log_message("You have no active abilities to use.", ThemeColors.MSG_SYSTEM)
		_pending_ability_bind_slot = -1
		voice_menu.set_meta("bind_slot", -1)
		return

	voice_menu.clear()
	for i in range(_voice_menu_abilities.size()):
		var ab: Dictionary = _voice_menu_abilities[i]
		var label: String = str(ab.get("name", "Ability"))
		var cost: int = int(ab.get("cost", 0))
		if cost > 0:
			label += " (%d voice)" % cost
		if bind_slot < 0 and not bool(ab.get("can_use", false)):
			label += " [%s]" % str(ab.get("reason", "Unavailable"))
		voice_menu.add_item(label, i)
		if bind_slot < 0:
			voice_menu.set_item_disabled(i, not bool(ab.get("can_use", false)))

	voice_menu.popup_centered()
	GameManager.is_player_turn = false
	if bind_slot >= 0:
		GameManager.log_message("Choose an ability for gem %d." % (bind_slot + 1), ThemeColors.MSG_INFO)
	else:
		GameManager.log_message("Select an ability to cast.", ThemeColors.MSG_SYSTEM)

func _on_voice_menu_selected(index: int) -> void:
	GameManager.is_player_turn = true
	_voice_menu_targeting_requested = false
	if index < 0 or index >= _voice_menu_abilities.size() or not player:
		return
	var ab: Dictionary = _voice_menu_abilities[index]
	var ability_id: int = int(ab.get("id", -1))
	if ability_id < 0:
		return

	var bind_slot: int = _pending_ability_bind_slot
	if voice_menu and voice_menu.has_meta("bind_slot"):
		bind_slot = int(voice_menu.get_meta("bind_slot"))
	# Bind flow takes priority when user opened menu from gem bind UX.
	if bind_slot >= 0:
		if bind_slot < player.ability_hotkeys.size():
			player.ability_hotkeys[bind_slot] = ability_id
			GameManager.log_message("Bound %s to gem %d." % [str(ab.get("name", "Ability")), bind_slot + 1], ThemeColors.MSG_INFO)
			hud.update_hotbar(player, ability_system)
		_pending_ability_bind_slot = -1
		if voice_menu:
			voice_menu.set_meta("bind_slot", -1)
		return

	if not bool(ab.get("can_use", false)):
		return
	if _cast_hotbar_ability(ability_id):
		# Targeting requested; keep the game paused for target selection.
		GameManager.is_player_turn = false

func _on_voice_menu_closed() -> void:
	# If this hide came from selecting a targeted ability, keep turn control paused.
	if _voice_menu_targeting_requested:
		_voice_menu_targeting_requested = false
		return
	# Keep bind slot state intact through popup-hide event ordering.
	# It is explicitly cleared in selection, and overwritten on next menu open.
	if not (target_panel and target_panel.visible):
		GameManager.is_player_turn = true

func _get_all_hotbar_bindable_abilities() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not player:
		return entries

	# Player active/toggle ability gems (combat/utility stances)
	var gem_candidates: Array[Dictionary] = [
		{"id": Player.GEM_DEFENSIVE_STANCE, "skill": Constants.Skill.S_MEL, "ability": Constants.MeleeAbility.MEL_DEFENSIVE_STANCE},
		{"id": Player.GEM_READY_PARRY, "skill": Constants.Skill.S_EVN, "ability": Constants.EvasionAbility.EVN_PARRY},
		{"id": Player.GEM_MARK_QUARRY, "skill": Constants.Skill.S_PER, "ability": Constants.PerceptionAbility.PER_FOCUSED_ATTACK},
		{"id": Player.GEM_EXPOSE_WEAKNESS, "skill": Constants.Skill.S_PER, "ability": Constants.PerceptionAbility.PER_BANE},
		{"id": Player.GEM_EXPLOIT_OPENING, "skill": Constants.Skill.S_PER, "ability": Constants.PerceptionAbility.PER_MASTER_HUNTER},
		{"id": Player.GEM_DISGUISE, "skill": Constants.Skill.S_STL, "ability": Constants.StealthAbility.STL_DISGUISE},
		{"id": Player.GEM_CIRCULAR_GUARD, "skill": Constants.Skill.S_EVN, "ability": Constants.EvasionAbility.EVN_CROWD_FIGHTING},
		{"id": Player.GEM_SWIFT_STRIKES, "skill": Constants.Skill.S_MEL, "ability": Constants.MeleeAbility.MEL_RAPID_ATTACK},
		{"id": Player.GEM_CRIPPLING_SHOT, "skill": Constants.Skill.S_ARC, "ability": Constants.ArcheryAbility.ARC_CRIPPLING_SHOT},
		{"id": Player.GEM_KEEN_SENSES, "skill": Constants.Skill.S_PER, "ability": Constants.PerceptionAbility.PER_KEEN_SENSES},
		{"id": Player.GEM_CURSE_BREAKING, "skill": Constants.Skill.S_WIL, "ability": Constants.WillAbility.WIL_CURSE_BREAKING},
		{"id": Player.GEM_POWER_STANCE, "skill": Constants.Skill.S_MEL, "ability": Constants.MeleeAbility.MEL_POWER},
		{"id": Player.GEM_FINESSE_STANCE, "skill": Constants.Skill.S_MEL, "ability": Constants.MeleeAbility.MEL_FINESSE},
		{"id": Player.GEM_VANISH, "skill": Constants.Skill.S_STL, "ability": Constants.StealthAbility.STL_VANISH},
		{"id": Player.GEM_SPRINTING, "skill": Constants.Skill.S_EVN, "ability": Constants.EvasionAbility.EVN_SPRINTING},
	]
	for item in gem_candidates:
		var skill_id: int = int(item.get("skill", -1))
		var ability_idx: int = int(item.get("ability", -1))
		if not player.has_ability(skill_id, ability_idx):
			continue
		var gem_id: int = int(item.get("id", -1))
		var check: Dictionary = player.can_use_hotbar_ability(gem_id, ability_system)
		entries.append({
			"id": gem_id,
			"name": player.get_hotbar_ability_display_name(gem_id),
			"cost": player.get_hotbar_ability_cost(gem_id, ability_system),
			"can_use": bool(check.get("can_use", false)),
			"reason": str(check.get("reason", "")),
			"needs_target": player.is_hotbar_ability_targeted(gem_id, ability_system),
		})

	# Lore actives/sustains from ability system.
	if ability_system:
		var lore_entries: Array[Dictionary] = ability_system.get_learned_active_abilities()
		for lore_entry in lore_entries:
			entries.append({
				"id": int(lore_entry.get("id", -1)),
				"name": str(lore_entry.get("name", "")),
				"cost": int(lore_entry.get("cost", 0)),
				"can_use": bool(lore_entry.get("can_use", false)),
				"reason": str(lore_entry.get("reason", "")),
				"needs_target": bool(lore_entry.get("needs_target", false)),
			})
	return entries

func _cast_hotbar_slot(slot_index: int) -> void:
	if not player or not player.is_alive or not GameManager.is_player_turn:
		return
	if slot_index < 0 or slot_index >= player.ability_hotkeys.size():
		return
	var ability_id: int = int(player.ability_hotkeys[slot_index])
	if ability_id < 0:
		# Empty slot: pressing the key enters bind flow for this gem.
		_open_voice_menu(slot_index)
		return
	_cast_hotbar_ability(ability_id)

func _cast_hotbar_ability(ability_id: int) -> bool:
	if not player or not player.is_alive or not GameManager.is_player_turn:
		return false
	var check: Dictionary = player.can_use_hotbar_ability(ability_id, ability_system)
	if not bool(check.get("can_use", false)):
		GameManager.log_message(str(check.get("reason", "Ability unavailable.")), ThemeColors.MSG_SYSTEM)
		return false

	var name_text: String = player.get_hotbar_ability_display_name(ability_id) if ability_id >= 1000 else ""
	if ability_id >= 140 and ability_id <= 159 and ability_system and ability_system.has_method("_get_ability_name"):
		name_text = str(ability_system._get_ability_name(ability_id))

	var needs_target: bool = player.is_hotbar_ability_targeted(ability_id, ability_system)
	if needs_target:
		if ability_id == Player.GEM_MARK_QUARRY:
			_start_mark_quarry_targeting()
			_voice_menu_targeting_requested = voice_menu != null and voice_menu.visible
			return true
		_pending_voice_ability_id = ability_id
		GameManager.log_message("Select a target for %s..." % name_text, ThemeColors.MSG_INFO)
		target_panel.open(player, current_level)
		GameManager.is_player_turn = false
		_voice_menu_targeting_requested = voice_menu != null and voice_menu.visible
		return true

	var success: bool = false
	if ability_id >= 140 and ability_id <= 159:
		if ability_system:
			success = ability_system.activate_ability(ability_id)
	else:
		success = _activate_player_gem_ability(ability_id)
	if success:
		if ability_id == Player.GEM_SPRINTING:
			hud.update_player_stats(player)
		else:
			_consume_turn_for_ability()
	return success

func _activate_player_gem_ability(ability_id: int) -> bool:
	if not player:
		return false
	match ability_id:
		Player.GEM_DEFENSIVE_STANCE:
			return player.activate_defensive_stance()
		Player.GEM_READY_PARRY:
			return player.ready_parry()
		Player.GEM_EXPOSE_WEAKNESS:
			return player.activate_expose_weakness()
		Player.GEM_EXPLOIT_OPENING:
			return player.activate_exploit_opening()
		Player.GEM_DISGUISE:
			return player.activate_disguise_stance()
		Player.GEM_CIRCULAR_GUARD:
			return player.activate_circular_guard()
		Player.GEM_SWIFT_STRIKES:
			return player.activate_swift_strikes()
		Player.GEM_CRIPPLING_SHOT:
			return player.activate_crippling_shot()
		Player.GEM_KEEN_SENSES:
			return player.activate_keen_senses()
		Player.GEM_CURSE_BREAKING:
			return player.activate_curse_breaking()
		Player.GEM_POWER_STANCE:
			return player.activate_power_stance()
		Player.GEM_FINESSE_STANCE:
			return player.activate_finesse_stance()
		Player.GEM_VANISH:
			return player.activate_vanish()
		Player.GEM_SPRINTING:
			return player.activate_sprinting()
	return false

func _consume_turn_for_ability() -> void:
	if not player or not player.is_alive:
		return
	player.consume_energy()
	turn_system._after_player_action()
	hud.update_player_stats(player)

func _try_open_chest() -> bool:
	if not player or not current_level or not GameManager.is_player_turn:
		return false

	var search_positions: Array[Vector2i] = [player.grid_position]
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			search_positions.append(player.grid_position + Vector2i(dx, dy))

	for pos in search_positions:
		if not current_level.is_in_bounds(pos):
			continue
		var floor_items: Array[Item] = current_level.get_items_at(pos)
		for floor_item in floor_items:
			if floor_item == null:
				continue
			var item_data: Variant = floor_item.get_data()
			if item_data == null or not ("tval" in item_data):
				continue
			if int(item_data.tval) != TVAL_CHEST:
				continue
			_open_chest_item(floor_item, item_data, pos)
			return true
	return false

func _open_chest_item(chest_item: Item, chest_data: Variant, pos: Vector2i) -> void:
	if not current_level or not player:
		return

	var chest_name: String = chest_item.get_display_name()
	current_level.remove_item(chest_item)
	chest_item.queue_free()

	var sval: int = int(chest_data.sval) if ("sval" in chest_data) else 0
	var loot_count: int = 1
	if sval >= 11:
		loot_count = 2
	if sval in [3, 13]:
		loot_count += 1

	var spawned: int = 0
	for _i in range(loot_count):
		var loot_template: DataManager.ItemData = DataManager.get_themed_item_for_depth(GameManager.current_depth)
		if loot_template == null:
			continue
		var loot_copy: DataManager.ItemData = DataManager.duplicate_item_data(loot_template)
		loot_copy.identified = false
		loot_copy.stack_count = 1
		var loot_node: Item = ITEM_SCENE.instantiate()
		loot_node.grid_position = pos
		loot_node.initialize_from_item_data(loot_copy)
		current_level.add_item(loot_node)
		spawned += 1

	GameManager.log_message("You open %s. %d item%s spill out." % [
		chest_name, spawned, "" if spawned == 1 else "s"
	], ThemeColors.MSG_LOOT)
	player.consume_energy()
	turn_system._after_player_action()
	hud.update_player_stats(player)

# ============================================================================
# ITEM SELECTION MENU (comma / Q / R keys)
# ============================================================================

func _open_item_selection(tval: int, verb: String, empty_msg: String) -> void:
	## Open a selection popup for consumable items of the given tval.
	## If 0 items: show empty_msg. If 1 item: use immediately. If 2+: show popup.
	if not player or not player.is_alive or not GameManager.is_player_turn:
		return

	# Filter inventory for matching tval
	_item_menu_items.clear()
	_item_menu_tval = tval
	for item in player.inventory:
		if item != null and "tval" in item and item.tval == tval:
			_item_menu_items.append(item)

	if _item_menu_items.is_empty():
		GameManager.log_message(empty_msg, ThemeColors.MSG_SYSTEM)
		return

	if _item_menu_items.size() == 1:
		# Single item - use directly without popup
		_consume_inventory_item(_item_menu_items[0])
		return

	# Multiple items - build and show popup menu
	item_menu.clear()
	for i in range(_item_menu_items.size()):
		var item = _item_menu_items[i]
		var label: String = GameManager.get_item_display_name(item)
		var stack: int = item.stack_count if "stack_count" in item else 1
		if stack > 1:
			label += " (x%d)" % stack
		item_menu.add_item(label, i)

	item_menu.popup_centered()
	GameManager.is_player_turn = false

func _on_item_menu_selected(index: int) -> void:
	## Handle item selection from the popup menu.
	GameManager.is_player_turn = true
	if index < 0 or index >= _item_menu_items.size():
		return

	var item = _item_menu_items[index]
	_consume_inventory_item(item)

func _on_item_menu_closed() -> void:
	## Restore player turn when menu is dismissed without selection.
	if not GameManager.is_player_turn:
		GameManager.is_player_turn = true

func _consume_inventory_item(item: Variant) -> void:
	## Use a consumable item from inventory, decrement stack or remove, and end turn.
	if item == null or not player:
		return

	# For horns, use_item sets up pending state and returns false; don't consume turn yet
	if "tval" in item and item.tval == Constants.TVAL_HORN:
		ConsumableSystem.use_item(player, item)
		# Horn pending state is handled by the horn direction intercept at top of _unhandled_input
		return

	if ConsumableSystem.use_item(player, item):
		# Decrement stack or remove from inventory
		var count: int = item.stack_count if "stack_count" in item else 1
		if count > 1:
			item.stack_count = count - 1
		else:
			var idx: int = player.inventory.find(item)
			if idx >= 0:
				player.inventory.remove_at(idx)

		# Consume a turn
		player.consume_energy()
		turn_system._after_player_action()
		hud.update_player_stats(player)

func _on_utility_bind_requested(item_data: Variant, slot_index: int) -> void:
	if not player or item_data == null:
		return
	if not player.bind_utility_item(slot_index, item_data):
		GameManager.log_message("Failed to load utility slot %d." % (slot_index + 1), ThemeColors.MSG_ERROR)
		return
	var item_name: String = GameManager.get_item_display_name(item_data)
	GameManager.log_message("Loaded %s into utility slot %d." % [item_name, slot_index + 1], ThemeColors.MSG_INFO)
	hud.update_player_stats(player)

func _on_hud_utility_slot_activated(slot_index: int) -> void:
	if not player or not player.is_alive or not GameManager.is_player_turn:
		return
	var desc: Dictionary = player.get_utility_descriptor(slot_index)
	if desc.is_empty():
		GameManager.log_message("Utility slot %d is empty." % (slot_index + 1), ThemeColors.MSG_SYSTEM)
		return
	var item = player.resolve_utility_item(slot_index)
	if item == null:
		GameManager.log_message("That utility item is no longer available.", ThemeColors.MSG_SYSTEM)
		player.clear_utility_item(slot_index)
		hud.update_player_stats(player)
		return
	if not ("tval" in item):
		return
	var tval: int = int(item.tval)

	# Consumables: use directly (turn-consuming).
	if tval in [55, 75, 80]:
		if not player.inventory.has(item):
			GameManager.log_message("Consumables must be in inventory to use.", ThemeColors.MSG_SYSTEM)
			return
		_consume_inventory_item(item)
		hud.update_player_stats(player)
		return

	# Equippables: hot-swap into their natural slot.
	if Constants.TVAL_TO_SLOT.has(tval):
		var slot_id: int = int(Constants.TVAL_TO_SLOT[tval])
		var slot_key: String = player._equip_slot_id_to_key(slot_id)
		if slot_key.is_empty():
			return
		if player.inventory.has(item):
			if player.equip_item(item, slot_key):
				var item_name: String = GameManager.get_item_display_name(item)
				GameManager.log_message("Equipped %s from utility slot." % item_name, ThemeColors.MSG_INFO)
				player.consume_energy()
				turn_system._after_player_action()
		else:
			GameManager.log_message("That item is already equipped.", ThemeColors.MSG_SYSTEM)
		hud.update_player_stats(player)
		return

	GameManager.log_message("This item can't be used from utility slots.", ThemeColors.MSG_SYSTEM)

func _on_hud_utility_slot_cleared(slot_index: int) -> void:
	if not player:
		return
	player.clear_utility_item(slot_index)
	GameManager.log_message("Cleared utility slot %d." % (slot_index + 1), ThemeColors.MSG_INFO)
	hud.update_player_stats(player)

func _on_hud_utility_slot_bind_requested(slot_index: int) -> void:
	if not player or slot_index < 0:
		return
	_pending_utility_bind_slot = slot_index
	if inventory_panel and not inventory_panel.visible:
		_toggle_inventory()
	GameManager.log_message("Select an inventory item to load into utility slot %d." % (slot_index + 1), ThemeColors.MSG_INFO)

func _on_hud_utility_equip_drop_requested(slot_index: int, equip_slot_name: String) -> void:
	if not player or not player.is_alive or not GameManager.is_player_turn:
		return
	if equip_slot_name.is_empty():
		return
	var item = player.resolve_utility_item(slot_index)
	if item == null or not ("tval" in item):
		GameManager.log_message("No valid utility item to equip.", ThemeColors.MSG_SYSTEM)
		return
	if not player.inventory.has(item):
		GameManager.log_message("Only inventory items can be dragged to equipment slots.", ThemeColors.MSG_SYSTEM)
		return
	if not player.equipment.has(equip_slot_name):
		return
	if not Constants.TVAL_TO_SLOT.has(int(item.tval)):
		GameManager.log_message("That item is not equippable.", ThemeColors.MSG_SYSTEM)
		return
	var expected_slot_key: String = player._equip_slot_id_to_key(int(Constants.TVAL_TO_SLOT[int(item.tval)]))
	if expected_slot_key != equip_slot_name:
		GameManager.log_message("That item cannot be equipped to %s." % equip_slot_name.replace("_", " "), ThemeColors.MSG_SYSTEM)
		return
	if player.equip_item(item, equip_slot_name):
		var item_name: String = GameManager.get_item_display_name(item)
		GameManager.log_message("Equipped %s." % item_name, ThemeColors.MSG_INFO)
		player.consume_energy()
		turn_system._after_player_action()
		hud.update_player_stats(player)

func _on_hud_ability_slot_cast_requested(slot_index: int) -> void:
	_cast_hotbar_slot(slot_index)

func _on_hud_ability_slot_cleared(slot_index: int) -> void:
	if not player:
		return
	if slot_index < 0 or slot_index >= player.ability_hotkeys.size():
		return
	player.ability_hotkeys[slot_index] = -1
	GameManager.log_message("Cleared gem %d." % (slot_index + 1), ThemeColors.MSG_INFO)
	hud.update_hotbar(player, ability_system)

func _on_hud_ability_slot_bind_requested(slot_index: int) -> void:
	if not player or slot_index < 0:
		return
	_open_voice_menu(slot_index)

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
	if ChronicleManager:
		ChronicleManager.record_run(player, player.run_stats, "death")

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
	_cleanup_before_exit()
	get_tree().quit()

func _cleanup_before_exit() -> void:
	if _cleanup_done:
		return
	_cleanup_done = true

	# Disconnect global signals first to avoid callbacks during teardown.
	if EventBus.npc_interacted.is_connected(_on_npc_interacted):
		EventBus.npc_interacted.disconnect(_on_npc_interacted)
	if EventBus.item_dropped.is_connected(_on_item_dropped_to_ground):
		EventBus.item_dropped.disconnect(_on_item_dropped_to_ground)

	var nodes_to_free: Array = [
		title_screen, character_creation, inventory_panel, tome_panel, death_screen, look_panel,
		dialogue_panel, smithing_panel, target_panel, bestiary_panel, settings_panel,
		character_panel, transition_overlay, voice_menu, item_menu, ability_system,
		quest_system, current_level, player
	]
	for node in nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()

	title_screen = null
	character_creation = null
	inventory_panel = null
	tome_panel = null
	death_screen = null
	look_panel = null
	dialogue_panel = null
	smithing_panel = null
	target_panel = null
	bestiary_panel = null
	settings_panel = null
	character_panel = null
	transition_overlay = null
	voice_menu = null
	item_menu = null
	ability_system = null
	quest_system = null
	current_level = null
	player = null


# ============================================================================
# SMITHING SYSTEM (Phase 8C)
# ============================================================================

func _try_use_forge() -> void:
	if not player or not current_level:
		return

	var tile: int = current_level.get_tile(player.grid_position)
	if not current_level.is_forge_tile(player.grid_position):
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

	# HP regen during rest: +1 HP every 4 rest turns (disabled on Ironman)
	var rest_heal_allowed: bool = GameManager.allows_rest_healing() if GameManager else true
	if rest_heal_allowed and _rest_turns_taken % 4 == 0 and player.current_health < player.max_health:
		player.current_health = mini(player.current_health + 1, player.max_health)

	# Simulate player consuming energy and processing the game tick
	player.consume_energy()
	turn_system._after_player_action()
	if ability_system:
		ability_system.regenerate_voice()
	hud.update_player_stats(player)

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
# TUNNELLING / MINING (T key)
# ============================================================================

func _try_start_tunnel() -> void:
	if not player or not player.is_alive:
		return
	if not player.has_equip_flag("TUNNEL"):
		GameManager.log_message("You need a digging tool to mine rubble.", ThemeColors.MSG_WARNING)
		return
	_pending_tunnel = true
	GameManager.log_message("Tunnel in which direction?", ThemeColors.MSG_INFO)

func _try_mine_direction(dir: Vector2i) -> void:
	_pending_tunnel = false
	if not player or not current_level:
		return
	var target_pos: Vector2i = player.grid_position + dir
	if not current_level.is_in_bounds(target_pos):
		GameManager.log_message("Nothing to mine there.", ThemeColors.MSG_SYSTEM)
		return
	if current_level.get_tile(target_pos) != Level.Tile.RUBBLE:
		GameManager.log_message("There is no rubble in that direction.", ThemeColors.MSG_SYSTEM)
		return

	# Calculate mining turns based on smithing skill
	var smithing_level: int = player.get_effective_skill("smithing") if player.has_method("get_effective_skill") else 0
	_mining_turns_required = maxi(2, 4 - smithing_level / 2)
	_mining_target = target_pos
	_mining_turns_taken = 0
	_mining_hp_before = player.current_health
	_mining = true
	GameManager.log_message("You begin mining the rubble... (%d turns)" % _mining_turns_required, ThemeColors.MSG_SYSTEM)

func _process_mining_step() -> void:
	if not _mining or not player or not player.is_alive:
		_stop_mining("Invalid state")
		return

	# Interrupt: monster visible
	if _has_visible_monster():
		_stop_mining("Monster spotted!")
		return

	# Interrupt: took damage
	if player.current_health < _mining_hp_before:
		_stop_mining("Took damage!")
		return

	# Take a mining turn
	_mining_turns_taken += 1

	# Generate digging noise each turn
	if current_level:
		current_level.add_floor_noise(Constants.NOISE_DIGGING)
	if player.has_method("add_noise"):
		player.add_noise(Constants.NOISE_DIGGING)

	# Consume energy for the turn
	player.consume_energy()
	turn_system._after_player_action()

	# Update HP tracker for next check
	_mining_hp_before = player.current_health

	# Check completion
	if _mining_turns_taken >= _mining_turns_required:
		_complete_mining()
		return

func _complete_mining() -> void:
	_mining = false
	if current_level and current_level.is_in_bounds(_mining_target):
		current_level.set_tile(_mining_target, Level.Tile.FLOOR)
		GameManager.log_message("You clear the rubble.", ThemeColors.MSG_INFO)
		player.gain_experience(5, "mining")
		# Refresh FOV since rubble was already transparent but passability changed
		var fov_radius: int = current_level.get_fov_radius()
		var light_radius: int = player.get_light_radius()
		current_level.update_fov(player.grid_position, fov_radius)
		current_level.apply_lighting(player.grid_position, light_radius)
		current_level.update_entity_visibility()
		current_level.apply_fov_to_tilemap()
		hud.update_player_stats(player)

func _stop_mining(reason: String) -> void:
	if not _mining:
		return
	_mining = false
	if _mining_turns_taken > 0:
		GameManager.log_message("Mining interrupted: %s" % reason, ThemeColors.MSG_WARNING)
	else:
		GameManager.log_message(reason, ThemeColors.MSG_WARNING)

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

	# Check if next tile is a closed door — open it (costs a turn, then continue next tick)
	if current_level and current_level.get_tile(next_pos) == Level.Tile.DOOR_CLOSED:
		current_level.set_tile(next_pos, Level.Tile.DOOR_OPEN)
		GameManager.log_message("You open the door.", ThemeColors.TEXT_PRIMARY)
		player.add_noise(Constants.NOISE_DOOR)
		player.consume_energy()
		turn_system._after_player_action()
		return

	# Move the player
	if player.try_move(direction):
		player.record_action(player.direction_to_action(direction))
		var move_cost: int = current_level.get_movement_cost(player.grid_position) if current_level else Constants.ACTION_COST
		if player.stealth_mode:
			move_cost *= Constants.STEALTH_MODE_SPEED_MULTIPLIER
		player.consume_energy(move_cost)
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
	var player_lore: int = player.get_effective_skill("lore") if player != null else 0

	# Whisper of the Valar: check if player has active whisper reveals
	var has_whisper: bool = player != null and "_whisper_turns" in player and player._whisper_turns > 0
	var whisper_revealed: Array = player._whisper_revealed if has_whisper and "_whisper_revealed" in player else []
	var has_listen: bool = player != null and "_listen_turns" in player and player._listen_turns > 0
	var listen_revealed: Array = player._listen_revealed if has_listen and "_listen_revealed" in player else []

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

			# Listen (Perception): reveals nearby monsters through walls while stationary
			if not is_visible and has_listen:
				if entity.get_instance_id() in listen_revealed:
					is_visible = true
					entity.visible = true

			if is_visible:
				# Deep Memory: on first sighting, grant Lore/3 bonus observations
				if has_deep_memory and entity.monster_data and "index" in entity.monster_data:
					var monster_id: int = entity.monster_data.index
					if monster_memory.get_observation_count(monster_id) == 0:
						var bonus: int = maxi(1, player_lore / 3)
						for i in range(bonus):
							monster_memory.record_observation(entity)
						var monster_name: String = entity.entity_name if entity.entity_name else "creature"
						GameManager.log_message("Deep Memory: You recall lore about the %s." % monster_name, ThemeColors.SKILL_LORE)
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

# ============================================================================
# CHARACTER PANEL (C key)
# ============================================================================

func _toggle_character_panel() -> void:
	if character_panel and character_panel.visible:
		character_panel.close()
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
		if character_panel and player:
			character_panel.open(player)
			GameManager.is_player_turn = false

func _on_character_panel_closed() -> void:
	GameManager.is_player_turn = true

# ============================================================================
# ITEM DROP HANDLER
# ============================================================================

func _on_item_dropped_to_ground(entity: Node, item_data: Variant, pos: Vector2i) -> void:
	## Spawn a ground Item node when an item is dropped from inventory.
	if not current_level:
		return

	var item_node: Item = ITEM_SCENE.instantiate()
	item_node.grid_position = pos

	if item_data is DataManager.ArtifactData:
		item_node.initialize_from_artifact_data(item_data)
	elif item_data is DataManager.ItemData:
		item_node.initialize_from_item_data(item_data)

	current_level.add_item(item_node)

	var item_name: String = item_node.get_display_name()
	GameManager.log_message("You drop the %s." % item_name, ThemeColors.MSG_SYSTEM)

# ============================================================================
# WIZARD MODE
# ============================================================================

func _wizard_descend() -> void:
	if not player or not player.is_alive:
		return
	GameManager.log_message("[WIZARD] Descending...", Color.YELLOW)
	_descend()

func _wizard_heal() -> void:
	if not player:
		return
	# Resurrect if dead
	if not player.is_alive:
		player.is_alive = true
		current_state = GameState.PLAYING
		GameManager.log_message("[WIZARD] Resurrected!", Color.YELLOW)
	player.current_health = player.max_health
	player.voice_charges = player.max_voice
	# Clear all negative status effects
	if player.status_fx:
		player.status_fx.effects.clear()
	GameManager.log_message("[WIZARD] Fully healed. HP: %d/%d, Voice: %d/%d" % [player.current_health, player.max_health, player.voice_charges, player.max_voice], Color.YELLOW)
	hud.update_player_stats(player)

func _wizard_kill_all() -> void:
	if not current_level:
		return
	var monsters: Array[Monster] = current_level.get_monsters()
	var count: int = monsters.size()
	for monster in monsters:
		monster.current_health = 0
		monster.is_alive = false
		current_level.remove_entity(monster)
		monster.queue_free()
	GameManager.log_message("[WIZARD] Killed %d monsters." % count, Color.YELLOW)

func _wizard_xp() -> void:
	if not player or not player.is_alive:
		return
	player.gain_experience(100000, "wizard")
	GameManager.log_message("[WIZARD] Granted 100,000 XP.", Color.YELLOW)
	hud.update_player_stats(player)

func _wizard_reveal() -> void:
	if not current_level:
		return
	# Mark all tiles as explored AND visible so monsters/items are shown everywhere
	for y in range(current_level.height):
		for x in range(current_level.width):
			var pos := Vector2i(x, y)
			current_level.set_explored(pos, true)
			current_level.set_tile_visible(pos, true)
	# Update entity visibility (monsters + items) based on new tile_visibility
	current_level.update_entity_visibility()
	# Redraw tilemap with all tiles lit
	current_level.apply_fov_to_tilemap()
	GameManager.log_message("[WIZARD] Map and all monsters revealed.", Color.YELLOW)

func _wizard_teleport_to_thrain() -> void:
	if not player or not player.is_alive:
		return
	const ENDGAME_DEPTH: int = 20
	GameManager.log_message("[WIZARD] Teleporting to Thrain...", Color.YELLOW)

	# Rebuild the target endgame floor directly.
	if current_level:
		current_level.remove_entity(player)
	GameManager.current_depth = ENDGAME_DEPTH
	_generate_level(ENDGAME_DEPTH)
	var fixed_thrain_coord: Vector2i = _get_depth20_thrain_fixed_coord()
	GameManager.log_message("[WIZARD] Depth 20 Thrain target coordinate: %s" % [fixed_thrain_coord], Color.YELLOW)
	var fixed_entity: Entity = current_level.get_entity_at(fixed_thrain_coord)
	if fixed_entity != null:
		var interactable: bool = fixed_entity.has_method("interact")
		GameManager.log_message("[WIZARD] Occupant at fixed coord: %s (%s) interactable=%s" % [fixed_entity.entity_name, fixed_entity.get_class(), str(interactable)], Color.YELLOW)
	else:
		GameManager.log_message("[WIZARD] Occupant at fixed coord: none", Color.YELLOW)

	# Place player adjacent to Thrain if present, otherwise at stairs/random floor.
	var thrain_pos: Vector2i = _find_thrain_position_on_current_level()
	if thrain_pos == Vector2i(-1, -1):
		thrain_pos = _wizard_force_spawn_thrain()
		if thrain_pos == Vector2i(-1, -1):
			thrain_pos = _find_thrain_position_on_current_level()
	var spawn_pos: Vector2i = Vector2i(-1, -1)
	if thrain_pos != Vector2i(-1, -1):
		spawn_pos = _find_or_create_open_tile_near(thrain_pos)
	if spawn_pos == Vector2i(-1, -1):
		spawn_pos = current_level.find_stairs_up()
	if spawn_pos == Vector2i(-1, -1):
		spawn_pos = current_level.find_random_floor()

	player.grid_position = spawn_pos
	current_level.add_entity(player)

	# Keep systems in sync with the new level.
	turn_system.set_level(current_level)
	floater_manager.set_container(current_level.get_node("Effects"))
	hud.set_level(current_level)

	var fov_radius: int = current_level.get_fov_radius()
	var light_radius: int = player.get_light_radius()
	current_level.update_fov(player.grid_position, fov_radius)
	current_level.apply_lighting(player.grid_position, light_radius)
	current_level.update_entity_visibility()
	current_level.apply_fov_to_tilemap()

	if thrain_pos != Vector2i(-1, -1):
		GameManager.log_message("[WIZARD] Arrived near Thrain on depth %d." % ENDGAME_DEPTH, Color.YELLOW)
		GameManager.log_message("[WIZARD] Thrain position: %s | Player position: %s" % [thrain_pos, player.grid_position], Color.YELLOW)
	else:
		GameManager.log_message("[WIZARD] Depth %d loaded (Thrain not found on this floor)." % ENDGAME_DEPTH, Color.YELLOW)
		GameManager.log_message("[WIZARD] Player position: %s" % [player.grid_position], Color.YELLOW)

func _wizard_force_spawn_thrain() -> Vector2i:
	if not current_level:
		return Vector2i(-1, -1)
	var spawn_pos: Vector2i = _find_wizard_thrain_spawn_position()
	if spawn_pos == Vector2i(-1, -1):
		return Vector2i(-1, -1)
	var thrain_script: GDScript = load("res://scripts/entities/thrain_npc.gd")
	if thrain_script == null:
		return Vector2i(-1, -1)
	var thrain: Node = thrain_script.create_at_position(spawn_pos, quest_system)
	# Set identifying fields immediately so detection works before _ready.
	if thrain.has_method("set"):
		thrain.set("npc_id", "thrain_ii")
		thrain.set("entity_name", "Thrain II, Son of Thror")
	current_level.add_entity(thrain)
	if quest_system and quest_system.has_method("mark_thrain_spawned"):
		quest_system.mark_thrain_spawned()
	GameManager.log_message("[WIZARD] Forced Thrain spawn at %s." % [spawn_pos], Color.YELLOW)
	return spawn_pos

func _find_wizard_thrain_spawn_position() -> Vector2i:
	if not current_level:
		return Vector2i(-1, -1)
	var fixed: Vector2i = _get_depth20_thrain_fixed_coord()
	if not current_level.is_in_bounds(fixed):
		return current_level.find_random_floor()
	# Ensure fixed tile is walkable and not stairs/dais.
	var tile: int = current_level.get_tile(fixed)
	if tile == Level.Tile.STAIRS_UP or tile == Level.Tile.STAIRS_DOWN or tile == Level.Tile.THRONE_DAIS or not current_level.is_passable(fixed):
		current_level.set_tile(fixed, Level.Tile.FLOOR)

	# Move blocker out of the fixed tile if needed.
	var blocker: Entity = current_level.get_entity_at(fixed)
	if blocker != null:
		for r in range(1, 13):
			var moved: bool = false
			for y in range(fixed.y - r, fixed.y + r + 1):
				for x in range(fixed.x - r, fixed.x + r + 1):
					var pos := Vector2i(x, y)
					if not current_level.is_in_bounds(pos):
						continue
					if not current_level.is_passable(pos):
						continue
					if current_level.get_entity_at(pos) != null:
						continue
					var t: int = current_level.get_tile(pos)
					if t == Level.Tile.STAIRS_UP or t == Level.Tile.STAIRS_DOWN or t == Level.Tile.THRONE_DAIS:
						continue
					blocker.grid_position = pos
					moved = true
					break
				if moved:
					break
			if moved:
				break
		if blocker.grid_position == fixed:
			current_level.remove_entity(blocker)
			blocker.queue_free()
	return fixed

func _get_depth20_thrain_fixed_coord() -> Vector2i:
	var sauron_pos: Vector2i = _find_sauron_position_on_current_level()
	if sauron_pos != Vector2i(-1, -1):
		return sauron_pos + Vector2i(0, -2)
	return Vector2i(8, 20)

func _find_sauron_position_on_current_level() -> Vector2i:
	if not current_level:
		return Vector2i(-1, -1)
	const SAURON_ID: int = 135
	for entity in current_level.entities:
		if not is_instance_valid(entity):
			continue
		var data: Variant = entity.get("monster_data")
		if data and data.has_method("get"):
			var mon_index: Variant = data.get("index")
			if mon_index == SAURON_ID:
				return entity.grid_position
		var entity_name: Variant = entity.get("entity_name")
		if entity_name is String and String(entity_name).find("Sauron") != -1:
			return entity.grid_position
	return Vector2i(-1, -1)

func _find_thrain_position_on_current_level() -> Vector2i:
	if not current_level:
		return Vector2i(-1, -1)
	for entity in current_level.entities:
		if not is_instance_valid(entity):
			continue
		# Prefer canonical NPC id, with a fallback on display name for safety.
		var npc_id: Variant = entity.get("npc_id")
		if npc_id == "thrain_ii":
			return entity.grid_position
		var entity_name: Variant = entity.get("entity_name")
		if entity_name is String and String(entity_name).find("Thrain") != -1:
			return entity.grid_position
	return Vector2i(-1, -1)

func _find_open_tile_near(origin: Vector2i) -> Vector2i:
	if not current_level:
		return Vector2i(-1, -1)
	var dirs: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
		Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	for dir in dirs:
		var pos := origin + dir
		if not current_level.is_in_bounds(pos):
			continue
		if not current_level.is_passable(pos):
			continue
		if current_level.get_entity_at(pos) != null:
			continue
		return pos
	return Vector2i(-1, -1)

func _find_or_create_open_tile_near(origin: Vector2i) -> Vector2i:
	var near: Vector2i = _find_open_tile_near(origin)
	if near != Vector2i(-1, -1):
		return near
	if not current_level:
		return Vector2i(-1, -1)

	# Hard fallback for deterministic wizard testing:
	# carve a standing tile east of Thrain and clear any non-player blocker.
	var forced: Vector2i = origin + Vector2i(1, 0)
	if not current_level.is_in_bounds(forced):
		forced = origin + Vector2i(-1, 0)
	if not current_level.is_in_bounds(forced):
		return Vector2i(-1, -1)

	var tile: int = current_level.get_tile(forced)
	if tile == Level.Tile.STAIRS_UP or tile == Level.Tile.STAIRS_DOWN or tile == Level.Tile.THRONE_DAIS or not current_level.is_passable(forced):
		current_level.set_tile(forced, Level.Tile.FLOOR)

	var blocker: Entity = current_level.get_entity_at(forced)
	if blocker != null and blocker != player:
		current_level.remove_entity(blocker)
		blocker.queue_free()
	return forced
