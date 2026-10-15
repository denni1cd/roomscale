extends SceneTree
const Catalog := preload("res://scripts/military_catalog.gd")
const Abilities := preload("res://scripts/military_abilities.gd")
var failures: Array = []
var evidence := {}
class MusterBlockedNavigation extends Node:
	var delegate: Node
	var depot := Vector3.ZERO
	var _floor_height := 0.0
	func path_between(start: Vector3,finish: Vector3) -> Array[Vector3]:
		if finish.is_equal_approx(depot): return []
		return delegate.path_between(start,finish)
func check(ok: bool,label: String) -> void:
	if not ok and not failures.has(label): failures.append(label)
func _initialize() -> void: call_deferred("run")
func spawn() -> Node3D:
	OS.set_environment("ROOMSCALE_ROOM","room_conflict_c"); OS.set_environment("ROOMSCALE_CONFLICT","1"); OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO","three_party_conflict"); OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE","1"); OS.set_environment("ROOMSCALE_MANUAL_CAMERA","1")
	var scene: Node3D = load("res://scenes/pipeline_proof.tscn").instantiate(); root.add_child(scene); current_scene = scene
	var world: Node = scene.get_node("WorldSimulation"); world.conflict_enabled = false
	for sim in world.runtimes: sim.set_process(false); sim.governor.enabled = false
	return scene

func capture(scene: Node3D,label: String,at: Vector3,distance: float = 22) -> void:
	var directory := OS.get_environment("ROOMSCALE_VISUAL_DIR")
	if directory.is_empty(): return
	check(DisplayServer.get_name() != "headless","real graphical ability evidence")
	scene.get_node("CameraRig").focus_detail_at(at+Vector3(0,0.3,0),distance,55)
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	check(root.get_texture().get_image().save_png(directory.path_join(label+".png")) == OK,"ability capture written")

func scarcity() -> void:
	var scene := spawn(); var world: Node = scene.get_node("WorldSimulation")
	var trials: Array = []
	for runtime in world.runtimes:
		for metal in [3,2]:
			runtime.economy = preload("res://scripts/economy_system.gd").new(); runtime.economy.instance_id = runtime.instance_id; runtime.economy.configure({"food":5000,"water":5000,"wood":3,"metal":metal})
			runtime.armory = preload("res://scripts/armory_system.gd").new(); runtime.armory.configure(runtime)
			var allowed: bool = runtime.armory.order("heavy")
			var jury: bool = Catalog.has(runtime,"JURY_RIG_EQUIPMENT")
			check(allowed == (metal == 3 or jury),"metal scarcity blocks standard factions")
			if allowed:
				var p: Dictionary = runtime.armory.projects.values()[0]
				check(p.variant == ("jury_rigged" if metal == 2 else "normal"),"normal recipe first")
				check(p.cost == ({"wood":3,"metal":2} if metal == 2 else {"wood":1,"metal":3}) and p.required_work == (15.0 if metal == 2 else 12.0),"exact heavy fallback")
				trials.append(p.duplicate(true))
			check(runtime.economy.audit().is_empty(),"scarcity exact tickets")
	var sim: Node = world.runtimes[0]
	sim.definition = sim.definition.duplicate(true); sim.definition.id = "synthetic_society"; sim.definition.combat.capabilities = ["JURY_RIG_EQUIPMENT"]
	sim.economy = preload("res://scripts/economy_system.gd").new(); sim.economy.configure({"wood":3,"metal":0,"food":100,"water":100})
	sim.armory = preload("res://scripts/armory_system.gd").new(); sim.armory.configure(sim)
	check(sim.armory.order("ranged"),"synthetic society receives generic jury-rig behavior")
	var project: Dictionary = sim.armory.projects.values()[0]
	check(project.cost == {"wood":3,"metal":0} and project.required_work == 10.0,"exact ranged fallback")
	evidence.scarcity = trials
	# Existing innovation capability authority, no new technology authoring.
	sim.definition.combat.roles.heavy["requires"] = ["STEAM_POWER"]
	check(not Catalog.permitted(sim,"heavy"),"missing role gate blocks")
	check(not sim.military.profile().has("heavy"),"doctrine excludes unavailable role")
	sim.innovation.resolver = preload("res://scripts/innovation_system.gd").create("clockwork",["STEAM_POWER"]).system
	check(Catalog.permitted(sim,"heavy"),"existing learned capability unlocks role")
	var gated: Dictionary = Catalog.EQUIPMENT.ranged_kit.duplicate(true); gated.requires = ["POWER_SOURCE"]
	check(Catalog.permitted(sim,"ranged",gated),"capability implication unlocks equipment")
	scene.queue_free(); await process_frame

func prepared() -> void:
	var scene := spawn(); var world: Node = scene.get_node("WorldSimulation")
	var sim: Node = world.runtimes[0]; var citizen: Node3D = sim.citizens[0]
	# Authored initially issued fixture; live acceptance separately manufactures kits.
	citizen.combat_kit = "prepared-fixture"
	var rows: Array = []
	for role in ["ranged","artillery"]:
		citizen.equip_combat(Catalog.Roles.loadout(sim.definition,role))
		var stats: Dictionary = citizen.combat_stats.duplicate(true)
		citizen.preparation_initialized = false; citizen.prepared = false
		Abilities.update(citizen,0)
		Abilities.update(citizen,1.9); check(not citizen.prepared,"preparation requires full two seconds")
		Abilities.update(citizen,2.0); check(citizen.prepared,"preparation at exactly two seconds")
		check(is_equal_approx(Abilities.interval(citizen),float(stats.interval)*0.85),"exact prepared interval")
		citizen.position.x += 0.25; Abilities.update(citizen,2.1); check(citizen.prepared,"anchor tolerance inclusive")
		citizen.position.x += 0.01; Abilities.update(citizen,2.2); check(not citizen.prepared,"movement immediately clears prepared")
		Abilities.update(citizen,4.2); check(citizen.prepared,"stationary re-preparation")
		check(citizen.combat_stats == stats,"no other stats changed")
		rows.append({"role":role,"base":stats.interval,"prepared":Abilities.interval(citizen)})
	# Ability is attached to capability, independent of definition identity.
	sim.definition = sim.definition.duplicate(true); sim.definition.id = "synthetic_society"
	Abilities.update(citizen,4.3); check(citizen.prepared,"synthetic prepared-fire capability")
	evidence.prepared = rows
	scene.queue_free(); await process_frame

func pathfinder() -> void:
	var scene := spawn(); var world: Node = scene.get_node("WorldSimulation")
	var sim: Node = world.runtime_for("verdant_alpha"); var citizen: Node3D = sim.citizens[0]
	var proved := false
	for rect in citizen.navigation.obstacle_rects:
		var origin := Vector3(rect.center.x-rect.half.x-2,0,rect.center.y)
		if not citizen.navigation.room_bounds().has_point(Vector2(origin.x,origin.z)) or citizen.navigation.is_obstacle_position(origin): continue
		citizen.global_position = origin
		var desired := Vector3(rect.center.x+rect.half.x+2,0,rect.center.y)
		var choice := Abilities.endpoint(citizen,desired)
		if choice.is_empty(): continue
		check(choice.angle in [0,30,-30,60,-60,90,-90],"exact pathfinder candidate set")
		var minimum := INF; var best_angle := 0
		for angle in [0,30,-30,60,-60,90,-90]:
			var target := origin+(desired-origin).rotated(Vector3.UP,deg_to_rad(float(angle)))
			var route: Array[Vector3] = citizen.navigation.combat_path_between(origin,target)
			if route.is_empty(): continue
			var length := 0.0; var previous := origin
			for point in route: length += previous.distance_to(point); previous = point
			if length < minimum: minimum = length; best_angle = angle
		check(choice.angle == best_angle and choice.length == minimum,"shortest real route, exact-order ties")
		check(not citizen.navigation.is_obstacle_position(choice.target),"obstacle legality retained")
		var speed: float = citizen.combat_speed()
		sim.definition = sim.definition.duplicate(true); sim.definition.combat.capabilities = []
		var normal := Abilities.endpoint(citizen,desired)
		check(normal.is_empty() or normal.angle in [0,45,-45],"baseline candidate behavior preserved")
		check(not normal.is_empty() and choice.length < normal.length,"Pathfinder improves real route length in clutter")
		sim.definition.combat.capabilities = ["PATHFINDER_MANEUVERS"]; sim.definition.id = "synthetic_society"
		check(Abilities.endpoint(citizen,desired) == choice and citizen.combat_speed() == speed,"synthetic pathfinder, unchanged speed")
		citizen.equip_combat(Catalog.Roles.loadout(sim.definition,"skirmisher"))
		scene._selected_citizen = citizen; scene._inspection_label.show()
		check(citizen.assign_combat_duty("MANEUVER",choice.target),"pathfinder accepted real route")
		var route: Array[Vector3] = citizen.navigation.combat_path_between(origin,choice.target)
		for point in [origin]+route:
			preload("res://scripts/visuals/visual_geometry.gd").box(scene,"LegalRouteMarker",Vector3(0.5,0.06,0.5),point+Vector3(0,0.04,0),"paint",Color("38dce6"),0.01)
		var route_points: Array = [origin]+route
		for index in range(1,route_points.size()):
			var start: Vector3 = route_points[index-1]; var finish: Vector3 = route_points[index]
			var segment: Node3D = preload("res://scripts/visuals/visual_geometry.gd").box(scene,"LegalRouteSegment",Vector3(0.25,0.06,start.distance_to(finish)),(start+finish)/2+Vector3(0,0.06,0),"paint",Color("38dce6"),0.01)
			segment.rotation.y = atan2(finish.x-start.x,finish.z-start.z)
		var explanation := Label.new(); explanation.position = Vector2(20,20); explanation.add_theme_font_size_override("font_size",20); explanation.add_theme_color_override("font_color",Color.BLACK)
		explanation.text = "PATHFINDER: %s degrees / %.2f inches legal route\nDirect route crosses the blocked workbench footprint.\nCyan line: real navigation route; motion: 8.775 in/s." % [choice.angle,choice.length]
		scene.get_node("Overlay").add_child(explanation)
		var label := Label3D.new(); label.text = "PATHFINDER %s deg / %.2f in legal route" % [choice.angle,choice.length]; label.position = origin+Vector3(0,2,0); label.font_size = 28; label.pixel_size = 0.02; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; scene.add_child(label)
		var overview: Vector3 = (origin+Vector3(choice.target))/2
		await capture(scene,"pathfinder-before",overview,70)
		for tick in range(300):
			var before: Vector3 = citizen.global_position
			citizen.advance_simulation(0.1); citizen.refresh_combat_presentation(0.1)
			check(citizen.global_position.distance_to(before)<=0.87753 and not citizen.navigation.is_obstacle_position(citizen.global_position),"pathfinder real movement legal and speed bounded")
			if citizen.combat_arrived: break
		check(citizen.combat_arrived,"pathfinder physically reaches selected legal endpoint")
		await capture(scene,"pathfinder-after",overview,70)
		evidence.pathfinder = {"origin":origin,"desired":desired,"selected":choice,"baseline":normal,"speed":speed}
		proved = true; break
	check(proved,"actual cluttered-room fixture found")
	scene.queue_free(); await process_frame

func muster_cancel() -> void:
	var scene := spawn(); var world: Node = scene.get_node("WorldSimulation")
	var sim: Node = world.runtimes[0]
	# Prepared stock only; manufacture is exercised in armory/live suites.
	for role in ["line","ranged"]:
		var id := "%s:kit:%d" % [sim.instance_id,sim.armory._next_kit]; sim.armory._next_kit += 1
		sim.armory.kits[id] = {"id":id,"equipment_id":role+"_kit","role":role,"owner":sim.instance_id,"variant":"normal","state":"STOCKED","citizen_id":-1}
	var at: Vector3 = world.territory.sites[world.scenario.strategic_site].position
	var ranked: Array = sim.citizens.filter(func(c: Node3D) -> bool: return c.eligible_for_combat(at))
	ranked.sort_custom(func(a: Node3D,b: Node3D) -> bool:
		var da := a.global_position.distance_squared_to(at); var db := b.global_position.distance_squared_to(at)
		return da < db if da != db else a.citizen_id < b.citizen_id)
	var excluded: Node3D = ranked[0]
	var original_navigation: Node = excluded.navigation
	var blocked_navigation := MusterBlockedNavigation.new()
	blocked_navigation.delegate = original_navigation; blocked_navigation.depot = sim.coordinator.depot_station
	root.add_child(blocked_navigation); excluded.navigation = blocked_navigation
	var excluded_task: int = excluded.task_id
	sim.military.authorize({"min_force":2,"max_force":3,"force_fraction":0.25},at)
	sim.military.update()
	check(not sim.military.members.any(func(m: Dictionary) -> bool: return m.citizen == excluded) and excluded.task_id == excluded_task,"unreachable muster candidate replaced without mutation")
	excluded.navigation = original_navigation; blocked_navigation.queue_free()
	check(sim.military.state == "MUSTERING" and sim.military.members.size() == 2,"physical muster starts")
	check(sim.armory.kits.values().all(func(k: Dictionary) -> bool: return k.state == "RESERVED"),"reserve before issue")
	for member in sim.military.members: check(not sim.armory.issue(member.kit,member.citizen),"remote issue refused")
	var max_step := 0.0
	for tick in range(1000):
		var positions := {}; for c in sim.citizens: positions[c.citizen_id] = c.global_position
		world.step()
		for c in sim.citizens: max_step = maxf(max_step,c.global_position.distance_to(positions[c.citizen_id]))
		if sim.military.state == "READY": break
	check(sim.military.state == "READY","all accepted members physically issue before ready")
	check(max_step <= 0.65003,"muster production speed bound")
	var survivor: Node3D = sim.military.members[0].citizen
	survivor.suffer_combat_damage(7)
	var health_fraction: float = survivor.health/survivor.max_health
	var ids: Array = sim.armory.kits.keys()
	sim.military.cancel()
	for tick in range(100): world.step()
	check(is_equal_approx(survivor.health/survivor.max_health,health_fraction),"demobilization preserves health fraction")
	check(sim.military.state == "PEACE" and sim.armory.kits.values().all(func(k: Dictionary) -> bool: return k.state == "STOCKED"),"cancelled equipped muster returns assets physically")
	# Reuse also accepts the finished state left by a completed battle.
	sim.military.state = "COMPLETE"
	sim.military.authorize({"min_force":2,"max_force":3,"force_fraction":0.25},at)
	for tick in range(1000):
		world.step()
		if sim.military.state == "READY": break
	check(sim.military.state == "READY" and sim.armory.kits.keys() == ids,"persistent kits reused on later mobilization")
	sim.military.cancel(); for tick in range(100): world.step()
	evidence.muster = {"kits":sim.armory.kits,"events":sim.armory.events,"max_step":max_step}
	scene.queue_free(); await process_frame

func prepared_attacks(role: String) -> void:
	var scene := spawn(); var world: Node = scene.get_node("WorldSimulation")
	var ids := ["clockwork_alpha","verdant_alpha"]
	var policies := {}
	for id in ids:
		world.territory.claim(world.scenario.strategic_site,id,0)
		policies[id] = {"min_force":1,"max_force":1,"allow_retreat":false,"retreat_threshold":0,"roles":[role if id == ids[0] else "heavy"]}
	world.territory.set_relation(ids[0],ids[1],"HOSTILE",0,world.scenario.strategic_site)
	preload("res://scripts/verification/prepared_armory_fixture.gd").prepare(world,ids,policies)
	check(world.combat.start(world,world.scenario.strategic_site,{"participants":ids,"side_policies":policies}),"controlled prepared-fire battle starts")
	var shooter: Node3D = world.combat.forces[ids[0]][0]
	var target: Node3D = world.combat.forces[ids[1]][0]
	var at: Vector3 = world.territory.sites[world.scenario.strategic_site].position
	shooter.global_position = at+Vector3(-10 if role == "artillery" else -4.5,0,0); target.global_position = at
	shooter.combat_arrived = true; target.combat_arrived = true
	world.combat.phase = "FIGHT"
	# Stationary controlled target: real CombatSystem attacks/damage/armor/cooldowns.
	for tick in range(400):
		world.tick += 1; world.seconds += 0.1
		Abilities.update(shooter,world.seconds)
		world.combat.update()
		if world.combat.phase != "FIGHT": break
	var shots: Array = world.combat.attack_history.filter(func(e: Dictionary) -> bool: return e.attacker == shooter.citizen_id and e.prepared)
	check(shots.size() >= 2,"prepared-fire real repeated attacks " + role)
	for index in range(1,shots.size()):
		check(shots[index].tick-shots[index-1].tick == (30 if role == "artillery" else 11),"prepared actual timestamp cadence " + role)
	check(shots.all(func(e: Dictionary) -> bool: return is_equal_approx(e.interval,3.5*0.85 if role == "artillery" else 1.2*0.85)),"actual attack effective interval")
	evidence["prepared_attacks_"+role] = shots
	scene.queue_free(); await process_frame

func run() -> void:
	await scarcity(); await prepared(); await pathfinder(); await muster_cancel()
	await prepared_attacks("ranged"); await prepared_attacks("artillery")
	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures,"evidence":evidence}
	var path := OS.get_environment("ROOMSCALE_FOCUSED_RESULT")
	if not path.is_empty(): var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(result,"  ")); file.close()
	print("ROOMSCALE_POC54_BEHAVIOR_"+result.result+" "+JSON.stringify(result)); quit(0 if failures.is_empty() else 1)

