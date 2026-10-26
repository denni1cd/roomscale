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
	var parameters: Dictionary = recipe.get("parameters", {})
	match method:
		"basic_rectangular_desk":
			_build_basic(asset, size, recipe.get("parameters", {}))
		"beveled_smoked_glass_and_tubular_frame":
			_build_glass_frame(asset, size, recipe.get("parameters", {}))
		"standing_desk_t_frame_glass":
			_build_t_frame_desk(asset, size, recipe.get("parameters", {}))
		"native_scene_standing_desk_t_frame_glass":
			_build_t_frame_desk(asset, size, recipe.get("parameters", {}))
		"photo_grounded_cad_desk_pbr_v1":
			_build_photo_grounded_pbr_desk(asset, size, parameters, output_directory)
		_:
			_fail("unsupported desk recipe method: %s" % method)
			asset.free()
			return
	root.add_child(asset)
	await process_frame
	DirAccess.make_dir_recursive_absolute(output_directory)
	var use_native_scene := method in ["native_scene_standing_desk_t_frame_glass", "photo_grounded_cad_desk_pbr_v1"]
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
	if method == "photo_grounded_cad_desk_pbr_v1":
		var mesh_count := 0
		var triangle_count := 0
		for mesh_variant in asset.find_children("*", "MeshInstance3D", true, false):
			var mesh_node := mesh_variant as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			mesh_count += 1
			for surface_index in range(mesh_node.mesh.get_surface_count()):
				var surface_arrays: Array = mesh_node.mesh.surface_get_arrays(surface_index)
				var indices: PackedInt32Array = surface_arrays[Mesh.ARRAY_INDEX]
				triangle_count += int(indices.size() / 3) if not indices.is_empty() else int((surface_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
		var manifest := {
			"schema_version": 1,
			"candidate_method": method,
			"source_reference": "photo_holder/Sample (2).jpg",
			"source_guidance": "Thin smoked glass top; two dark steel telescoping supports; T feet spanning the desktop depth.",
			"geometry": {"mesh_parts": mesh_count, "triangles": triangle_count, "approach": "CAD-like rounded panels, overlapping manufactured joins, flanges, countersunk fasteners, molded pads, cable pan, and routed leads."},
			"pbr_materials": [
				{"name": "smoked_tempered_glass", "albedo": "128x128 deterministic image map", "roughness": "128x128 deterministic map", "normal": "128x128 deterministic map", "metallic": 0.38, "roughness_base": 0.16},
				{"name": "graphite_powder_coat", "albedo": "128x128 deterministic image map", "roughness": "128x128 deterministic map", "normal": "128x128 brushed normal map", "metallic": 0.72, "roughness_base": 0.38},
				{"name": "satin_machined_steel", "albedo": "128x128 deterministic image map", "roughness": "128x128 deterministic map", "normal": "128x128 radial brushed normal map", "metallic": 0.86, "roughness_base": 0.28}
			],
			"gameplay_geometry": "unchanged; RoomDefinition retains all obstacle, placement, and surface ownership"
		}
		var manifest_file := FileAccess.open(output_directory.path_join("pbr-material-manifest.json"), FileAccess.WRITE)
		manifest_file.store_string(JSON.stringify(manifest, "  ") + "\n")
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


func _build_photo_grounded_pbr_desk(asset: Node3D, size: Vector3, parameters: Dictionary, output_directory: String) -> void:
	# Distinct CAD-like furniture construction method: rounded layered panels,
	# telescoping steel columns, bolted mounting plates, slotted cable tray,
	# molded feet, wiring, and packed spatially textured PBR materials.
	var top_thickness := clampf(float(parameters.get("top_thickness", 0.72)), 0.55, 0.95)
	var top_y := size.y - top_thickness * 0.5
	var glass := _pbr_surface(Color("20272a"), 8025, 0.16, 0.38, "glass")
	var frame := _pbr_surface(Color("191d1f"), 8026, 0.38, 0.72, "vertical_brush")
	var satin := _pbr_surface(Color("70787b"), 8027, 0.28, 0.86, "radial_brush")
	var rubber := _pbr_surface(Color("111416"), 8028, 0.82, 0.02, "rubber")
	var control := _pbr_surface(Color("161a1b"), 8029, 0.44, 0.08, "fine_grain")
	var glass_edge := _material(Color("667174"), 0.72, 0.25)
	var dark_cable := _material(Color("0e1213"), 0.0, 0.68)
	var led := _material(Color("d8e6dc"), 0.0, 0.24)

	# Smoked glass slab with a generous manufactured corner radius and a
	# separate polished laminate edge, rather than a single sharp box primitive.
	_add_box(asset, "RoundedSmokedTemperedGlass", Vector3(size.x, top_thickness, size.z), Vector3(0, top_y, 0), glass, 0.34)
	_add_box(asset, "GlassFrontEdgeLaminate", Vector3(size.x - 0.48, 0.095, 0.18), Vector3(0, top_y - top_thickness * 0.5 + 0.035, size.z * 0.493), glass_edge, 0.055)
	_add_box(asset, "GlassRearEdgeLaminate", Vector3(size.x - 0.48, 0.095, 0.18), Vector3(0, top_y - top_thickness * 0.5 + 0.035, -size.z * 0.493), glass_edge, 0.055)
	for side_x in [-1.0, 1.0]:
		_add_box(asset, "GlassSideEdgeLaminate_%s" % side_x, Vector3(0.18, 0.095, size.z - 0.48), Vector3(side_x * size.x * 0.493, top_y - top_thickness * 0.5 + 0.035, 0), glass_edge, 0.055)

	var frame_y := size.y - top_thickness - 1.15
	var post_x := size.x * 0.37
	# Two continuous T pedestals reflect the actual source desk construction.
	for side_x in [-1.0, 1.0]:
		var x: float = side_x * post_x
		_add_box(asset, "TFootCore_%s" % side_x, Vector3(2.45, 0.86, size.z * 0.92), Vector3(x, 0.56, 0), frame, 0.38)
		_add_box(asset, "TFootUpperSeam_%s" % side_x, Vector3(2.12, 0.14, size.z * 0.84), Vector3(x, 0.98, 0), satin, 0.065)
		_add_box(asset, "FrontFootPad_%s" % side_x, Vector3(1.55, 0.20, 2.3), Vector3(x, 0.09, size.z * 0.39), rubber, 0.09)
		_add_box(asset, "RearFootPad_%s" % side_x, Vector3(1.55, 0.20, 2.3), Vector3(x, 0.09, -size.z * 0.39), rubber, 0.09)
		# Tapered foot caps and inset end plates soften the industrial profile.
		for end_z in [-1.0, 1.0]:
			_add_box(asset, "FootEndCap_%s_%s" % [side_x, end_z], Vector3(2.0, 0.56, 0.48), Vector3(x, 0.56, end_z * (size.z * 0.45 - 0.20)), satin, 0.22)
			_add_cylinder(asset, "FootEndFastener_%s_%s" % [side_x, end_z], 0.14, 0.10, Vector3(x, 0.56, end_z * (size.z * 0.45 - 0.20)), satin)
		# Nested rounded telescoping columns with real overlap, flange, and seam.
		_add_box(asset, "LowerTelescopingColumn_%s" % side_x, Vector3(2.12, frame_y * 0.66, 1.92), Vector3(x, frame_y * 0.34 + 0.95, 0), frame, 0.38)
		_add_box(asset, "UpperLiftColumn_%s" % side_x, Vector3(1.52, frame_y * 0.36, 1.36), Vector3(x, frame_y * 0.83 + 0.95, 0), satin, 0.29)
		_add_box(asset, "ColumnJointSleeve_%s" % side_x, Vector3(2.27, 0.55, 2.07), Vector3(x, frame_y * 0.67 + 0.95, 0), frame, 0.2)
		_add_box(asset, "UpperMountPlate_%s" % side_x, Vector3(8.4, 0.42, 4.3), Vector3(x, size.y - top_thickness - 0.45, 0), frame, 0.26)
		_add_box(asset, "UpperMountInset_%s" % side_x, Vector3(7.6, 0.11, 3.6), Vector3(x, size.y - top_thickness - 0.19, 0), satin, 0.075)
		for fore_aft in [-1.0, 1.0]:
			for bolt_side in [-1.0, 1.0]:
				var bolt_at := Vector3(x + bolt_side * 3.25, size.y - top_thickness - 0.11, fore_aft * 1.35)
				_add_cylinder(asset, "MountWasher_%s_%s_%s" % [side_x, fore_aft, bolt_side], 0.34, 0.08, bolt_at, satin)
				_add_cylinder(asset, "MountBolt_%s_%s_%s" % [side_x, fore_aft, bolt_side], 0.18, 0.13, bolt_at + Vector3.UP * 0.08, frame)
		for seam_side in [-1.0, 1.0]:
			for seam_z in [-0.58, 0.0, 0.58]:
				_add_box(asset, "ColumnFlute_%s_%s_%s" % [side_x, seam_side, seam_z], Vector3(0.075, frame_y * 0.29, 0.12), Vector3(x + seam_side * 0.79, frame_y * 0.84 + 0.95, seam_z), satin, 0.035)
		for fastener_index in range(4):
			var bolt_y := 1.38 + fastener_index * maxf(0.62, frame_y * 0.17)
			_add_cylinder(asset, "ColumnSideBolt_%s_%s" % [side_x, fastener_index], 0.11, 0.10, Vector3(x + side_x * 1.08, bolt_y, 0.56), satin)

	# Structural rails have flanged ends and visible bolted joints under the glass.
	_add_box(asset, "RearApronRail", Vector3(size.x * 0.78, 1.32, 1.75), Vector3(0, size.y - top_thickness - 1.75, -size.z * 0.23), frame, 0.28)
	_add_box(asset, "FrontApronRail", Vector3(size.x * 0.58, 0.72, 1.2), Vector3(0, size.y - top_thickness - 1.57, size.z * 0.35), frame, 0.22)
	for rail_x in [-1.0, 1.0]:
		_add_box(asset, "CrossSupportRail_%s" % rail_x, Vector3(1.22, 1.05, size.z * 0.72), Vector3(rail_x * size.x * 0.24, size.y - top_thickness - 1.64, 0), frame, 0.26)
		for rail_z in [-1.0, 1.0]:
			_add_cylinder(asset, "RailJoinWasher_%s_%s" % [rail_x, rail_z], 0.28, 0.09, Vector3(rail_x * size.x * 0.24, size.y - top_thickness - 1.06, rail_z * size.z * 0.24), satin)
			_add_cylinder(asset, "RailJoinBolt_%s_%s" % [rail_x, rail_z], 0.14, 0.12, Vector3(rail_x * size.x * 0.24, size.y - top_thickness - 0.98, rail_z * size.z * 0.24), frame)

	# A folded cable pan with open slots, rolled hems, tie points, and cable runs.
	var tray_y := size.y - top_thickness - 4.35
	_add_box(asset, "CablePanBase", Vector3(size.x * 0.46, 0.24, size.z * 0.43), Vector3(0, tray_y, 0), frame, 0.12)
	for side in [-1.0, 1.0]:
		_add_box(asset, "CablePanSideWall_%s" % side, Vector3(size.x * 0.46, 0.76, 0.24), Vector3(0, tray_y + 0.44, side * size.z * 0.20), satin, 0.09)
		_add_box(asset, "CablePanRolledHem_%s" % side, Vector3(size.x * 0.46, 0.13, 0.30), Vector3(0, tray_y + 0.82, side * size.z * 0.20), frame, 0.065)
	for slot_index in range(12):
		var slot_x := -size.x * 0.21 + float(slot_index) * size.x * 0.42 / 11.0
		_add_box(asset, "CablePanDrainSlot_%02d" % slot_index, Vector3(0.34, 0.035, size.z * 0.29), Vector3(slot_x, tray_y + 0.14, 0), rubber, 0.1)
	for cable_index in range(5):
		var cable_x := -8.0 + cable_index * 4.0
		_add_strut(asset, "CableRunA_%d" % cable_index, Vector3(cable_x, tray_y + 0.45, -2.4), Vector3(cable_x + 0.8, tray_y + 0.65, 1.3), 0.095, dark_cable)
		_add_strut(asset, "CableRunB_%d" % cable_index, Vector3(cable_x + 0.8, tray_y + 0.65, 1.3), Vector3(cable_x + 2.1, tray_y + 0.36, 4.0), 0.075, dark_cable)

	# Small wired height controller with separated buttons and status light.
	var panel_x := size.x * 0.29
	var panel_at := Vector3(panel_x, size.y - top_thickness - 0.62, size.z * 0.46)
	_add_box(asset, "HeightControlHousing", Vector3(5.6, 0.64, 1.5), panel_at, control, 0.3)
	_add_box(asset, "ControlDisplayInset", Vector3(1.1, 0.08, 0.68), panel_at + Vector3(-1.5, 0.35, 0), satin, 0.12)
	_add_box(asset, "ControlDisplayGlass", Vector3(0.88, 0.055, 0.46), panel_at + Vector3(-1.5, 0.41, 0), _material(Color("263536"), 0.35, 0.12), 0.09)
	for button_index in range(3):
		var button_x := panel_x + 0.2 + float(button_index) * 0.9
		_add_cylinder(asset, "ControlButton_%d" % button_index, 0.24, 0.16, Vector3(button_x, panel_at.y + 0.39, panel_at.z), satin if button_index == 0 else frame)
	_add_cylinder(asset, "ControlStatusLED", 0.075, 0.06, panel_at + Vector3(2.22, 0.4, 0), led)
	_add_strut(asset, "ControllerPowerLead", panel_at + Vector3(2.65, -0.26, -0.5), Vector3(panel_x + 4.0, tray_y + 0.4, size.z * 0.16), 0.07, dark_cable)

	# Fine optical/material-scale detail: edge fasteners, feet, labels, and seams.
	for index in range(10):
		var x := -size.x * 0.43 + float(index) * size.x * 0.86 / 9.0
		for z_side in [-1.0, 1.0]:
			_add_cylinder(asset, "GlassClamp_%02d_%s" % [index, z_side], 0.13, 0.07, Vector3(x, size.y - top_thickness - 0.005, z_side * size.z * 0.40), satin)
	_add_box(asset, "DeskModelBadge", Vector3(3.1, 0.16, 0.65), Vector3(-size.x * 0.31, size.y - top_thickness - 1.2, size.z * 0.43), satin, 0.08)
	_add_box(asset, "LowerServicePanel", Vector3(10.0, 0.1, 4.4), Vector3(0, tray_y - 0.18, -size.z * 0.03), frame, 0.18)


func _pbr_surface(base: Color, seed: int, roughness: float, metallic: float, grain_mode: String) -> StandardMaterial3D:
	const TEXTURE_SIZE := 128
	var albedo := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	var roughness_map := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	var height_map := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	var normal_map := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.08
	noise.fractal_octaves = 3
	var random := RandomNumberGenerator.new()
	random.seed = seed
	for y in range(TEXTURE_SIZE):
		for x in range(TEXTURE_SIZE):
			var n := noise.get_noise_2d(float(x), float(y))
			var grain := sin(float(x) * (0.91 if grain_mode == "vertical_brush" else 0.17) + n * 5.0) * 0.018
			if grain_mode == "radial_brush":
				grain = sin(Vector2(x - 64, y - 64).length() * 0.9 + n * 3.0) * 0.025
			var fleck := random.randf_range(-0.012, 0.012)
			var value := clampf(1.0 + n * 0.07 + grain + fleck, 0.88, 1.12)
			albedo.set_pixel(x, y, Color(base.r * value, base.g * value, base.b * value))
			var rough_value := clampf(roughness + n * 0.075 + absf(grain) * 0.7, 0.035, 0.96)
			roughness_map.set_pixel(x, y, Color(rough_value, rough_value, rough_value))
			var height := clampf(0.5 + n * 0.035 + grain, 0.0, 1.0)
			height_map.set_pixel(x, y, Color(height, height, height))
	for y in range(TEXTURE_SIZE):
		for x in range(TEXTURE_SIZE):
			var left := height_map.get_pixel((x - 1 + TEXTURE_SIZE) % TEXTURE_SIZE, y).r
			var right := height_map.get_pixel((x + 1) % TEXTURE_SIZE, y).r
			var up := height_map.get_pixel(x, (y - 1 + TEXTURE_SIZE) % TEXTURE_SIZE).r
			var down := height_map.get_pixel(x, (y + 1) % TEXTURE_SIZE).r
			var nx := clampf(0.5 - (right - left) * 3.0, 0.0, 1.0)
			var ny := clampf(0.5 - (down - up) * 3.0, 0.0, 1.0)
			normal_map.set_pixel(x, y, Color(nx, ny, 1.0))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(albedo)
	material.roughness_texture = ImageTexture.create_from_image(roughness_map)
	material.normal_enabled = true
	material.normal_texture = ImageTexture.create_from_image(normal_map)
	material.normal_scale = 0.22 if grain_mode in ["vertical_brush", "radial_brush"] else 0.12
	material.roughness = roughness
	material.metallic = metallic
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * (0.22 if grain_mode == "glass" else 0.42)
	return material


func _add_strut(parent: Node3D, label: String, start: Vector3, finish: Vector3, radius: float, material: Material) -> void:
	var direction := finish - start
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = direction.length()
	mesh.radial_segments = 20
	node.mesh = mesh
	node.position = (start + finish) * 0.5
	node.quaternion = Quaternion(Vector3.UP, direction.normalized())
	node.material_override = material
	parent.add_child(node)


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
