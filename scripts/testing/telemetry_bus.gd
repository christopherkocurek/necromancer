extends RefCounted
class_name TelemetryBus

var _state: Dictionary = {}

func reset() -> void:
	_state = {
		"light_state": {"runtime_radius": 0, "ui_radius": 0, "stack": []},
		"naming_state": {"raw_name": "", "display_name": "", "category_prefix": "", "identified": false},
		"protection_state": {"pools": [], "total_min": 0, "total_max": 0, "total_value": 0, "invalid_pools_filtered": []},
		"boss_state": {
			"base_monster_name": "",
			"displayed_title": "",
			"unique_key": "",
			"spawn_source": "",
			"is_transition_boss": false
		},
		"xp_state": {
			"source": "",
			"raw_amount": 0,
			"multiplier": 1.0,
			"final_amount": 0,
			"event_context": ""
		},
		"aggro_state": {
			"source_monster": "",
			"alerted_monsters": [],
			"radius": 0,
			"wake_count": 0,
			"target_updates": 0
		},
		"meta": {"warnings": []}
	}

func _init() -> void:
	reset()

func apply_action(op: String, args: Dictionary, inject_enabled: bool) -> void:
	match op:
		"set_light":
			_state["light_state"] = {
				"runtime_radius": args.get("runtime_radius", 0),
				"ui_radius": args.get("ui_radius", 0),
				"stack": args.get("stack", [])
			}
		"set_naming":
			_state["naming_state"] = {
				"raw_name": args.get("raw_name", ""),
				"display_name": args.get("display_name", ""),
				"category_prefix": args.get("category_prefix", ""),
				"identified": args.get("identified", false)
			}
		"set_protection":
			_state["protection_state"] = {
				"pools": args.get("pools", []),
				"total_min": args.get("total_min", 0),
				"total_max": args.get("total_max", 0),
				"total_value": args.get("total_value", 0),
				"invalid_pools_filtered": args.get("invalid_pools_filtered", [])
			}
		"set_boss":
			_state["boss_state"] = {
				"base_monster_name": args.get("base_monster_name", ""),
				"displayed_title": args.get("displayed_title", ""),
				"unique_key": args.get("unique_key", ""),
				"spawn_source": args.get("spawn_source", ""),
				"is_transition_boss": args.get("is_transition_boss", false)
			}
		"set_xp":
			_state["xp_state"] = {
				"source": args.get("source", ""),
				"raw_amount": args.get("raw_amount", 0),
				"multiplier": args.get("multiplier", 1.0),
				"final_amount": args.get("final_amount", 0),
				"event_context": args.get("event_context", "")
			}
		"set_aggro":
			_state["aggro_state"] = {
				"source_monster": args.get("source_monster", ""),
				"alerted_monsters": args.get("alerted_monsters", []),
				"radius": args.get("radius", 0),
				"wake_count": args.get("wake_count", 0),
				"target_updates": args.get("target_updates", 0)
			}
		"add_warning":
			var warnings: Array = _state["meta"].get("warnings", [])
			warnings.append(args.get("message", ""))
			_state["meta"]["warnings"] = warnings
		"inject_regression_if_enabled":
			if inject_enabled:
				_inject_regression(str(args.get("class", "")))
		_:
			pass

func snapshot(run_id: String, scenario_id: String, checkpoint_id: String, seed_value: int, test_mode_enabled: bool) -> Dictionary:
	var now_ms := Time.get_unix_time_from_system() * 1000
	return {
		"schema_version": "v1",
		"run_id": run_id,
		"scenario_id": scenario_id,
		"checkpoint_id": checkpoint_id,
		"timestamp_unix_ms": int(now_ms),
		"seed": seed_value,
		"test_mode": test_mode_enabled,
		"light_state": _state["light_state"],
		"naming_state": _state["naming_state"],
		"protection_state": _state["protection_state"],
		"boss_state": _state["boss_state"],
		"xp_state": _state["xp_state"],
		"aggro_state": _state["aggro_state"],
		"warnings": _state["meta"].get("warnings", [])
	}

func _inject_regression(regression_class: String) -> void:
	match regression_class:
		"light":
			_state["light_state"]["ui_radius"] = int(_state["light_state"].get("runtime_radius", 0)) + 2
		"naming":
			_state["naming_state"]["display_name"] = "Unknown Relic"
			_state["naming_state"]["identified"] = false
		"protection":
			_state["protection_state"]["invalid_pools_filtered"] = []
			_state["protection_state"]["pools"] = [{"dice": "0d0", "value": 0}, {"dice": "1d0", "value": 0}]
		"boss":
			_state["boss_state"]["displayed_title"] = "Nameless"
			_state["boss_state"]["unique_key"] = ""
		"xp":
			_state["xp_state"]["final_amount"] = int(_state["xp_state"].get("raw_amount", 0))
		"aggro":
			_state["aggro_state"]["wake_count"] = 0
			_state["aggro_state"]["alerted_monsters"] = []
		_:
			var warnings: Array = _state["meta"].get("warnings", [])
			warnings.append("unknown regression class: %s" % regression_class)
			_state["meta"]["warnings"] = warnings
