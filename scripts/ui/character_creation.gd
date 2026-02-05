extends Control
class_name CharacterCreation
## Character creation flow: Race → House → Stats → Name → Start Game

signal creation_complete(character_data: Dictionary)
signal creation_cancelled

enum Stage { RACE, HOUSE, STATS, NAME, CONFIRM }

var current_stage: Stage = Stage.RACE

# Character build state
var selected_race: String = ""
var selected_house: String = ""
var base_stats: Dictionary = {"str": 0, "dex": 0, "con": 0, "gra": 0}
var character_name: String = ""

# UI References (set in _ready or via @onready)
@onready var stage_label: Label = $VBoxContainer/StageLabel
@onready var content_container: VBoxContainer = $VBoxContainer/ContentContainer
@onready var info_label: RichTextLabel = $VBoxContainer/InfoLabel
@onready var nav_container: HBoxContainer = $VBoxContainer/NavContainer
@onready var back_button: Button = $VBoxContainer/NavContainer/BackButton
@onready var next_button: Button = $VBoxContainer/NavContainer/NextButton

# Stat allocation UI
var stat_labels: Dictionary = {}
var stat_buttons: Dictionary = {}
var points_remaining: int = Constants.STAT_POINTS_TOTAL

func _ready() -> void:
	_setup_ui()
	_show_stage(Stage.RACE)

func _setup_ui() -> void:
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)

func _show_stage(stage: Stage) -> void:
	current_stage = stage
	_clear_content()

	match stage:
		Stage.RACE:
			_show_race_selection()
		Stage.HOUSE:
			_show_house_selection()
		Stage.STATS:
			_show_stat_allocation()
		Stage.NAME:
			_show_name_entry()
		Stage.CONFIRM:
			_show_confirmation()

	_update_navigation()

func _clear_content() -> void:
	for child in content_container.get_children():
		child.queue_free()
	stat_labels.clear()
	stat_buttons.clear()

# ============================================================================
# RACE SELECTION
# ============================================================================

func _show_race_selection() -> void:
	stage_label.text = "Choose Your Race"

	var races := DataManager.races
	for race_name in races:
		var race_data: DataManager.RaceData = races[race_name]
		if race_name == "Istari":
			continue  # Skip debug race

		var btn := Button.new()
		btn.text = race_name
		btn.toggle_mode = true
		btn.button_group = _get_or_create_button_group("race")
		btn.pressed.connect(_on_race_selected.bind(race_name))

		if selected_race == race_name:
			btn.button_pressed = true

		content_container.add_child(btn)

	_update_race_info()

func _on_race_selected(race_name: String) -> void:
	selected_race = race_name
	selected_house = ""  # Reset house when race changes
	_update_race_info()
	_update_navigation()

func _update_race_info() -> void:
	if selected_race.is_empty():
		info_label.text = "Select a race to see details."
		return

	var race: DataManager.RaceData = DataManager.get_race(selected_race)
	if not race:
		return

	var stats_text := "STR %+d  DEX %+d  CON %+d  GRA %+d" % [
		race.str_mod, race.dex_mod, race.con_mod, race.gra_mod
	]

	var flags_text := ""
	if not race.flags.is_empty():
		flags_text = "\n[color=yellow]Traits:[/color] " + ", ".join(race.flags)

	info_label.bbcode_enabled = true
	info_label.text = "[b]%s[/b]\n%s%s\n\n%s" % [
		selected_race, stats_text, flags_text, race.description
	]

# ============================================================================
# HOUSE SELECTION
# ============================================================================

func _show_house_selection() -> void:
	stage_label.text = "Choose Your House"

	var race_data: DataManager.RaceData = DataManager.get_race(selected_race)
	if not race_data:
		return

	var houses := DataManager.houses
	for house_name in houses:
		var house_data: DataManager.HouseData = houses[house_name]

		# Filter by race compatibility
		if not race_data.compatible_houses.is_empty():
			if not race_data.compatible_houses.has(house_data.index):
				continue

		var btn := Button.new()
		btn.text = house_name
		btn.toggle_mode = true
		btn.button_group = _get_or_create_button_group("house")
		btn.pressed.connect(_on_house_selected.bind(house_name))

		if selected_house == house_name:
			btn.button_pressed = true

		content_container.add_child(btn)

	_update_house_info()

func _on_house_selected(house_name: String) -> void:
	selected_house = house_name
	_update_house_info()
	_update_navigation()

func _update_house_info() -> void:
	if selected_house.is_empty():
		info_label.text = "Select a house to see details."
		return

	var house: DataManager.HouseData = DataManager.get_house(selected_house)
	if not house:
		return

	var stats_text := "STR %+d  DEX %+d  CON %+d  GRA %+d" % [
		house.str_mod, house.dex_mod, house.con_mod, house.gra_mod
	]

	var affinity_text := ""
	if not house.affinities.is_empty():
		affinity_text = "\n[color=cyan]Affinity:[/color] " + ", ".join(house.affinities)

	info_label.bbcode_enabled = true
	info_label.text = "[b]%s[/b]\n%s%s\n\n%s" % [
		selected_house, stats_text, affinity_text, house.description
	]

# ============================================================================
# STAT ALLOCATION
# ============================================================================

func _show_stat_allocation() -> void:
	stage_label.text = "Allocate Stats (%d points)" % Constants.STAT_POINTS_TOTAL

	# Calculate starting stats from race + house
	var race: DataManager.RaceData = DataManager.get_race(selected_race)
	var house: DataManager.HouseData = DataManager.get_house(selected_house)

	var race_mods := {"str": 0, "dex": 0, "con": 0, "gra": 0}
	var house_mods := {"str": 0, "dex": 0, "con": 0, "gra": 0}

	if race:
		race_mods = {"str": race.str_mod, "dex": race.dex_mod, "con": race.con_mod, "gra": race.gra_mod}
	if house:
		house_mods = {"str": house.str_mod, "dex": house.dex_mod, "con": house.con_mod, "gra": house.gra_mod}

	# Create stat rows
	for stat_name in ["str", "dex", "con", "gra"]:
		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = stat_name.to_upper()
		label.custom_minimum_size.x = 50
		row.add_child(label)

		var minus_btn := Button.new()
		minus_btn.text = "-"
		minus_btn.pressed.connect(_on_stat_decrease.bind(stat_name))
		row.add_child(minus_btn)
		stat_buttons[stat_name + "_minus"] = minus_btn

		var value_label := Label.new()
		value_label.custom_minimum_size.x = 60
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(value_label)
		stat_labels[stat_name] = value_label

		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.pressed.connect(_on_stat_increase.bind(stat_name))
		row.add_child(plus_btn)
		stat_buttons[stat_name + "_plus"] = plus_btn

		var mod_label := Label.new()
		var total_mod: int = race_mods[stat_name] + house_mods[stat_name]
		mod_label.text = "(Race %+d, House %+d)" % [race_mods[stat_name], house_mods[stat_name]]
		mod_label.add_theme_color_override("font_color", Color.GRAY)
		row.add_child(mod_label)

		content_container.add_child(row)

	_recalculate_points()
	_update_stat_display()

func _on_stat_increase(stat_name: String) -> void:
	var current: int = base_stats[stat_name]
	if current >= 6:
		return  # Max stat

	var current_cost: int = Constants.get_stat_cost(current)
	var next_cost: int = Constants.get_stat_cost(current + 1)
	var cost_diff: int = next_cost - current_cost

	if cost_diff > points_remaining:
		return  # Can't afford

	base_stats[stat_name] = current + 1
	_recalculate_points()
	_update_stat_display()

func _on_stat_decrease(stat_name: String) -> void:
	var current: int = base_stats[stat_name]
	if current <= -4:
		return  # Min stat

	base_stats[stat_name] = current - 1
	_recalculate_points()
	_update_stat_display()

func _recalculate_points() -> void:
	var spent: int = 0
	for stat_name in base_stats:
		spent += Constants.get_stat_cost(base_stats[stat_name])
	points_remaining = Constants.STAT_POINTS_TOTAL - spent

func _update_stat_display() -> void:
	for stat_name in stat_labels:
		var label: Label = stat_labels[stat_name]
		var value: int = base_stats[stat_name]
		label.text = "%+d" % value

		# Color based on value
		if value > 0:
			label.add_theme_color_override("font_color", Color.GREEN)
		elif value < 0:
			label.add_theme_color_override("font_color", Color.RED)
		else:
			label.remove_theme_color_override("font_color")

	# Update stage label with remaining points
	stage_label.text = "Allocate Stats (%d points remaining)" % points_remaining

	# Update button states
	for stat_name in base_stats:
		var minus_btn: Button = stat_buttons.get(stat_name + "_minus")
		var plus_btn: Button = stat_buttons.get(stat_name + "_plus")

		if minus_btn:
			minus_btn.disabled = base_stats[stat_name] <= -4
		if plus_btn:
			var current: int = base_stats[stat_name]
			var next_cost: int = Constants.get_stat_cost(current + 1) - Constants.get_stat_cost(current)
			plus_btn.disabled = current >= 6 or next_cost > points_remaining

	info_label.text = _get_stat_summary()

func _get_stat_summary() -> String:
	var race: DataManager.RaceData = DataManager.get_race(selected_race)
	var house: DataManager.HouseData = DataManager.get_house(selected_house)

	var final_str: int = base_stats["str"] + (race.str_mod if race else 0) + (house.str_mod if house else 0)
	var final_dex: int = base_stats["dex"] + (race.dex_mod if race else 0) + (house.dex_mod if house else 0)
	var final_con: int = base_stats["con"] + (race.con_mod if race else 0) + (house.con_mod if house else 0)
	var final_gra: int = base_stats["gra"] + (race.gra_mod if race else 0) + (house.gra_mod if house else 0)

	return "Final Stats: STR %+d  DEX %+d  CON %+d  GRA %+d" % [
		final_str, final_dex, final_con, final_gra
	]

# ============================================================================
# NAME ENTRY
# ============================================================================

func _show_name_entry() -> void:
	stage_label.text = "Name Your Character"

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Enter name..."
	name_edit.text = character_name
	name_edit.text_changed.connect(_on_name_changed)
	name_edit.custom_minimum_size.x = 300
	content_container.add_child(name_edit)

	# Random name button
	var random_btn := Button.new()
	random_btn.text = "Random Name"
	random_btn.pressed.connect(_on_random_name)
	content_container.add_child(random_btn)

	info_label.text = _get_character_summary()

func _on_name_changed(new_name: String) -> void:
	character_name = new_name
	info_label.text = _get_character_summary()
	_update_navigation()

func _on_random_name() -> void:
	var names := ["Thorin", "Elrond", "Galadriel", "Aragorn", "Legolas", "Gimli",
		"Beren", "Luthien", "Fingolfin", "Feanor", "Turin", "Hurin", "Earendil",
		"Celebrimbor", "Gil-galad", "Thranduil", "Glorfindel", "Ecthelion"]
	character_name = names.pick_random()

	# Update LineEdit
	for child in content_container.get_children():
		if child is LineEdit:
			child.text = character_name
			break

	info_label.text = _get_character_summary()
	_update_navigation()

func _get_character_summary() -> String:
	var race: DataManager.RaceData = DataManager.get_race(selected_race)
	var house: DataManager.HouseData = DataManager.get_house(selected_house)

	var final_str: int = base_stats["str"] + (race.str_mod if race else 0) + (house.str_mod if house else 0)
	var final_dex: int = base_stats["dex"] + (race.dex_mod if race else 0) + (house.dex_mod if house else 0)
	var final_con: int = base_stats["con"] + (race.con_mod if race else 0) + (house.con_mod if house else 0)
	var final_gra: int = base_stats["gra"] + (race.gra_mod if race else 0) + (house.gra_mod if house else 0)

	var display_name: String = character_name if not character_name.is_empty() else "(unnamed)"
	var house_suffix: String = house.alternate_name if house and not house.alternate_name.is_empty() else selected_house

	return "%s of %s\n%s %s\n\nSTR %+d  DEX %+d  CON %+d  GRA %+d\n\nStarting XP: %d" % [
		display_name, house_suffix, selected_race, selected_house,
		final_str, final_dex, final_con, final_gra, Player.STARTING_XP
	]

# ============================================================================
# CONFIRMATION
# ============================================================================

func _show_confirmation() -> void:
	stage_label.text = "Confirm Character"
	info_label.text = _get_character_summary() + "\n\n[color=yellow]Press 'Start Game' to begin your quest.[/color]"
	info_label.bbcode_enabled = true

# ============================================================================
# NAVIGATION
# ============================================================================

func _update_navigation() -> void:
	back_button.visible = current_stage != Stage.RACE
	back_button.text = "Back"

	match current_stage:
		Stage.RACE:
			next_button.text = "Next"
			next_button.disabled = selected_race.is_empty()
		Stage.HOUSE:
			next_button.text = "Next"
			next_button.disabled = selected_house.is_empty()
		Stage.STATS:
			next_button.text = "Next"
			next_button.disabled = false
		Stage.NAME:
			next_button.text = "Confirm"
			next_button.disabled = character_name.is_empty()
		Stage.CONFIRM:
			next_button.text = "Start Game"
			next_button.disabled = false

func _on_back_pressed() -> void:
	if current_stage > Stage.RACE:
		_show_stage(current_stage - 1 as Stage)

func _on_next_pressed() -> void:
	if current_stage < Stage.CONFIRM:
		_show_stage(current_stage + 1 as Stage)
	else:
		_finish_creation()

func _finish_creation() -> void:
	var character_data := {
		"race": selected_race,
		"house": selected_house,
		"base_stats": base_stats.duplicate(),
		"name": character_name
	}
	creation_complete.emit(character_data)

# ============================================================================
# UTILITY
# ============================================================================

var _button_groups: Dictionary = {}

func _get_or_create_button_group(group_name: String) -> ButtonGroup:
	if not _button_groups.has(group_name):
		_button_groups[group_name] = ButtonGroup.new()
	return _button_groups[group_name]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_stage > Stage.RACE:
			_on_back_pressed()
		else:
			creation_cancelled.emit()
