extends Control
class_name CharacterCreation
## Character creation flow: Race -> House -> Gender -> Trait -> Stats -> Name -> Confirm
## Enhanced with gender selection, age system, parentage history, and NameGenerator integration.

const BackstoryGeneratorScript := preload("res://scripts/systems/backstory_generator.gd")

signal creation_complete(character_data: Dictionary)
signal creation_cancelled

enum Stage { RACE, HOUSE, GENDER, TRAIT, STATS, NAME, DIFFICULTY, CONFIRM }

var current_stage: Stage = Stage.RACE

# Character build state
var selected_race: String = ""
var selected_house: String = ""
var selected_gender: String = ""
var selected_trait: String = ""
var base_stats: Dictionary = {"str": 0, "dex": 0, "con": 0, "gra": 0}
var character_name: String = ""
var character_age: int = 0
var character_history: String = ""
var selected_difficulty: int = GameManager.Difficulty.NORMAL

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

# Stage transition
var _transitioning: bool = false

# Progress indicator dots
var _progress_dots: Array[ColorRect] = []
var _progress_container: HBoxContainer = null

# Character preview
var _preview_rect: TextureRect = null
var _tileset_texture: Texture2D = null

# Name list loaded from file (legacy fallback)
var _name_list: PackedStringArray = []
const NAMES_FILE_PATH := "res://data/names.txt"
const FALLBACK_NAMES: Array[String] = [
	"Thorin", "Elrond", "Galadriel", "Aragorn", "Legolas", "Gimli",
	"Beren", "Luthien", "Fingolfin", "Feanor", "Turin", "Hurin", "Earendil",
	"Celebrimbor", "Gil-galad", "Thranduil", "Glorfindel", "Ecthelion"]

# Stat bar colors
const STAT_COLORS: Dictionary = {
	"str": Color("#EF4444"),  # Red
	"dex": Color("#4ADE80"),  # Green
	"con": Color("#60A5FA"),  # Blue
	"gra": Color("#A855F7"),  # Purple
}

# Age ranges by race + house (lore-accurate)
const AGE_RANGES: Dictionary = {
	"Man_Gondor": {"min": 18, "max": 75},
	"Man_Rohan": {"min": 16, "max": 70},
	"Man_Dunedain": {"min": 25, "max": 140},
	"Dwarf": {"min": 40, "max": 250},
	"Hobbit": {"min": 25, "max": 130},
	"Elf_Lothlorien": {"min": 100, "max": 2000, "ancient_chance": 500, "ancient_min": 3000, "ancient_max": 7000},
	"Elf_Rivendell": {"min": 100, "max": 3000},
	"Elf_Greenwood": {"min": 100, "max": 2000},
}

# History data parsed from history.txt
var _history_chains: Dictionary = {}  # primary_index -> Array of {secondary, probability, house, text}

func _ready() -> void:
	_load_names_file()
	_load_tileset()
	_load_history_data()
	_setup_progress_indicator()
	_setup_ui()
	_show_stage(Stage.RACE)
	if AudioManager:
		AudioManager.play_music("main_theme")

func _load_names_file() -> void:
	if not FileAccess.file_exists(NAMES_FILE_PATH):
		return
	var file := FileAccess.open(NAMES_FILE_PATH, FileAccess.READ)
	if not file:
		return
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.begins_with("N:"):
			var name_str: String = line.substr(2).strip_edges()
			if not name_str.is_empty():
				_name_list.append(name_str.capitalize())

func _load_tileset() -> void:
	if FileAccess.file_exists("res://assets/sprites/necromancer_dcss_tileset.png"):
		_tileset_texture = load("res://assets/sprites/necromancer_dcss_tileset.png")

func _load_history_data() -> void:
	## Parse history.txt into chain lookup tables for parentage generation.
	var path: String = "res://data/history.txt"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return

	var current_primary: int = -1
	var current_secondary: int = 0
	var current_probability: int = 0
	var current_house: int = 0
	var current_text: String = ""

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("V:"):
			continue

		if line.begins_with("N:"):
			# Save previous entry if valid
			if current_primary >= 0 and not current_text.is_empty():
				if current_primary not in _history_chains:
					_history_chains[current_primary] = []
				_history_chains[current_primary].append({
					"secondary": current_secondary,
					"probability": current_probability,
					"house": current_house,
					"text": current_text
				})

			# Parse N: line - primary:secondary:probability:house
			var parts: PackedStringArray = line.substr(2).split(":")
			if parts.size() >= 4:
				current_primary = int(parts[0])
				current_secondary = int(parts[1])
				current_probability = int(parts[2])
				current_house = int(parts[3])
			current_text = ""

		elif line.begins_with("D:"):
			var text: String = line.substr(2)
			if current_text.is_empty():
				current_text = text
			else:
				current_text += " " + text

	# Save last entry
	if current_primary >= 0 and not current_text.is_empty():
		if current_primary not in _history_chains:
			_history_chains[current_primary] = []
		_history_chains[current_primary].append({
			"secondary": current_secondary,
			"probability": current_probability,
			"house": current_house,
			"text": current_text
		})

func _setup_progress_indicator() -> void:
	# Create progress dots above the stage label
	_progress_container = HBoxContainer.new()
	_progress_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_progress_container.add_theme_constant_override("separation", 12)

	for i in range(Stage.size()):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(17, 17)
		dot.color = ThemeColors.TEXT_DISABLED
		_progress_container.add_child(dot)
		_progress_dots.append(dot)

	# Insert before stage label (after Title which is index 0)
	var vbox: VBoxContainer = $VBoxContainer
	vbox.add_child(_progress_container)
	vbox.move_child(_progress_container, 1)  # After Title

func _update_progress_dots() -> void:
	for i in range(_progress_dots.size()):
		if i < current_stage:
			_progress_dots[i].color = ThemeColors.PRIMARY
		elif i == current_stage:
			_progress_dots[i].color = ThemeColors.PRIMARY_BRIGHT
		else:
			_progress_dots[i].color = ThemeColors.TEXT_DISABLED

func _setup_ui() -> void:
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)

	# Apply Diablo-themed fonts and buttons
	ThemeColors.apply_heading_font(stage_label, ThemeColors.FONT_SIZE_H2)
	ThemeColors.apply_rich_body_font(info_label)
	ThemeColors.apply_button_theme(back_button)
	ThemeColors.apply_button_theme(next_button)

func _show_stage(stage: Stage, direction: int = 0) -> void:
	if _transitioning:
		return

	var old_stage: Stage = current_stage
	current_stage = stage

	if direction != 0 and content_container.get_child_count() > 0:
		_transitioning = true
		await _slide_transition(direction)
		_transitioning = false
	else:
		_clear_content()

	_populate_stage(stage)
	_update_navigation()
	_update_progress_dots()

func _populate_stage(stage: Stage) -> void:
	match stage:
		Stage.RACE:
			_show_race_selection()
		Stage.HOUSE:
			_show_house_selection()
		Stage.GENDER:
			_show_gender_selection()
		Stage.TRAIT:
			_show_trait_selection()
		Stage.STATS:
			_show_stat_allocation()
		Stage.NAME:
			_show_name_entry()
		Stage.DIFFICULTY:
			_show_difficulty_selection()
		Stage.CONFIRM:
			_show_confirmation()

func _slide_transition(direction: int) -> void:
	# direction: 1 = forward (slide left), -1 = backward (slide right)
	var slide_distance: float = 600.0
	var old_pos: float = content_container.position.x

	# Slide old content out
	var out_tween := create_tween()
	out_tween.set_ease(Tween.EASE_IN)
	out_tween.set_trans(Tween.TRANS_CUBIC)
	out_tween.tween_property(content_container, "position:x", old_pos - direction * slide_distance, 0.15)
	out_tween.parallel().tween_property(content_container, "modulate:a", 0.0, 0.15)
	await out_tween.finished

	_clear_content()

	# Position new content on opposite side
	content_container.position.x = old_pos + direction * slide_distance
	content_container.modulate.a = 0.0

	# Slide new content in
	var in_tween := create_tween()
	in_tween.set_ease(Tween.EASE_OUT)
	in_tween.set_trans(Tween.TRANS_CUBIC)
	in_tween.tween_property(content_container, "position:x", old_pos, 0.15)
	in_tween.parallel().tween_property(content_container, "modulate:a", 1.0, 0.15)
	await in_tween.finished

func _clear_content() -> void:
	for child in content_container.get_children():
		child.queue_free()
	stat_labels.clear()
	stat_buttons.clear()
	_preview_rect = null

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

		ThemeColors.apply_button_theme(btn)
		content_container.add_child(btn)

	_update_race_info()

func _on_race_selected(race_name: String) -> void:
	selected_race = race_name
	selected_house = ""  # Reset house when race changes
	selected_gender = ""  # Reset gender when race changes
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
		var gold := ThemeColors.PRIMARY.to_html(false)
		flags_text = "\n[color=#%s]Traits:[/color] " % gold + ", ".join(race.flags)

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

		ThemeColors.apply_button_theme(btn)
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
		var cyan := ThemeColors.MSG_INFO.to_html(false)
		affinity_text = "\n[color=#%s]Affinity:[/color] " % cyan + ", ".join(house.affinities)

	info_label.bbcode_enabled = true
	info_label.text = "[b]%s[/b]\n%s%s\n\n%s" % [
		selected_house, stats_text, affinity_text, house.description
	]

# ============================================================================
# GENDER SELECTION
# ============================================================================

func _show_gender_selection() -> void:
	stage_label.text = "Choose Your Gender"

	# Character preview sprite
	if _tileset_texture:
		var preview_container := CenterContainer.new()
		_preview_rect = TextureRect.new()
		_preview_rect.custom_minimum_size = Vector2(180, 180)
		_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Show male preview by default, will update on selection
		_update_character_preview()
		preview_container.add_child(_preview_rect)
		content_container.add_child(preview_container)

	for gender in ["Male", "Female"]:
		var btn := Button.new()
		btn.text = gender
		btn.toggle_mode = true
		btn.button_group = _get_or_create_button_group("gender")
		btn.pressed.connect(_on_gender_selected.bind(gender.to_lower()))

		if selected_gender == gender.to_lower():
			btn.button_pressed = true

		ThemeColors.apply_button_theme(btn)
		content_container.add_child(btn)

	# Note about portraits
	var note_label := Label.new()
	note_label.text = "(No female character portraits yet)"
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	ThemeColors.apply_body_font(note_label, ThemeColors.FONT_SIZE_HINT)
	content_container.add_child(note_label)

	_update_gender_info()

func _on_gender_selected(gender: String) -> void:
	selected_gender = gender
	_update_character_preview()
	_update_gender_info()
	_update_navigation()

func _update_gender_info() -> void:
	if selected_gender.is_empty():
		info_label.text = "Select a gender for your character."
		return

	var display_gender: String = selected_gender.capitalize()
	var child_text: String = "son" if selected_gender == "male" else "daughter"

	info_label.bbcode_enabled = true
	info_label.text = "[b]%s[/b]\nReferred to as %s in histories." % [
		display_gender, child_text
	]

# ============================================================================
# TRAIT SELECTION
# ============================================================================

## Trait archetype groupings for character creation UI
const TRAIT_ARCHETYPES := {
	"Warrior": ["Defiance", "Last Stand", "Undying Resolve", "Mithril Skin", "Shield Brother", "Blood of Numenor"],
	"Rogue": ["Ambush Mastery", "Shadow Step", "Steady Aim", "Nimble Striker", "Patient Stalker", "Oath of Enmity", "Wayfarer's Instinct"],
	"Lore": ["Light of the Eldar", "Song of Banishment", "Echoes of the Firstborn", "Whisper of the Valar", "Forge Intuition", "Fortune's Favor", "Rallying Cry"],
}
const ARCHETYPE_COLORS := {
	"Warrior": Color(0.9, 0.3, 0.2),
	"Rogue": Color(0.3, 0.8, 0.4),
	"Lore": Color(0.4, 0.6, 1.0),
}
const ARCHETYPE_DESCRIPTIONS := {
	"Warrior": "Strength, endurance, and defiance in the face of darkness.",
	"Rogue": "Precision, stealth, and deadly opportunism.",
	"Lore": "Ancient knowledge, voice abilities, and mystical insight.",
}

func _show_trait_selection() -> void:
	stage_label.text = "Choose Your Trait"

	var all_traits: Array = DataManager.get_all_traits()
	if all_traits.is_empty():
		info_label.text = "No traits available."
		return

	# Build name->TraitData lookup
	var trait_lookup: Dictionary = {}
	for td in all_traits:
		trait_lookup[td.name] = td

	# Scrollable container for the archetype columns
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 450)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_container.add_child(scroll)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	scroll.add_child(columns)

	for archetype in TRAIT_ARCHETYPES:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 6)
		columns.add_child(col)

		# Archetype header
		var header := Label.new()
		header.text = archetype.to_upper()
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_color_override("font_color", ARCHETYPE_COLORS[archetype])
		ThemeColors.apply_heading_font(header, ThemeColors.FONT_SIZE_LARGE)
		col.add_child(header)

		# Archetype subtitle
		var subtitle := Label.new()
		subtitle.text = ARCHETYPE_DESCRIPTIONS[archetype]
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
		ThemeColors.apply_body_font(subtitle, ThemeColors.FONT_SIZE_HINT)
		col.add_child(subtitle)

		var sep := HSeparator.new()
		col.add_child(sep)

		# Trait buttons
		for trait_name in TRAIT_ARCHETYPES[archetype]:
			if trait_name not in trait_lookup:
				continue
			var btn := Button.new()
			btn.text = trait_name
			btn.toggle_mode = true
			btn.button_group = _get_or_create_button_group("trait")
			btn.pressed.connect(_on_trait_selected.bind(trait_name))
			if selected_trait == trait_name:
				btn.button_pressed = true
			ThemeColors.apply_button_theme(btn)
			col.add_child(btn)

	_update_trait_info()

func _on_trait_selected(trait_name: String) -> void:
	selected_trait = trait_name
	_update_trait_info()
	_update_navigation()

func _update_trait_info() -> void:
	if selected_trait.is_empty():
		info_label.text = "Select a trait to define your hero's identity."
		return

	var trait_data: DataManager.TraitData = DataManager.get_trait_by_name(selected_trait)
	if not trait_data:
		return

	var gold := ThemeColors.PRIMARY.to_html(false)
	info_label.bbcode_enabled = true
	info_label.text = "[b]%s[/b]\n\n%s" % [trait_data.name, trait_data.description]

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

	# Create stat rows with colored bars
	for stat_name in ["str", "dex", "con", "gra"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = stat_name.to_upper()
		label.custom_minimum_size.x = 70
		label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
		ThemeColors.apply_body_font(label, ThemeColors.FONT_SIZE_LARGE)
		row.add_child(label)

		var minus_btn := Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(45, 45)
		minus_btn.pressed.connect(_on_stat_decrease.bind(stat_name))
		ThemeColors.apply_button_theme(minus_btn)
		row.add_child(minus_btn)
		stat_buttons[stat_name + "_minus"] = minus_btn

		var value_label := Label.new()
		value_label.custom_minimum_size.x = 56
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ThemeColors.apply_body_font(value_label)
		row.add_child(value_label)
		stat_labels[stat_name] = value_label

		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(45, 45)
		plus_btn.pressed.connect(_on_stat_increase.bind(stat_name))
		ThemeColors.apply_button_theme(plus_btn)
		row.add_child(plus_btn)
		stat_buttons[stat_name + "_plus"] = plus_btn

		# Stat bar visualization
		var bar_bg := ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(280, 17)
		bar_bg.color = ThemeColors.IRON_SHADOW
		row.add_child(bar_bg)

		var bar_fill := ColorRect.new()
		bar_fill.custom_minimum_size = Vector2(0, 17)
		bar_fill.color = STAT_COLORS.get(stat_name, ThemeColors.PRIMARY)
		bar_bg.add_child(bar_fill)
		bar_fill.position = Vector2.ZERO
		stat_labels[stat_name + "_bar"] = bar_fill
		stat_labels[stat_name + "_bar_bg"] = bar_bg

		var mod_label := Label.new()
		mod_label.text = "(R%+d H%+d)" % [race_mods[stat_name], house_mods[stat_name]]
		mod_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
		ThemeColors.apply_body_font(mod_label, ThemeColors.FONT_SIZE_HINT)
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
	var race: DataManager.RaceData = DataManager.get_race(selected_race)
	var house: DataManager.HouseData = DataManager.get_house(selected_house)

	for stat_name in ["str", "dex", "con", "gra"]:
		if not stat_labels.has(stat_name):
			continue
		var label: Label = stat_labels[stat_name]
		var value: int = base_stats[stat_name]
		label.text = "%+d" % value

		# Color based on value
		if value > 0:
			label.add_theme_color_override("font_color", ThemeColors.HEALTH_HIGH)
		elif value < 0:
			label.add_theme_color_override("font_color", ThemeColors.HEALTH_LOW)
		else:
			label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)

		# Update stat bar
		var bar_key: String = stat_name + "_bar"
		var bar_bg_key: String = stat_name + "_bar_bg"
		if stat_labels.has(bar_key) and stat_labels.has(bar_bg_key):
			var bar_fill: ColorRect = stat_labels[bar_key]
			var bar_bg: ColorRect = stat_labels[bar_bg_key]
			var race_mod: int = 0
			var house_mod: int = 0
			if race:
				match stat_name:
					"str": race_mod = race.str_mod
					"dex": race_mod = race.dex_mod
					"con": race_mod = race.con_mod
					"gra": race_mod = race.gra_mod
			if house:
				match stat_name:
					"str": house_mod = house.str_mod
					"dex": house_mod = house.dex_mod
					"con": house_mod = house.con_mod
					"gra": house_mod = house.gra_mod
			var total: int = value + race_mod + house_mod
			# Map range [-10, +10] to [0, 200] pixels
			var bar_width: float = clampf((total + 10.0) / 20.0, 0.0, 1.0) * bar_bg.custom_minimum_size.x
			bar_fill.custom_minimum_size.x = bar_width

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
# NAME ENTRY (with age and parentage)
# ============================================================================

func _show_name_entry() -> void:
	stage_label.text = "Name Your Character"

	# Character preview sprite
	if _tileset_texture:
		var preview_container := CenterContainer.new()
		_preview_rect = TextureRect.new()
		_preview_rect.custom_minimum_size = Vector2(180, 180)
		_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_update_character_preview()
		preview_container.add_child(_preview_rect)
		content_container.add_child(preview_container)

	# Name entry row
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Enter name..."
	name_edit.text = character_name
	name_edit.text_changed.connect(_on_name_changed)
	name_edit.custom_minimum_size.x = 320
	name_edit.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	name_edit.add_theme_color_override("caret_color", ThemeColors.GOLD_WARM)
	name_row.add_child(name_edit)

	# Random name button (uses NameGenerator)
	var random_btn := Button.new()
	random_btn.text = "Random Name"
	random_btn.pressed.connect(_on_random_name)
	ThemeColors.apply_button_theme(random_btn)
	name_row.add_child(random_btn)
	content_container.add_child(name_row)

	# Age display with reroll
	if character_age == 0:
		_roll_age()

	var age_row := HBoxContainer.new()
	age_row.add_theme_constant_override("separation", 8)

	var age_label := Label.new()
	age_label.text = "Age: %d" % character_age
	age_label.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	ThemeColors.apply_body_font(age_label)
	age_row.add_child(age_label)
	stat_labels["_age_label"] = age_label

	var reroll_btn := Button.new()
	reroll_btn.text = "(r)eroll"
	reroll_btn.pressed.connect(_on_reroll_age)
	ThemeColors.apply_button_theme(reroll_btn)
	age_row.add_child(reroll_btn)

	content_container.add_child(age_row)

	# Generate history if not already done
	if character_history.is_empty():
		_generate_history()

	# History display
	var history_label := RichTextLabel.new()
	history_label.bbcode_enabled = true
	history_label.fit_content = true
	history_label.scroll_active = false
	history_label.custom_minimum_size = Vector2(0, 60)
	history_label.add_theme_color_override("default_color", ThemeColors.TEXT_SECONDARY)
	ThemeColors.apply_rich_body_font(history_label)

	var muted := ThemeColors.TEXT_MUTED.to_html(false)
	history_label.text = "[color=#%s]%s[/color]" % [muted, character_history]
	content_container.add_child(history_label)
	stat_labels["_history_label"] = history_label

	info_label.text = _get_character_summary()

func _roll_age() -> void:
	## Roll an age based on race + house with lore-accurate ranges.
	var house_data: DataManager.HouseData = DataManager.get_house(selected_house)
	var house_alt: String = ""
	if house_data and not house_data.alternate_name.is_empty():
		house_alt = house_data.alternate_name
		# Strip "the " prefix for key matching (e.g. "the Dunedain" -> "Dunedain")
		if house_alt.begins_with("the "):
			house_alt = house_alt.substr(4)

	# Build lookup key: try race_house first, then race alone
	var key: String = selected_race + "_" + house_alt
	if key not in AGE_RANGES:
		key = selected_race
	if key not in AGE_RANGES:
		# Fallback to base race.txt values
		var race: DataManager.RaceData = DataManager.get_race(selected_race)
		if race:
			character_age = randi_range(race.age_base, race.age_max)
		else:
			character_age = randi_range(20, 60)
		return

	var range_data: Dictionary = AGE_RANGES[key]

	# Check for ancient Lothlorien elf (1/500 chance)
	if "ancient_chance" in range_data:
		if randi_range(1, range_data["ancient_chance"]) == 1:
			character_age = randi_range(range_data["ancient_min"], range_data["ancient_max"])
			return

	character_age = randi_range(range_data["min"], range_data["max"])

func _on_reroll_age() -> void:
	_roll_age()
	# Update age label
	if stat_labels.has("_age_label"):
		var age_label: Label = stat_labels["_age_label"]
		age_label.text = "Age: %d" % character_age
	# Regenerate history since age changed
	_generate_history()
	_update_history_display()
	info_label.text = _get_character_summary()

func _generate_history() -> void:
	## Generate parentage text by walking the history.txt chain tables.
	## Chain: start at race's history_index, roll probability, follow secondary index.
	var race: DataManager.RaceData = DataManager.get_race(selected_race)
	if not race:
		character_history = _generate_fallback_history()
		return

	var house_data: DataManager.HouseData = DataManager.get_house(selected_house)
	var house_index: int = house_data.index if house_data else 0

	var history_parts: Array[String] = []
	var current_index: int = race.history_index

	# Walk the chain: follow primary_index -> secondary_index until secondary == 0
	var max_steps: int = 20  # Safety limit
	var steps: int = 0
	while current_index > 0 and steps < max_steps:
		steps += 1
		if current_index not in _history_chains:
			break

		var entries: Array = _history_chains[current_index]
		var roll: int = randi_range(1, 100)
		var chosen_text: String = ""
		var chosen_secondary: int = 0

		# Find matching entry by probability (entries are sorted by ascending probability)
		for entry in entries:
			# Filter by house: house 0 means any house, otherwise must match
			if entry["house"] != 0 and entry["house"] != house_index:
				continue
			if roll <= entry["probability"]:
				chosen_text = entry["text"]
				chosen_secondary = entry["secondary"]
				break

		# Fallback: pick last matching entry if nothing matched
		if chosen_text.is_empty():
			for entry in entries:
				if entry["house"] == 0 or entry["house"] == house_index:
					chosen_text = entry["text"]
					chosen_secondary = entry["secondary"]

		if not chosen_text.is_empty():
			# Apply gender substitution: "child" -> "son"/"daughter"
			var child_word: String = "son" if selected_gender == "male" else "daughter"
			chosen_text = chosen_text.replace("child", child_word)
			history_parts.append(chosen_text)

		current_index = chosen_secondary

	if history_parts.is_empty():
		character_history = _generate_fallback_history()
	else:
		character_history = " ".join(history_parts)

func _generate_fallback_history() -> String:
	## Fallback history when history.txt chain data is unavailable.
	var child_word: String = "son" if selected_gender == "male" else "daughter"
	var house_data: DataManager.HouseData = DataManager.get_house(selected_house)
	var location: String = ""
	if house_data and not house_data.alternate_name.is_empty():
		location = house_data.alternate_name
	else:
		location = selected_house

	var professions: Array[String] = ["warrior", "craftsman", "healer", "archer", "scholar"]
	var profession: String = professions.pick_random()

	return "You are the %s of a %s from %s." % [child_word, profession, location]

func _update_history_display() -> void:
	if stat_labels.has("_history_label"):
		var history_label: RichTextLabel = stat_labels["_history_label"]
		var muted := ThemeColors.TEXT_MUTED.to_html(false)
		history_label.text = "[color=#%s]%s[/color]" % [muted, character_history]

func _update_character_preview() -> void:
	if not _preview_rect or not _tileset_texture:
		return

	# Use v2 player sprite system: race name + house ID + gender
	var house_id: int = 0
	var house_data: DataManager.HouseData = DataManager.get_house(selected_house)
	if house_data:
		house_id = house_data.index
	var gender: String = selected_gender if not selected_gender.is_empty() else "male"
	var coords: Vector2i = TileMapper.get_player_coords_v2(selected_race, house_id, gender)

	var atlas := AtlasTexture.new()
	atlas.atlas = _tileset_texture
	atlas.region = Rect2(coords.x * 64, coords.y * 64, 64, 64)
	_preview_rect.texture = atlas

func _on_name_changed(new_name: String) -> void:
	character_name = new_name
	info_label.text = _get_character_summary()
	_update_navigation()

func _on_random_name() -> void:
	# Use NameGenerator with race + house + gender awareness
	var house_data: DataManager.HouseData = DataManager.get_house(selected_house)
	var house_alt: String = ""
	if house_data and not house_data.alternate_name.is_empty():
		house_alt = house_data.alternate_name
	else:
		house_alt = selected_house

	var gender: String = selected_gender if not selected_gender.is_empty() else "male"
	character_name = NameGenerator.get_random_name(selected_race, house_alt, gender)

	# Update LineEdit
	for child in content_container.get_children():
		if child is HBoxContainer:
			for sub_child in child.get_children():
				if sub_child is LineEdit:
					sub_child.text = character_name
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
	var trait_text: String = selected_trait if not selected_trait.is_empty() else "(none)"
	var gender_text: String = selected_gender.capitalize() if not selected_gender.is_empty() else "?"
	var age_text: String = str(character_age) if character_age > 0 else "?"

	var diff_label: String = GameManager.DIFFICULTY_MODIFIERS.get(selected_difficulty, {}).get("label", "Normal")

	return "%s of %s\n%s %s | %s | Age %s\nTrait: %s | Difficulty: %s\n\nSTR %+d  DEX %+d  CON %+d  GRA %+d\n\nStarting XP: %d" % [
		display_name, house_suffix, selected_race, selected_house,
		gender_text, age_text, trait_text, diff_label,
		final_str, final_dex, final_con, final_gra, Player.STARTING_XP
	]

# ============================================================================
# DIFFICULTY SELECTION
# ============================================================================

func _show_difficulty_selection() -> void:
	stage_label.text = "Choose Difficulty"

	var gold: String = ThemeColors.PRIMARY.to_html(false)
	var muted: String = ThemeColors.TEXT_MUTED.to_html(false)

	info_label.bbcode_enabled = true
	info_label.text = "[color=#%s]Select the challenge level for your descent into Dol Guldur.[/color]" % muted

	var difficulty_group := _get_or_create_button_group("difficulty")

	var difficulties: Array[int] = [
		GameManager.Difficulty.EASY,
		GameManager.Difficulty.NORMAL,
		GameManager.Difficulty.HARD,
		GameManager.Difficulty.IRONMAN,
	]

	for diff: int in difficulties:
		var mods: Dictionary = GameManager.DIFFICULTY_MODIFIERS.get(diff, {})
		var label_text: String = mods.get("label", "Unknown")
		var desc: String = mods.get("description", "")

		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = difficulty_group
		btn.custom_minimum_size = Vector2(0, 60)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Style
		var btn_style: StyleBoxFlat = ThemeColors.create_panel_stylebox(
			ThemeColors.IRON_DARK, ThemeColors.IRON_HIGHLIGHT, 1, 6
		)
		btn.add_theme_stylebox_override("normal", btn_style)
		var pressed_style: StyleBoxFlat = ThemeColors.create_panel_stylebox(
			ThemeColors.GOLD_WARM * 0.3, ThemeColors.GOLD_WARM, 2, 6
		)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
		btn.add_theme_color_override("font_pressed_color", ThemeColors.PRIMARY)

		btn.text = "%s — %s" % [label_text, desc]

		# Pre-select current difficulty
		if diff == selected_difficulty:
			btn.button_pressed = true

		var captured_diff: int = diff
		btn.pressed.connect(func() -> void:
			selected_difficulty = captured_diff
		)

		content_container.add_child(btn)

# ============================================================================
# CONFIRMATION
# ============================================================================

func _show_confirmation() -> void:
	stage_label.text = "Confirm Character"

	# Show character preview if available
	if _tileset_texture:
		var preview_container := CenterContainer.new()
		_preview_rect = TextureRect.new()
		_preview_rect.custom_minimum_size = Vector2(180, 180)
		_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_update_character_preview()
		preview_container.add_child(_preview_rect)
		content_container.add_child(preview_container)

	# Generate procedural backstory
	var backstory_data: Dictionary = {
		"race": selected_race,
		"house": selected_house,
		"gender": selected_gender,
		"trait": selected_trait,
		"base_stats": base_stats,
		"age": character_age,
	}
	var backstory: String = BackstoryGeneratorScript.generate(backstory_data)
	# Merge backstory into history (parentage chain + backstory)
	if not character_history.is_empty():
		character_history = character_history + "\n\n" + backstory
	else:
		character_history = backstory

	var gold := ThemeColors.PRIMARY.to_html(false)
	var warm_gold: String = ThemeColors.GOLD_WARM.to_html(false)
	var muted := ThemeColors.TEXT_MUTED.to_html(false)
	var summary: String = _get_character_summary()

	# Backstory in a scrollable parchment-style container
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_container.add_child(scroll)

	var backstory_panel := PanelContainer.new()
	var parchment_style: StyleBoxFlat = ThemeColors.create_panel_stylebox(
		Color(0.12, 0.10, 0.08, 0.9),
		Color(0.6, 0.5, 0.3, 0.5),
		1, 8
	)
	backstory_panel.add_theme_stylebox_override("panel", parchment_style)
	backstory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(backstory_panel)

	var backstory_label := RichTextLabel.new()
	backstory_label.bbcode_enabled = true
	backstory_label.fit_content = true
	backstory_label.scroll_active = false
	backstory_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeColors.apply_rich_body_font(backstory_label)
	backstory_label.text = "[color=#%s]%s[/color]" % [warm_gold, character_history]
	backstory_panel.add_child(backstory_label)

	info_label.text = summary + "\n\n[color=#%s]Press 'Start Game' to begin your quest.[/color]" % gold
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
		Stage.GENDER:
			next_button.text = "Next"
			next_button.disabled = selected_gender.is_empty()
		Stage.TRAIT:
			next_button.text = "Next"
			next_button.disabled = selected_trait.is_empty()
		Stage.STATS:
			next_button.text = "Next"
			next_button.disabled = false
		Stage.NAME:
			next_button.text = "Next"
			next_button.disabled = character_name.is_empty()
		Stage.DIFFICULTY:
			next_button.text = "Confirm"
			next_button.disabled = false
		Stage.CONFIRM:
			next_button.text = "Start Game"
			next_button.disabled = false

func _on_back_pressed() -> void:
	if current_stage > Stage.RACE and not _transitioning:
		_show_stage(current_stage - 1 as Stage, -1)

func _on_next_pressed() -> void:
	if _transitioning:
		return
	if current_stage < Stage.CONFIRM:
		_show_stage(current_stage + 1 as Stage, 1)
	else:
		_finish_creation()

func _finish_creation() -> void:
	# Apply difficulty setting to GameManager before game starts
	if GameManager:
		GameManager.set_difficulty(selected_difficulty)

	var character_data := {
		"race": selected_race,
		"house": selected_house,
		"gender": selected_gender,
		"trait": selected_trait,
		"base_stats": base_stats.duplicate(),
		"name": character_name,
		"age": character_age,
		"history": character_history,
		"difficulty": selected_difficulty,
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

	# Keyboard shortcut for age reroll in NAME stage
	if current_stage == Stage.NAME and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and not event.shift_pressed and not event.ctrl_pressed:
			# Only reroll if focus is NOT on the LineEdit
			var focused: Control = get_viewport().gui_get_focus_owner()
			if not focused is LineEdit:
				_on_reroll_age()
				get_viewport().set_input_as_handled()
