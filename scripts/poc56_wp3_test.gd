extends SceneTree
## Construction labels and footprint states are sourced from live projects.

const Pipeline := preload("res://scenes/pipeline_proof.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_WP3_CHECK_PASS " + label)
	else:
		failures.append(label)
		print("POC56_WP3_CHECK_FAIL " + label)

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
	check(sim.development.request("shelter"), "live settlement system starts a construction project")
	var project: Dictionary = sim.development.active
	var visual: Node3D = sim.development.visuals[project.id]
	var label := visual.get_node("ProjectStatusLabel") as Label3D
	check(label != null and label.text.contains("Shelter") and label.text.contains("WAITING FOR MATERIALS"), "active site label names the project and truthful blocker state")
	var outline_count := 0
	for child in visual.get_children():
		if String(child.name).begins_with("SiteOutline"):
			outline_count += 1
			var outline_mesh: Mesh = (child as MeshInstance3D).mesh
			var outline_size := outline_mesh.get_aabb().size
			check(outline_size.x >= 0.2 or outline_size.z >= 0.2, "site footprint has a visibly thick perimeter")
	check(outline_count == 4, "all four edges of the active shelter site are outlined")
	project.work = 12.0
	sim.development._set_project_status(project, "UNDER_CONSTRUCTION")
	sim.development._refresh_project_label(project)
	check(label.text.contains("20%") and label.text.contains("UNDER CONSTRUCTION"), "project label shows authoritative work progress and current state")
	sim.development._set_project_status(project, "BLOCKED", "Finite wood source depleted", sim.seconds + 60.0)
	check(label.text.contains("Finite wood source depleted") and label.modulate.r > label.modulate.g, "blocked project gets a truthful label and warning color")
	scene.queue_free()
	await process_frame
	print("POC56_WP3_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
