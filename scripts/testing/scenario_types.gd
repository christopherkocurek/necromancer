extends RefCounted
class_name ScenarioTypes

const REQUIRED_TOP_LEVEL := [
	"schema_version", "id", "name", "mode", "seed", "severity", "tags",
	"setup", "actions", "settle_ticks", "checkpoints", "teardown"
]

const VALID_MODES := {"deterministic": true, "exploratory": true}
const VALID_SEVERITIES := {"blocker": true, "major": true, "minor": true, "info": true}
const VALID_ASSERT_TYPES := {"eq": true, "range": true, "contains": true, "regex": true, "exists": true}

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"_error": "scenario file missing: %s" % path}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"_error": "cannot read scenario file: %s" % path}
	var text := f.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"_error": "scenario must be a JSON object: %s" % path}
	return parsed

static func validate_scenario(s: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key in REQUIRED_TOP_LEVEL:
		if not s.has(key):
			errors.append("missing key: %s" % key)

	if errors.size() > 0:
		return errors

	if s.get("schema_version", "") != "v1":
		errors.append("schema_version must be v1")
	if not VALID_MODES.has(s.get("mode", "")):
		errors.append("mode must be deterministic|exploratory")
	if not VALID_SEVERITIES.has(s.get("severity", "")):
		errors.append("severity must be blocker|major|minor|info")

	if typeof(s.get("checkpoints", [])) != TYPE_ARRAY or s["checkpoints"].is_empty():
		errors.append("checkpoints must be a non-empty array")
	else:
		var seen: Dictionary = {}
		for checkpoint in s["checkpoints"]:
			if typeof(checkpoint) != TYPE_DICTIONARY:
				errors.append("checkpoint must be object")
				continue
			var cid := str(checkpoint.get("id", ""))
			if cid == "":
				errors.append("checkpoint id required")
			elif seen.has(cid):
				errors.append("duplicate checkpoint id: %s" % cid)
			seen[cid] = true
			for assertion in checkpoint.get("assertions", []):
				if typeof(assertion) != TYPE_DICTIONARY:
					errors.append("assertion must be object in checkpoint %s" % cid)
					continue
				var a_type := str(assertion.get("type", ""))
				if not VALID_ASSERT_TYPES.has(a_type):
					errors.append("invalid assertion type %s in %s" % [a_type, cid])
				if str(assertion.get("path", "")) == "":
					errors.append("assertion path required in %s" % cid)
				if assertion.has("severity") and not VALID_SEVERITIES.has(assertion.get("severity")):
					errors.append("invalid assertion severity in %s" % cid)

	return errors

static func load_and_validate(path: String) -> Dictionary:
	var payload := load_json(path)
	if payload.has("_error"):
		return payload
	var validation := validate_scenario(payload)
	if validation.size() > 0:
		return {"_error": "validation failed", "errors": validation}
	return payload
