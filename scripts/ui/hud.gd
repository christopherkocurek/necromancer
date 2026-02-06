extends CanvasLayer
class_name HUD
## Heads-up display with redesigned top bar, bottom message log, minimap,
## stealth meter, and status pill badges.

# --- Top Bar nodes (built in code) ---
var top_panel: PanelContainer
var health_bar: ProgressBar
var health_label: Label
var xp_label: Label
var voice_bar: ProgressBar
var voice_label: Label
var prot_label: Label
var depth_label: Label
var turn_label: Label
var stealth_label: Label
var status_container: HBoxContainer

# --- Bottom Bar nodes ---
var bottom_panel: PanelContainer
var message_log: RichTextLabel
var equip_container: HBoxContainer
var filter_container: HBoxContainer
var _bottom_expanded: bool = false

# --- Minimap ---
var minimap: Minimap = null

# --- Stealth meter ---
var stealth_meter: ColorRect = null

# --- Message system ---
const MAX_MESSAGES := 200
var messages: Array[Dictionary] = []  # {text, color, category}
var _active_filter: String = "all"
var _turn_count: int = 0

# Dangerous statuses that pulse in the HUD
const DANGER_STATUSES := ["poisoned", "burning", "stunned", "confused"]

# Equipment quick-view slot order
const EQUIP_SLOTS := ["weapon", "off_hand", "armor", "head", "light", "amulet"]

func _ready() -> void:
	layer = 10
	_build_top_bar()
	_build_bottom_bar()
	_build_minimap()
	_build_stealth_meter()
	_connect_signals()

# ============================================================================
# BUILD UI
# ============================================================================

func _build_top_bar() -> void:
	top_panel = PanelContainer.new()
	top_panel.name = "TopPanel"
	top_panel.add_theme_stylebox_override("panel", ThemeColors.create_panel_stylebox(
		Color(ThemeColors.BG_DARK.r, ThemeColors.BG_DARK.g, ThemeColors.BG_DARK.b, 0.85),
		ThemeColors.BORDER_DEFAULT, 1, 0
	))
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_bottom = 36
	add_child(top_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	top_panel.add_child(hbox)

	# Health icon + bar + label
	var hp_icon := Label.new()
	hp_icon.text = "HP"
	hp_icon.add_theme_color_override("font_color", ThemeColors.HEALTH_HIGH)
	hp_icon.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
	hbox.add_child(hp_icon)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(140, 16)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(health_bar)

	health_label = Label.new()
	health_label.text = "10/10"
	health_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	health_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	hbox.add_child(health_label)

	# Separator
	var sep1 := VSeparator.new()
	sep1.add_theme_constant_override("separation", 4)
	hbox.add_child(sep1)

	# XP
	xp_label = Label.new()
	xp_label.text = "XP: 0"
	xp_label.add_theme_color_override("font_color", ThemeColors.MSG_XP)
	xp_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	hbox.add_child(xp_label)

	# Voice charges (hidden when max_voice == 0)
	var sep_voice := VSeparator.new()
	sep_voice.name = "VoiceSep"
	hbox.add_child(sep_voice)

	var voice_icon := Label.new()
	voice_icon.name = "VoiceIcon"
	voice_icon.text = "Voice"
	voice_icon.add_theme_color_override("font_color", ThemeColors.SECONDARY)
	voice_icon.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
	hbox.add_child(voice_icon)

	voice_bar = ProgressBar.new()
	voice_bar.name = "VoiceBar"
	voice_bar.custom_minimum_size = Vector2(60, 12)
	voice_bar.max_value = 10
	voice_bar.value = 0
	voice_bar.show_percentage = false
	voice_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(voice_bar)

	voice_label = Label.new()
	voice_label.name = "VoiceLabel"
	voice_label.text = "0/10"
	voice_label.add_theme_color_override("font_color", ThemeColors.SECONDARY)
	voice_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
	hbox.add_child(voice_label)

	# Separator
	var sep2 := VSeparator.new()
	hbox.add_child(sep2)

	# Protection dice
	prot_label = Label.new()
	prot_label.text = ""
	prot_label.add_theme_color_override("font_color", ThemeColors.SECONDARY)
	prot_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	hbox.add_child(prot_label)

	# Depth and turn
	depth_label = Label.new()
	depth_label.text = "Depth:1"
	depth_label.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
	depth_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	hbox.add_child(depth_label)

	turn_label = Label.new()
	turn_label.text = "Turn:0"
	turn_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	turn_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	hbox.add_child(turn_label)

	# Stealth indicator
	stealth_label = Label.new()
	stealth_label.text = ""
	stealth_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	hbox.add_child(stealth_label)

	# Spacer to push status icons right
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Status icons
	status_container = HBoxContainer.new()
	status_container.add_theme_constant_override("separation", 4)
	hbox.add_child(status_container)

func _build_bottom_bar() -> void:
	bottom_panel = PanelContainer.new()
	bottom_panel.name = "BottomPanel"
	bottom_panel.add_theme_stylebox_override("panel", ThemeColors.create_panel_stylebox(
		Color(ThemeColors.BG_DARK.r, ThemeColors.BG_DARK.g, ThemeColors.BG_DARK.b, 0.85),
		ThemeColors.BORDER_DEFAULT, 1, 0
	))
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -100  # 100px collapsed height
	add_child(bottom_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	bottom_panel.add_child(vbox)

	# Filter bar
	filter_container = HBoxContainer.new()
	filter_container.add_theme_constant_override("separation", 4)
	vbox.add_child(filter_container)

	for filter_name in ["All", "Combat", "Items", "System"]:
		var btn := Button.new()
		btn.text = filter_name
		btn.toggle_mode = true
		btn.button_pressed = (filter_name == "All")
		btn.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
		btn.pressed.connect(_on_filter_pressed.bind(filter_name.to_lower()))
		filter_container.add_child(btn)

	# Add expand hint
	var expand_hint := Label.new()
	expand_hint.text = "[Tab to expand]"
	expand_hint.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
	expand_hint.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
	expand_hint.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	filter_container.add_child(expand_hint)

	# Main content row
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 8)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_hbox)

	# Message log (left side, takes most space)
	message_log = RichTextLabel.new()
	message_log.name = "MessageLog"
	message_log.bbcode_enabled = true
	message_log.scroll_following = true
	message_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_log.add_theme_color_override("default_color", ThemeColors.TEXT_PRIMARY)
	message_log.add_theme_font_size_override("normal_font_size", ThemeColors.FONT_SIZE_BODY)
	content_hbox.add_child(message_log)

	# Equipment quick-view (right side, 6 icons)
	equip_container = HBoxContainer.new()
	equip_container.add_theme_constant_override("separation", 2)
	content_hbox.add_child(equip_container)

	for slot_name in EQUIP_SLOTS:
		var slot := PanelContainer.new()
		slot.name = "Slot_%s" % slot_name
		slot.custom_minimum_size = Vector2(32, 32)
		slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
			ThemeColors.SLOT_EMPTY, ThemeColors.BORDER_DEFAULT
		))
		slot.tooltip_text = slot_name.capitalize().replace("_", " ")
		equip_container.add_child(slot)

func _build_minimap() -> void:
	minimap = Minimap.new()
	minimap.name = "Minimap"
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -168
	minimap.offset_top = 42
	minimap.offset_right = -8
	minimap.offset_bottom = 122
	minimap.visible = false
	add_child(minimap)

func _build_stealth_meter() -> void:
	stealth_meter = ColorRect.new()
	stealth_meter.name = "StealthMeter"
	stealth_meter.custom_minimum_size = Vector2(8, 100)
	stealth_meter.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	stealth_meter.offset_left = 4
	stealth_meter.offset_top = -50
	stealth_meter.offset_right = 12
	stealth_meter.offset_bottom = 50
	stealth_meter.color = ThemeColors.ALERT_SAFE
	stealth_meter.visible = false
	add_child(stealth_meter)

func _connect_signals() -> void:
	EventBus.message_logged.connect(_on_message_logged)
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.entity_healed.connect(_on_entity_healed)
	EventBus.level_entered.connect(_on_level_entered)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.status_removed.connect(_on_status_removed)

# ============================================================================
# PLAYER STATS UPDATE
# ============================================================================

func update_player_stats(player: Player) -> void:
	if not player:
		return

	# Health
	health_bar.max_value = player.max_health
	health_bar.value = player.current_health
	health_label.text = "%d/%d" % [player.current_health, player.max_health]
	var health_pct := float(player.current_health) / float(maxi(player.max_health, 1))
	health_bar.modulate = ThemeColors.get_health_color(health_pct)

	# XP
	xp_label.text = "XP: %s" % _format_number(player.xp_available)

	# Voice charges
	var show_voice: bool = player.max_voice > 0
	voice_bar.visible = show_voice
	voice_label.visible = show_voice
	var voice_icon_node := top_panel.find_child("VoiceIcon", true, false)
	if voice_icon_node:
		voice_icon_node.visible = show_voice
	var voice_sep_node := top_panel.find_child("VoiceSep", true, false)
	if voice_sep_node:
		voice_sep_node.visible = show_voice
	if show_voice:
		voice_bar.max_value = player.max_voice
		voice_bar.value = player.voice_charges
		voice_label.text = "%d/%d" % [player.voice_charges, player.max_voice]

	# Protection dice
	if player.protection_dice > 0 and player.protection_sides > 0:
		prot_label.text = "[%dd%d]" % [player.protection_dice, player.protection_sides]
	else:
		prot_label.text = ""

	# Stealth indicator
	if player.stealth_mode:
		stealth_label.text = "STL"
		stealth_label.add_theme_color_override("font_color", ThemeColors.MSG_STEALTH)
	else:
		stealth_label.text = ""

	# Update stealth meter visibility
	_update_stealth_meter(player)

	# Equipment quick-view
	_update_equip_icons(player)

func _update_equip_icons(player: Player) -> void:
	for i in range(EQUIP_SLOTS.size()):
		if i >= equip_container.get_child_count():
			break
		var slot: PanelContainer = equip_container.get_child(i)
		var slot_name: String = EQUIP_SLOTS[i]
		var item = player.equipment.get(slot_name)

		if item != null:
			slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
				ThemeColors.SLOT_EQUIP_EMPTY, ThemeColors.BORDER_FOCUS
			))
			var item_name: String = GameManager.get_item_display_name(item)
			slot.tooltip_text = "%s: %s" % [slot_name.capitalize().replace("_", " "), item_name]
		else:
			slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
				ThemeColors.SLOT_EMPTY, ThemeColors.BORDER_DEFAULT
			))
			slot.tooltip_text = "%s: empty" % slot_name.capitalize().replace("_", " ")

func _update_stealth_meter(player: Player) -> void:
	if not stealth_meter:
		return

	# Show meter when in stealth mode or when nearby monsters exist
	var show_meter: bool = player.stealth_mode
	if not show_meter and GameManager.current_level:
		for entity in GameManager.current_level.entities:
			if is_instance_valid(entity) and entity is Monster and entity.is_alive:
				if GameManager.current_level.is_tile_visible(entity.grid_position):
					show_meter = true
					break

	stealth_meter.visible = show_meter
	if not show_meter:
		return

	# Find highest nearby alertness
	var max_alertness: int = 0
	if GameManager.current_level:
		for entity in GameManager.current_level.entities:
			if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
				continue
			if not GameManager.current_level.is_tile_visible(entity.grid_position):
				continue
			if "alertness" in entity and entity.alertness > max_alertness:
				max_alertness = entity.alertness

	stealth_meter.color = ThemeColors.get_alertness_color(max_alertness)

# ============================================================================
# MINIMAP
# ============================================================================

func set_level(level: Level) -> void:
	if minimap:
		minimap.set_level(level)

func set_player(player: Player) -> void:
	if minimap:
		minimap.set_player(player)

func refresh_minimap() -> void:
	if minimap:
		minimap.mark_dirty()
		minimap.refresh()

func toggle_minimap() -> void:
	if minimap:
		minimap.visible = not minimap.visible

# ============================================================================
# BOTTOM BAR EXPAND/COLLAPSE
# ============================================================================

func toggle_bottom_bar() -> void:
	_bottom_expanded = not _bottom_expanded
	var target_top: float = -280.0 if _bottom_expanded else -100.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(bottom_panel, "offset_top", target_top, 0.2)

# ============================================================================
# MESSAGES
# ============================================================================

func _on_message_logged(text: String, color: Color) -> void:
	# Determine category from color
	var category: String = _categorize_message(color)

	messages.append({"text": text, "color": color, "category": category})

	while messages.size() > MAX_MESSAGES:
		messages.pop_front()

	_refresh_message_display()

func _categorize_message(color: Color) -> String:
	# Categorize based on the color used (semantic mapping)
	if color == ThemeColors.DMG_PHYSICAL or color == ThemeColors.COMBAT_HIT or \
	   color == ThemeColors.COMBAT_CRIT or color == ThemeColors.COMBAT_MISS or \
	   color == ThemeColors.COMBAT_BLOCK or color == ThemeColors.MSG_ERROR:
		return "combat"
	elif color == ThemeColors.MSG_LOOT or color == ThemeColors.RARITY_ARTIFACT or \
		 color == ThemeColors.MSG_INFO:
		return "items"
	elif color == ThemeColors.MSG_SYSTEM or color == ThemeColors.TEXT_MUTED:
		return "system"
	return "all"

func _refresh_message_display() -> void:
	message_log.clear()

	var last_turn_separator: int = -1
	for msg in messages:
		# Filter
		if _active_filter != "all" and msg.category != _active_filter and msg.category != "all":
			continue

		var colored_text := "[color=#%s]%s[/color]" % [msg.color.to_html(false), msg.text]
		message_log.append_text(colored_text + "\n")

	message_log.scroll_to_line(message_log.get_line_count())

func _on_filter_pressed(filter_name: String) -> void:
	_active_filter = filter_name
	# Update button states
	for btn in filter_container.get_children():
		if btn is Button:
			btn.button_pressed = (btn.text.to_lower() == filter_name)
	_refresh_message_display()

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_entity_damaged(entity: Entity, damage: int, damage_type: String, source: Entity) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		var source_name := source.entity_name if is_instance_valid(source) else "something"
		var msg := "The %s hits you for %d %s damage." % [source_name, damage, damage_type]
		_on_message_logged(msg, ThemeColors.DMG_PHYSICAL)
		update_player_stats(entity as Player)
	elif is_instance_valid(source) and source is Player:
		var msg := "You hit the %s for %d damage." % [entity.entity_name, damage]
		_on_message_logged(msg, ThemeColors.COMBAT_HIT)

func _on_entity_healed(entity: Entity, amount: int, _source: Entity) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		var msg := "You recover %d health." % amount
		_on_message_logged(msg, ThemeColors.MSG_HEAL)
		update_player_stats(entity as Player)

func _on_level_entered(depth: int) -> void:
	depth_label.text = "Depth:%d" % depth
	_on_message_logged("You descend to depth %d." % depth, ThemeColors.MSG_INFO)

func _on_round_completed(round_number: int) -> void:
	turn_label.text = "Turn:%d" % round_number
	_turn_count = round_number

	# Refresh minimap each turn
	refresh_minimap()

func _on_status_applied(entity: Entity, status_name: String, duration: int) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		_on_message_logged("You are afflicted with %s (%d turns)." % [status_name, duration], ThemeColors.MSG_WARNING)
		_update_status_icons(entity as Player)

func _on_status_removed(entity: Entity, status_name: String) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		_on_message_logged("The %s effect wears off." % status_name, ThemeColors.MSG_INFO)
		_update_status_icons(entity as Player)

func _update_status_icons(player: Player) -> void:
	# Clear existing icons
	for child in status_container.get_children():
		child.queue_free()

	if not player.status_fx:
		return

	for effect_id: StringName in player.status_fx.get_active_effects():
		var duration: int = player.status_fx.get_duration(effect_id)
		var status_name := String(effect_id)
		var status_color := ThemeColors.get_status_color(status_name)

		# Create pill-style status badge
		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", ThemeColors.create_status_pill(status_color))

		var icon := Label.new()
		icon.text = _get_status_abbreviation(status_name)
		icon.add_theme_color_override("font_color", status_color)
		icon.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
		icon.tooltip_text = "%s (%d turns)" % [status_name.capitalize(), duration]
		badge.add_child(icon)
		status_container.add_child(badge)

		# Pulse dangerous statuses
		if status_name.to_lower() in DANGER_STATUSES:
			_pulse_node(badge)

func _pulse_node(node: Control) -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(node, "modulate:a", 0.5, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)

func _get_status_abbreviation(status_name: String) -> String:
	match status_name.to_lower():
		"poisoned": return "PSN"
		"confused": return "CNF"
		"blind": return "BLD"
		"afraid": return "AFR"
		"slow": return "SLW"
		"fast": return "HST"
		"entranced": return "ENT"
		"stunned": return "STN"
		"cut": return "CUT"
		"burning": return "BRN"
		"rage": return "RGE"
		"darkened": return "DRK"
		"image": return "HAL"
		_: return status_name.substr(0, 3).to_upper()

# ============================================================================
# HELPERS
# ============================================================================

func _format_number(n: int) -> String:
	if n >= 10000:
		return "%d.%dk" % [n / 1000, (n % 1000) / 100]
	return str(n)
