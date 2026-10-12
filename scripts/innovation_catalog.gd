extends RefCounted
## Loads authored technologies and solutions for one civilization.
##
## Adding a civilization requires a new JSON catalog, not a new branch in this
## class. The catalog describes civilization-specific inventions using shared
## problem and capability ids.

const ROOT := "res://innovation/civilizations"
const Validation := preload("res://scripts/innovation_validation.gd")

var civilization_id: String = ""
var technologies: Dictionary = {}
var solutions: Dictionary = {}
var load_errors: Array[String] = []


static func load_id(civ_id: String) -> Dictionary:
	var normalized := civ_id.strip_edges().to_lower()
	var errors: Array[String] = []
	if normalized.is_empty():
		errors.append("innovation civilization id is empty")
		return {"ok": false, "catalog": null, "errors": errors}
	for forbidden in ["/", "\\", "..", ":"]:
		if normalized.contains(forbidden):
			errors.append("innovation civilization id contains invalid path characters: %s" % normalized)
			return {"ok": false, "catalog": null, "errors": errors}
	var path := "%s/%s.json" % [ROOT, normalized]
	return load_path(path, normalized)


static func load_path(path: String, civ_id: String) -> Dictionary:
	var normalized := civ_id.strip_edges().to_lower()
	var errors: Array[String] = []
	if not FileAccess.file_exists(path):
		errors.append("innovation catalog not found for civilization '%s' (expected %s)" % [normalized, path])
		return {"ok": false, "catalog": null, "errors": errors}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("could not open innovation catalog: %s" % path)
		return {"ok": false, "catalog": null, "errors": errors}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("innovation catalog is not a JSON object: %s" % path)
		return {"ok": false, "catalog": null, "errors": errors}
	var catalog := new()
	catalog.civilization_id = normalized
	catalog.load_errors = catalog._load(parsed)
	return {"ok": catalog.load_errors.is_empty(), "catalog": catalog if catalog.load_errors.is_empty() else null, "errors": catalog.load_errors}


func _load(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	Validation.schema(data.get("schema_version"), errors)
	var file_civ := Validation.id(data.get("civilization_id"), "civilization_id", errors, true)
	if file_civ != civilization_id:
		errors.append("innovation catalog civilization_id '%s' does not match requested id '%s'" % [file_civ, civilization_id])
	var staged_technologies: Dictionary = {}
	var staged_solutions: Dictionary = {}
	_load_entries(data.get("technologies"), "technology", staged_technologies, errors)
	_load_entries(data.get("solutions"), "solution", staged_solutions, errors)
	if errors.is_empty():
		technologies = staged_technologies
		solutions = staged_solutions
	return errors


func _load_entries(raw_entries: Variant, label: String, target: Dictionary, errors: Array[String]) -> void:
	if not (raw_entries is Array):
		errors.append("%ss must be an array" % label)
		return
	for raw_entry in raw_entries:
		if not (raw_entry is Dictionary):
			errors.append("%s entry must be an object" % label)
			continue
		var entry: Dictionary = raw_entry
		var entry_id := Validation.id(entry.get("id"), "%s id" % label, errors, true)
		if entry_id.is_empty():
			errors.append("%s id must not be empty" % label)
			continue
		if target.has(entry_id):
			errors.append("duplicate %s id: %s" % [label, entry_id])
			continue
		var normalized := entry.duplicate(true)
		normalized["id"] = entry_id
		Validation.text_fields(entry, "%s %s" % [label, entry_id], errors)
		for field in ["grants", "requires_capabilities", "addresses"]:
			normalized[field] = Validation.ids(entry.get(field, []), "%s %s %s" % [label, entry_id, field], errors)
		if label == "solution" and normalized.addresses.is_empty():
			errors.append("solution %s addresses must be a non-empty array" % entry_id)
		if label == "technology" and normalized.grants.is_empty():
			errors.append("technology %s grants must be a non-empty array" % entry_id)
		Validation.numeric_field(entry, "priority", "%s %s" % [label, entry_id], errors)
		Validation.numeric_field(entry, "research_work", "%s %s" % [label, entry_id], errors, true)
		if entry.has("construction"):
			if not (entry.construction is Dictionary):
				errors.append("%s %s construction must be an object" % [label, entry_id])
			else:
				for field in entry.construction:
					Validation.numeric_field(entry.construction, field, "%s %s construction" % [label, entry_id], errors)
		if entry.has("properties") and not (entry.properties is Dictionary):
			errors.append("%s %s properties must be an object" % [label, entry_id])
		if entry.has("deployment"):
			if label != "solution" or not (entry.deployment is Dictionary):
				errors.append("solution %s deployment must be an object" % entry_id)
			else:
				Validation.id(entry.deployment.get("adapter"), "solution %s deployment adapter" % entry_id, errors, true)
				if entry.deployment.has("style"): Validation.id(entry.deployment.style, "solution %s deployment style" % entry_id, errors, true)
				if not (entry.get("construction") is Dictionary) or not entry.construction.has("work"):
					errors.append("deployable solution %s requires construction work" % entry_id)
				else:
					Validation.numeric_field(entry.construction, "work", "solution %s construction" % entry_id, errors, true)
					for resource in entry.construction:
						if resource not in ["wood", "metal", "mechanical_parts", "work"]: errors.append("solution %s unsupported construction resource %s" % [entry_id, resource])
		target[entry_id] = normalized


func technology(technology_id: String) -> Dictionary:
	return technologies.get(technology_id.strip_edges().to_lower(), {}).duplicate(true)


func solution(solution_id: String) -> Dictionary:
	return solutions.get(solution_id.strip_edges().to_lower(), {}).duplicate(true)


func technology_list() -> Array[Dictionary]:
	return _sorted_entries(technologies)


func solution_list() -> Array[Dictionary]:
	return _sorted_entries(solutions)


func _sorted_entries(source: Dictionary) -> Array[Dictionary]:
	var ids := source.keys()
	ids.sort()
	var result: Array[Dictionary] = []
	for entry_id in ids:
		result.append(source[entry_id].duplicate(true))
	return result
