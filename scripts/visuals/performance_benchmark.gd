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
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var camera := scene.get_node("CameraRig")
	var subject := scene.get_node("Citizen01") as Node3D
	var definition: Dictionary = scene.get("_room_definition")
	var landmark: Array = definition.landmarks.workshop
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
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Performance output could not be written: " + output)
		quit(1)
		return
	file.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "vsync": "disabled", "results": results}, "  "))
	print("ROOMSCALE_PERFORMANCE_PASS %s" % [results])
	quit()
