extends SceneTree
## Drives only the ordinary production clock; grants no stock, stages, work or links.
var failures: Array[String] = []
var scene: Node3D
var sim: Node
var saw_research_travel := false
var saw_research_work := false
var saw_solution_haul := false
var saw_solution_work := false
var rejected_forged_work := false
var paused_checked := false
var cancellation_checked := false
var captures: Array[String] = []
var tree_completed := false
var shelter_bonus_verified := false
var recognition_time := -1.0
var spectator_event_history: Array[Dictionary] = []
var spectator_event_cursor := 0

func _initialize() -> void:
	create_timer(90.0).timeout.connect(func() -> void: push_error("INNOVATION_LIVE_FAIL watchdog"); quit(1))
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition and not failures.has(label): failures.append(label)

func run() -> void:
	if OS.get_environment("ROOMSCALE_ROOM").is_empty(): OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_INNOVATION", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	sim = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	check(sim.citizens.size() == int(sim.room_definition.start.population) and sim.economy.available.wood == 0 and sim.economy.available.metal == 0 and sim.economy.available.mechanical_parts == 0, "Earned founder start")
	check(sim.innovation.enabled and sim.innovation.resolver.known_technologies.is_empty(), "No initial inventions")
	var initial_problems := preload("res://scripts/world_problem_detector.gd").vertical_access(sim.resources, sim.coordinator.surface_navigation)
	check(not initial_problems.is_empty() and initial_problems[0].type == "VERTICAL_ACCESS", "Generic world problem")
	while sim.seconds < 4800 and failures.is_empty():
		for tick_index in range(100):
			var before: Dictionary = {}
			for citizen in sim.citizens: before[citizen.citizen_id] = citizen.global_position
			var shelter_before: int = sim.needs.shelter_capacity
			sim.step()
			if recognition_time < 0:
				for recognized in sim.innovation.resolver.problem_registry.active_problems():
					if recognized.type == "VERTICAL_ACCESS": recognition_time = recognized.recognized_at
			if sim.seconds < 10:
				check(sim.innovation.resolver.problem_registry.active_problems().is_empty() and sim.innovation.research.is_empty(), "Weak initial awareness cannot research")
			for built in sim.innovation.projects:
				if built.state == "COMPLETE" and built.solution.deployment.adapter == "living_structure" and not tree_completed:
					check(sim.needs.shelter_capacity - shelter_before == int(built.solution.properties.shelter_capacity), "Authored shelter property changes actual capacity only at paid completion")
					check(sim.needs.shelter_capacity == built.shelter_before + int(built.solution.properties.shelter_capacity), "Living effect applies once")
					shelter_bonus_verified = true
					tree_completed = true
			check(not sim.construction.project_created, "Legacy progression bypassed")
			check(sim.economy.audit().is_empty() and sim.resources.audit().is_empty(), "Conservation")
			for citizen in sim.citizens:
				if before.has(citizen.citizen_id): check(before[citizen.citizen_id].distance_to(citizen.global_position) <= 0.651, "Legal movement speed")
				if citizen.task_type == "INNOVATION_RESEARCH":
					if citizen.state == "TRAVEL": saw_research_travel = true
					if citizen.state == "WORK":
						saw_research_work = true
						if not rejected_forged_work:
							var previous_work: Dictionary = sim.innovation.research.duplicate(true)
							check(not sim.coordinator.advance_innovation_work(citizen.task_id, citizen.citizen_id, 1000.0), "Reject fabricated large work")
							check(not sim.coordinator.advance_innovation_work(citizen.task_id, citizen.citizen_id, sim.STEP), "Reject duplicate work in one tick")
							check(previous_work == sim.innovation.research, "Rejected work immutable")
							rejected_forged_work = true
				var task: Dictionary = sim.coordinator.get_task(citizen.task_id)
				if task.get("innovation_project", false):
					if citizen.carrying: saw_solution_haul = true
					if citizen.task_type == "CONSTRUCTION_BUILD" and citizen.state == "WORK": saw_solution_work = true
			if not sim.innovation.research.is_empty() and not paused_checked:
				var prior: Dictionary = sim.innovation.status()
				var old_seconds: float = sim.seconds
				sim.speed = 0.0
				sim.advance_elapsed_time(1.0)
				check(old_seconds == sim.seconds and prior == sim.innovation.status(), "Pause freezes research")
				sim.speed = 1.0
				paused_checked = true
			if OS.get_environment("ROOMSCALE_INNOVATION_CANCEL_PROBE") == "1" and not cancellation_checked and not sim.innovation.active.is_empty():
				var project: Dictionary = sim.innovation.active
				if project.delivered.values().any(func(amount: Variant) -> bool: return float(amount) > 0):
					var id: String = project.id
					var target: Vector3 = project.target
					var paid: Dictionary = project.delivered.duplicate(true)
					var known: Array = sim.innovation.resolver.known_technologies.keys()
					sim.innovation._cancel_project("Cancellation recovery QA probe")
					check(project.state == "CANCELLED" and sim.innovation.active.is_empty() and sim.world_simulation.innovation_claims.is_empty(), "Cancelled project releases shared ownership")
					check(sim.innovation.resolver.known_technologies.keys() == known and not sim.coordinator.surface_navigation.has_connection("FLOOR", project.region), "Cancellation grants no capability or route")
					check(not sim.economy.tickets.values().any(func(ticket: Dictionary) -> bool: return ticket.owner == id), "Cancelled project has no ledger tickets")
					check(not sim.coordinator.tasks.any(func(job: Dictionary) -> bool: return job.get("project_id","") == id and job.state in ["active","reserved"]), "Cancellation retires project delivery, build and recipe jobs")
					for resource in paid:
						var recovered := 0.0
						for bundle in sim.resources.bundles.values():
							if bundle.source == id and bundle.resource == resource and bundle.position.distance_to(target) < 0.001: recovered += float(bundle.amount)
						check(absf(recovered-float(paid[resource])) < 0.0001, "Delivered material recovered physically: " + resource)
					cancellation_checked = true
			if sim.innovation.research_history.is_empty(): check(sim.innovation.resolver.known_technologies.is_empty(), "No capabilities before real work")
			if not sim.innovation.projects.is_empty() and sim.innovation.projects[-1].state == "COMPLETE" and int(sim.source_visits.water) > 0:
				var elevated := false
				for citizen in sim.citizens:
					if citizen.global_position.y > 5: elevated = true
				if elevated: break
		if not sim.innovation.research.is_empty() and float(sim.innovation.research.work) > 10:
			await capture("research", sim.innovation.research.target + Vector3(0,1,0), 22)
		if not sim.innovation.projects.is_empty() and sim.innovation.projects[-1].state == "COMPLETE":
			var project: Dictionary = sim.innovation.projects[-1]
			if OS.get_environment("ROOMSCALE_REQUIRE_LIVING_STRUCTURE") != "1" or project.solution.deployment.adapter == "living_structure": await capture("deployed-route", (project.site + project.path.back()) / 2, project.path[0].distance_to(project.path.back()) * 1.4)
		await process_frame
		if OS.get_environment("ROOMSCALE_CAPTURE_EVENT_HISTORY") == "1":
			for event in sim.journal.events:
				if int(event.id) > spectator_event_cursor:
					spectator_event_history.append(event.duplicate(true))
					spectator_event_cursor = int(event.id)
		var completed: bool = not sim.innovation.projects.is_empty() and sim.innovation.projects[-1].state == "COMPLETE"
		if completed and (OS.get_environment("ROOMSCALE_REQUIRE_LIVING_STRUCTURE") != "1" or tree_completed) and sim.journal.events.any(func(e: Dictionary) -> bool: return e.kind == "territory_reached"): break
	if OS.get_environment("ROOMSCALE_INNOVATION_CANCEL_PROBE") == "1": check(cancellation_checked, "Physical cancellation boundary exercised")
	if OS.get_environment("ROOMSCALE_REQUIRE_LIVING_STRUCTURE") == "1": check(tree_completed and shelter_bonus_verified, "Mechanically distinct living structure completed")
	check(recognition_time >= 10, "Vertical access recognized after fixed observations")
	check(saw_research_travel and saw_research_work and paused_checked and rejected_forged_work, "Physical research and pause witnessed")
	check(saw_solution_haul and saw_solution_work, "Physical hauling and construction witnessed")
	check(not sim.innovation.research_history.is_empty(), "Research completed")
	check(not sim.innovation.projects.is_empty() and sim.innovation.projects[-1].state == "COMPLETE", "Solution deployed")
	check(sim.journal.events.any(func(e: Dictionary) -> bool: return e.kind == "territory_reached"), "Citizens physically reach elevated resources")
	for citizen in sim.citizens:
		if citizen.global_position.y > 5:
			await capture("citizen-access", citizen.global_position + Vector3(0,0.5,0), 12)
			break
	var research_receipts: Array = []
	for research in sim.innovation.research_history:
		if research.state != "COMPLETE": continue
		var sum := 0.0
		for effort in research.work_by_citizen.values(): sum += float(effort)
		check(absf(sum - float(research.required_work)) <= 0.0001, "Research backed by citizen work")
		research_receipts.append({"id":research.id, "completed":research.completed, "work":research.work, "contributors":research.work_by_citizen})
	var project_receipts: Array = []
	for project in sim.innovation.projects:
		if project.state != "COMPLETE": continue
		check(project.required == project.delivered and project.delivery_distance > 0 and sim.coordinator.surface_navigation.has_connection("FLOOR", project.region), "Paid physical solution and real link")
		var sum := 0.0
		for effort in project.work_by_citizen.values(): sum += float(effort)
		check(absf(sum - float(project.required_work)) <= 0.0001, "Construction backed by citizen work")
		project_receipts.append({"solution":project.solution.id, "region":project.region, "style":project.solution.deployment.style, "completed":project.completed, "required":project.required, "delivered":project.delivered, "work":project.work, "contributors":project.work_by_citizen, "delivery_distance":project.delivery_distance,"shelter_added":project.solution.get("properties",{}).get("shelter_capacity",0) if project.get("effect_applied",false) else 0})
		if project.solution.deployment.adapter == "living_structure":
			var adapter: RefCounted = sim.innovation.adapters.adapter_for(project.solution)
			var before_capacity: int = sim.needs.shelter_capacity
			check(adapter.finish(sim,project) and before_capacity == sim.needs.shelter_capacity,"Completed living effect is idempotent")
			var duplicate: Dictionary = adapter.prepare(sim,project.solution,{"source_id":project.region,"context":{"region":project.region}})
			check(not duplicate.get("valid",false),"Permanent structure cannot be duplicated into free capacity at the same region")
	var receipt := {"result":"PASS" if failures.is_empty() else "FAIL", "failures":failures, "civilization":sim.definition_id,"recognition_time":recognition_time,"shelter_bonus_verified":shelter_bonus_verified, "research":research_receipts, "projects":project_receipts, "seconds":sim.seconds, "source_visits":sim.source_visits, "reason":sim.innovation.reason}
	if OS.get_environment("ROOMSCALE_CAPTURE_EVENT_HISTORY") == "1": receipt["events"] = spectator_event_history
	var destination := OS.get_environment("ROOMSCALE_INNOVATION_RESULT")
	if not destination.is_empty():
		var file := FileAccess.open(destination, FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(receipt, "  ")); file.flush(); file.close()
	print("INNOVATION_LIVE_RECEIPT ", JSON.stringify(receipt))
	if failures.is_empty(): print("ROOMSCALE_INNOVATION_LIVE_PASS")
	else: push_error("ROOMSCALE_INNOVATION_LIVE_FAIL %s" % [failures])
	quit(0 if failures.is_empty() else 1)

func capture(label: String, at: Vector3, distance: float) -> void:
	var directory := OS.get_environment("ROOMSCALE_VISUAL_DIR")
	if directory.is_empty() or captures.has(label): return
	check(DisplayServer.get_name() != "headless", "Visual evidence uses a real renderer")
	sim.spectator.refresh()
	scene.get_node("CameraRig").focus_detail_at(at, distance, 40)
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	check(root.get_texture().get_image().save_png(directory.path_join(label+".png")) == OK, "Visual evidence written")
	captures.append(label)
