extends RefCounted
## Presentation only: no physics bodies, navigation obstacles, or task stations.
const G := preload("res://scripts/visuals/visual_geometry.gd")

static func build(settlement: Node3D, definition: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "SettlementStreets"
	settlement.add_child(root)
	root.set_meta("presentation_only", true)
	var shop := _point(definition.landmarks.workshop)
	var depot := _point(definition.landmarks.depot)
	var homes := _point(definition.landmarks.housing)
	var yard := _point(definition.landmarks.work_area)
	var a := shop + Vector3(0, 0, 10)
	var b := depot + Vector3(0, 0, 10)
	var c := homes + Vector3(0, 0, -7)
	var d := yard + Vector3(0, 0, -7)
	_lane(root, a, b, 2.2)
	_lane(root, c, d, 2.2)
	_lane(root, a, c, 1.8)
	_lane(root, b, d, 1.8)
	var plaza := (a + b + c + d) * 0.25
	G.box(root, "Commons", Vector3(5, 0.016, 4), plaza + Vector3.UP * 0.01, "wood", Color("675745"), 0.004)
	for i in range(3):
		var at := yard + Vector3(-5 + i * 3, 0, -3)
		G.box(root, "AssemblyRack", Vector3(1.5, 0.12, 1), at + Vector3.UP * 0.6, "wood", Color("79533c"), 0.03)
		for x in [-0.55, 0.55]:
			G.box(root, "RackLeg", Vector3(0.08, 0.6, 0.08), at + Vector3(x, 0.3, 0), "iron", Color("34484b"), 0.015)
		G.gear(root, "SpareCog", 0.3, at + Vector3(0.3, 0.75, 0))
		_cart(root, depot + Vector3(-7 + i * 2, 0, -4))
	for pair in [[shop + Vector3(0, 0, 6), a], [depot + Vector3(0, 0, 6), b], [homes + Vector3(0, 0, 4), c], [yard + Vector3(0, 0, 4), d]]:
		_lane(root, pair[0], pair[1], 1.5)
	# Poles, stores and machinery stay inside the original reserved building yards.
	var poles: Array[Vector3] = []
	for at in [shop, depot, homes, yard]:
		var pole: Vector3 = at + Vector3(-7, 0, 5)
		poles.append(pole)
		_lantern(root, pole)
		for i in range(3):
			_crate(root, at + Vector3(6 + i * 1.1, 0, 4), i)
		_barrel(root, at + Vector3(7.5, 0, -4))
		_barrel(root, at + Vector3(8.5, 0, -3))
	for i in range(poles.size()):
		var start := poles[i] + Vector3.UP * 3.5
		var end := poles[(i + 1) % poles.size()] + Vector3.UP * 3.5
		for segment in range(8):
			var t0 := segment / 8.0
			var t1 := (segment + 1) / 8.0
			_line(root, "UtilityWire", start.lerp(end, t0) - Vector3.UP * sin(t0 * PI) * 0.45, start.lerp(end, t1) - Vector3.UP * sin(t1 * PI) * 0.45, 0.035, "iron", Color("39494b"))
	# Small satellite huts and shared machinery establish a connected work yard.
	for i in range(3):
		var at := homes + Vector3(-8 + i * 7, 0, -4)
		G.box(root, "Cabin", Vector3(2.7, 1.5, 2), at + Vector3.UP * 0.75, "wood", Color("684832"), 0.08)
		var roof := G.box(root, "CabinRoof", Vector3(3.1, 0.16, 2.5), at + Vector3.UP * 1.6, "iron", Color("405759"), 0.06)
		roof.rotation.z = 0.12 * (1 if i % 2 == 0 else -1)
		G.box(root, "CabinWindow", Vector3(0.55, 0.6, 0.04), at + Vector3(0.65, 1, 1.02), "lamp", Color("e6a64b"), 0.04)
		G.box(root, "CabinDoor", Vector3(0.6, 1.1, 0.06), at + Vector3(-0.5, 0.55, 1.03), "wood", Color("352d29"), 0.04)
	var machine := Node3D.new()
	machine.name = "DistributionEngine"
	machine.position = shop + Vector3(7, 0, -4)
	root.add_child(machine)
	G.box(machine, "Base", Vector3(2, 0.25, 2.2), Vector3.UP * 0.12, "iron", Color("293a40"), 0.08)
	G.cylinder(machine, "Tank", 0.55, 1.8, Vector3.UP * 1.1, "copper", Color("996344"))
	G.gear(machine, "Drive", 0.65, Vector3(0.9, 0.9, 0)).rotation.x = PI * 0.5
	_line(root, "SteamMain", shop + Vector3(7, 2, -4), depot + Vector3(-7, 2, -4), 0.09, "copper", Color("9b6748"))
	# Keep solid scale props inside the workshop's already reserved footprint,
	# clear of the front street and authoritative citizen work stations.
	_scale_props(root, shop + Vector3(8, 0, 7))
	_facades(settlement)
	# Paint and copper roofing separate miniature structures from room furniture.
	for name in ["Depot", "Housing"]:
		var building := settlement.get_node(name)
		for mesh in building.get_children():
			if mesh is MeshInstance3D and (String(mesh.name).begins_with("RoofWing") or String(mesh.name).begins_with("CanvasRoof")):
				mesh.material_override = preload("res://scripts/visuals/material_library.gd").get_material("copper" if name == "Depot" else "canvas", Color("6d7f7c") if name == "Depot" else Color("9c8761"))

static func _cart(parent: Node3D, at: Vector3) -> void:
	G.box(parent, "CartBed", Vector3(1.1, 0.15, 1.6), at + Vector3.UP * 0.4, "wood", Color("8b6241"), 0.03)
	for x in [-0.55, 0.55]:
		G.box(parent, "CartSide", Vector3(0.07, 0.4, 1.6), at + Vector3(x, 0.65, 0), "wood", Color("71543e"), 0.02)
		G.cylinder(parent, "CartWheel", 0.28, 0.08, at + Vector3(x * 1.2, 0.28, 0), "iron", Color("2c4047")).rotation.z = PI * 0.5
		G.box(parent, "CartHandle", Vector3(0.05, 0.06, 0.8), at + Vector3(x * 0.7, 0.5, 1), "wood", Color("71543e"), 0.01)

static func _facades(settlement: Node3D) -> void:
	var housing := settlement.get_node("Housing") as Node3D
	for x in [-4.2, 4.2]:
		G.box(housing, "FrontTimber", Vector3(7, 3.1, 0.25), Vector3(x, 2.2, 3.05), "wood", Color("71513a"), 0.08)
		G.box(housing, "Door", Vector3(1.5, 2.6, 0.15), Vector3(x, 1.7, 3.3), "wood", Color("35494c"), 0.05)
		for side in [-1, 1]:
			G.box(housing, "HomeWindow", Vector3(1.1, 1.3, 0.08), Vector3(x + side * 2.2, 2.3, 3.23), "lamp", Color("ddb77b"), 0.04)
			G.box(housing, "WindowCross", Vector3(0.1, 1.4, 0.15), Vector3(x + side * 2.2, 2.3, 3.3), "iron", Color("3b4848"), 0.015)
			G.box(housing, "CornerPost", Vector3(0.25, 3.2, 0.4), Vector3(x + side * 3.3, 2.1, 3.12), "wood", Color("47392c"), 0.05)
		G.cylinder(housing, "HomeFlue", 0.28, 2, Vector3(x + 2, 5.2, -1), "copper", Color("8d6347"))
	var depot := settlement.get_node("Depot") as Node3D
	for x in [-8, 8]:
		var brace := G.box(depot, "AwningBrace", Vector3(0.35, 3.5, 0.35), Vector3(x, 5.3, 10), "iron", Color("364e51"), 0.07)
		brace.rotation.x = -0.45

static func _point(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

static func _lane(parent: Node3D, a: Vector3, b: Vector3, width: float) -> void:
	var length := a.distance_to(b)
	var count := maxi(1, ceili(length / 0.55))
	var street := MultiMeshInstance3D.new()
	street.name = "StreetPlanks"
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.012, length / count * 0.97)
	instances.mesh = mesh
	instances.instance_count = count
	street.multimesh = instances
	street.material_override = preload("res://scripts/visuals/material_library.gd").get_material("wood", Color("594c3e"))
	parent.add_child(street)
	for i in range(count):
		var basis := Basis(Vector3.UP, atan2(b.x - a.x, b.z - a.z))
		instances.set_instance_transform(i, Transform3D(basis, a.lerp(b, (i + 0.5) / count) + Vector3.UP * 0.008))

static func _line(parent: Node3D, label: String, a: Vector3, b: Vector3, radius: float, category: String, color: Color) -> void:
	var line := G.cylinder(parent, label, radius, a.distance_to(b), (a + b) * 0.5, category, color)
	line.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

static func _lantern(parent: Node3D, at: Vector3) -> void:
	G.cylinder(parent, "UtilityPole", 0.07, 3.7, at + Vector3.UP * 1.85, "wood", Color("594335"))
	G.box(parent, "Crossarm", Vector3(1.1, 0.08, 0.08), at + Vector3.UP * 3.3, "iron", Color("293b40"), 0.02)
	G.box(parent, "LanternGlass", Vector3(0.28, 0.4, 0.28), at + Vector3(0.45, 3, 0), "lamp", Color("ffc477"), 0.035)
	for y in [2.76, 3.23]:
		G.box(parent, "LanternCap", Vector3(0.38, 0.08, 0.38), at + Vector3(0.45, y, 0), "iron", Color("293b40"), 0.03)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0.45, 2.8, 0)
	light.light_color = Color("ffc477")
	light.light_energy = 0.9
	light.omni_range = 7
	parent.add_child(light)

static func _crate(parent: Node3D, at: Vector3, index: int) -> void:
	G.box(parent, "YardCrate", Vector3(0.9, 0.8, 0.8), at + Vector3.UP * 0.4, "wood", Color("8e603f"), 0.045)
	for z in [-0.41, 0.41]:
		for y in [0.14, 0.68]:
			G.box(parent, "CrateBand", Vector3(0.96, 0.055, 0.035), at + Vector3(0, y, z), "iron", Color("36484d"), 0.008)
	if index == 1:
		G.box(parent, "StackedCrate", Vector3(0.7, 0.6, 0.7), at + Vector3.UP * 1.1, "wood", Color("9d7652"), 0.04)

static func _barrel(parent: Node3D, at: Vector3) -> void:
	G.cylinder(parent, "Barrel", 0.4, 1.1, at + Vector3.UP * 0.55, "wood", Color("765239"))
	for y in [0.14, 0.9]:
		G.cylinder(parent, "BarrelHoop", 0.42, 0.07, at + Vector3.UP * y, "iron", Color("39494b"))

static func _scale_props(parent: Node3D, at: Vector3) -> void:
	# Seven-inch human pencil and a one-inch coin: ordinary objects beside .5in people.
	var pencil := Node3D.new()
	pencil.name = "HumanPencil"
	pencil.position = at
	pencil.rotation.y = -0.3
	parent.add_child(pencil)
	_line(pencil, "PaintedHexBody", Vector3(-3, 0.16, 0), Vector3(2.7, 0.16, 0), 0.15, "paint", Color("bd713a"))
	var tip := G.cylinder(pencil, "SharpenedWood", 0.15, 0.7, Vector3(3.05, 0.16, 0), "wood", Color("d4b58a"), 0.0)
	tip.rotation.z = -PI * 0.5
	_line(pencil, "Ferrule", Vector3(-3.3, 0.16, 0), Vector3(-3, 0.16, 0), 0.16, "iron", Color("a4acad"))
	_line(pencil, "Eraser", Vector3(-3.65, 0.16, 0), Vector3(-3.3, 0.16, 0), 0.15, "fabric", Color("bb837c"))
	var coin := at + Vector3(5, 0.045, 1.1)
	G.cylinder(parent, "HumanCoin", 0.48, 0.07, coin, "copper", Color("a77645"))
	G.cylinder(parent, "CoinFace", 0.41, 0.012, coin + Vector3.UP * 0.04, "brass", Color("ba975e"))
	G.box(parent, "CoinRelief", Vector3(0.08, 0.012, 0.42), coin + Vector3.UP * 0.05, "copper", Color("a77645"), 0.01)
