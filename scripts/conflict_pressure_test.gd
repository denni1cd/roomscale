extends SceneTree
## Focused POC 5.1 verification: pressure math plus real production-world peace/war gates.
const Pressure := preload("res://scripts/conflict_pressure_system.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition and not failures.has(message): failures.append(message)

func spawn_world() -> Array:
	var scene: Node3D = load("res://scenes/pipeline_proof.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var world: Node = scene.get_node_or_null("WorldSimulation")
	if world != null:
		for runtime in world.runtimes: runtime.set_process(false)
	return [scene, world]

func run_until_pressure(world: Node, limit: int = 5000) -> void:
	for iteration in range(limit):
		world.step()
		if world.first_contact_tick > 0 and world.conflict_pressure.evaluations > 0: return
		if iteration % 200 == 0: await process_frame

func run() -> void:
	# Pure deterministic contract boundaries.
	check(Pressure.resource_scarcity(100.0,20.0) == 0.0,"abundant resource has zero scarcity")
	check(Pressure.resource_scarcity(0.0,20.0) == 1.0,"missing survival resource has maximum scarcity")
	check(Pressure.space_pressure(12,24.0) == 0.0,"ample space has zero territorial pressure")
	check(Pressure.classify(Pressure.space_pressure(12,11.0)) == Pressure.LIMITED_WAR,"canonical crowding maps to limited war")
	check(Pressure.classify(Pressure.space_pressure(12,6.0)) == Pressure.SURVIVAL_WAR,"extreme crowding maps to survival war")
	var limited := Pressure.policy_for(Pressure.LIMITED_WAR)
	var major := Pressure.policy_for(Pressure.MAJOR_WAR)
	var survival := Pressure.policy_for(Pressure.SURVIVAL_WAR)
	check(float(limited.force_fraction) < float(major.force_fraction) and float(major.force_fraction) < float(survival.force_fraction),"force commitment rises with intensity")
	check(bool(limited.allow_retreat) and bool(major.allow_retreat) and not bool(survival.allow_retreat),"survival war disables ordinary morale retreat")
	check(float(limited.retreat_threshold) > float(major.retreat_threshold),"major war tolerates more losses before retreat")

	# Real evaluator against production world state: a sole contested food source with no secured stock is existential.
	var resource_fixture := spawn_world()
	var resource_scene: Node3D = resource_fixture[0]
	var resource_world: Node = resource_fixture[1]
	check(resource_world != null,"resource fixture world")
	if resource_world != null:
		resource_world.scenario.site_benefits = {"resource_sources":{"food":["food_cache"]}}
		for runtime in resource_world.runtimes: runtime.economy.available.food = 0.0
		var site_id := String(resource_world.scenario.strategic_site)
		for runtime in resource_world.runtimes: resource_world.territory.claim(site_id,runtime.instance_id,0.0)
		var result: Dictionary = resource_world.conflict_pressure.evaluate(resource_world,site_id)
		check(result.cause == "RESOURCE" and result.resource == "food","scarce contested food produces explicit resource reason")
		check(result.intensity == Pressure.SURVIVAL_WAR,"zero secured food with sole contested source is survival pressure")
		var probe := preload("res://scripts/combat_system.gd").new()
		var before_tasks := {}
		for citizen in resource_world.citizens: before_tasks[citizen.citizen_id] = citizen.task_id
		var sides: Array = resource_world.territory.sites[site_id].contesting_civilizations
		resource_world.territory.set_relation(sides[0], sides[1], "HOSTILE", 0, site_id)
		check(not probe.start(resource_world, site_id, {"participants":"invalid"}), "invalid battle participant type fails closed")
		check(not probe.start(resource_world, site_id, {"min_force":150,"max_force":150}), "unavailable complete force rejects commitment")
		check(probe.world == null and probe.forces.is_empty() and probe.phase == "DORMANT", "rejected battle publishes no partial authority")
		for citizen in resource_world.citizens: check(citizen.task_id == before_tasks[citizen.citizen_id] and citizen.combat_duty.is_empty(), "rejected battle leaves citizen work unchanged")
	resource_scene.queue_free()
	await process_frame

	# Full production-world gate: abundant secured space permits contact/competition without battle.
	var peace_fixture := spawn_world()
	var peace_scene: Node3D = peace_fixture[0]
	var peace_world: Node = peace_fixture[1]
	check(peace_world != null,"peace fixture world")
	if peace_world != null:
		for participant in peace_world.scenario.participants: participant.home_space_capacity = 150
		await run_until_pressure(peace_world)
		check(peace_world.first_contact_tick > 0,"abundant fixture reaches real first contact")
		check(not peace_world.conflict_state.is_empty(),"abundant fixture evaluates pressure")
		if not peace_world.conflict_state.is_empty():
			check(int(peace_world.conflict_state.intensity) == Pressure.PEACE,"abundant space remains peace")
		check(peace_world.combat.battle_start_tick < 0 and peace_world.combat.phase == "DORMANT","abundance blocks combat after contact")
		var participants: Array = peace_world.territory.sites[peace_world.scenario.strategic_site].contesting_civilizations
		if participants.size() >= 2:
			check(peace_world.territory.relations.get(peace_world.territory.relation_key(participants[0],participants[1]),"") == "CONTACT","peaceful contested claim does not become hostile")
	peace_scene.queue_free()
	await process_frame

	# Canonical production scenario: the exact same world path escalates because home space is constrained.
	var war_fixture := spawn_world()
	var war_scene: Node3D = war_fixture[0]
	var war_world: Node = war_fixture[1]
	check(war_world != null,"war fixture world")
	if war_world != null:
		for iteration in range(5000):
			war_world.step()
			if war_world.combat.battle_start_tick > 0: break
			if iteration % 200 == 0: await process_frame
		check(war_world.combat.battle_start_tick > 0,"canonical scarcity starts real combat")
		check(war_world.conflict_state.cause == "SPACE","canonical conflict reason is space")
		check(int(war_world.conflict_state.intensity) == Pressure.LIMITED_WAR,"canonical conflict is limited war")
		check(war_world.conflict_state.objective == "SECURE_TERRITORY","limited territorial war has bounded objective")
		check(war_world.combat.conflict_intensity == "LIMITED_WAR" and war_world.combat.conflict_cause == "SPACE","combat receives pressure policy")
		for size in war_world.combat.initial_sizes.values(): check(int(size) <= 6,"limited war keeps bounded POC5 force size")
	war_scene.queue_free()
	await process_frame

	# Three real runtime instances: invalid setup is atomic and a comfortable
	# third claimant neither suppresses the scarce pair nor joins their force.
	OS.set_environment("ROOMSCALE_ROOM", "room_conflict_c")
	OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO", "three_party_conflict")
	var multi_fixture := spawn_world()
	var multi_scene: Node3D = multi_fixture[0]
	var multi_world: Node = multi_fixture[1]
	if multi_world != null:
		var navigation: Node = multi_scene.get_node("FloorNavigation")
		var validator := preload("res://scripts/conflict_scenario.gd")
		for invalid in [null, {}, {"participants":"wrong"}]: check(not validator.prepare(invalid, multi_world.room_definition, navigation).ok, "malformed scenario fails closed")
		for field in ["duplicate_id", "duplicate_slot", "unknown_slot", "unknown_definition", "numeric_time", "bad_capacity", "ambiguous_namespace", "bad_benefits", "unknown_source"]:
			var bad: Dictionary = multi_world.scenario.duplicate(true)
			match field:
				"duplicate_id": bad.participants[2].instance_id = bad.participants[0].instance_id
				"duplicate_slot": bad.participants[2].start_slot = bad.participants[0].start_slot
				"unknown_slot": bad.participants[2].start_slot = "missing"
				"unknown_definition": bad.participants[2].definition_id = "missing"
				"numeric_time": bad.pre_contact_seconds = "120"
				"bad_capacity": bad.participants[2].home_space_capacity = -1
				"ambiguous_namespace": bad.participants[2].instance_id = "a:b"
				"bad_benefits": bad.site_benefits = {"resource_sources":{"food":[42]}}
				"unknown_source": bad.site_benefits = {"resource_sources":{"food":["missing"]}}
			var rejected: Dictionary = validator.prepare(bad, multi_world.room_definition, navigation)
			check(not rejected.ok and rejected.get("prepared", []).is_empty(), "invalid scenario publishes no staged roster: " + field)
		check(multi_world.citizens.size() == 36 and multi_world.tick == 0, "scenario validation leaves real actors untouched")
		multi_world.scenario.participants[2].home_space_capacity = 150
		var outsider: Node = multi_world.runtimes[2]
		var third_health := {}
		for citizen in outsider.citizens: third_health[citizen.citizen_id] = citizen.health
		for iteration in range(4500):
			multi_world.step()
			check(not multi_world.combat.forces.has(outsider.instance_id), "peaceful third society excluded from military selection")
			for citizen in outsider.citizens: check(citizen.health == third_health[citizen.citizen_id] and citizen.combat_duty.is_empty(), "peaceful third citizens never attacked or recruited")
			check(multi_world.resources.audit().is_empty(), "multi-party conservation")
			if iteration % 200 == 0: await process_frame
		check(multi_world.combat.attacks > 0 and multi_world.combat.initial_sizes.size() == 2, "scarce pair still fights despite comfortable third")
		check(multi_world.combat.site_capture_tick < 0, "surviving peaceful claim prevents exclusive military capture")
		check(multi_world.conflict_state.pairs.size() == 3, "all bilateral pressures evaluated")
		check(not multi_world.combat.start(multi_world, multi_world.scenario.strategic_site), "cannot overwrite an active battle")
	else: check(false, "three-party production world available")
	multi_scene.queue_free()
	await process_frame

	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures}
	print("ROOMSCALE_CONFLICT_PRESSURE_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
