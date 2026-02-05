extends Control
class_name SkillsPanel
## Skills and abilities panel for spending XP on skill points.

signal skill_increased(skill_name: String, new_level: int)
signal closed

const SKILL_NAMES: Array[String] = [
	"melee", "archery", "evasion", "stealth",
	"perception", "will", "smithing", "lore"
]

const SKILL_DESCRIPTIONS: Dictionary = {
	"melee": "Combat prowess with melee weapons. Affects attack rolls.",
	"archery": "Skill with bows and thrown weapons. Affects ranged attacks.",
	"evasion": "Ability to dodge attacks. Affects defense rolls.",
	"stealth": "Moving unseen and unheard. Affects detection by enemies.",
	"perception": "Awareness of surroundings. Affects spotting hidden things.",
	"will": "Mental fortitude. Resists fear, confusion, and magical effects.",
	"smithing": "Crafting and repairing equipment at forges.",
	"lore": "Knowledge of ancient secrets. Powers the Necromancer's magic."
}

var player: Player
var skill_rows: Dictionary = {}

@onready var xp_label: Label = $VBoxContainer/XPLabel
@onready var skills_container: VBoxContainer = $VBoxContainer/SkillsContainer
@onready var info_label: RichTextLabel = $VBoxContainer/InfoLabel

func _ready() -> void:
	_setup_skills()
	visible = false

func open(player_ref: Player) -> void:
	player = player_ref
	visible = true
	_refresh_display()
	grab_focus()

func close() -> void:
	visible = false
	closed.emit()

func _setup_skills() -> void:
	for skill_name in SKILL_NAMES:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 40

		# Skill name
		var name_label := Label.new()
		name_label.text = skill_name.capitalize()
		name_label.custom_minimum_size.x = 100
		row.add_child(name_label)

		# Current level
		var level_label := Label.new()
		level_label.custom_minimum_size.x = 40
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(level_label)

		# Cost display
		var cost_label := Label.new()
		cost_label.custom_minimum_size.x = 80
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(cost_label)

		# Buy button
		var buy_btn := Button.new()
		buy_btn.text = "+"
		buy_btn.custom_minimum_size = Vector2(40, 30)
		buy_btn.pressed.connect(_on_skill_buy_pressed.bind(skill_name))
		row.add_child(buy_btn)

		# Progress bar
		var progress := ProgressBar.new()
		progress.custom_minimum_size = Vector2(100, 20)
		progress.max_value = 20
		progress.show_percentage = false
		row.add_child(progress)

		skills_container.add_child(row)

		skill_rows[skill_name] = {
			"row": row,
			"name_label": name_label,
			"level_label": level_label,
			"cost_label": cost_label,
			"buy_btn": buy_btn,
			"progress": progress
		}

func _refresh_display() -> void:
	if not player:
		return

	# Update XP display
	xp_label.text = "Available XP: %d  (Total earned: %d)" % [
		player.xp_available, player.total_xp_earned
	]

	# Update each skill row
	for skill_name in SKILL_NAMES:
		var row_data: Dictionary = skill_rows[skill_name]
		var current_level: int = player.skills.get(skill_name, 0)
		var cost: int = player.get_skill_cost(current_level)
		var can_afford: bool = player.can_afford_skill(skill_name)

		row_data.level_label.text = str(current_level)
		row_data.progress.value = current_level

		if current_level >= 20:
			row_data.cost_label.text = "MAX"
			row_data.cost_label.add_theme_color_override("font_color", Color.GOLD)
			row_data.buy_btn.disabled = true
		else:
			row_data.cost_label.text = "%d XP" % cost
			if can_afford:
				row_data.cost_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				row_data.cost_label.add_theme_color_override("font_color", Color.RED)
			row_data.buy_btn.disabled = not can_afford

		# Color level based on value
		if current_level >= 10:
			row_data.level_label.add_theme_color_override("font_color", Color.GOLD)
		elif current_level >= 5:
			row_data.level_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			row_data.level_label.remove_theme_color_override("font_color")

func _on_skill_buy_pressed(skill_name: String) -> void:
	if not player:
		return

	if player.invest_skill(skill_name):
		skill_increased.emit(skill_name, player.skills[skill_name])
		_refresh_display()

func _on_skill_hovered(skill_name: String) -> void:
	var desc: String = SKILL_DESCRIPTIONS.get(skill_name, "No description.")
	var current: int = player.skills.get(skill_name, 0) if player else 0

	info_label.bbcode_enabled = true
	info_label.text = "[b]%s[/b] (Level %d)\n\n%s" % [
		skill_name.capitalize(), current, desc
	]

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("skills"):
		close()
		get_viewport().set_input_as_handled()

	# Number keys for quick purchase (1-8)
	if event is InputEventKey and event.pressed:
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

		if key_index >= 0 and key_index < SKILL_NAMES.size():
			_on_skill_buy_pressed(SKILL_NAMES[key_index])
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	# Detect hovering over skill rows for info display
	pass  # Would need mouse tracking per row
