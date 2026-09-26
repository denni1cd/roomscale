extends SceneTree
## Visible evidence driver; exercises the same surface-pick and goal APIs used by the game UI.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/pipeline_proof.tscn") as PackedScene
	if packed == null:
		push_error("M3_EVIDENCE_FAIL: main scene did not load")
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.capture_interaction_state()
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var navigation := scene.get_node("SurfaceNavigation")
	var target_surface: Dictionary = navigation.goal_surface()
	var target_screen_position := camera.unproject_position(target_surface.anchor)
	if not scene.select_surface_at_screen_position(target_screen_position):
		push_error("M3_EVIDENCE_FAIL: production target-surface screen-ray selection failed")
		quit(1)
		return
	await process_frame
	scene.capture_interaction_state()
	var goal: Dictionary = scene.issue_reach_explore()
	if not goal.accepted:
		push_error("M3_EVIDENCE_FAIL: Reach / Explore rejected selection: %s" % goal)
		quit(1)
		return
	var coordinator := scene.get_node("TaskCoordinator")
	var elapsed := 0.0
	var status: Dictionary = coordinator.get_reach_goal_status()
	while status.state != "BARRIER_CONFIRMED" and elapsed < 35.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
		status = coordinator.get_reach_goal_status()
	if status.state != "BARRIER_CONFIRMED":
		push_error("M3_EVIDENCE_FAIL: explorers did not confirm the barrier in time: %s" % status)
		quit(1)
		return
	await process_frame
	scene.capture_interaction_state()
	print("ROOMSCALE_M3_VISIBLE_EVIDENCE_PASS explorers=%d/%d elapsed=%.2fs" % [status.arrived_explorers, status.expected_explorers, elapsed])
	quit(0)
