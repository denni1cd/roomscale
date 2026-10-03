extends RefCounted
## Bounded macro history. Suppression keys retain only bounded recent state.
const MAJOR := ["salvage_authorized", "traversal_complete", "structure_complete", "cohort_joined", "source_exhausted"]
var limit := 128
var events: Array[Dictionary] = []
var sequence := 0
var _states: Dictionary = {}

func record(seconds: float, kind: String, message: String, evidence: Dictionary = {}, focus: Vector3 = Vector3.ZERO, key: String = "") -> bool:
	var suppression := kind if key.is_empty() else key
	if _states.get(suppression, "") == message: return false
	_states[suppression] = message
	sequence += 1
	events.append({"id": sequence, "seconds": seconds, "day": seconds / 600.0, "kind": kind, "message": message, "evidence": evidence.duplicate(true), "focus": focus, "major": kind in MAJOR})
	while events.size() > limit: events.pop_front()
	while _states.size() > limit * 2: _states.erase(_states.keys()[0])
	return true
