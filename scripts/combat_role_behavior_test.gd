extends SceneTree
const Roles := preload("res://scripts/combat_roles.gd")
var failures: Array[String] = []
var assertions := 0
var observations := {}
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok and not failures.has(label): failures.append(label)

func spawn() -> Node3D:
	OS.set_environment("ROOMSCALE_ROOM","room_conflict_c")
	OS.set_environment("ROOMSCALE_CONFLICT","1")
	OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO","three_party_conflict")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE","1")
	OS.set_environment("ROOMSCALE_MANUAL_CAMERA","1")
	var scene: Node3D = load("res://scenes/pipeline_proof.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	for runtime in scene.get_node("WorldSimulation").runtimes: runtime.set_process(false)
	scene.get_node("WorldSimulation").conflict_enabled = false
	return scene

func capture(scene: Node3D, label: String, at: Vector3, distance: float) -> void:
	var directory := OS.get_environment("ROOMSCALE_VISUAL_DIR")
	if directory.is_empty(): return
	check(DisplayServer.get_name() != "headless","real renderer")
	scene.get_node("CameraRig").focus_detail_at(at+Vector3(0,0.4,0),distance,55)
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(label+".png")
	check(root.get_texture().get_image().save_png(path) == OK,"capture written")
	captures.append(path)

func movement(role: String) -> void:
	var scene := spawn()
	var world: Node = scene.get_node("WorldSimulation")
	var actor: Node3D = world.runtimes[0].citizens[0]
	var enemy: Node3D = world.runtimes[1].citizens[0]
	var center: Vector3 = world.territory.sites[world.scenario.strategic_site].position
	# Controlled V3 initial positions only. Every observed movement is CitizenAgent.
	var gap := 10.0 if role in ["line","heavy"] else (4.5 if role == "skirmisher" else 1.5)
	actor.global_position = center + Vector3(-gap,0,0)
	enemy.global_position = center
	actor.equip_combat(Roles.loadout(world.runtimes[0].definition,role))
	enemy.equip_combat(Roles.loadout(world.runtimes[1].definition,"line"))
	check(actor.assign_combat_duty("MANEUVER",actor.global_position),"fixture legal actor " + role)
	check(enemy.assign_combat_duty("MANEUVER",enemy.global_position),"fixture legal target " + role)
	var battle: RefCounted = world.combat
	battle.world = world
	battle.forces = {actor.civilization_id:[actor],enemy.civilization_id:[enemy]}
	battle.next_position[actor.citizen_id] = 0.0
	var origin: Vector3 = actor.global_position
	scene._selected_citizen = actor
	scene._inspection_label.show()
	var max_step := 0.0
	var states: Array = []
	await capture(scene,role+"-before",center,16)
	for tick in range(30):
		world.seconds += 0.1
		battle.position_combatant(actor,[enemy])
		var before: Vector3 = actor.global_position
		actor.advance_simulation(0.1)
		actor.refresh_combat_presentation(0.1)
		var distance: float = actor.global_position.distance_to(before)
		max_step = maxf(max_step,distance)
		check(distance <= actor.combat_speed()*0.1+0.00002,"role speed bound " + role)
		check(not actor.navigation.is_obstacle_position(actor.global_position),"legal movement " + role)
		if not states.has(actor.combat_state): states.append(actor.combat_state)
		if tick == 9: await capture(scene,role+"-one-second",center,16)
	var final_gap: float = actor.global_position.distance_to(enemy.global_position)
	if role in ["line","heavy"]: check(final_gap < gap and states.has("SCREEN" if role == "line" else "ASSAULT"),role+" closes")
	elif role in ["ranged","artillery"]: check(final_gap > gap+1 and states.has("WITHDRAW"),role+" restores distance")
	else: check(actor.global_position.distance_to(origin)>1 and states.has("FLANK"),"skirmisher repositions")
	check(actor.combat_inspection().contains(role) and actor.get_inspection_status().combat_stats.has("armor"),"inspection stats " + role)
	observations[role] = {"start":origin,"finish":actor.global_position,"initial_gap":gap,"final_gap":final_gap,"max_step":max_step,"states":states,"speed":actor.combat_speed()}
	await capture(scene,role+"-after",center,16)
	await capture(scene,role+"-detail",actor.global_position,2.2)
	scene.queue_free(); await process_frame

func mixed() -> void:
	var scene := spawn()
	var world: Node = scene.get_node("WorldSimulation")
	var battle: RefCounted = world.combat
	var site: String = world.scenario.strategic_site
	var ids: Array = []
	var policies := {}
	for runtime in world.runtimes:
		ids.append(runtime.instance_id)
		world.territory.claim(site,runtime.instance_id,0)
		policies[runtime.instance_id] = {"min_force":5,"max_force":5,"force_fraction":0.5,"retreat_threshold":0.4,"roles":Roles.ORDER}
	for a in ids:
		for b in ids:
			if a < b: world.territory.set_relation(a,b,"HOSTILE",0,site)
	check(battle.start(world,site,{"participants":ids,"side_policies":policies}),"all-role three-party battle starts")
	if battle.phase == "DORMANT":
		scene.queue_free(); await process_frame
		return
	var identities := {}
	for entry in battle.commitments:
		identities[entry.id] = world.runtime_for(entry.side).citizen_for(entry.id)
	check(battle.commitments.size() == 15,"fifteen real committed citizens")
	var max_step := 0.0
	var states := {}
	var fire_roles := {}
	var complete := -1
	var first_fight := -1
	for tick in range(7000):
		var positions := {}
		var speeds := {}
		for citizen in world.citizens:
			positions[citizen.citizen_id] = citizen.global_position
			speeds[citizen.citizen_id] = citizen.combat_speed()
		world.step(); battle.update()
		for citizen in world.citizens:
			var delta: float = citizen.global_position.distance_to(positions[citizen.citizen_id])
			check(delta <= float(speeds[citizen.citizen_id])*0.1+0.00003,"per-citizen role speed bound")
			max_step = maxf(max_step,delta)
			if not citizen.combat_role.is_empty():
				if not states.has(citizen.combat_role): states[citizen.combat_role] = []
				if not states[citizen.combat_role].has(citizen.combat_state): states[citizen.combat_role].append(citizen.combat_state)
			citizen.refresh_combat_presentation(0.1)
		for entry in battle.commitments:
			check(world.runtime_for(entry.side).citizen_for(entry.id) == identities[entry.id],"persistent actor identity")
		for event in battle.attack_history: fire_roles[event.role] = true
		check(world.resources.audit().is_empty(),"finite world conservation")
		for runtime in world.runtimes: check(runtime.economy.audit().is_empty(),"depot conservation")
		if battle.phase == "FIGHT" and first_fight < 0:
			first_fight = world.tick
			await capture(scene,"mixed-formed",world.territory.sites[site].position,32)
		if world.tick == first_fight+40:
			await capture(scene,"mixed-fighting",world.territory.sites[site].position,32)
		if battle.phase == "COMPLETE":
			if complete < 0: complete = world.tick
			if world.tick > complete+1500: break
		if tick % 100 == 0: await process_frame
	check(complete > 0,"mixed secure capture completes")
	check(battle.casualties.values().reduce(func(a: int,b: int) -> int: return a+b,0)>0,"real mixed casualties")
	check(battle.retreated_sides.size()+battle.eliminated_sides.size() == 2,"independent departures")
	for role in Roles.ORDER: check(fire_roles.has(role),"role attacks " + role)
	var intervals := {}
	for event in battle.attack_history:
		if intervals.has(event.attacker):
			var loadout: Dictionary = battle.commitments.filter(func(entry: Dictionary) -> bool: return entry.id == event.attacker)[0].stats
			check(event.tick-int(intervals[event.attacker]) >= roundi(loadout.interval/0.1),"role attack cycle")
		intervals[event.attacker] = event.tick
	for id in battle.forces:
		for citizen in battle.living(id):
			check(citizen.combat_duty.is_empty() and citizen.combat_role.is_empty(),"survivor sheds military role")
			check(world.runtime_for(id).coordinator.tasks.any(func(task: Dictionary) -> bool: return task.citizen_id == citizen.citizen_id and task.state == "complete" and float(task.get("claimed_sim",0)) > complete*0.1),"every survivor resumes real work")
	observations.mixed = {"commitments":battle.commitments,"attack_digest":battle.attack_digest,"attacks":battle.attacks,"casualties":battle.casualties,"winner":battle.winner,"capture":battle.site_capture_tick,"retreated":battle.retreated_sides,"eliminated":battle.eliminated_sides,"returned":battle.returned,"states":states,"fire_roles":fire_roles,"max_step":max_step}
	await capture(scene,"mixed-returned",world.territory.sites[site].position,35)
	scene.queue_free(); await process_frame

func targeting() -> void:
	var scene := spawn()
	var world: Node = scene.get_node("WorldSimulation")
	var actor: Node3D = world.runtimes[0].citizens[0]
	var friend: Node3D = world.runtimes[0].citizens[1]
	var enemy: Node3D = world.runtimes[1].citizens[0]
	var rival: Node3D = world.runtimes[1].citizens[1]
	var peaceful: Node3D = world.runtimes[2].citizens[0]
	var center: Vector3 = world.territory.sites[world.scenario.strategic_site].position
	actor.global_position = center
	friend.global_position = center+Vector3(-2,0,0)
	enemy.global_position = center+Vector3(2,0,0)
	rival.global_position = center+Vector3(-4,0,0)
	peaceful.global_position = center+Vector3(0,0,1)
	actor.equip_combat(Roles.loadout(world.runtimes[0].definition,"line"))
	friend.equip_combat(Roles.loadout(world.runtimes[0].definition,"artillery"))
	enemy.equip_combat(Roles.loadout(world.runtimes[1].definition,"heavy"))
	rival.equip_combat(Roles.loadout(world.runtimes[1].definition,"ranged"))
	peaceful.equip_combat(Roles.loadout(world.runtimes[2].definition,"skirmisher"))
	var battle: RefCounted = world.combat
	battle.world = world
	battle.forces = {actor.civilization_id:[actor,friend],enemy.civilization_id:[enemy,rival],peaceful.civilization_id:[peaceful]}
	world.territory.set_relation(actor.civilization_id,enemy.civilization_id,"HOSTILE",0,world.scenario.strategic_site)
	check(battle.targets_for(actor)[0] == rival,"Line prioritizes rear threat over nearer Heavy")
	check(not battle.targets_for(actor).has(peaceful),"peaceful citizen excluded")
	actor.equip_combat(Roles.loadout(world.runtimes[0].definition,"skirmisher"))
	check(battle.targets_for(actor)[0] == rival,"Skirmisher chooses vulnerable target")
	actor.equip_combat(Roles.loadout(world.runtimes[0].definition,"ranged"))
	rival.global_position = center+Vector3(-2,0,0)
	check(battle.targets_for(actor)[0] == (enemy if enemy.citizen_id < rival.citizen_id else rival),"equal target distances break by citizen ID")
	rival.global_position = center+Vector3(-10,0,0)
	check(battle.targets_for(actor)[0] == enemy,"Ranged prefers in-range target")
	var nav: Node = actor.navigation
	check(nav.combat_path_between(center,center+Vector3(10000,0,0)).is_empty(),"tactical endpoint outside room rejected")
	check(nav.combat_path_between(center,center+Vector3(0,4,0)).is_empty(),"tactical elevated endpoint rejected")
	for rect in nav.obstacle_rects:
		var blocked := Vector3(rect.center.x,0,rect.center.y)
		check(nav.combat_path_between(center,blocked).is_empty(),"blocked combat endpoint rejected")
	scene.queue_free(); await process_frame

func grades() -> void:
	var scene := spawn()
	var world: Node = scene.get_node("WorldSimulation")
	var index := 0
	var results := {}
	for role in Roles.ORDER:
		var previous := 0.0
		results[role] = []
		for grade in ["Bad","Neutral","Good","Great"]:
			var definition: Dictionary = world.runtimes[0].definition.duplicate(true)
			definition.combat.roles[role].grade = grade
			var stats := Roles.loadout(definition,role)
			var victim: Node3D = world.citizens[index]
			index += 1
			var damage := 0.0
			var effect := 0.0
			if role in ["line","heavy"]:
				victim.equip_combat(stats)
				damage = Roles.damage(14,float(stats.armor))
				effect = victim.health / damage
			else:
				victim.equip_combat(Roles.loadout(world.runtimes[1].definition,"heavy"))
				damage = Roles.damage(float(stats.damage),float(victim.combat_stats.armor))
				effect = damage / float(stats.interval)
			var hits := 0
			while victim.life_state == "ALIVE" and hits < 300:
				victim.suffer_combat_damage(damage)
				hits += 1
			check(victim.life_state == "DEAD" and victim.health == 0 and victim.task_id == -1,"graded assay real citizen mortality")
			check(effect > previous,"strict real armor/health/damage performance ordering " + role)
			previous = effect
			results[role].append({"grade":grade,"damage_taken":damage,"hits_to_death":hits,"effectiveness":effect})
	observations.grades = results
	scene.queue_free(); await process_frame

func run() -> void:
	await targeting()
	await grades()
	for role in Roles.ORDER: await movement(role)
	check(observations.heavy.max_step < observations.line.max_step and observations.skirmisher.max_step > observations.line.max_step,"relative role speeds observed")
	await mixed()
	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures,"assertions":assertions,"observations":observations}
	var output := OS.get_environment("ROOMSCALE_FOCUSED_RESULT")
	if not output.is_empty():
		var file := FileAccess.open(output,FileAccess.WRITE); file.store_string(JSON.stringify(result,"  ")); file.close()
	print("ROOMSCALE_ROLE_BEHAVIOR_"+result.result+" "+JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
