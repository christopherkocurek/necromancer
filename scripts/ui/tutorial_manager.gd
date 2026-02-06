extends CanvasLayer
## Contextual tutorial hint system. Shows hints once per save.

var _shown_hints: Dictionary = {}  # hint_id -> true
var _hint_panel: PanelContainer
var _hint_label: Label
var _dismiss_timer: Timer
var _is_showing: bool = false
const HINTS_PATH := "user://tutorial_hints.cfg"

func _ready() -> void:
	layer = 15
	_setup_ui()
	_load_hints()
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.level_entered.connect(_on_level_entered)

func _setup_ui() -> void:
	_hint_panel = PanelContainer.new()
	_hint_panel.visible = false
	var style := ThemeColors.create_panel_stylebox(Color(ThemeColors.BG_SURFACE, 0.9), ThemeColors.PRIMARY_DIM, 1, 8)
	_hint_panel.add_theme_stylebox_override("panel", style)
	# Position at top center
	_hint_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint_panel.position = Vector2(-200, 20)
	_hint_panel.custom_minimum_size = Vector2(400, 0)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	_hint_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_LARGE)
	_hint_panel.add_child(_hint_label)
	add_child(_hint_panel)

	_dismiss_timer = Timer.new()
	_dismiss_timer.one_shot = true
	_dismiss_timer.timeout.connect(_hide_hint)
	add_child(_dismiss_timer)

func show_hint(hint_id: String, text: String) -> void:
	if _shown_hints.has(hint_id):
		return
	_shown_hints[hint_id] = true
	_save_hints()
	_hint_label.text = text
	_hint_panel.visible = true
	_hint_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_hint_panel, "modulate:a", 1.0, 0.3)
	_dismiss_timer.start(5.0)
	_is_showing = true

func _hide_hint() -> void:
	var tween := create_tween()
	tween.tween_property(_hint_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): _hint_panel.visible = false; _is_showing = false)

func check_hints(player_node: Node) -> void:
	if not player_node or _is_showing:
		return
	# HP < 30%
	if "current_health" in player_node and "max_health" in player_node:
		if float(player_node.current_health) / float(maxi(player_node.max_health, 1)) < 0.3:
			show_hint("low_hp", "Use potions [Shift+Q] or herbs [,] to heal")
	# XP >= first skill cost
	if "xp_available" in player_node and player_node.xp_available >= 500:
		show_hint("can_buy_skill", "Press [@] to open Skills and spend XP")
	# Stealth mode available
	if "stealth_mode" in player_node and not player_node.stealth_mode:
		# Check for nearby unwary monster
		if GameManager.current_level:
			for entity in GameManager.current_level.entities:
				if is_instance_valid(entity) and entity is Monster and entity.is_alive:
					if "alertness" in entity and entity.alertness < 5:
						var dist: int = max(abs(entity.grid_position.x - player_node.grid_position.x), abs(entity.grid_position.y - player_node.grid_position.y))
						if dist <= 5:
							show_hint("stealth_hint", "Press [;] for stealth mode")
							break

func check_tile_hints(player_node: Node, tile: int) -> void:
	if not player_node or _is_showing:
		return
	# Standing on stairs
	if tile == 6 or tile == 7:  # STAIRS_UP or STAIRS_DOWN
		show_hint("stairs", "Press [Enter] to use stairs")
	# Standing on forge
	if tile == 9:  # FORGE
		show_hint("forge", "Press [F] to use the forge")

func _on_entity_died(entity: Node, _killer: Node) -> void:
	if entity is Player:
		return
	show_hint("first_kill", "Monsters drop items and give XP")

func _on_item_picked_up(_entity: Node, _item: Variant) -> void:
	pass  # Could show inventory hint

func _on_level_entered(_depth: int) -> void:
	pass

func _load_hints() -> void:
	var config := ConfigFile.new()
	if config.load(HINTS_PATH) == OK:
		for key in config.get_section_keys("hints"):
			_shown_hints[key] = true

func _save_hints() -> void:
	var config := ConfigFile.new()
	for key in _shown_hints:
		config.set_value("hints", key, true)
	config.save(HINTS_PATH)

func reset_hints() -> void:
	_shown_hints.clear()
	_save_hints()
