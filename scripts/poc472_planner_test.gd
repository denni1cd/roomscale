extends SceneTree
## Production planner trials must preserve physical state and repeat exactly.
const Sites := preload("res://scripts/settlement_site_planner.gd")
var scene: Node3D
var failed := false

func _initialize() -> void:
	call_deferred("run")

func physical_state(sim: Node) -> String:
	var positions: Array = []
	for citizen in sim.citizens: positions.append(citizen.global_position)
	return JSON.stringify([positions, sim.economy.snapshot(), sim.resources.sources, sim.resources.bundles, sim.resources.generated, sim.salvage.objects, sim.coordinator.navigation.room_definition, sim.coordinator.navigation.obstacle_rects, sim.development.projects, sim.needs.shelter_capacity, sim.needs.rest_capacity])

func check(condition: bool, reason: String) -> void:
	if condition: return
	failed = true
	push_error("POC472_PLANNER_FAIL " + reason)

func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	scene = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	var first := Sites.new()
	var second := Sites.new()
	first.configure(sim)
	second.configure(sim)
	var before := physical_state(sim)
	var preview := first.preview("shelter")
	check(preview.valid, "canonical founding certificate")
	check(first.reservations.is_empty() and first.rest_targets.is_empty(), "preview changed reservations")
	check(before == physical_state(sim), "preview mutated physical state")
	var selected := first.select("shelter")
	var repeated := second.select("shelter")
	check(selected.valid and repeated.valid, "complete founding sequence found")
	check(JSON.stringify([selected, first.reservations, first.rest_targets, first.decisions]) == JSON.stringify([repeated, second.reservations, second.rest_targets, second.decisions]), "starting state did not produce identical decisions")
	check(before == physical_state(sim), "select created resources, moved a citizen, or changed room")
	check(first.reservations.size() == 3 and first.rest_targets.size() == 7, "shelter did not reserve remaining founding chain/rest slots")
	var all: Array = first.reservations.duplicate()
	all.append(selected)
	for i in range(all.size()):
		for j in range(i): check(not first.apron(all[i].position).intersects(first.apron(all[j].position)), "future apron overlap")
	check(first._plan_evidence.navigation_trials >= 4 and first._plan_evidence.navigation_trials <= first.MAX_TRIALS, "unbounded navigation search")
	check(first.decisions[0].validation_navigation_trials == 1, "acceptance proof not counted separately")
	var budget := Sites.new()
	budget.configure(sim)
	budget._prepare(false)
	budget._search([], [], 0)
	check(budget._trials == 1, "terminal connectivity/rest proof not counted")
	budget._trials = budget.MAX_TRIALS
	var exhausted := budget._trial([], 0)
	check(not exhausted.valid and exhausted.reason == "navigation trial budget exhausted" and budget._trials == budget.MAX_TRIALS, "navigation trial cap exceeded")

	# Loose, reachable bundles occupy every otherwise legal candidate apron.
	# Collection changes no room geometry, but must invalidate a failed search.
	var retry := Sites.new()
	retry.configure(sim)
	retry._prepare()
	var bundle_ids: Array[int] = []
	for site in retry._positions: bundle_ids.append(sim.resources.create_bundle("wood", 1, site, "planner_retry_fixture"))
	check(not bundle_ids.is_empty(), "retry fixture has no legal positions")
	var blocked := retry.select("shelter")
	check(not blocked.valid and retry.reservations.is_empty() and not retry._failed_state.is_empty(), "transient bundles did not block planning")
	var blocked_state: String = retry._failed_state
	check(not retry.select("shelter").valid and retry._failed_state == blocked_state and retry._trials == 0, "identical failure state did not reuse cache")
	for id in bundle_ids:
		var at: Vector3 = sim.resources.bundles[id].position
		check(sim.resources.reserve_bundle(id, 0), "fixture bundle reservation")
		check(sim.resources.pickup_bundle(id, 0, at), "fixture bundle collection")
		check(sim.resources.deliver_bundle(id, 0, sim.coordinator.depot_station, sim.coordinator.depot_station, sim.economy), "fixture bundle delivery")
	var after_collection := physical_state(sim)
	var retried := retry.select("shelter")
	check(retried.valid and retry._failed_state.is_empty(), "collected bundles left planner permanently cached as infeasible")
	check(JSON.stringify(retried) == JSON.stringify(selected), "retry changed deterministic site ordering")
	check(after_collection == physical_state(sim), "retry mutated physical state")
	print("POC472_PLANNER_%s trials=%s decisions=%s" % ["FAIL" if failed else "PASS", first._plan_evidence.navigation_trials, JSON.stringify(first.decisions)])
	scene.queue_free()
	quit(1 if failed else 0)
