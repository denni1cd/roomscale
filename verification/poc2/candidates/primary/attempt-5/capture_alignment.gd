extends SceneTree

const Loader := preload("res://scripts/room_definition.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var loaded: Dictionary = Loader.load_requested()
	if not bool(loaded.get("ok", false)):
		push_error("ALIGNMENT_CAPTURE_LOAD_FAIL %s" % loaded.get("errors", []))
		quit(1)
		return
	var packed := load("res://scenes/pipeline_proof.tscn") as PackedScene
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame
	var definition: Dictionary = loaded.definition
	var output_dir := OS.get_environment("ROOMSCALE_CAPTURE_DIR")
	var camera_rig := scene.get_node("CameraRig")	
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null:
		overlay.visible = false
	var captures := [
		{"name": "window-corner", "yaw": deg_to_rad(315.0), "distance": 220.0},
		{"name": "desk-wall", "yaw": deg_to_rad(45.0), "distance": 220.0},
		{"name": "room-overview", "yaw": deg_to_rad(90.0), "distance": 270.0}
	]
	for capture in captures:
		camera_rig.focus_at(Vector3(0.0, 28.0, 0.0), float(capture.distance), 60.0, float(capture.yaw))
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		var image: Image = scene.get_viewport().get_texture().get_image()
		var filename := "%s/room_photo_luna-%s.png" % [output_dir, String(capture.name)]
		var error := image.save_png(filename)
		if error != OK:
			push_error("ALIGNMENT_CAPTURE_SAVE_FAIL path=%s error=%d" % [filename, error])
			quit(1)
			return
		print("ALIGNMENT_CAPTURE_PASS room=%s objects=%d name=%s path=%s size=%dx%d" % [String(definition.id), (definition.get("objects", []) as Array).size(), String(capture.name), filename, image.get_width(), image.get_height()])
	quit(0)
