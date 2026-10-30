extends SceneTree
## Standalone real-population renderer measurements; no simulation shortcuts.
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Performance benchmark requires the real renderer")
		quit(1)
		return
	OS.set_environment("ROOMSCALE_ROOM", "room_a")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_CIVILIZATION", "clockwork")
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	var camera: Node
	var citizens: Array = []
	var definition: Dictionary = {}
	for frame in range(120):
		await process_frame
		camera = scene.get_node_or_null("CameraRig")
		var citizens_variant: Variant = scene.get("_citizens")
		if citizens_variant is Array:
			citizens = citizens_variant
		var definition_variant: Variant = scene.get("_room_definition")
		if definition_variant is Dictionary:
			definition = definition_variant
		if camera != null and citizens.size() == 50 and definition.has("landmarks"):
			break
	if camera == null or citizens.size() != 50 or not definition.has("landmarks"):
		push_error("Performance benchmark could not find the initialized camera, 50 citizens, and RoomDefinition")
		quit(1)
		return
	var subject := citizens[0] as Node3D
	var landmarks: Dictionary = definition.get("landmarks", {})
	var landmark: Array = landmarks.get("workshop", [])
	if subject == null or landmark.size() != 3:
		push_error("Performance benchmark could not resolve the citizen subject or workshop landmark")
		quit(1)
		return
	for view in ["room", "settlement", "citizen"]:
		if view == "room":
			camera.focus_at(Vector3.ZERO, 330.0)
		elif view == "settlement":
			camera.focus_at(Vector3(float(landmark[0]), float(landmark[1]) + 4.0, float(landmark[2])), 42.0, 35.0, 0.4)
		else:
			camera.focus_at(subject.global_position + Vector3.UP * 0.25, 2.0, 24.0, 0.3)
			camera.distance = 2.0
			camera.call("_apply_transform")
		await create_timer(2.0).timeout
		var samples: Array[float] = []
		var started := Time.get_ticks_usec()
		var previous := started
		while samples.size() < 360 or Time.get_ticks_usec() - started < 8000000:
			if view == "citizen":
				camera.target = subject.global_position + Vector3.UP * 0.25
				camera.call("_apply_transform")
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append(float(now - previous) / 1000.0)
			previous = now
		var elapsed := float(Time.get_ticks_usec() - started) / 1000000.0
		samples.sort()
		results.append({"view": view, "frames": samples.size(), "duration_seconds": elapsed, "fps": samples.size() / elapsed, "median_ms": samples[samples.size() / 2], "p95_ms": samples[floori(samples.size() * 0.95)], "max_ms": samples.back(), "cpu_process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "population": 50})
	var output := OS.get_environment("ROOMSCALE_PERFORMANCE_PATH")
	if output.is_empty():
		output = "res://verification/poc3/performance.json"
	var output_directory := output.get_base_dir()
	if output_directory.begins_with("res://"):
		output_directory = ProjectSettings.globalize_path(output_directory)
	DirAccess.make_dir_recursive_absolute(output_directory)
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Performance output could not be written: " + output)
		quit(1)
		return
	var report := {
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"vsync": "disabled",
		"art_registry_path": OS.get_environment("ROOMSCALE_ART_REGISTRY"),
		"art_registry_mode": OS.get_environment("ROOMSCALE_ART_REGISTRY_MODE"),
		"review_label": "BEST CURRENT / PRODUCTION ART FOLLOW-UP REQUIRED" if OS.get_environment("ROOMSCALE_ART_REGISTRY_MODE") == "review_showcase" else "",
		"results": results,
	}
	file.store_string(JSON.stringify(report, "  "))
	print("ROOMSCALE_PERFORMANCE_PASS %s" % [results])
	quit()
