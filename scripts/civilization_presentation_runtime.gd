extends "res://scripts/civilization_presentation.gd"
## Safe production adapter for civilization presentation.
##
## The base presenter owns shared civilization visuals. This runtime override keeps
## simulation-owned settlement nodes alive: pipeline_proof retains references to
## animated gears, boiler lights and other Clockwork presentation nodes, so Verdant
## hides those existing children rather than freeing/replacing their parent objects.


func _apply_verdant_settlement(scene: Node3D) -> void:
	var settlement := scene.get_node("Settlement") as Node3D
	var room_definition: Dictionary = scene.get("_room_definition")
	var start: Dictionary = room_definition.get("start", {})
	var infrastructure: Array = start.get("infrastructure", ["workshop", "depot", "housing", "work_area"])
	if infrastructure.is_empty():
		_style_founder_supplies(settlement)
		return
	var roles := {
		"workshop": "Workshop",
		"depot": "Depot",
		"housing": "Housing",
		"work_area": "WorkArea",
	}
	for role in roles:
		if role not in infrastructure:
			continue
		var building := settlement.get_node_or_null(String(roles[role])) as Node3D
		if building == null:
			continue
		_hide_existing_presentation(building)
		_build_verdant_overlay(building, role)


func _hide_existing_presentation(building: Node3D) -> void:
	# Hide only children that already belong to the Clockwork presentation. The
	# building parent stays visible/valid so later production systems can attach
	# stockpiles and other earned state to the same authoritative node.
	for child in building.get_children():
		if child.name == "VerdantOverlay":
			continue
		if child is Node3D:
			(child as Node3D).visible = false


func _build_verdant_overlay(building: Node3D, role: String) -> void:
	if building.has_node("VerdantOverlay"):
		return
	var overlay := Node3D.new()
	overlay.name = "VerdantOverlay"
	building.add_child(overlay)
	match role:
		"workshop":
			_box(overlay, "RootPlatform", Vector3(15, 0.5, 11), Vector3(0, 0.25, 0), Color("6b5235"), 0.96)
			for side in [-1.0, 1.0]:
				_segment(overlay, "TrunkPost%s" % side, Vector3(side * 5.8, 0.5, -3.6), Vector3(side * 5.2, 7.8, -3.2), 0.42, Color("67503a"))
				_segment(overlay, "FrontRoot%s" % side, Vector3(side * 5.6, 0.35, 4.0), Vector3(side * 3.2, 0.65, 0), 0.28, Color("59462f"))
			_sphere(overlay, "LeafCanopy", Vector3(0, 8.2, -1.0), Vector3(13, 1.2, 9), Color("4f783d"))
			for index in range(5):
				_sphere(overlay, "SeedPod%d" % index, Vector3(-4.0 + index * 2.0, 5.8 + float(index % 2) * 0.6, -1.0), Vector3(0.8, 1.4, 0.8), Color("b49147"))
			_world_label(overlay, "VerdantLabel", "GROWTH NURSERY", Vector3(0, 10.2, 0), Color("d9cf72"))
		"depot":
			_box(overlay, "WovenFloor", Vector3(14, 0.45, 10), Vector3(0, 0.22, 0), Color("806744"), 0.98)
			for side in [-1.0, 1.0]:
				_segment(overlay, "Arch%sA" % side, Vector3(side * 5.2, 0.4, -3.4), Vector3(side * 4.7, 6.2, 0), 0.32, Color("5e4a34"))
				_segment(overlay, "Arch%sB" % side, Vector3(side * 4.7, 6.2, 0), Vector3(side * 5.2, 0.4, 3.4), 0.32, Color("5e4a34"))
			for index in range(6):
				var x := -4.5 + float(index % 3) * 4.5
				var z := -2.0 + float(index / 3) * 4.0
				_sphere(overlay, "CachePod%d" % index, Vector3(x, 1.0, z), Vector3(1.6, 1.7, 1.4), Color("8d7441") if index % 2 == 0 else Color("ad8648"))
			_world_label(overlay, "VerdantLabel", "SEED CACHE", Vector3(0, 8.0, 0), Color("d9cf72"))
		"housing":
			for index in range(3):
				var x := -5.0 + index * 5.0
				_sphere(overlay, "HomePod%d" % index, Vector3(x, 2.3, 0), Vector3(3.6, 4.8, 3.5), Color("6f7c43") if index % 2 == 0 else Color("806644"))
				_box(overlay, "Door%d" % index, Vector3(1.1, 1.8, 0.28), Vector3(x, 1.25, 1.72), Color("3d4d2e"), 0.9)
				_leaf(overlay, "RoofLeaf%d" % index, Vector3(x, 4.7, 0), Vector3(3.8, 0.25, 2.0), Color("527b3c"), -0.25 + index * 0.22)
			_world_label(overlay, "VerdantLabel", "POD HOMES", Vector3(0, 7.2, 0), Color("d9cf72"))
		"work_area":
			_cylinder(overlay, "CultivationMat", 6.5, 0.18, Vector3(0, 0.09, 0), Color("526a3d"))
			for index in range(8):
				var angle := TAU * float(index) / 8.0
				_sphere(overlay, "GrowthStone%d" % index, Vector3(cos(angle) * 5.2, 0.45, sin(angle) * 5.2), Vector3(0.7, 0.5, 0.7), Color("88724f"))
			_world_label(overlay, "VerdantLabel", "CULTIVATION CIRCLE", Vector3(0, 4.0, 0), Color("d9cf72"))
