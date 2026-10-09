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

	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures}
	print("ROOMSCALE_CONFLICT_PRESSURE_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
