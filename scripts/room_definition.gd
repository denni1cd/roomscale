extends RefCounted
## Loads and validates versioned RoomDefinition data used by rendering and gameplay.

const APPEARANCE_MATERIALS := ["wood", "metal", "fabric", "glass", "stone", "plastic", "ceramic", "paint", "plant", "other"]
const WALL_SIDES := ["north", "south", "east", "west"]
const OPENING_KINDS := ["door", "window", "opening"]
const ResourceProfiles := preload("res://scripts/resource_system.gd")


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
	var start_errors := prepare_start(definition)
	if not start_errors.is_empty(): return {"ok": false, "definition": definition, "errors": start_errors}
	var errors := validate(definition)
	return {"ok": errors.is_empty(), "definition": definition, "errors": errors}


static func prepare_start(definition: Dictionary) -> Array[String]:
	if not definition.has("start"): return []
	var start: Variant = definition.start
	if not start is Dictionary: return ["start must be an object"]
	if not _number_vector(start.get("origin"), 3): return ["start.origin requires three finite numbers"]
	if not _positive_number(start.get("population")) or float(start.population) != floorf(float(start.population)) or float(start.population) > 150: return ["start.population must be an integer from 1 to 150"]
	if not start.get("infrastructure") is Array: return ["start.infrastructure must be an array"]
	if not definition.get("objects") is Array: return ["objects must be an array"]
	var initial_ids := {}
	for kind in start.infrastructure:
		if kind not in ["workshop", "depot", "housing", "work_area"]: return ["Unknown starting infrastructure"]
		if initial_ids.has(kind): return ["Duplicate starting infrastructure"]
		initial_ids[kind] = true
	for object in definition.objects:
		if object is Dictionary and object.get("kind") == "settlement" and not initial_ids.has(object.get("id")): return ["Starting settlement objects must match start.infrastructure"]
	if not start.infrastructure.is_empty(): return []
	for object in definition.get("objects", []):
		if object is Dictionary and object.get("kind") == "settlement": return ["Empty start cannot include completed settlement objects"]
	# Compatibility anchors are places on the floor, not buildings or capabilities.
	# All coordinates are derived here, so gameplay does not depend on room IDs.
	var origin: Array = start.origin
	definition.landmarks = {}
	for kind in ["workshop", "depot", "housing", "work_area"]: definition.landmarks[kind] = origin.duplicate()
	definition.construction = {"depot_pickup": origin.duplicate()}
	definition.activity_stations = {"workshop": [origin.duplicate()], "housing": origin.duplicate(), "work_area": origin.duplicate(), "patrol": []}
	for offset in [Vector3(-12, 0, -12), Vector3(12, 0, -12), Vector3(12, 0, 12), Vector3(-12, 0, 12)]:
		var at := Vector3(float(origin[0]) + offset.x, float(origin[1]), float(origin[2]) + offset.z)
		# Derived compatibility activities must validate before runtime navigation
		# can select clear connected cells. Wall-adjacent founders cannot emit
		# out-of-room anchors merely because the nominal patrol offset is twelve.
		if _positive_vector(definition.get("dimensions"), 2) and definition.get("floor") is Dictionary and _number_vector(definition.floor.get("center"), 3):
			var floor_center := vector3_from(definition.floor.center)
			var half := Vector2(float(definition.dimensions[0]), float(definition.dimensions[1])) / 2
			at.x = clampf(at.x, floor_center.x - half.x + 2, floor_center.x + half.x - 2)
			at.z = clampf(at.z, floor_center.z - half.y + 2, floor_center.z + half.y - 2)
		definition.activity_stations.patrol.append([at.x, at.y, at.z])
	if not definition.get("civilization") is Dictionary: return ["start requires civilization configuration"]
	definition.civilization.shelter_capacity = 0
	definition.civilization.rest_capacity = 0
	return []


static func load_requested() -> Dictionary:
	var explicit_file := OS.get_environment("ROOMSCALE_ROOM_FILE").strip_edges()
	if not explicit_file.is_empty():
		var candidate_path := explicit_file.replace("\\", "/")
		if candidate_path.begins_with("res://"):
			candidate_path = ProjectSettings.globalize_path(candidate_path)
		elif not candidate_path.is_absolute_path():
			candidate_path = ProjectSettings.globalize_path("res://" + candidate_path)
		candidate_path = candidate_path.simplify_path()
		var project_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
		if not project_root.ends_with("/"):
			project_root += "/"
		var checked_path := candidate_path
		var checked_root := project_root
		if OS.get_name() == "Windows":
			checked_path = checked_path.to_lower()
			checked_root = checked_root.to_lower()
		if not checked_path.begins_with(checked_root) or candidate_path.get_extension().to_lower() != "json":
			return {"ok": false, "definition": {}, "errors": ["ROOMSCALE_ROOM_FILE must be a .json file inside the project directory"]}
		var file_room_id := candidate_path.get_file().get_basename()
		var file_id_pattern := RegEx.new()
		file_id_pattern.compile("^[A-Za-z0-9][A-Za-z0-9_-]*$")
		if file_id_pattern.search(file_room_id) == null:
			return {"ok": false, "definition": {}, "errors": ["RoomDefinition filename must use letters, digits, underscores, or hyphens"]}
		var file_result := load_file(candidate_path)
		var file_definition: Variant = file_result.get("definition", {})
		var file_definition_id: Variant = file_definition.get("id", null) if file_definition is Dictionary else null
		if not file_definition_id is String or String(file_definition_id) != file_room_id:
			file_result.errors.append("RoomDefinition id must match its JSON filename")
			file_result.ok = false
		return file_result
	var room_id := OS.get_environment("ROOMSCALE_ROOM").strip_edges()
	if room_id.is_empty():
		room_id = "room_a"
	var id_pattern := RegEx.new()
	id_pattern.compile("^[A-Za-z0-9][A-Za-z0-9_-]*$")
	if id_pattern.search(room_id) == null:
		return {"ok": false, "definition": {}, "errors": ["ROOMSCALE_ROOM must be a safe room ID or use ROOMSCALE_ROOM_FILE for an in-project JSON candidate"]}
	var room_path := "res://rooms/%s.json" % room_id
	var room_result := load_file(room_path)
	var room_definition: Variant = room_result.get("definition", {})
	var loaded_room_id: Variant = room_definition.get("id", null) if room_definition is Dictionary else null
	if not loaded_room_id is String or String(loaded_room_id) != room_id:
		room_result.errors.append("RoomDefinition id must match its JSON filename")
		room_result.ok = false
	return room_result


static func validate(definition: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var version: Variant = definition.get("schema_version", null)
	var valid_version_number := _finite_number(version) and is_equal_approx(float(version), roundf(float(version)))
	if not valid_version_number or int(version) not in [1, 2]:
		errors.append("schema_version must be integer 1 or 2")
	var schema_version := int(version) if valid_version_number else 0
	var room_id: Variant = definition.get("id", null)
	if not room_id is String or String(room_id).strip_edges().is_empty():
		errors.append("id is required")
	elif not _safe_room_id(String(room_id)):
		errors.append("id must use letters, digits, underscores, or hyphens and begin with a letter or digit")
	var display_name: Variant = definition.get("display_name", null)
	if not display_name is String or String(display_name).strip_edges().is_empty():
		errors.append("display_name is required")

	var room_size_value: Variant = definition.get("dimensions", null)
	var room_size: Array = room_size_value if room_size_value is Array else []
	var valid_room_size := room_size.size() == 2 and _positive_number(room_size[0]) and _positive_number(room_size[1])
	if not valid_room_size:
		errors.append("dimensions must contain positive width and depth")
	if not _positive_number(definition.get("wall_height", null)):
		errors.append("wall_height must be positive")
	var wall_height_value: Variant = definition.get("wall_height", null)
	var wall_height := float(wall_height_value) if _positive_number(wall_height_value) else 0.0

	var floor_value: Variant = definition.get("floor", null)
	var floor: Dictionary = floor_value if floor_value is Dictionary else {}
	var floor_center_value: Variant = floor.get("center", null)
	var floor_dimensions_value: Variant = floor.get("dimensions", null)
	var floor_height_value: Variant = floor.get("height", null)
	var floor_valid := floor_value is Dictionary and _positive_vector(floor_dimensions_value, 2) and _number_vector(floor_center_value, 3) and _finite_number(floor_height_value)
	if not floor_valid:
		errors.append("floor requires positive dimensions, a 3D center, and height")
	elif valid_room_size and (not is_equal_approx(float(floor.dimensions[0]), float(room_size[0])) or not is_equal_approx(float(floor.dimensions[1]), float(room_size[1]))):
		errors.append("floor dimensions must match room dimensions")
	var floor_center: Array = floor.center if _number_vector(floor_center_value, 3) else [0.0, 0.0, 0.0]
	var floor_height := float(floor_height_value) if _finite_number(floor_height_value) else 0.0
	if _number_vector(floor_center_value, 3) and _finite_number(floor_height_value) and not is_equal_approx(float(floor_center[1]), floor_height):
		errors.append("floor center Y must match walkable floor height")
	if definition.has("floor_color") and not _valid_color(definition.get("floor_color")):
		errors.append("floor_color must be a valid HTML color string")

	var objects_value: Variant = definition.get("objects", null)
	var objects: Array = objects_value if objects_value is Array else []
	if not objects_value is Array or objects.is_empty():
		errors.append("objects must be a nonempty array")
	var object_ids: Dictionary = {}
	var surface_ids: Dictionary = {"FLOOR": true}
	var target_surface_value: Variant = definition.get("target_surface_id", null)
	var target_surface_id := String(target_surface_value).strip_edges() if target_surface_value is String else ""
	if not target_surface_value is String:
		errors.append("target_surface_id must be a string")
	for object_index in range(objects.size()):
		var object_variant: Variant = objects[object_index]
		if not object_variant is Dictionary:
			errors.append("each object must be an object")
			continue
		var object: Dictionary = object_variant
		var object_id_value: Variant = object.get("id", null)
		var object_id := String(object_id_value).strip_edges() if object_id_value is String else ""
		if object_id.is_empty() or object_ids.has(object_id):
			errors.append("object ids must be present and unique: %s" % object_id)
		else:
			object_ids[object_id] = true
		var kind_value: Variant = object.get("kind", null)
		if not kind_value is String or String(kind_value).strip_edges().is_empty():
			errors.append("object %s requires kind" % object_id)
		if object.has("name") and not object.get("name") is String:
			errors.append("object %s name must be a string" % object_id)
		if not object.has("blocks_navigation") or not object.get("blocks_navigation") is bool:
			errors.append("object %s blocks_navigation must be a boolean" % object_id)
		if not _number_vector(object.get("position", null), 3):
			errors.append("object %s position must contain three numbers" % object_id)
		if not _positive_vector(object.get("dimensions", null), 3):
			errors.append("object %s dimensions must contain three positive numbers" % object_id)
		if object.has("rotation_degrees") and not _finite_number(object.get("rotation_degrees")):
			errors.append("object %s rotation_degrees must be finite" % object_id)
		if object.has("color") and not _valid_color(object.get("color")):
			errors.append("object %s color must be a valid HTML color string" % object_id)

		var position_value: Variant = object.get("position", null)
		var dimensions_value: Variant = object.get("dimensions", null)
		var padding_value: Variant = object.get("navigation_padding", [0.0, 0.0, 0.0])
		var padding: Array = padding_value if padding_value is Array else []
		if object.has("navigation_padding") and not _nonnegative_vector(padding_value, 3):
			errors.append("object %s navigation_padding must contain three nonnegative numbers" % object_id)
			padding = [0.0, 0.0, 0.0]
		if _positive_vector(dimensions_value, 3) and _number_vector(position_value, 3) and valid_room_size:
			var object_position: Array = position_value
			var object_dimensions: Array = dimensions_value
			if padding.size() != 3:
				padding = [0.0, 0.0, 0.0]
			var half_x := float(object_dimensions[0]) * 0.5 + float(padding[0])
			var half_z := float(object_dimensions[2]) * 0.5 + float(padding[2])
			var angle := deg_to_rad(float(object.get("rotation_degrees", 0.0)) if _finite_number(object.get("rotation_degrees", 0.0)) else 0.0)
			var extent_x := absf(cos(angle)) * half_x + absf(sin(angle)) * half_z
			var extent_z := absf(sin(angle)) * half_x + absf(cos(angle)) * half_z
			if absf(float(object_position[0]) - float(floor_center[0])) + extent_x > float(room_size[0]) * 0.5 - 1.0 or absf(float(object_position[2]) - float(floor_center[2])) + extent_z > float(room_size[1]) * 0.5 - 1.0:
				errors.append("object %s bounds exceed the room floor" % object_id)
			if _finite_number(floor_height_value):
				var object_base_y := float(object_position[1])
				if object_base_y < floor_height or object_base_y + float(object_dimensions[1]) > floor_height + wall_height:
					errors.append("object %s vertical bounds must stay between the floor and room ceiling" % object_id)
				if object.get("blocks_navigation", false) is bool and bool(object.get("blocks_navigation", false)) and not is_equal_approx(object_base_y, floor_height):
					errors.append("blocking object %s base height must match the floor height" % object_id)

		if object.has("appearance"):
			_validate_appearance(object.get("appearance"), "object %s appearance" % object_id, errors)
		if object.has("resource_profile"):
			var profile_errors := ResourceProfiles.validate_profile(object.resource_profile)
			for diagnostic in profile_errors: errors.append("object %s %s" % [object_id, diagnostic])
			var derivable_appearance: bool = not object.has("appearance") or (object.appearance is Dictionary and (not object.appearance.has("material") or object.appearance.material is String))
			if profile_errors.is_empty() and kind_value is String and _positive_vector(dimensions_value, 3) and derivable_appearance:
				var effective_profile := ResourceProfiles.derive(object)
				if effective_profile.harvestable and effective_profile.stages.is_empty():
					errors.append("object %s harvestable resource profile requires salvage stages" % object_id)
		if object.has("surface"):
			var surface_value: Variant = object.get("surface")
			if not surface_value is Dictionary:
				errors.append("object %s surface must be an object" % object_id)
				continue
			var surface: Dictionary = surface_value
			var region_id_value: Variant = surface.get("region_id", null)
			var region_id := String(region_id_value).strip_edges() if region_id_value is String else ""
			if not region_id_value is String:
				errors.append("object %s surface region_id must be a string" % object_id)
			if region_id.is_empty() or surface_ids.has(region_id):
				errors.append("surface region ids must be present and unique: %s" % region_id)
			else:
				surface_ids[region_id] = true
			var surface_height_value: Variant = surface.get("height", null)
			if not _positive_number(surface_height_value):
				errors.append("surface %s height must be positive" % region_id)
			elif _number_vector(position_value, 3) and _positive_vector(dimensions_value, 3):
				var expected_height := float(position_value[1]) + float(dimensions_value[1])
				if not is_equal_approx(float(surface_height_value), expected_height) or (wall_height > 0.0 and float(surface_height_value) >= wall_height + floor_height):
					errors.append("surface %s height is inconsistent with its object bounds or room walls" % region_id)
			var anchor_value: Variant = surface.get("anchor", null)
			if not _number_vector(anchor_value, 3):
				errors.append("surface %s anchor must contain three numbers" % region_id)
			elif _number_vector(position_value, 3) and _positive_vector(dimensions_value, 3) and _positive_number(surface_height_value):
				var anchor: Array = anchor_value
				var object_position: Array = position_value
				var object_dimensions: Array = dimensions_value
				var object_angle := deg_to_rad(float(object.get("rotation_degrees", 0.0)) if _finite_number(object.get("rotation_degrees", 0.0)) else 0.0)
				var dx := float(anchor[0]) - float(object_position[0])
				var dz := float(anchor[2]) - float(object_position[2])
				var local_x := dx * cos(object_angle) - dz * sin(object_angle)
				var local_z := dx * sin(object_angle) + dz * cos(object_angle)
				if not is_equal_approx(float(anchor[1]), float(surface_height_value)) or absf(local_x) > float(object_dimensions[0]) * 0.5 or absf(local_z) > float(object_dimensions[2]) * 0.5:
					errors.append("surface %s anchor is outside the navigable surface bounds" % region_id)
			if surface.has("approach_points"):
				var approach_value: Variant = surface.get("approach_points")
				if not approach_value is Array:
					errors.append("surface %s approach_points hint must be an array" % region_id)
				else:
					var approaches: Array = approach_value
					if approaches.size() < 2:
						errors.append("surface %s optional approach_points hint must contain at least two points" % region_id)
					for approach_variant in approaches:
						if not _number_vector(approach_variant, 3):
							errors.append("surface %s has malformed approach point" % region_id)
							continue
						var approach: Array = approach_variant
						if valid_room_size and (absf(float(approach[0]) - float(floor_center[0])) > float(room_size[0]) * 0.5 - 1.0 or absf(float(approach[2]) - float(floor_center[2])) > float(room_size[1]) * 0.5 - 1.0):
							errors.append("surface %s approach point lies outside the room floor" % region_id)
						elif _finite_number(floor_height_value) and not is_equal_approx(float(approach[1]), floor_height):
							errors.append("surface %s approach point height must match the floor" % region_id)
						elif _number_vector(position_value, 3) and _positive_vector(dimensions_value, 3):
							var object_position: Array = position_value
							var object_dimensions: Array = dimensions_value
							var pad: Array = padding if padding.size() == 3 else [0.0, 0.0, 0.0]
							var angle := deg_to_rad(float(object.get("rotation_degrees", 0.0)) if _finite_number(object.get("rotation_degrees", 0.0)) else 0.0)
							var delta_x := float(approach[0]) - float(object_position[0])
							var delta_z := float(approach[2]) - float(object_position[2])
							var local_x := delta_x * cos(angle) - delta_z * sin(angle)
							var local_z := delta_x * sin(angle) + delta_z * cos(angle)
							var blocked_x := float(object_dimensions[0]) * 0.5 + float(pad[0])
							var blocked_z := float(object_dimensions[2]) * 0.5 + float(pad[2])
							if absf(local_x) <= blocked_x and absf(local_z) <= blocked_z:
								errors.append("surface %s approach point is inside its blocking footprint" % region_id)

	for object in objects:
		if object is Dictionary and object.get("resource_profile") is Dictionary:
			var region: Variant = object.resource_profile.get("region_id", "FLOOR")
			if region is String and not surface_ids.has(region): errors.append("resource_profile references unknown region: " + region)
	if definition.has("civilization"):
		if not definition.civilization is Dictionary: errors.append("civilization must be an object")
		else:
			var config: Dictionary = definition.civilization
			if config.has("economy_construction") and not config.economy_construction is bool: errors.append("civilization.economy_construction must be boolean")
			if config.has("cohort_size") and (not _positive_number(config.cohort_size) or float(config.cohort_size) != floorf(float(config.cohort_size)) or float(config.cohort_size) > 150): errors.append("civilization.cohort_size must be an integer from 1 to 150")
			if config.has("initial_speed") and (not _finite_number(config.initial_speed) or float(config.initial_speed) < 0): errors.append("civilization.initial_speed must be finite and nonnegative")
			for field in ["shelter_capacity", "rest_capacity"]:
				if config.has(field) and (not _finite_number(config[field]) or float(config[field]) < 0 or float(config[field]) != floorf(float(config[field]))): errors.append("civilization.%s must be a nonnegative integer" % field)
			if config.has("stock"):
				if not config.stock is Dictionary: errors.append("civilization.stock must be an object")
				else:
					for resource in config.stock:
						if resource not in ResourceProfiles.RESOURCES or not _finite_number(config.stock[resource]) or float(config.stock[resource]) < 0: errors.append("invalid civilization stock: " + String(resource))
	if target_surface_id.is_empty() or target_surface_id == "FLOOR" or not surface_ids.has(target_surface_id):
		errors.append("target_surface_id references an unknown navigable surface: %s" % target_surface_id)
	var construction_value: Variant = definition.get("construction", null)
	if not construction_value is Dictionary or not _number_vector(construction_value.get("depot_pickup", null) if construction_value is Dictionary else null, 3):
		errors.append("construction requires a 3D depot_pickup position; the site is derived from target geometry")
	elif _number_vector(floor_center_value, 3) and _finite_number(floor_height_value) and not is_equal_approx(float(construction_value.depot_pickup[1]), floor_height):
		errors.append("construction.depot_pickup Y must match the floor height")
	elif floor_valid and valid_room_size and not _inside_floor(construction_value.depot_pickup, floor_center, room_size):
		errors.append("construction.depot_pickup lies outside the room floor")
	var landmarks_value: Variant = definition.get("landmarks", null)
	if not landmarks_value is Dictionary:
		errors.append("landmarks must be an object")
	else:
		var landmarks: Dictionary = landmarks_value
		for key in ["workshop", "depot", "housing", "work_area"]:
			if not _number_vector(landmarks.get(key, null), 3):
				errors.append("landmark %s must contain three numbers" % key)
			elif _finite_number(floor_height_value) and not is_equal_approx(float(landmarks[key][1]), floor_height):
				errors.append("landmark %s Y must match the floor height" % key)
			elif floor_valid and valid_room_size and not _inside_floor(landmarks[key], floor_center, room_size):
				errors.append("landmark %s lies outside the room floor" % key)
	var stations_value: Variant = definition.get("activity_stations", null)
	if not stations_value is Dictionary:
		errors.append("activity_stations requires workshop and patrol arrays")
	else:
		var stations: Dictionary = stations_value
		var workshop_value: Variant = stations.get("workshop", null)
		var patrol_value: Variant = stations.get("patrol", null)
		if not workshop_value is Array or not patrol_value is Array:
			errors.append("activity_stations requires workshop and patrol arrays")
		else:
			if workshop_value.size() < 1 or patrol_value.size() < 4:
				errors.append("activity_stations needs workshop stations and four patrol points")
			for point in workshop_value + patrol_value:
				if not _number_vector(point, 3):
					errors.append("activity station points must contain three numbers")
				elif _finite_number(floor_height_value) and not is_equal_approx(float(point[1]), floor_height):
					errors.append("activity station Y must match the floor height")
				elif floor_valid and valid_room_size and not _inside_floor(point, floor_center, room_size):
					errors.append("activity station lies outside the room floor")
			for station_key in ["housing", "work_area"]:
				if not _number_vector(stations.get(station_key, null), 3):
					errors.append("activity station %s must contain three numbers" % station_key)
				elif _finite_number(floor_height_value) and not is_equal_approx(float(stations[station_key][1]), floor_height):
					errors.append("activity station %s Y must match the floor height" % station_key)
				elif floor_valid and valid_room_size and not _inside_floor(stations[station_key], floor_center, room_size):
					errors.append("activity station %s lies outside the room floor" % station_key)

	var spawn_value: Variant = definition.get("spawn", null)
	if not spawn_value is Dictionary:
		errors.append("spawn requires a 3D center and positive horizontal footprint dimensions")
	else:
		var spawn: Dictionary = spawn_value
		var spawn_center_value: Variant = spawn.get("center", null)
		var spawn_dimensions_value: Variant = spawn.get("dimensions", null)
		if not _number_vector(spawn_center_value, 3) or not _number_vector(spawn_dimensions_value, 3) or not _positive_number(spawn_dimensions_value[0] if spawn_dimensions_value is Array and spawn_dimensions_value.size() == 3 else null) or not _positive_number(spawn_dimensions_value[2] if spawn_dimensions_value is Array and spawn_dimensions_value.size() == 3 else null):
			errors.append("spawn requires a 3D center and positive horizontal footprint dimensions")
		elif valid_room_size and floor_valid:
			var spawn_center: Array = spawn_center_value
			var spawn_dimensions: Array = spawn_dimensions_value
			if not is_equal_approx(float(spawn_center[1]), floor_height):
				errors.append("spawn center Y must match the floor height")
			if absf(float(spawn_center[0]) - float(floor_center[0])) + float(spawn_dimensions[0]) * 0.5 > float(room_size[0]) * 0.5 - 1.0 or absf(float(spawn_center[2]) - float(floor_center[2])) + float(spawn_dimensions[2]) * 0.5 > float(room_size[1]) * 0.5 - 1.0:
				errors.append("spawn region lies outside the room floor")

	_validate_camera(definition.get("camera", null), definition, errors)
	if schema_version == 2:
		_validate_room_shell(definition.get("room_shell", null), definition, errors)
	elif definition.has("room_shell"):
		errors.append("room_shell requires schema_version 2")
	return errors


static func _validate_camera(camera_value: Variant, definition: Dictionary, errors: Array[String]) -> void:
	if camera_value == null:
		return
	if not camera_value is Dictionary:
		errors.append("camera must be an object when provided")
		return
	var camera: Dictionary = camera_value
	for field in ["focus", "fill_position", "lantern_position"]:
		if camera.has(field) and not _number_vector(camera.get(field), 3):
			errors.append("camera.%s must contain three numbers" % field)
	if camera.has("yaw_degrees") and not _finite_number(camera.get("yaw_degrees")):
		errors.append("camera.yaw_degrees must be finite")
	if camera.has("cutaway_wall_id"):
		if not camera.get("cutaway_wall_id") is String:
			errors.append("camera.cutaway_wall_id must be a string")
		elif not String(camera.cutaway_wall_id).is_empty():
			var shell_value: Variant = definition.get("room_shell", null)
			var found := false
			if shell_value is Dictionary:
				var walls_value: Variant = shell_value.get("walls", null)
				if walls_value is Array:
					for wall_variant in walls_value:
						if wall_variant is Dictionary:
							var wall_id_value: Variant = wall_variant.get("id", null)
							if wall_id_value is String and String(wall_id_value) == String(camera.cutaway_wall_id):
								found = true
				if not found:
					errors.append("camera.cutaway_wall_id must reference a room_shell wall")


static func _validate_room_shell(shell_value: Variant, definition: Dictionary, errors: Array[String]) -> void:
	if not shell_value is Dictionary:
		errors.append("schema_version 2 requires room_shell object")
		return
	var shell: Dictionary = shell_value
	if shell.has("wall_thickness") and not _positive_number(shell.get("wall_thickness")):
		errors.append("room_shell.wall_thickness must be positive")
	if shell.has("baseboard_height") and (not _finite_number(shell.get("baseboard_height")) or float(shell.baseboard_height) < 0.0):
		errors.append("room_shell.baseboard_height must be nonnegative")
	elif shell.has("baseboard_height") and _positive_number(definition.get("wall_height")) and float(shell.baseboard_height) > float(definition.wall_height):
		errors.append("room_shell.baseboard_height must not exceed wall_height")
	if shell.has("baseboard_appearance"):
		_validate_appearance(shell.get("baseboard_appearance"), "room_shell.baseboard_appearance", errors)
	if shell.has("floor_appearance"):
		_validate_appearance(shell.get("floor_appearance"), "room_shell.floor_appearance", errors)
	if shell.has("ceiling_appearance"):
		_validate_appearance(shell.get("ceiling_appearance"), "room_shell.ceiling_appearance", errors)
	if shell.has("crown_molding_height") and (not _finite_number(shell.get("crown_molding_height")) or float(shell.crown_molding_height) < 0.0):
		errors.append("room_shell.crown_molding_height must be nonnegative")
	elif shell.has("crown_molding_height") and _positive_number(definition.get("wall_height")) and float(shell.crown_molding_height) > float(definition.wall_height):
		errors.append("room_shell.crown_molding_height must not exceed wall_height")
	if shell.has("crown_molding_appearance"):
		_validate_appearance(shell.get("crown_molding_appearance"), "room_shell.crown_molding_appearance", errors)
	var walls_value: Variant = shell.get("walls", null)
	if not walls_value is Array or walls_value.is_empty():
		errors.append("room_shell.walls must contain at least one wall")
		return
	var room_size_value: Variant = definition.get("dimensions", null)
	var room_size: Array = room_size_value if room_size_value is Array else []
	var wall_height_value: Variant = definition.get("wall_height", null)
	var wall_height := float(wall_height_value) if _positive_number(wall_height_value) else 0.0
	var seen_ids: Dictionary = {}
	var seen_sides: Dictionary = {}
	for wall_variant in walls_value:
		if not wall_variant is Dictionary:
			errors.append("each room_shell wall must be an object")
			continue
		var wall: Dictionary = wall_variant
		var wall_id_value: Variant = wall.get("id", null)
		var side_value: Variant = wall.get("side", null)
		var wall_id := String(wall_id_value).strip_edges() if wall_id_value is String else ""
		var side := String(side_value) if side_value is String else ""
		if wall_id.is_empty() or seen_ids.has(wall_id):
			errors.append("room_shell wall ids must be present and unique: %s" % wall_id)
		else:
			seen_ids[wall_id] = true
		if not WALL_SIDES.has(side):
			errors.append("room_shell wall %s side must be lowercase north, south, east, or west" % wall_id)
		elif seen_sides.has(side):
			errors.append("room_shell may define only one wall per side: %s" % side)
		else:
			seen_sides[side] = true
		if wall.has("appearance"):
			_validate_appearance(wall.get("appearance"), "room_shell wall %s appearance" % wall_id, errors)
		var openings_value: Variant = wall.get("openings", [])
		if not openings_value is Array:
			errors.append("room_shell wall %s openings must be an array" % wall_id)
			continue
		var side_length := 0.0
		if _positive_vector(room_size, 2):
			if side in ["north", "south"]:
				side_length = float(room_size[0])
			elif side in ["east", "west"]:
				side_length = float(room_size[1])
		var openings: Array = openings_value
		var intervals: Array[Vector2] = []
		for opening_variant in openings:
			if not opening_variant is Dictionary:
				errors.append("room_shell wall %s opening must be an object" % wall_id)
				continue
			var opening: Dictionary = opening_variant
			var opening_id_value: Variant = opening.get("id", null)
			var opening_kind_value: Variant = opening.get("kind", null)
			var opening_id := String(opening_id_value).strip_edges() if opening_id_value is String else ""
			var opening_kind := String(opening_kind_value) if opening_kind_value is String else ""
			if opening_id.is_empty() or seen_ids.has(opening_id):
				errors.append("room_shell IDs must be present and unique: %s" % opening_id)
			else:
				seen_ids[opening_id] = true
			if not OPENING_KINDS.has(opening_kind):
				errors.append("room_shell opening %s kind must be lowercase door, window, or opening" % opening_id)
			var offset_value: Variant = opening.get("offset", null)
			var width_value: Variant = opening.get("width", null)
			var bottom_value: Variant = opening.get("bottom", 0.0)
			var height_value: Variant = opening.get("height", null)
			if not _finite_number(offset_value) or float(offset_value) < 0.0:
				errors.append("room_shell opening %s offset must be nonnegative" % opening_id)
			if not _positive_number(width_value):
				errors.append("room_shell opening %s width must be positive" % opening_id)
			if not _finite_number(bottom_value) or float(bottom_value) < 0.0:
				errors.append("room_shell opening %s bottom must be nonnegative" % opening_id)
			if not _positive_number(height_value):
				errors.append("room_shell opening %s height must be positive" % opening_id)
			if _finite_number(offset_value) and _positive_number(width_value):
				if float(offset_value) + float(width_value) > side_length:
					errors.append("room_shell opening %s exceeds wall length" % opening_id)
				intervals.append(Vector2(float(offset_value), float(offset_value) + float(width_value)))
			if _finite_number(bottom_value) and _positive_number(height_value) and float(bottom_value) + float(height_value) > wall_height:
				errors.append("room_shell opening %s exceeds wall height" % opening_id)
			if opening_kind == "door" and _finite_number(bottom_value) and not is_equal_approx(float(bottom_value), 0.0):
				errors.append("room_shell door %s bottom must be zero" % opening_id)
			if opening.has("appearance"):
				_validate_appearance(opening.get("appearance"), "room_shell opening %s appearance" % opening_id, errors)
		for interval_index in range(intervals.size()):
			for other_index in range(interval_index + 1, intervals.size()):
				if intervals[interval_index].y > intervals[other_index].x and intervals[other_index].y > intervals[interval_index].x:
					errors.append("room_shell wall %s openings must not overlap" % wall_id)


static func _validate_appearance(value: Variant, label: String, errors: Array[String]) -> void:
	if not value is Dictionary:
		errors.append("%s must be an object" % label)
		return
	var appearance: Dictionary = value
	for field in ["base_color", "accent_color", "glass_color"]:
		if appearance.has(field) and not _valid_color(appearance.get(field)):
			errors.append("%s.%s must be a valid HTML color string" % [label, field])
	if appearance.has("archetype") and (not appearance.get("archetype") is String or String(appearance.archetype).strip_edges().is_empty()):
		errors.append("%s.archetype must be a nonempty string" % label)
	if appearance.has("material") and (not appearance.get("material") is String or not APPEARANCE_MATERIALS.has(String(appearance.material).to_lower())):
		errors.append("%s.material must be one of %s" % [label, ", ".join(APPEARANCE_MATERIALS)])
	if appearance.has("transparency") and (not _finite_number(appearance.get("transparency")) or float(appearance.transparency) < 0.0 or float(appearance.transparency) > 1.0):
		errors.append("%s.transparency must be between 0 and 1" % label)


static func validate_navigation(definition: Dictionary, floor_navigation: Node, surface_navigation: Node) -> Array[String]:
	var errors: Array[String] = []
	if not is_instance_valid(floor_navigation) or not is_instance_valid(surface_navigation):
		return ["navigation validators must be configured before runtime validation"]
	var spawn_value: Variant = definition.get("spawn", null)
	if not spawn_value is Dictionary:
		return ["spawn must be an object before navigation validation"]
	var spawn_center_value: Variant = spawn_value.get("center", null)
	if not _number_vector(spawn_center_value, 3):
		return ["spawn.center must contain three numbers before navigation validation"]
	var objects_value: Variant = definition.get("objects", [])
	if not objects_value is Array:
		return ["objects must be an array before navigation validation"]
	for object_variant in objects_value:
		if not object_variant is Dictionary:
			continue
		var object: Dictionary = object_variant
		if not object.has("surface") or not object.surface is Dictionary:
			continue
		var region_id_value: Variant = object.surface.get("region_id", null)
		if not region_id_value is String:
			continue
		var region_id := String(region_id_value)
		var usable_approaches := 0
		for approach in surface_navigation.investigation_candidates_for(region_id):
			if floor_navigation.is_obstacle_position(approach):
				continue
			if floor_navigation.path_between(vector3_from(spawn_center_value), approach).is_empty():
				continue
			usable_approaches += 1
		if usable_approaches < 2:
			errors.append("surface %s has fewer than two walkable, reachable approach points" % region_id)
	var construction_site: Dictionary = surface_navigation.derive_construction_site(floor_navigation)
	if not construction_site.get("valid", false):
		errors.append("no reachable traversal construction site can be derived: %s" % construction_site.get("reason", "unknown reason"))
	for object in definition.objects:
		if not object.get("resource_profile") is Dictionary or object.resource_profile.get("contents", {}).is_empty(): continue
		var region_id := String(object.resource_profile.get("region_id", "FLOOR"))
		var position := vector3_from(object.position)
		if region_id == "FLOOR":
			if not is_equal_approx(position.y, float(definition.floor.height)) or floor_navigation.is_obstacle_position(position) or floor_navigation.path_between(vector3_from(spawn_center_value), position).is_empty(): errors.append("resource source %s must have a clear reachable floor extraction point" % object.id)
		elif surface_navigation.regions.has(region_id):
			var region: Dictionary = surface_navigation.regions[region_id]
			var offset: Vector3 = position - region.center
			var local := offset.rotated(Vector3.UP, -deg_to_rad(float(region.rotation_degrees)))
			if not is_equal_approx(position.y, float(region.height)) or absf(local.x) > float(region.dimensions.x) * 0.5 or absf(local.z) > float(region.dimensions.y) * 0.5: errors.append("resource source %s extraction point must lie on its declared surface" % object.id)
	return errors


static func vector3_from(values: Array) -> Vector3:
	if values.size() < 3:
		return Vector3.ZERO
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


static func _valid_color(value: Variant) -> bool:
	return value is String and Color.html_is_valid(String(value))


static func _number_vector(value: Variant, size: int) -> bool:
	if not value is Array or value.size() != size:
		return false
	for item in value:
		if not _finite_number(item):
			return false
	return true


static func _nonnegative_vector(value: Variant, size: int) -> bool:
	if not _number_vector(value, size):
		return false
	for item in value:
		if float(item) < 0.0:
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


static func _safe_room_id(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9][A-Za-z0-9_-]*$")
	return pattern.search(value) != null


static func _inside_floor(position_value: Variant, center: Array, room_size: Array, margin: float = 1.0) -> bool:
	if not _number_vector(position_value, 3) or not _number_vector(center, 3) or not _positive_vector(room_size, 2):
		return false
	var position: Array = position_value
	return absf(float(position[0]) - float(center[0])) <= float(room_size[0]) * 0.5 - margin and absf(float(position[2]) - float(center[2])) <= float(room_size[1]) * 0.5 - margin
