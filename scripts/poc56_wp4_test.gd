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
