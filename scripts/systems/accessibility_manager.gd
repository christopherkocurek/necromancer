extends Node
## Manages accessibility settings, persisted to user://settings.cfg.

# Settings
var screen_shake_enabled: bool = true
var animation_speed: float = 1.0
var font_scale: float = 1.0
var reduced_flash: bool = false
var reduced_motion: bool = false
var colorblind_mode: String = "none"  # "none", "protanopia", "deuteranopia", "tritanopia"
var high_contrast: bool = false
var assist_level: String = "full"  # "off", "basic", "full"
var build_dashboard_enabled: bool = false
var god_mode_enabled: bool = false
var god_mode_reduction: float = 0.20
var death_count: int = 0

var _config := ConfigFile.new()
const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var err: int = _config.load(SETTINGS_PATH)
	if err != OK:
		return
	screen_shake_enabled = _config.get_value("display", "screen_shake", true)
	animation_speed = _config.get_value("display", "animation_speed", 1.0)
	font_scale = _config.get_value("display", "font_scale", 1.0)
	reduced_flash = _config.get_value("display", "reduced_flash", false)
	reduced_motion = _config.get_value("display", "reduced_motion", false)
	colorblind_mode = _config.get_value("accessibility", "colorblind_mode", "none")
	high_contrast = _config.get_value("accessibility", "high_contrast", false)
	assist_level = _config.get_value("accessibility", "assist_level", "full")
	build_dashboard_enabled = _config.get_value("accessibility", "build_dashboard_enabled", false)
	god_mode_enabled = _config.get_value("accessibility", "god_mode", false)
	god_mode_reduction = _config.get_value("accessibility", "god_mode_reduction", 0.20)
	death_count = _config.get_value("accessibility", "death_count", 0)

func save_settings() -> void:
	_config.set_value("display", "screen_shake", screen_shake_enabled)
	_config.set_value("display", "animation_speed", animation_speed)
	_config.set_value("display", "font_scale", font_scale)
	_config.set_value("display", "reduced_flash", reduced_flash)
	_config.set_value("display", "reduced_motion", reduced_motion)
	_config.set_value("accessibility", "colorblind_mode", colorblind_mode)
	_config.set_value("accessibility", "high_contrast", high_contrast)
	_config.set_value("accessibility", "assist_level", assist_level)
	_config.set_value("accessibility", "build_dashboard_enabled", build_dashboard_enabled)
	_config.set_value("accessibility", "god_mode", god_mode_enabled)
	_config.set_value("accessibility", "god_mode_reduction", god_mode_reduction)
	_config.set_value("accessibility", "death_count", death_count)
	_config.save(SETTINGS_PATH)

func is_assist_enabled() -> bool:
	if GameManager and GameManager.has_method("is_hardcore_mode") and GameManager.is_hardcore_mode():
		return false
	return assist_level != "off"

func is_build_dashboard_enabled() -> bool:
	if GameManager and GameManager.has_method("is_hardcore_mode") and GameManager.is_hardcore_mode():
		return false
	return build_dashboard_enabled

func get_god_mode_reduction() -> float:
	if not god_mode_enabled:
		return 0.0
	return god_mode_reduction

func record_death() -> void:
	death_count += 1
	god_mode_reduction = minf(0.80, 0.20 + death_count * 0.02)
	save_settings()

func get_tween_duration(base: float) -> float:
	return base / maxf(animation_speed, 0.1)

func toggle_god_mode() -> void:
	god_mode_enabled = not god_mode_enabled
	save_settings()
