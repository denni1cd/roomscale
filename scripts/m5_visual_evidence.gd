extends SceneTree
## Live evidence driver for the deployed grapple and continuous desk traversal.

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
		push_error("M5_EVIDENCE_FAIL: production desk selection/Reach failed")
		quit(1)
		return
	var coordinator := scene.get_node("TaskCoordinator")
	var construction := scene.get_node("ConstructionSystem")
	var elapsed := 0.0
	while coordinator.get_reach_goal_status().get("state", "") != "BARRIER_CONFIRMED" and elapsed < 35.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
	elapsed = 0.0
	while (construction.status().completed_stages < 3 or not construction.status().cable_deployed) and elapsed < 120.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
	if construction.status().completed_stages < 3 or not construction.status().cable_deployed:
		push_error("M5_EVIDENCE_FAIL: completed construction did not deploy traversal cable")
		quit(1)
		return
	var cable_root := scene.get_node_or_null("DeployedGrappleCable") as Node3D
	if cable_root == null or cable_root.get_child_count() < 12:
		push_error("M5_EVIDENCE_FAIL: segmented cable visual is missing")
		quit(1)
		return
	var rig := scene.get_node("CameraRig")
	rig.set_view_mode(1)
	rig.yaw = deg_to_rad(35.0)
	rig.target = Vector3(-36.0, 18.0, -52.0)
	rig.distance = 100.0
	rig.tilt_degrees = 50.0
	rig._apply_transform()
	rig.zoom_by(1.0)
	await process_frame
	_save_capture("milestone5-deployed-cable")
	var climber: Node3D
	for child in scene.get_children():
		if child.name.begins_with("Citizen") and child.task_type == "GRAPPLE_TRAVERSAL":
			climber = child
			break
	if climber == null:
		push_error("M5_EVIDENCE_FAIL: deployed traversal task has no citizen")
		quit(1)
		return
	var traversal_elapsed := 0.0
	while coordinator.get_traversal_goal_status().state != "TRAVERSAL_COMPLETE" and traversal_elapsed < 60.0:
		await create_timer(0.25).timeout
		traversal_elapsed += 0.25
	if coordinator.get_traversal_goal_status().state != "TRAVERSAL_COMPLETE" or climber.global_position.y < 29.0:
		push_error("M5_EVIDENCE_FAIL: citizen did not arrive on the desk")
		quit(1)
		return
	rig.set_view_mode(2)
	rig.distance = 8.0
	rig.tilt_degrees = 38.0
	rig._apply_transform()
	var close_camera := rig.get_node("Camera") as Camera3D
	var screen_right := close_camera.global_transform.basis.x.normalized()
	var screen_up := close_camera.global_transform.basis.y.normalized()
	rig.set_citizen_focus(climber, Vector3(0.0, 0.25, 0.0) - screen_right * 2.4 + screen_up * 1.0)
	rig.distance = 8.0
	rig._apply_transform()
	await process_frame
	_save_capture("milestone5-citizen-on-desk")
	var proof := FileAccess.open("res://verification/milestone5-visual.log", FileAccess.WRITE)
	proof.store_line("Cable capture: segments=%d status=%s" % [cable_root.get_child_count() - 1, JSON.stringify(construction.status())])
	proof.store_line("Desk arrival: citizen=%s state=%s position=%s walked=%.1fin" % [climber.name, climber.state, climber.global_position, coordinator.get_traversal_goal_status().actual_travelled_distance])
	print("ROOMSCALE_M5_VISIBLE_EVIDENCE_PASS cable_and_desk_arrival_captured")
	quit(0)


func _save_capture(name: String) -> void:
	var directory := ProjectSettings.globalize_path("res://verification")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := "%s/%s.png" % [directory, name]
	var result := get_root().get_viewport().get_texture().get_image().save_png(path)
	print("ROOMSCALE_M5_CAPTURE path=%s result=%d" % [path, result])
