extends RefCounted
const Catalog := preload("res://scripts/military_catalog.gd")
var sim: Node
var kits: Dictionary = {}
var projects: Dictionary = {}
var events: Array = []
var _next_project := 1
var _next_kit := 1
var _last_order := -1
var _last_work: Dictionary = {}
var blocked := ""

func configure(runtime: Node) -> void:
	sim = runtime

func record(kind: String, data: Dictionary) -> void:
	var event := {"tick":sim.world_simulation.tick,"kind":kind,"data":data.duplicate(true)}
	events.append(event)
	var context := preload("res://scripts/event_fact_context.gd").society(sim,data)
	if kind.begins_with("KIT_"):
		context.subject_type = "equipment"
		context.subject_id = str(data.get("id",data.get("project","")))
		context.story_key = "equipment:"+sim.instance_id+":"+str(context.subject_id)
	if kind in ["CITIZEN_MUSTERING","ABILITY_STATE"]:
		context.subject_type = "citizen"
		context.subject_id = str(data.get("id",""))
	sim.journal.record(sim.seconds,kind,kind+": "+JSON.stringify(data),data,sim.coordinator.depot_station,kind+":"+str(data.get("id","readiness")),context)

func active_count() -> int:
	return projects.values().filter(func(p: Dictionary) -> bool: return p.state == "BUILDING").size()

func stock(include_projects: bool = false) -> Dictionary:
	var result := {}
	for role in Catalog.Roles.ORDER: result[role] = 0
	for kit in kits.values():
		if kit.state == "STOCKED": result[kit.role] += 1
	if include_projects:
		for project in projects.values():
			if project.state == "BUILDING": result[project.role] += 1
	return result

func order(role: String) -> bool:
	blocked = ""
	if sim.governor.emergency: blocked = "survival crisis"; return false
	if _last_order == sim.governor.evaluations: blocked = "one order per governor evaluation"; return false
	if active_count() >= 2: blocked = "two active equipment projects"; return false
	if not Catalog.permitted(sim,role): blocked = "missing learned capability"; return false
	var equipment_id: String = Catalog.equipment_id(sim,role)
	var definition: Dictionary = Catalog.EQUIPMENT[equipment_id]
	if not Catalog.validate_equipment(definition).is_empty(): blocked = "invalid equipment definition"; return false
	var cost: Dictionary = definition.cost.duplicate(true)
	var work: float = definition.work
	var variant := "normal"
	# Only metal shortage permits substitution; normal recipe always wins.
	if float(sim.economy.available.get("metal",0)) < float(cost.get("metal",0)) and Catalog.has(sim,"JURY_RIG_EQUIPMENT"):
		cost.metal -= 1
		cost.wood += 2
		work *= 1.25
		variant = "jury_rigged"
	for resource in cost:
		if float(sim.economy.available.get(resource,0)) < float(cost[resource]): blocked = "missing " + resource; return false
	var id := "%s:equipment:%d" % [sim.instance_id,_next_project]
	var tickets: Array = []
	for resource in cost:
		if cost[resource] <= 0: continue
		var ticket: int = sim.economy.reserve(resource,float(cost[resource]),id)
		if ticket < 0:
			for prior in tickets: sim.economy.release(prior,id)
			blocked = "reservation failed"
			return false
		tickets.append(ticket)
	_next_project += 1
	_last_order = sim.governor.evaluations
	projects[id] = {"id":id,"role":role,"equipment_id":equipment_id,"variant":variant,"cost":cost,"required_work":work,"work":0.0,"tickets":tickets,"state":"BUILDING","workers":{},"evaluation":sim.governor.evaluations}
	record("KIT_ORDERED",projects[id])
	return true

func options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for project in projects.values():
		if project.state != "BUILDING": continue
		if sim.coordinator.tasks.any(func(task: Dictionary) -> bool: return task.get("armory_project","") == project.id and task.state in ["reserved","active"]): continue
		result.append({"task_type":"ARMORY_BUILD","armory_project":project.id,"source":sim.coordinator.depot_station,"target":sim.coordinator.depot_station,"urgency":0.9})
	return result

func work(citizen: Node3D, effort: float) -> bool:
	if not is_finite(effort) or effort <= 0 or effort > sim.STEP+0.00001: return false
	if citizen.civilization_id != sim.instance_id or citizen.life_state != "ALIVE" or not citizen.combat_duty.is_empty() or not citizen.production_work_active or citizen.state != "WORK": return false
	var task: Dictionary = sim.coordinator._find_task(citizen.task_id)
	if task.is_empty() or task.state != "active" or task.task_type != "ARMORY_BUILD" or task.citizen_id != citizen.citizen_id or task.instance_id != sim.instance_id: return false
	if citizen.global_position.distance_to(task.target) > 1.6 or sim.world_simulation.tick <= 0 or _last_work.get(citizen.citizen_id,-1) == sim.world_simulation.tick: return false
	if not projects.has(task.armory_project) or projects[task.armory_project].state != "BUILDING": return false
	_last_work[citizen.citizen_id] = sim.world_simulation.tick
	var project: Dictionary = projects[task.armory_project]
	var applied := minf(effort,float(project.required_work)-float(project.work))
	project.work += applied
	project.workers[citizen.citizen_id] = float(project.workers.get(citizen.citizen_id,0))+applied
	if project.work+0.00001 < project.required_work: return false
	for ticket in project.tickets:
		if not sim.economy.tickets.has(ticket) or sim.economy.tickets[ticket].owner != project.id or sim.economy.tickets[ticket].state != "reserved": return false
	for ticket in project.tickets: sim.economy.consume(ticket,project.id,true)
	project.state = "COMPLETE"
	var kit := _create_kit(project)
	record("KIT_COMPLETED",{"id":kit,"project":project.id})
	return true

func _create_kit(project: Dictionary) -> String:
	if project.state != "COMPLETE" or project.has("kit"): return ""
	var equipment_id: String = project.equipment_id
	var variant: String = project.variant
	var id := "%s:kit:%d" % [sim.instance_id,_next_kit]
	_next_kit += 1
	project["kit"] = id
	kits[id] = {"id":id,"equipment_id":equipment_id,"role":Catalog.EQUIPMENT[equipment_id].role,"owner":sim.instance_id,"variant":variant,"state":"STOCKED","citizen_id":-1}
	return id

func reserve(role: String,citizen_id: int) -> String:
	for kit in kits.values():
		if kit.role == role and kit.state == "STOCKED":
			kit.state = "RESERVED"; kit.citizen_id = citizen_id
			record("KIT_RESERVED",kit)
			return kit.id
	return ""

func issue(id: String,citizen: Node3D) -> bool:
	if not kits.has(id) or citizen.civilization_id != sim.instance_id or citizen.life_state != "ALIVE" or citizen.global_position.distance_to(sim.coordinator.depot_station) > 0.1 or not citizen.combat_arrived: return false
	var kit: Dictionary = kits[id]
	if kit.state != "RESERVED" or kit.citizen_id != citizen.citizen_id or not Catalog.permitted(sim,kit.role): return false
	kit.state = "ISSUED"
	citizen.combat_kit = id
	citizen.equip_combat(Catalog.Roles.loadout(sim.definition,kit.role))
	record("KIT_ISSUED",kit)
	return true

func release_reservation(id: String) -> void:
	if kits.has(id) and kits[id].state == "RESERVED":
		kits[id].state = "STOCKED"; kits[id].citizen_id = -1
		record("KIT_RELEASED",kits[id])

func return_kit(citizen: Node3D) -> bool:
	var id: String = citizen.combat_kit
	if not kits.has(id) or kits[id].state != "ISSUED" or kits[id].citizen_id != citizen.citizen_id or citizen.life_state != "ALIVE" or citizen.global_position.distance_to(sim.coordinator.depot_station)>0.1: return false
	kits[id].state = "STOCKED"; kits[id].citizen_id = -1
	record("KIT_RETURNED",kits[id])
	citizen.combat_kit = ""
	return true

func lose(citizen: Node3D) -> void:
	var id: String = citizen.combat_kit
	if not kits.has(id) or kits[id].state != "ISSUED" or kits[id].citizen_id != citizen.citizen_id: return
	kits[id].state = "LOST"
	record("KIT_LOST",kits[id])

func audit() -> Array[String]:
	var errors: Array[String] = []
	var issued := {}
	for kit in kits.values():
		if kit.owner != sim.instance_id or kit.state not in ["STOCKED","RESERVED","ISSUED","LOST"]: errors.append("invalid kit")
		if kit.state == "ISSUED":
			var citizen: Node3D = sim.citizen_for(kit.citizen_id)
			if citizen == null or citizen.life_state != "ALIVE" or citizen.combat_kit != kit.id or issued.has(kit.citizen_id): errors.append("invalid issue mapping")
			issued[kit.citizen_id] = true
	return errors

func snapshot() -> Dictionary:
	return {"kits":kits.duplicate(true),"projects":projects.duplicate(true),"stock":stock(),"blocked":blocked}

