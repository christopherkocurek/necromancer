extends SceneTree

const TestMode = preload("res://scripts/testing/test_mode.gd")
const ScenarioRunner = preload("res://scripts/testing/scenario_runner.gd")

const SCENARIO_FILES := [
	"res://tests/scenarios/v1/light_matrix_v1.json",
	"res://tests/scenarios/v1/identify_naming_v1.json",
	"res://tests/scenarios/v1/protection_model_v1.json",
	"res://tests/scenarios/v1/transition_boss_v1.json",
	"res://tests/scenarios/v1/xp_sources_v1.json",
	"res://tests/scenarios/v1/social_aggro_v1.json"
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := _arg_value(args, "--mode", "smoke")
	var update_baseline := "--update-baseline" in args
	var inject_regressions := "--inject-regressions" in args

	var test_mode = TestMode.from_cmdline(true, 1337)
	test_mode.apply_runtime()

	var scenario_paths: PackedStringArray = []
	if mode == "smoke":
		scenario_paths = PackedStringArray([SCENARIO_FILES[0], SCENARIO_FILES[1]])
	else:
		scenario_paths = PackedStringArray(SCENARIO_FILES)

	var runner := ScenarioRunner.new()
	var summary := await runner.run_suite({
		"label": "visual_%s" % mode,
		"mode": mode,
		"deterministic": test_mode.deterministic_enabled,
		"update_baseline": update_baseline,
		"inject_regressions": inject_regressions
	}, scenario_paths)

	print("[VISUAL SUITE] run_id=%s" % summary.get("run_id", ""))
	print("[VISUAL SUITE] report=%s" % summary.get("report_md", ""))
	print("[VISUAL SUITE] passed=%s blocker=%d major=%d" % [
		str(summary.get("passed", false)),
		int(summary.get("blocker_failures", 0)),
		int(summary.get("major_failures", 0))
	])

	if bool(summary.get("passed", false)):
		quit(0)
	else:
		quit(1)

func _arg_value(args: PackedStringArray, key: String, fallback: String) -> String:
	for i in range(args.size()):
		var arg := args[i]
		if arg.begins_with("%s=" % key):
			return arg.substr(("%s=" % key).length())
		if arg == key and i + 1 < args.size():
			return args[i + 1]
	return fallback
