extends SceneTree
## Visible evidence for autonomous desk exploration and a later cable-route reuse.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/pipeline_proof.tscn") as PackedScene
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await process_frame
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var desk_pos: Vector2 = camera.unproject_position(Vector3(-58.0, 30.0, -52.0))
	if not scene.select_surface_at_screen_position(desk_pos) or not scene.issue_reach_explore().accepted:
		_fail("production desk selection/Reach failed")
		return
	var coordinator := scene.get_node("TaskCoordinator")
	var construction := scene.get_node("ConstructionSystem")
	var elapsed := 0.0
	while coordinator.get_reach_goal_status().get("state", "") != "BARRIER_CONFIRMED" and elapsed < 40.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
	if coordinator.get_reach_goal_status().get("state", "") != "BARRIER_CONFIRMED":
		_fail("barrier scenario timed out")
		return
	elapsed = 0.0
	while (construction.status().completed_stages < 3 or not construction.status().cable_deployed) and elapsed < 130.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
	if not construction.status().cable_deployed:
		_fail("construction did not deploy the cable")
		return
	var project_sign := scene.get_node_or_null("GrappleConstructionSite/ProjectSign") as Label3D
	if is_instance_valid(project_sign):
		project_sign.visible = false
	var rig := scene.get_node("CameraRig")
	var first_explorer: Node3D
	var explore_task: Dictionary = {}
	elapsed = 0.0
	while elapsed < 70.0:
		for child in scene.get_children():
			if child.name.begins_with("Citizen") and child.task_type == "DESK_EXPLORATION" and child.state == "WORK":
				first_explorer = child
				explore_task = coordinator.get_task(child.task_id)
				break
		if first_explorer != null:
			break
		await create_timer(0.2).timeout
		elapsed += 0.2
	if first_explorer == null:
		_fail("first citizen did not visibly begin desk exploration")
		return
	rig.set_view_mode(2)
	rig.distance = 8.0
	rig.tilt_degrees = 38.0
	rig._apply_transform()
	var close_camera := rig.get_node("Camera") as Camera3D
	var screen_right := close_camera.global_transform.basis.x.normalized()
	var screen_up := close_camera.global_transform.basis.y.normalized()
	rig.set_citizen_focus(first_explorer, Vector3(0.0, 0.25, 0.0) - screen_right * 2.4 + screen_up * 1.0)
	rig.distance = 8.0
	rig._apply_transform()
	await process_frame
	await process_frame
	_save_capture("milestone6-desk-exploration")
	var reuse_citizen: Node3D
	elapsed = 0.0
	while elapsed < 50.0:
		for child in scene.get_children():
			if child.name.begins_with("Citizen") and child.task_type == "GRAPPLE_TRAVERSAL" and bool(coordinator.get_task(child.task_id).get("autonomous_reuse", false)) and child.global_position.y > 14.0:
				reuse_citizen = child
				break
		if reuse_citizen != null:
			break
		await create_timer(0.2).timeout
		elapsed += 0.2
	if reuse_citizen == null:
		_fail("second citizen did not autonomously reuse the deployed route")
		return
	rig.set_view_mode(2)
	rig.distance = 8.0
	rig.tilt_degrees = 28.0
	rig.yaw = 0.0
	rig._apply_transform()
	rig.set_citizen_focus(reuse_citizen, Vector3(-1.5, 1.5, 0.0))
	rig.distance = 8.0
	rig._apply_transform()
	await create_timer(0.3).timeout
	scene._update_population_ui()
	await process_frame
	_save_capture("milestone6-autonomous-route-reuse")
	var m6: Dictionary = coordinator.get_m6_status()
	var proof := FileAccess.open("res://verification/milestone6-visual.log", FileAccess.WRITE)
	proof.store_line("Desk exploration capture: citizen=%s position=%s state=%s work_seconds=%.2f route=%.1fin walked=%.1fin" % [first_explorer.name, first_explorer.global_position, first_explorer.state, explore_task.get("work_seconds", 0.0), explore_task.get("route_length", 0.0), explore_task.get("actual_travelled_distance", 0.0)])
	proof.store_line("Autonomous reuse capture: citizen=%s position=%s state=%s task=%s cable_segments=%d arrivals=%d reuses=%d infrastructure=%s" % [reuse_citizen.name, reuse_citizen.global_position, reuse_citizen.state, JSON.stringify(coordinator.get_task(reuse_citizen.task_id)), scene.get_node("DeployedGrappleCable").get_child_count() - 1, m6.desk_arrivals, m6.autonomous_reuses_assigned, m6.infrastructure_operational])
	print("ROOMSCALE_M6_VISIBLE_EVIDENCE_PASS exploration_and_autonomous_route_reuse_captured")
	quit(0)


func _fail(message: String) -> void:
	push_error("M6_EVIDENCE_FAIL: " + message)
	quit(1)


func _save_capture(name: String) -> void:
	var directory := ProjectSettings.globalize_path("res://verification")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := "%s/%s.png" % [directory, name]
	var result := get_root().get_viewport().get_texture().get_image().save_png(path)
	print("ROOMSCALE_M6_CAPTURE path=%s result=%d" % [path, result])
