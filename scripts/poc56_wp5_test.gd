extends SceneTree
## Population UI adapter must report live model state without becoming a second rule system.

const Pipeline := preload("res://scenes/pipeline_proof.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_WP5_CHECK_PASS " + label)
	else:
		failures.append(label)
		print("POC56_WP5_CHECK_FAIL " + label)

func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	var scene := Pipeline.instantiate()
	root.add_child(scene)
	await process_frame
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	sim.seconds = 120.0
	sim.population.stable_since = 0.0
	sim.population.last_growth = 0.0
	sim.population.reason = "Healthy stability window 120/300 seconds"
	var state: Dictionary = sim.status()
	state.shelter = 10
	var before := {"stable_since":sim.population.stable_since, "last_growth":sim.population.last_growth, "reason":sim.population.reason}
	var snapshot: Dictionary = sim.population.player_snapshot(sim, state)
	check(snapshot.population == state.population and snapshot.shelter_capacity == 10 and snapshot.headroom == 5, "growth snapshot exposes population, shelter, and headroom from authoritative status")
	check(snapshot.cohort_size == sim.population.cohort_size and snapshot.reason == sim.population.reason, "growth snapshot preserves authoritative cohort and blocker explanation")
	check(absf(float(snapshot.stable_seconds) - 120.0) < 0.001 and absf(float(snapshot.cooldown_remaining) - 480.0) < 0.001, "growth snapshot reports stability accumulation and cooldown")
	var after := {"stable_since":sim.population.stable_since, "last_growth":sim.population.last_growth, "reason":sim.population.reason}
	check(before == after, "read-only growth presentation does not change population rules or timers")
	sim.hud.refresh()
	sim.spectator.refresh()
	check(sim.hud.strategy.text.contains("Growth 0/1 shelter spaces") and sim.hud.strategy.text.contains(sim.population.reason), "normal settlement HUD explains available growth space and reason")
	check(sim.spectator.governor_label.text.contains("Growth 0/1 shelter spaces") and sim.spectator.governor_label.text.contains("Stability 120/300 sec"), "fishbowl HUD shows growth reason and stability progress without diagnostics")
	scene.queue_free()
	await process_frame
	print("POC56_WP5_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
