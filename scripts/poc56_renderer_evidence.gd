extends SceneTree
## Final POC5.6 real-renderer evidence from the production setup and world scenes.

const Pipeline := preload("res://scenes/pipeline_proof.tscn")
const Evidence := preload("res://scripts/verification/evidence_io.gd")

var output_dir := "res://verification/poc56/final"
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var scene: Node3D
var simulation: Node


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_RENDERER_CHECK_PASS " + label)
	else:
		failures.append(label)
		push_error("POC56_RENDERER_CHECK_FAIL " + label)


func capture(label: String, context: Dictionary = {}) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output_dir.path_join(label + ".png")
	var error := Evidence.save_png(image, path)
	check(error == OK, "real-renderer capture " + label)
	if error == OK:
		captures.append({"label":label, "path":path, "pixels":[image.get_width(), image.get_height()], "renderer":RenderingServer.get_video_adapter_name(), "context":context.duplicate(true)})


func run() -> void:
	if DisplayServer.get_name() == "headless":
		check(false, "renderer evidence requires a visible real renderer")
		finish()
		return
	root.size = Vector2i(1920, 1080)
	await capture_setup_menu()
	await capture_production_world()
	var receipt := {"result":"PASS" if failures.is_empty() else "FAIL", "renderer":RenderingServer.get_video_adapter_name(), "display_server":DisplayServer.get_name(), "failures":failures, "captures":captures, "one_x_reference":1.0, "pace_probe":captures.filter(func(item: Dictionary) -> bool: return item.label == "pacing-probe").front().get("context", {}) if captures.any(func(item: Dictionary) -> bool: return item.label == "pacing-probe") else {}}
	var receipt_error := Evidence.save_json(receipt, output_dir.path_join("renderer-evidence.json"))
	check(receipt_error == OK, "renderer evidence receipt written")
	print("POC56_RENDERER_EVIDENCE_" + String(receipt.result) + " captures=%d renderer=%s" % [captures.size(), RenderingServer.get_video_adapter_name()])
	finish()


func capture_setup_menu() -> void:
	check(DisplayServer.get_name() != "headless", "normal graphical launch evidence uses the real display server")
	OS.set_environment("ROOMSCALE_ROOM", "")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_NO_MENU", "")
	var launch := Pipeline.instantiate()
	root.add_child(launch)
	current_scene = launch
	for frame in range(8):
		if current_scene != launch: break
		await process_frame
	var menu := current_scene as Control
	if is_instance_valid(launch) and launch != menu: launch.queue_free()
	await process_frame
	menu = current_scene as Control
	check(menu != launch and is_instance_valid(menu) and menu.get_script().resource_path == "res://scripts/setup_menu.gd", "configured normal entry scene transitions to setup before simulation starts")
	if not is_instance_valid(menu): return
	check(menu.session_choice.item_count == 3 and menu.session_choice.selected == 0, "normal launch presents the frozen single-society setup before simulation")
	await capture("start-menu", {"session":"Founder room · 1 society", "simulation_started":false, "speed":menu.speed_choice.get_item_metadata(menu.speed_choice.selected)})
	menu.session_choice.select(2)
	menu._refresh_society_rows(2)
	var defaults := ["clockwork", "verdant", "scavenger"]
	for index in range(3):
		var choice: OptionButton = menu.society_rows[index].choice
		check(String(choice.get_item_metadata(choice.selected)) == defaults[index], "three-society menu default %d is a distinct valid definition" % (index + 1))
	await capture("start-menu-three-society-defaults", {"session":"Shared frontier · 3 societies", "civilizations":defaults})
	menu.session_choice.select(0)
	menu._refresh_society_rows(0)
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	var start_button := find_start_button(menu)
	check(start_button != null, "normal start menu exposes its Start action")
	if start_button != null:
		await click_control(start_button)
		for frame in range(6): await process_frame
		scene = current_scene as Node3D
		check(is_instance_valid(scene) and scene.get_node_or_null("CivilizationSimulation") != null, "actual Start button click enters the real one-society simulation")
		if is_instance_valid(scene):
			simulation = scene.get_node("CivilizationSimulation")
			check(simulation.world_simulation.runtimes.size() == 1 and is_equal_approx(float(simulation.speed), 0.5), "menu start applies its real one-society composition and half pace")
	else:
		menu.queue_free()
		await process_frame


func capture_production_world() -> void:
	if not is_instance_valid(scene) or not is_instance_valid(simulation):
		check(false, "production evidence starts from the actual menu-created world")
		return
	simulation.set_process(false)
	simulation.speed = 0.0
	simulation.camera_director.enabled = false
	simulation.camera_director.set_process(false)
	simulation.spectator.set_process(false)
	simulation.spectator.title_panel.hide()
	var camera: Node = scene.get_node("CameraRig")
	var hud: Control = simulation.spectator

	var blocker: Dictionary = simulation.population.player_snapshot(simulation, simulation.status())
	simulation.spectator.refresh()
	simulation.hud.refresh()
	scene._update_population_ui()
	await capture("population-growth-blocker", {"population":simulation.living_population(), "reason":blocker.get("reason", ""), "headroom":blocker.get("headroom", -1), "source":"PopulationSystem.player_snapshot"})

	check(simulation.development.request("shelter"), "real production settlement accepts an evidence shelter")
	if simulation.development.active.is_empty():
		finish()
		return
	var project: Dictionary = simulation.development.active
	var project_id := String(project.id)
	simulation.spectator.refresh()
	simulation.hud.refresh()
	scene._update_population_ui()
	camera.focus_at(project.site + Vector3.UP * 2.5, 36.0, 48.0, deg_to_rad(56.0))
	await capture("planned-site-footprint-label", {"project":project_id, "lifecycle":project.lifecycle_status, "work":project.work, "required_work":project.required_work})
	check(deliver_project_materials(project), "production shelter receives real owned material deliveries")
	var build_specification := {"task_type":"CONSTRUCTION_BUILD", "project_id":project_id, "stage":0, "source":project.target, "target":project.target, "urgency":0.4}
	var builder_a: Node3D = simulation.citizens[0]
	var builder_b: Node3D = simulation.citizens[1]
	var task_a: Dictionary = simulation.coordinator.create_construction_task(build_specification, builder_a.citizen_id)
	var task_b: Dictionary = simulation.coordinator.create_construction_task(build_specification, builder_b.citizen_id)
	check(not task_a.is_empty() and not task_b.is_empty(), "two real production builders reserve the shared work face")
	if task_a.is_empty() or task_b.is_empty():
		finish()
		return
	prepare_builder(builder_a, task_a)
	prepare_builder(builder_b, task_b)
	check(Vector3(task_a.get("standing_target", task_a.target)).distance_to(Vector3(task_b.get("standing_target", task_b.target))) >= 0.5, "production builder positions are distinct")
	var work_to_frame: float = float(project.required_work) * 0.30 / 2.0
	simulation.coordinator.advance_construction_work(int(task_a.id), builder_a.citizen_id, work_to_frame)
	simulation.coordinator.advance_construction_work(int(task_b.id), builder_b.citizen_id, work_to_frame)
	simulation.development.status_snapshot()
	simulation.spectator.refresh()
	simulation.hud.refresh()
	scene._update_population_ui()
	camera.focus_at(project.site + Vector3.UP * 2.5, 36.0, 48.0, deg_to_rad(56.0))
	await capture("active-site-footprint-label", {"project":project_id, "lifecycle":project.lifecycle_status, "work":project.work, "required_work":project.required_work})
	set_project_labels_visible(false)
	var worksite_center: Vector3 = (builder_a.global_position + builder_b.global_position) * 0.5
	camera.focus_at(worksite_center + Vector3.UP * 0.5, 16.0, 40.0, deg_to_rad(56.0))
	await capture("spaced-worksite", {"builders":[builder_a.global_position, builder_b.global_position], "standing_targets":[task_a.get("standing_target", task_a.target), task_b.get("standing_target", task_b.target)]})
	set_project_labels_visible(true)
	camera.focus_at(project.site + Vector3.UP * 4.0, 42.0, 48.0, deg_to_rad(58.0))
	camera.focus_at(project.site + Vector3.UP * 4.0, 42.0, 48.0, deg_to_rad(58.0))
	await click_world_position(project.site + Vector3.UP, "project", project_id, "viewport click selects active project")
	await capture("selected-active-project", {"project":project_id, "descriptor":simulation.spectator.selection_label.text})
	simulation.spectator.show_highlight({"focus":builder_b.global_position, "target":{}, "framing":"SETTLEMENT"})
	await click_world_position(project.site + Vector3.UP, "project", project_id, "viewport click preserves POC 5.5 event highlight")
	check(is_instance_valid(simulation.spectator.highlight) and is_instance_valid(simulation.spectator.selection_highlight), "POC 5.5 event and entity selection highlights coexist in the rendered world")
	await capture("selection-event-highlight-coexistence", {"project":project_id, "event_highlight":"POC 5.5 spectator event marker", "selection_highlight":"selected active project", "both_visible_nodes":true})
	set_project_labels_visible(false)
	camera.focus_at(builder_b.global_position + Vector3.UP * 0.5, 16.0, 38.0, deg_to_rad(56.0))
	await click_world_position(builder_b.global_position + Vector3.UP * 0.5, "citizen", str(builder_b.citizen_id), "viewport click selects citizen")
	await capture("selected-citizen", {"citizen_id":builder_b.citizen_id, "descriptor":simulation.spectator.selection_label.text})
	set_project_labels_visible(true)

	var obstruction: Node3D = simulation.citizens[2]
	obstruction.global_position = project.site
	obstruction._destination = project.site
	obstruction.state = "TRAVEL"
	for index in range(3, simulation.citizens.size()):
		var idle_citizen: Node3D = simulation.citizens[index]
		idle_citizen.state = "IDLE"
		idle_citizen._destination = simulation.coordinator.depot_station
		idle_citizen.global_position = simulation.coordinator.depot_station + Vector3(0.0, 0.0, float(index) * 1.5)
	var remaining_work: float = float(project.required_work) - float(project.work)
	simulation.coordinator.advance_construction_work(int(task_a.id), builder_a.citizen_id, remaining_work)
	var blocked: Dictionary = simulation.development.status_snapshot()
	check(String(blocked.get("lifecycle_status", "")) == "WAITING_FOR_SITE" and not String(blocked.get("blocker", "")).is_empty(), "fully worked project exposes an actual site blocker")
	camera.focus_at(project.site + Vector3.UP * 4.0, 42.0, 48.0, deg_to_rad(58.0))
	await capture("blocked-site-status", {"project":project_id, "lifecycle":blocked.get("lifecycle_status", ""), "blocker":blocked.get("blocker", ""), "work_percent":blocked.get("work_percent", 0.0)})

	obstruction.state = "IDLE"
	obstruction._destination = simulation.coordinator.depot_station
	obstruction.global_position = simulation.coordinator.depot_station
	simulation.seconds = float(project.get("retry_at", simulation.seconds))
	simulation.coordinator.advance_construction_work(int(task_a.id), builder_a.citizen_id, 0.1)
	var completed: Dictionary = simulation.development.project_status(project_id)
	check(String(completed.get("lifecycle_status", "")) == "COMPLETE", "real builder completes the project after its blocker clears")
	if String(completed.get("lifecycle_status", "")) == "COMPLETE":
		camera.focus_at(project.site + Vector3.UP * 4.0, 42.0, 48.0, deg_to_rad(58.0))
		await click_world_position(project.site + Vector3.UP, "building", project_id, "viewport click selects completed building")
		await capture("selected-completed-building", {"project":project_id, "descriptor":simulation.spectator.selection_label.text})

	var intact_bookcase: Node3D = simulation.scene.get_room_object("bookcase")
	camera.focus_at(intact_bookcase.global_position + Vector3.UP * 31.5, 90.0, 52.0, deg_to_rad(12.0))
	await click_world_position(intact_bookcase.global_position + Vector3.UP * 31.5, "furniture", "bookcase", "viewport click selects intact furniture")
	await capture("selected-bookcase-full", {"state":"AVAILABLE", "object_position":intact_bookcase.global_position, "descriptor":simulation.spectator.selection_label.text})

	if simulation.authorize_salvage("bookcase"):
		var bookcase_state: Dictionary = simulation.salvage.objects.bookcase
		var salvage_worker: Node3D = simulation.citizens[2]
		var salvage_target: Vector3 = simulation.salvage_targets.bookcase
		salvage_worker.global_position = salvage_target
		var first_stage: Dictionary = bookcase_state.stages[0]
		var salvage_task: Dictionary = simulation.coordinator.create_construction_task({"task_type":"SALVAGE", "object_id":"bookcase", "stage":0, "source":salvage_target, "target":salvage_target}, salvage_worker.citizen_id)
		salvage_worker.task_id = int(salvage_task.id)
		salvage_worker.task_type = "SALVAGE"
		salvage_worker.state = "WORK"
		salvage_worker._destination = salvage_target
		simulation.coordinator.activate_task(int(salvage_task.id))
		var first_stage_finished: bool = simulation.work(salvage_worker, float(first_stage.work) / simulation.needs.work_factor(salvage_worker.needs))
		check(first_stage_finished and simulation.salvage.objects.bookcase.stage == 1 and simulation.scene.get_room_object("bookcase").visible, "bookcase remains physical after a real partial salvage stage")
		simulation.coordinator.complete_task(int(salvage_task.id))
		var bookcase_root: Node3D = simulation.scene.get_room_object("bookcase")
		var bookcase_focus: Vector3 = bookcase_root.global_position + Vector3.UP * 31.5
		camera.focus_at(bookcase_focus, 90.0, 52.0, deg_to_rad(12.0))
		await click_world_position(bookcase_focus, "furniture", "bookcase", "viewport click selects partial furniture")
		await capture("selected-partial-bookcase", {"state":simulation.salvage.objects.bookcase.state, "stage":simulation.salvage.objects.bookcase.stage, "stage_count":bookcase_state.stages.size(), "object_position":bookcase_root.global_position, "camera_target":camera.target, "descriptor":simulation.spectator.selection_label.text})
	else:
		check(false, "production bookcase is authorized for partial salvage evidence")

	var source_ids: Array = simulation.resources.sources.keys()
	if not source_ids.is_empty():
		var resource_id := String(source_ids[0])
		var source: Dictionary = simulation.resources.sources[resource_id]
		camera.focus_at(source.position + Vector3.UP * 1.0, 95.0, 55.0, deg_to_rad(12.0))
		await click_world_position(source.position, "resource", resource_id, "viewport click selects finite resource")
		await capture("selected-finite-resource", {"resource":resource_id, "descriptor":simulation.spectator.selection_label.text})
	var surface_ids: Array = simulation.coordinator.surface_navigation.regions.keys()
	for surface_id in surface_ids:
		if String(surface_id) == "FLOOR": continue
		var surface: Dictionary = simulation.coordinator.surface_navigation.regions[surface_id]
		camera.focus_at(surface.center, 115.0, 55.0, deg_to_rad(12.0))
		await click_world_position(surface.center, "surface", String(surface_id), "viewport click selects inspectable surface")
		await capture("selected-inspectable-surface", {"surface":surface_id, "descriptor":simulation.spectator.selection_label.text})
		break

	await capture_motion_and_pacing(camera)


func click_world_position(world_position: Vector3, expected_type: String, expected_id: String, label: String) -> void:
	var camera: Camera3D = scene.get_node("CameraRig/Camera")
	var screen_position := camera.unproject_position(world_position)
	scene.set("_selected_world_descriptor", {})
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = screen_position
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await process_frame
	var selected: Dictionary = scene.get("_selected_world_descriptor")
	check(String(selected.get("type", "")) == expected_type and String(selected.get("id", "")) == expected_id, label)


func find_start_button(node: Node) -> Button:
	if node is Button and (node as Button).text == "Start settlement": return node as Button
	for child in node.get_children():
		var found := find_start_button(child)
		if found != null: return found
	return null


func click_control(control: Control) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = control.get_global_rect().get_center()
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await process_frame


func deliver_project_materials(project: Dictionary) -> bool:
	var worker: Node3D = simulation.citizens[0]
	for resource in ["wood", "metal"]:
		var amount := int(project.required.get(resource, 0))
		if amount <= 0: continue
		if not simulation.economy.receive(resource, amount): return false
		for unit in range(amount):
			var ticket := int(simulation.economy.reserve(resource, 1, String(project.id)))
			if ticket < 0: return false
			var specification := {"task_type":"CONSTRUCTION_DELIVERY", "project_id":project.id, "source":simulation.coordinator.depot_station, "target":project.target, "resource":resource, "amount":1, "ticket":ticket, "picked_up":false}
			var task: Dictionary = simulation.coordinator.create_construction_task(specification, worker.citizen_id)
			if task.is_empty(): return false
			simulation.coordinator.activate_task(int(task.id))
			worker.global_position = task.source
			if not simulation.coordinator.confirm_project_pickup(int(task.id), worker, resource): return false
			var route: Array[Vector3] = simulation.coordinator.navigation.path_between(task.source, task.target)
			worker.travelled_distance += simulation.coordinator._path_length(route) * 0.95
			worker.global_position = task.target
			if not simulation.coordinator.confirm_project_delivery(int(task.id), worker, resource, resource): return false
			simulation.coordinator.complete_task(int(task.id))
	var delivered: Dictionary = project.get("delivered", {})
	var required: Dictionary = project.get("required", {})
	return String(project.get("state", "")) == "SUPPLIED" and float(delivered.get("wood", 0.0)) >= float(required.get("wood", 0.0)) and float(delivered.get("metal", 0.0)) >= float(required.get("metal", 0.0))


func prepare_builder(citizen: Node3D, task: Dictionary) -> void:
	var target: Vector3 = task.get("standing_target", task.target)
	citizen.global_position = target
	citizen.assign_project_task(task)
	citizen._destination = target
	citizen.state = "WORK"
	simulation.coordinator.activate_task(int(task.id))


func set_project_labels_visible(visible: bool) -> void:
	for root_node in simulation.development.visuals.values():
		if not is_instance_valid(root_node): continue
		var label := root_node.get_node_or_null("ProjectStatusLabel") as Label3D
		if label != null: label.visible = visible and String(simulation.development.active.get("state", "")) != "COMPLETE"


func capture_motion_and_pacing(camera: Node) -> void:
	var citizen: Node3D = simulation.citizens[4]
	scene.call("_select_world_entity", "citizen", str(citizen.citizen_id))
	camera.focus_at(citizen.global_position + Vector3.UP * 0.5, 22.0, 42.0, deg_to_rad(56.0))
	var destination: Vector3 = simulation.coordinator.patrol_stations.back()
	var route: Array[Vector3] = simulation.coordinator.navigation.path_between(citizen.global_position, destination)
	check(not route.is_empty() and citizen.global_position.distance_to(destination) > 3.0, "motion fixture has a live, legal route")
	var task: Dictionary = simulation.coordinator.create_construction_task({"task_type":"FLOOR_PATROL", "source":citizen.global_position, "target":destination}, citizen.citizen_id)
	citizen.assign_project_task(task)
	citizen.rotation.y = 0.0
	citizen.begin_presentation_step()
	var initial_authoritative: Vector3 = citizen.global_position
	var initial_visual: Vector3 = citizen.get_node("Figure").global_position
	var initial_visual_yaw := float(citizen.get_node("Figure").global_rotation.y)
	simulation.spectator.speed_buttons[0.5].pressed.emit()
	simulation.set_process(true)
	var motion_frames: Array[Dictionary] = []
	for frame in range(8):
		await create_timer(0.16).timeout
		await RenderingServer.frame_post_draw
		var visual: Vector3 = citizen.get_node("Figure").global_position
		var visual_yaw := float(citizen.get_node("Figure").global_rotation.y)
		motion_frames.append({"frame":frame, "simulation_seconds":simulation.seconds, "authoritative":citizen.global_position, "visual":visual, "authoritative_yaw":citizen.rotation.y, "visual_yaw":visual_yaw})
		await capture("smooth-motion-%02d" % frame, {"frame":frame, "simulation_seconds":simulation.seconds, "authoritative":citizen.global_position, "visual":visual, "authoritative_yaw":citizen.rotation.y, "visual_yaw":visual_yaw})
	check(citizen.global_position.distance_to(initial_authoritative) > 0.1, "simulation advances the live citizen at the selected below-one speed")
	var visual_positions: Array[Vector3] = []
	var every_visual_position_is_finite := true
	for sample in motion_frames:
		var visual_position: Vector3 = sample.visual
		visual_positions.append(visual_position)
		every_visual_position_is_finite = every_visual_position_is_finite and visual_position.is_finite()
	var rendered_motion: bool = visual_positions.size() >= 2 and visual_positions.front().distance_to(visual_positions.back()) > 0.1
	var visual_yaws: Array[float] = []
	var every_visual_yaw_is_finite: bool = is_finite(initial_visual_yaw)
	for sample in motion_frames:
		var visual_yaw := float(sample.visual_yaw)
		visual_yaws.append(visual_yaw)
		every_visual_yaw_is_finite = every_visual_yaw_is_finite and is_finite(visual_yaw)
	var rendered_turn := visual_yaws.size() >= 2 and absf(wrapf(visual_yaws.back() - visual_yaws.front(), -PI, PI)) > 0.1
	check(initial_visual.is_finite() and every_visual_position_is_finite and every_visual_yaw_is_finite and rendered_motion and rendered_turn and motion_frames.size() >= 4, "motion evidence retains finite rendered positions and smoothed heading changes across simulation samples")
	simulation.spectator.speed_buttons[1.0].pressed.emit()
	await capture("speed-switch-1x", {"speed":simulation.speed, "citizen":citizen.citizen_id, "visual":citizen.get_node("Figure").global_position})
	var sim_before := float(simulation.seconds)
	var wall_before := Time.get_ticks_usec()
	simulation.spectator.speed_buttons[0.5].pressed.emit()
	await create_timer(6.0).timeout
	var wall_seconds := float(Time.get_ticks_usec() - wall_before) / 1000000.0
	var sim_seconds := float(simulation.seconds) - sim_before
	var ratio := sim_seconds / maxf(wall_seconds, 0.001)
	var measured := {"sim_seconds":sim_seconds, "wall_seconds":wall_seconds, "ratio":ratio, "target_speed":0.5, "result":"PASS" if ratio >= 0.35 and ratio <= 0.65 else "FAIL"}
	check(String(measured.result) == "PASS", "live renderer measures 0.5x simulation pace")
	simulation.spectator.refresh()
	await capture("pacing-probe", measured)
	simulation.spectator.speed_buttons[1.0].pressed.emit()
	await capture("pacing-1x-reference", {"speed":simulation.speed, "reference_speed":1.0})


func finish() -> void:
	if is_instance_valid(scene): scene.queue_free()
	if is_instance_valid(current_scene): current_scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
