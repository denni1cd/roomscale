extends RefCounted
## Data-driven civilization identity and presentation vocabulary.
##
## RoomDefinition describes physical reality. CivilizationDefinition describes
## how one society presents the shared simulation. The two contracts are kept
## deliberately separate so reconstructed rooms never need civilization hacks.

const DEFAULT_ID := "clockwork"
const ROOT := "res://civilizations"
const REQUIRED_RESOURCE_KEYS := ["wood", "metal", "mechanical_parts"]
const REQUIRED_STAGE_KEYS := ["base", "winch", "launcher"]


static func requested_id() -> String:
	var requested := OS.get_environment("ROOMSCALE_CIVILIZATION").strip_edges().to_lower()
	return DEFAULT_ID if requested.is_empty() else requested


static func load_requested() -> Dictionary:
	return load_id(requested_id())


static func load_id(civilization_id: String) -> Dictionary:
	var normalized := civilization_id.strip_edges().to_lower()
	var errors: Array[String] = []
	if normalized.is_empty():
		errors.append("civilization id is empty")
		return {"ok": false, "definition": {}, "errors": errors}
	for forbidden in ["/", "\\", "..", ":"]:
		if normalized.contains(forbidden):
			errors.append("civilization id contains invalid path characters: %s" % normalized)
			return {"ok": false, "definition": {}, "errors": errors}
	var path := "%s/%s.json" % [ROOT, normalized]
	if not FileAccess.file_exists(path):
		errors.append("unknown civilization '%s' (expected %s)" % [normalized, path])
		return {"ok": false, "definition": {}, "errors": errors}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("could not open civilization definition: %s" % path)
		return {"ok": false, "definition": {}, "errors": errors}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("civilization definition is not a JSON object: %s" % path)
		return {"ok": false, "definition": {}, "errors": errors}
	var definition: Dictionary = parsed
	errors.append_array(validate(definition, normalized))
	return {"ok": errors.is_empty(), "definition": definition, "errors": errors}


static func validate(definition: Dictionary, expected_id: String = "") -> Array[String]:
	var errors: Array[String] = []
	for key in ["schema_version", "id", "display_name", "citizen_style", "settlement_style", "traversal_style", "palette", "resource_vocabulary", "construction", "world_influence"]:
		if not definition.has(key):
			errors.append("missing required civilization field: %s" % key)
	if not errors.is_empty():
		return errors
	var civilization_id := String(definition.id).strip_edges().to_lower()
	if civilization_id.is_empty():
		errors.append("civilization id must not be empty")
	if not expected_id.is_empty() and civilization_id != expected_id:
		errors.append("civilization file id '%s' does not match requested id '%s'" % [civilization_id, expected_id])
	if int(definition.schema_version) != 1:
		errors.append("unsupported civilization schema_version %s" % definition.schema_version)
	if not (definition.palette is Dictionary):
		errors.append("palette must be an object")
	if not (definition.resource_vocabulary is Dictionary):
		errors.append("resource_vocabulary must be an object")
	else:
		for resource in REQUIRED_RESOURCE_KEYS:
			if not definition.resource_vocabulary.has(resource):
				errors.append("resource_vocabulary missing shared resource key: %s" % resource)
				continue
			var entry: Variant = definition.resource_vocabulary[resource]
			if not (entry is Dictionary) or String(entry.get("display_name", "")).strip_edges().is_empty():
				errors.append("resource_vocabulary.%s requires display_name" % resource)
	if not (definition.construction is Dictionary):
		errors.append("construction must be an object")
	else:
		var construction: Dictionary = definition.construction
		if String(construction.get("project_name", "")).strip_edges().is_empty():
			errors.append("construction.project_name is required")
		var stage_names: Variant = construction.get("stage_names", {})
		if not (stage_names is Dictionary):
			errors.append("construction.stage_names must be an object")
		else:
			for stage in REQUIRED_STAGE_KEYS:
				if String(stage_names.get(stage, "")).strip_edges().is_empty():
					errors.append("construction.stage_names missing: %s" % stage)
		if String(construction.get("traversal_name", "")).strip_edges().is_empty():
			errors.append("construction.traversal_name is required")
	if not (definition.world_influence is Dictionary):
		errors.append("world_influence must be an object")
	return errors


static func resource_name(definition: Dictionary, resource: String) -> String:
	var vocabulary: Dictionary = definition.get("resource_vocabulary", {})
	var entry: Variant = vocabulary.get(resource, {})
	return String(entry.get("display_name", resource.capitalize())) if entry is Dictionary else resource.capitalize()


static func resource_style(definition: Dictionary, resource: String) -> String:
	var vocabulary: Dictionary = definition.get("resource_vocabulary", {})
	var entry: Variant = vocabulary.get(resource, {})
	return String(entry.get("visual_style", resource)) if entry is Dictionary else resource


static func stage_name(definition: Dictionary, stage_id: String) -> String:
	var construction: Dictionary = definition.get("construction", {})
	var stage_names: Variant = construction.get("stage_names", {})
	return String(stage_names.get(stage_id, stage_id.capitalize())) if stage_names is Dictionary else stage_id.capitalize()


static func project_name(definition: Dictionary) -> String:
	return String(definition.get("construction", {}).get("project_name", "Traversal Project"))


static func traversal_name(definition: Dictionary) -> String:
	return String(definition.get("construction", {}).get("traversal_name", "Traversal Route"))


static func color(definition: Dictionary, key: String, fallback: Color) -> Color:
	var palette: Dictionary = definition.get("palette", {})
	var encoded := String(palette.get(key, ""))
	return Color(encoded) if not encoded.is_empty() else fallback
