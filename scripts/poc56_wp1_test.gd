extends SceneTree
## Production-path regression for project status/cleanup and finite furniture salvage.

const Pipeline := preload("res://scenes/pipeline_proof.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_WP1_CHECK_PASS " + label)
	else:
		failures.append(label)
		print("POC56_WP1_CHECK_FAIL " + label)

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
	test_bookcase_salvage(sim)
	test_project_status_and_cleanup(sim)
	scene.queue_free()
	await process_frame
	await test_reserved_ticket_cleanup()
	await test_terminal_cleanup_variant("FAILED")
	await test_terminal_cleanup_variant("SUPERSEDED")
	print("POC56_WP1_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func test_bookcase_salvage(sim: Node) -> void:
	const object_id := "bookcase"
	check(sim.salvage.objects.has(object_id), "canonical bookcase has production salvage state")
	check(sim.authorize_salvage(object_id), "bookcase can be authorized through production access checks")
	var target: Vector3 = sim.salvage_targets[object_id]
	var citizen: Node3D = sim.citizens[0]
	citizen.global_position = target
	var bookcase: Node3D = sim.scene.get_room_object(object_id)
	var object_position := Vector3(91, 0, -63)
	var state: Dictionary = sim.salvage.objects[object_id]
	var stage_count: int = state.stages.size()
	for stage_index in range(stage_count):
		var specification: Dictionary = state.stages[stage_index]
		var task: Dictionary = sim.coordinator.create_construction_task({"task_type":"SALVAGE", "object_id":object_id, "stage":stage_index, "source":target, "target":target}, citizen.citizen_id)
		citizen.task_id = int(task.id)
		citizen.task_type = "SALVAGE"
		sim.coordinator.activate_task(int(task.id))
		var factor: float = sim.needs.work_factor(citizen.needs)
		check(factor > 0, "bookcase worker has positive production work factor")
		var completed: bool = sim.work(citizen, float(specification.work) / factor)
		check(completed, "real salvage task completes stage %d" % (stage_index + 1))
		sim.coordinator.complete_task(int(task.id))
		if stage_index == 0:
			check(int(state.stage) == 1, "first pull advances exactly one salvage stage")
			check(bookcase.visible, "full-size bookcase remains visibly present after first pull")
			check(sim.coordinator.navigation.is_obstacle_position(object_position), "partial bookcase remains a navigation obstacle")
	check(int(state.stage) == stage_count and sim.salvage.depleted(object_id), "bookcase depletion requires every finite stage")
	check(not bookcase.visible, "bookcase is removed only after the final real stage")
	check(not sim.coordinator.navigation.is_obstacle_position(object_position), "depleted bookcase releases its navigation obstacle")
	check(sim.resources.audit().is_empty(), "salvage bundles preserve resource conservation")
	check(sim.economy.audit().is_empty(), "salvage does not corrupt economy accounting")

func test_project_status_and_cleanup(sim: Node) -> void:
	var development: RefCounted = sim.development
	check(development.request("shelter"), "production development system accepts a valid shelter request")
	var summary: Dictionary = development.status_snapshot() if development.has_method("status_snapshot") else {}
	check(String(summary.get("lifecycle_status", "")) == "WAITING_FOR_MATERIALS", "project exposes truthful waiting-for-materials state")
	check(not String(summary.get("blocker", "")).is_empty(), "waiting project explains its current blocker")
	if not development.has_method("cancel_active"):
		check(false, "active project cancellation is available")
		return
	var project_id := String(development.active.id)
	check(sim.economy.receive("wood", 4.0), "focused delivery fixture funds real economy tickets")
	var before := float(sim.economy.available.wood)
	var ticket: int = sim.economy.reserve("wood", 1, project_id)
	check(ticket >= 0, "project delivery reservation is owned by the real project")
	var delivery: Dictionary = sim.coordinator.create_construction_task({"task_type":"CONSTRUCTION_DELIVERY", "project_id":project_id, "resource":"wood", "amount":1, "ticket":ticket, "source":sim.coordinator.depot_station, "target":development.active.target, "picked_up":false}, 0)
	check(not delivery.is_empty(), "project reservation is represented by a coordinator task")
	check(String(development.status_snapshot().get("lifecycle_status", "")) == "WAITING_FOR_DELIVERY", "available or reserved project materials report waiting for delivery")
	var citizen: Node3D = sim.citizens[0]
	for unit in range(4):
		var task := delivery
		if unit > 0:
			var next_ticket: int = sim.economy.reserve("wood", 1, project_id)
			var specification := {"task_type":"CONSTRUCTION_DELIVERY", "project_id":project_id, "resource":"wood", "amount":1, "ticket":next_ticket, "source":sim.coordinator.depot_station, "target":development.active.target, "picked_up":false}
			task = sim.coordinator.create_construction_task(specification, citizen.citizen_id)
		sim.coordinator.activate_task(int(task.id))
		citizen.global_position = task.source
		check(sim.coordinator.confirm_project_pickup(int(task.id), citizen, "wood"), "real project delivery pickup %d validates" % (unit + 1))
		var route: Array[Vector3] = sim.coordinator.navigation.path_between(task.source, task.target)
		citizen.travelled_distance += sim.coordinator._path_length(route)
		citizen.global_position = task.target
		check(sim.coordinator.confirm_project_delivery(int(task.id), citizen, "wood", "wood"), "real project delivery arrival %d validates" % (unit + 1))
		sim.coordinator.complete_task(int(task.id))
	check(String(development.status_snapshot().get("lifecycle_status", "")) == "WAITING_FOR_WORKERS", "fully delivered project reports that it needs a builder")
	var build_specs: Array[Dictionary] = development.options()
	var build_option: Dictionary = {}
	for option in build_specs:
		if option.task_type == "CONSTRUCTION_BUILD": build_option = option
	var build_task: Dictionary = sim.coordinator.create_construction_task(build_option, citizen.citizen_id)
	check(not build_task.is_empty() and int(development.status_snapshot().get("worker_count", 0)) == 1, "project status counts its assigned real builder task")
	citizen.task_id = int(build_task.id)
	citizen.task_type = "CONSTRUCTION_BUILD"
	citizen._destination = development.active.target
	citizen.global_position = development.active.target
	citizen.state = "WORK"
	sim.coordinator.activate_task(int(build_task.id))
	check(not sim.coordinator.advance_construction_work(int(build_task.id), citizen.citizen_id, 5.0), "real builder advances project work without completing early")
	var work_summary: Dictionary = development.status_snapshot()
	check(String(work_summary.get("lifecycle_status", "")) == "UNDER_CONSTRUCTION" and float(work_summary.get("work_progress", 0.0)) == 5.0, "in-progress status exposes authoritative work progress")
	var saved_position: Vector3 = sim.citizens[1].global_position
	sim.citizens[1].global_position = development.active.site
	check(not sim.coordinator.advance_construction_work(int(build_task.id), citizen.citizen_id, 55.0), "builder waits when a citizen occupies the reserved footprint")
	var blocked_summary: Dictionary = development.status_snapshot()
	check(String(blocked_summary.get("lifecycle_status", "")) == "WAITING_FOR_SITE", "completed work reports a truthful site blocker")
	check(float(blocked_summary.get("work_percent", 0.0)) == 1.0 and not String(blocked_summary.get("blocker", "")).is_empty(), "site blocker retains full work and a visible reason")
	sim.citizens[1].global_position = saved_position
	sim.citizens[1].state = "IDLE"
	check(development.cancel_active("focused regression cancellation"), "active project cancellation is accepted")
	check(development.active.is_empty(), "cancelled project leaves no active project")
	var terminal: Dictionary = development.project_status(project_id)
	check(String(terminal.get("lifecycle_status", "")) == "CANCELLED", "terminal project status remains inspectable in history")
	var observed_states: Array[String] = []
	for entry in terminal.get("status_history", []): observed_states.append(String(entry.lifecycle_status))
	var expected_states: Array[String] = ["PLANNING", "WAITING_FOR_MATERIALS", "WAITING_FOR_DELIVERY", "WAITING_FOR_WORKERS", "UNDER_CONSTRUCTION", "WAITING_FOR_SITE", "CANCELLED"]
	check(expected_states.all(func(value: String) -> bool: return observed_states.has(value)), "project history retains each authoritative lifecycle transition")
	check(not sim.economy.tickets.has(ticket), "cancellation releases its delivered ticket")
	check(is_equal_approx(float(sim.economy.available.wood), before), "all delivered project materials return to available stock")
	var stored: Dictionary = sim.coordinator._find_task(int(delivery.id))
	var build_stored: Dictionary = sim.coordinator._find_task(int(build_task.id))
	check(stored.get("state", "") == "complete", "delivered project task keeps its completed coordinator history")
	check(build_stored.get("state", "") == "cancelled", "cancellation cancels its active builder task")
	check(sim.economy.audit().is_empty(), "project cancellation preserves economy conservation")
	var planner: RefCounted = development.site_planner
	planner.reservations.clear()
	planner._failed_state = ""
	planner._prepare(false)
	var positions: Array[Vector3] = []
	for worker in sim.world_citizens(): positions.append(worker.global_position)
	planner._failed_state = JSON.stringify([sim.coordinator.navigation.room_definition, "shelter", sim.needs.rest_capacity, planner._anchors, development.projects, sim.construction.project_created, sim.construction.site_position, positions]).sha256_text()
	check(not development.request("shelter"), "cached transient site conflict rejects a new placement attempt")
	var waiting_site: Dictionary = development.status_snapshot()
	check(String(waiting_site.get("lifecycle_status", "")) == "WAITING_FOR_SITE" and not String(waiting_site.get("blocker", "")).is_empty(), "site rejection is exposed with a truthful blocker")
	check(float(waiting_site.get("retry_in_seconds", 0.0)) <= 60.0 and float(waiting_site.get("retry_in_seconds", 0.0)) >= 5.0, "first site retry uses a bounded visible delay")
	sim.seconds = float(waiting_site.retry_at)
	development.consider_founding(sim.status())
	var retried_site: Dictionary = development.status_snapshot()
	check(int(retried_site.get("retry_count", 0)) == 2 and float(retried_site.get("retry_in_seconds", 0.0)) <= 60.0, "repeated transient site failures back off within the 60-second bound")

func test_reserved_ticket_cleanup() -> void:
	var scene := Pipeline.instantiate()
	root.add_child(scene)
	await process_frame
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	check(sim.development.request("shelter"), "fresh production world accepts a shelter for reservation cleanup")
	check(sim.economy.receive("wood", 1.0), "reserved-ticket cleanup fixture receives finite stock")
	var project_id := String(sim.development.active.id)
	var before := float(sim.economy.available.wood)
	var ticket: int = sim.economy.reserve("wood", 1, project_id)
	var task: Dictionary = sim.coordinator.create_construction_task({"task_type":"CONSTRUCTION_DELIVERY", "project_id":project_id, "resource":"wood", "amount":1, "ticket":ticket, "source":sim.coordinator.depot_station, "target":sim.development.active.target, "picked_up":false}, 0)
	check(ticket >= 0 and not task.is_empty(), "real project creates an outstanding reserved delivery")
	check(sim.development.cancel_active("reserved-ticket cleanup regression"), "project with reserved delivery can be cancelled")
	check(not sim.economy.tickets.has(ticket) and is_equal_approx(float(sim.economy.available.wood), before), "cancellation returns the undelivered project reservation")
	check(sim.coordinator._find_task(int(task.id)).get("state", "") == "cancelled", "cancellation cancels the reserved delivery task")
	check(sim.economy.audit().is_empty(), "reserved-task cancellation preserves economy conservation")
	scene.queue_free()
	await process_frame

func test_terminal_cleanup_variant(terminal_status: String) -> void:
	var scene := Pipeline.instantiate()
	root.add_child(scene)
	await process_frame
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	var development: RefCounted = sim.development
	check(development.request("shelter"), "%s fixture creates a production project" % terminal_status)
	if development.active.is_empty():
		scene.queue_free()
		await process_frame
		return
	var project_id := String(development.active.id)
	var before := float(sim.economy.available.wood)
	check(sim.economy.receive("wood", 1.0), "%s fixture receives finite delivery stock" % terminal_status)
	var ticket: int = sim.economy.reserve("wood", 1, project_id)
	var worker: Node3D = sim.citizens[0]
	var delivery: Dictionary = sim.coordinator.create_construction_task({"task_type":"CONSTRUCTION_DELIVERY", "project_id":project_id, "resource":"wood", "amount":1, "ticket":ticket, "source":sim.coordinator.depot_station, "target":development.active.target, "picked_up":false}, worker.citizen_id)
	var builder: Dictionary = sim.coordinator.create_construction_task({"task_type":"CONSTRUCTION_BUILD", "project_id":project_id, "stage":0, "source":development.active.target, "target":development.active.target}, worker.citizen_id)
	sim.coordinator.activate_task(int(builder.id))
	check(ticket >= 0 and not delivery.is_empty() and not builder.is_empty(), "%s project owns a reserved delivery and an active builder" % terminal_status)
	var terminated: bool = development.fail_active("focused %s regression" % terminal_status) if terminal_status == "FAILED" else development.supersede_active("focused %s regression" % terminal_status)
	check(terminated and development.active.is_empty(), "%s terminal operation clears the active project" % terminal_status)
	check(String(development.project_status(project_id).get("lifecycle_status", "")) == terminal_status, "%s terminal status remains in project history" % terminal_status)
	check(not sim.economy.tickets.has(ticket) and is_equal_approx(float(sim.economy.available.wood), before + 1.0), "%s releases the owned reservation back to available finite stock" % terminal_status)
	check(sim.coordinator._find_task(int(delivery.id)).get("state", "") == "cancelled" and sim.coordinator._find_task(int(builder.id)).get("state", "") == "cancelled", "%s cancels its delivery and builder tasks" % terminal_status)
	check(sim.economy.audit().is_empty(), "%s cleanup preserves economy conservation" % terminal_status)
	scene.queue_free()
	await process_frame
