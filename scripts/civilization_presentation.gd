extends Node
## Civilization-specific procedural presentation over the shared RoomScale simulation.
##
## This deliberately does not own navigation, needs, economy, task choice, build
## progress, or traversal eligibility. It translates those production systems
## into a civilization-specific visual language so pacing stays identical.

const CivilizationDefinition := preload("res://scripts/civilization_definition.gd")

var definition: Dictionary = {}
var _scene_instance_id := 0
var _scene_applied := false
var _refresh_timer := 0.0
var _verdant_site: Node3D
var _verdant_vine: Node3D
var _vine_segments: Array[Node3D] = []
var _vine_anchor: Node3D
var _influence_root: Node3D
var _route_signature := ""
var _reclamation_applied := false
var _banner: Label


func _ready() -> void:
	var loaded := CivilizationDefinition.load_requested()
	if not bool(loaded.ok):
		for diagnostic in loaded.errors:
			push_error("CIVILIZATIONDEFINITION_INVALID: %s" % diagnostic)
		get_tree().quit(2)
		return
	definition = loaded.definition
	print("ROOMSCALE_CIVILIZATION_PROFILE id=%s name=%s citizen_style=%s settlement_style=%s traversal_style=%s" % [definition.id, definition.display_name, definition.citizen_style, definition.settlement_style, definition.traversal_style])


func _process(delta: float) -> void:
	if definition.is_empty():
		return
	var scene := get_tree().current_scene as Node3D
	if scene == null:
		return
	if scene.get_instance_id() != _scene_instance_id:
		_reset_for_scene(scene)
	if not _scene_applied:
		_try_apply_scene(scene)
		return
	_refresh_timer += delta
	if _refresh_timer < 0.12:
		return
	_refresh_timer = 0.0
	_refresh_banner(scene)
	if String(definition.id) == "verdant":
		_refresh_verdant_citizens(scene)
		_refresh_verdant_project(scene)


func _reset_for_scene(scene: Node3D) -> void:
	_scene_instance_id = scene.get_instance_id()
	_scene_applied = false
	_refresh_timer = 0.0
	_verdant_site = null
	_verdant_vine = null
	_vine_segments.clear()
	_vine_anchor = null
	_influence_root = null
	_route_signature = ""
	_reclamation_applied = false
	_banner = null


func _try_apply_scene(scene: Node3D) -> void:
	if not scene.has_node("Settlement") or not scene.has_node("Overlay"):
		return
	var citizens_variant: Variant = scene.get("_citizens")
	if not (citizens_variant is Array) or citizens_variant.is_empty():
		return
	scene.set_meta("civilization_definition", definition.duplicate(true))
	_ensure_banner(scene)
	if String(definition.id) == "verdant":
		_apply_verdant_settlement(scene)
		_refresh_verdant_citizens(scene)
		_create_initial_influence(scene)
	_scene_applied = true
	print("ROOMSCALE_CIVILIZATION_PRESENTATION_READY id=%s citizens=%d" % [definition.id, citizens_variant.size()])


func _ensure_banner(scene: Node3D) -> void:
	var overlay := scene.get_node("Overlay") as Control
	_banner = overlay.get_node_or_null("CivilizationBanner") as Label
	if _banner != null:
		return
	_banner = Label.new()
	_banner.name = "CivilizationBanner"
	_banner.position = Vector2(16, 12)
	_banner.size = Vector2(420, 66)
	_banner.add_theme_font_size_override("font_size", 17)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(_banner)
	_refresh_banner(scene)


func _refresh_banner(scene: Node3D) -> void:
	if _banner == null:
		return
	var text := "Civilization: %s" % String(definition.display_name)
	var construction := scene.get_node_or_null("ConstructionSystem")
	if construction != null and bool(construction.get("project_created")):
		var status: Dictionary = construction.status()
		var stage_id := String(status.get("active_stage", "locked"))
		var stage_name := stage_id.capitalize()
		if stage_id not in ["locked", "complete"]:
			stage_name = CivilizationDefinition.stage_name(definition, stage_id)
		text += "\n%s — %s" % [CivilizationDefinition.project_name(definition), stage_name]
		var delivered: Dictionary = status.get("delivered", {})
		var required: Dictionary = status.get("required", {})
		var material_parts: Array[String] = []
		for resource in CivilizationDefinition.REQUIRED_RESOURCE_KEYS:
			if required.has(resource):
				material_parts.append("%s %s/%s" % [CivilizationDefinition.resource_name(definition, resource), delivered.get(resource, 0), required.get(resource, 0)])
		if not material_parts.is_empty():
			text += "\n" + "  •  ".join(material_parts)
	_banner.text = text


func _apply_verdant_settlement(scene: Node3D) -> void:
	var settlement := scene.get_node("Settlement") as Node3D
	var room_definition: Dictionary = scene.get("_room_definition")
	var start: Dictionary = room_definition.get("start", {})
	var infrastructure: Array = start.get("infrastructure", ["workshop", "depot", "housing", "work_area"])
	if infrastructure.is_empty():
		_style_founder_supplies(settlement)
		return
	for child in settlement.get_children():
		settlement.remove_child(child)
		child.free()
	var landmarks: Dictionary = room_definition.get("landmarks", {})
	if "workshop" in infrastructure and landmarks.has("workshop"):
		_build_growth_nursery(settlement, _vec3(landmarks.workshop))
	if "depot" in infrastructure and landmarks.has("depot"):
		_build_seed_cache(settlement, _vec3(landmarks.depot))
	if "housing" in infrastructure and landmarks.has("housing"):
		_build_pod_homes(settlement, _vec3(landmarks.housing))
	if "work_area" in infrastructure and landmarks.has("work_area"):
		_build_cultivation_circle(settlement, _vec3(landmarks.work_area))


func _style_founder_supplies(settlement: Node3D) -> void:
	var supplies := settlement.get_node_or_null("PortableSupplies") as Node3D
	if supplies == null:
		return
	for child in supplies.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = _material(Color("6c7e45"), 0.92)
	if not supplies.has_node("VerdantFounderMarker"):
		var marker := Node3D.new()
		marker.name = "VerdantFounderMarker"
		supplies.add_child(marker)
		_leaf(marker, "FounderLeafA", Vector3(-0.5, 0.34, 0), Vector3(0.34, 0.05, 0.18), Color("5f873e"), -0.35)
		_leaf(marker, "FounderLeafB", Vector3(0.5, 0.34, 0), Vector3(0.34, 0.05, 0.18), Color("769a4c"), 0.35)
		_sphere(marker, "FounderSporeLamp", Vector3(0, 0.48, 0), Vector3(0.16, 0.2, 0.16), Color("d8c964"))


func _build_growth_nursery(parent: Node3D, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Workshop"
	root.position = at
	parent.add_child(root)
	_box(root, "RootPlatform", Vector3(15, 0.5, 11), Vector3(0, 0.25, 0), Color("6b5235"), 0.96)
	for side in [-1.0, 1.0]:
		_segment(root, "TrunkPost%s" % side, Vector3(side * 5.8, 0.5, -3.6), Vector3(side * 5.2, 7.8, -3.2), 0.42, Color("67503a"))
		_segment(root, "FrontRoot%s" % side, Vector3(side * 5.6, 0.35, 4.0), Vector3(side * 3.2, 0.65, 0), 0.28, Color("59462f"))
	var canopy := _sphere(root, "LeafCanopy", Vector3(0, 8.2, -1.0), Vector3(13, 1.2, 9), Color("4f783d"))
	canopy.rotation.z = 0.04
	for index in range(5):
		var x := -4.0 + index * 2.0
		_sphere(root, "SeedPod%d" % index, Vector3(x, 5.8 + float(index % 2) * 0.6, -1.0), Vector3(0.8, 1.4, 0.8), Color("b49147"))
	for index in range(6):
		_leaf(root, "NurseryLeaf%d" % index, Vector3(-5.0 + index * 2.0, 1.0 + float(index % 3) * 0.25, 3.5), Vector3(1.2, 0.12, 0.55), Color("618943"), float(index) * 0.7)
	_world_label(root, "WorkshopLabel", "GROWTH NURSERY", Vector3(0, 10.2, 0), Color("d9cf72"))


func _build_seed_cache(parent: Node3D, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Depot"
	root.position = at
	parent.add_child(root)
	_box(root, "WovenFloor", Vector3(14, 0.45, 10), Vector3(0, 0.22, 0), Color("806744"), 0.98)
	for side in [-1.0, 1.0]:
		_segment(root, "Arch%sA" % side, Vector3(side * 5.2, 0.4, -3.4), Vector3(side * 4.7, 6.2, 0), 0.32, Color("5e4a34"))
		_segment(root, "Arch%sB" % side, Vector3(side * 4.7, 6.2, 0), Vector3(side * 5.2, 0.4, 3.4), 0.32, Color("5e4a34"))
	for index in range(6):
		var x := -4.5 + float(index % 3) * 4.5
		var z := -2.0 + float(index / 3) * 4.0
		_sphere(root, "CachePod%d" % index, Vector3(x, 1.0, z), Vector3(1.6, 1.7, 1.4), Color("8d7441") if index % 2 == 0 else Color("ad8648"))
	_world_label(root, "DepotLabel", "SEED CACHE", Vector3(0, 8.0, 0), Color("d9cf72"))


func _build_pod_homes(parent: Node3D, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Housing"
	root.position = at
	parent.add_child(root)
	for index in range(3):
		var x := -5.0 + index * 5.0
		_sphere(root, "HomePod%d" % index, Vector3(x, 2.3, 0), Vector3(3.6, 4.8, 3.5), Color("6f7c43") if index % 2 == 0 else Color("806644"))
		_box(root, "Door%d" % index, Vector3(1.1, 1.8, 0.28), Vector3(x, 1.25, 1.72), Color("3d4d2e"), 0.9)
		_leaf(root, "RoofLeaf%d" % index, Vector3(x, 4.7, 0), Vector3(3.8, 0.25, 2.0), Color("527b3c"), -0.25 + index * 0.22)
		_sphere(root, "GlowCap%d" % index, Vector3(x + 1.3, 1.4, 2.0), Vector3(0.35, 0.45, 0.35), Color("d7cf73"))
	_world_label(root, "HousingLabel", "POD HOMES", Vector3(0, 7.2, 0), Color("d9cf72"))


func _build_cultivation_circle(parent: Node3D, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "WorkArea"
	root.position = at
	parent.add_child(root)
	_cylinder(root, "CultivationMat", 6.5, 0.18, Vector3(0, 0.09, 0), Color("526a3d"))
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var p := Vector3(cos(angle) * 5.2, 0.45, sin(angle) * 5.2)
		_sphere(root, "GrowthStone%d" % index, p, Vector3(0.7, 0.5, 0.7), Color("88724f"))
	for index in range(4):
		_leaf(root, "WorkLeaf%d" % index, Vector3(-2.8 + index * 1.9, 0.65, 0), Vector3(1.5, 0.12, 0.7), Color("638d45"), float(index) * 0.8)
	_world_label(root, "WorkAreaLabel", "CULTIVATION CIRCLE", Vector3(0, 4.0, 0), Color("d9cf72"))


func _refresh_verdant_citizens(scene: Node3D) -> void:
	var citizens_variant: Variant = scene.get("_citizens")
	if not (citizens_variant is Array):
		return
	for citizen_variant in citizens_variant:
		var citizen := citizen_variant as Node3D
		if citizen == null:
			continue
		_style_verdant_citizen(citizen)
		_refresh_verdant_cargo(citizen)


func _style_verdant_citizen(citizen: Node3D) -> void:
	var figure := citizen.get_node_or_null("Figure") as Node3D
	if figure == null or figure.has_meta("verdant_styled"):
		return
	figure.set_meta("verdant_styled", true)
	var body := figure.get_node_or_null("Body") as MeshInstance3D
	var head := figure.get_node_or_null("Head") as MeshInstance3D
	if body != null:
		body.material_override = _material(Color("68834b") if int(citizen.get("citizen_id")) % 2 == 0 else Color("7a7048"), 0.94)
	if head != null:
		head.material_override = _material(Color("ddb98d"), 0.96)
	for limb_name in ["LeftArm", "RightArm", "LeftLeg", "RightLeg"]:
		var limb := figure.get_node_or_null(limb_name) as MeshInstance3D
		if limb != null:
			limb.material_override = _material(Color("5b4934"), 0.96)
	for child in figure.get_children():
		var child_name := String(child.name)
		if child_name in ["ClockworkCap", "CapBrim", "Buckle"] or child_name.begins_with("Goggle") or child_name.begins_with("Lens") or child_name.begins_with("ShoulderPlate"):
			child.visible = false
	var belt := figure.get_node_or_null("Belt") as MeshInstance3D
	if belt != null:
		belt.material_override = _material(Color("765438"), 0.95)
	var pack := figure.get_node_or_null("ExplorerPack") as MeshInstance3D
	if pack != null:
		pack.material_override = _material(Color("53653c"), 0.96)
	var cap := MeshInstance3D.new()
	cap.name = "AcornCap"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.025
	cap_mesh.bottom_radius = 0.105
	cap_mesh.height = 0.10
	cap_mesh.radial_segments = 12
	cap.mesh = cap_mesh
	cap.position = Vector3(0, 0.474, 0)
	cap.material_override = _material(Color("8a633b"), 0.95)
	figure.add_child(cap)
	var cap_leaf := _leaf(figure, "CapLeaf", Vector3(0.075, 0.505, 0), Vector3(0.12, 0.025, 0.055), Color("5b873f"), 0.45)
	cap_leaf.rotation.z = 0.2
	_leaf(figure, "LeafCloakLeft", Vector3(-0.06, 0.265, -0.07), Vector3(0.15, 0.025, 0.12), Color("4f773b"), -0.55)
	_leaf(figure, "LeafCloakRight", Vector3(0.06, 0.265, -0.07), Vector3(0.15, 0.025, 0.12), Color("628b45"), 0.55)
	if int(citizen.get("citizen_id")) % 4 == 0:
		_leaf(figure, "FaerieWingLeft", Vector3(-0.11, 0.31, -0.08), Vector3(0.16, 0.018, 0.08), Color("8cab68", 0.78), -0.75)
		_leaf(figure, "FaerieWingRight", Vector3(0.11, 0.31, -0.08), Vector3(0.16, 0.018, 0.08), Color("9db97a", 0.78), 0.75)
	var tool := figure.get_node_or_null("BuilderHammer") as Node3D
	if tool != null:
		for child in tool.get_children():
			if String(child.name) in ["HammerHead", "HammerFace"]:
				child.visible = false
		var handle := tool.get_node_or_null("Handle") as MeshInstance3D
		if handle != null:
			handle.material_override = _material(Color("5b4934"), 0.96)
		if not tool.has_node("GrowthHook"):
			_leaf(tool, "GrowthHook", Vector3(0, 0.115, 0), Vector3(0.13, 0.025, 0.06), Color("6c9148"), PI * 0.5)
	var clip := figure.get_node_or_null("CableSafetyClip") as Node3D
	if clip != null:
		var clamp := clip.get_node_or_null("CableClamp")
		if clamp != null:
			clamp.visible = false
		var lanyard := clip.get_node_or_null("SafetyLanyard") as MeshInstance3D
		if lanyard != null:
			lanyard.material_override = _material(Color("567543"), 0.96)


func _refresh_verdant_cargo(citizen: Node3D) -> void:
	var cargo := citizen.get("_cargo") as MeshInstance3D
	if cargo == null:
		return
	if not bool(citizen.get("carrying")):
		cargo.remove_meta("verdant_styled_for")
		return
	var resource := String(cargo.get_meta("cargo_resource", ""))
	if resource not in ["wood", "metal", "mechanical_parts"]:
		return
	if String(cargo.get_meta("verdant_styled_for", "")) == resource and cargo.has_node("VerdantCargo"):
		return
	for child in cargo.get_children():
		cargo.remove_child(child)
		child.free()
	cargo.mesh = null
	var root := Node3D.new()
	root.name = "VerdantCargo"
	cargo.add_child(root)
	if resource == "wood":
		for index in range(4):
			var y := 0.025 + index * 0.035
			_segment(root, "Fiber%d" % index, Vector3(-0.13, y, 0), Vector3(0.13, y + 0.015 * float(index % 2), 0), 0.018, Color("6c7e45"))
		for side in [-1.0, 1.0]:
			_segment(root, "FiberTie%s" % side, Vector3(side * 0.075, -0.01, -0.08), Vector3(side * 0.075, 0.14, 0.08), 0.012, Color("8a7045"))
	elif resource == "metal":
		_sphere(root, "ResinPod", Vector3.ZERO, Vector3(0.20, 0.16, 0.18), Color("d39742"))
		_leaf(root, "ResinLeaf", Vector3(0, 0.10, 0), Vector3(0.16, 0.025, 0.08), Color("668844"), 0.3)
	else:
		for index in range(3):
			var x := -0.075 + index * 0.075
			_sphere(root, "SporePod%d" % index, Vector3(x, 0.03 + float(index % 2) * 0.04, 0), Vector3(0.08, 0.11, 0.08), Color("b9ad67"))
	cargo.set_meta("verdant_styled_for", resource)


func _refresh_verdant_project(scene: Node3D) -> void:
	var construction := scene.get_node_or_null("ConstructionSystem")
	if construction == null or not bool(construction.get("project_created")):
		return
	var old_site := scene.get_node_or_null("GrappleConstructionSite") as Node3D
	if old_site != null:
		old_site.visible = false
	if _verdant_site == null or not is_instance_valid(_verdant_site):
		_build_verdant_project(scene, construction)
	_update_verdant_project_stages(construction)
	var path_variant: Variant = construction.get("_deployment_path")
	if path_variant is Array and not path_variant.is_empty():
		_refresh_vine(scene, construction, path_variant)
	if bool(construction.get("traversal_deployed")) and not _reclamation_applied:
		_apply_traversal_reclamation(scene, construction)


func _build_verdant_project(scene: Node3D, construction: Node) -> void:
	_verdant_site = Node3D.new()
	_verdant_site.name = "VerdantConstructionSite"
	_verdant_site.position = construction.get("site_position")
	scene.add_child(_verdant_site)
	var blueprint := _cylinder(_verdant_site, "GrowthBlueprint", 5.6, 0.04, Vector3(0, 0.08, 0), Color("4e7b47", 0.35))
	var mat := blueprint.material_override as StandardMaterial3D
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var root_bed := Node3D.new()
	root_bed.name = "RootBed"
	_verdant_site.add_child(root_bed)
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		_segment(root_bed, "Root%d" % index, Vector3(cos(angle) * 0.5, 0.15, sin(angle) * 0.5), Vector3(cos(angle) * 4.8, 0.22, sin(angle) * 3.5), 0.12, Color("5f4933"))
	var lattice := Node3D.new()
	lattice.name = "GrowthLattice"
	_verdant_site.add_child(lattice)
	for index in range(4):
		var angle := TAU * float(index) / 4.0
		var base := Vector3(cos(angle) * 1.8, 0.25, sin(angle) * 1.8)
		var top := Vector3(cos(angle + 0.45) * 0.75, 7.0, sin(angle + 0.45) * 0.75)
		_segment(lattice, "LatticeVine%d" % index, base, top, 0.16, Color("486b3a"))
		_leaf(lattice, "LatticeLeaf%d" % index, top * 0.7 + Vector3(0, 0.3, 0), Vector3(0.7, 0.08, 0.32), Color("6b9349"), angle)
	var bloom := Node3D.new()
	bloom.name = "BloomAnchor"
	_verdant_site.add_child(bloom)
	_sphere(bloom, "Bud", Vector3(0, 7.7, 0), Vector3(1.35, 1.6, 1.35), Color("8b9a4f"))
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		_leaf(bloom, "Petal%d" % index, Vector3(cos(angle) * 1.1, 7.7, sin(angle) * 1.1), Vector3(1.25, 0.10, 0.52), Color("879d55") if index % 2 == 0 else Color("d0a25a"), angle)
	_world_label(_verdant_site, "ProjectSign", CivilizationDefinition.project_name(definition).to_upper(), Vector3(0, 10.5, 2.8), Color("d9cf72"))


func _update_verdant_project_stages(construction: Node) -> void:
	if _verdant_site == null:
		return
	var completed := int(construction.get("_completed_stages"))
	var active := int(construction.get("_active_stage"))
	var progress := 0.0
	var status: Dictionary = construction.status()
	progress = float(status.get("stage_progress", 0.0))
	var groups := [_verdant_site.get_node("RootBed") as Node3D, _verdant_site.get_node("GrowthLattice") as Node3D, _verdant_site.get_node("BloomAnchor") as Node3D]
	for index in range(groups.size()):
		var group: Node3D = groups[index]
		group.visible = index < completed or index == active
		if index < completed:
			group.scale = Vector3.ONE
		elif index == active:
			var growth := 0.12 + clampf(progress, 0.0, 1.0) * 0.88
			group.scale = Vector3(growth, growth, growth)


func _refresh_vine(scene: Node3D, construction: Node, path: Array) -> void:
	var signature := "%d:%s:%s" % [path.size(), path.front(), path.back()]
	if _verdant_vine == null or not is_instance_valid(_verdant_vine) or signature != _route_signature:
		_route_signature = signature
		_build_vine(scene, path)
	var old_cable := scene.get_node_or_null("DeployedGrappleCable") as Node3D
	if old_cable != null:
		old_cable.visible = false
	var cursor := int(construction.get("_deployment_cursor"))
	var deployed := bool(construction.get("traversal_deployed"))
	for index in range(_vine_segments.size()):
		_vine_segments[index].visible = deployed or index < cursor
	if _vine_anchor != null:
		_vine_anchor.visible = deployed or cursor >= _vine_segments.size()


func _build_vine(scene: Node3D, path: Array) -> void:
	if _verdant_vine != null and is_instance_valid(_verdant_vine):
		_verdant_vine.queue_free()
	_verdant_vine = Node3D.new()
	_verdant_vine.name = "VerdantTraversal"
	scene.add_child(_verdant_vine)
	_vine_segments.clear()
	for index in range(1, path.size()):
		var start: Vector3 = path[index - 1]
		var finish: Vector3 = path[index]
		var segment_root := Node3D.new()
		segment_root.name = "VineSegment%03d" % index
		_verdant_vine.add_child(segment_root)
		_segment(segment_root, "Stem", start, finish, 0.055 + 0.008 * float(index % 3), Color("3f6a38"))
		if index % 4 == 0:
			var midpoint := (start + finish) * 0.5
			_leaf(segment_root, "Leaf", midpoint + Vector3(0.08, 0.04, 0), Vector3(0.30, 0.035, 0.13), Color("659248"), float(index) * 0.71)
		segment_root.visible = false
		_vine_segments.append(segment_root)
	_vine_anchor = Node3D.new()
	_vine_anchor.name = "LivingSurfaceAnchor"
	_vine_anchor.position = path.back()
	_verdant_vine.add_child(_vine_anchor)
	for index in range(7):
		var angle := TAU * float(index) / 7.0
		_leaf(_vine_anchor, "AnchorLeaf%d" % index, Vector3(cos(angle) * 0.32, 0.08, sin(angle) * 0.32), Vector3(0.5, 0.04, 0.2), Color("608b45"), angle)
	_vine_anchor.visible = false


func _create_initial_influence(scene: Node3D) -> void:
	_influence_root = scene.get_node_or_null("VerdantInfluence") as Node3D
	if _influence_root == null:
		_influence_root = Node3D.new()
		_influence_root.name = "VerdantInfluence"
		scene.add_child(_influence_root)
	var room_definition: Dictionary = scene.get("_room_definition")
	var center := Vector3.ZERO
	if room_definition.has("start"):
		center = _vec3(room_definition.start.get("origin", [0, 0, 0]))
	elif room_definition.has("landmarks") and room_definition.landmarks.has("housing"):
		center = _vec3(room_definition.landmarks.housing)
	var influence: Dictionary = definition.get("world_influence", {})
	var count := int(influence.get("settlement_patch_budget", 18))
	_add_moss_patches(_influence_root, center, 9.0, count, "%s:%s:settlement" % [room_definition.get("id", "room"), definition.id])


func _apply_traversal_reclamation(scene: Node3D, construction: Node) -> void:
	_reclamation_applied = true
	if _influence_root == null:
		_create_initial_influence(scene)
	var room_definition: Dictionary = scene.get("_room_definition")
	var influence: Dictionary = definition.get("world_influence", {})
	var lower: Vector3 = construction.get("site_position")
	var upper: Vector3 = construction.get("target_anchor")
	_add_moss_patches(_influence_root, lower, 4.5, int(influence.get("lower_anchor_patch_budget", 10)), "%s:%s:lower" % [room_definition.get("id", "room"), construction.get("target_region")])
	_add_moss_patches(_influence_root, upper + Vector3(0, 0.03, 0), 5.5, int(influence.get("surface_patch_budget", 12)), "%s:%s:surface" % [room_definition.get("id", "room"), construction.get("target_region")])
	for index in range(3):
		var offset := Vector3(-1.4 + index * 1.4, 0.12, 1.1 + float(index % 2) * 0.7)
		_mushroom(_influence_root, "SurfaceMushroom%d" % index, upper + offset, 0.22 + index * 0.03)
	print("ROOMSCALE_VERDANT_RECLAMATION target=%s lower_patches=%s surface_patches=%s" % [construction.get("target_region"), influence.get("lower_anchor_patch_budget", 10), influence.get("surface_patch_budget", 12)])


func _add_moss_patches(parent: Node3D, center: Vector3, radius: float, count: int, seed_text: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(hash(seed_text))
	for index in range(count):
		var angle := rng.randf_range(0.0, TAU)
		var distance := sqrt(rng.randf()) * radius
		var at := center + Vector3(cos(angle) * distance, 0.035, sin(angle) * distance)
		var patch := _sphere(parent, "Moss_%s_%03d" % [abs(hash(seed_text)) % 10000, index], at, Vector3(rng.randf_range(0.35, 0.85), 0.06, rng.randf_range(0.28, 0.72)), Color("4d7b3d") if index % 2 == 0 else Color("668b46"))
		patch.rotation.y = angle
		if index % 5 == 0:
			_leaf(parent, "Sprout_%s_%03d" % [abs(hash(seed_text)) % 10000, index], at + Vector3(0, 0.08, 0), Vector3(0.28, 0.025, 0.12), Color("7aa253"), angle)


func _mushroom(parent: Node3D, node_name: String, at: Vector3, size: float) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = at
	parent.add_child(root)
	_cylinder(root, "Stem", size * 0.28, size * 1.4, Vector3(0, size * 0.7, 0), Color("d7c7a0"))
	_sphere(root, "Cap", Vector3(0, size * 1.45, 0), Vector3(size * 1.3, size * 0.45, size * 1.3), Color("b77a58"))


func _vec3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO


func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, color: Color, roughness: float = 0.9) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = at
	item.material_override = _material(color, roughness)
	parent.add_child(item)
	return item


func _sphere(parent: Node3D, node_name: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	item.mesh = mesh
	item.position = at
	item.scale = size
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
	item.material_override = _material(color, 0.94)
	parent.add_child(item)
	return item


func _segment(parent: Node3D, node_name: String, start: Vector3, finish: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var direction := finish - start
	var item := _cylinder(parent, node_name, radius, maxf(0.001, direction.length()), (start + finish) * 0.5, color)
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
	label.font_size = 32
	label.pixel_size = 0.025
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_modulate = Color("263320")
	label.outline_size = 4
	parent.add_child(label)
	return label
