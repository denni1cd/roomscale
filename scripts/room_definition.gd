extends RefCounted
## Loads and validates the external room contract used by rendering and gameplay.


static func load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "definition": {}, "errors": ["file not found: %s" % path]}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "definition": {}, "errors": ["could not open: %s" % path]}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "definition": {}, "errors": ["root must be a JSON object"]}
	var definition: Dictionary = parsed
	var errors := validate(definition)
	return {"ok": errors.is_empty(), "definition": definition, "errors": errors}


static func validate(definition: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if int(definition.get("schema_version", 0)) != 1:
		errors.append("schema_version must be 1")
	if String(definition.get("id", "")).strip_edges().is_empty():
		errors.append("id is required")
	var room_size: Array = definition.get("dimensions", [])
	if room_size.size() != 2 or not _positive_number(room_size[0]) or not _positive_number(room_size[1]):
		errors.append("dimensions must contain positive width and depth")
	if not _positive_number(definition.get("wall_height", null)):
		errors.append("wall_height must be positive")
	var floor: Variant = definition.get("floor", null)
	if not floor is Dictionary or not _positive_vector(floor.get("dimensions", null), 2) or not _number_vector(floor.get("center", null), 3) or not _finite_number(floor.get("height", null)):
		errors.append("floor requires positive dimensions, a 3D center, and height")
	elif room_size.size() == 2 and (not is_equal_approx(float(floor.dimensions[0]), float(room_size[0])) or not is_equal_approx(float(floor.dimensions[1]), float(room_size[1]))):
		errors.append("floor dimensions must match room dimensions")
	var objects: Array = definition.get("objects", [])
	if objects.is_empty():
		errors.append("objects must contain at least one room object")
	var object_ids: Dictionary = {}
	var surface_ids: Dictionary = {"FLOOR": true}
	var target_surface_id := String(definition.get("target_surface_id", "")).strip_edges()
	var floor_center: Array = [0.0, 0.0, 0.0]
	if floor is Dictionary and _number_vector(floor.get("center", null), 3):
		floor_center = floor.center
	for object_variant in objects:
		if not object_variant is Dictionary:
			errors.append("each object must be an object")
			continue
		var object: Dictionary = object_variant
		var object_id := String(object.get("id", "")).strip_edges()
		if object_id.is_empty() or object_ids.has(object_id):
			errors.append("object ids must be present and unique: %s" % object_id)
		else:
			object_ids[object_id] = true
		if String(object.get("kind", "")).strip_edges().is_empty():
			errors.append("object %s requires kind" % object_id)
		if not _number_vector(object.get("position", null), 3):
			errors.append("object %s position must contain three numbers" % object_id)
		if not _positive_vector(object.get("dimensions", null), 3):
			errors.append("object %s dimensions must contain three positive numbers" % object_id)
		elif _number_vector(object.get("position", null), 3) and room_size.size() == 2:
			var pos: Array = object.position
			var size: Array = object.dimensions
			var padding: Array = object.get("navigation_padding", [0.0, 0.0, 0.0])
			if not _number_vector(padding, 3):
				if object.has("navigation_padding"):
					errors.append("object %s navigation_padding must contain three numbers" % object_id)
				padding = [0.0, 0.0, 0.0]
			var half_x := float(size[0]) * 0.5 + float(padding[0])
			var half_z := float(size[2]) * 0.5 + float(padding[2])
			if absf(float(pos[0]) - float(floor_center[0])) + half_x > float(room_size[0]) * 0.5 - 1.0 or absf(float(pos[2]) - float(floor_center[2])) + half_z > float(room_size[1]) * 0.5 - 1.0:
				errors.append("object %s bounds exceed the room floor" % object_id)
		if object.has("surface"):
			var surface: Variant = object.surface
			if not surface is Dictionary:
				errors.append("object %s surface must be an object" % object_id)
				continue
			var region_id := String(surface.get("region_id", "")).strip_edges()
			if region_id.is_empty() or surface_ids.has(region_id):
				errors.append("surface region ids must be present and unique: %s" % region_id)
			else:
				surface_ids[region_id] = true
			if not _positive_number(surface.get("height", null)):
				errors.append("surface %s height must be positive" % region_id)
			elif _number_vector(object.get("position", null), 3) and _positive_vector(object.get("dimensions", null), 3):
				var expected_height := float(object.position[1]) + float(object.dimensions[1])
				if not is_equal_approx(float(surface.height), expected_height) or float(surface.height) >= float(definition.get("wall_height", INF)):
					errors.append("surface %s height is inconsistent with its object bounds or room walls" % region_id)
			if not _number_vector(surface.get("anchor", null), 3):
				errors.append("surface %s anchor must contain three numbers" % region_id)
			elif _number_vector(object.get("position", null), 3) and _positive_vector(object.get("dimensions", null), 3):
				var anchor: Array = surface.anchor
				var pos: Array = object.position
				var size: Array = object.dimensions
				if not is_equal_approx(float(anchor[1]), float(surface.height)) or absf(float(anchor[0]) - float(pos[0])) > float(size[0]) * 0.5 or absf(float(anchor[2]) - float(pos[2])) > float(size[2]) * 0.5:
					errors.append("surface %s anchor is outside the navigable surface bounds" % region_id)
			if surface.has("approach_points"):
				var approach_value: Variant = surface.get("approach_points")
				if not approach_value is Array:
					errors.append("surface %s approach_points hint must be an array" % region_id)
				else:
					var approaches: Array = approach_value
					if approaches.size() < 2:
						errors.append("surface %s optional approach_points hint must contain at least two points" % region_id)
					for approach in approaches:
						if not _number_vector(approach, 3):
							errors.append("surface %s has malformed approach point" % region_id)
						elif room_size.size() == 2 and (absf(float(approach[0]) - float(floor_center[0])) > float(room_size[0]) * 0.5 - 1.0 or absf(float(approach[2]) - float(floor_center[2])) > float(room_size[1]) * 0.5 - 1.0):
							errors.append("surface %s approach point lies outside the room floor" % region_id)
						elif floor is Dictionary and _finite_number(floor.get("height", null)) and not is_equal_approx(float(approach[1]), float(floor.height)):
							errors.append("surface %s approach point height must match the floor" % region_id)
						elif _number_vector(object.get("position", null), 3) and _positive_vector(object.get("dimensions", null), 3):
							var surface_pos: Array = object.position
							var surface_size: Array = object.dimensions
							var pad: Array = object.get("navigation_padding", [0.0, 0.0, 0.0])
							if not _number_vector(pad, 3):
								pad = [0.0, 0.0, 0.0]
							var angle := deg_to_rad(float(object.get("rotation_degrees", 0.0)))
							var delta_x := float(approach[0]) - float(surface_pos[0])
							var delta_z := float(approach[2]) - float(surface_pos[2])
							var local_x := delta_x * cos(angle) + delta_z * sin(angle)
							var local_z := -delta_x * sin(angle) + delta_z * cos(angle)
							var blocked_x := float(surface_size[0]) * 0.5 + float(pad[0])
							var blocked_z := float(surface_size[2]) * 0.5 + float(pad[2])
							if absf(local_x) <= blocked_x and absf(local_z) <= blocked_z:
								errors.append("surface %s approach point is inside its blocking footprint" % region_id)
	if target_surface_id.is_empty() or target_surface_id == "FLOOR" or not surface_ids.has(target_surface_id):
		errors.append("target_surface_id references an unknown navigable surface: %s" % target_surface_id)
	var construction: Variant = definition.get("construction", null)
	if not construction is Dictionary or not _number_vector(construction.get("depot_pickup", null), 3):
		errors.append("construction requires a 3D depot_pickup position; the site is derived from target geometry")
	var landmarks: Variant = definition.get("landmarks", null)
	if not landmarks is Dictionary:
		errors.append("landmarks must be an object")
	else:
		for key in ["workshop", "depot", "housing", "work_area"]:
			if not _number_vector(landmarks.get(key, null), 3):
				errors.append("landmark %s must contain three numbers" % key)
	var stations: Variant = definition.get("activity_stations", null)
	if not stations is Dictionary or not stations.get("workshop", []) is Array or not stations.get("patrol", []) is Array:
		errors.append("activity_stations requires workshop and patrol arrays")
	elif stations.workshop.size() < 1 or stations.patrol.size() < 4:
		errors.append("activity_stations needs workshop stations and four patrol points")
	var spawn: Variant = definition.get("spawn", null)
	if not spawn is Dictionary or not _number_vector(spawn.get("center", null), 3) or not _positive_number(spawn.get("dimensions", [])[0] if spawn.get("dimensions", []) is Array and spawn.dimensions.size() == 3 else null) or not _positive_number(spawn.get("dimensions", [])[2] if spawn.get("dimensions", []) is Array and spawn.dimensions.size() == 3 else null):
		errors.append("spawn requires a 3D center and positive horizontal footprint dimensions")
	elif room_size.size() == 2 and floor is Dictionary and _number_vector(floor.get("center", null), 3):
		var spawn_center: Array = spawn.center
		var spawn_size: Array = spawn.dimensions
		if absf(float(spawn_center[0]) - float(floor_center[0])) + float(spawn_size[0]) * 0.5 > float(room_size[0]) * 0.5 - 1.0 or absf(float(spawn_center[2]) - float(floor_center[2])) + float(spawn_size[2]) * 0.5 > float(room_size[1]) * 0.5 - 1.0:
			errors.append("spawn region lies outside the room floor")
	return errors


static func validate_navigation(definition: Dictionary, floor_navigation: Node, surface_navigation: Node) -> Array[String]:
	var errors: Array[String] = []
	for object_variant in definition.get("objects", []):
		var object: Dictionary = object_variant
		if not object.has("surface"):
			continue
		var region_id := String(object.surface.region_id)
		var usable_approaches := 0
		for approach in surface_navigation.investigation_candidates_for(region_id):
			if floor_navigation.is_obstacle_position(approach):
				continue
			if floor_navigation.path_between(vector3_from(definition.spawn.center), approach).is_empty():
				continue
			usable_approaches += 1
		if usable_approaches < 2:
			errors.append("surface %s has fewer than two walkable, reachable approach points" % region_id)
	var construction_site: Dictionary = surface_navigation.derive_construction_site(floor_navigation)
	if not construction_site.get("valid", false):
		errors.append("no reachable traversal construction site can be derived: %s" % construction_site.get("reason", "unknown reason"))
	return errors


static func vector3_from(values: Array) -> Vector3:
	if values.size() < 3:
		return Vector3.ZERO
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


static func _number_vector(value: Variant, size: int) -> bool:
	if not value is Array or value.size() != size:
		return false
	for item in value:
		if not (item is int or item is float) or not is_finite(float(item)):
			return false
	return true


static func _positive_vector(value: Variant, size: int) -> bool:
	if not _number_vector(value, size):
		return false
	for item in value:
		if float(item) <= 0.0:
			return false
	return true


static func _positive_number(value: Variant) -> bool:
	return _finite_number(value) and float(value) > 0.0


static func _finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
