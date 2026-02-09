extends Control
class_name CharacterPanel
## Character profile screen — read-only display of player stats, skills, flags, and abilities.
## Opened with C key during gameplay or from the death screen.

signal closed

var player: Player = null
var _content_label: RichTextLabel

func _ready() -> void:
	visible = false
	_setup_ui()

func _setup_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)
	var style: StyleBox
	if ThemeColors.has_textures():
		style = ThemeColors.create_textured_panel("panel_stone", 8.0)
	else:
		style = ThemeColors.create_panel_stylebox(ThemeColors.STONE_DARK, ThemeColors.IRON_HIGHLIGHT, 2, 4)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Character"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ThemeColors.apply_heading_font(title, ThemeColors.FONT_SIZE_H2)
	vbox.add_child(title)

	# Scrollable content
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_content_label = RichTextLabel.new()
	_content_label.bbcode_enabled = true
	_content_label.fit_content = true
	_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_label.add_theme_color_override("default_color", ThemeColors.TEXT_PRIMARY)
	ThemeColors.apply_rich_body_font(_content_label)
	scroll.add_child(_content_label)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close [Esc]"
	close_btn.pressed.connect(close)
	ThemeColors.apply_button_theme(close_btn)
	vbox.add_child(close_btn)

func open(p: Player) -> void:
	player = p
	visible = true
	_refresh()
	grab_focus()

func close() -> void:
	visible = false
	closed.emit()

func _refresh() -> void:
	if not player:
		_content_label.text = "No character data."
		return

	var gold: String = ThemeColors.GOLD_WARM.to_html(false)
	var muted: String = ThemeColors.TEXT_MUTED.to_html(false)
	var green: String = ThemeColors.ABILITY_LEARNED.to_html(false)
	var red: String = ThemeColors.HEALTH_LOW.to_html(false)
	var secondary: String = ThemeColors.TEXT_SECONDARY.to_html(false)

	var text: String = ""

	# --- Identity ---
	var house_str: String = " of %s" % player.house_name if not player.house_name.is_empty() else ""
	var trait_str: String = " (%s)" % player.trait_name if not player.trait_name.is_empty() else ""
	text += "[color=#%s][b]%s[/b][/color]\n" % [gold, player.entity_name]
	text += "%s%s%s\n\n" % [player.race_name, house_str, trait_str]

	# --- Attributes ---
	text += "[color=#%s][b]Attributes[/b][/color]\n" % gold
	text += _format_stat("STR", player.strength, player._equip_str_bonus)
	text += _format_stat("DEX", player.dexterity, player._equip_dex_bonus)
	text += _format_stat("CON", player.constitution, player._equip_con_bonus)
	text += _format_stat("GRA", player.grace, player._equip_gra_bonus)
	text += "\n"

	# --- Combat ---
	text += "[color=#%s][b]Combat[/b][/color]\n" % gold
	text += "  Attack:      [color=#%s]%+d[/color]\n" % [secondary, player.melee_bonus]
	text += "  Evasion:     [color=#%s]%+d[/color]\n" % [secondary, player.evasion_bonus]
	text += "  Weapon:      [color=#%s]%s[/color]\n" % [secondary, player.get_weapon_damage_dice()]
	if player.protection_dice > 0 and player.protection_sides > 0:
		text += "  Protection:  [color=#%s]%dd%d[/color]\n" % [secondary, player.protection_dice, player.protection_sides]
	else:
		text += "  Protection:  [color=#%s]none[/color]\n" % muted
	text += "  Health:      [color=#%s]%d / %d[/color]\n" % [secondary, player.current_health, player.max_health]
	text += "  Voice:       [color=#%s]%d / %d[/color]\n" % [secondary, player.voice_charges, player.max_voice]
	text += "\n"

	# --- Experience ---
	text += "[color=#%s][b]Experience[/b][/color]\n" % gold
	text += "  Available:   [color=#%s]%d XP[/color]\n" % [secondary, player.xp_available]
	text += "  Total earned:[color=#%s]%d XP[/color]\n" % [secondary, player.total_xp_earned]
	text += "\n"

	# --- Skills ---
	text += "[color=#%s][b]Skills[/b][/color]\n" % gold
	var skill_order: Array[String] = ["melee", "archery", "evasion", "stealth", "hunting", "will", "smithing", "lore"]
	for skill_name in skill_order:
		var base_level: int = player.skills.get(skill_name, 0)
		var equip_bonus: int = player.equip_skill_bonuses.get(skill_name, 0)
		var color: String = ThemeColors.get_skill_color(skill_name).to_html(false)
		var affinity_mark: String = ""
		if player.has_affinity(skill_name):
			affinity_mark = " [color=#%s]*[/color]" % gold
		var bonus_str: String = ""
		if equip_bonus > 0:
			bonus_str = " [color=#%s](+%d)[/color]" % [green, equip_bonus]
		elif equip_bonus < 0:
			bonus_str = " [color=#%s](%d)[/color]" % [red, equip_bonus]
		# Count learned abilities for this skill
		var skill_idx: int = _skill_name_to_index(skill_name)
		var learned_count: int = 0
		if skill_idx >= 0 and skill_idx < player.innate_ability.size():
			for ab_learned in player.innate_ability[skill_idx]:
				if ab_learned:
					learned_count += 1
		var ability_str: String = ""
		if learned_count > 0:
			ability_str = " [color=#%s](%d abilities)[/color]" % [muted, learned_count]
		text += "  [color=#%s]%-10s[/color] %d%s%s%s\n" % [color, skill_name.capitalize(), base_level, bonus_str, affinity_mark, ability_str]
	text += "\n"

	# --- Equipment Flags (Resistances & Properties) ---
	var positive_flags: Array[String] = []
	var negative_flags: Array[String] = []
	for flag in player.equip_flags:
		if flag in TooltipManager.FLAG_DESCRIPTIONS:
			var desc: String = TooltipManager.FLAG_DESCRIPTIONS[flag]
			if flag in TooltipManager.NEGATIVE_FLAGS:
				negative_flags.append(desc)
			else:
				positive_flags.append(desc)
		elif flag in TooltipManager.STAT_FLAG_DESCRIPTIONS:
			# Stat flags handled by attribute display, skip
			pass

	if not positive_flags.is_empty() or not negative_flags.is_empty():
		text += "[color=#%s][b]Equipment Properties[/b][/color]\n" % gold
		for desc in positive_flags:
			text += "  [color=#%s]%s[/color]\n" % [green, desc]
		for desc in negative_flags:
			text += "  [color=#%s]%s[/color]\n" % [red, desc]
		text += "\n"

	# --- Active Status Effects ---
	var active_statuses: Array[String] = []
	if player.status_effects.size() > 0:
		for effect_name in player.status_effects:
			var effect_data: Variant = player.status_effects[effect_name]
			var duration: int = effect_data.duration if effect_data is Dictionary and "duration" in effect_data else 0
			var status_color: String = ThemeColors.get_status_color(effect_name).to_html(false)
			if duration > 0:
				active_statuses.append("[color=#%s]%s[/color] (%d turns)" % [status_color, effect_name.capitalize(), duration])
			else:
				active_statuses.append("[color=#%s]%s[/color]" % [status_color, effect_name.capitalize()])

	if not active_statuses.is_empty():
		text += "[color=#%s][b]Status Effects[/b][/color]\n" % gold
		for status_str in active_statuses:
			text += "  %s\n" % status_str
		text += "\n"

	# --- Stealth ---
	if player.stealth_mode:
		text += "[color=#%s][b]Stealth Mode Active[/b][/color]\n" % ThemeColors.SKILL_STEALTH.to_html(false)
		text += "  +5 stealth, +5 hunting, 2x movement cost\n"
		text += "\n"

	# --- Hunger ---
	var hunger_state: String = ""
	if player.hunger <= Player.HUNGER_STARVING:
		hunger_state = "[color=#%s]Starving[/color]" % red
	elif player.hunger <= Player.HUNGER_FAMISHED:
		hunger_state = "[color=#%s]Famished[/color]" % red
	elif player.hunger <= Player.HUNGER_HUNGRY:
		hunger_state = "[color=#%s]Hungry[/color]" % ThemeColors.MSG_WARNING.to_html(false)
	elif player.hunger <= Player.HUNGER_NORMAL:
		hunger_state = "[color=#%s]Normal[/color]" % secondary
	else:
		hunger_state = "[color=#%s]Well Fed[/color]" % green

	text += "[color=#%s][b]Condition[/b][/color]\n" % gold
	text += "  Hunger: %s\n" % hunger_state
	text += "  Depth:  [color=#%s]%d feet[/color]\n" % [secondary, GameManager.current_depth * 50]

	_content_label.text = text

func _format_stat(label: String, base: int, equip_bonus: int) -> String:
	var secondary: String = ThemeColors.TEXT_SECONDARY.to_html(false)
	var green: String = ThemeColors.ABILITY_LEARNED.to_html(false)
	var red: String = ThemeColors.HEALTH_LOW.to_html(false)
	if equip_bonus > 0:
		return "  %-4s [color=#%s]%d[/color] [color=#%s](+%d)[/color]\n" % [label, secondary, base, green, equip_bonus]
	elif equip_bonus < 0:
		return "  %-4s [color=#%s]%d[/color] [color=#%s](%d)[/color]\n" % [label, secondary, base, red, equip_bonus]
	else:
		return "  %-4s [color=#%s]%d[/color]\n" % [label, secondary, base]

func _skill_name_to_index(skill_name: String) -> int:
	match skill_name:
		"melee": return Constants.Skill.S_MEL
		"archery": return Constants.Skill.S_ARC
		"evasion": return Constants.Skill.S_EVN
		"stealth": return Constants.Skill.S_STL
		"hunting": return Constants.Skill.S_PER
		"will": return Constants.Skill.S_WIL
		"smithing": return Constants.Skill.S_SMT
		"lore": return Constants.Skill.S_LOR
		_: return -1

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_C:
		close()
		get_viewport().set_input_as_handled()
