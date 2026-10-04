extends SceneTree
## Short uninterrupted automatic-camera replay. Never chooses a target for the director.
const Evidence := preload("res://scripts/verification/evidence_io.gd")

func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("POC46_CAMERA_FAIL: visual evidence requires a renderer")
		quit(1)
		return
	OS.set_environment("ROOMSCALE_ROOM", "room_poc45")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	root.size = Vector2i(1920, 1080)
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	var captured := false
	for tick in range(12000):
		sim.step()
		sim.camera_director.advance(0.01)
		sim.spectator.advance(0.01)
		if tick % 100 == 0:
			await process_frame
			print("CAMERA_OBSERVE seconds=%s distance=%s shot=%s" % [sim.seconds, sim.camera_director.rig.distance, sim.camera_director.current_shot])
		var shot: Dictionary = sim.camera_director.current_shot
		if not captured and shot.has("citizen") and sim.camera_director.rig.distance < 8 and sim.spectator.title_age > 0.5 and sim.spectator.title_age < 5:
			var citizen: Node3D = sim.citizens[int(shot.citizen)]
			if citizen.task_type != shot.activity_task: continue
			if sim.camera_director.rig.target.distance_to(citizen.global_position + Vector3.UP * 0.25) > 0.5: continue
			await process_frame
			for worker in sim.citizens: worker.refresh_visual_lod()
			await RenderingServer.frame_post_draw
			var directory := OS.get_environment("ROOMSCALE_VISUAL_DIR")
			if directory.is_empty(): directory = "res://verification/poc46/visuals-release/scenario-visuals"
			var error := Evidence.save_png(root.get_texture().get_image(), directory.path_join("automatic-worker-detail.png"))
			if error == OK:
				error = Evidence.save_json({"seconds": sim.seconds, "shot": shot, "citizen": citizen.get_inspection_status(), "distance": sim.camera_director.rig.distance}, directory.path_join("automatic-worker-detail.json"))
			if error != OK:
				push_error("POC46_CAMERA_FAIL: evidence write failed in %s (error=%d)" % [directory, error])
				break
			captured = true
			break
	print("POC46_CAMERA_" + ("PASS" if captured else "FAIL"))
	scene.queue_free()
	await process_frame
	quit(0 if captured else 1)
