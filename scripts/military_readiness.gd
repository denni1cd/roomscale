extends RefCounted
const Doctrine := preload("res://scripts/military_doctrine.gd")
const Catalog := preload("res://scripts/military_catalog.gd")
var sim: Node
var policy: Dictionary = {}
var objective := Vector3.ZERO
var state := "PEACE"
var planned: Array[String] = []
var missing: Array[String] = []
var members: Array = []
var blocked := "no hostile authorization"
var authorized := 0

func configure(runtime: Node) -> void: sim = runtime

func profile() -> Dictionary:
	var result := {}
	for role in Catalog.Roles.ORDER:
		if Catalog.permitted(sim,role): result[role] = sim.definition.combat.roles[role]
	return result

func authorize(own: Dictionary, at: Vector3) -> void:
	policy = own.duplicate(true)
	objective = at
	if state in ["PEACE","COMPLETE"]:
		state = "PREPARING"
		sim.armory.record("READINESS_TARGET",{"id":sim.instance_id,"policy":policy})
	refresh()

func refresh() -> void:
	if policy.is_empty(): return
	authorized = Doctrine.authorized_size(sim.living_population(),policy)
	planned = Doctrine.compose(profile(),authorized)
	missing.clear()
	var counts: Dictionary = sim.armory.stock(true)
	for kit in sim.armory.kits.values():
		if kit.state in ["RESERVED","ISSUED"]: counts[kit.role] += 1
	for role in planned:
		if counts.get(role,0)>0: counts[role] -= 1
		else: missing.append(role)
	if state == "PREPARING": blocked = "awaiting equipment" if not missing.is_empty() else "awaiting eligible citizens"

func govern() -> void:
	if state != "PREPARING" or policy.is_empty(): return
	refresh()
	if not missing.is_empty():
		if not sim.armory.order(missing[0]):
			blocked = sim.armory.blocked
			sim.journal.record(sim.seconds, "KIT_BLOCKED", blocked, {"role":missing[0]}, sim.coordinator.depot_station, "kit_blocked", preload("res://scripts/event_fact_context.gd").society(sim, {"role":missing[0]}))

func shortage() -> Dictionary:
	var result := {"wood":0.0,"metal":0.0}
	if state != "PREPARING" or missing.is_empty(): return result
	var bill: Dictionary = Catalog.EQUIPMENT[missing[0]+"_kit"].cost.duplicate()
	if Catalog.has(sim,"JURY_RIG_EQUIPMENT") and float(sim.economy.available.get("metal",0)) < float(bill.metal): bill.metal -= 1; bill.wood += 2
	for resource in result: result[resource] = maxf(0,float(bill.get(resource,0))-float(sim.economy.available.get(resource,0)))
	return result

func muster() -> void:
	if state != "PREPARING": return
	var roles := Doctrine.compose(profile(),authorized,sim.armory.stock())
	if roles.size() < int(policy.get("min_force",2)): blocked = "equipment below war-policy minimum"; return
	var candidates: Array = sim.citizens.filter(func(c: Node3D) -> bool: return c.eligible_for_combat(objective) and not c.navigation.path_between(c.global_position,sim.coordinator.depot_station).is_empty())
	candidates.sort_custom(func(a: Node3D,b: Node3D) -> bool:
		var da := a.global_position.distance_squared_to(objective)
		var db := b.global_position.distance_squared_to(objective)
		return da < db if da != db else a.citizen_id < b.citizen_id)
	if candidates.size() < roles.size():
		roles = roles.slice(0,candidates.size())
		if roles.size() < int(policy.get("min_force",2)): blocked = "eligible citizens below minimum"; return
	members.clear()
	for index in roles.size():
		var citizen: Node3D = candidates[index]
		var kit: String = sim.armory.reserve(roles[index],citizen.citizen_id)
		members.append({"citizen":citizen,"kit":kit,"role":roles[index]})
	for member in members:
		member.citizen.pending_kit = member.kit
		member.citizen.assign_combat_duty("MUSTER",sim.coordinator.depot_station)
		sim.armory.record("CITIZEN_MUSTERING",{"id":member.citizen.citizen_id,"kit":member.kit,"role":member.role})
	state = "MUSTERING"; blocked = "physical muster in progress"

func update() -> void:
	if state == "PREPARING": muster()
	if state == "MUSTERING":
		for member in members:
			var citizen: Node3D = member.citizen
			if citizen.combat_kit.is_empty() and citizen.combat_arrived:
				if sim.armory.issue(member.kit,citizen): citizen.assign_combat_duty("EQUIPPED",sim.coordinator.depot_station)
		if members.all(func(m: Dictionary) -> bool: return m.citizen.combat_kit == m.kit and m.citizen.combat_arrived):
			state = "READY"; blocked = "waiting for other authorized forces"
			sim.armory.record("MOBILIZATION_READY",{"id":sim.instance_id,"size":members.size()})
	elif state == "CANCELLING":
		for member in members:
			if member.citizen.combat_arrived and not member.citizen.combat_duty.is_empty(): member.citizen.end_combat_duty()
		if members.all(func(m: Dictionary) -> bool: return m.citizen.combat_duty.is_empty()): members.clear(); state = "PEACE"
	elif state == "DEPLOYED" and members.all(func(m: Dictionary) -> bool: return m.citizen.life_state == "DEAD" or m.citizen.combat_duty.is_empty()):
		state = "COMPLETE"; blocked = ""; policy.clear(); missing.clear()

func cancel() -> void:
	if state in ["PEACE","COMPLETE","DEPLOYED"]: return
	policy.clear(); planned.clear(); missing.clear()
	for member in members:
		sim.armory.release_reservation(member.kit)
		member.citizen.assign_combat_duty("RETREAT",sim.coordinator.depot_station)
	state = "CANCELLING" if not members.is_empty() else "PEACE"
	blocked = "hostile authorization ended"

func snapshot() -> Dictionary:
	return {"state":state,"authorized":authorized,"minimum":policy.get("min_force",0),"planned":planned.duplicate(),"missing":missing.duplicate(),"stock":sim.armory.stock(),"projects":sim.armory.active_count(),"blocked":blocked,"capabilities":sim.definition.combat.capabilities,"members":members.map(func(m: Dictionary) -> Dictionary: return {"citizen_id":m.citizen.citizen_id,"kit":m.kit,"role":m.role})}
