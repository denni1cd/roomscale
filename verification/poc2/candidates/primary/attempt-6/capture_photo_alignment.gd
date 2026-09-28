extends SceneTree
const Loader := preload("res://scripts/room_definition.gd")
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var loaded: Dictionary = Loader.load_requested()
	if not bool(loaded.get("ok", false)):
		push_error("PHOTO_ALIGNMENT_LOAD_FAIL %s" % loaded.get("errors", [])); quit(1); return
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame
	var output_dir := OS.get_environment("ROOMSCALE_CAPTURE_DIR")
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null: overlay.visible = false
	var settlement := scene.get_node_or_null("Settlement") as Node3D
	if settlement != null: settlement.visible = false
	var citizens: Array = scene.get("_citizens")
	for citizen_value in citizens:
		var citizen := citizen_value as Node3D
		if is_instance_valid(citizen): citizen.visible = false
	var rig := scene.get_node("CameraRig")
	var captures := [
		{"name":"window-hammock-view", "yaw":deg_to_rad(315.0), "distance":85.0, "tilt":18.0, "focus":Vector3(0.0,24.0,0.0)},
		{"name":"desk-art-view", "yaw":deg_to_rad(180.0), "distance":85.0, "tilt":22.0, "focus":Vector3(0.0,24.0,10.0)},
		{"name":"doors-window-overview", "yaw":deg_to_rad(90.0), "distance":115.0, "tilt":24.0, "focus":Vector3(0.0,24.0,0.0)}
	]
	for capture in captures:
		rig.focus_at(capture.focus, float(capture.distance), float(capture.tilt), float(capture.yaw))
		await create_timer(0.45).timeout
		await RenderingServer.frame_post_draw
		var image: Image = scene.get_viewport().get_texture().get_image()
		var output_path := "%s/room_photo_luna-%s.png" % [output_dir, String(capture.name)]
		var error := image.save_png(output_path)
		if error != OK:
			push_error("PHOTO_ALIGNMENT_SAVE_FAIL path=%s error=%d" % [output_path, error]); quit(1); return
		print("PHOTO_ALIGNMENT_CAPTURE_PASS room=%s objects=%d image=%s size=%dx%d" % [String(loaded.definition.id), (loaded.definition.objects as Array).size(), output_path, image.get_width(), image.get_height()])
	quit(0)
