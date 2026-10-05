extends SceneTree
## Wall-clock observer: normal production processing and automatic camera at 1x.
const Evidence := preload("res://scripts/verification/evidence_io.gd")
var scene: Node3D
var sim: Node
var evidence: Array[Dictionary] = []
var directory := "res://verification/poc47/live-1x"

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		fail("Live visual evidence requires a renderer")
		return
	if not OS.get_environment("ROOMSCALE_LIVE_DIR").is_empty(): directory = OS.get_environment("ROOMSCALE_LIVE_DIR")
	OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	root.size = Vector2i(1920,1080)
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	sim = scene.get_node("CivilizationSimulation")
	var started := Time.get_ticks_msec()
	if not await capture("startup"): return
	var next_capture := 30.0
	var shelter_seen := false
	while sim.seconds < 185:
		await create_timer(1).timeout
		if sim.seconds >= next_capture:
			if not await capture("normal-speed-%03d" % int(next_capture)): return
			next_capture += 30
		if not shelter_seen and sim.development.count("shelter") > 0:
			shelter_seen = true
			if not await capture("first-shelter-built-live"): return
	var wall := (Time.get_ticks_msec() - started) / 1000.0
	var passed: bool = sim.speed == 1 and shelter_seen and sim.citizens.size() == 5 and absf(sim.seconds - wall) < 10 and sim.coordinator.summary().failed_total == 0
	var result := {"result":"PASS" if passed else "FAIL", "wall_seconds":wall,"simulation_seconds":sim.seconds,"speed":sim.speed,"shelter_built":shelter_seen,"snapshots":evidence,"projects":sim.development.projects}
	var error := Evidence.save_json(result, directory.path_join("result.json"))
	if error != OK:
		fail("Result write failed (error=%d)" % error)
		return
	print("POC47_LIVE_" + ("PASS" if passed else "FAIL"))
	scene.queue_free()
	await process_frame
	quit(0 if passed else 1)

func capture(label: String) -> bool:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := directory.path_join(label + ".png")
	var error := Evidence.save_png(root.get_texture().get_image(), path)
	if error != OK:
		fail("Screenshot write failed: %s (error=%d)" % [path, error])
		return false
	evidence.append({"label":label,"seconds":sim.seconds,"state":sim.status(),"shot":sim.camera_director.current_shot.duplicate(true)})
	return true

func fail(reason: String) -> void:
	push_error("POC47_LIVE_FAIL " + reason)
	if is_instance_valid(scene): scene.queue_free()
	quit(1)
