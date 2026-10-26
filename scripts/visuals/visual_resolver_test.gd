extends SceneTree

const Resolver := preload("res://scripts/visuals/visual_resolver.gd")
const AssetRegistry := preload("res://scripts/visuals/asset_registry.gd")
var fallback_count := 0

func _initialize() -> void:
	var empty_registry_path := "user://poc25_art_factory_empty_registry.json"
	var empty_registry_file := FileAccess.open(empty_registry_path, FileAccess.WRITE)
	empty_registry_file.store_string(JSON.stringify({"schema_version": 1, "entries": {}}))
	empty_registry_file.close()
	var resolver := Resolver.new(empty_registry_path)
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
	var registry_path := "user://poc25_art_factory_test_registry.json"
	var registry_file := FileAccess.open(registry_path, FileAccess.WRITE)
	registry_file.store_string(JSON.stringify({"schema_version": 1, "entries": {
		"desk": {"status": "accepted", "path": "art/missing-candidate.glb", "candidate_id": "desk-v001", "sha256": "0".repeat(64)}
	}}))
	registry_file.close()
	var strict_resolver := Resolver.new(registry_path)
	fixture.appearance.archetype = "desk"
	strict_resolver.render(parent, fixture, _fallback)
	assert(fallback_count == 3, "a missing accepted candidate must never invoke the legacy fallback")
	assert(parent.get_meta("visual_source") == "required_asset_failure")
	assert(String(parent.get_meta("visual_asset_error")).contains("desk"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(registry_path))
	var eol_asset_path := "res://.godot/poc25-art-factory-eol-probe.tscn"
	var canonical_scene := "[gd_scene format=4]\n\n[node name=\"HashProbe\" type=\"Node3D\"]\n"
	var eol_asset_file := FileAccess.open(eol_asset_path, FileAccess.WRITE)
	assert(eol_asset_file != null, "temporary line-ending hash asset must be writable")
	eol_asset_file.store_buffer(canonical_scene.replace("\n", "\r\n").to_utf8_buffer())
	eol_asset_file.close()
	var eol_registry_path := "user://poc25_art_factory_eol_hash_registry.json"
	var eol_registry_file := FileAccess.open(eol_registry_path, FileAccess.WRITE)
	eol_registry_file.store_string(JSON.stringify({"schema_version": 1, "entries": {
		"probe": {"status": "accepted", "path": ".godot/poc25-art-factory-eol-probe.tscn", "candidate_id": "probe-v001", "sha256": canonical_scene.sha256_text()}
	}}))
	eol_registry_file.close()
	var eol_registry := AssetRegistry.new(eol_registry_path)
	var eol_entry := eol_registry.lookup("probe")
	assert(String(eol_entry.get("resolution_error", "")).is_empty(), "CRLF checkout must verify against canonical LF asset hash")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(eol_registry_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(eol_asset_path))
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2, 4, 6)
	instance.mesh = mesh
	instance.position = Vector3(10, 2, -8)
	parent.add_child(instance)
	var bounds := Resolver.mesh_bounds(parent)
	assert(bounds.size.is_equal_approx(mesh.size) and bounds.position.is_equal_approx(Vector3(9, 0, -11)))
	parent.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(empty_registry_path))
	print("ROOMSCALE_VISUAL_RESOLVER_PASS catalog=true legacy_fallback=true required_asset_failure_visible=true transformed_bounds=true crlf_hash_normalization=true")
	quit()

func _fallback(_parent: Node3D, _object: Dictionary) -> void:
	fallback_count += 1
