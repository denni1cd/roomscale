extends RefCounted
const G := preload("res://scripts/visuals/visual_geometry.gd")
const AssetRegistry := preload("res://scripts/visuals/asset_registry.gd")
const Materials := preload("res://scripts/visuals/material_library.gd")

static func build(parent: Node3D) -> Array[Node3D]:
	var registry := AssetRegistry.new()
	if not registry.valid:
		parent.set_meta("grapple_art_required", true)
		return _required_failure(parent, "registry could not be read")
	if not registry.entries.has("grapple"):
		return build_procedural(parent)
	var entry := registry.lookup("grapple")
	parent.set_meta("grapple_art_required", true)
	var asset_root := Node3D.new()
	asset_root.name = "GrappleArtAsset"
	asset_root.set_meta("visual_asset_id", "grapple")
	asset_root.set_meta("visual_asset_candidate_id", String(entry.get("candidate_id", "")))
	asset_root.set_meta("visual_source", String(entry.get("resolved_path", "")))
	parent.add_child(asset_root)
	if not String(entry.get("resolution_error", "")).is_empty():
		asset_root.set_meta("visual_source", "required_asset_failure")
		asset_root.set_meta("visual_asset_error", String(entry.get("resolution_error", "registry could not be read")))
		registry._diagnose("grapple", String(entry.get("resolution_error", "accepted asset could not be resolved")))
		return _empty_groups(asset_root)
	var packed := load(String(entry.resolved_path)) as PackedScene
	if packed == null:
		registry._diagnose("grapple", "accepted asset is not an instantiable PackedScene: %s" % entry.resolved_path)
		asset_root.set_meta("visual_source", "required_asset_failure")
		asset_root.set_meta("visual_asset_error", "accepted asset could not be instantiated")
		return _empty_groups(asset_root)
	var instance := packed.instantiate() as Node3D
	if instance == null:
		registry._diagnose("grapple", "accepted asset root must be Node3D")
		asset_root.set_meta("visual_source", "required_asset_failure")
		asset_root.set_meta("visual_asset_error", "accepted asset root must be Node3D")
		return _empty_groups(asset_root)
	asset_root.add_child(instance)
	var groups := _groups_from(instance)
	if groups.size() != 3:
		registry._diagnose("grapple", "accepted asset must contain FoundationDetails, MachineryDetails, and LauncherDetails")
		asset_root.set_meta("visual_source", "required_asset_failure")
		asset_root.set_meta("visual_asset_error", "accepted grapple group structure is invalid")
		asset_root.remove_child(instance)
		instance.queue_free()
		return _empty_groups(asset_root)
	return groups


static func _required_failure(parent: Node3D, reason: String) -> Array[Node3D]:
	var asset_root := Node3D.new()
	asset_root.name = "GrappleArtAsset"
	asset_root.set_meta("visual_asset_id", "grapple")
	asset_root.set_meta("visual_source", "required_asset_failure")
	asset_root.set_meta("visual_asset_error", reason)
	parent.add_child(asset_root)
	push_warning("ROOMSCALE_REQUIRED_VISUAL_ASSET_FAILURE asset=grapple: %s" % reason)
	return _empty_groups(asset_root)


static func _empty_groups(parent: Node3D) -> Array[Node3D]:
	var groups: Array[Node3D] = []
	for name in ["FoundationDetails", "MachineryDetails", "LauncherDetails"]:
		var group := Node3D.new()
		group.name = name
		group.visible = false
		parent.add_child(group)
		groups.append(group)
	return groups


static func _groups_from(asset: Node3D) -> Array[Node3D]:
	var groups: Array[Node3D] = []
	for name in ["FoundationDetails", "MachineryDetails", "LauncherDetails"]:
		var group := asset.get_node_or_null(name) as Node3D
		if group == null:
			return []
		groups.append(group)
	return groups


static func build_procedural(parent: Node3D, refinement: String = "") -> Array[Node3D]:
	var has_mechanical_refinement := refinement in ["mechanical_readability_v2", "mechanical_readability_v3", "mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"]
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
		if has_mechanical_refinement:
			var rim_category := "iron" if refinement in ["mechanical_readability_v3", "mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"] else "brass"
			var rim_color := Color("586568") if refinement == "mechanical_readability_v3" else brass
			if refinement in ["mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"]:
				rim_category = "iron"
				rim_color = Color("39494d")
				_add_torus(groups[1], "SpoolRim%d" % x, 2.4, 2.58, Vector3(0, 3.6, x * 1.05), rim_category, rim_color)
			else:
				_add_torus(groups[1], "SpoolRim%d" % x, 2.18, 2.62, Vector3(0, 3.6, x * 1.05), rim_category, rim_color)
		else:
			G.cylinder(groups[1], "SpoolFlange%d" % x, 2.65, 0.22, Vector3(0, 3.6, x * 1.05), "brass", brass).rotation.x = PI * 0.5
		var winding_count := 9 if refinement in ["mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"] else 7
		for z in range(winding_count):
			var rope_color := Color("8a6948") if refinement in ["mechanical_readability_v3", "mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"] else Color("565042")
			var winding_spacing := 0.18 if refinement in ["mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"] else 0.23
			var winding_at := Vector3(0, 3.6, -winding_spacing * float(winding_count - 1) * 0.5 + z * winding_spacing)
			if refinement in ["mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"]:
				_add_torus(groups[1], "CableWinding%d" % z, 2.34, 2.44, winding_at, "rope", rope_color)
			elif refinement == "mechanical_readability_v3":
				_add_torus(groups[1], "CableWinding%d" % z, 2.30, 2.49, winding_at, "rope", rope_color)
			else:
				G.cylinder(groups[1], "CableWinding%d" % z, 2.42, 0.12, Vector3(0, 3.6, -0.7 + z * 0.23), "rope", rope_color).rotation.x = PI * 0.5
		G.box(groups[2], "TowerRail%d" % x, Vector3(0.35, 9.0, 0.35), Vector3(x * 0.7, 6.4, -1.6), "iron", iron, 0.07)
	for rung in range(15):
		G.box(groups[2], "TowerRung%d" % rung, Vector3(1.8, 0.1, 0.16), Vector3(0, 1.7 + rung * 0.64, -0.95), "brass", brass, 0.03)
	var gear := G.gear(groups[1], "DriveGear", 1.7, Vector3(2.8, 3.2, 0.8), 14)
	gear.rotation.x = PI * 0.5
	G.cylinder(groups[1], "PressureVessel", 0.85, 3.3, Vector3(-3.0, 3.3, 0), "copper", copper)
	G.cylinder(groups[1], "PressurePipe", 0.15, 3, Vector3(-1.8, 4.7, 0), "copper", copper).rotation.z = PI * 0.5
	if has_mechanical_refinement:
		var pulley_at := Vector3(0, 11, -1.6)
		var sheave := G.cylinder(groups[2], "TopPulley", 0.58, 0.36, pulley_at, "iron", iron)
		sheave.rotation.x = PI * 0.5
		_add_torus(groups[2], "TopPulleyRim", 0.43, 0.62, pulley_at, "brass", brass)
		var hub := G.cylinder(groups[2], "TopPulleyHub", 0.22, 0.52, pulley_at, "brass", brass)
		hub.rotation.x = PI * 0.5
	else:
		var pulley := G.gear(groups[2], "TopPulley", 0.7, Vector3(0, 11, -1.6), 10)
		pulley.rotation.x = PI * 0.5
	G.box(groups[2], "PulleyBracket", Vector3(1.8, 0.28, 0.7), Vector3(0, 10.7, -1.6), "iron", iron, 0.05)
	G.cylinder(groups[2], "WarningLamp", 0.2, 0.3, Vector3(0.8, 10.8, -1.6), "lamp", Color("dea14c"))
	if has_mechanical_refinement:
		_add_challenger_details(groups, refinement)
	if refinement in ["mechanical_readability_v3", "mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"]:
		_add_refinement_v3(groups, refinement)
	if refinement in ["mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"]:
		_add_refinement_v4(groups)
	if refinement in ["mechanical_readability_v5", "mechanical_readability_v6"]:
		_add_refinement_v5(groups)
	return groups


static func _add_challenger_details(groups: Array[Node3D], refinement: String) -> void:
	var iron := Color("263438")
	var brass := Color("c3964d")
	var copper := Color("9d5d3c")
	var wood := Color("60432f")
	# Give the machine distinct load-bearing timber, forged iron and brass
	# assemblies; add explicit controls and linkage where v1 reads as cylinders.
	for side in [-1.0, 1.0]:
		G.box(groups[0], "TimberSole_%s" % side, Vector3(3.1, 0.24, 0.72), Vector3(side * 2.95, 0.16, 0.0), "wood", wood, 0.08)
		G.box(groups[0], "ForgedFootShoe_%s" % side, Vector3(0.42, 0.18, 0.54), Vector3(side * 4.0, 0.13, 0.0), "iron", iron, 0.06)
		for height in [2.45, 3.8, 5.2, 6.6, 8.0]:
			G.box(groups[2], "RungCollar_%s_%.2f" % [side, height], Vector3(0.49, 0.22, 0.48), Vector3(side * 0.7, height, -1.6), "iron", iron, 0.04)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			G.cylinder(groups[0], "DeckRivet_%s_%s" % [x, z], 0.09, 0.08, Vector3(x * 3.45, 1.97, z * 2.42), "brass", brass)
	# A stepped mechanical linkage ties the pressure vessel to the winch shaft.
	G.cylinder(groups[1], "ShaftBearing", 0.34, 1.35, Vector3(1.45, 3.25, 0.8), "iron", iron).rotation.x = PI * 0.5
	G.cylinder(groups[1], "ShaftCollar", 0.44, 0.24, Vector3(1.45, 3.25, 1.55), "brass", brass).rotation.x = PI * 0.5
	G.box(groups[1], "GearboxHousing", Vector3(1.8, 1.15, 1.45), Vector3(2.05, 2.95, -0.1), "iron", Color("303b3b"), 0.18)
	if refinement not in ["mechanical_readability_v3", "mechanical_readability_v4"]:
		G.gear(groups[1], "GovernorGear", 0.68, Vector3(2.02, 2.98, 0.72), 10).rotation.x = PI * 0.5
	# Gauges use a dark face, brass bezel, pointer and a real connecting pipe.
	for index in range(2):
		var gauge_at := Vector3(-2.65 + index * 0.72, 5.25 + index * 0.42, 0.82)
		var gauge := Node3D.new()
		gauge.name = "PressureGauge%d" % index
		gauge.position = gauge_at
		gauge.rotation.x = PI * 0.5
		groups[1].add_child(gauge)
		G.cylinder(gauge, "BrassBezel", 0.42, 0.16, Vector3.ZERO, "brass", brass)
		G.cylinder(gauge, "EnamelDial", 0.33, 0.18, Vector3(0.0, 0.0, 0.09), "iron", Color("d6c79d"))
		var needle := G.box(gauge, "Needle", Vector3(0.045, 0.23, 0.04), Vector3(0.025, 0.0, 0.19), "copper", copper, 0.015)
		needle.rotation.z = -0.55 + index * 0.28
		G.cylinder(groups[1], "GaugeFeedPipe%d" % index, 0.075, 0.62, gauge_at + Vector3(0.0, -0.42, -0.08), "copper", copper)
	# Repeated mechanical stops, bolt heads and a safety chain give the close
	# render more scale cues without changing the project's construction bounds.
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var at := Vector3(cos(angle) * 1.95, 3.6 + sin(angle) * 1.95, -0.86)
		var drum_bolt := G.cylinder(groups[1], "DrumBolt%02d" % index, 0.11, 0.12, at, "brass", brass)
		drum_bolt.rotation.x = PI * 0.5
	for rung in [1, 4, 7, 10, 13]:
		G.cylinder(groups[2], "RungBolt%02d" % rung, 0.075, 0.1, Vector3(-0.7, 1.7 + rung * 0.64, -0.84), "brass", brass)


static func _add_refinement_v3(groups: Array[Node3D], refinement: String) -> void:
	var iron := Color("354347")
	var brass := Color("b78a42")
	# Spokes and separate hubs make each thin rim read as a supported winch wheel.
	var spoke_length := 1.95 if refinement in ["mechanical_readability_v4", "mechanical_readability_v5", "mechanical_readability_v6"] else 1.58
	for side in [-1.0, 1.0]:
		var hub := G.cylinder(groups[1], "SpoolHub_%s" % side, 0.52, 0.42, Vector3(0, 3.6, side * 1.08), "iron", iron)
		hub.rotation.x = PI * 0.5
		for spoke_index in range(8):
			var angle := TAU * float(spoke_index) / 8.0
			var spoke := G.box(groups[1], "SpoolSpoke_%s_%02d" % [side, spoke_index], Vector3(spoke_length, 0.16, 0.13), Vector3(cos(angle) * 1.36, 3.6 + sin(angle) * 1.36, side * 1.08), "iron", iron, 0.045)
			spoke.rotation.z = angle
			var pin := G.cylinder(groups[1], "SpokePin_%s_%02d" % [side, spoke_index], 0.075, 0.1, Vector3(cos(angle) * 2.0, 3.6 + sin(angle) * 2.0, side * 1.08), "brass", brass)
			pin.rotation.x = PI * 0.5
	# Put the second gear beyond the drum silhouette; a rod and two bearings
	# make its transfer path to the main drive wheel legible from the front.
	var governor := G.gear(groups[1], "GovernorGear", 0.58, Vector3(3.7, 5.15, 1.12), 12)
	governor.rotation.x = PI * 0.5
	G.cylinder(groups[1], "GovernorShaft", 0.13, 1.35, Vector3(3.1, 4.2, 1.1), "iron", iron).rotation.x = PI * 0.5
	G.box(groups[1], "GovernorLink", Vector3(0.14, 1.1, 0.16), Vector3(3.55, 4.25, 0.98), "iron", iron, 0.045)
	G.cylinder(groups[1], "GovernorValveWheel", 0.32, 0.12, Vector3(-2.35, 5.2, 0.96), "brass", brass).rotation.x = PI * 0.5
	# Bright enamel faces and pointers lie in the dial plane (local X/Z).
	for gauge_variant in groups[1].find_children("PressureGauge*", "Node3D", true, false):
		var gauge := gauge_variant as Node3D
		var dial := gauge.get_node_or_null("EnamelDial") as MeshInstance3D
		if dial != null:
			dial.material_override = Materials.get_material("paint", Color("e4d8bb"))
		var old_needle := gauge.get_node_or_null("Needle") as Node3D
		if old_needle != null:
			old_needle.visible = false
		var needle := G.box(gauge, "ReadoutNeedle", Vector3(0.035, 0.035, 0.22), Vector3(0.0, 0.0, 0.16), "copper", Color("7b3e2b"), 0.01)
		needle.rotation.y = -0.38
		G.cylinder(gauge, "NeedlePivot", 0.04, 0.05, Vector3(0.0, 0.0, 0.17), "brass", brass)
	# A muted X brace transfers the tower load back to the floor rails.
	for side in [-1.0, 1.0]:
		var brace := G.box(groups[2], "TowerDiagonalBrace_%s" % side, Vector3(0.16, 7.6, 0.18), Vector3(0.0, 6.25, -1.78 + side * 0.08), "iron", iron, 0.035)
		brace.rotation.z = deg_to_rad(side * 9.0)


static func _add_refinement_v4(groups: Array[Node3D]) -> void:
	var iron := Color("354347")
	var copper := Color("9d5d3c")
	var brass := Color("b78a42")
	# Reduce the square-post look without moving the functional centerline.
	for rail_variant in groups[2].find_children("TowerRail*", "MeshInstance3D", true, false):
		(rail_variant as MeshInstance3D).visible = false
	for side in [-1.0, 1.0]:
		G.cylinder(groups[2], "TubularTowerRail_%s" % side, 0.16, 9.0, Vector3(side * 0.7, 6.4, -1.6), "iron", iron)
	# Copper vessel bands break the unbroken cylinder surface at real joints.
	for index in range(2):
		var band := _add_torus(groups[1], "PressureVesselBand%d" % index, 0.78, 0.9, Vector3(-3.0, 2.2 + index * 2.2, 0.0), "copper", copper)
		band.rotation.x = PI * 0.5
	# Enlarge the instruments and bring their face hardware forward of the dial.
	for gauge_variant in groups[1].find_children("PressureGauge*", "Node3D", true, false):
		var gauge := gauge_variant as Node3D
		var index := 1 if String(gauge.name).ends_with("1") else 0
		gauge.position = Vector3(-3.15 + index * 0.86, 5.15 + index * 0.48, 0.93)
		gauge.scale = Vector3.ONE * 1.35
		var needle := gauge.get_node_or_null("ReadoutNeedle") as Node3D
		if needle != null:
			needle.position.z = 0.28
		var pivot := gauge.get_node_or_null("NeedlePivot") as Node3D
		if pivot != null:
			pivot.position.z = 0.28
		for tick_index in range(8):
			var angle := TAU * float(tick_index) / 8.0
			var tick := G.box(gauge, "DialTick%02d" % tick_index, Vector3(0.025, 0.025, 0.055), Vector3(cos(angle) * 0.255, 0.0, 0.255 + sin(angle) * 0.255), "iron", iron, 0.008)
			tick.rotation.y = -angle


static func _add_refinement_v5(groups: Array[Node3D]) -> void:
	var iron := Color("253239")
	var copper := Color("843b25")
	var ivory := Color("f1dfb5")
	var brass := Color("d0a24b")
	# CylinderMesh end faces are normal to local Y. Gauge overlays must advance
	# along local Y; previous iterations placed all readout parts on local Z,
	# leaving the real front face unmarked from the production camera.
	for gauge_variant in groups[1].find_children("PressureGauge*", "Node3D", true, false):
		var gauge := gauge_variant as Node3D
		var dial := gauge.get_node_or_null("EnamelDial") as MeshInstance3D
		if dial != null:
			dial.position = Vector3(0.0, 0.105, 0.0)
			dial.material_override = Materials.get_material("paint", ivory)
		var old_needle := gauge.get_node_or_null("ReadoutNeedle") as Node3D
		if old_needle != null:
			old_needle.visible = false
		var old_pivot := gauge.get_node_or_null("NeedlePivot") as MeshInstance3D
		if old_pivot != null:
			old_pivot.visible = false
		for tick_index in range(12):
			var angle := TAU * float(tick_index) / 12.0
			var tick := G.box(gauge, "FaceTick%02d" % tick_index, Vector3(0.045, 0.025, 0.085), Vector3(cos(angle) * 0.255, 0.22, sin(angle) * 0.255), "iron", iron, 0.008)
			tick.rotation.y = -angle
		# Radial hand in the dial's X/Z plane; a warm tip and central cap make
		# the readout remain legible at the actual citizen-scale render size.
		var hand := G.box(gauge, "FaceReadoutNeedle", Vector3(0.055, 0.035, 0.25), Vector3(0.0, 0.225, 0.02), "copper", copper, 0.012)
		hand.rotation.y = -0.48
		var hub := G.cylinder(gauge, "FaceNeedleHub", 0.055, 0.045, Vector3(0.0, 0.245, 0.0), "brass", brass)
		var counterweight := G.cylinder(gauge, "NeedleCounterweight", 0.034, 0.03, Vector3(0.0, 0.24, -0.085), "brass", brass)
		counterweight.rotation.x = PI * 0.5


static func _add_torus(parent: Node3D, label: String, inner_radius: float, outer_radius: float, at: Vector3, category: String, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 48
	mesh.ring_segments = 12
	item.mesh = mesh
	item.position = at
	item.material_override = Materials.get_material(category, color)
	parent.add_child(item)
	return item

static func animate(groups: Array[Node3D], completed: int, active: int, progress: float, deploying: bool, delta: float) -> void:
	for index in range(groups.size()):
		groups[index].visible = completed > index or (active == index and progress > 0.25)
	if groups.size() > 1 and (deploying or active == 1):
		var gear := groups[1].get_node_or_null("DriveGear") as Node3D
		if gear != null:
			gear.rotate_object_local(Vector3.UP, delta * 2.5)
