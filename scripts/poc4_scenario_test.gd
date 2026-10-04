extends SceneTree
## Complete scenario drives production fixed ticks; only player-level intent is issued.

var scene: Node3D
var sim: Node
var water_source := ""
var salvage_object := ""
var target_region := ""
var checks: Array[String] = []
var failed := false
var observations := {"salvage_work": false, "haul": false, "reserved": false, "in_transit": false, "delivered": false, "climb": false}
var max_tasks := 0
var max_tickets := 0
var max_bundles := 0
var longest_task := 0.0
var max_step := 0.0
var captures: Array[String] = []
var recovered_at := 0.0
var wall_start := 0
var failed_tasks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> bool:
	if not condition:
		failed = true
		push_error("POC4_SCENARIO_FAIL: " + label)
		print("POC4_FAILURE_STATE " + JSON.stringify(sim.status() if sim != null else {}))
		if sim != null:
			print("POC4_FAILURE_TASKS " + JSON.stringify(sim.coordinator.tasks.filter(func(t: Dictionary) -> bool: return t.state in ["active", "reserved"])))
			print("POC4_FAILED_HISTORY " + JSON.stringify(failed_tasks))
		quit(1)
		return false
	checks.append(label)
	print("POC4_CHECK_PASS " + label)
	return true

func ticks(count: int) -> bool:
	for index in range(count):
		var positions: Array[Vector3] = []
		for citizen in sim.citizens: positions.append(citizen.global_position)
		sim.step()
		max_tasks = maxi(max_tasks, sim.coordinator.tasks.size())
		max_tickets = maxi(max_tickets, sim.economy.tickets.size())
		max_bundles = maxi(max_bundles, sim.resources.bundles.size())
		for citizen in sim.citizens:
			max_step = maxf(max_step, citizen.global_position.distance_to(positions[citizen.citizen_id]))
			if not citizen.global_position.is_finite() or float(citizen.needs.food) < 0 or float(citizen.needs.food) > 1 or float(citizen.needs.water) < 0 or float(citizen.needs.water) > 1 or float(citizen.needs.fatigue) < 0 or float(citizen.needs.fatigue) > 1:
				return check(false, "citizen need/position state corrupted")
			if citizen.task_type == "SALVAGE" and citizen.state == "WORK":
				if sim.distance_to_object(String(sim.coordinator.get_task(citizen.task_id).object_id), citizen.global_position) > 0.3: return check(false, "salvage worker must reach actual object edge")
				observations.salvage_work = true
			if citizen.carrying and citizen.task_type == "BUNDLE_HAUL": observations.haul = true
			if citizen.task_type == "RESOURCE_COLLECT" and citizen.global_position.y > 3 and citizen.global_position.y < 29: observations.climb = true
		for state in ["reserved", "in_transit", "delivered"]:
			if sim.economy.state_total("wood", state) + sim.economy.state_total("metal", state) > 0: observations[state] = true
		if index % 100 == 0:
			for task in sim.coordinator.tasks:
				if task.state == "failed" and not failed_tasks.has(task.id):
					var failure: Dictionary = task.duplicate(true)
					var owner: Node3D = sim.citizens[int(task.citizen_id)]
					failure.observed_position = owner.global_position
					failure.observed_region = sim.region_of(owner.global_position)
					failed_tasks[task.id] = failure
				if task.state in ["active", "reserved"]: longest_task = maxf(longest_task, sim.seconds - float(task.get("started_sim", task.get("claimed_sim", task.get("created_sim", 0)))))
			var errors: Array[String] = sim.economy.audit()
			errors.append_array(sim.resources.audit())
			if not errors.is_empty() or max_tasks > 600 or max_tickets > 80 or max_bundles > 80 or longest_task > 600 or max_step > 0.651:
				return check(false, "accounting/task health: " + JSON.stringify({"audit":errors,"tasks":max_tasks,"tickets":max_tickets,"bundles":max_bundles,"oldest_live_seconds":longest_task,"movement":max_step}))
	return true

func _run() -> void:
	wall_start = Time.get_ticks_msec()
	OS.set_environment("ROOMSCALE_ROOM", "room_poc4")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	sim = scene.get_node_or_null("CivilizationSimulation")
	if not check(sim != null and sim.citizens.size() == 50, "01 population=50 and production simulation initializes"): return
	sim.set_process(false)
	for id in sim.resources.sources:
		if sim.resources.sources[id].remaining.has("water") and sim.resources.sources[id].region != "FLOOR":
			water_source = id
			target_region = sim.resources.sources[id].region
	for id in sim.salvage.objects:
		var profile: Dictionary = sim.resources.objects[id].profile
		if sim.resources.objects[id].data.has("surface"): continue
		var yields := {"wood": 0.0, "metal": 0.0}
		for stage in profile.stages:
			for resource in stage.yields:
				if yields.has(resource): yields[resource] += float(stage.yields[resource])
		if yields.wood >= 4 and yields.metal >= 4:
			salvage_object = id
			break
	if not check(not water_source.is_empty() and not salvage_object.is_empty(), "02 generic elevated water and material sources discovered"): return
	if not check(sim.citizens[0].needs.has("food") and sim.citizens[0].needs.has("water") and sim.citizens[0].needs.has("fatigue"), "03 persistent citizen needs initialized"): return
	if not check(sim.economy.available.wood < 4 and sim.economy.available.metal < 4, "04 starting construction stock insufficient"): return
	await capture("starting-settlement", Vector3.ZERO, 330)
	var initial_water: float = sim.economy.available.water
	var initial_need: float = sim.citizens[0].needs.water
	if not ticks(1000): return
	if not check(sim.needs.drinks > 0 and sim.economy.available.water < initial_water and sim.citizens[0].needs.water != initial_need, "05 real need decay and water consumption lower forecast"): return
	if not check(sim.economy.forecast("water", 50) < 1, "06 water shortage forecast"): return
	await capture("declining-water", Vector3.ZERO, 330)
	sim.planner.set_priority("Survival", 4)
	sim.planner.set_priority("Resources", 3)
	sim.planner.set_priority("Construction", 3)
	if not check(sim.secure_resource("water"), "07 civilization Secure Water directive"): return
	if not check(not sim.coordinator.surface_navigation.has_connection("FLOOR", target_region), "08 water source initially unreachable"): return
	for batch in range(100):
		if not ticks(10): return
		if sim.construction.project_created: break
		if batch % 20 == 0: await process_frame
	if not check(sim.construction.project_created and sim.coordinator.get_reach_goal_status().state == "BARRIER_CONFIRMED", "09 existing physical investigation creates traversal project"): return
	if not ticks(500): return
	if not check(sim.salvage.objects[salvage_object].stage == 0 and sim.salvage.total_work == 0 and sim.economy.received.wood == 0, "10 protected objects remain intact during shortage"): return
	if not check(sim.construction.delivered.wood == 0 and sim.construction.delivered.metal == 0 and sim.planner.reasons.any(func(reason: String) -> bool: return reason.contains("No authorized")), "11 planner explains missing authorized construction resources"): return
	sim.hud.select_object(salvage_object)
	await capture("material-shortage", object_position(salvage_object), 65)
	if not check(sim.authorize_salvage(salvage_object), "12 high-level salvage authorization"): return
	sim.hud.select_object(salvage_object)
	await capture("salvage-authorized", object_position(salvage_object), 65)
	var captured_stage := 0
	var captured_haul := false
	var captured_construction := false
	var captured_route := false
	var captured_water := false
	var captured_worker := false
	var captured_carry := false
	var captured_climb := false
	for batch in range(1600):
		if not ticks(10): return
		for citizen in sim.citizens:
			if not captured_worker and citizen.task_type == "SALVAGE" and citizen.state == "WORK":
				captured_worker = true
				scene.set("_selected_citizen", citizen)
				await capture("citizen-salvage-work", citizen.global_position + Vector3.UP * 0.25, 3)
			if not captured_carry and citizen.task_type == "BUNDLE_HAUL" and citizen.carrying:
				captured_carry = true
				scene.set("_selected_citizen", citizen)
				await capture("citizen-carrying-material", citizen.global_position + Vector3.UP * 0.25, 3)
			if not captured_climb and citizen.task_type == "RESOURCE_COLLECT" and citizen.global_position.y > 8 and citizen.global_position.y < 15:
				captured_climb = true
				scene.set("_selected_citizen", citizen)
				await capture("water-source-climb", citizen.global_position + Vector3.UP * 0.25, 4)
		var stage: int = sim.salvage.objects[salvage_object].stage
		if stage > captured_stage:
			captured_stage = stage
			await capture("salvage-stage-%d" % stage, object_position(salvage_object), 65)
		if not captured_haul and observations.haul:
			captured_haul = true
			await capture("resource-hauling", sim.salvage_targets[salvage_object], 45)
		if not captured_construction and sim.construction.delivered.wood > 0:
			captured_construction = true
			await capture("construction-supplied", sim.construction.site_position, 65)
		if not captured_route and sim.construction.traversal_deployed:
			captured_route = true
			await capture("traversal-complete", sim.construction.site_position.lerp(sim.resources.sources[water_source].position, 0.5), 150)
		if not captured_water and sim.source_visits.water > 0:
			captured_water = true
			await capture("water-acquisition", sim.resources.sources[water_source].position, 65)
		if sim.source_visits.water > 0 and sim.economy.available.water > initial_water + 60 and sim.salvage.depleted(salvage_object):
			recovered_at = sim.seconds
			break
		if batch % 50 == 0: await process_frame
	if not check(recovered_at > 0, "13 complete water crisis recovery within bounded time"): return
	if not check(observations.salvage_work and sim.salvage.stage_completions >= 4, "14 citizens perform genuine staged salvage work"): return
	if not check(not scene.get_node("RoomObjects/" + salvage_object).visible and sim.salvage.depleted(salvage_object), "15 visible persistent depleted object"): return
	if not check(observations.haul and sim.haul_pickups >= 5 and sim.haul_deliveries >= 5, "16 physical bundle pickup/carry/delivery"): return
	if not check(observations.reserved and observations.in_transit and observations.delivered and sim.economy.project_consumed.wood == 4 and sim.economy.project_consumed.metal == 4, "17 exclusive reserved/transit/delivered/consumed project material"): return
	if not check(sim.construction._completed_stages == 3 and sim.construction.traversal_deployed and sim.coordinator.surface_navigation.has_connection("FLOOR", target_region), "18 existing construction builds and activates traversal"): return
	if not check(observations.climb and sim.source_visits.water > 0 and sim.resources.delivered.water > 0, "19 citizens climb to elevated source and return stored water"): return
	if not check(sim.economy.forecast("water", 50) > initial_water / 150.0, "20 recovered water forecast"): return
	await capture("water-recovered", Vector3.ZERO, 330)
	print("POC4_M6_PASS recovered_seconds=%.1f water_visits=%d status=%s" % [recovered_at, sim.source_visits.water, JSON.stringify(sim.status())])
	var duration := float(OS.get_environment("ROOMSCALE_POC4_DAYS"))
	if duration > 0:
		var until: float = sim.seconds + duration * 600
		var generated_wood: float = sim.resources.generated.wood
		var consumed_food: float = sim.economy.consumed.food
		var consumed_water: float = sim.economy.consumed.water
		var rest_count: int = sim.needs.rests
		var next_day: float = sim.seconds + 600
		while sim.seconds < until:
			if not ticks(100): return
			await process_frame
			if sim.seconds >= next_day:
				print("POC4_SUSTAINED_DAY %.2f %s" % [sim.seconds / 600, JSON.stringify(sim.status())])
				next_day += 600
		if not check(sim.economy.consumed.food > consumed_food and sim.economy.consumed.water > consumed_water and sim.needs.rests > rest_count, "21 ongoing food/water/rest after recovery"): return
		if not check(sim.resources.generated.wood == generated_wood and sim.salvage.depleted(salvage_object) and sim.construction.traversal_deployed, "22 depleted salvage and completed infrastructure persist"): return
		if not check(sim.economy.available.food > 0 and sim.economy.available.water > 0 and sim.status().urgent < 15, "23 settlement remains supplied and operational"): return
		if not check(sim.coordinator.summary().failed_total == 0, "24 no failed citizen tasks across sustained simulation"): return
		if not check(sim.coordinator.tasks.size() <= 600 and sim.economy.tickets.size() < 80 and sim.resources.bundles.size() < 80, "25 bounded task/inventory lifecycle"): return
		print("POC4_SUSTAINED_PASS days_after_recovery=%.0f" % duration)
		await capture("sustained-altered-room", object_position(salvage_object), 80)
	var result := {"result": "PASS", "days_after_recovery": duration, "recovered_seconds": recovered_at, "checks": checks, "observations": observations, "max_tasks": max_tasks, "max_tickets": max_tickets, "max_bundles": max_bundles, "max_active_task_seconds": longest_task, "max_movement_per_tick": max_step, "status": sim.status(), "source_visits": sim.source_visits, "sources": sim.resources.sources, "salvage": sim.salvage.objects[salvage_object], "captures": captures, "wall_seconds": (Time.get_ticks_msec() - wall_start) / 1000.0}
	var output := OS.get_environment("ROOMSCALE_POC4_RESULT")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "\t"))
	print("POC4_SCENARIO_PASS " + JSON.stringify(result))
	scene.queue_free()
	await process_frame
	quit()

func object_position(id: String) -> Vector3:
	var values: Array = sim.resources.objects[id].data.position
	return Vector3(float(values[0]), float(values[1]) + 8, float(values[2]))

func capture(label: String, focus: Vector3, distance: float) -> void:
	var directory := OS.get_environment("ROOMSCALE_VISUAL_DIR")
	if directory.is_empty(): return
	sim.hud.refresh()
	var rig: Node = scene.get_node("CameraRig")
	rig.focus_at(focus, distance, 40, 0)
	rig.distance = distance
	rig._camera_transition_active = false
	rig._apply_transform()
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(label + ".png")
	if not check(scene.get_viewport().get_texture().get_image().save_png(path) == OK, "capture " + label): return
	var note := FileAccess.open(directory.path_join(label + ".json"), FileAccess.WRITE)
	note.store_string(JSON.stringify({"seconds": sim.seconds, "state": sim.status(), "salvage": sim.salvage.objects[salvage_object], "focus": focus, "distance": distance}, "\t"))
	captures.append(path)
