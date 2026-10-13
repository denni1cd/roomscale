extends SceneTree
const Resolver := preload("res://scripts/innovation_system.gd")
const Registry := preload("res://scripts/deployment_adapter_registry.gd")
const Problems := preload("res://scripts/problem_registry.gd")
var failures: Array[String] = []
var assertions := 0

class StockAdapter extends RefCounted:
	var finished := false
	func supports(solution: Dictionary) -> bool: return solution.deployment.adapter == "stock_fixture"
	func prepare(sim: Node, _solution: Dictionary, _problem: Dictionary) -> Dictionary:
		if finished: return {"valid":false}
		var at: Vector3 = sim.coordinator.navigation.nearest_walkable_position(sim.coordinator.depot_station+Vector3(0,0,16))
		return {"valid":true,"position":at,"target":at,"claim_key":"stock_fixture"}
	func status(_sim: Node, _project: Dictionary) -> String: return "VALID"
	func render(root: Node3D, _project: Dictionary, fraction: float, _color: Color) -> void: root.set_meta("progress",fraction)
	func finish(_sim: Node, project: Dictionary) -> bool: project["fixture_applied"] = true; finished = true; return true
	func advance(_sim: Node, project: Dictionary, delta: float) -> void: project["periodic_work"] = float(project.get("periodic_work",0))+delta

func _initialize() -> void:
	create_timer(45).timeout.connect(func() -> void: push_error("ROOMSCALE_EXTENSIBILITY_FAIL watchdog"); quit(1))
	call_deferred("run")
func check(value: bool, label: String) -> void:
	assertions += 1
	if not value and not failures.has(label): failures.append(label)

func catalog(solutions: Array, civ: String = "fixture") -> String:
	var path := "user://extensibility-%s.json" % civ
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":1,"civilization_id":civ,"technologies":[],"solutions":solutions})); file.close()
	return path

func solution(id: String, addresses: Array, priority: float = 1, adapter: String = "climb_route") -> Dictionary:
	return {"id":id,"addresses":addresses,"requires_capabilities":[],"priority":priority,"construction":{"work":4},"deployment":{"adapter":adapter,"style":"rope"}}

func problem(type: String, severity: float, source: String = "target") -> Dictionary:
	return {"type":type,"severity":severity,"source_id":source,"recognition_state":"RECOGNIZED"}

func run() -> void:
	var registry := Registry.new()
	var definitions := [solution("vertical",["VERTICAL_ACCESS"]),solution("water",["WATER_SHORTAGE"])]
	var system = Resolver.create("fixture",[],catalog(definitions)).system
	var pressure := [problem("VERTICAL_ACCESS",0.30),problem("WATER_SHORTAGE",0.95)]
	check(system.solution_candidates(pressure,registry.supported)[0].id == "water","urgent water beats mild access")
	pressure.reverse()
	check(system.solution_candidates(pressure,registry.supported)[0].id == "water","problem input order is irrelevant")
	for iteration in range(5): check(system.solution_candidates(pressure,registry.supported)[0].id == "water","identical solution choice")
	check(system.solution_candidates([problem("VERTICAL_ACCESS",0.5),problem("WATER_SHORTAGE",0.5)],registry.supported)[0].id == "vertical","exact tie uses stable ID")
	var duplicates := [problem("WATER_SHORTAGE",0.95)]
	for i in range(100): duplicates.append(problem("VERTICAL_ACCESS",0.1,str(i)))
	check(system.solution_candidates(duplicates,registry.supported)[0].id == "water","many mild sources cannot multiply pressure")
	definitions.append(solution("combined",["VERTICAL_ACCESS","WATER_SHORTAGE"]))
	system = Resolver.create("fixture",[],catalog(definitions)).system
	var ranked: Array = system.solution_candidates(pressure,registry.supported)
	check(ranked[0].id == "combined" and ranked[0].problems.size() == 2,"one solution benefits from distinct addressed problems")
	definitions.append(solution("unsupported",["VERTICAL_ACCESS","WATER_SHORTAGE"],100,"not_implemented"))
	system = Resolver.create("fixture",[],catalog(definitions)).system
	check(system.solution_candidates(pressure,registry.supported)[0].id == "combined","unsupported physical class excluded")
	check(system.solution_candidates([{"type":"UNKNOWN","severity":1},{"type":"WATER_SHORTAGE","severity":NAN}],registry.supported).is_empty(),"invalid pressures cannot produce projects")
	check(system.solution_candidates([{"type":"WATER_SHORTAGE","severity":1,"recognition_state":"EMERGING"}],registry.supported).is_empty(),"unrecognized problem cannot trigger construction")

	var observations := [{"type":"VERTICAL_ACCESS","source_id":"desk","severity":1,"strength":0.35,"context":{"region":"surface"}}]
	var awareness = Problems.load_default().registry
	awareness.observe_batch(observations,0)
	check(awareness.active_problems().is_empty() and awareness.active_problems(false)[0].observation_count == 1,"one weak observation is only emerging")
	awareness.observe_batch(observations,0)
	check(awareness.active_problems(false)[0].observation_count == 1,"duplicate detector call at one tick adds no evidence")
	awareness.observe_batch(observations,5); awareness.observe_batch(observations,10)
	check(awareness.active_problems()[0].recognized_at == 10,"repeated fixed-time observations recognize")
	var a = Problems.load_default().registry; var b = Problems.load_default().registry
	var batch := [observations[0].duplicate(true),observations[0].duplicate(true),observations[0].duplicate(true)]
	batch[0].strength = 0.2; batch[1].strength = 0.3; batch[2].strength = 0.5
	a.observe_batch(batch,7); batch.reverse(); b.observe_batch(batch,7)
	check(a.active_problems() == b.active_problems(),"detector evidence order does not alter recognition")
	check(a.active_problems()[0].recognized_at == 7,"recognition depends on simulation time")
	a.observe_batch([],12)
	check(a.active_problems(false).is_empty(),"solved or disappeared problem removes evidence")
	a.observe_batch(observations,17)
	check(a.active_problems().is_empty(),"reappearance begins a fresh awareness episode")
	check(system.known_technologies.is_empty(),"recognition and solution ranking grant no knowledge")
	var research = Resolver.create("clockwork").system
	check(research.preferred_research(awareness.active_problems(false)).size() > 0,"recognized evidence enables only a research choice")
	check(research.preferred_research(a.active_problems(false)).is_empty() and research.known_technologies.is_empty(),"weak evidence neither schedules research nor grants technology")

	var economy := preload("res://scripts/economy_system.gd").new()
	economy.configure({"wood":1.0e308})
	var before := economy.snapshot()
	check(not economy.receive("wood",1.0e308) and economy.snapshot() == before,"finite deposits cannot overflow inventory and are atomic")
	economy.available.wood = NAN
	check(not economy.audit().is_empty(),"NaN inventory cannot pass conservation audit")
	var resources := preload("res://scripts/resource_system.gd").new()
	check(resources.create_bundle("wood",1.0e308,Vector3.ZERO,"fixture") > 0,"finite bundle admitted")
	check(resources.create_bundle("wood",1.0e308,Vector3.ZERO,"fixture") == -1 and resources.audit().is_empty(),"bundle overflow rejected before mutation")
	var unknown := solution("bad",["VERTICAL_ACCESS"]); unknown.construction = {"crystal":1,"work":4}
	check(not Resolver.create("fixture",[],catalog([unknown])).ok,"unknown economy material rejected at vocabulary boundary")
	# Real ordinary-clock project with food/water materials and a non-route adapter.
	# Starting established infrastructure is authored scenario configuration.
	OS.set_environment("ROOMSCALE_ROOM","room_a"); OS.set_environment("ROOMSCALE_FISHBOWL","1"); OS.set_environment("ROOMSCALE_INNOVATION","1"); OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE","1")
	var scene: Node3D = load("res://scenes/pipeline_proof.tscn").instantiate(); root.add_child(scene); current_scene = scene
	var sim: Node = scene.start_civilization({"innovation":true,"autonomous":true,"cohort_size":1}); sim.set_process(false); sim.camera_director.set_process(false); sim.spectator.set_process(false)
	var stock_solution := solution("food_water_fixture",["VERTICAL_ACCESS"],1,"stock_fixture"); stock_solution.construction = {"food":2,"water":3,"work":4}
	check(sim.innovation.configure(sim,{"innovation":true,"innovation_catalog_path":catalog([stock_solution],"clockwork")}),"generic material catalog configures")
	check(sim.innovation.adapters.register("stock_fixture",StockAdapter.new()),"a new physical class registers without runtime edits")
	check(not sim.innovation.adapters.register("stock_fixture",StockAdapter.new()),"duplicate adapter registration rejected")
	sim.innovation.request_surface(sim.coordinator.surface_navigation.goal_surface_id)
	for i in range(3000):
		sim.step()
		if not sim.economy.audit().is_empty() or not sim.resources.audit().is_empty(): check(false,"generic material conservation")
		if not sim.innovation.projects.is_empty() and sim.innovation.projects[-1].state == "COMPLETE": break
		if i % 100 == 0: await process_frame
	check(not sim.innovation.projects.is_empty() and sim.innovation.projects[-1].state == "COMPLETE","generic non-route project completed through real work")
	var completed: Dictionary = sim.innovation.projects[-1] if not sim.innovation.projects.is_empty() else {}
	check(completed.get("required",{}) == {"food":2.0,"water":3.0} and completed.get("delivered",{}) == completed.get("required",{}),"project iterates authored material fields")
	check(sim.economy.project_consumed.food == 2 and sim.economy.project_consumed.water == 3,"actual food/water charged to project ledger")
	check(completed.get("fixture_applied",false) and absf(float(completed.get("work",0))-4) < 0.00001 and completed.get("delivery_distance",0) > 0,"adapter effect follows physical deliveries and labor")
	check(sim.coordinator.surface_navigation.connections.is_empty(),"non-route adapter creates no phantom navigation link")
	for tick in range(10): sim.step()
	check(absf(float(completed.get("periodic_work",0))-1) < 0.00001,"persistent adapter behavior runs on fixed production ticks")
	var before_periodic: float = completed.periodic_work
	sim.speed = 0; sim.advance_elapsed_time(1)
	check(completed.periodic_work == before_periodic,"pause freezes persistent adapter behavior")
	var receipt := {"result":"PASS" if failures.is_empty() else "FAIL","assertions":assertions,"failures":failures,"recognition_time":10,"generic_project":completed.get("required",{}),"completion_time":completed.get("completed",-1)}
	var path := OS.get_environment("ROOMSCALE_FOCUSED_RESULT")
	if not path.is_empty(): var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(receipt,"  ")); file.flush(); file.close()
	print("ROOMSCALE_EXTENSIBILITY_"+receipt.result+" "+JSON.stringify(receipt)); quit(0 if failures.is_empty() else 1)
