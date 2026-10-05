extends "res://scripts/poc45_scenario_test.gd"
## Fresh production observer. No strategic commands or stock mutation after startup.
var checkpoints := {}
var initial_state := {}

func run() -> void:
	started = Time.get_ticks_msec()
	OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	sim = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	initial_state = sim.status()
	root.size = Vector2i(1920,1080)
	var checks := {"five_founders": sim.citizens.size() == 5, "empty_settlement": scene.get_node("Settlement").get_child_count() == 1 and sim.needs.shelter_capacity == 0 and sim.needs.rest_capacity == 0 and not sim.has_capability("workshop"), "portable_only": sim.economy.initial == {"food":20.0,"water":30.0,"wood":0.0,"metal":0.0}, "speed_one": sim.speed == 1}
	await capture("five-founders-empty-settlement", sim.development.center(), 22)
	for key in checks:
		if not checks[key]: failure += key + " "
	var next_log := 0.0
	while sim.seconds < 4800 and failure.is_empty():
		for tick in range(100):
			var previous: Array[Vector3] = []
			for citizen in sim.citizens: previous.append(citizen.global_position)
			sim.step()
			sim.camera_director.advance(sim.STEP)
			sim.spectator.advance(sim.STEP)
			for index in range(sim.citizens.size()):
				var citizen: Node3D = sim.citizens[index]
				if not citizen.global_position.is_finite(): failure = "Nonfinite position"
				if index < previous.size() and previous[index].distance_to(citizen.global_position) > 0.651: failure = "Movement exceeds walking speed"
				if citizen.task_type == "SALVAGE" and citizen.state == "WORK": mark("first_salvage")
				if citizen.state == "WORK" and citizen.task_type in ["SALVAGE","RESOURCE_COLLECT","CONSTRUCTION_BUILD"]: mark("meaningful_work")
				if citizen.carrying: mark("first_haul")
				if citizen.carrying and citizen.task_type == "BUNDLE_HAUL" and citizen._delivery_resource in ["wood","metal"]: mark("material_haul")
				for need in ["food","water","fatigue"]:
					if not is_finite(float(citizen.needs[need])) or float(citizen.needs[need]) < 0 or float(citizen.needs[need]) > 1: failure = "Invalid need"
				if citizen.global_position.y > 5 and citizen.global_position.y < 29: mark("physical_climb")
				if citizen.global_position.y >= 29: mark("elevated_territory")
			if sim.construction.project_created and not sim.has_capability("workshop"): failure = "Traversal before workshop"
			if sim.citizens.size() > 5 and not sim.has_capability("workshop"): failure = "Growth before workshop"
			var expected_shelter: int = 5 * sim.development.count("shelter") + 10 * sim.development.count("housing")
			if sim.needs.shelter_capacity != expected_shelter: failure = "Unearned shelter"
			if not sim.economy.audit().is_empty() or not sim.resources.audit().is_empty(): failure = "Resource conservation"
			for resource in ["food","water","wood","metal"]:
				var acquired: float = sim.economy.exported[resource]
				for object in sim.salvage.objects.values(): acquired += float(object.yielded.get(resource,0))
				for source in sim.resources.sources.values(): acquired += float(source.extracted.get(resource,0))
				if absf(acquired - float(sim.resources.generated[resource])) > 0.0001 or sim.economy.received[resource] != sim.resources.delivered[resource]: failure = "Material created without source"
			for p in sim.development.projects:
				mark(p.kind + "_started", p.created)
				mark(p.kind + "_" + p.stage.to_lower())
				if p.state == "COMPLETE": mark(p.kind + "_complete", p.completed)
			if sim.citizens.size() > 5: mark("sixth_citizen")
			if sim.construction.project_created: mark("traversal_started")
			if sim.construction.traversal_deployed: mark("traversal_complete")
			if not failure.is_empty(): break
		await process_frame
		sim.spectator.refresh()
		for event in sim.journal.events:
			if int(event.id) > event_cursor:
				all_events.append(event.duplicate(true))
				event_cursor = int(event.id)
		for task in sim.coordinator.tasks:
			if task.state in ["active","reserved"]:
				oldest_task = maxf(oldest_task, sim.seconds - float(task.created_sim))
		if not sim.development.active.is_empty(): oldest_project = maxf(oldest_project, sim.seconds - float(sim.development.active.created))
		for p in sim.development.projects:
			await once(p.kind + "-" + p.stage.to_lower(), p.site, 24)
		for c in sim.citizens:
			if c.task_type == "SALVAGE" and c.state == "WORK": await once("first-salvage", c.global_position + Vector3.UP * 0.25, 6)
			if c.carrying: await once("physical-hauling", c.global_position + Vector3.UP * 0.25, 6)
			if c.global_position.y > 5 and c.global_position.y < 29: await once("physical-climbing", c.global_position, 12)
		if sim.citizens.size() > 5: await once("first-new-citizen", sim.citizens[5].global_position, 12)
		if sim.construction.project_created: await once("grapple-construction", sim.construction.site_position, 40)
		if checkpoints.has("elevated_territory"): await once("elevated-expansion", sim.construction.target_anchor, 45)
		if sim.seconds >= next_log:
			timeline.append(sim.status())
			print("POC47_PROGRESS " + JSON.stringify({"seconds":sim.seconds,"state":sim.status(),"checkpoints":checkpoints,"active":sim.development.active,"growth":sim.population.reason}))
			next_log += 300
	for key in ["first_salvage", "material_haul", "first_haul", "shelter_complete", "depot_complete", "workshop_complete", "housing_complete", "sixth_citizen", "physical_climb", "elevated_territory", "traversal_complete"]: checks[key] = checkpoints.has(key)
	checks.real_labor = sim.development.projects.all(func(p: Dictionary) -> bool: return p.state != "COMPLETE" or p.work >= p.required_work and p.work_by_citizen.size() > 0 and p.delivery_distance > 0 and p.delivered.wood == p.required.wood and p.delivered.metal == p.required.metal)
	checks.growth_rules = not sim.population.cohorts.is_empty() and sim.population.cohorts.all(func(c: Dictionary) -> bool: return c.after - c.before == 1 and c.after <= c.shelter and minf(c.food_days_before,c.water_days_before) >= 2 and c.seconds >= checkpoints.get("workshop_complete",INF) + 300)
	checks.real_entities = sim.citizens.size() == scene.get_children().filter(func(n: Node) -> bool: return n.get_script() == preload("res://scripts/citizen_agent.gd")).size()
	checks.no_failed_tasks = sim.coordinator.summary().failed_total == 0
	checks.conserved = sim.economy.audit().is_empty() and sim.resources.audit().is_empty()
	checks.no_deadlocks = oldest_task < 1200 and oldest_project < 1200 and sim.development.active.is_empty()
	checks.demand_increases = sim.population.cohorts.all(func(c: Dictionary) -> bool: return c.food_days_after < c.food_days_before and c.water_days_after < c.water_days_before and c.stable_seconds >= 299.9 and minf(c.food_days_after,c.water_days_after) >= 2)
	for kind in ["shelter","depot","workshop","housing"]:
		checks[kind + "_stages"] = checkpoints.has(kind + "_frame") and checkpoints.has(kind + "_shell")
	var cost := {"wood":4.0,"metal":4.0}
	for project in sim.development.projects:
		if project.state == "COMPLETE":
			for resource in cost: cost[resource] += float(project.required[resource])
	checks.costs_exact = sim.economy.project_consumed.wood == cost.wood and sim.economy.project_consumed.metal == cost.metal
	checks.navigation_updated = sim.development.projects.all(func(p: Dictionary) -> bool: return p.state != "COMPLETE" or sim.coordinator.navigation.is_obstacle_position(p.site))
	checks.population_cooldown = true
	for i in range(1, sim.population.cohorts.size()):
		if sim.population.cohorts[i].seconds - sim.population.cohorts[i-1].seconds < 599.9: checks.population_cooldown = false
	for key in checks:
		if not checks[key]: failure += key + " "
	await capture("established-settlement", sim.development.center(), 120)
	var result := {"result":"PASS" if failure.is_empty() else "FAIL", "failure":failure, "checks":checks, "initial":initial_state, "checkpoints":checkpoints, "status":sim.status(), "projects":sim.development.projects, "cohorts":sim.population.cohorts, "timeline":timeline, "sources":sim.resources.sources, "salvage":sim.salvage.objects, "tasks":sim.coordinator.summary(), "captures":captures, "events":all_events, "oldest_task_seconds":oldest_task,"oldest_project_seconds":oldest_project}
	var path := OS.get_environment("ROOMSCALE_POC45_RESULT")
	if not path.is_empty(): FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("POC47_SCENARIO_" + result.result + " " + failure)
	scene.queue_free()
	await process_frame
	quit(0 if failure.is_empty() else 1)

func mark(key: String, at: float = -1) -> void:
	if not checkpoints.has(key): checkpoints[key] = sim.seconds if at < 0 else at

func capture(label: String, focus: Vector3, distance: float) -> void:
	if OS.get_environment("ROOMSCALE_VISUAL_DIR").is_empty(): return
	# Evidence framing is separate from the director's live subject/title.
	sim.spectator.title_panel.hide()
	sim.spectator.refresh()
	await super.capture(label, focus + Vector3.UP * 0.4, distance)
	sim.spectator.refresh()
