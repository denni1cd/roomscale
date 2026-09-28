extends SceneTree
const Loader := preload("res://scripts/room_definition.gd")
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var loaded: Dictionary = Loader.load_requested()
	if not bool(loaded.get("ok", false)):
		push_error("EYE_CAPTURE_LOAD_FAIL %s" % loaded.get("errors", [])); quit(1); return
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame
	var output_dir := OS.get_environment("ROOMSCALE_CAPTURE_DIR")
	var rig := scene.get_node("CameraRig")	
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null: overlay.visible = false
	var captures := [
		{"name":"window-corner-eye", "yaw":deg_to_rad(315.0), "distance":105.0},
		{"name":"desk-wall-eye", "yaw":deg_to_rad(45.0), "distance":105.0},
		{"name":"room-overview-eye", "yaw":deg_to_rad(90.0), "distance":115.0}
	]
	for capture in captures:
		rig.focus_at(Vector3(0.0, 24.0, 0.0), float(capture.distance), 18.0, float(capture.yaw))
		await create_timer(0.45).timeout
		await RenderingServer.frame_post_draw
		var image: Image = scene.get_viewport().get_texture().get_image()
		var path := "%s/room_photo_luna-%s.png" % [output_dir, String(capture.name)]
		var error := image.save_png(path)
		if error != OK:
			push_error("EYE_CAPTURE_SAVE_FAIL path=%s error=%d" % [path, error]); quit(1); return
		print("EYE_CAPTURE_PASS %s size=%dx%d" % [path, image.get_width(), image.get_height()])
	quit(0)

