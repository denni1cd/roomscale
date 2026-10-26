extends SceneTree
## Recorded, deterministic grapple-art generator; it does not edit construction or traversal state.

const GrappleDetails := preload("res://scripts/visuals/grapple_details.gd")


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
	if String(brief.get("asset_id", "")) != "grapple":
		_fail("generator only accepts the stable grapple asset brief")
		return
	var refinement := String(recipe.get("parameters", {}).get("refinement", ""))
	if String(recipe.get("method", "")) != "godot_procedural_miniature_grapple" or refinement not in ["baseline_v1", "mechanical_readability_v2", "mechanical_readability_v3", "mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"]:
		_fail("unsupported grapple recipe method/refinement")
		return
	var asset := Node3D.new()
	asset.name = "GrappleCandidate"
	GrappleDetails.build_procedural(asset, "" if refinement == "baseline_v1" else refinement)
	_assign_owner(asset, asset)
	root.add_child(asset)
	await process_frame
	DirAccess.make_dir_recursive_absolute(output_directory)
	var output_path := output_directory.path_join("grapple.tscn")
	var packed := PackedScene.new()
	var error := packed.pack(asset)
	if error == OK:
		error = ResourceSaver.save(packed, output_path)
	if error != OK:
		_fail("could not save native candidate scene, Godot error=%d" % error)
		asset.free()
		return
	var part_count := asset.find_children("*", "MeshInstance3D", true, false).size()
	print("ROOMSCALE_ART_FACTORY_GENERATION_PASS method=%s refinement=%s path=%s mesh_parts=%d" % [recipe.method, refinement, output_path, part_count])
	asset.free()
	await process_frame
	quit(0)


func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_assign_owner(child, owner)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + message)
	quit(1)
