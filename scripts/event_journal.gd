extends RefCounted
## Bounded authoritative facts. Presentation policy belongs in SpectatorEventCatalog.
const MAJOR := ["salvage_authorized", "traversal_complete", "structure_complete", "cohort_joined", "source_exhausted", "technology_complete", "solution_complete"]
const CONTEXT_FIELDS := ["society_id", "civilization_id", "subject_type", "subject_id", "project_id", "site_id", "conflict_id", "story_key", "severity", "state"]
var limit := 128
var events: Array[Dictionary] = []
var sequence := 0
var _states: Dictionary = {}
var defaults: Dictionary = {}

func configure_context(society_id: String, civilization_id: String) -> void:
	defaults = {"society_id":society_id, "civilization_id":civilization_id}

func record(seconds: float, kind: String, message: String, evidence: Dictionary = {}, focus: Variant = null, key: String = "", context: Dictionary = {}) -> bool:
	var suppression := kind if key.is_empty() else key
	if _states.get(suppression, "") == message: return false
	_states[suppression] = message
	sequence += 1
	var event := {"id":sequence, "seconds":seconds, "day":seconds / 600.0, "kind":kind, "message":message, "evidence":evidence.duplicate(true), "focus":focus if focus is Vector3 else Vector3.ZERO, "focus_valid":focus is Vector3 and focus.is_finite(), "major":kind in MAJOR}
	var normalized := defaults.duplicate(true)
	for field in CONTEXT_FIELDS:
		if evidence.has(field): normalized[field] = evidence[field]
	normalized.merge(context, true)
	if not normalized.has("society_id"): normalized["society_id"] = str(evidence.get("instance_id", ""))
	for field in CONTEXT_FIELDS: event[field] = str(normalized.get(field, ""))
	event["related_entities"] = normalized.get("related_entities", evidence.get("related_entities", [])).duplicate(true)
	event["participants"] = normalized.get("participants", evidence.get("participants", [])).duplicate(true)
	if event.story_key.is_empty(): event.story_key = event.society_id + ":" + suppression
	if context.has("focus_valid"): event.focus_valid = bool(context.focus_valid) and event.focus_valid
	events.append(event)
	while events.size() > limit: events.pop_front()
	while _states.size() > limit * 2: _states.erase(_states.keys()[0])
	return true

static func validate(event: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for field in ["id", "seconds", "day", "kind", "message", "evidence", "focus"]:
		if not event.has(field): errors.append("Missing " + field)
	if event.has("id") and (not event.id is int or int(event.id) < 1): errors.append("Invalid id")
	for field in ["seconds", "day"]:
		if event.has(field):
			if not event[field] is int and not event[field] is float: errors.append("Invalid " + field)
			elif not is_finite(float(event[field])) or float(event[field]) < 0: errors.append("Invalid " + field)
	for field in ["kind", "message"]:
		if event.has(field) and not event[field] is String: errors.append("Invalid " + field)
	if event.has("focus") and (not event.focus is Vector3 or not event.focus.is_finite()): errors.append("Invalid focus")
	if event.has("focus_valid") and not event.focus_valid is bool: errors.append("Invalid focus_valid")
	if event.has("evidence") and not event.evidence is Dictionary: errors.append("Invalid evidence")
	for field in CONTEXT_FIELDS:
		if event.has(field) and not event[field] is String: errors.append("Invalid " + field)
	for field in ["participants", "related_entities"]:
		if event.has(field) and not event[field] is Array: errors.append("Invalid " + field)
	for field in ["shot_distance", "camera_priority", "dwell", "ui_color", "camera_mode", "shot_yaw", "shot_tilt", "interrupt_policy"]:
		if event.has(field): errors.append("Presentation policy forbidden: " + field)
	return errors
