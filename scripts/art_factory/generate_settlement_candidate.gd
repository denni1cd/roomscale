extends SceneTree
## Deterministic, recipe-driven maker for four presentation-only clockwork structures.

const G := preload("res://scripts/visuals/visual_geometry.gd")


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
	if String(recipe.get("method", "")) != "godot_procedural_clockwork_settlement":
		_fail("unsupported settlement generator method")
		return
	var refinement := String(recipe.get("parameters", {}).get("refinement", ""))
	if refinement not in ["blockout_v1", "joinery_and_materials_v2", "footprint_calibration_v3"]:
		_fail("unsupported settlement refinement: %s" % refinement)
		return
	var asset_id := String(brief.get("asset_id", ""))
	var asset := Node3D.new()
	asset.name = "Generated_%s" % asset_id
	asset.set_meta("presentation_only", true)
	match asset_id:
		"settlement_workshop": _workshop(asset, refinement)
		"settlement_depot": _depot(asset, refinement)
		"settlement_housing": _housing(asset, refinement)
		"settlement_workarea": _work_area(asset, refinement)
		_:
			asset.free()
			_fail("unknown stable settlement asset id: %s" % asset_id)
			return
	_assign_owner(asset, asset)
	root.add_child(asset)
	await process_frame
	DirAccess.make_dir_recursive_absolute(output_directory)
	var output_path := output_directory.path_join("%s.tscn" % asset_id)
	var packed := PackedScene.new()
	var error := packed.pack(asset)
	if error == OK:
		error = ResourceSaver.save(packed, output_path)
	if error != OK:
		_fail("could not save native candidate scene, Godot error=%d" % error)
		asset.free()
		return
	var mesh_count := asset.find_children("*", "MeshInstance3D", true, false).size()
	print("ROOMSCALE_ART_FACTORY_GENERATION_PASS asset=%s refinement=%s meshes=%d path=%s" % [asset_id, refinement, mesh_count, output_path])
	asset.free()
	await process_frame
	quit(0)


func _workshop(parent: Node3D, refinement: String) -> void:
	G.box(parent, "StoneAndTimberFooting", Vector3(26, 0.9, 20), Vector3(0, 0.45, 0), "stone", Color("554d42"), 0.12)
	G.box(parent, "BackFrame", Vector3(23.5, 8.1, 0.85), Vector3(0, 4.95, -8.4), "wood", Color("63452f"), 0.16)
	for x in [-11.3, 11.3]:
		G.box(parent, "SideFrame", Vector3(0.85, 8.1, 15.8), Vector3(x, 4.95, -0.4), "wood", Color("73523a"), 0.14)
		G.box(parent, "CornerIronShoe", Vector3(1.05, 1.0, 1.05), Vector3(x, 0.95, -8.2), "iron", Color("303b3e"), 0.1)
	if refinement == "blockout_v1":
		G.box(parent, "PlainWorkshopWall", Vector3(21, 7, 0.8), Vector3(0, 4.6, -7.8), "wood", Color("72543b"), 0.04)
		G.box(parent, "PlainWorkshopRoof", Vector3(22, 1.4, 18), Vector3(0, 9.2, 0), "iron", Color("405052"), 0.02)
		G.cylinder(parent, "Boiler", 2.6, 8, Vector3(-6.5, 4.8, -2), "iron", Color("465657"))
		G.cylinder(parent, "Chimney", 1.2, 10, Vector3(-6.5, 13.7, -2), "iron", Color("39474a"))
		return
	# A visible frame carries irregular plank infill, standing-seam roof panels,
	# a riveted boiler, a useful bench, and distinct pressure-system metals.
	for y in [1.4, 2.8, 4.2, 5.6, 7.0]:
		G.box(parent, "BackCladding_%02d" % int(y * 10), Vector3(21.5, 1.17, 0.18), Vector3(0, y, -7.78), "wood", Color("76583e" if int(y * 10) % 2 == 0 else "674a34"), 0.06)
	for x in [-11.15, 11.15]:
		for y in [1.5, 4.0, 6.5]:
			G.box(parent, "FrameCollar_%d_%d" % [int(x), int(y)], Vector3(1.08, 0.38, 1.06), Vector3(x, y, -8.05), "iron", Color("354448"), 0.08)
	for side in [-1, 1]:
		var roof_center: float = float(side) * 7.25
		var roof_width: float = 10.2
		var seam_count: int = 7
		var seam_spacing: float = 1.36
		if refinement == "footprint_calibration_v3":
			# Pull each wing outward to open a clear central machinery slot over
			# the existing boiler and stack rather than hiding them under the roof.
			roof_center = side * 9.5
			roof_width = 7.0
			seam_count = 5
			seam_spacing = 1.3
		G.box(parent, "RoofWing_%d" % side, Vector3(roof_width, 1.35, 19.0), Vector3(roof_center, 9.1, 0), "iron", Color("3f5050" if side == -1 else "465858"), 0.09)
		for seam in range(seam_count):
			G.box(parent, "RoofStandingSeam_%d_%d" % [side, seam], Vector3(0.11, 0.16, 18.7), Vector3(roof_center + (seam - (seam_count - 1) * 0.5) * seam_spacing, 9.77, 0), "copper", Color("936e53"), 0.025)
	for x in [-11.2, 11.2]:
		for z in [-7.0, 0.0, 7.0]:
			G.box(parent, "FrontPost_%d_%d" % [int(x), int(z)], Vector3(0.72, 8.2, 0.72), Vector3(x, 4.95, z), "wood", Color("4e392b"), 0.12)
			G.cylinder(parent, "PostBolt_%d_%d" % [int(x), int(z)], 0.12, 0.16, Vector3(x, 5.0, z + 0.39), "brass", Color("bd9559"))
	# Boiler shell and staggered copper hoops.
	G.cylinder(parent, "BoilerShell", 2.75, 7.2, Vector3(-6.5, 4.5, -2), "iron", Color("46585a"))
	for y in [1.5, 3.0, 6.0, 7.4]:
		G.cylinder(parent, "BoilerHoop_%d" % int(y * 10), 2.88, 0.28, Vector3(-6.5, y, -2), "copper", Color("a96e49"))
	G.cylinder(parent, "SmokeStack", 1.12, 11.5, Vector3(-6.5, 13.95, -2), "iron", Color("344246"))
	G.cylinder(parent, "StackCap", 1.38, 0.44, Vector3(-6.5, 19.72, -2), "copper", Color("936746"))
	_pipe(parent, "PressureFeed", Vector3(-4.0, 6.4, -2), Vector3(-1.3, 6.4, -2), 0.22, "copper", Color("a36c4c"))
	_pipe(parent, "UpperSteam", Vector3(-4.3, 8.1, -2), Vector3(-4.3, 10.3, -2), 0.18, "copper", Color("b07854"))
	G.cylinder(parent, "GaugeBezel", 0.72, 0.3, Vector3(-3.5, 7.8, 0.15), "brass", Color("c19b58"))
	G.cylinder(parent, "GaugeFace", 0.57, 0.12, Vector3(-3.5, 7.8, 0.34), "paint", Color("ded4b5"))
	if refinement in ["joinery_and_materials_v2", "footprint_calibration_v3"]:
		G.box(parent, "WorkbenchTop", Vector3(10.5, 0.7, 4.0), Vector3(4.4, 3.9, -2.0), "wood", Color("906b48"), 0.16)
		for x in [0.5, 8.3]:
			G.box(parent, "WorkbenchTrestle", Vector3(0.8, 3.3, 3.0), Vector3(x, 2.25, -2.0), "wood", Color("533b2b"), 0.14)
		G.gear(parent, "ExposedFlywheel", 1.55, Vector3(4.2, 5.0, 0.6)).rotation.x = PI * 0.5
		_pipe(parent, "CopperReturn", Vector3(2.7, 4.8, -4.0), Vector3(2.7, 6.8, -4.0), 0.17, "copper", Color("ad714e"))
		for x in [1.5, 3.0, 4.5, 6.0, 7.5]:
			G.box(parent, "BenchTool", Vector3(0.24, 0.6 + fposmod(x, 2.0) * 0.2, 0.2), Vector3(x, 4.55, -1.8), "iron", Color("87918b"), 0.04)
		G.box(parent, "DoorPanel", Vector3(4.2, 6.4, 0.34), Vector3(0, 3.8, 8.4), "wood", Color("523d2d"), 0.08)
		for x in [-1.7, 1.7]:
			G.box(parent, "DoorStrap_%d" % int(x), Vector3(0.2, 5.4, 0.18), Vector3(x, 3.8, 8.64), "iron", Color("303b3e"), 0.03)
			for y in [1.8, 5.6]:
				G.cylinder(parent, "DoorRivet_%d_%d" % [int(x), int(y)], 0.1, 0.1, Vector3(x, y, 8.77), "brass", Color("c0995d"))
		G.box(parent, "IlluminatedSash", Vector3(3.1, 2.2, 0.12), Vector3(8.4, 4.8, 8.9), "lamp", Color("c99456"), 0.06)
		for y in [3.7, 4.8, 5.9]:
			G.box(parent, "WindowMullion_%d" % int(y * 10), Vector3(3.3, 0.12, 0.16), Vector3(8.4, y, 9.0), "iron", Color("25373b"), 0.02)


func _depot(parent: Node3D, refinement: String) -> void:
	G.box(parent, "RaisedStonePlinth", Vector3(24, 0.8, 20), Vector3(0, 0.4, 0), "stone", Color("514a40"), 0.12)
	for x in [-10.8, 10.8]:
		G.box(parent, "TimberColumn_%d" % int(x), Vector3(1.0, 7.2, 1.0), Vector3(x, 4.4, 6.3), "wood", Color("62452f"), 0.12)
	G.box(parent, "RearBoardWall", Vector3(21.5, 6.5, 0.8), Vector3(0, 4.05, -8.2), "wood", Color("80603f"), 0.12)
	if refinement == "blockout_v1":
		G.box(parent, "PlainDepotCanopy", Vector3(23, 1.4, 20), Vector3(0, 8.0, 0), "wood", Color("9a744b"), 0.02)
		return
	for y in [1.5, 2.7, 3.9, 5.1, 6.3]:
		G.box(parent, "RearPlank_%d" % int(y * 10), Vector3(20.7, 0.9, 0.16), Vector3(0, y, -7.76), "wood", Color("8a6845" if int(y * 10) % 2 == 0 else "73563b"), 0.05)
	for side in [-1, 1]:
		var roof := G.box(parent, "CopperAwning_%d" % side, Vector3(12.4, 0.62, 20), Vector3(side * 5.4, 9.2, -0.15), "copper", Color("68766d"), 0.08)
		roof.rotation.z = deg_to_rad(-8.0 * side)
		for seam in range(7):
			G.box(parent, "AwningSeam_%d_%d" % [side, seam], Vector3(0.12, 0.12, 19.3), Vector3(side * 5.4 + (seam - 3) * 1.65, 9.58, -0.15), "iron", Color("36484a"), 0.02)
		G.box(parent, "CornerBrace_%d" % side, Vector3(0.42, 4.6, 0.42), Vector3(side * 10.2, 4.0, 7.0), "iron", Color("354347"), 0.06).rotation.x = -0.44
	for crate_index in range(4):
		var x := -7.0 + float(crate_index % 3) * 6.0
		var z := -2.5 + float(crate_index / 3) * 4.0
		G.box(parent, "TimberCrate_%d" % crate_index, Vector3(4.0, 3.4, 3.4), Vector3(x, 2.5, z), "wood", Color("936d48"), 0.12)
		for y in [1.2, 3.75]:
			G.box(parent, "CrateIronBand_%d_%d" % [crate_index, int(y * 10)], Vector3(4.15, 0.22, 3.58), Vector3(x, y, z), "iron", Color("354245"), 0.035)
		for x_offset in [-1.45, 1.45]:
			G.cylinder(parent, "BandRivet_%d_%d" % [crate_index, int(x_offset)], 0.11, 0.12, Vector3(x + x_offset, 2.4, z + 1.78), "brass", Color("b79157"))
	G.cylinder(parent, "PartsBarrel", 1.25, 4.8, Vector3(8.0, 2.8, 2.7), "wood", Color("77573d"))
	for y in [0.9, 3.0, 4.6]:
		G.cylinder(parent, "BarrelHoop_%d" % int(y * 10), 1.34, 0.22, Vector3(8.0, y, 2.7), "iron", Color("39474a"))
	_pipe(parent, "OverheadLoadingRail", Vector3(-8.0, 7.5, -4.0), Vector3(8.0, 7.5, -4.0), 0.2, "iron", Color("38474a"))
	G.gear(parent, "PulleyWheel", 0.75, Vector3(5.8, 6.8, -4.0)).rotation.x = PI * 0.5
	_pipe(parent, "HoistChain", Vector3(5.8, 6.4, -4.0), Vector3(5.8, 3.7, -4.0), 0.075, "iron", Color("606665"))
	G.box(parent, "CounterWindow", Vector3(3.8, 2.8, 0.15), Vector3(-7.3, 4.6, 8.9), "lamp", Color("b48d59"), 0.06)
	for x in [-8.4, -6.2]:
		G.box(parent, "WindowJamb_%d" % int(x), Vector3(0.18, 3.2, 0.2), Vector3(x, 4.6, 9.0), "iron", Color("354347"), 0.025)
	G.cylinder(parent, "CopperRoofVent", 0.56, 2.6, Vector3(0, 11.7, -8.15), "copper", Color("a16f4e"))
	G.cylinder(parent, "VentRainCap", 0.84, 0.24, Vector3(0, 12.96, -8.15), "iron", Color("39484b"))


func _housing(parent: Node3D, refinement: String) -> void:
	G.box(parent, "SharedDeck", Vector3(17, 0.6, 9), Vector3(0, 0.3, 0), "wood", Color("634831"), 0.12)
	for index in range(2):
		var x := -4.2 + float(index) * 8.4
		G.box(parent, "HomeWallBack_%d" % index, Vector3(7.0, 3.4, 0.45), Vector3(x, 2.25, -3.0), "wood", Color("79583c"), 0.12)
		for side in [-1, 1]:
			G.box(parent, "HomeSide_%d_%d" % [index, side], Vector3(0.45, 3.3, 6.4), Vector3(x + side * 3.3, 2.25, 0), "wood", Color("88623f"), 0.12)
		G.box(parent, "RidgeBeam_%d" % index, Vector3(0.42, 0.55, 8.3), Vector3(x, 6.48, 0), "wood", Color("4d392b"), 0.08)
		for side in [-1, 1]:
			var roof := G.box(parent, "StandingSeamRoof_%d_%d" % [index, side], Vector3(4.3, 0.34, 8.8), Vector3(x + side * 2.0, 5.05, 0), "iron", Color("445756" if index == 0 else "51605c"), 0.06)
			roof.rotation.z = deg_to_rad(-24.0 * side)
		if refinement == "joinery_and_materials_v2":
			for plank in range(6):
				G.box(parent, "FrontCladding_%d_%d" % [index, plank], Vector3(6.5, 0.42, 0.15), Vector3(x, 0.95 + float(plank) * 0.49, 3.05), "wood", Color("856243" if plank % 2 == 0 else "725238"), 0.045)
			G.box(parent, "EntryDoor_%d" % index, Vector3(1.35, 2.5, 0.16), Vector3(x, 1.8, 3.25), "wood", Color("3f3429"), 0.06)
			for side in [-1, 1]:
				G.box(parent, "WindowFrame_%d_%d" % [index, side], Vector3(1.28, 1.4, 0.22), Vector3(x + side * 2.25, 2.45, 3.22), "iron", Color("303d3f"), 0.035)
				G.box(parent, "WarmWindow_%d_%d" % [index, side], Vector3(1.02, 1.12, 0.08), Vector3(x + side * 2.25, 2.45, 3.36), "lamp", Color("bd9256"), 0.02)
			for side in [-1, 1]:
				for seam in range(5):
					_pipe(parent, "RoofRib_%d_%d_%d" % [index, side, seam], Vector3(x + side * 0.35, 6.0, -3.7 + seam * 1.8), Vector3(x + side * 3.72, 4.5, -3.7 + seam * 1.8), 0.045, "copper", Color("a37a56"))
	for x in [-7.7, 7.7]:
		G.box(parent, "PorchPost_%d" % int(x), Vector3(0.28, 2.8, 0.28), Vector3(x, 1.7, 4.0), "wood", Color("4e392b"), 0.06)
	G.cylinder(parent, "SharedFlue", 0.32, 1.6, Vector3(6.7, 6.2, -2.0), "copper", Color("936548"))
	G.cylinder(parent, "FlueCap", 0.5, 0.18, Vector3(6.7, 7.0, -2.0), "iron", Color("303e40"))
	G.box(parent, "PorchLanding", Vector3(17, 0.24, 1.6), Vector3(0, 0.75, 4.55), "wood", Color("715238"), 0.07)
	if refinement in ["joinery_and_materials_v2", "footprint_calibration_v3"]:
		for x in [-4.2, 4.2]:
			G.box(parent, "DoorLintel_%d" % int(x), Vector3(2.0, 0.2, 0.22), Vector3(x, 3.2, 3.38), "iron", Color("39474a"), 0.04)
			for side in [-1, 1]:
				G.cylinder(parent, "DoorHinge_%d_%d" % [int(x), side], 0.11, 0.44, Vector3(x + side * 0.48, 1.85, 3.4), "brass", Color("b79158"))


func _work_area(parent: Node3D, refinement: String) -> void:
	G.box(parent, "PavedWorkyard", Vector3(23, 0.45, 12), Vector3(0, 0.225, 0), "stone", Color("5d5141"), 0.08)
	for plank in range(16):
		G.box(parent, "PavingBlock_%02d" % plank, Vector3(1.35, 0.1, 0.72), Vector3(-10.1 + float(plank % 8) * 2.9, 0.52, -3.6 + float(plank / 8) * 7.2), "stone", Color("776957" if plank % 2 == 0 else "6b5f50"), 0.08)
	G.box(parent, "AssemblyBenchTop", Vector3(14.0, 0.72, 4.5), Vector3(0.0, 4.05, 0.0), "wood", Color("936a45"), 0.12)
	for x in [-5.5, 5.5]:
		G.box(parent, "BenchTrestle_%d" % int(x), Vector3(0.85, 3.35, 3.8), Vector3(x, 2.05, 0), "wood", Color("523b2b"), 0.12)
		G.box(parent, "IronShoe_%d" % int(x), Vector3(1.15, 0.32, 4.0), Vector3(x, 0.48, 0), "iron", Color("37464a"), 0.06)
	G.gear(parent, "SpareGear", 1.5, Vector3(-3.6, 4.72, -0.5)).rotation.x = PI * 0.5
	G.cylinder(parent, "PartsTin", 1.25, 2.6, Vector3(4.4, 5.5, -0.1), "iron", Color("53615e"))
	_pipe(parent, "ToolRail", Vector3(-8, 7.1, -4.4), Vector3(8, 7.1, -4.4), 0.18, "iron", Color("344245"))
	G.box(parent, "RearToolRack", Vector3(16, 0.6, 0.5), Vector3(0, 6.4, -4.4), "wood", Color("644a34"), 0.08)
	G.box(parent, "HoistLegLeft", Vector3(0.48, 8.5, 0.48), Vector3(-10.15, 4.25, -5.1), "wood", Color("4e392b"), 0.08)
	G.box(parent, "HoistLegRight", Vector3(0.48, 8.5, 0.48), Vector3(10.15, 4.25, -5.1), "wood", Color("4e392b"), 0.08)
	G.box(parent, "HoistHeader", Vector3(20.8, 0.38, 0.5), Vector3(0, 8.81, -5.1), "iron", Color("354448"), 0.06)
	G.gear(parent, "HeaderPulley", 0.62, Vector3(0, 8.1, -4.72)).rotation.x = PI * 0.5
	if refinement in ["joinery_and_materials_v2", "footprint_calibration_v3"]:
		for index in range(7):
			var x := -6.5 + float(index) * 2.15
			var height := 0.5 + float(index % 3) * 0.24
			G.box(parent, "HangingTool_%d" % index, Vector3(0.18, height, 0.16), Vector3(x, 6.0, -4.0), "iron", Color("86908a"), 0.035)
			G.cylinder(parent, "ToolPeg_%d" % index, 0.09, 0.3, Vector3(x, 6.43, -3.72), "brass", Color("b38b52"))
		G.box(parent, "SideStorageShelf", Vector3(3.8, 0.35, 5.5), Vector3(8.2, 2.6, -1.4), "wood", Color("694b33"), 0.09)
		for index in range(5):
			G.box(parent, "PartsBin_%d" % index, Vector3(0.66, 1.3, 0.85), Vector3(6.8 + float(index % 3) * 1.1, 3.45, -2.9 + float(index / 3) * 2.6), "wood", Color("967149" if index % 2 == 0 else "76563a"), 0.07)
		G.cylinder(parent, "LatheSpindle", 0.4, 2.2, Vector3(3.1, 5.1, -1.15), "brass", Color("bb9252"))
		G.gear(parent, "DriveWheel", 0.85, Vector3(3.1, 5.1, 0.0)).rotation.x = PI * 0.5


func _pipe(parent: Node3D, label: String, start: Vector3, finish: Vector3, radius: float, category: String, color: Color) -> void:
	var direction := finish - start
	var segment := G.cylinder(parent, label, radius, direction.length(), (start + finish) * 0.5, category, color)
	segment.quaternion = Quaternion(Vector3.UP, direction.normalized())


func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_assign_owner(child, owner)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + message)
	quit(1)
