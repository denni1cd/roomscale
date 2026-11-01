extends SceneTree
## Matched production-scene captures for bounded Art Factory replacement batches.

var output_directory := ""
var room_file := ""
var room_id := ""
var captures: Array[Dictionary] = []
var candidate_usage: Array[Dictionary] = []

const BATCH01_CANDIDATES := {
	"settlement_workshop": "settlement_workshop-v006",
	"settlement_depot": "settlement_depot-v005",
	"settlement_housing": "settlement_housing-v004",
	"settlement_workarea": "settlement_workarea-v006",
	"room_bookcase_production": "room_bookcase_production-v001",
	"room_photo_window_production": "room_photo_window_production-v002",
	"room_photo_french_door_production": "room_photo_french_door_production-v002",
}


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	output_directory = OS.get_environment("ROOMSCALE_BATCH_CAPTURE_DIR")
	room_file = OS.get_environment("ROOMSCALE_ROOM_FILE")
	room_id = OS.get_environment("ROOMSCALE_ROOM")
	if output_directory.is_empty() or room_file.is_empty() or room_id.is_empty():
		_fail("capture directory, room file, and room id are required")
		return
	if DisplayServer.get_name() == "headless":
		_fail("matched visual evidence requires the real RoomScale renderer")
		return
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_ROOM_FILE", room_file)
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
	if OS.get_environment("ROOMSCALE_ART_REGISTRY_MODE") != "review_showcase":
		_fail("Batch 1 comparison requires the explicit review_showcase registry mode")
		return
	if not _verify_review_assets(scene):
		return
	var rig := scene.get_node_or_null("CameraRig")
	if rig == null or not rig.has_method("focus_at"):
		_fail("production camera rig is unavailable")
		return
	rig.set_process(false)
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null:
		overlay.visible = false
	var floor: Dictionary = definition.get("floor", {})
	var center := _vector3(floor.get("center", [0.0, 0.0, 0.0]))
	center.y = float(floor.get("height", 0.0))
	var camera_data: Dictionary = definition.get("camera", {})
	var yaw := deg_to_rad(float(camera_data.get("yaw_degrees", 0.0)))
	if not await _capture(scene, "room-overview", center + Vector3.UP * 12.0, 330.0, 52.0, yaw):
		return
	var landmarks: Dictionary = definition.get("landmarks", {})
	if landmarks.has("workshop") and landmarks.has("work_area"):
		var workshop := scene.get_node_or_null("Settlement/Workshop") as Node3D
		var work_area := scene.get_node_or_null("Settlement/WorkArea") as Node3D
		if workshop == null or work_area == null:
			_fail("settlement landmarks exist but production nodes are missing")
			return
		var settlement_focus := (workshop.global_position + work_area.global_position) * 0.5 + Vector3.UP * 4.0
		if not await _capture(scene, "settlement-gameplay", settlement_focus, 64.0, 42.0, 0.25):
			return
	if room_id == "room_b":
		var bookcase := scene.call("get_room_object", "parts_rack") as Node3D
		if bookcase == null:
			_fail("Room B parts rack is not available for the object-scale capture")
			return
		if not await _capture(scene, "parts-rack-gameplay", bookcase.global_position + Vector3.UP * 26.0, 52.0, 42.0, 0.45):
			return
	if room_id == "room_photo_luna":
		if not await _capture(scene, "room-photo-gameplay", center + Vector3.UP * 12.0, 220.0, 52.0, yaw):
			return
		var chair := scene.call("get_room_object", "office-chair") as Node3D
		if chair != null:
			if not await _capture(scene, "chair-gameplay", chair.global_position + Vector3.UP * 22.0, 55.0, 42.0, 0.55):
				return
	var registry_path := OS.get_environment("ROOMSCALE_ART_REGISTRY")
	if registry_path.is_empty():
		registry_path = "res://art/registry.json"
	var receipt := {
		"status": "pass",
		"room_id": room_id,
		"room_file": room_file,
		"registry_path": registry_path,
		"registry_mode": OS.get_environment("ROOMSCALE_ART_REGISTRY_MODE"),
		"asset_usage": candidate_usage,
		"engine": Engine.get_version_info(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"viewport": {"width": root.size.x, "height": root.size.y},
		"captures": captures,
	}
	var receipt_file := FileAccess.open(output_directory.path_join("receipt.json"), FileAccess.WRITE)
	if receipt_file == null:
		_fail("capture receipt cannot be written")
		return
	receipt_file.store_string(JSON.stringify(receipt, "\t") + "\n")
	receipt_file.close()
	print("ROOMSCALE_BATCH_CAPTURE_PASS room=%s captures=%d output=%s" % [room_id, captures.size(), output_directory])
	quit(0)


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
	var bytes := FileAccess.get_file_as_bytes(path)
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		_fail("SHA-256 context could not start for %s" % phase)
		return false
	hashing.update(bytes)
	var sha256 := hashing.finish().hex_encode()
	captures.append({
		"phase": phase,
		"path": path,
		"sha256": sha256,
		"production_path": true,
		"camera": {
			"focus": rig.get("target"),
			"distance_inches": rig.get("distance"),
			"tilt_degrees": rig.get("tilt_degrees"),
			"yaw_radians": rig.get("yaw"),
			"fov_degrees": camera.fov,
			"position": camera.global_position,
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


func _verify_review_assets(scene: Node3D) -> bool:
	var required_ids := ["settlement_workshop", "settlement_depot", "settlement_housing", "settlement_workarea"]
	if room_id == "room_b":
		required_ids.append("room_bookcase_production")
	if room_id == "room_photo_luna":
		required_ids.append("room_photo_window_production")
		required_ids.append("room_photo_french_door_production")
	var nodes := scene.find_children("*", "Node3D", true, false)
	for asset_id_variant in required_ids:
		var asset_id := String(asset_id_variant)
		var expected_candidate := String(BATCH01_CANDIDATES[asset_id])
		var matched: Array[Node3D] = []
		for node_variant in nodes:
			var node := node_variant as Node3D
			if String(node.get_meta("visual_asset_id", "")) == asset_id \
			and String(node.get_meta("visual_asset_candidate_id", "")) == expected_candidate \
			and String(node.get_meta("visual_source", "")).begins_with("res://art/") \
			and bool(node.get_meta("visual_asset_review_only", false)):
				matched.append(node)
		var minimum_count := 2 if asset_id == "room_photo_window_production" else 1
		if matched.size() < minimum_count:
			_fail("review asset %s expected candidate %s at least %d time(s); found %d" % [asset_id, expected_candidate, minimum_count, matched.size()])
			return false
		candidate_usage.append({
			"asset_id": asset_id,
			"candidate_id": expected_candidate,
			"instances": matched.size(),
			"review_only": true,
			"source_paths": matched.map(func(node: Node3D) -> String: return String(node.get_meta("visual_source", ""))),
		})
	return true


func _fail(reason: String) -> void:
	push_error("ROOMSCALE_BATCH_CAPTURE_FAIL: " + reason)
	quit(1)
