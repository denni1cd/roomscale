extends SceneTree
## V3/V4/V11: exercise real input dispatch and actual rendered widgets/rig.
const Evidence := preload("res://scripts/verification/evidence_io.gd")
var failures: Array[String] = []
var checks: Array[String] = []
var cadence_traces: Array[Dictionary] = []
var capture_metadata: Array[Dictionary] = []
var capture_dir := "res://verification/poc55/graphics"
func _initialize() -> void: call_deferred("run")
func check(value: bool, description: String) -> void:
	checks.append(description)
	if not value:
		failures.append(description)
		push_error("POC55_UI_FAIL " + description)
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	capture_metadata.append({"label":label, "pixels":[image.get_width(), image.get_height()], "logical_viewport":str(root.get_visible_rect()), "renderer":DisplayServer.get_name()})
	check(Evidence.save_png(image, capture_dir.path_join(label + ".png")) == OK, "capture " + label)
func settle(rig: Node, seconds: float = 2.0) -> void:
	for tick in range(int(seconds * 60)):
		rig._process(1.0 / 60.0)
func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_poc45")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	root.size = Vector2i(1920, 1080)
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var sim: Node = scene.get_node("CivilizationSimulation")
	var director: Node = sim.camera_director
	var hud: Control = sim.spectator
	var rig: Node = scene.get_node("CameraRig")
	sim.set_process(false)
	director.set_process(false)
	hud.set_process(false)
	rig.set_process(false)
	await process_frame
	check(hud.camera_button.item_count == 4, "four visible modes")
	for mode in [2, 3, 1]:
		for key in [KEY_1, KEY_2, KEY_3, KEY_W, KEY_A, KEY_S, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_Q, KEY_E]:
			if mode == 1: director.follow(director.follow_choices()[0])
			else: director.set_mode(mode)
			var input := InputEventKey.new()
			input.keycode = key
			input.physical_keycode = key
			input.pressed = true
			Input.parse_input_event(input)
			await process_frame
			rig._process(0.1)
			check(director.mode == 0, "real keyboard " + str(key) + " exits mode " + str(mode))
			input = input.duplicate()
			input.pressed = false
			Input.parse_input_event(input)
			await process_frame
		for button in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if mode == 1: director.follow(director.follow_choices()[0])
			else: director.set_mode(mode)
			var mouse := InputEventMouseButton.new()
			mouse.button_index = button
			mouse.pressed = true
			mouse.position = Vector2(1200, 400)
			Input.parse_input_event(mouse)
			await process_frame
			if button in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
				var motion := InputEventMouseMotion.new()
				motion.position = mouse.position + Vector2(20,10)
				motion.relative = Vector2(20,10)
				Input.parse_input_event(motion)
				await process_frame
			check(director.mode == 0, "real mouse " + str(button) + " exits mode " + str(mode))
			mouse = mouse.duplicate()
			mouse.pressed = false
			Input.parse_input_event(mouse)
			await process_frame
			director.advance(600)
			check(director.mode == 0, "manual OFF persists after 600 real seconds")
		director.set_mode(mode if mode != 1 else 2)
		rig.request_spectator_frame(Vector3.ZERO, 30)
		rig._process(0.1)
		check(director.mode != 0, "programmatic camera request preserves Director")
		director.set_mode(0)
	hud.advance(0.1)
	check(hud.camera_button.selected == 0, "visible mode reflects manual OFF")
	await capture("manual-override-off")
	var citizen: Node3D = sim.citizens[0]
	sim.journal.record(sim.seconds, "COMBAT_CASUALTY", "Citizen remembered", {}, citizen.global_position, "ui-selected", {"subject_type":"citizen", "subject_id":citizen.citizen_id})
	hud.advance(0.1)
	await process_frame
	var row: Button = hud.feed_rows.get_child(1)
	var event: Dictionary = row.get_meta("event")
	director.set_mode(2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = row.get_global_rect().get_center()
	click.pressed = true
	root.push_input(click, true)
	await process_frame
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	await process_frame
	settle(rig)
	check(director.mode == 0 and is_instance_valid(hud.highlight), "click exits Director and creates marker")
	check(rig.target.distance_to(citizen.global_position) < 4.0 and rig.position.distance_to(rig.target) < 0.1, "real event-row click physically reaches live subject")
	if not is_instance_valid(hud.highlight):
		quit(1)
		return
	var previous: Vector3 = hud.highlight.global_position
	citizen.global_position += Vector3(1, 0, 0)
	hud.advance_highlight(0.1)
	check(hud.highlight.global_position.distance_to(previous) > 0.5, "highlight tracks live subject")
	citizen.global_position -= Vector3(1, 0, 0)
	hud.advance_highlight(0)
	await capture("click-to-focus-highlight")
	hud.advance_highlight(5.0)
	check(not is_instance_valid(hud.highlight), "highlight expires")
	director.advance(600)
	check(director.mode == 0, "click does not recapture camera")
	var invalid := event.duplicate(true)
	invalid.subject_id = -999
	invalid.focus_valid = false
	check(not director.resolve_event(invalid).get("valid", false), "invalid event has no invented focus")
	invalid.focus_valid = true
	check(director.resolve_event(invalid).get("valid", false), "historical focus fallback")
	var f3 := InputEventKey.new()
	f3.keycode = KEY_F3
	f3.pressed = true
	Input.parse_input_event(f3)
	await process_frame
	check(hud.diagnostics, "real F3 diagnostics")
	hud.set_diagnostics(false)
	for index in range(12):
		sim.journal.record(sim.seconds + index, ["growth_paused", "development_started", "structure_complete", "COMBAT_CASUALTY"][index % 4], "Story " + str(index), {}, citizen.global_position, "ui:" + str(index))
	hud.advance(0.1)
	check(hud.feed_rows.get_child_count() >= 9, "persistent multi-event feed")
	await capture("event-feed-priorities")
	for viewport_size in [Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = viewport_size
		await process_frame
		check(not hud.event_panel.get_global_rect().intersects(hud.controls_panel.get_global_rect()), "feed controls disjoint at " + str(viewport_size))
		check(not hud.event_panel.get_global_rect().intersects(hud.project_panel.get_global_rect()), "feed project disjoint at " + str(viewport_size))
		check(not hud.event_panel.get_global_rect().intersects(hud.title_panel.get_global_rect()), "feed title disjoint at " + str(viewport_size))
	director.set_mode(0)
	for automatic_mode in [2, 3]:
		var baseline: Array = []
		for rate in [1.0, 4.0, 10.0]:
			hud.speed_buttons[rate].pressed.emit()
			var observed := preload("res://scripts/fishbowl_camera_director.gd").new()
			scene.add_child(observed)
			observed.configure(sim)
			observed.set_process(false)
			observed.set_spectator_seed(5505)
			observed.set_mode(automatic_mode)
			var trace: Array[Dictionary] = []
			var previous_shots := 0
			var previous_cut := -100.0
			for tick in range(384):
				observed.advance(0.25)
				rig._process(0.25)
				if observed.shots != previous_shots:
					var real_time := (tick + 1) * 0.25
					check(real_time - previous_cut >= 5.0, "minimum actual shot dwell mode " + str(automatic_mode) + " speed " + str(rate))
					trace.append({"real_seconds":real_time, "key":observed.current_shot.key})
					previous_cut = real_time
					previous_shots = observed.shots
			check(trace.size() >= 8, "actual automatic shot trace is exercised mode " + str(automatic_mode))
			if rate == 1.0: baseline = trace.duplicate(true)
			else: check(trace == baseline, "actual shot timing and targets identical speed " + str(rate) + " mode " + str(automatic_mode))
			cadence_traces.append({"mode":automatic_mode, "simulation_speed":rate, "spectator_seed":5505, "real_step":0.25, "real_horizon":96.0, "shots":trace})
			observed.set_mode(0)
			observed.free()
	Evidence.save_json({"traces":cadence_traces}, "res://verification/poc55/cadence.json")
	Evidence.save_json({"result": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures, "captures":capture_metadata}, "res://verification/poc55/ui-headless.json" if DisplayServer.get_name() == "headless" else "res://verification/poc55/ui.json")
	scene.queue_free()
	await process_frame
	print("POC55_UI_" + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
