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
	item.set_meta("roomscale_material_category", category)
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
	item.set_meta("roomscale_material_category", category)
	parent.add_child(item)
	return item


static func lathe_profile(
	parent: Node3D,
	label: String,
	start: Vector3,
	finish: Vector3,
	profile: Array[Vector2],
	category: String,
	color: Color,
	radial_segments: int = 32
) -> MeshInstance3D:
	"""Build a turned member from normalized-height/radius stations and align it between endpoints."""
	var direction := finish - start
	var length := direction.length()
	if length < 0.001 or profile.size() < 2:
		return null
	var cache_key := "lathe:%s:%s:%d" % [length, profile, radial_segments]
	if not _meshes.has(cache_key):
		var samples: Array[Vector2] = []
		for index in range(profile.size() - 1):
			var p0: Vector2 = profile[maxi(index - 1, 0)]
			var p1: Vector2 = profile[index]
			var p2: Vector2 = profile[index + 1]
			var p3: Vector2 = profile[mini(index + 2, profile.size() - 1)]
			for step in range(4):
				var t := float(step) / 4.0
				var t2 := t * t
				var t3 := t2 * t
				var radius := 0.5 * (
					2.0 * p1.y
					+ (-p0.y + p2.y) * t
					+ (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2
					+ (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3
				)
				samples.append(Vector2(lerpf(p1.x, p2.x, t), maxf(0.025, radius)))
		samples.append(profile[profile.size() - 1])
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for ring in range(samples.size() - 1):
			var lower := samples[ring]
			var upper := samples[ring + 1]
			for segment in range(radial_segments):
				var angle0 := TAU * float(segment) / float(radial_segments)
				var angle1 := TAU * float(segment + 1) / float(radial_segments)
				var radial0 := Vector3(cos(angle0), 0.0, sin(angle0))
				var radial1 := Vector3(cos(angle1), 0.0, sin(angle1))
				var lower0 := Vector3(radial0.x * lower.y, (lower.x - 0.5) * length, radial0.z * lower.y)
				var lower1 := Vector3(radial1.x * lower.y, (lower.x - 0.5) * length, radial1.z * lower.y)
				var upper0 := Vector3(radial0.x * upper.y, (upper.x - 0.5) * length, radial0.z * upper.y)
				var upper1 := Vector3(radial1.x * upper.y, (upper.x - 0.5) * length, radial1.z * upper.y)
				# Godot uses clockwise front faces; this order emits outward-facing triangles.
				for point in [lower0, upper1, upper0, lower0, lower1, upper1]:
					var radial := Vector3(point.x, 0.0, point.z).normalized()
					surface.set_normal(radial)
					surface.set_uv(Vector2(atan2(radial.z, radial.x) / TAU, point.y / length + 0.5))
					surface.add_vertex(point)
		# Cap only the two terminal rings; intermediate caps would create seams.
		var bottom := samples[0]
		var top := samples[samples.size() - 1]
		for segment in range(radial_segments):
			var angle0 := TAU * float(segment) / float(radial_segments)
			var angle1 := TAU * float(segment + 1) / float(radial_segments)
			var p0 := Vector3(cos(angle0) * bottom.y, (bottom.x - 0.5) * length, sin(angle0) * bottom.y)
			var p1 := Vector3(cos(angle1) * bottom.y, (bottom.x - 0.5) * length, sin(angle1) * bottom.y)
			var q0 := Vector3(cos(angle0) * top.y, (top.x - 0.5) * length, sin(angle0) * top.y)
			var q1 := Vector3(cos(angle1) * top.y, (top.x - 0.5) * length, sin(angle1) * top.y)
			_append_triangle(surface, Vector3(0.0, (bottom.x - 0.5) * length, 0.0), Vector3.DOWN, Vector2(0.5, 0.5), p0, Vector3.DOWN, Vector2(0.0, 0.0), p1, Vector3.DOWN, Vector2(1.0, 0.0))
			_append_triangle(surface, Vector3(0.0, (top.x - 0.5) * length, 0.0), Vector3.UP, Vector2(0.5, 0.5), q1, Vector3.UP, Vector2(1.0, 0.0), q0, Vector3.UP, Vector2(0.0, 0.0))
		_meshes[cache_key] = surface.commit()
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = _meshes[cache_key]
	item.position = (start + finish) * 0.5
	item.quaternion = Quaternion(Vector3.UP, direction.normalized())
	item.material_override = Materials.get_material(category, color)
	item.set_meta("roomscale_material_category", category)
	parent.add_child(item)
	return item


static func profiled_beam(
	parent: Node3D,
	label: String,
	start: Vector3,
	finish: Vector3,
	profile: Array[Vector3],
	category: String,
	color: Color,
	corner_chamfer: float = 0.12
) -> MeshInstance3D:
	"""Create a fitted rectangular beam with eased corners and tenon shoulders at its ends."""
	var direction := finish - start
	var length := direction.length()
	if length < 0.001 or profile.size() < 2:
		return null
	var cache_key := "profiled-beam:%s:%s:%s" % [length, profile, corner_chamfer]
	if not _meshes.has(cache_key):
		var stations: Array[Vector3] = []
		for index in range(profile.size() - 1):
			var p0: Vector3 = profile[maxi(index - 1, 0)]
			var p1: Vector3 = profile[index]
			var p2: Vector3 = profile[index + 1]
			var p3: Vector3 = profile[mini(index + 2, profile.size() - 1)]
			for step in range(4):
				var t := float(step) / 4.0
				var t2 := t * t
				var t3 := t2 * t
				var station := Vector3.ZERO
				for axis in range(3):
					station[axis] = 0.5 * (
						2.0 * p1[axis]
						+ (-p0[axis] + p2[axis]) * t
						+ (2.0 * p0[axis] - 5.0 * p1[axis] + 4.0 * p2[axis] - p3[axis]) * t2
						+ (-p0[axis] + 3.0 * p1[axis] - 3.0 * p2[axis] + p3[axis]) * t3
					)
				station.y = maxf(0.04, station.y)
				station.z = maxf(0.04, station.z)
				stations.append(station)
		stations.append(profile[profile.size() - 1])
		var section_count := 8
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for station_index in range(stations.size() - 1):
			var lower := stations[station_index]
			var upper := stations[station_index + 1]
			var lower_ring := _profiled_beam_ring(lower, length, corner_chamfer)
			var upper_ring := _profiled_beam_ring(upper, length, corner_chamfer)
			for section in range(section_count):
				var next := (section + 1) % section_count
				var a: Vector3 = lower_ring[section]
				var b: Vector3 = lower_ring[next]
				var c: Vector3 = upper_ring[next]
				var d: Vector3 = upper_ring[section]
				var n_a := Vector3(a.x / lower.y, 0.0, a.z / lower.z).normalized()
				var n_b := Vector3(b.x / lower.y, 0.0, b.z / lower.z).normalized()
				var n_c := Vector3(c.x / upper.y, 0.0, c.z / upper.z).normalized()
				var n_d := Vector3(d.x / upper.y, 0.0, d.z / upper.z).normalized()
				var outward := (n_a + n_b + n_c + n_d).normalized()
				var uv_a := Vector2(float(section) / section_count, lower.x)
				var uv_b := Vector2(float(next) / section_count, lower.x)
				var uv_c := Vector2(float(next) / section_count, upper.x)
				var uv_d := Vector2(float(section) / section_count, upper.x)
				if (d - a).cross(c - a).dot(outward) >= 0.0:
					_append_triangle(surface, a, n_a, uv_a, d, n_d, uv_d, c, n_c, uv_c)
					_append_triangle(surface, a, n_a, uv_a, c, n_c, uv_c, b, n_b, uv_b)
				else:
					_append_triangle(surface, a, n_a, uv_a, c, n_c, uv_c, d, n_d, uv_d)
					_append_triangle(surface, a, n_a, uv_a, b, n_b, uv_b, c, n_c, uv_c)
		var bottom := _profiled_beam_ring(stations[0], length, corner_chamfer)
		var top := _profiled_beam_ring(stations[stations.size() - 1], length, corner_chamfer)
		var bottom_center := Vector3(0.0, (stations[0].x - 0.5) * length, 0.0)
		var top_center := Vector3(0.0, (stations[stations.size() - 1].x - 0.5) * length, 0.0)
		for section in range(section_count):
			var next := (section + 1) % section_count
			_append_triangle(surface, bottom_center, Vector3.DOWN, Vector2(0.5, 0.5), bottom[section], Vector3.DOWN, Vector2(0.0, 0.0), bottom[next], Vector3.DOWN, Vector2(1.0, 0.0))
			_append_triangle(surface, top_center, Vector3.UP, Vector2(0.5, 0.5), top[next], Vector3.UP, Vector2(1.0, 0.0), top[section], Vector3.UP, Vector2(0.0, 0.0))
		_meshes[cache_key] = surface.commit()
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = _meshes[cache_key]
	item.position = (start + finish) * 0.5
	item.quaternion = Quaternion(Vector3.UP, direction.normalized())
	item.material_override = Materials.get_material(category, color)
	item.set_meta("roomscale_material_category", category)
	parent.add_child(item)
	return item


static func _profiled_beam_ring(station: Vector3, length: float, corner_chamfer: float) -> PackedVector3Array:
	var half_width := station.y
	var half_depth := station.z
	var cut := minf(corner_chamfer, minf(half_width, half_depth) * 0.45)
	var section := PackedVector2Array([
		Vector2(-half_width + cut, -half_depth), Vector2(half_width - cut, -half_depth),
		Vector2(half_width, -half_depth + cut), Vector2(half_width, half_depth - cut),
		Vector2(half_width - cut, half_depth), Vector2(-half_width + cut, half_depth),
		Vector2(-half_width, half_depth - cut), Vector2(-half_width, -half_depth + cut)
	])
	var result := PackedVector3Array()
	for point in section:
		result.append(Vector3(point.x, (station.x - 0.5) * length, point.y))
	return result


static func raised_panel(
	parent: Node3D,
	label: String,
	width: float,
	height: float,
	thickness: float,
	at: Vector3,
	category: String,
	color: Color,
	corner_chamfer: float = 0.22
) -> MeshInstance3D:
	"""Create a routed panel with a beveled perimeter and a subtly raised center field."""
	var cache_key := "raised-panel:%s:%s:%s:%s:%s" % [width, height, thickness, corner_chamfer, color.to_html()]
	if not _meshes.has(cache_key):
		var sections: Array[Vector2] = [Vector2(1.0, -0.5), Vector2(1.0, 0.10), Vector2(0.94, 0.32), Vector2(0.82, 0.50)]
		var loops: Array[PackedVector3Array] = []
		for section in sections:
			var half_width := width * 0.5 * section.x
			var half_height := height * 0.5 * section.x
			var cut := minf(corner_chamfer, minf(half_width, half_height) * 0.45)
			var outline := PackedVector2Array([
				Vector2(-half_width + cut, -half_height), Vector2(half_width - cut, -half_height),
				Vector2(half_width, -half_height + cut), Vector2(half_width, half_height - cut),
				Vector2(half_width - cut, half_height), Vector2(-half_width + cut, half_height),
				Vector2(-half_width, half_height - cut), Vector2(-half_width, -half_height + cut)
			])
			var loop := PackedVector3Array()
			for point in outline:
				loop.append(Vector3(point.x, point.y, section.y * thickness))
			loops.append(loop)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for ring in range(loops.size() - 1):
			for index in range(8):
				var next := (index + 1) % 8
				var outer0: Vector3 = loops[ring][index]
				var outer1: Vector3 = loops[ring][next]
				var inner0: Vector3 = loops[ring + 1][index]
				var inner1: Vector3 = loops[ring + 1][next]
				var middle := (outer0 + outer1 + inner0 + inner1) * 0.25
				var normal := Vector3(middle.x / maxf(width * 0.5, 0.01), middle.y / maxf(height * 0.5, 0.01), 0.62).normalized()
				_append_triangle(surface, outer0, normal, Vector2(0.0, 0.0), outer1, normal, Vector2(1.0, 0.0), inner1, normal, Vector2(1.0, 1.0))
				_append_triangle(surface, outer0, normal, Vector2(0.0, 0.0), inner1, normal, Vector2(1.0, 1.0), inner0, normal, Vector2(0.0, 1.0))
		var center_front := Vector3(0.0, 0.0, thickness * 0.50)
		for index in range(8):
			var next := (index + 1) % 8
			_append_triangle(surface, center_front, Vector3.BACK, Vector2(0.5, 0.5), loops[loops.size() - 1][next], Vector3.BACK, Vector2(1.0, 1.0), loops[loops.size() - 1][index], Vector3.BACK, Vector2(0.0, 1.0))
		var back_center := Vector3(0.0, 0.0, -thickness * 0.50)
		for index in range(8):
			var next := (index + 1) % 8
			_append_triangle(surface, back_center, Vector3.FORWARD, Vector2(0.5, 0.5), loops[0][index], Vector3.FORWARD, Vector2(0.0, 1.0), loops[0][next], Vector3.FORWARD, Vector2(1.0, 1.0))
		_meshes[cache_key] = surface.commit()
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = _meshes[cache_key]
	item.position = at
	item.material_override = Materials.get_material(category, color)
	item.set_meta("roomscale_material_category", category)
	parent.add_child(item)
	return item


static func elliptical_profile(
	parent: Node3D,
	label: String,
	start: Vector3,
	finish: Vector3,
	profile: Array[Vector3],
	category: String,
	color: Color,
	radial_segments: int = 32
) -> MeshInstance3D:
	"""Build a turned member with independent width and depth radii at each height."""
	var direction := finish - start
	var length := direction.length()
	if length < 0.001 or profile.size() < 2:
		return null
	var cache_key := "ellipse-profile:%s:%s:%d" % [length, profile, radial_segments]
	if not _meshes.has(cache_key):
		var samples: Array[Vector3] = []
		for index in range(profile.size() - 1):
			var p0: Vector3 = profile[maxi(index - 1, 0)]
			var p1: Vector3 = profile[index]
			var p2: Vector3 = profile[index + 1]
			var p3: Vector3 = profile[mini(index + 2, profile.size() - 1)]
			for step in range(4):
				var t := float(step) / 4.0
				var t2 := t * t
				var t3 := t2 * t
				var station := Vector3.ZERO
				for axis in range(3):
					station[axis] = 0.5 * (
						2.0 * p1[axis]
						+ (-p0[axis] + p2[axis]) * t
						+ (2.0 * p0[axis] - 5.0 * p1[axis] + 4.0 * p2[axis] - p3[axis]) * t2
						+ (-p0[axis] + 3.0 * p1[axis] - 3.0 * p2[axis] + p3[axis]) * t3
					)
				station.y = maxf(0.025, station.y)
				station.z = maxf(0.025, station.z)
				samples.append(station)
		samples.append(profile[profile.size() - 1])
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for ring in range(samples.size() - 1):
			var lower := samples[ring]
			var upper := samples[ring + 1]
			for segment in range(radial_segments):
				var angle0 := TAU * float(segment) / float(radial_segments)
				var angle1 := TAU * float(segment + 1) / float(radial_segments)
				var radial0 := Vector3(cos(angle0), 0.0, sin(angle0))
				var radial1 := Vector3(cos(angle1), 0.0, sin(angle1))
				var lower0 := Vector3(radial0.x * lower.y, (lower.x - 0.5) * length, radial0.z * lower.z)
				var lower1 := Vector3(radial1.x * lower.y, (lower.x - 0.5) * length, radial1.z * lower.z)
				var upper0 := Vector3(radial0.x * upper.y, (upper.x - 0.5) * length, radial0.z * upper.z)
				var upper1 := Vector3(radial1.x * upper.y, (upper.x - 0.5) * length, radial1.z * upper.z)
				for point in [lower0, upper1, upper0, lower0, lower1, upper1]:
					var local_normal := Vector3(point.x / maxf(lower.y, 0.025), 0.0, point.z / maxf(lower.z, 0.025)).normalized()
					surface.set_normal(local_normal)
					surface.set_uv(Vector2(atan2(local_normal.z, local_normal.x) / TAU, point.y / length + 0.5))
					surface.add_vertex(point)
			for segment in range(radial_segments):
				var angle0 := TAU * float(segment) / float(radial_segments)
				var angle1 := TAU * float(segment + 1) / float(radial_segments)
				var lower0 := Vector3(cos(angle0) * lower.y, (lower.x - 0.5) * length, sin(angle0) * lower.z)
				var lower1 := Vector3(cos(angle1) * lower.y, (lower.x - 0.5) * length, sin(angle1) * lower.z)
				var upper0 := Vector3(cos(angle0) * upper.y, (upper.x - 0.5) * length, sin(angle0) * upper.z)
				var upper1 := Vector3(cos(angle1) * upper.y, (upper.x - 0.5) * length, sin(angle1) * upper.z)
				_append_triangle(surface, Vector3(0.0, (lower.x - 0.5) * length, 0.0), Vector3.DOWN, Vector2(0.5, 0.5), lower0, Vector3.DOWN, Vector2(0.0, 0.0), lower1, Vector3.DOWN, Vector2(1.0, 0.0))
				_append_triangle(surface, Vector3(0.0, (upper.x - 0.5) * length, 0.0), Vector3.UP, Vector2(0.5, 0.5), upper1, Vector3.UP, Vector2(1.0, 0.0), upper0, Vector3.UP, Vector2(0.0, 0.0))
		_meshes[cache_key] = surface.commit()
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = _meshes[cache_key]
	item.position = (start + finish) * 0.5
	item.quaternion = Quaternion(Vector3.UP, direction.normalized())
	item.material_override = Materials.get_material(category, color)
	item.set_meta("roomscale_material_category", category)
	parent.add_child(item)
	return item


static func swept_oval(
	parent: Node3D,
	label: String,
	path: Array[Vector3],
	radius_y: float,
	radius_z: float,
	category: String,
	color: Color,
	radial_segments: int = 16
) -> MeshInstance3D:
	"""Sweep an oval section along a curved path to author shaped rails and rails with a real bow."""
	if path.size() < 2:
		return null
	var cache_key := "sweep:%s:%s:%s:%d" % [path, radius_y, radius_z, radial_segments]
	if not _meshes.has(cache_key):
		var rings: Array[PackedVector3Array] = []
		var normals: Array[PackedVector3Array] = []
		for path_index in range(path.size()):
			var before: Vector3 = path[maxi(path_index - 1, 0)]
			var after: Vector3 = path[mini(path_index + 1, path.size() - 1)]
			var tangent := (after - before).normalized()
			var depth_axis := Vector3.FORWARD
			if absf(tangent.dot(depth_axis)) > 0.94:
				depth_axis = Vector3.RIGHT
			var up_axis := tangent.cross(depth_axis).normalized()
			depth_axis = up_axis.cross(tangent).normalized()
			var ring: PackedVector3Array = []
			var ring_normals: PackedVector3Array = []
			for segment in range(radial_segments):
				var angle := TAU * float(segment) / float(radial_segments)
				var depth_component := cos(angle)
				var up_component := sin(angle)
				var radial := depth_axis * depth_component + up_axis * up_component
				var point := path[path_index] + depth_axis * (depth_component * radius_z) + up_axis * (up_component * radius_y)
				var normal := (depth_axis * (depth_component / radius_z) + up_axis * (up_component / radius_y)).normalized()
				ring.append(point)
				ring_normals.append(normal if normal.length_squared() > 0.0 else radial.normalized())
			rings.append(ring)
			normals.append(ring_normals)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for ring_index in range(path.size() - 1):
			for segment in range(radial_segments):
				var next_segment := (segment + 1) % radial_segments
				var a: Vector3 = rings[ring_index][segment]
				var b: Vector3 = rings[ring_index + 1][segment]
				var c: Vector3 = rings[ring_index + 1][next_segment]
				var d: Vector3 = rings[ring_index][next_segment]
				var normal_a: Vector3 = normals[ring_index][segment]
				var normal_b: Vector3 = normals[ring_index + 1][segment]
				var normal_c: Vector3 = normals[ring_index + 1][next_segment]
				var normal_d: Vector3 = normals[ring_index][next_segment]
				var outward := normal_a + normal_b + normal_c + normal_d
				var uv0 := Vector2(float(segment) / radial_segments, float(ring_index) / (path.size() - 1))
				var uv1 := Vector2(float(next_segment) / radial_segments, float(ring_index) / (path.size() - 1))
				var uv2 := Vector2(float(next_segment) / radial_segments, float(ring_index + 1) / (path.size() - 1))
				var uv3 := Vector2(float(segment) / radial_segments, float(ring_index + 1) / (path.size() - 1))
				if (b - a).cross(c - a).dot(outward) >= 0.0:
					_append_triangle(surface, a, normal_a, uv0, b, normal_b, uv3, c, normal_c, uv2)
					_append_triangle(surface, a, normal_a, uv0, c, normal_c, uv2, d, normal_d, uv1)
				else:
					_append_triangle(surface, a, normal_a, uv0, c, normal_c, uv2, b, normal_b, uv3)
					_append_triangle(surface, a, normal_a, uv0, d, normal_d, uv1, c, normal_c, uv2)
		_meshes[cache_key] = surface.commit()
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = _meshes[cache_key]
	item.material_override = Materials.get_material(category, color)
	item.set_meta("roomscale_material_category", category)
	parent.add_child(item)
	return item


static func dished_seat(
	parent: Node3D,
	label: String,
	width: float,
	depth: float,
	top_y: float,
	thickness: float,
	dish_depth: float,
	category: String,
	color: Color
) -> MeshInstance3D:
	"""Create one shaped slab with a dished top, softened superellipse perimeter, and solid sides."""
	var cache_key := "dished-seat:%s:%s:%s:%s:%s" % [width, depth, top_y, thickness, dish_depth]
	if not _meshes.has(cache_key):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var radial_steps := 10
		var radial_segments := 48
		var center := Vector3(0.0, top_y - dish_depth, 0.0)
		for ring in range(radial_steps):
			var inner_r := float(ring) / radial_steps
			var outer_r := float(ring + 1) / radial_steps
			for segment in range(radial_segments):
				var angle0 := TAU * float(segment) / radial_segments
				var angle1 := TAU * float(segment + 1) / radial_segments
				var a := _seat_surface_point(width, depth, inner_r, angle0, top_y, dish_depth)
				var b := _seat_surface_point(width, depth, outer_r, angle0, top_y, dish_depth)
				var c := _seat_surface_point(width, depth, outer_r, angle1, top_y, dish_depth)
				var d := _seat_surface_point(width, depth, inner_r, angle1, top_y, dish_depth)
				if ring == 0:
					_append_triangle(surface, center, Vector3.UP, Vector2(0.5, 0.5), c, _seat_normal(c, width, depth, dish_depth), Vector2(1.0, 0.0), b, _seat_normal(b, width, depth, dish_depth), Vector2(1.0, 1.0))
				else:
					_append_triangle(surface, a, _seat_normal(a, width, depth, dish_depth), Vector2(inner_r, angle0 / TAU), c, _seat_normal(c, width, depth, dish_depth), Vector2(outer_r, angle1 / TAU), b, _seat_normal(b, width, depth, dish_depth), Vector2(outer_r, angle0 / TAU))
					_append_triangle(surface, a, _seat_normal(a, width, depth, dish_depth), Vector2(inner_r, angle0 / TAU), d, _seat_normal(d, width, depth, dish_depth), Vector2(inner_r, angle1 / TAU), c, _seat_normal(c, width, depth, dish_depth), Vector2(outer_r, angle1 / TAU))
		var edge_profile: Array[Vector2] = [
			Vector2(1.0, 0.0), Vector2(0.994, 0.05), Vector2(0.982, 0.13),
			Vector2(0.966, 0.25), Vector2(0.955, 0.39), Vector2(0.955, thickness - 0.16),
			Vector2(0.966, thickness)
		]
		for ring in range(edge_profile.size() - 1):
			var upper := edge_profile[ring]
			var lower := edge_profile[ring + 1]
			for segment in range(radial_segments):
				var angle0 := TAU * float(segment) / radial_segments
				var angle1 := TAU * float(segment + 1) / radial_segments
				var radial0 := Vector3(cos(angle0), 0.0, sin(angle0)).normalized()
				var radial1 := Vector3(cos(angle1), 0.0, sin(angle1)).normalized()
				var upper0 := _seat_surface_point(width, depth, upper.x, angle0, top_y - upper.y, 0.0)
				var upper1 := _seat_surface_point(width, depth, upper.x, angle1, top_y - upper.y, 0.0)
				var lower0 := _seat_surface_point(width, depth, lower.x, angle0, top_y - lower.y, 0.0)
				var lower1 := _seat_surface_point(width, depth, lower.x, angle1, top_y - lower.y, 0.0)
				var normal0 := (radial0 + Vector3.UP * (0.42 if ring < 3 else 0.0)).normalized()
				var normal1 := (radial1 + Vector3.UP * (0.42 if ring < 3 else 0.0)).normalized()
				_append_triangle(surface, upper0, normal0, Vector2(0.0, 1.0), upper1, normal1, Vector2(1.0, 1.0), lower1, normal1, Vector2(1.0, 0.0))
				_append_triangle(surface, upper0, normal0, Vector2(0.0, 1.0), lower1, normal1, Vector2(1.0, 0.0), lower0, normal0, Vector2(0.0, 0.0))
		var bottom_center := Vector3(0.0, top_y - thickness, 0.0)
		for segment in range(radial_segments):
			var angle0 := TAU * float(segment) / radial_segments
			var angle1 := TAU * float(segment + 1) / radial_segments
			var bottom0 := _seat_surface_point(width * 0.965, depth * 0.965, 1.0, angle0, top_y - thickness, 0.0)
			var bottom1 := _seat_surface_point(width * 0.965, depth * 0.965, 1.0, angle1, top_y - thickness, 0.0)
			_append_triangle(surface, bottom_center, Vector3.DOWN, Vector2(0.5, 0.5), bottom0, Vector3.DOWN, Vector2(0.0, 0.0), bottom1, Vector3.DOWN, Vector2(1.0, 0.0))
		_meshes[cache_key] = surface.commit()
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = _meshes[cache_key]
	item.material_override = Materials.get_material(category, color)
	item.set_meta("roomscale_material_category", category)
	parent.add_child(item)
	return item


static func _seat_surface_point(width: float, depth: float, radius: float, angle: float, top_y: float, dish_depth: float) -> Vector3:
	var x_unit := cos(angle)
	var z_unit := sin(angle)
	var x_shape := signf(x_unit) * sqrt(absf(x_unit))
	var z_shape := signf(z_unit) * sqrt(absf(z_unit))
	var y := top_y - dish_depth * (1.0 - radius * radius)
	return Vector3(width * 0.5 * radius * x_shape, y, depth * 0.5 * radius * z_shape)


static func _seat_normal(point: Vector3, width: float, depth: float, dish_depth: float) -> Vector3:
	return Vector3(2.0 * dish_depth * point.x / (width * width * 0.25), 1.0, 2.0 * dish_depth * point.z / (depth * depth * 0.25)).normalized()


static func _append_triangle(
	surface: SurfaceTool,
	a: Vector3,
	normal_a: Vector3,
	uv_a: Vector2,
	b: Vector3,
	normal_b: Vector3,
	uv_b: Vector2,
	c: Vector3,
	normal_c: Vector3,
	uv_c: Vector2
) -> void:
	surface.set_normal(normal_c)
	surface.set_uv(uv_c)
	surface.add_vertex(c)
	surface.set_normal(normal_b)
	surface.set_uv(uv_b)
	surface.add_vertex(b)
	surface.set_normal(normal_a)
	surface.set_uv(uv_a)
	surface.add_vertex(a)

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
