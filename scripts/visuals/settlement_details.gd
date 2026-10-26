extends RefCounted
const G := preload("res://scripts/visuals/visual_geometry.gd")

static func decorate(settlement: Node3D, definition: Dictionary, resolver: Variant = null) -> void:
	for name in ["Workshop", "Depot", "Housing", "WorkArea"]:
		var building := settlement.get_node(name) as Node3D
		var asset_id := _asset_id(name)
		var dimensions := _asset_dimensions(name)
		var descriptor := {"kind": asset_id, "appearance": {"asset_id": asset_id}, "dimensions": dimensions}
		var uses_registered_art := false
		if resolver != null:
			var recipe: Dictionary = resolver.resolve(descriptor)
			uses_registered_art = bool(recipe.get("asset_registry_required", false))
		if uses_registered_art:
			_hide_legacy_meshes(building)
			building.set_meta("accepted_art_visible", true)
			var asset_root := Node3D.new()
			asset_root.name = "ArtPresentation"
			asset_root.set_meta("presentation_only", true)
			building.add_child(asset_root)
			resolver.render(asset_root, descriptor, func(_parent: Node3D, _object: Dictionary) -> void: pass)
		var visual := Node3D.new()
		visual.name = "ClockworkDetails"
		building.add_child(visual)
		if not uses_registered_art and name in ["Workshop", "Depot"]:
			for side in [-1, 1]:
				for end in [-1, 1]:
					G.box(visual, "IronPost%d_%d" % [side, end], Vector3(0.7, 8.4, 0.7), Vector3(side * 10.5, 4.4, end * 7.5), "iron", Color("29363a"), 0.1)
					for y in [1.3, 5.0, 8.2]:
						G.cylinder(visual, "Rivet%d_%d_%s" % [side, end, y], 0.18, 0.16, Vector3(side * 10.5, y, end * 7.9), "brass", Color("bc9351")).rotation.x = PI * 0.5
				G.box(visual, "WindowFrame%d" % side, Vector3(3.3, 3.4, 0.4), Vector3(side * 8.5, 4.8, 8.65), "iron", Color("25363b"), 0.2)
				G.box(visual, "WarmWindow%d" % side, Vector3(2.7, 2.8, 0.1), Vector3(side * 8.5, 4.8, 8.9), "lamp", Color("e6ab59"), 0.05)
				G.box(visual, "WindowMullion%d" % side, Vector3(0.18, 3.0, 0.3), Vector3(side * 8.5, 4.8, 9.0), "iron", Color("25363b"), 0.04)
				for strip in range(6):
					G.box(visual, "RoofSeam%d_%d" % [side, strip], Vector3(9.5, 0.18, 0.15), Vector3(side * 8.0, 10.6 if name == "Workshop" else 8.85, -8.0 + strip * 3.2), "copper", Color("94715c"), 0.025)
			G.box(visual, "DoorLintel", Vector3(8, 0.65, 0.8), Vector3(0, 6.8, 8.7), "wood", Color("362e26"), 0.15)
			G.box(visual, "FrontStep", Vector3(6, 0.35, 2.0), Vector3(0, 0.65, 9.2), "wood", Color("987047"), 0.1)
		if name == "Workshop":
			for y in [1.4, 6.5]:
				if not uses_registered_art:
					G.cylinder(visual, "BoilerHoop%s" % y, 2.85, 0.35, Vector3(-6.5, y, -2), "copper", Color("b17042"))
			if not uses_registered_art:
				G.cylinder(visual, "SteamPipe", 0.35, 6, Vector3(-2.7, 4, -2), "copper", Color("b17042"))
				G.cylinder(visual, "SteamElbow", 0.38, 3.5, Vector3(-4.5, 6.7, -2), "copper", Color("b17042")).rotation.z = PI * 0.5
			G.gear(visual, "Flywheel", 1.7, Vector3(3.5, 5, 2)).rotation.x = PI * 0.5
			if not uses_registered_art:
				G.box(visual, "PistonHousing", Vector3(1.1, 0.7, 2.6), Vector3(5.5, 4.9, 2), "iron", Color("3f5155"), 0.16)
				G.cylinder(visual, "Piston", 0.18, 2.1, Vector3(5.5, 4.9, 3.2), "brass", Color("b69b65")).rotation.x = PI * 0.5
		if name == "Depot" and not uses_registered_art:
			for x in [-6, 0, 6]:
				for y in [1.4, 4.0]:
					G.box(visual, "CrateBrace%s_%s" % [x, y], Vector3(4.9, 0.28, 0.35), Vector3(x, y, 0.1), "iron", Color("384449"), 0.05)
		if name == "Housing" and not uses_registered_art:
			for x in [-4.2, 4.2]:
				G.box(visual, "TentRidge%s" % x, Vector3(0.3, 0.3, 8.3), Vector3(x, 5.25, 0), "wood", Color("675039"), 0.05)
				G.box(visual, "Porch%s" % x, Vector3(6.3, 0.3, 2.0), Vector3(x, 0.4, 4.1), "wood", Color("80603b"), 0.06)
	# Visual scale is independent of conservative gameplay building footprints.
	# Keep original named simulation stations as work yards with tiny benches.
	for name in ["Workshop", "Depot", "Housing", "WorkArea"]:
		settlement.get_node(name).scale = Vector3.ONE * 0.6
	var stations: Array = definition.activity_stations.workshop.duplicate()
	stations.append(definition.activity_stations.work_area)
	for index in range(stations.size()):
		var station: Array = stations[index]
		var at := Vector3(float(station[0]), float(station[1]), float(station[2]))
		G.box(settlement, "StationBench%d" % index, Vector3(1.2, 0.08, 0.6), at + Vector3(0, 0.37, -0.5), "wood", Color("79533b"), 0.025)
		for side in [-1, 1]:
			G.box(settlement, "BenchLeg%d_%d" % [index, side], Vector3(0.08, 0.35, 0.5), at + Vector3(side * 0.47, 0.17, -0.5), "iron", Color("2f4147"), 0.02)
	preload("res://scripts/visuals/settlement_composition.gd").build(settlement, definition)


static func _asset_id(building_name: String) -> String:
	return "settlement_%s" % building_name.to_lower()


static func _asset_dimensions(building_name: String) -> Array[float]:
	match building_name:
		"Workshop": return [26.0, 20.0, 20.0]
		"Depot": return [24.0, 13.0, 20.0]
		"Housing": return [17.0, 7.0, 9.0]
		"WorkArea": return [23.0, 9.0, 12.0]
		_: return [1.0, 1.0, 1.0]


static func _hide_legacy_meshes(building: Node3D) -> void:
	for child in building.get_children():
		if child is MeshInstance3D or child is Label3D:
			child.visible = false

static func animate(settlement: Node3D, clock: float) -> void:
	var flywheel := settlement.get_node_or_null("Workshop/ClockworkDetails/Flywheel") as Node3D
	if flywheel != null:
		flywheel.rotation.y = clock * 1.4
	var piston := settlement.get_node_or_null("Workshop/ClockworkDetails/Piston") as Node3D
	if piston != null:
		piston.position.z = 3.2 + sin(clock * 2.8) * 0.5
