extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/pipeline_proof.tscn") as PackedScene
	if packed == null:
		_fail("could not load the authored 3D scene")
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("main scene did not instantiate as Node3D")
		return
	root.add_child(scene)
	await process_frame
	var required_nodes := [
		"Room/Floor", "Room/WallBack", "Room/WallLeft", "Room/WallRight",
		"Furniture/Desk/DeskTop", "Furniture/Chair/ChairSeat", "Furniture/Bookcase",
		"Furniture/Rug", "Furniture/SideTable", "Props/StorageBox",
		"Settlement/Workshop", "Settlement/Depot", "Settlement/Housing", "Settlement/WorkArea",
		"FloorNavigation", "TaskCoordinator", "Citizen01", "Citizen50",
		"CameraRig/Camera", "KeyLight", "WorldEnvironment", "Overlay/Controls", "Overlay/CameraMode"
	]
	for node_path in required_nodes:
		if scene.get_node_or_null(NodePath(node_path)) == null:
			_fail("missing code-authored room/camera node: %s" % node_path)
			return
	var floor := scene.get_node("Room/Floor") as MeshInstance3D
	if (floor.mesh as BoxMesh).size != Vector3(240.0, 1.0, 180.0):
		_fail("room floor dimensions are not 240 x 180 inches")
		return
	var desk_top := scene.get_node("Furniture/Desk/DeskTop") as MeshInstance3D
	if not is_equal_approx(desk_top.position.y + (desk_top.mesh as BoxMesh).size.y * 0.5, 30.0):
		_fail("desk surface is not at the planned 30-inch height")
		return
	var chair_seat := scene.get_node("Furniture/Chair/ChairSeat") as MeshInstance3D
	if not is_equal_approx(chair_seat.position.y + (chair_seat.mesh as BoxMesh).size.y * 0.5, 18.0):
		_fail("chair seat is not at the planned 18-inch height")
		return
	var camera_rig := scene.get_node("CameraRig")
	if not camera_rig.has_method("set_view_mode") or not camera_rig.has_method("orbit_by") or not camera_rig.has_method("pan_by") or not camera_rig.has_method("zoom_by"):
		_fail("strategy camera does not expose all navigation controls")
		return
	camera_rig.set_view_mode(0)
	var room_distance: float = camera_rig.distance
	camera_rig.set_view_mode(1)
	var settlement_distance: float = camera_rig.distance
	camera_rig.set_view_mode(2)
	var citizen_distance: float = camera_rig.distance
	if not (room_distance > settlement_distance and settlement_distance > citizen_distance):
		_fail("room/settlement/citizen presets do not zoom progressively")
		return
	var initial_yaw: float = camera_rig.yaw
	var initial_tilt: float = camera_rig.tilt_degrees
	var initial_target: Vector3 = camera_rig.target
	camera_rig.orbit_by(Vector2(20.0, 12.0))
	if is_equal_approx(camera_rig.yaw, initial_yaw) or is_equal_approx(camera_rig.tilt_degrees, initial_tilt):
		_fail("orbit input did not change yaw and tilt")
		return
	camera_rig.pan_by(Vector2(12.0, -8.0))
	if camera_rig.target.is_equal_approx(initial_target):
		_fail("pan input did not change the camera target")
		return
	camera_rig.zoom_by(1.1)
	if camera_rig.distance <= citizen_distance:
		_fail("zoom input did not change camera distance")
		return
	var citizen_count := 0
	var distinct_citizens: Dictionary = {}
	for child in scene.get_children():
		if child.name.begins_with("Citizen"):
			citizen_count += 1
			distinct_citizens[child.get_instance_id()] = true
	if citizen_count != 50 or distinct_citizens.size() != 50:
		_fail("expected exactly 50 separate citizen nodes, found %d" % citizen_count)
		return
	var first_citizen := scene.get_node("Citizen01")
	var figure := first_citizen.get_node("Figure")
	if not is_equal_approx(float(figure.get_meta("body_height_inches")), 0.5):
		_fail("citizen procedural figure is not 0.5 inches tall")
		return
	var coordinator := scene.get_node("TaskCoordinator")
	var task_summary: Dictionary = coordinator.summary()
	if task_summary.active != 50 or task_summary.available < 1 or task_summary.created_total < 50:
		_fail("shared task board did not assign 50 active tasks with queued work: %s" % task_summary)
		return
	var navigation := scene.get_node("FloorNavigation")
	var obstacle_detour: Array[Vector3] = navigation.path_between(Vector3(-58.0, 0.0, 0.0), Vector3(-58.0, 0.0, -80.0))
	if obstacle_detour.is_empty():
		_fail("A* floor path could not route around the desk footprint")
		return
	var detour_length := 0.0
	for index in range(obstacle_detour.size()):
		if navigation.is_obstacle_position(obstacle_detour[index]):
			_fail("A* path entered blocked geometry at %s" % obstacle_detour[index])
			return
		if index > 0:
			detour_length += obstacle_detour[index - 1].distance_to(obstacle_detour[index])
	if detour_length < 100.0:
		_fail("obstacle test route did not detour around major furniture")
		return
	var distance_before: float = first_citizen.get_travelled_distance()
	await create_timer(1.5).timeout
	var moving_count := 0
	for child in scene.get_children():
		if child.name.begins_with("Citizen") and child.state in ["TRAVEL", "CARRY"] and child.get_travelled_distance() > 0.0:
			moving_count += 1
	if moving_count < 30 or first_citizen.get_travelled_distance() < distance_before:
		_fail("autonomous task assignment did not produce visible floor movement: moving=%d" % moving_count)
		return
	print("ROOMSCALE_M2_SMOKE_PASS nodes=%d citizens=%d tasks_active=%d tasks_available=%d moving=%d desk_detour=%.1fin" % [required_nodes.size(), citizen_count, coordinator.summary().active, coordinator.summary().available, moving_count, detour_length])
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_SMOKE_FAIL: " + message)
	quit(1)
