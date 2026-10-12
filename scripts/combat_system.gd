extends RefCounted
## Shared battle authority. Deterministic citizen ID initiative, distance/ID targets.
const ATTACK_DAMAGE := 10.0
const ATTACK_INTERVAL := 1.0
const ATTACK_RANGE := 6.0
const DEFAULT_RETREAT_THRESHOLD := 0.70
var world: Node
var site_id := ""
var forces: Dictionary = {}
var initial_sizes: Dictionary = {}
var morale: Dictionary = {}
var casualties: Dictionary = {}
var next_attack: Dictionary = {}
var phase := "DORMANT"
var winner := ""
var retreating_side := ""
var retreated_sides: Dictionary = {}
var attacks := 0
var retreat_tick := -1
var battle_start_tick := -1
var site_capture_tick := -1
var stand_down_tick := -1
var stand_down_reason := ""
var returned: Dictionary = {}
var cooldown_until: Dictionary = {}
var arrivals: Dictionary = {}
var policy: Dictionary = {}
var conflict_intensity := "LIMITED_WAR"
var conflict_cause := ""
var conflict_objective := "SECURE_CONTESTED_ASSET"
var retreat_threshold := DEFAULT_RETREAT_THRESHOLD
var allow_retreat := true

func start(controller: Node, objective: String, war_policy: Dictionary = {}) -> bool:
	if phase != "DORMANT" or not controller.territory.sites.has(objective): return false
	var requested: Variant = war_policy.get("participants", controller.territory.sites[objective].contesting_civilizations)
	if not requested is Array or not requested.all(func(id: Variant) -> bool: return id is String): return false
	var ids: Array = requested.duplicate()
	ids.sort()
	if ids.size() < 2: return false
	for id in ids:
		if not id is String or not controller.territory.sites[objective].contesting_civilizations.has(id): return false
		if not ids.any(func(rival: Variant) -> bool: return rival is String and rival != id and controller.territory.relations.get(controller.territory.relation_key(id, rival), "UNKNOWN") == "HOSTILE"): return false
	for field in ["force_fraction", "min_force", "max_force", "retreat_threshold"]:
		if war_policy.has(field) and not preload("res://scripts/innovation_validation.gd").number(war_policy[field]): return false
	for field in ["min_force", "max_force"]:
		if war_policy.has(field) and (war_policy[field] < 1 or war_policy[field] > 150 or war_policy[field] != floorf(war_policy[field])): return false
	if war_policy.has("allow_retreat") and not war_policy.allow_retreat is bool: return false
	var participants: Array = []
	for runtime in controller.runtimes:
		if ids.has(runtime.instance_id): participants.append(runtime)
	if participants.size() != ids.size(): return false
	for id in ids:
		if controller.seconds < float(cooldown_until.get(id, -1)): return false
	var staged_forces := {}
	var force_fraction := clampf(float(war_policy.get("force_fraction", 0.25)), 0.0, 1.0)
	var min_force := maxi(1, int(war_policy.get("min_force", 2)))
	var max_force := maxi(min_force, int(war_policy.get("max_force", 6)))
	var target: Vector3 = controller.territory.sites[objective].position
	for runtime in participants:
		var selected: Array = []
		var count := mini(max_force, maxi(min_force, ceili(runtime.living_population() * force_fraction)))
		for citizen in runtime.citizens:
			if citizen.eligible_for_combat(target): selected.append(citizen)
		selected.sort_custom(func(a: Node3D, b: Node3D) -> bool:
			var da := a.global_position.distance_squared_to(target)
			var db := b.global_position.distance_squared_to(target)
			return da < db if da != db else a.citizen_id < b.citizen_id)
		if selected.size() < count: return false
		staged_forces[runtime.instance_id] = selected.slice(0, count)
	# Validate every station before any citizen/task mutation. Keep the original
	# 4-inch navigation-grid spacing, expanding into additional depth rows for
	# larger wars instead of shrinking the proven POC5 formation.
	var planned_targets := {}
	var occupied: Array[Vector3] = []
	for runtime in participants:
		var force_size: int = staged_forces[runtime.instance_id].size()
		for index in range(force_size):
			var citizen: Node3D = staged_forces[runtime.instance_id][index]
			var sign_x := -1.0 if runtime == participants[0] else 1.0
			var depth := floori(index / 5.0)
			var slot_in_row := index % 5
			var row_count := mini(5, force_size - depth * 5)
			var lateral := (float(slot_in_row) - float(row_count - 1) / 2.0) * 4.0
			var desired := target + Vector3(sign_x * (2.0 + depth * 4.0), 0, lateral)
			if participants.size() > 2:
				var angle := TAU * float(participants.find(runtime)) / participants.size()
				var radial := Vector3(cos(angle), 0, sin(angle))
				desired = target + radial * (3.0 + floori(index / 2.0) * 4.0) + radial.rotated(Vector3.UP, PI / 2) * (-2.0 if index % 2 == 0 else 2.0)
			var at: Vector3 = runtime.coordinator.navigation.nearest_walkable_position(desired)
			if participants.size() > 2 and occupied.any(func(point: Vector3) -> bool: return point.distance_to(at) < 1.0):
				var found := false
				for offset in [Vector3(4,0,0),Vector3(-4,0,0),Vector3(0,0,4),Vector3(0,0,-4)]:
					var candidate: Vector3 = runtime.coordinator.navigation.nearest_walkable_position(desired + offset)
					if not occupied.any(func(point: Vector3) -> bool: return point.distance_to(candidate) < 1.0) and not runtime.coordinator.navigation.is_obstacle_position(candidate) and not runtime.coordinator.navigation.path_between(citizen.global_position,candidate).is_empty():
						at = candidate
						found = true
						break
				if not found: return false
			if runtime.coordinator.navigation.is_obstacle_position(at) or runtime.coordinator.navigation.path_between(citizen.global_position,at).is_empty() or occupied.any(func(point: Vector3) -> bool: return point.distance_to(at) < 1.0): return false
			occupied.append(at)
			planned_targets[citizen.citizen_id] = at
	world = controller
	site_id = objective
	_reset_battle_state()
	policy = war_policy.duplicate(true)
	conflict_intensity = String(policy.get("intensity_name", "LIMITED_WAR"))
	conflict_cause = String(policy.get("cause", ""))
	conflict_objective = String(policy.get("objective", "SECURE_CONTESTED_ASSET"))
	retreat_threshold = float(policy.get("retreat_threshold", DEFAULT_RETREAT_THRESHOLD))
	allow_retreat = bool(policy.get("allow_retreat", true))
	forces = staged_forces
	# No partial commitment if either side cannot supply a legal force.
	for runtime in participants:
		var id: String = runtime.instance_id
		initial_sizes[id] = forces[id].size()
		casualties[id] = 0
		morale[id] = 1.0
		arrivals[id] = false
		returned[id] = 0
		for index in range(forces[id].size()):
			var citizen: Node3D = forces[id][index]
			# Distinct legal station points keep the tiny force readable.
			if not citizen.assign_combat_duty("MARCH", planned_targets[citizen.citizen_id]): return false
			next_attack[citizen.citizen_id] = 0.0
		world.journal.record(world.seconds, "FORCE_COMMITTED", id + " committed citizens", {"instance_id":id,"size":initial_sizes[id],"intensity":conflict_intensity,"cause":conflict_cause,"objective":conflict_objective}, target, id + ":force")
	phase = "MARCH"
	battle_start_tick = world.tick
	return true

func _reset_battle_state() -> void:
	forces.clear()
	initial_sizes.clear()
	morale.clear()
	casualties.clear()
	next_attack.clear()
	arrivals.clear()
	returned.clear()
	winner = ""
	retreating_side = ""
	retreated_sides.clear()
	attacks = 0
	retreat_tick = -1
	battle_start_tick = -1
	site_capture_tick = -1
	stand_down_tick = -1
	stand_down_reason = ""

func living(id: String) -> Array:
	if not forces.has(id): return []
	return forces[id].filter(func(c: Node3D) -> bool: return c.life_state == "ALIVE")

func update() -> void:
	if phase == "DORMANT": return
	for id in retreated_sides:
		_return_arrivals(String(id))
	var target: Vector3 = world.territory.sites[site_id].position
	for id in forces:
		if not arrivals[id] and living(id).all(func(c: Node3D) -> bool: return c.combat_arrived):
			arrivals[id] = true
			world.journal.record(world.seconds, "FORCE_ARRIVED", id + " physically arrived", {"instance_id":id}, target, id + ":arrived")
	if phase == "MARCH":
		if not arrivals.values().all(func(value: bool) -> bool: return value): return
		phase = "FIGHT"
	if phase == "FIGHT":
		var has_rivals := false
		for a in forces:
			for b in forces:
				if _hostile(String(a), String(b)) and not living(a).is_empty() and not living(b).is_empty(): has_rivals = true
		if not has_rivals:
			stand_down("remaining societies are not hostile")
			return
		var ordered: Array = []
		for id in forces:
			if not retreated_sides.has(id): ordered.append_array(living(id))
		ordered.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.citizen_id < b.citizen_id)
		for citizen in ordered:
			if retreated_sides.has(citizen.civilization_id) or citizen.life_state != "ALIVE" or not citizen.combat_arrived or world.seconds < float(next_attack[citizen.citizen_id]): continue
			var opponents: Array = []
			for id in forces:
				if _hostile(citizen.civilization_id, String(id)): opponents.append_array(living(id).filter(func(c: Node3D) -> bool: return c.combat_arrived and c.global_position.distance_to(citizen.global_position) <= ATTACK_RANGE))
			if opponents.is_empty():
				# Larger formations close distance through ordinary floor navigation.
				if forces.size() > 2:
					var distant: Array = []
					for id in forces:
						if _hostile(citizen.civilization_id, String(id)): distant.append_array(living(id))
					distant.sort_custom(func(a: Node3D, b: Node3D) -> bool:
						var da := a.global_position.distance_squared_to(citizen.global_position)
						var db := b.global_position.distance_squared_to(citizen.global_position)
						return da < db if da != db else a.citizen_id < b.citizen_id)
					if not distant.is_empty():
						var at: Vector3 = citizen.navigation.nearest_walkable_position(distant[0].global_position)
						if not citizen.navigation.path_between(citizen.global_position, at).is_empty(): citizen.assign_combat_duty("MARCH", at)
				continue
			opponents.sort_custom(func(a: Node3D, b: Node3D) -> bool:
				var da := a.global_position.distance_squared_to(citizen.global_position)
				var db := b.global_position.distance_squared_to(citizen.global_position)
				return da < db if da != db else a.citizen_id < b.citizen_id)
			var victim: Node3D = opponents[0]
			phase = "FIGHT"
			next_attack[citizen.citizen_id] = world.seconds + ATTACK_INTERVAL
			attacks += 1
			world.present_attack(citizen, victim)
			if victim.suffer_combat_damage(ATTACK_DAMAGE):
				casualties[victim.civilization_id] += 1
				world.journal.record(world.seconds, "COMBAT_CASUALTY", "Citizen %d fell" % victim.citizen_id, {"citizen_id":victim.citizen_id,"instance_id":victim.civilization_id}, victim.global_position, "casualty:%d" % victim.citizen_id)
			if evaluate_morale(): return
	elif phase in ["RETREAT", "SECURE", "COMPLETE", "STAND_DOWN"]:
		for id in forces:
			for citizen in living(id):
				if citizen.combat_duty == "RETREAT" and citizen.combat_arrived:
					citizen.end_combat_duty()
					returned[id] = int(returned.get(id, 0)) + 1
		if phase == "STAND_DOWN":
			if forces.keys().all(func(id: Variant) -> bool: return living(String(id)).all(func(c: Node3D) -> bool: return c.combat_duty.is_empty())):
				phase = "DORMANT"
			return
		if phase == "RETREAT" and _rivals_withdrawn(target): phase = "SECURE"
		if phase == "SECURE" and _rivals_withdrawn(target) and living(winner).any(func(c: Node3D) -> bool: return c.combat_arrived and c.global_position.distance_to(target) <= ATTACK_RANGE):
			if world.territory.hold(site_id, winner, world.seconds, world.STEP):
				site_capture_tick = world.tick
				phase = "COMPLETE"
				for citizen in living(winner): citizen.assign_combat_duty("RETREAT", world.runtime_for(winner).coordinator.housing_station)
		elif phase == "SECURE":
			world.territory.sites[site_id].hold_progress = 0.0

func retreat(id: String) -> void:
	if retreated_sides.has(id): return
	retreat_tick = world.tick
	retreating_side = id
	retreated_sides[id] = world.tick
	var remaining: Array = forces.keys().filter(func(side: Variant) -> bool: return not retreated_sides.has(side) and not living(String(side)).is_empty())
	if remaining.size() == 1:
		winner = String(remaining[0])
		phase = "RETREAT"
		var at: Vector3 = world.territory.sites[site_id].position
		if not living(winner).any(func(c: Node3D) -> bool: return c.global_position.distance_to(at) <= ATTACK_RANGE):
			for citizen in living(winner): citizen.assign_combat_duty("MARCH", at)
	elif remaining.is_empty():
		winner = ""
		phase = "STAND_DOWN"
	else:
		winner = ""
		phase = "FIGHT"
	world.territory.sites[site_id].hold_progress = 0.0
	cooldown_until[id] = world.seconds + 600.0
	for citizen in living(id): citizen.assign_combat_duty("RETREAT", world.runtime_for(id).coordinator.housing_station)
	world.journal.record(world.seconds, "RETREAT", id + " morale broke; returning to rally", {"instance_id":id,"morale":morale.duplicate(),"intensity":conflict_intensity}, world.territory.sites[site_id].position, id + ":retreat")

func stand_down(reason: String) -> void:
	if phase not in ["MARCH", "FIGHT"]: return
	stand_down_tick = world.tick
	stand_down_reason = reason
	winner = ""
	retreating_side = ""
	phase = "STAND_DOWN"
	for id in forces:
		for citizen in living(id): citizen.assign_combat_duty("RETREAT", world.runtime_for(String(id)).coordinator.housing_station)
	world.journal.record(world.seconds, "CONFLICT_STOOD_DOWN", "Conflict ended because its cause no longer justified war", {"reason":reason,"intensity":conflict_intensity,"cause":conflict_cause}, world.territory.sites[site_id].position, site_id + ":standdown:%d" % world.tick)

func evaluate_morale() -> bool:
	var losing := ""
	var lowest := retreat_threshold
	for id in forces:
		if retreated_sides.has(id): continue
		var survivors := living(id)
		if survivors.is_empty():
			retreat(String(id))
			return true
		var other := 0
		for rival in forces:
			if _hostile(String(id), String(rival)): other += living(rival).size()
		var average := 0.0
		for survivor in survivors: average += survivor.health / maxf(1, survivors.size())
		var disadvantage := maxf(0, 1.0 - float(survivors.size()) / maxf(1, other))
		morale[id] = 1.0 - float(casualties[id]) / initial_sizes[id] * 0.65 - disadvantage * 0.20 - (1.0 - average / 100.0) * 0.15
		if allow_retreat and morale[id] < lowest:
			lowest = morale[id]
			losing = String(id)
	if not losing.is_empty():
		retreat(losing)
		return true
	return false

func _hostile(a: String, b: String) -> bool:
	return a != b and not retreated_sides.has(a) and not retreated_sides.has(b) and world.territory.relations.get(world.territory.relation_key(a,b), "UNKNOWN") == "HOSTILE"

func _rivals_withdrawn(target: Vector3) -> bool:
	for id in forces:
		if id != winner and not living(id).all(func(c: Node3D) -> bool: return c.global_position.distance_to(target) > ATTACK_RANGE): return false
	# Uncommitted, peaceful claimants also prevent exclusive military capture.
	for id in world.territory.sites[site_id].contesting_civilizations:
		if id == winner or forces.has(id): continue
		var runtime: Node = world.runtime_for(String(id))
		if runtime != null and runtime.living_population() > 0: return false
	return true

func _return_arrivals(id: String) -> void:
	for citizen in living(id):
		if citizen.combat_duty == "RETREAT" and citizen.combat_arrived:
			citizen.end_combat_duty()
			returned[id] = int(returned.get(id, 0)) + 1
