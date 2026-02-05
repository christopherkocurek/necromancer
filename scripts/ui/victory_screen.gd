extends Control
class_name VictoryScreen
## Displays victory recap with statistics and celebration text.

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

func _ready() -> void:
	hide()

func show_victory(player: Player, stats: RunStats, v_type: String) -> void:
	run_stats = stats
	victory_type = v_type
	_store_player_data(player)
	_calculate_score(player)
	_generate_display()
	show()

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
	# Full score formula from Sil-Q with victory bonuses
	var points: int = 0

	# Base: 100000 - turns (0-99999)
	points += maxi(0, Constants.SCORE_MAX_TURNS - run_stats.total_turns)

	# Challenge factor based on race
	var challenge: int = Constants.get_race_challenge_factor(player.race_name)

	# Depth bonus: 10 * challenge * depth
	points += run_stats.max_depth_reached * Constants.SCORE_DEPTH_MULTIPLIER * challenge

	# Escape bonus
	if run_stats.escaped:
		points += Constants.SCORE_ESCAPE_BONUS * challenge

	# Victory bonus (banishment is worth more)
	if run_stats.necromancer_defeated:
		points += Constants.SCORE_VICTORY_BONUS * challenge
	elif victory_type == "Escape":
		points += (Constants.SCORE_VICTORY_BONUS / 2) * challenge

	final_score = points

func _generate_display() -> void:
	# Set title based on victory type
	if victory_type == "Banishment":
		title_label.text = "THE NECROMANCER IS BANISHED!"
		title_label.add_theme_color_override("font_color", Color.GOLD)
		subtitle_label.text = "Sauron's power is broken!"
	else:  # Escape
		title_label.text = "YOU HAVE ESCAPED!"
		title_label.add_theme_color_override("font_color", Color.GREEN)
		subtitle_label.text = "The light of day greets you once more!"

	# Generate victory story
	_generate_story()

	# Character info (left column top)
	var house_str: String = " of %s" % player_data.house if not player_data.house.is_empty() else ""
	character_info.text = """THE VICTOR

%s
%s%s

Total XP Earned: %d
Turns Played: %d""" % [
		player_data.name,
		player_data.race,
		house_str,
		player_data.xp_earned,
		run_stats.total_turns
	]

	# Combat stats (right column)
	combat_stats.text = """DEEDS OF VALOR

Enemies slain: %d
Biggest kill: %s
Damage dealt: %d
Biggest hit: %d
Silent kills: %d""" % [
		run_stats.enemies_killed,
		run_stats.biggest_enemy_killed_name if not run_stats.biggest_enemy_killed_name.is_empty() else "None",
		run_stats.total_damage_dealt,
		run_stats.biggest_hit,
		run_stats.silent_kills
	]

	# Journey stats (left column bottom)
	journey_stats.text = """THE JOURNEY

Max depth: %d feet
Stairs down: %d
Stairs up: %d
Enemies avoided: %d
Times detected: %d
Best stealth streak: %d
Potions used: %d
Herbs consumed: %d""" % [
		run_stats.max_depth_reached * 50,
		run_stats.stairs_descended,
		run_stats.stairs_ascended,
		run_stats.enemies_avoided,
		run_stats.times_detected,
		run_stats.stealth_streak_max,
		run_stats.potions_quaffed,
		run_stats.herbs_consumed
	]

	# Achievements
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

	# Always add the primary victory achievement
	if victory_type == "Banishment" and not run_stats.necromancer_defeated:
		achievements.append("* BANISHED THE NECROMANCER")
	elif victory_type == "Escape" and not run_stats.escaped:
		achievements.append("* Escaped Dol Guldur")

	achievements_label.text = "LEGENDARY DEEDS\n\n" + "\n".join(achievements)

	# Score
	score_label.text = "FINAL SCORE: %d" % final_score

	# Options
	options_label.text = """
[N] New Game    [Q] Quit

[S] Save Victory Dump"""

func _generate_story() -> void:
	var story_text: String = ""

	if victory_type == "Banishment":
		story_text = """In the depths of Dol Guldur, you gathered the three pieces of the Rod of Istari,
the ancient staff of the Maiar. With wisdom forged through trials and will tempered
by adversity, you confronted the Necromancer upon his dark throne.

Speaking the words of banishment taught by the Wise, you raised the Rod and
unleashed its light. Sauron's spirit was torn from Middle-earth, cast into the
void between worlds. The shadow over the forest lifts, and the Elves of the
Greenwood will once again know peace.

Your name shall be remembered among the great heroes of the Third Age."""

	else:  # Escape
		story_text = """Armed with the Ring of Thrain and the Key to Erebor, you found the secret
way out of Dol Guldur. The ancient dwarven key opened passages hidden for
centuries, while the Ring's fire lit your path through the darkness.

You emerge into the light of day, free at last. The Ring of Thrain burns
warm against your skin, and with it you carry the last wish of Thrain son
of Thror - to see his legacy returned to his son Thorin.

The shadow of Dol Guldur still looms, but you have won your freedom."""

	story_label.text = story_text

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
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
	# Generate character dump
	var dump: String = _generate_character_dump()
	var filename: String = "victory-%s-%s.txt" % [
		player_data.name.replace(" ", "_"),
		Time.get_datetime_string_from_system().replace(":", "-")
	]
	var path: String = "user://dumps/%s" % filename

	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute("user://dumps")

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(dump)
		file.close()
		GameManager.log_message("Victory dump saved to: %s" % path, Color.GREEN)
	else:
		GameManager.log_message("Failed to save victory dump.", Color.RED)

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
		player_data.name,
		player_data.race,
		house_str,
		_get_victory_description(),
		skills_str,
		run_stats.total_turns,
		run_stats.enemies_killed,
		run_stats.total_damage_dealt,
		run_stats.max_depth_reached * 50,
		final_score,
		_get_achievements_string(),
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
