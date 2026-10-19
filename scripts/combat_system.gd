extends RefCounted
## Shared battle authority. Generic loadouts, legal role movement, stable ID initiative.
const Roles := preload("res://scripts/combat_roles.gd")
const SITE_CONTROL_RADIUS := 6.0
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
var eliminated_sides: Dictionary = {}
var attacks := 0
var commitments: Array = []
var attack_digest := ""
var attack_history: Array = []
var next_position: Dictionary = {}
var attack_pairs: Dictionary = {}
var retreat_tick := -1
var battle_start_tick := -1
var site_capture_tick := -1
var stand_down_tick := -1
var stand_down_reason := ""
var returned: Dictionary = {}
var cooldown_until: Dictionary = {}
var arrivals: Dictionary = {}
var policy: Dictionary = {}
var side_policies: Dictionary = {}
var conflict_intensity := "LIMITED_WAR"
var conflict_cause := ""
var conflict_objective := "SECURE_CONTESTED_ASSET"

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
	var staged_policies := {}
	if war_policy.has("side_policies") and not war_policy.side_policies is Dictionary: return false
	for id in ids:
		if war_policy.has("side_policies") and not war_policy.side_policies.has(id): return false
		var own: Variant = war_policy.get("side_policies", {}).get(id, war_policy)
		if not own is Dictionary or not _valid_policy(own): return false
		staged_policies[id] = own.duplicate(true)
	var participants: Array = []
	for runtime in controller.runtimes:
		if ids.has(runtime.instance_id): participants.append(runtime)
	if participants.size() != ids.size(): return false
	participants.sort_custom(func(a: Node, b: Node) -> bool: return a.instance_id < b.instance_id)
	for id in ids:
		if controller.seconds < float(cooldown_until.get(id, -1)): return false
	var staged_forces := {}
	var target: Vector3 = controller.territory.sites[objective].position
	for runtime in participants:
		var selected: Array = []
		var own: Dictionary = staged_policies[runtime.instance_id]
		var count := mini(int(own.get("max_force",6)), maxi(int(own.get("min_force",2)), ceili(runtime.living_population() * float(own.get("force_fraction",0.25)))))
		# All gameplay battles require previously issued physical armory assets.
		for member in runtime.military.members:
			var citizen: Node3D = member.citizen
			if not preload("res://scripts/military_catalog.gd").permitted(runtime,member.role) or citizen.life_state != "ALIVE" or citizen.combat_kit != member.kit or not runtime.armory.kits.has(member.kit) or runtime.armory.kits[member.kit].state != "ISSUED" or not Roles.BASE.has(member.role): return false
			selected.append(citizen)
		if selected.size() < int(own.get("min_force",2)) or selected.size() > count: return false
		staged_forces[runtime.instance_id] = selected

	# Validate every station before any citizen/task mutation. Keep the original
	# 4-inch navigation-grid spacing, expanding into additional depth rows for
	# larger wars instead of shrinking the proven POC5 formation.
	var planned_targets := {}
	var planned_loadouts := {}
	var occupied: Array[Vector3] = []
	for runtime in participants:
		var force_size: int = staged_forces[runtime.instance_id].size()
		for index in range(force_size):
			var citizen: Node3D = staged_forces[runtime.instance_id][index]
			planned_loadouts[citizen.citizen_id] = citizen.combat_stats.duplicate(true)
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
			var rear := 0.0
			if planned_loadouts[citizen.citizen_id].behavior == "support": rear = 8.0
			elif planned_loadouts[citizen.citizen_id].behavior == "ranged": rear = 4.0
			if rear > 0:
				var outward := (desired-target).normalized()
				desired += outward * rear
			var at: Vector3 = runtime.coordinator.navigation.nearest_walkable_position(desired)
			if occupied.any(func(point: Vector3) -> bool: return point.distance_to(at) < 1.0):
				var found := false
				for offset in [Vector3(4,0,0),Vector3(-4,0,0),Vector3(0,0,4),Vector3(0,0,-4),Vector3(4,0,4),Vector3(-4,0,-4),Vector3(8,0,0),Vector3(-8,0,0),Vector3(0,0,8),Vector3(0,0,-8)]:
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
	forces = staged_forces
	side_policies = staged_policies
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
			# Loadout was issued by ArmorySystem at physical muster.
			commitments.append({"id":citizen.citizen_id,"side":id,"role":citizen.combat_role,"kit":citizen.combat_kit,"stats":citizen.combat_stats.duplicate(true)})
			next_position[citizen.citizen_id] = 0.0
			# Distinct legal station points keep the tiny force readable.
			if not citizen.assign_combat_duty("MARCH", planned_targets[citizen.citizen_id]): return false
			next_attack[citizen.citizen_id] = 0.0
		world.journal.record(world.seconds, "FORCE_COMMITTED", id + " committed citizens", {"instance_id":id,"size":initial_sizes[id],"intensity":side_policies[id].get("intensity_name", conflict_intensity),"cause":side_policies[id].get("cause", conflict_cause),"objective":side_policies[id].get("objective", conflict_objective)}, target, id + ":force", preload("res://scripts/event_fact_context.gd").conflict(site_id, forces.keys(), id))
	phase = "MARCH"
	battle_start_tick = world.tick
	return true

func _reset_battle_state() -> void:
	commitments.clear()
	attack_digest = ""
	attack_history.clear()
	next_position.clear()
	forces.clear()
	side_policies.clear()
	initial_sizes.clear()
	morale.clear()
	casualties.clear()
	next_attack.clear()
	arrivals.clear()
	returned.clear()
	winner = ""
	retreating_side = ""
	retreated_sides.clear()
	eliminated_sides.clear()
	attacks = 0
	attack_pairs.clear()
	retreat_tick = -1
	battle_start_tick = -1
	site_capture_tick = -1
	stand_down_tick = -1
	stand_down_reason = ""

func living(id: String) -> Array:
	if not forces.has(id): return []
	return forces[id].filter(func(c: Node3D) -> bool: return c.life_state == "ALIVE")

func targets_for(citizen: Node3D) -> Array:
	var candidates: Array = []
	for id in forces:
		if _hostile(citizen.civilization_id,String(id)): candidates.append_array(living(id))
	candidates = candidates.filter(func(enemy: Node3D) -> bool:
		return citizen.global_position.distance_to(enemy.global_position) <= float(citizen.combat_stats.range) or not citizen.navigation.combat_path_between(citizen.global_position,enemy.global_position).is_empty())
	candidates.sort_custom(func(a: Node3D,b: Node3D) -> bool:
		var pa := target_priority(citizen,a)
		var pb := target_priority(citizen,b)
		if pa != pb: return pa < pb
		var da := citizen.global_position.distance_squared_to(a.global_position)
		var db := citizen.global_position.distance_squared_to(b.global_position)
		return da < db if da != db else a.citizen_id < b.citizen_id)
	return candidates

func target_priority(citizen: Node3D, enemy: Node3D) -> int:
	var behavior: String = citizen.combat_stats.behavior
	if behavior == "screen":
		for friend in living(citizen.civilization_id):
			if friend.combat_stats.get("behavior", "") in ["ranged","support"] and enemy.global_position.distance_to(friend.global_position) <= 3.0: return 0
		return 1
	if behavior == "assault" and enemy.global_position.distance_to(citizen.global_position) <= float(citizen.combat_stats.range): return -1
	if behavior == "harass": return 0 if float(enemy.combat_stats.armor) <= 1 else 1
	if behavior == "assault": return 0 if float(enemy.combat_stats.armor) <= 1 and enemy.global_position.distance_to(citizen.global_position) <= 3.0 else 1
	return 0 if enemy.global_position.distance_to(citizen.global_position) <= float(citizen.combat_stats.range) else 1

func position_combatant(citizen: Node3D, enemies: Array) -> void:
	if world.seconds < float(next_position[citizen.citizen_id]): return
	next_position[citizen.citizen_id] = world.seconds + float(citizen.combat_stats.reposition)
	var victim: Node3D = enemies[0]
	var nearest: Node3D = victim
	for enemy in enemies:
		if citizen.global_position.distance_squared_to(enemy.global_position) < citizen.global_position.distance_squared_to(nearest.global_position): nearest = enemy
	var at: Vector3 = citizen.global_position
	var behavior: String = citizen.combat_stats.behavior
	var separation := at.distance_to(nearest.global_position)
	var away: Vector3 = (at - nearest.global_position).normalized()
	if away.length() < 0.01: away = Vector3.RIGHT if citizen.citizen_id < nearest.citizen_id else Vector3.LEFT
	var desired := at
	var mode := "HOLD_RANGE"
	if behavior in ["screen","assault"]:
		if at.distance_to(victim.global_position) <= float(citizen.combat_stats.range):
			citizen.combat_state = "MELEE"
			return
		desired = victim.global_position + (at-victim.global_position).normalized() * float(citizen.combat_stats.preferred)
		mode = "SCREEN" if behavior == "screen" else "ASSAULT"
	elif separation < float(citizen.combat_stats.preferred) * 0.65:
		desired = nearest.global_position + away * float(citizen.combat_stats.preferred)
		mode = "WITHDRAW"
	elif at.distance_to(victim.global_position) > float(citizen.combat_stats.range) * 0.95:
		desired = victim.global_position + (at-victim.global_position).normalized() * float(citizen.combat_stats.preferred)
		mode = "SUPPORT" if behavior == "support" else "ADVANCE"
	elif behavior == "harass":
		var flank := away.rotated(Vector3.UP, PI/2 if citizen.citizen_id % 2 == 0 else -PI/2)
		desired = at + flank * 2.0
		mode = "FLANK"
	else:
		citizen.combat_state = mode
		return
	var choice := preload("res://scripts/military_abilities.gd").endpoint(citizen,desired)
	if choice.is_empty(): citizen.combat_state = "BLOCKED"; return
	if citizen.state == "TRAVEL" and citizen._destination.distance_to(choice.target) < 0.3: return
	if citizen.assign_combat_duty("MANEUVER",choice.target): citizen.combat_state = mode

func update() -> void:
	if phase == "DORMANT": return
	for id in retreated_sides:
		_return_arrivals(String(id))
	for side in forces:
		if int(returned.get(side,0)) > 0 and living(String(side)).all(func(c: Node3D) -> bool: return c.combat_duty.is_empty()):
			story_event("DEMOBILIZATION_COMPLETE", "Surviving force returned", String(side))
	var target: Vector3 = world.territory.sites[site_id].position
	for id in forces:
		if not arrivals[id] and living(id).all(func(c: Node3D) -> bool: return c.combat_arrived):
			arrivals[id] = true
			world.journal.record(world.seconds, "FORCE_ARRIVED", id + " physically arrived", {"instance_id":id}, target, id + ":arrived", preload("res://scripts/event_fact_context.gd").conflict(site_id, forces.keys(), id))
	if phase == "MARCH":
		if not arrivals.values().all(func(value: bool) -> bool: return value): return
		phase = "FIGHT"
		story_event("BATTLE_BEGINS", "Forces begin engagement")
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
			if not _departed(String(id)): ordered.append_array(living(id))
		ordered.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.citizen_id < b.citizen_id)
		for citizen in ordered:
			if _departed(citizen.civilization_id) or citizen.life_state != "ALIVE": continue
			var enemies := targets_for(citizen)
			if enemies.is_empty(): continue
			position_combatant(citizen,enemies)
			if world.seconds < float(next_attack[citizen.citizen_id]): continue
			var opponents: Array = enemies.filter(func(c: Node3D) -> bool: return c.global_position.distance_to(citizen.global_position) <= float(citizen.combat_stats.range))
			if opponents.is_empty(): continue
			var victim: Node3D = opponents[0]
			phase = "FIGHT"
			next_attack[citizen.citizen_id] = world.seconds + preload("res://scripts/military_abilities.gd").interval(citizen)
			attacks += 1
			var pair_key: String = world.territory.relation_key(citizen.civilization_id,victim.civilization_id)
			attack_pairs[pair_key] = int(attack_pairs.get(pair_key,0))+1
			world.present_attack(citizen, victim)
			var amount := Roles.damage(float(citizen.combat_stats.damage),float(victim.combat_stats.armor))
			var event := {"tick":world.tick,"attacker":citizen.citizen_id,"target":victim.citizen_id,"damage":amount,"role":citizen.combat_role,"interval":preload("res://scripts/military_abilities.gd").interval(citizen),"prepared":citizen.prepared,"kit":citizen.combat_kit}
			attack_digest = (attack_digest + JSON.stringify(event)).sha256_text()
			if attack_history.size() < 256: attack_history.append(event)
			if victim.suffer_combat_damage(amount):
				casualties[victim.civilization_id] += 1
				world.journal.record(world.seconds, "COMBAT_CASUALTY", "Citizen %d fell" % victim.citizen_id, {"citizen_id":victim.citizen_id,"instance_id":victim.civilization_id}, victim.global_position, "casualty:%d" % victim.citizen_id, casualty_context(victim))
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
		if phase == "SECURE" and _rivals_withdrawn(target) and living(winner).any(func(c: Node3D) -> bool: return c.combat_arrived and c.global_position.distance_to(target) <= SITE_CONTROL_RADIUS):
			if world.territory.hold(site_id, winner, world.seconds, world.STEP):
				site_capture_tick = world.tick
				phase = "COMPLETE"
				story_event("DEMOBILIZATION_STARTED", "Securing force begins returning", winner)
				for citizen in living(winner): citizen.assign_combat_duty("RETREAT", world.runtime_for(winner).coordinator.depot_station)
		elif phase == "SECURE":
			world.territory.sites[site_id].hold_progress = 0.0

func retreat(id: String) -> void:
	if _departed(id) or living(id).is_empty() or not bool(side_policies[id].get("allow_retreat", true)): return
	story_event("MORALE_BREAK", "Force morale broke", id)
	story_event("DEMOBILIZATION_STARTED", "Survivors begin returning", id)
	retreat_tick = world.tick
	retreating_side = id
	retreated_sides[id] = world.tick
	_resolve_departure(true)
	cooldown_until[id] = world.seconds + 600.0
	for citizen in living(id): citizen.assign_combat_duty("RETREAT", world.runtime_for(id).coordinator.depot_station)
	world.journal.record(world.seconds, "RETREAT", id + " morale broke; returning to rally", {"instance_id":id,"morale":morale.duplicate(),"intensity":side_policies[id].get("intensity_name", conflict_intensity),"survivors":living(id).size()}, world.territory.sites[site_id].position, id + ":retreat", preload("res://scripts/event_fact_context.gd").conflict(site_id, forces.keys(), id))

func eliminate(id: String) -> void:
	if not forces.has(id) or _departed(id) or not living(id).is_empty(): return
	eliminated_sides[id] = world.tick
	cooldown_until[id] = world.seconds + 600.0
	_resolve_departure(false)
	world.journal.record(world.seconds, "FORCE_ELIMINATED", id + " committed force eliminated", {"instance_id":id,"casualties":casualties[id],"initial_committed_force":initial_sizes[id],"intensity":side_policies[id].get("intensity_name", conflict_intensity),"cause":side_policies[id].get("cause", conflict_cause),"objective":side_policies[id].get("objective", conflict_objective),"tick":world.tick}, world.territory.sites[site_id].position, id + ":eliminated", preload("res://scripts/event_fact_context.gd").conflict(site_id, forces.keys(), id))

func _departed(id: String) -> bool:
	return retreated_sides.has(id) or eliminated_sides.has(id)

func _resolve_departure(withdrawing: bool) -> void:
	var remaining: Array = forces.keys().filter(func(side: Variant) -> bool: return not _departed(String(side)) and not living(String(side)).is_empty())
	if remaining.size() == 1:
		winner = String(remaining[0])
		phase = "RETREAT" if withdrawing else "SECURE"
		var at: Vector3 = world.territory.sites[site_id].position
		# Role maneuvers can leave support outside the objective. Assign a real
		# capturer explicitly so a stale attack path cannot carry the winner away.
		var holders := living(winner)
		holders.sort_custom(func(a: Node3D,b: Node3D) -> bool:
			var da := a.global_position.distance_squared_to(at)
			var db := b.global_position.distance_squared_to(at)
			return da < db if da != db else a.citizen_id < b.citizen_id)
		if not holders.is_empty(): holders[0].assign_combat_duty("MARCH",at)
	elif remaining.is_empty():
		winner = ""
		phase = "STAND_DOWN"
	else:
		winner = ""
		phase = "FIGHT"
	world.territory.sites[site_id].hold_progress = 0.0

func stand_down(reason: String) -> void:
	if phase not in ["MARCH", "FIGHT"]: return
	stand_down_tick = world.tick
	stand_down_reason = reason
	winner = ""
	retreating_side = ""
	phase = "STAND_DOWN"
	for id in forces:
		story_event("DEMOBILIZATION_STARTED", "Force stands down and returns", String(id))
		for citizen in living(id): citizen.assign_combat_duty("RETREAT", world.runtime_for(String(id)).coordinator.depot_station)
	world.journal.record(world.seconds, "CONFLICT_STOOD_DOWN", "Conflict ended because its cause no longer justified war", {"reason":reason,"intensity":conflict_intensity,"cause":conflict_cause}, world.territory.sites[site_id].position, site_id + ":standdown:%d" % world.tick, preload("res://scripts/event_fact_context.gd").conflict(site_id, forces.keys(), ""))

func evaluate_morale() -> bool:
	var losing := ""
	var largest_deficit := 0.0
	for id in forces:
		if _departed(String(id)): continue
		var survivors := living(id)
		if survivors.is_empty():
			eliminate(String(id))
			return true
		var other := 0
		for rival in forces:
			if _hostile(String(id), String(rival)): other += living(rival).size()
		var average := 0.0
		for survivor in survivors: average += (survivor.health / survivor.max_health) / maxf(1, survivors.size())
		var disadvantage := maxf(0, 1.0 - float(survivors.size()) / maxf(1, other))
		morale[id] = 1.0 - float(casualties[id]) / initial_sizes[id] * 0.65 - disadvantage * 0.20 - (1.0 - average) * 0.15
		var own: Dictionary = side_policies[id]
		var deficit := float(own.get("retreat_threshold", DEFAULT_RETREAT_THRESHOLD)) - float(morale[id])
		if bool(own.get("allow_retreat", true)) and deficit > largest_deficit:
			largest_deficit = deficit
			losing = String(id)
	if not losing.is_empty():
		retreat(losing)
		return true
	return false

func _hostile(a: String, b: String) -> bool:
	return a != b and not _departed(a) and not _departed(b) and world.territory.relations.get(world.territory.relation_key(a,b), "UNKNOWN") == "HOSTILE"

func _rivals_withdrawn(target: Vector3) -> bool:
	for id in forces:
		if id != winner and not living(id).all(func(c: Node3D) -> bool: return c.global_position.distance_to(target) > maxf(SITE_CONTROL_RADIUS,float(c.combat_stats.get("range",0)))): return false
	# A side's withdrawal against one rival does not surrender its peaceful claim
	# to a different winner. Any living non-hostile claimant prevents exclusivity.
	for id in world.territory.sites[site_id].contesting_civilizations:
		if id == winner: continue
		var runtime: Node = world.runtime_for(String(id))
		if runtime != null and runtime.living_population() > 0 and world.territory.relations.get(world.territory.relation_key(winner,String(id)),"UNKNOWN") != "HOSTILE": return false
	return true

func _return_arrivals(id: String) -> void:
	for citizen in living(id):
		if citizen.combat_duty == "RETREAT" and citizen.combat_arrived:
			citizen.end_combat_duty()
			returned[id] = int(returned.get(id, 0)) + 1

static func _valid_policy(value: Dictionary) -> bool:
	if value.has("roles"):
		if not value.roles is Array or value.roles.is_empty() or not value.roles.all(func(role: Variant) -> bool: return role is String and role in Roles.BASE): return false
	var validation := preload("res://scripts/innovation_validation.gd")
	for field in ["force_fraction", "min_force", "max_force", "retreat_threshold"]:
		if value.has(field) and not validation.number(value[field]): return false
	for field in ["min_force", "max_force"]:
		if value.has(field) and (value[field] < 1 or value[field] > 150 or value[field] != floorf(value[field])): return false
	if float(value.get("force_fraction",0.25)) < 0 or float(value.get("force_fraction",0.25)) > 1: return false
	if int(value.get("max_force",6)) < int(value.get("min_force",2)): return false
	if value.has("allow_retreat") and not value.allow_retreat is bool: return false
	return float(value.get("retreat_threshold",0.7)) >= -1 and float(value.get("retreat_threshold",0.7)) <= 1

func casualty_context(victim: Node3D) -> Dictionary:
	var context := preload("res://scripts/event_fact_context.gd").conflict(site_id, forces.keys(), victim.civilization_id)
	context.subject_type = "citizen"
	context.subject_id = str(victim.citizen_id)
	return context

func story_event(kind: String, message: String, society_id: String = "") -> void:
	world.journal.record(world.seconds, kind, message, {"instance_id":society_id,"phase":phase}, world.territory.sites[site_id].position, site_id+":"+society_id+":"+kind+":"+str(battle_start_tick), preload("res://scripts/event_fact_context.gd").conflict(site_id,forces.keys(),society_id))
