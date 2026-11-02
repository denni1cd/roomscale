extends SceneTree
## Alternate component-authored canopy built onto the current best workshop.

const G := preload("res://scripts/visuals/visual_geometry.gd")

const TARGET := "art/settlement_workshop/visual_director/round-01/approved-target-r01.png"
const BEST_3D := "art/settlement_workshop/iterations/v008/generated/settlement_workshop.tscn"
const BEST_3D_ID := "settlement_workshop-v008"


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
	if String(recipe_value.get("method", "")) != "godot_alternate_two_tier_clerestory_canopy":
		_fail("unsupported alternate workshop method")
		return
	if not bool(parameters.get("materially_different_strategy", false)):
		_fail("third attempt must declare a materially different strategy")
		return
	if String(parameters.get("visual_director_target", "")) != TARGET:
		_fail("recipe must reference the approved raised-canopy target")
		return
	if String(parameters.get("incumbent_scene", "")) != BEST_3D:
		_fail("alternate canopy must edit the best current v008 scene")
		return
	if not FileAccess.file_exists("res://" + TARGET) or not FileAccess.file_exists("res://" + BEST_3D):
		_fail("approved target or best current scene is missing")
		return

	var packed := load("res://" + BEST_3D) as PackedScene
	if packed == null:
		_fail("could not load best current workshop scene")
		return
	var asset := packed.instantiate() as Node3D
	asset.name = "SettlementWorkshopTwoTierCanopy"
	asset.set_meta("presentation_only", true)

	var roof_material := _find_material(asset, "RidgeCanopyLeftStandingSeamPanel")
	var copper_material := _find_material(asset, "RidgeCanopyCopperRidgeCap")
	var timber_material := _find_material(asset, "RidgeCanopyLeftRafter_")
	if roof_material == null or copper_material == null or timber_material == null:
		asset.free()
		_fail("best candidate roof, copper, or timber materials are missing")
		return

	# Replace only the prior canopy assembly. The boiler, stack, bench, walls,
	# accepted fittings, and presentation/gameplay ownership remain in the scene.
	for child in asset.get_children():
		if child.name.begins_with("RidgeCanopy"):
			asset.remove_child(child)
			child.free()

	var canopy: Dictionary = parameters.get("canopy", {})
	var x_left := float(canopy.get("lower_left_x", -11.5))
	var x_ridge := float(canopy.get("lower_ridge_x", 0.0))
	var x_right := float(canopy.get("lower_right_x", 11.5))
	var y_eave := float(canopy.get("lower_eave_y", 14.35))
	var y_ridge := float(canopy.get("lower_ridge_y", 16.65))
	var z_front := float(canopy.get("front_z", -8.9))
	var z_back := float(canopy.get("back_z", 8.9))
	var x_cut_left := float(canopy.get("chimney_cut_left_x", -7.95))
	var x_cut_right := float(canopy.get("chimney_cut_right_x", -5.05))
	var z_cut_front := float(canopy.get("chimney_cut_front_z", -3.45))
	var z_cut_back := float(canopy.get("chimney_cut_back_z", -0.55))
	_build_lower_roof(
		asset,
		x_left,
		x_ridge,
		x_right,
		y_eave,
		y_ridge,
		z_front,
		z_back,
		x_cut_left,
		x_cut_right,
		z_cut_front,
		z_cut_back,
		roof_material,
		copper_material,
		timber_material
	)
	_build_raised_ridge(
		asset,
		float(canopy.get("upper_left_x", -3.6)),
		float(canopy.get("upper_ridge_x", 0.0)),
		float(canopy.get("upper_right_x", 3.6)),
		float(canopy.get("upper_eave_y", 17.25)),
		float(canopy.get("upper_ridge_y", 19.05)),
		float(canopy.get("upper_front_z", 0.2)),
		float(canopy.get("upper_back_z", 8.45)),
		roof_material,
		copper_material,
		timber_material
	)

	_assign_owner(asset, asset)
	var output_path := output_directory.path_join("settlement_workshop.tscn")
	DirAccess.make_dir_recursive_absolute(output_directory)
	var scene := PackedScene.new()
	var pack_error := scene.pack(asset)
	if pack_error != OK:
		asset.free()
		_fail("could not pack two-tier canopy, error=%d" % pack_error)
		return
	var save_error := ResourceSaver.save(scene, output_path)
	asset.free()
	if save_error != OK:
		_fail("could not save two-tier canopy, error=%d" % save_error)
		return

	var record := {
		"asset_id": "settlement_workshop",
		"method": "godot_alternate_two_tier_clerestory_canopy",
		"parent_candidate_id": BEST_3D_ID,
		"visual_director_target": TARGET,
		"transfer_diagnosis_ref": String(parameters.get("diagnosis_ref", "")),
		"roof_strategy": "full-width lower gable with a chimney clearance and a raised rear ridge tier",
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


func _build_lower_roof(
	parent: Node3D,
	x_left: float,
	x_ridge: float,
	x_right: float,
	y_eave: float,
	y_ridge: float,
	z_front: float,
	z_back: float,
	x_cut_left: float,
	x_cut_right: float,
	z_cut_front: float,
	z_cut_back: float,
	roof_material: StandardMaterial3D,
	copper_material: StandardMaterial3D,
	timber_material: StandardMaterial3D
) -> void:
	# Tile the boiler-side roof plane around a real clearance for the stack cap.
	var x_breaks := [x_left, x_cut_left, x_cut_right, x_ridge]
	var z_breaks := [z_front, z_cut_front, z_cut_back, z_back]
	for x_index in range(x_breaks.size() - 1):
		for z_index in range(z_breaks.size() - 1):
			if x_index == 1 and z_index == 1:
				continue
			_roof_patch(
				parent,
				"LowerRoofStackCutout_%d_%d" % [x_index, z_index],
				float(x_breaks[x_index]),
				float(x_breaks[x_index + 1]),
				float(z_breaks[z_index]),
				float(z_breaks[z_index + 1]),
				x_left,
			y_eave,
			x_ridge,
			y_ridge,
			0.34,
			0.0,
			roof_material
			)
	_roof_patch(
		parent,
		"LowerRoofRightPlane",
		x_ridge,
		x_right,
		z_front,
		z_back,
		x_ridge,
		y_ridge,
		x_right,
		y_eave,
		0.34,
		0.0,
		roof_material
	)

	# Copper flashing returns frame the flue penetration on all four sides.
	_roof_patch(parent, "StackFlashingLeft", x_cut_left, x_cut_left + 0.16, z_cut_front, z_cut_back, x_left, y_eave, x_ridge, y_ridge, 0.12, 0.22, copper_material)
	_roof_patch(parent, "StackFlashingRight", x_cut_right - 0.16, x_cut_right, z_cut_front, z_cut_back, x_left, y_eave, x_ridge, y_ridge, 0.12, 0.22, copper_material)
	_roof_patch(parent, "StackFlashingFront", x_cut_left, x_cut_right, z_cut_front, z_cut_front + 0.15, x_left, y_eave, x_ridge, y_ridge, 0.12, 0.22, copper_material)
	_roof_patch(parent, "StackFlashingBack", x_cut_left, x_cut_right, z_cut_back - 0.15, z_cut_back, x_left, y_eave, x_ridge, y_ridge, 0.12, 0.22, copper_material)

	# Standing seams follow each pitch but leave the stack opening unobstructed.
	for z_value in [z_front + 1.7, z_front + 4.0, z_front + 7.8, z_front + 11.3, z_front + 14.8, z_back - 1.5]:
		var seam_z := float(z_value)
		if seam_z > z_cut_front - 0.1 and seam_z < z_cut_back + 0.1:
			continue
		_sloped_beam(parent, "LowerRoofLeftCopperSeam_%0.1f" % seam_z, x_left, y_eave + 0.20, x_ridge, y_ridge + 0.20, seam_z, 0.09, 0.12, copper_material)
		_sloped_beam(parent, "LowerRoofRightCopperSeam_%0.1f" % seam_z, x_ridge, y_ridge + 0.20, x_right, y_eave + 0.20, seam_z, 0.09, 0.12, copper_material)

	# Load paths: five cross trusses, longitudinal purlins, and corner knees.
	var truss_z := [z_front + 0.55, z_front + 3.15, z_front + 7.15, z_front + 12.4, z_back - 0.55]
	for z_value in truss_z:
		var z := float(z_value)
		_sloped_beam(parent, "LowerTrussLeftRafter_%0.1f" % z, x_left, y_eave, x_ridge, y_ridge, z, 0.42, 0.46, timber_material)
		_sloped_beam(parent, "LowerTrussRightRafter_%0.1f" % z, x_ridge, y_ridge, x_right, y_eave, z, 0.42, 0.46, timber_material)
		_beam(parent, "LowerTrussTie_%0.1f" % z, Vector3(x_left, 13.55, z), Vector3(x_right, 13.55, z), 0.38, 0.42, timber_material)
		_box(parent, "LowerTrussKingPost_%0.1f" % z, Vector3(0.36, y_ridge - 13.55, 0.42), Vector3(x_ridge, (y_ridge + 13.55) * 0.5, z), timber_material)
	for z_value in [z_front + 0.7, 0.0, z_back - 0.7]:
		var z := float(z_value)
		_box(parent, "LowerEavePostLeft_%0.1f" % z, Vector3(0.48, 4.9, 0.48), Vector3(x_left, 11.9, z), timber_material)
		_box(parent, "LowerEavePostRight_%0.1f" % z, Vector3(0.48, 4.9, 0.48), Vector3(x_right, 11.9, z), timber_material)
		_beam(parent, "LowerKneeLeft_%0.1f" % z, Vector3(x_left + 0.1, 10.2, z), Vector3(x_left + 2.15, 14.0, z), 0.28, 0.32, timber_material)
		_beam(parent, "LowerKneeRight_%0.1f" % z, Vector3(x_right - 0.1, 10.2, z), Vector3(x_right - 2.15, 14.0, z), 0.28, 0.32, timber_material)
	_box(parent, "LowerEavePurlinLeft", Vector3(0.42, 0.48, z_back - z_front), Vector3(x_left, y_eave - 0.12, (z_front + z_back) * 0.5), timber_material)
	_box(parent, "LowerEavePurlinRight", Vector3(0.42, 0.48, z_back - z_front), Vector3(x_right, y_eave - 0.12, (z_front + z_back) * 0.5), timber_material)
	_box(parent, "LowerRidgePurlin", Vector3(0.48, 0.5, z_back - z_front), Vector3(x_ridge, y_ridge - 0.16, (z_front + z_back) * 0.5), timber_material)


func _build_raised_ridge(
	parent: Node3D,
x_left: float,
x_ridge: float,
x_right: float,
y_eave: float,
y_ridge: float,
z_front: float,
z_back: float,
roof_material: StandardMaterial3D,
copper_material: StandardMaterial3D,
timber_material: StandardMaterial3D
) -> void:
	_roof_patch(parent, "UpperRaisedRoofLeft", x_left, x_ridge, z_front, z_back, x_left, y_eave, x_ridge, y_ridge, 0.30, 0.0, roof_material)
	_roof_patch(parent, "UpperRaisedRoofRight", x_ridge, x_right, z_front, z_back, x_ridge, y_ridge, x_right, y_eave, 0.30, 0.0, roof_material)
	for z_value in [z_front + 1.25, z_front + 3.45, z_front + 5.65, z_back - 0.8]:
		var z := float(z_value)
		_sloped_beam(parent, "UpperRaisedCopperSeamLeft_%0.1f" % z, x_left, y_eave + 0.18, x_ridge, y_ridge + 0.18, z, 0.08, 0.11, copper_material)
		_sloped_beam(parent, "UpperRaisedCopperSeamRight_%0.1f" % z, x_ridge, y_ridge + 0.18, x_right, y_eave + 0.18, z, 0.08, 0.11, copper_material)
	var upper_truss_z := [z_front, (z_front + z_back) * 0.5, z_back]
	for z_value in upper_truss_z:
		var z := float(z_value)
		_sloped_beam(parent, "UpperTrussLeftRafter_%0.1f" % z, x_left, y_eave, x_ridge, y_ridge, z, 0.34, 0.36, timber_material)
		_sloped_beam(parent, "UpperTrussRightRafter_%0.1f" % z, x_ridge, y_ridge, x_right, y_eave, z, 0.34, 0.36, timber_material)
		_beam(parent, "UpperTrussTie_%0.1f" % z, Vector3(x_left, y_eave - 0.1, z), Vector3(x_right, y_eave - 0.1, z), 0.28, 0.32, timber_material)
		_box(parent, "UpperTrussKingPost_%0.1f" % z, Vector3(0.28, y_ridge - y_eave + 0.1, 0.32), Vector3(x_ridge, (y_ridge + y_eave - 0.1) * 0.5, z), timber_material)
	for x in [x_left, x_right]:
		_box(parent, "UpperMonitorPost_%0.2f" % x, Vector3(0.34, 0.75, z_back - z_front), Vector3(x, (y_eave + 16.7) * 0.5, (z_front + z_back) * 0.5), timber_material)
	_box(parent, "UpperMonitorRidgeBeam", Vector3(0.38, 0.36, z_back - z_front), Vector3(x_ridge, y_ridge - 0.22, (z_front + z_back) * 0.5), timber_material)
	_box(parent, "UpperCopperRidgeCap", Vector3(0.46, 0.28, z_back - z_front + 0.16), Vector3(x_ridge, y_ridge + 0.22, (z_front + z_back) * 0.5), copper_material)


func _roof_patch(
	parent: Node3D,
label: String,
x_min: float,
x_max: float,
z_min: float,
z_max: float,
line_x0: float,
line_y0: float,
line_x1: float,
line_y1: float,
thickness: float,
lift: float,
material: StandardMaterial3D
) -> void:
	if x_max - x_min < 0.05 or z_max - z_min < 0.05:
		return
	var y0 := _line_y(x_min, line_x0, line_y0, line_x1, line_y1) + lift
	var y1 := _line_y(x_max, line_x0, line_y0, line_x1, line_y1) + lift
	var direction := Vector2(x_max - x_min, y1 - y0)
	var panel := _box(
		parent,
		label,
		Vector3(direction.length(), thickness, z_max - z_min),
		Vector3((x_min + x_max) * 0.5, (y0 + y1) * 0.5, (z_min + z_max) * 0.5),
		material
	)
	panel.rotation.z = atan2(direction.y, direction.x)


func _sloped_beam(
	parent: Node3D,
label: String,
x0: float,
y0: float,
x1: float,
y1: float,
z: float,
height: float,
depth: float,
material: StandardMaterial3D
) -> void:
	var direction := Vector2(x1 - x0, y1 - y0)
	var item := _box(
		parent,
		label,
		Vector3(direction.length(), height, depth),
		Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z),
		material
	)
	item.rotation.z = atan2(direction.y, direction.x)


func _beam(parent: Node3D, label: String, start: Vector3, finish: Vector3, height: float, depth: float, material: StandardMaterial3D) -> void:
	var direction := finish - start
	var item := _box(parent, label, Vector3(Vector2(direction.x, direction.y).length(), height, depth), (start + finish) * 0.5, material)
	item.rotation.z = atan2(direction.y, direction.x)


func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var item := G.box(parent, label, size, at, "wood", Color("63452f"), 0.045)
	item.material_override = material.duplicate(true) as StandardMaterial3D
	return item


func _find_material(parent: Node, name_prefix: String) -> StandardMaterial3D:
	for child in parent.get_children():
		if not child.name.begins_with(name_prefix):
			continue
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null and mesh_instance.material_override is StandardMaterial3D:
			return (mesh_instance.material_override as StandardMaterial3D).duplicate(true)
	return null


func _line_y(x: float, x0: float, y0: float, x1: float, y1: float) -> float:
	return lerpf(y0, y1, (x - x0) / (x1 - x0))


func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_assign_owner(child, owner)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + message)
	quit(1)
