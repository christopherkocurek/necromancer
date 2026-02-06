extends Control
class_name VictoryScreen
## Displays victory recap with phased reveal: gold title fade, narrative text scroll,
## score counter with shake, achievement "stamp" effect. Space skips to end.

signal new_game_requested
signal quit_requested

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var story_label: Label = %StoryLabel
@onready var character_info: Label = %CharacterInfo
@onready var combat_stats: Label = %CombatStats
@onready var journey_stats: Label = %JourneyStats
@onready var achievements_label: Label = %AchievementsLabel
@onready var options_label: Label = %OptionsLabel
@onready var score_label: Label = %ScoreLabel

var player_data: Dictionary = {}
var run_stats: RunStats = null
var final_score: int = 0
var victory_type: String = ""

# Phased reveal state
var _reveal_active: bool = false
var _reveal_complete: bool = false

# Gradient overlay
var _gradient_bg: ColorRect = null

# Story scroll state
var _story_timer: Timer = null
var _story_text: String = ""
var _story_index: int = 0

func _ready() -> void:
	hide()
	_setup_gradient_bg()
	_setup_story_timer()

func _setup_gradient_bg() -> void:
	_gradient_bg = ColorRect.new()
	_gradient_bg.set_anchors_preset(PRESET_FULL_RECT)
	_gradient_bg.color = Color(0, 0, 0, 0)
	_gradient_bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_gradient_bg)
	move_child(_gradient_bg, 0)

func _setup_story_timer() -> void:
	_story_timer = Timer.new()
	_story_timer.wait_time = 0.02
	_story_timer.one_shot = false
	_story_timer.timeout.connect(_on_story_tick)
	add_child(_story_timer)

func show_victory(player: Player, stats: RunStats, v_type: String) -> void:
	run_stats = stats
	victory_type = v_type
	_store_player_data(player)
	_calculate_score(player)
	_prepare_display()
	show()
	_start_phased_reveal()

func _store_player_data(player: Player) -> void:
	player_data = {
		"name": player.entity_name,
		"race": player.race_name,
		"house": player.house_name,
		"depth": GameManager.current_depth,
		"xp_earned": player.total_xp_earned,
		"skills": player.skills.duplicate(),
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
	elif victory_type == "Escape":
		points += (Constants.SCORE_VICTORY_BONUS / 2) * challenge
	final_score = points

func _prepare_display() -> void:
	# Set title based on victory type
	if victory_type == "Banishment":
		title_label.text = "THE NECROMANCER IS BANISHED!"
		subtitle_label.text = "Sauron's power is broken!"
	else:
		title_label.text = "YOU HAVE ESCAPED!"
		subtitle_label.text = "The light of day greets you once more!"

	# Generate story text for scrolling reveal
	_story_text = _get_story_text()

	# Character info
	var house_str: String = " of %s" % player_data.house if not player_data.house.is_empty() else ""
	character_info.text = """THE VICTOR

%s
%s%s

Total XP Earned: %d
Turns Played: %d""" % [
		player_data.name, player_data.race, house_str,
		player_data.xp_earned, run_stats.total_turns
	]

	# Combat stats
	combat_stats.text = """DEEDS OF VALOR

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
Potions used: %d
Herbs consumed: %d""" % [
		run_stats.max_depth_reached * 50, run_stats.stairs_descended,
		run_stats.stairs_ascended, run_stats.enemies_avoided,
		run_stats.times_detected, run_stats.stealth_streak_max,
		run_stats.potions_quaffed, run_stats.herbs_consumed
	]

	# Achievements
	var achievements: Array[String] = _get_achievement_list()
	if achievements.is_empty():
		achievements_label.text = ""
	else:
		achievements_label.text = "LEGENDARY DEEDS\n\n" + "\n".join(achievements)

	# Options
	options_label.text = """
[N] New Game    [Q] Quit

[S] Save Victory Dump"""

	# Hide all elements initially
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	story_label.modulate.a = 0.0
	story_label.text = ""
	character_info.modulate.a = 0.0
	combat_stats.modulate.a = 0.0
	journey_stats.modulate.a = 0.0
	achievements_label.modulate.a = 0.0
	achievements_label.scale = Vector2.ONE
	score_label.modulate.a = 0.0
	score_label.text = "FINAL SCORE: 0"
	options_label.modulate.a = 0.0

	var hbox: HBoxContainer = $VBoxContainer/HBoxContainer
	if hbox:
		hbox.modulate.a = 0.0

func _start_phased_reveal() -> void:
	_reveal_active = true
	_reveal_complete = false

	# Phase 0 (0.0s): Background gradient - dark to golden tint
	var gold_tint := Color(0.15, 0.12, 0.04, 0.5) if victory_type == "Banishment" else Color(0.05, 0.12, 0.04, 0.4)
	var bg_tween := create_tween()
	bg_tween.tween_property(_gradient_bg, "color", gold_tint, 1.0)

	# Phase 1 (0.5s): Title fade in with gold color
	var title_tween := create_tween()
	title_tween.tween_interval(0.5)
	title_tween.tween_callback(func():
		var gold_color: Color = ThemeColors.PRIMARY_BRIGHT if victory_type == "Banishment" else ThemeColors.HEALTH_HIGH
		title_label.add_theme_color_override("font_color", gold_color)
		title_label.pivot_offset = title_label.size / 2.0
		title_label.scale = Vector2(1.3, 1.3)
	)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.6)
	title_tween.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Phase 1.5 (1.3s): Subtitle fade
	var sub_tween := create_tween()
	sub_tween.tween_interval(1.3)
	sub_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.4)

	# Phase 2 (2.0s): Story narrative scroll
	var story_tween := create_tween()
	story_tween.tween_interval(2.0)
	story_tween.tween_callback(_start_story_scroll)

	# Phase 3 (4.5s): Stats slide in
	var stats_tween := create_tween()
	stats_tween.tween_interval(4.5)
	stats_tween.tween_callback(_reveal_stats)

	# Phase 4 (5.5s): Achievements stamp in
	var achieve_tween := create_tween()
	achieve_tween.tween_interval(5.5)
	achieve_tween.tween_callback(_stamp_achievements)

	# Phase 5 (6.5s): Score counter with shake
	var score_tween := create_tween()
	score_tween.tween_interval(6.5)
	score_tween.tween_callback(_animate_score)

	# Phase 6 (8.5s): Options appear
	var options_tween := create_tween()
	options_tween.tween_interval(8.5)
	options_tween.tween_callback(_reveal_options)

func _start_story_scroll() -> void:
	story_label.modulate.a = 1.0
	_story_index = 0
	_story_timer.start()

func _on_story_tick() -> void:
	if _story_index < _story_text.length():
		_story_index += 1
		story_label.text = _story_text.substr(0, _story_index)
	else:
		_story_timer.stop()

func _reveal_stats() -> void:
	var hbox: HBoxContainer = $VBoxContainer/HBoxContainer
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

func _stamp_achievements() -> void:
	if achievements_label.text.is_empty():
		return
	# Stamp effect: start at 1.3x scale, slam down to 1.0x
	achievements_label.pivot_offset = achievements_label.size / 2.0
	achievements_label.scale = Vector2(1.3, 1.3)
	achievements_label.modulate.a = 0.0
	var stamp_tween := create_tween()
	stamp_tween.tween_property(achievements_label, "modulate:a", 1.0, 0.15)
	stamp_tween.parallel().tween_property(achievements_label, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _animate_score() -> void:
	score_label.modulate.a = 1.0
	score_label.add_theme_color_override("font_color", ThemeColors.PRIMARY_BRIGHT)
	score_label.pivot_offset = score_label.size / 2.0

	# Count up from 0 to final score
	var score_tween := create_tween()
	score_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	score_tween.tween_method(func(val: float):
		score_label.text = "FINAL SCORE: %d" % int(val)
	, 0.0, float(final_score), 1.5)

	# Brief shake when counter finishes
	score_tween.tween_callback(func():
		var shake_tween := create_tween()
		shake_tween.tween_property(score_label, "scale", Vector2(1.1, 1.1), 0.05)
		shake_tween.tween_property(score_label, "scale", Vector2(0.95, 0.95), 0.05)
		shake_tween.tween_property(score_label, "scale", Vector2(1.03, 1.03), 0.04)
		shake_tween.tween_property(score_label, "scale", Vector2.ONE, 0.04)
	)

func _reveal_options() -> void:
	_reveal_complete = true
	_reveal_active = false
	var tween := create_tween()
	tween.tween_property(options_label, "modulate:a", 1.0, 0.3)

func _skip_to_end() -> void:
	if _reveal_complete:
		return

	# Stop story scroll
	_story_timer.stop()

	# Make everything visible immediately
	_gradient_bg.color = Color(0.15, 0.12, 0.04, 0.5) if victory_type == "Banishment" else Color(0.05, 0.12, 0.04, 0.4)

	title_label.modulate.a = 1.0
	title_label.scale = Vector2.ONE
	var gold_color: Color = ThemeColors.PRIMARY_BRIGHT if victory_type == "Banishment" else ThemeColors.HEALTH_HIGH
	title_label.add_theme_color_override("font_color", gold_color)

	subtitle_label.modulate.a = 1.0

	story_label.text = _story_text
	story_label.modulate.a = 1.0

	var hbox: HBoxContainer = $VBoxContainer/HBoxContainer
	if hbox:
		hbox.modulate.a = 1.0

	character_info.modulate.a = 1.0
	combat_stats.modulate.a = 1.0
	journey_stats.modulate.a = 1.0

	achievements_label.modulate.a = 1.0
	achievements_label.scale = Vector2.ONE

	score_label.modulate.a = 1.0
	score_label.text = "FINAL SCORE: %d" % final_score
	score_label.add_theme_color_override("font_color", ThemeColors.PRIMARY_BRIGHT)
	score_label.scale = Vector2.ONE

	options_label.modulate.a = 1.0

	_reveal_complete = true
	_reveal_active = false

func _get_story_text() -> String:
	if victory_type == "Banishment":
		return """In the depths of Dol Guldur, you gathered the three pieces of the Rod of Istari,
the ancient staff of the Maiar. With wisdom forged through trials and will tempered
by adversity, you confronted the Necromancer upon his dark throne.

Speaking the words of banishment taught by the Wise, you raised the Rod and
unleashed its light. Sauron's spirit was torn from Middle-earth, cast into the
void between worlds. The shadow over the forest lifts, and the Elves of the
Greenwood will once again know peace.

Your name shall be remembered among the great heroes of the Third Age."""

	else:
		return """Armed with the Ring of Thrain and the Key to Erebor, you found the secret
way out of Dol Guldur. The ancient dwarven key opened passages hidden for
centuries, while the Ring's fire lit your path through the darkness.

You emerge into the light of day, free at last. The Ring of Thrain burns
warm against your skin, and with it you carry the last wish of Thrain son
of Thror - to see his legacy returned to his son Thorin.

The shadow of Dol Guldur still looms, but you have won your freedom."""

func _get_achievement_list() -> Array[String]:
	var achievements: Array[String] = []
	if run_stats.saw_sauron:
		achievements.append("* Glimpsed the Necromancer")
	if run_stats.found_thrain:
		achievements.append("* Found Thrain")
	if run_stats.killed_nazgul:
		achievements.append("* Slew a Nazgul")
	if run_stats.stole_ring:
		achievements.append("* Claimed the Ring of Thrain")
	if run_stats.escaped:
		achievements.append("* Escaped Dol Guldur")
	if run_stats.necromancer_defeated:
		achievements.append("* BANISHED THE NECROMANCER")
	# Ensure primary victory achievement is present
	if victory_type == "Banishment" and not run_stats.necromancer_defeated:
		achievements.append("* BANISHED THE NECROMANCER")
	elif victory_type == "Escape" and not run_stats.escaped:
		achievements.append("* Escaped Dol Guldur")
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
			KEY_S:
				_save_dump()
		get_viewport().set_input_as_handled()

func _save_dump() -> void:
	var dump: String = _generate_character_dump()
	var filename: String = "victory-%s-%s.txt" % [
		player_data.name.replace(" ", "_"),
		Time.get_datetime_string_from_system().replace(":", "-")
	]
	var path: String = "user://dumps/%s" % filename
	DirAccess.make_dir_recursive_absolute("user://dumps")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(dump)
		file.close()
		GameManager.log_message("Victory dump saved to: %s" % path, ThemeColors.ABILITY_LEARNED)
	else:
		GameManager.log_message("Failed to save victory dump.", ThemeColors.MSG_ERROR)

func _generate_character_dump() -> String:
	var house_str: String = " of %s" % player_data.house if not player_data.house.is_empty() else ""
	var skills_str: String = ""
	for skill_name in player_data.skills:
		skills_str += "  %s: %d\n" % [skill_name.capitalize(), player_data.skills[skill_name]]

	var dump: String = """
================================================================================
                    THE NECROMANCER - VICTORY CHARACTER DUMP
================================================================================

                            *** %s ***

%s, %s%s

--------------------------------------------------------------------------------
                                 VICTORY TYPE
--------------------------------------------------------------------------------

%s

--------------------------------------------------------------------------------
                                    SKILLS
--------------------------------------------------------------------------------

%s
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
                                  VICTORY STORY
--------------------------------------------------------------------------------

%s

================================================================================
Generated: %s
================================================================================
""" % [
		victory_type.to_upper() + " VICTORY",
		player_data.name, player_data.race, house_str,
		_get_victory_description(),
		skills_str,
		run_stats.total_turns, run_stats.enemies_killed,
		run_stats.total_damage_dealt, run_stats.max_depth_reached * 50,
		final_score, _get_achievements_string(),
		story_label.text if story_label else "",
		Time.get_datetime_string_from_system()
	]
	return dump

func _get_victory_description() -> String:
	if victory_type == "Banishment":
		return "Banished Sauron using the Rod of Istari in the Throne Room"
	else:
		return "Escaped Dol Guldur with the Ring of Thrain and the Key to Erebor"

func _get_achievements_string() -> String:
	var achievements: Array[String] = []
	if run_stats.saw_sauron:
		achievements.append("- Glimpsed the Necromancer")
	if run_stats.found_thrain:
		achievements.append("- Found Thrain")
	if run_stats.killed_nazgul:
		achievements.append("- Slew a Nazgul")
	if run_stats.stole_ring:
		achievements.append("- Claimed the Ring")
	if run_stats.escaped:
		achievements.append("- Escaped Dol Guldur")
	if run_stats.necromancer_defeated:
		achievements.append("- BANISHED THE NECROMANCER")
	if achievements.is_empty():
		return "None"
	return "\n".join(achievements)
