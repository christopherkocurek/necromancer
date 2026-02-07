extends CanvasLayer
class_name HUD
## Diablo-inspired bottom action bar HUD with health/voice orbs,
## floating message log, minimap, stealth meter, and status pills.

# --- Action Bar (bottom) ---
var action_bar: PanelContainer
var health_orb: TextureRect          # Shader-driven liquid orb
var health_orb_frame: TextureRect    # Metal rim overlay
var health_label: Label              # "34/34" centered on orb
var voice_orb: TextureRect
var voice_orb_frame: TextureRect
var voice_label: Label
var xp_bar: ProgressBar
var xp_label: Label
var depth_label: Label
var turn_label: Label
var prot_label: Label
var stealth_label: Label
var hunger_label: Label              # Hunger state indicator
var status_container: HBoxContainer
var stats_container: HBoxContainer   # Center column stats
var quick_slots_container: HBoxContainer  # 6 equipment slot panels

# --- Floating Message Log ---
var message_panel: PanelContainer
var message_log: RichTextLabel
var filter_container: HBoxContainer
var _bottom_expanded: bool = false

# --- Minimap ---
var minimap: Minimap = null

# --- Stealth meter ---
var stealth_meter: ColorRect = null

# --- Ability Hotbar (1-4 quick-cast) ---
var hotbar_container: HBoxContainer = null
var hotbar_slots: Array[PanelContainer] = []
var _hotbar_ability_labels: Array[Label] = []
var _hotbar_cost_labels: Array[Label] = []
var _ability_system_ref: Node = null  # Set by main.gd for hotbar updates

# --- Low HP peril warning ---
var _last_hp_pct: float = 1.0
var _peril_shown: bool = false
var peril_flash: ColorRect = null
var peril_label: Label = null

# --- Message system ---
const MAX_MESSAGES := 200
var messages: Array[Dictionary] = []
var _active_filter: String = "all"
var _turn_count: int = 0

const DANGER_STATUSES := ["poisoned", "burning", "stunned", "confused"]
const EQUIP_SLOTS := ["weapon", "off_hand", "armor", "head", "light", "amulet"]

# Layout constants
const ACTION_BAR_HEIGHT := 140
const ORB_SIZE := 90
const ORB_FRAME_SIZE := 100
const MESSAGE_LOG_HEIGHT := 140
const MESSAGE_LOG_EXPANDED := 360

# Health/voice orb materials
var _health_material: ShaderMaterial = null
var _voice_material: ShaderMaterial = null

func _ready() -> void:
	layer = 10
	_build_action_bar()
	_build_ability_hotbar()
	_build_floating_message_log()
	_build_minimap()
	_build_stealth_meter()
	_build_peril_overlay()
	_connect_signals()

# ============================================================================
# BUILD: BOTTOM ACTION BAR
# ============================================================================

func _build_action_bar() -> void:
	action_bar = PanelContainer.new()
	action_bar.name = "ActionBar"

	# Use textured background if available, otherwise iron flat
	if ThemeColors.has_textures():
		action_bar.add_theme_stylebox_override("panel", ThemeColors.create_textured_panel("panel_iron", 4.0))
	else:
		var bar_style := ThemeColors.create_panel_stylebox(
			Color(ThemeColors.IRON_DARK.r, ThemeColors.IRON_DARK.g, ThemeColors.IRON_DARK.b, 0.95),
			ThemeColors.IRON_HIGHLIGHT, 2, 0
		)
		bar_style.border_width_bottom = 0
		bar_style.border_width_left = 0
		bar_style.border_width_right = 0
		bar_style.border_width_top = 2
		action_bar.add_theme_stylebox_override("panel", bar_style)

	action_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	action_bar.offset_top = -ACTION_BAR_HEIGHT
	add_child(action_bar)

	# Main horizontal layout: [HealthOrb] [CenterStats] [VoiceOrb]
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_bar.add_child(hbox)

	# --- Health Orb (left) ---
	var health_container := _build_orb(true)
	hbox.add_child(health_container)

	# --- Center Column ---
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 2)
	hbox.add_child(center)

	# Row 1: Stats (Depth, Turn, Prot, Stealth, Status pills)
	stats_container = HBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 16)
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(stats_container)

	# Depth
	depth_label = Label.new()
	depth_label.text = "Depth 1"
	ThemeColors.apply_body_font(depth_label, ThemeColors.FONT_SIZE_LARGE)
	depth_label.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
	stats_container.add_child(depth_label)

	# Turn
	turn_label = Label.new()
	turn_label.text = "Turn 0"
	ThemeColors.apply_body_font(turn_label, ThemeColors.FONT_SIZE_BODY)
	turn_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	stats_container.add_child(turn_label)

	# Protection
	prot_label = Label.new()
	prot_label.text = ""
	ThemeColors.apply_body_font(prot_label, ThemeColors.FONT_SIZE_BODY)
	prot_label.add_theme_color_override("font_color", ThemeColors.SECONDARY)
	stats_container.add_child(prot_label)

	# Stealth
	stealth_label = Label.new()
	stealth_label.text = ""
	ThemeColors.apply_body_font(stealth_label, ThemeColors.FONT_SIZE_BODY)
	stats_container.add_child(stealth_label)

	# Hunger indicator
	hunger_label = Label.new()
	hunger_label.text = ""
	ThemeColors.apply_body_font(hunger_label, ThemeColors.FONT_SIZE_BODY)
	stats_container.add_child(hunger_label)

	# Status pills (right side of stats row)
	var status_spacer := Control.new()
	status_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_container.add_child(status_spacer)

	status_container = HBoxContainer.new()
	status_container.add_theme_constant_override("separation", 4)
	stats_container.add_child(status_container)

	# Row 2: Quick slots (6 equipment icons)
	quick_slots_container = HBoxContainer.new()
	quick_slots_container.add_theme_constant_override("separation", 4)
	quick_slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(quick_slots_container)
	var quick_slots := quick_slots_container

	for slot_name in EQUIP_SLOTS:
		var slot := PanelContainer.new()
		slot.name = "Slot_%s" % slot_name
		slot.custom_minimum_size = Vector2(45, 45)
		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
		else:
			slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
				ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
			))
		slot.tooltip_text = slot_name.capitalize().replace("_", " ")
		quick_slots.add_child(slot)

	# Row 3: XP bar (thin ornate bar across bottom)
	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 8)
	center.add_child(xp_row)

	var xp_icon := Label.new()
	xp_icon.text = "XP"
	ThemeColors.apply_body_font(xp_icon, ThemeColors.FONT_SIZE_HINT)
	xp_icon.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)
	xp_row.add_child(xp_icon)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(280, 14)
	xp_bar.max_value = 100
	xp_bar.value = 0
	xp_bar.show_percentage = false
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Style the XP bar with gold tint
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = ThemeColors.IRON_SHADOW
	xp_bg.border_color = ThemeColors.IRON_HIGHLIGHT
	xp_bg.border_width_left = 1
	xp_bg.border_width_right = 1
	xp_bg.border_width_top = 1
	xp_bg.border_width_bottom = 1
	xp_bg.corner_radius_top_left = 2
	xp_bg.corner_radius_top_right = 2
	xp_bg.corner_radius_bottom_left = 2
	xp_bg.corner_radius_bottom_right = 2
	xp_bar.add_theme_stylebox_override("background", xp_bg)
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = ThemeColors.GOLD_DIM
	xp_fill.corner_radius_top_left = 2
	xp_fill.corner_radius_top_right = 2
	xp_fill.corner_radius_bottom_left = 2
	xp_fill.corner_radius_bottom_right = 2
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	xp_row.add_child(xp_bar)

	xp_label = Label.new()
	xp_label.text = "0"
	ThemeColors.apply_body_font(xp_label, ThemeColors.FONT_SIZE_HINT)
	xp_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	xp_row.add_child(xp_label)

	# --- Voice Orb (right) ---
	var voice_container := _build_orb(false)
	hbox.add_child(voice_container)

func _build_orb(is_health: bool) -> Control:
	var container := CenterContainer.new()
	container.custom_minimum_size = Vector2(ORB_FRAME_SIZE + 8, ORB_FRAME_SIZE + 8)

	# Orb liquid (shader-driven ColorRect inside a mask)
	var orb_liquid := ColorRect.new()
	orb_liquid.custom_minimum_size = Vector2(ORB_SIZE, ORB_SIZE)
	orb_liquid.size = Vector2(ORB_SIZE, ORB_SIZE)
	orb_liquid.color = ThemeColors.BLOOD_DARK if is_health else ThemeColors.SPIRIT_DARK

	# Apply orb shader if available
	var mat: ShaderMaterial = ThemeColors.create_orb_material(is_health)
	if mat:
		orb_liquid.material = mat
		if is_health:
			_health_material = mat
		else:
			_voice_material = mat

	container.add_child(orb_liquid)

	if is_health:
		health_orb = TextureRect.new()
		health_orb.custom_minimum_size = Vector2(ORB_SIZE, ORB_SIZE)
	else:
		voice_orb = TextureRect.new()
		voice_orb.custom_minimum_size = Vector2(ORB_SIZE, ORB_SIZE)

	# Orb frame overlay
	var frame := TextureRect.new()
	frame.custom_minimum_size = Vector2(ORB_FRAME_SIZE, ORB_FRAME_SIZE)
	var frame_tex: Texture2D = ThemeColors.get_texture("orb_frame_watcher")
	if not frame_tex:
		frame_tex = ThemeColors.get_texture("orb_frame")
	if frame_tex:
		frame.texture = frame_tex
		frame.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(frame)

	if is_health:
		health_orb_frame = frame
	else:
		voice_orb_frame = frame

	# Value label centered on orb
	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ThemeColors.apply_heading_font(value_label, ThemeColors.FONT_SIZE_LARGE)
	value_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	# Use a shadow for readability against the liquid
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	value_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	container.add_child(value_label)

	if is_health:
		health_label = value_label
		health_label.text = "34"
	else:
		voice_label = value_label
		voice_label.text = "10"

	return container

# ============================================================================
# BUILD: ABILITY HOTBAR (1-4 quick-cast slots)
# ============================================================================

func _build_ability_hotbar() -> void:
	hotbar_container = HBoxContainer.new()
	hotbar_container.name = "AbilityHotbar"
	hotbar_container.add_theme_constant_override("separation", 4)

	# Position above the action bar, left-aligned
	hotbar_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hotbar_container.offset_left = 12
	hotbar_container.offset_top = -(ACTION_BAR_HEIGHT + 58)
	hotbar_container.offset_bottom = -(ACTION_BAR_HEIGHT + 4)
	hotbar_container.offset_right = 232  # 4 slots x 54px + gaps

	hotbar_slots.clear()
	_hotbar_ability_labels.clear()
	_hotbar_cost_labels.clear()

	for i in range(4):
		var slot: PanelContainer = PanelContainer.new()
		slot.name = "HotbarSlot_%d" % (i + 1)
		slot.custom_minimum_size = Vector2(52, 50)

		# Empty slot styling
		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
		else:
			slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
				ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
			))

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 0)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Number label (1-4)
		var num_label: Label = Label.new()
		num_label.text = str(i + 1)
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeColors.apply_body_font(num_label, ThemeColors.FONT_SIZE_HINT)
		num_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)
		vbox.add_child(num_label)

		# Ability abbreviation
		var ability_label: Label = Label.new()
		ability_label.name = "AbilityName"
		ability_label.text = "---"
		ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeColors.apply_body_font(ability_label, ThemeColors.FONT_SIZE_HINT)
		ability_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
		vbox.add_child(ability_label)
		_hotbar_ability_labels.append(ability_label)

		# Voice cost
		var cost_label: Label = Label.new()
		cost_label.name = "CostLabel"
		cost_label.text = ""
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeColors.apply_body_font(cost_label, ThemeColors.FONT_SIZE_HINT)
		cost_label.add_theme_color_override("font_color", ThemeColors.SPIRIT_BRIGHT)
		vbox.add_child(cost_label)
		_hotbar_cost_labels.append(cost_label)

		slot.add_child(vbox)
		hotbar_container.add_child(slot)
		hotbar_slots.append(slot)

	add_child(hotbar_container)

func update_hotbar(player_ref: Player, ability_sys: Node) -> void:
	if not hotbar_container or hotbar_slots.is_empty():
		return
	if not player_ref:
		return

	# Check if player has any abilities hotkeyed - hide hotbar if all empty
	var any_bound: bool = false
	for slot_id: int in player_ref.ability_hotkeys:
		if slot_id >= 0:
			any_bound = true
			break
	hotbar_container.visible = any_bound

	if not any_bound:
		return

	for i in range(4):
		if i >= hotbar_slots.size():
			break
		var ability_id: int = player_ref.ability_hotkeys[i]
		var slot: PanelContainer = hotbar_slots[i]
		var ab_label: Label = _hotbar_ability_labels[i]
		var cost_label: Label = _hotbar_cost_labels[i]

		if ability_id < 0:
			# Empty slot
			ab_label.text = "---"
			ab_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
			cost_label.text = ""
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
			else:
				slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
					ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
				))
			slot.tooltip_text = "Slot %d: empty (V menu, Shift+%d to bind)" % [i + 1, i + 1]
		else:
			# Bound ability
			var ab_name: String = _get_hotbar_ability_name(ability_id)
			var abbr: String = ab_name.substr(0, 4) if ab_name.length() > 4 else ab_name
			ab_label.text = abbr

			var cost: int = 0
			var can_use: bool = false
			if ability_sys and ability_sys.has_method("get_effective_voice_cost"):
				cost = ability_sys.get_effective_voice_cost(ability_id)
			if ability_sys and ability_sys.has_method("can_use_ability"):
				var check: Dictionary = ability_sys.can_use_ability(ability_id)
				can_use = check.can_use

			cost_label.text = "%dv" % cost if cost > 0 else ""

			if can_use:
				ab_label.add_theme_color_override("font_color", ThemeColors.ABILITY_LEARNED)
				if ThemeColors.has_textures():
					slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("selected"))
				else:
					slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
						ThemeColors.IRON_MID, ThemeColors.GOLD_DIM
					))
			else:
				ab_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
				if ThemeColors.has_textures():
					slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
				else:
					slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
						ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
					))

			slot.tooltip_text = "%s (%d voice)" % [ab_name, cost] if cost > 0 else ab_name

## Get a short display name for ability in hotbar
func _get_hotbar_ability_name(ability_id: int) -> String:
	# Match the ability IDs from AbilitySystem.LoreAbility
	match ability_id:
		140: return "Cmd"    # Word of Command
		141: return "Btl"    # Lore of Battle
		142: return "Mem"    # Deep Memory
		143: return "Open"   # Word of Opening
		144: return "Slnc"   # Lore of Silence
		145: return "Herb"   # Herbcraft
		146: return "Shut"   # Word of Shutting
		147: return "Lght"   # Inner Light
		148: return "Ddly"   # Deadly Lore
		149: return "Endr"   # Lore of Endurance
		150: return "Slp"    # Lore of Sleep
		151: return "Mstr"   # Word of Mastery
		152: return "Dev"    # Device Mastery
		153: return "Grce"   # Grace
		154: return "Bnsh"   # Song of Banishment
		_: return "???"

# ============================================================================
# BUILD: FLOATING MESSAGE LOG
# ============================================================================

func _build_floating_message_log() -> void:
	message_panel = PanelContainer.new()
	message_panel.name = "MessageLog"

	# Semi-transparent iron panel floating above action bar
	var msg_style := ThemeColors.create_panel_stylebox(
		Color(ThemeColors.IRON_DARK.r, ThemeColors.IRON_DARK.g, ThemeColors.IRON_DARK.b, 0.75),
		Color(ThemeColors.IRON_HIGHLIGHT.r, ThemeColors.IRON_HIGHLIGHT.g, ThemeColors.IRON_HIGHLIGHT.b, 0.4),
		1, 4
	)
	message_panel.add_theme_stylebox_override("panel", msg_style)

	# Anchor above the action bar
	message_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	message_panel.offset_top = -(ACTION_BAR_HEIGHT + MESSAGE_LOG_HEIGHT)
	message_panel.offset_bottom = -ACTION_BAR_HEIGHT
	# Slight side margins
	message_panel.offset_left = 8
	message_panel.offset_right = -8
	add_child(message_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	message_panel.add_child(vbox)

	# Filter bar
	filter_container = HBoxContainer.new()
	filter_container.add_theme_constant_override("separation", 4)
	vbox.add_child(filter_container)

	for filter_name in ["All", "Combat", "Items", "System"]:
		var btn := Button.new()
		btn.text = filter_name
		btn.toggle_mode = true
		btn.button_pressed = (filter_name == "All")
		ThemeColors.apply_button_theme(btn)
		btn.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
		btn.pressed.connect(_on_filter_pressed.bind(filter_name.to_lower()))
		filter_container.add_child(btn)

	# Expand hint
	var expand_hint := Label.new()
	expand_hint.text = "[Tab]"
	ThemeColors.apply_body_font(expand_hint, ThemeColors.FONT_SIZE_HINT)
	expand_hint.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
	expand_hint.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	filter_container.add_child(expand_hint)

	# Message log
	message_log = RichTextLabel.new()
	message_log.name = "MessageLogText"
	message_log.bbcode_enabled = true
	message_log.scroll_following = true
	message_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ThemeColors.apply_rich_body_font(message_log, ThemeColors.FONT_SIZE_BODY)
	vbox.add_child(message_log)

# ============================================================================
# BUILD: MINIMAP
# ============================================================================

func _build_minimap() -> void:
	minimap = Minimap.new()
	minimap.name = "Minimap"
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -168
	minimap.offset_top = 8
	minimap.offset_right = -8
	minimap.offset_bottom = 88
	minimap.visible = false
	add_child(minimap)

# ============================================================================
# BUILD: STEALTH METER
# ============================================================================

func _build_stealth_meter() -> void:
	stealth_meter = ColorRect.new()
	stealth_meter.name = "StealthMeter"
	stealth_meter.custom_minimum_size = Vector2(12, 140)
	stealth_meter.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	stealth_meter.offset_left = 4
	stealth_meter.offset_top = -70
	stealth_meter.offset_right = 16
	stealth_meter.offset_bottom = 70
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

	# Health orb
	var health_pct := float(player.current_health) / float(maxi(player.max_health, 1))
	health_label.text = "%d" % player.current_health
	if _health_material:
		_health_material.set_shader_parameter("fill_level", health_pct)
		_health_material.set_shader_parameter("is_critical", health_pct < 0.15)
	# Color the label based on health
	var hp_color: Color = ThemeColors.get_health_color(health_pct)
	health_label.add_theme_color_override("font_color", hp_color)

	# Peril warning check
	_check_peril_warning(player.current_health, player.max_health)

	# XP
	xp_label.text = _format_number(player.xp_available)

	# Voice orb
	var show_voice: bool = player.max_voice > 0
	voice_orb_frame.visible = show_voice
	voice_label.visible = show_voice
	if show_voice:
		var voice_pct := float(player.voice_charges) / float(maxi(player.max_voice, 1))
		voice_label.text = "%d" % player.voice_charges
		if _voice_material:
			_voice_material.set_shader_parameter("fill_level", voice_pct)

	# Protection dice
	if player.protection_dice > 0 and player.protection_sides > 0:
		prot_label.text = "[%dd%d]" % [player.protection_dice, player.protection_sides]
	else:
		prot_label.text = ""

	# Stealth indicator
	if player.stealth_mode:
		stealth_label.text = "STEALTH"
		stealth_label.add_theme_color_override("font_color", ThemeColors.MSG_STEALTH)
	else:
		stealth_label.text = ""

	# Hunger indicator
	_update_hunger_display(player)

	# Stealth meter
	_update_stealth_meter(player)

	# Equipment quick-view
	_update_equip_icons(player)

	# Ability hotbar
	update_hotbar(player, _ability_system_ref)

func _update_equip_icons(player: Player) -> void:
	if not quick_slots_container:
		return

	for i in range(EQUIP_SLOTS.size()):
		if i >= quick_slots_container.get_child_count():
			break
		var slot: PanelContainer = quick_slots_container.get_child(i)
		var slot_name: String = EQUIP_SLOTS[i]
		var item = player.equipment.get(slot_name)

		if item != null:
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("selected"))
			else:
				slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
					ThemeColors.IRON_MID, ThemeColors.GOLD_DIM
				))
			var item_name: String = GameManager.get_item_display_name(item)
			slot.tooltip_text = "%s: %s" % [slot_name.capitalize().replace("_", " "), item_name]
		else:
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
			else:
				slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
					ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
				))
			slot.tooltip_text = "%s: empty" % slot_name.capitalize().replace("_", " ")

func _update_stealth_meter(player: Player) -> void:
	if not stealth_meter:
		return

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

func _update_hunger_display(player: Player) -> void:
	if not hunger_label:
		return
	var state: String = player.get_hunger_state()
	match state:
		"well_fed", "normal":
			hunger_label.text = ""
		"hungry":
			hunger_label.text = "Hungry"
			hunger_label.add_theme_color_override("font_color", ThemeColors.MSG_WARNING)
		"famished":
			hunger_label.text = "Famished!"
			hunger_label.add_theme_color_override("font_color", ThemeColors.DMG_FIRE)
		"starving":
			hunger_label.text = "STARVING!"
			hunger_label.add_theme_color_override("font_color", ThemeColors.MSG_ERROR)
			# Blink effect for starving
			if not hunger_label.has_meta("starving_blink"):
				hunger_label.set_meta("starving_blink", true)
				var tween := create_tween()
				tween.set_loops()
				tween.tween_property(hunger_label, "modulate:a", 0.3, 0.4).set_ease(Tween.EASE_IN_OUT)
				tween.tween_property(hunger_label, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_IN_OUT)
	# Stop blinking when no longer starving
	if state != "starving" and hunger_label.has_meta("starving_blink"):
		hunger_label.remove_meta("starving_blink")
		hunger_label.modulate.a = 1.0

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
# PERIL WARNING (Sauron senses your peril)
# ============================================================================

func _build_peril_overlay() -> void:
	# Red flash overlay
	peril_flash = ColorRect.new()
	peril_flash.color = Color(0.8, 0.0, 0.0, 0.0)
	peril_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	peril_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	peril_flash.visible = false
	add_child(peril_flash)

	# Warning label
	peril_label = Label.new()
	peril_label.text = "SAURON SENSES YOUR PERIL..."
	peril_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	peril_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	peril_label.set_anchors_preset(Control.PRESET_CENTER)
	peril_label.add_theme_font_size_override("font_size", 36)
	peril_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
	peril_label.modulate.a = 0.0
	peril_label.visible = false
	add_child(peril_label)

func _check_peril_warning(current_hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return
	var hp_pct: float = float(current_hp) / float(max_hp)

	# Crossing below 10% from above
	if hp_pct < 0.1 and _last_hp_pct >= 0.1 and current_hp > 0:
		_show_peril_warning()

	# Reset when healing above 10%
	if hp_pct >= 0.1:
		_peril_shown = false

	_last_hp_pct = hp_pct

func _show_peril_warning() -> void:
	if _peril_shown:
		return
	_peril_shown = true

	# Depth-based peril tiers
	var depth: int = GameManager.current_depth
	var message: String
	var color: Color
	var font_size: int
	var flash_intensity: float

	if depth <= 6:
		message = "A malevolent presence watches from below..."
		color = Color(0.6, 0.6, 0.6)  # gray
		font_size = 28
		flash_intensity = 0.1
	elif depth <= 12:
		message = "A dark power stirs in the deep..."
		color = Color(0.6, 0.2, 0.8)  # purple
		font_size = 30
		flash_intensity = 0.2
	elif depth <= 15:
		message = "The Necromancer senses your weakness..."
		color = Color(1.0, 0.6, 0.2)  # orange
		font_size = 32
		flash_intensity = 0.3
	elif depth <= 18:
		message = "SAURON SENSES YOUR PERIL!"
		color = Color(1.0, 0.2, 0.1)  # red
		font_size = 36
		flash_intensity = 0.4
	else:  # depth 19-20
		message = "THE DARK LORD'S GAZE FALLS UPON YOU!"
		color = Color(1.0, 0.85, 0.2)  # gold
		font_size = 40
		flash_intensity = 0.5

	# Flash overlay with depth-scaled intensity
	peril_flash.visible = true
	peril_flash.color = Color(color.r, color.g, color.b, 0.0)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(peril_flash, "color:a", flash_intensity, 0.15)
	flash_tween.tween_property(peril_flash, "color:a", 0.0, 1.0)
	flash_tween.tween_callback(func(): peril_flash.visible = false)

	# Label with depth-based styling
	peril_label.text = message
	peril_label.add_theme_font_size_override("font_size", font_size)
	peril_label.add_theme_color_override("font_color", color)
	peril_label.visible = true
	peril_label.modulate.a = 0.0
	var label_tween: Tween = create_tween()
	label_tween.tween_property(peril_label, "modulate:a", 1.0, 0.2)
	label_tween.tween_interval(1.5)

	# Depth 19-20: pulsing gold effect before fade
	if depth >= 19:
		for i in range(3):
			label_tween.tween_property(peril_label, "modulate:a", 0.6, 0.3).set_ease(Tween.EASE_IN_OUT)
			label_tween.tween_property(peril_label, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_IN_OUT)

	label_tween.tween_property(peril_label, "modulate:a", 0.0, 1.0)
	label_tween.tween_callback(func(): peril_label.visible = false)

	# Log message
	EventBus.message_logged.emit(message, color)

# ============================================================================
# BOTTOM BAR EXPAND/COLLAPSE
# ============================================================================

func toggle_bottom_bar() -> void:
	_bottom_expanded = not _bottom_expanded
	var target_top: float
	var target_bottom: float
	if _bottom_expanded:
		target_top = -(ACTION_BAR_HEIGHT + MESSAGE_LOG_EXPANDED)
		target_bottom = -ACTION_BAR_HEIGHT
	else:
		target_top = -(ACTION_BAR_HEIGHT + MESSAGE_LOG_HEIGHT)
		target_bottom = -ACTION_BAR_HEIGHT
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(message_panel, "offset_top", target_top, 0.2)

# ============================================================================
# MESSAGES
# ============================================================================

func _on_message_logged(text: String, color: Color) -> void:
	var category: String = _categorize_message(color)
	messages.append({"text": text, "color": color, "category": category})

	while messages.size() > MAX_MESSAGES:
		messages.pop_front()

	_refresh_message_display()

func _categorize_message(color: Color) -> String:
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

	for msg in messages:
		if _active_filter != "all" and msg.category != _active_filter and msg.category != "all":
			continue
		var colored_text := "[color=#%s]%s[/color]" % [msg.color.to_html(false), msg.text]
		message_log.append_text(colored_text + "\n")

	message_log.scroll_to_line(message_log.get_line_count())

func _on_filter_pressed(filter_name: String) -> void:
	_active_filter = filter_name
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
	depth_label.text = "Depth %d" % depth
	_on_message_logged("You descend to depth %d." % depth, ThemeColors.MSG_INFO)

func _on_round_completed(round_number: int) -> void:
	turn_label.text = "Turn %d" % round_number
	_turn_count = round_number
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
	for child in status_container.get_children():
		child.queue_free()

	if not player.status_fx:
		return

	for effect_id: StringName in player.status_fx.get_active_effects():
		var duration: int = player.status_fx.get_duration(effect_id)
		var status_name := String(effect_id)
		var status_color := ThemeColors.get_status_color(status_name)

		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", ThemeColors.create_status_pill(status_color))

		var icon := Label.new()
		icon.text = _get_status_abbreviation(status_name)
		icon.add_theme_color_override("font_color", status_color)
		ThemeColors.apply_body_font(icon, ThemeColors.FONT_SIZE_HINT)
		icon.add_theme_color_override("font_color", status_color)
		icon.tooltip_text = "%s (%d turns)" % [status_name.capitalize(), duration]
		badge.add_child(icon)
		status_container.add_child(badge)

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
