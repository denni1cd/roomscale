extends Node
## Region graph for the floor and raised desk. A missing connection is an explicit barrier.

const FLOOR_REGION := "FLOOR"
const DESK_REGION := "DESK"

var floor_navigation: Node
var regions: Dictionary = {
	FLOOR_REGION: {"height": 0.0, "kind": "room_floor"},
	DESK_REGION: {"height": 30.0, "kind": "elevated_surface"},
}
var connections: Array[Dictionary] = []


func route_between(start_region: String, end_region: String, start: Vector3, finish: Vector3) -> Dictionary:
	if not regions.has(start_region) or not regions.has(end_region):
		return {"reachable": false, "path": [], "reason": "unknown navigation region"}
	if start_region == FLOOR_REGION and end_region == FLOOR_REGION:
		var floor_path: Array[Vector3] = floor_navigation.path_between(start, finish)
		return {"reachable": not floor_path.is_empty(), "path": floor_path, "reason": "" if not floor_path.is_empty() else "floor route blocked"}
	if start_region == DESK_REGION and end_region == DESK_REGION:
		return {"reachable": true, "path": [start, finish], "reason": ""}
	for connection in connections:
		if (String(connection["from"]) == start_region and String(connection["to"]) == end_region) or (String(connection["from"]) == end_region and String(connection["to"]) == start_region):
			return {"reachable": true, "path": [start, finish], "reason": "connected regions"}
	return {"reachable": false, "path": [], "reason": "no navigation connection between %s and %s" % [start_region, end_region]}


func investigation_candidates() -> Array[Vector3]:
	# The desk's right and left edges are clear of the chair and stay on the walkable floor.
	return [Vector3(-10.0, 0.0, -52.0), Vector3(-106.0, 0.0, -52.0)]


func investigation_route(start: Vector3, candidate_index: int) -> Array[Vector3]:
	var candidates := investigation_candidates()
	if candidate_index < 0 or candidate_index >= candidates.size():
		return []
	return floor_navigation.path_between(start, candidates[candidate_index])


func has_connection(start_region: String, end_region: String) -> bool:
	for connection in connections:
		if (String(connection["from"]) == start_region and String(connection["to"]) == end_region) or (String(connection["from"]) == end_region and String(connection["to"]) == start_region):
			return true
	return false
