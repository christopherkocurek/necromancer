extends RefCounted
class_name CaptureService

func capture_checkpoint(base_output_dir: String, scenario_id: String, checkpoint_id: String, telemetry: Dictionary, frame_image: Image = null) -> Dictionary:
	var rel_dir := "%s/%s/%s" % [base_output_dir, scenario_id, checkpoint_id]
	var abs_dir := ProjectSettings.globalize_path("res://%s" % rel_dir)
	DirAccess.make_dir_recursive_absolute(abs_dir)

	var image := frame_image
	if image == null:
		image = _build_deterministic_image(telemetry)
	var full_rel := "%s/full.png" % rel_dir
	var full_abs := ProjectSettings.globalize_path("res://%s" % full_rel)
	image.save_png(full_abs)

	var telemetry_rel := "%s/telemetry.json" % rel_dir
	var telemetry_abs := ProjectSettings.globalize_path("res://%s" % telemetry_rel)
	_write_json_file(telemetry_abs, telemetry)

	return {
		"image": image,
		"checkpoint_dir_rel": rel_dir,
		"full_png_rel": full_rel,
		"telemetry_rel": telemetry_rel
	}

func save_diff_image(rel_path: String, image: Image) -> void:
	if image == null:
		return
	var abs_path := ProjectSettings.globalize_path("res://%s" % rel_path)
	var dir := abs_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	image.save_png(abs_path)

func _write_json_file(abs_path: String, payload: Dictionary) -> void:
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload, "\t"))

func _build_deterministic_image(telemetry: Dictionary) -> Image:
	var image := Image.create(256, 144, false, Image.FORMAT_RGBA8)
	var light_runtime := int(_resolve_path(telemetry, "light_state.runtime_radius", 0))
	var light_ui := int(_resolve_path(telemetry, "light_state.ui_radius", 0))
	var xp_final := int(_resolve_path(telemetry, "xp_state.final_amount", 0))
	var wake_count := int(_resolve_path(telemetry, "aggro_state.wake_count", 0))

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var r := float((x + light_runtime * 11) % 255) / 255.0
			var g := float((y + light_ui * 7) % 255) / 255.0
			var b := float((x + y + xp_final + wake_count * 13) % 255) / 255.0
			image.set_pixel(x, y, Color(r, g, b, 1.0))

	return image

func _resolve_path(root: Dictionary, path: String, fallback):
	var current = root
	for token in path.split("."):
		if typeof(current) != TYPE_DICTIONARY or not current.has(token):
			return fallback
		current = current[token]
	return current
