extends SceneTree
## Read-only observer of the actual scene and 0.1s production step; no commands.
const Room = preload("res://scripts/room_definition.gd")
const Floor = preload("res://scripts/floor_navigation.gd")
const Surface = preload("res://scripts/surface_navigation.gd")
const Citizen = preload("res://scripts/citizen_agent.gd")
var sim: Node
var scene: Node3D
var config: Dictionary
var validation: Dictionary = {}
var milestones: Dictionary = {}
var violations: Array = []
var failure = ""
var initial: Dictionary = {}
var maxima = {"population":5,"tasks":0,"live_tasks":0,"journal":0,"tickets":0,"bundles":0,"projects":0,"movement":0.0,"oldest_live_task":0.0}
var timeline: Array = []
var connectivity: Array = []
var stall_windows: Array = []
var stage_history: Dictionary = {}
var previous_positions: Dictionary = {}
var previous_population = 5
var growth_cursor = 0
var previous_navigation = ""
var last_progress = ""
var last_progress_at = 0.0
var deadlock = false
var labor_witnesses: Dictionary = {}
var traversal_labor_witnesses: Dictionary = {}
var strategic_witnesses: Dictionary = {}
var started = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	started = Time.get_ticks_msec()
	config = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("ROOMSCALE_POC471_CONFIG")))
	var loaded = Room.load_requested()
	validation = {"structural": loaded.ok,"schema_errors":loaded.errors,"navigation_errors":[],"solvability_errors":[],"solvable":false}
	if not loaded.ok:
		failure = "Generator invalid: structural contract"
		finish()
		return
	var floor_nav = Floor.new()
	floor_nav.configure(loaded.definition)
	floor_nav._rebuild_grid()
	var surface_nav = Surface.new()
	surface_nav.configure(loaded.definition, floor_nav)
	# Surface _ready does not change simulation rules; it registers definition regions.
	root.add_child(floor_nav)
	root.add_child(surface_nav)
	validation.navigation_errors = Room.validate_navigation(loaded.definition, floor_nav, surface_nav)
	var origin = Room.vector3_from(loaded.definition.start.origin)
	var spawn = Room.vector3_from(loaded.definition.spawn.center)
	if not floor_nav.is_walkable(origin) or floor_nav.is_obstacle_position(origin): validation.solvability_errors.append("Illegal founding origin")
	if floor_nav.path_between(spawn, origin).is_empty(): validation.solvability_errors.append("Spawn disconnected from settlement")
	floor_nav.free()
	surface_nav.free()
	if not validation.navigation_errors.is_empty() or not validation.solvability_errors.is_empty():
		if config.classification == "negative" and config.name == "Disconnected Spawn":
			validation.expected_rejection = true
		else: failure = "Generator invalid: navigation/connectivity"
		finish()
		return
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	sim = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	initial = snapshot()
	if sim.citizens.size() != 5 or sim.needs.shelter_capacity != 0 or sim.has_capability("workshop") or sim.has_capability("storage"):
		violate("Invalid five-founder startup")
	# Conservative feasibility certificate: production-safe reachable salvage and sites,
	# connected floor resources and enough finite survival horizon/materials.
	var material = {"wood":0.0,"metal":0.0}
	for candidate in sim.governor.candidates(sim, {"wood":30,"metal":11}):
		for stage in sim.salvage.objects[candidate.id].stages:
			for resource in material: material[resource] += float(stage.yields.get(resource,0))
	validation.safe_salvage_totals = material
	var floor_resources = {"food":0.0,"water":0.0}
	for source in sim.resources.sources.values():
		if source.region == "FLOOR":
			for resource in floor_resources: floor_resources[resource] += float(source.remaining.get(resource,0))
	validation.floor_resources = floor_resources
	validation.floor_resource_path_lengths = {}
	for id in sim.resources.sources:
		var source = sim.resources.sources[id]
		if source.region == "FLOOR": validation.floor_resource_path_lengths[id] = sim.coordinator._path_length(sim.coordinator.navigation.path_between(origin,source.position))
	validation.safe_salvage_path_lengths = {}
	for candidate in sim.governor.candidates(sim,{"wood":30,"metal":11}):
		var paths = sim.salvage_approaches(candidate.id).map(func(at): return sim.coordinator._path_length(sim.coordinator.navigation.path_between(origin,at)))
		if not paths.is_empty(): validation.safe_salvage_path_lengths[candidate.id] = paths.min()
	validation.shelter_site = sim.development.select_site("shelter")
	validation.depot_site = sim.development.select_site("depot")
	if config.name in ["Crowded Settlement Origin","Constrained Build Sites"]:
		var local_sites = 0
		for x in range(-3,4):
			for z in range(-3,4):
				if sim.development.valid_site(origin + Vector3(x*16,0,z*16)): local_sites += 1
		validation.local_safe_sites_within_48_inches = local_sites
	if not validation.shelter_site.valid: validation.solvability_errors.append("No legal primitive shelter site")
	if not validation.depot_site.valid: validation.solvability_errors.append("No legal bootstrap depot site")
	if material.wood < 30 or material.metal < 11: validation.solvability_errors.append("Insufficient safe reachable full-sequence material budget")
	if floor_resources.food < 150 or floor_resources.water + sim.economy.initial.water < 60: validation.solvability_errors.append("Insufficient reachable founder survival horizon")
	validation.solvable = validation.solvability_errors.is_empty()
	if config.classification != "negative" and not validation.solvable:
		failure = "Generator invalid: insufficient feasibility certificate"
		finish()
		return
	for c in sim.citizens: previous_positions[c.citizen_id] = c.global_position
	check_invariants()
	var next_sample = 0.0
	var limit = float(config.days) * 600.0
	while sim.seconds + 0.00001 < limit and failure.is_empty():
		for tick in range(200):
			if sim.seconds + 0.00001 >= limit or not failure.is_empty(): break
			sim.step()
			observe()
			check_invariants()
		if sim.seconds >= next_sample:
			timeline.append({"seconds":sim.seconds,"status":sim.status(),"tasks":sim.coordinator.summary(),"journal_size":sim.journal.events.size(),"journal_sequence":sim.journal.sequence,"suppression_keys":sim.journal._states.size(),"projects":sim.development.projects.size(),"governor":sim.governor.reason,"growth":sim.population.reason,"states":state_distribution()})
			check_progress()
			next_sample += 600.0
		await process_frame
	if config.classification == "negative": check_negative()
	else:
		for key in ["shelter_complete","depot_complete","workshop_complete","housing_complete","sixth_citizen","traversal_complete","physical_climb","elevated_territory"]:
			if not milestones.has(key): failure += " Missing milestone " + key
	finish()

func violate(reason: String) -> void:
	if violations.is_empty(): violations.append({"seconds":sim.seconds if sim != null else 0,"reason":reason})
	failure = reason

func mark(key: String, at: float = -1.0) -> void:
	if not milestones.has(key): milestones[key] = sim.seconds if at < 0 else at

func observe() -> void:
	for c in sim.citizens:
		if c.state == "WORK" and c.task_type in ["SALVAGE","RESOURCE_COLLECT","CONSTRUCTION_BUILD"]: mark("meaningful_work")
		if c.task_type == "SALVAGE" and c.state == "WORK": mark("first_salvage")
		if c.carrying: mark("first_haul")
		if c.carrying and c.task_type == "BUNDLE_HAUL" and c._delivery_resource in ["wood","metal"]: mark("material_haul")
		if c.state == "WORK" and c.task_type == "CONSTRUCTION_BUILD":
			labor_witnesses[c.citizen_id] = true
			var task = sim.coordinator.get_task(c.task_id)
			if not task.has("project_id") and task.has("stage"):
				if not traversal_labor_witnesses.has(task.stage): traversal_labor_witnesses[task.stage] = {}
				traversal_labor_witnesses[task.stage][c.citizen_id] = true
		if c.global_position.y > 0.1 and c.global_position.y < sim.construction.target_anchor.y - 0.1: mark("physical_climb")
		if c.global_position.y >= sim.construction.target_anchor.y - 0.1: mark("elevated_territory")
	for p in sim.development.projects:
		mark(p.kind + "_started", p.created)
		if not stage_history.has(p.id):
			stage_history[p.id] = {"states":[],"stages":[]}
			# PLANNED is transient inside request(); use its real journal snapshot.
			for event in sim.journal.events:
				if event.kind == "development_started" and event.evidence.get("id","") == p.id and event.evidence.get("state","") == "PLANNED": stage_history[p.id].states.append("PLANNED")
		if not p.state in stage_history[p.id].states: stage_history[p.id].states.append(p.state)
		if not p.stage in stage_history[p.id].stages: stage_history[p.id].stages.append(p.stage)
		if p.state == "COMPLETE": mark(p.kind + "_complete", p.completed)
	if sim.citizens.size() > 5: mark("sixth_citizen")
	if sim.construction.project_created: mark("traversal_started")
	if sim.construction.traversal_deployed: mark("traversal_complete")
	var nav_hash = JSON.stringify(sim.coordinator.navigation.obstacle_rects).sha256_text()
	if nav_hash != previous_navigation:
		previous_navigation = nav_hash
		var paths = {}
		for id in sim.resources.sources:
			var s = sim.resources.sources[id]
			if s.region == "FLOOR": paths[id] = not sim.coordinator.navigation.path_between(sim.coordinator.depot_station,s.position).is_empty()
		paths.housing = not sim.coordinator.navigation.path_between(sim.coordinator.depot_station,sim.coordinator.housing_station).is_empty()
		connectivity.append({"seconds":sim.seconds,"obstacles":sim.coordinator.navigation.obstacle_rects.size(),"paths":paths})
		if config.classification != "negative" and paths.values().has(false): violate("Settlement build/salvage disconnected required anchors")

func check_invariants() -> void:
	var ids = {}
	var population = sim.citizens.size()
	var entities = scene.get_children().filter(func(n): return n.get_script() == Citizen).size()
	if entities != population: violate("Population/entity mismatch")
	if population - previous_population not in [0,1]: violate("Growth did not create one citizen")
	if population > 5 and population > sim.needs.shelter_capacity: violate("Growth exceeds earned shelter")
	for c in sim.citizens:
		if ids.has(c.citizen_id): violate("Duplicate citizen ID")
		ids[c.citizen_id] = true
		var at: Vector3 = c.global_position
		if not at.is_finite(): violate("Nonfinite position")
		if previous_positions.has(c.citizen_id):
			var movement = at.distance_to(previous_positions[c.citizen_id])
			maxima.movement = maxf(maxima.movement,movement)
			if movement > Citizen.WALK_SPEED * sim.STEP + 0.0001: violate("Movement exceeds production tick limit")
		elif not sim.coordinator.navigation.is_walkable(at) or sim.coordinator.navigation.is_obstacle_position(at): violate("Illegal citizen arrival position")
		if not sim.coordinator.navigation.room_bounds().has_point(Vector2(at.x,at.z)): violate("Citizen outside world bounds")
		if at.y < 0.1:
			if sim.coordinator.navigation.is_obstacle_position(at): violate("Citizen inside navigation obstacle: %s citizen=%s task=%s" % [at,c.citizen_id,c.task_type])
		else:
			if not sim.construction.traversal_deployed or not sim.coordinator.surface_navigation.has_connection("FLOOR",sim.construction.target_region): violate("Elevated access without legitimate traversal")
			else:
				var surface = sim.coordinator.surface_navigation.regions[sim.construction.target_region]
				var local: Vector3 = (at - surface.center).rotated(Vector3.UP,-deg_to_rad(surface.rotation_degrees))
				var on_surface = absf(at.y - surface.height) < 0.001 and absf(local.x) <= surface.dimensions.x / 2 and absf(local.z) <= surface.dimensions.y / 2
				var on_link = false
				for connection in sim.coordinator.surface_navigation.connections:
					for segment in range(1,connection.path.size()):
						var a: Vector3 = connection.path[segment-1]
						var b: Vector3 = connection.path[segment]
						var along = clampf((at-a).dot(b-a) / maxf((b-a).length_squared(),0.000001),0,1)
						if at.distance_to(a+(b-a)*along) < 0.001: on_link = true
				if not on_surface and not on_link: violate("Citizen outside valid surface/traversal geometry")
		for need in ["food","water","fatigue"]:
			if not is_finite(float(c.needs[need])) or float(c.needs[need]) < 0 or float(c.needs[need]) > 1: violate("Invalid citizen need")
		previous_positions[c.citizen_id] = at
	previous_population = population
	if sim.citizens.size() != 5 + sim.population.cohorts.size(): violate("Population growth ledger mismatch")
	var shelter = 5 * sim.development.count("shelter") + 10 * sim.development.count("housing")
	if sim.needs.shelter_capacity != shelter: violate("Unearned shelter capacity")
	for capability in ["storage","workshop"]:
		var kind = "depot" if capability == "storage" else "workshop"
		if sim.has_capability(capability) != (sim.development.count(kind) > 0): violate("Unearned capability " + capability)
	if sim.construction.project_created and not sim.has_capability("workshop"): violate("Traversal before completed workshop")
	if sim.construction.traversal_deployed and (sim.construction._completed_stages != 3 or traversal_labor_witnesses.size() != 3): violate("Traversal deployed without real build stages/labor")
	for gate_index in range(sim.construction._stage_gate_snapshots.size()):
		var gate = sim.construction._stage_gate_snapshots[gate_index]
		var required = sim.construction.stage_requirements(gate_index)
		for resource in required:
			if gate[resource] < required[resource]: violate("Traversal stage before physical delivery")
	var expected_cost = {"wood":0.0,"metal":0.0}
	for p in sim.development.projects:
		if p.state != "COMPLETE":
			if p.effect_applied: violate("Effect before completion")
			continue
		if p.work < p.required_work or p.work_by_citizen.is_empty() or p.delivery_distance <= 0: violate("Completed structure lacks physical delivery/labor")
		for id in p.work_by_citizen:
			if not ids.has(id): violate("Construction labor attributed to missing citizen")
		for r in expected_cost:
			if p.delivered[r] != p.required[r]: violate("Completion without exact required materials")
			expected_cost[r] += p.required[r]
		if not p.effect_applied or not sim.coordinator.navigation.is_obstacle_position(p.site): violate("Completion lacks effect/navigation obstacle")
		if stage_history.has(p.id) and (not "FRAME" in stage_history[p.id].stages or not "SHELL" in stage_history[p.id].stages): violate("Missing visible construction stages")
	for resource in ["food","water","wood","metal"]:
		var acquired = float(sim.economy.exported[resource])
		for o in sim.salvage.objects.values(): acquired += float(o.yielded.get(resource,0))
		for s in sim.resources.sources.values(): acquired += float(s.extracted.get(resource,0))
		if absf(acquired - sim.resources.generated[resource]) > 0.0001 or sim.economy.received[resource] != sim.resources.delivered[resource]: violate("Resource generated without source: " + resource)
		if not is_finite(float(sim.economy.available[resource])): violate("Nonfinite resource account")
	for resource in expected_cost:
		if sim.construction._completed_stages == 3: expected_cost[resource] += sim.construction.requirements()[resource]
		if sim.economy.project_consumed[resource] != expected_cost[resource]: violate("Project material consumption not exactly once")
	if not sim.economy.audit().is_empty() or not sim.resources.audit().is_empty(): violate("Production economy/resource audit")
	for o in sim.salvage.objects.values():
		var earned = {}
		var work = 0.0
		for i in range(o.stage):
			work += float(o.stages[i].work)
			for r in o.stages[i].yields: earned[r] = float(earned.get(r,0)) + float(o.stages[i].yields[r])
		if earned != o.yielded or o.work + 0.0001 < work: violate("Salvage yield without legitimate stages/work")
	while growth_cursor < sim.population.cohorts.size():
		var c = sim.population.cohorts[growth_cursor]
		if c.after - c.before != 1 or c.after > c.shelter or c.stable_seconds < 299.99 or minf(c.food_days_before,c.water_days_before) < 2 or minf(c.food_days_after,c.water_days_after) < 2 or not sim.has_capability("workshop") or not sim.has_capability("storage") or sim.governor.emergency or not sim.development.carrying_capacity(c.after): violate("Unsafe population growth event")
		if c.food_days_after >= c.food_days_before or c.water_days_after >= c.water_days_before: violate("Demand did not increase on arrival")
		if growth_cursor > 0 and c.seconds - sim.population.cohorts[growth_cursor-1].seconds < 599.99: violate("Growth cooldown bypass")
		growth_cursor += 1
	var live = 0
	for task in sim.coordinator.tasks:
		if task.state not in ["active","reserved"]: continue
		live += 1
		if not ids.has(task.citizen_id): violate("Live task has invalid/deleted owner")
		maxima.oldest_live_task = maxf(maxima.oldest_live_task,sim.seconds - float(task.created_sim))
	if live > population * 3 + 20 or sim.coordinator.tasks.size() > sim.coordinator.MAX_HISTORY + population * 3 + 20: violate("Unbounded retained/live task growth")
	if sim.journal.events.size() > sim.journal.limit: violate("Unbounded journal")
	maxima.population = maxi(maxima.population,population)
	maxima.tasks = maxi(maxima.tasks,sim.coordinator.tasks.size())
	maxima.live_tasks = maxi(maxima.live_tasks,live)
	maxima.journal = maxi(maxima.journal,sim.journal.events.size())
	maxima.tickets = maxi(maxima.tickets,sim.economy.tickets.size())
	maxima.bundles = maxi(maxima.bundles,sim.resources.bundles.size())
	maxima.projects = maxi(maxima.projects,sim.development.projects.size())

func check_progress() -> void:
	# Strategic progress excludes routine patrol and self-care, which can mask deadlock.
	var signature = [sim.resources.generated.wood,sim.resources.generated.metal,sim.resources.delivered.wood,sim.resources.delivered.metal,sim.salvage.total_work,sim.development.projects,sim.construction.delivered,sim.construction._completed_stages,sim.construction._stage_work,sim.population.cohorts.size()]
	var digest = JSON.stringify(signature).sha256_text()
	if digest != last_progress:
		last_progress = digest
		last_progress_at = sim.seconds
	elif sim.seconds - last_progress_at >= 1200:
		var classification = "legitimate scarcity / finite carrying capacity" if not sim.development.carrying_capacity(sim.citizens.size()+1) else "stable completed progression"
		if config.classification == "negative": classification = "expected impossible scenario"
		elif not milestones.has("elevated_territory") and not sim.governor.emergency and sim.development.carrying_capacity(sim.citizens.size()+1):
			classification = "actual strategic deadlock: feasible founder sequence stopped"
			deadlock = true
			failure = classification
		elif sim.governor.emergency: classification = "survival emergency; inspect feasible supply / haul rate"
		stall_windows.append({"seconds":sim.seconds,"no_strategic_progress_seconds":sim.seconds-last_progress_at,"classification":classification,"governor":sim.governor.reason,"development":sim.development.site_reason,"growth":sim.population.reason})
	# Diagnose old strategic tickets by actual attributable work/haul movement,
	# rather than treating a long project age alone as a failure.
	for task in sim.coordinator.tasks:
		if task.state not in ["active","reserved"] or task.task_type not in ["SALVAGE","BUNDLE_HAUL","CONSTRUCTION_DELIVERY","CONSTRUCTION_BUILD"]: continue
		var c = sim.citizens[task.citizen_id]
		var actual_work = 0.0
		if task.task_type == "SALVAGE": actual_work = sim.salvage.objects[task.object_id].work
		elif task.has("project_id") and not sim.development.active.is_empty(): actual_work = sim.development.active.work
		elif task.task_type == "CONSTRUCTION_BUILD": actual_work = sim.construction._completed_stages * 1000 + sim.construction._stage_work
		var current = [c.global_position,actual_work,c.carrying]
		var id = task.id
		if not strategic_witnesses.has(id) or strategic_witnesses[id].signal != current: strategic_witnesses[id] = {"signal":current,"last_progress":sim.seconds}
		elif sim.seconds - strategic_witnesses[id].last_progress >= 1200:
			stall_windows.append({"seconds":sim.seconds,"task_id":id,"task_type":task.task_type,"classification":"stale strategic task without attributable movement/work","no_progress_seconds":sim.seconds-strategic_witnesses[id].last_progress})
	var retained_ids = sim.coordinator.tasks.map(func(t): return t.id)
	for id in strategic_witnesses.keys():
		if not id in retained_ids: strategic_witnesses.erase(id)

func check_negative() -> void:
	if not failure.is_empty(): return
	match config.name:
		"No Reachable Water", "Critical Elevated Resource Before Workshop":
			if sim.citizens.size() != 5 or sim.has_capability("workshop") or sim.construction.traversal_deployed or not sim.governor.emergency: failure = "Negative did not safely stop in survival crisis"
		"Insufficient Shelter Materials":
			if sim.has_capability("shelter") or sim.economy.received.wood > 0 or sim.citizens.size() != 5: failure = "Insufficient materials negative bypassed blockage"
		"No Valid Depot Site":
			if not sim.has_capability("shelter") or sim.has_capability("storage") or sim.development.site_reason.is_empty() or sim.citizens.size() != 5: failure = "Depot negative did not stop with observable site blockage"
		"Disconnected Spawn": failure = "Disconnected spawn was not rejected before execution"

func state_distribution() -> Dictionary:
	var result = {}
	for c in sim.citizens: result[c.state] = int(result.get(c.state,0)) + 1
	return result

func snapshot() -> Dictionary:
	var citizens = []
	for c in sim.citizens: citizens.append({"id":c.citizen_id,"position":c.global_position,"state":c.state,"task_id":c.task_id,"task":c.task_type,"destination":c._destination,"needs":c.needs,"path":c._path,"path_cursor":c._path_cursor,"travelled":c.travelled_distance})
	var live_tasks = sim.coordinator.tasks.filter(func(t): return t.state in ["active","reserved"])
	live_tasks.sort_custom(func(a,b): return a.created_sim < b.created_sim)
	return {"seconds":sim.seconds,"status":sim.status(),"population":sim.citizens.size(),"shelter":sim.needs.shelter_capacity,"citizens":citizens,"states":state_distribution(),"active_development":sim.development.active,"projects":sim.development.projects,"site_reason":sim.development.site_reason,"governor":{"mode":sim.governor.mode,"reason":sim.governor.reason,"emergency":sim.governor.emergency,"rejections":sim.governor.rejections},"planner":sim.planner.reasons,"growth_reason":sim.population.reason,"growth_events":sim.population.cohorts,"tasks":sim.coordinator.summary(),"oldest_live_tasks":live_tasks.slice(0,20),"ledger":{"initial":sim.economy.initial,"available":sim.economy.available,"received":sim.economy.received,"consumed":sim.economy.consumed,"project_consumed":sim.economy.project_consumed,"exported":sim.economy.exported,"tickets":sim.economy.tickets},"sources":sim.resources.sources,"salvage":sim.salvage.objects,"bundles":sim.resources.bundles,"traversal":sim.construction.status(),"connections":sim.coordinator.surface_navigation.connections,"journal":sim.journal.events,"journal_sequence":sim.journal.sequence,"suppression_keys":sim.journal._states.size()}.duplicate(true)

func finish() -> void:
	var result = {"result":"PASS" if failure.is_empty() else "FAIL","failure":failure,"validation":validation,"initial":initial,"milestones":milestones,"violations":violations,"deadlock":deadlock,"maxima":maxima,"timeline":timeline,"connectivity":connectivity,"stage_history":stage_history,"traversal_labor_witnesses":traversal_labor_witnesses,"stall_windows":stall_windows,"observer_seconds":(Time.get_ticks_msec()-started)/1000.0}
	if sim != null:
		result.final = snapshot()
		result.structures = {}
		for kind in ["shelter","depot","workshop","housing"]: result.structures[kind] = sim.development.count(kind)
		var semantic = {"milestones":milestones,"population":sim.citizens.size(),"projects":sim.development.projects,"economy":sim.economy.snapshot(),"sources":sim.resources.sources,"salvage":sim.salvage.objects,"tasks":sim.coordinator.summary(),"citizens":result.final.citizens,"traversal":sim.construction.status(),"cohorts":sim.population.cohorts}
		result.fingerprint = JSON.stringify(semantic).sha256_text()
	FileAccess.open(OS.get_environment("ROOMSCALE_POC471_RESULT"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("POC471_OBSERVER_" + result.result + " " + failure)
	if scene != null: scene.queue_free()
	quit(0 if failure.is_empty() else 1)
