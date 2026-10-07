extends Node
## Verdant presentation adapter for dynamically constructed settlement modules.
##
## The production settlement-development system remains civilization-neutral and
## authoritative for placement, material delivery, build progress, capacity,
## navigation footprints, and completion. This adapter only changes presentation
## after those real modules are rendered.

var _refresh_timer := 0.0
var _active := false


func _ready() -> void:
	_active = OS.get_environment("ROOMSCALE_CIVILIZATION").strip_edges().to_lower() == "verdant"


func _process(delta: float) -> void:
	if not _active:
		return
	_refresh_timer += delta
	if _refresh_timer < 0.2:
		return
	_refresh_timer = 0.0
	var scene := get_tree().current_scene as Node3D
	if scene == null:
		return
	for child in scene.get_children():
		if child is Node3D and child.has_meta("module") and child.has_meta("stage"):
			_style_module(child as Node3D)


func _style_module(root: Node3D) -> void:
	var stage := String(root.get_meta("stage", ""))
	var kind := String(root.get_meta("module", ""))
	var signature := "%s:%s" % [kind, stage]
	if String(root.get_meta("verdant_signature", "")) == signature:
		return
	root.set_meta("verdant_signature", signature)
	_recolor_existing(root)
	var overlay := root.get_node_or_null("VerdantGrowth") as Node3D
	if overlay != null:
		root.remove_child(overlay)
		overlay.free()
	overlay = Node3D.new()
	overlay.name = "VerdantGrowth"
	root.add_child(overlay)
	_build_stage_growth(overlay, kind, stage)


func _recolor_existing(root: Node3D) -> void:
	for child in root.get_children():
		if not (child is MeshInstance3D):
			continue
		var mesh := child as MeshInstance3D
		var name := String(mesh.name).to_lower()
		var color := Color("6b5339")
		if "roof" in name or "panel" in name or "back" in name or "side" in name:
			color = Color("516f3e")
		elif "window" in name:
			color = Color("d8cf72")
		elif "stone" in name or "foundation" in name or "yard" in name or "threshold" in name:
			color = Color("776f57")
		elif "door" in name:
			color = Color("58432f")
		elif "workpiece" in name:
			color = Color("7c8c4b")
		mesh.material_override = _material(color, 0.94)


func _build_stage_growth(root: Node3D, kind: String, stage: String) -> void:
	# Each production re-render creates a new module root, so these details track
	# the real construction stage without inventing a second build progression.
	for index in range(5):
		var angle := TAU * float(index) / 5.0
		var radius := 3.2 + float(index % 2) * 0.6
		var start := Vector3(cos(angle) * 0.8, 0.05, sin(angle) * 0.8 - 1.0)
		var finish := Vector3(cos(angle) * radius, 0.09, sin(angle) * radius - 1.0)
		_segment(root, "FoundationRoot%d" % index, start, finish, 0.045, Color("58452f"))
	if stage == "FOUNDATION":
		return
	for index in range(4):
		var x := -3.2 + float(index) * 2.1
		_segment(root, "LivingPost%d" % index, Vector3(x, 0.08, -2.7), Vector3(x * 0.9, 0.95, -2.4), 0.055, Color("5f5036"))
		_leaf(root, "PostLeaf%d" % index, Vector3(x * 0.9, 0.65, -2.35), Vector3(0.32, 0.035, 0.15), Color("658a47"), float(index) * 0.8)
	if stage == "FRAME":
		return
	for index in range(6):
		var x := -3.6 + float(index) * 1.45
		_leaf(root, "WallLeaf%d" % index, Vector3(x, 0.72 + float(index % 2) * 0.18, 1.08), Vector3(0.44, 0.045, 0.19), Color("547a40") if index % 2 == 0 else Color("6a914b"), float(index) * 0.55)
	if stage == "SHELL":
		return
	var label := "GROVE SHELTER"
	match kind:
		"depot": label = "SEED CACHE"
		"housing": label = "POD HOMES"
		"workshop": label = "GROWTH NURSERY"
	_world_label(root, "VerdantModuleLabel", label, Vector3(0, 2.0 if kind in ["housing", "workshop"] else 1.45, -0.9), Color("d8cf72"))
	if kind == "shelter":
		for index in range(3):
			_sphere(root, "SleepMoss%d" % index, Vector3(-2.4 + index * 2.4, 0.17, -1.0), Vector3(1.1, 0.10, 0.7), Color("4d763e"))
	elif kind == "depot":
		for index in range(3):
			_sphere(root, "StoragePod%d" % index, Vector3(-2.2 + index * 2.2, 0.45, -1.0), Vector3(0.75, 0.9, 0.7), Color("9a7742"))
	elif kind == "housing":
		for index in range(3):
			_leaf(root, "HomeCanopy%d" % index, Vector3(-2.7 + index * 2.7, 1.9, -1.0), Vector3(1.4, 0.10, 0.65), Color("50783e"), float(index) * 0.7)
	elif kind == "workshop":
		_sphere(root, "WorkshopBud", Vector3(2.7, 1.35, -1.3), Vector3(0.55, 0.72, 0.55), Color("9a9b51"))
		for index in range(4):
			var angle := TAU * float(index) / 4.0
			_leaf(root, "WorkshopPetal%d" % index, Vector3(2.7 + cos(angle) * 0.5, 1.35, -1.3 + sin(angle) * 0.5), Vector3(0.55, 0.05, 0.22), Color("c99a55"), angle)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _sphere(parent: Node3D, node_name: String, at: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	item.mesh = mesh
	item.position = at
	item.scale = scale_value
	item.material_override = _material(color, 0.95)
	parent.add_child(item)
	return item


func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, at: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	item.mesh = mesh
	item.position = at
	item.material_override = _material(color, 0.95)
	parent.add_child(item)
	return item


func _segment(parent: Node3D, node_name: String, start: Vector3, finish: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var direction := finish - start
	var item := _cylinder(parent, node_name, radius, maxf(direction.length(), 0.001), (start + finish) * 0.5, color)
	if direction.length() > 0.0001:
		item.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return item


func _leaf(parent: Node3D, node_name: String, at: Vector3, size: Vector3, color: Color, yaw: float) -> MeshInstance3D:
	var leaf := _sphere(parent, node_name, at, size, color)
	leaf.rotation.y = yaw
	leaf.rotation.z = 0.12
	return leaf


func _world_label(parent: Node3D, node_name: String, value: String, at: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = value
	label.position = at
	label.font_size = 20
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_modulate = Color("263320")
	label.outline_size = 3
	parent.add_child(label)
	return label
