extends SceneTree
## Matched production-scene captures for the Tier 1 lighting review.

const RoomDefinitionLoader := preload("res://scripts/room_definition.gd")

var output_directory := ""
var room_file := ""
var room_id := ""
var lighting_profile := "baseline"
var captures: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	output_directory = OS.get_environment("ROOMSCALE_LIGHTING_CAPTURE_DIR")
	var output_root := output_directory
	room_file = OS.get_environment("ROOMSCALE_ROOM_FILE")
	room_id = OS.get_environment("ROOMSCALE_ROOM")
	lighting_profile = OS.get_environment("ROOMSCALE_LIGHTING_PROFILE")
	if lighting_profile.is_empty():
		lighting_profile = "baseline"
	if output_directory.is_empty() or room_file.is_empty() or room_id.is_empty():
		_fail("capture directory, RoomDefinition file, and room id are required")
		return
	if DisplayServer.get_name() == "headless":
		_fail("matched lighting evidence requires the real RoomScale renderer")
		return
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_ROOM_FILE", room_file)
	OS.set_environment("ROOMSCALE_ART_REGISTRY", "res://art/registry.json")
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(output_directory)
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	if error != OK:
		_fail("production scene could not load: %s" % error)
		return
	await scene_changed
	var scene := current_scene as Node3D
	if scene == null or not scene.is_node_ready():
		_fail("RoomScale production scene did not become ready")
		return
	for _frame in range(45):
		await process_frame
	var definition: Dictionary = scene.get("_room_definition")
	if definition.is_empty() or String(definition.get("id", "")) != room_id:
		_fail("expected RoomDefinition %s; loaded %s" % [room_id, String(definition.get("id", ""))])
		return
	if scene.get("_citizens").size() != 50:
		_fail("expected the normal 50-citizen population")
		return
	var rig := scene.get_node_or_null("CameraRig")
	if rig == null or not rig.has_method("focus_at"):
		_fail("production camera rig is unavailable")
		return
	rig.set_process(false)
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null:
		overlay.visible = false
	var profile_names: Array[String] = []
	if lighting_profile == "compare":
		profile_names.append("baseline")
		profile_names.append("candidate")
	else:
		profile_names.append(lighting_profile)
	var profile_results: Dictionary = {}
	for profile in profile_names:
		if profile == "baseline":
			_apply_baseline_profile(scene)
		elif profile.begins_with("candidate"):
			_apply_candidate_profile(scene)
		output_directory = output_root.path_join(profile) if lighting_profile == "compare" else output_root
		DirAccess.make_dir_recursive_absolute(output_directory)
		captures.clear()
		if not await _capture_views(scene):
			return
		var environment_node := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
		var key := scene.get_node_or_null("KeyLight") as DirectionalLight3D
		var fill := scene.get_node_or_null("RoomFill") as OmniLight3D
		profile_results[profile] = {
			"lighting": _lighting_state(environment_node, key, fill, scene),
			"captures": captures.duplicate(true),
		}
	output_directory = output_root
	var receipt := {
		"status": "pass",
		"room_id": room_id,
		"room_file": room_file,
		"profile": lighting_profile,
		"population": scene.get("_citizens").size(),
		"registry_path": "res://art/registry.json",
		"engine": Engine.get_version_info(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"viewport": {"width": root.size.x, "height": root.size.y},
		"profiles": profile_results,
	}
	var receipt_file := FileAccess.open(output_directory.path_join("receipt.json"), FileAccess.WRITE)
	if receipt_file == null:
		_fail("capture receipt cannot be written")
		return
	receipt_file.store_string(JSON.stringify(receipt, "\t") + "\n")
	receipt_file.close()
	print("ROOMSCALE_LIGHTING_CAPTURE_PASS room=%s profile=%s output=%s" % [room_id, lighting_profile, output_directory])
	quit(0)


func _capture_views(scene: Node3D) -> bool:
	var definition: Dictionary = scene.get("_room_definition")
	var floor: Dictionary = definition.get("floor", {})
	var center := _vector3(floor.get("center", [0.0, 0.0, 0.0]))
	center.y = float(floor.get("height", 0.0))
	var camera_data: Dictionary = definition.get("camera", {})
	var yaw := deg_to_rad(float(camera_data.get("yaw_degrees", 0.0)))
	if not await _capture(scene, "room-overview", center + Vector3.UP * 12.0, 330.0, 52.0, yaw):
		return false
	if not await _capture(scene, "room-opposite-angle", center + Vector3.UP * 12.0, 330.0, 52.0, yaw + PI * 0.5):
		return false
	var landmarks: Dictionary = definition.get("landmarks", {})
	var workshop := scene.get_node_or_null("Settlement/Workshop") as Node3D
	var work_area := scene.get_node_or_null("Settlement/WorkArea") as Node3D
	if landmarks.has("workshop") and landmarks.has("work_area"):
		if workshop == null or work_area == null:
			_fail("settlement landmarks exist but production nodes are missing")
			return false
		var settlement_focus := (workshop.global_position + work_area.global_position) * 0.5 + Vector3.UP * 4.0
		if not await _capture(scene, "settlement-gameplay", settlement_focus, 64.0, 42.0, 0.25):
			return false
	if room_id == "room_photo_luna":
		if not await _capture(scene, "room-photo-gameplay", center + Vector3.UP * 12.0, 220.0, 52.0, yaw):
			return false
	return true


func _apply_baseline_profile(scene: Node3D) -> void:
	var key := scene.get_node("KeyLight") as DirectionalLight3D
	key.light_color = Color("ffffff")
	key.light_energy = 0.8
	key.light_angular_distance = 0.0
	key.shadow_blur = 1.0
	key.shadow_opacity = 1.0
	var fill := scene.get_node("RoomFill") as OmniLight3D
	fill.light_energy = 1.2
	var environment_node := scene.get_node("WorldEnvironment") as WorldEnvironment
	environment_node.environment.background_color = Color("17212b")
	environment_node.environment.ambient_light_energy = 0.72
	environment_node.environment.glow_enabled = true
	environment_node.environment.glow_intensity = 0.14
	environment_node.environment.glow_bloom = 0.04


func _apply_candidate_profile(scene: Node3D) -> void:
	var key := scene.get_node("KeyLight") as DirectionalLight3D
	key.light_color = Color("fff2e2")
	key.light_energy = 0.92
	key.light_angular_distance = 0.5
	key.shadow_blur = 1.25
	key.shadow_opacity = 0.82
	var fill := scene.get_node("RoomFill") as OmniLight3D
	fill.light_energy = 0.65
	var environment_node := scene.get_node("WorldEnvironment") as WorldEnvironment
	environment_node.environment.background_color = Color("43566a")
	environment_node.environment.ambient_light_energy = 0.56
	environment_node.environment.glow_enabled = false

func _lighting_state(environment_node: WorldEnvironment, key: DirectionalLight3D, fill: OmniLight3D, scene: Node3D) -> Dictionary:
	return {
		"key_energy": key.light_energy,
		"key_color": key.light_color.to_html(false),
		"key_angular_distance": key.light_angular_distance,
		"key_shadow_blur": key.shadow_blur,
		"key_shadow_opacity": key.shadow_opacity,
		"fill_energy": fill.light_energy,
		"background_color": environment_node.environment.background_color.to_html(false),
		"ambient_energy": environment_node.environment.ambient_light_energy,
		"glow_enabled": environment_node.environment.glow_enabled,
		"lantern_energy": (scene.get_node("SettlementLanternFill") as OmniLight3D).light_energy,
	}


func _capture(scene: Node3D, phase: String, focus: Vector3, distance: float, tilt: float, yaw: float) -> bool:
	var rig := scene.get_node("CameraRig")
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	rig.focus_at(focus, distance, tilt, yaw)
	rig.distance = distance
	rig.call("_apply_transform")
	for _frame in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = scene.get_viewport().get_texture().get_image()
	if image.is_empty() or image.get_width() != 1280 or image.get_height() != 720:
		_fail("render %s returned an invalid viewport image" % phase)
		return false
	var path := output_directory.path_join("%s.png" % phase)
	if image.save_png(path) != OK:
		_fail("render %s could not be saved" % phase)
		return false
	captures.append({
		"phase": phase,
		"path": path,
		"production_path": true,
		"camera": {
			"focus": rig.get("target"),
			"distance_inches": rig.get("distance"),
			"tilt_degrees": rig.get("tilt_degrees"),
			"yaw_radians": rig.get("yaw"),
			"position": camera.global_position,
			"fov_degrees": camera.fov,
		},
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
	})
	return true


func _vector3(value: Variant) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO


func _fail(reason: String) -> void:
	push_error("ROOMSCALE_LIGHTING_CAPTURE_FAIL: " + reason)
	quit(1)