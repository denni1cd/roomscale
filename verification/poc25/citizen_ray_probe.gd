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
	await physics_frame
	var rig := scene.get_node("CameraRig")
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var directory := ProjectSettings.globalize_path("res://verification/poc25/baseline/citizen-ray-probe")
	DirAccess.make_dir_recursive_absolute(directory)
	var space := scene.get_world_3d().direct_space_state
	var citizens: Array[Node3D] = []
	for child in scene.get_children():
		if child.name.begins_with("Citizen") and child is Node3D:
			citizens.append(child)
	var found := false
	for citizen in citizens:
		var target := citizen.global_position + Vector3.UP * 0.25
		for angle_index in range(16):
			var yaw := TAU * float(angle_index) / 16.0
			rig.focus_at(target, 4.0, 32.0, yaw)
			rig.distance = 4.0
			rig.call("_apply_transform")
			await process_frame
			var query := PhysicsRayQueryParameters3D.create(camera.global_position, target)
			query.collide_with_areas = true
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				var marker := MeshInstance3D.new()
				marker.name = "CaptureProbeMarker"
				var marker_mesh := SphereMesh.new()
				marker_mesh.radius = 0.3
				marker_mesh.height = 0.6
				marker.mesh = marker_mesh
				var marker_material := StandardMaterial3D.new()
				marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				marker_material.albedo_color = Color.MAGENTA
				marker.material_override = marker_material
				marker.global_position = target + Vector3.UP * 0.5
				scene.add_child(marker)
				var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
				if overlay != null:
					overlay.visible = false
				citizen.refresh_visual_lod()
				await process_frame
				await RenderingServer.frame_post_draw
				var image: Image = root.get_texture().get_image()
				var path := directory.path_join("%s-yaw-%02d-diagnostic.png" % [citizen.name, angle_index])
				image.save_png(path)
				var note := FileAccess.open(path.get_basename() + ".txt", FileAccess.WRITE)
				note.store_line("citizen=%s state=%s task=%s position=%s yaw=%.3f distance=%.1f tilt=32 head_projection=%s head_behind=%s camera=%s active_camera=%s figure_visible=%s body_visible=%s body_global=%s marker_projection=%s" % [citizen.name, citizen.get("state"), citizen.get("task_type"), citizen.global_position, yaw, rig.distance, camera.unproject_position(citizen.global_position + Vector3.UP * 0.42), camera.is_position_behind(citizen.global_position + Vector3.UP * 0.42), camera.global_position, scene.get_viewport().get_camera_3d().global_position, citizen.get_node("Figure").visible, citizen.get_node("Figure/Body").visible, citizen.get_node("Figure/Body").global_position, camera.unproject_position(marker.global_position)])
				print("CLEAR_VIEW citizen=%s yaw=%.3f path=%s" % [citizen.name, yaw, path])
				found = true
				break
		if found:
			break
	if not found:
		push_error("No ray-clear citizen close view was found")
		quit(1)
		return
	quit(0)
