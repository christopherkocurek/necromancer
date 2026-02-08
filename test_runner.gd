extends SceneTree
## Test runner for Necromancer Godot
## Runs all GUT unit tests, gameplay tests, and bots
##
## Usage:
##   godot --path . --headless --script res://test_runner.gd
##   godot --path . --headless --script res://test_runner.gd -- --unit-only
##   godot --path . --headless --script res://test_runner.gd -- --gameplay-only
##   godot --path . --headless --script res://test_runner.gd -- --bot-only
##   godot --path . --headless --script res://test_runner.gd -- --fuzz
##   godot --path . --headless --script res://test_runner.gd -- --survival

var _args: PackedStringArray
var _unit_only: bool = false
var _gameplay_only: bool = false
var _bot_only: bool = false
var _fuzz: bool = false
var _survival: bool = false
var _exit_code: int = 0

# Archetype bot args
var _archetype_name: String = ""
var _run_index_val: int = -1
var _seed_val: int = -1

func _init():
	# User args come after "--" separator in Godot 4.x
	_args = OS.get_cmdline_user_args()
	# Fallback: also check full args in case invoked without "--" separator
	var _all_args: PackedStringArray = OS.get_cmdline_args()
	_unit_only = "--unit-only" in _args or "--unit-only" in _all_args
	_gameplay_only = "--gameplay-only" in _args or "--gameplay-only" in _all_args
	_bot_only = "--bot-only" in _args or "--bot-only" in _all_args
	_fuzz = "--fuzz" in _args or "--fuzz" in _all_args
	_survival = "--survival" in _args or "--survival" in _all_args

	# Parse archetype bot arguments from both arg sources
	for arg in _args:
		if arg.begins_with("--archetype="):
			_archetype_name = arg.substr("--archetype=".length())
		elif arg.begins_with("--run-index="):
			_run_index_val = arg.substr("--run-index=".length()).to_int()
		elif arg.begins_with("--seed="):
			_seed_val = arg.substr("--seed=".length()).to_int()
	for arg in _all_args:
		if arg.begins_with("--archetype="):
			_archetype_name = arg.substr("--archetype=".length())
		elif arg.begins_with("--run-index="):
			_run_index_val = arg.substr("--run-index=".length()).to_int()
		elif arg.begins_with("--seed="):
			_seed_val = arg.substr("--seed=".length()).to_int()

	# If archetype specified, force survival mode
	if _archetype_name != "":
		_survival = true

	print("\n" + "=".repeat(70))
	print("  NECROMANCER GODOT - TEST RUNNER")
	print("=".repeat(70) + "\n")

	if _unit_only:
		print("Mode: Unit tests only\n")
	elif _gameplay_only:
		print("Mode: Gameplay tests only\n")
	elif _bot_only:
		print("Mode: Bot playtest only\n")
	elif _fuzz:
		print("Mode: Fuzz bot only\n")
	elif _survival:
		print("Mode: Survival bot only\n")
	else:
		print("Mode: Full test suite (unit + gameplay + bot)\n")

	call_deferred("_run_tests")

func _run_tests():
	var _run_gut: bool = not _bot_only and not _fuzz and not _survival
	var _run_bot: bool = not _unit_only and not _gameplay_only and not _fuzz and not _survival

	if _run_gut:
		await _run_unit_tests()

	if _fuzz:
		await _run_fuzz_bot()
		return  # Bot calls get_tree().quit() when done
	elif _survival:
		await _run_survival_bot()
		return  # Bot calls get_tree().quit() when done
	elif _run_bot:
		await _run_bot_playtest()
		return  # Bot calls get_tree().quit() when done

	_report_final()
	quit(_exit_code)

func _run_unit_tests():
	var _label: String = "UNIT TESTS" if _unit_only else "UNIT + GAMEPLAY TESTS"
	if _gameplay_only:
		_label = "GAMEPLAY TESTS"
	print("─".repeat(70))
	print("  %s" % _label)
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

		# Disable subdirectory auto-discovery so only explicitly added dirs run
		gut.include_subdirectories = false

		if not _gameplay_only:
			gut.add_directory("res://tests/unit")
			gut.add_directory("res://tests/integration")
		if not _unit_only:
			gut.add_directory("res://tests/gameplay")

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

func _run_fuzz_bot():
	print("─".repeat(70))
	print("  FUZZ BOT")
	print("─".repeat(70) + "\n")

	var bot_script_path: String = "res://tests/bot/fuzz_bot.gd"
	if not ResourceLoader.exists(bot_script_path):
		print("[ERROR] Fuzz bot script not found: %s\n" % bot_script_path)
		_exit_code = 1
		return

	var main_scene_path: String = "res://scenes/main.tscn"
	if not ResourceLoader.exists(main_scene_path):
		print("[ERROR] Main scene not found: %s\n" % main_scene_path)
		_exit_code = 1
		return

	var main_scene: PackedScene = load(main_scene_path)
	var main_instance: Node = main_scene.instantiate()
	root.add_child(main_instance)

	var bot_script = load(bot_script_path)
	var bot: Node = Node.new()
	bot.set_script(bot_script)
	bot.name = "FuzzBot"
	main_instance.add_child(bot)

	print("[FUZZ BOT] Running 500+ random actions... (will exit when complete)\n")

func _run_survival_bot():
	print("─".repeat(70))
	print("  SURVIVAL BOT")
	print("─".repeat(70) + "\n")

	var bot_script_path: String = "res://tests/bot/survival_bot.gd"
	if not ResourceLoader.exists(bot_script_path):
		print("[ERROR] Survival bot script not found: %s\n" % bot_script_path)
		_exit_code = 1
		return

	var main_scene_path: String = "res://scenes/main.tscn"
	if not ResourceLoader.exists(main_scene_path):
		print("[ERROR] Main scene not found: %s\n" % main_scene_path)
		_exit_code = 1
		return

	var main_scene: PackedScene = load(main_scene_path)
	var main_instance: Node = main_scene.instantiate()
	root.add_child(main_instance)

	var bot_script = load(bot_script_path)
	var bot: Node = Node.new()
	bot.set_script(bot_script)
	bot.name = "SurvivalBot"

	# Inject archetype config if specified
	if _archetype_name != "":
		var configs_script = load("res://tests/bot/archetype_configs.gd")
		var config: Dictionary = configs_script.get_archetype(_archetype_name)
		if config.is_empty():
			print("[ERROR] Unknown archetype: %s" % _archetype_name)
			print("[INFO] Available: %s" % str(configs_script.get_all_archetype_names()))
			_exit_code = 1
			return
		bot.archetype_config = config
		bot.run_index = _run_index_val
		bot.run_seed = _seed_val
		print("[SURVIVAL BOT] Archetype: %s | Run: %d | Seed: %d" % [_archetype_name, _run_index_val, _seed_val])

	main_instance.add_child(bot)

	print("[SURVIVAL BOT] Running full 20-floor playthrough... (will exit when complete)\n")

func _report_final():
	print("\n" + "=".repeat(70))
	print("  TEST RUN COMPLETE")
	print("=".repeat(70))

	if _exit_code == 0:
		print("  Status: ALL TESTS PASSED")
	else:
		print("  Status: SOME TESTS FAILED")

	print("=".repeat(70) + "\n")
