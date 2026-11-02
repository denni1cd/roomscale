extends SceneTree
## Deterministic room-furniture maker for the RoomScale Art Factory.

const G := preload("res://scripts/visuals/visual_geometry.gd")
const Materials := preload("res://scripts/visuals/material_library.gd")
const ROOM_WOODGRAIN_V3 := preload("res://scripts/art_factory/roomscale_woodgrain_v3.gdshader")
const ROOM_CHAIR_WOODFINISH_V4 := preload("res://scripts/art_factory/room_chair_woodfinish_v4.gdshader")
const ROOM_FURNITURE_WOODFINISH_V5 := preload("res://scripts/art_factory/room_furniture_woodfinish_v5.gdshader")


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
	if refinement not in ["blockout_v1", "joinery_and_fabric_v2", "visibility_and_material_v3", "floor_contact_joinery_v3", "double_sided_canvas_v4", "roomscale_joinery_v1", "roomscale_joinery_v2_material_correction", "roomscale_directional_woodgrain_v3", "mesh_authored_joinery_v4", "mesh_authored_leaf_joinery_v5", "mesh_authored_furniture_v5", "mesh_authored_furniture_warm_finish_v6"]:
		_fail("unsupported room furniture refinement: %s" % refinement)
		return
	var asset_id := String(brief.get("asset_id", ""))
	var asset := Node3D.new()
	asset.name = "Generated_%s" % asset_id
	asset.set_meta("presentation_only", true)
	match asset_id:
		"room_elevated_workbench": _elevated_workbench(asset, refinement)
		"room_assembly_table": _assembly_table(asset, refinement)
		"room_tool_wardrobe": _tool_wardrobe(asset, refinement)
		"room_floor_cabinet": _floor_cabinet(asset, refinement)
		"room_chair":
			if refinement in ["mesh_authored_joinery_v4", "mesh_authored_leaf_joinery_v5"]:
				_low_room_chair_mesh_authored(asset)
			else:
				_low_room_chair(asset)
		"room_side_table": _side_table(asset, refinement)
		"office_chair": _office_chair(asset, refinement)
		"rocking_chair": _rocking_chair(asset, refinement)
		"hammock_with_stand": _hammock(asset, refinement)
		"display_cabinet": _display_cabinet(asset, refinement)
		_:
			asset.free()
			_fail("unknown stable room furniture asset id: %s" % asset_id)
			return
	if asset_id in ["room_elevated_workbench", "room_assembly_table", "room_tool_wardrobe", "room_floor_cabinet", "room_chair", "room_side_table"] and refinement == "roomscale_joinery_v2_material_correction":
		_apply_roomscale_wood_correction(asset)
	if asset_id in ["room_elevated_workbench", "room_assembly_table", "room_tool_wardrobe", "room_floor_cabinet", "room_chair", "room_side_table"] and refinement in ["roomscale_directional_woodgrain_v3", "mesh_authored_joinery_v4", "mesh_authored_leaf_joinery_v5", "mesh_authored_furniture_v5", "mesh_authored_furniture_warm_finish_v6"]:
		_apply_roomscale_directional_woodgrain(
			asset,
			0.96 if refinement == "mesh_authored_furniture_warm_finish_v6" else (0.86 if refinement == "mesh_authored_leaf_joinery_v5" else (0.78 if refinement == "mesh_authored_joinery_v4" else 0.68)),
			refinement == "mesh_authored_leaf_joinery_v5",
			refinement == "mesh_authored_furniture_warm_finish_v6"
		)
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


func _apply_roomscale_wood_correction(parent: Node3D) -> void:
	# Round 01 production captures were substantially paler than the reviewed
	# warm-oak target. Darken only non-metal material instances, preserving the
	# separately authored brass and iron response.
	var corrected_by_color: Dictionary = {}
	for mesh_variant in parent.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_variant as MeshInstance3D
		var material := mesh_instance.material_override as StandardMaterial3D
		if material == null or material.metallic > 0.05:
			continue
		var key := material.albedo_color.to_html()
		if not corrected_by_color.has(key):
			var corrected := material.duplicate(true) as StandardMaterial3D
			corrected.albedo_color = corrected.albedo_color.darkened(0.30)
			corrected_by_color[key] = corrected
		mesh_instance.material_override = corrected_by_color[key]


func _apply_roomscale_directional_woodgrain(parent: Node3D, tone_scale: float = 0.68, chair_finish_v4: bool = false, furniture_finish_v5: bool = false) -> void:
	# Round 02 still used the shared isotropic noise texture and produced pale,
	# mottled surfaces. Round 03 uses a per-wood-part shader with grain aligned
	# to the component's long axis; hardware keeps its authored metal material.
	var materials_by_color: Dictionary = {}
	for mesh_variant in parent.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_variant as MeshInstance3D
		if String(mesh_instance.get_meta("roomscale_material_category", "")) != "wood":
			continue
		var source := mesh_instance.material_override as StandardMaterial3D
		if source == null:
			continue
		var key := source.albedo_color.to_html()
		if not materials_by_color.has(key):
			var wood_material := ShaderMaterial.new()
			wood_material.shader = ROOM_CHAIR_WOODFINISH_V4 if chair_finish_v4 else (ROOM_FURNITURE_WOODFINISH_V5 if furniture_finish_v5 else ROOM_WOODGRAIN_V3)
			var timber_tint := source.albedo_color
			if furniture_finish_v5 and timber_tint.get_luminance() > 0.08:
				# The first mesh-authored furniture pass kept the target grain but
				# rendered the oak too dark and red. Restore yellow/brown midtones.
				timber_tint.r *= 0.98
				timber_tint.g *= 0.88
				timber_tint.b *= 0.76
			elif furniture_finish_v5:
				timber_tint.r *= 0.98
				timber_tint.g *= 0.90
				timber_tint.b *= 0.82
			elif chair_finish_v4 and timber_tint.get_luminance() > 0.08:
				# The chair-specific finish reduces the orange cast while keeping
				# distinct oak and walnut values from the authored part palette.
				timber_tint.r *= 0.84
				timber_tint.g *= 0.78
				timber_tint.b *= 0.68
			elif chair_finish_v4:
				timber_tint.r *= 0.90
				timber_tint.g *= 0.82
				timber_tint.b *= 0.72
			elif timber_tint.get_luminance() > 0.08:
				# The source palette renders too yellow under the room's bright key
				# light; keep oak warm while reducing its green and blue response.
				timber_tint.r *= 0.87
				timber_tint.g *= 0.60
				timber_tint.b *= 0.53
			else:
				# Preserve dark walnut as a distinct red-brown instead of crushing it.
				timber_tint.r *= 0.92
				timber_tint.g *= 0.76
				timber_tint.b *= 0.68
			wood_material.set_shader_parameter("timber_color", timber_tint)
			wood_material.set_shader_parameter("tone_scale", tone_scale)
			materials_by_color[key] = wood_material
		mesh_instance.material_override = materials_by_color[key]


func _uses_mesh_authored_furniture(refinement: String) -> bool:
	return refinement in ["mesh_authored_furniture_v5", "mesh_authored_furniture_warm_finish_v6"]


func _elevated_workbench(parent: Node3D, refinement: String) -> void:
	var oak := Color("9a693d")
	var oak_light := Color("b1814e")
	var walnut := Color("503620")
	var iron := Color("303333")
	var brass := Color("a88448")
	# Six fitted boards retain the full 58 x 30 in worktop envelope.
	for index in range(6):
		var z := -12.5 + float(index) * 5.0
		G.box(parent, "TopBoard_%02d" % index, Vector3(57.8, 3.8, 4.85), Vector3(0, 34.0, z), "wood", oak_light if index % 2 == 0 else oak, 0.16)
	for side in [-1, 1]:
		G.box(parent, "BreadboardEnd_%d" % side, Vector3(2.0, 3.95, 29.6), Vector3(side * 27.9, 34.0, 0), "wood", walnut, 0.13)
	# Four square legs, visible apron and a full stretcher frame.
	for x_side in [-1, 1]:
		for z_side in [-1, 1]:
			var x := float(x_side) * 24.4
			var z := float(z_side) * 10.2
			if _uses_mesh_authored_furniture(refinement):
				var leg_profile: Array[Vector3] = [
					Vector3(0.0, 2.58, 2.58), Vector3(0.06, 2.58, 2.58), Vector3(0.12, 2.43, 2.43),
					Vector3(0.82, 2.43, 2.43), Vector3(0.90, 2.72, 2.72), Vector3(1.0, 2.45, 2.45)
				]
				G.profiled_beam(parent, "Shouldered_Mortise_Leg_%d_%d" % [x_side, z_side], Vector3(x, 0.0, z), Vector3(x, 32.0, z), leg_profile, "wood", walnut if z_side < 0 else oak, 0.18)
			else:
				G.box(parent, "Leg_%d_%d" % [x_side, z_side], Vector3(5.2, 32.0, 5.2), Vector3(x, 16.0, z), "wood", walnut if z_side < 0 else oak, 0.34)
			G.box(parent, "MortiseShoulder_%d_%d" % [x_side, z_side], Vector3(5.45, 1.3, 5.45), Vector3(x, 29.7, z), "wood", oak_light, 0.12)
			G.box(parent, "FootShoe_%d_%d" % [x_side, z_side], Vector3(5.35, 1.4, 5.35), Vector3(x, 1.0, z), "wood", walnut, 0.13)
	for z_side in [-1, 1]:
		if _uses_mesh_authored_furniture(refinement):
			var apron_profile: Array[Vector3] = [Vector3(0.0, 2.15, 0.55), Vector3(0.08, 2.8, 0.9), Vector3(0.92, 2.8, 0.9), Vector3(1.0, 2.15, 0.55)]
			var stretcher_profile: Array[Vector3] = [Vector3(0.0, 1.0, 0.55), Vector3(0.10, 1.6, 1.0), Vector3(0.90, 1.6, 1.0), Vector3(1.0, 1.0, 0.55)]
			G.profiled_beam(parent, "Shouldered_Front_Apron_%d" % z_side, Vector3(-22.4, 27.4, float(z_side) * 9.6), Vector3(22.4, 27.4, float(z_side) * 9.6), apron_profile, "wood", oak, 0.12)
			G.profiled_beam(parent, "Shouldered_Lower_Stretcher_%d" % z_side, Vector3(-21.9, 6.0, float(z_side) * 9.4), Vector3(21.9, 6.0, float(z_side) * 9.4), stretcher_profile, "wood", walnut, 0.10)
		else:
			G.box(parent, "ApronLong_%d" % z_side, Vector3(44.8, 5.6, 1.8), Vector3(0, 27.4, float(z_side) * 9.6), "wood", oak, 0.18)
			G.box(parent, "LowerStretcherLong_%d" % z_side, Vector3(43.8, 3.2, 2.0), Vector3(0, 6.0, float(z_side) * 9.4), "wood", walnut, 0.14)
	for x_side in [-1, 1]:
		if _uses_mesh_authored_furniture(refinement):
			var apron_profile: Array[Vector3] = [Vector3(0.0, 2.15, 0.55), Vector3(0.08, 2.8, 0.9), Vector3(0.92, 2.8, 0.9), Vector3(1.0, 2.15, 0.55)]
			var stretcher_profile: Array[Vector3] = [Vector3(0.0, 1.0, 0.55), Vector3(0.10, 1.6, 1.0), Vector3(0.90, 1.6, 1.0), Vector3(1.0, 1.0, 0.55)]
			G.profiled_beam(parent, "Shouldered_End_Apron_%d" % x_side, Vector3(float(x_side) * 23.0, 27.4, -8.4), Vector3(float(x_side) * 23.0, 27.4, 8.4), apron_profile, "wood", oak, 0.12)
			G.profiled_beam(parent, "Shouldered_End_Stretcher_%d" % x_side, Vector3(float(x_side) * 22.9, 6.0, -8.4), Vector3(float(x_side) * 22.9, 6.0, 8.4), stretcher_profile, "wood", walnut, 0.10)
		else:
			G.box(parent, "ApronEnd_%d" % x_side, Vector3(1.8, 5.6, 16.8), Vector3(float(x_side) * 23.0, 27.4, 0), "wood", oak, 0.18)
			G.box(parent, "LowerStretcherEnd_%d" % x_side, Vector3(2.0, 3.2, 16.8), Vector3(float(x_side) * 22.9, 6.0, 0), "wood", walnut, 0.14)
	# Dovetailed drawer bank: distinct reveals and three individually fitted fronts.
	for index in range(3):
		var y := 28.7 - float(index) * 3.0
		var width := 18.0 if index < 2 else 38.0
		var x := -11.0 if index == 0 else (10.0 if index == 1 else 0.0)
		if _uses_mesh_authored_furniture(refinement):
			G.raised_panel(parent, "Reeded_Drawer_Front_%02d" % index, width, 2.45, 0.7, Vector3(x, y, 10.62), "wood", oak_light if index == 1 else oak, 0.1)
		else:
			G.box(parent, "DrawerFront_%02d" % index, Vector3(width, 2.45, 0.7), Vector3(x, y, 10.62), "wood", oak_light if index == 1 else oak, 0.1)
		for dovetail_side in [-1, 1]:
			G.box(parent, "DrawerDovetail_%02d_%d" % [index, dovetail_side], Vector3(0.48, 0.75, 0.10), Vector3(x + float(dovetail_side) * (width * 0.5 - 1.1), y - 0.7, 11.02), "wood", walnut, 0.02)
		G.cylinder(parent, "DrawerPull_%02d" % index, 0.42, 0.42, Vector3(x, y, 11.1), "brass", brass).rotation.x = PI * 0.5
		G.box(parent, "DrawerPullBackplate_%02d" % index, Vector3(1.5, 1.0, 0.12), Vector3(x, y, 10.95), "brass", walnut, 0.06)
	# Workholding dogs and a mechanical iron shoulder vise at the front corner.
	for row in range(2):
		for column in range(5):
			var x := -17.0 + float(column) * 7.0
			var z := -8.0 + float(row) * 5.5
			G.cylinder(parent, "BenchDog_%d_%d" % [row, column], 0.38, 0.09, Vector3(x, 35.96, z), "iron", iron)
	G.box(parent, "ViseIronPlate", Vector3(8.0, 8.2, 0.55), Vector3(-20.8, 29.7, 14.45), "iron", iron, 0.12)
	G.box(parent, "ViseFixedJaw", Vector3(9.0, 2.2, 1.35), Vector3(-20.8, 33.4, 14.2), "wood", walnut, 0.08)
	G.box(parent, "ViseSlidingJaw", Vector3(9.0, 2.2, 1.35), Vector3(-20.8, 26.4, 14.2), "wood", oak_light, 0.08)
	var screw := G.cylinder(parent, "ViseScrew", 0.56, 2.0, Vector3(-20.8, 29.6, 14.55), "iron", Color("6e7470"))
	screw.rotation.x = PI * 0.5
	G.cylinder(parent, "ViseHandle", 0.28, 3.8, Vector3(-20.8, 27.1, 14.55), "iron", Color("c0a070"))
	for side in [-1, 1]:
		G.cylinder(parent, "ViseHandleKnob_%d" % side, 0.48, 0.72, Vector3(-20.8, 27.1 + float(side) * 1.8, 14.55), "wood", walnut)


func _assembly_table(parent: Node3D, refinement: String) -> void:
	var oak := Color("a87846")
	var walnut := Color("523920")
	var iron := Color("383d3c")
	var brass := Color("a9854a")
	G.box(parent, "WorktopMainSlab", Vector3(40.8, 2.8, 31.0), Vector3(0, 22.1, 0), "wood", oak, 0.14)
	for side in [-1, 1]:
		G.box(parent, "BreadboardEnd_%d" % side, Vector3(1.0, 2.9, 31.8), Vector3(float(side) * 20.2, 22.1, 0), "wood", walnut, 0.1)
	for x_side in [-1, 1]:
		for z_side in [-1, 1]:
			var x := float(x_side) * 17.2
			var z := float(z_side) * 12.7
			if _uses_mesh_authored_furniture(refinement):
				var leg_profile: Array[Vector3] = [Vector3(0.0, 1.1, 1.1), Vector3(0.08, 1.45, 1.45), Vector3(0.18, 1.3, 1.3), Vector3(0.86, 1.0, 1.0), Vector3(0.94, 1.4, 1.4), Vector3(1.0, 1.2, 1.2)]
				G.profiled_beam(parent, "Tapered_Tenoned_Leg_%d_%d" % [x_side, z_side], Vector3(x, 0.0, z), Vector3(x, 19.4, z), leg_profile, "wood", walnut, 0.10)
			else:
				G.cylinder(parent, "TaperedLeg_%d_%d" % [x_side, z_side], 1.55, 19.4, Vector3(x, 10.0, z), "wood", walnut, 1.05)
				G.cylinder(parent, "TurnedFoot_%d_%d" % [x_side, z_side], 1.5, 2.0, Vector3(x, 1.0, z), "wood", oak, 1.1)
	for z_side in [-1, 1]:
		if _uses_mesh_authored_furniture(refinement):
			var apron_profile: Array[Vector3] = [Vector3(0.0, 1.4, 0.42), Vector3(0.08, 2.0, 0.68), Vector3(0.92, 2.0, 0.68), Vector3(1.0, 1.4, 0.42)]
			var stretcher_profile: Array[Vector3] = [Vector3(0.0, 0.58, 0.38), Vector3(0.1, 1.1, 0.75), Vector3(0.9, 1.1, 0.75), Vector3(1.0, 0.58, 0.38)]
			G.profiled_beam(parent, "Fitted_Front_Apron_%d" % z_side, Vector3(-16.7, 18.3, float(z_side) * 11.9), Vector3(16.7, 18.3, float(z_side) * 11.9), apron_profile, "wood", walnut, 0.08)
			G.profiled_beam(parent, "Shouldered_Lower_Stretcher_%d" % z_side, Vector3(-15.75, 5.2, float(z_side) * 10.9), Vector3(15.75, 5.2, float(z_side) * 10.9), stretcher_profile, "wood", oak, 0.08)
		else:
			G.box(parent, "FrontBackApron_%d" % z_side, Vector3(33.4, 4.0, 1.35), Vector3(0, 18.3, float(z_side) * 11.9), "wood", walnut, 0.14)
			G.box(parent, "LowerStretcher_%d" % z_side, Vector3(31.5, 2.2, 1.5), Vector3(0, 5.2, float(z_side) * 10.9), "wood", oak, 0.10)
	for x_side in [-1, 1]:
		if _uses_mesh_authored_furniture(refinement):
			var apron_profile: Array[Vector3] = [Vector3(0.0, 1.4, 0.42), Vector3(0.08, 2.0, 0.68), Vector3(0.92, 2.0, 0.68), Vector3(1.0, 1.4, 0.42)]
			var stretcher_profile: Array[Vector3] = [Vector3(0.0, 0.58, 0.38), Vector3(0.1, 1.1, 0.75), Vector3(0.9, 1.1, 0.75), Vector3(1.0, 0.58, 0.38)]
			G.profiled_beam(parent, "Fitted_End_Apron_%d" % x_side, Vector3(float(x_side) * 16.4, 18.3, -11.4), Vector3(float(x_side) * 16.4, 18.3, 11.4), apron_profile, "wood", walnut, 0.08)
			G.profiled_beam(parent, "Fitted_End_Stretcher_%d" % x_side, Vector3(float(x_side) * 15.9, 5.2, -10.4), Vector3(float(x_side) * 15.9, 5.2, 10.4), stretcher_profile, "wood", oak, 0.08)
		else:
			G.box(parent, "EndApron_%d" % x_side, Vector3(1.4, 4.0, 22.8), Vector3(float(x_side) * 16.4, 18.3, 0), "wood", walnut, 0.14)
			G.box(parent, "EndStretcher_%d" % x_side, Vector3(1.5, 2.2, 20.8), Vector3(float(x_side) * 15.9, 5.2, 0), "wood", oak, 0.10)
	if _uses_mesh_authored_furniture(refinement):
		G.raised_panel(parent, "Routed_Drawer_Front", 13.8, 3.1, 0.65, Vector3(-3.7, 18.2, 12.85), "wood", oak, 0.08)
	else:
		G.box(parent, "DrawerFront", Vector3(13.8, 3.1, 0.65), Vector3(-3.7, 18.2, 12.85), "wood", oak, 0.1)
	for side in [-1, 1]:
		G.box(parent, "DrawerDovetail_%d" % side, Vector3(0.55, 0.7, 0.08), Vector3(-3.7 + float(side) * 5.8, 17.4, 13.22), "wood", walnut, 0.03)
	G.cylinder(parent, "DrawerCupPull", 0.48, 0.32, Vector3(-3.7, 18.2, 13.25), "brass", brass).rotation.x = PI * 0.5
	G.box(parent, "VisePlate", Vector3(6.4, 5.5, 0.45), Vector3(14.7, 19.8, 12.65), "iron", iron, 0.12)
	G.box(parent, "ViseJaw", Vector3(6.0, 2.2, 1.0), Vector3(14.7, 21.0, 13.4), "wood", walnut, 0.08)
	var screw := G.cylinder(parent, "ViseScrew", 0.42, 1.3, Vector3(14.7, 18.7, 13.3), "iron", Color("727875"))
	screw.rotation.x = PI * 0.5
	G.cylinder(parent, "ViseHandle", 0.2, 2.5, Vector3(14.7, 17.5, 13.5), "iron", brass)
	for x in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		G.cylinder(parent, "BenchDog_%d" % int(x), 0.32, 0.07, Vector3(x, 23.48, -7.0), "iron", iron)


func _tool_wardrobe(parent: Node3D, refinement: String) -> void:
	var oak := Color("91613a")
	var panel := Color("a67645")
	var walnut := Color("49311f")
	var brass := Color("ad8748")
	var steel := Color("444a48")
	# Framed carcass, stepped crown and plinth, all within 42 x 70 x 22 in.
	G.box(parent, "BackBoard", Vector3(38.6, 59.0, 1.0), Vector3(0, 34.5, -10.2), "wood", walnut, 0.08)
	for side in [-1, 1]:
		G.box(parent, "CarcassSide_%d" % side, Vector3(1.4, 60.0, 19.2), Vector3(float(side) * 20.0, 35.0, 0), "wood", oak, 0.12)
	G.box(parent, "CarcassTop", Vector3(39.8, 2.0, 20.4), Vector3(0, 64.0, 0), "wood", walnut, 0.1)
	G.box(parent, "PlinthBase", Vector3(40.8, 5.2, 21.2), Vector3(0, 2.6, 0), "wood", walnut, 0.2)
	G.box(parent, "PlinthBand", Vector3(41.5, 1.6, 21.7), Vector3(0, 5.2, 0), "wood", oak, 0.12)
	G.box(parent, "CrownLower", Vector3(41.3, 1.5, 21.6), Vector3(0, 64.8, 0), "wood", walnut, 0.13)
	G.box(parent, "CrownNeckBand", Vector3(40.4, 0.9, 20.5), Vector3(0, 65.85, 0), "wood", walnut, 0.08)
	G.box(parent, "CrownMould", Vector3(42.0, 3.7, 22.0), Vector3(0, 68.15, 0), "wood", oak, 0.22)
	# Front frame and a centered pair of raised/recessed door panels.
	for x in [-18.8, -1.0, 12.2]:
		G.box(parent, "FrontStile_%d" % int(x), Vector3(1.6, 57.0, 1.0), Vector3(x, 35.0, 10.3), "wood", walnut, 0.10)
	G.box(parent, "FrontTopRail", Vector3(32.6, 1.8, 1.1), Vector3(-3.2, 63.0, 10.3), "wood", walnut, 0.1)
	G.box(parent, "FrontBottomRail", Vector3(32.6, 1.8, 1.1), Vector3(-3.2, 7.0, 10.3), "wood", walnut, 0.1)
	for door in [-1, 1]:
		var cx := -3.1 + float(door) * 7.2
		G.box(parent, "Door_%d" % door, Vector3(14.4, 51.8, 0.72), Vector3(cx, 35.0, 10.5), "wood", panel, 0.12)
		for x_side in [-1, 1]:
			G.box(parent, "DoorStile_%d_%d" % [door, x_side], Vector3(1.0, 51.2, 0.9), Vector3(cx + float(x_side) * 6.3, 35.0, 10.95), "wood", oak, 0.07)
		for y_side in [-1, 1]:
			G.box(parent, "DoorRail_%d_%d" % [door, y_side], Vector3(12.7, 1.4, 0.9), Vector3(cx, 35.0 + float(y_side) * 24.5, 10.95), "wood", oak, 0.07)
		if _uses_mesh_authored_furniture(refinement):
			G.raised_panel(parent, "Routed_RaisedPanel_%d" % door, 10.8, 45.0, 0.32, Vector3(cx, 35.0, 11.16), "wood", panel.darkened(0.07), 0.18)
		else:
			G.box(parent, "RaisedPanel_%d" % door, Vector3(10.8, 45.0, 0.32), Vector3(cx, 35.0, 11.16), "wood", panel.darkened(0.07), 0.18)
		G.cylinder(parent, "DoorPull_%d" % door, 0.42, 1.2, Vector3(cx + float(door) * 5.2, 34.5, 10.2), "brass", brass).rotation.x = PI * 0.5
		for y in [12.0, 35.0, 58.0]:
			var hinge := G.box(parent, "HingePlate_%d_%d" % [door, int(y)], Vector3(1.15, 2.7, 0.18), Vector3(cx + float(door) * 6.75, y, 10.8), "brass", brass, 0.07)
			for bolt_y in [-0.8, 0.8]:
				G.cylinder(parent, "HingePin_%d_%d_%d" % [door, int(y), int(bolt_y * 10)], 0.09, 0.12, hinge.position + Vector3(0, bolt_y, 0.13), "iron", steel).rotation.x = PI * 0.5
	# Open right-hand tool bay: shelves, hang rail, and individually built tools.
	for shelf in range(5):
		var y := 13.0 + float(shelf) * 11.0
		G.box(parent, "ToolShelf_%02d" % shelf, Vector3(8.6, 0.9, 17.4), Vector3(16.0, y, 0), "wood", walnut, 0.07)
		G.box(parent, "ShelfNosings_%02d" % shelf, Vector3(8.6, 0.45, 0.7), Vector3(16.0, y + 0.45, 8.1), "wood", oak, 0.05)
	for row in range(3):
		var base_y := 15.0 + float(row) * 16.0
		for tool in range(3):
			var z := -5.2 + float(tool) * 4.6
			var x := 19.0
			G.cylinder(parent, "ToolHandle_%d_%d" % [row, tool], 0.42, 4.4, Vector3(x, base_y + 5.8, z), "wood", oak, 0.22)
			G.box(parent, "ToolFerrule_%d_%d" % [row, tool], Vector3(0.7, 0.7, 0.7), Vector3(x, base_y + 3.1, z), "brass", brass, 0.08)
			G.box(parent, "ToolBlade_%d_%d" % [row, tool], Vector3(0.45, 4.7, 0.75), Vector3(x, base_y + 0.8, z), "iron", steel, 0.04)
			G.cylinder(parent, "ToolEndCap_%d_%d" % [row, tool], 0.46, 0.34, Vector3(x, base_y + 8.0, z), "wood", walnut)


func _floor_cabinet(parent: Node3D, refinement: String) -> void:
	var oak := Color("a47443")
	var walnut := Color("4a321f")
	var brass := Color("ad884b")
	G.box(parent, "TopSlab", Vector3(25.8, 2.1, 23.8), Vector3(0, 19.95, 0), "wood", oak, 0.14)
	for side in [-1, 1]:
		G.box(parent, "SidePanel_%d" % side, Vector3(1.5, 15.6, 20.0), Vector3(float(side) * 11.6, 10.7, 0), "wood", oak.darkened(0.12), 0.10)
		G.box(parent, "FrontStile_%d" % side, Vector3(1.7, 15.7, 1.0), Vector3(float(side) * 11.6, 10.7, 11.2), "wood", walnut, 0.10)
	G.box(parent, "BackPanel", Vector3(22.8, 15.7, 1.1), Vector3(0, 10.7, -11.1), "wood", walnut, 0.06)
	G.box(parent, "TopRail", Vector3(22.4, 1.2, 1.1), Vector3(0, 18.4, 11.2), "wood", walnut, 0.08)
	G.box(parent, "BottomRail", Vector3(22.4, 1.0, 1.1), Vector3(0, 3.1, 11.2), "wood", walnut, 0.07)
	for index in range(2):
		var y := 14.0 - float(index) * 6.7
		G.box(parent, "DrawerBox_%d" % index, Vector3(18.6, 5.8, 8.2), Vector3(0, y, 5.8), "wood", walnut, 0.06)
		if _uses_mesh_authored_furniture(refinement):
			G.raised_panel(parent, "Routed_DrawerFront_%d" % index, 19.5, 5.5, 0.8, Vector3(0, y, 11.15), "wood", oak, 0.10)
		else:
			G.box(parent, "DrawerFront_%d" % index, Vector3(19.5, 5.5, 0.8), Vector3(0, y, 11.15), "wood", oak, 0.10)
		for side in [-1, 1]:
			G.box(parent, "Dovetail_%d_%d" % [index, side], Vector3(0.55, 1.0, 0.08), Vector3(float(side) * 7.4, y - 1.9, 11.58), "wood", walnut, 0.025)
		G.box(parent, "CupPullBackplate_%d" % index, Vector3(2.2, 1.25, 0.18), Vector3(0, y, 11.66), "brass", walnut, 0.06)
		G.cylinder(parent, "CupPull_%d" % index, 0.44, 0.50, Vector3(0, y, 11.7), "brass", brass).rotation.x = PI * 0.5
	G.box(parent, "Plinth", Vector3(24.8, 1.8, 22.8), Vector3(0, 1.2, 0), "wood", walnut, 0.16)
	for x_side in [-1, 1]:
		for z_side in [-1, 1]:
			G.box(parent, "CabinetFoot_%d_%d" % [x_side, z_side], Vector3(3.7, 2.2, 3.7), Vector3(float(x_side) * 10.0, 1.1, float(z_side) * 9.0), "wood", oak, 0.18)
	for index in range(4):
		var x := -8.0 + float(index) * 5.3
		G.box(parent, "TopBoardSeam_%d" % index, Vector3(0.045, 0.02, 20.0), Vector3(x, 21.01, 0), "wood", walnut, 0.01)


func _low_room_chair(parent: Node3D) -> void:
	var oak := Color("a87948")
	var walnut := Color("4a321f")
	var dark := Color("33261c")
	# Broad 25 x 23 in footprint with a crest at exactly 19 in overall height.
	G.box(parent, "SeatCore", Vector3(22.8, 2.5, 22.8), Vector3(0, 10.5, 0), "wood", oak, 0.48)
	G.box(parent, "SeatFrontLip", Vector3(21.5, 0.65, 1.1), Vector3(0, 9.9, 10.1), "wood", walnut, 0.24)
	for x_side in [-1, 1]:
		for z_side in [-1, 1]:
			var top_point := Vector3(float(x_side) * 8.6, 9.5, float(z_side) * 7.3)
			var foot_point := Vector3(float(x_side) * 11.6, 0.5, float(z_side) * 10.4)
			_pipe(parent, "TurnedSplayedLeg_%d_%d" % [x_side, z_side], foot_point, top_point, 0.82, "wood", walnut)
			_pipe(parent, "TurnedFootCollar_%d_%d" % [x_side, z_side], foot_point.lerp(top_point, 0.18), foot_point.lerp(top_point, 0.27), 1.05, "wood", oak)
			G.cylinder(parent, "SeatPeg_%d_%d" % [x_side, z_side], 0.18, 0.10, Vector3(float(x_side) * 8.6, 11.78, float(z_side) * 7.3), "wood", dark)
	# Four visible stretchers, all joined between the splayed legs.
	for z_side in [-1, 1]:
		_pipe(parent, "SideStretcher_%d" % z_side, Vector3(-10.1, 4.2, float(z_side) * 9.0), Vector3(10.1, 4.2, float(z_side) * 9.0), 0.48, "wood", oak)
	for x_side in [-1, 1]:
		_pipe(parent, "FrontBackStretcher_%d" % x_side, Vector3(float(x_side) * 10.1, 4.2, -9.0), Vector3(float(x_side) * 10.1, 4.2, 9.0), 0.48, "wood", walnut)
	# Short back posts rise above the broad seat without violating the low chair envelope.
	for x_side in [-1, 1]:
		_pipe(parent, "BackPost_%d" % x_side, Vector3(float(x_side) * 9.0, 11.5, -8.5), Vector3(float(x_side) * 8.8, 18.4, -8.8), 0.78, "wood", walnut)
	G.box(parent, "LowCrestRail", Vector3(19.0, 1.2, 1.6), Vector3(0, 18.35, -8.8), "wood", oak, 0.36)
	for index in range(3):
		var x := -4.6 + float(index) * 4.6
		_pipe(parent, "ShapedSpindle_%02d" % index, Vector3(x, 11.7, -8.65), Vector3(x, 17.7, -8.65), 0.32, "wood", oak)
		G.cylinder(parent, "SpindleTurn_%02d" % index, 0.43, 0.55, Vector3(x, 15.2, -8.65), "wood", walnut)


func _low_room_chair_mesh_authored(parent: Node3D) -> void:
	var oak := Color("9a8067")
	var oak_light := Color("b09272")
	var walnut := Color("805b42")
	var peg_color := Color("d0a16f")
	# A continuous custom seat mesh replaces the former box seat and front lip.
	G.dished_seat(parent, "Sculpted_Dished_Oak_Seat", 22.4, 17.3, 11.35, 1.95, 0.80, "wood", oak)

	# Lathed turned legs have bead/cove transitions and splay out to the floor.
	var leg_profile: Array[Vector2] = [
		Vector2(0.0, 0.42), Vector2(0.055, 0.58), Vector2(0.12, 0.66), Vector2(0.17, 0.76),
		Vector2(0.22, 0.88), Vector2(0.27, 0.83), Vector2(0.32, 0.60), Vector2(0.42, 0.56),
		Vector2(0.54, 0.72), Vector2(0.63, 0.84), Vector2(0.69, 0.76), Vector2(0.74, 0.58),
		Vector2(0.83, 0.55), Vector2(0.92, 0.62), Vector2(1.0, 0.48)
	]
	for x_side in [-1, 1]:
		for z_side in [-1, 1]:
			var foot := Vector3(float(x_side) * 10.9, 0.55, float(z_side) * 9.5)
			var shoulder := Vector3(float(x_side) * 8.55, 9.45, float(z_side) * 6.45)
			G.lathe_profile(parent, "Turned_Splayed_Leg_%d_%d" % [x_side, z_side], foot, shoulder, leg_profile, "wood", walnut)
			G.cylinder(parent, "Seat_Tenon_Peg_%d_%d" % [x_side, z_side], 0.22, 0.10, Vector3(float(x_side) * 8.3, 11.16, float(z_side) * 6.3), "wood", peg_color)

	# Fitted oval stretchers use shaped end shoulders; visible pins show their through-tenons.
	var stretcher_profile: Array[Vector2] = [
		Vector2(0.0, 0.27), Vector2(0.08, 0.37), Vector2(0.16, 0.47), Vector2(0.25, 0.43),
		Vector2(0.42, 0.35), Vector2(0.58, 0.35), Vector2(0.75, 0.43), Vector2(0.84, 0.47),
		Vector2(0.92, 0.37), Vector2(1.0, 0.27)
	]
	for z_side in [-1, 1]:
		var z := float(z_side) * 8.25
		G.lathe_profile(parent, "Fitted_Side_Stretcher_%d" % z_side, Vector3(-9.9, 4.0, z), Vector3(9.9, 4.0, z), stretcher_profile, "wood", oak_light)
	for x_side in [-1, 1]:
		var x := float(x_side) * 9.7
		G.lathe_profile(parent, "Fitted_Cross_Stretcher_%d" % x_side, Vector3(x, 4.0, 8.25), Vector3(x, 4.0, -8.25), stretcher_profile, "wood", walnut)
		G.cylinder(parent, "Front_Stretcher_Through_Tenon_%d" % x_side, 0.22, 0.12, Vector3(x, 4.0, 9.02), "wood", peg_color).rotation.x = PI * 0.5
		G.cylinder(parent, "Rear_Stretcher_Through_Tenon_%d" % x_side, 0.22, 0.12, Vector3(x, 4.0, -9.02), "wood", peg_color).rotation.x = -PI * 0.5
	for z_side in [-1, 1]:
		for x_side in [-1, 1]:
			G.cylinder(parent, "Side_Stretcher_Through_Tenon_%d_%d" % [x_side, z_side], 0.22, 0.12, Vector3(float(x_side) * 10.62, 4.0, float(z_side) * 8.25), "wood", peg_color).rotation.z = PI * 0.5 * float(x_side)

	# The back continues from the seat as turned posts and three shaped, tapered spindles.
	var post_profile: Array[Vector2] = [
		Vector2(0.0, 0.40), Vector2(0.08, 0.50), Vector2(0.16, 0.63), Vector2(0.23, 0.54),
		Vector2(0.35, 0.45), Vector2(0.65, 0.45), Vector2(0.79, 0.56), Vector2(0.88, 0.62),
		Vector2(0.95, 0.48), Vector2(1.0, 0.39)
	]
	for x_side in [-1, 1]:
		G.lathe_profile(parent, "Turned_Back_Post_%d" % x_side, Vector3(float(x_side) * 8.25, 10.8, -7.1), Vector3(float(x_side) * 8.95, 17.7, -9.0), post_profile, "wood", walnut)

	var spindle_profile: Array[Vector3] = [
		Vector3(0.0, 0.17, 0.16), Vector3(0.08, 0.26, 0.20), Vector3(0.22, 0.40, 0.25),
		Vector3(0.36, 0.72, 0.28), Vector3(0.50, 0.86, 0.26), Vector3(0.64, 0.72, 0.28),
		Vector3(0.82, 0.40, 0.25), Vector3(0.94, 0.25, 0.19), Vector3(1.0, 0.17, 0.16)
	]
	for index in range(3):
		var x := -4.5 + float(index) * 4.5
		G.elliptical_profile(parent, "Flattened_Leaf_Spindle_%02d" % index, Vector3(x, 11.25, -8.15), Vector3(x, 17.1, -9.0), spindle_profile, "wood", oak_light)

	# A swept oval crest has a real crown curve and rounded, shaped section.
	var crest_path: Array[Vector3] = []
	for index in range(19):
		var t := float(index) / 18.0
		var x := lerpf(-9.65, 9.65, t)
		var normalized_x := x / 9.65
		var y := 17.55 + 0.34 * (1.0 - normalized_x * normalized_x)
		crest_path.append(Vector3(x, y, -9.35))
	G.swept_oval(parent, "Curved_Sculpted_Crest_Rail", crest_path, 0.88, 0.66, "wood", oak_light)

	# End-grain pegs on the seat fascia make the seat-to-frame assembly visible at close range.
	for x_side in [-1, 1]:
		G.cylinder(parent, "Seat_Fascia_Peg_%d" % x_side, 0.16, 0.10, Vector3(float(x_side) * 8.1, 10.15, 8.48), "wood", peg_color).rotation.x = PI * 0.5


func _side_table(parent: Node3D, refinement: String) -> void:
	var oak := Color("a97745")
	var walnut := Color("4b321e")
	var brass := Color("ad8849")
	G.box(parent, "TopSlab", Vector3(19.8, 1.8, 16.8), Vector3(0, 19.0, 0), "wood", oak, 0.22)
	# Turned leg profiles use joined taper sections and collars, within the 20 in height.
	for x_side in [-1, 1]:
		for z_side in [-1, 1]:
			var x := float(x_side) * 7.7
			var z := float(z_side) * 6.1
			if _uses_mesh_authored_furniture(refinement):
				var turned_leg: Array[Vector2] = []
				if refinement == "mesh_authored_furniture_warm_finish_v6":
					turned_leg = [
						Vector2(0.0, 0.58), Vector2(0.08, 0.72), Vector2(0.16, 0.72),
						Vector2(0.24, 0.62), Vector2(0.42, 0.68), Vector2(0.50, 0.82),
						Vector2(0.58, 0.90), Vector2(0.68, 0.78), Vector2(0.78, 0.64),
						Vector2(0.90, 0.70), Vector2(1.0, 0.78)
					]
				else:
					turned_leg = [
						Vector2(0.0, 0.52), Vector2(0.07, 0.70), Vector2(0.16, 0.72),
						Vector2(0.22, 0.48), Vector2(0.40, 0.48), Vector2(0.48, 0.74),
						Vector2(0.57, 0.92), Vector2(0.66, 0.76), Vector2(0.73, 0.52),
						Vector2(0.88, 0.54), Vector2(0.94, 0.82), Vector2(1.0, 0.70)
					]
				G.lathe_profile(parent, "Continuous_Turned_Leg_%d_%d" % [x_side, z_side], Vector3(x, 0.5, z), Vector3(x, 18.1, z), turned_leg, "wood", oak)
			else:
				G.cylinder(parent, "Foot_%d_%d" % [x_side, z_side], 0.82, 2.0, Vector3(x, 1.0, z), "wood", walnut, 0.62)
				G.cylinder(parent, "LowerShaft_%d_%d" % [x_side, z_side], 0.62, 4.5, Vector3(x, 4.25, z), "wood", oak, 0.72)
				G.cylinder(parent, "TurnedBulb_%d_%d" % [x_side, z_side], 0.92, 2.4, Vector3(x, 7.7, z), "wood", walnut, 0.74)
				G.cylinder(parent, "UpperShaft_%d_%d" % [x_side, z_side], 0.62, 9.2, Vector3(x, 13.5, z), "wood", oak, 0.74)
				G.cylinder(parent, "LegCollar_%d_%d" % [x_side, z_side], 0.84, 1.0, Vector3(x, 17.4, z), "wood", walnut, 0.78)
	for side in [-1, 1]:
		G.box(parent, "ApronLong_%d" % side, Vector3(14.4, 3.6, 1.1), Vector3(0, 16.4, float(side) * 6.2), "wood", walnut, 0.16)
		G.box(parent, "ApronEnd_%d" % side, Vector3(1.1, 3.6, 11.6), Vector3(float(side) * 7.6, 16.4, 0), "wood", walnut, 0.16)
	if _uses_mesh_authored_furniture(refinement):
		G.raised_panel(parent, "Routed_DrawerFront", 8.2, 2.5, 0.62, Vector3(0, 16.5, 6.95), "wood", oak, 0.1)
	else:
		G.box(parent, "DrawerFront", Vector3(8.2, 2.5, 0.62), Vector3(0, 16.5, 6.95), "wood", oak, 0.1)
	for side in [-1, 1]:
		G.box(parent, "DrawerDovetail_%d" % side, Vector3(0.45, 0.62, 0.08), Vector3(float(side) * 3.0, 15.9, 7.28), "wood", walnut, 0.025)
	G.cylinder(parent, "DrawerPull", 0.34, 0.3, Vector3(0, 16.5, 7.35), "brass", brass).rotation.x = PI * 0.5
	if _uses_mesh_authored_furniture(refinement):
		var routed_shelf := G.raised_panel(parent, "Routed_Lower_Shelf", 15.3, 12.0, 1.05, Vector3(0, 5.8, 0), "wood", walnut, 0.12)
		routed_shelf.rotation.x = -PI * 0.5
	else:
		G.box(parent, "LowerShelf", Vector3(15.3, 1.05, 12.0), Vector3(0, 5.8, 0), "wood", walnut, 0.12)
	for side in [-1, 1]:
		G.box(parent, "ShelfRail_%d" % side, Vector3(0.6, 1.3, 12.2), Vector3(float(side) * 7.35, 6.0, 0), "wood", oak, 0.08)
	G.box(parent, "FrontRail", Vector3(15.4, 1.2, 0.8), Vector3(0, 6.0, 5.9), "wood", oak, 0.08)
	G.box(parent, "RearRail", Vector3(15.4, 1.2, 0.8), Vector3(0, 6.0, -5.9), "wood", oak, 0.08)


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
