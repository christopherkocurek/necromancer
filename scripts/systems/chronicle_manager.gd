extends Node
## Persistent chronicle of completed runs (deaths and victories).
## Stored as lightweight JSON in user://chronicle.json.

const CHRONICLE_PATH := "user://chronicle.json"
const MAX_ENTRIES := 300

var entries: Array[Dictionary] = []

func _ready() -> void:
	_load()

func record_run(player: Player, stats: RunStats, outcome: String) -> void:
	if not player or not stats:
		return
	var entry: Dictionary = {
		"timestamp": Time.get_unix_time_from_system(),
		"datetime": Time.get_datetime_string_from_system(),
		"name": player.entity_name,
		"race": player.race_name,
		"house": player.house_name,
		"depth": GameManager.current_depth,
		"turns": stats.total_turns,
		"outcome": outcome,  # "death", "escape", "banishment"
		"killer": stats.killer_name,
		"died_from": stats.died_from,
		"score_hint": _score_hint(stats),
		"epitaph": EpitaphGenerator.generate(stats),
		"highlights": stats.get_recent_forensics(3),
		"tags": stats.run_goal_tags.duplicate(),
	}
	entries.append(entry)
	if entries.size() > MAX_ENTRIES:
		entries.pop_front()
	_save()
	if EventBus:
		EventBus.chronicle_updated.emit(entries.size())

func get_recent_entries(limit: int = 20) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var start_idx: int = maxi(0, entries.size() - limit)
	for i in range(start_idx, entries.size()):
		out.append(entries[i])
	return out

func get_recent_summary_lines(limit: int = 10) -> Array[String]:
	var lines: Array[String] = []
	var recent: Array[Dictionary] = get_recent_entries(limit)
	for i in range(recent.size() - 1, -1, -1):
		var e: Dictionary = recent[i]
		var name: String = str(e.get("name", "Unknown"))
		var race: String = str(e.get("race", ""))
		var depth: int = int(e.get("depth", 0))
		var outcome: String = str(e.get("outcome", "death"))
		var killer: String = str(e.get("killer", ""))
		var outcome_text: String = "FELL"
		if outcome == "escape":
			outcome_text = "ESCAPED"
		elif outcome == "banishment":
			outcome_text = "BANISHED"
		var line: String = "%s (%s) - %s at %dft" % [name, race, outcome_text, depth * 50]
		if not killer.is_empty() and outcome == "death":
			line += " by %s" % killer
		var tags: Variant = e.get("tags", [])
		if tags is Array and not tags.is_empty():
			line += " [%s]" % ", ".join(tags)
		lines.append(line)
	return lines

func _score_hint(stats: RunStats) -> int:
	return stats.enemies_killed * 10 + stats.max_depth_reached * 50 + stats.total_damage_dealt / 3

func _load() -> void:
	if not FileAccess.file_exists(CHRONICLE_PATH):
		return
	var file := FileAccess.open(CHRONICLE_PATH, FileAccess.READ)
	if not file:
		return
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Variant = json.data
	if data is Dictionary:
		var raw_entries: Variant = data.get("entries", [])
		if raw_entries is Array:
			for v in raw_entries:
				if v is Dictionary:
					entries.append(v)

func _save() -> void:
	var file := FileAccess.open(CHRONICLE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify({"entries": entries}, "\t"))
	file.close()
