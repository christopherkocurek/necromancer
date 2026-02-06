extends Control
class_name ConfirmDialog
## Simple modal confirmation dialog: "Drop X? [Y/N]"

signal confirmed
signal cancelled

var _label: Label = null
var _panel: PanelContainer = null

func _ready() -> void:
	_setup_ui()
	hide()

func _setup_ui() -> void:
	# Full-screen dim overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.mouse_filter = MOUSE_FILTER_STOP
	add_child(overlay)

	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(300, 80)
	_panel.add_theme_stylebox_override("panel", ThemeColors.create_panel_stylebox(
		ThemeColors.BG_SURFACE, ThemeColors.BORDER_FOCUS, 2, 6
	))
	add_child(_panel)

	# Center the panel properly
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -150
	_panel.offset_top = -40
	_panel.offset_right = 150
	_panel.offset_bottom = 40

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	vbox.add_child(_label)

	var hint := Label.new()
	hint.text = "[Y] Confirm    [N] Cancel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	hint.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_BODY)
	vbox.add_child(hint)

func show_confirm(message: String) -> void:
	_label.text = message
	show()
	# Brief scale-in
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.9, 0.9)
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.1)

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Y, KEY_ENTER:
				hide()
				confirmed.emit()
			KEY_N, KEY_ESCAPE:
				hide()
				cancelled.emit()
		get_viewport().set_input_as_handled()
