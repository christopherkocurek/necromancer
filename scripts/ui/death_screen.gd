extends Control
class_name DeathScreen
## Displays death recap with phased reveal: title, epitaph typewriter, stats slide,
## achievements, animated score counter. Space skips to end.

signal new_game_requested
signal quit_requested

@onready var epitaph_label: Label = $MarginContainer/VBoxContainer/EpitaphLabel
@onready var character_info: Label = $MarginContainer/VBoxContainer/ScrollContainer/StatsBox/HBoxContainer/LeftColumn/CharacterInfo
@onready var combat_stats: Label = $MarginContainer/VBoxContainer/ScrollContainer/StatsBox/HBoxContainer/RightColumn/CombatStats
@onready var journey_stats: Label = $MarginContainer/VBoxContainer/ScrollContainer/StatsBox/HBoxContainer/MiddleColumn/JourneyStats
@onready var achievements_label: Label = $MarginContainer/VBoxContainer/ScrollContainer/StatsBox/AchievementsLabel
@onready var options_label: Label = $MarginContainer/VBoxContainer/OptionsLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel

var player_data: Dictionary = {}
var run_stats: RunStats = null
var final_score: int = 0
var _player_ref: Player = null  # Kept for character panel access

# Phased reveal state
var _reveal_active: bool = false
var _reveal_complete: bool = false
var _typewriter_timer: Timer = null
var _typewriter_text: String = ""
var _typewriter_index: int = 0

# Vignette overlay
var _vignette: ColorRect = null

# Run highlights
var _highlights: Array[String] = []

func _ready() -> void:
	hide()
	_setup_vignette()
	_setup_typewriter_timer()

func _setup_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(PRESET_FULL_RECT)
	_vignette.color = Color(0, 0, 0, 0)
	_vignette.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_vignette)
	move_child(_vignette, 0)  # Behind everything

func _setup_typewriter_timer() -> void:
	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = 0.03
	_typewriter_timer.one_shot = false
	_typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(_typewriter_timer)

func show_death(player: Player, stats: RunStats) -> void:
	_player_ref = player
	run_stats = stats
	_store_player_data(player)
	_calculate_score(player)
	_generate_highlights()
	_prepare_display()
	show()
	_start_phased_reveal()
	if AudioManager:
		AudioManager.play_music("death")

func _store_player_data(player: Player) -> void:
	var depth: int = GameManager.current_depth
	player_data = {
		"name": player.entity_name,
		"race": player.race_name,
		"house": player.house_name,
		"depth": depth,
		"xp_earned": player.total_xp_earned,
		"layer_name": LayerConfig.get_layer_name(depth),
	}

func _calculate_score(player: Player) -> void:
	var points: int = 0
	points += maxi(0, Constants.SCORE_MAX_TURNS - run_stats.total_turns)
	var challenge: int = Constants.get_race_challenge_factor(player.race_name)
	points += run_stats.max_depth_reached * Constants.SCORE_DEPTH_MULTIPLIER * challenge
	if run_stats.escaped:
		points += Constants.SCORE_ESCAPE_BONUS * challenge
	if run_stats.necromancer_defeated:
		points += Constants.SCORE_VICTORY_BONUS * challenge
	final_score = points

func _generate_highlights() -> void:
	_highlights.clear()
	if run_stats.biggest_hit > 20:
		_highlights.append("* Dealt a devastating %d damage blow" % run_stats.biggest_hit)
	if run_stats.stealth_streak_max > 10:
		_highlights.append("* Remained undetected for %d turns" % run_stats.stealth_streak_max)
	if run_stats.silent_kills > 5:
		_highlights.append("* Dispatched %d enemies silently" % run_stats.silent_kills)
	if run_stats.enemies_avoided > 20:
		_highlights.append("* Avoided %d dangerous encounters" % run_stats.enemies_avoided)
	if run_stats.potions_quaffed > 10:
		_highlights.append("* Consumed %d potions in the depths" % run_stats.potions_quaffed)
	if not run_stats.biggest_enemy_killed_name.is_empty():
		_highlights.append("* Greatest foe slain: %s" % run_stats.biggest_enemy_killed_name)

func _prepare_display() -> void:
	# Generate all text but hide everything initially
	var epitaph: String = EpitaphGenerator.generate(run_stats)
	var layer_death_msg: String = DescriptionGenerator.generate_death_message(player_data.get("layer_name", ""))
	if not layer_death_msg.is_empty():
		_typewriter_text = '%s\n\n"%s"' % [layer_death_msg, epitaph]
	else:
		_typewriter_text = '"%s"' % epitaph

	# Character info
	var house_str: String = " of %s" % player_data.house if not player_data.house.is_empty() else ""
	character_info.text = """THE FALLEN

%s
%s%s

Slain by: %s
Depth: %d feet
Turns: %d""" % [
		player_data.name, player_data.race, house_str,
		run_stats.killer_name if not run_stats.killer_name.is_empty() else run_stats.died_from,
		player_data.depth * 50, run_stats.total_turns
	]

	# Combat stats
	combat_stats.text = """BLOOD SPILLED

Enemies slain: %d
Biggest kill: %s
Damage dealt: %d
Biggest hit: %d
Silent kills: %d""" % [
		run_stats.enemies_killed,
		run_stats.biggest_enemy_killed_name if not run_stats.biggest_enemy_killed_name.is_empty() else "None",
		run_stats.total_damage_dealt, run_stats.biggest_hit, run_stats.silent_kills
	]

	# Journey stats
	journey_stats.text = """THE JOURNEY

Max depth: %d feet
Stairs down: %d
Stairs up: %d
Enemies avoided: %d
Times detected: %d
Best stealth streak: %d
Doors closed: %d
Potions used: %d
Herbs consumed: %d""" % [
		run_stats.max_depth_reached * 50, run_stats.stairs_descended,
		run_stats.stairs_ascended, run_stats.enemies_avoided,
		run_stats.times_detected, run_stats.stealth_streak_max,
		run_stats.doors_closed, run_stats.potions_quaffed, run_stats.herbs_consumed
	]

	# Achievements + highlights
	var achievements: Array[String] = _get_achievement_list()
	achievements.append_array(_highlights)
	if achievements.is_empty():
		achievements_label.text = ""
	else:
		achievements_label.text = "MOMENTS OF NOTE\n\n" + "\n".join(achievements)

	# Options
	options_label.text = "[N] New Game   [Q] Quit   [I] Inventory   [C] Character   [S] Save Dump"

	# Apply Diablo-themed fonts - stat columns get larger text
	ThemeColors.apply_body_font(character_info, ThemeColors.FONT_SIZE_H3)
	ThemeColors.apply_body_font(combat_stats, ThemeColors.FONT_SIZE_H3)
	ThemeColors.apply_body_font(journey_stats, ThemeColors.FONT_SIZE_H3)
	ThemeColors.apply_body_font(achievements_label, ThemeColors.FONT_SIZE_BODY)
	ThemeColors.apply_heading_font(score_label, ThemeColors.FONT_SIZE_H2)
	ThemeColors.apply_body_font(options_label, ThemeColors.FONT_SIZE_BODY)
	ThemeColors.apply_body_font(epitaph_label)
	epitaph_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)

	# Apply title font
	var title_node_prep: Label = $MarginContainer/VBoxContainer.get_child(0) if $MarginContainer/VBoxContainer.get_child_count() > 0 else null
	if title_node_prep and title_node_prep is Label:
		ThemeColors.apply_heading_font(title_node_prep, ThemeColors.FONT_SIZE_TITLE)
		title_node_prep.add_theme_color_override("font_color", ThemeColors.BLOOD_BRIGHT)

	# Hide all elements initially
	epitaph_label.modulate.a = 0.0
	epitaph_label.text = ""
	character_info.modulate.a = 0.0
	combat_stats.modulate.a = 0.0
	journey_stats.modulate.a = 0.0
	achievements_label.modulate.a = 0.0
	score_label.modulate.a = 0.0
	score_label.text = "FINAL SCORE: 0"
	options_label.modulate.a = 0.0

	var hbox: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/StatsBox/HBoxContainer
	if hbox:
		hbox.modulate.a = 0.0

func _start_phased_reveal() -> void:
	_reveal_active = true
	_reveal_complete = false

	# Phase 0 (0.0s): Vignette fade in
	var vignette_tween := create_tween()
	vignette_tween.tween_property(_vignette, "color:a", 0.4, 0.5)

	# Phase 1 (0.8s): Title scale in
	var title_node: Label = $MarginContainer/VBoxContainer.get_child(0) if $MarginContainer/VBoxContainer.get_child_count() > 0 else null
	if title_node and title_node is Label:
		ThemeColors.apply_heading_font(title_node, ThemeColors.FONT_SIZE_TITLE)
		title_node.add_theme_color_override("font_color", ThemeColors.BLOOD_BRIGHT)
		title_node.pivot_offset = title_node.size / 2.0
		title_node.scale = Vector2(1.5, 1.5)
		title_node.modulate.a = 0.0
		var title_tween := create_tween()
		title_tween.tween_interval(0.8)
		title_tween.tween_property(title_node, "modulate:a", 1.0, 0.4)
		title_tween.parallel().tween_property(title_node, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Phase 2 (1.5s): Epitaph typewriter
	var epitaph_tween := create_tween()
	epitaph_tween.tween_interval(1.5)
	epitaph_tween.tween_callback(_start_typewriter)

	# Phase 3 (3.0s): Stats slide in
	var stats_tween := create_tween()
	stats_tween.tween_interval(3.0)
	stats_tween.tween_callback(_reveal_stats)

	# Phase 4 (4.0s): Achievements fade in
	var achieve_tween := create_tween()
	achieve_tween.tween_interval(4.0)
	achieve_tween.tween_callback(_reveal_achievements)

	# Phase 5 (5.0s): Score counter
	var score_tween := create_tween()
	score_tween.tween_interval(5.0)
	score_tween.tween_callback(_animate_score)

	# Phase 6 (6.5s): Options appear
	var options_tween := create_tween()
	options_tween.tween_interval(6.5)
	options_tween.tween_callback(_reveal_options)

func _start_typewriter() -> void:
	epitaph_label.modulate.a = 1.0
	_typewriter_index = 0
	_typewriter_timer.start()

func _on_typewriter_tick() -> void:
	if _typewriter_index < _typewriter_text.length():
		_typewriter_index += 1
		epitaph_label.text = _typewriter_text.substr(0, _typewriter_index)
	else:
		_typewriter_timer.stop()

func _reveal_stats() -> void:
	var hbox: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/StatsBox/HBoxContainer
	if hbox:
		hbox.modulate.a = 1.0

	# Left column slides from left
	var ci_base_x: float = character_info.position.x
	character_info.position.x = ci_base_x - 200
	character_info.modulate.a = 0.0
	var left_tween := create_tween()
	left_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	left_tween.tween_property(character_info, "position:x", ci_base_x, 0.3)
	left_tween.parallel().tween_property(character_info, "modulate:a", 1.0, 0.3)

	var js_base_x: float = journey_stats.position.x
	journey_stats.position.x = js_base_x - 200
	journey_stats.modulate.a = 0.0
	var journey_tween := create_tween()
	journey_tween.tween_interval(0.1)
	journey_tween.tween_property(journey_stats, "position:x", js_base_x, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	journey_tween.parallel().tween_property(journey_stats, "modulate:a", 1.0, 0.3)

	# Right column slides from right
	var cs_base_x: float = combat_stats.position.x
	combat_stats.position.x = cs_base_x + 200
	combat_stats.modulate.a = 0.0
	var right_tween := create_tween()
	right_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	right_tween.tween_property(combat_stats, "position:x", cs_base_x, 0.3)
	right_tween.parallel().tween_property(combat_stats, "modulate:a", 1.0, 0.3)

func _reveal_achievements() -> void:
	if achievements_label.text.is_empty():
		return
	achievements_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(achievements_label, "modulate:a", 1.0, 0.3)

func _animate_score() -> void:
	score_label.modulate.a = 1.0
	score_label.add_theme_color_override("font_color", ThemeColors.GOLD_BRIGHT)
	var score_tween := create_tween()
	score_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	score_tween.tween_method(func(val: float):
		score_label.text = "FINAL SCORE: %d" % int(val)
	, 0.0, float(final_score), 1.5)

func _reveal_options() -> void:
	_reveal_complete = true
	_reveal_active = false
	var tween := create_tween()
	tween.tween_property(options_label, "modulate:a", 1.0, 0.3)

func _skip_to_end() -> void:
	if _reveal_complete:
		return

	# Stop typewriter
	_typewriter_timer.stop()

	# Make everything visible immediately
	epitaph_label.text = _typewriter_text
	epitaph_label.modulate.a = 1.0

	var title_node: Label = $MarginContainer/VBoxContainer.get_child(0) if $MarginContainer/VBoxContainer.get_child_count() > 0 else null
	if title_node and title_node is Label:
		title_node.modulate.a = 1.0
		title_node.scale = Vector2.ONE

	var hbox: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/StatsBox/HBoxContainer
	if hbox:
		hbox.modulate.a = 1.0

	character_info.modulate.a = 1.0
	combat_stats.modulate.a = 1.0
	journey_stats.modulate.a = 1.0
	achievements_label.modulate.a = 1.0
	score_label.modulate.a = 1.0
	score_label.text = "FINAL SCORE: %d" % final_score
	options_label.modulate.a = 1.0
	_vignette.color.a = 0.4

	_reveal_complete = true
	_reveal_active = false

func _get_achievement_list() -> Array[String]:
	var achievements: Array[String] = []
	if run_stats.saw_sauron:
		achievements.append("* Glimpsed the Necromancer")
	if run_stats.found_thrain:
		achievements.append("* Found Thrain")
	if run_stats.killed_nazgul:
		achievements.append("* Slew a Nazgul")
	if run_stats.stole_ring:
		achievements.append("* Took the Ring")
	if run_stats.escaped:
		achievements.append("* Escaped Dol Guldur")
	if run_stats.necromancer_defeated:
		achievements.append("* DEFEATED THE NECROMANCER")
	return achievements

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		# Space skips reveal animation
		if event.keycode == KEY_SPACE and not _reveal_complete:
			_skip_to_end()
			get_viewport().set_input_as_handled()
			return

		if not _reveal_complete:
			get_viewport().set_input_as_handled()
			return

		match event.keycode:
			KEY_N:
				new_game_requested.emit()
				hide()
			KEY_Q, KEY_ESCAPE:
				quit_requested.emit()
			KEY_I:
				_show_inventory()
			KEY_C:
				_show_character()
			KEY_M:
				_show_messages()
			KEY_S:
				_save_dump()
		get_viewport().set_input_as_handled()

func _show_inventory() -> void:
	GameManager.log_message("Inventory view not yet implemented.", ThemeColors.MSG_SYSTEM)

func _show_character() -> void:
	if _player_ref and is_instance_valid(_player_ref):
		# Find the character panel in our parent (UILayer)
		var parent_layer: Node = get_parent()
		if parent_layer:
			for child in parent_layer.get_children():
				if child is CharacterPanel:
					child.open(_player_ref)
					return
	GameManager.log_message("Character data not available.", ThemeColors.MSG_SYSTEM)

func _show_messages() -> void:
	GameManager.log_message("Message log not yet implemented.", ThemeColors.MSG_SYSTEM)

func _save_dump() -> void:
	var dump: String = _generate_character_dump()
	var filename: String = "%s-%s.txt" % [
		player_data.name.replace(" ", "_"),
		Time.get_datetime_string_from_system().replace(":", "-")
	]
	var path: String = "user://dumps/%s" % filename
	DirAccess.make_dir_recursive_absolute("user://dumps")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(dump)
		file.close()
		GameManager.log_message("Character dump saved to: %s" % path, ThemeColors.ABILITY_LEARNED)
	else:
		GameManager.log_message("Failed to save character dump.", ThemeColors.MSG_ERROR)

func _generate_character_dump() -> String:
	var dump: String = """
================================================================================
                         THE NECROMANCER - Character Dump
================================================================================

%s, %s%s
Slain by %s on depth %d (%d feet)

--------------------------------------------------------------------------------
                                 FINAL STATISTICS
--------------------------------------------------------------------------------

Turns played: %d
Enemies killed: %d
Total damage dealt: %d
Max depth reached: %d feet
Final score: %d

--------------------------------------------------------------------------------
                                  ACHIEVEMENTS
--------------------------------------------------------------------------------

%s

--------------------------------------------------------------------------------
                                    EPITAPH
--------------------------------------------------------------------------------

"%s"

================================================================================
Generated: %s
================================================================================
""" % [
		player_data.name, player_data.race,
		" of %s" % player_data.house if not player_data.house.is_empty() else "",
		run_stats.killer_name if not run_stats.killer_name.is_empty() else run_stats.died_from,
		player_data.depth, player_data.depth * 50,
		run_stats.total_turns, run_stats.enemies_killed, run_stats.total_damage_dealt,
		run_stats.max_depth_reached * 50, final_score,
		_get_achievements_string(), EpitaphGenerator.generate(run_stats),
		Time.get_datetime_string_from_system()
	]
	return dump

func _get_achievements_string() -> String:
	var achievements: Array[String] = []
	if run_stats.saw_sauron:
		achievements.append("- Glimpsed the Necromancer")
	if run_stats.found_thrain:
		achievements.append("- Found Thrain")
	if run_stats.killed_nazgul:
		achievements.append("- Slew a Nazgul")
	if run_stats.stole_ring:
		achievements.append("- Took the Ring")
	if run_stats.escaped:
		achievements.append("- Escaped Dol Guldur")
	if run_stats.necromancer_defeated:
		achievements.append("- DEFEATED THE NECROMANCER")
	if achievements.is_empty():
		return "None"
	return "\n".join(achievements)
