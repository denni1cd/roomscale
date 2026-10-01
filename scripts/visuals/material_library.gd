extends RefCounted
## Shared lit materials and deterministic textures; no per-frame generation.
static var _cache: Dictionary = {}
static var _definitions: Dictionary = {}
static var _textures: Dictionary = {}
static var _loaded := false

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
	if category in ["wood", "canvas", "fabric", "rope", "leather", "stone"]:
		material.albedo_texture = _texture(category)
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3(0.006, 0.2, 0.18) if category == "wood" else Vector3.ONE * 0.5
	if properties.has("emission"):
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = float(properties.emission)
	_cache[key] = material
	return material

static func _texture(category: String) -> NoiseTexture2D:
	if _textures.has(category):
		return _textures[category]
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	var noise := FastNoiseLite.new()
	noise.seed = 317
	noise.frequency = 0.08 if category == "wood" else 0.28
	noise.fractal_octaves = 3
	texture.noise = noise
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.72, 0.72, 0.72))
	gradient.set_color(1, Color(1.0, 1.0, 1.0))
	texture.color_ramp = gradient
	_textures[category] = texture
	return texture
