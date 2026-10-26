extends RefCounted
## Presentation-only semantic resolution; never supplies collision or navigation.

const CATALOG_PATH := "res://visual/catalog.json"
const Furniture := preload("res://scripts/visuals/furniture_recipes.gd")
const AssetRegistry := preload("res://scripts/visuals/asset_registry.gd")
var catalog: Dictionary = {}
var diagnostics: Array[String] = []
var registry: Variant


func _init(registry_path: String = "") -> void:
	registry = AssetRegistry.new(registry_path)
	diagnostics.append_array(registry.diagnostics)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if parsed is Dictionary and parsed.get("entries") is Dictionary:
		catalog = parsed
	else:
		diagnostics.append("VISUAL_CATALOG_INVALID: expected an entries dictionary; procedural fallback remains available")
		catalog = {"defaults": {}, "entries": {}}


func resolve(object: Dictionary) -> Dictionary:
	var appearance: Dictionary = object.get("appearance", {})
	var semantic := String(object.get("kind", "unknown")).to_lower()
	var archetype := String(appearance.get("archetype", semantic)).to_lower()
	var entries: Dictionary = catalog.get("entries", {})
	var recipe: Dictionary = catalog.get("defaults", {}).duplicate(true)
	# Appearance archetypes override semantic defaults, preserving photo inputs.
	recipe.merge(entries.get(archetype, entries.get(semantic, {})), true)
	recipe["semantic"] = semantic
	recipe["archetype"] = archetype
	recipe["appearance"] = appearance.duplicate(true)
	var stable_asset_id := String(appearance.get("asset_id", semantic)).to_lower()
	var registered: Dictionary = registry.lookup(stable_asset_id)
	if not registered.is_empty():
		recipe["asset"] = String(registered.resolved_path)
		recipe["asset_registry_id"] = stable_asset_id
		recipe["asset_registry_required"] = true
		recipe["asset_registry_error"] = String(registered.get("resolution_error", ""))
		recipe["asset_registry_candidate_id"] = String(registered.get("candidate_id", ""))
	return recipe


func render(parent: Node3D, object: Dictionary, fallback: Callable) -> void:
	if not registry.valid:
		_required_asset_failure(parent, "registry", "registry could not be read")
		return
	var recipe := resolve(object)
	parent.set_meta("visual_recipe", recipe.archetype)
	var path := String(recipe.get("asset", ""))
	var required := bool(recipe.get("asset_registry_required", false))
	parent.set_meta("visual_asset_id", String(recipe.get("asset_registry_id", recipe.get("semantic", ""))))
	if required and not String(recipe.get("asset_registry_error", "")).is_empty():
		_required_asset_failure(parent, String(recipe.asset_registry_id), String(recipe.asset_registry_error))
		return
	if not path.is_empty() and _render_imported(parent, object, recipe, required):
		parent.set_meta("visual_source", path)
		if required:
			parent.set_meta("visual_asset_candidate_id", String(recipe.get("asset_registry_candidate_id", "")))
		print("ROOMSCALE_VISUAL_ASSET object=%s source=%s normalization=%s" % [parent.name, path, parent.get_meta("visual_normalization")])
		return
	if required:
		_required_asset_failure(parent, String(recipe.asset_registry_id), "accepted asset could not be imported")
		return
	if String(recipe.get("fallback", "")) == "detailed_furniture" and Furniture.build(parent, object, recipe):
		parent.set_meta("visual_source", "detailed_furniture")
		return
	parent.set_meta("visual_source", "procedural_fallback")
	fallback.call(parent, object)


func _render_imported(parent: Node3D, object: Dictionary, recipe: Dictionary, required: bool = false) -> bool:
	var path := String(recipe.asset)
	if not (path.begins_with("res://assets/") or path.begins_with("res://art/")) or path.get_extension().to_lower() not in ["glb", "gltf", "tscn"]:
		return _reject(path, "asset must be a project-local GLB, GLTF, or scene under assets/ or art/", required)
	if not ResourceLoader.exists(path):
		return _reject(path, "missing or not imported; run the asset import pipeline", required)
	var packed := load(path) as PackedScene
	if packed == null:
		return _reject(path, "resource is not an instantiable scene", required)
	var asset := packed.instantiate() as Node3D
	if asset == null:
		return _reject(path, "asset root must be Node3D", required)
	var wrapper := Node3D.new()
	wrapper.name = "ResolvedAsset"
	wrapper.add_child(asset)
	asset.rotation_degrees.y = float(recipe.get("yaw_degrees", 0.0))
	var bounds := mesh_bounds(wrapper)
	if not bounds.size.is_finite() or not bounds.position.is_finite() or bounds.size.x <= 0.00001 or bounds.size.y <= 0.00001 or bounds.size.z <= 0.00001:
		wrapper.free()
		return _reject(path, "nonzero mesh bounds required on all axes", required)
	var dims: Array = object.dimensions
	var size := Vector3(float(dims[0]), float(dims[1]), float(dims[2]))
	wrapper.scale = size / bounds.size
	# Wrap the source: base-centered pivot, fitted dimensions, no source mutation.
	asset.position -= Vector3(bounds.position.x + bounds.size.x * 0.5, bounds.position.y, bounds.position.z + bounds.size.z * 0.5)
	parent.add_child(wrapper)
	parent.set_meta("visual_normalization", {"source_bounds": bounds, "fitted_dimensions": size})
	return true


static func mesh_bounds(node: Node3D, accumulated: Transform3D = Transform3D.IDENTITY) -> AABB:
	var result := AABB()
	var found := false
	for child in node.get_children():
		if not child is Node3D:
			continue
		var transform: Transform3D = accumulated * child.transform
		if child is MeshInstance3D and child.mesh != null:
			var local: AABB = transform * child.get_aabb()
			result = result.merge(local) if found else local
			found = true
		var descendants := mesh_bounds(child, transform)
		if descendants.size.length_squared() > 0.0:
			result = result.merge(descendants) if found else descendants
			found = true
	return result


func _reject(path: String, reason: String, required: bool = false) -> bool:
	var diagnostic := "ROOMSCALE_REQUIRED_VISUAL_ASSET_FAILURE %s: %s" % [path, reason] if required else "VISUAL_ASSET_FALLBACK %s: %s" % [path, reason]
	diagnostics.append(diagnostic)
	push_warning(diagnostic)
	return false


func _required_asset_failure(parent: Node3D, asset_id: String, reason: String) -> void:
	var diagnostic := "ROOMSCALE_REQUIRED_VISUAL_ASSET_FAILURE asset=%s: %s" % [asset_id, reason]
	parent.set_meta("visual_source", "required_asset_failure")
	parent.set_meta("visual_asset_error", diagnostic)
	if not diagnostics.has(diagnostic):
		diagnostics.append(diagnostic)
		push_warning(diagnostic)
