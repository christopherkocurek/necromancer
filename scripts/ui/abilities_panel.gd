extends Control
class_name AbilitiesPanel
## Abilities browser showing all abilities organized by skill tree.

signal ability_purchased(ability_name: String)
signal closed

const SKILL_NAMES: Array[String] = [
	"Melee", "Archery", "Evasion", "Stealth",
	"Perception", "Will", "Smithing", "Lore"
]

const SKILL_KEYS: Array[String] = [
	"melee", "archery", "evasion", "stealth",
	"perception", "will", "smithing", "lore"
]

var player: Player
var current_skill_tab: int = 0
var selected_ability: DataManager.AbilityData = null

@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var info_panel: RichTextLabel = $VBoxContainer/InfoPanel
@onready var xp_label: Label = $VBoxContainer/XPLabel
@onready var buy_button: Button = $VBoxContainer/HBoxContainer/BuyButton
@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton

func _ready() -> void:
	_setup_tabs()
	close_button.pressed.connect(close)
	visible = false

func open(player_ref: Player) -> void:
	player = player_ref
	visible = true
	_refresh_all_tabs()
	_update_xp_display()
	grab_focus()

func close() -> void:
	visible = false
	closed.emit()

func _setup_tabs() -> void:
	# Create a tab for each skill
	for i in range(SKILL_NAMES.size()):
		var scroll := ScrollContainer.new()
		scroll.name = SKILL_NAMES[i]
		scroll.custom_minimum_size = Vector2(0, 300)

		var vbox := VBoxContainer.new()
		vbox.name = "AbilitiesList"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(vbox)

		tab_container.add_child(scroll)

	tab_container.tab_changed.connect(_on_tab_changed)
	buy_button.pressed.connect(_on_buy_pressed)

func _on_tab_changed(tab_idx: int) -> void:
	current_skill_tab = tab_idx
	selected_ability = null
	_update_info_panel()

func _refresh_all_tabs() -> void:
	for i in range(SKILL_NAMES.size()):
		_refresh_skill_tab(i)

func _refresh_skill_tab(skill_idx: int) -> void:
	var scroll: ScrollContainer = tab_container.get_child(skill_idx)
	var vbox: VBoxContainer = scroll.get_node("AbilitiesList")

	# Clear existing
	for child in vbox.get_children():
		child.queue_free()

	# Get abilities for this skill
	var abilities := DataManager.get_abilities_for_skill(skill_idx)
	var player_skill_level: int = player.skills.get(SKILL_KEYS[skill_idx], 0) if player else 0

	# Add header showing current skill level
	var header := Label.new()
	header.text = "%s (Level %d)" % [SKILL_NAMES[skill_idx], player_skill_level]
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(header)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	if abilities.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No abilities in this skill tree."
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		vbox.add_child(empty_label)
		return

	# Add each ability as a button
	for ability in abilities:
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 40

		var has_ability := _player_has_ability(ability)
		var can_learn := _can_learn_ability(ability)
		var meets_reqs := ability.level_requirement <= player_skill_level

		# Format: [Level X] Ability Name
		var status_icon := ""
		if has_ability:
			status_icon = "[color=green]✓[/color] "
		elif can_learn:
			status_icon = "[color=yellow]●[/color] "
		elif not meets_reqs:
			status_icon = "[color=gray]○[/color] "
		else:
			status_icon = "[color=red]✗[/color] "

		btn.text = "[%d] %s" % [ability.level_requirement, ability.name]

		# Color based on status
		if has_ability:
			btn.add_theme_color_override("font_color", Color.GREEN)
		elif can_learn:
			btn.add_theme_color_override("font_color", Color.WHITE)
		elif not meets_reqs:
			btn.add_theme_color_override("font_color", Color.DIM_GRAY)
		else:
			btn.add_theme_color_override("font_color", Color.INDIAN_RED)

		btn.pressed.connect(_on_ability_selected.bind(ability))
		vbox.add_child(btn)

func _on_ability_selected(ability: DataManager.AbilityData) -> void:
	selected_ability = ability
	_update_info_panel()

func _update_info_panel() -> void:
	if selected_ability == null:
		info_panel.text = "Select an ability to see details."
		buy_button.disabled = true
		return

	var ability := selected_ability
	var skill_name := SKILL_NAMES[ability.skill_type] if ability.skill_type < SKILL_NAMES.size() else "Unknown"
	var has_ability := _player_has_ability(ability)
	var can_learn := _can_learn_ability(ability)

	var text := "[b]%s[/b]\n" % ability.name
	text += "[color=gray]%s ability (Level %d required)[/color]\n\n" % [skill_name, ability.level_requirement]
	text += ability.description + "\n\n"

	# Prerequisites
	if not ability.prereqs.is_empty():
		text += "[color=yellow]Prerequisites:[/color]\n"
		for prereq in ability.prereqs:
			var prereq_skill: int = prereq.get("skill", 0)
			var prereq_ability_idx: int = prereq.get("ability", 0)
			# Find the prereq ability name
			var prereq_name := _find_ability_by_index(prereq_skill, prereq_ability_idx)
			if prereq_name != "":
				text += "  - %s\n" % prereq_name

	# XP Cost (abilities cost XP to learn)
	var xp_cost := _get_ability_xp_cost(ability)
	text += "\n[color=cyan]Cost: %d XP[/color]" % xp_cost

	if has_ability:
		text += "\n[color=green]You have learned this ability.[/color]"
	elif can_learn:
		text += "\n[color=yellow]You can learn this ability![/color]"

	info_panel.bbcode_enabled = true
	info_panel.text = text

	buy_button.disabled = has_ability or not can_learn
	buy_button.text = "Learned" if has_ability else "Learn (%d XP)" % xp_cost

func _on_buy_pressed() -> void:
	if selected_ability == null or not player:
		return

	var xp_cost := _get_ability_xp_cost(selected_ability)
	if player.xp_available < xp_cost:
		return

	if not _can_learn_ability(selected_ability):
		return

	# Deduct XP and add ability
	player.xp_available -= xp_cost
	if not player.has_meta("learned_abilities"):
		player.set_meta("learned_abilities", [])
	var learned: Array = player.get_meta("learned_abilities")
	learned.append(selected_ability.name)
	player.set_meta("learned_abilities", learned)

	# Register in the gameplay ability array system so has_ability() works
	player.learn_ability(selected_ability.skill_type, selected_ability.ability_num)

	GameManager.log_message("You have learned %s!" % selected_ability.name, Color.GOLD)
	ability_purchased.emit(selected_ability.name)

	_refresh_all_tabs()
	_update_xp_display()
	_update_info_panel()

func _update_xp_display() -> void:
	if player:
		xp_label.text = "Available XP: %d" % player.xp_available
	else:
		xp_label.text = "Available XP: ---"

func _player_has_ability(ability: DataManager.AbilityData) -> bool:
	if not player or not player.has_meta("learned_abilities"):
		return false
	var learned: Array = player.get_meta("learned_abilities")
	return learned.has(ability.name)

func _can_learn_ability(ability: DataManager.AbilityData) -> bool:
	if not player:
		return false

	# Already have it?
	if _player_has_ability(ability):
		return false

	# Check skill level requirement
	var skill_key := SKILL_KEYS[ability.skill_type] if ability.skill_type < SKILL_KEYS.size() else ""
	var player_skill_level: int = player.skills.get(skill_key, 0)
	if player_skill_level < ability.level_requirement:
		return false

	# Check prerequisites
	for prereq in ability.prereqs:
		var prereq_skill: int = prereq.get("skill", 0)
		var prereq_ability_idx: int = prereq.get("ability", 0)
		var prereq_name := _find_ability_by_index(prereq_skill, prereq_ability_idx)
		if prereq_name != "" and not _player_has_ability_by_name(prereq_name):
			return false

	# Check XP
	var xp_cost := _get_ability_xp_cost(ability)
	if player.xp_available < xp_cost:
		return false

	return true

func _player_has_ability_by_name(ability_name: String) -> bool:
	if not player or not player.has_meta("learned_abilities"):
		return false
	var learned: Array = player.get_meta("learned_abilities")
	return learned.has(ability_name)

func _find_ability_by_index(skill_type: int, ability_num: int) -> String:
	for ability in DataManager.abilities.values():
		if ability.skill_type == skill_type and ability.ability_num == ability_num:
			return ability.name
	return ""

func _get_ability_xp_cost(ability: DataManager.AbilityData) -> int:
	# Base cost scales with level requirement
	# Level 1 = 500 XP, Level 5 = 1500 XP, Level 10 = 3000 XP, etc.
	return (ability.level_requirement + 1) * 300

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
