extends Node3D

func _ready() -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.1882353, 0.227451, 0.239216, 0.58)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.08
	glass.roughness = 0.08
	glass.rim_enabled = true
	glass.rim = 0.38
	glass.rim_tint = 0.8
	glass.clearcoat_enabled = true
	glass.clearcoat = 0.98
	glass.clearcoat_roughness = 0.08

	var graphite := StandardMaterial3D.new()
	graphite.albedo_color = Color(0.1411765, 0.164706, 0.172549)
	graphite.metallic = 0.82
	graphite.roughness = 0.28

	var satin := StandardMaterial3D.new()
	satin.albedo_color = Color(0.572549, 0.615686, 0.635294)
	satin.metallic = 0.85
	satin.roughness = 0.24

	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.066667, 0.078431, 0.086275)
	rubber.metallic = 0.02
	rubber.roughness = 0.82

	var assigned := 0
	for item in find_children("*", "MeshInstance3D", true, false):
		var mesh := item as MeshInstance3D
		var label := mesh.name.to_lower().replace("_", " ")
		mesh.layers = 2
		if label.contains("desktop") or label.contains("smoked glass"):
			mesh.material_override = glass
		elif label.contains("leveler") or label.contains("isolation pad"):
			mesh.material_override = rubber
		elif label.contains("fastener"):
			mesh.material_override = satin
		else:
			mesh.material_override = graphite
		assigned += 1
	if assigned != 22:
		push_error("Visual Director material assignment expected 22 meshes, found %d" % assigned)
	else:
		print("ROOMSCALE_VISUAL_DIRECTOR_NATIVE_MATERIALS_PASS meshes=%d" % assigned)
