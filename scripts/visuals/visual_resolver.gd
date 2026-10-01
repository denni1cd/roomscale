extends RefCounted
## Presentation-only semantic resolution; never supplies collision or navigation.

const CATALOG_PATH := "res://visual/catalog.json"
const Furniture := preload("res://scripts/visuals/furniture_recipes.gd")
var catalog: Dictionary = {}
var diagnostics: Array[String] = []


func _init() -> void:
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
	return recipe


func render(parent: Node3D, object: Dictionary, fallback: Callable) -> void:
	var recipe := resolve(object)
	parent.set_meta("visual_recipe", recipe.archetype)
	var path := String(recipe.get("asset", ""))
	if not path.is_empty() and _render_imported(parent, object, recipe):
		parent.set_meta("visual_source", path)
		print("ROOMSCALE_VISUAL_ASSET object=%s source=%s normalization=%s" % [parent.name, path, parent.get_meta("visual_normalization")])
		return
	if String(recipe.get("fallback", "")) == "detailed_furniture" and Furniture.build(parent, object, recipe):
		parent.set_meta("visual_source", "detailed_furniture")
		return
	parent.set_meta("visual_source", "procedural_fallback")
	fallback.call(parent, object)


func _render_imported(parent: Node3D, object: Dictionary, recipe: Dictionary) -> bool:
	var path := String(recipe.asset)
	if not path.begins_with("res://assets/") or path.get_extension().to_lower() not in ["glb", "gltf", "tscn"]:
		return _reject(path, "asset must be a project-local GLB, GLTF, or scene under assets/")
	if not ResourceLoader.exists(path):
		return _reject(path, "missing or not imported; run the asset import pipeline")
	var packed := load(path) as PackedScene
	if packed == null:
		return _reject(path, "resource is not an instantiable scene")
	var asset := packed.instantiate() as Node3D
	if asset == null:
		return _reject(path, "asset root must be Node3D")
	var wrapper := Node3D.new()
	wrapper.name = "ResolvedAsset"
	wrapper.add_child(asset)
	asset.rotation_degrees.y = float(recipe.get("yaw_degrees", 0.0))
	var bounds := mesh_bounds(wrapper)
	if not bounds.size.is_finite() or not bounds.position.is_finite() or bounds.size.x <= 0.00001 or bounds.size.y <= 0.00001 or bounds.size.z <= 0.00001:
		wrapper.free()
		return _reject(path, "nonzero mesh bounds required on all axes")
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


func _reject(path: String, reason: String) -> bool:
	var diagnostic := "VISUAL_ASSET_FALLBACK %s: %s" % [path, reason]
	diagnostics.append(diagnostic)
	push_warning(diagnostic)
	return false
