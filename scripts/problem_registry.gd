extends RefCounted
## Civilization-agnostic problem vocabulary and active problem state.
##
## World systems report problems here using shared problem ids. They never need
## to know which civilization is observing the problem or what solution that
## civilization may eventually invent.

const DEFAULT_PATH := "res://innovation/problems.json"

var definitions: Dictionary = {}
var active: Dictionary = {}
var load_errors: Array[String] = []


static func load_default() -> Dictionary:
	return load_path(DEFAULT_PATH)


static func load_path(path: String) -> Dictionary:
	var errors: Array[String] = []
	if not FileAccess.file_exists(path):
		errors.append("problem registry not found: %s" % path)
		return {"ok": false, "registry": null, "errors": errors}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("could not open problem registry: %s" % path)
		return {"ok": false, "registry": null, "errors": errors}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("problem registry is not a JSON object: %s" % path)
		return {"ok": false, "registry": null, "errors": errors}
	var registry := new()
	registry.load_errors = registry._load(parsed)
	return {"ok": registry.load_errors.is_empty(), "registry": registry, "errors": registry.load_errors}


func _load(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if int(data.get("schema_version", 0)) != 1:
		errors.append("unsupported problem schema_version %s" % data.get("schema_version", 0))
	var entries: Variant = data.get("problems", [])
	if not (entries is Array):
		errors.append("problems must be an array")
		return errors
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			errors.append("problem entry must be an object")
			continue
		var entry: Dictionary = raw_entry
		var problem_id := normalize_id(String(entry.get("id", "")))
		if problem_id.is_empty():
			errors.append("problem id must not be empty")
			continue
		if definitions.has(problem_id):
			errors.append("duplicate problem id: %s" % problem_id)
			continue
		var normalized := entry.duplicate(true)
		normalized["id"] = problem_id
		definitions[problem_id] = normalized
	return errors


func has_problem(problem_id: String) -> bool:
	return definitions.has(normalize_id(problem_id))


func set_problem(problem_id: String, source_id: String, severity: float, context: Dictionary = {}) -> Dictionary:
	var normalized := normalize_id(problem_id)
	if not definitions.has(normalized):
		return {"ok": false, "error": "unknown problem id: %s" % normalized}
	var source := source_id.strip_edges()
	if source.is_empty():
		return {"ok": false, "error": "problem source id must not be empty"}
	var key := "%s::%s" % [normalized, source]
	var previous: Dictionary = active.get(key, {})
	var observations := int(previous.get("observation_count", 0)) + 1
	var instance := {
		"key": key,
		"type": normalized,
		"source_id": source,
		"severity": clampf(severity, 0.0, 1.0),
		"observation_count": observations,
		"context": context.duplicate(true),
	}
	active[key] = instance
	return {"ok": true, "problem": instance.duplicate(true)}


func clear_problem(problem_id: String, source_id: String) -> void:
	active.erase("%s::%s" % [normalize_id(problem_id), source_id.strip_edges()])


func active_problems() -> Array[Dictionary]:
	var keys := active.keys()
	keys.sort()
	var result: Array[Dictionary] = []
	for key in keys:
		var instance: Dictionary = active[key]
		if float(instance.get("severity", 0.0)) > 0.0:
			result.append(instance.duplicate(true))
	return result


static func normalize_id(value: String) -> String:
	return value.strip_edges().to_upper()
