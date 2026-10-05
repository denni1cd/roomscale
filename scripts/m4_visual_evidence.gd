extends SceneTree
const Evidence := preload("res://scripts/verification/evidence_io.gd")
## Visible driver for production Reach/Explore, hauling, and construction evidence.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/pipeline_proof.tscn") as PackedScene
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await process_frame
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var navigation := scene.get_node("SurfaceNavigation")
	var target_surface: Dictionary = navigation.goal_surface()
	var target_pos: Vector2 = camera.unproject_position(target_surface.anchor)
	if not scene.select_surface_at_screen_position(target_pos) or not scene.issue_reach_explore().accepted:
		push_error("M4_EVIDENCE_FAIL: production target-surface selection/Reach failed")
		quit(1)
		return
	var coordinator := scene.get_node("TaskCoordinator")
	var construction := scene.get_node("ConstructionSystem")
	var elapsed := 0.0
	while coordinator.get_reach_goal_status().get("state", "") != "BARRIER_CONFIRMED" and elapsed < 35.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
	var carrier: Node3D
	elapsed = 0.0
	while (carrier == null or not carrier.carrying or int(construction.status().delivered.wood) == 0) and elapsed < 90.0:
		for child in scene.get_children():
			if child.name.begins_with("Citizen") and child.task_type == "CONSTRUCTION_DELIVERY" and child.carrying:
				carrier = child
				break
		await create_timer(0.25).timeout
		elapsed += 0.25
	if carrier == null or not carrier.carrying or int(construction.status().delivered.wood) == 0:
		push_error("M4_EVIDENCE_FAIL: no actual carried depot material observed")
		quit(1)
		return
	var rig := scene.get_node("CameraRig")
	rig.set_view_mode(2)
	rig.set_citizen_focus(carrier)
	rig.zoom_by(2.0)
	await process_frame
	if not _save_capture("milestone4-hauling"): return
	var haul_status: Dictionary = construction.status()
	var haul_proof := FileAccess.open("res://verification/milestone4-visual.log", FileAccess.WRITE)
	haul_proof.store_line("Hauling capture: citizen=%s carrying=%s cargo=%s citizen_view=%d in active_carriers=%d delivered=%s" % [carrier.name, carrier.carrying, carrier.get_node("Figure/Parcel").get_meta("cargo_resource", ""), roundi(rig.distance), construction.active_delivery_count(), JSON.stringify(haul_status.delivered)])
	var build_elapsed := 0.0
	var builders_working := false
	while (construction.status().completed_stages < 1 or construction.status().active_stage != "winch") and build_elapsed < 120.0:
		for task in coordinator.tasks:
			if task.task_type == "CONSTRUCTION_BUILD" and float(task.get("work_seconds", 0.0)) > 0.2:
				builders_working = true
		await create_timer(0.25).timeout
		build_elapsed += 0.25
	if construction.status().completed_stages < 1 or construction.status().active_stage != "winch":
		push_error("M4_EVIDENCE_FAIL: assembled base and winch stage did not become visible")
		quit(1)
		return
	build_elapsed = 0.0
	while construction.status().stage_progress < 0.2 and build_elapsed < 15.0:
		await create_timer(0.25).timeout
		build_elapsed += 0.25
	var builder: Node3D
	for child in scene.get_children():
		if child.name.begins_with("Citizen") and child.task_type == "CONSTRUCTION_BUILD" and child.state != "IDLE":
			builder = child
			break
	rig.set_view_mode(1)
	rig.set_citizen_focus(null)
	rig.target = coordinator.get_construction_site() + Vector3(0.0, 4.0, 0.0)
	rig.distance = 82.0
	rig.tilt_degrees = 42.0
	rig._apply_transform()
	rig.zoom_by(1.0)
	await create_timer(0.75).timeout
	await process_frame
	if not _save_capture("milestone4-construction"): return
	var final_status: Dictionary = construction.status()
	var proof := FileAccess.open("res://verification/milestone4-visual.log", FileAccess.READ_WRITE)
	proof.seek_end()
	proof.store_line("Construction capture: status=%s" % JSON.stringify(final_status))
	proof.store_line("Builder=%s state=%s task=%d work_seconds=%.2f" % [builder.name if builder else "none", builder.state if builder else "none", builder.task_id if builder else -1, float(coordinator.get_task(builder.task_id).get("work_seconds", 0.0)) if builder else 0.0])
	print("ROOMSCALE_M4_VISIBLE_EVIDENCE_PASS haul_and_build_captured")
	quit(0)


func _save_capture(name: String) -> bool:
	var path := "res://verification".path_join(name + ".png")
	var result := Evidence.save_png(root.get_texture().get_image(), path)
	print("ROOMSCALE_M4_CAPTURE path=%s result=%d" % [path, result])
	if result != OK:
		push_error("M4_EVIDENCE_FAIL: screenshot write failed: %s (error=%d)" % [path, result])
		quit(1)
		return false
	return true
