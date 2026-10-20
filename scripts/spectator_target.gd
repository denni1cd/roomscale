extends RefCounted
## Stable descriptors shared by event navigation, explicit Follow and shot selection.
## Resolve against current authoritative state on every use; do not retain nodes.
const CITIZEN := "citizen"
const PROJECT := "project"
const SITE := "site"
const CONFLICT := "conflict"

static func make(type: String, id: Variant, society_id: String = "", framing: String = "SITE_MEDIUM", display_name: String = "") -> Dictionary:
	return {"type":type, "id":str(id), "society_id":society_id, "framing":framing, "display_name":display_name}

static func from_event(event: Dictionary) -> Dictionary:
	var society := String(event.get("society_id", ""))
	if not String(event.get("subject_type", "")).is_empty() and not str(event.get("subject_id", "")).is_empty():
		return make(String(event.subject_type), event.subject_id, society)
	for pair in [["project_id", PROJECT], ["site_id", SITE], ["conflict_id", CONFLICT]]:
		if not str(event.get(pair[0], "")).is_empty(): return make(pair[1], event[pair[0]], society)
	return {}
