extends SceneTree
## Production-scene evidence, including society journals before bounded history evicts them.
var failures: Array[String] = []
var seen := {}
var societies := {}
var lost_events_validated := {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok and not failures.has(label): failures.append(label)
func collect(journal: RefCounted, runtime: Node = null, world: Node = null) -> void:
	for event in journal.events:
		seen[event.kind] = true
		check(journal.validate(event).is_empty(),"valid event schema")
		check(not event.story_key.is_empty(),"stable story grouping")
		if not event.society_id.is_empty(): societies[event.society_id] = true
		if event.kind in ["BATTLE_BEGINS","COMBAT_CASUALTY","RETREAT","SITE_CAPTURED"]:
			check(not event.site_id.is_empty() and not event.conflict_id.is_empty(),"military conflict identity")
		if event.kind == "COMBAT_CASUALTY": check(event.subject_type == "citizen" and not event.subject_id.is_empty(),"casualty subject identity")
		if event.kind == "KIT_LOST" and runtime != null:
			var key := String(event.society_id) + ":" + str(event.id)
			if lost_events_validated.has(key): continue
			lost_events_validated[key] = true
			var citizen_id := int(event.evidence.get("citizen_id", -1))
			var casualty: Node3D = runtime.citizen_for(citizen_id)
			check(casualty != null and casualty.life_state == "DEAD", "KIT_LOST belongs to dead issued-kit citizen")
			check(event.society_id == runtime.instance_id and event.subject_type == "equipment" and event.subject_id == str(event.evidence.get("id", "")), "KIT_LOST preserves society and equipment identity")
			check(String(event.evidence.get("state", "")) == "LOST" and citizen_id >= 0, "KIT_LOST evidence records issued kit terminal state and casualty")
			if casualty == null: continue
			check(casualty.global_position.distance_to(runtime.coordinator.depot_station) > 1.0, "KIT_LOST casualty is away from depot")
			check(event.focus_valid and event.focus.distance_to(casualty.global_position) < 0.01, "KIT_LOST factual focus is casualty location")
			check(event.focus.distance_to(runtime.coordinator.depot_station) > 1.0, "KIT_LOST focus is not depot")
			var economy_before: Dictionary = runtime.economy.snapshot()
			var armory_before: Dictionary = runtime.armory.snapshot()
			var attacks_before: int = world.combat.attacks if world != null else -1
			var digest_before: String = world.combat.attack_digest if world != null else ""
			var director: Node = world.runtimes[0].camera_director if world != null and not world.runtimes.is_empty() else null
			check(director != null, "spectator director is available for KIT_LOST navigation")
			if director != null:
				var resolved: Dictionary = director.resolve_event(event)
				check(not resolved.is_empty() and resolved.focus.distance_to(casualty.global_position) < 0.01, "KIT_LOST event navigation resolves to casualty location")
			check(runtime.economy.snapshot() == economy_before and runtime.armory.snapshot() == armory_before, "KIT_LOST event navigation leaves economy/equipment unchanged")
			if world != null: check(world.combat.attacks == attacks_before and world.combat.attack_digest == digest_before, "KIT_LOST event navigation leaves combat outcome unchanged")
func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM","room_conflict_c")
	OS.set_environment("ROOMSCALE_CONFLICT","1")
	OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO","three_party_conflict")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE","1")
	OS.set_environment("ROOMSCALE_MANUAL_CAMERA","1")
	var scene: Node3D = load("res://scenes/pipeline_proof.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	var world: Node = scene.get_node("WorldSimulation")
	for sim in world.runtimes: sim.set_process(false)
	for tick in range(6200):
		world.step()
		collect(world.journal, null, world)
		for sim in world.runtimes: collect(sim.journal, sim, world)
	for kind in ["SITE_TARGETED","FIRST_CONTACT","HOSTILITY_DECLARED","READINESS_TARGET","KIT_ORDERED","KIT_COMPLETED","CITIZEN_MUSTERING","MOBILIZATION_READY","FORCE_DEPLOYED","BATTLE_BEGINS","COMBAT_CASUALTY","MORALE_BREAK","RETREAT","SITE_CAPTURED","DEMOBILIZATION_STARTED","DEMOBILIZATION_COMPLETE","KIT_LOST"]:
		check(seen.has(kind),"live milestone "+kind)
	for id in ["clockwork_alpha","verdant_alpha","scavenger_alpha"]: check(societies.has(id),"society "+id)
	check(not seen.has("ABILITY_STATE"),"Prepared Fire mechanics do not enter spectator journals")
	var primary_director: Node = world.runtimes[0].camera_director
	var ability_event_keys := {}
	for event in primary_director.events():
		if event.kind == "ABILITY_STATE": ability_event_keys[event.source_key] = true
	for mode in [primary_director.PRIORITY, primary_director.RANDOM]:
		primary_director.set_mode(mode)
		for candidate in primary_director.collect_candidates():
			check(not (candidate.get("class", "") == "event" and ability_event_keys.has(candidate.get("key", ""))), "ABILITY_STATE cannot become a %s event candidate" % primary_director.mode_name())
	primary_director.set_mode(primary_director.OFF)
	var internal_ability_seen := false
	for sim in world.runtimes:
		for internal_event in sim.armory.events:
			if internal_event.kind == "ABILITY_STATE": internal_ability_seen = true
	check(internal_ability_seen,"Prepared Fire capability timing remains in internal Armory evidence")
	check(not seen.has("ATTACK"),"no attack journal spam")
	# Conditional elimination fixture after the unmodified live campaign. Uses the
	# existing damage/departure authority; no spectator-only gameplay is added.
	var eliminated := String(world.combat.winner)
	check(not eliminated.is_empty(),"live winner available for conditional elimination fixture")
	if not eliminated.is_empty():
		for citizen in world.combat.living(eliminated): citizen.suffer_combat_damage(citizen.max_health+1.0)
		world.combat.eliminate(eliminated)
		collect(world.journal, null, world)
		check(seen.has("FORCE_ELIMINATED"),"conditional force elimination milestone")
	check(lost_events_validated.size() > 0, "at least one live KIT_LOST event had factual navigation validated")
	check(world.combat.attack_digest == "c7847e27ffedeb53938fe077f4425e8468ccb1cd7cdfe82929a67ce7ecf207b2", "spectator hardening preserves accepted combat attack digest")
	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures,"kinds":seen.keys(),"societies":societies.keys(),"attack_digest":world.combat.attack_digest,"lost_events_validated":lost_events_validated.size(),"final_tick":world.tick}
	var output := OS.get_environment("ROOMSCALE_PRODUCER_RESULT")
	if not output.is_empty():
		var file := FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"\t"))
	print("ROOMSCALE_POC55_PRODUCERS_"+result.result+" "+JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
