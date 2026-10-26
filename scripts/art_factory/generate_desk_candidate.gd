extends SceneTree
## Recorded offline generator for the desk pilot. It never changes gameplay geometry.

const Geometry := preload("res://scripts/visuals/visual_geometry.gd")
const Furniture := preload("res://scripts/visuals/furniture_recipes.gd")


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
	var dimensions: Array = brief.get("intended_dimensions", [])
	if dimensions.size() != 3:
		_fail("desk brief must provide three intended dimensions")
		return
	var size := Vector3(float(dimensions[0]), float(dimensions[1]), float(dimensions[2]))
	if minf(size.x, minf(size.y, size.z)) <= 0.0:
		_fail("desk dimensions must be positive")
		return
	var asset := Node3D.new()
	asset.name = "DeskAsset"
	var method := String(recipe.get("method", ""))
	match method:
		"basic_rectangular_desk":
			_build_basic(asset, size, recipe.get("parameters", {}))
		"beveled_smoked_glass_and_tubular_frame":
			_build_glass_frame(asset, size, recipe.get("parameters", {}))
		"standing_desk_t_frame_glass":
			_build_t_frame_desk(asset, size, recipe.get("parameters", {}))
		"native_scene_standing_desk_t_frame_glass":
			_build_t_frame_desk(asset, size, recipe.get("parameters", {}))
		_:
			_fail("unsupported desk recipe method: %s" % method)
			asset.free()
			return
	root.add_child(asset)
	await process_frame
	DirAccess.make_dir_recursive_absolute(output_directory)
	var use_native_scene := method == "native_scene_standing_desk_t_frame_glass"
	var output_path := output_directory.path_join("desk.tscn" if use_native_scene else "desk.glb")
	var error := OK
	if use_native_scene:
		_assign_owner(asset, asset)
		var packed_scene := PackedScene.new()
		error = packed_scene.pack(asset)
		if error == OK:
			error = ResourceSaver.save(packed_scene, output_path)
	else:
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		error = document.append_from_scene(asset, state)
		if error == OK:
			error = document.write_to_filesystem(state, output_path)
	if error != OK:
		_fail("could not export candidate GLB, Godot error=%d" % error)
		asset.free()
		return
	print("ROOMSCALE_ART_FACTORY_GENERATION_PASS method=%s path=%s mesh_parts=%d" % [method, output_path, asset.get_child_count()])
	asset.free()
	await process_frame
	quit(0)


func _build_basic(asset: Node3D, size: Vector3, parameters: Dictionary) -> void:
	var color := Color(String(parameters.get("color", "202427")))
	var spec := {"kind": "desk", "dimensions": [size.x, size.y, size.z], "color": color.to_html(false)}
	var recipe := {"archetype": "desk", "appearance": {"base_color": color.to_html(false)}}
	Furniture.build(asset, spec, recipe)


func _build_glass_frame(asset: Node3D, size: Vector3, parameters: Dictionary) -> void:
	var glass_color := Color(String(parameters.get("glass_color", "1a2225")))
	var frame_color := Color(String(parameters.get("frame_color", "252b2e")))
	var metal_color := Color(String(parameters.get("metal_color", "778187")))
	var top_thickness := clampf(float(parameters.get("top_thickness", 0.7)), 0.35, 1.2)
	var leg_radius := clampf(float(parameters.get("leg_radius", 0.68)), 0.4, 0.95)
	var top_y := size.y - top_thickness * 0.5
	_add_box(asset, "SmokedGlassTop", Vector3(size.x, top_thickness, size.z), Vector3(0, top_y, 0), _material(glass_color, 0.42, 0.18), minf(top_thickness * 0.45, 0.25))
	_add_box(asset, "PolishedFrontEdge", Vector3(size.x * 0.985, 0.12, 0.38), Vector3(0, size.y - top_thickness - 0.05, size.z * 0.49), _material(Color("333b3e"), 0.7, 0.24), 0.05)
	var leg_height := size.y - top_thickness - 0.7
	var x_offset := size.x * 0.43
	var z_offset := size.z * 0.40
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			var leg := _add_cylinder(asset, "TubularLeg_%s_%s" % [side_x, side_z], leg_radius, leg_height, Vector3(side_x * x_offset, leg_height * 0.5, side_z * z_offset), _material(frame_color, 0.72, 0.32))
			leg.rotation.z = deg_to_rad(float(parameters.get("leg_splay_degrees", 0.0))) * -side_x
			_add_cylinder(asset, "LevelingFoot_%s_%s" % [side_x, side_z], leg_radius * 1.12, 0.72, Vector3(side_x * x_offset, 0.36, side_z * z_offset), _material(Color("111416"), 0.05, 0.76))
			_add_cylinder(asset, "UpperCollar_%s_%s" % [side_x, side_z], leg_radius * 1.3, 0.4, Vector3(side_x * x_offset, size.y - top_thickness - 0.42, side_z * z_offset), _material(metal_color, 0.82, 0.26))
	for side_z in [-1.0, 1.0]:
		_add_box(asset, "LongitudinalSupport_%s" % side_z, Vector3(size.x * 0.82, 0.72, 0.65), Vector3(0, size.y * 0.73, side_z * z_offset), _material(frame_color, 0.7, 0.34), 0.24)
	for side_x in [-1.0, 1.0]:
		_add_box(asset, "EndSupport_%s" % side_x, Vector3(0.65, 0.72, size.z * 0.72), Vector3(side_x * x_offset, size.y * 0.73, 0), _material(frame_color, 0.7, 0.34), 0.22)
	_add_box(asset, "CableTray", Vector3(size.x * 0.42, 0.55, size.z * 0.34), Vector3(0, size.y * 0.82, -size.z * 0.1), _material(Color("14191b"), 0.28, 0.68), 0.14)
	# Four restrained mounting discs catch light through the dark top at close range.
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			_add_cylinder(asset, "GlassMount_%s_%s" % [side_x, side_z], 1.05, 0.16, Vector3(side_x * x_offset, size.y - top_thickness - 0.02, side_z * z_offset), _material(metal_color, 0.78, 0.24))


func _build_t_frame_desk(asset: Node3D, size: Vector3, parameters: Dictionary) -> void:
	var top_thickness := clampf(float(parameters.get("top_thickness", 0.72)), 0.35, 1.2)
	var glass_color := Color(String(parameters.get("glass_color", "424b50")))
	var frame_color := Color(String(parameters.get("frame_color", "242a2c")))
	var metal_color := Color(String(parameters.get("metal_color", "929da2")))
	var rubber_color := Color(String(parameters.get("rubber_color", "111416")))
	var glass_alpha := clampf(float(parameters.get("glass_alpha", 1.0)), 0.35, 1.0)
	var top_y := size.y - top_thickness * 0.5
	_add_box(asset, "SmokedGlassTop", Vector3(size.x, top_thickness, size.z), Vector3(0, top_y, 0), _material(glass_color, 0.08, 0.08, 0.98, glass_alpha, float(parameters.get("glass_rim", 0.0))), 0.24)
	_add_box(asset, "DarkEdgeBand", Vector3(size.x * 0.99, 0.2, size.z * 0.99), Vector3(0, size.y - top_thickness - 0.1, 0), _material(Color("1b2225"), 0.35, 0.2), 0.08)
	var post_x := size.x * 0.37
	var post_height := size.y - top_thickness - 1.15
	for side_x in [-1.0, 1.0]:
		# The reference uses two independent standing-desk end frames and feet
		# spanning the desktop depth, rather than four furniture-style legs.
		_add_box(asset, "RectangularLiftColumn_%s" % side_x, Vector3(2.0, post_height, 1.75), Vector3(side_x * post_x, post_height * 0.5 + 0.95, 0), _material(frame_color, 0.82, 0.28), 0.34)
		_add_box(asset, "TBaseFoot_%s" % side_x, Vector3(2.7, 0.85, size.z * 0.94), Vector3(side_x * post_x, 0.55, 0), _material(frame_color, 0.82, 0.28), 0.34)
		for side_z in [-1.0, 1.0]:
			_add_box(asset, "RubberLeveler_%s_%s" % [side_x, side_z], Vector3(2.3, 0.38, 1.5), Vector3(side_x * post_x, 0.22, side_z * size.z * 0.41), _material(rubber_color, 0.02, 0.82), 0.12)
		_add_box(asset, "SatinColumnCollar_%s" % side_x, Vector3(2.25, 0.34, 2.05), Vector3(side_x * post_x, size.y - top_thickness - 0.62, 0), _material(metal_color, 0.85, 0.24), 0.18)
	_add_box(asset, "RearCrossbar", Vector3(size.x * 0.78, 1.05, 1.25), Vector3(0, size.y - top_thickness - 2.0, -size.z * 0.25), _material(frame_color, 0.8, 0.3), 0.22)
	_add_box(asset, "CableTray", Vector3(size.x * 0.42, 0.62, size.z * 0.34), Vector3(0, size.y * 0.79, size.z * 0.08), _material(Color("171d1f"), 0.25, 0.66), 0.16)
	_add_box(asset, "HeightControlPad", Vector3(4.8, 0.3, 1.2), Vector3(size.x * 0.28, size.y - top_thickness - 0.52, size.z * 0.47), _material(Color("161b1d"), 0.18, 0.54), 0.16)
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			_add_cylinder(asset, "GlassMount_%s_%s" % [side_x, side_z], 0.88, 0.14, Vector3(side_x * post_x, size.y - top_thickness - 0.02, side_z * size.z * 0.39), _material(metal_color, 0.84, 0.22))


func _add_box(parent: Node3D, label: String, dimensions: Vector3, position: Vector3, material: Material, bevel: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = Geometry.rounded_box(dimensions, bevel)
	node.position = position
	node.material_override = material
	parent.add_child(node)
	return node


func _add_cylinder(parent: Node3D, label: String, radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	node.mesh = mesh
	node.position = position
	node.material_override = material
	parent.add_child(node)
	return node


func _material(color: Color, metallic: float, roughness: float, clearcoat: float = 0.0, alpha: float = 1.0, rim: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.albedo_color.a = alpha
	material.metallic = metallic
	material.roughness = roughness
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	if clearcoat > 0.0:
		material.clearcoat_enabled = true
		material.clearcoat = clampf(clearcoat, 0.0, 1.0)
		material.clearcoat_roughness = 0.08
	if rim > 0.0:
		material.rim_enabled = true
		material.rim = clampf(rim, 0.0, 1.0)
		material.rim_tint = 0.8
	return material


func _assign_owner(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_assign_owner(child, scene_root)


func _fail(reason: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + reason)
	quit(1)
