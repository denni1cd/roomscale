extends RefCounted
## Shared rounded meshes, small gears, and presentation-only assembly parts.
const Materials := preload("res://scripts/visuals/material_library.gd")
static var _meshes: Dictionary = {}

static func box(parent: Node3D, label: String, size: Vector3, at: Vector3, category: String, color: Color, bevel: float = 0.05) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	item.position = at
	item.mesh = rounded_box(size, bevel)
	item.material_override = Materials.get_material(category, color)
	parent.add_child(item)
	return item

static func rounded_box(size: Vector3, bevel: float) -> ArrayMesh:
	var key := "%s:%s" % [size, bevel]
	if _meshes.has(key):
		return _meshes[key]
	var half := size * 0.5
	var radius := minf(bevel, minf(half.x, minf(half.y, half.z)) * 0.45)
	var inner := half - Vector3.ONE * radius
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normals := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	for normal in normals:
		var u := Vector3.UP if absf(normal.y) < 0.5 else Vector3.RIGHT
		var v: Vector3 = normal.cross(u)
		for row in range(4):
			for col in range(4):
				var points: Array[Vector3] = []
				var shades: Array[Vector3] = []
				for pair in [Vector2(col, row), Vector2(col + 1, row), Vector2(col + 1, row + 1), Vector2(col, row + 1)]:
					var p: Vector3 = (normal + u * (pair.x * 0.5 - 1.0) + v * (pair.y * 0.5 - 1.0)) * half
					var closest := p.clamp(-inner, inner)
					var outward := (p - closest).normalized()
					points.append(closest + outward * radius)
					shades.append(outward)
				# Godot front faces use clockwise winding.
				for index in [0, 2, 1, 0, 3, 2]:
					surface.set_normal(shades[index])
					surface.set_uv(Vector2(points[index].x, points[index].z))
					surface.add_vertex(points[index])
	surface.index()
	var mesh := surface.commit()
	_meshes[key] = mesh
	return mesh

static func cylinder(parent: Node3D, label: String, radius: float, height: float, at: Vector3, category: String, color: Color, top: float = -1.0) -> MeshInstance3D:
	var key := "cylinder:%s:%s:%s" % [radius, height, top]
	if not _meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius if top < 0.0 else top
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 24
		_meshes[key] = mesh
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = _meshes[key]
	item.position = at
	item.material_override = Materials.get_material(category, color)
	parent.add_child(item)
	return item

static func gear(parent: Node3D, label: String, radius: float, at: Vector3, teeth: int = 12) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = at
	parent.add_child(root)
	cylinder(root, "Disk", radius * 0.8, radius * 0.18, Vector3.ZERO, "brass", Color("b99246"))
	cylinder(root, "Hub", radius * 0.22, radius * 0.3, Vector3.ZERO, "iron", Color("303b3e"))
	for index in range(teeth):
		var angle := TAU * index / teeth
		var tooth := box(root, "Tooth%d" % index, Vector3(radius * 0.28, radius * 0.2, radius * 0.22), Vector3(cos(angle) * radius * 0.83, 0, sin(angle) * radius * 0.83), "brass", Color("b99246"), radius * 0.025)
		tooth.rotation.y = -angle
	return root
