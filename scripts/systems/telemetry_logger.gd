extends Node
## Lightweight telemetry capture for balancing and confusion diagnosis.
## Writes NDJSON lines to user://telemetry/current_run.ndjson.

const TELEMETRY_DIR := "user://telemetry"
const TELEMETRY_FILE := "user://telemetry/current_run.ndjson"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(TELEMETRY_DIR)
	_reset_run_file()
	_connect_signals()

func _connect_signals() -> void:
	if not EventBus:
		return
	EventBus.threat_summary_updated.connect(_on_threat_summary_updated)
	EventBus.forensic_event_recorded.connect(_on_forensic_event_recorded)
	EventBus.chronicle_updated.connect(_on_chronicle_updated)
	EventBus.room_event_seeded.connect(_on_room_event_seeded)
	EventBus.run_goal_completed.connect(_on_run_goal_completed)
	EventBus.level_entered.connect(_on_level_entered)
	EventBus.game_over.connect(_on_game_over)

func _reset_run_file() -> void:
	var file := FileAccess.open(TELEMETRY_FILE, FileAccess.WRITE)
	if file:
		file.store_string("")
		file.close()

func _write_event(event_name: String, payload: Dictionary) -> void:
	var file := FileAccess.open(TELEMETRY_FILE, FileAccess.READ_WRITE)
	if not file:
		return
	file.seek_end()
	var row: Dictionary = {
		"ts": Time.get_unix_time_from_system(),
		"turn": GameManager.turn_count if GameManager else 0,
		"depth": GameManager.current_depth if GameManager else 0,
		"event": event_name,
		"payload": payload,
	}
	file.store_string(JSON.stringify(row) + "\n")
	file.close()

func _on_threat_summary_updated(level: String, ready: int, casters: int, seen: int) -> void:
	_write_event("threat_summary_updated", {
		"level": level,
		"ready": ready,
		"casters": casters,
		"seen": seen,
	})

func _on_forensic_event_recorded(category: String, severity: String, text: String, turn: int) -> void:
	_write_event("forensic_event_recorded", {
		"category": category,
		"severity": severity,
		"text": text,
		"turn": turn,
	})

func _on_chronicle_updated(entry_count: int) -> void:
	_write_event("chronicle_updated", {"entry_count": entry_count})

func _on_room_event_seeded(depth: int, room_id: int, seed: int, tags: Array) -> void:
	_write_event("room_event_seeded", {
		"depth": depth,
		"room_id": room_id,
		"seed": seed,
		"tags": tags,
	})

func _on_level_entered(depth: int) -> void:
	_write_event("level_entered", {"depth": depth})

func _on_game_over(victory: bool, reason: String) -> void:
	_write_event("game_over", {"victory": victory, "reason": reason})

func _on_run_goal_completed(goal_id: String, description: String, tag: String) -> void:
	_write_event("run_goal_completed", {
		"goal_id": goal_id,
		"description": description,
		"tag": tag,
	})
