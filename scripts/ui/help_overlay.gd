extends CanvasLayer
## Full-screen keybinding reference overlay. Toggle with ? key.

var _panel: PanelContainer
var _is_visible: bool = false

func _ready() -> void:
	layer = 25
	_setup_ui()

func _setup_ui() -> void:
	# Background dimmer
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.name = "HelpBG"
	add_child(bg)

	_panel = PanelContainer.new()
	var style: StyleBox
	if ThemeColors.has_textures():
		style = ThemeColors.create_textured_panel("panel_stone", 8.0)
	else:
		style = ThemeColors.create_panel_stylebox(ThemeColors.STONE_DARK, ThemeColors.GOLD_DIM, 2, 4)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(1120, 840)
	_panel.position = Vector2(-560, -420)
	_panel.name = "HelpPanel"

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1100, 820)

	var content := RichTextLabel.new()
	content.bbcode_enabled = true
	content.fit_content = true
	content.custom_minimum_size = Vector2(1060, 0)
	content.add_theme_color_override("default_color", ThemeColors.TEXT_PRIMARY)
	ThemeColors.apply_rich_body_font(content, ThemeColors.FONT_SIZE_BODY)

	var gold := ThemeColors.PRIMARY.to_html(false)
	var muted := ThemeColors.TEXT_MUTED.to_html(false)
	var cyan := ThemeColors.MSG_INFO.to_html(false)

	content.text = """[color=#%s][b]THE NECROMANCER - KEYBINDINGS[/b][/color]

[color=#%s]Press any key to close[/color]

[color=#%s][b]MOVEMENT[/b][/color]
  WASD / HJKL / Arrows .... Cardinal movement
  YUBN / Numpad 7913 ...... Diagonal movement
  . / Numpad 5 ............ Wait one turn
  O ........................ Auto-explore

[color=#%s][b]INVENTORY[/b][/color]
  I ........................ Open inventory
  G ........................ Pick up item
  E ........................ Equip selected item
  R ........................ Unequip selected item
  Shift+D .................. Drop selected item
  Shift+Q .................. Quaff potion
  , (comma) ................ Eat herb/food

[color=#%s][b]COMBAT[/b][/color]
  (bump into enemy) ....... Melee attack
  F ........................ Fire bow / Use forge
  ; (semicolon) ........... Toggle stealth mode
  Shift+F .................. Defensive stance
  Shift+P .................. Ready parry
  Shift+H .................. Mark quarry (Hunting)
  Shift+X .................. Expose weakness (Hunting)
  Shift+E .................. Exploit opening (Hunting)
  Shift+T .................. Tunnel / dig rubble
  Shift+S .................. Search for secrets
  C ........................ Close adjacent door
  Shift+C .................. Character profile

[color=#%s][b]INFORMATION[/b][/color]
  X ........................ Look mode (examine)
  @ ........................ Skills panel
  A ........................ Abilities panel
  M ........................ Toggle minimap

[color=#%s][b]SYSTEM[/b][/color]
  Enter .................... Use stairs / Advance dialogue
  Space .................... Skip/Advance
  Escape ................... Settings / Close panel
  ? ........................ This help screen
  Mouse Wheel .............. Zoom (0.5x - 3.0x)
""" % [gold, muted, cyan, cyan, cyan, cyan, cyan]

	scroll.add_child(content)
	_panel.add_child(scroll)
	add_child(_panel)

	# Start hidden
	bg.visible = false
	_panel.visible = false

func toggle() -> void:
	_is_visible = not _is_visible
	get_node("HelpBG").visible = _is_visible
	get_node("HelpPanel").visible = _is_visible

func _unhandled_input(event: InputEvent) -> void:
	if _is_visible:
		if event is InputEventKey and event.pressed:
			toggle()
			get_viewport().set_input_as_handled()
