extends SceneTree
const Resolver := preload("res://scripts/visuals/visual_resolver.gd")

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var path := "res://assets/generated/writing_desk.glb"
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("ASSET_INVALID %s: Godot import did not produce a PackedScene" % path)
		quit(1)
		return
	var asset := packed.instantiate() as Node3D
	var bounds := Resolver.mesh_bounds(asset)
	var meshes := asset.find_children("*", "MeshInstance3D", true, false)
	var surfaces := 0
	for mesh in meshes:
		for index in range(mesh.mesh.get_surface_count()):
			if mesh.get_active_material(index) == null:
				push_error("ASSET_INVALID %s: unresolved material on %s surface %d" % [path, mesh.name, index])
				asset.free()
				quit(1)
				return
			surfaces += 1
	if meshes.is_empty() or not bounds.size.is_equal_approx(Vector3(68, 30, 34)):
		push_error("ASSET_INVALID %s: unexpected bounds=%s meshes=%s" % [path, bounds, meshes.size()])
		asset.free()
		quit(1)
		return
	asset.free()
	var resolver := Resolver.new()
	resolver.catalog.entries.desk.asset = path
	resolver.catalog.entries.desk.yaw_degrees = 90.0
	var wrapper := Node3D.new()
	resolver.render(wrapper, {"kind": "desk", "dimensions": [102, 45, 51]}, func(_parent, _object): push_error("ASSET_NORMALIZATION_FAILED: unexpected fallback"))
	var fitted := Resolver.mesh_bounds(wrapper)
	if not fitted.size.is_equal_approx(Vector3(102, 45, 51)) or absf(fitted.position.y) >= 0.001:
		push_error("ASSET_NORMALIZATION_FAILED: expected 102x45x51, floor pivot; got %s" % fitted)
		wrapper.free()
		quit(1)
		return
	wrapper.free()
	print("ROOMSCALE_ASSET_VALIDATION_PASS glb_import=true meshes=%d surfaces=%d bounds=%s yaw_and_scale_fit=true materials=true" % [meshes.size(), surfaces, bounds])
	quit()
