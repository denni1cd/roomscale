extends RefCounted
## TEST ONLY: authored initially equipped citizens isolate accepted tactical contracts.
## Live conflict drivers never import this fixture and must manufacture every kit.
static func prepare(world: Node, ids: Array, policies: Dictionary) -> void:
	var site: Vector3 = world.territory.sites[world.scenario.strategic_site].position
	for id in ids:
		var sim: Node = world.runtime_for(id)
		var own: Dictionary = policies[id]
		var count := preload("res://scripts/military_doctrine.gd").authorized_size(sim.living_population(),own)
		var candidates: Array = sim.citizens.filter(func(c: Node3D) -> bool: return c.eligible_for_combat(site))
		candidates.sort_custom(func(a: Node3D,b: Node3D) -> bool:
			var da := a.global_position.distance_squared_to(site)
			var db := b.global_position.distance_squared_to(site)
			return da < db if da != db else a.citizen_id < b.citizen_id)
		sim.military.members.clear()
		for index in mini(count,candidates.size()):
			var citizen: Node3D = candidates[index]
			var roles: Array = own.get("roles",preload("res://scripts/combat_roles.gd").ORDER)
			var role: String = roles[index % roles.size()]
			var kit := "%s:kit:%d" % [sim.instance_id,sim.armory._next_kit]
			sim.armory._next_kit += 1
			sim.armory.kits[kit] = {"id":kit,"equipment_id":role+"_kit","role":role,"owner":sim.instance_id,"variant":"normal","state":"STOCKED","citizen_id":-1}
			sim.armory.kits[kit].state = "ISSUED"; sim.armory.kits[kit].citizen_id = citizen.citizen_id
			citizen.combat_kit = kit
			citizen.equip_combat(preload("res://scripts/combat_roles.gd").loadout(sim.definition,role))
			sim.military.members.append({"citizen":citizen,"kit":kit,"role":role})
		sim.military.state = "READY"
