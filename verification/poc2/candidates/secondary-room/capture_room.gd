extends SceneTree

const Loader := preload("res://scripts/room_definition.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var loaded: Dictionary = Loader.load_requested()
	if not bool(loaded.get("ok", false)):
		push_error("SECOND_ROOM_CAPTURE_LOAD_FAIL %s" % loaded.get("errors", []))
		quit(1)
		return
	var definition: Dictionary = loaded.definition
	var room_id := String(definition.get("id", "room"))
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame
	var output_dir := OS.get_environment("ROOMSCALE_CAPTURE_DIR")
	if output_dir.is_empty():
		push_error("SECOND_ROOM_CAPTURE_FAIL ROOMSCALE_CAPTURE_DIR is empty")
		quit(1)
		return
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null:
		overlay.visible = false
	var settlement := scene.get_node_or_null("Settlement") as Node3D
	if settlement != null:
		settlement.visible = false
	var citizens: Array = scene.get("_citizens")	
	for citizen_value in citizens:
		var citizen := citizen_value as Node3D
		if is_instance_valid(citizen):
			citizen.visible = false
	var rig := scene.get_node("CameraRig")
	var captures := [
		{"name":"hearth-and-builtins", "yaw":0.0, "distance":238.0, "tilt":38.0, "focus":Vector3(0.0, 38.0, -48.0)},
		{"name":"coffee-table-detail", "yaw":deg_to_rad(-24.0), "distance":108.0, "tilt":32.0, "focus":Vector3(0.0, 27.0, 12.0)},
		{"name":"shaded-windows-and-slider", "yaw":deg_to_rad(-90.0), "distance":205.0, "tilt":38.0, "focus":Vector3(62.0, 40.0, 15.0)},
		{"name":"opposite-wall-and-sofa", "yaw":PI, "distance":210.0, "tilt":36.0, "focus":Vector3(0.0, 42.0, 52.0), "hide_wall":"hearth-wall"}
	]
	for capture in captures:
		var hide_wall_id := String(capture.get("hide_wall", ""))
		var wall_to_restore := scene.get_node_or_null("Room/ShellWall_%s" % hide_wall_id) as Node3D if not hide_wall_id.is_empty() else null
		var wall_was_visible := wall_to_restore.visible if wall_to_restore != null else false
		if wall_to_restore != null:
			wall_to_restore.visible = false
		rig.focus_at(capture.focus, float(capture.distance), float(capture.tilt), float(capture.yaw))
		await create_timer(0.45).timeout
		await RenderingServer.frame_post_draw
		var image: Image = scene.get_viewport().get_texture().get_image()
		var output_path := "%s/%s-%s.png" % [output_dir, room_id, String(capture.name)]
		var error := image.save_png(output_path)
		if error != OK:
			push_error("SECOND_ROOM_CAPTURE_SAVE_FAIL path=%s error=%d" % [output_path, error])
			quit(1)
			return
		print("SECOND_ROOM_CAPTURE_PASS room=%s image=%s size=%dx%d" % [room_id, output_path, image.get_width(), image.get_height()])
		if wall_to_restore != null:
			wall_to_restore.visible = wall_was_visible
	quit(0)
