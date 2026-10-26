extends SceneTree
## Deterministic room-furniture maker for the RoomScale Art Factory.

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
	if String(recipe.get("method", "")) != "godot_procedural_room_furniture":
		_fail("unsupported room furniture generator method")
		return
	var refinement := String(recipe.get("parameters", {}).get("refinement", ""))
	if refinement not in ["blockout_v1", "joinery_and_fabric_v2", "visibility_and_material_v3", "floor_contact_joinery_v3", "double_sided_canvas_v4"]:
		_fail("unsupported room furniture refinement: %s" % refinement)
		return
	var asset_id := String(brief.get("asset_id", ""))
	var asset := Node3D.new()
	asset.name = "Generated_%s" % asset_id
	asset.set_meta("presentation_only", true)
	match asset_id:
		"office_chair": _office_chair(asset, refinement)
		"rocking_chair": _rocking_chair(asset, refinement)
		"hammock_with_stand": _hammock(asset, refinement)
		"display_cabinet": _display_cabinet(asset, refinement)
		_:
			asset.free()
			_fail("unknown stable room furniture asset id: %s" % asset_id)
			return
	_assign_owner(asset, asset)
	root.add_child(asset)
	await process_frame
	var mesh_count := asset.find_children("*", "MeshInstance3D", true, false).size()
	if asset_id == "hammock_with_stand":
		var minimum_meshes := 16 if refinement == "joinery_and_fabric_v2" else 12
		if mesh_count < minimum_meshes:
			_fail("hammock generator produced %d meshes; expected at least %d including its woven sling" % [mesh_count, minimum_meshes])
			asset.free()
			return
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
	print("ROOMSCALE_ART_FACTORY_GENERATION_PASS asset=%s refinement=%s meshes=%d path=%s" % [asset_id, refinement, mesh_count, output_path])
	asset.free()
	await process_frame
	quit(0)


func _office_chair(parent: Node3D, refinement: String) -> void:
	var frame := Color("253643")
	var upholstery := Color("131d23")
	var accent := Color("365474")
	if refinement == "visibility_and_material_v3":
		# The first production capture showed a readable chair silhouette but
		# almost no separation between the shell and padded surfaces. Lift the
		# values and give the fabric panels a visible slate-blue contrast.
		frame = Color("34444c")
		upholstery = Color("263641")
		accent = Color("718f9e")
	G.cylinder(parent, "GasLiftColumn", 0.82, 13.0, Vector3(0, 9.0, 1.0), "iron", frame)
	G.cylinder(parent, "ColumnSleeve", 1.05, 4.0, Vector3(0, 4.0, 1.0), "metal", Color("7b8584"))
	G.box(parent, "SeatPan", Vector3(20.2, 2.6, 14.2), Vector3(0, 20.0, 1.5), "iron", Color("222d32"), 0.85)
	G.box(parent, "SeatCushion", Vector3(19.6, 3.0, 14.0), Vector3(0, 22.4, 1.4), "leather", upholstery, 1.2)
	var back := G.box(parent, "BackShell", Vector3(18.4, 18.2, 2.2), Vector3(0, 32.1, -5.4), "iron", frame, 0.9)
	back.rotation.x = deg_to_rad(-7.0)
	var pad := G.box(parent, "BackCushion", Vector3(16.7, 15.8, 1.45), Vector3(0, 32.2, -6.55), "fabric", upholstery, 1.1)
	pad.rotation.x = deg_to_rad(-7.0)
	for side in [-1, 1]:
		G.box(parent, "BackRail_%d" % side, Vector3(0.85, 15.3, 0.9), Vector3(side * 7.5, 30.5, -4.3), "iron", frame, 0.28)
		G.box(parent, "ArmSupport_%d" % side, Vector3(0.85, 5.1, 0.85), Vector3(side * 8.1, 25.1, -0.4), "iron", frame, 0.26)
		G.box(parent, "ArmPad_%d" % side, Vector3(2.8, 1.15, 7.7), Vector3(side * 8.1, 27.6, 0.3), "leather", upholstery, 0.52)
	if refinement in ["joinery_and_fabric_v2", "visibility_and_material_v3"]:
		for x in [-5.0, 0.0, 5.0]:
			var channel := G.box(parent, "BackQuiltChannel_%d" % int(x), Vector3(0.13, 12.6, 0.08), Vector3(x, 32.4, -7.28), "leather", accent.darkened(0.2), 0.04)
			channel.rotation.x = deg_to_rad(-7.0)
		for y in [27.2, 36.5]:
			for x in [-6.8, 6.8]:
				G.cylinder(parent, "BackFastener_%d_%d" % [int(y), int(x)], 0.16, 0.08, Vector3(x, y, -7.35), "metal", Color("95a0a0"))
		for x in [-7.0, 0.0, 7.0]:
			G.box(parent, "SeatStitch_%d" % int(x), Vector3(0.08, 0.08, 10.0), Vector3(x, 23.97, 1.2), "fabric", accent, 0.025)
		G.box(parent, "TiltControl", Vector3(3.2, 0.7, 2.4), Vector3(0.0, 18.2, -2.3), "metal", Color("718080"), 0.22)
	if refinement == "visibility_and_material_v3":
		# Split the back into padded panels and add restrained piping. These
		# surfaces sit within the original shell, so the brief envelope is intact.
		for panel in range(3):
			var panel_x := -5.5 + float(panel) * 5.5
			var panel_color := Color("314957") if panel == 1 else Color("293b45")
			var panel_mesh := G.box(parent, "BackFabricPanel_%02d" % panel, Vector3(4.9, 13.8, 0.28), Vector3(panel_x, 32.2, -7.32), "citizen_fabric", panel_color, 0.18)
			panel_mesh.rotation.x = deg_to_rad(-7.0)
		for side in [-1, 1]:
			var piping := G.box(parent, "BackAccentPiping_%d" % side, Vector3(0.16, 13.6, 0.18), Vector3(side * 8.15, 32.2, -7.38), "leather", accent, 0.07)
			piping.rotation.x = deg_to_rad(-7.0)
			G.box(parent, "SeatFabricPanel_%d" % side, Vector3(5.1, 0.14, 12.2), Vector3(side * 5.75, 23.98, 1.4), "citizen_fabric", Color("2d424d"), 0.12)
		G.box(parent, "SeatFabricPanel_Center", Vector3(5.1, 0.14, 12.2), Vector3(0.0, 23.98, 1.4), "citizen_fabric", Color("344c58"), 0.12)
		G.box(parent, "LumbarSeam", Vector3(14.8, 0.16, 0.2), Vector3(0.0, 28.2, -7.39), "leather", Color("526d7a"), 0.07)
	for spoke in range(5):
		var angle := TAU * float(spoke) / 5.0
		var end := Vector3(cos(angle) * 5.0, 1.65, 1.0 + sin(angle) * 5.0)
		var foot := G.box(parent, "FiveStarBase_%02d" % spoke, Vector3(5.8, 0.75, 1.0), Vector3(cos(angle) * 2.7, 1.65, 1.0 + sin(angle) * 2.7), "iron", frame, 0.28)
		foot.rotation.y = -angle
		G.cylinder(parent, "CasterHousing_%02d" % spoke, 0.65, 1.1, end, "iron", Color("20282b"))
		var wheel := G.cylinder(parent, "CasterWheel_%02d" % spoke, 0.68, 0.62, end + Vector3(0.0, -0.85, 0.0), "rubber", Color("171c1e"))
		wheel.rotation.x = PI * 0.5


func _rocking_chair(parent: Node3D, refinement: String) -> void:
	var wood := Color("493021")
	var dark := Color("33241d")
	G.box(parent, "SeatRail", Vector3(20.5, 2.1, 18.8), Vector3(0, 17.0, 0.0), "wood", dark, 0.48)
	G.box(parent, "SeatSlatOne", Vector3(18.4, 0.7, 8.0), Vector3(0, 18.15, -4.7), "wood", wood, 0.26)
	G.box(parent, "SeatSlatTwo", Vector3(18.4, 0.7, 8.0), Vector3(0, 18.15, 4.5), "wood", wood.darkened(0.12), 0.26)
	for side in [-1, 1]:
		G.box(parent, "BackPost_%d" % side, Vector3(1.15, 19.0, 1.25), Vector3(side * 8.3, 27.8, -7.8), "wood", dark, 0.34)
		G.box(parent, "ArmSupport_%d" % side, Vector3(1.2, 8.7, 1.25), Vector3(side * 9.0, 22.4, -0.5), "wood", dark, 0.3)
		G.box(parent, "ArmCap_%d" % side, Vector3(2.8, 1.2, 15.2), Vector3(side * 8.8, 26.8, -0.4), "wood", wood, 0.46)
		var rocker_start := -13.8
		var rocker_step := 1.15
		for index in range(24):
			var z := rocker_start + float(index) * rocker_step
			var rocker_base_y := 0.49 if refinement == "floor_contact_joinery_v3" else 1.0
			var y := rocker_base_y + 2.4 * (1.0 - pow(z / 14.2, 2.0))
			var point_a := Vector3(side * 8.6, y, z)
			var next_z := z + rocker_step
			var point_b := Vector3(side * 8.6, rocker_base_y + 2.4 * (1.0 - pow(next_z / 14.2, 2.0)), next_z)
			_pipe(parent, "CurvedRocker_%d_%02d" % [side, index], point_a, point_b, 0.62, "wood", wood if index % 2 == 0 else dark)
		for pin in [-1, 1]:
			G.cylinder(parent, "RockerBolt_%d_%d" % [side, pin], 0.18, 0.12, Vector3(side * 9.25, 2.9, pin * 10.4), "brass", Color("b38c54")).rotation.x = PI * 0.5
	if refinement == "blockout_v1":
		G.box(parent, "PlainBack", Vector3(17.0, 17.0, 2.3), Vector3(0, 28.0, -8.4), "wood", wood, 0.3)
	else:
		for slat in range(7):
			var x := -6.4 + float(slat) * 2.13
			G.box(parent, "BackSlat_%02d" % slat, Vector3(1.55, 16.6, 0.95), Vector3(x, 28.1, -8.5), "wood", wood if slat % 2 == 0 else dark, 0.48)
		G.box(parent, "CrestRail", Vector3(18.2, 1.2, 1.35), Vector3(0, 36.6, -8.45), "wood", dark, 0.46)
		for x in [-8.4, 8.4]:
			G.cylinder(parent, "ArmTenon_%d" % int(x), 0.28, 0.22, Vector3(x, 27.2, -0.4), "brass", Color("b38c54"))


func _hammock(parent: Node3D, refinement: String) -> void:
	var frame := Color("374447")
	for side in [-1, 1]:
		var x := float(side) * 52.0
		for depth_side in [-1, 1]:
			_pipe(parent, "AFrameLeg_%d_%d" % [side, depth_side], Vector3(x + side * 5.0, 0.8, depth_side * 13.5), Vector3(x - side * 2.0, 36.5, depth_side * 6.0), 0.82, "iron", frame)
		_pipe(parent, "EndBrace_%d" % side, Vector3(x - side * 3.2, 2.2, -13.4), Vector3(x - side * 3.2, 2.2, 13.4), 0.78, "iron", frame)
		_pipe(parent, "SlingRod_%d" % side, Vector3(x - side * 7.0, 29.5, -12.0), Vector3(x - side * 7.0, 29.5, 12.0), 0.5, "iron", Color("566463"))
	_pipe(parent, "TopTensionCable", Vector3(-52.0, 35.5, 0.0), Vector3(52.0, 35.5, 0.0), 0.2, "iron", Color("4c595a"))
	var stripe_colors: Array[Color] = [Color("c7c6ba"), Color("727a73"), Color("dedbd0"), Color("4d5b58"), Color("c7c6ba"), Color("727a73"), Color("dedbd0")]
	var stripe_count := 7 if refinement in ["joinery_and_fabric_v2", "double_sided_canvas_v4"] else 3
	_add_hammock_canvas(parent, stripe_colors, stripe_count)
	for side in [-1, 1]:
		for cord in [-1, 1]:
			_pipe(parent, "HammockEndCord_%d_%d" % [side, cord], Vector3(side * 45.0, 27.5, cord * 10.0), Vector3(side * 45.0, 28.8, cord * 12.0), 0.1, "rope", Color("88775f"))
		G.cylinder(parent, "SuspensionRing_%d" % side, 0.72, 0.28, Vector3(side * 45.0, 29.0, 0.0), "iron", Color("84908b")).rotation.x = PI * 0.5
	if refinement == "joinery_and_fabric_v2":
		for side in [-1, 1]:
			for z in [-12.0, 12.0]:
				G.cylinder(parent, "SlingEyelet_%d_%d" % [side, int(z)], 0.18, 0.14, Vector3(side * 44.0, 27.6, z), "brass", Color("ac8a55")).rotation.x = PI * 0.5


func _add_hammock_canvas(parent: Node3D, colors: Array[Color], count: int) -> void:
	var total_width := 25.0
	var start_z := -total_width * 0.5
	var stripe_width := total_width / float(count)
	for stripe in range(count):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var z0 := start_z + float(stripe) * stripe_width
		var z1 := z0 + stripe_width
		var longitudinal_segments := 24
		for segment in range(longitudinal_segments):
			var x0 := -45.0 + 90.0 * float(segment) / float(longitudinal_segments)
			var x1 := -45.0 + 90.0 * float(segment + 1) / float(longitudinal_segments)
			var y0 := 19.0 + 8.5 * pow(x0 / 45.0, 2.0)
			var y1 := 19.0 + 8.5 * pow(x1 / 45.0, 2.0)
			var a := Vector3(x0, y0, z0)
			var b := Vector3(x1, y1, z0)
			var c := Vector3(x1, y1, z1)
			var d := Vector3(x0, y0, z1)
			# The first capture showed an empty frame: this surface winding faced
			# the floor and Godot's default back-face culling removed the sling.
			for pair in [[a, Vector2(0.0, float(stripe) / float(count))], [c, Vector2(1.0, float(stripe + 1) / float(count))], [b, Vector2(1.0, float(stripe) / float(count))], [a, Vector2(0.0, float(stripe) / float(count))], [d, Vector2(0.0, float(stripe + 1) / float(count))], [c, Vector2(1.0, float(stripe + 1) / float(count))]]:
				surface.set_uv(pair[1])
				surface.add_vertex(pair[0])
		surface.generate_normals()
		var mesh := surface.commit()
		var instance := MeshInstance3D.new()
		instance.name = "WovenHammockStripe_%02d" % stripe
		instance.mesh = mesh
		var sling_material := Materials.get_material("fabric", colors[stripe % colors.size()]).duplicate() as StandardMaterial3D
		sling_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		instance.material_override = sling_material
		parent.add_child(instance)


func _display_cabinet(parent: Node3D, refinement: String) -> void:
	var wood := Color("ad733c")
	var dark := Color("704827")
	var iron := Color("4b5045")
	G.box(parent, "RaisedPlinth", Vector3(33.0, 5.5, 18.0), Vector3(0, 2.75, 0), "wood", dark, 0.52)
	G.box(parent, "CabinetBack", Vector3(31.5, 67.0, 1.2), Vector3(0, 40.5, -7.8), "wood", dark, 0.32)
	for side in [-1, 1]:
		G.box(parent, "SidePanel_%d" % side, Vector3(1.5, 68.0, 16.5), Vector3(side * 15.6, 40.0, 0), "wood", wood, 0.42)
		G.box(parent, "FrontStile_%d" % side, Vector3(2.0, 68.0, 1.8), Vector3(side * 14.9, 40.0, 8.0), "wood", dark, 0.35)
	G.box(parent, "CabinetTop", Vector3(33.0, 4.5, 18.0), Vector3(0, 73.7, 0), "wood", dark, 0.5)
	for shelf_index in range(3):
		var y := 20.0 + float(shelf_index) * 17.2
		G.box(parent, "DisplayShelf_%02d" % shelf_index, Vector3(29.0, 1.2, 15.2), Vector3(0, y, 0), "wood", wood if shelf_index % 2 == 0 else dark, 0.25)
	if refinement == "blockout_v1":
		G.box(parent, "PlainGlassDoor", Vector3(28.0, 61.0, 0.35), Vector3(0, 39.5, 8.9), "glass", Color("8faaa9"), 0.1)
	else:
		for side in [-1, 1]:
			var glass := G.box(parent, "GlassDoor_%d" % side, Vector3(13.1, 58.0, 0.18), Vector3(side * 6.7, 39.6, 8.98), "glass", Color("afc4c0"), 0.08)
			var glass_material := glass.material_override as StandardMaterial3D
			glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glass_material.albedo_color.a = 0.3
			glass_material.metallic = 0.08
			for y in [12.0, 38.0, 65.0]:
				G.box(parent, "DoorRail_%d_%d" % [side, int(y)], Vector3(13.4, 0.7, 0.5), Vector3(side * 6.7, y, 9.15), "wood", wood, 0.12)
			for x_offset in [-12.0, 12.0]:
				G.box(parent, "DoorMullion_%d_%d" % [side, int(x_offset)], Vector3(0.55, 58.0, 0.45), Vector3(side * 6.7 + x_offset * 0.3, 39.5, 9.15), "wood", dark, 0.1)
			G.cylinder(parent, "CabinetHandle_%d" % side, 0.34, 2.2, Vector3(side * 1.2, 39.0, 9.35), "brass", Color("c29858")).rotation.x = PI * 0.5
			for y in [10.0, 68.0]:
				G.cylinder(parent, "CabinetHinge_%d_%d" % [side, int(y)], 0.24, 0.45, Vector3(side * 13.0, y, 9.05), "iron", iron).rotation.x = PI * 0.5
		for x in [-13.8, 13.8]:
			G.box(parent, "CornerInlay_%d" % int(x), Vector3(0.45, 57.0, 0.15), Vector3(x, 39.5, 9.2), "brass", Color("a88755"), 0.06)
		G.box(parent, "UpperCrownMolding", Vector3(34.0, 1.0, 19.0), Vector3(0, 70.8, 0), "wood", wood, 0.28)
		G.box(parent, "BaseMolding", Vector3(33.5, 0.9, 18.5), Vector3(0, 6.0, 0), "wood", wood, 0.24)


func _pipe(parent: Node3D, label: String, start: Vector3, finish: Vector3, radius: float, category: String, color: Color) -> MeshInstance3D:
	var direction := finish - start
	var segment := G.cylinder(parent, label, radius, direction.length(), (start + finish) * 0.5, category, color)
	segment.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return segment


func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_assign_owner(child, owner)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + message)
	quit(1)
