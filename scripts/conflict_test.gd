extends SceneTree
## Bounded observer of the actual production scene and fixed world clock.
var failures: Array[String] = []
var captures: Array[String] = []
var output := ""
var scene: Node3D
var world: Node
var post_work: Dictionary = {}
var foreign_delivery_checked := false
var foreign_source_checked := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition and not failures.has(message): failures.append(message)

func capture(name: String, at: Vector3, distance: float) -> void:
	var directory := OS.get_environment("ROOMSCALE_VISUAL_DIR")
	if directory.is_empty() or captures.has(name): return
	check(DisplayServer.get_name() != "headless", "graphical evidence requires a real renderer")
	scene.get_node("CameraRig").focus_detail_at(at,distance,28 if distance < 3 else 55)
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(name + ".png")
	check(root.get_texture().get_image().save_png(path) == OK,"capture write")
	captures.append(name)

func run() -> void:
	output = OS.get_environment("ROOMSCALE_CONFLICT_RESULT")
	scene = load("res://scenes/pipeline_proof.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.get_node_or_null("WorldSimulation")
	if world == null:
		push_error("ROOMSCALE_CONFLICT_FAIL world unavailable")
		quit(1)
		return
	for runtime in world.runtimes: runtime.set_process(false)
	check(world.runtimes.size() == 2,"two civilization instances")
	var a: Node = world.runtimes[0]
	var b: Node = world.runtimes[1]
	check(a.economy != b.economy and a.needs != b.needs and a.population != b.population and a.development != b.development,"independent society authorities")
	check(a.resources == b.resources and a.salvage == b.salvage,"one finite source and salvage authority")
	check(a.coordinator.navigation == b.coordinator.navigation and a.coordinator.surface_navigation == b.coordinator.surface_navigation,"one navigation authority")
	check(a.coordinator.claim_for(b.citizens[0].citizen_id).is_empty() and b.coordinator.claim_for(a.citizens[0].citizen_id).is_empty(),"foreign citizen claim rejected")
	await capture("01-two-societies",Vector3.ZERO,280)
	var complete_at := -1
	var pre_checked := false
	var max_step := 0.0
	var dead_positions: Dictionary = {}
	var dead_distance: Dictionary = {}
	for iteration in range(9000):
		var positions: Dictionary = {}
		for citizen in world.citizens: positions[citizen.citizen_id] = citizen.global_position
		world.step()
		check(world.resources.audit().is_empty(),"finite source conservation")
		if not foreign_source_checked:
			for source_id in world.resources.sources:
				var source: Dictionary = world.resources.sources[source_id]
				for resource in source.reserved:
					if float(source.reserved[resource]) < 1: continue
					var reserved_before: float = source.reserved[resource]
					check(world.resources.extract(source_id,resource,1,source.position,"foreign_probe") == -1,"foreign source extraction rejected")
					world.resources.release_source(source_id,resource,1,"foreign_probe")
					check(source.reserved[resource] == reserved_before,"foreign cancellation cannot release another society reservation")
					foreign_source_checked = true
		if not foreign_delivery_checked:
			for bundle_id in world.resources.bundles:
				var bundle: Dictionary = world.resources.bundles[bundle_id]
				if bundle.state != "in_transit": continue
				var foreign: Node = b if bundle.instance_id == a.instance_id else a
				check(not world.resources.deliver_bundle(bundle_id,bundle.citizen_id,foreign.coordinator.depot_station,foreign.coordinator.depot_station,foreign.economy),"cross-depot delivery rejected")
				foreign_delivery_checked = true
				break
		for runtime in world.runtimes:
			check(runtime.economy.audit().is_empty(),"depot conservation")
			for citizen in runtime.citizens:
				check(citizen.civilization_id == runtime.instance_id,"roster ownership")
				if positions.has(citizen.citizen_id):
					max_step = maxf(max_step,citizen.global_position.distance_to(positions[citizen.citizen_id]))
				if citizen.life_state == "DEAD":
					if not dead_positions.has(citizen.citizen_id):
						dead_positions[citizen.citizen_id] = citizen.global_position
						dead_distance[citizen.citizen_id] = citizen.travelled_distance
					check(citizen.task_id == -1 and citizen.state == "DEAD" and citizen.global_position == dead_positions[citizen.citizen_id] and citizen.travelled_distance == dead_distance[citizen.citizen_id],"dead citizens terminally leave work pool")
			for task in runtime.coordinator.tasks:
				check(task.instance_id == runtime.instance_id,"task board ownership")
				if task.state in ["active","reserved"]:
					var worker: Node3D = runtime.citizen_for(task.citizen_id)
					check(worker != null and worker.life_state == "ALIVE" and worker.civilization_id == task.instance_id,"active task belongs to living owner")
		if world.tick >= 1000 and not pre_checked:
			pre_checked = true
			check(a.haul_deliveries > 0 and b.haul_deliveries > 0,"both societies perform ordinary physical deliveries")
			check(a.governor.evaluations > 0 and b.governor.evaluations > 0,"both autonomous governors active")
			check(world.combat.phase == "DORMANT","bounded peaceful coexistence")
			await capture("02-coexistence",Vector3.ZERO,190)
		if world.first_contact_tick == world.tick: await capture("03-contested-site",world.territory.sites[world.scenario.strategic_site].position + Vector3(0,0.3,0),10)
		if world.combat.phase == "MARCH" and world.tick - world.combat.battle_start_tick >= 10:
			for id in world.combat.forces:
				if captures.has("03-" + id + "-march"): continue
				for citizen in world.combat.forces[id]:
					if citizen.state == "TRAVEL":
						await capture("03-" + id + "-march",citizen.global_position + Vector3(0,0.25,0),8)
						break
		if world.combat.attacks >= 6 and world.combat.arrivals.values().all(func(value: bool) -> bool: return value) and not captures.has("04-battle"):
			await capture("04-battle",world.territory.sites[world.scenario.strategic_site].position + Vector3(0,0.3,0),12)
			if not OS.get_environment("ROOMSCALE_VISUAL_DIR").is_empty():
				for id in world.combat.forces:
					await capture("04-" + id + "-weapon",world.combat.forces[id][0].global_position + Vector3(0,0.25,0),2.2)
		if world.combat.retreat_tick > 0 and world.tick - world.combat.retreat_tick >= 12 and not captures.has("05-retreat"):
			await capture("05-retreat",(world.territory.sites[world.scenario.strategic_site].position + world.runtime_for(world.combat.retreating_side).coordinator.housing_station)/2,75)
		if world.combat.phase == "COMPLETE":
			if complete_at < 0:
				complete_at = world.tick
				for runtime in world.runtimes: post_work[runtime.instance_id] = runtime.coordinator._completed_count
				await capture("06-captured-site",world.territory.sites[world.scenario.strategic_site].position + Vector3(0,0.3,0),9)
			if world.tick - complete_at >= 1000: break
		if iteration % 100 == 0: await process_frame
	check(complete_at > 0,"production battle and secure capture complete")
	check(max_step <= 0.65001,"all military and retreat movement respects production speed")
	for kind in ["SITE_TARGETED","FIRST_CONTACT","HOSTILITY_DECLARED","SITE_CONTESTED","FORCE_COMMITTED","FORCE_ARRIVED","COMBAT_CASUALTY","RETREAT","SITE_CAPTURED"]:
		check(world.journal.events.any(func(e: Dictionary) -> bool: return e.kind == kind),"event " + kind)
	check(foreign_source_checked,"foreign source negative boundary exercised on a real reservation")
	check(foreign_delivery_checked,"cross-depot negative boundary exercised on a real bundle")
	for kind in ["FIRST_CONTACT","HOSTILITY_DECLARED","SITE_CONTESTED","SITE_CAPTURED"]:
		check(world.journal.events.filter(func(e: Dictionary) -> bool: return e.kind == kind).size() == 1,"single transition " + kind)
	check(world.combat.attacks > 0 and dead_positions.size() > 0,"attacks cause real persistent casualties")
	check(world.combat.morale.values().any(func(value: float) -> bool: return value < 1.0),"morale responds to health and losses")
	for runtime in world.runtimes:
		check(runtime.living_population() > 0,"both civilizations survive")
		check(runtime.coordinator._completed_count > int(post_work.get(runtime.instance_id,2147483647)),"ordinary post-battle work resumes")
		for citizen in world.combat.living(runtime.instance_id):
			check(citizen.combat_duty.is_empty(),"every surviving combatant leaves military duty")
			check(runtime.coordinator.tasks.any(func(task: Dictionary) -> bool: return task.citizen_id == citizen.citizen_id and task.state == "complete" and float(task.get("claimed_sim",0)) > complete_at * world.STEP),"each surviving combatant completes ordinary post-battle activity")
		check(int(world.combat.returned.get(runtime.instance_id,0)) > 0,"surviving combatants physically return to ordinary duty")
		check(bool(world.combat.arrivals.get(runtime.instance_id,false)),"both forces physically arrive")
		check(int(world.combat.initial_sizes.get(runtime.instance_id,0)) <= 6,"bounded military forces")
	await capture("07-post-battle",Vector3.ZERO,240)
	for runtime in world.runtimes:
		await capture("08-" + runtime.instance_id + "-settlement",runtime.coordinator.depot_station + Vector3(0,0.5,0),25)
	if not dead_positions.is_empty(): await capture("09-casualty",dead_positions.values()[0] + Vector3(0,0.25,0),2.2)
	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures,"room":world.room_definition.id,"first_contact_tick":world.first_contact_tick,"battle_start_tick":world.combat.battle_start_tick,"force_sizes":world.combat.initial_sizes,"casualties":world.combat.casualties,"retreating_side":world.combat.retreating_side,"winner":world.combat.winner,"site_capture_tick":world.combat.site_capture_tick,"attacks":world.combat.attacks,"morale":world.combat.morale,"returned":world.combat.returned,"max_step":max_step,"societies":{a.instance_id:{"status":a.status(),"projects":a.development.projects,"deliveries":a.haul_deliveries},b.instance_id:{"status":b.status(),"projects":b.development.projects,"deliveries":b.haul_deliveries}},"events":world.journal.events,"captures":captures,"final_tick":world.tick,"living_populations":{a.instance_id:a.living_population(),b.instance_id:b.living_population()}}
	if not output.is_empty():
		var file := FileAccess.open(output,FileAccess.WRITE)
		if file == null: check(false,"result write failed")
		else: file.store_string(JSON.stringify(result,"  "))
	print("ROOMSCALE_CONFLICT_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
