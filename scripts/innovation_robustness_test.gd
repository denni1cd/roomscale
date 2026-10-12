extends SceneTree
const IS = preload("res://scripts/innovation_system.gd")
const CR = preload("res://scripts/capability_registry.gd")
const PR = preload("res://scripts/problem_registry.gd")
const Visuals = preload("res://scripts/civilization_presentation.gd")
const World = preload("res://scripts/world_simulation.gd")
const IC = preload("res://scripts/innovation_catalog.gd")
var checks: Array = []
var fixture_ids: Dictionary = {}
const FIXTURE_ROOT = "user://innovation-robustness"

class LabelRuntime:
	extends RefCounted
	var definition = {"display_name":"Scavenger"}
	func living_population(): return 7

func _initialize():
	call_deferred("run")
func check(label, condition, detail = null):
	checks.append({"test":label,"pass":condition,"detail":detail})
func ids(entries):
	var out = []
	for e in entries: out.append(e.id)
	return out
func choice(s, problems):
	return s.preferred_research(problems).get("technology", {}).get("id", "")
func save_catalog(id, data):
	var f = FileAccess.open("%s/%s.json" % [FIXTURE_ROOT,id], FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	fixture_ids[id] = true
func tech(id, grants, req = []):
	return {"id":id,"grants":grants,"requires_capabilities":req}
func sol(id, req, problem = "VERTICAL_ACCESS"):
	return {"id":id,"addresses":[problem],"requires_capabilities":req}
func fixture(id, ts, ss):
	return {"schema_version":1,"civilization_id":id,"technologies":ts,"solutions":ss}
func make_system(civ_id, starting = []):
	if not fixture_ids.has(civ_id): return IS.create(civ_id, starting)
	return IS.create(civ_id,starting,"%s/%s.json" % [FIXTURE_ROOT,civ_id])
func run():
	DirAccess.make_dir_recursive_absolute(FIXTURE_ROOT)
	# Previously these types raised script errors while the loader reported ok=true.
	for case in ["schema_object", "id_object", "grant_object", "requirement_object", "address_object", "civ_object", "construction_object", "construction_negative", "display_object", "description_object"]:
		var data = fixture("hostile",[tech("t",["STEAM_POWER"])],[sol("s",["POWER_SOURCE"])])
		match case:
			"schema_object": data.schema_version = {"bad":1}
			"id_object": data.technologies[0].id = {"bad":1}
			"grant_object": data.technologies[0].grants = [{"bad":1}]
			"requirement_object": data.technologies[0].requires_capabilities = [{"bad":1}]
			"address_object": data.solutions[0].addresses = [{"bad":1}]
			"civ_object": data.civilization_id = {"bad":1}
			"construction_object": data.solutions[0].construction = []
			"construction_negative": data.solutions[0].construction = {"work":-1}
			"display_object": data.technologies[0].display_name = {}
			"description_object": data.solutions[0].description = []
		save_catalog("hostile",data)
		var loaded = IC.load_path("%s/hostile.json" % FIXTURE_ROOT,"hostile")
		check("hostile_"+case,not loaded.ok and loaded.catalog == null and not loaded.errors.is_empty())
	for kind in ["capability","problem"]:
		for case in ["schema_object","id_object","member_object"]:
			if kind == "problem" and case == "member_object": continue
			var data = {"schema_version":1,"capabilities":[{"id":"A","implies":[]}],"problems":[{"id":"A"}]}
			match case:
				"schema_object": data.schema_version = {"bad":1}
				"id_object":
					data.capabilities[0].id = {"bad":1}
					data.problems[0].id = {"bad":1}
				"member_object": data.capabilities[0].implies = [{"bad":1}]
			var file = FileAccess.open("%s/registry.json" % FIXTURE_ROOT,FileAccess.WRITE)
			file.store_string(JSON.stringify(data)); file.close()
			var loaded = CR.load_path("%s/registry.json" % FIXTURE_ROOT) if kind == "capability" else PR.load_path("%s/registry.json" % FIXTURE_ROOT)
			check("hostile_%s_%s" % [kind,case],not loaded.ok and loaded.registry == null and not loaded.errors.is_empty())
	var atomic = IC.new(); atomic.civilization_id = "atomic"
	atomic._load(fixture("atomic",[tech("good",["STEAM_POWER"])],[sol("good",["POWER_SOURCE"])]))
	var atomic_before = atomic.technology_list()
	check("atomic_catalog_rejection",not atomic._load(fixture("atomic",[tech("bad",[{}])],[])).is_empty() and atomic_before == atomic.technology_list())
	var atomic_cap = CR.load_default().registry
	var cap_before = atomic_cap.definitions.duplicate(true)
	check("atomic_capability_rejection",not atomic_cap._load({"schema_version":1,"capabilities":[{"id":"BAD","implies":["UNKNOWN"]}]}).is_empty() and cap_before == atomic_cap.definitions)
	check("invalid_starting_member",not IS.create("clockwork",[{}]).ok and IS.create("clockwork",[""]).system == null)
	for priority in [INF,NAN,-1.0,"1",{},true]:
		var invalid_catalog = IC.new(); invalid_catalog.civilization_id = "numbers"
		var t = tech("t",["STEAM_POWER"]); t.priority = priority
		check("reject_numeric_priority_%s" % str(priority),not invalid_catalog._load(fixture("numbers",[t],[])).is_empty())
	var battle_world = World.new()
	for i in range(3): battle_world.runtimes.append(Node.new())
	check("invalid_battle_rejected_without_mutation",not battle_world.combat.start(battle_world,"unused") and battle_world.combat.world == null and battle_world.combat.forces.is_empty())
	for runtime in battle_world.runtimes: runtime.free()
	battle_world.free()
	check("data_driven_combat_style",Visuals.uses_organic_combat({"id":"scavenger","citizen_style":"unknown","combat_style":"organic"}) and not Visuals.uses_organic_combat({"citizen_style":"verdant_folk"}))
	check("data_driven_conflict_labels",Visuals.society_summary([LabelRuntime.new()]) == "SCAVENGER 7")
	for p in ["VERTICAL_ACCESS","CROSS_GAP","LONG_HAUL_DISTANCE","LOGISTICS_BOTTLENECK"]:
		for civ in ["clockwork","verdant"]:
			var s = make_system(civ).system
			var ch = choice(s,[{"type":p,"severity":0.8}])
			check("shared_%s_%s" % [p,civ], not ch.is_empty(), ch)
	var req = ["CABLE_ENGINEERING","STEAM_POWER","LOAD_BEARING_FRAMES"]
	check("lift_all", ids(make_system("clockwork",req).system.viable_solutions("VERTICAL_ACCESS")).has("steam_lift"))
	for r in req:
		var subset = req.duplicate(); subset.erase(r)
		check("lift_missing_"+r, not ids(make_system("clockwork",subset).system.viable_solutions("VERTICAL_ACCESS")).has("steam_lift"))
	check("lift_direct_power", ids(make_system("clockwork",["CABLE_ENGINEERING","POWER_SOURCE","LOAD_BEARING_FRAMES"]).system.viable_solutions("VERTICAL_ACCESS")).has("steam_lift"))
	var cr = CR.new()
	var errs = cr._load({"schema_version":1,"capabilities":[{"id":"A","implies":["B"]},{"id":"B","implies":["C"]},{"id":"C","implies":["A"]}]})
	check("transitive_and_cycle_safe", errs.is_empty() and cr.expand(["A"]) == ["A","B","C"])
	var v = make_system("verdant").system
	check("prereq_too_early", not v.learn_technology("accelerated_growth").ok and not ids(v.researchable_technologies()).has("accelerated_growth"))
	v.learn_technology("cultivated_vines")
	check("prereq_available", ids(v.researchable_technologies()).has("accelerated_growth") and v.learn_technology("accelerated_growth").ok)
	check("grants", v.known_capabilities().has("RAPID_BIOMASS_GROWTH"))
	var before = v.known_capabilities()
	check("duplicate_learn", v.learn_technology("accelerated_growth").already_known and before == v.known_capabilities())
	check("unknown_learn", not v.learn_technology("missing").ok and before == v.known_capabilities())
	for civ in ["clockwork","verdant"]:
		var foreign = "verdant" if civ == "clockwork" else "clockwork"
		var s = make_system(civ, CR.load_default().registry.definitions.keys()).system
		var foreign_ids = ids(make_system(foreign).system.catalog.solution_list())
		var isolated = true
		for p in ["VERTICAL_ACCESS","CROSS_GAP","WATER_SHORTAGE"]:
			for id in ids(s.viable_solutions(p)):
				if foreign_ids.has(id): isolated = false
		check("isolation_"+civ, isolated and not s.learn_technology("cultivated_vines" if civ == "clockwork" else "steam_engine").ok)
	var vertical = {"type":"VERTICAL_ACCESS","severity":1.0}
	var water = {"type":"WATER_SHORTAGE","severity":0.1}
	var pressures = [vertical,water,{"type":"CROSS_GAP","severity":0.05},{"type":"LOGISTICS_BOTTLENECK","severity":0.02}]
	v = make_system("verdant").system
	check("pressure_vertical", choice(v,pressures) == "cultivated_vines",v.research_candidates(pressures))
	vertical.severity = 0.01; water.severity = 1.0
	check("pressure_water", choice(v,pressures) == "water_retaining_growth",v.research_candidates(pressures))
	var baseline = JSON.stringify(v.research_candidates(pressures))
	var stable = true
	for i in range(100):
		pressures.reverse()
		if JSON.stringify(v.research_candidates(pressures)) != baseline: stable = false
	check("problem_order_100",stable)
	var caps = ["FLEXIBLE_GROWTH","STEAM_POWER","LOAD_BEARING_GROWTH"]
	var first = make_system("verdant",caps).system
	caps.reverse()
	var second = make_system("verdant",caps).system
	check("capability_order",first.known_capabilities() == second.known_capabilities() and first.research_candidates(pressures) == second.research_candidates(pressures) and first.viable_solutions("VERTICAL_ACCESS") == second.viable_solutions("VERTICAL_ACCESS"))
	var known_order_a = make_system("clockwork").system
	known_order_a.learn_technology("grapple_engineering"); known_order_a.learn_technology("steam_engine")
	var known_order_b = make_system("clockwork").system
	known_order_b.learn_technology("steam_engine"); known_order_b.learn_technology("grapple_engineering")
	check("known_technology_dictionary_order",known_order_a.known_capabilities() == known_order_b.known_capabilities() and known_order_a.research_candidates(pressures) == known_order_b.research_candidates(pressures) and known_order_a.viable_solutions("VERTICAL_ACCESS") == known_order_b.viable_solutions("VERTICAL_ACCESS"))
	var ts = [tech("salvage_cable",["CABLE_ENGINEERING"]),tech("salvage_frame",["LOAD_BEARING_FRAMES"],["CABLE_ENGINEERING"]),tech("salvage_power",["STEAM_POWER"])]
	save_catalog("scavenger",fixture("scavenger",ts,[sol("scrap_ladder",["CABLE_ENGINEERING"]),sol("scrap_elevator",["CABLE_ENGINEERING","LOAD_BEARING_FRAMES","POWER_SOURCE"]) ]))
	var sc = make_system("scavenger")
	check("third_civ_load",sc.ok)
	check("third_civ_path",choice(sc.system,[{"type":"VERTICAL_ACCESS","severity":1}]) == "salvage_cable")
	check("third_civ_prereq",not sc.system.learn_technology("salvage_frame").ok)
	sc.system.learn_technology("salvage_cable"); sc.system.learn_technology("salvage_frame"); sc.system.learn_technology("salvage_power")
	check("third_civ_composed_solution",ids(sc.system.viable_solutions("VERTICAL_ACCESS")) == ["scrap_elevator","scrap_ladder"])
	var reversed_catalog = fixture("scavenger",ts.duplicate(true),[sol("scrap_elevator",["CABLE_ENGINEERING","LOAD_BEARING_FRAMES","POWER_SOURCE"]),sol("scrap_ladder",["CABLE_ENGINEERING"])])
	reversed_catalog.technologies.reverse()
	var original_choice = make_system("scavenger").system.research_candidates([{"type":"VERTICAL_ACCESS","severity":1}])
	save_catalog("scavenger",reversed_catalog)
	check("catalog_order",original_choice == make_system("scavenger").system.research_candidates([{"type":"VERTICAL_ACCESS","severity":1}]))
	# prerequisite-only enabler, with no direct capability overlap with the solution
	save_catalog("chain",fixture("chain",[tech("starter",["FLEXIBLE_GROWTH"]),tech("final",["RAPID_BIOMASS_GROWTH"],["FLEXIBLE_GROWTH"])],[sol("platform",["RAPID_BIOMASS_GROWTH"]) ]))
	var chain = make_system("chain").system
	check("prerequisite_path_discovery",choice(chain,[{"type":"VERTICAL_ACCESS","severity":1}]) == "starter",chain.research_candidates([{"type":"VERTICAL_ACCESS","severity":1}]))
	chain.learn_technology("starter")
	check("chain_manual_unblocks",choice(chain,[{"type":"VERTICAL_ACCESS","severity":1}]) == "final")
	save_catalog("cycle",fixture("cycle",[tech("a",["CABLE_ENGINEERING"],["LOAD_BEARING_FRAMES"]),tech("b",["LOAD_BEARING_FRAMES"],["CABLE_ENGINEERING"])],[sol("s",["CABLE_ENGINEERING"]) ]))
	check("cyclic_path_terminates",choice(make_system("cycle").system,[{"type":"VERTICAL_ACCESS","severity":1}]).is_empty())
	save_catalog("unreachable",fixture("unreachable",[tech("a",["CABLE_ENGINEERING"],["POWER_SOURCE"])],[sol("s",["CABLE_ENGINEERING"]) ]))
	check("unreachable_path_not_scored",choice(make_system("unreachable").system,[{"type":"VERTICAL_ACCESS","severity":1}]).is_empty())
	var shelter_system = make_system("verdant").system
	var shelter_pressure = [{"type":"INSUFFICIENT_SHELTER","severity":1.0}]
	var shelter_first = choice(shelter_system,shelter_pressure)
	shelter_system.learn_technology(shelter_first)
	check("shipped_verdant_shelter_path",not choice(shelter_system,shelter_pressure).is_empty(),{"first":shelter_first,"next":choice(shelter_system,shelter_pressure),"researchable":ids(shelter_system.researchable_technologies()),"viable":ids(shelter_system.viable_solutions("INSUFFICIENT_SHELTER"))})
	for step in range(5):
		if not shelter_system.viable_solutions("INSUFFICIENT_SHELTER").is_empty(): break
		var next_research = choice(shelter_system,shelter_pressure)
		if next_research.is_empty(): break
		shelter_system.learn_technology(next_research)
	check("shelter_path_completes_autonomously",ids(shelter_system.viable_solutions("INSUFFICIENT_SHELTER")).has("climbing_tree"))
	# authored numeric types and empty capability ids must be rejected
	for case in ["unknown_grant","unknown_req","unknown_problem","duplicate_tech","duplicate_solution","empty_tech","empty_solution","bad_array","bad_entry","bad_grants","blank_requirement","blank_grant","bad_priority","bad_work","bad_deployment","bad_adapter","bad_style","bad_construction","unsupported_cost","missing_build_work","zero_build_work"]:
		var d = fixture("bad",[tech("t",["STEAM_POWER"])],[sol("s",["POWER_SOURCE"])])
		match case:
			"unknown_grant": d.technologies[0].grants = ["UNKNOWN"]
			"unknown_req": d.technologies[0].requires_capabilities = ["UNKNOWN"]
			"unknown_problem": d.solutions[0].addresses = ["UNKNOWN"]
			"duplicate_tech": d.technologies.append(d.technologies[0].duplicate(true))
			"duplicate_solution": d.solutions.append(d.solutions[0].duplicate(true))
			"empty_tech": d.technologies[0].id = ""
			"empty_solution": d.solutions[0].id = ""
			"bad_array": d.technologies = {}
			"bad_entry": d.technologies = [42]
			"bad_grants": d.technologies[0].grants = {}
			"blank_requirement": d.solutions[0].requires_capabilities = [""]
			"blank_grant": d.technologies[0].grants = [""]
			"bad_priority": d.technologies[0].priority = {"bad":1}
			"bad_work": d.technologies[0].research_work = -10
			"bad_deployment": d.solutions[0].deployment = "bad"
			"bad_adapter": d.solutions[0].deployment = {"adapter":42}
			"bad_style": d.solutions[0].deployment = {"adapter":"climb_route","style":{}}
			"bad_construction": d.solutions[0].construction = []
			"unsupported_cost":
				d.solutions[0].deployment = {"adapter":"climb_route"}
				d.solutions[0].construction = {"work":10,"magic":1}
			"missing_build_work": d.solutions[0].deployment = {"adapter":"climb_route"}
			"zero_build_work":
				d.solutions[0].deployment = {"adapter":"climb_route"}
				d.solutions[0].construction = {"work":0}
		save_catalog("bad",d)
		var r = make_system("bad")
		check("reject_"+case,not r.ok,{"ok":r.ok,"errors":r.errors,"system_returned":r.system != null})
	var obstacle = {"position":[0,0,0],"dimensions":[0.2,5,8],"rotation_degrees":30}
	var adapter = preload("res://scripts/solution_deployment.gd")
	check("thin_rotated_furniture_blocks_route_span",adapter._span_blocked(Vector3(-2,2,0),Vector3(2,2,0),obstacle))
	check("route_may_lie_on_supported_surface",not adapter._span_blocked(Vector3(-2,5,0),Vector3(2,5,0),obstacle))
	check("route_may_climb_above_furniture",not adapter._span_blocked(Vector3(-2,6,0),Vector3(2,6,0),obstacle))
	check("unknown_deployment_style_not_executed",not preload("res://scripts/solution_deployment.gd").supported({"deployment":{"adapter":"climb_route","style":"unknown"}}))
	check("unknown_civ",not make_system("missing").ok)
	check("empty_civ",not make_system("").ok)
	check("unknown_start",not make_system("clockwork",["UNKNOWN"]).ok)
	cr = CR.new()
	check("unknown_implication",not cr._load({"schema_version":1,"capabilities":[{"id":"A","implies":["UNKNOWN"]}]}).is_empty())
	# approximate score comparisons can form a comparator cycle
	var permutations = [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
	var source = [{"id":"a","score":1.0},{"id":"b","score":1.000009},{"id":"c","score":1.000018}]
	var orders = []
	for perm in permutations:
		var entries: Array[Dictionary] = []
		for index in perm: entries.append(source[index].duplicate(true))
		v._sort_scored(entries)
		orders.append(ids(entries))
	check("near_tie_total_order",orders.all(func(order): return order == orders[0]),orders)
	var tie_ts = [tech("a",["CABLE_ENGINEERING"]),tech("b",["WATER_RETENTION"]),tech("c",["LOAD_BEARING_FRAMES"])]
	tie_ts[0].priority = 1.0; tie_ts[1].priority = 1.000009; tie_ts[2].priority = 1.000018
	save_catalog("ties",fixture("ties",tie_ts,[sol("sa",["CABLE_ENGINEERING"],"VERTICAL_ACCESS"),sol("sb",["WATER_RETENTION"],"WATER_SHORTAGE"),sol("sc",["LOAD_BEARING_FRAMES"],"CROSS_GAP")]))
	var tie_system = make_system("ties").system
	var tie_problems = [{"type":"VERTICAL_ACCESS","severity":1.0},{"type":"WATER_SHORTAGE","severity":1.0},{"type":"CROSS_GAP","severity":1.0}]
	var choices = []
	for perm in permutations:
		var input = []
		for index in perm: input.append(tie_problems[index])
		choices.append(choice(tie_system,input))
	check("preferred_research_permutation_near_ties",choices.all(func(ch): return ch == choices[0]),choices)
	# multiplying overlapping alternative solutions: max pressure versus tiny repeated pressure
	var huge_tech = tech("huge",["STEAM_POWER"]); huge_tech.priority = 1.0e308
	var huge_solution = sol("huge",["POWER_SOURCE"]); huge_solution.priority = 1.0e308
	save_catalog("huge",fixture("huge",[huge_tech],[huge_solution]))
	var huge_choice = choice(make_system("huge").system,[{"type":"VERTICAL_ACCESS","severity":1.0}])
	var huge_candidates = make_system("huge").system.research_candidates([{"type":"VERTICAL_ACCESS","severity":1.0}])
	check("finite_scores_for_finite_extreme_priorities",huge_choice == "huge" and is_finite(huge_candidates[0].score))
	v = make_system("verdant").system
	var repeated = [{"type":"WATER_SHORTAGE","severity":1.0}]
	for i in range(20): repeated.append({"type":"VERTICAL_ACCESS","source_id":str(i),"severity":0.05})
	check("many_mild_vs_one_urgent",choice(v,repeated) == "water_retaining_growth",v.research_candidates(repeated))
	var out = FileAccess.open("%s/results.json" % FIXTURE_ROOT,FileAccess.WRITE)
	out.store_string(JSON.stringify(checks,"  "))
	for c in checks: print("INNOVATION_ROBUSTNESS ","PASS " if c.pass else "FAIL ",c.test," ",JSON.stringify(c.detail))
	var passed = checks.all(func(c): return c.pass)
	if passed: print("ROOMSCALE_INNOVATION_ROBUSTNESS_PASS checks=",checks.size())
	else: push_error("ROOMSCALE_INNOVATION_ROBUSTNESS_FAIL")
	quit(0 if passed else 1)
