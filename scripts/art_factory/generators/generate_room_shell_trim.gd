extends SceneTree
## Art Factory generator for a paired source-matched baseboard/crown profile sample.
## Runtime extents, wall locations, trim heights, and cutaway remain RoomDefinition-owned.

const TrimProfile := preload("res://scripts/visuals/room_shell_trim_profile.gd")
const MaterialLibrary := preload("res://scripts/visuals/material_library.gd")

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
	if String(recipe.get("method", "")) != "godot_room_shell_trim_profile":
		_fail("unsupported room-shell trim generator method")
		return
	if String(brief.get("asset_id", "")) != "room_shell_trim":
		_fail("generator supports only the stable room_shell_trim identity")
		return
	var parameters: Dictionary = recipe.get("parameters", {})
	var target_path := String(parameters.get("visual_director_target", ""))
	if target_path.is_empty() or not FileAccess.file_exists("res://" + target_path.trim_prefix("res://")):
		_fail("recipe must reference the approved Visual Director target")
		return
	var dimensions: Array = brief.get("intended_dimensions", [])
	if dimensions != [48.0, 5.0, 1.4]:
		_fail("the paired profile sample expects the 48 x 5 x 1.4 inch ArtBrief envelope")
		return

	var material_settings: Dictionary = parameters.get("material", {})
	var wood_color := Color(String(material_settings.get("base_color", "563a28")))
	var wood_roughness := clampf(float(material_settings.get("roughness", 0.68)), 0.0, 1.0)
	var wood := MaterialLibrary.get_material("wood", wood_color, wood_roughness).duplicate(true) as StandardMaterial3D
	wood.albedo_color = wood_color
	wood.roughness = wood_roughness
	var surface_detail := String(material_settings.get("surface_detail", "procedural_grain"))
	if surface_detail == "solid_matte":
		wood.albedo_texture = null
		wood.normal_texture = null
		wood.normal_scale = 0.0
		wood.uv1_triplanar = false
		wood.uv1_world_triplanar = false
	elif surface_detail == "procedural_grain":
		wood.uv1_triplanar = true
		wood.uv1_world_triplanar = true
		wood.uv1_scale = Vector3.ONE * float(material_settings.get("world_triplanar_scale", 0.12))
	elif surface_detail == "directional_low_frequency_grain":
		var grain_noise := FastNoiseLite.new()
		grain_noise.seed = 1701
		grain_noise.frequency = 0.055
		grain_noise.fractal_octaves = 2
		var grain_texture := NoiseTexture2D.new()
		grain_texture.width = 256
		grain_texture.height = 256
		grain_texture.seamless = true
		grain_texture.noise = grain_noise
		var grain_ramp := Gradient.new()
		var grain_min := clampf(float(material_settings.get("grain_min", 0.94)), 0.0, 1.0)
		grain_ramp.set_color(0, Color(grain_min, grain_min, grain_min))
		grain_ramp.set_color(1, Color.WHITE)
		grain_texture.color_ramp = grain_ramp
		wood.albedo_texture = grain_texture
		wood.normal_texture = null
		wood.normal_scale = 0.0
		wood.uv1_triplanar = true
		wood.uv1_world_triplanar = true
		wood.uv1_scale = Vector3(0.015, 0.04, 0.04)
	else:
		_fail("unsupported room-shell trim surface detail: " + surface_detail)
		return
	var root := Node3D.new()
	root.name = "RoomShellTrimProfileSet"
	root.set_meta("presentation_only", true)
	var baseboard := MeshInstance3D.new()
	baseboard.name = "BaseboardProfile24in"
	baseboard.mesh = TrimProfile.build_segment(24.0, 5.0, 1.4, "baseboard")
	baseboard.position.x = -12.0
	baseboard.material_override = wood.duplicate(true) as StandardMaterial3D
	root.add_child(baseboard)
	baseboard.owner = root
	var crown := MeshInstance3D.new()
	crown.name = "CrownProfile24in"
	crown.mesh = TrimProfile.build_segment(24.0, 5.0, 0.75, "crown")
	crown.position.x = 12.0
	crown.material_override = wood.duplicate(true) as StandardMaterial3D
	root.add_child(crown)
	crown.owner = root
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		_fail("could not pack the profile candidate, error=%d" % pack_error)
		root.free()
		return
	var scene_path := output_directory.path_join("asset.tscn")
	var save_error := ResourceSaver.save(packed, scene_path)
	if save_error != OK:
		_fail("could not save the profile candidate, error=%d" % save_error)
		root.free()
		return
	var record := {
		"asset_id": "room_shell_trim",
		"method": "godot_room_shell_trim_profile",
		"approved_visual_target": target_path,
		"profile_sections": [
			{"name": "baseboard", "length_inches": 24.0, "height_inches": 5.0, "depth_inches": 1.4},
			{"name": "crown", "length_inches": 24.0, "height_inches": 5.0, "interior_projection_inches": 0.75}
		],
		"material": {"family": "stained residential wood", "base_color": wood_color.to_html(false), "roughness": wood_roughness, "surface_detail": surface_detail, "grain_min": float(material_settings.get("grain_min", 0.0)), "world_triplanar_scale": float(material_settings.get("world_triplanar_scale", 0.0)), "anisotropic_triplanar_scale": [0.015, 0.04, 0.04]},
		"runtime_geometry": "RoomDefinition-driven segments using the same profile helper; no gameplay bounds or topology change",
		"outputs": ["asset.tscn", "generation-record.json"]
	}
	var file := FileAccess.open(output_directory.path_join("generation-record.json"), FileAccess.WRITE)
	if file == null:
		_fail("could not write the generation record")
		root.free()
		return
	file.store_string(JSON.stringify(record, "  ") + "\n")
	file.close()
	print("ROOMSCALE_ART_FACTORY_GENERATION_PASS asset=room_shell_trim bounds=48x5x1.4 scene=%s" % scene_path)
	root.free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_ART_FACTORY_GENERATION_FAIL: " + message)
	quit(1)
