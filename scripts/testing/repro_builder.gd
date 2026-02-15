extends RefCounted
class_name ReproBuilder

func write_repro(run_root: String, session_id: String, finding: Dictionary, action_trace: Array, telemetry: Dictionary) -> Dictionary:
	var step_index: int = int(finding.get("step", action_trace.size() - 1))
	var failure_id: String = str(finding.get("id", "unknown_failure")).replace(".", "_")
	var repro_dir_rel := "%s/repros" % run_root
	var repro_dir_abs := ProjectSettings.globalize_path("res://%s" % repro_dir_rel)
	DirAccess.make_dir_recursive_absolute(repro_dir_abs)

	var clipped_actions: Array = []
	var limit := mini(step_index + 1, action_trace.size())
	for i in range(limit):
		clipped_actions.append(action_trace[i])

	var payload := {
		"schema_version": "v1",
		"session_id": session_id,
		"failure": finding,
		"step_index": step_index,
		"actions": clipped_actions,
		"telemetry": telemetry
	}

	var base_name := "%s_step_%04d" % [failure_id, maxi(step_index, 0)]
	var json_rel := "%s/%s.json" % [repro_dir_rel, base_name]
	var md_rel := "%s/%s.md" % [repro_dir_rel, base_name]
	var json_abs := ProjectSettings.globalize_path("res://%s" % json_rel)
	var md_abs := ProjectSettings.globalize_path("res://%s" % md_rel)

	var jf := FileAccess.open(json_abs, FileAccess.WRITE)
	if jf != null:
		jf.store_string(JSON.stringify(payload, "\t"))

	var mf := FileAccess.open(md_abs, FileAccess.WRITE)
	if mf != null:
		mf.store_string(_to_markdown(session_id, finding, step_index, json_rel))

	return {"repro_json": json_rel, "repro_md": md_rel}

func _to_markdown(session_id: String, finding: Dictionary, step_index: int, json_rel: String) -> String:
	var lines: PackedStringArray = []
	lines.append("# Exploratory Repro")
	lines.append("")
	lines.append("- session: `%s`" % session_id)
	lines.append("- step: `%d`" % step_index)
	lines.append("- failure_id: `%s`" % str(finding.get("id", "")))
	lines.append("- severity: `%s`" % str(finding.get("severity", "major")))
	lines.append("- path: `%s`" % str(finding.get("path", "")))
	lines.append("- detail: `%s`" % str(finding.get("detail", "")))
	lines.append("- json: `%s`" % json_rel)
	lines.append("")
	lines.append("Replay by applying listed actions in order from a fresh run.")
	return "\n".join(lines) + "\n"
