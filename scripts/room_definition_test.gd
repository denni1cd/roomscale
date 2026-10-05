extends SceneTree

const RoomDefinitionLoader := preload("res://scripts/room_definition.gd")
const FloorNavigationController := preload("res://scripts/floor_navigation.gd")
const SurfaceNavigationController := preload("res://scripts/surface_navigation.gd")
const TaskCoordinatorController := preload("res://scripts/task_coordinator.gd")
const PipelineProofController := preload("res://scripts/pipeline_proof.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var definitions: Array[Dictionary] = []
	for room_id in ["room_a", "room_b"]:
		var loaded: Dictionary = RoomDefinitionLoader.load_file("res://rooms/%s.json" % room_id)
		if not loaded.ok:
			_fail("%s parse/validation failed: %s" % [room_id, loaded.errors])
			return
		var definition: Dictionary = loaded.definition
		if String(definition.id) != room_id or definition.has("construction") and definition.construction.has("site"):
			_fail("room contract identity or derived-site boundary failed for %s" % room_id)
			return
		var target_object: Dictionary = {}
		for object_variant in definition.objects:
			var object: Dictionary = object_variant
			if object.has("surface") and String(object.surface.region_id) == String(definition.target_surface_id):
				target_object = object
				break
		if target_object.is_empty() or target_object.surface.has("approach_points"):
			_fail("%s must derive investigation points without required approach_points" % room_id)
			return
		definitions.append(definition)
		var navigation := FloorNavigationController.new()
		navigation.configure(definition)
		root.add_child(navigation)
		await process_frame
		var surface_navigation := SurfaceNavigationController.new()
		surface_navigation.configure(definition, navigation)
		root.add_child(surface_navigation)
		var runtime_errors: Array[String] = RoomDefinitionLoader.validate_navigation(definition, navigation, surface_navigation)
		if not runtime_errors.is_empty():
			_fail("runtime navigation validation failed for %s: %s" % [room_id, runtime_errors])
			return
		var goal := surface_navigation.goal_surface()
		if String(goal.object_id).is_empty() or goal.dimensions.x <= 0.0 or goal.dimensions.y <= 0.0:
			_fail("target discovery failed for %s" % room_id)
			return
		var candidates: Array[Vector3] = surface_navigation.investigation_candidates()
		if candidates.size() < 2:
			_fail("approach geometry discovery failed for %s" % room_id)
			return
		for candidate in candidates:
			if not navigation.room_bounds().has_point(Vector2(candidate.x, candidate.z)) or navigation.is_obstacle_position(candidate) or navigation.path_between(RoomDefinitionLoader.vector3_from(definition.spawn.center), candidate).is_empty():
				_fail("derived investigation candidate is invalid for %s: %s" % [room_id, candidate])
				return
		var derived_site: Dictionary = surface_navigation.derive_construction_site(navigation)
		if not derived_site.valid or navigation.is_obstacle_position(derived_site.position) or navigation.path_between(RoomDefinitionLoader.vector3_from(definition.construction.depot_pickup), derived_site.position).is_empty():
			_fail("dynamic construction site derivation failed for %s: %s" % [room_id, derived_site])
			return
		if surface_navigation.route_between("FLOOR", surface_navigation.goal_surface_id, Vector3.ZERO, goal.anchor).reachable:
			_fail("elevated surface was reachable before traversal deployment in %s" % room_id)
			return
		var route: Array[Vector3] = [derived_site.position, goal.anchor]
		if not surface_navigation.connect_regions("FLOOR", surface_navigation.goal_surface_id, route):
			_fail("generic navigation-region connection rejected valid geometry in %s" % room_id)
			return
		var connected: Dictionary = surface_navigation.route_between("FLOOR", surface_navigation.goal_surface_id, RoomDefinitionLoader.vector3_from(definition.construction.depot_pickup), goal.anchor)
		if not connected.reachable or connected.path.size() < 2:
			_fail("connected navigation graph did not expose the traversal route in %s" % room_id)
			return
		root.remove_child(surface_navigation)
		surface_navigation.free()
		root.remove_child(navigation)
		navigation.free()
	if definitions[0].dimensions == definitions[1].dimensions:
		_fail("room definitions are not materially different in scale")
		return
	var legacy_elevated_nonblocking: Dictionary = definitions[0].duplicate(true)
	for object_variant in legacy_elevated_nonblocking.objects:
		var object: Dictionary = object_variant
		if String(object.get("id", "")) == "rug":
			object.position[1] = 8.0
	if not RoomDefinitionLoader.validate(legacy_elevated_nonblocking).is_empty():
		_fail("legacy version 1 stopped accepting an elevated nonblocking object")
		return
	var malformed: Dictionary = definitions[0].duplicate(true)
	malformed.erase("id")
	if RoomDefinitionLoader.validate(malformed).is_empty():
		_fail("validator accepted a missing room identifier")
		return
	malformed = definitions[0].duplicate(true)
	malformed.dimensions = [-1, 0]
	if RoomDefinitionLoader.validate(malformed).is_empty():
		_fail("validator accepted malformed room dimensions")
		return
	malformed = definitions[0].duplicate(true)
	malformed.objects[0].position = [0, 1]
	if RoomDefinitionLoader.validate(malformed).is_empty():
		_fail("validator accepted a malformed object position")
		return
	malformed = definitions[0].duplicate(true)
	malformed.objects[0].surface.approach_points = [[0, 0, 0]]
	if RoomDefinitionLoader.validate(malformed).is_empty():
		_fail("validator accepted too few investigation points")
		return
	malformed = definitions[0].duplicate(true)
	malformed.construction.depot_pickup = [0, 0]
	if RoomDefinitionLoader.validate(malformed).is_empty():
		_fail("validator accepted a malformed depot pickup position")
		return
	malformed = definitions[0].duplicate(true)
	malformed.erase("floor")
	if not _expect_invalid(malformed, "floor requires"):
		return
	malformed = definitions[0].duplicate(true)
	malformed.target_surface_id = "UNKNOWN_SURFACE"
	if not _expect_invalid(malformed, "unknown navigable surface"):
		return
	malformed = definitions[0].duplicate(true)
	malformed.objects[1].id = malformed.objects[0].id
	if not _expect_invalid(malformed, "object ids must be present and unique"):
		return
	malformed = definitions[0].duplicate(true)
	malformed.objects[0].surface.anchor = [0, 30, 0]
	if not _expect_invalid(malformed, "anchor is outside the navigable surface bounds"):
		return
	malformed = definitions[0].duplicate(true)
	malformed.objects[0].surface.approach_points = [[500, 0, 0], [500, 0, 4]]
	if not _expect_invalid(malformed, "approach point lies outside the room floor"):
		return
	malformed = definitions[0].duplicate(true)
	var blocker_position: Array = malformed.objects[0].position
	malformed.objects[0].surface.approach_points = [blocker_position, blocker_position.duplicate(), blocker_position.duplicate()]
	if not _expect_invalid(malformed, "approach point is inside its blocking footprint"):
		return
	malformed = definitions[0].duplicate(true)
	malformed.floor.center = [0, 0]
	if not _expect_invalid(malformed, "floor requires"):
		return
	var v2_fixture := _make_v2_fixture(definitions[0])
	var v2_errors: Array[String] = RoomDefinitionLoader.validate(v2_fixture)
	if not v2_errors.is_empty():
		_fail("valid schema v2 fixture failed validation: %s" % v2_errors)
		return
	if not _write_and_load_candidate(v2_fixture):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.dimensions = ["bad", {"nested": []}]
	if not _expect_invalid(malformed, "dimensions must"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.walls = {"not": "an array"}
	if not _expect_invalid(malformed, "room_shell.walls must"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.floor_appearance = ["not", "an object"]
	if not _expect_invalid(malformed, "floor_appearance must be an object"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.ceiling_appearance = ["not", "an object"]
	if not _expect_invalid(malformed, "ceiling_appearance must be an object"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.crown_molding_height = {"bad": "number"}
	if not _expect_invalid(malformed, "crown_molding_height must be nonnegative"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.walls[0].openings[0].offset = {"bad": "number"}
	malformed.room_shell.walls[0].openings[0].appearance = {"base_color": ["bad"], "glass_color": ["bad"], "transparency": {"bad": 1}}
	if not _expect_invalid(malformed, "offset must be nonnegative") or not _expect_invalid(malformed, "base_color must be a valid") or not _expect_invalid(malformed, "glass_color must be a valid") or not _expect_invalid(malformed, "transparency must be between"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.walls[0].openings[1].exterior_scene = []
	if not _expect_invalid(malformed, "exterior_scene must be an object"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.walls[0].openings[1].exterior_scene = {"elements":[{"shape":"tree", "position":[0, 0, 12], "dimensions":[8, 16, 8]}]}
	if not _expect_invalid(malformed, "shape must be one of box, sphere, cylinder"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.walls[0].openings[1].exterior_scene = {"elements":[{"shape":"box", "position":[0, 0], "dimensions":[8, 0, 8]}]}
	if not _expect_invalid(malformed, "position must contain three finite numbers") or not _expect_invalid(malformed, "dimensions must contain three positive finite numbers"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.camera = {"fill_position": {"bad": "vector"}, "cutaway_wall_id": {"bad": "wall id"}}
	if not _expect_invalid(malformed, "camera.fill_position") or not _expect_invalid(malformed, "camera.cutaway_wall_id"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.walls[0].openings[1].offset = malformed.room_shell.walls[0].openings[0].offset
	malformed.room_shell.walls[0].openings[1].width = malformed.room_shell.walls[0].openings[0].width
	if not _expect_invalid(malformed, "openings must not overlap"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.walls[0].side = "North"
	if not _expect_invalid(malformed, "side must be lowercase"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.room_shell.walls[0].openings[0].kind = "WINDOW"
	if not _expect_invalid(malformed, "kind must be lowercase"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.objects[0].erase("blocks_navigation")
	if not _expect_invalid(malformed, "blocks_navigation must be a boolean"):
		return
	malformed = v2_fixture.duplicate(true)
	for object_variant in malformed.objects:
		var object: Dictionary = object_variant
		if String(object.id) == "rug":
			object.position[1] = 8.0
			object.blocks_navigation = true
	if not _expect_invalid(malformed, "blocking object rug base height"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.landmarks.depot = [500.0, 5.0, 0.0]
	if not _expect_invalid(malformed, "landmark depot lies outside"):
		return
	malformed = v2_fixture.duplicate(true)
	malformed.activity_stations.patrol[0] = [500.0, 5.0, 0.0]
	if not _expect_invalid(malformed, "activity station lies outside"):
		return
	if not await _verify_v2_geometry_and_renderer(v2_fixture):
		return
	var history_fixture := TaskCoordinatorController.new()
	history_fixture.configure_room(definitions[0])
	root.add_child(history_fixture)
	var first_task: Dictionary = history_fixture.create_construction_task({"task_type":"FAST_REGRESSION","target":Vector3.ZERO}, 0)
	history_fixture.supersede_task(int(first_task.id), "superseded cleanup fixture")
	for index in range(history_fixture.MAX_HISTORY):
		history_fixture.create_construction_task({"task_type":"FAST_REGRESSION","target":Vector3.ZERO}, index % 5)
	if history_fixture.tasks.size() != history_fixture.MAX_HISTORY:
		_fail("superseded tasks at the front prevented bounded history trimming")
		return
	var superseded_retained := false
	for task in history_fixture.tasks:
		if int(task.id) == int(first_task.id):
			superseded_retained = true
	if superseded_retained:
		_fail("superseded task was retained after overflow cleanup")
		return
	for index in range(history_fixture.MAX_HISTORY + 50):
		var task: Dictionary = history_fixture.create_construction_task({"task_type":"FAST_REGRESSION","target":Vector3.ZERO}, index % 5)
		history_fixture.cancel_task(int(task.id), "long-run cleanup fixture")
	if history_fixture.tasks.size() > history_fixture.MAX_HISTORY:
		_fail("task history exceeded its configured bound during long-run cancellation")
		return
	print("ROOMSCALE_FAST_TEST_PASS rooms=2 legacy_schema=verified schema_v2=verified malformed_cases=29 candidate_file=verified obstacles=generated rotated_bounds=verified rotated_approaches=verified elevated_floor=verified elevated_nonblocking_objects=verified room_shell_openings=verified exterior_scene=verified ceiling_crown=verified generic_appearance=verified targets=discovered sites=reachable runtime_navigation=validated region_connectivity=verified task_history=%d/%d" % [history_fixture.tasks.size(), history_fixture.MAX_HISTORY])
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_FAST_TEST_FAIL: " + message)
	quit(1)


func _expect_invalid(definition: Dictionary, expected_diagnostic: String) -> bool:
	var diagnostics: Array[String] = RoomDefinitionLoader.validate(definition)
	for diagnostic in diagnostics:
		if diagnostic.contains(expected_diagnostic):
			return true
	_fail("validator omitted diagnostic '%s': %s" % [expected_diagnostic, diagnostics])
	return false


func _make_v2_fixture(source: Dictionary) -> Dictionary:
	var fixture: Dictionary = source.duplicate(true)
	fixture["schema_version"] = 2
	fixture["id"] = "m2_fixture"
	var floor: Dictionary = fixture["floor"]
	floor["height"] = 5.0
	floor["center"] = [0.0, 5.0, 0.0]
	for object_variant in fixture["objects"]:
		var object: Dictionary = object_variant
		var position: Array = object["position"]
		position[1] = 5.0
		if String(object["id"]) == "rug":
			position[1] = 8.0
		if object.has("surface"):
			var surface: Dictionary = object["surface"]
			surface["height"] = 5.0 + float(object["dimensions"][1])
			var anchor: Array = surface["anchor"]
			anchor[1] = surface["height"]
			if String(object["id"]) == "desk":
				object["rotation_degrees"] = 15.0
				object["appearance"] = {"archetype":"workbench", "base_color":"81593e", "accent_color":"c2985c", "material":"wood"}
		if String(object["id"]) == "storage_box":
			object["appearance"] = {"archetype":"simple", "base_color":"a98254", "accent_color":"d5b47a", "material":"wood"}
	var construction: Dictionary = fixture["construction"]
	construction["depot_pickup"][1] = 5.0
	var landmarks: Dictionary = fixture["landmarks"]
	for key in landmarks.keys():
		landmarks[key][1] = 5.0
	var stations: Dictionary = fixture["activity_stations"]
	for key in ["workshop", "patrol"]:
		for point in stations[key]:
			point[1] = 5.0
	stations["housing"][1] = 5.0
	stations["work_area"][1] = 5.0
	fixture["spawn"]["center"][1] = 5.0
	fixture["camera"]["focus"][1] = 5.0
	fixture["camera"]["fill_position"][1] = 73.0
	fixture["camera"]["lantern_position"][1] = 15.0
	fixture["camera"]["cutaway_wall_id"] = "north-wall"
	fixture["room_shell"] = {
		"wall_thickness": 2.0,
		"baseboard_height": 3.0,
		"baseboard_appearance": {"base_color":"76583f", "material":"wood"},
		"ceiling_appearance": {"base_color":"38a6a1", "material":"paint"},
		"crown_molding_height": 4.0,
		"crown_molding_appearance": {"base_color":"b58650", "accent_color":"d5b77b", "material":"wood"},
		"floor_appearance": {"base_color":"795b43", "material":"wood"},
		"walls": [
			{"id":"north-wall", "side":"north", "appearance":{"base_color":"d9c9aa", "material":"paint"}, "openings":[
				{"id":"north-door", "kind":"door", "offset":70.0, "width":36.0, "bottom":0.0, "height":70.0, "appearance":{"archetype":"french_door", "base_color":"795b43", "accent_color":"c2985c", "glass_color":"9bbec8", "material":"wood", "transparency":0.48}},
				{"id":"north-window", "kind":"window", "offset":145.0, "width":40.0, "bottom":28.0, "height":32.0, "appearance":{"archetype":"transomed_window", "base_color":"9bbec8", "accent_color":"f1e8d4", "material":"glass", "transparency":0.36}}
			]},
			{"id":"south-wall", "side":"south", "appearance":{"base_color":"d4c4a8", "material":"paint"}},
			{"id":"east-wall", "side":"east", "appearance":{"base_color":"cfc2a7", "material":"paint"}},
			{"id":"west-wall", "side":"west", "appearance":{"base_color":"cfc2a7", "material":"paint"}, "openings":[
				{"id":"west-gap", "kind":"opening", "offset":60.0, "width":32.0, "bottom":1.0, "height":40.0}
			]}
		]
	}
	return fixture


func _write_and_load_candidate(fixture: Dictionary) -> bool:
	var relative_path := "res://verification/poc2/fixtures/m2_fixture.json"
	var absolute_path := ProjectSettings.globalize_path(relative_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		_fail("could not create deterministic project-local candidate fixture")
		return false
	file.store_string(JSON.stringify(fixture, "\t") + "\n")
	file.close()
	var previous_room_file := OS.get_environment("ROOMSCALE_ROOM_FILE")
	OS.set_environment("ROOMSCALE_ROOM_FILE", absolute_path)
	var loaded: Dictionary = RoomDefinitionLoader.load_requested()
	OS.set_environment("ROOMSCALE_ROOM_FILE", previous_room_file)
	if not loaded.get("ok", false) or String(loaded.get("definition", {}).get("id", "")) != "m2_fixture":
		_fail("arbitrary project-local candidate path did not load and validate: %s" % loaded.get("errors", []))
		return false
	OS.set_environment("ROOMSCALE_ROOM_FILE", ProjectSettings.globalize_path("res://../outside.json"))
	var escaped: Dictionary = RoomDefinitionLoader.load_requested()
	OS.set_environment("ROOMSCALE_ROOM_FILE", previous_room_file)
	if escaped.get("ok", false) or not str(escaped.get("errors", [])).contains("inside the project"):
		_fail("candidate loader accepted a path outside the project")
		return false
	return true


func _verify_v2_geometry_and_renderer(fixture: Dictionary) -> bool:
	var desk: Dictionary = {}
	var simple_object: Dictionary = {}
	for object_variant in fixture.objects:
		var object: Dictionary = object_variant
		if String(object.id) == "desk":
			desk = object
		elif String(object.id) == "storage_box":
			simple_object = object
	if desk.is_empty() or simple_object.is_empty():
		_fail("schema v2 regression fixture lost required generic objects")
		return false
	var navigation := FloorNavigationController.new()
	navigation.configure(fixture)
	root.add_child(navigation)
	await process_frame
	var surface_navigation := SurfaceNavigationController.new()
	surface_navigation.configure(fixture, navigation)
	root.add_child(surface_navigation)
	var nameless_fixture: Dictionary = fixture.duplicate(true)
	for object_variant in nameless_fixture.objects:
		var object: Dictionary = object_variant
		if String(object.get("id", "")) == "desk":
			object.erase("name")
	if not RoomDefinitionLoader.validate(nameless_fixture).is_empty():
		_fail("optional object name was rejected by the RoomDefinition contract")
		return false
	surface_navigation.configure(nameless_fixture, navigation)
	if String(surface_navigation.goal_surface().get("object_name", "")) != "desk":
		_fail("surface navigation did not use the object ID when optional name is absent")
		return false
	surface_navigation.configure(fixture, navigation)
	var navigation_errors: Array[String] = RoomDefinitionLoader.validate_navigation(fixture, navigation, surface_navigation)
	if not navigation_errors.is_empty():
		_fail("schema v2 rotated/elevated navigation failed: %s" % [navigation_errors])
		return false
	var desk_rect: Dictionary = {}
	for rect_variant in navigation.obstacle_rects:
		var rect: Dictionary = rect_variant
		if String(rect.reason) == "desk":
			desk_rect = rect
			break
	var dimensions: Array = desk.dimensions
	var padding: Array = desk.navigation_padding
	var angle := deg_to_rad(float(desk.rotation_degrees))
	var local_half_x := float(dimensions[0]) * 0.5 + float(padding[0])
	var local_half_z := float(dimensions[2]) * 0.5 + float(padding[2])
	var expected_half := Vector2(absf(cos(angle)) * local_half_x + absf(sin(angle)) * local_half_z, absf(sin(angle)) * local_half_x + absf(cos(angle)) * local_half_z)
	var actual_half: Vector2 = desk_rect.get("half", Vector2.ZERO)
	if desk_rect.is_empty() or not actual_half.is_equal_approx(expected_half):
		_fail("floor navigation does not use rotated local extents and padding")
		return false
	var candidates: Array[Vector3] = surface_navigation.investigation_candidates()
	var candidate_has_rotated_offset := false
	var desk_position: Array = desk.position
	for candidate in candidates:
		var delta_x := candidate.x - float(desk_position[0])
		var delta_z := candidate.z - float(desk_position[2])
		if absf(delta_x) > 1.0 and absf(delta_z) > 1.0 and is_equal_approx(candidate.y, 5.0):
			candidate_has_rotated_offset = true
	if candidates.size() < 2 or not candidate_has_rotated_offset:
		_fail("rotated surface exploration candidates were not generated on the floor plane")
		return false
	var exploration: Array[Vector3] = surface_navigation.exploration_route(RoomDefinitionLoader.vector3_from(desk.surface.anchor), String(fixture.target_surface_id))
	if exploration.size() < 6 or not is_equal_approx(exploration[1].y, float(desk.surface.height)) or absf(exploration[1].x - float(desk_position[0])) < 1.0 or absf(exploration[1].z - float(desk_position[2])) < 1.0:
		_fail("elevated exploration route does not respect the rotated local surface frame")
		return false
	var derived_site: Dictionary = surface_navigation.derive_construction_site(navigation)
	if not derived_site.get("valid", false) or not is_equal_approx(derived_site.position.y, 5.0):
		_fail("nonzero floor elevation was not preserved in the derived construction site")
		return false
	var renderer := PipelineProofController.new()
	renderer.set("_room_definition", fixture)
	renderer.call("_build_room")
	var room := renderer.get_node_or_null("Room") as Node3D
	if room == null or room.get_node_or_null("ShellWall_north-wall") == null or room.get_node_or_null("ShellWall_west-wall") == null:
		_fail("generic room-shell renderer did not build selected wall runs")
		return false
	var ceiling := room.get_node_or_null("Ceiling") as MeshInstance3D
	if ceiling == null or not ceiling.mesh is PlaneMesh:
		_fail("version 2 ceiling appearance did not create a generic ceiling plane")
		return false
	var crown_segment_count := 0
	for wall_variant in room.get_children():
		if not wall_variant is Node3D or not String(wall_variant.name).begins_with("ShellWall_"):
			continue
		for visual_variant in wall_variant.get_children():
			if String(visual_variant.name).begins_with("Crown_"):
				crown_segment_count += 1
	if crown_segment_count < 4:
		_fail("generic crown molding renderer omitted version 2 wall trim")
		return false
	var room_center := RoomDefinitionLoader.vector3_from(fixture.floor.center)
	var room_dimensions: Array = fixture.dimensions
	var shell_wall_thickness := float(fixture.room_shell.wall_thickness)
	var crown_sides_verified: Array[String] = []
	for side in ["north", "south", "east", "west"]:
		var wall_node := room.get_node_or_null("ShellWall_%s-wall" % side) as Node3D
		if wall_node == null:
			continue
		var inside_normal := Vector3.ZERO
		var inside_face := 0.0
		match side:
			"north":
				inside_normal = Vector3(0.0, 0.0, 1.0)
				inside_face = room_center.z - float(room_dimensions[1]) * 0.5 + shell_wall_thickness * 0.5
			"south":
				inside_normal = Vector3(0.0, 0.0, -1.0)
				inside_face = -(room_center.z + float(room_dimensions[1]) * 0.5 - shell_wall_thickness * 0.5)
			"east":
				inside_normal = Vector3(-1.0, 0.0, 0.0)
				inside_face = -(room_center.x + float(room_dimensions[0]) * 0.5 - shell_wall_thickness * 0.5)
			"west":
				inside_normal = Vector3(1.0, 0.0, 0.0)
				inside_face = room_center.x - float(room_dimensions[0]) * 0.5 + shell_wall_thickness * 0.5
		for visual_variant in wall_node.get_children():
			if visual_variant is CollisionObject3D:
				_fail("generic room-shell crown may not add collision objects")
				return false
			if not visual_variant is MeshInstance3D or not String(visual_variant.name).begins_with("Crown_") or not visual_variant.mesh is BoxMesh:
				continue
			var crown_mesh: MeshInstance3D = visual_variant
			var crown_box := crown_mesh.mesh as BoxMesh
			var normal_depth := crown_box.size.z if side in ["north", "south"] else crown_box.size.x
			var interior_extent := crown_mesh.position.dot(inside_normal) + normal_depth * 0.5
			if interior_extent - inside_face >= 0.74:
				crown_sides_verified.append(side)
				break
	if crown_sides_verified.size() != 4:
		_fail("crown molding must project at least 0.74 inches beyond every interior wall face and remain visual-only; sides=%s" % [crown_sides_verified])
		return false
	var empty_ceiling_fixture: Dictionary = fixture.duplicate(true)
	empty_ceiling_fixture.room_shell.ceiling_appearance = {}
	var empty_ceiling_renderer := PipelineProofController.new()
	empty_ceiling_renderer.set("_room_definition", empty_ceiling_fixture)
	empty_ceiling_renderer.call("_build_room")
	var empty_ceiling_room := empty_ceiling_renderer.get_node_or_null("Room") as Node3D
	var default_ceiling := empty_ceiling_room.get_node_or_null("Ceiling") as MeshInstance3D if empty_ceiling_room != null else null
	var default_ceiling_material := default_ceiling.material_override as StandardMaterial3D if default_ceiling != null else null
	if default_ceiling == null or not default_ceiling.mesh is PlaneMesh or default_ceiling_material == null or not default_ceiling_material.albedo_color.is_equal_approx(Color("ece5d4")):
		_fail("present empty ceiling appearance must render with the documented generic ceiling defaults")
		return false
	empty_ceiling_renderer.free()
	var north_opening_names: Array[String] = []
	for opening_visual in room.get_node("ShellWall_north-wall").get_children():
		north_opening_names.append(String(opening_visual.name))
	if room.get_node_or_null("ShellWall_north-wall/FrenchDoorGlass_north-door") == null or room.get_node_or_null("ShellWall_north-wall/WindowPane_north-window") == null or room.get_node_or_null("ShellWall_north-wall/FrenchDoorMuntinH_north-door_0_34") == null or room.get_node_or_null("ShellWall_north-wall/WindowMuntinV_north-window") == null:
		_fail("styled door/window geometry missing; north wall nodes=%s" % [north_opening_names])
		return false
	for side in ["north", "south", "east", "west"]:
		var shell_wall := room.get_node_or_null("ShellWall_%s-wall" % side) as Node3D
		if shell_wall == null:
			continue
		for visual_variant in shell_wall.get_children():
			var node_name := String(visual_variant.name)
			if node_name.begins_with("ExteriorDeck_") or node_name.begins_with("PorchRail") or node_name.begins_with("ExteriorTree") or node_name.begins_with("ExteriorGreenery_") or node_name.begins_with("ExteriorSceneElement_"):
				_fail("ordinary window acquired undeclared exterior scenery: %s" % node_name)
				return false
	var explicit_exterior_fixture: Dictionary = fixture.duplicate(true)
	explicit_exterior_fixture.room_shell.walls[0].openings[1].exterior_scene = {"elements":[
		{"shape":"box", "position":[0, 0, 12], "dimensions":[10, 8, 2], "appearance":{"base_color":"cc3322", "material":"paint"}},
		{"shape":"sphere", "position":[0, 8, 20], "dimensions":[4, 4, 4], "appearance":{"base_color":"22aa55", "material":"plant"}}
	]}
	if not RoomDefinitionLoader.validate(explicit_exterior_fixture).is_empty():
		_fail("valid explicit exterior scene was rejected by validation")
		return false
	var explicit_exterior_renderer := PipelineProofController.new()
	explicit_exterior_renderer.set("_room_definition", explicit_exterior_fixture)
	explicit_exterior_renderer.call("_build_room")
	var explicit_exterior_wall := explicit_exterior_renderer.get_node_or_null("Room/ShellWall_north-wall") as Node3D
	var exterior_elements: Array[MeshInstance3D] = []
	if explicit_exterior_wall != null:
		for visual_variant in explicit_exterior_wall.get_children():
			if String(visual_variant.name).begins_with("ExteriorSceneElement_") and visual_variant is MeshInstance3D:
				exterior_elements.append(visual_variant as MeshInstance3D)
	if exterior_elements.size() != 2:
		_fail("explicit exterior scene should render exactly the two declared shapes; found %d" % exterior_elements.size())
		return false
	var explicit_box := exterior_elements[0] if exterior_elements[0].mesh is BoxMesh else exterior_elements[1]
	var explicit_sphere := exterior_elements[0] if exterior_elements[0].mesh is SphereMesh else exterior_elements[1]
	var explicit_floor_center := RoomDefinitionLoader.vector3_from(explicit_exterior_fixture.floor.center)
	var explicit_room_dimensions: Array = explicit_exterior_fixture.dimensions
	var explicit_window: Dictionary = explicit_exterior_fixture.room_shell.walls[0].openings[1]
	var explicit_origin := Vector3(explicit_floor_center.x - float(explicit_room_dimensions[0]) * 0.5 + float(explicit_window.offset) + float(explicit_window.width) * 0.5, float(explicit_exterior_fixture.floor.height) + float(explicit_window.bottom) + float(explicit_window.height) * 0.5, explicit_floor_center.z - float(explicit_room_dimensions[1]) * 0.5 - float(explicit_exterior_fixture.room_shell.wall_thickness) * 0.5)
	if not explicit_box.mesh is BoxMesh or not explicit_sphere.mesh is SphereMesh or not explicit_box.position.is_equal_approx(explicit_origin + Vector3(0.0, 0.0, -12.0)) or not explicit_sphere.position.is_equal_approx(explicit_origin + Vector3(0.0, 8.0, -20.0)):
		_fail("explicit exterior scene shapes did not follow opening-relative axes and dimensions")
		return false
	explicit_exterior_renderer.free()
	var window_muntin := room.get_node("ShellWall_north-wall/WindowMuntinV_north-window") as MeshInstance3D
	var window_frame_material := window_muntin.material_override as StandardMaterial3D if window_muntin != null else null
	if window_frame_material == null or window_frame_material.albedo_color.a < 0.99:
		_fail("wood window muntins inherited transparency from their glass appearance")
		return false
	var west_wall := room.get_node("ShellWall_west-wall") as Node3D
	var gap_center := Vector3(-120.0, 5.0 + 1.0 + 20.0, -90.0 + 60.0 + 16.0)
	for visual_variant in west_wall.get_children():
		if not visual_variant is MeshInstance3D or not visual_variant.mesh is BoxMesh:
			continue
		var visual: MeshInstance3D = visual_variant
		var box := visual.mesh as BoxMesh
		if box == null:
			continue
		var center: Vector3 = visual.position
		if absf(gap_center.x - center.x) <= box.size.x * 0.5 and absf(gap_center.y - center.y) <= box.size.y * 0.5 and absf(gap_center.z - center.z) <= box.size.z * 0.5:
			_fail("clear room-shell opening was covered by an opaque wall segment")
			return false
	var opening_start_z := -90.0 + 60.0
	var opening_end_z := opening_start_z + 32.0
	for visual_variant in west_wall.get_children():
		if not visual_variant is MeshInstance3D or not String(visual_variant.name).begins_with("Trim_"):
			continue
		var trim_visual: MeshInstance3D = visual_variant
		var trim_box := trim_visual.mesh as BoxMesh
		if trim_box == null:
			continue
		var trim_start_z := trim_visual.position.z - trim_box.size.z * 0.5
		var trim_end_z := trim_visual.position.z + trim_box.size.z * 0.5
		if trim_start_z < opening_end_z and trim_end_z > opening_start_z:
			_fail("baseboard crossed a wall opening beginning below the trim height")
			return false
	if renderer.get("_cutaway_wall_group") != room.get_node("ShellWall_north-wall"):
		_fail("camera cutaway selector did not resolve the generic wall ID")
		return false
	var carpet_fixture: Dictionary = fixture.duplicate(true)
	carpet_fixture.room_shell.floor_appearance = {"base_color":"8d887f", "material":"fabric"}
	var carpet_renderer := PipelineProofController.new()
	carpet_renderer.set("_room_definition", carpet_fixture)
	carpet_renderer.call("_build_room")
	var carpet_room := carpet_renderer.get_node_or_null("Room") as Node3D
	for visual_variant in carpet_room.get_children():
		if String(visual_variant.name).begins_with("FloorSeam"):
			_fail("fabric carpet renderer added wood plank seams")
			return false
	carpet_renderer.free()
	var object_renderer := PipelineProofController.new()
	object_renderer.set("_room_definition", fixture)
	var object_parent := Node3D.new()
	object_renderer.add_child(object_parent)
	object_renderer.call("_build_room_object", object_parent, desk)
	var desk_node := object_parent.get_node_or_null("desk")
	var surface_body := desk_node.get_node_or_null("GoalSurfaceCollider") if desk_node != null else null
	var collider: CollisionShape3D
	if surface_body != null:
		for child in surface_body.get_children():
			if child is CollisionShape3D:
				collider = child
				break
	if collider == null:
		_fail("production furniture builder omitted elevated target collider; object keys=%s body_children=%s" % [desk.keys(), surface_body.get_children() if surface_body != null else []])
		return false
	var collider_box := collider.shape as BoxShape3D
	if not is_equal_approx(float(desk.position[1]) + collider.position.y + collider_box.size.y * 0.5, float(desk.surface.height)):
		_fail("elevated target collider double-counted the nonzero object-base elevation")
		return false
	object_renderer.call("_build_room_object", object_parent, simple_object)
	var generic_box := object_parent.get_node_or_null("storage_box/ObjectBody")
	if generic_box == null or object_parent.get_node_or_null("storage_box/ObjectLid") != null:
		_fail("generic unknown semantic kind did not use its documented simple archetype")
		return false
	var hammock_fixture := {"id":"visual_hammock_test", "kind":"hammock", "position":[0, 0, 0], "dimensions":[48, 30, 24], "appearance":{"archetype":"hammock", "base_color":"a9a59a", "accent_color":"343739", "material":"fabric"}}
	object_renderer.call("_build_room_object", object_parent, hammock_fixture)
	var hammock_visual := object_parent.get_node_or_null("visual_hammock_test")
	var hammock_frame_found := false
	if hammock_visual != null:
		for visual_variant in hammock_visual.get_children():
			if String(visual_variant.name).begins_with("HammockAFrame_"):
				hammock_frame_found = true
	if hammock_visual == null or hammock_visual.get_node_or_null("HammockFabricStripe_0") == null or not hammock_frame_found:
		_fail("hammock renderer omitted striped suspended fabric or its freestanding frame")
		return false
	var rocker_fixture := {"id":"visual_rocker_test", "kind":"rocking_chair", "position":[0, 0, 0], "dimensions":[26, 38, 32], "appearance":{"archetype":"rocking_chair", "base_color":"754629", "accent_color":"493023", "material":"wood"}}
	object_renderer.call("_build_room_object", object_parent, rocker_fixture)
	var rocker_visual := object_parent.get_node_or_null("visual_rocker_test")
	var rocker_runner_found := false
	if rocker_visual != null:
		for visual_variant in rocker_visual.get_children():
			if String(visual_variant.name).begins_with("Rocker_"):
				rocker_runner_found = true
	if rocker_visual == null or not rocker_runner_found or rocker_visual.get_node_or_null("BackSlat_1") == null:
		_fail("rocking chair renderer omitted curved runners or back slats")
		return false
	var cabinet_fixture := {"id":"visual_display_test", "kind":"display_cabinet", "position":[0, 0, 0], "dimensions":[34, 76, 20], "appearance":{"archetype":"display_cabinet", "base_color":"ad733c", "accent_color":"4b5045", "material":"wood", "transparency":0.66}}
	object_renderer.call("_build_room_object", object_parent, cabinet_fixture)
	var display_visual := object_parent.get_node_or_null("visual_display_test")
	var glass_pane_found := false
	if display_visual != null:
		for visual_variant in display_visual.get_children():
			if String(visual_variant.name).begins_with("DisplayGlass_"):
				glass_pane_found = true
	if display_visual == null or not glass_pane_found or display_visual.get_node_or_null("DisplayShelf_2") == null:
		_fail("display cabinet renderer omitted glass frontage or interior shelves")
		return false
	for cabinet_part in display_visual.get_children():
		if String(cabinet_part.name).begins_with("CabinetCollectible_"):
			_fail("display cabinet renderer added undeclared items above the cabinet")
			return false
	var cabinet_frame_material: StandardMaterial3D
	for cabinet_part in display_visual.get_children():
		if String(cabinet_part.name).begins_with("CabinetSide_"):
			var cabinet_mesh := cabinet_part as MeshInstance3D
			cabinet_frame_material = cabinet_mesh.material_override as StandardMaterial3D if cabinet_mesh != null else null
			break
	var cabinet_glass_material: StandardMaterial3D
	for cabinet_part in display_visual.get_children():
		if String(cabinet_part.name).begins_with("DisplayGlass_"):
			var cabinet_mesh := cabinet_part as MeshInstance3D
			cabinet_glass_material = cabinet_mesh.material_override as StandardMaterial3D if cabinet_mesh != null else null
			break
	if cabinet_frame_material == null or cabinet_frame_material.albedo_color.a < 0.99 or cabinet_glass_material == null or cabinet_glass_material.albedo_color.a >= 0.99:
		_fail("display cabinet should keep its wood frame opaque while its glass remains translucent")
		return false
	var seat_fixture := {"id":"visual_floor_seat_test", "kind":"floor_seat", "position":[0, 0, 0], "dimensions":[24, 12, 22], "appearance":{"archetype":"floor_seat", "base_color":"73da53", "accent_color":"202b2b", "material":"plastic"}}
	object_renderer.call("_build_room_object", object_parent, seat_fixture)
	var seat_visual := object_parent.get_node_or_null("visual_floor_seat_test")
	if seat_visual == null or seat_visual.get_node_or_null("ShallowScoop") == null:
		_fail("saucer-style floor seat renderer omitted its shallow scoop")
		return false
	var blanket_fixture := {"id":"visual_blanket_pile_test", "kind":"blanket", "position":[0, 0, 0], "dimensions":[34, 5, 18], "appearance":{"archetype":"blanket_pile", "base_color":"74b829", "accent_color":"397566", "material":"fabric"}}
	object_renderer.call("_build_room_object", object_parent, blanket_fixture)
	var blanket_visual := object_parent.get_node_or_null("visual_blanket_pile_test")
	if blanket_visual == null or blanket_visual.get_node_or_null("BlanketFold_0") == null or blanket_visual.get_node_or_null("BlanketMound_0") == null:
		_fail("blanket pile renderer omitted its folded cloth surface or soft mound")
		return false
	var collectibles_fixture := {"id":"visual_collectibles_test", "kind":"boxed_collectibles", "position":[0, 0, 0], "dimensions":[16, 8, 29], "appearance":{"archetype":"boxed_collectibles", "base_color":"d8d1c1", "accent_color":"51463c", "material":"other"}}
	object_renderer.call("_build_room_object", object_parent, collectibles_fixture)
	var collectibles_visual := object_parent.get_node_or_null("visual_collectibles_test")
	if collectibles_visual == null or collectibles_visual.get_node_or_null("CollectibleBox_0_0") == null:
		_fail("display-top collectibles renderer omitted its individual boxes")
		return false
	var art_fixture := {"id":"visual_triptych_art_test", "kind":"wall_art", "position":[0, 0, 0], "dimensions":[65, 30, 1], "appearance":{"archetype":"triptych_art", "base_color":"9a9478", "accent_color":"514c42", "material":"other"}}
	object_renderer.call("_build_room_object", object_parent, art_fixture)
	var art_visual := object_parent.get_node_or_null("visual_triptych_art_test")
	if art_visual == null or art_visual.get_node_or_null("TriptychTriangle_0") == null or art_visual.get_node_or_null("ArtPanel_2") == null:
		_fail("generic triptych renderer omitted its panel composition or abstract shapes")
		return false
	for index in range(3):
		var triangle := art_visual.get_node("TriptychTriangle_%d" % index) as MeshInstance3D
		var bounds := triangle.mesh.get_aabb()
		if bounds.position.x < -32.5 or bounds.end.x > 32.5:
			_fail("triptych motif extends beyond the authored frame bounds")
			return false
		var circle := art_visual.get_node("TriptychCircle_%d" % index) as MeshInstance3D
		var panel := art_visual.get_node("ArtPanel_%d" % index) as MeshInstance3D
		if absf(circle.position.x - panel.position.x) > 65.0 / 6.0:
			_fail("triptych motif is not within its corresponding panel")
			return false
	var emblem_fixture := {"id":"visual_wall_emblem_test", "kind":"wall_decoration", "position":[0, 0, 0], "dimensions":[14, 14, 1], "appearance":{"archetype":"wall_emblem", "base_color":"bec5bd", "accent_color":"666a66", "material":"metal"}}
	object_renderer.call("_build_room_object", object_parent, emblem_fixture)
	var emblem_visual := object_parent.get_node_or_null("visual_wall_emblem_test")
	if emblem_visual == null or emblem_visual.get_node_or_null("EmblemRay_0") == null or emblem_visual.get_node_or_null("EmblemCenter") == null:
		_fail("generic wall emblem renderer omitted its radial geometry")
		return false
	var bookcase_fixture := {"id":"visual_built_in_test", "kind":"bookcase", "position":[0, 0, 0], "dimensions":[94, 101, 22], "appearance":{"archetype":"built_in_bookcase", "base_color":"785638", "accent_color":"50351f", "material":"wood"}}
	object_renderer.call("_build_room_object", object_parent, bookcase_fixture)
	var built_in_visual := object_parent.get_node_or_null("visual_built_in_test")
	if built_in_visual == null or built_in_visual.get_node_or_null("BuiltInCabinetDoor_0") == null or built_in_visual.get_node_or_null("BuiltInShelf_3") == null or built_in_visual.get_node_or_null("Book_2_4") == null:
		_fail("built-in bookcase renderer omitted lower cabinets, shelves, or shelf contents")
		return false
	var fireplace_fixture := {"id":"visual_stone_hearth_test", "kind":"fireplace", "position":[0, 0, 0], "dimensions":[82, 86, 24], "appearance":{"archetype":"stone_fireplace", "base_color":"57534d", "accent_color":"8e8069", "material":"stone"}}
	object_renderer.call("_build_room_object", object_parent, fireplace_fixture)
	var fireplace_visual := object_parent.get_node_or_null("visual_stone_hearth_test")
	var fireplace_stone_found := false
	if fireplace_visual != null:
		for fireplace_part in fireplace_visual.get_children():
			if String(fireplace_part.name).begins_with("SideStone_"):
				fireplace_stone_found = true
	if fireplace_visual == null or fireplace_visual.get_node_or_null("FireboxRecess") == null or not fireplace_stone_found or fireplace_visual.get_node_or_null("WoodMantel") == null:
		_fail("stone fireplace renderer omitted its recess, masonry surround, or mantel")
		return false
	var table_fixture := {"id":"visual_octagonal_glass_table_test", "kind":"coffee_table", "position":[0, 0, 0], "dimensions":[84, 19, 66], "appearance":{"archetype":"octagonal_glass_table", "base_color":"9a9082", "accent_color":"3c271a", "material":"wood", "transparency":0.22}}
	object_renderer.call("_build_room_object", object_parent, table_fixture)
	var table_visual := object_parent.get_node_or_null("visual_octagonal_glass_table_test")
	var table_rim := table_visual.get_node_or_null("OctagonalWoodRim_0") as MeshInstance3D if table_visual != null else null
	var table_rim_material := table_rim.material_override as StandardMaterial3D if table_rim != null else null
	var table_leg_found := false
	if table_visual != null:
		for table_part in table_visual.get_children():
			if String(table_part.name).begins_with("SplayedWoodLeg_"):
				table_leg_found = true
				break
	if table_visual == null or table_visual.get_node_or_null("OctagonalGlassInset") == null or not table_leg_found or table_rim_material == null or table_rim_material.albedo_color.a < 0.99:
		_fail("glass coffee table renderer omitted octagonal glass/supports or made its wood frame transparent")
		return false
	var opening_fixture: Dictionary = fixture.duplicate(true)
	opening_fixture.room_shell.walls[0].openings[0].appearance.archetype = "sliding_glass_door"
	opening_fixture.room_shell.walls[0].openings[1].appearance.archetype = "shaded_window"
	var opening_renderer := PipelineProofController.new()
	opening_renderer.set("_room_definition", opening_fixture)
	opening_renderer.call("_build_room")
	var opening_wall := opening_renderer.get_node_or_null("Room/ShellWall_north-wall") as Node3D
	if opening_wall == null or opening_wall.get_node_or_null("SlidingDoorGlass_north-door") == null or opening_wall.get_node_or_null("SlidingDoorStile_north-door") == null or opening_wall.get_node_or_null("RollerShade_north-window") == null or opening_wall.get_node_or_null("ShadeFold_north-window_1") == null:
		_fail("renderer omitted generic shaded-window or sliding-glass-door detail")
		return false
	opening_renderer.free()
	object_renderer.free()
	renderer.free()
	root.remove_child(surface_navigation)
	surface_navigation.free()
	root.remove_child(navigation)
	navigation.free()
	return true
