extends SceneTree
## Reproducible Art Factory generator for source-matched RoomDefinition surface materials.
## The sample mesh is presentation evidence only; runtime dimensions stay RoomDefinition-owned.

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
	if String(recipe.get("method", "")) != "godot_room_surface_pbr":
		_fail("unsupported room-surface generator method")
		return
	var asset_id := String(brief.get("asset_id", ""))
	if asset_id not in ["room_shell_floor", "room_shell_wall_finish"]:
		_fail("unsupported stable room surface id: %s" % asset_id)
		return
	var parameters: Dictionary = recipe.get("parameters", {})
	var target_path := String(parameters.get("visual_director_target", ""))
	if target_path.is_empty():
		_fail("recipe must name its approved Visual Director target")
		return
	var target_absolute := ProjectSettings.globalize_path("res://" + target_path.trim_prefix("res://"))
	var albedo_path := output_directory.path_join("albedo.png")
	var copy_error := DirAccess.copy_absolute(target_absolute, albedo_path)
	if copy_error != OK:
		_fail("could not copy approved albedo target, error=%d path=%s" % [copy_error, target_absolute])
		return
	var albedo_image := Image.new()
	var load_error := albedo_image.load(albedo_path)
	if load_error != OK:
		_fail("could not load approved albedo target, error=%d" % load_error)
		return
	albedo_image.convert(Image.FORMAT_RGBA8)
	var width := albedo_image.get_width()
	var height := albedo_image.get_height()
	if width < 64 or height < 64:
		_fail("approved texture resolution is too small: %d x %d" % [width, height])
		return

	var normal_image := albedo_image.duplicate()
	normal_image.bump_map_to_normal_map(float(parameters.get("bump_scale", 0.025)))
	normal_image.generate_mipmaps(true)
	var normal_path := output_directory.path_join("normal.png")
	if normal_image.save_png(normal_path) != OK:
		_fail("could not write normal map")
		return
	var roughness := clampf(float(parameters.get("roughness", 0.95)), 0.0, 1.0)
	var roughness_image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	roughness_image.fill(Color(roughness, roughness, roughness, 1.0))
	roughness_image.generate_mipmaps()
	var roughness_path := output_directory.path_join("roughness.png")
	if roughness_image.save_png(roughness_path) != OK:
		_fail("could not write roughness map")
		return

	albedo_image.generate_mipmaps()
	var albedo_texture := ImageTexture.create_from_image(albedo_image)
	var normal_texture := ImageTexture.create_from_image(normal_image)
	var roughness_texture := ImageTexture.create_from_image(roughness_image)
	var material := StandardMaterial3D.new()
	var tint_value: Variant = parameters.get("albedo_tint", [1.0, 1.0, 1.0])
	var albedo_tint := Color.WHITE
	if tint_value is Array and tint_value.size() == 3:
		albedo_tint = Color(float(tint_value[0]), float(tint_value[1]), float(tint_value[2]), 1.0)
	material.albedo_color = albedo_tint
	material.albedo_texture = albedo_texture
	material.roughness = roughness
	material.roughness_texture = roughness_texture
	material.normal_enabled = true
	material.normal_texture = normal_texture
	material.normal_scale = float(parameters.get("normal_scale", 0.08))
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	var repeat_inches := maxf(1.0, float(parameters.get("repeat_inches", 8.0)))
	material.uv1_scale = Vector3.ONE * (1.0 / repeat_inches)

	var dimensions: Array = brief.get("intended_dimensions", [])
	if dimensions.size() != 3:
		_fail("ArtBrief intended_dimensions must have three values")
		return
	var asset_root := Node3D.new()
	asset_root.name = "Generated_%s_SurfaceMaterial" % asset_id
	asset_root.set_meta("presentation_only", true)
	var surface := MeshInstance3D.new()
	surface.name = "RoomSurfaceSample"
	var box := BoxMesh.new()
	box.size = Vector3(float(dimensions[0]), float(dimensions[1]), float(dimensions[2]))
	surface.mesh = box
	surface.material_override = material
	asset_root.add_child(surface)
	surface.owner = asset_root
	var packed := PackedScene.new()
	var pack_error := packed.pack(asset_root)
	if pack_error != OK:
		_fail("could not pack surface candidate, error=%d" % pack_error)
		asset_root.free()
		return
	var scene_path := output_directory.path_join("asset.tscn")
	var save_error := ResourceSaver.save(packed, scene_path)
	if save_error != OK:
		_fail("could not save surface candidate, error=%d" % save_error)
		asset_root.free()
		return
	var generation_record := {
		"asset_id": asset_id,
		"method": recipe.method,
		"approved_visual_target": target_path,
		"sample_dimensions_inches": dimensions,
		"material": {
			"albedo": "approved target copied without repaint",
			"albedo_tint_linear": [albedo_tint.r, albedo_tint.g, albedo_tint.b],
			"roughness": roughness,
			"normal_map": "low-strength normal derived from the approved target via Image.bump_map_to_normal_map",
			"normal_scale": material.normal_scale,
			"world_repeat_inches": repeat_inches,
			"runtime_geometry": "existing RoomDefinition-driven floor/wall segments; candidate mesh is a material sample only"
		},
		"outputs": ["asset.tscn", "albedo.png", "normal.png", "roughness.png", "generation-record.json"]
	}
	var record_file := FileAccess.open(output_directory.path_join("generation-record.json"), FileAccess.WRITE)
	if record_file == null:
		_fail("could not write generation record")
		asset_root.free()
		return
	record_file.store_string(JSON.stringify(generation_record, "  ") + "\n")
	record_file.close()
	print("ROOMSCALE_ART_FACTORY_GENERATION_PASS asset=%s pixels=%d x %d scene=%s" % [asset_id, width, height, scene_path])
	asset_root.free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + message)
	quit(1)
