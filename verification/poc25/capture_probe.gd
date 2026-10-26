extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_ROOM", "room_photo_luna")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "verification/poc2/candidates/primary/attempt-7/room_photo_luna.json")
	OS.set_environment("ROOMSCALE_CIVILIZATION", "clockwork")
	root.size = Vector2i(1280, 720)
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	if error != OK:
		push_error("scene load failed: %s" % error)
		quit(1)
		return
	await scene_changed
	var scene := current_scene as Node3D
	for _frame in range(90):
		await process_frame
	var citizen := scene.get_node("Citizen01") as Node3D
	var rig := scene.get_node("CameraRig")
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var directory := ProjectSettings.globalize_path("res://verification/poc25/baseline/citizen-probes")
	DirAccess.make_dir_recursive_absolute(directory)
	var shots := [
		{"name":"close-yaw0", "distance":2.0, "tilt":24.0, "yaw":0.0, "focus_y":0.25},
		{"name":"close-yaw90", "distance":2.0, "tilt":24.0, "yaw":1.5708, "focus_y":0.25},
		{"name":"close-higher", "distance":3.0, "tilt":55.0, "yaw":0.0, "focus_y":0.55},
		{"name":"normal-close", "distance":5.0, "tilt":55.0, "yaw":0.0, "focus_y":0.55},
		{"name":"raised", "distance":12.0, "tilt":65.0, "yaw":0.0, "focus_y":4.0}
	]
	for shot in shots:
		var focus: Vector3 = citizen.global_position + Vector3.UP * float(shot.focus_y)
		rig.focus_at(focus, float(shot.distance), float(shot.tilt), float(shot.yaw))
		rig.distance = float(shot.distance)
		rig.call("_apply_transform")
		citizen.refresh_visual_lod()
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		var path := directory.path_join("%s.png" % shot.name)
		image.save_png(path)
		var figure := citizen.get_node("Figure") as Node3D
		var data := FileAccess.open(path.get_basename() + ".txt", FileAccess.WRITE)
		data.store_line("shot=%s citizen=%s citizen_pos=%s figure_pos=%s cam=%s target=%s projection=%s behind=%s fov=%s" % [shot.name, citizen.name, citizen.global_position, figure.global_position, camera.global_position, focus, camera.unproject_position(figure.global_position + Vector3.UP * 0.25), camera.is_position_behind(figure.global_position), camera.fov])
		print("CAPTURE_PROBE %s %s" % [shot.name, path])
	quit(0)
