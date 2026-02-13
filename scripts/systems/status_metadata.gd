class_name StatusMetadata
extends RefCounted
## Central status UI metadata registry used by HUD/panels/tooltips.

static func get_status_meta(status_name: String, duration: int) -> Dictionary:
	var key: String = status_name.to_lower()
	var meta: Dictionary = {
		"name": status_name.capitalize(),
		"source": "Unknown",
		"severity": "minor",
		"severity_rank": 1,
		"exact_effect": "",
		"counterplay": "",
	}
	match key:
		"poisoned":
			meta.exact_effect = "Takes poison damage each turn."
			meta.counterplay = "Use herbs/potions and avoid prolonged exposure."
		"burning":
			meta.exact_effect = "Takes fire damage each turn."
			meta.counterplay = "Break line and end exposure quickly."
		"stunned":
			meta.exact_effect = "Can lose actions and be impaired."
			meta.counterplay = "Retreat and stabilize before re-engaging."
		"confused":
			meta.exact_effect = "Actions can misfire or movement can drift."
			meta.counterplay = "Slow down and avoid risky commitments."
		"afraid":
			meta.exact_effect = "Forced defensive behavior and poor initiative."
			meta.counterplay = "Create distance and recover composure."
		"blind":
			meta.exact_effect = "Severely reduced battlefield information."
			meta.counterplay = "Hold position and avoid unknown tiles."
		"slow":
			meta.exact_effect = "Acts less frequently."
			meta.counterplay = "Avoid fights until the effect expires."
		"entranced":
			meta.exact_effect = "Can be unable to act effectively."
			meta.counterplay = "Seek immunity sources and avoid control casters."
		_:
			meta.exact_effect = "Temporary status effect."
			meta.counterplay = "Observe duration and react conservatively."

	if duration >= 10:
		meta.severity = "critical"
		meta.severity_rank = 3
	elif duration >= 5:
		meta.severity = "high"
		meta.severity_rank = 2

	if key in ["burning", "poisoned", "stunned", "entranced"]:
		meta.severity = "critical" if duration >= 4 else "high"
		meta.severity_rank = 3 if duration >= 4 else 2

	return meta
