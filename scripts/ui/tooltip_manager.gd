extends CanvasLayer
## Rich tooltip system. Shows contextual tooltips on hover/focus.

var _tooltip_panel: PanelContainer
var _tooltip_label: RichTextLabel
var _show_timer: Timer
var _current_trigger: Control = null
var _is_visible: bool = false

func _ready() -> void:
	layer = 20
	_setup_tooltip()
	_setup_timer()

func _setup_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := ThemeColors.create_panel_stylebox(ThemeColors.BG_RAISED, ThemeColors.BORDER_DEFAULT, 1, 6)
	_tooltip_panel.add_theme_stylebox_override("panel", style)

	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.custom_minimum_size = Vector2(200, 0)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_label.add_theme_color_override("default_color", ThemeColors.TEXT_PRIMARY)
	_tooltip_label.add_theme_font_size_override("normal_font_size", ThemeColors.FONT_SIZE_BODY)
	_tooltip_panel.add_child(_tooltip_label)
	add_child(_tooltip_panel)

func _setup_timer() -> void:
	_show_timer = Timer.new()
	_show_timer.one_shot = true
	_show_timer.timeout.connect(_show_tooltip)
	add_child(_show_timer)

func show_rich_tooltip(text: String, global_pos: Vector2, delay: float = 0.4) -> void:
	_tooltip_label.text = text
	_tooltip_panel.position = _clamp_position(global_pos + Vector2(16, 16))
	_show_timer.start(delay)

func hide_tooltip() -> void:
	_show_timer.stop()
	_tooltip_panel.visible = false
	_is_visible = false
	_current_trigger = null

func _show_tooltip() -> void:
	_tooltip_panel.visible = true
	_is_visible = true

func _clamp_position(pos: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var tooltip_size := _tooltip_panel.size
	pos.x = minf(pos.x, viewport_size.x - tooltip_size.x - 10)
	pos.y = minf(pos.y, viewport_size.y - tooltip_size.y - 10)
	pos.x = maxf(pos.x, 10)
	pos.y = maxf(pos.y, 10)
	return pos

## Format an item tooltip with stats
static func format_item_tooltip(item: Variant) -> String:
	if item == null:
		return ""
	var text := "[b]%s[/b]\n" % GameManager.get_item_display_name(item)
	if "attack_bonus" in item and item.attack_bonus != 0:
		text += "[color=#%s]Attack: %+d[/color]\n" % [ThemeColors.COMBAT_HIT.to_html(false), item.attack_bonus]
	if "damage_dice" in item and item.damage_dice != "":
		text += "Damage: %s\n" % item.damage_dice
	if "evasion_bonus" in item and item.evasion_bonus != 0:
		text += "[color=#%s]Evasion: %+d[/color]\n" % [ThemeColors.SECONDARY.to_html(false), item.evasion_bonus]
	if "protection_dice" in item and item.protection_dice != "":
		text += "Protection: %s\n" % item.protection_dice
	if "weight" in item:
		text += "[color=#%s]Weight: %.1f lb[/color]\n" % [ThemeColors.TEXT_MUTED.to_html(false), item.weight / 10.0]
	if "description" in item and item.description != "":
		text += "\n[color=#%s]%s[/color]" % [ThemeColors.TEXT_SECONDARY.to_html(false), item.description]
	return text

## Format a status effect tooltip
static func format_status_tooltip(status_name: String, duration: int) -> String:
	var color := ThemeColors.get_status_color(status_name)
	return "[color=#%s][b]%s[/b][/color]\nDuration: %d turns" % [color.to_html(false), status_name.capitalize(), duration]

## Format an ability tooltip
static func format_ability_tooltip(ability: DataManager.AbilityData) -> String:
	var text := "[b]%s[/b]\n" % ability.name
	text += "[color=#%s]Level %d required[/color]\n\n" % [ThemeColors.TEXT_MUTED.to_html(false), ability.level_requirement]
	text += ability.description
	return text

## Format a skill tooltip
static func format_skill_tooltip(skill_name: String, level: int, cost: int) -> String:
	var color := ThemeColors.get_skill_color(skill_name)
	var text := "[color=#%s][b]%s[/b][/color] (Level %d)\n" % [color.to_html(false), skill_name.capitalize(), level]
	if level < 20:
		text += "Next level: %d XP" % cost
	else:
		text += "[color=#%s]Maximum level[/color]" % ThemeColors.PRIMARY.to_html(false)
	return text
