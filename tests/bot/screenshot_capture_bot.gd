extends Node
## Deterministic screenshot capture bot for visual regression baselines.
## Captures multiple UI/gameplay states and writes PNGs + manifest JSON.

var screenshots_dir: String = ""
var screenshot_label: String = "capture"
var screenshot_seed: int = -1

const MAX_SETUP_WAIT_FRAMES: int = 600
const MAX_CAPTURE_RETRIES: int = 8
const MIN_VALID_PNG_BYTES: int = 1024

var _main: Node = null
var _captured: Array[String] = []
var _failed: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	_main = get_parent()

	if DisplayServer.get_name() == "headless":
		_fail_and_quit("Display driver is headless; screenshot capture requires a rendered display backend.")
		return

	if not _ensure_output_dir():
		_fail_and_quit("Unable to create screenshot output dir: %s" % screenshots_dir)
		return

	if not await _bootstrap_run():
		_fail_and_quit("Unable to bootstrap game run for screenshot capture.")
		return

	await _capture_sequence()
	_write_manifest()

	if _captured.size() < 3:
		_fail_and_quit("Insufficient captures (%d). Expected at least 3." % _captured.size())
		return

	print("[SCREENSHOT BOT] Captured %d screenshots, %d failures." % [_captured.size(), _failed.size()])
	get_tree().quit(0)

func _ensure_output_dir() -> bool:
	if screenshots_dir.is_empty():
		screenshots_dir = "user://screenshots"
	var abs_dir: String = ProjectSettings.globalize_path(screenshots_dir)
	var err: Error = DirAccess.make_dir_recursive_absolute(abs_dir)
	if err != OK and not DirAccess.dir_exists_absolute(abs_dir):
		return false
	screenshots_dir = abs_dir
	return true

func _bootstrap_run() -> bool:
	if _main == null:
		return false
	if not _main.has_method("_on_character_created"):
		return false

	var character_data: Dictionary = {
		"name": "ScreenshotBot",
		"race": "Man",
		"house": "House of Beor",
		"trait": "Resilient",
		"gender": "male",
		"base_stats": {"str": 4, "dex": 3, "con": 4, "gra": 2},
	}
	if screenshot_seed >= 0:
		seed(screenshot_seed)
	_main._on_character_created(character_data)

	var frame_waited: int = 0
	while frame_waited < MAX_SETUP_WAIT_FRAMES:
		await get_tree().process_frame
		if _main.get("player") != null and _main.get("current_level") != null:
			return true
		frame_waited += 1

	return false

func _capture_sequence() -> void:
	await _capture_named("gameplay")
	if _main.get("hud") and _main.hud.get("minimap"):
		_main.hud._on_minimap_clicked()
		await _capture_named("gameplay_minimap_expanded")
		_main.hud._on_minimap_clicked()

	if _main.has_method("_toggle_inventory"):
		_main._toggle_inventory()
		await _capture_named("inventory")
		if _main.get("inventory_panel") and _main.inventory_panel.visible:
			_main.inventory_panel.close()

	if _main.has_method("_toggle_tome"):
		_main._toggle_tome()
		await _capture_named("tome")
		if _main.get("tome_panel") and _main.tome_panel.visible:
			_main.tome_panel.close()

	if _main.has_method("_toggle_look"):
		_main._toggle_look()
		await _capture_named("look")
		if _main.get("look_panel") and _main.look_panel.visible:
			_main.look_panel.close()

	if _main.get("target_panel") and _main.get("player") and _main.get("current_level"):
		_main.target_panel.open(_main.player, _main.current_level)
		await _capture_named("target")
		if _main.target_panel.visible:
			_main.target_panel.close()

func _capture_named(name: String) -> void:
	var seed_tag: String = "s%s" % str(screenshot_seed) if screenshot_seed >= 0 else "sna"
	var file_name: String = "%s_%s_%s.png" % [screenshot_label, seed_tag, name]
	var path: String = screenshots_dir.path_join(file_name)
	var ok: bool = await _capture_viewport_png(path)
	if ok:
		_captured.append(file_name)
		print("[SCREENSHOT BOT] Saved %s" % path)
	else:
		_failed.append(file_name)
		push_warning("[SCREENSHOT BOT] Failed to capture %s" % path)

func _capture_viewport_png(path: String) -> bool:
	for _i in range(MAX_CAPTURE_RETRIES):
		await get_tree().process_frame
		await get_tree().create_timer(0.03).timeout

		var vp: Viewport = get_viewport()
		if vp == null:
			continue
		var tex: ViewportTexture = vp.get_texture()
		if tex == null:
			continue
		var img: Image = tex.get_image()
		if img == null or img.get_width() <= 1 or img.get_height() <= 1:
			continue
		if img.save_png(path) != OK:
			continue
		if not FileAccess.file_exists(path):
			continue
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		if bytes.size() < MIN_VALID_PNG_BYTES:
			continue
		return true
	return false

func _write_manifest() -> void:
	var manifest: Dictionary = {
		"label": screenshot_label,
		"seed": screenshot_seed,
		"output_dir": screenshots_dir,
		"captured": _captured,
		"failed": _failed,
		"captured_count": _captured.size(),
		"failed_count": _failed.size(),
	}
	var path: String = screenshots_dir.path_join("%s_manifest.json" % screenshot_label)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(manifest, "\t"))

func _fail_and_quit(msg: String) -> void:
	push_error("[SCREENSHOT BOT] %s" % msg)
	get_tree().quit(1)
