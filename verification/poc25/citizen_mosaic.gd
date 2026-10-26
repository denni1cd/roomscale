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
	var rig := scene.get_node("CameraRig")
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null:
		overlay.visible = false
	var citizens: Array[Node3D] = []
	for child in scene.get_children():
		if child.name.begins_with("Citizen") and child is Node3D:
			citizens.append(child)
	var cell := Image.create(256, 144, false, Image.FORMAT_RGBA8)
	var sheet := Image.create(1280, 1440, false, Image.FORMAT_RGBA8)
	var index_file := FileAccess.open("res://verification/poc25/baseline/citizen-mosaic-index.tsv", FileAccess.WRITE)
	for index in range(citizens.size()):
		var citizen := citizens[index]
		var target: Vector3 = citizen.global_position + Vector3.UP * 0.25
		var yaw := fposmod(float(index) * 2.399963, TAU)
		rig.focus_at(target, 8.0, 65.0, yaw)
		rig.distance = 8.0
		rig.call("_apply_transform")
		citizen.refresh_visual_lod()
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		image.resize(256, 144, Image.INTERPOLATE_LANCZOS)
		var x := (index % 5) * 256
		var y := floori(float(index) / 5.0) * 144
		sheet.blit_rect(image, Rect2i(Vector2i.ZERO, Vector2i(256, 144)), Vector2i(x, y))
		index_file.store_line("%d\t%s\t%s\t%s\t%s" % [index, citizen.name, citizen.global_position, citizen.get("state"), citizen.get("task_type")])
	var output := ProjectSettings.globalize_path("res://verification/poc25/baseline/citizen-mosaic.png")
	sheet.save_png(output)
	print("CITIZEN_MOSAIC count=%d output=%s camera=%s" % [citizens.size(), output, camera.global_position])
	quit(0)
