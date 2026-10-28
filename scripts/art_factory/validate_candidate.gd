extends SceneTree
## Technical gate for a single candidate resource; it does not alter gameplay state.

const Resolver := preload("res://scripts/visuals/visual_resolver.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var asset_path := OS.get_environment("ROOMSCALE_ART_FACTORY_ASSET_PATH")
	var brief_path := OS.get_environment("ROOMSCALE_ART_FACTORY_BRIEF")
	var output_path := OS.get_environment("ROOMSCALE_ART_FACTORY_VALIDATION_OUTPUT")
	var issues: Array[String] = []
	if asset_path.is_empty() or brief_path.is_empty() or output_path.is_empty():
		issues.append("asset path, brief path, and output path are required")
	if not issues.is_empty():
		push_error("ROOMSCALE_ART_FACTORY_VALIDATION_FAIL: " + "; ".join(issues))
		quit(1)
		return
	var brief: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(brief_path)) if not brief_path.is_empty() else {}
	if not brief is Dictionary:
		issues.append("ArtBrief must be a JSON object")
	var resource := load(asset_path) as PackedScene if not asset_path.is_empty() else null
	if resource == null:
		issues.append("Godot did not import the candidate as an instantiable PackedScene")
	var mesh_count := 0
	var surface_count := 0
	var triangle_count := 0
	var bounds := AABB()
	if resource != null:
		var root := resource.instantiate() as Node3D
		if root == null:
			issues.append("candidate scene root must be Node3D")
		else:
			# Include the PackedScene root so candidate-local axis/scale transforms
			# are measured in the same frame in which RoomScale renders the asset.
			bounds = Resolver.mesh_bounds(root, root.transform)
			for mesh_variant in root.find_children("*", "MeshInstance3D", true, false):
				var mesh_instance := mesh_variant as MeshInstance3D
				if mesh_instance.mesh == null:
					issues.append("mesh instance %s has no mesh" % mesh_instance.name)
					continue
				mesh_count += 1
				for surface_index in range(mesh_instance.mesh.get_surface_count()):
					surface_count += 1
					if mesh_instance.get_active_material(surface_index) == null:
						issues.append("mesh instance %s surface %d has no material" % [mesh_instance.name, surface_index])
					var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
					if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
						triangle_count += floori(float((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()) / 3.0)
					elif arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
						triangle_count += floori(float((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3.0)
			if mesh_count == 0 or surface_count == 0:
				issues.append("candidate needs at least one render mesh and surface")
			if not bounds.position.is_finite() or not bounds.size.is_finite() or minf(bounds.size.x, minf(bounds.size.y, bounds.size.z)) <= 0.0001:
				issues.append("candidate bounds must be finite and positive on all axes")
			var expected: Array = brief.get("intended_dimensions", [])
			if expected.size() == 3 and bounds.size.is_finite():
				var expected_size := Vector3(float(expected[0]), float(expected[1]), float(expected[2]))
				var ratios := Vector3(bounds.size.x / expected_size.x, bounds.size.y / expected_size.y, bounds.size.z / expected_size.z)
				var smallest := minf(ratios.x, minf(ratios.y, ratios.z))
				var largest := maxf(ratios.x, maxf(ratios.y, ratios.z))
				var tolerance := float(brief.get("technical_tolerances", {}).get("proportion_error", 0.20))
				if smallest <= 0.0 or largest / smallest - 1.0 > tolerance:
					issues.append("source proportions exceed brief tolerance: ratios=%s tolerance=%.3f" % [ratios, tolerance])
			root.free()
	var report := {
		"status": "pass" if issues.is_empty() else "fail",
		"asset_path": asset_path,
		"bounds": {"position": [bounds.position.x, bounds.position.y, bounds.position.z], "size": [bounds.size.x, bounds.size.y, bounds.size.z]},
		"mesh_count": mesh_count,
		"surface_count": surface_count,
		"triangle_count": triangle_count,
		"issues": issues,
		"engine": Engine.get_version_info().string,
	}
	var absolute_output := ProjectSettings.globalize_path(output_path) if output_path.begins_with("res://") else output_path
	var file := FileAccess.open(absolute_output, FileAccess.WRITE)
	if file == null:
		push_error("ART_FACTORY_VALIDATION_REPORT_WRITE_FAILED: %s" % absolute_output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")
	if issues.is_empty():
		print("ROOMSCALE_ART_FACTORY_VALIDATION_PASS asset=%s meshes=%d surfaces=%d triangles=%d bounds=%s" % [asset_path, mesh_count, surface_count, triangle_count, bounds.size])
		quit(0)
	else:
		push_error("ROOMSCALE_ART_FACTORY_VALIDATION_FAIL: %s" % "; ".join(issues))
		quit(1)
