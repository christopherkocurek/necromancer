extends Node
## Non-power run goals manager. Provides directional objectives and chronicle tags.

signal goals_generated(goals: Array)
signal goal_completed(goal_id: String, description: String, tag: String)

var active_goals: Array[Dictionary] = []
var _is_active: bool = false

func _ready() -> void:
	if EventBus:
		EventBus.game_started.connect(_on_game_started)
		EventBus.round_completed.connect(_on_round_completed)
		EventBus.game_over.connect(_on_game_over)

func _on_game_started() -> void:
	_generate_goals()
	_is_active = true

func _on_game_over(_victory: bool, _reason: String) -> void:
	_is_active = false

func _generate_goals() -> void:
	active_goals.clear()
	active_goals.append(_make_goal("reach_depth_3", "Reach 150ft (Depth 3)", "Reached First Descent", 3))
	active_goals.append(_make_goal("kill_12", "Slay 12 enemies", "Held the Line", 12))
	active_goals.append(_make_goal("survive_150", "Survive 150 turns", "Endured the Dark", 150))
	if EventBus:
		EventBus.popup_requested.emit("Run Goals", _format_goal_popup())
	goals_generated.emit(active_goals.duplicate(true))

func _make_goal(id: String, desc: String, tag: String, target: int) -> Dictionary:
	return {
		"id": id,
		"description": desc,
		"tag": tag,
		"target": target,
		"progress": 0,
		"completed": false,
	}

func _on_round_completed(round_number: int) -> void:
	if not _is_active:
		return
	var player: Player = GameManager.player as Player
	if not player or not player.run_stats:
		return
	for i in range(active_goals.size()):
		var g: Dictionary = active_goals[i]
		if bool(g.completed):
			continue
		match str(g.id):
			"reach_depth_3":
				g.progress = maxi(int(g.progress), GameManager.current_depth)
			"kill_12":
				g.progress = maxi(int(g.progress), player.run_stats.enemies_killed)
			"survive_150":
				g.progress = maxi(int(g.progress), round_number)
		if int(g.progress) >= int(g.target):
			g.completed = true
			_award_goal(player, g)
		active_goals[i] = g

func _award_goal(player: Player, goal: Dictionary) -> void:
	var tag: String = str(goal.get("tag", "Unmarked Deed"))
	if not player.run_stats.run_goal_tags.has(tag):
		player.run_stats.run_goal_tags.append(tag)
	GameManager.log_message("Run Goal Complete: %s" % str(goal.get("description", "")), ThemeColors.ABILITY_LEARNED)
	if EventBus:
		EventBus.run_goal_completed.emit(str(goal.get("id", "")), str(goal.get("description", "")), tag)
	goal_completed.emit(str(goal.get("id", "")), str(goal.get("description", "")), tag)

func get_goal_summary_line() -> String:
	if active_goals.is_empty():
		return "Goals: --"
	var remaining: Array[String] = []
	for g in active_goals:
		if not bool(g.completed):
			remaining.append("%s %d/%d" % [str(g.description), int(g.progress), int(g.target)])
	if remaining.is_empty():
		return "Goals: Complete"
	return "Goals: " + remaining[0]

func _format_goal_popup() -> String:
	var lines: Array[String] = []
	lines.append("Field Orders:")
	for g in active_goals:
		lines.append("- %s" % str(g.description))
	lines.append("")
	lines.append("Chronicle rewards only. No power creep.")
	return "\n".join(lines)
