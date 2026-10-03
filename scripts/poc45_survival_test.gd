extends SceneTree
var sim: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_poc4")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	sim = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	for batch in range(2000):
		for tick in range(10): sim.step()
		if not sim.economy.audit().is_empty() or not sim.resources.audit().is_empty():
			push_error("POC45_SURVIVAL_FAIL conservation")
			quit(1)
			return
		if sim.construction.traversal_deployed and sim.source_visits.water > 0 and sim.economy.available.water > 200 and sim.salvage.stage_completions >= 4:
			print("POC45_SURVIVAL_PASS seconds=%.1f state=%s events=%s" % [sim.seconds, JSON.stringify(sim.status()), JSON.stringify(sim.journal.events)])
			scene.queue_free()
			await process_frame
			quit()
			return
		if batch % 100 == 0: await process_frame
	push_error("POC45_SURVIVAL_FAIL timeout " + JSON.stringify(sim.status()))
	quit(1)
