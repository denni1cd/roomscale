extends RefCounted
## Detached, bounded snapshots of the existing journals, never another event log.
## All consumers use source_key instead of assuming journal-local IDs are global.

static func runtimes(simulation: Node) -> Array:
	var world: Node = simulation.get("world_simulation")
	if is_instance_valid(world): return world.ordered_runtimes()
	return [simulation]

static func events(simulation: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var world: Node = simulation.get("world_simulation")
	if is_instance_valid(world): _append(result, world.journal.events, "world", "", "")
	for runtime in runtimes(simulation):
		_append(result, runtime.journal.events, "society:" + String(runtime.instance_id), String(runtime.instance_id), String(runtime.definition_id))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a.seconds) != float(b.seconds): return float(a.seconds) < float(b.seconds)
		if String(a.source_id) != String(b.source_id): return String(a.source_id) < String(b.source_id)
		return int(a.id) < int(b.id))
	return result

static func _append(result: Array[Dictionary], records: Array, source: String, society: String, civilization: String) -> void:
	for record in records:
		var event: Dictionary = record.duplicate(true)
		event["source_id"] = source
		event["source_key"] = source + ":" + str(event.id)
		if String(event.get("society_id", "")).is_empty(): event["society_id"] = society
		if String(event.get("civilization_id", "")).is_empty(): event["civilization_id"] = civilization
		result.append(event)
