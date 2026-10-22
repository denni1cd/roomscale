extends SceneTree
## Semantic inspection and selection coexistence checks on the production scene.

const Pipeline := preload("res://scenes/pipeline_proof.tscn")
const Inspector := preload("res://scripts/world_entity_inspector.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_WP4_CHECK_PASS " + label)
	else:
		failures.append(label)
		print("POC56_WP4_CHECK_FAIL " + label)

func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_poc47")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	root.size = Vector2i(1920, 1080)
	var scene := Pipeline.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	var citizen := Inspector.describe(sim, "citizen", "0")
	check(citizen.get("valid", false) and citizen.title == "Citizen 01" and "Task:" in "\n".join(citizen.details), "citizen descriptor uses the live agent identity and task")
	var furniture := Inspector.describe(sim, "furniture", "bookcase")
	check(furniture.get("valid", false) and furniture.title == "Bookcase" and "Salvage:" in "\n".join(furniture.details), "furniture descriptor uses semantic name and finite salvage state")
	var source_id := String(sim.resources.sources.keys()[0])
	var source := Inspector.describe(sim, "resource", source_id)
	check(source.get("valid", false) and "remaining" in "\n".join(source.details).to_lower(), "resource descriptor exposes finite remaining stock")
	var surface_id := String(sim.scene.get_node("SurfaceNavigation").goal_surface_id)
	var surface := Inspector.describe(sim, "surface", surface_id)
	check(surface.get("valid", false) and "Access:" in "\n".join(surface.details), "surface descriptor explains its current connection")
	check(sim.development.request("shelter"), "production project fixture creates a real active build project")
	var project_id := String(sim.development.active.id)
	var active_project: Dictionary = sim.development.active
	var project := Inspector.describe(sim, "project", project_id)
	check(project.get("valid", false) and project.title == "Shelter" and "Blocker:" in "\n".join(project.details), "project descriptor reports authoritative progress and blocker")
	await click_world_position(scene, sim, active_project.site + Vector3.UP, "project", project_id, "viewport click selects an active project")
	check(scene._selected_world_descriptor.type == "project" and sim.hud.world_descriptor.id == project_id, "selected project reaches both normal inspector surfaces")
	sim.spectator.show_highlight({"focus":project.focus, "target":{}, "framing":"SETTLEMENT"})
	var event_highlight: Node3D = sim.spectator.highlight
	var bookcase: Node3D = sim.scene.get_room_object("bookcase")
	await click_world_position(scene, sim, bookcase.global_position + Vector3.UP * 31.5, "furniture", "bookcase", "viewport click selects room furniture")
	check(is_instance_valid(event_highlight) and is_instance_valid(sim.spectator.selection_highlight), "entity selection highlight coexists with POC 5.5 event highlight")
	await test_furniture_salvage_selection(scene, sim)
	await click_world_position(scene, sim, sim.citizens[0].global_position + Vector3.UP, "citizen", str(sim.citizens[0].citizen_id), "viewport click selects a citizen")
	var resource_id := String(sim.resources.sources.keys()[0])
	var resource: Dictionary = sim.resources.sources[resource_id]
	await click_world_position(scene, sim, resource.position, "resource", resource_id, "viewport click selects a finite resource")
	var inspectable_surface_id := String(scene.surface_navigation_goal_id())
	var inspectable_surface: Dictionary = sim.coordinator.surface_navigation.regions[inspectable_surface_id]
	await click_world_position(scene, sim, inspectable_surface.center, "surface", inspectable_surface_id, "viewport click selects an inspectable surface")
	check(scene._selected_surface == inspectable_surface_id and scene._reach_button.visible, "goal-surface click preserves the Reach/Explore action")
	scene.queue_free()
	await process_frame
	await test_strategic_site_click()
	print("POC56_WP4_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func test_furniture_salvage_selection(scene: Node, sim: Node) -> void:
	var salvageable: Array[String] = []
	for object_id in sim.salvage.objects:
		var id := String(object_id)
		if sim.salvage.depleted(id) or bool(sim.salvage.objects[id].authorized): continue
		if not sim.salvage_approaches(id).is_empty(): salvageable.append(id)
	check(salvageable.size() >= 2, "production access checks expose at least two unapproved salvageable furniture objects")
	if salvageable.size() < 2: return
	var object_a := salvageable[0]
	var object_b := salvageable[1]
	check(sim.hud.select_object(object_a) and sim.hud.object_ids[sim.hud.object_choice.selected] == object_a, "existing salvage selector is explicitly set to object A")
	check(not sim.salvage.objects[object_a].authorized and not sim.salvage.objects[object_b].authorized, "both selected test objects begin unauthorized")
	var object_b_data: Dictionary = sim.resources.objects[object_b].data
	var object_b_dimensions: Array = object_b_data.get("dimensions", [0, 0, 0])
	var object_b_root: Node3D = sim.scene.get_room_object(object_b)
	var object_b_focus := object_b_root.global_position + Vector3.UP * float(object_b_dimensions[1]) * 0.5
	await click_world_position(scene, sim, object_b_focus, "furniture", object_b, "real viewport click selects furniture B after selector A")
	var selected: Dictionary = scene.get("_selected_world_descriptor")
	check(String(selected.get("id", "")) == object_b and String(selected.get("type", "")) == "furniture", "generalized inspector descriptor identifies clicked furniture B")
	check(sim.hud.object_ids[sim.hud.object_choice.selected] == object_b and sim.hud.world_descriptor.get("id", "") == object_b, "existing salvage selector and HUD inspector both synchronize to furniture B")
	check(not sim.hud.authorize.disabled, "Authorize Salvage action is enabled for the selected unapproved furniture")
	check(int(sim.camera_director.mode) == sim.camera_director.OFF, "viewport furniture selection transfers camera ownership to manual control")
	check(is_instance_valid(sim.spectator.highlight) and is_instance_valid(sim.spectator.selection_highlight), "furniture selection preserves the POC 5.5 event highlight")
	# WP4 runs in fishbowl mode, where the normal HUD is intentionally hidden. Reveal
	# the same production controls so this click still traverses the real Button path.
	sim.hud.show()
	sim.hud.inspection.show()
	sim.hud.object_choice.show()
	sim.hud.authorize.show()
	if sim.hud.fishbowl_events != null: sim.hud.fishbowl_events.hide()
	if sim.hud.fishbowl_development != null: sim.hud.fishbowl_development.hide()
	await click_control(sim.hud.authorize)
	check(bool(sim.salvage.objects[object_b].authorized), "normal Authorize Salvage button authorizes clicked furniture B")
	check(not bool(sim.salvage.objects[object_a].authorized), "previously selected object A is not authorized by furniture B click")
	selected = scene.get("_selected_world_descriptor")
	check(String(selected.get("id", "")) == object_b and "Authorization: Authorized" in "\n".join(selected.get("details", [])), "world selection descriptor refreshes to authorized state after the action")
	check(sim.hud.inspection.text.contains("Authorization: Authorized") and sim.hud.inspection.text.contains("Salvage authorized"), "HUD inspector shows authoritative authorization state and action result")
	check(sim.spectator.selection_label.text.contains("Authorization: Authorized") and sim.hud.authorize.disabled, "spectator inspector and action availability refresh after authorization")
	sim.hud.hide()

	var non_salvageable_id := "rug"
	var non_salvageable: Node3D = sim.scene.get_room_object(non_salvageable_id)
	var non_salvageable_data: Dictionary = sim.resources.objects[non_salvageable_id].data
	var non_salvageable_dimensions: Array = non_salvageable_data.get("dimensions", [0, 0, 0])
	var non_salvageable_focus := non_salvageable.global_position + Vector3.UP * float(non_salvageable_dimensions[1]) * 0.5
	await click_world_position(scene, sim, non_salvageable_focus, "furniture", non_salvageable_id, "non-salvageable furniture remains selectable for inspection")
	selected = scene.get("_selected_world_descriptor")
	check("Authorization: Not salvageable" in "\n".join(selected.get("details", [])) and sim.hud.object_choice.selected == -1 and sim.hud.authorize.disabled, "non-salvageable inspection clears stale salvage choice and disables its action")

	check(sim.authorize_salvage(object_a), "production authorization accepts furniture A for depletion regression")
	var worker: Node3D = sim.citizens[0]
	var target: Vector3 = sim.salvage_targets[object_a]
	worker.global_position = target
	var state: Dictionary = sim.salvage.objects[object_a]
	var root: Node3D = sim.scene.get_room_object(object_a)
	for stage_index in range(state.stages.size()):
		var stage: Dictionary = state.stages[stage_index]
		var task: Dictionary = sim.coordinator.create_construction_task({"task_type":"SALVAGE", "object_id":object_a, "stage":stage_index, "source":target, "target":target}, worker.citizen_id)
		worker.task_id = int(task.id)
		worker.task_type = "SALVAGE"
		worker.state = "WORK"
		worker._destination = target
		sim.coordinator.activate_task(int(task.id))
		var completed: bool = sim.work(worker, float(stage.work) / sim.needs.work_factor(worker.needs))
		check(completed, "real production salvage completes furniture A stage %d" % (stage_index + 1))
		sim.coordinator.complete_task(int(task.id))
	check(sim.salvage.depleted(object_a) and not root.visible, "furniture A is physically removed only after production salvage depletion")
	var camera: Camera3D = scene.get_node("CameraRig/Camera")
	scene.get_node("CameraRig").focus_at(root.global_position + Vector3.UP * float(sim.resources.objects[object_a].data.dimensions[1]) * 0.5, 90.0, 52.0, 0.0)
	await process_frame
	var removed_position := camera.unproject_position(root.global_position + Vector3.UP * float(sim.resources.objects[object_a].data.dimensions[1]) * 0.5)
	scene.set("_selected_world_descriptor", {})
	var selected_removed: bool = scene.select_inspectable_entity_at_screen_position(removed_position)
	selected = scene.get("_selected_world_descriptor")
	check(not selected_removed or selected.get("type", "") != "furniture" or selected.get("id", "") != object_a, "depleted furniture A cannot be selected through the generalized picker")


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

func click_world_position(scene: Node, sim: Node, world_position: Vector3, expected_type: String, expected_id: String, label: String) -> void:
	var camera: Camera3D = scene.get_node("CameraRig/Camera")
	scene.get_node("CameraRig").focus_at(world_position, 90.0, 52.0, 0.0)
	await process_frame
	var screen_position := camera.unproject_position(world_position)
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
	if String(selected.get("type", "")) != expected_type or String(selected.get("id", "")) != expected_id:
		print("POC56_WP4_CLICK_DEBUG label=%s expected=%s:%s selected=%s:%s screen=%s world=%s" % [label, expected_type, expected_id, String(selected.get("type", "")), String(selected.get("id", "")), screen_position, world_position])
	check(String(selected.get("type", "")) == expected_type and String(selected.get("id", "")) == expected_id, label)

func test_strategic_site_click() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_conflict")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_CONFLICT", "1")
	OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO", "clockwork_vs_verdant")
	OS.set_environment("ROOMSCALE_SESSION_CIVILIZATIONS", "clockwork,verdant")
	var scene := Pipeline.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	await physics_frame
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	sim.camera_director.set_process(false)
	sim.spectator.set_process(false)
	var sites: Dictionary = sim.world_simulation.territory.sites
	check(not sites.is_empty(), "shared-world production fixture exposes stable strategic sites")
	if not sites.is_empty():
		var site_id := String(sites.keys()[0])
		var site: Dictionary = sites[site_id]
		await click_world_position(scene, sim, site.position + Vector3.UP, "site", site_id, "viewport click selects strategic site")
	scene.queue_free()
	await process_frame
