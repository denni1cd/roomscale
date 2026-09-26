extends SceneTree

const RoomDefinitionLoader := preload("res://scripts/room_definition.gd")
const FloorNavigationController := preload("res://scripts/floor_navigation.gd")
const SurfaceNavigationController := preload("res://scripts/surface_navigation.gd")
const TaskCoordinatorController := preload("res://scripts/task_coordinator.gd")


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
		if surface_navigation.investigation_candidates().size() < 2:
			_fail("approach geometry discovery failed for %s" % room_id)
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
	print("ROOMSCALE_FAST_TEST_PASS rooms=2 parsing=verified malformed=12 obstacles=generated targets=discovered approaches=derived sites=reachable runtime_navigation=validated region_connectivity=verified task_history=%d/%d" % [history_fixture.tasks.size(), history_fixture.MAX_HISTORY])
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
