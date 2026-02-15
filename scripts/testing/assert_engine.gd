extends RefCounted
class_name AssertEngine

func evaluate_assertions(assertions: Array, telemetry: Dictionary) -> Array:
	var results: Array = []
	for assertion in assertions:
		results.append(evaluate_assertion(assertion, telemetry))
	return results

func evaluate_assertion(assertion: Dictionary, telemetry: Dictionary) -> Dictionary:
	var a_type := str(assertion.get("type", ""))
	var path := str(assertion.get("path", ""))
	var actual = _resolve_path(telemetry, path)
	var expected = assertion.get("value")
	var severity := str(assertion.get("severity", "major"))
	var ok := false
	var detail := ""

	match a_type:
		"eq":
			ok = actual == expected
			detail = "expected=%s actual=%s" % [str(expected), str(actual)]
		"range":
			var min_v = assertion.get("min")
			var max_v = assertion.get("max")
			ok = typeof(actual) in [TYPE_INT, TYPE_FLOAT] and actual >= min_v and actual <= max_v
			detail = "expected=[%s,%s] actual=%s" % [str(min_v), str(max_v), str(actual)]
		"contains":
			if typeof(actual) == TYPE_STRING:
				ok = str(actual).find(str(expected)) >= 0
			elif typeof(actual) == TYPE_ARRAY:
				ok = actual.has(expected)
			detail = "expected contains %s actual=%s" % [str(expected), str(actual)]
		"regex":
			var re := RegEx.new()
			if re.compile(str(expected)) == OK and typeof(actual) == TYPE_STRING:
				ok = re.search(str(actual)) != null
			detail = "expected regex=%s actual=%s" % [str(expected), str(actual)]
		"exists":
			ok = actual != null
			detail = "exists actual=%s" % str(actual)
		_:
			ok = false
			detail = "unsupported assertion type %s" % a_type

	return {
		"type": a_type,
		"path": path,
		"severity": severity,
		"passed": ok,
		"detail": detail,
		"message": str(assertion.get("message", ""))
	}

func _resolve_path(root: Dictionary, path: String):
	if path == "":
		return null
	var current = root
	for token in path.split("."):
		if typeof(current) != TYPE_DICTIONARY or not current.has(token):
			return null
		current = current[token]
	return current
