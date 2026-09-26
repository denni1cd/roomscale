extends Node
## Navigation regions and elevated surfaces are projected from RoomDefinition.

const FLOOR_REGION := "FLOOR"

var floor_navigation: Node
var room_definition: Dictionary = {}
var regions: Dictionary = {}
var connections: Array[Dictionary] = []
var goal_surface_id := ""


func configure(definition: Dictionary, floor_nav: Node) -> void:
	room_definition = definition.duplicate(true)
	floor_navigation = floor_nav
	regions.clear()
	regions[FLOOR_REGION] = {"height": 0.0, "kind": "room_floor", "region_id": FLOOR_REGION}
	goal_surface_id = String(room_definition.get("target_surface_id", ""))
	for object_variant in room_definition.objects:
		var object: Dictionary = object_variant
		if not object.has("surface"):
			continue
		var surface: Dictionary = object.surface
		var region_id := String(surface.region_id)
		var pos: Vector3 = _vector(object.position)
		var dims: Array = object.dimensions
		regions[region_id] = {
			"height": float(surface.height),
			"kind": "elevated_surface",
			"region_id": region_id,
			"object_id": String(object.id),
			"object_name": String(object.name),
			"center": Vector3(pos.x, float(surface.height), pos.z),
			"dimensions": Vector2(float(dims[0]), float(dims[2])),
			"anchor": _vector(surface.anchor),
			"approach_points": surface.get("approach_points", []).duplicate(true),
			"goal": region_id == goal_surface_id,
		}
	connections.clear()


func goal_surface() -> Dictionary:
	return regions.get(goal_surface_id, {}).duplicate(true)


func route_between(start_region: String, end_region: String, start: Vector3, finish: Vector3) -> Dictionary:
	if not regions.has(start_region) or not regions.has(end_region):
		return {"reachable": false, "path": [], "reason": "unknown navigation region"}
	if start_region == FLOOR_REGION and end_region == FLOOR_REGION:
		var floor_path: Array[Vector3] = floor_navigation.path_between(start, finish)
		return {"reachable": not floor_path.is_empty(), "path": floor_path, "reason": "" if not floor_path.is_empty() else "floor route blocked"}
	if start_region == end_region:
		return {"reachable": true, "path": [start, finish], "reason": "same navigation region"}
	for connection_variant in connections:
		var connection: Dictionary = connection_variant
		var forward := String(connection.from) == start_region and String(connection.to) == end_region
		var reverse := String(connection.from) == end_region and String(connection.to) == start_region
		if not forward and not reverse:
			continue
		var link_path: Array[Vector3] = connection.get("path", [])
		if link_path.size() < 2:
			return {"reachable": false, "path": [], "reason": "deployed traversal geometry missing"}
		var floor_region := start_region == FLOOR_REGION or end_region == FLOOR_REGION
		var route: Array[Vector3] = []
		if floor_region and start_region == FLOOR_REGION:
			var floor_approach: Array[Vector3] = floor_navigation.path_between(start, link_path[0])
			if floor_approach.is_empty():
				return {"reachable": false, "path": [], "reason": "no floor route to traversal base"}
			route.append_array(floor_approach)
			for index in range(1, link_path.size()):
				route.append(link_path[index])
			if route.back().distance_to(finish) > 0.1:
				route.append(finish)
		elif floor_region:
			route.append(start)
			for index in range(link_path.size() - 1, -1, -1):
				route.append(link_path[index])
			var floor_exit: Array[Vector3] = floor_navigation.path_between(link_path[0], finish)
			for index in range(1, floor_exit.size()):
				route.append(floor_exit[index])
		else:
			if forward:
				route.append_array(link_path)
			else:
				var reversed_path := link_path.duplicate()
				reversed_path.reverse()
				route.append_array(reversed_path)
			if route.front().distance_to(start) > 0.1:
				route.push_front(start)
			if route.back().distance_to(finish) > 0.1:
				route.append(finish)
		return {"reachable": not route.is_empty(), "path": route, "reason": "deployed traversal geometry"}
	return {"reachable": false, "path": [], "reason": "no navigation connection between %s and %s" % [start_region, end_region]}


func connect_regions(start_region: String, end_region: String, path: Array[Vector3]) -> bool:
	if not regions.has(start_region) or not regions.has(end_region) or start_region == end_region or path.size() < 2:
		return false
	if has_connection(start_region, end_region):
		return false
	connections.append({"from": start_region, "to": end_region, "path": path.duplicate()})
	return true


func investigation_candidates() -> Array[Vector3]:
	return investigation_candidates_for(goal_surface_id)


func investigation_candidates_for(region_id: String) -> Array[Vector3]:
	var candidates: Array[Vector3] = []
	var goal: Dictionary = regions.get(region_id, {})
	for item in goal.get("approach_points", []):
		candidates.append(_vector(item))
	return candidates


func investigation_route(start: Vector3, candidate_index: int) -> Array[Vector3]:
	var candidates := investigation_candidates()
	if candidate_index < 0 or candidate_index >= candidates.size():
		return []
	return floor_navigation.path_between(start, candidates[candidate_index])


func exploration_route(start: Vector3, region_id: String) -> Array[Vector3]:
	if not regions.has(region_id) or region_id == FLOOR_REGION:
		return []
	var region: Dictionary = regions[region_id]
	var center: Vector3 = region.center
	var half: Vector2 = region.dimensions * 0.36
	var points: Array[Vector3] = [
		Vector3(center.x - half.x, center.y, center.z - half.y),
		Vector3(center.x + half.x, center.y, center.z - half.y),
		Vector3(center.x + half.x, center.y, center.z + half.y),
		Vector3(center.x - half.x, center.y, center.z + half.y),
		Vector3(center.x, center.y, center.z),
	]
	var path: Array[Vector3] = [start]
	path.append_array(points)
	return path


func derive_construction_site(floor_nav: Node) -> Dictionary:
	if goal_surface_id.is_empty() or not regions.has(goal_surface_id):
		return {"valid": false, "reason": "no goal surface is registered"}
	var surface: Dictionary = regions[goal_surface_id]
	var center: Vector3 = surface.center
	var bounds: Rect2 = floor_nav.room_bounds()
	for approach in investigation_candidates():
		var direction := Vector2(approach.x - center.x, approach.z - center.z).normalized()
		var proposed := Vector3(approach.x + direction.x * 12.0, 0.0, approach.z + direction.y * 12.0)
		if not bounds.grow(-4.0).has_point(Vector2(proposed.x, proposed.z)):
			continue
		var site: Vector3 = floor_nav.nearest_walkable_position(proposed)
		if not is_finite(site.x) or site.distance_to(proposed) > 8.0 or floor_nav.is_obstacle_position(site):
			continue
		if floor_nav.path_between(site, approach).is_empty():
			continue
		return {"valid": true, "position": site, "approach": approach, "target_region": goal_surface_id, "reason": "derived from target surface approach geometry"}
	return {"valid": false, "reason": "no clear, reachable construction point could be derived near the target"}


func has_connection(start_region: String, end_region: String) -> bool:
	for connection in connections:
		if (String(connection.from) == start_region and String(connection.to) == end_region) or (String(connection.from) == end_region and String(connection.to) == start_region):
			return true
	return false


func _vector(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
