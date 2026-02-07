extends Control
class_name TomePanel
## Tome of Fallen Heroes — unified skill tree + ability browser.
## Single-page book navigation: Index page or Chapter page, with page-turn transitions.

signal skill_increased(skill_name: String, new_level: int)
signal ability_purchased(ability_name: String)
signal closed

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const SKILL_NAMES: Array[String] = [
	"melee", "archery", "evasion", "stealth",
	"perception", "will", "smithing", "lore"
]

const SKILL_LABELS: Array[String] = [
	"Melee", "Archery", "Evasion", "Stealth",
	"Perception", "Will", "Smithing", "Lore"
]

const SKILL_RUNES: Array[String] = [
	"ᛏ", "ᛇ", "ᛖ", "ᛈ", "ᛞ", "ᚢ", "ᚦ", "ᚲ",
]

const CHAPTER_TITLES: Array[String] = [
	"Chapter I: The Way of the Blade",
	"Chapter II: The Far Eye",
	"Chapter III: The Art of Not Being There",
	"Chapter IV: The Shadow's Gift",
	"Chapter V: The Watcher's Vigil",
	"Chapter VI: The Unyielding Mind",
	"Chapter VII: The Maker's Craft",
	"Chapter VIII: Words of Power",
]

const CHAPTER_FLAVORS: Array[String] = [
	"Steel teaches lessons that cannot be unlearned.",
	"The arrow knows things the archer has forgotten.",
	"The best defence is not being where the blade falls.",
	"Darkness is not the absence of light. It is a weapon.",
	"To see is to survive. To see first is to choose.",
	"The fortress of the mind has no gate.",
	"Iron remembers the hands that shaped it.",
	"To name a thing is to have power over it.",
]

# Roman numerals for index page
const SKILL_NUMERALS: Array[String] = [
	"I", "II", "III", "IV", "V", "VI", "VII", "VIII"
]

# Voice costs for lore abilities (mirrors AbilitySystem)
const VOICE_COSTS := {
	140: 3, 141: 1, 142: 2, 143: 2, 144: 2, 146: 2, 147: 3, 148: 0, 150: 3, 151: 4, 154: 3
}

# Marginalia quotes (5 per skill tree = 40 total)
const MARGINALIA := {
	"melee": [
		"Saved my life on level 4. Learn this first. -- B.G.",
		"The blade remembers what the hand forgets.",
		"He who hesitates is already bleeding.",
		"Strength is the argument that needs no words. -- Hurin",
		"The difference between alive and dead is one good parry.",
	],
	"archery": [
		"You get one shot. After that they know where you are.",
		"Patience is a weapon with infinite range.",
		"Aim for the eyes. Always the eyes. -- Celeborn",
		"Wind lies. Gravity never does.",
		"The bow is a coward's tool. Use it. Live longer.",
	],
	"evasion": [
		"The trick is not speed. The trick is knowing where not to be.",
		"I once dodged twelve arrows. The thirteenth found me.",
		"Armour slows you. Speed saves you. Choose. -- Fingolfin",
		"Moved like water. Died to fire.",
		"An enemy who cannot hit you is already half defeated.",
	],
	"stealth": [
		"They cannot kill what they cannot find.",
		"Moved like a shadow. Died like everyone else. -- Celebrimbor, Depth 450ft",
		"The loudest sound in Dol Guldur is a footstep.",
		"I passed unseen through halls of nightmare. Then I sneezed.",
		"Silence is the only language the darkness respects.",
	],
	"perception": [
		"Saw the trap. Stepped in it anyway. -- R.T., final entry",
		"Trust your eyes. Trust your ears more.",
		"The walls have eyes. Literally. Check them.",
		"Every shadow hides something. EVERY shadow.",
		"I noticed the ambush too late. Learn from my bones.",
	],
	"will": [
		"The mind is the last thing they break.",
		"When the darkness speaks your name, do not answer.",
		"Fear is a lie your body tells your legs. -- Beren",
		"I watched three companions go mad. I endured. Barely.",
		"Resist everything. Especially the urge to give up.",
	],
	"smithing": [
		"A dull blade is a death sentence.",
		"The forge is the only safe place in this hell.",
		"Iron into steel. Steel into survival. -- Telchar",
		"Fix your armour BEFORE the next fight.",
		"The best equipment is the equipment you made yourself.",
	],
	"lore": [
		"The first time you speak it, even YOU will be afraid.",
		"Words have power here. Terrible power.",
		"Knowledge is a blade that cuts the wielder first. -- Gandalf",
		"I learned the name of darkness. It learned mine.",
		"Voice is finite. Spend it like your last coin.",
	],
}

enum PageState { INDEX, CHAPTER }

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var player: Player
var selected_skill_idx: int = 0
var selected_ability_idx: int = -1
var current_page: PageState = PageState.INDEX
var _ability_list: Array = []  # Filtered abilities for current skill tree
var pending_investments: Dictionary = {}  # skill_name -> staged point count

# ---------------------------------------------------------------------------
# UI Nodes (built in _setup_ui)
# ---------------------------------------------------------------------------
var book_frame: PanelContainer
var title_label: Label

# Single page (replaces left_page/spine/right_page)
var page_container: PanelContainer
var page_bg: TextureRect
var _paper_material: ShaderMaterial
var index_content: VBoxContainer
var chapter_content: VBoxContainer

# Index page elements
var index_header: Label
var skill_rows: Array[Dictionary] = []

# Chapter page elements
var chapter_header: Label
var chapter_flavor: Label
var marginalia_label: Label
var voice_bar_container: HBoxContainer
var voice_bar: ProgressBar
var voice_label: Label
var ability_scroll: ScrollContainer
var ability_vbox: VBoxContainer
var ability_buttons: Array[Button] = []
var detail_panel: PanelContainer
var detail_name: Label
var detail_desc: RichTextLabel
var detail_prereqs: Label
var detail_cost: Label
var detail_voice: Label
var learn_button: Button

# Confirm bar (skill investment staging)
var confirm_bar: HBoxContainer
var confirm_label: Label
var confirm_btn: Button
var cancel_btn: Button

# Layered depth elements
var book_shadow: ColorRect
var cover_texture: TextureRect
var page_edges_texture: TextureRect
var corner_dogear: TextureRect
var loose_note: TextureRect
var page_turn_overlay: ColorRect
var _page_turn_material: ShaderMaterial
var _is_turning_page: bool = false

# Parallax state
var _base_note_offset: Vector2 = Vector2.ZERO
var _base_corner_offset: Vector2 = Vector2.ZERO

# Skill-to-page texture mapping
const SKILL_PAGE_KEYS: Array[String] = [
	"tome_page_melee", "tome_page_archery", "tome_page_evasion", "tome_page_stealth",
	"tome_page_perception", "tome_page_will", "tome_page_smithing", "tome_page_lore",
]

# Footer
var footer_xp: Label
var footer_hint: Label

func _ready() -> void:
	_setup_ui()
	visible = false
	set_process(false)

func _process(_delta: float) -> void:
	if not visible:
		return
	# Subtle parallax: shift decorative layers based on mouse position
	var vp_size := get_viewport_rect().size
	if vp_size.x < 1.0:
		return
	var mouse := get_viewport().get_mouse_position()
	# Normalized -1..+1 from center
	var nx: float = (mouse.x / vp_size.x - 0.5) * 2.0
	var ny: float = (mouse.y / vp_size.y - 0.5) * 2.0
	# Parallax amounts (small, subtle)
	if corner_dogear and corner_dogear.visible:
		corner_dogear.offset_left = _base_corner_offset.x + nx * 3.0
		corner_dogear.offset_top = _base_corner_offset.y + ny * 2.0
	# Book shadow slight shift (depth cue)
	if book_shadow:
		book_shadow.offset_left = -590 + nx * 4.0
		book_shadow.offset_top = -358 + ny * 3.0

func open(player_ref: Player) -> void:
	player = player_ref
	current_page = PageState.INDEX
	_swap_page_texture_instant()
	index_content.visible = true
	chapter_content.visible = false
	_refresh_all()
	_randomize_loose_note(selected_skill_idx)
	PanelTransition.open_panel(self)
	set_process(true)
	grab_focus()

func close() -> void:
	pending_investments.clear()
	set_process(false)
	PanelTransition.close_panel(self, func(): closed.emit())

# ===========================================================================
# UI CONSTRUCTION
# ===========================================================================

func _setup_ui() -> void:
	# Layer 0: Drop shadow beneath the book (depth cue)
	book_shadow = ColorRect.new()
	book_shadow.anchor_left = 0.5
	book_shadow.anchor_top = 0.5
	book_shadow.anchor_right = 0.5
	book_shadow.anchor_bottom = 0.5
	book_shadow.offset_left = -590
	book_shadow.offset_top = -358
	book_shadow.offset_right = 610
	book_shadow.offset_bottom = 382
	book_shadow.color = Color(0, 0, 0, 0.45)
	book_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(book_shadow)

	# Layer 1: Book cover texture (DALL-E leather, slightly larger than pages)
	cover_texture = TextureRect.new()
	cover_texture.anchor_left = 0.5
	cover_texture.anchor_top = 0.5
	cover_texture.anchor_right = 0.5
	cover_texture.anchor_bottom = 0.5
	cover_texture.offset_left = -608
	cover_texture.offset_top = -378
	cover_texture.offset_right = 608
	cover_texture.offset_bottom = 378
	cover_texture.stretch_mode = TextureRect.STRETCH_SCALE
	cover_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cover_tex: Texture2D = ThemeColors.get_texture("tome_cover")
	if cover_tex:
		cover_texture.texture = cover_tex
		var depth_shader: Shader = ThemeColors.get_shader("book_depth")
		if depth_shader:
			var depth_mat := ShaderMaterial.new()
			depth_mat.shader = depth_shader
			cover_texture.material = depth_mat
	else:
		cover_texture.self_modulate = Color(0.18, 0.12, 0.08, 1.0)
	add_child(cover_texture)

	# Layer 2: Book frame
	book_frame = PanelContainer.new()
	book_frame.anchor_left = 0.5
	book_frame.anchor_top = 0.5
	book_frame.anchor_right = 0.5
	book_frame.anchor_bottom = 0.5
	book_frame.offset_left = -600
	book_frame.offset_top = -370
	book_frame.offset_right = 600
	book_frame.offset_bottom = 370
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0) if cover_tex else Color(0.15, 0.1, 0.07, 0.95)
	frame_style.content_margin_left = 12
	frame_style.content_margin_right = 12
	frame_style.content_margin_top = 8
	frame_style.content_margin_bottom = 8
	book_frame.add_theme_stylebox_override("panel", frame_style)
	add_child(book_frame)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	book_frame.add_child(main_vbox)

	# Title
	title_label = Label.new()
	title_label.text = "TOME OF FALLEN HEROES"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeColors.apply_heading_font(title_label, ThemeColors.FONT_SIZE_H2)
	var engraved: Shader = ThemeColors.get_shader("engraved")
	if engraved:
		var mat := ShaderMaterial.new()
		mat.shader = engraved
		title_label.material = mat
	main_vbox.add_child(title_label)

	# Content: Single page area (full width)
	_setup_page(main_vbox)

	# Layer 3: Page edges
	_setup_page_edges()
	# Layer 4: Corner dogear overlay
	_setup_corner_overlay()
	# Layer 5: Page turn overlay
	_setup_page_turn_overlay()
	# Layer 6: Loose note
	_setup_loose_note()
	# Footer bar
	_setup_footer(main_vbox)

func _setup_page(parent: VBoxContainer) -> void:
	page_container = PanelContainer.new()
	page_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_container.clip_contents = true
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = Color(0, 0, 0, 0)
	page_style.content_margin_left = 24
	page_style.content_margin_right = 24
	page_style.content_margin_top = 8
	page_style.content_margin_bottom = 8
	page_container.add_theme_stylebox_override("panel", page_style)
	parent.add_child(page_container)

	# Page texture background
	page_bg = TextureRect.new()
	page_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_bg.stretch_mode = TextureRect.STRETCH_SCALE
	page_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_bg.show_behind_parent = true
	var index_tex: Texture2D = ThemeColors.get_texture("tome_page_index")
	if index_tex:
		page_bg.texture = index_tex
		var paper_shader: Shader = ThemeColors.get_shader("paper_lighting")
		if paper_shader:
			_paper_material = ShaderMaterial.new()
			_paper_material.shader = paper_shader
			_paper_material.set_shader_parameter("light_pos", Vector2(0.5, 0.2))
			_paper_material.set_shader_parameter("shadow_at_spine", 0.0)
			_paper_material.set_shader_parameter("desaturation", 0.45)
			_paper_material.set_shader_parameter("brightness_boost", 1.15)
			page_bg.material = _paper_material
	else:
		page_container.remove_theme_stylebox_override("panel")
		var fallback: StyleBox = ThemeColors.create_textured_panel("panel_parchment", 12.0)
		page_container.add_theme_stylebox_override("panel", fallback)
	page_container.add_child(page_bg)

	# [#7] Dark backing panel — increased opacity (0.55 → 0.68) to mute texture
	var page_backing := PanelContainer.new()
	page_backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	var backing_style := StyleBoxFlat.new()
	backing_style.bg_color = Color(0.12, 0.09, 0.06, 0.68)
	backing_style.content_margin_left = 24
	backing_style.content_margin_right = 24
	backing_style.content_margin_top = 8
	backing_style.content_margin_bottom = 8
	page_backing.add_theme_stylebox_override("panel", backing_style)
	page_container.add_child(page_backing)

	# Stack both content containers inside the backing
	var stack := Control.new()
	stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_backing.add_child(stack)

	index_content = VBoxContainer.new()
	index_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	index_content.add_theme_constant_override("separation", 6)
	index_content.visible = true
	stack.add_child(index_content)

	chapter_content = VBoxContainer.new()
	chapter_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	chapter_content.add_theme_constant_override("separation", 4)
	chapter_content.visible = false
	stack.add_child(chapter_content)

	_setup_index_content()
	_setup_chapter_content()

func _setup_index_content() -> void:
	# Header
	index_header = Label.new()
	index_header.text = "The Index of Disciplines"
	index_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeColors.apply_heading_font(index_header, ThemeColors.FONT_SIZE_H3)
	index_header.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	index_header.add_theme_constant_override("shadow_offset_x", 1)
	index_header.add_theme_constant_override("shadow_offset_y", 2)
	index_header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	index_content.add_child(index_header)

	var sep := HSeparator.new()
	index_content.add_child(sep)

	# [#3] Skill rows — increased spacing (2 → 8) for breathing room
	var skills_vbox := VBoxContainer.new()
	skills_vbox.add_theme_constant_override("separation", 8)
	skills_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	index_content.add_child(skills_vbox)

	for i in range(SKILL_NAMES.size()):
		var row := _create_skill_row(i)
		skills_vbox.add_child(row.container)
		skill_rows.append(row)

	# Confirm bar (visible when pending skill investments exist)
	confirm_bar = HBoxContainer.new()
	confirm_bar.add_theme_constant_override("separation", 8)
	confirm_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_bar.visible = false
	index_content.add_child(confirm_bar)

	confirm_label = Label.new()
	ThemeColors.apply_body_font(confirm_label, ThemeColors.FONT_SIZE_HINT)
	confirm_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	confirm_bar.add_child(confirm_label)

	confirm_btn = Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.custom_minimum_size = Vector2(80, 28)
	confirm_btn.pressed.connect(_confirm_investments)
	ThemeColors.apply_button_theme(confirm_btn)
	confirm_bar.add_child(confirm_btn)

	cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(80, 28)
	cancel_btn.pressed.connect(_cancel_investments)
	ThemeColors.apply_button_theme(cancel_btn)
	confirm_bar.add_child(cancel_btn)

func _create_skill_row(idx: int) -> Dictionary:
	# [#3] Row height increased (42 → 56) to fit preview line
	var row_btn := Button.new()
	row_btn.flat = true
	row_btn.custom_minimum_size.y = 56
	row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_btn.pressed.connect(_select_skill.bind(idx))
	# [#2] Normal style — will be swapped for selected row in _update_selection_indicators
	var row_normal := StyleBoxFlat.new()
	row_normal.bg_color = Color(0, 0, 0, 0)
	row_normal.content_margin_left = 4
	row_btn.add_theme_stylebox_override("normal", row_normal)
	var row_hover := StyleBoxFlat.new()
	row_hover.bg_color = Color(ThemeColors.PARCHMENT_EDGE, 0.15)
	row_hover.content_margin_left = 4
	row_btn.add_theme_stylebox_override("hover", row_hover)

	# VBox wrapping main row + preview line
	var row_vbox := VBoxContainer.new()
	row_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	row_vbox.add_theme_constant_override("separation", 0)
	row_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_btn.add_child(row_vbox)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_vbox.add_child(hbox)

	# Numeral (left side)
	var numeral_label := Label.new()
	numeral_label.text = "%s." % SKILL_NUMERALS[idx]
	numeral_label.custom_minimum_size.x = 40
	numeral_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var heading_font: Font = ThemeColors.get_font("heading")
	if heading_font:
		numeral_label.add_theme_font_override("font", heading_font)
	numeral_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	numeral_label.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
	numeral_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(numeral_label)

	# Name
	var name_label := Label.new()
	name_label.text = SKILL_LABELS[idx]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if heading_font:
		name_label.add_theme_font_override("font", heading_font)
	name_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	name_label.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_label)

	# Level text
	var level_label := Label.new()
	level_label.custom_minimum_size.x = 65
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeColors.apply_body_font(level_label, ThemeColors.FONT_SIZE_BODY)
	level_label.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(level_label)

	# Cost
	var cost_label := Label.new()
	cost_label.custom_minimum_size.x = 80
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ThemeColors.apply_body_font(cost_label, ThemeColors.FONT_SIZE_HINT)
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(cost_label)

	# [#6] - button — enlarged (24→34), circular dark bg, gold text
	var minus_btn := Button.new()
	minus_btn.text = "-"
	minus_btn.custom_minimum_size = Vector2(34, 34)
	minus_btn.visible = false
	minus_btn.pressed.connect(_on_skill_decrement.bind(idx))
	_apply_circular_button_style(minus_btn)
	hbox.add_child(minus_btn)

	# [#6] + button — enlarged (24→34), circular dark bg, gold text
	var buy_btn := Button.new()
	buy_btn.text = "+"
	buy_btn.custom_minimum_size = Vector2(34, 34)
	buy_btn.pressed.connect(_on_skill_invest.bind(idx))
	_apply_circular_button_style(buy_btn)
	hbox.add_child(buy_btn)

	# [#4] Preview line — "Next: [ability] | X/Y abilities"
	var preview_label := Label.new()
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var body_font: Font = ThemeColors.get_font("body")
	if body_font:
		preview_label.add_theme_font_override("font", body_font)
	preview_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT - 2)
	preview_label.add_theme_color_override("font_color", Color(ThemeColors.PARCHMENT_TEXT, 0.6))
	preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Indent to align with skill name (past numeral column)
	preview_label.add_theme_constant_override("margin_left", 50)
	row_vbox.add_child(preview_label)

	return {
		"container": row_btn,
		"hbox": hbox,
		"row_vbox": row_vbox,
		"numeral_label": numeral_label,
		"name_label": name_label,
		"level_label": level_label,
		"cost_label": cost_label,
		"minus_btn": minus_btn,
		"buy_btn": buy_btn,
		"preview_label": preview_label,
	}

# [#6] Helper: circular stone button style for +/- investment buttons
func _apply_circular_button_style(btn: Button) -> void:
	btn.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	btn.add_theme_font_size_override("font_size", 18)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.08, 0.06, 0.5)
	normal.corner_radius_top_left = 17
	normal.corner_radius_top_right = 17
	normal.corner_radius_bottom_left = 17
	normal.corner_radius_bottom_right = 17
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(ThemeColors.GOLD_WARM, 0.25)
	hover.corner_radius_top_left = 17
	hover.corner_radius_top_right = 17
	hover.corner_radius_bottom_left = 17
	hover.corner_radius_bottom_right = 17
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(ThemeColors.GOLD_WARM, 0.4)
	pressed.corner_radius_top_left = 17
	pressed.corner_radius_top_right = 17
	pressed.corner_radius_bottom_left = 17
	pressed.corner_radius_bottom_right = 17
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.1, 0.08, 0.06, 0.2)
	disabled.corner_radius_top_left = 17
	disabled.corner_radius_top_right = 17
	disabled.corner_radius_bottom_left = 17
	disabled.corner_radius_bottom_right = 17
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_disabled_color", Color(ThemeColors.PARCHMENT_EDGE, 0.4))

func _setup_chapter_content() -> void:
	# Chapter header
	chapter_header = Label.new()
	chapter_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeColors.apply_heading_font(chapter_header, ThemeColors.FONT_SIZE_H3)
	chapter_header.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	chapter_header.add_theme_constant_override("shadow_offset_x", 1)
	chapter_header.add_theme_constant_override("shadow_offset_y", 2)
	chapter_header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	chapter_content.add_child(chapter_header)

	# Chapter flavor
	chapter_flavor = Label.new()
	chapter_flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body_font: Font = ThemeColors.get_font("body")
	if body_font:
		chapter_flavor.add_theme_font_override("font", body_font)
	chapter_flavor.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
	chapter_flavor.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
	chapter_flavor.add_theme_constant_override("shadow_offset_x", 1)
	chapter_flavor.add_theme_constant_override("shadow_offset_y", 1)
	chapter_flavor.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	chapter_content.add_child(chapter_flavor)

	# [#8] Marginalia — moved from index bottom to chapter subtitle area
	marginalia_label = Label.new()
	marginalia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marginalia_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if body_font:
		marginalia_label.add_theme_font_override("font", body_font)
	marginalia_label.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT - 2)
	marginalia_label.add_theme_color_override("font_color", Color(ThemeColors.MARGINALIA_INK, 0.7))
	marginalia_label.add_theme_constant_override("shadow_offset_x", 1)
	marginalia_label.add_theme_constant_override("shadow_offset_y", 1)
	marginalia_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
	chapter_content.add_child(marginalia_label)

	# Voice bar (only for Lore)
	voice_bar_container = HBoxContainer.new()
	voice_bar_container.add_theme_constant_override("separation", 8)
	voice_bar_container.visible = false
	chapter_content.add_child(voice_bar_container)

	var voice_icon := Label.new()
	voice_icon.text = "Voice:"
	ThemeColors.apply_body_font(voice_icon, ThemeColors.FONT_SIZE_HINT)
	voice_icon.add_theme_color_override("font_color", ThemeColors.SPIRIT_BRIGHT)
	voice_bar_container.add_child(voice_icon)

	voice_bar = ProgressBar.new()
	voice_bar.custom_minimum_size = Vector2(120, 14)
	voice_bar.show_percentage = false
	voice_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vb_bg := StyleBoxFlat.new()
	vb_bg.bg_color = ThemeColors.SPIRIT_DARK
	vb_bg.corner_radius_top_left = 2
	vb_bg.corner_radius_top_right = 2
	vb_bg.corner_radius_bottom_left = 2
	vb_bg.corner_radius_bottom_right = 2
	voice_bar.add_theme_stylebox_override("background", vb_bg)
	var vb_fill := StyleBoxFlat.new()
	vb_fill.bg_color = ThemeColors.SPIRIT_BRIGHT
	vb_fill.corner_radius_top_left = 2
	vb_fill.corner_radius_top_right = 2
	vb_fill.corner_radius_bottom_left = 2
	vb_fill.corner_radius_bottom_right = 2
	voice_bar.add_theme_stylebox_override("fill", vb_fill)
	voice_bar_container.add_child(voice_bar)

	voice_label = Label.new()
	voice_label.custom_minimum_size.x = 60
	ThemeColors.apply_body_font(voice_label, ThemeColors.FONT_SIZE_HINT)
	voice_label.add_theme_color_override("font_color", ThemeColors.SPIRIT_BRIGHT)
	voice_bar_container.add_child(voice_label)

	var sep := HSeparator.new()
	chapter_content.add_child(sep)

	# Ability scroll area
	ability_scroll = ScrollContainer.new()
	ability_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ability_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chapter_content.add_child(ability_scroll)

	ability_vbox = VBoxContainer.new()
	ability_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_vbox.add_theme_constant_override("separation", 2)
	ability_scroll.add_child(ability_vbox)

	# [#5] Detail panel — enhanced separation: 35% bg, gold top border, 16px margin, 4px corners
	var detail_spacer := Control.new()
	detail_spacer.custom_minimum_size.y = 16
	chapter_content.add_child(detail_spacer)

	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size.y = 160
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(ThemeColors.PARCHMENT_EDGE, 0.35)
	detail_style.border_width_top = 2
	detail_style.border_color = Color(ThemeColors.GOLD_WARM, 0.5)
	detail_style.content_margin_left = 12
	detail_style.content_margin_right = 12
	detail_style.content_margin_top = 8
	detail_style.content_margin_bottom = 8
	detail_style.corner_radius_top_left = 4
	detail_style.corner_radius_top_right = 4
	detail_style.corner_radius_bottom_left = 4
	detail_style.corner_radius_bottom_right = 4
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	chapter_content.add_child(detail_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 4)
	detail_panel.add_child(detail_vbox)

	detail_name = Label.new()
	ThemeColors.apply_heading_font(detail_name, ThemeColors.FONT_SIZE_LARGE)
	detail_name.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
	detail_vbox.add_child(detail_name)

	detail_desc = RichTextLabel.new()
	detail_desc.bbcode_enabled = true
	detail_desc.fit_content = true
	detail_desc.scroll_active = false
	detail_desc.custom_minimum_size.y = 40
	ThemeColors.apply_rich_body_font(detail_desc, ThemeColors.FONT_SIZE_HINT)
	detail_desc.add_theme_color_override("default_color", ThemeColors.PARCHMENT_TEXT)
	detail_vbox.add_child(detail_desc)

	detail_prereqs = Label.new()
	ThemeColors.apply_body_font(detail_prereqs, ThemeColors.FONT_SIZE_HINT)
	detail_prereqs.add_theme_color_override("font_color", ThemeColors.MSG_WARNING)
	detail_prereqs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(detail_prereqs)

	detail_cost = Label.new()
	ThemeColors.apply_body_font(detail_cost, ThemeColors.FONT_SIZE_HINT)
	detail_vbox.add_child(detail_cost)

	detail_voice = Label.new()
	ThemeColors.apply_body_font(detail_voice, ThemeColors.FONT_SIZE_HINT)
	detail_voice.add_theme_color_override("font_color", ThemeColors.SPIRIT_BRIGHT)
	detail_vbox.add_child(detail_voice)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	detail_vbox.add_child(btn_row)

	learn_button = Button.new()
	learn_button.text = "Inscribe"
	learn_button.flat = true
	learn_button.custom_minimum_size = Vector2(160, 34)
	learn_button.disabled = true
	learn_button.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	learn_button.pressed.connect(_on_learn_pressed)
	btn_row.add_child(learn_button)

	_clear_detail()

func _setup_page_edges() -> void:
	page_edges_texture = TextureRect.new()
	page_edges_texture.anchor_left = 0.5
	page_edges_texture.anchor_top = 0.5
	page_edges_texture.anchor_right = 0.5
	page_edges_texture.anchor_bottom = 0.5
	page_edges_texture.offset_left = 596
	page_edges_texture.offset_top = -360
	page_edges_texture.offset_right = 596 + 24
	page_edges_texture.offset_bottom = 360
	page_edges_texture.stretch_mode = TextureRect.STRETCH_SCALE
	page_edges_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var edges_tex: Texture2D = ThemeColors.get_texture("tome_page_edges")
	if edges_tex:
		page_edges_texture.texture = edges_tex
	else:
		page_edges_texture.self_modulate = Color(0.82, 0.76, 0.65, 0.8)
	add_child(page_edges_texture)

func _setup_corner_overlay() -> void:
	corner_dogear = TextureRect.new()
	corner_dogear.anchor_left = 0.5
	corner_dogear.anchor_top = 0.5
	corner_dogear.offset_left = 510
	corner_dogear.offset_top = -365
	corner_dogear.custom_minimum_size = Vector2(64, 64)
	corner_dogear.stretch_mode = TextureRect.STRETCH_SCALE
	corner_dogear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var corner_tex: Texture2D = ThemeColors.get_texture("tome_corner_dogear")
	if corner_tex:
		corner_dogear.texture = corner_tex
		corner_dogear.self_modulate = Color(1, 1, 1, 0.7)
	else:
		corner_dogear.visible = false
	add_child(corner_dogear)
	_base_corner_offset = Vector2(corner_dogear.offset_left, corner_dogear.offset_top)

func _setup_page_turn_overlay() -> void:
	page_turn_overlay = ColorRect.new()
	page_turn_overlay.anchor_left = 0.5
	page_turn_overlay.anchor_top = 0.5
	page_turn_overlay.anchor_right = 0.5
	page_turn_overlay.anchor_bottom = 0.5
	page_turn_overlay.offset_left = -588
	page_turn_overlay.offset_top = -340
	page_turn_overlay.offset_right = 588
	page_turn_overlay.offset_bottom = 340
	page_turn_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_turn_overlay.visible = false
	var page_turn_shader: Shader = ThemeColors.get_shader("page_turn")
	if page_turn_shader:
		_page_turn_material = ShaderMaterial.new()
		_page_turn_material.shader = page_turn_shader
		page_turn_overlay.material = _page_turn_material
	add_child(page_turn_overlay)

func _setup_loose_note() -> void:
	loose_note = TextureRect.new()
	loose_note.anchor_left = 0.5
	loose_note.anchor_top = 0.5
	loose_note.anchor_right = 0.5
	loose_note.anchor_bottom = 0.5
	loose_note.offset_left = -530
	loose_note.offset_top = 200
	loose_note.offset_right = -530 + 96
	loose_note.offset_bottom = 200 + 96
	loose_note.stretch_mode = TextureRect.STRETCH_SCALE
	loose_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loose_note.rotation_degrees = -7.0
	var note_tex: Texture2D = ThemeColors.get_texture("tome_loose_note")
	if note_tex:
		loose_note.texture = note_tex
		loose_note.self_modulate = Color(1, 1, 1, 0.6)
	else:
		loose_note.visible = false
	add_child(loose_note)
	_base_note_offset = Vector2(loose_note.offset_left, loose_note.offset_top)

func _setup_footer(parent: VBoxContainer) -> void:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 20)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(footer)

	footer_xp = Label.new()
	ThemeColors.apply_heading_font(footer_xp, ThemeColors.FONT_SIZE_LARGE)
	footer_xp.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	footer.add_child(footer_xp)

	footer_hint = Label.new()
	footer_hint.text = "[1-8] Chapter  [+/-] Invest  [Enter] Open  [Esc] Close"
	ThemeColors.apply_body_font(footer_hint, ThemeColors.FONT_SIZE_HINT - 2)
	footer_hint.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	footer.add_child(footer_hint)

# ===========================================================================
# REFRESH / DISPLAY
# ===========================================================================

func _refresh_all() -> void:
	if not player:
		return
	if current_page == PageState.INDEX:
		_refresh_index_page()
	else:
		_refresh_chapter_page()
	_refresh_footer()
	_update_selection_indicators()
	_update_marginalia()

func _refresh_index_page() -> void:
	for i in range(SKILL_NAMES.size()):
		var skill_name: String = SKILL_NAMES[i]
		var row: Dictionary = skill_rows[i]
		var current_level: int = player.skills.get(skill_name, 0)
		var pending: int = pending_investments.get(skill_name, 0)
		var effective_level: int = current_level + pending

		if pending > 0:
			row.level_label.text = "Lv %d+%d" % [current_level, pending]
			row.level_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
			var total_cost := _get_pending_cost(skill_name)
			row.cost_label.text = "[%d XP]" % total_cost
			row.cost_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
			row.minus_btn.visible = true
			row.buy_btn.disabled = effective_level >= 20 or not _can_afford_invest(skill_name)
		elif current_level >= 20:
			row.level_label.text = "Lv %d" % current_level
			row.level_label.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
			row.cost_label.text = "MASTERED"
			row.cost_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
			row.buy_btn.disabled = true
			row.minus_btn.visible = false
		else:
			row.level_label.text = "Lv %d" % current_level
			row.level_label.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
			var cost: int = player.get_skill_cost(current_level, 1, skill_name)
			row.cost_label.text = "[%d XP]" % cost
			if _can_afford_invest(skill_name):
				row.cost_label.add_theme_color_override("font_color", Color("#2D6A2E"))
			else:
				row.cost_label.add_theme_color_override("font_color", ThemeColors.RED_INK)
			row.buy_btn.disabled = not _can_afford_invest(skill_name)
			row.minus_btn.visible = false

		# [#4] Update preview label with next ability + progress
		var preview := _get_skill_preview(i)
		if preview.learned >= preview.total and preview.total > 0:
			row.preview_label.text = "      MASTERED  |  %d/%d abilities" % [preview.learned, preview.total]
			row.preview_label.add_theme_color_override("font_color", Color(ThemeColors.GOLD_WARM, 0.6))
		elif preview.next_name != "":
			row.preview_label.text = "      Next: %s (Lv %d)  |  %d/%d abilities" % [preview.next_name, preview.next_level, preview.learned, preview.total]
			row.preview_label.add_theme_color_override("font_color", Color(ThemeColors.PARCHMENT_TEXT, 0.5))
		else:
			row.preview_label.text = "      %d abilities" % preview.total
			row.preview_label.add_theme_color_override("font_color", Color(ThemeColors.PARCHMENT_TEXT, 0.4))
	_update_confirm_bar()

# [#4] Helper: get next ability and progress counts for a skill tree
func _get_skill_preview(skill_idx: int) -> Dictionary:
	var abilities := DataManager.get_abilities_for_skill(skill_idx)
	var total: int = abilities.size()
	var learned: int = 0
	var next_name: String = ""
	var next_level: int = -1

	for ability in abilities:
		if _player_has_ability(ability):
			learned += 1
		elif next_name == "":
			next_name = ability.name
			next_level = ability.level_requirement

	return {"next_name": next_name, "next_level": next_level, "learned": learned, "total": total}

func _refresh_chapter_page() -> void:
	var skill_name: String = SKILL_NAMES[selected_skill_idx]

	chapter_header.text = CHAPTER_TITLES[selected_skill_idx]
	chapter_flavor.text = CHAPTER_FLAVORS[selected_skill_idx]

	# Voice bar visibility (Lore only)
	var is_lore: bool = selected_skill_idx == 7
	voice_bar_container.visible = is_lore
	if is_lore and player:
		var max_voice: int = int(20.0 * pow(1.2, player.grace))
		var current_voice: int = player.voice if "voice" in player else 0
		voice_bar.max_value = max_voice
		voice_bar.value = current_voice
		voice_label.text = "%d / %d" % [current_voice, max_voice]

	# Clear ability list
	for child in ability_vbox.get_children():
		child.queue_free()
	ability_buttons.clear()

	# Get abilities for this skill
	var abilities := DataManager.get_abilities_for_skill(selected_skill_idx)
	_ability_list = abilities
	var player_skill_level: int = player.skills.get(skill_name, 0) if player else 0

	# Group by level requirement
	var current_tier: int = -1
	var btn_index: int = 0
	for ability in abilities:
		if ability.level_requirement != current_tier:
			current_tier = ability.level_requirement
			var tier_header := Label.new()
			tier_header.text = "--- Requires Level %d ---" % current_tier
			tier_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ThemeColors.apply_body_font(tier_header, ThemeColors.FONT_SIZE_HINT)
			tier_header.add_theme_color_override("font_color", Color(ThemeColors.PARCHMENT_EDGE, 0.7))
			ability_vbox.add_child(tier_header)

		var btn := _create_ability_row(ability, player_skill_level, btn_index)
		ability_vbox.add_child(btn)
		ability_buttons.append(btn)
		btn_index += 1

	if not abilities.is_empty():
		selected_ability_idx = 0
		_on_ability_selected(0)
	else:
		selected_ability_idx = -1
		_clear_detail()

# [#1] Ability row — LOCKED 60%, BLOCKED 70% (was 20%/40%)
func _create_ability_row(ability: DataManager.AbilityData, player_skill_level: int, idx: int) -> Button:
	var has_it := _player_has_ability(ability)
	var can_learn := _can_learn_ability(ability)
	var meets_level := ability.level_requirement <= player_skill_level
	var has_prereqs := _has_prerequisites(ability)
	var has_xp := player.xp_available >= _get_ability_xp_cost(ability) if player else false

	var name_color: Color
	var use_heading_font: bool = false

	if has_it:
		name_color = ThemeColors.PARCHMENT_TEXT
		use_heading_font = true
	elif can_learn:
		name_color = Color(ThemeColors.PARCHMENT_TEXT, 0.85)
	elif meets_level and has_prereqs and not has_xp:
		name_color = ThemeColors.ABILITY_NO_XP
	elif not meets_level:
		# [#1] LOCKED: 0.2 → 0.6 — readable but clearly disabled
		name_color = Color(ThemeColors.PARCHMENT_TEXT, 0.6)
	else:
		# [#1] BLOCKED (has prereqs unmet): 0.4 → 0.7
		name_color = Color(ThemeColors.PARCHMENT_TEXT, 0.7)

	var btn := Button.new()
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size.y = 34

	var label_text: String = "[%d] %s" % [ability.level_requirement, ability.name]

	if ability.skill_type == 7:
		var vc: int = VOICE_COSTS.get(ability.index, 0)
		if vc > 0:
			label_text += "  [%dv]" % vc

	btn.text = label_text
	btn.add_theme_color_override("font_color", name_color)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0, 0, 0, 0)
	normal_style.content_margin_left = 8
	btn.add_theme_stylebox_override("normal", normal_style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(ThemeColors.PARCHMENT_EDGE, 0.15)
	hover_style.content_margin_left = 8
	btn.add_theme_stylebox_override("hover", hover_style)

	if use_heading_font:
		var heading_font: Font = ThemeColors.get_font("heading")
		if heading_font:
			btn.add_theme_font_override("font", heading_font)
	else:
		var body_font: Font = ThemeColors.get_font("body")
		if body_font:
			btn.add_theme_font_override("font", body_font)
	btn.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)

	btn.pressed.connect(_on_ability_selected.bind(idx))
	return btn

func _on_ability_selected(idx: int) -> void:
	selected_ability_idx = idx
	if idx < 0 or idx >= _ability_list.size():
		_clear_detail()
		return

	var ability: DataManager.AbilityData = _ability_list[idx]
	var has_it := _player_has_ability(ability)
	var can_learn := _can_learn_ability(ability)
	var xp_cost := _get_ability_xp_cost(ability)

	detail_name.text = ability.name
	detail_desc.text = ability.description

	if not ability.prereqs.is_empty():
		var prereq_text := "Prerequisites: "
		var parts: Array[String] = []
		for prereq in ability.prereqs:
			var prereq_skill: int = prereq.get("skill", 0)
			var prereq_ability_idx: int = prereq.get("ability", 0)
			var prereq_name := _find_ability_by_index(prereq_skill, prereq_ability_idx)
			if prereq_name != "":
				var has_prereq := _player_has_ability_by_name(prereq_name)
				var skill_label: String = SKILL_LABELS[prereq_skill] if prereq_skill < SKILL_LABELS.size() else "?"
				if has_prereq:
					parts.append("%s (%s)" % [prereq_name, skill_label])
				else:
					parts.append("%s (%s) [MISSING]" % [prereq_name, skill_label])
		prereq_text += ", ".join(parts)
		detail_prereqs.text = prereq_text
		detail_prereqs.visible = true
	else:
		detail_prereqs.visible = false

	if has_it:
		detail_cost.text = "Inscribed"
		detail_cost.add_theme_color_override("font_color", ThemeColors.ABILITY_LEARNED)
	else:
		detail_cost.text = "Cost: %d XP" % xp_cost
		if player and player.xp_available >= xp_cost:
			detail_cost.add_theme_color_override("font_color", Color("#2D6A2E"))
		else:
			detail_cost.add_theme_color_override("font_color", ThemeColors.MSG_ERROR)

	if ability.skill_type == 7:
		var vc: int = VOICE_COSTS.get(ability.index, 0)
		if vc > 0:
			detail_voice.text = "Voice cost: %d" % vc
			detail_voice.visible = true
		else:
			detail_voice.text = "Passive"
			detail_voice.visible = true
	else:
		detail_voice.visible = false

	if has_it:
		learn_button.text = "Inscribed"
		learn_button.disabled = true
	elif can_learn:
		learn_button.text = "Inscribe (%d XP)" % xp_cost
		learn_button.disabled = false
	else:
		var skill_name: String = SKILL_NAMES[ability.skill_type] if ability.skill_type < SKILL_NAMES.size() else ""
		var player_level: int = player.skills.get(skill_name, 0) if player else 0
		if ability.level_requirement > player_level:
			learn_button.text = "Need %s Lv %d" % [SKILL_LABELS[ability.skill_type], ability.level_requirement]
		elif not _has_prerequisites(ability):
			learn_button.text = "Missing prereqs"
		else:
			learn_button.text = "Need %d XP" % xp_cost
		learn_button.disabled = true

	_update_ability_selection()

func _clear_detail() -> void:
	detail_name.text = "Select an ability"
	detail_desc.text = "Choose an ability from the list above to see its details."
	detail_prereqs.visible = false
	detail_cost.text = ""
	detail_voice.visible = false
	learn_button.text = "Inscribe"
	learn_button.disabled = true

# [#2] Selection indicator — gold bg + 2px left border for selected row
func _update_selection_indicators() -> void:
	for i in range(skill_rows.size()):
		var row: Dictionary = skill_rows[i]
		var btn: Button = row.container
		if i == selected_skill_idx:
			row.name_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
			row.numeral_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
			# Gold background + left border for spatial selection
			var sel_style := StyleBoxFlat.new()
			sel_style.bg_color = Color(ThemeColors.GOLD_WARM, 0.18)
			sel_style.border_width_left = 2
			sel_style.border_color = ThemeColors.GOLD_WARM
			sel_style.content_margin_left = 4
			btn.add_theme_stylebox_override("normal", sel_style)
		else:
			row.name_label.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
			row.numeral_label.add_theme_color_override("font_color", ThemeColors.PARCHMENT_TEXT)
			# Restore transparent normal style
			var norm_style := StyleBoxFlat.new()
			norm_style.bg_color = Color(0, 0, 0, 0)
			norm_style.content_margin_left = 4
			btn.add_theme_stylebox_override("normal", norm_style)

func _update_ability_selection() -> void:
	for i in range(ability_buttons.size()):
		var btn: Button = ability_buttons[i]
		if i == selected_ability_idx:
			btn.add_theme_stylebox_override("focus", ThemeColors.create_panel_stylebox(
				Color(ThemeColors.GOLD_WARM, 0.12), ThemeColors.GOLD_WARM, 1, 2))
		else:
			btn.remove_theme_stylebox_override("focus")

func _update_marginalia() -> void:
	var skill_name: String = SKILL_NAMES[selected_skill_idx]
	var quotes: Array = MARGINALIA.get(skill_name, [])
	if not quotes.is_empty():
		var quote_idx: int = (selected_skill_idx * 3 + (GameManager.turn_count if GameManager else 0)) % quotes.size()
		marginalia_label.text = "\"%s\"" % quotes[quote_idx]
	else:
		marginalia_label.text = ""

func _refresh_footer() -> void:
	if player:
		footer_xp.text = "XP: %d available  |  %d total earned" % [player.xp_available, player.total_xp_earned]
	else:
		footer_xp.text = "XP: ---"
	if current_page == PageState.INDEX:
		footer_hint.text = "[1-8] Chapter  [+/-] Invest  [Enter] Open  [Esc] Close"
	else:
		footer_hint.text = "[1-8] Chapter  [J/K] Navigate  [Enter] Inscribe  [Esc] Back"

# ===========================================================================
# NAVIGATION
# ===========================================================================

func _navigate_to_chapter(skill_idx: int) -> void:
	selected_skill_idx = skill_idx
	selected_ability_idx = -1
	current_page = PageState.CHAPTER
	_play_page_turn(skill_idx, true)
	_update_selection_indicators()
	_update_marginalia()
	_randomize_loose_note(skill_idx)

func _navigate_to_index() -> void:
	current_page = PageState.INDEX
	_play_page_turn(selected_skill_idx, false)
	_update_selection_indicators()

func _swap_page_texture_instant() -> void:
	if current_page == PageState.INDEX:
		var index_tex: Texture2D = ThemeColors.get_texture("tome_page_index")
		if index_tex and page_bg:
			page_bg.texture = index_tex
	else:
		var page_key: String = SKILL_PAGE_KEYS[selected_skill_idx] if selected_skill_idx < SKILL_PAGE_KEYS.size() else ""
		if page_key != "":
			var tex: Texture2D = ThemeColors.get_texture(page_key)
			if tex and page_bg:
				page_bg.texture = tex

# ===========================================================================
# ACTIONS
# ===========================================================================

func _select_skill(idx: int) -> void:
	if current_page == PageState.INDEX:
		if idx != selected_skill_idx:
			selected_skill_idx = idx
			_update_selection_indicators()
			_update_marginalia()
			_randomize_loose_note(idx)
		_navigate_to_chapter(idx)
	else:
		if idx != selected_skill_idx:
			_navigate_to_chapter(idx)

func _play_page_turn(_skill_idx: int, to_chapter: bool) -> void:
	if _is_turning_page:
		_finish_page_turn_swap(to_chapter, _skill_idx if to_chapter else -1)
		return

	_is_turning_page = true

	page_turn_overlay.visible = true
	page_turn_overlay.color = Color(0.08, 0.06, 0.04, 0.0)
	page_turn_overlay.material = null

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	tween.tween_property(page_turn_overlay, "color:a", 0.7, 0.12)
	tween.tween_callback(_finish_page_turn_swap.bind(to_chapter, _skill_idx if to_chapter else -1))
	tween.tween_property(page_turn_overlay, "color:a", 0.0, 0.15)
	tween.tween_callback(_finish_page_turn_cleanup)

func _finish_page_turn_swap(to_chapter: bool, skill_idx: int) -> void:
	if to_chapter:
		if skill_idx >= 0 and skill_idx < SKILL_PAGE_KEYS.size():
			var page_key: String = SKILL_PAGE_KEYS[skill_idx]
			var tex: Texture2D = ThemeColors.get_texture(page_key)
			if tex and page_bg:
				page_bg.texture = tex
		index_content.visible = false
		chapter_content.visible = true
		_refresh_chapter_page()
	else:
		var index_tex: Texture2D = ThemeColors.get_texture("tome_page_index")
		if index_tex and page_bg:
			page_bg.texture = index_tex
		chapter_content.visible = false
		index_content.visible = true
		_refresh_index_page()
	_refresh_footer()

func _finish_page_turn_cleanup() -> void:
	_is_turning_page = false
	page_turn_overlay.visible = false
	if _page_turn_material:
		_page_turn_material.set_shader_parameter("progress", 0.0)

func _randomize_loose_note(skill_idx: int) -> void:
	if not loose_note or not loose_note.visible:
		return
	var rng_x: float = fmod(sin(float(skill_idx) * 73.17) * 43758.5453, 1.0)
	var rng_y: float = fmod(sin(float(skill_idx) * 127.33) * 24634.6345, 1.0)
	var rng_rot: float = fmod(sin(float(skill_idx) * 31.71) * 91827.3456, 1.0)
	var new_left: float = _base_note_offset.x + (rng_x - 0.5) * 60.0
	var new_top: float = _base_note_offset.y + (rng_y - 0.5) * 40.0
	var rotation: float = -12.0 + rng_rot * 18.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(true)
	tween.tween_property(loose_note, "offset_left", new_left, 0.25)
	tween.tween_property(loose_note, "offset_top", new_top, 0.25)
	tween.tween_property(loose_note, "offset_right", new_left + 96.0, 0.25)
	tween.tween_property(loose_note, "offset_bottom", new_top + 96.0, 0.25)
	tween.tween_property(loose_note, "rotation_degrees", rotation, 0.25)

func _on_skill_invest(idx: int) -> void:
	if not player:
		return
	var skill_name: String = SKILL_NAMES[idx]
	var current_level: int = player.skills.get(skill_name, 0)
	var pending: int = pending_investments.get(skill_name, 0)
	if current_level + pending >= 20:
		return
	if not _can_afford_invest(skill_name):
		return
	pending_investments[skill_name] = pending + 1
	_refresh_index_page()
	_update_selection_indicators()

func _on_skill_decrement(idx: int) -> void:
	var skill_name: String = SKILL_NAMES[idx]
	var pending: int = pending_investments.get(skill_name, 0)
	if pending > 0:
		pending_investments[skill_name] = pending - 1
		if pending_investments[skill_name] == 0:
			pending_investments.erase(skill_name)
		_refresh_index_page()
		_update_selection_indicators()

func _confirm_investments() -> void:
	if not player or pending_investments.is_empty():
		return
	for skill_name in pending_investments.keys():
		var count: int = pending_investments[skill_name]
		for i in range(count):
			player.invest_skill(skill_name)
		skill_increased.emit(skill_name, player.skills[skill_name])
	var tween := create_tween()
	tween.tween_property(footer_xp, "modulate", Color(ThemeColors.GOLD_BRIGHT, 1.0), 0.1)
	tween.tween_property(footer_xp, "modulate", Color.WHITE, 0.15)
	pending_investments.clear()
	_refresh_all()

func _cancel_investments() -> void:
	pending_investments.clear()
	_refresh_index_page()
	_update_selection_indicators()

func _get_pending_cost(skill_name: String) -> int:
	var pending: int = pending_investments.get(skill_name, 0)
	if pending <= 0:
		return 0
	var current_level: int = player.skills.get(skill_name, 0)
	var total: int = 0
	for i in range(pending):
		total += player.get_skill_cost(current_level + i, 1, skill_name)
	return total

func _can_afford_invest(skill_name: String) -> bool:
	if not player:
		return false
	var pending: int = pending_investments.get(skill_name, 0)
	var current_level: int = player.skills.get(skill_name, 0)
	if current_level + pending >= 20:
		return false
	var total_reserved: int = 0
	for sn in pending_investments.keys():
		total_reserved += _get_pending_cost(sn)
	var next_cost: int = player.get_skill_cost(current_level + pending, 1, skill_name)
	return player.xp_available >= total_reserved + next_cost

func _update_confirm_bar() -> void:
	var has_pending := not pending_investments.is_empty()
	confirm_bar.visible = has_pending
	if has_pending:
		var total_points: int = 0
		var total_cost: int = 0
		for skill_name in pending_investments.keys():
			total_points += pending_investments[skill_name]
			total_cost += _get_pending_cost(skill_name)
		confirm_label.text = "%d point%s (%d XP)" % [total_points, "s" if total_points > 1 else "", total_cost]

func _on_learn_pressed() -> void:
	if selected_ability_idx < 0 or selected_ability_idx >= _ability_list.size():
		return
	if not player:
		return

	var ability: DataManager.AbilityData = _ability_list[selected_ability_idx]
	var xp_cost := _get_ability_xp_cost(ability)

	if not _can_learn_ability(ability):
		return

	player.xp_available -= xp_cost

	if not player.has_meta("learned_abilities"):
		player.set_meta("learned_abilities", [])
	var learned: Array = player.get_meta("learned_abilities")
	learned.append(ability.name)
	player.set_meta("learned_abilities", learned)

	player.learn_ability(ability.skill_type, ability.ability_num)

	GameManager.log_message("You have inscribed %s!" % ability.name, ThemeColors.PRIMARY)
	ability_purchased.emit(ability.name)

	var tween := create_tween()
	tween.tween_property(learn_button, "modulate", Color(ThemeColors.GOLD_BRIGHT, 1.0), 0.15)
	tween.tween_property(learn_button, "modulate", Color.WHITE, 0.15)

	_refresh_all()

# ===========================================================================
# ABILITY HELPERS
# ===========================================================================

func _player_has_ability(ability: DataManager.AbilityData) -> bool:
	if not player or not player.has_meta("learned_abilities"):
		return false
	var learned: Array = player.get_meta("learned_abilities")
	return learned.has(ability.name)

func _player_has_ability_by_name(ability_name: String) -> bool:
	if not player or not player.has_meta("learned_abilities"):
		return false
	var learned: Array = player.get_meta("learned_abilities")
	return learned.has(ability_name)

func _can_learn_ability(ability: DataManager.AbilityData) -> bool:
	if not player:
		return false
	if _player_has_ability(ability):
		return false
	var skill_key: String = SKILL_NAMES[ability.skill_type] if ability.skill_type < SKILL_NAMES.size() else ""
	var player_skill_level: int = player.skills.get(skill_key, 0)
	if player_skill_level < ability.level_requirement:
		return false
	if not _has_prerequisites(ability):
		return false
	var xp_cost := _get_ability_xp_cost(ability)
	if player.xp_available < xp_cost:
		return false
	return true

func _has_prerequisites(ability: DataManager.AbilityData) -> bool:
	for prereq in ability.prereqs:
		var prereq_skill: int = prereq.get("skill", 0)
		var prereq_ability_idx: int = prereq.get("ability", 0)
		var prereq_name := _find_ability_by_index(prereq_skill, prereq_ability_idx)
		if prereq_name != "" and not _player_has_ability_by_name(prereq_name):
			return false
	return true

func _find_ability_by_index(skill_type: int, ability_num: int) -> String:
	for ability in DataManager.abilities.values():
		if ability.skill_type == skill_type and ability.ability_num == ability_num:
			return ability.name
	return ""

func _get_ability_xp_cost(ability: DataManager.AbilityData) -> int:
	return (ability.level_requirement + 1) * 300

# ===========================================================================
# INPUT
# ===========================================================================

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		if current_page == PageState.CHAPTER:
			_navigate_to_index()
		elif not pending_investments.is_empty():
			_cancel_investments()
		else:
			close()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("skills") or event.is_action_pressed("abilities"):
		close()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_T and not event.shift_pressed and not event.echo:
		close()
		get_viewport().set_input_as_handled()
		return

	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var key_index: int = -1
	match event.keycode:
		KEY_1: key_index = 0
		KEY_2: key_index = 1
		KEY_3: key_index = 2
		KEY_4: key_index = 3
		KEY_5: key_index = 4
		KEY_6: key_index = 5
		KEY_7: key_index = 6
		KEY_8: key_index = 7

	if key_index >= 0:
		_navigate_to_chapter(key_index)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_BACKSPACE and current_page == PageState.CHAPTER:
		_navigate_to_index()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
		_on_skill_invest(selected_skill_idx)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
		_on_skill_decrement(selected_skill_idx)
		get_viewport().set_input_as_handled()
		return

	if current_page == PageState.INDEX:
		if event.keycode == KEY_UP or event.keycode == KEY_K:
			var new_idx := maxi(0, selected_skill_idx - 1)
			if new_idx != selected_skill_idx:
				selected_skill_idx = new_idx
				_update_selection_indicators()
				_update_marginalia()
				_randomize_loose_note(new_idx)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN or event.keycode == KEY_J:
			var new_idx := mini(SKILL_NAMES.size() - 1, selected_skill_idx + 1)
			if new_idx != selected_skill_idx:
				selected_skill_idx = new_idx
				_update_selection_indicators()
				_update_marginalia()
				_randomize_loose_note(new_idx)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if not pending_investments.is_empty():
				_confirm_investments()
			else:
				_navigate_to_chapter(selected_skill_idx)
			get_viewport().set_input_as_handled()
	else:
		if event.keycode == KEY_UP or event.keycode == KEY_K:
			if selected_ability_idx > 0:
				_on_ability_selected(selected_ability_idx - 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN or event.keycode == KEY_J:
			if selected_ability_idx < _ability_list.size() - 1:
				_on_ability_selected(selected_ability_idx + 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_learn_pressed()
			get_viewport().set_input_as_handled()
