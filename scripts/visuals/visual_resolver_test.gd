extends SceneTree

const Resolver := preload("res://scripts/visuals/visual_resolver.gd")
var fallback_count := 0

func _initialize() -> void:
	var resolver := Resolver.new()
	assert(resolver.diagnostics.is_empty(), "catalog must load")
	resolver.catalog.entries.desk = {"fallback": "existing_procedural", "material": "wood"}
	var fixture := {"kind": "desk", "dimensions": [68, 30, 34], "appearance": {"archetype": "desk"}}
	assert(resolver.resolve(fixture).material == "wood")
	var parent := Node3D.new()
	resolver.render(parent, fixture, _fallback)
	assert(fallback_count == 1 and parent.get_meta("visual_source") == "procedural_fallback")
	resolver.catalog.entries.desk.asset = "res://assets/does-not-exist.glb"
	resolver.render(parent, fixture, _fallback)
	assert(fallback_count == 2 and resolver.diagnostics.size() == 1, "missing asset must not block rendering")
	fixture.appearance.archetype = "unknown_photo_archetype"
	resolver.render(parent, fixture, _fallback)
	assert(fallback_count == 3, "unknown semantics retain fallback")
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2, 4, 6)
	instance.mesh = mesh
	instance.position = Vector3(10, 2, -8)
	parent.add_child(instance)
	var bounds := Resolver.mesh_bounds(parent)
	assert(bounds.size.is_equal_approx(mesh.size) and bounds.position.is_equal_approx(Vector3(9, 0, -11)))
	parent.free()
	print("ROOMSCALE_VISUAL_RESOLVER_PASS catalog=true missing_asset_fallback=true unknown_fallback=true transformed_bounds=true")
	quit()

func _fallback(_parent: Node3D, _object: Dictionary) -> void:
	fallback_count += 1
