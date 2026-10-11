extends RefCounted
## Loads authored technologies and solutions for one civilization.
##
## Adding a civilization requires a new JSON catalog, not a new branch in this
## class. The catalog describes civilization-specific inventions using shared
## problem and capability ids.

const ROOT := "res://innovation/civilizations"

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
	return {"ok": catalog.load_errors.is_empty(), "catalog": catalog, "errors": catalog.load_errors}


func _load(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if int(data.get("schema_version", 0)) != 1:
		errors.append("unsupported innovation schema_version %s" % data.get("schema_version", 0))
	var file_civ := String(data.get("civilization_id", "")).strip_edges().to_lower()
	if file_civ != civilization_id:
		errors.append("innovation catalog civilization_id '%s' does not match requested id '%s'" % [file_civ, civilization_id])
	_load_entries(data.get("technologies", []), "technology", technologies, errors)
	_load_entries(data.get("solutions", []), "solution", solutions, errors)
	for technology_id in technologies:
		var technology: Dictionary = technologies[technology_id]
		if not (technology.get("grants", []) is Array):
			errors.append("technology %s grants must be an array" % technology_id)
		if not (technology.get("requires_capabilities", []) is Array):
			errors.append("technology %s requires_capabilities must be an array" % technology_id)
	for solution_id in solutions:
		var solution: Dictionary = solutions[solution_id]
		if not (solution.get("addresses", []) is Array) or solution.get("addresses", []).is_empty():
			errors.append("solution %s addresses must be a non-empty array" % solution_id)
		if not (solution.get("requires_capabilities", []) is Array):
			errors.append("solution %s requires_capabilities must be an array" % solution_id)
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
		var entry_id := String(entry.get("id", "")).strip_edges().to_lower()
		if entry_id.is_empty():
			errors.append("%s id must not be empty" % label)
			continue
		if target.has(entry_id):
			errors.append("duplicate %s id: %s" % [label, entry_id])
			continue
		var normalized := entry.duplicate(true)
		normalized["id"] = entry_id
		for field in ["grants", "requires_capabilities", "addresses"]:
			if normalized.get(field, []) is Array:
				var values: Array = normalized.get(field, [])
				var normalized_values: Array[String] = []
				for value in values:
					var item := String(value).strip_edges().to_upper()
					if not item.is_empty() and not normalized_values.has(item):
						normalized_values.append(item)
				normalized_values.sort()
				normalized[field] = normalized_values
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
