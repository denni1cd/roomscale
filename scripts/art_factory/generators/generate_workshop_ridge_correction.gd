extends SceneTree
## Targeted roof correction layered onto the accepted workshop incumbent.

const G := preload("res://scripts/visuals/visual_geometry.gd")

const TARGET := "art/settlement_workshop/visual_director/round-01/approved-target-r01.png"
const INCUMBENT := "art/settlement_workshop/iterations/v004/generated/settlement_workshop.tscn"

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var recipe_path := OS.get_environment("ROOMSCALE_ART_FACTORY_RECIPE")
	var output_directory := OS.get_environment("ROOMSCALE_ART_FACTORY_OUTPUT_DIR")
	if recipe_path.is_empty() or output_directory.is_empty():
		_fail("recipe and output directory are required")
		return
	var recipe_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(recipe_path))
	if not recipe_value is Dictionary:
		_fail("recipe must be a JSON object")
		return
	var parameters: Dictionary = recipe_value.get("parameters", {})
	if String(recipe_value.get("method", "")) != "godot_workshop_incumbent_ridge_canopy":
		_fail("unsupported workshop correction method")
		return
	if String(parameters.get("visual_director_target", "")) != TARGET:
		_fail("recipe must reference the approved raised-canopy target")
		return
	if String(parameters.get("incumbent_scene", "")) != INCUMBENT:
		_fail("recipe must begin from the accepted v004 incumbent scene")
		return
	if not FileAccess.file_exists("res://" + TARGET) or not FileAccess.file_exists("res://" + INCUMBENT):
		_fail("approved target or incumbent scene is missing")
		return

	var packed := load("res://" + INCUMBENT) as PackedScene
	if packed == null:
		_fail("could not load accepted workshop incumbent")
		return
	var asset := packed.instantiate() as Node3D
	asset.name = "SettlementWorkshopRidgeCanopyCorrection"
	asset.set_meta("presentation_only", true)

	var source_roof := asset.get_node_or_null("RoofWing_1") as MeshInstance3D
	var source_seam := asset.get_node_or_null("RoofStandingSeam_1_2") as MeshInstance3D
	var source_frame := asset.get_node_or_null("BackFrame") as MeshInstance3D
	if source_roof == null or source_seam == null or source_frame == null:
		asset.free()
		_fail("incumbent roof, standing seam, or timber material source is missing")
		return
	var roof_material := source_roof.material_override.duplicate(true) as StandardMaterial3D
	var seam_material := source_seam.material_override.duplicate(true) as StandardMaterial3D
	var timber_material := source_frame.material_override.duplicate(true) as StandardMaterial3D
	if roof_material == null or seam_material == null or timber_material == null:
		asset.free()
		_fail("incumbent construction materials are not StandardMaterial3D")
		return

	# Remove only the split wing sheets and their seams; all accepted machinery,
	# timber assembly, boardwork, tools, and moving-detail contracts are retained.
	for child in asset.get_children():
		if child.name.begins_with("RoofWing") or child.name.begins_with("RoofStandingSeam"):
			asset.remove_child(child)
			child.free()

	var canopy: Dictionary = parameters.get("canopy", {})
	var eave_left_values: Array = canopy.get("eave_left_xy", [-1.6, 14.6])
	var ridge_values: Array = canopy.get("ridge_xy", [4.4, 17.45])
	var eave_right_values: Array = canopy.get("eave_right_xy", [10.4, 14.6])
	var eave_left := Vector2(float(eave_left_values[0]), float(eave_left_values[1]))
	var ridge := Vector2(float(ridge_values[0]), float(ridge_values[1]))
	var eave_right := Vector2(float(eave_right_values[0]), float(eave_right_values[1]))
	var roof_front_z := float(canopy.get("front_z", -8.2))
	var roof_back_z := float(canopy.get("back_z", 8.2))
	var roof_length := roof_back_z - roof_front_z
	var roof_center_z := (roof_front_z + roof_back_z) * 0.5
	var truss_z_values: Array = canopy.get("truss_z", [-7.0, 0.0, 7.0])
	var lower_support_y := float(canopy.get("support_start_y", 8.8))
	var left_vector := ridge - eave_left
	var right_vector := eave_right - ridge
	var left_angle := atan2(left_vector.y, left_vector.x)
	var right_angle := atan2(right_vector.y, right_vector.x)

	var left_panel := _box(
		asset,
		"RidgeCanopyLeftStandingSeamPanel",
		Vector3(left_vector.length(), 0.34, roof_length),
		Vector3((ridge.x + eave_left.x) * 0.5, (ridge.y + eave_left.y) * 0.5, roof_center_z),
		roof_material
	)
	left_panel.rotation.z = left_angle
	var right_panel := _box(
		asset,
		"RidgeCanopyRightStandingSeamPanel",
		Vector3(right_vector.length(), 0.34, roof_length),
		Vector3((ridge.x + eave_right.x) * 0.5, (ridge.y + eave_right.y) * 0.5, roof_center_z),
		roof_material
	)
	right_panel.rotation.z = right_angle

	# The canopy covers the workbench bay; the boiler and flue lane to the left
	# stays open. Raised copper seams run down each pitch, with a continuous ridge cap.
	for fraction in [0.18, 0.38, 0.62, 0.82]:
		var left_point := eave_left.lerp(ridge, fraction)
		var right_point := ridge.lerp(eave_right, fraction)
		var left_seam := _box(
			asset,
			"RidgeCanopyLeftStandingSeam_%d" % int(fraction * 100.0),
			Vector3(0.09, 0.15, roof_length - 0.2),
			Vector3(left_point.x, left_point.y + 0.22, roof_center_z),
			seam_material
		)
		left_seam.rotation.z = left_angle
		var right_seam := _box(
			asset,
			"RidgeCanopyRightStandingSeam_%d" % int(fraction * 100.0),
			Vector3(0.09, 0.15, roof_length - 0.2),
			Vector3(right_point.x, right_point.y + 0.22, roof_center_z),
			seam_material
		)
		right_seam.rotation.z = right_angle

	_box(
		asset,
		"RidgeCanopyCopperRidgeCap",
		Vector3(0.48, 0.30, roof_length + 0.15),
		Vector3(ridge.x, ridge.y + 0.20, roof_center_z),
		seam_material
	)

	# Three tied trusses transfer each roof plane into posts and the side frame.
	for z_value in truss_z_values:
		var z := float(z_value)
		_beam(asset, "RidgeCanopyLeftRafter_%s" % str(z), Vector3(eave_left.x, eave_left.y, z), Vector3(ridge.x, ridge.y, z), 0.44, 0.46, timber_material)
		_beam(asset, "RidgeCanopyRightRafter_%s" % str(z), Vector3(ridge.x, ridge.y, z), Vector3(eave_right.x, eave_right.y, z), 0.44, 0.46, timber_material)
		_beam(asset, "RidgeCanopyTieBeam_%s" % str(z), Vector3(eave_left.x, 14.05, z), Vector3(eave_right.x, 14.05, z), 0.38, 0.42, timber_material)
		_box(asset, "RidgeCanopyKingPost_%s" % str(z), Vector3(0.34, ridge.y - 14.05, 0.40), Vector3(ridge.x, (ridge.y + 14.05) * 0.5, z), timber_material)
		_beam(asset, "RidgeCanopyLeftKnee_%s" % str(z), Vector3(eave_left.x + 0.12, 10.5, z), Vector3(eave_left.x + 2.0, 14.3, z), 0.26, 0.30, timber_material)
		_beam(asset, "RidgeCanopyRightKnee_%s" % str(z), Vector3(eave_right.x - 0.12, 10.5, z), Vector3(eave_right.x - 2.0, 14.3, z), 0.26, 0.30, timber_material)
		for x in [eave_left.x, eave_right.x]:
			_box(asset, "RidgeCanopyPost_%s_%s" % [str(x), str(z)], Vector3(0.44, 14.6 - lower_support_y, 0.44), Vector3(x, (14.6 + lower_support_y) * 0.5, z), timber_material)

	# Continuous purlins tie the trusses together along the eaves and ridge.
	for x in [eave_left.x, ridge.x, eave_right.x]:
		var y := ridge.y if is_equal_approx(x, ridge.x) else 14.6
		_box(asset, "RidgeCanopyPurlin_%s" % str(x), Vector3(0.36, 0.42, roof_length), Vector3(x, y - 0.22, roof_center_z), timber_material)

	_assign_owner(asset, asset)
	var output_path := output_directory.path_join("settlement_workshop.tscn")
	DirAccess.make_dir_recursive_absolute(output_directory)
	var scene := PackedScene.new()
	var pack_error := scene.pack(asset)
	if pack_error != OK:
		asset.free()
		_fail("could not pack corrected incumbent, error=%d" % pack_error)
		return
	var save_error := ResourceSaver.save(scene, output_path)
	asset.free()
	if save_error != OK:
		_fail("could not save corrected incumbent, error=%d" % save_error)
		return
	var record := {
		"asset_id": "settlement_workshop",
		"method": "godot_workshop_incumbent_ridge_canopy",
		"incumbent_candidate_id": "settlement_workshop-v004",
		"visual_director_target": TARGET,
		"transfer_diagnosis_ref": String(parameters.get("diagnosis_ref", "")),
		"roof_strategy": "continuous tied gable over the workbench bay; boiler and stack lane remains uncovered",
		"envelope_inches": [26.0, 20.0, 20.0],
		"roomdefinition_and_gameplay_geometry_changed": false,
		"outputs": ["settlement_workshop.tscn"]
	}
	var record_file := FileAccess.open(output_directory.path_join("generation-record.json"), FileAccess.WRITE)
	if record_file == null:
		_fail("could not write generation record")
		return
	record_file.store_string(JSON.stringify(record, "  ") + "\n")
	record_file.close()
	print("ROOMSCALE_ART_FACTORY_GENERATION_PASS asset=settlement_workshop candidate_scene=%s" % output_path)
	await process_frame
	quit(0)


func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var item := G.box(parent, label, size, at, "wood", Color("63452f"), 0.06)
	item.material_override = material.duplicate(true) as StandardMaterial3D
	return item


func _beam(parent: Node3D, label: String, start: Vector3, finish: Vector3, height: float, depth: float, material: StandardMaterial3D) -> MeshInstance3D:
	var direction := finish - start
	var item := _box(parent, label, Vector3(direction.length(), height, depth), (start + finish) * 0.5, material)
	item.rotation.z = atan2(direction.y, direction.x)
	return item


func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_assign_owner(child, owner)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + message)
	quit(1)
