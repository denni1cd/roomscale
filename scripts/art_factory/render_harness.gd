extends SceneTree
## Standardized candidate evidence from the normal RoomScale production scene.

var output_directory := ""
var candidate_id := ""
var asset_id := ""
var expected_asset_path := ""
var captures: Array[Dictionary] = []

const ROOM_FURNITURE_ASSET_IDS := [
	"bookcase",
	"room_elevated_workbench",
	"room_assembly_table",
	"room_tool_wardrobe",
	"room_floor_cabinet",
	"room_chair",
	"room_side_table",
]


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	asset_id = OS.get_environment("ROOMSCALE_ART_FACTORY_ASSET_ID")
	candidate_id = OS.get_environment("ROOMSCALE_ART_FACTORY_CANDIDATE")
	output_directory = OS.get_environment("ROOMSCALE_ART_FACTORY_RENDER_DIR")
	var registry_path := OS.get_environment("ROOMSCALE_ART_REGISTRY")
	var room_file := OS.get_environment("ROOMSCALE_ART_FACTORY_ROOM_FILE")
	expected_asset_path = OS.get_environment("ROOMSCALE_ART_FACTORY_EXPECTED_ASSET")
	var brief_path := OS.get_environment("ROOMSCALE_ART_FACTORY_BRIEF")
	var brief_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(brief_path)) if not brief_path.is_empty() else null
	if not brief_value is Dictionary:
		_fail("ArtBrief is required for candidate-specific production framing")
		return
	var brief: Dictionary = brief_value
	if asset_id.is_empty() or candidate_id.is_empty() or output_directory.is_empty() or registry_path.is_empty():
		_fail("asset, candidate, output directory, and registry override are required")
		return
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_ART_REGISTRY", registry_path)
	if room_file.is_empty():
		room_file = "verification/poc2/candidates/primary/attempt-7/room_photo_luna.json"
	OS.set_environment("ROOMSCALE_ROOM_FILE", room_file)
	if OS.get_environment("ROOMSCALE_ROOM").is_empty():
		OS.set_environment("ROOMSCALE_ROOM", "room_photo_luna")
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
	for _frame in range(30):
		await process_frame
	var definition: Dictionary = scene.get("_room_definition")
	if definition.is_empty():
		_fail("RoomDefinition did not initialize in the production scene")
		return
	var room_id := String(definition.get("id", ""))
	var is_room_surface := String(brief.get("category", "")) == "room_surface"
	var asset_node: Node3D
	var surface_material: StandardMaterial3D
	var loaded_asset_path := ""
	var loaded_candidate_id := ""
	var loaded_registry_status := ""
	var loaded_review_only := false
	if is_room_surface:
		asset_node = _find_surface_asset_node(scene)
		if asset_node == null:
			_fail("production room did not apply registered surface material %s" % asset_id)
			return
		surface_material = _find_registered_surface_material(scene)
		if surface_material == null:
			_fail("production room did not expose registered surface material %s" % asset_id)
			return
		loaded_asset_path = String(surface_material.get_meta("visual_source", ""))
		loaded_candidate_id = String(surface_material.get_meta("visual_asset_candidate_id", ""))
		loaded_registry_status = String(surface_material.get_meta("visual_asset_registry_status", ""))
		loaded_review_only = bool(surface_material.get_meta("visual_asset_review_only", false))
	else:
		asset_node = _find_asset_node(scene)
		if asset_node == null:
			_fail("production resolver did not instantiate stable asset id %s" % asset_id)
			return
		loaded_asset_path = String(asset_node.get_meta("visual_source", ""))
		loaded_candidate_id = String(asset_node.get_meta("visual_asset_candidate_id", ""))
		loaded_registry_status = String(asset_node.get_meta("visual_asset_registry_status", ""))
		loaded_review_only = bool(asset_node.get_meta("visual_asset_review_only", false))
	if loaded_asset_path != expected_asset_path:
		_fail("candidate was not loaded through the production resolver: expected=%s loaded=%s" % [expected_asset_path, loaded_asset_path])
		return
	if loaded_candidate_id != candidate_id:
		_fail("production resolver did not report candidate id %s" % candidate_id)
		return
	if not loaded_review_only:
		_fail("candidate render must use an explicit review-only showcase registry")
		return
	var selected_citizen_id := -1
	var selected_citizen_carrying := false
	var citizen_population: Array = []
	if asset_id == "citizen":
		citizen_population = scene.get("_citizens")
		if citizen_population.size() != 50:
			_fail("citizen candidate requires all 50 production citizens; found %d" % citizen_population.size())
			return
		for citizen_variant in citizen_population:
			var citizen := citizen_variant as Node3D
			var figure := citizen.get_node_or_null("Figure") as Node3D
			if figure == null or String(figure.get_meta("visual_source", "")) != expected_asset_path or String(figure.get_meta("visual_asset_candidate_id", "")) != candidate_id or not bool(figure.get_meta("visual_asset_review_only", false)):
				_fail("not every production citizen is using the candidate override: %s" % citizen.name)
				return
		var selected_figure := _select_clear_citizen(citizen_population, definition, true)
		if selected_figure == null:
			selected_figure = _select_clear_citizen(citizen_population, definition)
		if selected_figure == null:
			_fail("no accepted production citizen could be selected for the close render")
			return
		asset_node = selected_figure
		selected_citizen_id = int(selected_figure.get_parent().get("citizen_id"))
		selected_citizen_carrying = bool(selected_figure.get_parent().get("carrying"))
	var camera_rig := scene.get_node("CameraRig")
	# This harness chooses explicit evidence viewpoints. Disable interactive camera
	# smoothing so the requested close fit is the camera that reaches the renderer.
	camera_rig.set_process(false)
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay != null:
		overlay.visible = false
	var floor_data: Dictionary = definition.get("floor", {})
	var floor_center := _vector3(floor_data.get("center", [0.0, 0.0, 0.0]))
	floor_center.y = float(floor_data.get("height", 0.0))
	var room_camera: Dictionary = definition.get("camera", {})
	var room_yaw := deg_to_rad(float(room_camera.get("yaw_degrees", 0.0)))
	if not await _capture(scene, "room-scale", floor_center + Vector3.UP * 12.0, 330.0, 52.0, room_yaw):
		return
	if not await _capture(scene, "room-scale-opposite-angle", floor_center + Vector3.UP * 12.0, 330.0, 52.0, room_yaw + PI * 0.5):
		return
	var workshop := scene.get_node_or_null("Settlement/Workshop") as Node3D
	var work_area := scene.get_node_or_null("Settlement/WorkArea") as Node3D
	if workshop != null and work_area != null:
		var settlement_focus := (workshop.global_position + work_area.global_position) * 0.5 + Vector3.UP * 4.0
		var settlement_subject_names := {
			"scavenger_workshop": "Workshop",
			"settlement_workshop": "Workshop",
			"scavenger_depot": "Depot",
			"settlement_depot": "Depot",
			"scavenger_housing": "Housing",
			"settlement_housing": "Housing",
			"scavenger_workarea": "WorkArea",
			"settlement_workarea": "WorkArea",
		}
		var settlement_subject_name := String(settlement_subject_names.get(asset_id, ""))
		if not settlement_subject_name.is_empty():
			var settlement_subject := scene.get_node_or_null("Settlement/" + settlement_subject_name) as Node3D
			if settlement_subject != null:
				var brief_dimensions: Array = brief.get("intended_dimensions", [0.0, 8.0, 0.0])
				var subject_height := float(brief_dimensions[1]) if brief_dimensions.size() > 1 else 8.0
				settlement_focus = settlement_subject.global_position + Vector3.UP * subject_height * 0.5
		if not await _capture(scene, "settlement-scale", settlement_focus, 64.0, 42.0, 0.25):
			return
		if not settlement_subject_name.is_empty():
			if not await _capture(scene, "settlement-scale-opposite-angle", settlement_focus, 64.0, 42.0, 0.25 + PI):
				return
			if not await _capture(scene, "settlement-scale-side-angle", settlement_focus, 64.0, 42.0, 0.25 + PI * 0.5):
				return
	var dimensions := _vector3(brief.get("intended_dimensions", [1.0, 1.0, 1.0]))
	var close_distance := maxf(2.2, dimensions.length() * 0.72)
	var three_quarter_yaw := 0.62
	var opposite_yaw := 0.62 + PI
	var profile_yaw := 0.62 + PI * 0.5
	var detail_yaw := 0.25
	var target := asset_node.global_position + Vector3.UP * dimensions.y * 0.5
	if asset_id in ROOM_FURNITURE_ASSET_IDS:
		# The default close framing was built for the photographed room and clips
		# large furniture. Keep all views inside the playable room, on the front
		# and open-side quarter, and frame the whole constructed silhouette.
		close_distance = maxf(54.0, dimensions.length() * 1.24)
		three_quarter_yaw = 0.62
		opposite_yaw = 0.25
		profile_yaw = 0.12
		detail_yaw = 0.48
	if asset_id == "desk":
		# Keep close cameras inside the source room. The default 0.62-rad camera
		# lands behind the south wall for this desk's near-corner placement.
		close_distance = maxf(72.0, dimensions.length() * 0.92)
		three_quarter_yaw = 4.2
		opposite_yaw = 2.2
		profile_yaw = 4.71
		detail_yaw = 3.9
	if asset_id == "bookcase":
		# The authoritative Room A placement is near its north-east corner.
		# Keep every close camera inside the room while varying the view enough
		# to inspect the face frame, shelves, and framed side panel.
		var toward_room := floor_center - asset_node.global_position
		toward_room.y = 0.0
		var interior_yaw := atan2(toward_room.x, toward_room.z)
		three_quarter_yaw = interior_yaw - 0.25
		opposite_yaw = interior_yaw + 0.25
		profile_yaw = interior_yaw + 0.85
		detail_yaw = interior_yaw
	if asset_id in ["office_chair", "rocking_chair"]:
		# Tall seated furniture sits close to room walls in the canonical layout.
		# Back the close views away and use the proven interior-facing camera angles
		# so the whole chair remains visible against a useful range of room colors.
		close_distance = maxf(68.0, dimensions.length() * 1.1)
		three_quarter_yaw = 4.2
		opposite_yaw = 2.2
		profile_yaw = 4.71
		detail_yaw = 3.9
	if asset_id == "rocking_chair":
		# The RoomDefinition intentionally places a computer tower on this chair.
		# Focus behind the occupied seat so close captures inspect the chair's
		# slatted back, arms, and rocker rails instead of framing the tower.
		target.z -= 7.0
		three_quarter_yaw = 4.2
		opposite_yaw = 5.34
		profile_yaw = 4.71
		detail_yaw = 4.2
	if asset_id == "hammock_with_stand":
		# Face across the sling from inside the room. The hammock is unusually
		# long and sits against the north side of the room, so a diagonal close
		# camera would cross the wall before reaching the evidence distance.
		close_distance = maxf(96.0, dimensions.length() * 0.84)
		three_quarter_yaw = 0.0
		# The hammock backs onto the room wall, so a true 180-degree view would
		# leave the production room. Use two distinct interior obliques instead.
		opposite_yaw = 0.55
		profile_yaw = 1.0
		detail_yaw = 0.2
	if asset_id == "display_cabinet":
		# Fit the full-height cabinet and approach its rotated glass front from
		# inside the room, rather than clipping the top or looking through a wall.
		close_distance = maxf(100.0, dimensions.length() * 1.15)
		three_quarter_yaw = 2.2
		opposite_yaw = 5.34
		profile_yaw = 3.77
		detail_yaw = 2.8
	if asset_id == "citizen":
		close_distance = maxf(1.65, dimensions.length() * 3.0)
		target = asset_node.global_position + Vector3.UP * dimensions.y * 0.5
	if asset_id in ["room_photo_window_production", "room_photo_french_door_production"]:
		# The opening sits on a room boundary. Keep every close comparison camera
		# on the interior side while varying only the oblique angle slightly.
		var toward_room := (floor_center - target).normalized()
		var interior_yaw := atan2(toward_room.x, toward_room.z)
		close_distance = maxf(70.0, dimensions.length() * 0.78)
		three_quarter_yaw = interior_yaw - 0.26
		opposite_yaw = interior_yaw + 0.26
		profile_yaw = interior_yaw
		detail_yaw = interior_yaw
	if is_room_surface:
		var room_dimensions: Array = definition.get("dimensions", [156.0, 144.0])
		var room_depth := float(room_dimensions[1]) if room_dimensions.size() > 1 else 144.0
		var wall_height := float(definition.get("wall_height", dimensions.y))
		if asset_id == "room_shell_floor":
			# This open southwest floor patch avoids the central seat, hammock mat,
			# desk, and cabinet while keeping close material captures in the live room.
			target = Vector3(-35.0, floor_center.y + 0.15, 14.0)
			close_distance = 38.0
			three_quarter_yaw = 0.15
			opposite_yaw = 0.45
			profile_yaw = -0.15
			detail_yaw = 0.15
		elif asset_id == "room_shell_trim":
			var shell_value: Variant = definition.get("room_shell", {})
			var shell: Dictionary = shell_value if shell_value is Dictionary else {}
			var baseboard_height := float(shell.get("baseboard_height", 3.0))
			var south_inner_z := floor_center.z + room_depth * 0.5 - float(shell.get("wall_thickness", 2.0)) * 0.5
			target = Vector3(-10.0, floor_center.y + baseboard_height * 0.5, south_inner_z)
			close_distance = 24.0
			three_quarter_yaw = PI + 0.18
			opposite_yaw = PI - 0.18
			profile_yaw = PI
			detail_yaw = PI
		else:
			# The south wall is uninterrupted in this source RoomDefinition.
			target = Vector3(-35.0, wall_height * 0.5, room_depth * 0.5 - 1.0)
			close_distance = 55.0
			three_quarter_yaw = PI + 0.24
			opposite_yaw = PI - 0.24
			profile_yaw = PI
			detail_yaw = PI
	var asset_tilt := 38.0
	var detail_tilt := 28.0
	if asset_id in ROOM_FURNITURE_ASSET_IDS:
		asset_tilt = 24.0
		detail_tilt = 18.0
	if asset_id in ["room_photo_window_production", "room_photo_french_door_production"]:
		asset_tilt = 22.0
		detail_tilt = 20.0
	if asset_id.begins_with("settlement_"):
		# Settlement presentation roots retain the existing 0.6 visual scale.
		# Focus at the rendered structure center and lower the camera so roofs do
		# not conceal the doors, loading faces, tools, and machinery being judged.
		target = asset_node.global_position + Vector3.UP * dimensions.y * 0.3
		asset_tilt = 15.0
		detail_tilt = 12.0
	var follow_citizen: Node3D = asset_node if asset_id == "citizen" else null
	if asset_id in ROOM_FURNITURE_ASSET_IDS:
		var gameplay_distance := maxf(64.0, dimensions.y * 1.16)
		if not await _capture(scene, "asset-gameplay-distance", target, gameplay_distance, 28.0, three_quarter_yaw, follow_citizen):
			return
	if asset_id == "citizen":
		# The ArtBrief's gameplay-scale distance is intentionally separate from
		# settlement framing and close inspection. It proves the citizen remains
		# recognizable at a normal agent camera range in the live production scene.
		if not await _capture(scene, "asset-gameplay-distance", target, 12.0, 26.0, three_quarter_yaw, follow_citizen):
			return
	if not await _capture(scene, "asset-three-quarter", target, close_distance, asset_tilt, three_quarter_yaw, follow_citizen):
		return
	var alternate_phase := "asset-opposite-three-quarter"
	if asset_id in ROOM_FURNITURE_ASSET_IDS or asset_id in ["hammock_with_stand", "room_photo_window_production", "room_photo_french_door_production"]:
		alternate_phase = "asset-interior-oblique"
	if not await _capture(scene, alternate_phase, target, close_distance, asset_tilt, opposite_yaw, follow_citizen):
		return
	if not await _capture(scene, "asset-profile", target, close_distance, asset_tilt, profile_yaw, follow_citizen):
		return
	var detail_distance := maxf(2.0, dimensions.y * 1.15)
	if asset_id == "desk":
		detail_distance = maxf(48.0, dimensions.length() * 0.64)
	if asset_id in ["office_chair", "rocking_chair"]:
		detail_distance = maxf(64.0, dimensions.length() * 1.05)
	if asset_id == "display_cabinet":
		detail_distance = maxf(92.0, dimensions.length() * 1.05)
	if asset_id == "hammock_with_stand":
		detail_distance = maxf(46.0, dimensions.y * 1.15)
	if asset_id == "citizen":
		detail_distance = maxf(2.0, dimensions.y * 4.0)
		detail_yaw = 0.9
		detail_tilt = 38.0
	if asset_id in ["room_photo_window_production", "room_photo_french_door_production"]:
		detail_distance = maxf(44.0, dimensions.y * 0.72)
	if is_room_surface:
		detail_distance = 24.0 if asset_id == "room_shell_floor" else 32.0
		asset_tilt = 82.0 if asset_id == "room_shell_floor" else 12.0
		detail_tilt = asset_tilt
	if asset_id.begins_with("settlement_"):
		detail_distance *= 0.6
	if asset_id in ROOM_FURNITURE_ASSET_IDS:
		detail_distance = maxf(maxf(30.0, dimensions.length() * 0.88), dimensions.y * 1.25)
	if not await _capture(scene, "asset-detail", target, detail_distance, detail_tilt, detail_yaw, follow_citizen):
		return
	if asset_id == "room_shell_trim":
		var shell_value: Variant = definition.get("room_shell", {})
		var shell: Dictionary = shell_value if shell_value is Dictionary else {}
		var wall_thickness := float(shell.get("wall_thickness", 2.0))
		var south_inner_z := floor_center.z + float(definition.get("dimensions", [156.0, 144.0])[1]) * 0.5 - wall_thickness * 0.5
		var baseboard_height := float(shell.get("baseboard_height", 3.0))
		var crown_height := float(shell.get("crown_molding_height", 0.0))
		var baseboard_depth := maxf(1.0, wall_thickness * 0.7)
		var baseboard_target := Vector3(-10.0, floor_center.y + baseboard_height * 0.5, south_inner_z - baseboard_depth * 0.5)
		if not await _capture(scene, "baseboard-profile-detail", baseboard_target, 18.0, 22.0, PI):
			return
		var crown_depth := 0.75
		var crown_target := Vector3(-10.0, floor_center.y + float(definition.get("wall_height", 108.0)) - crown_height * 0.5, south_inner_z - crown_depth * 0.5)
		if crown_height > 0.0 and not await _capture(scene, "crown-profile-detail", crown_target, 18.0, 22.0, PI):
			return
	var controlled_citizen_yaws := OS.get_environment("ROOMSCALE_ART_FACTORY_CITIZEN_YAW_SWEEP_DEGREES")
	var controlled_citizen_receipt: Dictionary = {}
	if asset_id == "citizen" and not controlled_citizen_yaws.is_empty():
		var sweep_figure := _select_clear_citizen(citizen_population, definition, true)
		if sweep_figure == null:
			sweep_figure = follow_citizen
		controlled_citizen_receipt = await _capture_citizen_yaw_sweep(
			scene,
			sweep_figure,
			controlled_citizen_yaws,
			12.0,
			26.0,
			0.62
		)
		if controlled_citizen_receipt.is_empty():
			return
	var receipt := {
		"schema_version": 1,
		"production_path": true,
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"room_id": room_id,
		"asset_id": asset_id,
		"candidate_id": candidate_id,
		"registry_mode": OS.get_environment("ROOMSCALE_ART_REGISTRY_MODE"),
		"candidate_status": loaded_registry_status,
		"review_label": "BEST CURRENT / PRODUCTION ART FOLLOW-UP REQUIRED",
		"registry_path": OS.get_environment("ROOMSCALE_ART_REGISTRY"),
		"selected_citizen_id": selected_citizen_id,
		"selected_citizen_carrying": selected_citizen_carrying,
		"controlled_citizen_yaw_sweep": controlled_citizen_receipt,
		"loaded_asset_path": loaded_asset_path,
		"loaded_candidate_id": loaded_candidate_id,
		"viewport": [root.size.x, root.size.y],
		"captures": captures,
		"performance": {
			"fps": Performance.get_monitor(Performance.TIME_FPS),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		},
	}
	var receipt_path := output_directory.path_join("receipt.json")
	var receipt_file := FileAccess.open(receipt_path, FileAccess.WRITE)
	if receipt_file == null:
		_fail("could not write render receipt: %s" % receipt_path)
		return
	receipt_file.store_string(JSON.stringify(receipt, "  ") + "\n")
	print("ROOMSCALE_ART_FACTORY_RENDER_PASS asset=%s candidate=%s room=%s captures=%d output=%s" % [asset_id, candidate_id, room_id, captures.size(), output_directory])
	quit(0)


func _capture_citizen_yaw_sweep(
	scene: Node3D,
	figure: Node3D,
	yaw_degrees_csv: String,
	distance: float,
	tilt: float,
	camera_world_yaw: float
) -> Dictionary:
	if not is_instance_valid(figure) or figure.get_parent() == null:
		_fail("controlled citizen yaw sweep has no valid production citizen")
		return {}
	var citizen := figure.get_parent() as Node3D
	var angles: Array[float] = []
	for token in yaw_degrees_csv.split(",", false):
		var parsed := token.strip_edges().to_float()
		if not is_finite(parsed):
			_fail("controlled citizen yaw sweep contains a non-finite angle")
			return {}
		angles.append(parsed)
	if angles.is_empty():
		_fail("controlled citizen yaw sweep needs at least one angle")
		return {}

	# Supplemental stills only: retain the running production capture above, then
	# freeze the already-instantiated RoomScale scene while changing just the
	# selected citizen's facing. All 50 production citizens remain in the scene.
	var tree := scene.get_tree()
	tree.paused = true
	var capture_position := citizen.global_position
	var citizen_id := int(citizen.get("citizen_id"))
	citizen.rotation.y = camera_world_yaw - 0.62
	figure.rotation.y = 0.0
	var detail_camera_yaw := camera_world_yaw - figure.global_rotation.y
	if not await _capture(
		scene,
		"asset-idle-detail",
		figure.global_position + Vector3.UP * 0.25,
		2.0,
		38.0,
		detail_camera_yaw,
		figure,
		{
			"controlled_still": true,
			"idle_citizen_close_inspection": true,
			"selected_citizen_id": citizen_id,
			"selected_citizen_carrying": bool(citizen.get("carrying")),
			"subject_world_yaw_radians": figure.global_rotation.y,
		}
	):
		tree.paused = false
		return {}
	for relative_facing_degrees in angles:
		var relative_facing := deg_to_rad(relative_facing_degrees)
		# Match the standard three-quarter relation at 0 degrees. Camera world yaw
		# stays fixed, so the images isolate front/profile/back role cues.
		citizen.rotation.y = camera_world_yaw - 0.62 - relative_facing
		figure.rotation.y = 0.0
		var relative_camera_yaw := camera_world_yaw - figure.global_rotation.y
		var phase := "asset-gameplay-yaw-%03d" % posmod(roundi(relative_facing_degrees), 360)
		if not await _capture(
			scene,
			phase,
			figure.global_position + Vector3.UP * 0.25,
			distance,
			tilt,
			relative_camera_yaw,
			figure,
			{
				"controlled_still": true,
				"selected_citizen_id": citizen_id,
				"subject_facing_degrees_relative_to_standard": relative_facing_degrees,
				"subject_world_yaw_radians": figure.global_rotation.y,
			}
		):
			tree.paused = false
			return {}
	tree.paused = false
	return {
		"supplemental_stills_only": true,
		"scene_paused_during_stills": true,
		"production_citizen_count": 50,
		"selected_citizen_id": citizen_id,
		"selected_citizen_carrying": bool(citizen.get("carrying")),
		"selected_citizen_world_position": capture_position,
		"distance_inches": distance,
		"close_inspection_phase": "asset-idle-detail",
		"camera_world_yaw_radians": camera_world_yaw,
		"subject_facing_degrees_relative_to_standard": angles,
	}


func _find_asset_node(scene: Node3D) -> Node3D:
	var possible := scene.find_children("*", "Node3D", true, false)
	for node in possible:
		if String(node.get_meta("visual_asset_id", "")) != asset_id:
			continue
		if asset_id == "citizen" and not String(node.name).begins_with("Figure"):
			continue
		if String(node.get_meta("visual_source", "")) == expected_asset_path:
			return node as Node3D
	return null


func _find_registered_surface_material(scene: Node3D) -> StandardMaterial3D:
	for node_variant in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node_variant as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.get_active_material(surface_index) as StandardMaterial3D
			if material != null and String(material.get_meta("visual_asset_id", "")) == asset_id:
				return material
	return null


func _find_surface_asset_node(scene: Node3D) -> Node3D:
	for node_variant in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node_variant as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.get_active_material(surface_index) as StandardMaterial3D
			if material != null and String(material.get_meta("visual_asset_id", "")) == asset_id:
				return mesh_instance
	return null


func _select_clear_citizen(population: Array, definition: Dictionary, require_idle: bool = false) -> Node3D:
	var best: Node3D
	var best_clearance := -INF
	for citizen_variant in population:
		var citizen := citizen_variant as Node3D
		if require_idle and bool(citizen.get("carrying")):
			continue
		var figure := citizen.get_node_or_null("Figure") as Node3D
		if figure == null:
			continue
		var p := Vector2(citizen.global_position.x, citizen.global_position.z)
		var clearance := INF
		for object_variant in definition.get("objects", []):
			if not object_variant is Dictionary:
				continue
			var object: Dictionary = object_variant
			if not bool(object.get("blocks_navigation", false)):
				continue
			var at: Array = object.get("position", [])
			var size: Array = object.get("dimensions", [])
			if at.size() != 3 or size.size() != 3:
				continue
			var dx := maxf(absf(p.x - float(at[0])) - float(size[0]) * 0.5 - 2.0, 0.0)
			var dz := maxf(absf(p.y - float(at[2])) - float(size[2]) * 0.5 - 2.0, 0.0)
			clearance = minf(clearance, Vector2(dx, dz).length())
		var landmarks: Dictionary = definition.get("landmarks", {})
		for key in ["workshop", "depot", "housing", "work_area"]:
			var landmark: Array = landmarks.get(key, [])
			if landmark.size() == 3:
				clearance = minf(clearance, p.distance_to(Vector2(float(landmark[0]), float(landmark[2]))) - 12.0)
		for other_variant in population:
			var other := other_variant as Node3D
			if other == citizen:
				continue
			clearance = minf(clearance, p.distance_to(Vector2(other.global_position.x, other.global_position.z)) - 1.5)
		if clearance > best_clearance:
			best_clearance = clearance
			best = figure
	return best


func _capture(scene: Node3D, phase: String, focus: Vector3, distance: float, tilt: float, yaw: float, follow: Node3D = null, extra_evidence: Dictionary = {}) -> bool:
	var rig := scene.get_node("CameraRig")
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	if is_instance_valid(follow):
		# Follow the live Figure pivot during a close capture. Citizens continue
		# navigating while this harness waits for the rendered frame, so a fixed
		# world point can leave a half-inch subject off screen.
		rig.set_view_mode(2)
		_snap_to_subject(rig, follow, distance, tilt, yaw)
		camera.fov = 38.0
	else:
		rig.focus_at(focus, distance, tilt, yaw)
		rig.distance = distance
	rig.call("_apply_transform")
	# Let the live production camera, shell cutaway, and animated scene update
	# before reading back pixels from the rendered viewport.
	for _frame in range(5):
		await process_frame
		if is_instance_valid(follow):
			_snap_to_subject(rig, follow, distance, tilt, yaw)
	if is_instance_valid(follow) and follow.get_parent().has_method("refresh_visual_lod"):
		follow.get_parent().call("refresh_visual_lod")
	await RenderingServer.frame_post_draw
	var image: Image = scene.get_viewport().get_texture().get_image()
	if image.is_empty() or image.get_width() < 320 or image.get_height() < 200:
		_fail("render %s returned unusable dimensions %s" % [phase, image.get_size()])
		return false
	var sampled_colors: Dictionary = {}
	for y in range(0, image.get_height(), 24):
		for x in range(0, image.get_width(), 24):
			sampled_colors[image.get_pixel(x, y).to_html(false)] = true
	if sampled_colors.size() < 40:
		_fail("render %s appears occluded or nearly blank: %d sampled colors" % [phase, sampled_colors.size()])
		return false
	var image_path := output_directory.path_join("%s.png" % phase)
	if image.save_png(image_path) != OK:
		_fail("render %s could not save %s" % [phase, image_path])
		return false
	var capture_record := {
		"phase": phase,
		"path": image_path,
		"production_path": true,
		"camera": {"focus": rig.get("target"), "distance_inches": rig.get("distance"), "actual_camera_position": camera.global_position, "subject_screen_position": camera.unproject_position(rig.get("target")), "tilt_degrees": rig.get("tilt_degrees"), "yaw_radians": rig.get("yaw"), "fov_degrees": camera.fov},
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
	}
	capture_record.merge(extra_evidence, true)
	captures.append(capture_record)
	return true


func _snap_to_subject(rig: Node, subject: Node3D, distance: float, tilt: float, yaw: float) -> void:
	var focus := subject.global_position + Vector3.UP * 0.25
	var world_yaw := subject.global_rotation.y + yaw
	rig.focus_at(focus, distance, tilt, world_yaw)
	rig.distance = distance
	rig.tilt_degrees = tilt
	rig.yaw = world_yaw
	rig.call("_apply_transform")


func _vector3(value: Variant) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO


func _fail(reason: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_RENDER_FAIL: " + reason)
	quit(1)
