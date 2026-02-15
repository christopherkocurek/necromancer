extends RefCounted
class_name TestMode

var deterministic_enabled: bool = true
var seed_value: int = 1337
var fixed_delta: float = 0.0166667
var mode_name: String = "deterministic"

static func from_cmdline(default_deterministic: bool = true, default_seed: int = 1337):
	var mode = load("res://scripts/testing/test_mode.gd").new()
	mode.deterministic_enabled = default_deterministic
	mode.seed_value = default_seed
	mode.mode_name = "deterministic" if default_deterministic else "runtime"

	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--deterministic=off" or arg == "--test-mode=off":
			mode.deterministic_enabled = false
			mode.mode_name = "runtime"
		elif arg == "--deterministic=on" or arg == "--test-mode=on":
			mode.deterministic_enabled = true
			mode.mode_name = "deterministic"
		elif arg.begins_with("--seed="):
			mode.seed_value = arg.substr("--seed=".length()).to_int()
		elif arg.begins_with("--fixed-delta="):
			mode.fixed_delta = arg.substr("--fixed-delta=".length()).to_float()

	return mode

func apply_runtime() -> void:
	if deterministic_enabled:
		seed(seed_value)
		Engine.max_fps = 60
		Engine.physics_ticks_per_second = 60
	else:
		randomize()
