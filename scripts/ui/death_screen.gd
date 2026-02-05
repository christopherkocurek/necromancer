extends Control
class_name DeathScreen
## Displays death recap with epitaph, statistics, and options.

signal new_game_requested
signal quit_requested

@onready var epitaph_label: Label = $VBoxContainer/EpitaphLabel
@onready var character_info: Label = $VBoxContainer/HBoxContainer/LeftColumn/CharacterInfo
@onready var combat_stats: Label = $VBoxContainer/HBoxContainer/RightColumn/CombatStats
@onready var journey_stats: Label = $VBoxContainer/HBoxContainer/LeftColumn/JourneyStats
@onready var achievements_label: Label = $VBoxContainer/AchievementsLabel
@onready var options_label: Label = $VBoxContainer/OptionsLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel

var player_data: Dictionary = {}
var run_stats: RunStats = null
var final_score: int = 0

func _ready() -> void:
	hide()

func show_death(player: Player, stats: RunStats) -> void:
	run_stats = stats
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
	}

func _calculate_score(player: Player) -> void:
	# Full score formula from Sil-Q
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

	# Victory bonus
	if run_stats.necromancer_defeated:
		points += Constants.SCORE_VICTORY_BONUS * challenge

	final_score = points

func _generate_display() -> void:
	# Generate epitaph
	var epitaph: String = EpitaphGenerator.generate(run_stats)
	epitaph_label.text = '"%s"' % epitaph

	# Character info (left column top)
	var house_str: String = " of %s" % player_data.house if not player_data.house.is_empty() else ""
	character_info.text = """THE FALLEN

%s
%s%s

Slain by: %s
Depth: %d feet
Turns: %d""" % [
		player_data.name,
		player_data.race,
		house_str,
		run_stats.killer_name if not run_stats.killer_name.is_empty() else run_stats.died_from,
		player_data.depth * 50,  # Convert to feet
		run_stats.total_turns
	]

	# Combat stats (right column)
	combat_stats.text = """BLOOD SPILLED

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
Doors closed: %d
Potions used: %d
Herbs consumed: %d""" % [
		run_stats.max_depth_reached * 50,
		run_stats.stairs_descended,
		run_stats.stairs_ascended,
		run_stats.enemies_avoided,
		run_stats.times_detected,
		run_stats.stealth_streak_max,
		run_stats.doors_closed,
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
		achievements.append("* Took the Ring")
	if run_stats.escaped:
		achievements.append("* Escaped Dol Guldur")
	if run_stats.necromancer_defeated:
		achievements.append("* DEFEATED THE NECROMANCER")

	if achievements.is_empty():
		achievements_label.text = ""
	else:
		achievements_label.text = "MOMENTS OF NOTE\n\n" + "\n".join(achievements)

	# Score
	score_label.text = "FINAL SCORE: %d" % final_score

	# Options
	options_label.text = """
[N] New Game    [Q] Quit

[I] View Inventory    [C] Character Sheet
[M] Message Log       [S] Save Character Dump"""

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
	# TODO: Show final inventory
	GameManager.log_message("Inventory view not yet implemented.", Color.GRAY)

func _show_character() -> void:
	# TODO: Show character sheet
	GameManager.log_message("Character sheet not yet implemented.", Color.GRAY)

func _show_messages() -> void:
	# TODO: Show message log
	GameManager.log_message("Message log not yet implemented.", Color.GRAY)

func _save_dump() -> void:
	# Generate character dump
	var dump: String = _generate_character_dump()
	var filename: String = "%s-%s.txt" % [
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
		GameManager.log_message("Character dump saved to: %s" % path, Color.GREEN)
	else:
		GameManager.log_message("Failed to save character dump.", Color.RED)

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
		player_data.name,
		player_data.race,
		" of %s" % player_data.house if not player_data.house.is_empty() else "",
		run_stats.killer_name if not run_stats.killer_name.is_empty() else run_stats.died_from,
		player_data.depth,
		player_data.depth * 50,
		run_stats.total_turns,
		run_stats.enemies_killed,
		run_stats.total_damage_dealt,
		run_stats.max_depth_reached * 50,
		final_score,
		_get_achievements_string(),
		EpitaphGenerator.generate(run_stats),
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
