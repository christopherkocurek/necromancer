extends RefCounted
class_name ScenarioRunner

const ScenarioTypes = preload("res://scripts/testing/scenario_types.gd")
const TelemetryBus = preload("res://scripts/testing/telemetry_bus.gd")
const CaptureService = preload("res://scripts/testing/capture_service.gd")
const DiffEngine = preload("res://scripts/testing/diff_engine.gd")
const AssertEngine = preload("res://scripts/testing/assert_engine.gd")
const ReportBuilder = preload("res://scripts/testing/report_builder.gd")
const BaselineManager = preload("res://scripts/testing/baseline_manager.gd")
const GameAdapter = preload("res://scripts/testing/game_adapter.gd")

func run_suite(config: Dictionary, scenario_paths: PackedStringArray) -> Dictionary:
	var run_id := _make_run_id(config.get("label", "visual"))
	var output_root := "artifacts"
	var run_root := "%s/%s" % [output_root, run_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % run_root))

	var capture := CaptureService.new()
	var diff_engine := DiffEngine.new()
	var assert_engine := AssertEngine.new()
	var baseline := BaselineManager.new("tests/baselines/v1", bool(config.get("update_baseline", false)))

	var scenario_results: Array = []
	var blocker_failures := 0
	var major_failures := 0

	for path in scenario_paths:
		var loaded := ScenarioTypes.load_and_validate(path)
		if loaded.has("_error"):
			scenario_results.append({
				"scenario_id": path.get_file(),
				"status": "infra_error",
				"error": loaded
			})
			blocker_failures += 1
			continue

		var scenario: Dictionary = loaded
		var s_result := await _run_scenario(
			run_root,
			run_id,
			scenario,
			capture,
			diff_engine,
			assert_engine,
			baseline,
			config
		)
		scenario_results.append(s_result)
		blocker_failures += int(s_result.get("blocker_failures", 0))
		major_failures += int(s_result.get("major_failures", 0))

	var deterministic := bool(config.get("deterministic", true))
	var passed := true
	if deterministic and (blocker_failures > 0 or major_failures > 0):
		passed = false

	var summary := {
		"run_id": run_id,
		"mode": config.get("mode", "full"),
		"deterministic": deterministic,
		"inject_regressions": bool(config.get("inject_regressions", false)),
		"passed": passed,
		"blocker_failures": blocker_failures,
		"major_failures": major_failures,
		"scenarios": scenario_results
	}

	var report := ReportBuilder.new()
	var report_paths := report.write_reports(output_root, run_id, summary)
	summary["report_md"] = report_paths.get("report_md", "")
	summary["report_json"] = report_paths.get("report_json", "")
	return summary

func _run_scenario(
	run_root: String,
	run_id: String,
	scenario: Dictionary,
	capture: CaptureService,
	diff_engine: DiffEngine,
	assert_engine: AssertEngine,
	baseline: BaselineManager,
	config: Dictionary
) -> Dictionary:
	var bus := TelemetryBus.new()
	bus.reset()
	var adapter = GameAdapter.new()

	for setup_action in scenario.get("setup", []):
		await _apply_action(bus, adapter, setup_action, config)
	for action in scenario.get("actions", []):
		await _apply_action(bus, adapter, action, config)

	await _settle_ticks(int(scenario.get("settle_ticks", 0)))

	var checkpoints_out: Array = []
	var blocker_failures := 0
	var major_failures := 0

	for checkpoint in scenario.get("checkpoints", []):
		for checkpoint_action in checkpoint.get("actions", []):
			await _apply_action(bus, adapter, checkpoint_action, config)

		await _settle_ticks(int(checkpoint.get("settle_ticks", 0)))

		var cid := str(checkpoint.get("id", "checkpoint"))
		var telemetry: Dictionary
		if adapter.is_live_ready():
			telemetry = adapter.collect_telemetry(
				run_id,
				str(scenario.get("id", "")),
				cid,
				int(scenario.get("seed", 0)),
				bool(config.get("deterministic", true))
			)
		else:
			telemetry = bus.snapshot(
				run_id,
				str(scenario.get("id", "")),
				cid,
				int(scenario.get("seed", 0)),
				bool(config.get("deterministic", true))
			)
		var frame: Image = adapter.capture_frame() if adapter.is_live_ready() else null
		var cap := capture.capture_checkpoint(run_root, str(scenario.get("id", "")), cid, telemetry, frame)

		var assertion_results := assert_engine.evaluate_assertions(checkpoint.get("assertions", []), telemetry)
		var failed_assertions: Array = []
		for r in assertion_results:
			if not bool(r.get("passed", false)):
				failed_assertions.append(r)
				if r.get("severity", "major") == "blocker":
					blocker_failures += 1
				elif r.get("severity", "major") == "major":
					major_failures += 1

		baseline.upsert_baseline(str(scenario.get("id", "")), cid, cap.get("image"), telemetry)
		var baseline_img := baseline.load_baseline_image(str(scenario.get("id", "")), cid)
		var diff := diff_engine.compare(cap.get("image"), baseline_img)
		var diff_rel := ""
		var checkpoint_failed := not failed_assertions.is_empty() or not bool(diff.get("passed", true))
		if checkpoint_failed:
			diff_rel = "%s/%s/%s/diff.png" % [run_root, str(scenario.get("id", "")), cid]
			capture.save_diff_image(diff_rel, diff.get("diff_image"))
		if not bool(diff.get("passed", true)):
			if checkpoint.get("visual_severity", "minor") == "blocker":
				blocker_failures += 1
			elif checkpoint.get("visual_severity", "minor") == "major":
				major_failures += 1

		checkpoints_out.append({
			"checkpoint_id": cid,
			"status": "pass" if not checkpoint_failed else "fail",
			"full_png": cap.get("full_png_rel", ""),
			"telemetry_json": cap.get("telemetry_rel", ""),
			"diff_png": diff_rel,
			"failed_assertions": failed_assertions,
			"visual_diff": {
				"passed": diff.get("passed", true),
				"ratio": diff.get("ratio", 0.0),
				"changed_pixels": diff.get("changed_pixels", 0)
			}
		})

	for teardown_action in scenario.get("teardown", []):
		await _apply_action(bus, adapter, teardown_action, config)
	await adapter.teardown()

	var scenario_status := "pass"
	if blocker_failures > 0 or major_failures > 0:
		scenario_status = "fail"

	return {
		"scenario_id": scenario.get("id", ""),
		"status": scenario_status,
		"checkpoints": checkpoints_out,
		"blocker_failures": blocker_failures,
		"major_failures": major_failures
	}

func _apply_action(bus: TelemetryBus, adapter, action: Dictionary, config: Dictionary) -> void:
	var op := str(action.get("op", ""))
	var args: Dictionary = action.get("args", {})
	bus.apply_action(
		op,
		args,
		bool(config.get("inject_regressions", false))
	)
	await adapter.execute_action(op, args, bool(config.get("inject_regressions", false)))

func _settle_ticks(ticks: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for _i in range(max(ticks, 0)):
		await tree.process_frame

func _make_run_id(prefix: String) -> String:
	var ts := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	return "%s_%s" % [prefix, ts]
