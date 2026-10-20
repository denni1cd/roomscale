extends RefCounted
## Instance-owned live innovation. Citizens and economy remain production authorities.
const Resolver := preload("res://scripts/innovation_system.gd")
const Detector := preload("res://scripts/world_problem_detector.gd")
const AdapterRegistry := preload("res://scripts/deployment_adapter_registry.gd")
const Recipes := preload("res://scripts/production_recipe_registry.gd")
const Vocabulary := preload("res://scripts/resource_vocabulary.gd")
var adapters := AdapterRegistry.new()
var recipes := Recipes.new()
var sim: Node
var enabled := false
var resolver: RefCounted
var research: Dictionary = {}
var research_history: Array[Dictionary] = []
var active: Dictionary = {}
var projects: Array[Dictionary] = []
var manual_targets: Dictionary = {}
var _next := 0.0
var _last_work_tick: Dictionary = {}
var _visuals: Dictionary = {}
var reason := "Innovation disabled"

func configure(controller: Node, config: Dictionary) -> bool:
	sim = controller
	enabled = bool(config.get("innovation", OS.get_environment("ROOMSCALE_INNOVATION") == "1"))
	if not enabled: return true
	var result := Resolver.create(sim.definition_id, [], String(config.get("innovation_catalog_path", "")))
	if not result.ok:
		enabled = false
		resolver = null
		push_error("INNOVATION_START_INVALID: %s" % [result.errors])
		return false
	resolver = result.system
	if not adapters.errors.is_empty() or not recipes.errors.is_empty():
		push_error("INNOVATION_START_INVALID: %s %s" % [adapters.errors,recipes.errors])
		enabled = false; resolver = null
		return false
	for solution in resolver.catalog.solution_list():
		if adapters.adapter_for(solution) != null and not adapters.supported(solution):
			push_error("INNOVATION_START_INVALID: invalid adapter properties: " + solution.id)
			enabled = false; resolver = null
			return false
	reason = "Observing the room"
	return true

func request_surface(region: String) -> Dictionary:
	if not sim.coordinator.surface_navigation.regions.has(region) or region == "FLOOR":
		return {"accepted":false, "reason":"Unknown elevated surface"}
	manual_targets[region] = true
	_next = 0.0
	return {"accepted":true, "state":"PROBLEM_REPORTED", "message":"Vertical access reported; the colony will evaluate its own research and solution."}

func tick() -> void:
	if not enabled: return
	adapters.advance(sim,projects,sim.STEP)
	if sim.seconds + 0.00001 < _next: return
	_next = sim.seconds + 5.0
	var navigation: Node = sim.coordinator.surface_navigation
	var observations: Array[Dictionary] = Detector.observe(sim)
	for region in manual_targets:
		if navigation.regions.has(region) and not navigation.has_connection("FLOOR", region):
			var found := false
			for observation in observations:
				if observation.type == "VERTICAL_ACCESS" and observation.source_id == region: observation["strength"] = 1.0; found = true
			if not found: observations.append({"type":"VERTICAL_ACCESS","source_id":region,"severity":1.0,"strength":1.0,"context":{"region":region}})
	resolver.problem_registry.observe_batch(observations, sim.seconds)
	for problem in resolver.problem_registry.active_problems():
		sim.journal.record(sim.seconds, "problem_detected", "Problem recognized: " + problem.type, problem, sim.coordinator.depot_station, "problem:"+problem.key, preload("res://scripts/event_fact_context.gd").society(sim, problem))
	if sim.living_population() == 0:
		if not active.is_empty(): _cancel_project("No surviving builders")
		_cancel_research("No surviving researchers")
		return
	if not active.is_empty():
		var state: String = adapters.adapter_for(active.solution).status(sim,active)
		if state != "VALID": _cancel_project("Deployment target invalid or already solved")
		elif not active.problem_keys.any(func(key: Variant) -> bool: return resolver.problem_registry.active.has(key)): _cancel_project("Project problem disappeared")
		else: return
	if not sim.has_capability("workshop"):
		reason = "Research needs an earned workshop"
		return
	var problems: Array[Dictionary] = resolver.problem_registry.active_problems()
	if problems.is_empty():
		_cancel_research("No unresolved access problem")
		reason = "Known access problems solved"
		return
	if not research.is_empty(): return
	var candidates: Array[Dictionary] = resolver.solution_candidates(problems, adapters.supported)
	# Rank globally first; physical feasibility can exclude a candidate, but
	# must never let problem/dictionary order choose the project.
	for candidate in candidates:
		for problem in candidate.problems:
			var target_candidate: Dictionary = candidate.duplicate(true); target_candidate.problem = problem
			var plan: Dictionary = adapters.prepare(sim,target_candidate)
			if not _plan_available(plan): continue
			_start_project(candidate,plan)
			return
	var choice: Dictionary = resolver.preferred_research(problems, adapters.supported)
	if choice.is_empty():
		reason = "No reachable research path"
		return
	var target := _research_target()
	if not target.is_finite():
		reason = "Workshop research station is unavailable"
		return
	research = {"id":String(choice.technology.id), "name":String(choice.technology.get("display_name", choice.technology.id)), "target":target, "required_work":float(choice.technology.get("research_work", 100.0)), "work":0.0, "work_by_citizen":{}, "started":sim.seconds, "completed":-1.0, "state":"RESEARCHING"}
	reason = "Researching " + research.name
	sim.journal.record(sim.seconds, "research_started", research.name + " research started", research, target, "research:"+research.id, preload("res://scripts/event_fact_context.gd").society(sim, research))

func _research_target() -> Vector3:
	for project in sim.development.projects:
		if project.kind == "workshop" and project.state == "COMPLETE": return project.target
	if not sim.coordinator.workshop_stations.is_empty(): return sim.coordinator.workshop_stations[0]
	return Vector3(INF, INF, INF)

func busy() -> bool:
	return enabled and (not research.is_empty() or not active.is_empty())

func _pending(resource: String) -> float:
	var amount := 0.0
	if active.is_empty(): return amount
	for ticket in sim.economy.tickets.values():
		if ticket.owner == active.id and ticket.resource == resource and ticket.state in ["reserved", "in_transit"]: amount += float(ticket.amount)
	return amount

func _workers(kind: String) -> int:
	var count := 0
	for task in sim.coordinator.tasks:
		if task.task_type == kind and task.state in ["reserved", "active"]: count += 1
	return count

func _recipe(resource: String) -> Dictionary:
	return recipes.for_resource(resource,resolver.catalog.production_recipes,sim)

func _producing(resource: String) -> float:
	var amount := 0.0
	for task in sim.coordinator.tasks:
		if task.task_type == "INNOVATION_FABRICATE" and task.state in ["active","reserved"] and recipes.recipes.has(task.get("recipe_id","")):
			var recipe: Dictionary = recipes.recipes[task.recipe_id]
			if recipe.output == resource: amount += float(recipe.output_amount)
	return amount

func shortage() -> Dictionary:
	var demand := {}
	if not enabled or active.is_empty(): return demand
	for resource in active.required: demand[resource] = maxf(0,float(active.required[resource])-float(active.delivered[resource])-_pending(resource))
	for resource in active.required:
		var recipe := _recipe(resource)
		if recipe.is_empty(): continue
		var need := maxf(0,float(demand.get(resource,0))-float(sim.economy.available.get(resource,0))-_producing(resource))
		demand.erase(resource)
		if need > 0: demand[recipe.input] = float(demand.get(recipe.input,0)) + ceilf(need/float(recipe.output_amount))*float(recipe.input_amount)
	for resource in demand: demand[resource] = maxf(0,float(demand[resource])-float(sim.economy.available.get(resource,0)))
	return demand

func options(citizen: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not enabled or sim.should_interrupt(citizen): return result
	if not research.is_empty() and _workers("INNOVATION_RESEARCH") < 2:
		result.append({"task_type":"INNOVATION_RESEARCH", "technology_id":research.id, "source":research.target, "target":research.target, "urgency":0.7})
	if active.is_empty(): return result
	for resource in active.required:
		var remaining := float(active.required[resource]) - float(active.delivered[resource]) - _pending(resource)
		var amount := minf(1.0, minf(remaining, float(sim.economy.available.get(resource, 0))))
		if amount > 0.00001:
			result.append({"task_type":"CONSTRUCTION_DELIVERY", "innovation_project":true, "project_id":active.id, "source":sim.coordinator.depot_station, "target":active.target, "resource":resource, "amount":amount, "picked_up":false, "urgency":0.8})
	for resource in active.required:
		var needed := float(active.required[resource])-float(active.delivered[resource])-_pending(resource)-float(sim.economy.available.get(resource,0))-_producing(resource)
		var recipe := _recipe(resource)
		if needed > 0.00001 and not recipe.is_empty() and _workers("INNOVATION_FABRICATE") == 0 and float(sim.economy.available.get(recipe.input,0)) >= float(recipe.input_amount):
			result.append({"task_type":"INNOVATION_FABRICATE","project_id":active.id,"recipe_id":recipe.id,"source":sim.coordinator.depot_station,"target":sim.coordinator.depot_station,"resource":recipe.input,"amount":recipe.input_amount,"fabrication_owner":"%s:fabrication:%d" % [sim.instance_id,citizen.citizen_id],"urgency":0.8})
	if active.state in ["SUPPLIED", "BUILDING"] and _workers("CONSTRUCTION_BUILD") < 2:
		result.append({"task_type":"CONSTRUCTION_BUILD", "innovation_project":true, "project_id":active.id, "stage":0, "source":active.target, "target":active.target, "urgency":0.8})
	return result

func _plan_available(plan: Dictionary) -> bool:
	if not plan.get("valid",false): return false
	var owner: String = sim.world_simulation.innovation_claims.get(plan.claim_key, "")
	return (owner.is_empty() or owner == sim.instance_id) and not sim.coordinator.navigation.path_between(sim.coordinator.depot_station,plan.target).is_empty()

func _start_project(candidate: Dictionary, plan: Dictionary) -> void:
	var solution: Dictionary = candidate.solution
	var requirements: Dictionary = Vocabulary.requirements(solution.construction)
	var delivered := {}
	for resource in requirements: delivered[resource] = 0.0
	var keys: Array = []
	for problem in candidate.problems: keys.append(problem.get("key",problem.type+"::"+String(problem.get("source_id",""))))
	active = {"id":"%s_innovation_%03d" % [sim.instance_id, projects.size()+1],"solution":solution.duplicate(true),"deployment":plan,"problem_keys":keys,"claim_key":plan.claim_key,"region":plan.get("region",""),"site":plan.position,"target":plan.target,"path":plan.get("path",[]),"required":requirements,"delivered":delivered,"required_work":float(solution.construction.work),"work":0.0,"work_by_citizen":{},"delivery_distance":0.0,"state":"WAITING_FOR_MATERIALS","started":sim.seconds,"completed":-1.0}
	projects.append(active)
	sim.world_simulation.innovation_claims[plan.claim_key] = sim.instance_id
	var root := Node3D.new()
	root.name = active.id
	root.set_meta("civilization_id", sim.instance_id)
	root.set_meta("solution_id", solution.id)
	sim.scene.add_child(root)
	_visuals[active.id] = root
	reason = "Building " + String(solution.get("display_name", solution.id))
	sim.journal.record(sim.seconds, "solution_started", reason, {"solution_id":solution.id, "region":active.region}, active.site, active.id, preload("res://scripts/event_fact_context.gd").society(sim, active))
	_update_supplied()

func pickup(task: Dictionary) -> bool:
	if active.is_empty() or task.project_id != active.id or not sim.economy.tickets.has(task.ticket): return false
	var worker: Node3D = _task_worker(task)
	if worker == null or worker.global_position.distance_to(task.source) > 1.6: return false
	var ticket: Dictionary = sim.economy.tickets[task.ticket]
	return ticket.owner == active.id and ticket.instance_id == sim.instance_id and ticket.resource == task.resource and ticket.amount == task.amount and sim.economy.pickup(task.ticket,active.id)

func deliver(task: Dictionary, citizen: Node3D) -> bool:
	if active.is_empty() or task.project_id != active.id or citizen.global_position.distance_to(active.target) > 1.6 or not sim.economy.tickets.has(task.ticket): return false
	if _task_worker(task) != citizen or not citizen.carrying: return false
	var ticket: Dictionary = sim.economy.tickets[task.ticket]
	if ticket.owner != active.id or ticket.instance_id != sim.instance_id or ticket.resource != task.resource or ticket.amount != task.amount: return false
	if float(active.delivered[task.resource]) + float(task.amount) > float(active.required[task.resource]) + 0.00001: return false
	if not sim.economy.deliver(task.ticket,active.id): return false
	active.delivered[task.resource] += float(task.amount)
	active.delivery_distance += citizen.travelled_distance - float(task.pickup_travelled_distance)
	_update_supplied()
	return true

func _update_supplied() -> void:
	for resource in active.required:
		if float(active.delivered[resource]) + 0.00001 < float(active.required[resource]): return
	active.state = "SUPPLIED"

func _task_worker(task: Dictionary) -> Node3D:
	var worker: Node3D = sim.citizen_for(int(task.get("citizen_id", -1)))
	if worker == null or worker.task_id != task.get("id", -1) or worker.task_type != task.get("task_type", "") or worker.civilization_id != sim.instance_id or worker.life_state != "ALIVE" or not worker.combat_duty.is_empty(): return null
	var stored: Dictionary = sim.coordinator._find_task(int(task.get("id", -1)))
	if stored.is_empty() or stored != task or stored.state != "active" or stored.instance_id != sim.instance_id: return null
	return worker

func _valid_work(task: Dictionary, citizen: Node3D, effort: float) -> bool:
	if not enabled or not is_finite(effort) or effort <= 0 or effort > sim.STEP + 0.00001: return false
	if _task_worker(task) != citizen or citizen.state != "WORK" or not citizen.production_work_active or sim.world_simulation.tick <= 0: return false
	if citizen.global_position.distance_to(task.target) > 1.6 or _last_work_tick.get(citizen.citizen_id, -1) == sim.world_simulation.tick: return false
	_last_work_tick[citizen.citizen_id] = sim.world_simulation.tick
	return true

func work(task: Dictionary, citizen: Node3D, effort: float) -> bool:
	if not _valid_work(task, citizen, effort): return false
	if task.task_type == "INNOVATION_RESEARCH":
		if research.is_empty() or task.technology_id != research.id: return true
		var applied := minf(effort, float(research.required_work) - float(research.work))
		research.work += applied
		research.work_by_citizen[citizen.citizen_id] = float(research.work_by_citizen.get(citizen.citizen_id, 0)) + applied
		task.work_seconds = float(task.get("work_seconds", 0)) + applied
		if float(research.work) + 0.00001 < float(research.required_work): return false
		var learned: Dictionary = resolver.learn_technology(research.id)
		if not learned.ok: return false
		research.completed = sim.seconds
		research.state = "COMPLETE"
		research_history.append(research.duplicate(true))
		sim.journal.record(sim.seconds, "technology_complete", research.name + " completed", research, research.target, "technology:"+research.id, preload("res://scripts/event_fact_context.gd").society(sim, research))
		research = {}
		_cancel_peers("INNOVATION_RESEARCH", task.id)
		_next = 0.0
		return true
	if task.task_type == "INNOVATION_FABRICATE":
		if not resolver.catalog.production_recipes.has(task.get("recipe_id","")): return false
		return recipes.perform(sim,task,citizen,effort)
	return false

func build(task: Dictionary, citizen: Node3D, effort: float) -> bool:
	if active.is_empty() or task.project_id != active.id: return true
	if active.state not in ["SUPPLIED", "BUILDING"] or not _valid_work(task, citizen, effort): return false
	active.state = "BUILDING"
	var applied := minf(effort, float(active.required_work) - float(active.work))
	active.work += applied
	active.work_by_citizen[citizen.citizen_id] = float(active.work_by_citizen.get(citizen.citizen_id, 0)) + applied
	var fraction := float(active.work) / float(active.required_work)
	var adapter: RefCounted = adapters.adapter_for(active.solution)
	adapter.render(_visuals[active.id],active,fraction,Color(String(sim.definition.palette.primary)))
	if fraction + 0.00001 < 1.0: return false
	if not adapter.finish(sim,active): return false
	# Completion tolerance belongs to labor accounting; render the exact final
	# state so floating-point accumulation cannot leave the last segment/canopy out.
	adapter.render(_visuals[active.id],active,1.0,Color(String(sim.definition.palette.primary)))
	for ticket_id in sim.economy.tickets.keys():
		if sim.economy.tickets[ticket_id].owner == active.id: sim.economy.consume(ticket_id, active.id, true)
	active.state = "COMPLETE"
	active.completed = sim.seconds
	sim.world_simulation.innovation_claims.erase(active.claim_key)
	sim.journal.record(sim.seconds, "solution_complete", String(active.solution.get("display_name", active.solution.id)) + " deployed", {"solution_id":active.solution.id, "region":active.region}, active.site, active.id+":complete", preload("res://scripts/event_fact_context.gd").society(sim, active))
	active = {}
	_cancel_peers("CONSTRUCTION_BUILD", task.id, true)
	_next = 0.0
	return true

func _cancel_peers(kind: String, keep_id: int = -1, innovation_only: bool = false) -> void:
	for task in sim.coordinator.tasks.duplicate():
		if task.task_type != kind or int(task.id) == keep_id or task.state not in ["active", "reserved"]: continue
		if innovation_only and not task.get("innovation_project", false): continue
		if sim.coordinator.cancel_task(task.id, "Innovation job no longer active"):
			var worker: Node3D = sim.citizen_for(task.citizen_id)
			if worker != null: worker.cancel_task_and_resume(task.id)

func _cancel_research(why: String) -> void:
	if research.is_empty(): return
	research.state = "CANCELLED"
	research_history.append(research.duplicate(true))
	research = {}
	reason = why
	_cancel_peers("INNOVATION_RESEARCH")

func _cancel_project(why: String) -> void:
	var id: String = active.id
	var claim: String = active.claim_key
	var target: Vector3 = active.target
	active.state = "CANCELLED"
	active = {}
	_cancel_peers("CONSTRUCTION_BUILD", -1, true)
	for task in sim.coordinator.tasks.duplicate():
		if task.get("project_id", "") == id and task.state in ["active", "reserved"]:
			sim.coordinator.cancel_task(task.id, why)
			var worker: Node3D = sim.citizen_for(task.citizen_id)
			if worker != null: worker.cancel_task_and_resume(task.id)
	for ticket_id in sim.economy.tickets.keys():
		if sim.economy.tickets[ticket_id].owner != id: continue
		var recovered: Dictionary = sim.economy.recover_delivered(ticket_id,id)
		if not recovered.is_empty(): sim.show_bundle(sim.resources.create_bundle(recovered.resource, recovered.amount, target, id))
		else: sim.economy.release(ticket_id,id)
	if sim.world_simulation.innovation_claims.get(claim, "") == sim.instance_id: sim.world_simulation.innovation_claims.erase(claim)
	if _visuals.has(id): _visuals[id].queue_free(); _visuals.erase(id)
	reason = why

func status() -> Dictionary:
	return {"enabled":enabled, "reason":reason, "research":research.duplicate(true), "project":active.duplicate(true), "known_technologies":resolver.known_technologies.keys() if resolver != null else [], "projects":projects.size()}
