extends SceneTree
## Package the MPFB2 GLB under the stable RoomScale citizen pivots.

const Resolver := preload("res://scripts/visuals/visual_resolver.gd")
const BridgeScript := preload("res://scripts/art_factory/generators/mpfb_citizen_pivots_v087.gd")


func _initialize() -> void:
	call_deferred("write_scene")


func write_scene() -> void:
	var source_path := OS.get_environment("ROOMSCALE_MPFB_CITIZEN_GLB_PATH")
	var destination_path := OS.get_environment("ROOMSCALE_MPFB_CITIZEN_TSCN_PATH")
	if source_path.is_empty() or destination_path.is_empty():
		_fail("MPFB source and destination paths are required")
		return
	var source_scene := load(source_path) as PackedScene
	if source_scene == null:
		_fail("MPFB GLB did not import as a PackedScene")
		return
	var generated_asset := source_scene.instantiate() as Node3D
	if generated_asset == null:
		_fail("MPFB GLB scene root must be Node3D")
		return
	var skeleton := generated_asset.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		generated_asset.free()
		_fail("MPFB GLB has no exported Skeleton3D")
		return
	var high_detail_meshes := 0
	var distance_lod_meshes := 0
	for mesh_instance in generated_asset.find_children("*", "MeshInstance3D", true, false):
		if String(mesh_instance.name).ends_with("_LOD1"):
			mesh_instance.visibility_range_begin = 5.0
			mesh_instance.visibility_range_end = 0.0
			distance_lod_meshes += 1
		else:
			mesh_instance.visibility_range_begin = 0.0
			mesh_instance.visibility_range_end = 5.0
			high_detail_meshes += 1
	if high_detail_meshes != 9 or distance_lod_meshes != 9:
		generated_asset.free()
		_fail("Expected nine detailed meshes and nine shared-skeleton distance LOD meshes; got %d and %d" % [high_detail_meshes, distance_lod_meshes])
		return
	for bone_name in ["upperarm_l", "upperarm_r", "thigh_l", "thigh_r"]:
		if skeleton.find_bone(bone_name) < 0:
			generated_asset.free()
			_fail("MPFB game_engine skeleton is missing %s" % bone_name)
			return
	var source_bounds := Resolver.mesh_bounds(generated_asset, generated_asset.transform)
	if minf(source_bounds.size.x, minf(source_bounds.size.y, source_bounds.size.z)) <= 0.0001:
		generated_asset.free()
		_fail("MPFB GLB has no measurable three-axis extent")
		return

	var target := Vector3(0.26, 0.5, 0.21)
	var fit_scale := target / source_bounds.size
	generated_asset.scale = fit_scale
	generated_asset.position = Vector3(
		-(source_bounds.position.x + source_bounds.size.x * 0.5) * fit_scale.x,
		-source_bounds.position.y * fit_scale.y - 0.23,
		-(source_bounds.position.z + source_bounds.size.z * 0.5) * fit_scale.z
	)
	generated_asset.name = "MPFBGeneratedRig"

	var candidate_root := Node3D.new()
	candidate_root.name = "CitizenArtAsset"
	candidate_root.set_script(BridgeScript)
	var body := Node3D.new()
	body.name = "Body"
	body.position.y = 0.23
	body.set_meta("preserve_generated_vertex_color", true)
	candidate_root.add_child(body)
	body.add_child(generated_asset)
	var pivots := {
		"LeftArm": Vector3(-0.105, 0.235, 0.0),
		"RightArm": Vector3(0.105, 0.235, 0.0),
		"LeftLeg": Vector3(-0.045, 0.095, 0.0),
		"RightLeg": Vector3(0.045, 0.095, 0.0),
	}
	for pivot_name in pivots:
		var pivot := Node3D.new()
		pivot.name = pivot_name
		pivot.position = pivots[pivot_name]
		candidate_root.add_child(pivot)
		pivot.owner = candidate_root
	body.owner = candidate_root
	generated_asset.owner = candidate_root
	var final_bounds := Resolver.mesh_bounds(candidate_root, candidate_root.transform)
	if (final_bounds.size - target).length() > 0.003:
		candidate_root.free()
		_fail("MPFB final bounds do not meet the RoomScale package contract: %s" % final_bounds.size)
		return
	var packed := PackedScene.new()
	var pack_error := packed.pack(candidate_root)
	if pack_error != OK:
		candidate_root.free()
		_fail("PackedScene.pack returned %d" % pack_error)
		return
	var save_error := ResourceSaver.save(packed, destination_path)
	if save_error != OK:
		candidate_root.free()
		_fail("ResourceSaver.save returned %d" % save_error)
		return
	print("ROOMSCALE_MPFB_CITIZEN_V087_SCENE_PASS bounds=%s source_bounds=%s fit_scale=%s meshes=%d high_detail=%d distance_lod=%d switch_inches=5 bones=%d pivots=5" % [final_bounds.size, source_bounds.size, fit_scale, generated_asset.find_children("*", "MeshInstance3D", true, false).size(), high_detail_meshes, distance_lod_meshes, skeleton.get_bone_count()])
	candidate_root.free()
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_MPFB_CITIZEN_V087_SCENE_FAIL: " + message)
	quit(1)
