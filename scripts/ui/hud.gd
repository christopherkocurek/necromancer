extends CanvasLayer
class_name HUD
## Diablo-inspired bottom action bar HUD with health/voice orbs,
## floating message log, minimap, stealth meter, and status pills.

signal utility_slot_activated(slot_index: int)
signal utility_slot_cleared(slot_index: int)
signal utility_equip_drop_requested(slot_index: int, equip_slot_name: String)
signal utility_slot_bind_requested(slot_index: int)
signal ability_slot_cast_requested(slot_index: int)
signal ability_slot_cleared(slot_index: int)
signal ability_slot_bind_requested(slot_index: int)

const StatusMetadata = preload("res://scripts/systems/status_metadata.gd")

# --- Action Bar (bottom) ---
var action_bar: PanelContainer
var health_orb: TextureRect          # Shader-driven liquid orb
var health_orb_frame: TextureRect    # Metal rim overlay
var health_label: Label              # "34/34" centered on orb
var voice_orb: TextureRect
var voice_orb_frame: TextureRect
var voice_label: Label
var xp_label: Label
var xp_gem_icon: TextureRect
var depth_label: Label
var turn_label: Label
var prot_label: Label
var stealth_label: Label
var song_label: Label                # Active song indicator
var hunger_label: Label              # Hunger state indicator
var build_label: Label               # Optional archetype dashboard (normal mode only)
var mode_label: Label                # Runtime mode/assist policy indicator
var pursuit_label: Label             # Floor-wide pursuit pressure meter
var goals_label: Label               # Run goals summary
var threat_container: HBoxContainer  # Always-on threat summary with minimize toggle
var threat_label: Label
var threat_toggle: Button
var _threat_minimized: bool = false
var status_container: HBoxContainer
var stance_container: VBoxContainer
var stats_container: HBoxContainer   # Center column stats
var quick_slots_container: HBoxContainer  # 6 equipment slot panels
var utility_slots_container: HBoxContainer
var utility_slots: Array[PanelContainer] = []
var _utility_icon_nodes: Array[TextureRect] = []
var _utility_index_labels: Array[Label] = []

# --- Floating Message Log ---
var message_panel: PanelContainer
var message_log: RichTextLabel
var filter_container: HBoxContainer
var _bottom_expanded: bool = false

# --- Minimap ---
var minimap: Minimap = null
var minimap_frame: PanelContainer = null
var minimap_center: CenterContainer = null
var _minimap_expanded: bool = false

# --- Stealth meter ---
var stealth_meter: ColorRect = null

# --- Ability Gems (8 slots) ---
var hotbar_container: HBoxContainer = null
var hotbar_slots: Array[PanelContainer] = []
var _hotbar_key_labels: Array[Label] = []
var _hotbar_icon_nodes: Array[TextureRect] = []
var _hotbar_ability_labels: Array[Label] = []
var _hotbar_cost_labels: Array[Label] = []
var _hotbar_state_labels: Array[Label] = []
var _ability_system_ref: Node = null  # Set by main.gd for hotbar updates
var _hotbar_ability_ids: Array[int] = []
var hotbar_hint_label: Label = null

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
var _stance_signature: String = ""
var _threat_signature: String = ""
var _stance_icon_tileset: Texture2D = null
var _ui_icon_tileset: Texture2D = null
var _equip_icon_nodes: Dictionary = {}  # slot_name -> TextureRect
var _player_ref: Player = null
var _goal_banner: PanelContainer = null
var _goal_banner_label: Label = null
var _status_signature: String = ""

const DANGER_STATUSES := ["poisoned", "burning", "stunned", "confused"]
const EQUIP_SLOTS := ["weapon", "off_hand", "armor", "head", "light", "amulet"]

# Layout constants
const ACTION_BAR_HEIGHT := 156
const ORB_SIZE := 90
const ORB_FRAME_SIZE := 100
const MESSAGE_LOG_HEIGHT := 140
const MESSAGE_LOG_EXPANDED := 360
const HUD_ITEM_ICON_SIZE := 28
const MINIMAP_COMPACT_SIZE: Vector2 = Vector2(240, 120)
const MINIMAP_EXPANDED_SIZE: Vector2 = Vector2(480, 240)
const MINIMAP_PADDING: int = 8
const MINIMAP_MARGIN_TOP: int = 8
const MINIMAP_MARGIN_RIGHT: int = 8
const ICON_TILESET_CANDIDATE_PATHS: Array[String] = [
	"res://assets/sprites/necromancer_dcss_tileset.png",
	"res://assets/sprites/necromancer_dcss_tileset_pre_outer_pits_v2.png",
	"res://assets/sprites/64x64_necromancer.png",
]

# Health/voice orb materials
var _health_material: ShaderMaterial = null
var _voice_material: ShaderMaterial = null

func _ready() -> void:
	layer = 10
	_build_action_bar()
	_build_stance_overlay()
	_build_ability_hotbar()
	_build_floating_message_log()
	_build_goal_banner()
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
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.custom_minimum_size = Vector2(760, 0)
	center.add_theme_constant_override("separation", 3)
	hbox.add_child(center)

	# Row 1: Stats (Depth, Turn, Prot, Stealth, Status pills)
	stats_container = HBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 10)
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
	ThemeColors.apply_body_font(turn_label, ThemeColors.FONT_SIZE_HINT)
	turn_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	stats_container.add_child(turn_label)

	# Protection
	prot_label = Label.new()
	prot_label.text = ""
	ThemeColors.apply_body_font(prot_label, ThemeColors.FONT_SIZE_HINT)
	prot_label.add_theme_color_override("font_color", ThemeColors.SECONDARY)
	stats_container.add_child(prot_label)

	# Stealth
	stealth_label = Label.new()
	stealth_label.text = ""
	ThemeColors.apply_body_font(stealth_label, ThemeColors.FONT_SIZE_HINT)
	stats_container.add_child(stealth_label)

	# Song indicator
	song_label = Label.new()
	song_label.text = ""
	ThemeColors.apply_body_font(song_label, ThemeColors.FONT_SIZE_HINT)
	stats_container.add_child(song_label)

	# Hunger indicator
	hunger_label = Label.new()
	hunger_label.text = ""
	ThemeColors.apply_body_font(hunger_label, ThemeColors.FONT_SIZE_HINT)
	stats_container.add_child(hunger_label)

	build_label = Label.new()
	build_label.text = ""
	ThemeColors.apply_body_font(build_label, ThemeColors.FONT_SIZE_HINT)
	build_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	stats_container.add_child(build_label)

	mode_label = Label.new()
	mode_label.text = ""
	ThemeColors.apply_body_font(mode_label, ThemeColors.FONT_SIZE_HINT)
	mode_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	mode_label.visible = false  # User-facing request: remove Normal/ON mode line from HUD.
	stats_container.add_child(mode_label)

	goals_label = Label.new()
	goals_label.text = ""
	ThemeColors.apply_body_font(goals_label, ThemeColors.FONT_SIZE_HINT - 1)
	goals_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)
	goals_label.clip_text = true
	goals_label.custom_minimum_size = Vector2(220, 0)
	stats_container.add_child(goals_label)

	# Threat summary (always-on, minimizable)
	threat_container = HBoxContainer.new()
	threat_container.add_theme_constant_override("separation", 4)
	stats_container.add_child(threat_container)

	threat_label = Label.new()
	threat_label.text = "Threat: --"
	ThemeColors.apply_body_font(threat_label, ThemeColors.FONT_SIZE_HINT)
	threat_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	threat_label.clip_text = true
	threat_label.custom_minimum_size = Vector2(270, 0)
	threat_container.add_child(threat_label)

	threat_toggle = Button.new()
	threat_toggle.custom_minimum_size = Vector2(24, 24)
	threat_toggle.icon = _create_circle_tile_icon(Vector2i(15, 10), ThemeColors.TEXT_MUTED)
	threat_toggle.flat = true
	var toggle_style := StyleBoxFlat.new()
	toggle_style.bg_color = Color(0.08, 0.08, 0.10, 0.75)
	toggle_style.border_color = ThemeColors.IRON_HIGHLIGHT
	toggle_style.border_width_left = 1
	toggle_style.border_width_right = 1
	toggle_style.border_width_top = 1
	toggle_style.border_width_bottom = 1
	toggle_style.corner_radius_top_left = 12
	toggle_style.corner_radius_top_right = 12
	toggle_style.corner_radius_bottom_left = 12
	toggle_style.corner_radius_bottom_right = 12
	threat_toggle.add_theme_stylebox_override("normal", toggle_style)
	threat_toggle.add_theme_stylebox_override("hover", toggle_style)
	threat_toggle.add_theme_stylebox_override("pressed", toggle_style)
	threat_toggle.tooltip_text = "Minimize or expand threat summary"
	threat_toggle.pressed.connect(_toggle_threat_summary)
	threat_container.add_child(threat_toggle)

	# Pursuit meter line (floor alertness pressure)
	pursuit_label = Label.new()
	pursuit_label.text = "Pursuit: Calm"
	ThemeColors.apply_body_font(pursuit_label, ThemeColors.FONT_SIZE_HINT)
	pursuit_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	pursuit_label.clip_text = true
	pursuit_label.custom_minimum_size = Vector2(220, 0)
	stats_container.add_child(pursuit_label)

	# Dedicated status row to avoid icon clipping when top labels are dense.
	status_container = HBoxContainer.new()
	status_container.add_theme_constant_override("separation", 2)
	status_container.alignment = BoxContainer.ALIGNMENT_END
	status_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(status_container)

	# Row 2: Quick slots (6 equipment icons)
	quick_slots_container = HBoxContainer.new()
	quick_slots_container.add_theme_constant_override("separation", 4)
	quick_slots_container.alignment = BoxContainer.ALIGNMENT_END
	quick_slots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(quick_slots_container)
	var quick_slots := quick_slots_container

	for slot_name in EQUIP_SLOTS:
		var slot := PanelContainer.new()
		slot.name = "Slot_%s" % slot_name
		slot.custom_minimum_size = Vector2(40, 40)
		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
		else:
			slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
				ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
			))
		slot.tooltip_text = slot_name.capitalize().replace("_", " ")
		slot.set_drag_forwarding(
			func(_position: Vector2) -> Variant:
				return null,
			func(_position: Vector2, data: Variant) -> bool:
				return _can_drop_utility_to_equip(slot_name, data),
			func(_position: Vector2, data: Variant) -> void:
				_drop_utility_to_equip(slot_name, data)
		)

		var icon_rect := TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(HUD_ITEM_ICON_SIZE, HUD_ITEM_ICON_SIZE)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.visible = false
		slot.add_child(icon_rect)
		_equip_icon_nodes[slot_name] = icon_rect

		quick_slots.add_child(slot)

	# Row 3: Utility belt (loadable inventory slots)
	utility_slots_container = HBoxContainer.new()
	utility_slots_container.add_theme_constant_override("separation", 4)
	utility_slots_container.alignment = BoxContainer.ALIGNMENT_END
	utility_slots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(utility_slots_container)

	utility_slots.clear()
	_utility_icon_nodes.clear()
	_utility_index_labels.clear()
	for i in range(6):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(40, 40)
		slot.tooltip_text = "Utility %d (bind in inventory with Shift+%d)" % [i + 1, i + 1]
		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
		else:
			slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
				ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
			))
		slot.gui_input.connect(_on_utility_slot_gui_input.bind(i))
		slot.set_drag_forwarding(
			func(_position: Vector2) -> Variant:
				return _get_utility_drag_data(i),
			func(_position: Vector2, _data: Variant) -> bool:
				return false,
			func(_position: Vector2, _data: Variant) -> void:
				pass
		)

		var icon_rect := TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(HUD_ITEM_ICON_SIZE, HUD_ITEM_ICON_SIZE)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.visible = false
		slot.add_child(icon_rect)

		var idx_label := Label.new()
		idx_label.text = str(i + 1)
		ThemeColors.apply_body_font(idx_label, ThemeColors.FONT_SIZE_HINT - 2)
		idx_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)
		idx_label.position = Vector2(2, 0)
		idx_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(idx_label)

		utility_slots_container.add_child(slot)
		utility_slots.append(slot)
		_utility_icon_nodes.append(icon_rect)
		_utility_index_labels.append(idx_label)

	# Row 4: XP gem (brightness reflects XP bank)
	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 8)
	xp_row.alignment = BoxContainer.ALIGNMENT_END
	xp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(xp_row)

	xp_gem_icon = TextureRect.new()
	xp_gem_icon.custom_minimum_size = Vector2(32, 32)
	xp_gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xp_gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	xp_gem_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	xp_gem_icon.texture = _create_circle_tile_icon(Vector2i(5, 11), ThemeColors.GOLD_DIM)
	if xp_gem_icon.texture == null:
		xp_gem_icon.texture = _create_plain_ring_icon(ThemeColors.GOLD_DIM)
	xp_row.add_child(xp_gem_icon)

	xp_label = Label.new()
	xp_label.text = "0\nXP"
	ThemeColors.apply_heading_font(xp_label, ThemeColors.FONT_SIZE_HINT)
	xp_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_row.add_child(xp_label)

	# --- Voice Orb (right) ---
	var voice_container := _build_orb(false)
	hbox.add_child(voice_container)

func _build_stance_overlay() -> void:
	# Separate overlay so container layout in action_bar cannot reposition these cards.
	# Right-center keeps them visible without covering orb/log critical info.
	stance_container = VBoxContainer.new()
	stance_container.name = "StanceOverlay"
	stance_container.add_theme_constant_override("separation", 8)
	stance_container.alignment = BoxContainer.ALIGNMENT_END
	stance_container.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	stance_container.offset_left = -230
	stance_container.offset_right = -16
	stance_container.offset_top = -92
	stance_container.offset_bottom = 92
	add_child(stance_container)

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
# BUILD: ABILITY GEMS (8 slots)
# ============================================================================

func _build_ability_hotbar() -> void:
	hotbar_container = HBoxContainer.new()
	hotbar_container.name = "AbilityHotbar"
	hotbar_container.add_theme_constant_override("separation", 4)

	# Position above the action bar, left-aligned
	hotbar_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hotbar_container.offset_left = 218
	hotbar_container.offset_top = -(ACTION_BAR_HEIGHT - 42)
	hotbar_container.offset_bottom = -(ACTION_BAR_HEIGHT - 96)
	hotbar_container.offset_right = 544  # + left-side hint rail

	# Left-side bind/cast legend for gem bar.
	hotbar_hint_label = Label.new()
	hotbar_hint_label.name = "HotbarHint"
	hotbar_hint_label.text = "GEMS\n1-8 CAST\nL-BIND/CAST\nR-CLEAR"
	hotbar_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ThemeColors.apply_body_font(hotbar_hint_label, ThemeColors.FONT_SIZE_HINT - 1)
	hotbar_hint_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	hotbar_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hotbar_hint_label.offset_left = 122
	hotbar_hint_label.offset_top = -(ACTION_BAR_HEIGHT - 40)
	hotbar_hint_label.offset_bottom = -(ACTION_BAR_HEIGHT - 98)
	hotbar_hint_label.offset_right = 104
	add_child(hotbar_hint_label)

	hotbar_slots.clear()
	_hotbar_key_labels.clear()
	_hotbar_icon_nodes.clear()
	_hotbar_ability_labels.clear()
	_hotbar_cost_labels.clear()
	_hotbar_state_labels.clear()
	_hotbar_ability_ids.clear()

	for i in range(8):
		var slot: PanelContainer = PanelContainer.new()
		slot.name = "HotbarSlot_%d" % (i + 1)
		slot.custom_minimum_size = Vector2(52, 52)

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

		# Number label (1-8 keyboard casts).
		var num_label: Label = Label.new()
		num_label.text = str(i + 1)
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeColors.apply_body_font(num_label, ThemeColors.FONT_SIZE_HINT)
		num_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)
		num_label.visible = false
		vbox.add_child(num_label)
		_hotbar_key_labels.append(num_label)

		# Gem icon (tile icon from atlas)
		var icon_rect := TextureRect.new()
		icon_rect.name = "IconSigil"
		icon_rect.custom_minimum_size = Vector2(34, 34)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(icon_rect)
		_hotbar_icon_nodes.append(icon_rect)

		# Ability abbreviation
		var ability_label: Label = Label.new()
		ability_label.name = "AbilityName"
		ability_label.text = "EMPTY"
		ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeColors.apply_body_font(ability_label, ThemeColors.FONT_SIZE_HINT)
		ability_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
		vbox.add_child(ability_label)
		_hotbar_ability_labels.append(ability_label)

		# Footer row: voice cost (left) + state badge (right)
		var footer: HBoxContainer = HBoxContainer.new()
		footer.alignment = BoxContainer.ALIGNMENT_CENTER
		footer.add_theme_constant_override("separation", 3)
		vbox.add_child(footer)

		var cost_label: Label = Label.new()
		cost_label.name = "CostLabel"
		cost_label.text = ""
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		ThemeColors.apply_body_font(cost_label, ThemeColors.FONT_SIZE_HINT)
		cost_label.add_theme_color_override("font_color", ThemeColors.SPIRIT_BRIGHT)
		footer.add_child(cost_label)
		_hotbar_cost_labels.append(cost_label)

		var state_label: Label = Label.new()
		state_label.name = "StateLabel"
		state_label.text = "BIND"
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ThemeColors.apply_body_font(state_label, int(ThemeColors.FONT_SIZE_HINT * 0.5))
		state_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
		footer.add_child(state_label)
		_hotbar_state_labels.append(state_label)

		slot.add_child(vbox)
		hotbar_container.add_child(slot)
		hotbar_slots.append(slot)
		_hotbar_ability_ids.append(-1)
		slot.gui_input.connect(_on_hotbar_slot_gui_input.bind(i))

	add_child(hotbar_container)

func update_hotbar(player_ref: Player, ability_sys: Node) -> void:
	if not hotbar_container or hotbar_slots.is_empty():
		return
	if not player_ref:
		return

	hotbar_container.visible = true

	for i in range(hotbar_slots.size()):
		if i >= hotbar_slots.size():
			break
		var ability_id: int = player_ref.ability_hotkeys[i] if i < player_ref.ability_hotkeys.size() else -1
		_hotbar_ability_ids[i] = ability_id
		var slot: PanelContainer = hotbar_slots[i]
		var key_label: Label = _hotbar_key_labels[i]
		var icon_rect: TextureRect = _hotbar_icon_nodes[i]
		var ab_label: Label = _hotbar_ability_labels[i]
		var cost_label: Label = _hotbar_cost_labels[i]
		var state_label: Label = _hotbar_state_labels[i]
		key_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)

		if ability_id < 0:
			# Empty slot
			icon_rect.texture = null
			icon_rect.modulate = ThemeColors.TEXT_DISABLED
			ab_label.text = "EMPTY"
			ab_label.add_theme_color_override("font_color", ThemeColors.TEXT_DISABLED)
			cost_label.text = ""
			state_label.text = "BIND"
			state_label.add_theme_color_override("font_color", ThemeColors.MSG_INFO)
			_set_hotbar_node_anim(icon_rect, "idle")
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
			else:
				slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
					ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
				))
			slot.tooltip_text = "Gem %d: empty | Left click: bind | Right click: clear" % [i + 1]
		else:
			# Bound ability
			var ab_name: String = _get_hotbar_ability_name(ability_id, player_ref)
			var abbr: String = ab_name.substr(0, 4) if ab_name.length() > 4 else ab_name
			icon_rect.texture = _get_hotbar_icon_texture(ability_id)
			ab_label.text = abbr

			var cost: int = 0
			var can_use: bool = false
			var reason: String = ""
			var cooldown_turns: int = 0
			var needs_target: bool = false
			if player_ref and player_ref.has_method("get_hotbar_ability_cost"):
				cost = int(player_ref.get_hotbar_ability_cost(ability_id, ability_sys))
			if player_ref and player_ref.has_method("can_use_hotbar_ability"):
				var check: Dictionary = player_ref.can_use_hotbar_ability(ability_id, ability_sys)
				can_use = bool(check.get("can_use", false))
				reason = str(check.get("reason", ""))
				cooldown_turns = _extract_cooldown_turns(reason)
			if player_ref and player_ref.has_method("is_hotbar_ability_targeted"):
				needs_target = bool(player_ref.is_hotbar_ability_targeted(ability_id, ability_sys))

			cost_label.text = "%dv" % cost if cost > 0 else ""

			if can_use:
				icon_rect.modulate = ThemeColors.GOLD_BRIGHT
				ab_label.add_theme_color_override("font_color", ThemeColors.ABILITY_LEARNED)
				var is_active_state: bool = false
				if player_ref and player_ref.has_method("is_hotbar_ability_active"):
					is_active_state = bool(player_ref.is_hotbar_ability_active(ability_id))
				if is_active_state:
					state_label.text = "ACTV"
					state_label.add_theme_color_override("font_color", ThemeColors.MSG_WARNING)
				else:
					state_label.text = "TGT" if needs_target else "RDY"
					state_label.add_theme_color_override("font_color", ThemeColors.ABILITY_LEARNED)
				_set_hotbar_node_anim(icon_rect, "target" if needs_target else "ready")
				if ThemeColors.has_textures():
					slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("selected"))
				else:
					slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
						ThemeColors.IRON_MID, ThemeColors.GOLD_DIM
					))
			else:
				icon_rect.modulate = ThemeColors.TEXT_MUTED
				ab_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
				if cooldown_turns > 0:
					state_label.text = "CD %d" % cooldown_turns
					state_label.add_theme_color_override("font_color", ThemeColors.MSG_WARNING)
					_set_hotbar_node_anim(icon_rect, "cooldown")
				elif reason.begins_with("Already"):
					state_label.text = "ON"
					state_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
					_set_hotbar_node_anim(icon_rect, "idle")
				elif reason.begins_with("Need"):
					state_label.text = "RES"
					state_label.add_theme_color_override("font_color", ThemeColors.MSG_WARNING)
					_set_hotbar_node_anim(icon_rect, "idle")
				else:
					state_label.text = "NO"
					state_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
					_set_hotbar_node_anim(icon_rect, "idle")
				if ThemeColors.has_textures():
					slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
				else:
					var border_col: Color = ThemeColors.MSG_WARNING if cooldown_turns > 0 else ThemeColors.IRON_HIGHLIGHT
					slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(ThemeColors.IRON_SHADOW, border_col))

			var use_text: String = "Ready" if can_use else ("Unavailable: %s" % reason)
			var cast_hint: String = "Key %d" % (i + 1)
			slot.tooltip_text = "%s | %s | %s%s | Left: cast Right: clear" % [
				ab_name,
				cast_hint,
				use_text,
				(" | %d voice" % cost) if cost > 0 else ""
			]

## Get a short display name for ability in hotbar
func _get_hotbar_ability_name(ability_id: int, player_ref: Player = null) -> String:
	if player_ref and player_ref.has_method("get_hotbar_ability_display_name") and ability_id >= 1000:
		return player_ref.get_hotbar_ability_display_name(ability_id)
	# Match the ability IDs from AbilitySystem.LoreAbility (v4: IDs 140-159)
	match ability_id:
		140: return "Hide"   # Lore of Hidden Ways
		141: return "Open"   # Word of Opening
		142: return "Mem"    # Deep Memory
		143: return "Herb"   # Herbcraft
		144: return "Name"   # Lore of Naming
		145: return "Lght"   # Light of the Eldar
		146: return "Cmd"    # Word of Command
		147: return "Free"   # Song of Freedom
		148: return "Lor"    # Song of Lorien
		149: return "Endr"   # Lore of Endurance
		150: return "Bnsh"   # Song of Banishment
		151: return "Dom"    # Word of Domination
		152: return "Aule"   # Song of Aule
		153: return "Heal"   # Song of Healing
		154: return "Ward"   # Word of Warding
		155: return "Auth"   # Word of Authority
		156: return "Unmk"   # Word of Unmaking
		157: return "Thm"    # Mastery of Themes
		158: return "Grce"   # Grace
		159: return "Tree"   # Song of the Trees
		_: return "???"

func _get_hotbar_icon_texture(ability_id: int) -> Texture2D:
	if not _ensure_ui_icon_tileset():
		return _create_circle_tile_icon(Vector2i(9, 0), ThemeColors.GOLD_DIM)

	var coords: Vector2i = _get_hotbar_icon_coords(ability_id)
	var tex_size: Vector2i = _ui_icon_tileset.get_size()
	var tile_px: int = 64
	if coords.x < 0 or coords.y < 0 or ((coords.x + 1) * tile_px > tex_size.x) or ((coords.y + 1) * tile_px > tex_size.y):
		coords = _get_hotbar_fallback_icon_coords(ability_id)
		if coords.x < 0 or coords.y < 0:
			return _create_circle_tile_icon(Vector2i(9, 0), ThemeColors.GOLD_DIM)
		if ((coords.x + 1) * tile_px > tex_size.x) or ((coords.y + 1) * tile_px > tex_size.y):
			return _create_circle_tile_icon(Vector2i(9, 0), ThemeColors.GOLD_DIM)

	var atlas := AtlasTexture.new()
	atlas.atlas = _ui_icon_tileset
	atlas.region = Rect2(coords.x * 64, coords.y * 64, 64, 64)
	return atlas

func _get_hotbar_icon_coords(ability_id: int) -> Vector2i:
	match ability_id:
		# Core gem abilities
		Player.GEM_DEFENSIVE_STANCE: return Vector2i(21, 11)  # tower shield
		Player.GEM_READY_PARRY: return Vector2i(29, 11)       # Rohirrim blade
		Player.GEM_MARK_QUARRY: return Vector2i(23, 12)       # arrow
		Player.GEM_EXPOSE_WEAKNESS: return Vector2i(20, 13)   # ring/gaze motif
		Player.GEM_EXPLOIT_OPENING: return Vector2i(24, 11)   # ranger knife
		Player.GEM_DISGUISE: return Vector2i(17, 12)          # shadow cloak
		Player.GEM_CIRCULAR_GUARD: return Vector2i(22, 11)    # mithril shield
		Player.GEM_SWIFT_STRIKES: return Vector2i(26, 11)     # sylvan blade
		Player.GEM_CRIPPLING_SHOT: return Vector2i(24, 12)    # ammo shot
		Player.GEM_KEEN_SENSES: return Vector2i(12, 13)       # vigilant eye
		Player.GEM_CURSE_BREAKING: return Vector2i(12, 14)    # freedom/light motif
		Player.GEM_POWER_STANCE: return Vector2i(8, 12)       # dwarven hammer
		Player.GEM_FINESSE_STANCE: return Vector2i(23, 11)    # nimble blade
		Player.GEM_VANISH: return Vector2i(19, 12)            # bat-fell
		Player.GEM_SPRINTING: return Vector2i(28, 12)         # boots
		# Lore abilities
		140: return Vector2i(19, 12)  # Hidden Ways
		141: return Vector2i(0, 2)    # Word of Opening (door)
		142: return Vector2i(5, 17)   # Deep Memory (note)
		143: return Vector2i(5, 16)   # Herbcraft
		144: return Vector2i(15, 14)  # Lore of Naming
		145: return Vector2i(17, 13)  # Light of Eldar
		146: return Vector2i(4, 15)   # Word of Command (challenge/horn)
		147: return Vector2i(11, 14)  # Song of Freedom
		148: return Vector2i(19, 14)  # Song of Lorien
		149: return Vector2i(3, 14)   # Lore of Endurance
		150: return Vector2i(22, 14)  # Song of Banishment
		151: return Vector2i(24, 14)  # Word of Domination
		152: return Vector2i(8, 12)   # Song of Aule
		153: return Vector2i(14, 16)  # Song of Healing
		154: return Vector2i(21, 14)  # Word of Warding
		155: return Vector2i(20, 14)  # Word of Authority
		156: return Vector2i(3, 15)   # Word of Unmaking
		157: return Vector2i(21, 14)  # Mastery of Themes
		158: return Vector2i(7, 13)   # Grace
		159: return Vector2i(5, 14)   # Song of the Trees
		_: return Vector2i(-1, -1)

func _get_hotbar_fallback_icon_coords(ability_id: int) -> Vector2i:
	# Guarantee a visible tile-based placeholder for all bindable abilities.
	if ability_id >= 1000:
		return Vector2i(9, 0)   # gem/crystal placeholder
	if ability_id >= 140 and ability_id <= 200:
		return Vector2i(5, 17)  # lore sigil placeholder
	return Vector2i(9, 0)

func _set_hotbar_node_anim(node: CanvasItem, anim_key: String) -> void:
	if node == null:
		return
	var current_key: String = str(node.get_meta("hotbar_anim_key")) if node.has_meta("hotbar_anim_key") else ""
	if current_key == anim_key:
		return
	node.set_meta("hotbar_anim_key", anim_key)
	if node.has_meta("hotbar_anim_tween"):
		var old_tween: Variant = node.get_meta("hotbar_anim_tween")
		if old_tween is Tween and is_instance_valid(old_tween):
			(old_tween as Tween).kill()
		node.remove_meta("hotbar_anim_tween")
	node.modulate.a = 1.0
	if AccessibilityManager.reduced_motion:
		return
	match anim_key:
		"ready":
			var tween := create_tween()
			node.set_meta("hotbar_anim_tween", tween)
			tween.set_loops()
			tween.tween_property(node, "modulate:a", 0.72, 0.45).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(node, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_IN_OUT)
		"target":
			var tween := create_tween()
			node.set_meta("hotbar_anim_tween", tween)
			tween.set_loops()
			tween.tween_property(node, "modulate:a", 0.6, 0.32).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(node, "modulate:a", 1.0, 0.32).set_ease(Tween.EASE_IN_OUT)
		"cooldown":
			var tween := create_tween()
			node.set_meta("hotbar_anim_tween", tween)
			tween.set_loops()
			tween.tween_property(node, "modulate:a", 0.45, 0.62).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(node, "modulate:a", 0.9, 0.62).set_ease(Tween.EASE_IN_OUT)

func _extract_cooldown_turns(reason: String) -> int:
	if reason.is_empty():
		return 0
	var open_i: int = reason.find("(")
	var close_i: int = reason.find(")")
	if open_i < 0 or close_i <= open_i:
		return 0
	var inside: String = reason.substr(open_i + 1, close_i - open_i - 1)
	var parts: PackedStringArray = inside.split(" ", false)
	if parts.is_empty():
		return 0
	return maxi(0, int(parts[0]))

func _on_hotbar_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			ability_slot_cleared.emit(slot_index)
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var ability_id: int = -1
			if slot_index >= 0 and slot_index < _hotbar_ability_ids.size():
				ability_id = _hotbar_ability_ids[slot_index]
			if ability_id < 0:
				ability_slot_bind_requested.emit(slot_index)
			else:
				ability_slot_cast_requested.emit(slot_index)

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
	minimap_frame = PanelContainer.new()
	minimap_frame.name = "MinimapFrame"
	minimap_frame.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var frame_style: StyleBoxFlat = ThemeColors.create_panel_stylebox(
		Color(0.0, 0.0, 0.0, 0.35), Color(0.0, 0.0, 0.0, 0.35), 0, 10
	)
	minimap_frame.add_theme_stylebox_override("panel", frame_style)
	add_child(minimap_frame)

	minimap_center = CenterContainer.new()
	minimap_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	minimap_center.offset_left = MINIMAP_PADDING
	minimap_center.offset_top = MINIMAP_PADDING
	minimap_center.offset_right = -MINIMAP_PADDING
	minimap_center.offset_bottom = -MINIMAP_PADDING
	minimap_frame.add_child(minimap_center)

	minimap = Minimap.new()
	minimap.name = "Minimap"
	minimap.tooltip_text = "Click to expand/collapse minimap"
	minimap.minimap_clicked.connect(_on_minimap_clicked)
	minimap.visible = false
	minimap_center.add_child(minimap)

	_apply_minimap_layout()

func _apply_minimap_layout() -> void:
	if minimap == null or minimap_frame == null:
		return
	var minimap_size: Vector2 = MINIMAP_EXPANDED_SIZE if _minimap_expanded else MINIMAP_COMPACT_SIZE
	minimap.set_display_size(minimap_size)
	var frame_w: int = int(minimap_size.x) + MINIMAP_PADDING * 2
	var frame_h: int = int(minimap_size.y) + MINIMAP_PADDING * 2
	minimap_frame.custom_minimum_size = Vector2(frame_w, frame_h)
	minimap_frame.offset_top = MINIMAP_MARGIN_TOP
	minimap_frame.offset_right = -MINIMAP_MARGIN_RIGHT
	minimap_frame.offset_left = minimap_frame.offset_right - frame_w
	minimap_frame.offset_bottom = minimap_frame.offset_top + frame_h

func _on_minimap_clicked() -> void:
	_minimap_expanded = not _minimap_expanded
	_apply_minimap_layout()

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

func _build_goal_banner() -> void:
	_goal_banner = PanelContainer.new()
	_goal_banner.visible = false
	_goal_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_goal_banner.offset_top = 18
	_goal_banner.offset_left = 0
	_goal_banner.offset_right = 0
	_goal_banner.custom_minimum_size = Vector2(560, 44)
	_goal_banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := ThemeColors.create_panel_stylebox(
		Color(ThemeColors.IRON_DARK.r, ThemeColors.IRON_DARK.g, ThemeColors.IRON_DARK.b, 0.92),
		ThemeColors.GOLD_BRIGHT, 2, 8
	)
	_goal_banner.add_theme_stylebox_override("panel", style)

	_goal_banner_label = Label.new()
	_goal_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeColors.apply_heading_font(_goal_banner_label, ThemeColors.FONT_SIZE_LARGE)
	_goal_banner_label.text = "Goal Complete"
	_goal_banner.add_child(_goal_banner_label)
	add_child(_goal_banner)

func _connect_signals() -> void:
	EventBus.message_logged.connect(_on_message_logged)
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.entity_healed.connect(_on_entity_healed)
	EventBus.level_entered.connect(_on_level_entered)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.status_removed.connect(_on_status_removed)
	EventBus.status_tick.connect(_on_status_tick)
	EventBus.run_goal_completed.connect(_on_run_goal_completed)

# ============================================================================
# PLAYER STATS UPDATE
# ============================================================================

func update_player_stats(player: Player) -> void:
	if not player:
		return
	_player_ref = player

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
	xp_label.text = "%s\nXP" % _format_number(player.xp_available)
	_update_xp_gem(player.xp_available)
	_refresh_status_icons_if_needed(player)

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

	# Stealth / Detection eye indicator
	_update_detection_indicator(player)
	_update_threat_summary(player)
	_update_pursuit_meter()
	_update_build_identity(player)
	_update_mode_indicator()
	_update_goals_line()

	# Song indicator
	if song_label:
		if player.active_song_id >= 0 and _ability_system_ref:
			song_label.text = "♪ %s" % _ability_system_ref.get_active_song_name()
			song_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)
		else:
			song_label.text = ""

	# Hunger indicator
	_update_hunger_display(player)

	# Stealth meter
	_update_stealth_meter(player)

	# Equipment quick-view
	_update_equip_icons(player)
	_update_utility_slots(player)

	# Active melee stance/parry indicators
	_update_combat_stance_gems(player)

	# Ability hotbar
	update_hotbar(player, _ability_system_ref)

func _update_xp_gem(xp_value: int) -> void:
	if xp_gem_icon == null:
		return
	# Stronger brightness ramp so XP gain is visibly obvious.
	var t: float = clampf(float(xp_value) / 3000.0, 0.0, 1.0)
	var brightness: float = lerpf(0.54, 4.95, t)  # ~3x previous intensity range
	var glow: Color = Color(
		ThemeColors.GOLD_WARM.r * brightness,
		ThemeColors.GOLD_WARM.g * brightness,
		ThemeColors.GOLD_WARM.b * brightness,
		1.0
	)
	xp_gem_icon.modulate = glow
	if t >= 0.85:
		if not xp_gem_icon.has_meta("xp_pulse"):
			xp_gem_icon.set_meta("xp_pulse", true)
			var tween := create_tween()
			tween.set_loops()
			tween.tween_property(xp_gem_icon, "modulate:a", 0.55, 0.45).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(xp_gem_icon, "modulate:a", 1.0, 0.55).set_ease(Tween.EASE_IN_OUT)
	elif xp_gem_icon.has_meta("xp_pulse"):
		xp_gem_icon.remove_meta("xp_pulse")
		xp_gem_icon.modulate.a = 1.0

func _refresh_status_icons_if_needed(player: Player) -> void:
	if player == null:
		return
	var signature: String = ""
	if player.status_fx != null:
		var parts: PackedStringArray = []
		for effect_id: StringName in player.status_fx.get_active_effects():
			parts.append("%s:%d" % [String(effect_id), player.status_fx.get_duration(effect_id)])
		parts.sort()
		signature = "|".join(parts)
	if signature == _status_signature:
		return
	_status_signature = signature
	_update_status_icons(player)

func _update_equip_icons(player: Player) -> void:
	if not quick_slots_container:
		return

	for i in range(EQUIP_SLOTS.size()):
		if i >= quick_slots_container.get_child_count():
			break
		var slot: PanelContainer = quick_slots_container.get_child(i)
		var slot_name: String = EQUIP_SLOTS[i]
		var item = player.equipment.get(slot_name)
		var icon_rect: TextureRect = _equip_icon_nodes.get(slot_name, null)

		if item != null:
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("selected"))
			else:
				slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
					ThemeColors.IRON_MID, ThemeColors.GOLD_DIM
				))
			var item_name: String = GameManager.get_item_display_name(item)
			slot.tooltip_text = "%s: %s" % [slot_name.capitalize().replace("_", " "), item_name]
			if icon_rect:
				icon_rect.texture = _get_hud_item_icon(item)
				icon_rect.visible = (icon_rect.texture != null)
		else:
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
			else:
				slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
					ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
				))
			slot.tooltip_text = "%s: empty" % slot_name.capitalize().replace("_", " ")
			if icon_rect:
				icon_rect.texture = null
				icon_rect.visible = false

func _update_utility_slots(player: Player) -> void:
	if utility_slots.is_empty():
		return
	for i in range(mini(utility_slots.size(), player.utility_hotkeys.size())):
		var slot: PanelContainer = utility_slots[i]
		var icon_rect: TextureRect = _utility_icon_nodes[i]
		var descriptor: Dictionary = player.get_utility_descriptor(i)
		var item = player.resolve_utility_item(i)
		if descriptor.is_empty() or item == null:
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("empty"))
			else:
				slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
					ThemeColors.IRON_SHADOW, ThemeColors.IRON_HIGHLIGHT
				))
			icon_rect.texture = null
			icon_rect.visible = false
			slot.tooltip_text = "Utility %d (empty)" % (i + 1)
			continue

		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("panel", ThemeColors.create_textured_slot("selected"))
		else:
			slot.add_theme_stylebox_override("panel", ThemeColors.create_slot_stylebox(
				ThemeColors.IRON_MID, ThemeColors.GOLD_DIM
			))
		icon_rect.texture = _get_hud_item_icon(item)
		icon_rect.visible = icon_rect.texture != null
		slot.tooltip_text = "Utility %d: %s\nLeft click: use/equip  Right click: clear\nDrag to equip slot above." % [
			i + 1, GameManager.get_item_display_name(item)
		]

func _on_utility_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if _player_ref and _player_ref.get_utility_descriptor(slot_index).is_empty():
			utility_slot_bind_requested.emit(slot_index)
		else:
			utility_slot_activated.emit(slot_index)
		get_viewport().set_input_as_handled()
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		utility_slot_cleared.emit(slot_index)
		get_viewport().set_input_as_handled()

func _get_utility_drag_data(slot_index: int) -> Variant:
	if _player_ref == null:
		return null
	var desc: Dictionary = _player_ref.get_utility_descriptor(slot_index)
	var item = _player_ref.resolve_utility_item(slot_index)
	if desc.is_empty() or item == null:
		return null
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(28, 28)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.texture = _get_hud_item_icon(item)
	return {"type": "utility_item", "slot_index": slot_index}

func _can_drop_utility_to_equip(slot_name: String, data: Variant) -> bool:
	if data == null or not (data is Dictionary):
		return false
	var payload: Dictionary = data
	if str(payload.get("type", "")) != "utility_item":
		return false
	if _player_ref == null:
		return false
	var slot_index: int = int(payload.get("slot_index", -1))
	var item = _player_ref.resolve_utility_item(slot_index)
	if item == null or not ("tval" in item):
		return false
	if not Constants.TVAL_TO_SLOT.has(int(item.tval)):
		return false
	var expected_slot_key: String = _player_ref._equip_slot_id_to_key(int(Constants.TVAL_TO_SLOT[int(item.tval)]))
	return expected_slot_key == slot_name

func _drop_utility_to_equip(slot_name: String, data: Variant) -> void:
	if not _can_drop_utility_to_equip(slot_name, data):
		return
	var payload: Dictionary = data
	var slot_index: int = int(payload.get("slot_index", -1))
	utility_equip_drop_requested.emit(slot_index, slot_name)

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

func _update_combat_stance_gems(player: Player) -> void:
	if not stance_container:
		return

	if not player or not player.has_method("get_combat_stance_indicators"):
		if _stance_signature.is_empty():
			return
		_stance_signature = ""
		for child in stance_container.get_children():
			child.queue_free()
		return

	var indicators: Array[Dictionary] = player.get_combat_stance_indicators()
	var new_signature: String = JSON.stringify(indicators)
	if new_signature == _stance_signature:
		return
	_stance_signature = new_signature

	for child in stance_container.get_children():
		child.queue_free()

	for info in indicators:
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(180, 48)

		var active_turns: int = int(info.get("active_turns", 0))
		var cooldown_turns: int = int(info.get("cooldown_turns", 0))
		var state: String = "active" if active_turns > 0 else "cooldown"
		var style: StyleBoxFlat
		match state:
			"cooldown":
				style = ThemeColors.create_panel_stylebox(
					Color(ThemeColors.IRON_SHADOW.r, ThemeColors.IRON_SHADOW.g, ThemeColors.IRON_SHADOW.b, 0.8),
					ThemeColors.IRON_HIGHLIGHT, 1, 4
				)
			_:
				style = ThemeColors.create_panel_stylebox(
					Color(ThemeColors.SECONDARY.r, ThemeColors.SECONDARY.g, ThemeColors.SECONDARY.b, 0.16),
					ThemeColors.SECONDARY, 1, 4
				)
		badge.add_theme_stylebox_override("panel", style)

		# Layout: [Icon 36x36] [Text Column]
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		badge.add_child(hbox)

		var icon_tex: Texture2D = _get_stance_icon_texture(str(info.get("icon", "")))
		if icon_tex:
			var icon_rect := TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(36, 36)
			icon_rect.texture = icon_tex
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hbox.add_child(icon_rect)

		var text_col := VBoxContainer.new()
		text_col.add_theme_constant_override("separation", 0)
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_col)

		# Title + bonus on one line
		var title := Label.new()
		var bonus_text: String = str(info.get("bonus_text", ""))
		var title_text: String = str(info.get("title", "Buff"))
		title.text = "%s %s" % [bonus_text, title_text] if bonus_text else title_text
		ThemeColors.apply_body_font(title, ThemeColors.FONT_SIZE_BODY)
		title.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
		text_col.add_child(title)

		# State line: "Active 3t" or "Recharge 5t"
		var state_label := Label.new()
		if active_turns > 0:
			state_label.text = "%st" % active_turns
			state_label.add_theme_color_override("font_color", ThemeColors.SECONDARY)
		else:
			state_label.text = "CD %st" % cooldown_turns
			state_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)
		ThemeColors.apply_body_font(state_label, ThemeColors.FONT_SIZE_HINT)
		text_col.add_child(state_label)

		badge.tooltip_text = "%s\n%s\nActive: %d\nCD: %d" % [
			title_text,
			bonus_text,
			active_turns,
			cooldown_turns
		]

		stance_container.add_child(badge)

func _get_stance_icon_texture(icon_id: String) -> Texture2D:
	if not _ensure_stance_icon_tileset():
		return null

	var coords := Vector2i(-1, -1)
	match icon_id:
		"parry":
			coords = Vector2i(28, 11)  # Longsword
		"defend":
			coords = Vector2i(21, 11)  # Tower shield
		"circle":
			coords = Vector2i(22, 11)  # Circular guard shield
		"swift":
			coords = Vector2i(26, 11)  # Swift strikes blade
		"disguise":
			coords = Vector2i(17, 12)  # Cloak
		"hunt":
			coords = Vector2i(24, 11)  # Bow icon for quarry hunt state
		_:
			return null

	var atlas := AtlasTexture.new()
	atlas.atlas = _stance_icon_tileset
	atlas.region = Rect2(coords.x * 64, coords.y * 64, 64, 64)
	return atlas

# ============================================================================
# DETECTION EYE INDICATOR
# ============================================================================

## Detection eye indicator — replaces simple "STEALTH" text
## Shows: (.) HIDDEN, (-) CAUTIOUS, (O) DETECTED/COMBAT with color coding
func _update_detection_indicator(player: Player) -> void:
	if not stealth_label:
		return

	var max_alertness: int = Constants.ALERTNESS_MIN
	var any_visible_monster: bool = false

	if GameManager.current_level:
		for entity in GameManager.current_level.entities:
			if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
				continue
			if not GameManager.current_level.is_tile_visible(entity.grid_position):
				continue
			any_visible_monster = true
			if "alertness" in entity and entity.alertness > max_alertness:
				max_alertness = entity.alertness

	# Show indicator when in stealth mode OR when monsters are visible
	if not player.stealth_mode and not any_visible_monster:
		stealth_label.text = ""
		return

	# Determine eye state based on max alertness of visible monsters
	var eye_text: String
	var eye_color: Color

	if max_alertness >= Constants.ALERTNESS_ALERT:
		# DETECTED — enemy knows where you are
		eye_text = "(O) SEEN" if _is_compact_hud() else "(O) DETECTED"
		eye_color = ThemeColors.ALERT_DETECTED
	elif max_alertness >= Constants.ALERTNESS_UNWARY:
		# CAUTIOUS — enemy is searching
		eye_text = "(-) CAUT" if _is_compact_hud() else "(-) CAUTIOUS"
		eye_color = ThemeColors.ALERT_CAUTIOUS
	else:
		# HIDDEN — safe or stealth mode active
		if player.stealth_mode:
			eye_text = "(.) HIDDEN"
		else:
			eye_text = "(.) SAFE"
		eye_color = ThemeColors.ALERT_SAFE

	stealth_label.text = eye_text
	stealth_label.add_theme_color_override("font_color", eye_color)

func _toggle_threat_summary() -> void:
	_threat_minimized = not _threat_minimized
	if threat_label:
		threat_label.visible = not _threat_minimized
	if threat_toggle:
		var coords: Vector2i = Vector2i(9, 10) if _threat_minimized else Vector2i(15, 10)
		var color: Color = ThemeColors.TEXT_SECONDARY if _threat_minimized else ThemeColors.TEXT_MUTED
		threat_toggle.icon = _create_circle_tile_icon(coords, color)

func _update_threat_summary(player: Player) -> void:
	if not threat_label or not player:
		return
	if not AccessibilityManager.is_assist_enabled():
		if threat_container:
			threat_container.visible = false
		_clear_world_intent_markers()
		return
	if threat_container and not threat_container.visible:
		threat_container.visible = true
	if not GameManager.current_level:
		threat_label.text = "Threat: --"
		threat_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
		_clear_world_intent_markers()
		return

	var visible_count: int = 0
	var ready_count: int = 0
	var caster_count: int = 0
	var severe_count: int = 0

	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		if not GameManager.current_level.is_tile_visible(entity.grid_position):
			continue
		visible_count += 1

		var intent: Dictionary = {}
		if entity.has_method("get_intent_readout_for_viewer"):
			intent = entity.get_intent_readout_for_viewer(player)

		var eta: int = int(intent.get("eta", 1))
		var targets_player: bool = bool(intent.get("targets_player", false))
		var intent_type: String = str(intent.get("type", "uncertain"))

		if targets_player and eta <= 0:
			ready_count += 1
			if intent_type == "cast" or intent_type == "ranged":
				severe_count += 1
		if intent_type == "cast" or intent_type == "ranged":
			caster_count += 1

	if visible_count <= 0:
		threat_label.text = "Threat: Clear"
		threat_label.add_theme_color_override("font_color", ThemeColors.ALERT_SAFE)
		return

	var threat_level: String = "Low"
	var threat_color: Color = ThemeColors.ALERT_CAUTIOUS
	if severe_count > 0:
		threat_level = "Severe"
		threat_color = ThemeColors.MSG_ERROR
	elif ready_count >= 2:
		threat_level = "High"
		threat_color = ThemeColors.MSG_WARNING
	elif ready_count >= 1 or caster_count >= 1:
		threat_level = "Elevated"
		threat_color = ThemeColors.GOLD_DIM

	if AccessibilityManager.assist_level == "basic":
		threat_label.text = "Threat: %s" % threat_level
	else:
		threat_label.text = "Threat: %s I%d C%d V%d" % [
			threat_level, ready_count, caster_count, visible_count
		]
	threat_label.add_theme_color_override("font_color", threat_color)
	var signature: String = "%s:%d:%d:%d" % [threat_level, ready_count, caster_count, visible_count]
	if signature != _threat_signature:
		_threat_signature = signature
		if EventBus:
			EventBus.threat_summary_updated.emit(threat_level, ready_count, caster_count, visible_count)

func _update_world_intent_markers(player: Player) -> void:
	if not GameManager.current_level:
		return
	if not AccessibilityManager.is_assist_enabled():
		_clear_world_intent_markers()
		return
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		if not GameManager.current_level.is_tile_visible(entity.grid_position):
			if entity.has_method("clear_intent_marker"):
				entity.clear_intent_marker()
			continue
		if entity.has_method("get_intent_readout_for_viewer") and entity.has_method("set_intent_marker_from_readout"):
			var intent: Dictionary = entity.get_intent_readout_for_viewer(player)
			entity.set_intent_marker_from_readout(intent)

func _clear_world_intent_markers() -> void:
	if not GameManager.current_level:
		return
	for entity in GameManager.current_level.entities:
		if is_instance_valid(entity) and entity is Monster and entity.has_method("clear_intent_marker"):
			entity.clear_intent_marker()

func _update_pursuit_meter() -> void:
	if not pursuit_label:
		return
	if not GameManager.current_level:
		pursuit_label.text = "Pursuit Pressure: --"
		pursuit_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
		return
	var alert: int = GameManager.current_level.get_floor_alertness() if GameManager.current_level.has_method("get_floor_alertness") else 0
	var active_contact: bool = _has_visible_hostiles()
	var player_hidden: bool = false
	if GameManager.player and GameManager.player is Player:
		player_hidden = bool((GameManager.player as Player).stealth_mode)

	if not active_contact:
		if alert > 0:
			pursuit_label.text = "Pursuit: Dormant"
			pursuit_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
		else:
			pursuit_label.text = "Pursuit: Calm"
			pursuit_label.add_theme_color_override("font_color", ThemeColors.ALERT_SAFE)
		return

	var tier: String = "Calm"
	var color: Color = ThemeColors.ALERT_SAFE
	if alert >= 40:
		tier = "Relentless"
		color = ThemeColors.MSG_ERROR
	elif alert >= 25:
		tier = "Hunted"
		color = ThemeColors.MSG_WARNING
	elif alert >= 10:
		tier = "Wary"
		color = ThemeColors.GOLD_DIM
	if player_hidden and tier != "Calm":
		tier = "Wary"
		color = ThemeColors.GOLD_DIM
	pursuit_label.text = "Pursuit: %s (%d)" % [tier, alert]
	pursuit_label.add_theme_color_override("font_color", color)

func _update_build_identity(player: Player) -> void:
	if not build_label or not player:
		return
	if not AccessibilityManager.is_build_dashboard_enabled():
		build_label.text = ""
		return
	var ranked: Array[Dictionary] = []
	var keys: Array[String] = ["melee", "archery", "evasion", "stealth", "hunting", "will", "smithing", "lore"]
	for key in keys:
		ranked.append({"k": key, "v": int(player.get_effective_skill(key))})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.v) > int(b.v)
	)
	var a0: Dictionary = ranked[0] if not ranked.is_empty() else {"k": "none", "v": 0}
	var a1: Dictionary = ranked[1] if ranked.size() > 1 else {"k": "none", "v": 0}
	build_label.text = "BLD %s/%s" % [str(a0.k).capitalize(), str(a1.k).capitalize()] if _is_compact_hud() else "Build: %s/%s" % [str(a0.k).capitalize(), str(a1.k).capitalize()]

func _update_mode_indicator() -> void:
	if not mode_label:
		return
	mode_label.text = ""
	mode_label.visible = false

func _update_goals_line() -> void:
	if not goals_label:
		return
	if not RunGoalsManager:
		goals_label.text = ""
		return
	var line: String = RunGoalsManager.get_goal_summary_line()
	if _is_compact_hud():
		line = line.replace("Goals: ", "GOAL ")
		if line.length() > 26:
			line = line.substr(0, 26) + "..."
	elif line.length() > 36:
		line = line.substr(0, 36) + "..."
	goals_label.text = line

func _on_run_goal_completed(_goal_id: String, description: String, tag: String) -> void:
	if _goal_banner == null or _goal_banner_label == null:
		return
	_goal_banner_label.text = "Goal Complete: %s  •  Chronicle: %s" % [description, tag]
	_goal_banner.visible = true
	_goal_banner.modulate.a = 0.0
	_goal_banner.position.y = 8
	var tween := create_tween()
	tween.tween_property(_goal_banner, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(_goal_banner, "position:y", 18.0, 0.18)
	tween.tween_interval(1.8)
	tween.tween_property(_goal_banner, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func(): _goal_banner.visible = false)

func _is_compact_hud() -> bool:
	var vp := get_viewport()
	if vp == null:
		return false
	var width: float = vp.get_visible_rect().size.x
	return width > 0.0 and width <= 1680.0

func _create_circle_tile_icon(tile_coords: Vector2i, ring_color: Color) -> Texture2D:
	if not _ensure_ui_icon_tileset():
		return _create_plain_ring_icon(ring_color)

	var src_image: Image = _ui_icon_tileset.get_image()
	if src_image == null or src_image.is_empty():
		return _create_plain_ring_icon(ring_color)

	var out_size: int = 24
	var out := Image.create(out_size, out_size, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	var center := Vector2(out_size / 2, out_size / 2)
	var outer_radius: float = 11.0
	var inner_radius: float = 9.0
	for y in range(out_size):
		for x in range(out_size):
			var d: float = Vector2(x, y).distance_to(center)
			if d <= outer_radius and d >= inner_radius:
				out.set_pixel(x, y, ring_color)

	var tile_px: int = 64
	var src_rect := Rect2i(tile_coords.x * tile_px, tile_coords.y * tile_px, tile_px, tile_px)
	var tile_image: Image = src_image.get_region(src_rect)
	tile_image.resize(12, 12, Image.INTERPOLATE_LANCZOS)
	out.blit_rect(tile_image, Rect2i(0, 0, 12, 12), Vector2i(6, 6))

	return ImageTexture.create_from_image(out)

func _get_hud_item_icon(item: Variant) -> Texture2D:
	if item == null:
		return null
	if not _ensure_ui_icon_tileset():
		return null
	if not ("index" in item):
		return _create_circle_tile_icon(Vector2i(0, 11), ThemeColors.GOLD_DIM)

	var item_index: int = int(item.index)
	var atlas_coords: Vector2i = TileMapper.get_object_coords(item_index)
	if not _is_valid_tile_coords_for_texture(atlas_coords, _ui_icon_tileset):
		atlas_coords = _get_hud_item_fallback_coords(item)
	if not _is_valid_tile_coords_for_texture(atlas_coords, _ui_icon_tileset):
		atlas_coords = Vector2i(0, 11)

	var atlas := AtlasTexture.new()
	atlas.atlas = _ui_icon_tileset
	atlas.region = Rect2(atlas_coords.x * 64, atlas_coords.y * 64, 64, 64)
	return atlas

func _ensure_ui_icon_tileset() -> bool:
	if _ui_icon_tileset != null:
		return true
	for path in ICON_TILESET_CANDIDATE_PATHS:
		if FileAccess.file_exists(path):
			_ui_icon_tileset = load(path)
			if _ui_icon_tileset != null:
				return true
	return false

func _ensure_stance_icon_tileset() -> bool:
	if _stance_icon_tileset != null:
		return true
	for path in ICON_TILESET_CANDIDATE_PATHS:
		if FileAccess.file_exists(path):
			_stance_icon_tileset = load(path)
			if _stance_icon_tileset != null:
				return true
	return false

func _is_valid_tile_coords_for_texture(coords: Vector2i, texture: Texture2D) -> bool:
	if texture == null:
		return false
	if coords.x < 0 or coords.y < 0:
		return false
	var tex_size: Vector2i = texture.get_size()
	return ((coords.x + 1) * 64 <= tex_size.x) and ((coords.y + 1) * 64 <= tex_size.y)

func _get_hud_item_fallback_coords(item: Variant) -> Vector2i:
	var tval: int = int(item.tval) if item != null and ("tval" in item) else -1
	match tval:
		18, 19, 20, 21, 22, 23:
			return Vector2i(24, 11)  # generic weapon
		17:
			return Vector2i(23, 12)  # arrow
		34:
			return Vector2i(21, 11)  # shield
		36, 37:
			return Vector2i(14, 11)  # armor
		32, 33:
			return Vector2i(11, 12)  # helm/crown
		39:
			return Vector2i(1, 13)   # torch/light
		40, 45:
			return Vector2i(2, 11)   # jewelry
		80:
			return Vector2i(13, 16)  # food
		55, 56, 66, 75, 77:
			return Vector2i(26, 14)  # devices/consumables
		_:
			return Vector2i(0, 11)   # pile

func _create_plain_ring_icon(ring_color: Color) -> Texture2D:
	var out_size: int = 24
	var out := Image.create(out_size, out_size, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var center := Vector2(out_size / 2, out_size / 2)
	var outer_radius: float = 11.0
	var inner_radius: float = 9.0
	for y in range(out_size):
		for x in range(out_size):
			var d: float = Vector2(x, y).distance_to(center)
			if d <= outer_radius and d >= inner_radius:
				out.set_pixel(x, y, ring_color)
	return ImageTexture.create_from_image(out)

func _has_visible_hostiles() -> bool:
	if not GameManager.current_level:
		return false
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		if GameManager.current_level.is_tile_visible(entity.grid_position):
			return true
	return false

# ============================================================================
# MINIMAP
# ============================================================================

func set_level(level: Level) -> void:
	if minimap:
		minimap.set_level(level)
	if minimap_frame:
		minimap_frame.visible = minimap != null and minimap.visible

func set_player(player: Player) -> void:
	if minimap:
		minimap.set_player(player)

func refresh_minimap() -> void:
	if minimap:
		minimap.mark_dirty()
		minimap.refresh()

func toggle_minimap() -> void:
	if minimap and minimap_frame:
		var next_visible: bool = not minimap_frame.visible
		minimap_frame.visible = next_visible
		minimap.visible = next_visible

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
	peril_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	peril_label.offset_top = 90
	peril_label.offset_bottom = 150
	ThemeColors.apply_heading_font(peril_label, ThemeColors.FONT_SIZE_H1)
	peril_label.add_theme_color_override("font_color", ThemeColors.BLOOD_BRIGHT)
	peril_label.add_theme_constant_override("shadow_offset_x", 2)
	peril_label.add_theme_constant_override("shadow_offset_y", 2)
	peril_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
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
	var label_color: Color = ThemeColors.BLOOD_BRIGHT

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
	var peak: float = flash_intensity * 0.5 if AccessibilityManager.reduced_flash else flash_intensity
	var fade_time: float = 0.5 if AccessibilityManager.reduced_motion else 1.0
	flash_tween.tween_property(peril_flash, "color:a", peak, 0.15)
	flash_tween.tween_property(peril_flash, "color:a", 0.0, fade_time)
	flash_tween.tween_callback(func(): peril_flash.visible = false)

	# Label with depth-based styling
	peril_label.text = message
	peril_label.add_theme_font_size_override("font_size", font_size)
	peril_label.add_theme_color_override("font_color", label_color)
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
		_refresh_status_icons_if_needed(entity as Player)

func _on_status_removed(entity: Entity, status_name: String) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		_on_message_logged("The %s effect wears off." % status_name, ThemeColors.MSG_INFO)
		_refresh_status_icons_if_needed(entity as Player)

func _on_status_tick(entity: Entity, _status_name: String, _duration: int) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		_refresh_status_icons_if_needed(entity as Player)

func _update_status_icons(player: Player) -> void:
	if status_container == null:
		return
	for child in status_container.get_children():
		if child.has_meta("pulse_tween"):
			var pulse_tween: Variant = child.get_meta("pulse_tween")
			if pulse_tween is Tween and is_instance_valid(pulse_tween):
				(pulse_tween as Tween).kill()
			child.remove_meta("pulse_tween")
		child.queue_free()

	if not player.status_fx:
		return

	var active_effects: Array[Dictionary] = []
	for effect_id: StringName in player.status_fx.get_active_effects():
		var duration: int = player.status_fx.get_duration(effect_id)
		var status_name := String(effect_id)
		var meta: Dictionary = StatusMetadata.get_status_meta(status_name, duration)
		active_effects.append({
			"status_name": status_name,
			"duration": duration,
			"meta": meta,
			"rank": int(meta.get("severity_rank", 1)),
		})

	active_effects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.rank) > int(b.rank)
	)

	for entry in active_effects:
		var status_name: String = str(entry.status_name)
		var duration: int = int(entry.duration)
		var meta: Dictionary = entry.meta
		var status_color := ThemeColors.get_status_color(status_name)

		var badge := PanelContainer.new()
		badge.add_theme_stylebox_override("panel", ThemeColors.create_status_pill(status_color))
		var icon_row := HBoxContainer.new()
		icon_row.add_theme_constant_override("separation", 2)
		badge.add_child(icon_row)

		var icon_tex: Texture2D = _get_status_icon_texture(status_name)
		if icon_tex != null:
			var icon_rect := TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(16, 16)
			icon_rect.texture = icon_tex
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_row.add_child(icon_rect)
		else:
			var fallback := Label.new()
			fallback.text = _get_status_abbreviation(status_name)
			fallback.add_theme_color_override("font_color", status_color)
			ThemeColors.apply_body_font(fallback, ThemeColors.FONT_SIZE_HINT)
			icon_row.add_child(fallback)

		var dur_label := Label.new()
		dur_label.text = str(duration)
		ThemeColors.apply_body_font(dur_label, ThemeColors.FONT_SIZE_HINT - 2)
		dur_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
		icon_row.add_child(dur_label)

		badge.tooltip_text = "%s (%d turns)\nSeverity: %s\nEffect: %s\nCounterplay: %s" % [
			str(meta.get("name", status_name.capitalize())),
			duration,
			str(meta.get("severity", "minor")),
			str(meta.get("exact_effect", "Temporary effect.")),
			str(meta.get("counterplay", "React defensively.")),
		]
		status_container.add_child(badge)

		if status_name.to_lower() in DANGER_STATUSES:
			_pulse_node(badge)

func _pulse_node(node: Control) -> void:
	if AccessibilityManager.reduced_motion:
		return
	if node.has_meta("pulse_tween"):
		var old_tween: Variant = node.get_meta("pulse_tween")
		if old_tween is Tween and is_instance_valid(old_tween):
			(old_tween as Tween).kill()
		node.remove_meta("pulse_tween")
	var tween := create_tween()
	tween.bind_node(node)
	node.set_meta("pulse_tween", tween)
	tween.set_loops()
	tween.tween_property(node, "modulate:a", 0.5, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)

func pulse_hotbar_slot(slot_index: int, pulses: int = 3) -> void:
	if slot_index < 0 or slot_index >= hotbar_slots.size():
		return
	var slot: PanelContainer = hotbar_slots[slot_index]
	if slot == null or not is_instance_valid(slot):
		return
	var icon: TextureRect = _hotbar_icon_nodes[slot_index] if slot_index < _hotbar_icon_nodes.size() else null
	var label: Label = _hotbar_key_labels[slot_index] if slot_index < _hotbar_key_labels.size() else null
	var loops: int = maxi(1, pulses)
	var base_slot: Color = slot.modulate
	var base_icon: Color = icon.modulate if icon else Color.WHITE
	var tween := create_tween()
	tween.bind_node(slot)
	for _i in range(loops):
		tween.tween_property(slot, "modulate", Color(ThemeColors.GOLD_BRIGHT, 1.0), 0.15).set_ease(Tween.EASE_IN_OUT)
		if icon:
			tween.parallel().tween_property(icon, "modulate", Color(1.3, 1.25, 1.15, 1.0), 0.15).set_ease(Tween.EASE_IN_OUT)
		if label:
			label.add_theme_color_override("font_color", ThemeColors.GOLD_BRIGHT)
		tween.tween_property(slot, "modulate", base_slot, 0.22).set_ease(Tween.EASE_IN_OUT)
		if icon:
			tween.parallel().tween_property(icon, "modulate", base_icon, 0.22).set_ease(Tween.EASE_IN_OUT)

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
		"endurance_will": return "END"
		_: return status_name.substr(0, 3).to_upper()

func _get_status_icon_texture(status_name: String) -> Texture2D:
	if not _ensure_ui_icon_tileset():
		return null
	var coords: Vector2i = _get_status_icon_coords(status_name)
	if not _is_valid_tile_coords_for_texture(coords, _ui_icon_tileset):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = _ui_icon_tileset
	atlas.region = Rect2(coords.x * 64, coords.y * 64, 64, 64)
	return atlas

func _get_status_icon_coords(status_name: String) -> Vector2i:
	match status_name.to_lower():
		"poisoned": return Vector2i(22, 15)
		"burning": return Vector2i(27, 14)
		"stunned": return Vector2i(3, 15)
		"confused": return Vector2i(24, 15)
		"afraid": return Vector2i(30, 14)
		"blind": return Vector2i(24, 14)
		"slow": return Vector2i(28, 14)
		"fast": return Vector2i(28, 12)
		"entranced": return Vector2i(9, 16)
		"cut": return Vector2i(29, 11)
		"rage": return Vector2i(2, 16)
		"darkened": return Vector2i(25, 14)
		"image": return Vector2i(19, 12)
		"endurance_will": return Vector2i(3, 14)
		_: return Vector2i(9, 0)

# ============================================================================
# HELPERS
# ============================================================================

func _format_number(n: int) -> String:
	if n >= 10000:
		return "%d.%dk" % [n / 1000, (n % 1000) / 100]
	return str(n)
