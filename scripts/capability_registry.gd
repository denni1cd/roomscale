extends RefCounted
## Shared capability vocabulary for the innovation system.
##
## Capabilities describe what a civilization knows how to do, not how it learned
## it. Civilization-specific technologies grant capabilities while authored
## solutions require them. This keeps simulation logic independent of any one
## civilization's tech tree.

const Validation := preload("res://scripts/innovation_validation.gd")

const DEFAULT_PATH := "res://innovation/capabilities.json"

var definitions: Dictionary = {}
var load_errors: Array[String] = []


static func load_default() -> Dictionary:
	return load_path(DEFAULT_PATH)


static func load_path(path: String) -> Dictionary:
	var errors: Array[String] = []
	if not FileAccess.file_exists(path):
		errors.append("capability registry not found: %s" % path)
		return {"ok": false, "registry": null, "errors": errors}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("could not open capability registry: %s" % path)
		return {"ok": false, "registry": null, "errors": errors}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("capability registry is not a JSON object: %s" % path)
		return {"ok": false, "registry": null, "errors": errors}
	var registry := new()
	registry.load_errors = registry._load(parsed)
	return {"ok": registry.load_errors.is_empty(), "registry": registry if registry.load_errors.is_empty() else null, "errors": registry.load_errors}


func _load(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	Validation.schema(data.get("schema_version"), errors)
	var staged: Dictionary = {}
	var entries: Variant = data.get("capabilities")
	if not (entries is Array):
		errors.append("capabilities must be an array")
		return errors
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			errors.append("capability entry must be an object")
			continue
		var entry: Dictionary = raw_entry
		var capability_id := Validation.id(entry.get("id"), "capability id", errors)
		if capability_id.is_empty():
			errors.append("capability id must not be empty")
			continue
		if staged.has(capability_id):
			errors.append("duplicate capability id: %s" % capability_id)
			continue
		var implies: Variant = entry.get("implies", [])
		if not (implies is Array):
			errors.append("capability %s implies must be an array" % capability_id)
			continue
		var normalized := entry.duplicate(true)
		normalized["id"] = capability_id
		Validation.text_fields(entry, "capability %s" % capability_id, errors)
		normalized["implies"] = Validation.ids(implies, "capability %s implies" % capability_id, errors)
		staged[capability_id] = normalized
	for capability_id in staged:
		for implied in staged[capability_id].get("implies", []):
			if not staged.has(implied):
				errors.append("capability %s implies unknown capability %s" % [capability_id, implied])
	if errors.is_empty():
		definitions = staged
	return errors


func has_capability(capability_id: String) -> bool:
	return definitions.has(_normalize(capability_id))


func expand(capabilities: Array) -> Array[String]:
	var expanded: Dictionary = {}
	var pending: Array[String] = []
	for capability in capabilities:
		var normalized := _normalize(String(capability))
		if normalized.is_empty() or expanded.has(normalized):
			continue
		expanded[normalized] = true
		pending.append(normalized)
	while not pending.is_empty():
		var current: String = pending.pop_front()
		var definition: Dictionary = definitions.get(current, {})
		for implied in definition.get("implies", []):
			var implied_id := String(implied)
			if expanded.has(implied_id):
				continue
			expanded[implied_id] = true
			pending.append(implied_id)
	var result: Array[String] = []
	for capability_id in expanded:
		result.append(String(capability_id))
	result.sort()
	return result


func satisfies(known_capabilities: Array, required_capabilities: Array) -> bool:
	return missing(known_capabilities, required_capabilities).is_empty()


func missing(known_capabilities: Array, required_capabilities: Array) -> Array[String]:
	var expanded := expand(known_capabilities)
	var present: Dictionary = {}
	for capability in expanded:
		present[capability] = true
	var result: Array[String] = []
	for required in _normalize_list(required_capabilities):
		if not present.has(required):
			result.append(required)
	result.sort()
	return result


static func _normalize(value: String) -> String:
	return value.strip_edges().to_upper()


static func _normalize_list(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		var normalized := _normalize(String(value))
		if not normalized.is_empty() and not result.has(normalized):
			result.append(normalized)
	result.sort()
	return result
