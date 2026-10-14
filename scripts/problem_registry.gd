extends RefCounted
## Civilization-agnostic problem vocabulary and active problem state.
##
## World systems report problems here using shared problem ids. They never need
## to know which civilization is observing the problem or what solution that
## civilization may eventually invent.

const Validation := preload("res://scripts/innovation_validation.gd")

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
	return {"ok": registry.load_errors.is_empty(), "registry": registry if registry.load_errors.is_empty() else null, "errors": registry.load_errors}


func _load(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	Validation.schema(data.get("schema_version"), errors)
	var staged: Dictionary = {}
	var entries: Variant = data.get("problems")
	if not (entries is Array):
		errors.append("problems must be an array")
		return errors
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			errors.append("problem entry must be an object")
			continue
		var entry: Dictionary = raw_entry
		var problem_id := Validation.id(entry.get("id"), "problem id", errors)
		if problem_id.is_empty():
			errors.append("problem id must not be empty")
			continue
		if staged.has(problem_id):
			errors.append("duplicate problem id: %s" % problem_id)
			continue
		var normalized := entry.duplicate(true)
		normalized["id"] = problem_id
		Validation.text_fields(entry, "problem %s" % problem_id, errors)
		staged[problem_id] = normalized
	if errors.is_empty():
		definitions = staged
	return errors


func has_problem(problem_id: String) -> bool:
	return definitions.has(normalize_id(problem_id))


func set_problem(problem_id: String, source_id: String, severity: float, context: Dictionary = {}) -> Dictionary:
	var normalized := normalize_id(problem_id)
	if not definitions.has(normalized):
		return {"ok": false, "error": "unknown problem id: %s" % normalized}
	var source := source_id.strip_edges()
	if not is_finite(severity): return {"ok":false,"error":"problem severity must be finite"}
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
		"awareness": 1.0,
		"recognition_state": "RECOGNIZED",
		"context": context.duplicate(true),
	}
	active[key] = instance
	return {"ok": true, "problem": instance.duplicate(true)}


func clear_problem(problem_id: String, source_id: String) -> void:
	active.erase("%s::%s" % [normalize_id(problem_id), source_id.strip_edges()])


func observe_batch(observations: Array, seconds: float) -> void:
	# Called once per fixed detector interval. Sorted strengths make contributions
	# from several detectors order-independent; repeated calls at one time are inert.
	if not is_finite(seconds) or seconds < 0: return
	var grouped := {}
	for raw in observations:
		if not raw is Dictionary or not raw.get("type") is String or not Validation.nonempty_string(raw.get("source_id")): continue
		if not Validation.number(raw.get("severity")) or not Validation.number(raw.get("strength",0.35)): continue
		if float(raw.get("strength",0.35)) <= 0 or float(raw.severity) <= 0 or not raw.get("context",{}) is Dictionary: continue
		var type := normalize_id(raw.type)
		if not has_problem(type): continue
		var key := type + "::" + String(raw.source_id).strip_edges()
		if not grouped.has(key): grouped[key] = []
		var observation: Dictionary = raw.duplicate(true)
		observation.type = type
		grouped[key].append(observation)
	var keys: Array = grouped.keys(); keys.sort()
	for key in keys:
		var batch: Array = grouped[key]
		batch.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return JSON.stringify(a, "", true) < JSON.stringify(b, "", true))
		var prior: Dictionary = active.get(key,{})
		if not prior.is_empty() and seconds <= float(prior.get("last_observed",-1)): continue
		var strengths: Array[float] = []
		var severity := 0.0
		var context := {}
		for observation in batch:
			strengths.append(clampf(float(observation.get("strength",0.35)),0,1))
			severity = maxf(severity,clampf(float(observation.severity),0,1))
			context.merge(observation.get("context",{}),true)
		strengths.sort()
		var awareness := float(prior.get("awareness",0))
		for strength in strengths: awareness = minf(1, awareness+strength)
		var recognized := awareness >= 1.0 - 0.000001
		active[key] = {"key":key,"type":batch[0].type,"source_id":String(batch[0].source_id).strip_edges(),"severity":severity,"observation_count":int(prior.get("observation_count",0))+batch.size(),"awareness":awareness,"first_observed":prior.get("first_observed",seconds),"last_observed":seconds,"recognized_at":prior.get("recognized_at",seconds) if recognized and prior.get("recognition_state","") == "RECOGNIZED" else (seconds if recognized else -1.0),"recognition_state":"RECOGNIZED" if recognized else "EMERGING","context":context}
	# Missing/solved opportunities disappear, including their evidence. A later
	# reappearance is a new recognition episode, never stale perfect knowledge.
	for key in active.keys():
		if not grouped.has(key): active.erase(key)

func active_problems(recognized_only: bool = true) -> Array[Dictionary]:
	var keys := active.keys()
	keys.sort()
	var result: Array[Dictionary] = []
	for key in keys:
		var instance: Dictionary = active[key]
		if recognized_only and instance.get("recognition_state","RECOGNIZED") != "RECOGNIZED": continue
		if float(instance.get("severity", 0.0)) > 0.0:
			result.append(instance.duplicate(true))
	return result


static func normalize_id(value: String) -> String:
	return value.strip_edges().to_upper()
