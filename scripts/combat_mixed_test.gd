extends SceneTree
const Pressure := preload("res://scripts/conflict_pressure_system.gd")
const Battle := preload("res://scripts/combat_system.gd")
var failures: Array[String] = []
var assertions := 0

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: push_error("ROOMSCALE_MIXED_COMBAT_FAIL watchdog"); quit(1))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	assertions += 1
	if not value and not failures.has(label): failures.append(label)

func pair(a: String,b: String,intensity: int) -> Dictionary:
	return {"participants":[a,b],"intensity":intensity,"cause":"SPACE","objective":"SECURE_TERRITORY"}

func spawn() -> Array:
	OS.set_environment("ROOMSCALE_ROOM","room_conflict_mixed"); OS.set_environment("ROOMSCALE_CONFLICT","1"); OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO","mixed_intensity_conflict"); OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE","1"); OS.set_environment("ROOMSCALE_MANUAL_CAMERA","1")
	var scene: Node3D = load("res://scenes/pipeline_proof.tscn").instantiate(); root.add_child(scene); current_scene = scene
	var world: Node = scene.get_node("WorldSimulation")
	for runtime in world.runtimes: runtime.set_process(false)
	return [scene,world]

func exercise(reverse: bool) -> Dictionary:
	var fixture := spawn(); var scene: Node3D = fixture[0]; var world: Node = fixture[1]
	var ids := ["clockwork_alpha","verdant_alpha","scavenger_alpha"]
	var pairs := [pair(ids[0],ids[1],Pressure.SURVIVAL_WAR),pair(ids[1],ids[2],Pressure.LIMITED_WAR),pair(ids[0],ids[2],Pressure.PEACE)]
	var own := Pressure.commitment_policies(pairs,ids)
	check(own[ids[0]].force_fraction == 1 and not own[ids[0]].allow_retreat,"survival participant receives survival policy")
	check(own[ids[1]].force_fraction == 1 and not own[ids[1]].allow_retreat,"society with two wars uses strongest personally involved intensity")
	check(own[ids[2]].force_fraction == 0.25 and own[ids[2]].allow_retreat,"limited side does not inherit survival commitment or retreat rules")
	var reordered := pairs.duplicate(true); reordered.reverse(); var reversed_ids := ids.duplicate(); reversed_ids.reverse()
	check(Pressure.commitment_policies(reordered,reversed_ids) == own,"bilateral input order cannot change policy derivation")
	var uniform := Pressure.commitment_policies([pair(ids[0],ids[1],2),pair(ids[1],ids[2],2),pair(ids[0],ids[2],2)],ids)
	check(uniform.values().all(func(policy: Dictionary) -> bool: return policy.force_fraction == 0.25 and policy.allow_retreat),"same-intensity three parties retain limited policies")
	check(Pressure.commitment_policies([pair(ids[0],ids[1],2),pair(ids[1],ids[2],0),pair(ids[0],ids[2],0)],ids).size() == 2,"peaceful third claimant has no commitment policy")
	var site: String = world.scenario.strategic_site
	# Initial contested-claim fixture; no actors, health, supplies, work or links
	# are changed. All commitment, travel, attacks and withdrawals are production.
	for id in ids: world.territory.claim(site,id,0)
	for relation in pairs: world.territory.set_relation(relation.participants[0],relation.participants[1],"HOSTILE" if relation.intensity >= 2 else "CONTACT",0,site)
	var actor_tasks := {}
	for citizen in world.citizens: actor_tasks[citizen.citizen_id] = citizen.task_id
	var rejected := Battle.new(); var unavailable: Dictionary = own.duplicate(true)
	unavailable[ids[2]].min_force = 150; unavailable[ids[2]].max_force = 150
	check(not rejected.start(world,site,{"participants":ids,"side_policies":unavailable}),"one unavailable side rejects the whole engagement")
	check(rejected.world == null and rejected.forces.is_empty() and rejected.side_policies.is_empty(),"rejected force leaves no partial battle authority")
	for citizen in world.citizens: check(citizen.task_id == actor_tasks[citizen.citizen_id] and citizen.combat_duty.is_empty(),"rejected force preserves ordinary tasks")
	world.conflict_enabled = false # Drive the normal orchestration explicitly per fixed tick below.
	if reverse: world.runtimes.reverse(); ids.reverse()
	world.advance_conflict()
	check(world.combat.phase == "MARCH", "mixed physical engagement starts from actual bilateral pressure")
	check(world.conflict_state.pairs.size() == 3, "all actual pair pressures evaluated")
	check(world.combat.side_policies["scavenger_alpha"].intensity_name == "LIMITED_WAR", "world orchestration preserves the limited side policy")
	check(world.combat.initial_sizes["clockwork_alpha"] == 4 and world.combat.initial_sizes["verdant_alpha"] == 12 and world.combat.initial_sizes["scavenger_alpha"] == 2,"force counts use per-society policies")
	world.combat.retreat("clockwork_alpha")
	world.combat.eliminate("clockwork_alpha")
	check(world.combat.phase == "MARCH" and world.combat.retreated_sides.is_empty() and world.combat.eliminated_sides.is_empty(),"public transitions reject survival retreat and elimination of living forces")
	var limited_retreat := false
	var max_step := 0.0
	var observed_retreats := {}
	var elimination_events := {}
	var retreat_events := {}
	var continued_after_departure := false
	for tick in range(5000):
		var positions := {}
		var speeds := {}
		for citizen in world.citizens:
			positions[citizen.citizen_id] = citizen.global_position
			speeds[citizen.citizen_id] = citizen.combat_speed()
		world.step(); world.advance_conflict(); world.combat.update()
		for citizen in world.citizens:
			var moved: float = citizen.global_position.distance_to(positions[citizen.citizen_id])
			max_step = maxf(max_step,moved)
			check(moved <= float(speeds[citizen.citizen_id])*0.1+0.00003,"each citizen respects assigned role speed")
		for id in world.combat.retreated_sides:
			if observed_retreats.has(id): continue
			observed_retreats[id] = world.combat.living(id).size()
			if id == "scavenger_alpha": limited_retreat = world.combat.living(id).size() > 0
			else: check(false,"survival side does not make ordinary morale retreat")
		for event in world.journal.events:
			if event.kind == "FORCE_ELIMINATED": elimination_events[event.evidence.instance_id] = event
			elif event.kind == "RETREAT": retreat_events[event.evidence.instance_id] = event
		if (not world.combat.eliminated_sides.is_empty() or not world.combat.retreated_sides.is_empty()) and world.combat.phase == "FIGHT": continued_after_departure = true
		check(not world.combat.attack_pairs.has(world.territory.relation_key("clockwork_alpha","scavenger_alpha")),"peaceful pair never attacks")
		check(world.resources.audit().is_empty(),"mixed battle finite world conservation")
		for runtime in world.runtimes: check(runtime.economy.audit().is_empty(),"mixed battle depot conservation")
		if limited_retreat and world.combat.phase in ["RETREAT","SECURE","COMPLETE","STAND_DOWN"]: break
		if tick % 100 == 0: await process_frame
	check(limited_retreat,"limited side physically retreats with survivors beside non-retreating survival sides")
	check(world.combat.eliminated_sides.has("clockwork_alpha") and world.combat.living("clockwork_alpha").is_empty(),"annihilated survival force is eliminated")
	var event_count: int = world.journal.sequence
	world.combat.retreat("clockwork_alpha"); world.combat.eliminate("clockwork_alpha")
	check(world.journal.sequence == event_count,"elimination is idempotent and cannot turn into a retreat")
	check(not world.combat.retreated_sides.has("clockwork_alpha") and not retreat_events.has("clockwork_alpha"),"survival force never produces ordinary retreat state or event")
	check(world.combat.retreated_sides.has("scavenger_alpha") and not world.combat.eliminated_sides.has("scavenger_alpha"),"surviving limited force is retreated rather than eliminated")
	check(retreat_events.has("scavenger_alpha") and retreat_events.scavenger_alpha.evidence.survivors == 1,"limited withdrawal event records a living survivor")
	check(continued_after_departure,"remaining hostile pair continues fighting after first departure")
	check(world.combat.winner == "verdant_alpha", "winner resolves after elimination and survivor retreat")
	check(elimination_events.has("clockwork_alpha"),"distinct elimination journal event emitted")
	if elimination_events.has("clockwork_alpha"):
		var event: Dictionary = elimination_events.clockwork_alpha
		check(not "morale broke" in event.message and not "returning" in event.message,"elimination event makes no morale or homecoming claim")
		check(event.evidence.casualties == 4 and event.evidence.initial_committed_force == 4 and event.evidence.intensity == "SURVIVAL_WAR" and event.evidence.cause == "SPACE" and event.evidence.objective == "REMOVE_EXISTENTIAL_BLOCKER" and event.evidence.tick == world.combat.eliminated_sides.clockwork_alpha and event.seconds > 0,"elimination event includes force policy casualties and fixed clock")
		check(world.combat.forces.clockwork_alpha.all(func(c: Node3D) -> bool: return c.combat_duty.is_empty()),"eliminated citizens have no retreat duty")
	check(max_step <= 0.87753 and world.combat.attacks > 0,"mixed engagement uses physical movement and real attacks")
	for citizen in world.citizens:
		if citizen.life_state == "DEAD": check(citizen.health == 0 and citizen.task_id == -1 and citizen.state == "DEAD","casualties remain terminal")
	# Even a previously committed side's peaceful claim is not surrendered to
	# a winner it never fought. Probe the actual secure predicate without capture.
	if not world.combat.winner.is_empty():
		world.territory.set_relation(world.combat.winner,"scavenger_alpha","CONTACT",world.seconds,site)
		check(not world.combat._rivals_withdrawn(world.territory.sites[site].position),"peaceful surviving claimant prevents exclusive military capture")
	var result := {"initial_sizes":world.combat.initial_sizes,"side_policies":world.combat.side_policies,"attacks":world.combat.attacks,"attack_pairs":world.combat.attack_pairs,"casualties":world.combat.casualties,"eliminated_sides":world.combat.eliminated_sides,"retreated_sides":world.combat.retreated_sides,"survivors_at_retreat":observed_retreats,"elimination_events":elimination_events,"retreat_events":retreat_events,"winner":world.combat.winner,"tick":world.tick,"max_step":max_step}
	# Continue ordinary movement through withdrawal and secure. The peaceful
	# survivor must reach home while its claim still prevents exclusive capture.
	for tick in range(1000):
		world.step(); world.combat.update()
		for citizen in world.citizens:
			if citizen.life_state == "DEAD": check(citizen.health == 0 and citizen.task_id == -1 and citizen.state == "DEAD" and citizen.combat_duty.is_empty(),"dead citizens stay terminal after elimination")
		if world.combat.returned.scavenger_alpha == 1: break
		if tick % 100 == 0: await process_frame
	check(world.combat.returned.scavenger_alpha == 1,"limited survivor physically returns home")
	check(world.combat.phase in ["RETREAT", "SECURE"] and world.combat.site_capture_tick == -1 and world.territory.sites[site].owner_civilization_id.is_empty(),"living peaceful claimant blocks capture after physical withdrawal")
	world.territory.set_relation(world.combat.winner,"scavenger_alpha","HOSTILE",world.seconds,site)
	check(world.combat._rivals_withdrawn(world.territory.sites[site].position),"eliminated force cannot block securing against hostile withdrawn rivals")
	scene.queue_free(); await process_frame
	return result

func elimination_resolution(reverse: bool) -> Dictionary:
	var fixture := spawn(); var scene: Node3D = fixture[0]; var world: Node = fixture[1]
	world.conflict_enabled = false
	var ids := ["clockwork_alpha", "verdant_alpha"]
	var site: String = world.scenario.strategic_site
	for id in ids: world.territory.claim(site,id,0)
	world.territory.set_relation(ids[0],ids[1],"HOSTILE",0,site)
	var own := Pressure.commitment_policies([pair(ids[0],ids[1],Pressure.SURVIVAL_WAR)],ids)
	if reverse: ids.reverse(); world.runtimes.reverse()
	check(world.combat.start(world,site,{"participants":ids,"side_policies":own}),"survival-only physical engagement starts")
	for tick in range(5000):
		world.step(); world.combat.update()
		if world.combat.phase == "COMPLETE": break
		if tick % 100 == 0: await process_frame
	check(world.combat.eliminated_sides.size() == 1 and world.combat.retreated_sides.is_empty(),"last rival eliminated with no ordinary withdrawals")
	check(world.combat.phase == "COMPLETE" and not world.combat.winner.is_empty() and world.combat.site_capture_tick > 0,"last elimination permits physical secure hold and capture")
	check(world.combat.retreating_side.is_empty() and world.combat.retreat_tick == -1,"elimination-only victory leaves retreat metadata unset")
	check(world.territory.sites[site].owner_civilization_id == world.combat.winner,"surviving force owns captured site")
	var result := {"eliminated_sides":world.combat.eliminated_sides,"retreated_sides":world.combat.retreated_sides,"winner":world.combat.winner,"site_capture_tick":world.combat.site_capture_tick,"casualties":world.combat.casualties,"attacks":world.combat.attacks}
	scene.queue_free(); await process_frame
	return result

func three_survival() -> Dictionary:
	var fixture := spawn(); var scene: Node3D = fixture[0]; var world: Node = fixture[1]
	world.conflict_enabled = false
	var ids := ["clockwork_alpha","verdant_alpha","scavenger_alpha"]
	var site: String = world.scenario.strategic_site
	var policies := {}
	for index in ids.size():
		world.territory.claim(site,ids[index],0)
		policies[ids[index]] = {"force_fraction":1.0,"min_force":2,"max_force":2+index*2,"allow_retreat":false,"retreat_threshold":-1.0}
	for a in ids:
		for b in ids:
			if a < b: world.territory.set_relation(a,b,"HOSTILE",0,site)
	check(world.combat.start(world,site,{"participants":ids,"side_policies":policies}),"three survival forces start")
	var continued := false
	var attacks_at_elimination := -1
	for tick in range(6000):
		world.step(); world.combat.update()
		if world.combat.eliminated_sides.size() == 1:
			if attacks_at_elimination < 0: attacks_at_elimination = world.combat.attacks
			elif world.combat.attacks > attacks_at_elimination and world.combat.phase == "FIGHT": continued = true
		if world.combat.phase == "COMPLETE": break
		if tick % 100 == 0: await process_frame
	check(continued,"remaining pair actually attacks after first elimination")
	check(world.combat.eliminated_sides.size() == 2 and world.combat.retreated_sides.is_empty(),"three survival sides resolve through two distinct eliminations")
	check(world.combat.phase == "COMPLETE" and world.combat.site_capture_tick > 0,"three survival winner legitimately captures")
	var result := {"attacks":world.combat.attacks,"eliminated":world.combat.eliminated_sides,"winner":world.combat.winner,"capture":world.combat.site_capture_tick}
	scene.queue_free(); await process_frame
	return result

func run() -> void:
	var first: Dictionary = await exercise(false)
	var reversed: Dictionary = await exercise(true)
	check(first == reversed,"participant/runtime ordering yields identical physical mixed engagement")
	var elimination_only: Dictionary = await elimination_resolution(false)
	check(elimination_only == await elimination_resolution(true),"elimination-only secure/capture is deterministic under reversed participant order")
	var three: Dictionary = await three_survival()
	var receipt := {"three_survival":three,"result":"PASS" if failures.is_empty() else "FAIL","assertions":assertions,"failures":failures,"engagement":first,"elimination_only":elimination_only}
	var path := OS.get_environment("ROOMSCALE_FOCUSED_RESULT")
	if not path.is_empty(): var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(receipt,"  ")); file.flush(); file.close()
	print("ROOMSCALE_MIXED_COMBAT_"+receipt.result+" "+JSON.stringify(receipt)); quit(0 if failures.is_empty() else 1)
