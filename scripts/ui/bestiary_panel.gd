extends Control
## Monster bestiary using MonsterMemory data.

signal closed

var _monster_list: ItemList
var _detail_label: RichTextLabel
var _monster_memory: RefCounted = null  # MonsterMemory reference
var _observed_ids: Array = []  # Array of monster_id ints

func _ready() -> void:
	visible = false
	_setup_ui()

func _setup_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)
	var style := ThemeColors.create_panel_stylebox(ThemeColors.BG_DARK, ThemeColors.BORDER_DEFAULT, 2, 8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(PRESET_FULL_RECT)
	panel.add_child(hbox)

	# Left: monster list
	var left_panel := VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.4
	var title := Label.new()
	title.text = "Bestiary"
	title.add_theme_color_override("font_color", ThemeColors.PRIMARY)
	title.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_H2)
	left_panel.add_child(title)
	_monster_list = ItemList.new()
	_monster_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_monster_list.item_selected.connect(_on_monster_selected)
	_monster_list.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	left_panel.add_child(_monster_list)
	hbox.add_child(left_panel)

	# Right: detail panel
	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 0.6
	_detail_label = RichTextLabel.new()
	_detail_label.bbcode_enabled = true
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_label.add_theme_color_override("default_color", ThemeColors.TEXT_PRIMARY)
	right_panel.add_child(_detail_label)
	hbox.add_child(right_panel)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close [Esc]"
	close_btn.pressed.connect(close)
	left_panel.add_child(close_btn)

func open(memory: RefCounted) -> void:
	_monster_memory = memory
	visible = true
	_refresh_list()
	grab_focus()

func close() -> void:
	visible = false
	closed.emit()

func _refresh_list() -> void:
	_monster_list.clear()
	_observed_ids.clear()
	if not _monster_memory:
		_detail_label.text = "No monster data available."
		return

	# Get all observed monster IDs from monster_memory.seen_monsters
	var ids: Array = _monster_memory.seen_monsters.keys()
	ids.sort()

	for monster_id in ids:
		_observed_ids.append(monster_id)
		var tier: int = _monster_memory.get_knowledge_tier(monster_id)
		var display_name: String = _monster_memory.monster_names.get(monster_id, "???")
		if tier <= 0:
			display_name = "???"
		_monster_list.add_item(display_name)

func _on_monster_selected(index: int) -> void:
	if index < 0 or index >= _observed_ids.size():
		return
	var monster_id: int = _observed_ids[index]
	_show_monster_detail(monster_id)

func _show_monster_detail(monster_id: int) -> void:
	if not _monster_memory:
		return
	var tier: int = _monster_memory.get_knowledge_tier(monster_id)
	var monster_name: String = _monster_memory.monster_names.get(monster_id, "Unknown")
	var gold := ThemeColors.PRIMARY.to_html(false)
	var muted := ThemeColors.TEXT_MUTED.to_html(false)

	var text := "[color=#%s][b]%s[/b][/color]\n" % [gold, monster_name]
	text += "[color=#%s]Knowledge: Tier %d[/color]\n\n" % [muted, tier]

	if tier <= 0:
		text += "You have not observed this creature closely enough to learn anything."
	elif tier == 1:
		text += "You have glimpsed this creature but know little about it."
	elif tier >= 2:
		# Show basic info from DataManager
		var monster_data: Variant = DataManager.get_monster(monster_name)
		if monster_data:
			if "speed" in monster_data:
				text += "Speed: %d\n" % monster_data.speed
			if tier >= 3:
				if "hp" in monster_data:
					text += "HP: %d\n" % monster_data.hp
				if "melee" in monster_data:
					text += "Melee: %+d\n" % monster_data.melee
				if "evasion" in monster_data:
					text += "Evasion: %+d\n" % monster_data.evasion
				if "damage_dice" in monster_data:
					text += "Damage: %s\n" % monster_data.damage_dice
				if "flags" in monster_data and not monster_data.flags.is_empty():
					text += "\nTraits: %s" % ", ".join(monster_data.flags)
		else:
			text += "[color=#%s]No detailed data available.[/color]" % muted

	_detail_label.text = text

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
