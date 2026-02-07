extends Control
class_name CharacterCreation
## Character creation flow: Race -> House -> Trait -> Stats -> Name -> Start Game
## Enhanced with stage transitions, progress indicator, stat bars, and name file loading.

signal creation_complete(character_data: Dictionary)
signal creation_cancelled

enum Stage { RACE, HOUSE, TRAIT, STATS, NAME, CONFIRM }

var current_stage: Stage = Stage.RACE

# Character build state
var selected_race: String = ""
var selected_house: String = ""
var selected_trait: String = ""
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

# Stage transition
var _transitioning: bool = false

# Progress indicator dots
var _progress_dots: Array[ColorRect] = []
var _progress_container: HBoxContainer = null

# Character preview
var _preview_rect: TextureRect = null
var _tileset_texture: Texture2D = null

# Name list loaded from file
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

func _ready() -> void:
	_load_names_file()
	_load_tileset()
	_setup_progress_indicator()
	_setup_ui()
	_show_stage(Stage.RACE)

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
		Stage.TRAIT:
			_show_trait_selection()
		Stage.STATS:
			_show_stat_allocation()
		Stage.NAME:
			_show_name_entry()
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

	# Build name→TraitData lookup
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
# NAME ENTRY
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

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Enter name..."
	name_edit.text = character_name
	name_edit.text_changed.connect(_on_name_changed)
	name_edit.custom_minimum_size.x = 420
	name_edit.add_theme_color_override("font_color", ThemeColors.TEXT_PRIMARY)
	name_edit.add_theme_color_override("caret_color", ThemeColors.GOLD_WARM)
	content_container.add_child(name_edit)

	# Random name button
	var random_btn := Button.new()
	random_btn.text = "Random Name"
	random_btn.pressed.connect(_on_random_name)
	ThemeColors.apply_button_theme(random_btn)
	content_container.add_child(random_btn)

	info_label.text = _get_character_summary()

func _update_character_preview() -> void:
	if not _preview_rect or not _tileset_texture:
		return

	# Use v2 player sprite system: race name + house ID + gender
	var house_id: int = 0
	var house_data: DataManager.HouseData = DataManager.get_house(selected_house)
	if house_data:
		house_id = house_data.index
	var coords: Vector2i = TileMapper.get_player_coords_v2(selected_race, house_id, "male")

	var atlas := AtlasTexture.new()
	atlas.atlas = _tileset_texture
	atlas.region = Rect2(coords.x * 64, coords.y * 64, 64, 64)
	_preview_rect.texture = atlas

func _on_name_changed(new_name: String) -> void:
	character_name = new_name
	info_label.text = _get_character_summary()
	_update_navigation()

func _on_random_name() -> void:
	if _name_list.size() > 0:
		character_name = _name_list[randi() % _name_list.size()]
	else:
		character_name = FALLBACK_NAMES.pick_random()

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
	var trait_text: String = selected_trait if not selected_trait.is_empty() else "(none)"

	return "%s of %s\n%s %s\nTrait: %s\n\nSTR %+d  DEX %+d  CON %+d  GRA %+d\n\nStarting XP: %d" % [
		display_name, house_suffix, selected_race, selected_house, trait_text,
		final_str, final_dex, final_con, final_gra, Player.STARTING_XP
	]

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

	var gold := ThemeColors.PRIMARY.to_html(false)
	info_label.text = _get_character_summary() + "\n\n[color=#%s]Press 'Start Game' to begin your quest.[/color]" % gold
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
		Stage.TRAIT:
			next_button.text = "Next"
			next_button.disabled = selected_trait.is_empty()
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
	var character_data := {
		"race": selected_race,
		"house": selected_house,
		"trait": selected_trait,
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
