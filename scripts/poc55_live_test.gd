extends SceneTree
## Real fresh production scenario: deterministic simulation and selected shot evidence.
const Evidence := preload("res://scripts/verification/evidence_io.gd")
var failures: Array[String] = []
var trace: Array = []
var milestones := {}
var societies := {}
var frames := {}
var scene: Node3D
var sim: Node
var world: Node
var director: Node
var hud: Control
var rig: Node
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if not value and not failures.has(label): failures.append(label)
func canonical(value: Variant) -> String:
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		var parts: Array[String] = []
		for key in keys: parts.append(str(key) + ":" + canonical(value[key]))
		return "{" + ",".join(parts) + "}"
	if value is Array:
		var parts: Array[String] = []
		for item in value: parts.append(canonical(item))
		return "[" + ",".join(parts) + "]"
	return var_to_str(value)
func task_outcomes(tasks: Array) -> Array:
	# TaskCoordinator stamps these five diagnostic values with Time.get_ticks_msec().
	# Keep IDs, states, sim timestamps, assignments, progress and resource outcomes.
	var result: Array = tasks.duplicate(true)
	for task in result:
		for key in ["created_at", "started_at", "finished_at", "picked_up_at", "delivered_at"]: task.erase(key)
	return result
func snapshot() -> Dictionary:
	var state := {"tick": world.tick, "citizens": [], "societies": [], "resources": world.resources.sources, "bundles": world.resources.bundles, "sites": world.territory.sites, "combat": {"attack_digest":world.combat.attack_digest,"attacks":world.combat.attacks,"phase":world.combat.phase,"winner":world.combat.winner,"casualties":world.combat.casualties,"retreated":world.combat.retreated_sides}}
	for citizen in world.citizens:
		state.citizens.append({"id": citizen.citizen_id, "society": citizen.civilization_id, "position": citizen.global_position, "task":citizen.task_id, "task_type":citizen.task_type,"state":citizen.state,"needs":citizen.needs,"health":citizen.health,"kit":citizen.combat_kit,"duty":citizen.combat_duty})
	for runtime in world.ordered_runtimes():
		state.societies.append({"id":runtime.instance_id,"economy":runtime.economy.snapshot(),"tasks":task_outcomes(runtime.coordinator.tasks),"development":runtime.development.active,"development_projects":runtime.development.projects,"innovation":runtime.innovation.active,"innovation_projects":runtime.innovation.projects,"research_history":runtime.innovation.research_history,"known_technologies":runtime.innovation.resolver.known_technologies if runtime.innovation.resolver != null else {},"research":runtime.innovation.research,"kits":runtime.armory.kits,"projects":runtime.armory.projects,"military":runtime.military.snapshot(),"governor":{"mode":runtime.governor.mode,"evaluations":runtime.governor.evaluations,"emergency":runtime.governor.emergency},"salvage":runtime.salvage.objects,"cohorts":runtime.population.cohorts,"members":runtime.military.members.map(func(member: Dictionary) -> int: return member.citizen.citizen_id),"population":runtime.living_population()})
	return state
func capture(label: String) -> void:
	var directory := OS.get_environment("ROOMSCALE_VISUAL_DIR")
	if directory.is_empty() or frames.has(label): return
	check(DisplayServer.get_name() != "headless", "rendered capture requires renderer")
	for frame in range(60): rig._process(1.0 / 60.0)
	hud.advance(0.01)
	await process_frame
	await RenderingServer.frame_post_draw
	var path := directory.path_join(label + ".png")
	check(Evidence.save_png(root.get_texture().get_image(), path) == OK, "capture " + label)
	frames[label] = {"path":path,"tick":world.tick,"mode":director.mode_name(),"shot":director.current_shot.duplicate(true)}
func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_conflict_c")
	OS.set_environment("ROOMSCALE_CONFLICT", "1")
	OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO", "three_party_conflict")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_MANUAL_CAMERA", "1")
	root.size = Vector2i(1920, 1080)
	scene = load("res://scenes/pipeline_proof.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.get_node("WorldSimulation")
	sim = world.runtimes[0]
	director = sim.camera_director
	hud = sim.spectator
	rig = scene.get_node("CameraRig")
	for runtime in world.runtimes: runtime.set_process(false)
	director.set_process(false)
	hud.set_process(false)
	rig.set_process(false)
	var mode := OS.get_environment("ROOMSCALE_DIRECTOR_MODE")
	if mode.is_empty(): mode = "OFF"
	director.set_spectator_seed(5505)
	if mode == "FOLLOW": director.follow(director.follow_choices()[0])
	else: director.set_mode(mode)
	var digests := {}
	var last_shots := -1
	for tick in range(6200):
		world.step()
		director.advance(0.01)
		rig._process(0.01)
		if tick % 10 == 0:
			hud.advance(0.1)
			for event in director.events():
				milestones[event.kind] = true
				if not String(event.society_id).is_empty(): societies[event.society_id] = true
		if director.shots != last_shots and not director.current_shot.is_empty():
			last_shots = director.shots
			var shot: Dictionary = director.current_shot.duplicate(true)
			trace.append({"tick":world.tick,"real_seconds":director.real_seconds,"shot":shot})
			if mode == "PRIORITY" and int(shot.get("priority",0)) >= 2: await capture("priority-major-event")
			if mode == "RANDOM" and shot.get("class","") in ["hauling","salvage","construction","research","work","equipment"]: await capture("random-ordinary-work")
		if world.combat.phase in ["MARCH", "FIGHT"] and mode == "PRIORITY" and (director.current_shot.get("class","") == "conflict" or director.current_shot.get("category","") == "military"):
			await capture("combat-mobilization-framing")
		if tick in [999,2999,6199]:
			var checkpoint := snapshot()
			check(checkpoint.has("citizens") and checkpoint.get("citizens",[]).size() == world.citizens.size(), "nonempty checkpoint snapshot")
			digests[str(tick + 1)] = canonical(checkpoint).sha256_text()
		if tick % 100 == 0: await process_frame
	check(world.combat.attacks > 0 and world.combat.winner != "", "real military scenario resolves")
	for identity in ["clockwork_alpha","verdant_alpha","scavenger_alpha"]: check(societies.has(identity), "feed source " + identity)
	await capture("multi-civilization-feed")
	var state := snapshot()
	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures,"mode":mode,"digests":digests,"excluded_task_diagnostic_fields":["created_at","started_at","finished_at","picked_up_at","delivered_at"],"attack_digest":world.combat.attack_digest,"trace":trace,"milestones":milestones.keys(),"societies":societies.keys(),"frames":frames,"final":state}
	var output := OS.get_environment("ROOMSCALE_FOCUSED_RESULT")
	if output.is_empty(): output = "res://verification/poc55/live-" + mode.to_lower() + ".json"
	check(Evidence.save_json(result, output) == OK, "write live evidence")
	print("POC55_LIVE_" + ("PASS" if failures.is_empty() else "FAIL") + " mode=" + mode + " digest=" + str(digests) + " failures=" + str(failures))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)




