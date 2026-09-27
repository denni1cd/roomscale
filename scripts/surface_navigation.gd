extends Node
## Navigation regions and elevated surfaces are projected from RoomDefinition.

const FLOOR_REGION := "FLOOR"
const INVESTIGATION_CLEARANCE_INCHES := 4.0

var floor_navigation: Node
var room_definition: Dictionary = {}
var regions: Dictionary = {}
var connections: Array[Dictionary] = []
var goal_surface_id := ""
var _floor_height := 0.0
var _spawn_center := Vector3.ZERO


func configure(definition: Dictionary, floor_nav: Node) -> void:
	room_definition = definition.duplicate(true)
	floor_navigation = floor_nav
	regions.clear()
	goal_surface_id = String(room_definition.get("target_surface_id", ""))
	var floor_data: Dictionary = room_definition.get("floor", {})
	_floor_height = float(floor_data.get("height", 0.0))
	regions[FLOOR_REGION] = {"height": _floor_height, "kind": "room_floor", "region_id": FLOOR_REGION}
	var spawn_data: Dictionary = room_definition.get("spawn", {})
	if spawn_data.has("center"):
		_spawn_center = _vector(spawn_data.center)
	for object_variant in room_definition.objects:
		var object: Dictionary = object_variant
		if not object.has("surface"):
			continue
		var surface: Dictionary = object.surface
		var region_id := String(surface.region_id)
		var pos: Vector3 = _vector(object.position)
		var dims: Array = object.dimensions
		var padding: Array = object.get("navigation_padding", [0.0, 0.0, 0.0])
		regions[region_id] = {
			"height": float(surface.height),
			"kind": "elevated_surface",
			"region_id": region_id,
			"object_id": String(object.id),
			"object_name": String(object.get("name", object.get("id", "Object"))),
			"center": Vector3(pos.x, float(surface.height), pos.z),
			"floor_center": Vector3(pos.x, _floor_height, pos.z),
			"dimensions": Vector2(float(dims[0]), float(dims[2])),
			"rotation_degrees": float(object.get("rotation_degrees", 0.0)),
			"navigation_padding": Vector2(float(padding[0]), float(padding[2])),
			"anchor": _vector(surface.anchor),
			"approach_hints": surface.get("approach_points", []).duplicate(true),
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
	var goal: Dictionary = regions.get(region_id, {})
	if goal.is_empty() or region_id == FLOOR_REGION:
		return []
	var hinted := _filtered_hint_candidates(goal)
	if hinted.size() >= 2:
		return hinted
	return _derive_investigation_candidates(goal)


func _derive_investigation_candidates(surface: Dictionary) -> Array[Vector3]:
	var candidates: Array[Vector3] = []
	var center: Vector3 = surface.get("floor_center", Vector3.ZERO)
	var dimensions: Vector2 = surface.get("dimensions", Vector2.ZERO)
	var padding: Vector2 = surface.get("navigation_padding", Vector2.ZERO)
	var angle := deg_to_rad(float(surface.get("rotation_degrees", 0.0)))
	var cosine := absf(cos(angle))
	var sine := absf(sin(angle))
	var local_x_axis := Vector2(cos(angle), -sin(angle))
	var local_z_axis := Vector2(sin(angle), cos(angle))
	var local_half_x := dimensions.x * 0.5 + padding.x
	var local_half_z := dimensions.y * 0.5 + padding.y
	var world_half_x := cosine * local_half_x + sine * local_half_z
	var world_half_z := sine * local_half_x + cosine * local_half_z
	var safe_world_half_x := world_half_x + INVESTIGATION_CLEARANCE_INCHES
	var safe_world_half_z := world_half_z + INVESTIGATION_CLEARANCE_INCHES
	var x_axis_aabb_escape := minf(safe_world_half_x / maxf(cosine, 0.001), safe_world_half_z / maxf(sine, 0.001))
	var z_axis_aabb_escape := minf(safe_world_half_x / maxf(sine, 0.001), safe_world_half_z / maxf(cosine, 0.001))
	var x_offset := maxf(local_half_x + INVESTIGATION_CLEARANCE_INCHES, x_axis_aabb_escape)
	var z_offset := maxf(local_half_z + INVESTIGATION_CLEARANCE_INCHES, z_axis_aabb_escape)
	var offsets: Array[Vector2] = [
		local_x_axis * x_offset,
		local_x_axis * -x_offset,
		local_z_axis * z_offset,
		local_z_axis * -z_offset,
	]
	for offset in offsets:
		var candidate := Vector3(center.x + offset.x, _floor_height, center.z + offset.y)
		if _candidate_is_valid(candidate, surface):
			_append_distinct(candidates, candidate)
	return candidates


func _filtered_hint_candidates(surface: Dictionary) -> Array[Vector3]:
	var candidates: Array[Vector3] = []
	for item in surface.get("approach_hints", []):
		if not item is Array or item.size() != 3:
			continue
		var candidate := _vector(item)
		if _candidate_is_valid(candidate, surface):
			_append_distinct(candidates, candidate)
	return candidates


func _candidate_is_valid(candidate: Vector3, surface: Dictionary) -> bool:
	if not is_instance_valid(floor_navigation) or not floor_navigation.is_walkable(candidate):
		return false
	var bounds: Rect2 = floor_navigation.room_bounds()
	if not bounds.has_point(Vector2(candidate.x, candidate.z)):
		return false
	if _inside_surface_blocking_footprint(candidate, surface):
		return false
	if floor_navigation.is_obstacle_position(candidate):
		return false
	return not floor_navigation.path_between(_spawn_center, candidate).is_empty()


func _inside_surface_blocking_footprint(candidate: Vector3, surface: Dictionary) -> bool:
	var center: Vector3 = surface.get("floor_center", Vector3.ZERO)
	var dimensions: Vector2 = surface.get("dimensions", Vector2.ZERO)
	var padding: Vector2 = surface.get("navigation_padding", Vector2.ZERO)
	var angle := deg_to_rad(float(surface.get("rotation_degrees", 0.0)))
	var delta := Vector2(candidate.x - center.x, candidate.z - center.z)
	var local_x := delta.x * cos(angle) - delta.y * sin(angle)
	var local_z := delta.x * sin(angle) + delta.y * cos(angle)
	return absf(local_x) <= dimensions.x * 0.5 + padding.x and absf(local_z) <= dimensions.y * 0.5 + padding.y


func _append_distinct(candidates: Array[Vector3], candidate: Vector3) -> bool:
	for existing in candidates:
		if existing.distance_to(candidate) < 1.0:
			return false
	candidates.append(candidate)
	return true


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
	var angle := deg_to_rad(float(region.get("rotation_degrees", 0.0)))
	var local_points: Array[Vector2] = [
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
		Vector2.ZERO,
	]
	var points: Array[Vector3] = []
	for local_point in local_points:
		var world_x := local_point.x * cos(angle) + local_point.y * sin(angle)
		var world_z := -local_point.x * sin(angle) + local_point.y * cos(angle)
		points.append(Vector3(center.x + world_x, center.y, center.z + world_z))
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
		var proposed := Vector3(approach.x + direction.x * 12.0, _floor_height, approach.z + direction.y * 12.0)
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
