extends RefCounted
class_name RoomShellTrimProfile

## Presentation-only profile meshes scaled to the dimensions owned by RoomDefinition.

static func build_segment(length: float, height: float, depth: float, profile_name: String) -> ArrayMesh:
	if length <= 0.0 or height <= 0.0 or depth <= 0.0:
		return null
	var contour := _profile_points(profile_name)
	var triangles := Geometry2D.triangulate_polygon(contour)
	if triangles.is_empty():
		push_error("ROOMSCALE_TRIM_PROFILE_INVALID_CONTOUR profile=%s" % profile_name)
		return null
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_length := length * 0.5
	for index in range(contour.size()):
		var p0 := contour[index]
		var p1 := contour[(index + 1) % contour.size()]
		var start0 := _mesh_point(p0, -half_length, height, depth)
		var end0 := _mesh_point(p0, half_length, height, depth)
		var end1 := _mesh_point(p1, half_length, height, depth)
		var start1 := _mesh_point(p1, -half_length, height, depth)
		_add_triangle(surface, start0, end0, end1)
		_add_triangle(surface, start0, end1, start1)
	for index in range(0, triangles.size(), 3):
		var p0 := contour[triangles[index]]
		var p1 := contour[triangles[index + 1]]
		var p2 := contour[triangles[index + 2]]
		var left0 := _mesh_point(p0, -half_length, height, depth)
		var left1 := _mesh_point(p1, -half_length, height, depth)
		var left2 := _mesh_point(p2, -half_length, height, depth)
		var right0 := _mesh_point(p0, half_length, height, depth)
		var right1 := _mesh_point(p1, half_length, height, depth)
		var right2 := _mesh_point(p2, half_length, height, depth)
		_add_triangle(surface, left0, left1, left2)
		_add_triangle(surface, right0, right2, right1)
	surface.generate_normals()
	return surface.commit()


static func _profile_points(profile_name: String) -> PackedVector2Array:
	if profile_name == "crown":
		return PackedVector2Array([
			Vector2(0.00, 0.00), Vector2(0.28, 0.00), Vector2(0.34, 0.09),
			Vector2(0.48, 0.16), Vector2(0.64, 0.27), Vector2(0.78, 0.42),
			Vector2(0.88, 0.58), Vector2(0.96, 0.73), Vector2(1.00, 0.86),
			Vector2(0.94, 0.94), Vector2(0.84, 1.00), Vector2(0.00, 1.00),
		])
	return PackedVector2Array([
		Vector2(0.00, 0.00), Vector2(0.72, 0.00), Vector2(0.88, 0.07),
		Vector2(1.00, 0.12), Vector2(0.92, 0.19), Vector2(0.72, 0.22),
		Vector2(0.68, 0.31), Vector2(0.70, 0.72), Vector2(0.82, 0.78),
		Vector2(0.97, 0.86), Vector2(1.00, 0.94), Vector2(0.90, 1.00),
		Vector2(0.00, 1.00),
	])


static func _mesh_point(profile_point: Vector2, x: float, height: float, depth: float) -> Vector3:
	return Vector3(x, (profile_point.y - 0.5) * height, (profile_point.x - 0.5) * depth)


static func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
