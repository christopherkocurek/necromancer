extends Control
## Settings panel with Display, Accessibility, and Controls tabs.

signal closed

@onready var tab_container: TabContainer = $Panel/VBoxContainer/TabContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

func _ready() -> void:
	visible = false
	_setup_tabs()
	close_button.pressed.connect(close)
	ThemeColors.apply_button_theme(close_button)

func open() -> void:
	visible = true
	_refresh_all()
	grab_focus()

func close() -> void:
	AccessibilityManager.save_settings()
	visible = false
	closed.emit()

func _setup_tabs() -> void:
	# Display tab
	var display_tab := VBoxContainer.new()
	display_tab.name = "Display"
	_add_toggle(display_tab, "Screen Shake", AccessibilityManager.screen_shake_enabled, func(v: bool) -> void: AccessibilityManager.screen_shake_enabled = v)
	_add_slider(display_tab, "Animation Speed", 0.5, 2.0, AccessibilityManager.animation_speed, func(v: float) -> void: AccessibilityManager.animation_speed = v)
	_add_slider(display_tab, "Font Scale", 0.8, 1.5, AccessibilityManager.font_scale, func(v: float) -> void: AccessibilityManager.font_scale = v)
	tab_container.add_child(display_tab)

	# Accessibility tab
	var access_tab := VBoxContainer.new()
	access_tab.name = "Accessibility"
	_add_toggle(access_tab, "God Mode (Protective Blessing)", AccessibilityManager.god_mode_enabled, func(v: bool) -> void:
		AccessibilityManager.god_mode_enabled = v
	)
	var god_info := Label.new()
	god_info.text = "Current damage reduction: %.0f%% (increases with each death)" % (AccessibilityManager.god_mode_reduction * 100)
	god_info.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	access_tab.add_child(god_info)
	_add_dropdown(access_tab, "Colorblind Mode", ["None", "Protanopia", "Deuteranopia", "Tritanopia"], func(idx: int) -> void:
		var modes := ["none", "protanopia", "deuteranopia", "tritanopia"]
		AccessibilityManager.colorblind_mode = modes[idx]
	)
	_add_toggle(access_tab, "High Contrast", AccessibilityManager.high_contrast, func(v: bool) -> void: AccessibilityManager.high_contrast = v)
	tab_container.add_child(access_tab)

	# Controls tab
	var controls_tab := VBoxContainer.new()
	controls_tab.name = "Controls"
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var actions := InputMap.get_actions()
	for action in actions:
		if action.begins_with("ui_"):
			continue
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = action.capitalize().replace("_", " ")
		name_label.custom_minimum_size.x = 200
		ThemeColors.apply_body_font(name_label)
		row.add_child(name_label)
		var events := InputMap.action_get_events(action)
		var key_label := Label.new()
		if not events.is_empty():
			key_label.text = events[0].as_text()
		else:
			key_label.text = "Unbound"
		key_label.custom_minimum_size.x = 200
		key_label.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
		row.add_child(key_label)
		var rebind_btn := Button.new()
		rebind_btn.text = "Rebind"
		rebind_btn.pressed.connect(_start_rebind.bind(action, key_label))
		ThemeColors.apply_button_theme(rebind_btn)
		row.add_child(rebind_btn)
		vbox.add_child(row)
	scroll.add_child(vbox)
	controls_tab.add_child(scroll)
	tab_container.add_child(controls_tab)

	# Audio tab (placeholder)
	var audio_tab := VBoxContainer.new()
	audio_tab.name = "Audio"
	var placeholder := Label.new()
	placeholder.text = "Audio settings coming soon."
	placeholder.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	audio_tab.add_child(placeholder)
	tab_container.add_child(audio_tab)

var _rebinding_action: String = ""
var _rebinding_label: Label = null

func _start_rebind(action: String, label: Label) -> void:
	_rebinding_action = action
	_rebinding_label = label
	label.text = "Press a key..."
	label.add_theme_color_override("font_color", ThemeColors.PRIMARY)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and _rebinding_action.is_empty():
		close()
		get_viewport().set_input_as_handled()
		return
	if not _rebinding_action.is_empty() and event is InputEventKey and event.pressed:
		InputMap.action_erase_events(_rebinding_action)
		InputMap.action_add_event(_rebinding_action, event)
		if _rebinding_label:
			_rebinding_label.text = event.as_text()
			_rebinding_label.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
		_rebinding_action = ""
		_rebinding_label = null
		get_viewport().set_input_as_handled()

func _refresh_all() -> void:
	pass

func _add_toggle(parent: VBoxContainer, label_text: String, initial: bool, callback: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 300
	ThemeColors.apply_body_font(label)
	row.add_child(label)
	var toggle := CheckButton.new()
	toggle.button_pressed = initial
	toggle.toggled.connect(callback)
	row.add_child(toggle)
	parent.add_child(row)

func _add_slider(parent: VBoxContainer, label_text: String, min_val: float, max_val: float, initial: float, callback: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 300
	ThemeColors.apply_body_font(label)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = initial
	slider.step = 0.05
	slider.custom_minimum_size.x = 200
	slider.value_changed.connect(callback)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.text = "%.2f" % initial
	ThemeColors.apply_body_font(value_label, ThemeColors.FONT_SIZE_HINT)
	slider.value_changed.connect(func(v: float) -> void: value_label.text = "%.2f" % v)
	row.add_child(value_label)
	parent.add_child(row)

func _add_dropdown(parent: VBoxContainer, label_text: String, options: Array, callback: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 300
	ThemeColors.apply_body_font(label)
	row.add_child(label)
	var dropdown := OptionButton.new()
	for opt in options:
		dropdown.add_item(opt)
	dropdown.item_selected.connect(callback)
	row.add_child(dropdown)
	parent.add_child(row)
