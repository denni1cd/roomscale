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
		"FloorNavigation", "SurfaceNavigation", "TaskCoordinator", "Citizen01", "Citizen50",
		"Furniture/Desk/DeskSelectionCollider", "Furniture/Desk/DeskSelectionOutline",
		"CameraRig/Camera", "KeyLight", "WorldEnvironment", "Overlay/Controls", "Overlay/CameraMode",
		"Overlay/GoalStatus", "Overlay/ReachExploreButton", "Overlay/ProjectStatus",
		"Overlay/MaterialStatus", "Overlay/BuildStatus", "ConstructionSystem"
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
	var surface_navigation := scene.get_node("SurfaceNavigation")
	var construction := scene.get_node("ConstructionSystem")
	if construction.has_project():
		_fail("construction project must not exist before the barrier is confirmed")
		return
	var initial_surface_route: Dictionary = surface_navigation.route_between("FLOOR", "DESK", Vector3(-58.0, 0.0, 0.0), Vector3(-58.0, 30.0, -52.0))
	if initial_surface_route.reachable or surface_navigation.has_connection("FLOOR", "DESK"):
		_fail("floor and elevated desk navigation regions must initially be disconnected")
		return
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
	var desk_click_position: Vector2 = (scene.get_node("CameraRig/Camera") as Camera3D).unproject_position(Vector3(-58.0, 30.0, -52.0))
	if not scene.select_surface_at_screen_position(desk_click_position):
		_fail("production mouse-ray selection API did not select the elevated desk collision surface")
		return
	var goal_start: Dictionary = scene.issue_reach_explore()
	if not goal_start.accepted or goal_start.state != "EXPLORERS_EN_ROUTE" or goal_start.expected_explorers != 2:
		_fail("Reach / Explore did not assign floor investigators after the disconnected route: %s" % goal_start)
		return
	var arrival_wait := 0.0
	var goal_status: Dictionary = coordinator.get_reach_goal_status()
	while goal_status.state != "BARRIER_CONFIRMED" and arrival_wait < 35.0:
		await create_timer(0.25).timeout
		arrival_wait += 0.25
		goal_status = coordinator.get_reach_goal_status()
	if goal_status.state != "BARRIER_CONFIRMED" or goal_status.arrived_explorers != 2:
		_fail("barrier was not recognized after explorers physically approached the desk: %s" % goal_status)
		return
	if not goal_status.barrier.recognized_after_approach or goal_status.barrier["from"] != "FLOOR" or goal_status.barrier["to"] != "DESK":
		_fail("barrier record did not identify the missing FLOOR-to-DESK connection: %s" % goal_status.barrier)
		return
	var approach_position: Vector3 = goal_status.barrier.get("approach_position", Vector3.ZERO)
	if navigation.is_obstacle_position(approach_position):
		_fail("barrier recognition was not based on an accessible investigation position")
		return
	var confirmed_route: Dictionary = surface_navigation.route_between("FLOOR", "DESK", approach_position, Vector3(-58.0, 30.0, -52.0))
	if confirmed_route.reachable:
		_fail("surface navigation unexpectedly reached the desk after barrier recognition")
		return
	if not construction.has_project():
		_fail("BARRIER_CONFIRMED did not automatically create the traversal construction project")
		return
	var project_start: Dictionary = construction.status()
	if project_start.state != "DELIVERING" or project_start.required != {"wood": 4, "metal": 4, "mechanical_parts": 3}:
		_fail("project did not start with required materials and a delivery phase: %s" % project_start)
		return
	if project_start.stockpile != project_start.required or project_start.delivered != {"wood": 0, "metal": 0, "mechanical_parts": 0}:
		_fail("project stockpile/delivered counts were initialized incorrectly: %s" % project_start)
		return
	if project_start.cable_deployed or surface_navigation.has_connection("FLOOR", "DESK"):
		_fail("grapple cable or navigation connection appeared before the launcher was built")
		return
	var delivery_tasks: Array[Dictionary] = []
	var distinct_delivery_owners: Dictionary = {}
	var premature_build_tasks := 0
	for task in coordinator.tasks:
		if task.task_type == "CONSTRUCTION_DELIVERY":
			delivery_tasks.append(task)
			distinct_delivery_owners[int(task.citizen_id)] = true
		elif task.task_type == "CONSTRUCTION_BUILD":
			premature_build_tasks += 1
	if delivery_tasks.size() != 11 or distinct_delivery_owners.size() != 11 or premature_build_tasks != 0:
		_fail("expected 11 distinct material carriers and no builders before thresholds; deliveries=%d owners=%d builders=%d" % [delivery_tasks.size(), distinct_delivery_owners.size(), premature_build_tasks])
		return
	var delivery_material_counts := {"wood": 0, "metal": 0, "mechanical_parts": 0}
	for task in delivery_tasks:
		delivery_material_counts[task.resource] = int(delivery_material_counts[task.resource]) + int(task.amount)
		if task.source != Vector3(18.0, 0.0, 55.0) or task.target != Vector3(-14.0, 0.0, -52.0):
			_fail("material task did not link the depot to the construction site: %s" % task)
			return
	if delivery_material_counts != project_start.required:
		_fail("delivery tasks do not cover the exact required materials: %s" % delivery_material_counts)
		return
	var delivery_route: Array[Vector3] = navigation.path_between(Vector3(18.0, 0.0, 55.0), Vector3(-14.0, 0.0, -52.0))
	if delivery_route.is_empty() or delivery_route.size() < 8:
		_fail("depot-to-construction delivery did not receive a real multi-waypoint floor path")
		return
	var delivery_route_length := 0.0
	for index in range(delivery_route.size()):
		if navigation.is_obstacle_position(delivery_route[index]):
			_fail("delivery path entered blocked floor geometry: %s" % delivery_route[index])
			return
		if index > 0:
			delivery_route_length += delivery_route[index - 1].distance_to(delivery_route[index])
	if delivery_route_length < 100.0:
		_fail("delivery route is unexpectedly short and does not establish floor travel: %.1f" % delivery_route_length)
		return
	var construction_elapsed := 0.0
	var saw_carried_resource := false
	var saw_builder_work := false
	var project_status: Dictionary = construction.status()
	while project_status.completed_stages < 3 and construction_elapsed < 120.0:
		if construction.status().cable_deployed or surface_navigation.has_connection("FLOOR", "DESK"):
			_fail("cable or FLOOR-DESK link appeared before all construction stages completed")
			return
		for child in scene.get_children():
			if not child.name.begins_with("Citizen"):
				continue
			if child.task_type == "CONSTRUCTION_DELIVERY" and child.carrying:
				var delivery_task: Dictionary = coordinator.get_task(child.task_id)
				var parcel := child.get_node("Figure/Parcel") as MeshInstance3D
				if not bool(delivery_task.picked_up) or not parcel.visible or String(parcel.get_meta("cargo_resource", "")) != String(delivery_task.resource):
					_fail("citizen cargo did not match a verified physical stockpile pickup: %s" % delivery_task)
					return
				saw_carried_resource = true
			elif child.task_type == "CONSTRUCTION_BUILD" and child.state == "WORK":
				var build_task: Dictionary = coordinator.get_task(child.task_id)
				var site: Vector3 = build_task.target
				if child.global_position.distance_to(site) > 1.6:
					_fail("builder received work progress away from the construction site")
					return
				saw_builder_work = true
		for task in coordinator.tasks:
			if task.task_type == "CONSTRUCTION_BUILD" and float(task.get("work_seconds", 0.0)) > 0.0:
				saw_builder_work = true
		await create_timer(0.25).timeout
		construction_elapsed += 0.25
		project_status = construction.status()
	if project_status.completed_stages != 3 or absf(float(project_status.progress_percent) - 100.0) > 0.01:
		_fail("builders did not complete base, winch, and launcher within the wait window: %s" % project_status)
		return
	if not saw_carried_resource or not saw_builder_work:
		_fail("smoke did not observe attached resource cargo and on-site construction work")
		return
	if project_status.stockpile != {"wood": 0, "metal": 0, "mechanical_parts": 0} or project_status.delivered != project_status.required:
		_fail("delivery bookkeeping did not consume and deliver each stockpile unit exactly once: %s" % project_status)
		return
	if project_status.stage_gates.size() != 3:
		_fail("not all build stages recorded a material gate snapshot: %s" % project_status.stage_gates)
		return
	for stage_index in range(project_status.stage_gates.size()):
		var gate: Dictionary = project_status.stage_gates[stage_index]
		var required_gate: Dictionary = [{"wood": 2, "metal": 1, "mechanical_parts": 0}, {"wood": 3, "metal": 3, "mechanical_parts": 1}, {"wood": 4, "metal": 4, "mechanical_parts": 3}][stage_index]
		for resource in ["wood", "metal", "mechanical_parts"]:
			if int(gate[resource]) < int(required_gate[resource]):
				_fail("builder stage %d unlocked before its %s threshold: %s" % [stage_index, resource, gate])
				return
	var completed_delivery_count := 0
	var verified_delivery_counts := {"wood": 0, "metal": 0, "mechanical_parts": 0}
	for task in coordinator.tasks:
		if task.task_type == "CONSTRUCTION_DELIVERY":
			if task.state != "complete" or not task.get("picked_up", false) or not task.get("delivered", false):
				_fail("material task completed without both physical pickup and delivery: %s" % task)
				return
			if int(task.get("delivered_at", 0)) <= int(task.get("picked_up_at", 0)) or float(task.get("delivery_travelled_distance", 0.0)) < delivery_route_length * 0.9:
				_fail("material credit arrived before a real depot-to-site walk: %s" % task)
				return
			verified_delivery_counts[task.resource] = int(verified_delivery_counts[task.resource]) + int(task.amount)
			completed_delivery_count += 1
	if completed_delivery_count != 11 or verified_delivery_counts != project_status.required:
		_fail("verified delivery ledger does not match all stockpile units: %s" % verified_delivery_counts)
		return
	for component_path in ["GrappleBase", "BrassBasePlate", "WinchDrum", "WinchGear", "LauncherFrame", "LauncherArm"]:
		var component := scene.get_node_or_null(NodePath("GrappleConstructionSite/%s" % component_path)) as MeshInstance3D
		if component == null or not component.visible:
			_fail("completed stage component is not visibly present: %s" % component_path)
			return
	if not project_status.cable_deployed or not surface_navigation.has_connection("FLOOR", "DESK") or not project_status.floor_desk_connected:
		_fail("completed grapple construction did not deploy cable and connect FLOOR to DESK")
		return
	var deployed_route: Dictionary = surface_navigation.route_between("FLOOR", "DESK", approach_position, Vector3(-58.0, 30.0, -52.0))
	if not deployed_route.reachable or deployed_route.path.size() < 12 or deployed_route.reason != "deployed grapple cable":
		_fail("deployed connection did not expose its physical cable route: %s" % deployed_route)
		return
	var route_height := 0.0
	var route_prefix_points := 0
	var largest_route_gap := 0.0
	for index in range(deployed_route.path.size()):
		route_height = maxf(route_height, deployed_route.path[index].y)
		if deployed_route.path[index].y <= 0.05:
			route_prefix_points += 1
		if index > 0:
			largest_route_gap = maxf(largest_route_gap, deployed_route.path[index - 1].distance_to(deployed_route.path[index]))
	if route_prefix_points < 2 or route_height < 29.99 or largest_route_gap > 8.0:
		_fail("floor A* did not join continuous launcher/cable/desk route geometry: prefix=%d peak=%.1f gap=%.1f" % [route_prefix_points, route_height, largest_route_gap])
		return
	var cable_root := scene.get_node_or_null("DeployedGrappleCable") as Node3D
	if cable_root == null or cable_root.get_child_count() < 12:
		_fail("deployed grapple cable is missing visible segmented geometry")
		return
	var traversal_goal: Dictionary = coordinator.get_traversal_goal_status()
	if traversal_goal.state != "TRAVERSE_IN_PROGRESS":
		_fail("cable deployment did not assign its autonomous traversal task: %s" % traversal_goal)
		return
	var traversal_task: Dictionary = coordinator.get_task(int(traversal_goal.task_id))
	var climber := scene.get_node("Citizen%02d" % (int(traversal_goal.citizen_id) + 1)) as Node3D
	if traversal_task.task_type != "GRAPPLE_TRAVERSAL" or traversal_task.state != "active" or climber.task_type != "GRAPPLE_TRAVERSAL":
		_fail("grapple travel was not assigned through an active production task: %s" % traversal_task)
		return
	var traversal_elapsed := 0.0
	var min_sampled_y := climber.global_position.y
	var max_sampled_y := min_sampled_y
	var last_sampled_position: Vector3 = climber.global_position
	var max_step_distance := 0.0
	while coordinator.get_traversal_goal_status().state != "TRAVERSAL_COMPLETE" and traversal_elapsed < 60.0:
		await create_timer(0.2).timeout
		traversal_elapsed += 0.2
		var current_position: Vector3 = climber.global_position
		var frame_distance := current_position.distance_to(last_sampled_position)
		max_step_distance = maxf(max_step_distance, frame_distance)
		if frame_distance > 6.5 * 0.55 + 0.25:
			_fail("climber made a discontinuous movement step of %.2fin" % frame_distance)
			return
		last_sampled_position = current_position
		min_sampled_y = minf(min_sampled_y, current_position.y)
		max_sampled_y = maxf(max_sampled_y, current_position.y)
	traversal_goal = coordinator.get_traversal_goal_status()
	var completed_traversal: Dictionary = coordinator.get_task(int(traversal_goal.get("task_id", -1)))
	if traversal_goal.state != "TRAVERSAL_COMPLETE" or climber.state != "ON_DESK" or climber.global_position.y < 29.99 or String(completed_traversal.get("target_region", "")) != "DESK":
		_fail("citizen did not physically reach the elevated desk through the deployed path: %s" % traversal_goal)
		return
	if min_sampled_y > 1.0 or max_sampled_y < 29.99 or float(completed_traversal.get("actual_travelled_distance", 0.0)) < float(completed_traversal.get("route_length", 0.0)) * 0.9:
		_fail("traversal did not record continuous floor-to-desk movement: %s y=%.1f..%.1f" % [completed_traversal, min_sampled_y, max_sampled_y])
		return
	print("ROOMSCALE_M2_SMOKE_PASS nodes=%d citizens=%d tasks_active=%d tasks_available=%d moving=%d desk_detour=%.1fin" % [required_nodes.size(), citizen_count, coordinator.summary().active, coordinator.summary().available, moving_count, detour_length])
	print("ROOMSCALE_M3_SMOKE_PASS selected=DESK explorers=%d arrived=%d barrier=%s elapsed=%.2fs" % [goal_status.expected_explorers, goal_status.arrived_explorers, goal_status.barrier.reason, arrival_wait])
	print("ROOMSCALE_M4_SMOKE_PASS deliveries=%d stockpile=%s delivered=%s builder_gates=%d components=%d progress=%.1f%% walk=%.1fin elapsed=%.2fs" % [completed_delivery_count, project_status.stockpile, project_status.delivered, project_status.stage_gates.size(), project_status.completed_stages, project_status.progress_percent, delivery_route_length, construction_elapsed])
	print("ROOMSCALE_M5_SMOKE_PASS cable_segments=%d route_points=%d traverser=%s target=DESK height=%.1fin walked=%.1fin route=%.1fin max_step=%.2fin elapsed=%.2fs" % [cable_root.get_child_count() - 1, deployed_route.path.size(), climber.name, climber.global_position.y, completed_traversal.actual_travelled_distance, completed_traversal.route_length, max_step_distance, traversal_elapsed])
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_SMOKE_FAIL: " + message)
	quit(1)
