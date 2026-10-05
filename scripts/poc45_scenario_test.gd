extends SceneTree
## Observer only. Enables autonomy at startup, then advances production fixed ticks.
var sim: Node
var scene: Node3D
var seen := {}
var timeline: Array[Dictionary] = []
var maxima := {"tasks": 0, "tickets": 0, "bundles": 0, "events": 0, "population": 0}
var started := 0
var failure := ""
var all_events: Array[Dictionary] = []
var event_cursor := 0
var captures: Array[String] = []
var captured: Dictionary = {}
var health: Array[Dictionary] = []
var oldest_task := 0.0
var oldest_project := 0.0
var max_move := 0.0
var first_100 := -1.0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	started = Time.get_ticks_msec()
	OS.set_environment("ROOMSCALE_ROOM", "room_poc45")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	sim = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	if sim.citizens.size() != 50 or not sim.governor.enabled: failure = "Initial production population/autonomy"
	await capture("initial-settlement", sim.development.center(), 175)
	var days := maxf(8, float(OS.get_environment("ROOMSCALE_POC45_DAYS")))
	var next_day := 0.0
	while sim.seconds < days * 600 and failure.is_empty():
		for tick in range(100):
			var previous: Array[Vector3] = []
			for citizen in sim.citizens: previous.append(citizen.global_position)
			sim.step()
			for index in range(sim.citizens.size()):
				var citizen: Node3D = sim.citizens[index]
				if not citizen.global_position.is_finite(): failure = "Nonfinite citizen position"
				if index < previous.size() and previous[index].distance_to(citizen.global_position) > 0.651: failure = "Citizen movement exceeds production walking speed"
				if index < previous.size(): max_move = maxf(max_move, previous[index].distance_to(citizen.global_position))
				for need in ["food", "water", "fatigue"]:
					if not is_finite(float(citizen.needs[need])) or citizen.needs[need] < 0 or citizen.needs[need] > 1: failure = "Invalid need state"
				if citizen.task_type == "SALVAGE" and citizen.state == "WORK": seen.salvage_work = true
				if citizen.carrying and citizen.task_type == "BUNDLE_HAUL": seen.haul = true
				if citizen.task_type == "RESOURCE_COLLECT" and citizen.global_position.y > 5 and citizen.global_position.y < 29: seen.climb = true
				if citizen.task_type == "CONSTRUCTION_DELIVERY" and sim.coordinator.get_task(citizen.task_id).has("project_id") and citizen.carrying: seen.development_haul = true
				if citizen.task_type == "CONSTRUCTION_BUILD" and sim.coordinator.get_task(citizen.task_id).has("project_id") and citizen.state == "WORK": seen.development_work = true
			for resource in ["wood", "metal"]:
				for state in ["reserved", "in_transit", "delivered"]:
					if sim.economy.state_total(resource, state) > 0: seen[state] = true
			if sim.construction.project_created and sim.construction.delivered.wood == 0: seen.material_blocker = true
			if sim.needs.drinks > 0 and sim.economy.available.water < 100: seen.needs_pressure = true
			if sim.construction.traversal_deployed and sim.resources.delivered.water > 0 and sim.economy.forecast("water", sim.citizens.size()) >= 2: seen.recovery = true
			for project in sim.development.projects:
				if project.stage in ["FRAME", "SHELL"]:
					seen["stage_" + project.stage] = true
					seen[project.kind + "_stage_" + project.stage] = true
			if not sim.economy.audit().is_empty() or not sim.resources.audit().is_empty(): failure = "Resource conservation"
			if not failure.is_empty(): break
		await process_frame
		if sim.planner.directives.has("water"): await once("autonomous-water-crisis", sim.development.center(), 175)
		for citizen in sim.citizens:
			if citizen.task_type == "SALVAGE" and citizen.state == "WORK":
				await once("autonomous-salvage", citizen.global_position, 65)
				await once("citizen-salvage-work", citizen.global_position + Vector3.UP * 0.25, 3)
			if citizen.task_type == "BUNDLE_HAUL" and citizen.carrying: await once("citizen-material-hauling", citizen.global_position + Vector3.UP * 0.25, 3)
			if citizen.task_type == "RESOURCE_COLLECT" and citizen.global_position.y > 8 and citizen.global_position.y < 20: await once("citizen-water-climb", citizen.global_position + Vector3.UP * 0.25, 4)
			if citizen.task_type == "CONSTRUCTION_BUILD" and citizen.state == "WORK" and sim.coordinator.get_task(citizen.task_id).has("project_id"): await once("citizen-development-work", citizen.global_position + Vector3.UP * 0.25, 4)
		if seen.get("recovery", false): await once("water-recovery", sim.development.center(), 175)
		if not sim.development.active.is_empty() and sim.development.active.kind == "housing":
			await once("first-housing-project", sim.development.active.site, 65)
			if sim.development.active.stage == "FRAME": await once("housing-frame", sim.development.active.site, 50)
			if sim.development.active.stage == "SHELL": await once("housing-shell", sim.development.active.site, 50)
		if not sim.development.active.is_empty() and sim.development.active.kind == "workshop":
			if sim.development.active.stage == "FRAME": await once("workshop-frame", sim.development.active.site, 50)
			if sim.development.active.stage == "SHELL": await once("workshop-shell", sim.development.active.site, 50)
		for project in sim.development.projects:
			if project.kind == "workshop" and project.state == "COMPLETE": await once("completed-workshop", project.site, 65)
		if sim.development.count("housing") > 0: await once("completed-housing", sim.development.projects[0].site, 65)
		if sim.population.cohorts.size() > 0: await once("first-cohort", sim.development.center(), 175)
		if sim.development.projects.size() >= 3 and sim.development.projects[2].state == "COMPLETE": await once("multiple-structures", sim.development.center(), 175)
		for id in sim.salvage.objects:
			if sim.salvage.objects[id].stage > 0 and not sim.salvage.depleted(id):
				var at: Array = sim.resources.objects[id].data.position
				await once("salvage-intermediate-stage", Vector3(float(at[0]), float(at[1]) + 8, float(at[2])), 65)
			if sim.salvage.depleted(id):
				var at: Array = sim.resources.objects[id].data.position
				await once("altered-room-object", Vector3(float(at[0]), float(at[1]), float(at[2])), 85)
		for event in sim.journal.events:
			if int(event.id) > event_cursor:
				all_events.append(event.duplicate(true))
				event_cursor = int(event.id)
		maxima.tasks = maxi(maxima.tasks, sim.coordinator.tasks.size())
		maxima.tickets = maxi(maxima.tickets, sim.economy.tickets.size())
		maxima.bundles = maxi(maxima.bundles, sim.resources.bundles.size())
		maxima.events = maxi(maxima.events, sim.journal.events.size())
		maxima.population = maxi(maxima.population, sim.citizens.size())
		if first_100 < 0 and sim.citizens.size() >= 100: first_100 = sim.seconds
		if sim.seconds >= next_day:
			timeline.append(sim.status())
			var source_totals := {"food": 0.0, "water": 0.0}
			for source in sim.resources.sources.values():
				for resource in source_totals: source_totals[resource] += float(source.remaining.get(resource, 0))
			var age := 0.0
			for task in sim.coordinator.tasks:
				if task.state in ["active", "reserved"]: age = maxf(age, sim.seconds - float(task.created_sim))
			oldest_task = maxf(oldest_task, age)
			var project_age: float = 0 if sim.development.active.is_empty() else sim.seconds - sim.development.active.created
			oldest_project = maxf(oldest_project, project_age)
			health.append({"day": sim.seconds / 600, "population": sim.citizens.size(), "actual_entities": scene.get_children().filter(func(node: Node) -> bool: return node.get_script() == preload("res://scripts/citizen_agent.gd")).size(), "shelter": sim.needs.shelter_capacity, "stocks": sim.economy.snapshot(), "source_remaining": source_totals, "depleted_objects": sim.salvage.objects.keys().filter(func(id: String) -> bool: return sim.salvage.depleted(id)).size(), "housing": sim.development.count("housing"), "workshop": sim.development.count("workshop"), "active_projects": 0 if sim.development.active.is_empty() else 1, "governor": sim.governor.mode, "cohorts": sim.population.cohorts.size(), "tasks": sim.coordinator.tasks.size(), "tickets": sim.economy.tickets.size(), "bundles": sim.resources.bundles.size(), "events": sim.journal.events.size(), "failed_tasks": sim.coordinator.summary().failed_total, "oldest_task_seconds": age, "oldest_project_seconds": project_age, "ticks_per_wall_second": sim.seconds * 10 / maxf(0.01, (Time.get_ticks_msec() - started) / 1000.0)})
			print("POC45_DAY " + JSON.stringify(sim.status()) + " projects=" + JSON.stringify(sim.development.projects) + " growth=" + sim.population.reason)
			next_day += 600
	var checks := {
		"needs_pressure": seen.get("needs_pressure", false), "autonomous_water": sim.planner.directives.has("water"),
		"material_blocker": seen.get("material_blocker", false), "salvage_work": seen.get("salvage_work", false), "haul": seen.get("haul", false), "climb": seen.get("climb", false),
		"traversal": sim.construction.traversal_deployed, "recovery": seen.get("recovery", false),
		"development_haul": seen.get("development_haul", false), "development_work": seen.get("development_work", false), "frame": seen.get("stage_FRAME", false), "shell": seen.get("stage_SHELL", false),
		"workshop_frame": seen.get("workshop_stage_FRAME", false), "workshop_shell": seen.get("workshop_stage_SHELL", false),
		"population": sim.citizens.size() >= 65, "housing": sim.development.count("housing") >= 2, "workshop": sim.development.count("workshop") == 1,
		"additional_salvage": sim.salvage.stage_completions > 4, "shelter_exact": sim.needs.shelter_capacity == 50 + sim.development.count("housing") * 10,
		"actual_entities": scene.get_children().filter(func(child: Node) -> bool: return child.get_script() == preload("res://scripts/citizen_agent.gd")).size() == sim.citizens.size(),
		"healthy": sim.status().food_days >= 1 and sim.status().water_days >= 1 and sim.status().urgent <= sim.citizens.size() * 0.3,
		"bounded": maxima.tasks <= 600 and maxima.tickets < 300 and maxima.bundles < 300 and maxima.events <= 128,
		"no_failed_tasks": sim.coordinator.summary().failed_total == 0
	}
	var expected_cost := {"wood": 4.0, "metal": 4.0}
	for project in sim.development.projects:
		if project.state == "COMPLETE":
			for resource in expected_cost: expected_cost[resource] += float(project.required[resource])
	checks.costs_exact = sim.economy.project_consumed.wood == expected_cost.wood and sim.economy.project_consumed.metal == expected_cost.metal
	checks.effects_once = sim.development.projects.all(func(p: Dictionary) -> bool: return p.state != "COMPLETE" or p.effect_applied and p.work >= p.required_work and p.work_by_citizen.size() > 0 and p.delivery_distance > 0)
	checks.no_stuck_project = sim.development.active.is_empty() or sim.seconds - sim.development.active.created < 1200
	checks.cohort_rules = sim.population.cohorts.all(func(c: Dictionary) -> bool: return c.after - c.before == 5 and c.after <= 150 and c.shelter >= c.after and minf(c.food_days_before, c.water_days_before) >= 2)
	for index in range(1, sim.population.cohorts.size()):
		if sim.population.cohorts[index].seconds - sim.population.cohorts[index - 1].seconds < 599.9: checks.cohort_rules = false
	checks.completed_navigation = sim.development.projects.all(func(p: Dictionary) -> bool: return p.state != "COMPLETE" or sim.coordinator.navigation.is_obstacle_position(p.site) and not sim.coordinator.navigation.is_walkable(p.site))
	checks.safe_stop = days < 60 or sim.citizens.size() <= 150 and sim.development.active.is_empty()
	checks.hundred_real = days < 60 or maxima.population >= 100 and sim.seconds - first_100 >= 600
	for key in checks:
		if not checks[key]: failure += " " + key
	await capture("later-expanded-settlement", sim.development.center(), 175)
	await capture("mature-fishbowl-room", Vector3.ZERO, 330)
	var result := {"result": "PASS" if failure.is_empty() else "FAIL", "failure": failure, "checks": checks, "observed": seen, "maxima": maxima, "status": sim.status(), "timeline": timeline, "health": health, "projects": sim.development.projects, "cohorts": sim.population.cohorts, "sources": sim.resources.sources, "salvage": sim.salvage.objects, "events": all_events, "task_summary": sim.coordinator.summary(), "captures": captures, "governor_evaluations": sim.governor.evaluations, "oldest_task_seconds": oldest_task, "oldest_project_seconds": oldest_project, "max_movement_per_tick": max_move, "first_100_seconds": first_100, "wall_seconds": (Time.get_ticks_msec() - started) / 1000.0}
	var output := OS.get_environment("ROOMSCALE_POC45_RESULT")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "\t"))
	print("POC45_SCENARIO_" + result.result + " " + JSON.stringify(checks) + " failure=" + failure)
	scene.queue_free()
	await process_frame
	quit(0 if failure.is_empty() else 1)

func once(label: String, focus: Vector3, distance: float) -> void:
	if captured.has(label) or OS.get_environment("ROOMSCALE_VISUAL_DIR").is_empty(): return
	captured[label] = true
	await capture(label, focus, distance)

func capture(label: String, focus: Vector3, distance: float) -> void:
	var directory := OS.get_environment("ROOMSCALE_VISUAL_DIR")
	if directory.is_empty(): return
	var enabled: bool = sim.camera_director.enabled
	sim.camera_director.enabled = false
	sim.hud.refresh()
	var rig: Node = scene.get_node("CameraRig")
	rig.focus_at(focus + Vector3(-distance * 0.15, 0, 0), distance, 45, 0)
	rig.distance = distance
	rig._camera_transition_active = false
	rig._apply_transform()
	await process_frame
	for citizen in sim.citizens: citizen.refresh_visual_lod()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(label + ".png")
	if scene.get_viewport().get_texture().get_image().save_png(path) != OK: failure = "Screenshot capture failed: " + label
	var file := FileAccess.open(directory.path_join(label + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"seconds": sim.seconds, "state": sim.status(), "projects": sim.development.projects, "focus": focus, "distance": distance}, "\t"))
	captures.append(path)
	sim.camera_director.enabled = enabled
