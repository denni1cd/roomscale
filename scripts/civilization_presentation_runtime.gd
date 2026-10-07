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
	var streets := settlement.get_node_or_null("SettlementStreets") as Node3D
	if streets != null:
		# Retain the ordinary human pencil/coin scale cues, but hide industrial
		# streets, distribution engines, pipes and utility wires for this society.
		for child in streets.get_children():
			if child is Node3D and String(child.name) not in ["HumanPencil", "HumanCoin", "CoinFace", "CoinRelief"]:
				(child as Node3D).visible = false
	for child in settlement.get_children():
		if child is MeshInstance3D and (String(child.name).begins_with("StationBench") or String(child.name).begins_with("BenchLeg")):
			(child as MeshInstance3D).material_override = _material(Color("765438"), 0.96)


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
			# A cultivated tree is the nursery itself. The open front work yard stays
			# visible beneath a branching crown, rather than a green industrial roof.
			_segment(overlay, "NurseryTrunkLower", Vector3(0, 0.5, -2.0), Vector3(-0.55, 3.4, -2.1), 0.72, Color("745337"))
			_segment(overlay, "NurseryTrunkUpper", Vector3(-0.55, 3.4, -2.1), Vector3(0.15, 6.5, -1.4), 0.48, Color("745337"))
			_sphere(overlay, "TrunkKnot", Vector3(-0.55, 3.4, -2.1), Vector3(1.5, 1.35, 1.4), Color("745337"))
			var crown_points := [Vector3(-3.6, 7.2, -2.1), Vector3(3.4, 7.7, -1.9), Vector3(0.2, 8.0, 1.0)]
			for index in range(crown_points.size()):
				var tip: Vector3 = crown_points[index]
				_segment(overlay, "NurseryBranch%d" % index, Vector3(-0.3, 4.5, -1.8), tip, 0.3, Color("78593c"))
				_sphere(overlay, "TreeCrown%d" % index, tip + Vector3.UP * 0.45, Vector3(5.4, 2.3, 4.3), Color("4f783d") if index % 2 == 0 else Color("77934d"))
				_leaf(overlay, "CrownLeaf%d" % index, tip + Vector3(0.6, 1.55, 0.3), Vector3(3.3, 0.3, 1.7), Color("86a956"), index * 0.7)
				_segment(overlay, "HangingSeedStem%d" % index, tip, tip + Vector3(0.4, -1.7, 0.4), 0.075, Color("647848"))
				_sphere(overlay, "SeedPod%d" % index, tip + Vector3(0.4, -1.7, 0.4), Vector3(0.8, 1.2, 0.8), Color("bd9b53"))
				_magic_flower(overlay, "NurseryBloom%d" % index, tip + Vector3(0.2, 0.95, 1.45), 0.42)
			for index in range(5):
				var angle := TAU * float(index) / 5.0
				_segment(overlay, "NurseryRoot%d" % index, Vector3(0, 0.6, -2), Vector3(cos(angle) * 5.7, 0.55, -1 + sin(angle) * 3.4), 0.25, Color("705034"))
			_world_label(overlay, "VerdantLabel", "GROWTH NURSERY", Vector3(0, 11.0, 0), Color("d9cf72"))
		"depot":
			_box(overlay, "WovenFloor", Vector3(14, 0.45, 10), Vector3(0, 0.22, 0), Color("806744"), 0.98)
			for index in range(3):
				var x := -5.2 + index * 5.2
				var points := [Vector3(x, 0.45, -3.4), Vector3(x - 0.25, 3.4, -2), Vector3(x, 4.5, 0), Vector3(x + 0.25, 3.4, 2), Vector3(x, 0.45, 3.4)]
				for piece in range(1, points.size()):
					_segment(overlay, "WillowRib%d_%d" % [index, piece], points[piece - 1], points[piece], 0.18, Color("806441"))
			for level in range(3):
				_segment(overlay, "WovenBack%d" % level, Vector3(-5.3, 0.9 + level * 0.6, -3.3), Vector3(5.3, 1.1 + level * 0.6, -3.3), 0.08, Color("aa8752"))
			for index in range(6):
				var x := -4.5 + float(index % 3) * 4.5
				var z := -2.0 + float(index / 3) * 4.0
				_sphere(overlay, "CachePod%d" % index, Vector3(x, 1.3, z), Vector3(1.6, 1.7, 1.4), Color("8d7441") if index % 2 == 0 else Color("ad8648"))
				_leaf(overlay, "CacheLid%d" % index, Vector3(x, 2.15, z), Vector3(1.7, 0.16, 1.0), Color("65894a"), index * 0.2)
				_magic_flower(overlay, "CacheSpore%d" % index, Vector3(x + 0.4, 1.85, z + 0.55), 0.12)
			_world_label(overlay, "VerdantLabel", "SEED CACHE", Vector3(0, 5.5, 0), Color("d9cf72"))
		"housing":
			for index in range(3):
				var x := -5.0 + index * 5.0
				_sphere(overlay, "HomePod%d" % index, Vector3(x, 2.3, 0), Vector3(3.6, 4.8, 3.5), Color("6f7c43") if index % 2 == 0 else Color("806644"))
				_box(overlay, "Door%d" % index, Vector3(1.1, 1.8, 0.28), Vector3(x, 1.25, 1.72), Color("3d4d2e"), 0.9)
				_leaf(overlay, "RoofLeaf%d" % index, Vector3(x, 4.7, 0), Vector3(3.8, 0.25, 2.0), Color("527b3c"), -0.25 + index * 0.22)
				for side in [-1.0, 1.0]:
					_segment(overlay, "HomeRoot%d_%s" % [index, side], Vector3(x + side * 1.5, 0.08, 0.4), Vector3(x + side * 1.3, 2.9, 0.25), 0.14, Color("70543a"))
					_segment(overlay, "HomeBranch%d_%s" % [index, side], Vector3(x + side * 1.3, 2.9, 0.25), Vector3(x + side * 0.7, 4.7, 0), 0.1, Color("70543a"))
				_magic_flower(overlay, "DoorLamp%d" % index, Vector3(x + 0.85, 1.2, 1.8), 0.15)
			_world_label(overlay, "VerdantLabel", "POD HOMES", Vector3(0, 7.2, 0), Color("d9cf72"))
		"work_area":
			_cylinder(overlay, "CultivationMat", 6.5, 0.18, Vector3(0, 0.09, 0), Color("526a3d"))
			for index in range(8):
				var angle := TAU * float(index) / 8.0
				_sphere(overlay, "GrowthStone%d" % index, Vector3(cos(angle) * 5.2, 0.45, sin(angle) * 5.2), Vector3(0.7, 0.5, 0.7), Color("88724f"))
			for index in range(3):
				_mushroom(overlay, "CultureFungus%d" % index, Vector3(-2 + index * 2, 0.18, -1), 0.4 + index * 0.08)
			for index in range(3):
				var at := Vector3(-2.7 + index * 2.7, 0.18, 1.0)
				_segment(overlay, "CultivatedSapling%d" % index, at, at + Vector3(0.15, 1.7, -0.2), 0.1, Color("745337"))
				for side in [-1.0, 1.0]:
					var tip := at + Vector3(side * 0.65, 2, 0)
					_segment(overlay, "SaplingFork%d_%s" % [index, side], at + Vector3(0.15, 1.3, -0.2), tip, 0.06, Color("745337"))
					_leaf(overlay, "SaplingLeaf%d_%s" % [index, side], tip, Vector3(1.25, 0.23, 0.65), Color("7d9e4e"), side * 0.6)
				_magic_flower(overlay, "CultivationBloom%d" % index, at + Vector3(0.15, 2.2, -0.2), 0.22)
			_world_label(overlay, "VerdantLabel", "CULTIVATION CIRCLE", Vector3(0, 4.0, 0), Color("d9cf72"))


func _magic_flower(parent: Node3D, node_name: String, at: Vector3, radius: float) -> void:
	# Emissive blossoms suggest cultivation magic without producing resources,
	# particles, lights, collision, navigation links or another progression clock.
	var bloom := Node3D.new()
	bloom.name = node_name
	bloom.position = at
	parent.add_child(bloom)
	for petal in range(5):
		var angle := TAU * float(petal) / 5.0
		_leaf(bloom, "Petal%d" % petal, Vector3(cos(angle) * radius, 0, sin(angle) * radius), Vector3(radius * 1.65, radius * 0.25, radius * 0.8), Color("bb98cb") if petal % 2 == 0 else Color("d7c885"), angle)
	var heart := _sphere(bloom, "GlowHeart", Vector3(0, radius * 0.15, 0), Vector3.ONE * radius * 0.65, Color("e3edaa"))
	var material := heart.material_override as StandardMaterial3D
	material.emission_enabled = true
	material.emission = Color("ddec99")
	material.emission_energy_multiplier = 0.65
