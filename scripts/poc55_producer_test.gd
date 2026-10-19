extends SceneTree
## Production-scene evidence, including society journals before bounded history evicts them.
var failures: Array[String] = []
var seen := {}
var societies := {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok and not failures.has(label): failures.append(label)
func collect(journal: RefCounted) -> void:
	for event in journal.events:
		seen[event.kind] = true
		check(journal.validate(event).is_empty(),"valid event schema")
		check(not event.story_key.is_empty(),"stable story grouping")
		if not event.society_id.is_empty(): societies[event.society_id] = true
		if event.kind in ["BATTLE_BEGINS","COMBAT_CASUALTY","RETREAT","SITE_CAPTURED"]:
			check(not event.site_id.is_empty() and not event.conflict_id.is_empty(),"military conflict identity")
		if event.kind == "COMBAT_CASUALTY": check(event.subject_type == "citizen" and not event.subject_id.is_empty(),"casualty subject identity")
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
		collect(world.journal)
		for sim in world.runtimes: collect(sim.journal)
	for kind in ["SITE_TARGETED","FIRST_CONTACT","HOSTILITY_DECLARED","READINESS_TARGET","KIT_ORDERED","KIT_COMPLETED","CITIZEN_MUSTERING","MOBILIZATION_READY","FORCE_DEPLOYED","BATTLE_BEGINS","COMBAT_CASUALTY","MORALE_BREAK","RETREAT","SITE_CAPTURED","DEMOBILIZATION_STARTED","DEMOBILIZATION_COMPLETE","KIT_LOST"]:
		check(seen.has(kind),"live milestone "+kind)
	for id in ["clockwork_alpha","verdant_alpha","scavenger_alpha"]: check(societies.has(id),"society "+id)
	check(not seen.has("ATTACK"),"no attack journal spam")
	# Conditional elimination fixture after the unmodified live campaign. Uses the
	# existing damage/departure authority; no spectator-only gameplay is added.
	var eliminated := String(world.combat.winner)
	check(not eliminated.is_empty(),"live winner available for conditional elimination fixture")
	if not eliminated.is_empty():
		for citizen in world.combat.living(eliminated): citizen.suffer_combat_damage(citizen.max_health+1.0)
		world.combat.eliminate(eliminated)
		collect(world.journal)
		check(seen.has("FORCE_ELIMINATED"),"conditional force elimination milestone")
	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures,"kinds":seen.keys(),"societies":societies.keys(),"attack_digest":world.combat.attack_digest,"final_tick":world.tick}
	var output := OS.get_environment("ROOMSCALE_PRODUCER_RESULT")
	if not output.is_empty():
		var file := FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"\t"))
	print("ROOMSCALE_POC55_PRODUCERS_"+result.result+" "+JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
