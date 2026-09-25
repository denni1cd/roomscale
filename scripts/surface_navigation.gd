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
			var connection_path: Array[Vector3] = connection.get("path", [])
			if connection_path.size() < 2:
				return {"reachable": false, "path": [], "reason": "deployed traversal geometry missing"}
			var route: Array[Vector3] = []
			if start_region == FLOOR_REGION:
				var floor_approach: Array[Vector3] = floor_navigation.path_between(start, connection_path[0])
				if floor_approach.is_empty():
					return {"reachable": false, "path": [], "reason": "no floor route to grapple base"}
				route.append_array(floor_approach)
				for index in range(1, connection_path.size()):
					route.append(connection_path[index])
				if route[route.size() - 1].distance_to(finish) > 0.1:
					route.append(finish)
			else:
				route.append(start)
				for index in range(connection_path.size() - 1, -1, -1):
					route.append(connection_path[index])
				var floor_exit: Array[Vector3] = floor_navigation.path_between(connection_path[0], finish)
				for index in range(1, floor_exit.size()):
					route.append(floor_exit[index])
			return {"reachable": true, "path": route, "reason": "deployed grapple cable"}
	return {"reachable": false, "path": [], "reason": "no navigation connection between %s and %s" % [start_region, end_region]}


func connect_regions(start_region: String, end_region: String, path: Array[Vector3]) -> bool:
	if not regions.has(start_region) or not regions.has(end_region) or start_region == end_region or path.size() < 2:
		return false
	if has_connection(start_region, end_region):
		return false
	connections.append({"from": start_region, "to": end_region, "path": path.duplicate()})
	return true


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
