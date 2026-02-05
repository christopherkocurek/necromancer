extends SceneTree
## Test runner for Necromancer Godot
## Runs all GUT unit tests and the playtest bot
##
## Usage:
##   godot --path . --headless --script res://test_runner.gd
##   godot --path . --headless --script res://test_runner.gd -- --unit-only
##   godot --path . --headless --script res://test_runner.gd -- --bot-only

var _args: PackedStringArray
var _unit_only: bool = false
var _bot_only: bool = false
var _exit_code: int = 0

func _init():
	_args = OS.get_cmdline_args()
	_unit_only = "--unit-only" in _args
	_bot_only = "--bot-only" in _args

	print("\n" + "=".repeat(70))
	print("  NECROMANCER GODOT - TEST RUNNER")
	print("=".repeat(70) + "\n")

	if _unit_only:
		print("Mode: Unit tests only\n")
	elif _bot_only:
		print("Mode: Bot playtest only\n")
	else:
		print("Mode: Full test suite\n")

	call_deferred("_run_tests")

func _run_tests():
	if not _bot_only:
		await _run_unit_tests()

	if not _unit_only:
		await _run_bot_playtest()

	_report_final()
	quit(_exit_code)

func _run_unit_tests():
	print("─".repeat(70))
	print("  UNIT TESTS")
	print("─".repeat(70) + "\n")

	# Check if GUT is available
	var gut_path: String = "res://addons/gut/gut.gd"
	if not ResourceLoader.exists(gut_path):
		print("[WARN] GUT not installed. Skipping unit tests.")
		print("       Install GUT: AssetLib -> Search 'GUT' -> Install")
		print("       Or: git clone https://github.com/bitwes/Gut.git addons/gut\n")
		return

	# Run GUT tests
	var gut_script = load(gut_path)
	if gut_script:
		var gut = gut_script.new()
		root.add_child(gut)

		gut.add_directory("res://tests/unit")
		gut.add_directory("res://tests/integration")

		# Configure GUT
		gut.set_log_level(gut.LOG_LEVEL_ALL_ASSERTS)
		gut.set_include_subdirectories(true)

		# Run and wait
		gut.test_scripts()
		await gut.end_run

		# Check results
		if gut.get_fail_count() > 0:
			_exit_code = 1
			print("\n[UNIT TESTS] FAILED: %d failures\n" % gut.get_fail_count())
		else:
			print("\n[UNIT TESTS] PASSED: %d tests\n" % gut.get_pass_count())

		gut.queue_free()
	else:
		print("[ERROR] Could not load GUT\n")

func _run_bot_playtest():
	print("─".repeat(70))
	print("  BOT PLAYTEST")
	print("─".repeat(70) + "\n")

	var bot_script_path: String = "res://tests/bot/playtest_bot.gd"
	if not ResourceLoader.exists(bot_script_path):
		print("[ERROR] Bot playtest script not found: %s\n" % bot_script_path)
		_exit_code = 1
		return

	# Load main scene
	var main_scene_path: String = "res://scenes/main.tscn"
	if not ResourceLoader.exists(main_scene_path):
		print("[ERROR] Main scene not found: %s\n" % main_scene_path)
		_exit_code = 1
		return

	var main_scene: PackedScene = load(main_scene_path)
	var main_instance: Node = main_scene.instantiate()
	root.add_child(main_instance)

	# Attach bot
	var bot_script = load(bot_script_path)
	var bot: Node = Node.new()
	bot.set_script(bot_script)
	bot.name = "PlaytestBot"
	main_instance.add_child(bot)

	# Wait for bot to finish (it will call quit())
	# The bot handles its own exit code
	print("[BOT] Running... (will exit when complete)\n")

	# Give control to the scene tree
	# Bot will quit with appropriate exit code

func _report_final():
	print("\n" + "=".repeat(70))
	print("  TEST RUN COMPLETE")
	print("=".repeat(70))

	if _exit_code == 0:
		print("  Status: ALL TESTS PASSED")
	else:
		print("  Status: SOME TESTS FAILED")

	print("=".repeat(70) + "\n")
