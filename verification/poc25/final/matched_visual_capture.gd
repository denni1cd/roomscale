extends SceneTree

const ROOM_FILE := "res://verification/poc2/candidates/primary/attempt-7/room_photo_luna.json"
const REGISTRY_PATH := "res://verification/poc25/final/best-current-art-showcase-registry-v089.json"
const CAPTURE_DIRECTORY := "res://verification/poc25/final/matched-visual-comparison"
const IMAGE_PATH := CAPTURE_DIRECTORY + "/final-matched.png"
const RECEIPT_PATH := CAPTURE_DIRECTORY + "/final-capture-receipt.json"
const EXPECTED_ROOM := "room_photo_luna"
const EXPECTED_CIVILIZATION := "clockwork"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const CAMERA_FOCUS := Vector3.ZERO
const CAMERA_DISTANCE := 330.0
const CAMERA_TILT := 52.0
const CAMERA_YAW := 0.0


func _initialize() -> void:
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_MANUAL_CAMERA", "1")
	OS.set_environment("ROOMSCALE_ROOM", EXPECTED_ROOM)
	OS.set_environment("ROOMSCALE_ROOM_FILE", ROOM_FILE)
	OS.set_environment("ROOMSCALE_CIVILIZATION", EXPECTED_CIVILIZATION)
	OS.set_environment("ROOMSCALE_ART_REGISTRY", REGISTRY_PATH)
	OS.set_environment("ROOMSCALE_ART_REGISTRY_MODE", "review_showcase")
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("matched production render requires a real renderer")
		return
	root.size = VIEWPORT_SIZE
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	if error != OK:
		_fail("could not open the production scene: %d" % error)
		return
	await scene_changed
	var scene := current_scene as Node3D
	if scene == null:
		_fail("production scene did not instantiate")
		return
	for frame in range(60):
		if scene.has_meta("civilization_definition"):
			break
		await process_frame
	var definition: Dictionary = scene.get("_room_definition")
	if String(definition.get("id", "")) != EXPECTED_ROOM:
		_fail("wrong RoomDefinition loaded: %s" % String(definition.get("id", "")))
		return
	if String(scene.get_meta("civilization_definition", {}).get("id", "")) != EXPECTED_CIVILIZATION:
		_fail("wrong civilization loaded")
		return
	var citizens: Array = scene.get("_citizens")
	if citizens.size() != 50:
		_fail("expected 50 production citizens, found %d" % citizens.size())
		return
	var resolver: Variant = scene.get("_visual_resolver")
	var registry: Variant = resolver.get("registry") if resolver != null else null
	if registry == null or not bool(registry.get("review_showcase")) or String(registry.get("registry_path")) != REGISTRY_PATH:
		_fail("production scene did not load the explicit v089 review showcase registry")
		return
	# Match the original baseline capture's natural startup interval before freezing
	# time and taking a single production render.
	await create_timer(3.2).timeout
	var simulation := scene.get_node_or_null("CivilizationSimulation")
	if simulation != null:
		(simulation.spectator.speed_buttons[0.0] as Button).pressed.emit()
	var camera_rig := scene.get_node("CameraRig")
	camera_rig.set_view_mode(1)
	camera_rig.focus_at(CAMERA_FOCUS, CAMERA_DISTANCE, CAMERA_TILT, CAMERA_YAW)
	camera_rig.distance = CAMERA_DISTANCE
	camera_rig.call("_apply_transform")
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var overlay := scene.get_node("Overlay") as CanvasLayer
	overlay.visible = true
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != VIEWPORT_SIZE:
		_fail("render dimensions do not match baseline: %s" % image.get_size())
		return
	var output_absolute := ProjectSettings.globalize_path(IMAGE_PATH)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIRECTORY))
	error = image.save_png(output_absolute)
	if error != OK:
		_fail("could not save matched final image: %d" % error)
		return
	var registry_entries: Dictionary = registry.get("entries")
	var asset_identity := {}
	for asset_id in ["citizen", "desk", "grapple"]:
		var entry: Dictionary = registry_entries[asset_id]
		asset_identity[asset_id] = {"candidate_id": entry.candidate_id, "status": entry.status, "review_only": true}
	var receipt := {
		"result": "PASS",
		"image": IMAGE_PATH,
		"room": EXPECTED_ROOM,
		"room_definition": ROOM_FILE,
		"civilization": EXPECTED_CIVILIZATION,
		"viewport": {"width": image.get_width(), "height": image.get_height()},
		"camera": {
			"focus": CAMERA_FOCUS,
			"distance": camera_rig.distance,
			"tilt_degrees": camera_rig.tilt_degrees,
			"yaw_radians": camera_rig.yaw,
			"fov_degrees": camera.fov,
			"position": camera.global_position,
			"rotation_degrees": camera.global_rotation_degrees,
			"overlay_visible": overlay.visible,
			"project_labels_hidden": false,
		},
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"display": DisplayServer.get_name(),
		"population": citizens.size(),
		"art_registry": REGISTRY_PATH,
		"art_registry_mode": "review_showcase",
		"art_registry_review_assets": asset_identity,
		"strict_gate_effect": "No candidate promotion; review-only evidence capture",
	}
	var file := FileAccess.open(RECEIPT_PATH, FileAccess.WRITE)
	if file == null:
		_fail("could not write matched capture receipt")
		return
	file.store_string(JSON.stringify(receipt, "\t") + "\n")
	file.close()
	print("ROOMSCALE_POC25_FINAL_MATCHED_CAPTURE_PASS image=%s room=%s civilization=%s viewport=%s focus=%s distance=%.1f tilt=%.1f yaw=%.2f fov=%.2f registry_mode=review_showcase citizen=citizen-v089" % [IMAGE_PATH, EXPECTED_ROOM, EXPECTED_CIVILIZATION, image.get_size(), CAMERA_FOCUS, CAMERA_DISTANCE, camera_rig.tilt_degrees, camera_rig.yaw, camera.fov])
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_POC25_FINAL_MATCHED_CAPTURE_FAIL: " + message)
	quit(1)
