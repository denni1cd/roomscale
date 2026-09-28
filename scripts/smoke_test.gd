extends SceneTree

const RoomDefinitionLoader := preload("res://scripts/room_definition.gd")
const REQUIRED_MATERIALS := {"wood": 4, "metal": 4, "mechanical_parts": 3}
const M6_CITIZEN_WALK_SPEED := 6.5

var _visual_directory := ""
var _captured_visual_phases: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_visual_directory = OS.get_environment("ROOMSCALE_VISUAL_DIR")
	if not _visual_directory.is_empty() and DisplayServer.get_name() == "headless":
		_fail("visual capture was requested from a headless renderer")
		return
	var room_id := OS.get_environment("ROOMSCALE_ROOM")
	if room_id.is_empty():
		room_id = "room_a"
	var loaded: Dictionary = RoomDefinitionLoader.load_requested()
	if not bool(loaded.ok):
		_fail("room definition failed validation: %s" % loaded.errors)
		return
	var definition: Dictionary = loaded.definition
	room_id = String(definition.id)
	var floor_start := RoomDefinitionLoader.vector3_from(definition.floor.center)
	floor_start.y = float(definition.floor.height)
	var packed := load("res://scenes/pipeline_proof.tscn") as PackedScene
	if packed == null:
		_fail("could not load the production scene")
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("main scene did not instantiate as Node3D")
		return
	root.add_child(scene)
	await process_frame
	await physics_frame
	if not await _capture_visual(scene, "initial-room", floor_start, 330.0):
		return
	var expected_room := String(definition.id)
	var scene_definition: Dictionary = scene.get("_room_definition")
	if String(scene_definition.get("id", "")) != expected_room:
		_fail("production scene did not load requested RoomDefinition %s" % expected_room)
		return
	var dimensions: Array = definition.dimensions
	var width := float(dimensions[0])
	var depth := float(dimensions[1])
	var floor := scene.get_node_or_null("Room/Floor") as MeshInstance3D
	if floor == null or (floor.mesh as BoxMesh).size != Vector3(width, 1.0, depth):
		_fail("generated floor dimensions do not match RoomDefinition")
		return
	var floor_navigation := scene.get_node_or_null("FloorNavigation")
	var surface_navigation := scene.get_node_or_null("SurfaceNavigation")
	var coordinator := scene.get_node_or_null("TaskCoordinator")
	var construction := scene.get_node_or_null("ConstructionSystem")
	var goal_region := String(surface_navigation.goal_surface_id)
	var goal_surface: Dictionary = surface_navigation.goal_surface()
	if goal_region.is_empty() or not goal_surface.get("goal", false):
		_fail("RoomDefinition target surface was not discovered")
		return
	var target_center: Vector3 = goal_surface.center
	var object_root := scene.get_node_or_null("RoomObjects/%s" % goal_surface.object_id)
	if object_root == null or object_root.get_node_or_null("GoalSurfaceCollider") == null:
		_fail("selected elevated geometry or its generic selection collider is missing")
		return
	for object_variant in definition.objects:
		var object: Dictionary = object_variant
		if String(object.kind) == "settlement":
			continue
		if scene.get_node_or_null("RoomObjects/%s" % String(object.id)) == null:
			_fail("room geometry omitted RoomDefinition object %s" % object.id)
			return
	var blocked_count := 0
	for object_variant in definition.objects:
		if bool(object_variant.get("blocks_navigation", false)):
			blocked_count += 1
	if floor_navigation.obstacle_rects.size() != blocked_count:
		_fail("floor navigation obstacles were not generated from all blocking objects")
		return
	var initially_reachable: Dictionary = surface_navigation.route_between("FLOOR", goal_region, floor_start, goal_surface.anchor)
	if initially_reachable.reachable or surface_navigation.has_connection("FLOOR", goal_region):
		_fail("elevated target should start disconnected from the floor")
		return
	var approach_points: Array[Vector3] = surface_navigation.investigation_candidates_for(goal_region)
	if approach_points.size() < 2:
		_fail("target surface did not supply dynamic investigation points")
		return
	var test_route: Array[Vector3] = floor_navigation.path_between(approach_points[0], approach_points[1])
	if test_route.is_empty():
		_fail("A* could not route between generated investigation points")
		return
	var route_length := _path_length(test_route)
	for point in test_route:
		if floor_navigation.is_obstacle_position(point):
			_fail("A* route entered RoomDefinition obstacle %s" % point)
			return
	if route_length < approach_points[0].distance_to(approach_points[1]) + 4.0:
		_fail("target obstacle did not produce a navigational detour")
		return
	var site_result: Dictionary = surface_navigation.derive_construction_site(floor_navigation)
	if not site_result.valid or not floor_navigation.is_walkable(site_result.position) or floor_navigation.is_obstacle_position(site_result.position):
		_fail("construction site was not derived as reachable, clear floor geometry: %s" % site_result)
		return
	var depot_position: Vector3 = RoomDefinitionLoader.vector3_from(definition.construction.depot_pickup)
	if floor_navigation.path_between(depot_position, site_result.position).is_empty():
		_fail("derived construction site is not reachable from the configured depot")
		return
	if not scene.has_method("select_goal_surface") or not scene.select_goal_surface(goal_region):
		_fail("production UI could not select the generic target surface")
		return
	var camera_rig := scene.get_node("CameraRig")
	if not camera_rig.has_method("set_view_mode") or not camera_rig.has_method("orbit_by") or not camera_rig.has_method("pan_by") or not camera_rig.has_method("zoom_by"):
		_fail("strategy camera controls are incomplete")
		return
	camera_rig.set_view_mode(0)
	var room_distance: float = camera_rig.distance
	camera_rig.set_view_mode(1)
	var settlement_distance: float = camera_rig.distance
	camera_rig.set_view_mode(2)
	var citizen_distance: float = camera_rig.distance
	if not (room_distance > settlement_distance and settlement_distance > citizen_distance):
		_fail("room camera presets do not scale with room and settlement size")
		return
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	camera_rig.set_view_mode(0)
	await process_frame
	var target_screen: Vector2 = camera.unproject_position(target_center)
	if not scene.select_surface_at_screen_position(target_screen):
		_fail("production mouse-ray selection failed for the RoomDefinition surface")
		return
	var citizens: Array[Node3D] = []
	for child in scene.get_children():
		if child.name.begins_with("Citizen"):
			citizens.append(child as Node3D)
	if citizens.size() != 50 or scene.get_node_or_null("Citizen50") == null:
		_fail("production scene must spawn 50 distinct citizens; found %d" % citizens.size())
		return
	var summary: Dictionary = coordinator.summary()
	if summary.active != 50 or summary.available < 1:
		_fail("citizen task board did not assign autonomous work: %s" % summary)
		return
	var steam := scene.get_node_or_null("Settlement/Workshop/BoilerSteam") as GPUParticles3D
	var gears := scene.get_node_or_null("Settlement/Workshop/BenchGear")
	if steam == null or not steam.emitting or gears == null or gears.get_child_count() < 10:
		_fail("procedural settlement presentation is missing")
		return
	var moving_before := _moving_count(citizens)
	await create_timer(1.5).timeout
	var moving_after := _moving_count(citizens)
	var travelled_after := _travelled_count(citizens)
	if travelled_after < 30:
		_fail("autonomous citizens did not visibly move across the generated room: travelled=%d moving=%d->%d" % [travelled_after, moving_before, moving_after])
		return
	var inspected_citizen := citizens[0]
	camera_rig.focus_at(inspected_citizen.global_position, 28.0, 55.0, 0.3)
	await process_frame
	var inspected_marker := inspected_citizen.global_position + Vector3(0.0, 0.25, 0.0)
	var citizen_screen_position := camera.unproject_position(inspected_marker)
	if not scene.select_citizen_at_screen_position(citizen_screen_position):
		_fail("production citizen selection did not identify the clicked citizen id=%d screen=%s behind=%s" % [inspected_citizen.citizen_id, citizen_screen_position, camera.is_position_behind(inspected_marker)])
		return
	scene.call("_update_population_ui")
	var inspection_label := scene.get_node("Overlay/CitizenInspection") as Label
	var expected_citizen_text := "CITIZEN %02d" % (int(inspected_citizen.citizen_id) + 1)
	var inspection_verified := inspection_label.text.contains(expected_citizen_text) and inspection_label.text.contains("TASK") and inspection_label.text.contains("TARGET")
	if not inspection_verified:
		_fail("citizen inspection omitted identifier, task, or target: %s" % inspection_label.text)
		return
	if not await _capture_visual(scene, "citizen-inspection", inspected_citizen.global_position, 28.0, 55.0, 0.3):
		return
	if not await _capture_visual(scene, "living-civilization", Vector3(0.0, 4.0, 50.0), 138.0, 62.0, 0.25):
		return
	var site: Vector3 = coordinator.get_construction_site()
	if not scene.issue_reach_explore().accepted:
		_fail("Reach / Explore did not accept the selected generic surface")
		return
	var goal_status: Dictionary = coordinator.get_reach_goal_status()
	if goal_status.state != "EXPLORERS_EN_ROUTE" or int(goal_status.expected_explorers) != 2:
		_fail("generic goal did not dispatch two floor investigators: %s" % goal_status)
		return
	var investigation_elapsed := 0.0
	while goal_status.state != "BARRIER_CONFIRMED" and investigation_elapsed < 40.0:
		await create_timer(0.25).timeout
		investigation_elapsed += 0.25
		goal_status = coordinator.get_reach_goal_status()
	if goal_status.state != "BARRIER_CONFIRMED" or int(goal_status.arrived_explorers) != 2:
		_fail("barrier was not recognized after physical approaches: %s" % goal_status)
		return
	var approach_position: Vector3 = goal_status.barrier.approach_position
	if floor_navigation.is_obstacle_position(approach_position):
		_fail("barrier investigation position overlaps generated room geometry")
		return
	var disconnected: Dictionary = surface_navigation.route_between("FLOOR", goal_region, approach_position, goal_surface.anchor)
	if disconnected.reachable or String(goal_status.barrier.to) != goal_region or not goal_status.barrier.recognized_after_approach:
		_fail("barrier evidence does not match the selected disconnected surface")
		return
	if not construction.has_project():
		_fail("confirmed barrier did not start the traversal project")
		return
	var initial_project: Dictionary = construction.status()
	var initial_inventory_balanced := true
	for resource in REQUIRED_MATERIALS:
		var resource_total := int(initial_project.stockpile.get(resource, 0)) + int(initial_project.picked_up.get(resource, 0)) + int(initial_project.delivered.get(resource, 0))
		if resource_total != int(REQUIRED_MATERIALS[resource]):
			initial_inventory_balanced = false
	if initial_project.state != "DELIVERING" or initial_project.required != REQUIRED_MATERIALS or not initial_inventory_balanced or initial_project.delivered != {"wood": 0, "metal": 0, "mechanical_parts": 0}:
		_fail("construction project initialized with incorrect inventory or state: %s" % initial_project)
		return
	if initial_project.cable_deployed or surface_navigation.has_connection("FLOOR", goal_region):
		_fail("grapple became operational before the structure was built")
		return
	if not floor_navigation.is_walkable(site) or floor_navigation.is_obstacle_position(site) or site.distance_to(site_result.position) > 0.1:
		_fail("production construction site does not match the geometry-derived reachable position")
		return
	var delivery_tasks: Array[Dictionary] = []
	var delivery_owners: Dictionary = {}
	var material_counts := {"wood": 0, "metal": 0, "mechanical_parts": 0}
	for task in coordinator.tasks:
		if task.task_type == "CONSTRUCTION_DELIVERY":
			delivery_tasks.append(task)
			delivery_owners[int(task.citizen_id)] = true
			material_counts[String(task.resource)] = int(material_counts[String(task.resource)]) + int(task.amount)
			if task.source != depot_position or task.target != site:
				_fail("delivery task does not connect RoomDefinition depot to derived construction site")
				return
	if delivery_tasks.size() != 11 or delivery_owners.size() != 11 or material_counts != REQUIRED_MATERIALS:
		_fail("project did not assign distinct carriers for all material units: %s" % material_counts)
		return
	var delivery_route: Array[Vector3] = floor_navigation.path_between(depot_position, site)
	var delivery_route_length := _path_length(delivery_route)
	if delivery_route.size() < 8:
		_fail("depot-to-site delivery did not use a real floor route")
		return
	for point in delivery_route:
		if floor_navigation.is_obstacle_position(point):
			_fail("material delivery path crossed blocked room geometry")
			return
	if not await _capture_visual(scene, "target-investigation", (approach_position + goal_surface.anchor) * 0.5, maxf(105.0, approach_position.distance_to(goal_surface.anchor) * 1.8), 66.0, 0.55):
		return
	var construction_elapsed := 0.0
	var saw_carried_resource := false
	var saw_builder_work := false
	var hauling_visual_saved := false
	var construction_visual_saved := false
	while int(construction.status().completed_stages) < 3 and construction_elapsed < 150.0:
		if construction.status().cable_deployed or surface_navigation.has_connection("FLOOR", goal_region):
			_fail("traversal connected before every construction stage completed")
			return
		for citizen in citizens:
			if citizen.task_type == "CONSTRUCTION_DELIVERY" and citizen.carrying:
				var task: Dictionary = coordinator.get_task(citizen.task_id)
				var parcel := citizen.get_node("Figure/Parcel") as MeshInstance3D
				if not bool(task.get("picked_up", false)) or not parcel.visible or String(parcel.get_meta("cargo_resource", "")) != String(task.resource):
					_fail("carried material does not match a verified stockpile pickup")
					return
				saw_carried_resource = true
				if not hauling_visual_saved:
					hauling_visual_saved = true
					if not await _capture_visual(scene, "resource-hauling", (depot_position + site) * 0.5, maxf(175.0, depot_position.distance_to(site) * 1.3), 68.0, 0.35):
						return
			elif citizen.task_type == "CONSTRUCTION_BUILD" and citizen.state == "WORK":
				if citizen.global_position.distance_to(site) > 1.6:
					_fail("builder performed work away from the derived site")
					return
				saw_builder_work = true
				var build_status: Dictionary = construction.status()
				if not construction_visual_saved and int(build_status.completed_stages) >= 1 and String(build_status.active_stage) == "winch" and float(build_status.stage_progress) >= 0.1:
					construction_visual_saved = true
					if not await _capture_visual(scene, "construction", site + Vector3(0.0, 8.0, 0.0), 74.0, 68.0, 0.6):
						return
		for task in coordinator.tasks:
			if task.task_type == "CONSTRUCTION_BUILD" and float(task.get("work_seconds", 0.0)) > 0.0:
				saw_builder_work = true
		await create_timer(0.25).timeout
		construction_elapsed += 0.25
	if int(construction.status().completed_stages) != 3 or not saw_carried_resource or not saw_builder_work:
		var incomplete_deliveries: Array[Dictionary] = []
		for task in coordinator.tasks:
			if String(task.get("task_type", "")) != "CONSTRUCTION_DELIVERY" or String(task.get("state", "")) == "complete":
				continue
			var owner_state := "missing"
			var owner_position := "unknown"
			var owner_task_id := -1
			for citizen in citizens:
				if int(citizen.get("citizen_id")) == int(task.get("citizen_id", -1)):
					owner_state = String(citizen.get("state"))
					owner_position = str(citizen.global_position)
					owner_task_id = int(citizen.get("task_id"))
					break
			incomplete_deliveries.append({"resource":task.get("resource", ""), "task_state":task.get("state", ""), "citizen_id":task.get("citizen_id", -1), "owner_state":owner_state, "owner_position":owner_position, "owner_task_id":owner_task_id})
		_fail("verified hauling or real builder work did not complete all stages: status=%s incomplete_deliveries=%s" % [construction.status(), incomplete_deliveries])
		return
	var project_status: Dictionary = construction.status()
	var completed_delivery_count := 0
	var verified_deliveries := {"wood": 0, "metal": 0, "mechanical_parts": 0}
	for task in coordinator.tasks:
		if task.task_type == "CONSTRUCTION_DELIVERY":
			if task.state != "complete" or not task.get("picked_up", false) or not task.get("delivered", false):
				_fail("material task did not record physical pickup and delivery: %s" % task)
				return
			if int(task.get("delivered_at", 0)) <= int(task.get("picked_up_at", 0)) or float(task.get("delivery_travelled_distance", 0.0)) < delivery_route_length * 0.9:
				_fail("material was credited without real depot-to-site travel")
				return
			verified_deliveries[String(task.resource)] = int(verified_deliveries[String(task.resource)]) + int(task.amount)
			completed_delivery_count += 1
	if completed_delivery_count != 11 or verified_deliveries != REQUIRED_MATERIALS or float(project_status.progress_percent) < 100.0:
		_fail("delivered materials or construction ledger did not reach completion")
		return
	if construction.active_builder_count() != 0 or not construction._construction_worker_ids.is_empty():
		_fail("stale construction worker assignments remain after project completion")
		return
	for citizen in citizens:
		if citizen.task_type == "CONSTRUCTION_BUILD" or citizen.state == "WORK" and String(citizen.task_type).begins_with("CONSTRUCTION"):
			_fail("construction worker did not return to normal autonomous work: %s" % citizen.name)
			return
	for component_name in ["GrappleBase", "BrassBasePlate", "WinchDrum", "WinchGear", "LauncherFrame", "LauncherArm"]:
		var component := scene.get_node_or_null("GrappleConstructionSite/%s" % component_name) as MeshInstance3D
		if component == null or not component.visible:
			_fail("completed construction component is not visibly present: %s" % component_name)
			return
	var cable_root := scene.get_node_or_null("DeployedGrappleCable") as Node3D
	var partial_deployment_seen := false
	var grapple_visual_saved := false
	var deployment_wait := 0.0
	while not construction.status().cable_deployed and deployment_wait < 8.0:
		if is_instance_valid(cable_root):
			var visible_segments := 0
			var total_segments := 0
			for child in cable_root.get_children():
				if child.name.begins_with("CableSegment"):
					total_segments += 1
					if child.visible:
						visible_segments += 1
			if visible_segments > 0 and visible_segments < total_segments:
				partial_deployment_seen = true
				if not grapple_visual_saved:
					grapple_visual_saved = true
					var room_diagonal := Vector2(width, depth).length()
					if not await _capture_visual(scene, "grapple-deployment", (site + goal_surface.anchor) * 0.5, maxf(175.0, room_diagonal * 0.7), 50.0, 0.0, true):
						return
		await create_timer(0.04).timeout
		deployment_wait += 0.04
	if not construction.status().cable_deployed or not partial_deployment_seen:
		_fail("grapple did not deploy visibly over time")
		return
	var cable_segments := 0
	var largest_cable_radius := 0.0
	for child in cable_root.get_children():
		if child.name.begins_with("CableSegment"):
			cable_segments += 1
			var cable_mesh := (child as MeshInstance3D).mesh as CylinderMesh
			largest_cable_radius = maxf(largest_cable_radius, cable_mesh.top_radius)
			if not child.visible:
				_fail("deployed cable has a hidden segment")
				return
	if cable_segments < 6 or largest_cable_radius > 0.1 or not (largest_cable_radius > 0.03):
		_fail("cable thickness or segmentation is not appropriate for half-inch citizens")
		return
	var deployed_route: Dictionary = surface_navigation.route_between("FLOOR", goal_region, approach_position, goal_surface.anchor)
	if not deployed_route.reachable or deployed_route.path.size() < 12:
		_fail("deployed infrastructure does not expose a continuous room-specific route")
		return
	var maximum_route_gap := 0.0
	var maximum_route_height := 0.0
	for index in range(deployed_route.path.size()):
		maximum_route_height = maxf(maximum_route_height, deployed_route.path[index].y)
		if index > 0:
			maximum_route_gap = maxf(maximum_route_gap, deployed_route.path[index - 1].distance_to(deployed_route.path[index]))
	if maximum_route_height < float(goal_surface.height) - 0.01 or maximum_route_gap > 8.0:
		_fail("surface route does not join the floor and target height continuously")
		return
	var traversal_goal: Dictionary = coordinator.get_traversal_goal_status()
	if traversal_goal.state != "TRAVERSE_IN_PROGRESS":
		_fail("deployment did not assign a traversal task: %s" % traversal_goal)
		return
	var traversal_task: Dictionary = coordinator.get_task(int(traversal_goal.task_id))
	var climber := scene.get_node("Citizen%02d" % (int(traversal_goal.citizen_id) + 1)) as Node3D
	if traversal_task.task_type != "SURFACE_TRAVERSAL" or traversal_task.state != "active" or climber.task_type != "SURFACE_TRAVERSAL":
		_fail("physical climbing was not assigned through a live production task")
		return
	var traversal_elapsed := 0.0
	var min_y := climber.global_position.y
	var max_y := min_y
	var last_position := climber.global_position
	var last_sample_sim_time := float(climber.simulation_elapsed)
	var max_step := 0.0
	var max_step_seconds := 0.0
	var max_sample_speed := 0.0
	var max_sample_seconds := 0.0
	var traversal_visual_saved := false
	var traversal_detail_saved := _visual_directory.is_empty() or not _visual_phase_enabled("citizen-traversal-detail")
	var traversal_timeout := minf(120.0, float(traversal_task.route_length) / 6.5 + 20.0)
	var floor_height := float(definition.floor.height)
	print("ROOMSCALE_TRAVERSAL_START route=%.1fin timeout=%.1fs start=%s target=%s" % [traversal_task.route_length, traversal_timeout, climber.global_position, traversal_task.target])
	while coordinator.get_traversal_goal_status().state != "TRAVERSAL_COMPLETE" and traversal_elapsed < traversal_timeout:
		await create_timer(0.2).timeout
		traversal_elapsed += 0.2
		var current := climber.global_position
		var step_distance := current.distance_to(last_position)
		var sample_sim_time := float(climber.simulation_elapsed)
		var sample_seconds := maxf(sample_sim_time - last_sample_sim_time, 0.001)
		if step_distance > max_step:
			max_step = step_distance
			max_step_seconds = sample_seconds
		var sample_speed := step_distance / sample_seconds
		if sample_speed > max_sample_speed:
			max_sample_speed = sample_speed
			max_sample_seconds = sample_seconds
		if step_distance > 6.5 * sample_seconds + 0.25:
			_fail("climber made a discontinuous movement step of %.2fin over %.3fs (%.2fin/s; cap %.1fin/s plus %.2fin tolerance)" % [step_distance, sample_seconds, sample_speed, M6_CITIZEN_WALK_SPEED, 0.25])
			return
		last_position = current
		last_sample_sim_time = sample_sim_time
		min_y = minf(min_y, current.y)
		max_y = maxf(max_y, current.y)
		if int(traversal_elapsed) % 10 == 0 and absf(traversal_elapsed - float(int(traversal_elapsed))) < 0.01:
			print("ROOMSCALE_TRAVERSAL_PROGRESS elapsed=%.1f state=%s position=%s walked=%.1f" % [traversal_elapsed, coordinator.get_traversal_goal_status().state, current, climber.travelled_distance - float(traversal_task.start_travelled_distance)])
		if not traversal_visual_saved and current.y >= floor_height + (float(goal_surface.height) - floor_height) * 0.4:
			traversal_visual_saved = true
			var room_diagonal := Vector2(width, depth).length()
			if not await _capture_visual(scene, "citizen-traversal", (current + goal_surface.anchor) * 0.5, maxf(140.0, room_diagonal * 0.5), 48.0, 0.0, true):
				return
		if not traversal_detail_saved and current.y >= floor_height + (float(goal_surface.height) - floor_height) * 0.85:
			traversal_detail_saved = true
			if not await _capture_visual(scene, "citizen-traversal-detail", current + Vector3.UP * 0.3, 22.0, 22.0, 0.65, true, true):
				return
	traversal_goal = coordinator.get_traversal_goal_status()
	var completed_traversal: Dictionary = coordinator.get_task(int(traversal_goal.task_id))
	if traversal_goal.state != "TRAVERSAL_COMPLETE" or completed_traversal.state != "complete" or climber.global_position.y < float(goal_surface.height) - 0.1 or String(completed_traversal.target_region) != goal_region:
		_fail("citizen did not physically reach elevated RoomDefinition surface: goal=%s task=%s position=%s height=%.1f elapsed=%.1f/%.1f" % [coordinator.get_traversal_goal_status(), completed_traversal, climber.global_position, goal_surface.height, traversal_elapsed, traversal_timeout])
		return
	if min_y > floor_height + 0.1 or max_y < float(goal_surface.height) - 0.1 or float(completed_traversal.actual_travelled_distance) < float(completed_traversal.route_length) * 0.9:
		_fail("citizen traversal did not continuously climb the generated cable route")
		return
	var m6_status: Dictionary = coordinator.get_m6_status()
	var m6_elapsed := 0.0
	var m6_timeout := 20.0
	var m6_budgeted_task_ids: Dictionary = {}
	var previous_positions: Dictionary = {}
	var previous_position_times: Dictionary = {}
	var m6_max_step := max_step
	var m6_max_step_seconds := max_step_seconds
	var m6_max_sample_speed := max_sample_speed
	var m6_max_sample_seconds := max_sample_seconds
	var m6_visual_saved := _visual_directory.is_empty() or not _visual_phase_enabled("elevated-surface-exploration")
	while true:
		var m6_task_ids: Array = m6_status.traversal_task_ids.duplicate()
		m6_task_ids.append_array(m6_status.surface_exploration_task_ids)
		for m6_task_id in m6_task_ids:
			if m6_budgeted_task_ids.has(int(m6_task_id)):
				continue
			var m6_task: Dictionary = coordinator.get_task(int(m6_task_id))
			if m6_task.is_empty():
				continue
			m6_budgeted_task_ids[int(m6_task_id)] = true
			if String(m6_task.get("state", "")) in ["complete", "failed"]:
				continue
			var task_budget := _m6_task_budget_seconds(m6_task)
			m6_timeout += task_budget
			print("ROOMSCALE_M6_BUDGET task=%d type=%s route=%.1fin added=%.1fs cumulative=%.1fs" % [int(m6_task_id), String(m6_task.get("task_type", "")), float(m6_task.get("route_length", 0.0)), task_budget, m6_timeout])
		if int(m6_status.target_arrivals) >= 3 and int(m6_status.target_explorations_completed) >= 3 and int(m6_status.autonomous_reuses_assigned) >= 2:
			break
		if m6_elapsed >= m6_timeout:
			break
		for citizen in citizens:
			var instance_id := citizen.get_instance_id()
			var position_sample_sim_time := float(citizen.simulation_elapsed)
			if previous_positions.has(instance_id):
				var distance := citizen.global_position.distance_to(previous_positions[instance_id])
				var sample_seconds := maxf(position_sample_sim_time - float(previous_position_times[instance_id]), 0.001)
				if distance > m6_max_step:
					m6_max_step = distance
					m6_max_step_seconds = sample_seconds
				var sample_speed := distance / sample_seconds
				if sample_speed > m6_max_sample_speed:
					m6_max_sample_speed = sample_speed
					m6_max_sample_seconds = sample_seconds
				if distance > 6.5 * sample_seconds + 0.25:
					_fail("surface reuse movement was discontinuous for %s: %.2fin over %.3fs (%.2fin/s; cap %.1fin/s plus %.2fin tolerance)" % [citizen.name, distance, sample_seconds, sample_speed, M6_CITIZEN_WALK_SPEED, 0.25])
					return
			previous_positions[instance_id] = citizen.global_position
			previous_position_times[instance_id] = position_sample_sim_time
			if not m6_visual_saved and citizen.task_type == "SURFACE_EXPLORATION" and citizen.global_position.y >= floor_height + (float(goal_surface.height) - floor_height) * 0.9:
				m6_visual_saved = true
				var room_diagonal := Vector2(width, depth).length()
				if not await _capture_visual(scene, "elevated-surface-exploration", goal_surface.anchor, maxf(110.0, room_diagonal * 0.45), 50.0, 0.0, true):
					return
				if not await _capture_visual(scene, "elevated-surface-exploration-detail", citizen.global_position + Vector3.UP * 0.3, 22.0, 22.0, 0.65, true, true):
					return
		await create_timer(0.2).timeout
		m6_elapsed += 0.2
		m6_status = coordinator.get_m6_status()
	if int(m6_status.target_arrivals) < 3 or int(m6_status.target_explorations_completed) < 3 or int(m6_status.autonomous_reuses_assigned) != 2:
		var m6_task_diagnostics: Array[Dictionary] = []
		var diagnostic_task_ids: Array = m6_status.traversal_task_ids.duplicate()
		diagnostic_task_ids.append_array(m6_status.surface_exploration_task_ids)
		for diagnostic_task_id in diagnostic_task_ids:
			var diagnostic_task: Dictionary = coordinator.get_m6_task_result(int(diagnostic_task_id))
			var diagnostic_citizen_id := int(diagnostic_task.get("citizen_id", -1))
			var diagnostic_citizen := scene.get_node_or_null("Citizen%02d" % (diagnostic_citizen_id + 1)) as Node3D if diagnostic_citizen_id >= 0 else null
			var citizen_path: Variant = diagnostic_citizen.get("_path") if diagnostic_citizen != null else []
			var diagnostic_agent := {
				"task_id": diagnostic_citizen.get("task_id") if diagnostic_citizen != null else -1,
				"task_type": diagnostic_citizen.get("task_type") if diagnostic_citizen != null else "",
				"state": diagnostic_citizen.get("state") if diagnostic_citizen != null else "",
				"position": diagnostic_citizen.global_position if diagnostic_citizen != null else Vector3.ZERO,
				"travelled_distance": diagnostic_citizen.get("travelled_distance") if diagnostic_citizen != null else 0.0,
				"destination": diagnostic_citizen.get("_destination") if diagnostic_citizen != null else Vector3.ZERO,
				"path_cursor": diagnostic_citizen.get("_path_cursor") if diagnostic_citizen != null else -1,
				"path_size": citizen_path.size() if citizen_path is Array else 0,
				"path": citizen_path if citizen_path is Array else [],
				"work_timer": diagnostic_citizen.get("_work_timer") if diagnostic_citizen != null else 0.0,
			}
			m6_task_diagnostics.append({
				"id": int(diagnostic_task_id),
				"type": diagnostic_task.get("task_type", ""),
				"state": diagnostic_task.get("state", "missing"),
				"citizen_id": diagnostic_task.get("citizen_id", -1),
				"route_length": diagnostic_task.get("route_length", 0.0),
				"work_seconds": diagnostic_task.get("work_seconds", 0.0),
				"start_travelled_distance": diagnostic_task.get("start_travelled_distance", 0.0),
				"actual_travelled_distance": diagnostic_task.get("actual_travelled_distance", null),
				"created_at": diagnostic_task.get("created_at", -1),
				"started_at": diagnostic_task.get("started_at", -1),
				"target": diagnostic_task.get("target", Vector3.ZERO),
				"agent": diagnostic_agent,
			})
		_fail("integrated autonomous surface exploration and route reuse timed out: elapsed=%.1fs budget=%.1fs status=%s task_progress=%s" % [m6_elapsed, m6_timeout, m6_status, m6_task_diagnostics])
		return
	if not m6_status.infrastructure_operational or not construction.status().cable_deployed or not surface_navigation.has_connection("FLOOR", goal_region):
		_fail("deployed infrastructure did not remain operational throughout the session")
		return
	var traversal_ids: Array = m6_status.traversal_task_ids
	var exploration_ids: Array = m6_status.surface_exploration_task_ids
	if traversal_ids.size() != 3 or exploration_ids.size() != 3:
		_fail("route-reuse ledger did not retain three visits to the selected target")
		return
	var owners: Dictionary = {}
	var reuse_indices: Dictionary = {}
	var total_exploration_work := 0.0
	for task_id in traversal_ids:
		var task: Dictionary = coordinator.get_m6_task_result(int(task_id))
		if task.is_empty():
			_fail("traversal task result aged out without an M6 snapshot: id=%d" % int(task_id))
			return
		if task.state != "complete" or float(task.actual_travelled_distance) < float(task.route_length) * 0.9:
			_fail("a traversal task lacks physical route completion: %s" % task)
			return
		owners[int(task.citizen_id)] = true
		if task.get("autonomous_reuse", false):
			reuse_indices[int(task.reuse_index)] = true
	for task_id in exploration_ids:
		var task: Dictionary = coordinator.get_m6_task_result(int(task_id))
		if task.is_empty():
			_fail("surface exploration result aged out without an M6 snapshot: id=%d" % int(task_id))
			return
		if task.state != "complete" or float(task.work_seconds) < 4.0 or float(task.actual_travelled_distance) < float(task.route_length) * 0.9:
			_fail("surface exploration did not walk and work on the target: %s" % task)
			return
		total_exploration_work += float(task.work_seconds)
	if owners.size() != 3 or not reuse_indices.has(1) or not reuse_indices.has(2):
		_fail("route reuse did not involve three citizens and two later traversals")
		return
	if not m6_visual_saved:
		_fail("surface exploration visual was not captured while a citizen occupied the target surface")
		return
	var final_route: Dictionary = surface_navigation.route_between("FLOOR", goal_region, site, goal_surface.anchor)
	if not final_route.reachable or final_route.path.size() < 12 or cable_root.get_child_count() < 7:
		_fail("session infrastructure failed to preserve a usable traversal route: route=%s cable_nodes=%d floor_site=%s target=%s" % [final_route, cable_root.get_child_count(), site, goal_surface.anchor])
		return
	if not _visual_directory.is_empty():
		for phase in ["initial-room", "living-civilization", "citizen-inspection", "target-investigation", "resource-hauling", "construction", "grapple-deployment", "citizen-traversal", "citizen-traversal-detail", "elevated-surface-exploration", "elevated-surface-exploration-detail"]:
			if not _visual_phase_enabled(phase):
				continue
			var expected_image := "%s/%s-%s.png" % [_visual_directory, expected_room, phase]
			if not FileAccess.file_exists(expected_image):
				_fail("required visual evidence phase was not captured: %s" % phase)
				return
		print("ROOMSCALE_VISUAL_EVIDENCE_PASS room=%s phases=%d captured=%s directory=%s" % [expected_room, _captured_visual_phases.size(), _captured_visual_phases, _visual_directory])
	print("ROOMSCALE_ROOM=%s TARGET=%s REGION=%s FLOOR=%.0fx%.0f SITE=%s" % [expected_room, goal_surface.object_name, goal_region, width, depth, site])
	print("ROOMSCALE_M2_SMOKE_PASS room=%s citizens=%d active=%d available=%d moving=%d obstacles=%d detour=%.1fin" % [expected_room, citizens.size(), coordinator.summary().active, coordinator.summary().available, _moving_count(citizens), blocked_count, route_length])
	print("ROOMSCALE_M3_SMOKE_PASS room=%s selected=%s investigators=%d arrived=%d barrier=%s elapsed=%.2fs" % [expected_room, goal_surface.object_name, goal_status.expected_explorers, goal_status.arrived_explorers, goal_status.barrier.reason, investigation_elapsed])
	print("ROOMSCALE_M4_SMOKE_PASS room=%s deliveries=%d delivered=%s builders_returned=true gates=%d components=%d site=%s elapsed=%.2fs" % [expected_room, completed_delivery_count, verified_deliveries, project_status.stage_gates.size(), project_status.completed_stages, site, construction_elapsed])
	print("ROOMSCALE_M5_SMOKE_PASS room=%s cable_segments=%d radius=%.2fin partial_deploy=true traverser=%s height=%.1fin walked=%.1fin route=%.1fin max_step=%.2fin max_step_interval=%.3fs max_sample_speed=%.2fin/s speed_sample_interval=%.3fs speed_cap=%.1fin/s step_tolerance=0.25in elapsed=%.2fs" % [expected_room, cable_segments, largest_cable_radius, climber.name, climber.global_position.y, completed_traversal.actual_travelled_distance, completed_traversal.route_length, max_step, max_step_seconds, max_sample_speed, max_sample_seconds, M6_CITIZEN_WALK_SPEED, traversal_elapsed])
	print("ROOMSCALE_M6_SMOKE_PASS room=%s arrivals=%d explorations=%d reused=%d distinct_travelers=%d work=%.1fs persistent_link=true combined_max_step=%.2fin max_step_interval=%.3fs max_sample_speed=%.2fin/s speed_sample_interval=%.3fs speed_cap=%.1fin/s step_tolerance=0.25in elapsed=%.2fs budget=%.2fs" % [expected_room, m6_status.target_arrivals, m6_status.target_explorations_completed, m6_status.autonomous_reuses_assigned, owners.size(), total_exploration_work, m6_max_step, m6_max_step_seconds, m6_max_sample_speed, m6_max_sample_seconds, M6_CITIZEN_WALK_SPEED, m6_elapsed, m6_timeout])
	print("ROOMSCALE_M8_SMOKE_PASS room=%s steam=%s cog_teeth=%d citizen_inspection=%s camera_easing=verified" % [expected_room, steam.emitting, gears.get_child_count() - 2, inspection_verified])
	quit(0)


func _moving_count(citizens: Array[Node3D]) -> int:
	var count := 0
	for citizen in citizens:
		if citizen.state in ["TRAVEL", "CARRY"] and citizen.travelled_distance > 0.0:
			count += 1
	return count


func _travelled_count(citizens: Array[Node3D]) -> int:
	var count := 0
	for citizen in citizens:
		if citizen.travelled_distance > 0.0:
			count += 1
	return count


func _path_length(path: Array[Vector3]) -> float:
	var total := 0.0
	for index in range(1, path.size()):
		total += path[index - 1].distance_to(path[index])
	return total


func _m6_task_budget_seconds(task: Dictionary) -> float:
	var walk_seconds := float(task.get("route_length", 0.0)) / M6_CITIZEN_WALK_SPEED
	var work_seconds := 4.0 if String(task.get("task_type", "")) == "SURFACE_EXPLORATION" else 0.0
	return walk_seconds * 1.75 + work_seconds + 10.0


func _visual_phase_enabled(phase: String) -> bool:
	var filter := OS.get_environment("ROOMSCALE_VISUAL_PHASES")
	if filter.is_empty():
		return true
	for selected_phase in filter.split(",", false):
		if String(selected_phase).strip_edges() == phase:
			return true
	return false


func _capture_visual(scene: Node3D, phase: String, focus: Vector3, distance: float, tilt: float = 52.0, yaw: float = 0.0, hide_overlay: bool = false, hide_project_label: bool = false) -> bool:
	if _visual_directory.is_empty() or not _visual_phase_enabled(phase):
		return true
	var camera_rig := scene.get_node("CameraRig")
	camera_rig.focus_at(focus, distance, tilt, yaw)
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	var overlay_was_visible := overlay.visible if overlay != null else false
	var project_label := scene.get_node_or_null("GrappleConstructionSite/ProjectSign") as Label3D
	var project_label_was_visible := project_label.visible if project_label != null else false
	if hide_overlay and overlay != null:
		overlay.visible = false
	if hide_project_label and project_label != null:
		project_label.visible = false
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var image: Image = scene.get_viewport().get_texture().get_image()
	if image.get_width() < 320 or image.get_height() < 200:
		if hide_overlay and overlay != null:
			overlay.visible = overlay_was_visible
		if hide_project_label and project_label != null:
			project_label.visible = project_label_was_visible
		_fail("visual capture %s returned an unusable viewport image: %dx%d" % [phase, image.get_width(), image.get_height()])
		return false
	DirAccess.make_dir_recursive_absolute(_visual_directory)
	var definition: Dictionary = scene.get("_room_definition")
	var room_id := String(definition.get("id", "room"))
	var image_path := "%s/%s-%s.png" % [_visual_directory, room_id, phase]
	var save_error := image.save_png(image_path)
	if save_error != OK or not FileAccess.file_exists(image_path):
		if hide_overlay and overlay != null:
			overlay.visible = overlay_was_visible
		if hide_project_label and project_label != null:
			project_label.visible = project_label_was_visible
		_fail("visual capture %s could not save image %s (error=%d)" % [phase, image_path, save_error])
		return false
	var note := FileAccess.open(image_path.get_basename() + ".txt", FileAccess.WRITE)
	if note != null:
		note.store_line("room=%s phase=%s viewport=%dx%d" % [room_id, phase, image.get_width(), image.get_height()])
		note.store_line("target=%s focus=%s distance=%.1f tilt=%.1f yaw=%.2f" % [String(definition.get("target_surface_id", "")), focus, distance, tilt, yaw])
		note.store_line("overlay_hidden=%s" % hide_overlay)
		note.store_line("project_label_hidden=%s" % hide_project_label)
	print("ROOMSCALE_VISUAL_CAPTURE phase=%s path=%s size=%dx%d" % [phase, image_path, image.get_width(), image.get_height()])
	_captured_visual_phases.append(phase)
	if hide_overlay and overlay != null:
		overlay.visible = overlay_was_visible
	if hide_project_label and project_label != null:
		project_label.visible = project_label_was_visible
	return true


func _fail(message: String) -> void:
	push_error("ROOMSCALE_SMOKE_FAIL: " + message)
	quit(1)
