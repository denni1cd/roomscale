extends "res://scripts/poc46_fast_test.gd"
const Room := preload("res://scripts/room_definition.gd")

func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	var loaded := Room.load_requested()
	check(loaded.ok, "founder room contract validates")
	var malformed: Dictionary = loaded.definition.duplicate(true)
	malformed.start.population = -1
	check(not Room.prepare_start(malformed).is_empty(), "invalid population rejected")
	malformed = loaded.definition.duplicate(true)
	malformed.objects.append({"kind":"settlement"})
	check(not Room.prepare_start(malformed).is_empty(), "empty start rejects prebuilt structures")
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	check(sim.citizens.size() == 5 and sim.population.cohort_size == 1, "five real founders and individual growth")
	check(sim.speed == 1 and sim.governor.enabled and sim.camera_director.enabled, "canonical autonomous startup at 1x")
	check(sim.needs.shelter_capacity == 0 and sim.needs.rest_capacity == 0 and sim.needs.reserve_rest(0) == -1, "no hidden shelter or rest slots")
	check(not sim.has_capability("workshop") and not sim.has_capability("storage") and not sim.has_capability("advanced_construction"), "no starting capabilities")
	check(sim.construction.stockpile.values().all(func(value: int) -> bool: return value == 0), "unused legacy traversal stock is also empty")
	check(sim.citizens.all(func(c: Node3D) -> bool: return c.get_script() == preload("res://scripts/citizen_agent.gd") and not c.needs.is_empty() and not c.needs.sheltered and sim.coordinator.navigation.is_walkable(c.position)), "founders use real needs and walkable positions")
	check(sim.economy.available.wood == 0 and sim.economy.available.metal == 0 and sim.economy.forecast("food",5) == 2 and sim.economy.forecast("water",5) == 2, "portable supplies equal two days and zero building materials")
	var before := snapshot(sim)
	check(not sim.development.request("housing") and not sim.development.request("workshop") and not sim.development.request("depot"), "development prerequisites reject premature projects")
	check(not sim.coordinator.issue_reach_explore(sim.construction.target_region,sim.citizens).accepted, "Reach API rejects advanced traversal without workshop")
	sim.construction._create_project()
	check(not sim.construction.project_created and snapshot(sim) == before, "direct project entry cannot bypass workshop or mutate stocks")
	var healthy := {"population":5,"shelter":6,"urgent":0,"food_days":3.0,"water_days":3.0}
	check(sim.population.eligibility(healthy,false,false).is_empty(), "one spare shelter place supports individual growth")
	check(not sim.population.eligibility(healthy,true,false).is_empty(), "emergency blocks individual growth")
	check(not sim.population.eligibility(healthy,false,true).is_empty(), "material blockage blocks growth")
	healthy.shelter = 5
	check(not sim.population.eligibility(healthy,false,false).is_empty(), "no headroom blocks growth")
	healthy.shelter = 6
	healthy.water_days = 1.9
	check(not sim.population.eligibility(healthy,false,false).is_empty(), "unhealthy reserves block growth")
	check(sim.population.arrival_positions(sim).size() == 1, "individual arrival finds valid connected position")
	sim.population.evaluate(sim,sim.status(),false,false)
	check(sim.citizens.size() == 5 and sim.population.stable_since < 0, "growth cannot start stability window before infrastructure")
	var hud: Control = sim.spectator
	check(not hud.diagnostics and not sim.hud.visible, "compact presentation and hidden diagnostics")
	before = snapshot(sim)
	hud.set_diagnostics(true)
	hud.set_diagnostics(false)
	sim.camera_director.advance(8)
	hud.advance(1)
	check(snapshot(sim) == before, "presentation does not change production state")
	for viewport_size in [Vector2i(1920,1080),Vector2i(2560,1440)]:
		root.size = viewport_size
		await process_frame
		check(not hud.event_panel.get_global_rect().intersects(hud.project_panel.get_global_rect()), "founder card layout at %s" % viewport_size)
	for multiplier in [0.0,1.0,4.0,10.0]:
		hud.speed_buttons[multiplier].pressed.emit()
		var seconds: float = sim.seconds
		sim._process(0.2)
		check(absf(sim.seconds - seconds - 0.2 * multiplier) < 0.001, "speed button advances ordinary production ticks %s" % multiplier)
	check(Adapter.event_card({"id":1,"kind":"cohort_joined","day":0,"message":"","evidence":{"before":5,"after":6}}).headline == "NEW CITIZEN", "single citizen narrative")
	check(Adapter.module_name({"kind":"shelter","id":"development_001"}).begins_with("Founder Shelter"), "primitive project narrative")
	print("POC47_FAST_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify({"checks":checks,"failures":failures}))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
