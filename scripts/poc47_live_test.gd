extends SceneTree
## Wall-clock observer: normal production _process and automatic camera at 1x.
var scene: Node3D
var sim: Node
var evidence: Array[Dictionary] = []
var directory := "res://verification/poc47/live-1x"

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if not OS.get_environment("ROOMSCALE_LIVE_DIR").is_empty(): directory = OS.get_environment("ROOMSCALE_LIVE_DIR")
	OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	root.size = Vector2i(1920,1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	sim = scene.get_node("CivilizationSimulation")
	var started := Time.get_ticks_msec()
	await capture("startup")
	var next_capture := 30.0
	var shelter_seen := false
	while sim.seconds < 185:
		await create_timer(1).timeout
		if sim.seconds >= next_capture:
			await capture("normal-speed-%03d" % int(next_capture))
			next_capture += 30
		if not shelter_seen and sim.development.count("shelter") > 0:
			shelter_seen = true
			await capture("first-shelter-built-live")
	var wall := (Time.get_ticks_msec() - started) / 1000.0
	var passed: bool = sim.speed == 1 and shelter_seen and sim.citizens.size() == 5 and absf(sim.seconds - wall) < 10 and sim.coordinator.summary().failed_total == 0
	FileAccess.open(directory.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify({"result":"PASS" if passed else "FAIL", "wall_seconds":wall,"simulation_seconds":sim.seconds,"speed":sim.speed,"shelter_built":shelter_seen,"snapshots":evidence,"projects":sim.development.projects},"\t"))
	print("POC47_LIVE_" + ("PASS" if passed else "FAIL"))
	scene.queue_free()
	await process_frame
	quit(0 if passed else 1)

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(label + ".png"))
	evidence.append({"label":label,"seconds":sim.seconds,"state":sim.status(),"shot":sim.camera_director.current_shot.duplicate(true)})
