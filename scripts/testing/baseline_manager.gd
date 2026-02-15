extends RefCounted
class_name BaselineManager

var baseline_root: String = "tests/baselines/v1"
var update_baseline: bool = false

func _init(root: String = "tests/baselines/v1", update: bool = false) -> void:
	baseline_root = root
	update_baseline = update

func baseline_image_path(scenario_id: String, checkpoint_id: String) -> String:
	return "%s/%s/%s/full.png" % [baseline_root, scenario_id, checkpoint_id]

func baseline_telemetry_path(scenario_id: String, checkpoint_id: String) -> String:
	return "%s/%s/%s/telemetry.json" % [baseline_root, scenario_id, checkpoint_id]

func load_baseline_image(scenario_id: String, checkpoint_id: String) -> Image:
	var rel := baseline_image_path(scenario_id, checkpoint_id)
	var abs := ProjectSettings.globalize_path("res://%s" % rel)
	if not FileAccess.file_exists(abs):
		return null
	var img := Image.new()
	if img.load(abs) != OK:
		return null
	return img

func upsert_baseline(scenario_id: String, checkpoint_id: String, image: Image, telemetry: Dictionary) -> void:
	if not update_baseline:
		return
	var img_rel := baseline_image_path(scenario_id, checkpoint_id)
	var img_abs := ProjectSettings.globalize_path("res://%s" % img_rel)
	DirAccess.make_dir_recursive_absolute(img_abs.get_base_dir())
	image.save_png(img_abs)

	var telemetry_rel := baseline_telemetry_path(scenario_id, checkpoint_id)
	var telemetry_abs := ProjectSettings.globalize_path("res://%s" % telemetry_rel)
	var f := FileAccess.open(telemetry_abs, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(telemetry, "\t"))
