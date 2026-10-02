extends RefCounted
const G := preload("res://scripts/visuals/visual_geometry.gd")

static func build(parent: Node3D) -> Array[Node3D]:
	var groups: Array[Node3D] = []
	for name in ["FoundationDetails", "MachineryDetails", "LauncherDetails"]:
		var group := Node3D.new()
		group.name = name
		group.visible = false
		parent.add_child(group)
		groups.append(group)
	var iron := Color("2e4149")
	var brass := Color("b18a48")
	var copper := Color("a76543")
	G.box(groups[0], "AssemblyBlock", Vector3(0.5, 0.16, 0.24), Vector3(0, 0.08, -0.38), "wood", Color("72513b"), 0.025)
	G.box(groups[0], "AssemblyPlate", Vector3(0.32, 0.035, 0.21), Vector3(0, 0.177, -0.38), "iron", iron, 0.015)
	G.cylinder(groups[0], "AssemblyPin", 0.045, 0.09, Vector3(0.1, 0.24, -0.38), "brass", brass)
	for x in [-1, 1]:
		for z in [-1, 1]:
			G.box(groups[0], "FrameFoot%d_%d" % [x, z], Vector3(0.4, 1.6, 0.4), Vector3(x * 4, 0.8, z * 2.5), "iron", iron, 0.06)
			G.cylinder(groups[0], "FoundationBolt%d_%d" % [x, z], 0.25, 0.2, Vector3(x * 3.5, 1.75, z * 2.5), "iron", iron)
		G.box(groups[0], "Rail%d" % x, Vector3(0.5, 0.5, 7.5), Vector3(x * 4, 1.7, 0), "iron", iron, 0.1)
		G.box(groups[1], "BearingStand%d" % x, Vector3(0.5, 3.5, 1.0), Vector3(0, 3.1, x * 1.55), "iron", iron, 0.15)
		G.cylinder(groups[1], "SpoolFlange%d" % x, 2.65, 0.22, Vector3(0, 3.6, x * 1.05), "brass", brass).rotation.x = PI * 0.5
		for z in range(7):
			G.cylinder(groups[1], "CableWinding%d" % z, 2.42, 0.12, Vector3(0, 3.6, -0.7 + z * 0.23), "rope", Color("565042")).rotation.x = PI * 0.5
		G.box(groups[2], "TowerRail%d" % x, Vector3(0.35, 9.0, 0.35), Vector3(x * 0.7, 6.4, -1.6), "iron", iron, 0.07)
	for rung in range(15):
		G.box(groups[2], "TowerRung%d" % rung, Vector3(1.8, 0.1, 0.16), Vector3(0, 1.7 + rung * 0.64, -0.95), "brass", brass, 0.03)
	var gear := G.gear(groups[1], "DriveGear", 1.7, Vector3(2.8, 3.2, 0.8), 14)
	gear.rotation.x = PI * 0.5
	G.cylinder(groups[1], "PressureVessel", 0.85, 3.3, Vector3(-3.0, 3.3, 0), "copper", copper)
	G.cylinder(groups[1], "PressurePipe", 0.15, 3, Vector3(-1.8, 4.7, 0), "copper", copper).rotation.z = PI * 0.5
	var pulley := G.gear(groups[2], "TopPulley", 0.7, Vector3(0, 11, -1.6), 10)
	pulley.rotation.x = PI * 0.5
	G.box(groups[2], "PulleyBracket", Vector3(1.8, 0.28, 0.7), Vector3(0, 10.7, -1.6), "iron", iron, 0.05)
	G.cylinder(groups[2], "WarningLamp", 0.2, 0.3, Vector3(0.8, 10.8, -1.6), "lamp", Color("dea14c"))
	return groups

static func animate(groups: Array[Node3D], completed: int, active: int, progress: float, deploying: bool, delta: float) -> void:
	for index in range(groups.size()):
		groups[index].visible = completed > index or (active == index and progress > 0.25)
	if groups.size() > 1 and (deploying or active == 1):
		var gear := groups[1].get_node("DriveGear") as Node3D
		gear.rotate_object_local(Vector3.UP, delta * 2.5)
