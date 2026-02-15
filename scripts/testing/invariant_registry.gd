extends RefCounted
class_name InvariantRegistry

const AssertEngine = preload("res://scripts/testing/assert_engine.gd")

var _assert_engine := AssertEngine.new()
var _intent_rules: Array = []
var _intent_pack_path: String = ""

func configure(intent_pack_path: String) -> void:
	_intent_pack_path = intent_pack_path
	_intent_rules = []
	if intent_pack_path == "":
		return
	var abs_path := ProjectSettings.globalize_path("res://%s" % intent_pack_path)
	if not FileAccess.file_exists(abs_path):
		return
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var rules = parsed.get("rules", [])
		if rules is Array:
			_intent_rules = rules

func evaluate(telemetry: Dictionary, step_index: int) -> Array:
	var findings: Array = []

	_require_key(findings, telemetry, "runtime_state", "blocker", step_index)
	_require_key(findings, telemetry, "light_state", "major", step_index)
	_require_key(findings, telemetry, "xp_state", "major", step_index)
	_require_key(findings, telemetry, "boss_state", "major", step_index)
	_require_key(findings, telemetry, "aggro_state", "major", step_index)

	var runtime: Dictionary = telemetry.get("runtime_state", {})
	var hp: int = int(runtime.get("player_hp", 0))
	var max_hp: int = int(runtime.get("player_max_hp", 0))
	if max_hp <= 0:
		_add(findings, "runtime.hp.max_nonpositive", "blocker", "runtime_state.player_max_hp", "player_max_hp <= 0", step_index)
	elif hp < 0 or hp > max_hp:
		_add(findings, "runtime.hp.out_of_bounds", "blocker", "runtime_state.player_hp", "hp=%d max_hp=%d" % [hp, max_hp], step_index)

	if not bool(runtime.get("player_in_bounds", true)):
		_add(findings, "runtime.player_out_of_bounds", "blocker", "runtime_state.player_in_bounds", "player position is out of bounds", step_index)

	var depth: int = int(runtime.get("depth", 0))
	if depth < 1:
		_add(findings, "runtime.depth.invalid", "major", "runtime_state.depth", "depth must be >= 1", step_index)

	var light: Dictionary = telemetry.get("light_state", {})
	var lr: int = int(light.get("runtime_radius", 0))
	var lu: int = int(light.get("ui_radius", 0))
	if lr < 1:
		_add(findings, "light.runtime_too_low", "major", "light_state.runtime_radius", "runtime radius < 1", step_index)
	if abs(lr - lu) > 1:
		_add(findings, "light.ui_runtime_drift", "major", "light_state.ui_radius", "runtime=%d ui=%d" % [lr, lu], step_index)

	var xp: Dictionary = telemetry.get("xp_state", {})
	var raw: float = float(xp.get("raw_amount", 0))
	var final_amount: float = float(xp.get("final_amount", 0))
	var mult: float = float(xp.get("multiplier", 1.0))
	if raw < 0 or final_amount < 0:
		_add(findings, "xp.negative_amount", "major", "xp_state.final_amount", "raw=%s final=%s" % [str(raw), str(final_amount)], step_index)
	if raw > 0 and mult <= 0:
		_add(findings, "xp.multiplier_nonpositive", "major", "xp_state.multiplier", "raw>0 but multiplier<=0", step_index)

	var protection: Dictionary = telemetry.get("protection_state", {})
	for pool in protection.get("pools", []):
		if pool is Dictionary:
			var dice := str(pool.get("dice", ""))
			if dice == "0d0" or dice == "1d0":
				_add(findings, "protection.invalid_pool_present", "blocker", "protection_state.pools", "invalid pool %s present" % dice, step_index)

	var boss: Dictionary = telemetry.get("boss_state", {})
	if bool(boss.get("is_transition_boss", false)) and str(boss.get("unique_key", "")) == "":
		_add(findings, "boss.transition_missing_unique", "blocker", "boss_state.unique_key", "transition boss missing unique key", step_index)

	var aggro: Dictionary = telemetry.get("aggro_state", {})
	var alerted: Array = aggro.get("alerted_monsters", [])
	var wake_count: int = int(aggro.get("wake_count", 0))
	var target_updates: int = int(aggro.get("target_updates", 0))
	if wake_count < 0 or target_updates < 0:
		_add(findings, "aggro.negative_counts", "major", "aggro_state.wake_count", "negative aggro counters", step_index)
	if wake_count > 0 and alerted.is_empty():
		_add(findings, "aggro.wake_without_alerted", "major", "aggro_state.alerted_monsters", "wake_count>0 but alerted list empty", step_index)
	if not alerted.is_empty() and target_updates <= 0:
		_add(findings, "aggro.alerted_without_targets", "major", "aggro_state.target_updates", "alerted monsters but no target updates", step_index)

	_evaluate_intent_pack(findings, telemetry, step_index)

	return findings

func intent_rule_count() -> int:
	return _intent_rules.size()

func intent_pack_path() -> String:
	return _intent_pack_path

func _evaluate_intent_pack(findings: Array, telemetry: Dictionary, step_index: int) -> void:
	for rule in _intent_rules:
		if not (rule is Dictionary):
			continue
		var rule_dict: Dictionary = rule
		if not _rule_enabled(rule_dict):
			continue
		if not _when_passes(rule_dict, telemetry):
			continue
		var assertion: Dictionary = rule_dict.get("assert", {})
		if assertion.is_empty():
			continue
		var result := _assert_engine.evaluate_assertion(assertion, telemetry)
		if bool(result.get("passed", false)):
			continue
		var path := str(result.get("path", ""))
		var severity := str(rule_dict.get("severity", result.get("severity", "major")))
		var detail := str(rule_dict.get("description", str(result.get("detail", "intent rule failed"))))
		var rule_id := str(rule_dict.get("id", "unnamed_rule"))
		_add(findings, "intent.%s" % rule_id, severity, path, detail, step_index)

func _rule_enabled(rule: Dictionary) -> bool:
	if not rule.has("enabled"):
		return true
	return bool(rule.get("enabled", true))

func _when_passes(rule: Dictionary, telemetry: Dictionary) -> bool:
	var whens = rule.get("when", [])
	if not (whens is Array) or whens.is_empty():
		return true
	for clause in whens:
		if not (clause is Dictionary):
			return false
		var result := _assert_engine.evaluate_assertion(clause, telemetry)
		if not bool(result.get("passed", false)):
			return false
	return true

func _require_key(findings: Array, payload: Dictionary, key: String, severity: String, step_index: int) -> void:
	if not payload.has(key):
		_add(findings, "schema.missing_%s" % key, severity, key, "missing telemetry section", step_index)

func _add(findings: Array, id: String, severity: String, path: String, detail: String, step_index: int) -> void:
	findings.append({
		"id": id,
		"severity": severity,
		"path": path,
		"detail": detail,
		"step": step_index
	})
