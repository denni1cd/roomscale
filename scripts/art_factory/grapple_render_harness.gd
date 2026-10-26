extends SceneTree
## Candidate evidence through the live RoomScale reach/investigate/build workflow.

var output_directory := ""
var candidate_id := ""
var expected_asset_path := ""
var captures: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	candidate_id = OS.get_environment("ROOMSCALE_ART_FACTORY_CANDIDATE")
	output_directory = OS.get_environment("ROOMSCALE_ART_FACTORY_RENDER_DIR")
	expected_asset_path = OS.get_environment("ROOMSCALE_ART_FACTORY_EXPECTED_ASSET")
	var registry_path := OS.get_environment("ROOMSCALE_ART_REGISTRY")
	var room_file := OS.get_environment("ROOMSCALE_ART_FACTORY_ROOM_FILE")
	if candidate_id.is_empty() or output_directory.is_empty() or expected_asset_path.is_empty() or registry_path.is_empty():
		_fail("candidate, render path, expected asset, and registry override are required")
		return
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_ART_REGISTRY", registry_path)
	if room_file.is_empty():
		room_file = "verification/poc2/candidates/primary/attempt-7/room_photo_luna.json"
	OS.set_environment("ROOMSCALE_ROOM_FILE", room_file)
	if OS.get_environment("ROOMSCALE_ROOM").is_empty():
		OS.set_environment("ROOMSCALE_ROOM", "room_photo_luna")
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(output_directory)
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	if error != OK:
		_fail("production scene could not load: %s" % error)
		return
	await scene_changed
	var scene := current_scene as Node3D
	if scene == null or not scene.is_node_ready():
		_fail("RoomScale production scene did not become ready")
		return
	for _frame in range(8):
		await process_frame
	var navigation := scene.get_node("SurfaceNavigation")
	var goal_region := String(navigation.goal_surface_id)
	var coordinator := scene.get_node("TaskCoordinator")
	var construction := scene.get_node("ConstructionSystem")
	if not scene.select_goal_surface(goal_region):
		_fail("production scene could not select its configured target surface")
		return
	var request: Dictionary = scene.issue_reach_explore()
	if not bool(request.get("accepted", false)):
		_fail("normal Reach / Explore action did not start: %s" % request)
		return
	var elapsed := 0.0
	while String(coordinator.get_reach_goal_status().get("state", "")) != "BARRIER_CONFIRMED" and elapsed < 45.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
	if String(coordinator.get_reach_goal_status().get("state", "")) != "BARRIER_CONFIRMED" or not construction.has_project():
		_fail("autonomous explorers did not establish the construction project: goal=%s" % coordinator.get_reach_goal_status())
		return
	var asset_root := _find_asset_node(scene)
	if asset_root == null:
		_fail("production construction did not load the registered grapple candidate")
		return
	if String(asset_root.get_meta("visual_source", "")) != expected_asset_path or String(asset_root.get_meta("visual_asset_candidate_id", "")) != candidate_id:
		_fail("production construction did not load the requested candidate: path=%s id=%s" % [asset_root.get_meta("visual_source", ""), asset_root.get_meta("visual_asset_candidate_id", "")])
		return
	elapsed = 0.0
	while not (String(construction.status().active_stage) == "winch" and float(construction.status().stage_progress) >= 0.25) and elapsed < 150.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
	var status: Dictionary = construction.status()
	if String(status.active_stage) != "winch" or float(status.stage_progress) < 0.25:
		_fail("normal construction did not reveal the winch assembly: %s" % status)
		return
	var site := scene.get_node("GrappleConstructionSite") as Node3D
	var camera_rig := scene.get_node("CameraRig")
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null:
		overlay.visible = false
	var project_label := site.get_node_or_null("ProjectSign") as Label3D
	if project_label != null:
		project_label.visible = false
	if not await _capture(scene, camera_rig, "construction", site.global_position + Vector3.UP * 6.0, 34.0, 45.0, 2.6):
		return
	elapsed = 0.0
	while not bool(construction.status().cable_deployed) and elapsed < 120.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
	status = construction.status()
	if not bool(status.cable_deployed):
		_fail("normal builders did not complete and deploy the grapple: %s" % status)
		return
	var target_surface: Dictionary = navigation.goal_surface()
	var deployment_focus: Vector3 = (site.global_position + target_surface.get("anchor", Vector3.ZERO)) * 0.5
	if not await _capture(scene, camera_rig, "grapple-deployment", deployment_focus, 160.0, 65.0, PI):
		return
	if not await _capture(scene, camera_rig, "grapple-complete", site.global_position + Vector3.UP * 5.0, 32.0, 34.0, 0.6):
		return
	var room := scene.get("_room_definition") as Dictionary
	var floor: Dictionary = room.get("floor", {})
	var room_center := Vector3.ZERO
	if floor.get("center") is Array and floor.center.size() == 3:
		room_center = Vector3(float(floor.center[0]), float(floor.get("height", 0.0)) + 10.0, float(floor.center[2]))
	if not await _capture(scene, camera_rig, "room-scale", room_center, 285.0, 78.0, 0.0):
		return
	var target := site.global_position + Vector3.UP * 5.6
	if not await _capture(scene, camera_rig, "asset-three-quarter", target, 22.0, 38.0, 0.62):
		return
	if not await _capture(scene, camera_rig, "asset-opposite-three-quarter", target, 22.0, 38.0, 0.62 + PI):
		return
	if not await _capture(scene, camera_rig, "asset-profile", target, 19.0, 38.0, 0.62 + PI * 0.5):
		return
	if not await _capture(scene, camera_rig, "asset-detail", target + Vector3(0.8, 0.4, 0.7), 16.0, 25.0, 0.25):
		return
	var receipt := {
		"schema_version": 1,
		"production_path": true,
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"room_id": String(room.get("id", "")),
		"asset_id": "grapple",
		"candidate_id": candidate_id,
		"loaded_asset_path": String(asset_root.get_meta("visual_source", "")),
		"loaded_candidate_id": String(asset_root.get_meta("visual_asset_candidate_id", "")),
		"construction_state": status,
		"autonomous_reach_state": coordinator.get_reach_goal_status(),
		"viewport": [root.size.x, root.size.y],
		"captures": captures,
		"performance": {
			"fps": Performance.get_monitor(Performance.TIME_FPS),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		},
	}
	var receipt_file := FileAccess.open(output_directory.path_join("receipt.json"), FileAccess.WRITE)
	if receipt_file == null:
		_fail("could not write the grapple render receipt")
		return
	receipt_file.store_string(JSON.stringify(receipt, "  ") + "\n")
	print("ROOMSCALE_ART_FACTORY_RENDER_PASS asset=grapple candidate=%s project=%s captures=%d output=%s" % [candidate_id, status.project_id, captures.size(), output_directory])
	quit(0)


func _find_asset_node(scene: Node3D) -> Node3D:
	for node in scene.find_children("GrappleArtAsset", "Node3D", true, false):
		if String(node.get_meta("visual_asset_id", "")) == "grapple":
			return node as Node3D
	return null


func _capture(scene: Node3D, rig: Node, phase: String, focus: Vector3, distance: float, tilt: float, yaw: float) -> bool:
	var camera := rig.get_node("Camera") as Camera3D
	rig.focus_at(focus, distance, tilt, yaw)
	rig.distance = distance
	rig.call("_apply_transform")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var image: Image = scene.get_viewport().get_texture().get_image()
	if image.is_empty() or image.get_width() < 320 or image.get_height() < 200:
		_fail("render %s returned unusable dimensions %s" % [phase, image.get_size()])
		return false
	var colors: Dictionary = {}
	for y in range(0, image.get_height(), 24):
		for x in range(0, image.get_width(), 24):
			colors[image.get_pixel(x, y).to_html(false)] = true
	if colors.size() < 40:
		_fail("render %s appears occluded or nearly blank: %d sampled colors" % [phase, colors.size()])
		return false
	var image_path := output_directory.path_join("%s.png" % phase)
	if image.save_png(image_path) != OK:
		_fail("could not save production render %s" % image_path)
		return false
	captures.append({
		"phase": phase,
		"path": image_path,
		"production_path": true,
		"camera": {"focus": focus, "distance_inches": distance, "tilt_degrees": tilt, "yaw_radians": yaw, "fov_degrees": camera.fov},
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
	})
	return true


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_RENDER_FAIL: " + message)
	quit(1)
