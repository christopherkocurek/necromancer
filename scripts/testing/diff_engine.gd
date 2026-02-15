extends RefCounted
class_name DiffEngine

func compare(current: Image, baseline: Image, threshold: float = 0.005) -> Dictionary:
	if baseline == null:
		var placeholder := current.duplicate()
		return {
			"passed": true,
			"ratio": 0.0,
			"changed_pixels": 0,
			"total_pixels": 0,
			"diff_image": placeholder,
			"reason": "no baseline"
		}

	var width := mini(current.get_width(), baseline.get_width())
	var height := mini(current.get_height(), baseline.get_height())
	var total := width * height
	var changed := 0
	var diff := Image.create(width, height, false, Image.FORMAT_RGBA8)

	for y in range(height):
		for x in range(width):
			var c := current.get_pixel(x, y)
			var b := baseline.get_pixel(x, y)
			var delta: float = abs(c.r - b.r) + abs(c.g - b.g) + abs(c.b - b.b)
			if delta > threshold:
				changed += 1
				diff.set_pixel(x, y, Color(1, 0, 0, 1))
			else:
				diff.set_pixel(x, y, Color(0, 0, 0, 0))

	var ratio := 0.0 if total == 0 else float(changed) / float(total)
	return {
		"passed": ratio <= threshold,
		"ratio": ratio,
		"changed_pixels": changed,
		"total_pixels": total,
		"diff_image": diff,
		"reason": "pixel compare"
	}
