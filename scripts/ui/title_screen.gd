extends Control
class_name TitleScreen

signal enter_dungeon_pressed

const TITLE_ART_PATH := "res://assets/concept_art/title_screen_dalle3/variations_best01/generated/e1_h2_elf_lord_forest_regen_v5_blueblade_towertilt_spider.png"

@onready var background_rect: TextureRect = $Background
@onready var overlay_rect: ColorRect = $Overlay
@onready var title_label: Label = $TitleLabel
@onready var poem_label: RichTextLabel = $PoemLabel
@onready var cta_button: Button = $CTAButton

const TITLE_POEM_BBCODE: String = "[center]Beneath the boughs where shadow reigns,\nA black hill drinks the moon.\nDol Guldur binds forgotten chains,\nAnd old hearts fail too soon.\n\nTake up the light no night can drown,\nSeek Thrain through iron grief.\nBear ring and key from deep earth down,\nWin one small dawn's reprieve.\n\nIf courage holds where torches die,\nThe dark need not endure.\nGo now, and dare the Lidless Eye,\nIn halls where none are sure.[/center]"

func _ready() -> void:
	_load_background_texture()
	if AudioManager:
		AudioManager.play_music("main_theme")

	if is_instance_valid(ThemeColors):
		ThemeColors.apply_heading_font(title_label, ThemeColors.FONT_SIZE_TITLE)
		title_label.add_theme_color_override("font_color", ThemeColors.GOLD_BRIGHT)
		ThemeColors.apply_rich_body_font(poem_label, ThemeColors.FONT_SIZE_BODY)
		poem_label.add_theme_color_override("default_color", ThemeColors.TEXT_PRIMARY)
		cta_button.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
		cta_button.add_theme_color_override("font_hover_color", ThemeColors.GOLD_BRIGHT)
		cta_button.add_theme_color_override("font_pressed_color", ThemeColors.GOLD_WARM)
		cta_button.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_LARGE)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.05, 0.07, 0.10, 0.78)
	normal_style.border_color = Color(0.78, 0.66, 0.30, 0.95)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.09, 0.12, 0.18, 0.86)
	hover_style.border_color = Color(0.92, 0.82, 0.50, 1.0)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.03, 0.04, 0.07, 0.92)

	cta_button.add_theme_stylebox_override("normal", normal_style)
	cta_button.add_theme_stylebox_override("hover", hover_style)
	cta_button.add_theme_stylebox_override("pressed", pressed_style)
	cta_button.add_theme_stylebox_override("focus", hover_style)

	cta_button.pressed.connect(_on_cta_pressed)
	cta_button.mouse_entered.connect(_on_cta_hovered)
	cta_button.mouse_exited.connect(_on_cta_unhovered)
	cta_button.grab_focus()
	poem_label.text = TITLE_POEM_BBCODE

	_play_intro_animation()
	_start_cta_pulse()

func _load_background_texture() -> void:
	var texture: Texture2D = load(TITLE_ART_PATH)
	if texture == null:
		push_warning("Title art failed to load: %s" % TITLE_ART_PATH)
		return
	background_rect.texture = texture

func _play_intro_animation() -> void:
	modulate.a = 0.0
	title_label.modulate.a = 0.0
	poem_label.modulate.a = 0.0
	cta_button.modulate.a = 0.0
	var cta_start_y: float = cta_button.position.y + 24.0
	cta_button.position.y = cta_start_y
	overlay_rect.color.a = 0.55

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.55)
	tween.tween_property(overlay_rect, "color:a", 0.38, 0.65)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.65)
	tween.tween_property(poem_label, "modulate:a", 1.0, 0.8)
	tween.tween_property(cta_button, "modulate:a", 1.0, 0.65)
	tween.tween_property(cta_button, "position:y", cta_start_y - 24.0, 0.65)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _start_cta_pulse() -> void:
	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(cta_button, "modulate:a", 1.0, 0.9)
	pulse.tween_property(cta_button, "modulate:a", 0.9, 0.9)

func _on_cta_hovered() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(cta_button, "scale", Vector2(1.03, 1.03), 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(cta_button, "modulate:a", 1.0, 0.12)

func _on_cta_unhovered() -> void:
	var tween := create_tween()
	tween.tween_property(cta_button, "scale", Vector2.ONE, 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_cta_pressed() -> void:
	enter_dungeon_pressed.emit()
