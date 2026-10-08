extends SceneTree
## Main-scene contract check for civilization presentation.
## Gameplay smoke proves the shared simulation; this verifies the selected
## civilization actually changes the production scene the player sees while
## preserving production-owned Clockwork nodes that the scene still references.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	_check(error == OK, "production main scene must load")
	if error != OK:
		_finish()
		return
	# Allow the production scene to complete _ready and the presentation autoload
	# to observe it on a process tick. This does not advance or fake gameplay.
	await create_timer(0.75).timeout
	var scene := current_scene as Node3D
	_check(scene != null, "production scene must become current_scene")
	if scene == null:
		_finish()
		return
	_check(scene.is_node_ready(), "presentation must observe a ready production scene")
	var definition: Variant = scene.get_meta("civilization_definition", {})
	_check(definition is Dictionary and String(definition.get("id", "")) == "verdant", "active production scene must carry Verdant definition")
	var settlement := scene.get_node_or_null("Settlement") as Node3D
	_check(settlement != null, "settlement must exist")
	if settlement != null:
		var workshop := settlement.get_node_or_null("Workshop") as Node3D
		var depot := settlement.get_node_or_null("Depot") as Node3D
		var housing := settlement.get_node_or_null("Housing") as Node3D
		var work_area := settlement.get_node_or_null("WorkArea") as Node3D
		_check(workshop != null and workshop.has_node("VerdantOverlay/RootPlatform"), "Workshop must render a Growth Nursery overlay")
		_check(depot != null and depot.has_node("VerdantOverlay/WovenFloor"), "Depot must render a Seed Cache overlay")
		_check(housing != null and housing.has_node("VerdantOverlay/HomePod0"), "Housing must render Pod Homes")
		_check(work_area != null and work_area.has_node("VerdantOverlay/CultivationMat"), "Work area must render a Cultivation Circle")
		var boiler: Node3D = null
		if workshop != null:
			boiler = workshop.get_node_or_null("Boiler") as Node3D
		_check(boiler != null and not boiler.visible, "Clockwork workshop nodes must be preserved but hidden")
	var citizens: Variant = scene.get("_citizens")
	_check(citizens is Array and not citizens.is_empty(), "production population must exist")
	if citizens is Array and not citizens.is_empty():
		var citizen := citizens[0] as Node3D
		var figure := citizen.get_node_or_null("Figure") as Node3D
		_check(figure != null and figure.has_node("AcornCap"), "Verdant citizen must receive acorn/woodland headgear")
		var clockwork_cap: Node3D = null
		if figure != null:
			clockwork_cap = figure.get_node_or_null("ClockworkCap") as Node3D
		_check(clockwork_cap != null and not clockwork_cap.visible, "Clockwork cap must be hidden for Verdant citizen")
		var rig := scene.get_node("CameraRig")
		rig.set_citizen_focus(citizen)
		rig.set_view_mode(2)
		var original_distance: float = rig.distance
		rig.zoom_by(0.88)
		_check(rig.distance < original_distance, "inward citizen zoom must magnify rather than jump out to room distance")
		await create_timer(0.6).timeout
		var camera := scene.get_viewport().get_camera_3d()
		_check(camera.global_position.distance_to(citizen.global_position) < 12, "LOD regression must exercise an actual close camera")
		citizen.refresh_visual_lod()
		if figure != null:
			for detail in figure.get_children():
				var detail_name := String(detail.name)
				if detail_name.begins_with("Goggle") or detail_name.begins_with("Lens") or detail_name.begins_with("ShoulderPlate") or detail_name == "Buckle":
					_check(not detail.visible, "citizen LOD must not revive Clockwork ornament %s" % detail_name)
	_check(scene.has_node("VerdantInfluence"), "Verdant initial reclamation layer must exist")
	_check_rotated_reclamation_support(scene)
	_check_banner(scene)
	scene.set("_presentation_mode", false)
	scene._apply_presentation_mode()
	_check_banner(scene)
	scene.set("_presentation_mode", true)
	scene._apply_presentation_mode()
	_check_banner(scene)
	await _check_scene_reload(scene.get_instance_id())
	await _check_established_hud()
	_finish()


func _check_banner(scene: Node3D) -> void:
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	_check(overlay != null, "production Overlay must remain a CanvasLayer")
	var banner: Label = null
	if overlay != null:
		banner = overlay.get_node_or_null("CivilizationBanner") as Label
	_check(banner != null and banner.text.contains("Verdant"), "player UI must identify Verdant")
	if banner == null:
		return
	_check(banner.is_visible_in_tree(), "civilization identity must be visible to the player")
	var presenter := root.get_node("CivilizationPresentation")
	_check(bool(presenter.get("_scene_applied")), "scene must only be marked applied after its banner exists")
	# Refreshing identity must reuse the UI owned by this scene.
	_check(bool(presenter._ensure_banner(scene)), "ready production Overlay must accept the civilization banner")
	_check(overlay.get_node_or_null("CivilizationBanner") == banner, "banner refresh must preserve the scene-owned label")
	var banner_count := 0
	for child in overlay.get_children():
		if String(child.name).begins_with("CivilizationBanner"):
			banner_count += 1
	_check(banner_count == 1, "normal initialization and refresh must create exactly one banner")


func _check_rotated_reclamation_support(scene: Node3D) -> void:
	# Pure geometry fixture: transform actual target dimensions with the same
	# 3D basis as room objects. This never changes the room or production state.
	var surface: Dictionary = scene.get_node("SurfaceNavigation").goal_surface()
	surface.rotation_degrees = 37.0
	var center: Vector3 = surface.center
	var half: Vector2 = surface.dimensions * 0.5
	var basis := Basis(Vector3.UP, deg_to_rad(37.0))
	var inside := center + basis * Vector3(half.x - 0.8, 0, half.y - 0.8)
	var outside := center + basis * Vector3(half.x + 0.8, 0, half.y - 0.8)
	var presenter := root.get_node("CivilizationPresentation")
	_check(presenter._surface_contains(surface, inside, 0.5), "reclamation must accept supported points on a rotated surface")
	_check(not presenter._surface_contains(surface, outside, 0.5), "reclamation must reject points beyond a rotated furniture edge")


func _check_scene_reload(previous_scene_id: int) -> void:
	# A real scene transition checks that the autoload discards its old UI owner
	# and waits for the replacement production scene to finish initialization.
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	_check(error == OK, "replacement production main scene must load")
	if error != OK:
		return
	await scene_changed
	await process_frame
	await process_frame
	var scene := current_scene as Node3D
	_check(scene != null and scene.get_instance_id() != previous_scene_id, "reload must create a new production scene")
	if scene == null:
		return
	_check(scene.is_node_ready(), "replacement production scene must finish initialization")
	_check_banner(scene)


func _check_established_hud() -> void:
	var previous_room := OS.get_environment("ROOMSCALE_ROOM")
	OS.set_environment("ROOMSCALE_ROOM", "room_poc4")
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	_check(error == OK, "established simulation scene must load")
	if error != OK:
		OS.set_environment("ROOMSCALE_ROOM", previous_room)
		return
	await scene_changed
	await process_frame
	await process_frame
	OS.set_environment("ROOMSCALE_ROOM", previous_room)
	var scene := current_scene as Node3D
	var simulation := scene.get_node_or_null("CivilizationSimulation")
	_check(simulation != null, "established simulation HUD must exist")
	if simulation == null:
		return
	var hud: Control = simulation.get("hud")
	hud.refresh()
	var resources: Label = hud.get("resources")
	for label in ["Living Fiber", "Resin", "Growth Spores"]:
		_check(resources.text.contains(label), "established HUD must identify %s" % label)
	_check(not resources.text.contains("Wood") and not resources.text.contains("Metal"), "established Verdant HUD must not leak Clockwork resource names")
	var directives := hud.get_node("Directives") as Label
	_check(directives.text.contains("Living Vine"), "established objectives must identify Living Vine traversal")
	_check_banner(scene)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("ROOMSCALE_CIVILIZATION_VISUAL_PASS civilization=verdant settlement=true citizen=true influence=true ui=true ownership_preserved=true")
		quit(0)
	else:
		push_error("ROOMSCALE_CIVILIZATION_VISUAL_FAIL %s" % JSON.stringify(failures))
		quit(1)
