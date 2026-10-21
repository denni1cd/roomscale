extends SceneTree
## Fractional pace changes wall scheduling, while the authoritative fixed tick stays 0.1s.

const Pipeline := preload("res://scenes/pipeline_proof.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_WP7_CHECK_PASS " + label)
	else:
		failures.append(label)
		print("POC56_WP7_CHECK_FAIL " + label)

func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_INITIAL_SPEED", "0.5")
	var scene := Pipeline.instantiate()
	root.add_child(scene)
	await process_frame
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	check(is_equal_approx(sim.speed, 0.5), "configured initial pace honors the setup selection")
	check(sim.spectator.speed_buttons.has(0.5) and sim.spectator.speed_buttons[0.5].text == "0.5×", "normal fishbowl controls expose and accurately label half speed")
	check(sim.hud._speed_text(0.5) == "0.5x" and sim.spectator._speed_text(0.5) == "0.5×", "both normal speed displays preserve the fractional multiplier")
	sim.advance_elapsed_time(1.0)
	check(absf(sim.seconds - 0.5) < 0.0001, "half-speed selection advances half a simulation second per wall second")
	sim.speed = 1.0
	sim.advance_elapsed_time(1.0)
	check(absf(sim.seconds - 1.5) < 0.0001 and is_equal_approx(sim.world_simulation.STEP, 0.1), "switching to 1x preserves the ten hertz fixed simulation reference")
	scene.queue_free()
	await process_frame
	OS.set_environment("ROOMSCALE_INITIAL_SPEED", "")
	print("POC56_WP7_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
