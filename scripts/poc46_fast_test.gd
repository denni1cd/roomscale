extends SceneTree
const Adapter := preload("res://scripts/fishbowl_narrative_adapter.gd")
const Presenter := preload("res://scripts/fishbowl_event_presenter.gd")
var failures: Array[String] = []
var checks: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks.append(label)
	if not ok:
		failures.append(label)
		push_error("POC46_FAST_FAIL " + label)
func snapshot(sim: Node) -> Dictionary:
	var citizens := []
	for c in sim.citizens: citizens.append([c.global_position, c.needs.duplicate(true), c.task_id])
	return {"status": sim.status().duplicate(true), "citizens": citizens, "tasks": sim.coordinator.tasks.duplicate(true), "priorities": sim.planner.priorities.duplicate(), "events": sim.journal.events.duplicate(true)}
func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_poc45")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_FISHBOWL", "0")
	var normal := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(normal)
	var manual: Node = normal.get_node("CivilizationSimulation")
	manual.set_process(false)
	check(manual.speed == 1 and not manual.governor.enabled and manual.spectator == null, "normal launch 1x, manual HUD and governor disabled")
	normal.free()
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	var hud: Control = sim.spectator
	hud.set_process(false)
	await process_frame
	check(sim.speed == 10 and sim.governor.enabled and sim.camera_director.enabled, "fishbowl starts autonomous at 10x with camera on")
	check(not hud.diagnostics and not sim.hud.visible and not hud.details_panel.visible, "diagnostics default off and dense HUD hidden")
	check(not hud.event_panel.visible, "no empty event panel at startup")
	for viewport_size in [Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = viewport_size
		await process_frame
		check(not hud.event_panel.get_global_rect().intersects(hud.project_panel.get_global_rect()) and not hud.controls_panel.get_global_rect().intersects(hud.event_panel.get_global_rect()), "edge cards do not overlap at %s" % viewport_size)
	check(hud.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.status_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.project_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.event_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "decorative spectator controls pass world input through")
	var before := snapshot(sim)
	var s := Adapter.status(sim)
	check(s.days == sim.seconds / 600 and s.population == sim.citizens.size() and s.shelter == sim.needs.shelter_capacity and s.wood == sim.economy.available.wood and s.metal == sim.economy.available.metal and s.food_days == sim.economy.forecast("food", sim.citizens.size()) and s.water_days == sim.economy.forecast("water", sim.citizens.size()), "status values equal authoritative production values")
	check(Adapter.governor(sim).contains("Surveying") and Adapter.project(sim).is_empty(), "friendly governor and hidden inactive project")
	hud.set_diagnostics(true)
	check(hud.details_panel.visible and hud.details_label.text.contains("Accounting"), "details expose diagnostics")
	hud.set_diagnostics(false)
	var f3 := InputEventKey.new()
	f3.keycode = KEY_F3
	f3.pressed = true
	Input.parse_input_event(f3)
	await process_frame
	check(hud.diagnostics and not sim.hud.visible, "real F3 input toggles only spectator diagnostics")
	hud.set_diagnostics(false)
	for i in range(120): hud.advance(0.1)
	check(hud.status_panel.modulate.a <= 0.77, "HUD fades after ten real seconds")
	hud.wake()
	hud.advance(1)
	check(hud.status_panel.modulate.a == 1, "interaction restores readable HUD")
	check(snapshot(sim) == before, "adapter, diagnostics, titles and fades leave time, needs, tasks, stocks and positions unchanged")
	for speed in [0.0, 1.0, 4.0, 10.0]:
		hud.speed_buttons[speed].pressed.emit()
		var seconds: float = sim.seconds
		sim._process(0.2)
		check(sim.speed == speed and absf(sim.seconds - seconds - 0.2 * speed) < 0.001, "authoritative speed control %s" % speed)
	var presenter := Presenter.new()
	var events := []
	for i in range(20): events.append({"id": i + 1, "day": 1, "kind": "growth_paused", "message": "Reason %d" % i, "evidence": {}})
	events.append({"id": 21, "day": 1, "kind": "cohort_joined", "message": "New cohort", "evidence": {"after": 65}})
	presenter.ingest(events)
	check(presenter.pending.size() == Presenter.LIMIT and presenter.pending[0].headline == "NEW ARRIVALS", "bounded queue and major priority")
	presenter.advance(0)
	var card: Dictionary = presenter.current.duplicate()
	presenter.ingest(events)
	check(presenter.pending.size() == Presenter.LIMIT - 1, "journal cursor suppresses replay")
	presenter.ingest([{"id": 22, "day": 1, "kind": "cohort_joined", "message": "New cohort", "evidence": {"after": 65}}])
	check(presenter.pending.size() == Presenter.LIMIT - 1, "equivalent duplicate suppressed across IDs")
	presenter.advance(4)
	check(presenter.current == card and presenter.alpha == 1, "major card remains readable after four real seconds")
	presenter.advance(4)
	check(presenter.current != card, "major card expires after eight real seconds")
	for kind in ["directive", "salvage_authorized", "traversal_complete", "development_started", "structure_complete", "shelter_increased", "cohort_joined", "source_exhausted", "growth_paused"]:
		check(not Adapter.event_card({"id": 1, "day": 0, "kind": kind, "message": "Secure Water", "evidence": {}}).is_empty(), "event mapping " + kind)
	check(Adapter.event_card({"id": 1, "day": 0, "kind": "governor", "message": "SURVIVAL: low", "evidence": {"water_days": 0.5}}).headline == "WATER RESERVE LOW", "water crisis friendly mapping")
	var slow := Presenter.new()
	var fast := Presenter.new()
	slow.ingest(events)
	fast.ingest(events)
	for i in range(60):
		sim.speed = 1
		slow.advance(0.1)
		sim.speed = 10
		fast.advance(0.1)
	check(slow.current == fast.current and slow.age == fast.age and slow.alpha == fast.alpha, "event lifetime independent of authoritative speed")
	before = snapshot(sim)
	sim.camera_director.advance(8)
	check(sim.camera_director.shots == 1 and not sim.camera_director.current_shot.headline.is_empty(), "meaningful production shot has title")
	var shots: int = sim.camera_director.shots
	hud.camera_button.toggled.emit(false)
	var camera_at: Vector3 = sim.camera_director.rig.target
	sim.camera_director.advance(50)
	check(sim.camera_director.shots == shots and sim.camera_director.rig.target == camera_at, "camera off prevents automatic shots and movement")
	check(snapshot(sim) == before, "camera and event presentation have zero simulation effects")
	sim.camera_director.enabled = true
	sim.camera_director.wide_elapsed = 40
	check(sim.camera_director.choose().key == "overview", "periodic overview")
	var subject: Node3D = sim.citizens[0]
	sim.camera_director.current_shot = sim.camera_director.activity(subject, "ACTIVITY", "Current task")
	sim.camera_director.elapsed = 0
	sim.camera_director.advance(0.1)
	var tracking_error: Vector3 = sim.camera_director.last_focus - sim.camera_director.rig.target
	var original_position: Vector3 = subject.position
	subject.position += Vector3(2, 0, 0)
	sim.camera_director.advance(0.1)
	check((sim.camera_director.last_focus - sim.camera_director.rig.target).length() < tracking_error.length(), "moving subject does not add tracking lag at fast speed")
	subject.position = original_position
	sim.camera_director.current_shot.activity_task = "obsolete task"
	check(not sim.camera_director.title_is_current(), "obsolete worker activity title is hidden")
	sim.camera_director.current_shot = {"key": "settlement", "subtitle": "stale population"}
	check(sim.camera_director.shot_subtitle().begins_with(str(sim.citizens.size())), "settlement subtitle uses live population")
	var points: Array[Vector3] = sim.population.arrival_positions(sim)
	check(points.size() == 5 and points == sim.population.arrival_positions(sim), "five deterministic arrival points")
	var nav: Node = sim.coordinator.navigation
	for i in range(points.size()):
		check(nav.is_walkable(points[i]) and not nav.is_obstacle_position(points[i]) and not nav.path_between(points[i], sim.coordinator.depot_station).is_empty() and nav.room_bounds().has_point(Vector2(points[i].x, points[i].z)), "arrival walkable, connected, in bounds and clear %d" % i)
		for j in range(i): check(points[i].distance_to(points[j]) >= 3.99, "meaningful arrival spacing %d/%d" % [i,j])
	# Isolated fixtures below: these do not run in the autonomous scenario.
	sim.economy.configure({"food": 5000, "water": 5000, "wood": 30, "metal": 20})
	sim.needs.shelter_capacity = 60
	sim.seconds = 1000
	sim.population.stable_since = 600
	var definition: Dictionary = nav.room_definition.duplicate(true)
	nav.room_definition.objects.append({"id": "blocked_fixture", "position": [0,0,0], "dimensions": [240,10,180], "blocks_navigation": true})
	nav._rebuild_grid()
	sim.population.evaluate(sim, sim.status(), false, false)
	check(sim.citizens.size() == 50 and sim.population.cohorts.is_empty() and sim.population.reason.contains("five safe"), "blocked fixture creates zero citizens and explains whole-cohort refusal")
	nav.room_definition = definition
	nav._rebuild_grid()
	sim.population.evaluate(sim, sim.status(), false, false)
	check(sim.citizens.size() == 55 and sim.population.cohorts.size() == 1, "valid fixture spawns entire cohort")
	for i in range(5): check(sim.citizens[50+i].get_script() == preload("res://scripts/citizen_agent.gd") and sim.citizens[50+i].position == points[i] and not sim.citizens[50+i].needs.is_empty(), "real ordinary citizen initialized at distinct point %d" % i)
	check(sim.journal.events[-1].focus == sim.population.cohorts[-1].centroid, "arrival event focuses actual centroid")
	check(sim.development.request("housing"), "isolated housing progress fixture")
	var p: Dictionary = sim.development.active
	p.work = p.required_work * 0.42
	p.stage = "FRAME"
	p.state = "UNDER_CONSTRUCTION"
	var display := Adapter.project(sim)
	check(is_equal_approx(display.progress, 0.42) and display.stage == "Frame construction" and display.delivered == p.delivered and display.required == p.required, "active project maps exact work, stage and materials")
	var worker: Node3D = sim.citizens[0]
	worker.position = p.target
	worker.state = "WORK"
	var task: Dictionary = sim.coordinator.create_construction_task({"task_type": "CONSTRUCTION_BUILD", "project_id": p.id, "target": p.target, "stage": 0}, 0)
	var stored: Dictionary = sim.coordinator._find_task(task.id)
	stored.state = "active"
	sim.coordinator.advance_construction_work(task.id, 0, 0.1)
	check(is_equal_approx(stored.progress, p.work / p.required_work), "development task uses development work fraction")
	var traversal: Dictionary = sim.coordinator.create_construction_task({"task_type": "CONSTRUCTION_BUILD", "target": p.target, "stage": 0}, 0)
	var traversal_stored: Dictionary = sim.coordinator._find_task(traversal.id)
	traversal_stored.state = "active"
	sim.coordinator.advance_construction_work(traversal.id, 0, 0)
	check(traversal_stored.progress == sim.construction.status().stage_progress, "traversal task retains traversal stage progress")
	p.stage = "COMPLETE"
	var render_before := snapshot(sim)
	sim.development.render(p)
	var doors: Array = sim.development.visuals[p.id].find_children("Door", "MeshInstance3D", true, false)
	check(not doors.is_empty() and is_equal_approx(doors[0].get_aabb().size.y, 0.7), "housing door is 1.4 times the real half-inch citizen height")
	check(snapshot(sim) == render_before and sim.development.SIZE == Vector3(12, 7, 10), "citizen-scale render preserves simulation and reserved navigation footprint")
	sim.development.active = {}
	sim.construction.project_created = true
	sim.construction.traversal_deployed = false
	check(Adapter.project(sim).name == "Grapple Route", "active traversal context")
	sim.construction.traversal_deployed = true
	check(Adapter.project(sim).is_empty(), "completed traversal collapses context")
	print("POC46_FAST_" + ("PASS" if failures.is_empty() else "FAIL") + " checks=" + JSON.stringify(checks) + " failures=" + str(failures))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
