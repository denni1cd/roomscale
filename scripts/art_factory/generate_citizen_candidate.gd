extends SceneTree
## Recorded Godot recipe generator for the animated RoomScale citizen skin.

const G := preload("res://scripts/visuals/visual_geometry.gd")
const Materials := preload("res://scripts/visuals/material_library.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var brief_path := OS.get_environment("ROOMSCALE_ART_FACTORY_BRIEF")
	var recipe_path := OS.get_environment("ROOMSCALE_ART_FACTORY_RECIPE")
	var output_directory := OS.get_environment("ROOMSCALE_ART_FACTORY_OUTPUT_DIR")
	if brief_path.is_empty() or recipe_path.is_empty() or output_directory.is_empty():
		_fail("brief, recipe, and output directory are required")
		return
	var brief: Variant = JSON.parse_string(FileAccess.get_file_as_string(brief_path))
	var recipe: Variant = JSON.parse_string(FileAccess.get_file_as_string(recipe_path))
	if not brief is Dictionary or not recipe is Dictionary:
		_fail("brief and recipe must be JSON objects")
		return
	if String(brief.get("asset_id", "")) != "citizen":
		_fail("generator only accepts the stable citizen asset brief")
		return
	var method := String(recipe.get("method", ""))
	if method not in ["tailored_clockwork_worker_v1", "tailored_clockwork_worker_v2", "tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
		_fail("unsupported citizen recipe method: %s" % method)
	var asset := Node3D.new()
	asset.name = "CitizenArtAsset"
	_build_citizen(asset, method)
	_assign_owner(asset, asset)
	root.add_child(asset)
	await process_frame
	DirAccess.make_dir_recursive_absolute(output_directory)
	var packed := PackedScene.new()
	var output_path := output_directory.path_join("citizen.tscn")
	var error := packed.pack(asset)
	if error == OK:
		error = ResourceSaver.save(packed, output_path)
	if error != OK:
		_fail("could not save native citizen scene, Godot error=%d" % error)
		asset.free()
		return
	var meshes := asset.find_children("*", "MeshInstance3D", true, false).size()
	print("ROOMSCALE_ART_FACTORY_GENERATION_PASS method=%s path=%s mesh_parts=%d" % [method, output_path, meshes])
	asset.free()
	await process_frame
	quit(0)


func _build_citizen(asset: Node3D, method: String) -> void:
	var sleeve := Materials.get_material("leather", Color("71553f"))
	var skin := Materials.get_material("skin", Color("edcba2"))
	var leather := Materials.get_material("leather", Color("574537"))
	var iron := Materials.get_material("iron", Color("26383e"))
	var brass := Materials.get_material("brass", Color("d5a746"))
	var copper := Materials.get_material("copper", Color("a45d39"))
	var glass := Materials.get_material("glass", Color("294f59"))
	var dark := Materials.get_material("iron", Color("16262c"))

	# Five mesh pivots retain the production animator's exact rig contract.
	var coat_category := "citizen_fabric" if method == "tailored_clockwork_worker_v7" else "fabric"
	var body := G.box(asset, "Body", Vector3(0.15, 0.21, 0.11), Vector3(0.0, 0.23, 0.0), coat_category, Color("a87950"), 0.018)
	G.box(body, "TailoredVest", Vector3(0.099, 0.145, 0.019), Vector3(0.0, -0.005, 0.057), "leather", Color("574537"), 0.009)
	G.box(body, "LeftLapel", Vector3(0.035, 0.074, 0.012), Vector3(-0.028, 0.047, 0.07), "citizen_fabric", Color("c18d59"), 0.006).rotation.z = deg_to_rad(-12.0)
	G.box(body, "RightLapel", Vector3(0.035, 0.074, 0.012), Vector3(0.028, 0.047, 0.07), "citizen_fabric", Color("c18d59"), 0.006).rotation.z = deg_to_rad(12.0)
	G.box(body, "RaisedCollar", Vector3(0.10, 0.026, 0.075), Vector3(0.0, 0.092, 0.004), "leather", Color("4c3b31"), 0.007)
	G.box(body, "WaistBelt", Vector3(0.158, 0.027, 0.118), Vector3(0.0, -0.067, 0.0), "leather", Color("44352d"), 0.007)
	G.box(body, "SideSeamL", Vector3(0.008, 0.125, 0.009), Vector3(-0.073, -0.009, 0.045), "citizen_fabric", Color("cfaa6c"), 0.003)
	G.box(body, "SideSeamR", Vector3(0.008, 0.125, 0.009), Vector3(0.073, -0.009, 0.045), "citizen_fabric", Color("cfaa6c"), 0.003)
	if method == "tailored_clockwork_worker_v6":
		G.box(body, "RearCenterSeam", Vector3(0.004, 0.15, 0.006), Vector3(0.0, -0.002, -0.057), "citizen_fabric", Color("c18d59"), 0.0015)
		G.box(body, "RearShoulderSeam", Vector3(0.10, 0.004, 0.006), Vector3(0.0, 0.052, -0.057), "citizen_fabric", Color("c18d59"), 0.0015)
		G.box(body, "RearHemStitch", Vector3(0.12, 0.003, 0.006), Vector3(0.0, -0.093, -0.057), "citizen_fabric", Color("cfaa6c"), 0.001)
	if method == "tailored_clockwork_worker_v7":
		G.box(body, "RearCenterSeam", Vector3(0.003, 0.13, 0.004), Vector3(0.0, -0.004, -0.057), "citizen_fabric", Color("89936f"), 0.001)
		for side in [-1.0, 1.0]:
			G.box(body, "RearTailorDart%s" % side, Vector3(0.003, 0.068, 0.004), Vector3(side * 0.052, -0.008, -0.056), "citizen_fabric", Color("89936f"), 0.001)
		G.box(body, "RearHemFinish", Vector3(0.10, 0.002, 0.003), Vector3(0.0, -0.094, -0.056), "citizen_fabric", Color("96a07a"), 0.0008)
	for button_index in range(3):
		_sphere(body, "CoatButton%d" % button_index, 0.009, Vector3(0.0, 0.036 - button_index * 0.035, 0.071), brass)
	var emblem := G.gear(body, "TailorBadge", 0.021, Vector3(0.047, 0.061, 0.071), 8)
	emblem.rotation.x = PI * 0.5
	G.cylinder(body, "BadgeCenter", 0.007, 0.012, Vector3(0.047, 0.061, 0.084), "copper", Color("a45d39")).rotation.x = PI * 0.5

	var head := _sphere(asset, "Head", 0.066, Vector3(0.0, 0.395, 0.0), skin)
	_sphere(head, "Nose", 0.014, Vector3(0.0, -0.002, 0.064), skin)
	if method in ["tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
		for side in [-1.0, 1.0]:
			_sphere(head, "Cheek%s" % side, 0.007, Vector3(side * 0.044, -0.012, 0.047), Materials.get_material("skin", Color("d9b58f")))
	_sphere(head, "EyeL", 0.009, Vector3(-0.024, 0.009, 0.056), dark)
	_sphere(head, "EyeR", 0.009, Vector3(0.024, 0.009, 0.056), dark)
	G.box(head, "Mouth", Vector3(0.027, 0.006, 0.006), Vector3(0.0, -0.024, 0.063), "leather", Color("633b31"), 0.002)

	var cap_brim := G.cylinder(asset, "CapBrim", 0.105, 0.018, Vector3(0.0, 0.448, 0.0), "leather", Color("574537"))
	var cap := G.cylinder(asset, "ClockworkCap", 0.086, 0.05, Vector3(0.0, 0.475, 0.0), "citizen_fabric", Color("38535a"))
	cap.scale.x = 0.91
	cap.scale.z = 0.91
	if method in ["tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
		var cap_seam_color := Color("536a70") if method == "tailored_clockwork_worker_v6" else Color("455b60")
		var cap_seam_size := Vector3(0.004, 0.002, 0.09) if method == "tailored_clockwork_worker_v6" else Vector3(0.002, 0.0015, 0.08)
		G.box(asset, "CapTopSeam", cap_seam_size, Vector3(0.0, 0.499, 0.0), "citizen_fabric", cap_seam_color, 0.0008)
	if method == "tailored_clockwork_worker_v2":
		# v1's brim dominated the small face. Narrow the silhouette to expose the
		# goggles and let the asymmetric clockwork winding carry the style read.
		cap_brim.scale.x = 0.84
		cap_brim.scale.z = 0.84
		cap.scale.x = 0.88
		cap.scale.z = 0.88
	if method in ["tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
		# v2 reduced the brim but kept it at eye level. Lift it to the crown seam,
		# thin it, and bring its edge close to the head width so the face reads.
		var brim_scale := 0.70 if method == "tailored_clockwork_worker_v3" else (0.72 if method == "tailored_clockwork_worker_v4" else 0.82)
		cap_brim.scale.x = brim_scale
		cap_brim.scale.z = brim_scale
		cap_brim.position.y = 0.461
		cap_brim.mesh.height = 0.012
		cap.scale.x = 0.78
		cap.scale.z = 0.78
		cap.scale.y = 0.84
		cap.position.y = 0.477
	var cap_band := G.cylinder(asset, "CapBand", 0.088, 0.009, Vector3(0.0, 0.461, 0.0), "brass", Color("b58939"))
	if method in ["tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
		cap_band.scale.x = 0.76
		cap_band.scale.z = 0.76
		cap_band.position.y = 0.467
	var cap_gear_radius := 0.026
	var cap_gear_position := Vector3(0.0, 0.47, 0.061)
	if method in ["tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
		cap_gear_radius = 0.021
		cap_gear_position = Vector3(0.0, 0.481, 0.052)
	var capGear := G.gear(asset, "CapGear", cap_gear_radius, cap_gear_position, 10)
	capGear.rotation.x = PI * 0.5
	var cap_gear_pin_radius := 0.007
	var cap_gear_pin_height := 0.014
	var cap_gear_pin_position := Vector3(0.0, 0.47, 0.078)
	if method in ["tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
		cap_gear_pin_radius = 0.006
		cap_gear_pin_height = 0.012
		cap_gear_pin_position = Vector3(0.0, 0.481, 0.069)
	G.cylinder(asset, "CapGearPin", cap_gear_pin_radius, cap_gear_pin_height, cap_gear_pin_position, "copper", Color("a45d39")).rotation.x = PI * 0.5
	if method in ["tailored_clockwork_worker_v2", "tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
		_add_cap_winding(asset, brass, iron, method in ["tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"])

	# Two brass-frame goggles remain recognizable under every camera turn.
	for side in [-1.0, 1.0]:
		var frame := _torus(asset, "GoggleFrame%s" % side, 0.020, 0.027, Vector3(side * 0.031, 0.409, 0.066), brass)
		frame.rotation = Vector3.ZERO
		var lens := G.cylinder(asset, "GoggleLens%s" % side, 0.019, 0.012, Vector3(side * 0.031, 0.409, 0.066), "glass", Color("294f59"))
		lens.rotation.x = PI * 0.5
		_sphere(asset, "GoggleGlint%s" % side, 0.0045, Vector3(side * 0.031 - 0.004, 0.414, 0.074), Materials.get_material("paint", Color("d5e4d5")))
	G.box(asset, "GoggleBridge", Vector3(0.025, 0.012, 0.014), Vector3(0.0, 0.409, 0.071), "brass", Color("d5a746"), 0.004)
	G.box(asset, "GoggleStrap", Vector3(0.078, 0.010, 0.012), Vector3(0.0, 0.434, 0.0), "leather", Color("453832"), 0.004)

	var left_arm := _capsule(asset, "LeftArm", 0.024, 0.17, Vector3(-0.105, 0.235, 0.0), sleeve)
	var right_arm := _capsule(asset, "RightArm", 0.024, 0.17, Vector3(0.105, 0.235, 0.0), sleeve)
	for side in [-1.0, 1.0]:
		var arm := left_arm if side < 0.0 else right_arm
		G.cylinder(arm, "Cuff%s" % side, 0.027, 0.022, Vector3(0.0, -0.059, 0.0), "brass", Color("b58939"))
		G.box(arm, "Glove%s" % side, Vector3(0.043, 0.035, 0.04), Vector3(0.0, -0.084, 0.008), "leather", Color("47382f"), 0.009)
		var shoulder_size := Vector3(0.043, 0.03, 0.052) if method in ["tailored_clockwork_worker_v2", "tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"] else Vector3(0.055, 0.04, 0.069)
		var shoulder_at := Vector3(side * 0.095, 0.303, 0.0) if method in ["tailored_clockwork_worker_v2", "tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"] else Vector3(side * 0.099, 0.307, 0.0)
		if method in ["tailored_clockwork_worker_v3", "tailored_clockwork_worker_v4", "tailored_clockwork_worker_v5", "tailored_clockwork_worker_v6", "tailored_clockwork_worker_v7"]:
			var shoulder := _sphere(asset, "ShoulderPlate%s" % side, 0.023, shoulder_at, Materials.get_material("iron", Color("445359")))
			shoulder.scale = Vector3(1.0, 0.55, 1.0)
		else:
			G.box(asset, "ShoulderPlate%s" % side, shoulder_size, shoulder_at, "iron", Color("445359"), 0.01)
		G.cylinder(asset, "ShoulderRivet%s" % side, 0.008, 0.008, shoulder_at + Vector3(0.0, 0.0, 0.03), "brass", Color("d5a746"))

	var left_leg := _capsule(asset, "LeftLeg", 0.025, 0.19, Vector3(-0.045, 0.095, 0.0), leather)
	var right_leg := _capsule(asset, "RightLeg", 0.025, 0.19, Vector3(0.045, 0.095, 0.0), leather)
	for side in [-1.0, 1.0]:
		var leg := left_leg if side < 0.0 else right_leg
		G.box(leg, "Boot%s" % side, Vector3(0.064, 0.045, 0.09), Vector3(0.0, -0.07, 0.018), "leather", Color("493a31"), 0.009)
		G.box(leg, "BootSole%s" % side, Vector3(0.066, 0.009, 0.092), Vector3(0.0, -0.091, 0.018), "iron", Color("202b2e"), 0.003)
		G.cylinder(leg, "LegKneeRivet%s" % side, 0.008, 0.008, Vector3(0.0, 0.041, 0.024), "brass", Color("b58939"))

	# The production role pack owns the backpack silhouette; v1's candidate
	# yoke duplicated it, so the challenger leaves the role attachment clear.
	if method == "tailored_clockwork_worker_v1":
		G.box(asset, "HarnessYoke", Vector3(0.19, 0.043, 0.035), Vector3(0.0, 0.321, -0.066), "iron", Color("33464c"), 0.008)
		for side in [-1.0, 1.0]:
			G.box(asset, "HarnessStrap%s" % side, Vector3(0.018, 0.20, 0.014), Vector3(side * 0.058, 0.244, -0.061), "leather", Color("574537"), 0.004)
			G.cylinder(asset, "HarnessBuckle%s" % side, 0.012, 0.008, Vector3(side * 0.058, 0.25, -0.049), "brass", Color("d5a746"))


func _add_cap_winding(asset: Node3D, brass: Material, iron: Material, compact: bool = false) -> void:
	# v2 adds a delicate asymmetric side-winding and a finish ridge to respond
	# to the initial close-capture critique without changing the pose pivots.
	var winding_x := 0.073 if not compact else 0.062
	var winding_y := 0.475 if not compact else 0.48
	var winding := G.cylinder(asset, "CapWindingBarrel", 0.012, 0.045, Vector3(winding_x, winding_y, -0.004), "iron", Color("26383e"))
	winding.rotation.z = PI * 0.5
	G.cylinder(asset, "CapWindingHub", 0.012, 0.025, Vector3(winding_x + 0.002, winding_y, 0.023), "brass", Color("d5a746")).rotation.z = PI * 0.5
	var ridge_width := 0.12 if not compact else 0.105
	var ridge_y := 0.452 if not compact else 0.466
	G.box(asset, "CapFinishRidge", Vector3(ridge_width, 0.006, 0.006), Vector3(0.0, ridge_y, 0.0), "brass", Color("b58939"), 0.002)
	_sphere(asset, "CapWindingPin", 0.005, Vector3(winding_x + 0.015, winding_y, 0.023), brass)
	_sphere(asset, "CapWindingSocket", 0.004, Vector3(winding_x - 0.016, winding_y, 0.023), iron)


func _capsule(parent: Node3D, label: String, radius: float, height: float, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 8
	part.mesh = mesh
	part.position = at
	part.material_override = material
	parent.add_child(part)
	return part


func _sphere(parent: Node3D, label: String, radius: float, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	part.mesh = mesh
	part.position = at
	part.material_override = material
	parent.add_child(part)
	return part


func _torus(parent: Node3D, label: String, inner: float, outer: float, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 24
	mesh.ring_segments = 8
	part.mesh = mesh
	part.position = at
	part.material_override = material
	parent.add_child(part)
	return part


func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_assign_owner(child, owner)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + message)
	quit(1)
