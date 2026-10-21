extends SceneTree
## Focused production-scene checks for render-only motion and shared-site spacing.

const Pipeline := preload("res://scenes/pipeline_proof.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_WP2_CHECK_PASS " + label)
	else:
		failures.append(label)
		print("POC56_WP2_CHECK_FAIL " + label)

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
	test_presentation_pose(sim.citizens[0])
	test_build_standing_slots(sim)
	scene.queue_free()
	await process_frame
	print("POC56_WP2_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func test_presentation_pose(citizen: Node3D) -> void:
	citizen.global_position = Vector3.ZERO
	citizen.rotation.y = 0.0
	citizen.begin_presentation_step()
	citizen.global_position = Vector3(1.0, 0.0, 0.0)
	citizen.rotation.y = PI * 0.5
	var authoritative_position := citizen.global_position
	citizen.advance_presentation(0.5)
	var figure := citizen.get_node("Figure") as Node3D
	check(citizen.global_position.is_equal_approx(authoritative_position), "visual smoothing does not move the authoritative citizen")
	check(absf(figure.global_position.x - 0.5) < 0.01, "rendered figure interpolates between fixed-step positions")
	check(absf(angle_difference(figure.global_rotation.y, PI * 0.25)) < 0.01, "rendered heading follows the short interpolated turn")
	citizen.advance_presentation(1.0)
	check(absf(figure.global_position.x - 1.0) < 0.01, "rendered figure converges to the authoritative position")
	check(absf(angle_difference(figure.global_rotation.y, PI * 0.5)) < 0.01, "rendered heading converges to the authoritative orientation")

func test_build_standing_slots(sim: Node) -> void:
	var development: RefCounted = sim.development
	if development.active.is_empty(): development.request("shelter")
	var active: Dictionary = development.active
	if active.is_empty():
		check(false, "production site planner supplies a shared build site")
		return
	var specification := {"task_type":"CONSTRUCTION_BUILD", "project_id":active.id, "stage":0, "source":active.target, "target":active.target, "urgency":0.4}
	var repeat_a: Vector3 = sim.coordinator._construction_standing_target(specification, 0)
	var repeat_b: Vector3 = sim.coordinator._construction_standing_target(specification, 0)
	check(repeat_a.is_equal_approx(repeat_b), "same colony state assigns the same deterministic standing target")
	var first: Dictionary = sim.coordinator.create_construction_task(specification, 0)
	var second: Dictionary = sim.coordinator.create_construction_task(specification, 1)
	check(not first.is_empty() and not second.is_empty(), "two production builders can reserve the same work site")
	if first.is_empty() or second.is_empty(): return
	var first_target: Vector3 = first.get("standing_target", first.target)
	var second_target: Vector3 = second.get("standing_target", second.target)
	check(first.target.is_equal_approx(active.target) and second.target.is_equal_approx(active.target), "builder work retains the canonical production target")
	check(first_target.distance_to(second_target) >= 0.5, "shared-site workers receive distinct visible positions")
	for target_index in range(2):
		var target: Vector3 = [first_target, second_target][target_index]
		check(target.distance_to(active.target) <= 1.6, "standing position stays inside the real work radius")
		check(sim.coordinator.navigation.is_walkable(target) and not sim.coordinator.navigation.is_obstacle_position(target), "standing position remains in legal unobstructed navigation")
		var task: Dictionary = [first, second][target_index]
		check(not sim.coordinator.navigation.path_between(sim.citizen_for(task.citizen_id).global_position, target).is_empty(), "worker can physically route to its reserved standing position")
	var first_worker: Node3D = sim.citizen_for(first.citizen_id)
	first_worker.task_id = int(first.id)
	first_worker.task_type = "CONSTRUCTION_BUILD"
	first_worker._destination = first_target
	first_worker.state = "WORK"
	sim.coordinator.activate_task(int(first.id))
	check(sim.development.site_planner.can_complete(active), "project completion accepts its own legal builder standing offset")
	sim.coordinator.cancel_task(int(first.id), "standing slot completion regression")
	sim.coordinator.cancel_task(int(second.id), "standing slot completion regression")
