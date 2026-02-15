extends RefCounted
class_name ExplorationPolicy

const MOVE_DIRS: PackedStringArray = [
	"up", "right", "down", "left", "up_right", "down_right", "down_left", "up_left"
]

var _rng: RandomNumberGenerator
var _seen_tiles: Dictionary = {}
var _recent_actions: Array[String] = []

func _init(seed_value: int = 0) -> void:
	_rng = RandomNumberGenerator.new()
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

func observe(telemetry: Dictionary) -> void:
	var runtime: Dictionary = telemetry.get("runtime_state", {})
	var pos: Dictionary = runtime.get("player_pos", {})
	var key := "%d,%d" % [int(pos.get("x", -1)), int(pos.get("y", -1))]
	_seen_tiles[key] = true

func choose_action(step_index: int, telemetry: Dictionary) -> Dictionary:
	var runtime: Dictionary = telemetry.get("runtime_state", {})
	var visible_hostiles: int = int(runtime.get("visible_hostiles", 0))
	var ui_open: bool = bool(runtime.get("ui_open", false))

	if ui_open:
		if _rng.randf() < 0.5:
			return _record_action({"op": "toggle_inventory", "args": {}}, "toggle_inventory")
		return _record_action({"op": "toggle_character_panel", "args": {}}, "toggle_character_panel")

	if step_index > 0 and step_index % 17 == 0:
		return _record_action({"op": "toggle_inventory", "args": {}}, "toggle_inventory")
	if step_index > 0 and step_index % 23 == 0:
		return _record_action({"op": "toggle_character_panel", "args": {}}, "toggle_character_panel")
	if step_index > 0 and step_index % 13 == 0:
		return _record_action({
			"op": "gain_xp",
			"args": {"raw_amount": 12, "source": "exploration_probe", "event_context": "advisory_rule_probe"}
		}, "probe:xp")
	if step_index > 0 and step_index % 19 == 0:
		return _record_action({
			"op": "set_item_sample",
			"args": {"raw_name": "Curious Tonic", "tval": 75, "identified": false}
		}, "probe:item_sample")
	if step_index > 0 and step_index % 29 == 0:
		return _record_action({"op": "identify_item_sample", "args": {}}, "probe:identify")
	if step_index > 0 and step_index % 31 == 0:
		return _record_action({
			"op": "set_protection_pool",
			"args": {"effect_id": "exploration_probe_pool", "dice": 1, "sides": 4}
		}, "probe:protection")
	if step_index > 0 and step_index % 37 == 0:
		return _record_action({
			"op": "spawn_transition_boss",
			"args": {"displayed_title": "Probe Transition Boss"}
		}, "probe:boss")
	if step_index > 0 and step_index % 41 == 0:
		return _record_action({
			"op": "simulate_social_aggro",
			"args": {"source_monster": "probe_orc_captain", "ally_count": 2}
		}, "probe:aggro")

	if visible_hostiles > 0 and _rng.randf() < 0.30:
		return _record_action({"op": "wait_frames", "args": {"count": 1}}, "wait")

	var dir := _choose_direction()
	return _record_action({"op": "move", "args": {"dir": dir, "steps": 1}}, "move:%s" % dir)

func coverage_count() -> int:
	return _seen_tiles.size()

func _choose_direction() -> String:
	# Prefer cardinal movement for better map coverage; mix in diagonals.
	if _rng.randf() < 0.70:
		var cardinals: Array[String] = ["up", "right", "down", "left"]
		return cardinals[_rng.randi_range(0, cardinals.size() - 1)]
	return MOVE_DIRS[_rng.randi_range(0, MOVE_DIRS.size() - 1)]

func _record_action(action: Dictionary, label: String) -> Dictionary:
	_recent_actions.append(label)
	if _recent_actions.size() > 10:
		_recent_actions.pop_front()
	return action
