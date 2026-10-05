extends "res://scripts/poc472_observer.gd"
## Control run: no startup planner queries and no continuous invariant observer.
func run() -> void:
	started = Time.get_ticks_msec()
	config = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("ROOMSCALE_POC471_CONFIG")))
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	sim = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	initial = snapshot()
	validation = {"mode": "milestone sampler only; no planner certificate or invariant queries"}
	var limit := float(config.days) * 600
	while sim.seconds + .00001 < limit:
		for tick in range(200):
			if sim.seconds + .00001 >= limit: break
			sim.step()
			observe()
		await process_frame
	finish()
