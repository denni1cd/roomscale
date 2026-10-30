extends RefCounted
## Shared lit materials and deterministic textures; no per-frame generation.
static var _cache: Dictionary = {}
static var _definitions: Dictionary = {}
static var _textures: Dictionary = {}
static var _normal_textures: Dictionary = {}
static var _loaded := false
static var _floor_cache: Dictionary = {}

static func floor_material(color: Color) -> ShaderMaterial:
	var key := color.to_html()
	if not _floor_cache.has(key):
		var material := ShaderMaterial.new()
		material.shader = preload("res://visual/floor_wood.gdshader")
		material.set_shader_parameter("timber_color", color)
		_floor_cache[key] = material
	return _floor_cache[key]

static func get_material(category: String, color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://visual/materials.json"))
		if parsed is Dictionary:
			_definitions = parsed
		else:
			push_warning("VISUAL_MATERIAL_FALLBACK: invalid material definitions; using lit defaults")
	var key := "%s:%s:%.3f" % [category, color.to_html(), roughness]
	if _cache.has(key):
		return _cache[key]
	var properties: Dictionary = _definitions.get(category, {})
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = float(properties.get("roughness", roughness))
	material.metallic = float(properties.get("metallic", 0.0))
	if category in ["wood", "floor_wood", "canvas", "fabric", "citizen_fabric", "rope", "leather", "stone", "paint", "living_organic"]:
		material.albedo_texture = _texture(category)
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3(0.06, 0.12, 0.10) if category == "wood" else Vector3.ONE * 0.5
		if category in ["paint", "living_organic", "stone", "wood", "floor_wood", "leather"]:
			material.normal_texture = _normal_texture(category)
			material.normal_scale = 0.025 if category == "paint" else (0.045 if category in ["wood", "floor_wood"] else 0.07)
		if category == "paint":
			material.uv1_scale = Vector3.ONE * 0.32
		if category == "living_organic":
			material.uv1_scale = Vector3.ONE * 0.42
		if category == "citizen_fabric":
			material.uv1_scale = Vector3.ONE * 2.0
			material.roughness = 0.9
		if category == "floor_wood":
			material.uv1_scale = Vector3(0.025, 0.08, 0.07)
			material.roughness = 0.92
	if properties.has("emission"):
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = float(properties.emission)
	_cache[key] = material
	return material

static func _normal_texture(category: String) -> Texture2D:
	if _normal_textures.has(category):
		return _normal_textures[category]
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.as_normal_map = true
	texture.bump_strength = 0.04 if category in ["paint", "stone"] else 0.08
	var noise := FastNoiseLite.new()
	noise.seed = 9143 if category == "paint" else 317
	noise.frequency = 0.16 if category == "paint" else (0.12 if category == "living_organic" else 0.08)
	noise.fractal_octaves = 3
	texture.noise = noise
	_normal_textures[category] = texture
	return texture

static func _texture(category: String) -> Texture2D:
	if _textures.has(category):
		return _textures[category]
	if category == "citizen_fabric":
		var weave := Image.create(128, 128, false, Image.FORMAT_RGB8)
		for y in range(128):
			var tile_y := floori(float(y) / 8.0)
			for x in range(128):
				var tile_x := floori(float(x) / 8.0)
				var warp_on_top := (tile_x + tile_y) % 2 == 0
				var thread_core := (y % 8 < 6) if warp_on_top else (x % 8 < 6)
				var thread_ridge := (x % 2 == 0) if warp_on_top else (y % 2 == 0)
				var value := 0.94 if not thread_core else (0.99 if thread_ridge else 0.965)
				weave.set_pixel(x, y, Color(value, value, value))
		var woven_texture := ImageTexture.create_from_image(weave)
		_textures[category] = woven_texture
		return woven_texture
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	var noise := FastNoiseLite.new()
	noise.seed = 9143 if category == "paint" else 317
	noise.frequency = 0.055 if category in ["wood", "floor_wood"] else (0.16 if category == "paint" else 0.28)
	noise.fractal_octaves = 3
	texture.noise = noise
	var gradient := Gradient.new()
	var shadow_value := Color(0.965, 0.965, 0.965) if category == "paint" else (Color(0.9, 0.9, 0.9) if category == "living_organic" else (Color(0.94, 0.94, 0.94) if category == "floor_wood" else Color(0.84, 0.84, 0.84)))
	gradient.set_color(0, shadow_value)
	gradient.set_color(1, Color(1.0, 1.0, 1.0))
	texture.color_ramp = gradient
	_textures[category] = texture
	return texture
