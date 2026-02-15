extends SceneTree

const TestMode = preload("res://scripts/testing/test_mode.gd")
const GameAdapter = preload("res://scripts/testing/game_adapter.gd")
const ExplorationPolicy = preload("res://scripts/testing/exploration_policy.gd")
const InvariantRegistry = preload("res://scripts/testing/invariant_registry.gd")
const ReproBuilder = preload("res://scripts/testing/repro_builder.gd")
const CaptureService = preload("res://scripts/testing/capture_service.gd")
const ReportBuilder = preload("res://scripts/testing/report_builder.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := _arg_value(args, "--mode", "advisory")
	var steps := _arg_int(args, "--steps", 60)
	var sessions := _arg_int(args, "--sessions", 1)
	var capture_every := _arg_int(args, "--capture-every", 10)
	var inject_regressions := "--inject-regressions" in args
	var intent_pack := _arg_value(args, "--intent-pack", "tests/intent_rules/v1/advisory_core_v1.json")
	var test_mode = TestMode.from_cmdline(false, randi())
	test_mode.apply_runtime()

	var run_id := _make_run_id("exploratory_%s" % mode)
	var output_root := "artifacts"
	var run_root := "%s/%s" % [output_root, run_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % run_root))

	var capture := CaptureService.new()
	var registry = InvariantRegistry.new()
	registry.configure(intent_pack)
	var repro_builder = ReproBuilder.new()

	var scenario_results: Array = []
	var blocker_failures: int = 0
	var major_failures: int = 0

	for session_idx in range(maxi(1, sessions)):
		var session_id := "exploration_session_%02d" % session_idx
		var adapter = GameAdapter.new()
		var policy = ExplorationPolicy.new(int(Time.get_unix_time_from_system()) + session_idx)
		var action_trace: Array = []
		var checkpoints: Array = []
		var session_blockers: int = 0
		var session_majors: int = 0
		var seen_finding_ids: Dictionary = {}

		await adapter.execute_action("boot_game", {"name": "Explorer %02d" % session_idx}, false)
		await adapter.execute_action("wait_frames", {"count": 2}, false)

		for step_idx in range(maxi(1, steps)):
			var pre_checkpoint_id := "step_%04d_pre" % step_idx
			var pre_telemetry: Dictionary = adapter.collect_telemetry(run_id, session_id, pre_checkpoint_id, test_mode.seed_value, false)
			policy.observe(pre_telemetry)

			var action: Dictionary = policy.choose_action(step_idx, pre_telemetry)
			action_trace.append(action)
			await adapter.execute_action(str(action.get("op", "wait_frames")), action.get("args", {}), false)
			if inject_regressions and step_idx % 9 == 4:
				var cls := "light"
				await adapter.execute_action("inject_regression_if_enabled", {"class": cls}, true)
			await adapter.execute_action("wait_frames", {"count": 1}, false)

			var checkpoint_id := "step_%04d" % step_idx
			var telemetry: Dictionary = adapter.collect_telemetry(run_id, session_id, checkpoint_id, test_mode.seed_value, false)
			policy.observe(telemetry)
			var findings: Array = registry.evaluate(telemetry, step_idx)
			var should_capture: bool = findings.size() > 0 or (step_idx % maxi(1, capture_every) == 0) or (step_idx == steps - 1)

			var full_rel := ""
			var telemetry_rel := ""
			if should_capture:
				var frame: Image = adapter.capture_frame()
				var cap: Dictionary = capture.capture_checkpoint(run_root, session_id, checkpoint_id, telemetry, frame)
				full_rel = str(cap.get("full_png_rel", ""))
				telemetry_rel = str(cap.get("telemetry_rel", ""))

			var failed_assertions: Array = []
			for finding in findings:
				var severity := str(finding.get("severity", "major"))
				if severity == "blocker":
					session_blockers += 1
					blocker_failures += 1
				elif severity == "major":
					session_majors += 1
					major_failures += 1

				var finding_with_step: Dictionary = finding.duplicate()
				finding_with_step["step"] = step_idx
				var repro_json := ""
				if not seen_finding_ids.has(str(finding.get("id", ""))):
					seen_finding_ids[str(finding.get("id", ""))] = true
					var repro_paths := repro_builder.write_repro(run_root, session_id, finding_with_step, action_trace, telemetry)
					repro_json = str(repro_paths.get("repro_json", ""))
				failed_assertions.append({
					"type": "invariant",
					"path": finding.get("path", ""),
					"severity": severity,
					"passed": false,
					"detail": finding.get("detail", ""),
					"message": "%s%s" % [
						str(finding.get("id", "")),
						(" | repro=%s" % repro_json) if repro_json != "" else ""
					]
				})

			if should_capture or not failed_assertions.is_empty():
				checkpoints.append({
					"checkpoint_id": checkpoint_id,
					"status": "fail" if not failed_assertions.is_empty() else "pass",
					"full_png": full_rel,
					"telemetry_json": telemetry_rel,
					"diff_png": "",
					"failed_assertions": failed_assertions,
					"visual_diff": {"passed": true, "ratio": 0.0, "changed_pixels": 0}
				})

		await adapter.teardown()

		scenario_results.append({
			"scenario_id": session_id,
			"status": "fail" if (session_blockers > 0 or session_majors > 0) else "pass",
			"checkpoints": checkpoints,
			"blocker_failures": session_blockers,
			"major_failures": session_majors,
			"coverage_tiles": policy.coverage_count()
		})

	var summary := {
		"run_id": run_id,
		"mode": mode,
		"deterministic": false,
		"inject_regressions": inject_regressions,
		"intent_pack": registry.intent_pack_path(),
		"intent_rules_loaded": registry.intent_rule_count(),
		"passed": true,
		"blocker_failures": blocker_failures,
		"major_failures": major_failures,
		"scenarios": scenario_results
	}

	var report := ReportBuilder.new()
	var report_paths := report.write_reports(output_root, run_id, summary)
	summary["report_md"] = report_paths.get("report_md", "")
	summary["report_json"] = report_paths.get("report_json", "")

	print("[EXPLORATORY SUITE] run_id=%s" % run_id)
	print("[EXPLORATORY SUITE] report=%s" % summary.get("report_md", ""))
	print("[EXPLORATORY SUITE] intent_pack=%s rules=%d" % [summary.get("intent_pack", ""), int(summary.get("intent_rules_loaded", 0))])
	print("[EXPLORATORY SUITE] advisory findings blocker=%d major=%d" % [
		blocker_failures,
		major_failures
	])

	# Advisory-only: always non-blocking for findings.
	quit(0)

func _arg_value(args: PackedStringArray, key: String, fallback: String) -> String:
	for i in range(args.size()):
		var arg := args[i]
		if arg.begins_with("%s=" % key):
			return arg.substr(("%s=" % key).length())
		if arg == key and i + 1 < args.size():
			return args[i + 1]
	return fallback

func _arg_int(args: PackedStringArray, key: String, fallback: int) -> int:
	var value := _arg_value(args, key, "")
	if value == "":
		return fallback
	return int(value)

func _make_run_id(prefix: String) -> String:
	var ts := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	return "%s_%s" % [prefix, ts]
