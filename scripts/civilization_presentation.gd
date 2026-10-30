extends Node
## Civilization-specific procedural presentation over the shared RoomScale simulation.
##
## This deliberately does not own navigation, needs, economy, task choice, build
## progress, or traversal eligibility. It translates those production systems
## into a civilization-specific visual language so pacing stays identical.

const CivilizationDefinition := preload("res://scripts/civilization_definition.gd")
const MaterialLibrary := preload("res://scripts/visuals/material_library.gd")
const Geometry := preload("res://scripts/visuals/visual_geometry.gd")
static var _leaf_mesh: ArrayMesh


static func uses_organic_combat(civilization: Dictionary) -> bool:
	return civilization.get("combat_style", "industrial") == "organic"


static func society_summary(runtimes: Array) -> String:
	var labels: PackedStringArray = []
	for runtime in runtimes:
		labels.append("%s %d" % [String(runtime.definition.display_name).to_upper(), runtime.living_population()])
	return "  /  ".join(labels)


func refresh_runtime(runtime: Node) -> void:
	if runtime.definition.citizen_style == "verdant_folk":
		for citizen in runtime.citizens:
			_style_verdant_citizen(citizen)
			_refresh_verdant_cargo(citizen)
		var growth_presenter: Node = get_tree().root.get_node("VerdantDevelopmentPresentation")
		for module in runtime.development.visuals.values():
			growth_presenter._style_module(module)
	elif runtime.definition.citizen_style == "scavenger_salvage":
		for citizen in runtime.citizens:
			_style_scavenger_citizen(citizen)

var definition: Dictionary = {}
var _scene_instance_id := 0
var _scene_applied := false
var _refresh_timer := 0.0
var _verdant_site: Node3D
var _verdant_vine: Node3D
var _vine_segments: Array[Node3D] = []
var _vine_thresholds: Array[int] = []
var _vine_anchor: Node3D
var _influence_root: Node3D
var _route_signature := ""
var _reclamation_applied := false
var _banner: Label
var _growth_magic: Node3D
var _magic_clock := 0.0


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
	if OS.get_environment("ROOMSCALE_CONFLICT") == "1": return
	_magic_clock += delta
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
	match String(definition.id):
		"verdant":
			_refresh_verdant_citizens(scene)
			_refresh_verdant_project(scene)
		"scavenger":
			_refresh_scavenger_citizens(scene)


func _reset_for_scene(scene: Node3D) -> void:
	_scene_instance_id = scene.get_instance_id()
	_scene_applied = false
	_refresh_timer = 0.0
	_verdant_site = null
	_verdant_vine = null
	_vine_segments.clear()
	_vine_thresholds.clear()
	_vine_anchor = null
	_influence_root = null
	_route_signature = ""
	_reclamation_applied = false
	_banner = null
	_growth_magic = null


func _try_apply_scene(scene: Node3D) -> void:
	if not scene.is_node_ready() or not scene.has_node("Settlement"):
		return
	var citizens_variant: Variant = scene.get("_citizens")
	if not (citizens_variant is Array) or citizens_variant.is_empty():
		return
	if not _ensure_banner(scene):
		return
	scene.set_meta("civilization_definition", definition.duplicate(true))
	match String(definition.id):
		"verdant":
			_apply_verdant_settlement(scene)
			_refresh_verdant_citizens(scene)
			_create_initial_influence(scene)
		"scavenger":
			_apply_scavenger_settlement(scene)
			_refresh_scavenger_citizens(scene)
	_scene_applied = true
	print("ROOMSCALE_CIVILIZATION_PRESENTATION_READY id=%s citizens=%d" % [definition.id, citizens_variant.size()])


func _ensure_banner(scene: Node3D) -> bool:
	# Overlay is the production CanvasLayer, not a Control. Readiness is retried
	# by _try_apply_scene so presentation is never marked applied without its UI.
	var overlay := scene.get_node_or_null("Overlay") as CanvasLayer
	if overlay == null or not overlay.is_node_ready():
		return false
	_banner = overlay.get_node_or_null("CivilizationBanner") as Label
	if _banner != null:
		_refresh_banner(scene)
		return true
	_banner = Label.new()
	_banner.name = "CivilizationBanner"
	_banner.size = Vector2(310, 64)
	_banner.add_theme_font_size_override("font_size", 17)
	_banner.add_theme_color_override("font_color", Color("fff2dc"))
	_banner.add_theme_color_override("font_outline_color", Color("263320"))
	_banner.add_theme_constant_override("outline_size", 5)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(_banner)
	_refresh_banner(scene)
	return true


func _refresh_banner(scene: Node3D) -> void:
	if not is_instance_valid(_banner):
		return
	_banner.position = Vector2(scene.get_viewport().get_visible_rect().size.x - 330, 176)
	var simulation := scene.get_node_or_null("CivilizationSimulation")
	if simulation != null:
		_banner.position.y = 126 if is_instance_valid(simulation.get("spectator")) else 320
	var text := "Civilization: %s" % String(definition.display_name)
	var construction := scene.get_node_or_null("ConstructionSystem")
	if construction != null and bool(construction.get("project_created")):
		var status: Dictionary = construction.status()
		var stage_id := String(status.get("active_stage", "locked"))
		var stage_name := stage_id.capitalize()
		if stage_id not in ["locked", "complete"]:
			stage_name = CivilizationDefinition.stage_name(definition, stage_id)
		text += "\n%s — %s" % [CivilizationDefinition.project_name(definition), stage_name]
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


func _apply_scavenger_settlement(scene: Node3D) -> void:
	var settlement := scene.get_node("Settlement") as Node3D
	if settlement.has_node("ScavengerVisualPass"):
		return
	var details := Node3D.new()
	details.name = "ScavengerVisualPass"
	details.set_meta("presentation_only", true)
	settlement.add_child(details)
	var dimensions := {
		"Workshop": Vector3(26.0, 20.0, 20.0),
		"Depot": Vector3(24.0, 13.0, 20.0),
		"Housing": Vector3(17.0, 7.0, 9.0),
		"WorkArea": Vector3(23.0, 9.0, 12.0),
	}
	var sheet_colors := [Color("536c7a"), Color("8d5841"), Color("b0804f"), Color("46575c")]
	for building_index in range(dimensions.size()):
		var building_name: String = ["Workshop", "Depot", "Housing", "WorkArea"][building_index]
		var building := settlement.get_node_or_null(building_name) as Node3D
		if building == null:
			continue
		var overlay := Node3D.new()
		overlay.name = "ScrapCladding"
		overlay.set_meta("presentation_only", true)
		building.add_child(overlay)
		var size: Vector3 = dimensions[building_name]
		var sheet_color: Color = sheet_colors[building_index % sheet_colors.size()]
		var roof_width := size.x * 0.30
		var roof_depth := size.z * 0.78
		for side in [-1.0, 1.0]:
			var side_sign := float(side)
			var x := side_sign * size.x * 0.22
			var sheet := Node3D.new()
			sheet.name = "ScrapRoofSection%d%s" % [building_index, side]
			sheet.position = Vector3(x, size.y * 0.92, 0)
			sheet.rotation.z = -side_sign * 0.16
			overlay.add_child(sheet)
			var roof_panel := Geometry.box(sheet, "ScrapRoofPanel", Vector3(roof_width, 0.18, roof_depth), Vector3.ZERO, "iron", sheet_color, 0.045)
			roof_panel.set_meta("presentation_only", true)
			for seam in [-1.0, 1.0]:
				Geometry.box(sheet, "RoofFold%s" % seam, Vector3(roof_width * 0.88, 0.055, 0.11), Vector3(0, 0.115, seam * roof_depth * 0.28), "iron", sheet_colors[(building_index + 1) % sheet_colors.size()], 0.018)
			for fastener in [-1.0, 1.0]:
				Geometry.box(sheet, "RoofFastener%s" % fastener, Vector3(0.15, 0.06, 0.15), Vector3(fastener * roof_width * 0.40, 0.125, -roof_depth * 0.38), "brass", Color("c39150"), 0.03)
		var side_panel_size := Vector3(0.16, maxf(1.5, size.y * 0.25), size.z * 0.30)
		for side in [-1.0, 1.0]:
			var side_sign := float(side)
			var panel_center := Vector3(side_sign * (size.x * 0.5 + 0.07), size.y * 0.56, 0)
			var side_panel := Geometry.box(overlay, "ScrapSidePanel%d%s" % [building_index, side], side_panel_size, panel_center, "iron", sheet_colors[(building_index + 2) % sheet_colors.size()], 0.04)
			side_panel.set_meta("presentation_only", true)
			for fastener in [-1.0, 1.0]:
				Geometry.box(overlay, "SideFastener%d%s%s" % [building_index, side, fastener], Vector3(0.08, 0.17, 0.17), Vector3(panel_center.x + side_sign * 0.09, panel_center.y, float(fastener) * side_panel_size.z * 0.36), "brass", Color("c39150"), 0.04)


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
	var root_deck := Geometry.cylinder(root, "RootDeck", 6.4, 0.42, Vector3(0, 0.21, 0), "wood", Color("6b5235"))
	root_deck.scale.z = 0.78
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var slat := Geometry.box(root, "BarkDeckSlat%d" % index, Vector3(0.18, 0.045, 8.4), Vector3.ZERO, "wood", Color("795b3c") if index % 2 == 0 else Color("634a33"), 0.03)
		slat.rotation.y = angle
		slat.position = Vector3(cos(angle) * 0.55, 0.435, sin(angle) * 0.55)
	for side in [-1.0, 1.0]:
		_segment(root, "TrunkPost%s" % side, Vector3(side * 5.8, 0.5, -3.6), Vector3(side * 5.2, 7.8, -3.2), 0.42, Color("67503a"))
		_segment(root, "FrontRoot%s" % side, Vector3(side * 5.6, 0.35, 4.0), Vector3(side * 3.2, 0.65, 0), 0.28, Color("59462f"))
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var leaf_center := direction * 2.55 + Vector3(0.0, 8.05 + float(index % 2) * 0.28, -1.0)
		_segment(root, "CanopyBranch%d" % index, Vector3(0.0, 7.5, -1.0), leaf_center, 0.14, Color("68513a"))
		var canopy_leaf := _leaf(root, "CanopyLeaf%d" % index, leaf_center, Vector3(4.1, 0.14, 0.62), Color("4f783d") if index % 2 == 0 else Color("668b48"), -angle)
		canopy_leaf.rotation.z = 0.035 + float(index % 2) * 0.035
		var lateral := Vector3(-direction.z, 0.0, direction.x)
		for pair_index in range(2):
			var branch_distance := 1.2 + float(pair_index) * 1.2
			for side in [-1.0, 1.0]:
				var leaflet_at := direction * branch_distance + lateral * float(side) * 0.36 + Vector3(0.0, 8.0 + float(pair_index % 2) * 0.12, -1.0)
				var leaflet := _leaf(root, "CanopySideLeaf%d_%d_%s" % [index, pair_index, side], leaflet_at, Vector3(0.98, 0.10, 0.32), Color("5a8541") if (index + pair_index) % 2 == 0 else Color("73944d"), -angle + PI * 0.5)
				leaflet.rotation.z = float(side) * 0.08
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
		for side in [-1.0, 1.0]:
			_segment(root, "DoorJamb%d_%s" % [index, side], Vector3(x + side * 0.72, 0.4, 1.72), Vector3(x + side * 0.66, 2.3, 1.65), 0.11, Color("59462f"))
		_segment(root, "DoorArch%d" % index, Vector3(x - 0.66, 2.3, 1.65), Vector3(x + 0.66, 2.3, 1.65), 0.11, Color("59462f"))
		_sphere(root, "WarmWindow%d" % index, Vector3(x, 3.0, 1.48), Vector3(0.72, 0.78, 0.16), Color("d6b66d"))
		for leaf_index in range(3):
			var roof_leaf := _leaf(root, "RoofLeaf%d_%d" % [index, leaf_index], Vector3(x - 0.9 + leaf_index * 0.9, 4.72 + float(leaf_index % 2) * 0.08, -0.05), Vector3(2.1, 0.16, 0.86), Color("527b3c") if leaf_index % 2 == 0 else Color("638947"), -0.25 + index * 0.22 + float(leaf_index - 1) * 0.16)
			roof_leaf.rotation.z = -0.06 + float(leaf_index % 2) * 0.12
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


func _refresh_scavenger_citizens(scene: Node3D) -> void:
	var citizens_variant: Variant = scene.get("_citizens")
	if not (citizens_variant is Array):
		return
	for citizen_variant in citizens_variant:
		var citizen := citizen_variant as Node3D
		if citizen == null:
			continue
		_style_scavenger_citizen(citizen)


func _style_scavenger_citizen(citizen: Node3D) -> void:
	var figure := citizen.get_node_or_null("Figure") as Node3D
	if figure == null or figure.has_meta("scavenger_styled"):
		return
	var citizen_index := int(citizen.get("citizen_id"))
	var coat_colors := [Color("536c8b"), Color("695647"), Color("596b70"), Color("72584a"), Color("68744f")]
	var coat := MaterialLibrary.get_material("citizen_fabric", coat_colors[citizen_index % coat_colors.size()], 0.94).duplicate() as StandardMaterial3D
	var leather := MaterialLibrary.get_material("leather", Color("493d35"), 0.86)
	var iron := MaterialLibrary.get_material("iron", Color("59646a"), 0.72)
	var brass := MaterialLibrary.get_material("brass", Color("b0804f"), 0.52)
	var glass := MaterialLibrary.get_material("glass", Color("8db8bc"), 0.22)
	for child in figure.get_children():
		if not child is MeshInstance3D:
			continue
		var mesh := child as MeshInstance3D
		var node_name := String(mesh.name)
		if node_name in ["Body", "ClockworkCap"]:
			mesh.material_override = coat.duplicate() as StandardMaterial3D
		elif node_name in ["LeftArm", "RightArm", "LeftLeg", "RightLeg", "CapBrim", "Belt", "ExplorerPack"] or node_name.begins_with("Boot"):
			mesh.material_override = leather
		elif node_name.begins_with("Goggle") or node_name.begins_with("ShoulderPlate"):
			mesh.material_override = iron
		elif node_name.begins_with("Lens"):
			mesh.material_override = glass
		elif node_name == "Buckle":
			mesh.material_override = brass
		elif node_name == "RoleChest":
			mesh.material_override = MaterialLibrary.get_material("paint", Color("b0804f"), 0.82)
	var head := figure.get_node_or_null("Head") as MeshInstance3D
	if head != null:
		head.material_override = MaterialLibrary.get_material("skin", Color("ddb98d"), 0.9)
	var body := figure.get_node_or_null("Body") as MeshInstance3D
	if body != null:
		var coat_color: Color = coat_colors[citizen_index % coat_colors.size()]
		body.material_override = MaterialLibrary.get_material("citizen_fabric", coat_color, 0.94)
		for garment_part in body.get_children():
			if garment_part is MeshInstance3D:
				var part_name := String(garment_part.name)
				if part_name == "TunicHem":
					(garment_part as MeshInstance3D).material_override = leather
				else:
					var trim_color := coat_color.darkened(0.14) if part_name == "TunicYoke" else coat_color.lightened(0.08)
					(garment_part as MeshInstance3D).material_override = MaterialLibrary.get_material("citizen_fabric", trim_color, 0.94)
	_style_mpfb_faction_body(citizen, figure, coat_colors[citizen_index % coat_colors.size()], "scavenger")
	if figure.has_node("CitizenArtAsset"):
		_build_mpfb_scavenger_details(figure)
	else:
		var patch_colors := [Color("a57c54"), Color("647b85"), Color("8d5841"), Color("8e805d")]
		var strap := Geometry.box(figure, "SalvageBackStrap", Vector3(0.034, 0.19, 0.02), Vector3(-0.045, 0.25, -0.09), "leather", Color("493d35"), 0.009)
		strap.rotation.z = 0.24
		Geometry.box(figure, "SalvageShoulderPatch", Vector3(0.064, 0.044, 0.072), Vector3(-0.098, 0.306, -0.01), "canvas", patch_colors[(citizen_index + 1) % patch_colors.size()], 0.012)
		Geometry.box(figure, "SalvageToolLoop", Vector3(0.075, 0.028, 0.03), Vector3(0.076, 0.146, -0.09), "iron", Color("56636a"), 0.008)
		for index in range(2):
			Geometry.box(figure, "FieldNotePatch%d" % index, Vector3(0.036, 0.044, 0.014), Vector3(-0.052 + index * 0.075, 0.211, 0.063), "canvas", patch_colors[(citizen_index + index) % patch_colors.size()], 0.007)
		Geometry.box(figure, "SalvageCapFlap", Vector3(0.12, 0.018, 0.035), Vector3(0, 0.445, -0.065), "leather", Color("493d35"), 0.008)
	figure.set_meta("scavenger_styled", true)


func _build_mpfb_scavenger_details(figure: Node3D) -> void:
	var cap := MeshInstance3D.new()
	cap.name = "SalvageWorkerCap"
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.5
	cap_mesh.height = 1.0
	cap_mesh.radial_segments = 16
	cap_mesh.rings = 8
	cap.mesh = cap_mesh
	cap.scale = Vector3(0.112, 0.043, 0.108)
	cap.position = Vector3(0.0, 0.469, 0.0)
	cap.material_override = MaterialLibrary.get_material("citizen_fabric", Color("48555b"), 0.92)
	figure.add_child(cap)
	Geometry.box(figure, "SalvageCapBrim", Vector3(0.12, 0.012, 0.073), Vector3(0.0, 0.451, 0.028), "leather", Color("493d35"), 0.006)


func _style_mpfb_faction_body(citizen: Node3D, figure: Node3D, coat_color: Color, style: String) -> void:
	if figure.has_meta("mpfb_faction_styled"):
		return
	var asset := figure.get_node_or_null("CitizenArtAsset") as Node3D
	if asset == null:
		return
	var leather_color := Color("765438") if style == "verdant" else Color("493d35")
	var role_badge := figure.get_node_or_null("RoleChest") as MeshInstance3D
	if role_badge != null:
		role_badge.scale = Vector3(0.58, 0.68, 0.75)
		if style == "scavenger":
			role_badge.visible = false
	var role_pack := citizen.get("_role_pack") as Node3D
	if role_pack != null:
		role_pack.scale = Vector3(0.76, 0.82, 0.76)
	var cargo := citizen.get("_cargo") as MeshInstance3D
	if cargo != null:
		cargo.scale = Vector3(0.78, 0.82, 0.78)
	var traversal_clip := citizen.get("_traversal_clip") as Node3D
	if traversal_clip != null:
		traversal_clip.scale = Vector3(0.8, 0.85, 0.8)
	var core_details: Array = citizen.get("_asset_detail_core_nodes")
	var close_details: Array = citizen.get("_asset_detail_close_nodes")
	for mesh_variant in asset.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_variant as MeshInstance3D
		var node_name := String(mesh.name).to_lower()
		if "clockworkmachinisthelmet" in node_name or "clockworkbootconstruction" in node_name or "clockworkpacktoppressuregauge" in node_name or "clockworkworkshopclothing" in node_name:
			mesh.visible = false
			core_details.erase(mesh)
			close_details.erase(mesh)
		elif "male_worksuit01" in node_name:
			_tint_existing_mesh_materials(mesh, coat_color.lightened(0.72))
		elif "shoes03" in node_name or "gloves_medium" in node_name:
			_tint_existing_mesh_materials(mesh, leather_color.lightened(0.55))
	figure.set_meta("mpfb_faction_styled", true)


func _tint_existing_mesh_materials(mesh: MeshInstance3D, tint: Color) -> void:
	if mesh.mesh == null:
		return
	var source_materials: Array[Material] = []
	for surface_index in range(mesh.mesh.get_surface_count()):
		source_materials.append(mesh.get_active_material(surface_index))
	mesh.material_override = null
	for surface_index in range(source_materials.size()):
		var source := source_materials[surface_index] as StandardMaterial3D
		if source == null:
			continue
		var tinted := source.duplicate() as StandardMaterial3D
		if tinted == null:
			continue
		tinted.albedo_color = source.albedo_color * tint
		mesh.set_surface_override_material(surface_index, tinted)


func _style_verdant_citizen(citizen: Node3D) -> void:
	var figure := citizen.get_node_or_null("Figure") as Node3D
	if figure == null:
		return
	# The shared LOD refresh controls visibility on these original details. Remove
	# only Clockwork ornaments from that visual list so close views cannot revive
	# goggles/plates; leave the original rig, limbs and animation references alive.
	var fine_details: Array = citizen.get("_fine_details")
	for child in figure.get_children():
		var child_name := String(child.name)
		if child_name in ["ClockworkCap", "CapBrim", "Buckle"] or child_name.begins_with("Goggle") or child_name.begins_with("Lens") or child_name.begins_with("ShoulderPlate"):
			child.visible = false
			fine_details.erase(child)
	if not figure.has_meta("verdant_styled"):
		var verdant_coats := [Color("68834b"), Color("a2784d"), Color("83618b"), Color("628b89"), Color("b58b4e")]
		_style_mpfb_faction_body(citizen, figure, verdant_coats[int(citizen.get("citizen_id")) % verdant_coats.size()], "verdant")
	if figure.has_meta("verdant_styled"):
		return
	figure.set_meta("verdant_styled", true)
	var body := figure.get_node_or_null("Body") as MeshInstance3D
	var head := figure.get_node_or_null("Head") as MeshInstance3D
	if body != null:
		var coats := [Color("68834b"), Color("a2784d"), Color("83618b"), Color("628b89"), Color("b58b4e")]
		var coat_color: Color = coats[int(citizen.get("citizen_id")) % coats.size()]
		body.material_override = MaterialLibrary.get_material("citizen_fabric", coat_color, 0.94)
		for garment_part in body.get_children():
			if garment_part is MeshInstance3D:
				var part_name := String(garment_part.name)
				var trim_color := Color("765438") if part_name == "TunicHem" else (coat_color.darkened(0.12) if part_name == "TunicYoke" else coat_color.lightened(0.08))
				(garment_part as MeshInstance3D).material_override = _material(trim_color, 0.96)
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
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.5
	cap_mesh.height = 1.0
	cap_mesh.radial_segments = 12
	cap_mesh.rings = 6
	cap.mesh = cap_mesh
	cap.position = Vector3(0, 0.475, 0)
	var mpfb_derived := figure.has_node("CitizenArtAsset")
	cap.scale = Vector3(0.10, 0.043, 0.10) if mpfb_derived else Vector3(0.18, 0.075, 0.17)
	cap.material_override = _material(Color("8a633b"), 0.95)
	figure.add_child(cap)
	_cylinder(figure, "AcornRim", 0.048 if mpfb_derived else 0.088, 0.008 if mpfb_derived else 0.012, Vector3(0, 0.451, 0), Color("65472f"))
	var cap_leaf := _leaf(figure, "CapLeaf", Vector3(0.045 if mpfb_derived else 0.075, 0.505, 0), Vector3(0.07, 0.016, 0.032) if mpfb_derived else Vector3(0.12, 0.025, 0.055), Color("5b873f"), 0.45)
	cap_leaf.rotation.z = 0.2
	if not mpfb_derived:
		for side in [-1.0, 1.0]:
			_sphere(figure, "Eye%s" % side, Vector3(side * 0.027, 0.409, 0.064), Vector3(0.015, 0.017, 0.011), Color("30291f"))
			_sphere(figure, "Ear%s" % side, Vector3(side * 0.068, 0.4, 0), Vector3(0.035, 0.026, 0.022), Color("ddb98d"))
		_sphere(figure, "Nose", Vector3(0, 0.389, 0.067), Vector3(0.023, 0.025, 0.028), Color("c89c74"))
	for side in [-1.0, 1.0]:
		var mantle := _leaf(figure, "LeafMantle%s" % side, Vector3(float(side) * 0.05, 0.245, -0.07), Vector3(0.17, 0.022, 0.072), Color("4f773b") if side < 0.0 else Color("628b45"), 0.0)
		mantle.quaternion = Quaternion(Vector3.UP, float(side) * 0.12) * Quaternion(Vector3(1.0, 1.0, 1.0).normalized(), TAU / 3.0)
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
	_refresh_verdant_stockpile(scene, construction)
	var old_site := scene.get_node_or_null("GrappleConstructionSite") as Node3D
	if old_site != null:
		old_site.visible = false
	if _verdant_site == null or not is_instance_valid(_verdant_site):
		_build_verdant_project(scene, construction)
	_update_verdant_project_stages(construction)
	_refresh_growth_magic(construction)
	var path_variant: Variant = construction.get("_deployment_path")
	if path_variant is Array and not path_variant.is_empty():
		_refresh_vine(scene, construction, path_variant)
	if bool(construction.get("traversal_deployed")) and not _reclamation_applied:
		_apply_traversal_reclamation(scene, construction)


func _refresh_verdant_stockpile(scene: Node3D, construction: Node) -> void:
	var stock := scene.get_node_or_null("Settlement/Depot/ConstructionStockpile") as Node3D
	if stock == null:
		return
	var organic := stock.get_node_or_null("VerdantStock") as Node3D
	if organic == null:
		for child in stock.get_children():
			if child is Node3D:
				child.visible = false
		organic = Node3D.new()
		organic.name = "VerdantStock"
		stock.add_child(organic)
		for resource in CivilizationDefinition.REQUIRED_RESOURCE_KEYS:
			for index in range(4 if resource != "mechanical_parts" else 3):
				var unit := Node3D.new()
				unit.name = "%s%d" % [resource, index]
				unit.position = Vector3(-3.6 if resource == "wood" else (0.0 if resource == "metal" else 3.6), 0.3 + float(index / 2) * 0.6, -0.6 + float(index % 2) * 1.2)
				if resource == "wood":
					unit.position.y = 0.06 + float(index / 2) * 0.32
				organic.add_child(unit)
				if resource == "wood":
					for fiber in range(3):
						_segment(unit, "Fiber%d" % fiber, Vector3(-0.7, fiber * 0.1, 0), Vector3(0.7, fiber * 0.1, 0), 0.06, Color("75904e"))
				else:
					_sphere(unit, "Pod", Vector3.ZERO, Vector3(0.6, 0.5, 0.6), Color("d39742") if resource == "metal" else Color("b9ad67"))
					_leaf(unit, "PodLeaf", Vector3(0, 0.27, 0), Vector3(0.6, 0.06, 0.25), Color("668844"), 0.3)
	var status: Dictionary = construction.status()
	var remaining: Dictionary = status.get("stockpile", {})
	for resource in CivilizationDefinition.REQUIRED_RESOURCE_KEYS:
		for index in range(4 if resource != "mechanical_parts" else 3):
			(organic.get_node("%s%d" % [resource, index]) as Node3D).visible = index < int(remaining.get(resource, 0))


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
		var top := Vector3(cos(angle + 0.45) * 0.75, 8.8, -1.6 + sin(angle + 0.45) * 0.75)
		_segment(lattice, "LatticeVine%d" % index, base, top, 0.16, Color("486b3a"))
		_leaf(lattice, "LatticeLeaf%d" % index, top * 0.7 + Vector3(0, 0.3, 0), Vector3(0.7, 0.08, 0.32), Color("6b9349"), angle)
	var bloom := Node3D.new()
	bloom.name = "BloomAnchor"
	_verdant_site.add_child(bloom)
	# Meet the shared real launcher tip exactly; presentation never moves it.
	_segment(bloom, "BloomStem", Vector3(0, 8.4, -1.6), Vector3(0, 11.0, -1.6), 0.19, Color("486b3a"))
	_sphere(bloom, "Bud", Vector3(0, 10.5, -1.6), Vector3(1.35, 1.6, 1.35), Color("8b9a4f"))
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		_leaf(bloom, "Petal%d" % index, Vector3(cos(angle) * 1.1, 10.5, -1.6 + sin(angle) * 1.1), Vector3(1.25, 0.10, 0.52), Color("879d55") if index % 2 == 0 else Color("d0a25a"), angle)
	_world_label(_verdant_site, "ProjectSign", CivilizationDefinition.project_name(definition).to_upper(), Vector3(0, 10.5, 2.8), Color("d9cf72"))
	_growth_magic = Node3D.new()
	_growth_magic.name = "GrowthMagic"
	_verdant_site.add_child(_growth_magic)
	for index in range(7):
		var mote := _sphere(_growth_magic, "SporeLight%d" % index, Vector3.ZERO, Vector3.ONE * (0.10 + float(index % 3) * 0.035), Color("e4d483"))
		var glow := mote.material_override as StandardMaterial3D
		glow.emission_enabled = true
		glow.emission = Color("cadd82")
		glow.emission_energy_multiplier = 1.6
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_growth_magic.visible = false


func _refresh_growth_magic(construction: Node) -> void:
	if not is_instance_valid(_growth_magic):
		return
	var status: Dictionary = construction.status()
	var growing := String(status.get("state", "")) == "DEPLOYING_TRAVERSAL" or (int(construction.get("_active_stage")) >= 0 and float(status.get("stage_progress", 0)) > 0)
	_growth_magic.visible = growing and not bool(construction.get("traversal_deployed"))
	if not _growth_magic.visible:
		return
	var height := 0.7 + float(maxi(0, int(construction.get("_active_stage")))) * 3.8
	for index in range(_growth_magic.get_child_count()):
		var angle := _magic_clock * 0.65 + TAU * float(index) / 7.0
		var mote := _growth_magic.get_child(index) as Node3D
		mote.position = Vector3(cos(angle) * 1.8, height + sin(angle * 1.5 + index) * 0.45, -1.6 + sin(angle) * 1.2)


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
		_build_vine(scene, path, construction.get("_deployment_segments"))
	var old_cable := scene.get_node_or_null("DeployedGrappleCable") as Node3D
	if old_cable != null:
		old_cable.visible = false
	var cursor := int(construction.get("_deployment_cursor"))
	var deployed := bool(construction.get("traversal_deployed"))
	for index in range(_vine_segments.size()):
		_vine_segments[index].visible = deployed or cursor >= _vine_thresholds[index]
	if _vine_anchor != null:
		var coarse_segments: Array = construction.get("_deployment_segments")
		_vine_anchor.visible = deployed or cursor >= coarse_segments.size()


func _build_vine(scene: Node3D, path: Array, coarse_segments: Array) -> void:
	if _verdant_vine != null and is_instance_valid(_verdant_vine):
		_verdant_vine.queue_free()
	_verdant_vine = Node3D.new()
	_verdant_vine.name = "VerdantTraversal"
	scene.add_child(_verdant_vine)
	_vine_segments.clear()
	_vine_thresholds.clear()
	for index in range(1, path.size()):
		var start: Vector3 = path[index - 1]
		var finish: Vector3 = path[index]
		var segment_root := Node3D.new()
		segment_root.name = "VineSegment%03d" % index
		_verdant_vine.add_child(segment_root)
		# Keep the real climbing axis thin enough to leave a half-inch body visible.
		_segment(segment_root, "Stem", start, finish, 0.036 + 0.004 * float(index % 3), Color("3f6a38"))
		var direction := (finish - start).normalized()
		var across := direction.cross(Vector3.UP).normalized()
		if across.length_squared() < 0.01:
			across = Vector3.RIGHT
		var side := across * (0.075 if index % 2 == 0 else -0.075)
		_segment(segment_root, "TwiningFiber", start + side, finish - side, 0.02, Color("8b8750"))
		if index % 2 == 0:
			var midpoint := (start + finish) * 0.5
			_leaf(segment_root, "Leaf", midpoint + across * 0.40 + Vector3(0, 0.04, 0), Vector3(0.42, 0.045, 0.19), Color("659248"), float(index) * 0.71)
		segment_root.visible = false
		_vine_segments.append(segment_root)
		_vine_thresholds.append(_deployment_threshold((start + finish) * 0.5, coarse_segments))
	_vine_anchor = Node3D.new()
	_vine_anchor.name = "LivingSurfaceAnchor"
	_vine_anchor.position = path.back()
	_verdant_vine.add_child(_vine_anchor)
	for index in range(7):
		var angle := TAU * float(index) / 7.0
		_leaf(_vine_anchor, "AnchorLeaf%d" % index, Vector3(cos(angle) * 0.32, 0.08, sin(angle) * 0.32), Vector3(0.5, 0.04, 0.2), Color("608b45"), angle)
	_vine_anchor.visible = false


func _deployment_threshold(midpoint: Vector3, coarse_segments: Array) -> int:
	# The navigation route subdivides coarse production cable sections. Reveal
	# each subdivision with its actual parent section, rather than comparing two
	# different array counts. The already-built lower tower has no cable section.
	for index in range(coarse_segments.size()):
		var segment := coarse_segments[index] as MeshInstance3D
		var half_axis := segment.quaternion * Vector3.UP * (segment.mesh as CylinderMesh).height * 0.5
		var start := segment.position - half_axis
		var direction := half_axis * 2.0
		var ratio := clampf((midpoint - start).dot(direction) / maxf(direction.length_squared(), 0.000001), 0, 1)
		if midpoint.distance_to(start + direction * ratio) < 0.001:
			return index + 1
	return 0


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
	var settlement := scene.get_node("Settlement") as Node3D
	var occupied: Array[Node3D] = []
	for child in settlement.get_children():
		if child is Node3D and child.has_node("VerdantOverlay"):
			occupied.append(child as Node3D)
	if occupied.is_empty():
		# Founders have only their real portable supplies; a mature grove is earned.
		_add_moss_patches(_influence_root, center, 3.0, count, "%s:founders" % room_definition.id, scene, {}, 0.8)
	else:
		for index in range(occupied.size()):
			var budget := count / occupied.size() + (1 if index < count % occupied.size() else 0)
			_add_moss_patches(_influence_root, occupied[index].global_position, 9.0, budget, "%s:%s:settlement" % [room_definition.id, occupied[index].name], scene, {}, 5.4)


func _apply_traversal_reclamation(scene: Node3D, construction: Node) -> void:
	_reclamation_applied = true
	if _influence_root == null:
		_create_initial_influence(scene)
	var room_definition: Dictionary = scene.get("_room_definition")
	var influence: Dictionary = definition.get("world_influence", {})
	var lower: Vector3 = construction.get("site_position")
	var upper: Vector3 = construction.get("target_anchor")
	var navigation: Node = construction.get("surface_navigation")
	var surface: Dictionary = navigation.regions.get(String(construction.get("target_region")), {})
	_add_moss_patches(_influence_root, lower, 4.5, int(influence.get("lower_anchor_patch_budget", 10)), "%s:%s:lower" % [room_definition.get("id", "room"), construction.get("target_region")], scene, {}, 2.0)
	_add_moss_patches(_influence_root, upper, 5.5, int(influence.get("surface_patch_budget", 12)), "%s:%s:surface" % [room_definition.get("id", "room"), construction.get("target_region")], scene, surface, 2.2)
	for index in range(3):
		var at := upper + Vector3(-1.4 + index * 1.4, 0, 1.1 + float(index % 2) * 0.7)
		if _surface_contains(surface, at, 0.6):
			at.y = float(surface.height)
			_mushroom(_influence_root, "SurfaceMushroom%d" % index, at, 0.32 + index * 0.05)
	print("ROOMSCALE_VERDANT_RECLAMATION target=%s lower_patches=%s surface_patches=%s" % [construction.get("target_region"), influence.get("lower_anchor_patch_budget", 10), influence.get("surface_patch_budget", 12)])


func _add_moss_patches(parent: Node3D, center: Vector3, radius: float, count: int, seed_text: String, scene: Node3D, surface: Dictionary = {}, patch_scale: float = 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(hash(seed_text))
	for index in range(count):
		var angle := rng.randf_range(0.0, TAU)
		var distance := sqrt(rng.randf()) * radius
		var at := center + Vector3(cos(angle) * distance, 0.035, sin(angle) * distance)
		if surface.is_empty():
			var supported := _floor_decoration_height(scene, at, patch_scale * 0.5)
			if is_nan(supported):
				continue
			at.y = supported + 0.035
		else:
			if not _surface_contains(surface, at, patch_scale * 0.5):
				continue
			at.y = float(surface.height) + 0.035
		var patch := _sphere(parent, "Moss_%s_%03d" % [abs(hash(seed_text)) % 10000, index], at, Vector3(rng.randf_range(0.55, 1.0) * patch_scale, 0.07, rng.randf_range(0.4, 0.9) * patch_scale), Color("4d7b3d") if index % 2 == 0 else Color("668b46"))
		patch.rotation.y = angle
		var root_start := center + Vector3(0, 0.05, 0)
		var supported := true
		var root_points: Array[Vector3] = []
		for step in range(9):
			var point := root_start.lerp(at, float(step) / 8.0)
			if surface.is_empty():
				var support_y := _floor_decoration_height(scene, point, 0.12)
				if is_nan(support_y):
					supported = false
					break
				point.y = support_y + 0.055
			else:
				if not _surface_contains(surface, point, 0.12):
					supported = false
					break
				point.y = float(surface.height) + 0.055
			root_points.append(point)
		if supported and patch_scale >= 2.0:
			for piece in range(1, root_points.size()):
				_segment(parent, "RootRunner_%s_%03d_%d" % [abs(hash(seed_text)) % 10000, index, piece], root_points[piece - 1], root_points[piece], 0.055, Color("645434"))
			var lobe_at := root_points[4]
			var lobe_supported := _surface_contains(surface, lobe_at, patch_scale * 0.5) if not surface.is_empty() else not is_nan(_floor_decoration_height(scene, lobe_at, patch_scale * 0.5))
			if lobe_supported:
				_sphere(parent, "MossRunner_%s_%03d" % [abs(hash(seed_text)) % 10000, index], lobe_at - Vector3.UP * 0.02, Vector3(patch_scale * 0.75, 0.07, patch_scale * 0.4), Color("426e35"))
		if index % 5 == 0:
			_leaf(parent, "Sprout_%s_%03d" % [abs(hash(seed_text)) % 10000, index], at + Vector3(0, 0.08, 0), Vector3(0.28, 0.025, 0.12), Color("7aa253"), angle)


func _surface_contains(surface: Dictionary, at: Vector3, margin: float) -> bool:
	if surface.is_empty():
		return false
	var center: Vector3 = surface.center
	var local := Vector2(at.x - center.x, at.z - center.z).rotated(deg_to_rad(float(surface.get("rotation_degrees", 0))))
	var half: Vector2 = surface.dimensions * 0.5 - Vector2.ONE * margin
	return absf(local.x) <= half.x and absf(local.y) <= half.y


func _floor_decoration_height(scene: Node3D, at: Vector3, margin: float) -> float:
	# Consult room geometry only for visual support. No collision or navigation
	# objects are added, and no decoration is suspended over an edge or furniture.
	var room: Dictionary = scene.get("_room_definition")
	var floor: Dictionary = room.get("floor", {})
	var floor_center := _vec3(floor.get("center", [0, 0, 0]))
	var dimensions: Array = floor.get("dimensions", room.dimensions)
	if absf(at.x - floor_center.x) > float(dimensions[0]) * 0.5 - margin or absf(at.z - floor_center.z) > float(dimensions[1]) * 0.5 - margin:
		return NAN
	var height := float(floor.get("height", 0))
	for object_variant in room.objects:
		var object: Dictionary = object_variant
		if String(object.kind) == "settlement":
			continue
		var center := _vec3(object.position)
		var local := Vector2(at.x - center.x, at.z - center.z).rotated(deg_to_rad(float(object.get("rotation_degrees", 0))))
		var half := Vector2(float(object.dimensions[0]), float(object.dimensions[2])) * 0.5
		if absf(local.x) > half.x + margin or absf(local.y) > half.y + margin:
			continue
		if bool(object.get("blocks_navigation", false)):
			return NAN
		if String(object.kind) == "rug":
			# A flat patch must fit entirely on one support, rather than hovering
			# across a raised rug edge. Thin roots can use their own small margin.
			if absf(local.x) > half.x - margin or absf(local.y) > half.y - margin:
				return NAN
			height = maxf(height, center.y + float(object.dimensions[1]))
	return height


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
	var category := "wood" if color.r > color.b * 1.15 and roughness > 0.55 else "paint"
	if color.g > color.r * 1.08 and color.g > color.b * 1.05:
		category = "living_organic"
	var material := MaterialLibrary.get_material(category, color, roughness).duplicate() as StandardMaterial3D
	if category == "living_organic":
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = color.a
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
	leaf.mesh = _shared_leaf_mesh()
	leaf.rotation.y = yaw
	leaf.rotation.z = 0.12
	var material := leaf.material_override as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return leaf


static func _shared_leaf_mesh() -> ArrayMesh:
	if _leaf_mesh != null:
		return _leaf_mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const LONGITUDINAL_SEGMENTS := 12
	for segment in range(LONGITUDINAL_SEGMENTS):
		var t0 := float(segment) / LONGITUDINAL_SEGMENTS
		var t1 := float(segment + 1) / LONGITUDINAL_SEGMENTS
		for lane in range(2):
			var u0 := -1.0 + float(lane)
			var u1 := u0 + 1.0
			var top00 := _leaf_point(t0, u0, true)
			var top10 := _leaf_point(t1, u0, true)
			var top11 := _leaf_point(t1, u1, true)
			var top01 := _leaf_point(t0, u1, true)
			_leaf_triangle(surface, top00, top10, top11)
			_leaf_triangle(surface, top00, top11, top01)
			var bottom00 := _leaf_point(t0, u0, false)
			var bottom10 := _leaf_point(t1, u0, false)
			var bottom11 := _leaf_point(t1, u1, false)
			var bottom01 := _leaf_point(t0, u1, false)
			_leaf_triangle(surface, bottom00, bottom11, bottom10)
			_leaf_triangle(surface, bottom00, bottom01, bottom11)
		# Raised central rib catches light and makes the plant forms read as leaves.
		var rib0_left := _leaf_point(t0, -0.04, true)
		var rib0_right := _leaf_point(t0, 0.04, true)
		var rib1_left := _leaf_point(t1, -0.04, true)
		var rib1_right := _leaf_point(t1, 0.04, true)
		_leaf_triangle(surface, rib0_left, rib1_left, rib1_right)
		_leaf_triangle(surface, rib0_left, rib1_right, rib0_right)
	surface.generate_normals()
	_leaf_mesh = surface.commit()
	return _leaf_mesh


static func _leaf_point(t: float, across: float, upper: bool) -> Vector3:
	var width := sin(t * PI) * 0.47
	var ridge := (1.0 - absf(across)) * 0.035
	var curve := sin(t * PI) * 0.035
	var skin := 0.008 if upper else -0.008
	return Vector3(t - 0.5, curve + ridge + skin, across * width)


static func _leaf_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _world_label(parent: Node3D, node_name: String, value: String, at: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = value
	label.position = at
	label.font_size = 24
	label.pixel_size = 0.014
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_modulate = Color("263320")
	label.outline_size = 4
	parent.add_child(label)
	return label
