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
	if change_scene_to_file("res://scenes/pipeline_proof.tscn") != OK:
		quit(1)
		return
	await scene_changed
	var scene := current_scene as Node3D
	for _frame in range(90):
		await process_frame
	var citizen := scene.get_node("Citizen10") as Node3D
	var rig := scene.get_node("CameraRig")
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null:
		overlay.visible = false
	var directory := ProjectSettings.globalize_path("res://verification/poc25/baseline/citizen-open-probe")
	DirAccess.make_dir_recursive_absolute(directory)
	var yaws := [0.0, 0.785398, 1.570796, 2.356194, 3.141593, 3.926991, 4.712389, 5.497787]
	for index in range(yaws.size()):
		var focus: Vector3 = citizen.global_position + Vector3.UP * 0.25
		rig.focus_at(focus, 3.0, 40.0, float(yaws[index]))
		rig.distance = 3.0
		rig.call("_apply_transform")
		citizen.refresh_visual_lod()
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		var path := directory.path_join("citizen10-yaw-%02d.png" % index)
		image.save_png(path)
		var note := FileAccess.open(path.get_basename() + ".txt", FileAccess.WRITE)
		note.store_line("citizen=%s state=%s task=%s position=%s camera=%s target=%s projection=%s fov=%s" % [citizen.name, citizen.get("state"), citizen.get("task_type"), citizen.global_position, camera.global_position, focus, camera.unproject_position(citizen.global_position + Vector3.UP * 0.4), camera.fov])
		print("CITIZEN_OPEN_VIEW %d position=%s path=%s" % [index, citizen.global_position, path])
	quit(0)
