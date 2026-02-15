extends RefCounted
class_name ReportBuilder

func write_reports(base_output_dir: String, run_id: String, summary: Dictionary) -> Dictionary:
	var run_dir_rel := "%s/%s" % [base_output_dir, run_id]
	var run_dir_abs := ProjectSettings.globalize_path("res://%s" % run_dir_rel)
	DirAccess.make_dir_recursive_absolute(run_dir_abs)

	var json_rel := "%s/report.json" % run_dir_rel
	var md_rel := "%s/report.md" % run_dir_rel
	var json_abs := ProjectSettings.globalize_path("res://%s" % json_rel)
	var md_abs := ProjectSettings.globalize_path("res://%s" % md_rel)

	var jf := FileAccess.open(json_abs, FileAccess.WRITE)
	if jf != null:
		jf.store_string(JSON.stringify(summary, "\t"))

	var mf := FileAccess.open(md_abs, FileAccess.WRITE)
	if mf != null:
		mf.store_string(_to_markdown(summary))

	return {"report_json": json_rel, "report_md": md_rel}

func _to_markdown(summary: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("# Visual Bot Report")
	lines.append("")
	lines.append("- run_id: `%s`" % summary.get("run_id", ""))
	lines.append("- mode: `%s`" % summary.get("mode", ""))
	lines.append("- deterministic: `%s`" % str(summary.get("deterministic", false)))
	lines.append("- pass: `%s`" % str(summary.get("passed", false)))
	lines.append("- blocker_failures: `%d`" % int(summary.get("blocker_failures", 0)))
	lines.append("- major_failures: `%d`" % int(summary.get("major_failures", 0)))
	if summary.has("intent_pack"):
		lines.append("- intent_pack: `%s`" % str(summary.get("intent_pack", "")))
		lines.append("- intent_rules_loaded: `%d`" % int(summary.get("intent_rules_loaded", 0)))
	lines.append("")
	lines.append("## Scenario Results")

	for scenario in summary.get("scenarios", []):
		lines.append("")
		lines.append("### %s" % scenario.get("scenario_id", ""))
		lines.append("- status: `%s`" % scenario.get("status", "unknown"))
		for checkpoint in scenario.get("checkpoints", []):
			lines.append("- checkpoint `%s`: %s" % [checkpoint.get("checkpoint_id", ""), checkpoint.get("status", "unknown")])
			lines.append("- full: `%s`" % checkpoint.get("full_png", ""))
			lines.append("- telemetry: `%s`" % checkpoint.get("telemetry_json", ""))
			if str(checkpoint.get("diff_png", "")) != "":
				lines.append("- diff: `%s`" % checkpoint.get("diff_png", ""))
			for fail in checkpoint.get("failed_assertions", []):
				lines.append("- assert fail [%s] `%s`: %s" % [fail.get("severity", "major"), fail.get("path", ""), fail.get("detail", "")])

	lines.append("")
	lines.append("## Gate Decision")
	lines.append("- fail if deterministic and blocker/major > 0")
	return "\n".join(lines) + "\n"
