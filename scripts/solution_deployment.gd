extends RefCounted
## Generic physical climb-route adapter, with authored presentation styles.

static func supported(solution: Dictionary) -> bool:
	var deployment: Dictionary = solution.get("deployment", {})
	return deployment.get("adapter", "") == "climb_route" and deployment.get("style", "rope") in ["rope", "cable", "vine"]

static func derive(navigation: Node, floor_navigation: Node, region: String) -> Dictionary:
	var previous: String = navigation.goal_surface_id
	navigation.goal_surface_id = region
	var site: Dictionary = navigation.derive_construction_site(floor_navigation)
	navigation.goal_surface_id = previous
	if not site.get("valid", false): return site
	var surface: Dictionary = navigation.regions[region]
	var anchor: Vector3 = surface.anchor
	var angle := deg_to_rad(float(surface.rotation_degrees))
	var local: Vector3 = (site.position - surface.center).rotated(Vector3.UP, -angle)
	var half: Vector2 = surface.dimensions / 2
	var scale := maxf(absf(local.x) / half.x, absf(local.z) / half.y)
	if scale <= 1.0: return {"valid":false,"reason":"Climb base must be outside the surface footprint"}
	var edge: Vector3 = surface.center + Vector3(local.x / scale, 0, local.z / scale).rotated(Vector3.UP, angle)
	# The inclined span ends at a real furniture edge. The remaining segment
	# lies on the supported surface, without an unsupported corner in midair.
	var path: Array[Vector3] = [site.position]
	for pair in [[site.position, edge], [edge, anchor]]:
		var steps := maxi(1, ceili(pair[0].distance_to(pair[1]) / 2.5))
		for step in range(1, steps + 1): path.append(pair[0].lerp(pair[1], float(step) / steps))
	# Conservative 3D furniture volumes, including rotation. A route must not
	# pass through another object merely because its floor base is legal.
	for index in range(1, path.size()):
		for object in floor_navigation.room_definition.objects:
			if not object.get("blocks_navigation", false): continue
			if _span_blocked(path[index-1], path[index], object):
				return {"valid":false,"reason":"Climb span intersects furniture"}
	return {"valid":true, "position":site.position, "region":region, "path":path}

static func _span_blocked(start: Vector3, finish: Vector3, object: Dictionary) -> bool:
	var center := Vector3(object.position[0], object.position[1], object.position[2])
	var rotation := -deg_to_rad(float(object.get("rotation_degrees", 0)))
	var origin := (start-center).rotated(Vector3.UP, rotation)
	var direction := (finish-start).rotated(Vector3.UP, rotation)
	# Open interiors permit a route to meet a furniture edge or lie on its top.
	var low := Vector3(-float(object.dimensions[0])/2, 0, -float(object.dimensions[2])/2) + Vector3.ONE * 0.001
	var high := Vector3(float(object.dimensions[0])/2, float(object.dimensions[1]), float(object.dimensions[2])/2) - Vector3.ONE * 0.001
	var enter := 0.0
	var leave := 1.0
	for axis in range(3):
		if low[axis] >= high[axis]: return false
		if absf(direction[axis]) < 0.000001:
			if origin[axis] <= low[axis] or origin[axis] >= high[axis]: return false
		else:
			var first := (low[axis]-origin[axis]) / direction[axis]
			var last := (high[axis]-origin[axis]) / direction[axis]
			enter = maxf(enter, minf(first,last))
			leave = minf(leave, maxf(first,last))
			if leave <= enter: return false
	return leave > enter

static func render(root: Node3D, path: Array[Vector3], solution: Dictionary, fraction: float, color: Color) -> void:
	for child in root.get_children(): child.free()
	var style: String = solution.deployment.get("style", "rope")
	var radius := 0.1 if style == "vine" else 0.04
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("53854b") if style == "vine" else color
	var visible_segments := floori((path.size() - 1) * clampf(fraction, 0.0, 1.0))
	for index in range(1, visible_segments + 1):
		var start: Vector3 = path[index - 1]
		var finish: Vector3 = path[index]
		var direction := finish - start
		if direction.length() <= 0.001: continue
		var segment := MeshInstance3D.new()
		segment.name = "RouteSegment%03d" % index
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = direction.length()
		segment.mesh = mesh
		segment.position = (start + finish) * 0.5
		segment.quaternion = Quaternion(Vector3.UP, direction.normalized())
		segment.material_override = material
		root.add_child(segment)
		if style == "vine" and index % 3 == 0:
			var leaf := MeshInstance3D.new()
			var leaf_mesh := SphereMesh.new()
			leaf_mesh.radius = 0.22
			leaf_mesh.height = 0.15
			leaf.mesh = leaf_mesh
			leaf.position = segment.position + Vector3(0.18, 0, 0)
			leaf.material_override = material
			root.add_child(leaf)
