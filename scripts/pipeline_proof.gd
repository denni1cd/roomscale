extends Node3D
## Milestone 1: entirely code-generated room, all dimensions measured in inches.

const StrategyCameraController := preload("res://scripts/strategy_camera.gd")
const FloorNavigationController := preload("res://scripts/floor_navigation.gd")
const SurfaceNavigationController := preload("res://scripts/surface_navigation.gd")
const TaskCoordinatorController := preload("res://scripts/task_coordinator.gd")
const CitizenAgentController := preload("res://scripts/citizen_agent.gd")
const ConstructionSystemController := preload("res://scripts/construction_system.gd")
const RoomDefinitionLoader := preload("res://scripts/room_definition.gd")
const VisualResolver := preload("res://scripts/visuals/visual_resolver.gd")
const MaterialLibrary := preload("res://scripts/visuals/material_library.gd")
const SettlementDetails := preload("res://scripts/visuals/settlement_details.gd")
const CITIZEN_HEIGHT_INCHES := 0.5
const CROWN_INTERIOR_PROJECTION := 0.75

var ROOM_WIDTH := 240.0
var ROOM_DEPTH := 180.0
var WALL_HEIGHT := 72.0
const FLOOR_THICKNESS := 1.0
const CAPTURE_DELAY_SECONDS := 3.2

var _room_definition: Dictionary = {}
var _capture_timer := 0.0
var _capture_saved := false
var _materials: Dictionary = {}
var _visual_resolver := VisualResolver.new()
var _citizens: Array[Node3D] = []
var _animated_gear_roots: Array[Node3D] = []
var _presentation_clock := 0.0
var _boiler_light: OmniLight3D
var _task_coordinator: Node
var _construction_system: Node
var _ui_timer := 0.0
var _population_label: Label
var _activity_label: Label
var _focus_label: Label
var _surface_outlines: Dictionary = {}
var _cutaway_wall_group: Node3D
var _cutaway_wall_side := ""
var _reach_button: Button
var _goal_status_label: Label
var _project_status_label: Label
var _material_status_label: Label
var _build_status_label: Label
var _m6_status_label: Label
var _inspection_label: Label
var _presentation_mode := true
var _compact_status: Label
var _selected_citizen: Node3D
var _selected_surface := ""


func _ready() -> void:
	var room_id := OS.get_environment("ROOMSCALE_ROOM")
	if room_id.is_empty():
		room_id = "room_a"
	var loaded: Dictionary = RoomDefinitionLoader.load_requested()
	if not bool(loaded.ok):
		for diagnostic in loaded.errors:
			push_error("ROOMDEFINITION_INVALID room=%s: %s" % [room_id, diagnostic])
		get_tree().quit(1)
		return
	_room_definition = loaded.definition
	room_id = String(_room_definition.id)
	_build_room()
	_build_furniture()
	_build_settlement()
	_build_lighting()
	_build_camera()
	if not _build_population():
		return
	_build_ui()
	print("ROOMSCALE_M2_READY Godot=%s room=%s size=%.0fx%.0f in citizens=%d" % [Engine.get_version_info().string, _room_definition.id, ROOM_WIDTH, ROOM_DEPTH, _citizens.size()])


func _process(delta: float) -> void:
	_presentation_clock += delta
	var settlement := get_node_or_null("Settlement") as Node3D
	if settlement != null:
		SettlementDetails.animate(settlement, _presentation_clock)
	for index in range(_animated_gear_roots.size()):
		var gear := _animated_gear_roots[index]
		gear.rotation.y += delta * (0.72 if index % 2 == 0 else -0.58)
	if is_instance_valid(_boiler_light):
		_boiler_light.light_energy = 0.65 + 0.12 * (0.5 + 0.5 * sin(_presentation_clock * 2.0))
	_capture_timer += delta
	_ui_timer += delta
	if _ui_timer >= 0.2:
		_ui_timer = 0.0
		_update_population_ui()
	var camera_rig := get_node_or_null("CameraRig") as StrategyCameraController
	_update_cutaway_wall(camera_rig)
	var camera_settled := not is_instance_valid(camera_rig) or not camera_rig.is_camera_transition_active()
	if OS.get_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE") != "1" and not _capture_saved and _capture_timer >= CAPTURE_DELAY_SECONDS and (camera_settled or _capture_timer >= 8.0) and DisplayServer.get_name() != "headless":
		_capture_saved = true
		_capture_frame()


func _build_settlement() -> void:
	var settlement := Node3D.new()
	settlement.name = "Settlement"
	add_child(settlement)
	_build_workshop(settlement)
	_build_depot(settlement)
	_build_housing(settlement)
	_build_work_area(settlement)
	SettlementDetails.decorate(settlement, _room_definition)


func _build_workshop(parent: Node3D) -> void:
	var shop := Node3D.new()
	shop.name = "Workshop"
	shop.position = RoomDefinitionLoader.vector3_from(_room_definition.landmarks.workshop)
	parent.add_child(shop)
	_add_box(shop, "Foundation", Vector3(26.0, 1.0, 18.0), Vector3(0.0, 0.5, 0.0), Color("594b3a"), 0.86)
	_add_box(shop, "BackWall", Vector3(23.0, 8.0, 1.0), Vector3(0.0, 4.5, -8.0), Color("70533d"), 0.82)
	for x in [-11.0, 11.0]:
		_add_box(shop, "SideWall", Vector3(1.0, 8.0, 16.0), Vector3(x, 4.5, 0.0), Color("805e41"), 0.82)
	for x in [-8.5, 8.5]:
		_add_box(shop, "FrontWall", Vector3(6.0, 8.0, 1.0), Vector3(x, 4.5, 8.0), Color("775239"), 0.82)
	# Two roof wings leave an open inspection slot above the boiler and workbench.
	_add_box(shop, "RoofWingLeft", Vector3(10.0, 2.0, 20.0), Vector3(-8.0, 9.5, 0.0), Color("3d4d4c"), 0.7)
	_add_box(shop, "RoofWingRight", Vector3(10.0, 2.0, 20.0), Vector3(8.0, 9.5, 0.0), Color("465653"), 0.7)
	_add_box(shop, "SignBoard", Vector3(13.0, 2.6, 1.0), Vector3(0.0, 8.1, 9.0), Color("d4ae68"), 0.64)
	_add_box(shop, "WorkshopSign", Vector3(9.5, 0.7, 0.3), Vector3(0.0, 8.1, 9.7), Color("f0d79a"), 0.7)
	_add_cylinder(shop, "Boiler", 2.7, 8.0, Vector3(-6.5, 4.0, -2.0), Color("677875"))
	_add_cylinder(shop, "BoilerBand", 2.85, 0.65, Vector3(-6.5, 4.0, -2.0), Color("c7984e"))
	_add_cylinder(shop, "Chimney", 1.6, 9.0, Vector3(-6.5, 12.0, -2.0), Color("474542"))
	_add_box(shop, "WorkBench", Vector3(11.0, 1.2, 4.5), Vector3(3.5, 4.2, -2.0), Color("a27a4d"), 0.74)
	for x in [-0.5, 7.5]:
		_add_box(shop, "BenchLeg", Vector3(0.8, 4.0, 0.8), Vector3(x, 2.0, -2.0), Color("684a35"), 0.74)
	_build_animated_gear(shop, "BenchGear", Vector3(3.2, 5.1, -4.3), 1.8, 8)
	_add_cylinder(shop, "Gauge", 0.8, 0.45, Vector3(0.0, 7.0, 1.0), Color("d3c18f"))
	_add_world_label(shop, "WorkshopLabel", "WORKSHOP", Vector3(0.0, 14.0, 0.0), Color("f2d395"))
	_add_steam_emitter(shop, "BoilerSteam", Vector3(-6.5, 17.0, -2.0))
	_add_cylinder(shop, "BoilerGlow", 0.9, 0.4, Vector3(-6.5, 5.6, 0.76), Color("f0b55e"))
	_boiler_light = OmniLight3D.new()
	_boiler_light.name = "BoilerLamp"
	_boiler_light.position = Vector3(-6.5, 7.0, 0.76)
	_boiler_light.light_color = Color("f0a748")
	_boiler_light.light_energy = 0.8
	_boiler_light.omni_range = 12.0
	shop.add_child(_boiler_light)


func _build_depot(parent: Node3D) -> void:
	var depot := Node3D.new()
	depot.name = "Depot"
	depot.position = RoomDefinitionLoader.vector3_from(_room_definition.landmarks.depot)
	parent.add_child(depot)
	_add_box(depot, "Platform", Vector3(24.0, 1.0, 18.0), Vector3(0.0, 0.5, 0.0), Color("654a37"), 0.84)
	_add_box(depot, "BackWall", Vector3(22.0, 7.0, 1.0), Vector3(0.0, 4.0, -7.5), Color("9a7047"), 0.83)
	for x in [-10.5, 10.5]:
		_add_box(depot, "SidePost", Vector3(1.5, 7.0, 15.0), Vector3(x, 4.0, 0.0), Color("765139"), 0.8)
	_add_box(depot, "RoofWingLeft", Vector3(9.5, 1.6, 18.0), Vector3(-7.0, 8.0, 0.0), Color("a47b4e"), 0.72)
	_add_box(depot, "RoofWingRight", Vector3(9.5, 1.6, 18.0), Vector3(7.0, 8.0, 0.0), Color("b58b58"), 0.72)
	_add_box(depot, "Awning", Vector3(23.0, 1.2, 5.0), Vector3(0.0, 6.8, 9.5), Color("c6a166"), 0.83)
	_add_box(depot, "DepotSign", Vector3(11.0, 2.2, 0.8), Vector3(0.0, 6.1, 8.0), Color("c39b5a"), 0.68)
	for x in [-6.0, 0.0, 6.0]:
		_add_box(depot, "ResourceCrate", Vector3(4.8, 4.3, 4.6), Vector3(x, 2.7, -2.4), Color("b18450"), 0.84)
		_add_box(depot, "CrateBand", Vector3(5.0, 0.45, 4.8), Vector3(x, 3.0, -2.4), Color("d0a158"), 0.7)
	_add_cylinder(depot, "PartsBarrel", 2.6, 4.8, Vector3(7.0, 2.9, 4.4), Color("63756b"))
	_add_cylinder(depot, "BarrelHoop", 2.75, 0.45, Vector3(7.0, 2.9, 4.4), Color("c89a4e"))
	_add_world_label(depot, "DepotLabel", "DEPOT", Vector3(0.0, 12.0, 0.0), Color("f0d79a"))


func _build_housing(parent: Node3D) -> void:
	var housing := Node3D.new()
	housing.name = "Housing"
	housing.position = RoomDefinitionLoader.vector3_from(_room_definition.landmarks.housing)
	parent.add_child(housing)
	for index in range(2):
		var x := -4.2 + float(index) * 8.4
		_add_box(housing, "HutFloor", Vector3(7.4, 0.7, 7.0), Vector3(x, 0.35, 0.0), Color("745338"), 0.82)
		_add_box(housing, "TentBack", Vector3(7.0, 3.1, 0.6), Vector3(x, 2.2, -3.0), Color("9e7953"), 0.91)
		_add_box(housing, "TentLeft", Vector3(0.6, 3.1, 6.0), Vector3(x - 3.2, 2.2, 0.0), Color("bb9769"), 0.92)
		_add_box(housing, "TentRight", Vector3(0.6, 3.1, 6.0), Vector3(x + 3.2, 2.2, 0.0), Color("a78358"), 0.92)
		var roof_left := _add_box(housing, "CanvasRoof", Vector3(4.1, 0.45, 7.8), Vector3(x - 1.5, 4.15, 0.0), Color("c9ad7a"), 0.88)
		roof_left.rotation.z = deg_to_rad(-32.0)
		var roof_right := _add_box(housing, "CanvasRoof", Vector3(4.1, 0.45, 7.8), Vector3(x + 1.5, 4.15, 0.0), Color("9e8562"), 0.88)
		roof_right.rotation.z = deg_to_rad(32.0)
		_add_box(housing, "TentFlap", Vector3(3.0, 2.0, 0.3), Vector3(x, 1.55, 3.2), Color("806749"), 0.9)
	_add_cylinder(housing, "LanternPost", 0.28, 6.0, Vector3(0.0, 3.0, -6.0), Color("78583a"))
	_add_sphere(housing, "Lantern", Vector3(2.0, 2.0, 2.0), Vector3(0.0, 6.3, -6.0), Color("e4bf74"))
	_add_world_label(housing, "HousingLabel", "HOMES", Vector3(0.0, 9.5, 0.0), Color("f3dca9"))


func _build_work_area(parent: Node3D) -> void:
	var area := Node3D.new()
	area.name = "WorkArea"
	area.position = RoomDefinitionLoader.vector3_from(_room_definition.landmarks.work_area)
	parent.add_child(area)
	_add_box(area, "WorkMat", Vector3(23.0, 0.3, 12.0), Vector3(0.0, 0.2, 0.0), Color("80664b"), 0.91)
	_add_box(area, "AssemblyBench", Vector3(14.0, 1.0, 4.5), Vector3(0.0, 3.7, 0.0), Color("9a714a"), 0.74)
	for x in [-5.5, 5.5]:
		_add_box(area, "AssemblyLeg", Vector3(0.8, 3.4, 0.8), Vector3(x, 1.7, 0.0), Color("654933"), 0.76)
	_add_box(area, "GearBlank", Vector3(4.0, 0.8, 4.0), Vector3(-3.5, 4.6, 0.0), Color("d0a150"), 0.48)
	_add_cylinder(area, "PartsTin", 1.6, 3.0, Vector3(4.5, 5.5, 0.0), Color("64716b"))
	_add_world_label(area, "WorkAreaLabel", "WORK YARD", Vector3(0.0, 8.0, 0.0), Color("f1d59d"))


func _add_world_label(parent: Node3D, node_name: String, text: String, at: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = at
	label.font_size = 48
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_modulate = Color("342c21")
	label.outline_size = 4
	parent.add_child(label)


func _build_room() -> void:
	var room := Node3D.new()
	room.name = "Room"
	add_child(room)
	var dimensions: Array = _room_definition.dimensions
	var floor_definition: Dictionary = _room_definition.floor
	var floor_center := RoomDefinitionLoader.vector3_from(floor_definition.center)
	var floor_height := float(floor_definition.height)
	ROOM_WIDTH = float(dimensions[0])
	ROOM_DEPTH = float(dimensions[1])
	WALL_HEIGHT = float(_room_definition.wall_height)
	var floor_color := Color(String(_room_definition.get("floor_color", "795b43")))
	var room_shell_value: Variant = _room_definition.get("room_shell", {})
	var room_shell: Dictionary = room_shell_value if room_shell_value is Dictionary else {}
	var floor_appearance_value: Variant = room_shell.get("floor_appearance", {})
	var floor_appearance: Dictionary = floor_appearance_value if floor_appearance_value is Dictionary else {}
	floor_color = _appearance_color(floor_appearance, "base_color", floor_color)
	var floor_mesh := _add_box(room, "Floor", Vector3(ROOM_WIDTH, FLOOR_THICKNESS, ROOM_DEPTH), Vector3(floor_center.x, floor_height - FLOOR_THICKNESS * 0.5, floor_center.z), floor_color, 0.82)
	if not floor_appearance.is_empty():
		floor_mesh.material_override = _appearance_material(floor_appearance, floor_color, 0.82)
	if floor_appearance.is_empty() or String(floor_appearance.get("material", "")) == "wood":
		floor_mesh.material_override = MaterialLibrary.floor_material(floor_color.lerp(Color("7c8280"), 0.55))
	if String(floor_appearance.get("material", "")).to_lower() == "wood":
		var seam_count := maxi(1, floori(ROOM_WIDTH / 12.0))
		for index in range(1, seam_count):
			var x := floor_center.x - ROOM_WIDTH * 0.5 + float(index) * ROOM_WIDTH / float(seam_count)
			_add_box(room, "FloorSeam%02d" % index, Vector3(0.18, 0.025, ROOM_DEPTH - 1.0), Vector3(x, floor_height + 0.012, floor_center.z), floor_color.darkened(0.18), 0.92)
	if int(_room_definition.get("schema_version", 1)) >= 2:
		_build_data_room_shell(room, room_shell)
	else:
		_build_legacy_room_shell(room, floor_center, floor_height)


func _build_legacy_room_shell(room: Node3D, floor_center: Vector3, floor_height: float) -> void:
	_add_box(room, "WallBack", Vector3(ROOM_WIDTH, WALL_HEIGHT, 2.0), Vector3(floor_center.x, floor_height + WALL_HEIGHT * 0.5, floor_center.z - ROOM_DEPTH * 0.5), Color("d9c9aa"), 0.94)
	_add_box(room, "WallLeft", Vector3(2.0, WALL_HEIGHT, ROOM_DEPTH), Vector3(floor_center.x - ROOM_WIDTH * 0.5, floor_height + WALL_HEIGHT * 0.5, floor_center.z), Color("c6b99f"), 0.95)
	_add_box(room, "WallRight", Vector3(2.0, WALL_HEIGHT, ROOM_DEPTH), Vector3(floor_center.x + ROOM_WIDTH * 0.5, floor_height + WALL_HEIGHT * 0.5, floor_center.z), Color("c6b99f"), 0.95)
	_add_box(room, "BaseboardBack", Vector3(ROOM_WIDTH, 3.0, 1.0), Vector3(floor_center.x, floor_height + 1.5, floor_center.z - ROOM_DEPTH * 0.5 + 1.0), Color("76583f"), 0.78)
	_add_box(room, "BaseboardLeft", Vector3(1.0, 3.0, ROOM_DEPTH), Vector3(floor_center.x - ROOM_WIDTH * 0.5 + 1.0, floor_height + 1.5, floor_center.z), Color("76583f"), 0.78)
	_add_box(room, "BaseboardRight", Vector3(1.0, 3.0, ROOM_DEPTH), Vector3(floor_center.x + ROOM_WIDTH * 0.5 - 1.0, floor_height + 1.5, floor_center.z), Color("76583f"), 0.78)


func _build_data_room_shell(room: Node3D, shell: Dictionary) -> void:
	var walls: Array = shell.get("walls", [])
	var thickness := float(shell.get("wall_thickness", 2.0))
	var trim_height := float(shell.get("baseboard_height", 3.0))
	var cutaway_id := String(_room_definition.get("camera", {}).get("cutaway_wall_id", "")) if _room_definition.get("camera", {}) is Dictionary else ""
	var floor_center := RoomDefinitionLoader.vector3_from(_room_definition.floor.center)
	var floor_height := float(_room_definition.floor.height)
	var room_dimensions: Array = _room_definition.dimensions
	var trim_appearance_value: Variant = shell.get("baseboard_appearance", {})
	var trim_appearance: Dictionary = trim_appearance_value if trim_appearance_value is Dictionary else {}
	var trim_color := _appearance_color(trim_appearance, "base_color", Color("76583f"))
	var crown_height_value: Variant = shell.get("crown_molding_height", 0.0)
	var crown_height := float(crown_height_value) if RoomDefinitionLoader._positive_number(crown_height_value) else 0.0
	var crown_appearance_value: Variant = shell.get("crown_molding_appearance", {})
	var crown_appearance: Dictionary = crown_appearance_value if crown_appearance_value is Dictionary else {}
	var crown_color := _appearance_color(crown_appearance, "base_color", Color("76583f"))
	for wall_variant in walls:
		var wall: Dictionary = wall_variant
		var side := String(wall.side)
		var wall_visual := Node3D.new()
		wall_visual.name = "ShellWall_%s" % String(wall.id)
		room.add_child(wall_visual)
		if String(wall.get("id", "")) == cutaway_id:
			_cutaway_wall_group = wall_visual
			_cutaway_wall_side = side
		var side_length := float(room_dimensions[0]) if side in ["north", "south"] else float(room_dimensions[1])
		var appearance_value: Variant = wall.get("appearance", {})
		var appearance: Dictionary = appearance_value if appearance_value is Dictionary else {}
		var wall_color := _appearance_color(appearance, "base_color", Color("d9c9aa"))
		var openings_value: Variant = wall.get("openings", [])
		var openings: Array = openings_value if openings_value is Array else []
		openings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.offset) < float(b.offset))
		var cursor := 0.0
		for opening_variant in openings:
			var opening: Dictionary = opening_variant
			var offset := float(opening.offset)
			var opening_width := float(opening.width)
			var opening_bottom := float(opening.get("bottom", 0.0))
			var opening_height := float(opening.height)
			if offset > cursor:
				_add_shell_segment(wall_visual, "Wall_%s_%02d" % [side, int(cursor)], side, floor_center, room_dimensions, cursor, offset - cursor, 0.0, WALL_HEIGHT, thickness, wall_color, appearance)
			if opening_bottom > 0.0:
				_add_shell_segment(wall_visual, "Wall_%s_Sill_%s" % [side, opening.id], side, floor_center, room_dimensions, offset, opening_width, 0.0, opening_bottom, thickness, wall_color, appearance)
			var opening_top := opening_bottom + opening_height
			if opening_top < WALL_HEIGHT:
				_add_shell_segment(wall_visual, "Wall_%s_Head_%s" % [side, opening.id], side, floor_center, room_dimensions, offset, opening_width, opening_top, WALL_HEIGHT - opening_top, thickness, wall_color, appearance)
			_build_shell_opening(wall_visual, side, floor_center, room_dimensions, offset, opening_width, opening_bottom, opening_height, thickness, opening)
			cursor = offset + opening_width
		if cursor < side_length:
			_add_shell_segment(wall_visual, "Wall_%s_End" % side, side, floor_center, room_dimensions, cursor, side_length - cursor, 0.0, WALL_HEIGHT, thickness, wall_color, appearance)
		if trim_height > 0.0:
			var trim_cursor := 0.0
			for opening_variant in openings:
				var opening: Dictionary = opening_variant
				if float(opening.get("bottom", 0.0)) >= trim_height:
					continue
				var trim_offset := float(opening.offset)
				var trim_width := float(opening.width)
				if trim_offset > trim_cursor:
					_add_shell_segment(wall_visual, "Trim_%s_%02d" % [side, int(trim_cursor)], side, floor_center, room_dimensions, trim_cursor, trim_offset - trim_cursor, 0.0, trim_height, maxf(1.0, thickness * 0.7), trim_color, trim_appearance)
				trim_cursor = trim_offset + trim_width
			if trim_cursor < side_length:
				_add_shell_segment(wall_visual, "Trim_%s_End" % side, side, floor_center, room_dimensions, trim_cursor, side_length - trim_cursor, 0.0, trim_height, maxf(1.0, thickness * 0.7), trim_color, trim_appearance)
		if crown_height > 0.0:
			var crown_cursor := 0.0
			var crown_bottom := WALL_HEIGHT - crown_height
			for opening_variant in openings:
				var opening: Dictionary = opening_variant
				var opening_top := float(opening.get("bottom", 0.0)) + float(opening.height)
				if opening_top <= crown_bottom:
					continue
				var crown_offset := float(opening.offset)
				var crown_width := float(opening.width)
				if crown_offset > crown_cursor:
					_add_shell_segment(wall_visual, "Crown_%s_%02d" % [side, int(crown_cursor)], side, floor_center, room_dimensions, crown_cursor, crown_offset - crown_cursor, crown_bottom, crown_height, thickness + CROWN_INTERIOR_PROJECTION, crown_color, crown_appearance, CROWN_INTERIOR_PROJECTION * 0.5)
				crown_cursor = crown_offset + crown_width
			if crown_cursor < side_length:
				_add_shell_segment(wall_visual, "Crown_%s_End" % side, side, floor_center, room_dimensions, crown_cursor, side_length - crown_cursor, crown_bottom, crown_height, thickness + CROWN_INTERIOR_PROJECTION, crown_color, crown_appearance, CROWN_INTERIOR_PROJECTION * 0.5)
	var ceiling_appearance_value: Variant = shell.get("ceiling_appearance", {})
	if shell.has("ceiling_appearance") and ceiling_appearance_value is Dictionary:
		var ceiling_appearance: Dictionary = ceiling_appearance_value
		var ceiling_color := _appearance_color(ceiling_appearance, "base_color", Color("ece5d4"))
		var ceiling_mesh := MeshInstance3D.new()
		ceiling_mesh.name = "Ceiling"
		var plane := PlaneMesh.new()
		plane.size = Vector2(float(room_dimensions[0]), float(room_dimensions[1]))
		ceiling_mesh.mesh = plane
		ceiling_mesh.position = Vector3(floor_center.x, floor_height + WALL_HEIGHT, floor_center.z)
		var ceiling_material := _appearance_material(ceiling_appearance, ceiling_color, 1.0)
		ceiling_material.cull_mode = BaseMaterial3D.CULL_FRONT
		ceiling_mesh.material_override = ceiling_material
		room.add_child(ceiling_mesh)
	_update_cutaway_wall(get_node_or_null("CameraRig") as StrategyCameraController)


func _update_cutaway_wall(camera_rig: StrategyCameraController) -> void:
	if not is_instance_valid(_cutaway_wall_group) or not is_instance_valid(camera_rig):
		return
	var camera := camera_rig.get_node_or_null("Camera") as Camera3D
	if not is_instance_valid(camera):
		return
	var floor_center := RoomDefinitionLoader.vector3_from(_room_definition.floor.center)
	var viewer_offset := Vector2(camera.global_position.x - floor_center.x, camera.global_position.z - floor_center.z).normalized()
	var wall_normal := Vector2.ZERO
	match _cutaway_wall_side:
		"north": wall_normal = Vector2(0.0, -1.0)
		"south": wall_normal = Vector2(0.0, 1.0)
		"east": wall_normal = Vector2(1.0, 0.0)
		"west": wall_normal = Vector2(-1.0, 0.0)
	_cutaway_wall_group.visible = viewer_offset.dot(wall_normal) < 0.35


func _add_shell_segment(parent: Node3D, node_name: String, side: String, floor_center: Vector3, room_dimensions: Array, offset: float, length: float, bottom: float, height: float, thickness: float, color: Color, appearance: Dictionary, interior_offset: float = 0.0) -> void:
	if length <= 0.0 or height <= 0.0:
		return
	var position := Vector3.ZERO
	var size := Vector3.ZERO
	if side in ["north", "south"]:
		var z := floor_center.z - float(room_dimensions[1]) * 0.5 if side == "north" else floor_center.z + float(room_dimensions[1]) * 0.5
		position = Vector3(floor_center.x - float(room_dimensions[0]) * 0.5 + offset + length * 0.5, float(_room_definition.floor.height) + bottom + height * 0.5, z)
		size = Vector3(length, height, thickness)
	else:
		var x := floor_center.x - float(room_dimensions[0]) * 0.5 if side == "west" else floor_center.x + float(room_dimensions[0]) * 0.5
		position = Vector3(x, float(_room_definition.floor.height) + bottom + height * 0.5, floor_center.z - float(room_dimensions[1]) * 0.5 + offset + length * 0.5)
		size = Vector3(thickness, height, length)
	match side:
		"north": position.z += interior_offset
		"south": position.z -= interior_offset
		"east": position.x -= interior_offset
		"west": position.x += interior_offset
	var mesh := _add_box(parent, node_name, size, position, color, 0.9)
	mesh.material_override = _appearance_material(appearance, color, 0.9)


func _build_shell_opening(parent: Node3D, side: String, floor_center: Vector3, room_dimensions: Array, offset: float, width: float, bottom: float, height: float, wall_thickness: float, opening: Dictionary) -> void:
	var appearance_value: Variant = opening.get("appearance", {})
	var appearance: Dictionary = appearance_value if appearance_value is Dictionary else {}
	var kind := String(opening.kind)
	var archetype := String(appearance.get("archetype", "")).to_lower()
	var frame_color := _appearance_color(appearance, "accent_color", Color("76583f"))
	var frame_appearance := appearance.duplicate(true)
	frame_appearance["material"] = "wood"
	frame_appearance.erase("transparency")
	frame_appearance.erase("glass_color")
	var frame := 1.5
	var opening_thickness := maxf(0.35, wall_thickness * 0.25)
	var trimmed_width := maxf(0.5, width - frame * 2.0)
	var trimmed_height := maxf(0.5, height - frame * 2.0)
	_add_shell_segment(parent, "OpeningFrameLeft_%s" % opening.id, side, floor_center, room_dimensions, offset, frame, bottom, height, wall_thickness + 0.4, frame_color, frame_appearance)
	_add_shell_segment(parent, "OpeningFrameRight_%s" % opening.id, side, floor_center, room_dimensions, offset + width - frame, frame, bottom, height, wall_thickness + 0.4, frame_color, frame_appearance)
	_add_shell_segment(parent, "OpeningFrameHead_%s" % opening.id, side, floor_center, room_dimensions, offset + frame, trimmed_width, bottom + height - frame, frame, wall_thickness + 0.4, frame_color, frame_appearance)
	if bottom > 0.0:
		_add_shell_segment(parent, "OpeningFrameSill_%s" % opening.id, side, floor_center, room_dimensions, offset + frame, trimmed_width, bottom, frame, wall_thickness + 0.4, frame_color, frame_appearance)
	if kind == "opening":
		return
	var panel_position := Vector3.ZERO
	var panel_size := Vector3.ZERO
	var coordinate := offset + width * 0.5
	if side in ["north", "south"]:
		var z := floor_center.z - float(room_dimensions[1]) * 0.5 if side == "north" else floor_center.z + float(room_dimensions[1]) * 0.5
		panel_position = Vector3(floor_center.x - float(room_dimensions[0]) * 0.5 + coordinate, float(_room_definition.floor.height) + bottom + height * 0.5, z)
		panel_size = Vector3(trimmed_width, trimmed_height, opening_thickness)
	else:
		var x := floor_center.x - float(room_dimensions[0]) * 0.5 if side == "west" else floor_center.x + float(room_dimensions[0]) * 0.5
		panel_position = Vector3(x, float(_room_definition.floor.height) + bottom + height * 0.5, floor_center.z - float(room_dimensions[1]) * 0.5 + coordinate)
		panel_size = Vector3(opening_thickness, trimmed_height, trimmed_width)
	var panel_color := _appearance_color(appearance, "base_color", Color("819ba0") if kind == "window" else Color("795b43"))
	if kind == "window":
		var glass_appearance := appearance.duplicate(true)
		glass_appearance["material"] = "glass"
		glass_appearance["transparency"] = float(appearance.get("transparency", 0.36))
		_build_window_backdrop(parent, side, floor_center, room_dimensions, offset, width, bottom, height, wall_thickness, String(opening.id))
		var pane := _add_box(parent, "WindowPane_%s" % opening.id, panel_size, panel_position, panel_color, 0.22)
		pane.material_override = _appearance_material(glass_appearance, panel_color, 0.22)
		if archetype == "transomed_window":
			var bar_thickness := maxf(1.2, frame * 0.72)
			for fraction in [0.5, 0.78]:
				_add_shell_segment(parent, "WindowMuntinH_%s_%s" % [opening.id, str(fraction)], side, floor_center, room_dimensions, offset + frame, trimmed_width, bottom + height * fraction, bar_thickness, wall_thickness + 0.7, frame_color, frame_appearance)
			_add_shell_segment(parent, "WindowMuntinV_%s" % opening.id, side, floor_center, room_dimensions, offset + width * 0.5 - bar_thickness * 0.5, bar_thickness, bottom + frame, trimmed_height, wall_thickness + 0.7, frame_color, frame_appearance)
		elif archetype == "shaded_window":
			var bar_thickness := maxf(1.2, frame * 0.72)
			var shade_bottom := bottom + height * 0.37
			var shade_height := height * 0.59
			var shade_color := Color("eee9df")
			var inside_offset := opening_thickness * 0.5 + 0.18
			_add_shell_segment(parent, "RollerShade_%s" % opening.id, side, floor_center, room_dimensions, offset + frame + 0.5, trimmed_width - 1.0, shade_bottom, shade_height, opening_thickness * 0.4, shade_color, {"material":"fabric"}, inside_offset)
			for fold_index in range(1, 9):
				var fold_y := shade_bottom + shade_height * float(fold_index) / 9.0
				_add_shell_segment(parent, "ShadeFold_%s_%d" % [opening.id, fold_index], side, floor_center, room_dimensions, offset + frame + 0.5, trimmed_width - 1.0, fold_y, 0.42, opening_thickness * 0.45, Color("d3cec3"), {"material":"fabric"}, inside_offset + 0.12)
			_add_shell_segment(parent, "ShadedWindowMuntinV_%s" % opening.id, side, floor_center, room_dimensions, offset + width * 0.5 - bar_thickness * 0.5, bar_thickness, bottom + frame, trimmed_height, wall_thickness + 0.7, frame_color, frame_appearance)
			_add_shell_segment(parent, "ShadedWindowMuntinH_%s" % opening.id, side, floor_center, room_dimensions, offset + frame, trimmed_width, bottom + height * 0.36 - bar_thickness * 0.5, bar_thickness, wall_thickness + 0.7, frame_color, frame_appearance)
	elif kind == "door" and archetype in ["french_door", "sliding_glass_door"]:
		var glass_appearance := appearance.duplicate(true)
		glass_appearance["material"] = "glass"
		glass_appearance["transparency"] = float(appearance.get("transparency", 0.48))
		var door_glass_color := _appearance_color(appearance, "glass_color", Color("9bb7b6"))
		var glass_name := "SlidingDoorGlass" if archetype == "sliding_glass_door" else "FrenchDoorGlass"
		var glass := _add_box(parent, "%s_%s" % [glass_name, opening.id], panel_size, panel_position, door_glass_color, 0.22)
		glass.material_override = _appearance_material(glass_appearance, door_glass_color, 0.22)
		var bar_thickness := maxf(1.2, frame * 0.72)
		if archetype == "sliding_glass_door":
			_add_shell_segment(parent, "SlidingDoorStile_%s" % opening.id, side, floor_center, room_dimensions, offset + width * 0.5 - bar_thickness * 0.5, bar_thickness, bottom + frame, trimmed_height, wall_thickness + 0.7, frame_color, frame_appearance)
			_add_shell_segment(parent, "SlidingDoorTopRail_%s" % opening.id, side, floor_center, room_dimensions, offset + frame, trimmed_width, bottom + height - frame * 2.0, bar_thickness, wall_thickness + 0.7, frame_color, frame_appearance)
			_add_shell_segment(parent, "SlidingDoorHandle_%s" % opening.id, side, floor_center, room_dimensions, offset + width * 0.63, 1.25, bottom + height * 0.47, 12.0, wall_thickness + 0.8, frame_color.darkened(0.24), frame_appearance, opening_thickness * 0.6)
		else:
			for fraction in [0.25, 0.5, 0.75]:
				_add_shell_segment(parent, "FrenchDoorMuntinV_%s_%s" % [opening.id, str(fraction)], side, floor_center, room_dimensions, offset + width * fraction - bar_thickness * 0.5, bar_thickness, bottom + frame, trimmed_height, wall_thickness + 0.7, frame_color, frame_appearance)
			for fraction in [0.34, 0.67]:
				_add_shell_segment(parent, "FrenchDoorMuntinH_%s_%s" % [opening.id, str(fraction)], side, floor_center, room_dimensions, offset + frame, trimmed_width, bottom + height * fraction - bar_thickness * 0.5, bar_thickness, wall_thickness + 0.7, frame_color, frame_appearance)
	else:
		var door := _add_box(parent, "DoorPanel_%s" % opening.id, panel_size, panel_position, panel_color, 0.72)
		door.material_override = _appearance_material(appearance, panel_color, 0.72)


func _build_window_backdrop(parent: Node3D, side: String, floor_center: Vector3, room_dimensions: Array, offset: float, width: float, bottom: float, height: float, wall_thickness: float, opening_id: String) -> void:
	var floor_height := float(_room_definition.floor.height)
	var horizontal := side in ["north", "south"]
	var outside_sign := -1.0 if side in ["north", "west"] else 1.0
	var center_x := floor_center.x
	var center_z := floor_center.z
	if horizontal:
		center_x = floor_center.x - float(room_dimensions[0]) * 0.5 + offset + width * 0.5
		center_z = floor_center.z + (outside_sign * (float(room_dimensions[1]) * 0.5 + wall_thickness * 0.5 + 1.0))
	else:
		center_x = floor_center.x + (outside_sign * (float(room_dimensions[0]) * 0.5 + wall_thickness * 0.5 + 1.0))
		center_z = floor_center.z - float(room_dimensions[1]) * 0.5 + offset + width * 0.5
	var outward := Vector3(0.0, 0.0, outside_sign) if horizontal else Vector3(outside_sign, 0.0, 0.0)
	var background_depth := maxf(140.0, maxf(float(room_dimensions[0]), float(room_dimensions[1])) * 0.75)
	var sky_size := Vector3(width * 1.8, height * 1.5, 0.5) if horizontal else Vector3(0.5, height * 1.5, width * 1.8)
	var sky_center := Vector3(center_x, floor_height + bottom + height * 0.5, center_z) + outward * background_depth
	_add_box(parent, "ExteriorSky_%s" % opening_id, sky_size, sky_center, Color("7eaeb2"), 1.0)
	var ground_size := Vector3(width * 1.8, height * 0.56, 0.4) if horizontal else Vector3(0.4, height * 0.56, width * 1.8)
	var ground_center := sky_center + Vector3(0.0, -height * 0.22, 0.0)
	_add_box(parent, "ExteriorGreenery_%s" % opening_id, ground_size, ground_center, Color("59784d"), 1.0)
	var deck_center := Vector3(center_x, floor_height + bottom + height * 0.10, center_z) + outward * 28.0
	var deck_size := Vector3(width * 1.15, 1.4, 38.0) if horizontal else Vector3(38.0, 1.4, width * 1.15)
	_add_box(parent, "ExteriorDeck_%s" % opening_id, deck_size, deck_center, Color("8c6947"), 0.88)
	var rail_y := floor_height + bottom + height * 0.42
	var rail_center := Vector3(center_x, rail_y, center_z) + outward * 40.0
	var top_rail_size := Vector3(width, 2.0, 0.9) if horizontal else Vector3(0.9, 2.0, width)
	var lower_rail_size := Vector3(width, 1.4, 0.7) if horizontal else Vector3(0.7, 1.4, width)
	_add_box(parent, "PorchRailTop_%s" % opening_id, top_rail_size, rail_center, Color("947651"), 0.82)
	_add_box(parent, "PorchRailLower_%s" % opening_id, lower_rail_size, rail_center + Vector3(0.0, -height * 0.17, 0.0), Color("806443"), 0.84)
	var post_count := maxi(3, roundi(width / 12.0))
	var post_height := height * 0.24
	for post_index in range(post_count + 1):
		var fraction := float(post_index) / float(post_count)
		var along := lerpf(-width * 0.5, width * 0.5, fraction)
		var post_center := rail_center + Vector3(along, -height * 0.12, 0.0) if horizontal else rail_center + Vector3(0.0, -height * 0.12, along)
		var post_size := Vector3(1.0, post_height, 0.8) if horizontal else Vector3(0.8, post_height, 1.0)
		_add_box(parent, "PorchRailPost_%s_%d" % [opening_id, post_index], post_size, post_center, Color("a08763"), 0.84)
	var foliage_colors := [Color("294b36"), Color("3b6240"), Color("4d7046")]
	for tree_index in range(4):
		var tree_fraction := float(tree_index + 1) / 5.0
		var tree_along := (tree_fraction - 0.5) * width * 0.9
		var tree_distance := 66.0 + float(tree_index % 2) * 22.0
		var tree_base := Vector3(center_x, floor_height + bottom + height * 0.06, center_z) + outward * tree_distance
		if horizontal:
			tree_base.x += tree_along
		else:
			tree_base.z += tree_along
		var trunk_height := height * (0.34 + float(tree_index % 3) * 0.035)
		_add_cylinder(parent, "ExteriorTreeTrunk_%s_%d" % [opening_id, tree_index], 1.1, trunk_height, tree_base + Vector3(0.0, trunk_height * 0.5, 0.0), Color("66503a"))
		var canopy_center := tree_base + Vector3(0.0, trunk_height + height * 0.16, 0.0)
		var canopy_size := Vector3(15.0, 16.0, 12.0) if horizontal else Vector3(12.0, 16.0, 15.0)
		_add_sphere(parent, "ExteriorTreeCanopy_%s_%d" % [opening_id, tree_index], canopy_size, canopy_center, foliage_colors[tree_index % foliage_colors.size()])
		var side_shift := Vector3(7.0, -3.0, 0.0) if horizontal else Vector3(0.0, -3.0, 7.0)
		_add_sphere(parent, "ExteriorTreeCanopyLobe_%s_%d" % [opening_id, tree_index], canopy_size * 0.62, canopy_center + side_shift, foliage_colors[(tree_index + 1) % foliage_colors.size()])


func _build_furniture() -> void:
	var furniture := Node3D.new()
	furniture.name = "RoomObjects"
	add_child(furniture)
	for object_variant in _room_definition.objects:
		var object: Dictionary = object_variant
		if String(object.kind) != "settlement":
			_build_room_object(furniture, object)


func _build_room_object(parent: Node3D, object: Dictionary) -> void:
	var dims_array: Array = object.dimensions
	var dimensions := Vector3(float(dims_array[0]), float(dims_array[1]), float(dims_array[2]))
	var position := RoomDefinitionLoader.vector3_from(object.position)
	var root := Node3D.new()
	root.name = String(object.id)
	root.position = position
	root.rotation_degrees.y = float(object.get("rotation_degrees", 0.0))
	root.set_meta("semantic_name", String(object.get("name", object.id)))
	parent.add_child(root)
	_visual_resolver.render(root, object, _render_object_fallback)
	if object.has("surface"):
		var surface: Dictionary = object.surface
		var region_id := String(surface.region_id)
		var surface_height := float(surface.height)
		var body := StaticBody3D.new()
		body.name = "GoalSurfaceCollider"
		body.add_to_group("goal_surface")
		body.set_meta("region_id", region_id)
		body.set_meta("semantic_name", String(object.get("name", object.id)))
		body.collision_layer = 2
		body.collision_mask = 0
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(dimensions.x, 2.4, dimensions.z)
		collision.shape = shape
		collision.position = Vector3(0.0, surface_height - position.y - 1.2, 0.0)
		body.add_child(collision)
		root.add_child(body)
		var outline := _add_box(root, "SelectionOutline", Vector3(dimensions.x + 1.4, 0.18, dimensions.z + 1.4), Vector3(0.0, surface_height - position.y + 0.16, 0.0), Color("e9bf59"), 0.32)
		var outline_material := outline.material_override as StandardMaterial3D
		outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		outline_material.albedo_color.a = 0.36
		outline.visible = false
		_surface_outlines[region_id] = outline


func _render_object_fallback(root: Node3D, object: Dictionary) -> void:
	var dimensions := RoomDefinitionLoader.vector3_from(object.dimensions)
	var color := Color(String(object.get("color", "80664b")))
	var appearance: Variant = object.get("appearance", null)
	if appearance is Dictionary:
		_build_appearance_object(root, dimensions, String(object.kind), appearance, color)
	elif int(_room_definition.get("schema_version", 1)) >= 2:
		_build_appearance_object(root, dimensions, String(object.kind), {}, color)
	else:
		_build_legacy_room_object(root, dimensions, object, color)


func _build_legacy_room_object(root: Node3D, dimensions: Vector3, object: Dictionary, color: Color) -> void:
	var kind := String(object.kind)
	match kind:
		"rug":
			_add_box(root, "RugSurface", Vector3(dimensions.x, maxf(0.05, dimensions.y), dimensions.z), Vector3(0.0, dimensions.y * 0.5, 0.0), color, 0.96)
		"table", "workbench":
			var top_height := dimensions.y
			var thickness := clampf(top_height * 0.06, 1.2, 3.0)
			_add_box(root, "SurfaceTop", Vector3(dimensions.x, thickness, dimensions.z), Vector3(0.0, top_height - thickness * 0.5, 0.0), color, 0.56)
			var leg_height := maxf(0.8, top_height - thickness)
			for x_sign in [-1.0, 1.0]:
				for z_sign in [-1.0, 1.0]:
					_add_box(root, "Support", Vector3(maxf(0.8, dimensions.x * 0.035), leg_height, maxf(0.8, dimensions.z * 0.04)), Vector3(x_sign * dimensions.x * 0.43, leg_height * 0.5, z_sign * dimensions.z * 0.42), color.darkened(0.18), 0.74)
			if kind == "workbench":
				_add_box(root, "WorkbenchVice", Vector3(dimensions.x * 0.18, 1.1, dimensions.z * 0.2), Vector3(-dimensions.x * 0.28, top_height + 0.55, -dimensions.z * 0.2), Color("aab4ad"), 0.42)
				_add_box(root, "WorkbenchToolRail", Vector3(dimensions.x * 0.6, 1.0, 0.8), Vector3(0.0, top_height + 2.0, -dimensions.z * 0.38), Color("654d39"), 0.66)
		"chair":
			var seat_y := dimensions.y * 0.6
			_add_box(root, "Seat", Vector3(dimensions.x, 2.2, dimensions.z), Vector3(0.0, seat_y, 0.0), color, 0.72)
			for x_sign in [-1.0, 1.0]:
				for z_sign in [-1.0, 1.0]:
					_add_box(root, "Leg", Vector3(1.5, seat_y, 1.5), Vector3(x_sign * dimensions.x * 0.38, seat_y * 0.5, z_sign * dimensions.z * 0.38), color.darkened(0.2))
			_add_box(root, "Back", Vector3(dimensions.x, maxf(2.0, dimensions.y - seat_y), 2.0), Vector3(0.0, seat_y + (dimensions.y - seat_y) * 0.5, -dimensions.z * 0.44), color.darkened(0.12))
		"bookcase", "wardrobe":
			_add_box(root, "Back", Vector3(dimensions.x, dimensions.y, 1.5), Vector3(0.0, dimensions.y * 0.5, -dimensions.z * 0.46), color.darkened(0.16))
			for x_sign in [-1.0, 1.0]:
				_add_box(root, "Side", Vector3(1.6, dimensions.y, dimensions.z), Vector3(x_sign * dimensions.x * 0.47, dimensions.y * 0.5, 0.0), color, 0.62)
			var shelf_count := 4
			for shelf_index in range(shelf_count + 1):
				var shelf_y := dimensions.y * float(shelf_index) / float(shelf_count)
				_add_box(root, "Shelf", Vector3(dimensions.x, 1.6, dimensions.z * 0.9), Vector3(0.0, shelf_y, 0.0), color.lightened(0.08), 0.58)
			if kind == "wardrobe":
				_add_box(root, "Door", Vector3(dimensions.x * 0.42, dimensions.y * 0.88, 1.2), Vector3(0.0, dimensions.y * 0.5, dimensions.z * 0.43), color.lightened(0.06), 0.62)
		"cylinder":
			_add_cylinder(root, "Body", dimensions.x * 0.5, dimensions.y, Vector3(0.0, dimensions.y * 0.5, 0.0), color)
		"plant":
			_add_cylinder(root, "Pot", dimensions.x * 0.42, dimensions.y * 0.24, Vector3(0.0, dimensions.y * 0.12, 0.0), Color("a86549"))
			_add_cylinder(root, "Stem", 0.5, dimensions.y * 0.55, Vector3(0.0, dimensions.y * 0.52, 0.0), Color("607958"))
			for leaf_index in range(3):
				var angle := TAU * float(leaf_index) / 3.0
				var leaf := _add_sphere(root, "Leaf%d" % leaf_index, Vector3(dimensions.x * 0.62, dimensions.y * 0.18, dimensions.z * 0.5), Vector3(cos(angle) * dimensions.x * 0.18, dimensions.y * (0.64 + float(leaf_index % 2) * 0.12), sin(angle) * dimensions.z * 0.18), color)
				leaf.rotation.y = angle
		_:
			_add_box(root, "Body", dimensions, Vector3(0.0, dimensions.y * 0.5, 0.0), color, 0.78)
			_add_box(root, "Lid", Vector3(dimensions.x * 1.04, maxf(0.8, dimensions.y * 0.1), dimensions.z * 1.04), Vector3(0.0, dimensions.y * 0.98, 0.0), color.lightened(0.12), 0.66)


func _build_appearance_object(root: Node3D, dimensions: Vector3, semantic_kind: String, appearance: Dictionary, fallback_color: Color) -> void:
	var base_color := _appearance_color(appearance, "base_color", fallback_color)
	var accent_color := _appearance_color(appearance, "accent_color", base_color.darkened(0.18))
	var archetype := String(appearance.get("archetype", semantic_kind)).to_lower()
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	match archetype:
		"rug":
			_add_styled_box(root, "RugSurface", Vector3(width, maxf(0.05, height), depth), Vector3(0.0, height * 0.5, 0.0), appearance, base_color, 0.96)
		"table", "desk", "workbench":
			var top_thickness := clampf(height * 0.06, 1.2, 3.0)
			_add_styled_box(root, "TableTop", Vector3(width, top_thickness, depth), Vector3(0.0, height - top_thickness * 0.5, 0.0), appearance, base_color, 0.62)
			var leg_height := maxf(0.8, height - top_thickness)
			for x_sign in [-1.0, 1.0]:
				for z_sign in [-1.0, 1.0]:
					_add_styled_box(root, "TableLeg_%s_%s" % [x_sign, z_sign], Vector3(maxf(0.8, width * 0.035), leg_height, maxf(0.8, depth * 0.04)), Vector3(x_sign * width * 0.43, leg_height * 0.5, z_sign * depth * 0.42), appearance, accent_color, 0.8, true)
			if archetype == "workbench":
				_add_styled_box(root, "WorkbenchRail", Vector3(width * 0.72, 1.0, 0.8), Vector3(0.0, height + 1.3, -depth * 0.36), appearance, accent_color, 0.62, true)
				_add_styled_box(root, "WorkbenchVice", Vector3(width * 0.16, 1.2, depth * 0.18), Vector3(-width * 0.28, height + 0.6, -depth * 0.18), appearance, accent_color.lightened(0.25), 0.4, true)
		"chair":
			var seat_y := height * 0.62
			_add_styled_box(root, "ChairSeat", Vector3(width, maxf(1.5, height * 0.12), depth * 0.78), Vector3(0.0, seat_y, depth * 0.08), appearance, base_color, 0.8)
			var leg_size := maxf(1.0, minf(width, depth) * 0.08)
			for x_sign in [-1.0, 1.0]:
				for z_sign in [-1.0, 1.0]:
					_add_styled_box(root, "ChairLeg_%s_%s" % [x_sign, z_sign], Vector3(leg_size, maxf(0.8, seat_y), leg_size), Vector3(x_sign * width * 0.38, seat_y * 0.5, z_sign * depth * 0.3), appearance, accent_color, 0.78, true)
			var back_height := maxf(2.0, height - seat_y)
			_add_styled_box(root, "ChairBack", Vector3(width, back_height, maxf(1.2, depth * 0.1)), Vector3(0.0, seat_y + back_height * 0.5, -depth * 0.4), appearance, base_color, 0.82)
		"rocking_chair":
			_build_rocking_chair(root, dimensions, appearance, base_color, accent_color)
		"office_chair":
			_build_office_chair(root, dimensions, appearance, base_color, accent_color)
		"hammock":
			_build_hammock(root, dimensions, appearance, base_color, accent_color)
		"monitor":
			_build_monitor(root, dimensions, appearance, base_color, accent_color)
		"monitor_pair":
			_build_monitor_pair(root, dimensions, appearance, base_color, accent_color)
		"display_cabinet":
			_build_display_cabinet(root, dimensions, appearance, base_color, accent_color)
		"floor_lamp":
			_build_floor_lamp(root, dimensions, appearance, base_color, accent_color)
		"floor_seat":
			_build_floor_seat(root, dimensions, appearance, base_color, accent_color)
		"dragon_triptych":
			_build_dragon_triptych(root, dimensions, appearance, base_color, accent_color)
		"dragon_emblem":
			_build_dragon_emblem(root, dimensions, appearance, base_color, accent_color)
		"framed_map":
			_build_framed_map(root, dimensions, appearance, base_color, accent_color)
		"fabric_pile":
			_build_fabric_pile(root, dimensions, appearance, base_color, accent_color)
		"blanket_pile":
			_build_blanket_pile(root, dimensions, appearance, base_color, accent_color)
		"boxed_collectibles":
			_build_boxed_collectibles(root, dimensions, appearance, base_color, accent_color)
		"octagonal_glass_table":
			_build_octagonal_glass_table(root, dimensions, appearance, base_color, accent_color)
		"stone_fireplace":
			_build_stone_fireplace(root, dimensions, appearance, base_color, accent_color)
		"cabinet", "bookcase", "built_in_bookcase", "wardrobe", "shelf", "dresser":
			var body_thickness := maxf(1.5, minf(width, depth) * 0.07)
			_add_styled_box(root, "CabinetBack", Vector3(width, height, body_thickness), Vector3(0.0, height * 0.5, -depth * 0.5 + body_thickness * 0.5), appearance, accent_color, 0.84, true)
			for x_sign in [-1.0, 1.0]:
				_add_styled_box(root, "CabinetSide_%s" % x_sign, Vector3(body_thickness, height, depth), Vector3(x_sign * (width * 0.5 - body_thickness * 0.5), height * 0.5, 0.0), appearance, base_color, 0.82)
			_add_styled_box(root, "CabinetTop", Vector3(width, body_thickness, depth), Vector3(0.0, height - body_thickness * 0.5, 0.0), appearance, accent_color, 0.76, true)
			if archetype in ["bookcase", "shelf"]:
				for shelf_index in range(1, 5):
					var shelf_y := height * float(shelf_index) / 5.0
					_add_styled_box(root, "Shelf_%d" % shelf_index, Vector3(width - body_thickness * 2.0, maxf(1.0, body_thickness * 0.6), depth * 0.88), Vector3(0.0, shelf_y, 0.0), appearance, accent_color, 0.72, true)
			elif archetype == "built_in_bookcase":
				var cabinet_base_height := height * 0.34
				_add_styled_box(root, "BuiltInCabinetBase", Vector3(width - body_thickness * 1.5, cabinet_base_height, depth * 0.92), Vector3(0.0, cabinet_base_height * 0.5, depth * 0.02), appearance, accent_color, 0.76, true)
				for door_index in range(2):
					var door_x := (float(door_index) - 0.5) * width * 0.43
					_add_styled_box(root, "BuiltInCabinetDoor_%d" % door_index, Vector3(width * 0.40, cabinet_base_height * 0.82, maxf(0.7, body_thickness * 0.35)), Vector3(door_x, cabinet_base_height * 0.52, depth * 0.5 + 0.35), appearance, base_color.lightened(0.035), 0.78)
					var handle := _add_cylinder(root, "BuiltInCabinetKnob_%d" % door_index, 0.75, 1.0, Vector3(door_x + (0.055 * width if door_index == 0 else -0.055 * width), cabinet_base_height * 0.53, depth * 0.5 + 1.0), accent_color.lightened(0.24))
					handle.material_override = _appearance_material(appearance, accent_color.lightened(0.24), 0.5)
				for shelf_index in range(1, 5):
					var shelf_y := cabinet_base_height + (height - cabinet_base_height) * float(shelf_index) / 5.0
					_add_styled_box(root, "BuiltInShelf_%d" % shelf_index, Vector3(width - body_thickness * 2.0, maxf(1.0, body_thickness * 0.6), depth * 0.88), Vector3(0.0, shelf_y, 0.0), appearance, accent_color, 0.7, true)
					_build_book_row(root, width, depth, cabinet_base_height + (height - cabinet_base_height) * float(shelf_index - 1) / 5.0 + 1.6, (height - cabinet_base_height) / 5.0, shelf_index)
			else:
				var door_width := maxf(1.0, width * 0.44)
				_add_styled_box(root, "CabinetDoorLeft", Vector3(door_width, height * 0.82, maxf(0.7, body_thickness * 0.5)), Vector3(-width * 0.23, height * 0.49, depth * 0.5), appearance, base_color, 0.76)
				_add_styled_box(root, "CabinetDoorRight", Vector3(door_width, height * 0.82, maxf(0.7, body_thickness * 0.5)), Vector3(width * 0.23, height * 0.49, depth * 0.5), appearance, base_color, 0.76)
				_add_styled_box(root, "CabinetHandleLeft", Vector3(0.7, maxf(1.2, height * 0.08), 0.6), Vector3(-width * 0.04, height * 0.5, depth * 0.53), appearance, accent_color, 0.42, true)
				_add_styled_box(root, "CabinetHandleRight", Vector3(0.7, maxf(1.2, height * 0.08), 0.6), Vector3(width * 0.04, height * 0.5, depth * 0.53), appearance, accent_color, 0.42, true)
		"bed":
			var frame_height := maxf(1.5, height * 0.24)
			_add_styled_box(root, "BedFrame", Vector3(width, frame_height, depth), Vector3(0.0, frame_height * 0.5, 0.0), appearance, accent_color, 0.72, true)
			_add_styled_box(root, "Mattress", Vector3(width * 0.96, maxf(1.5, height - frame_height), depth * 0.94), Vector3(0.0, height - (height - frame_height) * 0.5, 0.0), appearance, base_color, 0.96)
			_add_styled_box(root, "Pillow", Vector3(width * 0.34, maxf(1.0, height * 0.12), depth * 0.18), Vector3(0.0, height - 0.5, -depth * 0.34), appearance, accent_color.lightened(0.3), 0.98, true)
		"sofa":
			var cushion_y := maxf(1.5, height * 0.48)
			_add_styled_box(root, "SofaBase", Vector3(width, cushion_y, depth), Vector3(0.0, cushion_y * 0.5, 0.0), appearance, accent_color, 0.85, true)
			_add_styled_box(root, "SofaSeat", Vector3(width * 0.78, cushion_y * 0.55, depth * 0.68), Vector3(0.0, cushion_y + cushion_y * 0.2, depth * 0.02), appearance, base_color, 0.96)
			_add_styled_box(root, "SofaBack", Vector3(width * 0.78, maxf(2.0, height - cushion_y), depth * 0.18), Vector3(0.0, cushion_y + (height - cushion_y) * 0.5, -depth * 0.38), appearance, base_color, 0.96)
			for x_sign in [-1.0, 1.0]:
				_add_styled_box(root, "SofaArm_%s" % x_sign, Vector3(width * 0.11, height * 0.72, depth * 0.78), Vector3(x_sign * width * 0.44, height * 0.36, depth * 0.02), appearance, accent_color, 0.88, true)
		"cylinder":
			var cylinder := _add_cylinder(root, "CylinderBody", minf(width, depth) * 0.5, height, Vector3(0.0, height * 0.5, 0.0), base_color)
			cylinder.material_override = _appearance_material(appearance, base_color, 0.68)
		"plant":
			var pot_height := maxf(1.0, height * 0.22)
			var pot := _add_cylinder(root, "PlantPot", minf(width, depth) * 0.42, pot_height, Vector3(0.0, pot_height * 0.5, 0.0), accent_color)
			pot.material_override = _appearance_material(appearance, accent_color, 0.78)
			var stem_height := maxf(1.0, height - pot_height)
			_add_styled_box(root, "PlantStem", Vector3(maxf(0.6, width * 0.06), stem_height, maxf(0.6, depth * 0.06)), Vector3(0.0, pot_height + stem_height * 0.5, 0.0), appearance, base_color.darkened(0.25), 0.94)
			for leaf_index in range(4):
				var angle := TAU * float(leaf_index) / 4.0
				var leaf := _add_sphere(root, "PlantLeaf_%d" % leaf_index, Vector3(width * 0.4, height * 0.16, depth * 0.35), Vector3(cos(angle) * width * 0.15, height * (0.68 + float(leaf_index % 2) * 0.08), sin(angle) * depth * 0.15), base_color)
				leaf.material_override = _appearance_material(appearance, base_color, 0.92)
		"box_with_lid":
			_add_styled_box(root, "ObjectBody", dimensions, Vector3(0.0, height * 0.5, 0.0), appearance, base_color, 0.82)
			_add_styled_box(root, "ObjectLid", Vector3(width * 1.04, maxf(0.8, height * 0.1), depth * 1.04), Vector3(0.0, height * 0.98, 0.0), appearance, accent_color, 0.72, true)
		_:
			_add_styled_box(root, "ObjectBody", dimensions, Vector3(0.0, height * 0.5, 0.0), appearance, base_color, 0.84)


func _build_book_row(root: Node3D, width: float, depth: float, shelf_y: float, shelf_height: float, row: int) -> void:
	var covers := [Color("8b3932"), Color("344f61"), Color("c19a52"), Color("4d6046"), Color("573e63"), Color("d1c5ae"), Color("293d39"), Color("a46537")]
	var book_count := 13
	var book_width := width * 0.048
	var left := -width * 0.42
	for book_index in range(book_count):
		var variation := float((book_index * 7 + row * 3) % 5) / 24.0
		var book_height := (0.68 + variation) * shelf_height
		var book_depth := depth * (0.38 + float((book_index + row) % 3) * 0.04)
		var x := left + float(book_index) * book_width * 1.28
		_add_box(root, "Book_%d_%d" % [row, book_index], Vector3(book_width, book_height, book_depth), Vector3(x, shelf_y + book_height * 0.5, depth * 0.04), covers[(book_index + row) % covers.size()], 0.86)


func _build_octagonal_glass_table(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var top_y := height - 1.5
	var wood_appearance := appearance.duplicate(true)
	wood_appearance["material"] = "wood"
	wood_appearance.erase("transparency")
	var glass_appearance := appearance.duplicate(true)
	glass_appearance["material"] = "glass"
	glass_appearance["transparency"] = float(appearance.get("transparency", 0.48))
	var glass := MeshInstance3D.new()
	glass.name = "OctagonalGlassInset"
	var glass_mesh := CylinderMesh.new()
	glass_mesh.top_radius = width * 0.455
	glass_mesh.bottom_radius = width * 0.455
	glass_mesh.height = 0.8
	glass_mesh.radial_segments = 8
	glass.mesh = glass_mesh
	glass.scale = Vector3(1.0, 1.0, depth / width)
	glass.position = Vector3(0.0, top_y, 0.0)
	glass.material_override = _appearance_material(glass_appearance, base_color, 0.2)
	root.add_child(glass)
	var rim_radius_x := width * 0.46
	var rim_radius_z := depth * 0.46
	for side_index in range(8):
		var angle_a := TAU * float(side_index) / 8.0 + PI / 8.0
		var angle_b := TAU * float(side_index + 1) / 8.0 + PI / 8.0
		var start := Vector3(cos(angle_a) * rim_radius_x, top_y, sin(angle_a) * rim_radius_z)
		var finish := Vector3(cos(angle_b) * rim_radius_x, top_y, sin(angle_b) * rim_radius_z)
		_add_rod_between(root, "OctagonalWoodRim_%d" % side_index, start, finish, 1.4, wood_appearance, accent_color)
	_add_styled_box(root, "TableApron", Vector3(width * 0.78, 3.2, depth * 0.68), Vector3(0.0, height * 0.72, 0.0), wood_appearance, accent_color, 0.74, true)
	for x_sign in [-1.0, 1.0]:
		for z_sign in [-1.0, 1.0]:
			var top_leg := Vector3(x_sign * width * 0.31, height * 0.70, z_sign * depth * 0.31)
			var lower_leg := Vector3(x_sign * width * 0.39, 1.6, z_sign * depth * 0.39)
			_add_rod_between(root, "SplayedWoodLeg_%s_%s" % [x_sign, z_sign], top_leg, lower_leg, 1.8, wood_appearance, accent_color)
			_add_styled_box(root, "ScrolledFoot_%s_%s" % [x_sign, z_sign], Vector3(width * 0.16, 2.2, depth * 0.12), Vector3(x_sign * width * 0.34, 1.1, z_sign * depth * 0.34), wood_appearance, accent_color, 0.72, true)


func _build_stone_fireplace(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var firebox_width := width * 0.57
	var firebox_bottom := height * 0.20
	var firebox_top := height * 0.62
	var front := depth * 0.49
	var stone_colors := [Color("57534d"), Color("665d51"), Color("786b58"), Color("494743"), Color("82735e"), Color("5c5750")]
	_add_styled_box(root, "FireboxRecess", Vector3(firebox_width, firebox_top - firebox_bottom, 1.1), Vector3(0.0, (firebox_bottom + firebox_top) * 0.5, front), appearance, Color("171614"), 0.94)
	_add_styled_box(root, "FireboxInner", Vector3(firebox_width * 0.88, (firebox_top - firebox_bottom) * 0.84, 0.45), Vector3(0.0, (firebox_bottom + firebox_top) * 0.49, front + 0.65), appearance, Color("30231b"), 0.88)
	for flame_index in range(4):
		var flame_x := (float(flame_index) - 1.5) * firebox_width * 0.16
		var flame := MeshInstance3D.new()
		flame.name = "FireFlame_%d" % flame_index
		var flame_mesh := CylinderMesh.new()
		flame_mesh.top_radius = 0.25
		flame_mesh.bottom_radius = width * 0.032
		flame_mesh.height = height * (0.15 + float(flame_index % 2) * 0.025)
		flame_mesh.radial_segments = 7
		flame.mesh = flame_mesh
		flame.position = Vector3(flame_x, firebox_bottom + flame_mesh.height * 0.5 + 0.5, front + 1.0)
		flame.material_override = _appearance_material({"material":"other"}, Color("d06427") if flame_index % 2 == 0 else Color("f0a540"), 0.75)
		root.add_child(flame)
	for log_index in range(2):
		var log := _add_box(root, "FireLog_%d" % log_index, Vector3(firebox_width * 0.34, 2.2, 2.0), Vector3((float(log_index) - 0.5) * firebox_width * 0.18, firebox_bottom + 2.0, front + 1.15), Color("403329"), 0.94)
		log.rotation_degrees.y = -18.0 + float(log_index) * 36.0
	var side_width := (width - firebox_width) * 0.5
	for side in [-1.0, 1.0]:
		for row in range(6):
			var center_y := firebox_bottom * (float(row) + 0.5) / 3.0
			if row >= 3:
				center_y = firebox_bottom + (firebox_top - firebox_bottom) * (float(row - 2) - 0.5) / 3.0
			for column in range(2):
				var block_width := side_width * (0.42 + float((row + column) % 2) * 0.06)
				var local_x := firebox_width * 0.5 + side_width * (0.25 + float(column) * 0.5)
				var block_height := maxf(3.0, height * (0.055 + float((row + column) % 3) * 0.006))
				var stone := _add_box(root, "SideStone_%s_%d_%d" % [side, row, column], Vector3(block_width, block_height, depth * 0.92), Vector3(side * local_x, center_y, depth * 0.04), stone_colors[(row * 3 + column * 2) % stone_colors.size()], 0.92)
				stone.rotation_degrees.y = float((row + column) % 3 - 1) * 1.4
	for row in range(4):
		var center_y := firebox_top + (height - firebox_top) * (float(row) + 0.5) / 4.0
		for column in range(5):
			var block_width := width * (0.17 + float((row + column) % 2) * 0.015)
			var center_x := -width * 0.40 + float(column) * width * 0.20
			var block_height := (height - firebox_top) / 4.0 * 0.88
			_add_box(root, "HeaderStone_%d_%d" % [row, column], Vector3(block_width, block_height, depth * 0.92), Vector3(center_x, center_y, depth * 0.04), stone_colors[(row + column * 2 + 1) % stone_colors.size()], 0.9)
	var mantel := _add_box(root, "WoodMantel", Vector3(width * 1.06, 3.5, depth * 1.1), Vector3(0.0, height * 0.77, depth * 0.03), Color("63452f"), 0.84)
	mantel.material_override = _appearance_material({"material":"wood"}, Color("63452f"), 0.84)
	_add_styled_box(root, "RaisedStoneHearth", Vector3(width * 1.02, 6.0, depth * 1.35), Vector3(0.0, 3.0, depth * 0.20), appearance, accent_color, 0.9, true)


func _build_monitor_pair(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var bezel_color := accent_color
	var screen_color := base_color.darkened(0.72)
	var screen_width := width * 0.46
	var screen_height := height * 0.78
	var stand_height := height * 0.18
	for side in [-1.0, 1.0]:
		var x: float = float(side) * width * 0.255
		var screen_center := Vector3(x, height * 0.6, 0.0)
		_add_styled_box(root, "MonitorBezel_%s" % side, Vector3(screen_width, screen_height, maxf(0.8, depth * 0.18)), screen_center, appearance, bezel_color, 0.62, true)
		_add_styled_box(root, "MonitorScreen_%s" % side, Vector3(screen_width * 0.91, screen_height * 0.87, maxf(0.25, depth * 0.04)), screen_center + Vector3(0.0, 0.0, depth * 0.12), appearance, screen_color, 0.24)
		_add_styled_box(root, "MonitorStand_%s" % side, Vector3(maxf(1.0, width * 0.035), stand_height, maxf(1.0, depth * 0.12)), Vector3(x, stand_height * 0.5, 0.0), appearance, bezel_color, 0.58, true)
		_add_styled_box(root, "MonitorFoot_%s" % side, Vector3(screen_width * 0.44, maxf(0.8, height * 0.035), depth * 0.72), Vector3(x, maxf(0.5, height * 0.018), depth * 0.05), appearance, bezel_color, 0.55, true)


func _build_monitor(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var bezel_size := Vector3(width, height, maxf(0.8, depth * 0.24))
	_add_styled_box(root, "MonitorBezel", bezel_size, Vector3(0.0, height * 0.5, 0.0), appearance, accent_color, 0.62, true)
	_add_styled_box(root, "MonitorScreen", Vector3(width * 0.91, height * 0.86, maxf(0.25, depth * 0.05)), Vector3(0.0, height * 0.5, depth * 0.15), appearance, base_color.darkened(0.72), 0.24)


func _build_office_chair(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var seat_y := height * 0.46
	var hub := Vector3(0.0, maxf(1.0, height * 0.12), 0.0)
	_add_cylinder(root, "ChairLift", maxf(0.8, width * 0.055), height * 0.25, Vector3(0.0, height * 0.24, 0.0), accent_color)
	for spoke in range(5):
		var angle := TAU * float(spoke) / 5.0
		var caster := Vector3(cos(angle) * width * 0.43, hub.y, sin(angle) * depth * 0.43)
		_add_rod_between(root, "CasterLeg_%d" % spoke, hub, caster, 0.8, appearance, accent_color)
		_add_sphere(root, "Caster_%d" % spoke, Vector3(3.2, 2.4, 3.2), caster, accent_color.darkened(0.12))
	_add_styled_box(root, "OfficeSeat", Vector3(width * 0.92, maxf(2.0, height * 0.1), depth * 0.78), Vector3(0.0, seat_y, depth * 0.06), appearance, base_color, 0.88)
	_add_styled_box(root, "OfficeBack", Vector3(width * 0.84, height * 0.45, maxf(2.0, depth * 0.22)), Vector3(0.0, height * 0.72, -depth * 0.3), appearance, base_color, 0.9)
	for side in [-1.0, 1.0]:
		_add_styled_box(root, "OfficeArm_%s" % side, Vector3(maxf(1.4, width * 0.08), maxf(1.6, height * 0.12), maxf(1.6, depth * 0.12)), Vector3(side * width * 0.43, seat_y + height * 0.14, depth * 0.02), appearance, accent_color, 0.8, true)


func _build_floor_lamp(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var radius := minf(dimensions.x, dimensions.z) * 0.5
	var height := dimensions.y
	_add_cylinder(root, "LampBase", radius * 0.82, maxf(1.0, height * 0.035), Vector3(0.0, maxf(1.0, height * 0.017), 0.0), accent_color)
	var stem_height := height * 0.82
	_add_cylinder(root, "LampStem", maxf(0.65, radius * 0.12), stem_height, Vector3(0.0, stem_height * 0.5 + height * 0.035, 0.0), base_color)
	var shade_height := maxf(4.0, height * 0.14)
	var shade := MeshInstance3D.new()
	shade.name = "LampShade"
	var shade_mesh := CylinderMesh.new()
	shade_mesh.top_radius = radius * 0.62
	shade_mesh.bottom_radius = radius
	shade_mesh.height = shade_height
	shade.mesh = shade_mesh
	shade.position = Vector3(0.0, height - shade_height * 0.5, 0.0)
	shade.material_override = _appearance_material(appearance, accent_color.lightened(0.38), 0.8)
	root.add_child(shade)


func _build_floor_seat(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var foot := TorusMesh.new()
	foot.inner_radius = minf(width, depth) * 0.31
	foot.outer_radius = minf(width, depth) * 0.43
	foot.rings = 10
	foot.ring_segments = 28
	var foot_mesh := MeshInstance3D.new()
	foot_mesh.name = "SeatRingBase"
	foot_mesh.mesh = foot
	foot_mesh.position.y = maxf(1.0, height * 0.1)
	foot_mesh.material_override = _appearance_material(appearance, accent_color, 0.62)
	root.add_child(foot_mesh)
	_add_cylinder(root, "SeatPedestal", minf(width, depth) * 0.09, maxf(1.0, height * 0.28), Vector3(0.0, height * 0.28, 0.0), accent_color)
	var rim := TorusMesh.new()
	rim.inner_radius = minf(width, depth) * 0.45
	rim.outer_radius = minf(width, depth) * 0.52
	rim.rings = 10
	rim.ring_segments = 28
	var rim_mesh := MeshInstance3D.new()
	rim_mesh.name = "SeatLip"
	rim_mesh.mesh = rim
	rim_mesh.position.y = height * 0.64
	rim_mesh.material_override = _appearance_material(appearance, base_color.lightened(0.12), 0.82)
	root.add_child(rim_mesh)
	var scoop := MeshInstance3D.new()
	scoop.name = "ShallowScoop"
	var scoop_mesh := CylinderMesh.new()
	scoop_mesh.top_radius = minf(width, depth) * 0.5
	scoop_mesh.bottom_radius = minf(width, depth) * 0.39
	scoop_mesh.height = maxf(2.4, height * 0.34)
	scoop.mesh = scoop_mesh
	scoop.position.y = height * 0.42
	scoop.material_override = _appearance_material(appearance, base_color.darkened(0.02), 0.84)
	root.add_child(scoop)


func _build_rocking_chair(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var seat_y := height * 0.53
	var seat_thickness := maxf(1.5, height * 0.08)
	for x_sign in [-1.0, 1.0]:
		var x: float = float(x_sign) * width * 0.4
		for segment in range(6):
			var t0 := float(segment) / 6.0
			var t1 := float(segment + 1) / 6.0
			var z0 := lerpf(-depth * 0.48, depth * 0.48, t0)
			var z1 := lerpf(-depth * 0.48, depth * 0.48, t1)
			var y0 := 0.9 + pow(absf(t0 * 2.0 - 1.0), 2.0) * height * 0.06
			var y1 := 0.9 + pow(absf(t1 * 2.0 - 1.0), 2.0) * height * 0.06
			_add_rod_between(root, "Rocker_%s_%d" % [x_sign, segment], Vector3(x, y0, z0), Vector3(x, y1, z1), 1.3, appearance, accent_color)
		_add_rod_between(root, "ChairSide_%s" % x_sign, Vector3(x, 3.0, -depth * 0.28), Vector3(x, seat_y, depth * 0.16), 1.8, appearance, accent_color)
		_add_rod_between(root, "ChairBackPost_%s" % x_sign, Vector3(x, seat_y, -depth * 0.22), Vector3(x, height * 0.94, -depth * 0.42), 1.9, appearance, base_color)
		_add_rod_between(root, "ChairArm_%s" % x_sign, Vector3(x, seat_y + height * 0.08, depth * 0.13), Vector3(x, seat_y + height * 0.08, -depth * 0.24), 1.5, appearance, base_color)
	_add_styled_box(root, "RockingChairSeat", Vector3(width * 0.84, seat_thickness, depth * 0.62), Vector3(0.0, seat_y, -depth * 0.02), appearance, base_color, 0.76)
	for slat in range(3):
		var y := seat_y + height * (0.16 + float(slat) * 0.11)
		_add_styled_box(root, "BackSlat_%d" % slat, Vector3(width * 0.72, maxf(1.3, height * 0.055), 1.8), Vector3(0.0, y, -depth * 0.32), appearance, base_color, 0.76)


func _build_display_cabinet(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var frame_appearance := appearance.duplicate(true)
	frame_appearance.erase("transparency")
	var frame := maxf(1.4, minf(width, depth) * 0.08)
	_add_styled_box(root, "CabinetBack", Vector3(width, height, frame), Vector3(0.0, height * 0.5, -depth * 0.5 + frame * 0.5), frame_appearance, base_color, 0.78)
	_add_styled_box(root, "CabinetTop", Vector3(width, frame * 1.4, depth), Vector3(0.0, height - frame * 0.7, 0.0), frame_appearance, accent_color, 0.72, true)
	_add_styled_box(root, "CabinetBottom", Vector3(width, frame * 1.2, depth), Vector3(0.0, frame * 0.6, 0.0), frame_appearance, accent_color, 0.72, true)
	for x_sign in [-1.0, 1.0]:
		_add_styled_box(root, "CabinetSide_%s" % x_sign, Vector3(frame, height, depth), Vector3(x_sign * (width * 0.5 - frame * 0.5), height * 0.5, 0.0), frame_appearance, base_color, 0.76)
	var glass_appearance := appearance.duplicate(true)
	glass_appearance["material"] = "glass"
	glass_appearance["transparency"] = float(appearance.get("transparency", 0.66))
	var pane_width := (width - frame * 3.2) * 0.5
	for side in [-1.0, 1.0]:
		var pane := _add_box(root, "DisplayGlass_%s" % side, Vector3(pane_width, height * 0.72, 0.65), Vector3(side * width * 0.245, height * 0.55, depth * 0.5 - 0.3), Color("b6c1b3"), 0.22)
		pane.material_override = _appearance_material(glass_appearance, Color("b6c1b3"), 0.22)
	for shelf_index in range(1, 4):
		var shelf_y := height * (0.21 + float(shelf_index - 1) * 0.2)
		_add_styled_box(root, "DisplayShelf_%d" % shelf_index, Vector3(width - frame * 2.0, maxf(0.8, frame * 0.32), depth * 0.82), Vector3(0.0, shelf_y, 0.0), frame_appearance, accent_color, 0.7, true)
	for x_sign in [-1.0, 1.0]:
		_add_styled_box(root, "DisplayDoorRail_%s" % x_sign, Vector3(frame * 0.55, height * 0.74, 0.8), Vector3(x_sign * width * 0.245, height * 0.55, depth * 0.5 + 0.1), frame_appearance, accent_color, 0.7, true)
	for y_fraction in [0.18, 0.92]:
		_add_styled_box(root, "DisplayDoorRailH_%s" % str(y_fraction), Vector3(width - frame * 2.0, frame * 0.5, 0.8), Vector3(0.0, height * y_fraction, depth * 0.5 + 0.1), frame_appearance, accent_color, 0.7, true)
	_add_styled_box(root, "DisplayHandleLeft", Vector3(0.65, height * 0.07, 0.8), Vector3(-width * 0.04, height * 0.55, depth * 0.5 + 0.55), frame_appearance, accent_color, 0.4, true)
	_add_styled_box(root, "DisplayHandleRight", Vector3(0.65, height * 0.07, 0.8), Vector3(width * 0.04, height * 0.55, depth * 0.5 + 0.55), frame_appearance, accent_color, 0.4, true)
	var collectible_colors := [Color("d2c7ab"), Color("b9a87f"), Color("ded7c4"), Color("9a947e")]
	for index in range(4):
		var box_size := Vector3(width * 0.18, height * 0.07, depth * 0.2)
		_add_box(root, "CabinetCollectible_%d" % index, box_size, Vector3(-width * 0.3 + float(index) * width * 0.2, height + box_size.y * 0.5, 0.0), collectible_colors[index], 0.86)


func _build_hammock(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var span_x := width * 0.39
	var base_z := depth * 0.42
	var end_y := height * 0.72
	for z_sign in [-1.0, 1.0]:
		_add_rod_between(root, "HammockStandRail_%s" % z_sign, Vector3(-span_x, 1.3, z_sign * base_z), Vector3(span_x, 1.3, z_sign * base_z), 1.1, appearance, accent_color)
		for x_sign in [-1.0, 1.0]:
			_add_rod_between(root, "HammockAFrame_%s_%s" % [x_sign, z_sign], Vector3(x_sign * span_x, 1.4, z_sign * base_z), Vector3(x_sign * span_x, end_y, 0.0), 1.0, appearance, accent_color)
	_add_rod_between(root, "HammockEndBar", Vector3(-span_x, end_y, 0.0), Vector3(span_x, end_y, 0.0), 1.1, appearance, accent_color)
	var stripe_colors := [base_color, accent_color, base_color.lightened(0.24), accent_color.lightened(0.12), base_color.darkened(0.12), accent_color, base_color.lightened(0.08), accent_color.lightened(0.22), base_color, accent_color.darkened(0.08), base_color.lightened(0.3), accent_color]
	for stripe in range(stripe_colors.size()):
		var v0 := float(stripe) / float(stripe_colors.size())
		var v1 := float(stripe + 1) / float(stripe_colors.size())
		_add_hammock_fabric_stripe(root, "HammockFabricStripe_%d" % stripe, span_x, height, depth, end_y, v0, v1, stripe_colors[stripe], appearance)


func _add_hammock_fabric_stripe(parent: Node3D, node_name: String, span_x: float, object_height: float, object_depth: float, end_y: float, v0: float, v1: float, color: Color, appearance: Dictionary) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 14
	var z_extent := object_depth * 0.34
	var mid_y := object_height * 0.34
	for segment in range(segments):
		var u0 := float(segment) / float(segments)
		var u1 := float(segment + 1) / float(segments)
		var x0 := lerpf(-span_x, span_x, u0)
		var x1 := lerpf(-span_x, span_x, u1)
		var z0 := lerpf(-z_extent, z_extent, v0)
		var z1 := lerpf(-z_extent, z_extent, v1)
		var sag0 := sin(u0 * PI)
		var sag1 := sin(u1 * PI)
		var edge0 := pow(absf((v0 + v1) * 0.5 - 0.5) * 2.0, 2.0) * object_height * 0.055
		var y00 := lerpf(end_y, mid_y, sag0) + edge0
		var y10 := lerpf(end_y, mid_y, sag1) + edge0
		var p00 := Vector3(x0, y00, z0)
		var p01 := Vector3(x0, y00, z1)
		var p10 := Vector3(x1, y10, z0)
		var p11 := Vector3(x1, y10, z1)
		surface.add_vertex(p00)
		surface.add_vertex(p01)
		surface.add_vertex(p10)
		surface.add_vertex(p10)
		surface.add_vertex(p01)
		surface.add_vertex(p11)
	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = surface.commit()
	var fabric_material := _appearance_material(appearance, color, 0.96)
	fabric_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = fabric_material
	parent.add_child(mesh_instance)


func _build_dragon_triptych(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var frame_color := Color("251b19")
	_add_styled_box(root, "ArtBacking", Vector3(width, height, maxf(0.6, depth)), Vector3(0.0, height * 0.5, 0.0), appearance, frame_color, 0.82, true)
	var panel_colors := [Color("171211"), Color("13151b"), Color("101720")]
	for index in range(3):
		var panel_width := width / 3.0 - 0.9
		var x := -width / 3.0 + float(index) * width / 3.0
		_add_box(root, "ArtPanel_%d" % index, Vector3(panel_width, height * 0.9, maxf(0.35, depth * 0.25)), Vector3(x, height * 0.5, depth * 0.58), panel_colors[index], 0.95)
		if index > 0:
			_add_styled_box(root, "ArtDivider_%d" % index, Vector3(0.8, height, depth * 0.4), Vector3(-width * 0.5 + float(index) * width / 3.0, height * 0.5, depth * 0.7), appearance, frame_color, 0.8, true)
	var art_z := depth * 0.78
	var fire_color := base_color.lightened(0.18)
	var ice_color := accent_color.lightened(0.22)
	var fire_shadow := Color("a93021")
	var ice_shadow := Color("1769aa")
	for side in [-1.0, 1.0]:
		var body_color := fire_color if side < 0.0 else ice_color
		var shadow_color := fire_shadow if side < 0.0 else ice_shadow
		var body_x: float = side * width * 0.22
		var head_x: float = body_x - side * width * 0.10
		var tail_x: float = body_x + side * width * 0.20
		var wing_x: float = body_x + side * width * 0.04
		var dragon_prefix := "FireDragon" if side < 0.0 else "IceDragon"
		_add_sphere(root, "%sBody" % dragon_prefix, Vector3(width * 0.24, height * 0.16, 0.7), Vector3(body_x, height * 0.45, art_z), body_color)
		_add_sphere(root, "%sHead" % dragon_prefix, Vector3(width * 0.075, height * 0.095, 0.75), Vector3(head_x, height * 0.66, art_z), body_color.lightened(0.12))
		_add_rod_between(root, "%sNeck" % dragon_prefix, Vector3(body_x - side * width * 0.04, height * 0.49, art_z), Vector3(head_x, height * 0.64, art_z), maxf(1.0, height * 0.028), appearance, body_color)
		_add_rod_between(root, "%sTail" % dragon_prefix, Vector3(tail_x - side * width * 0.04, height * 0.43, art_z), Vector3(tail_x, height * 0.61, art_z), maxf(0.8, height * 0.021), appearance, shadow_color)
		_add_art_triangle(root, "DragonWingLeft" if side < 0.0 else "IceDragonWingLeft", Vector3(wing_x, height * 0.56, art_z), Vector3(wing_x + side * width * 0.18, height * 0.96, art_z), Vector3(wing_x + side * width * 0.07, height * 0.46, art_z), body_color)
		_add_art_triangle(root, "DragonWingRight" if side < 0.0 else "IceDragonWingRight", Vector3(body_x - side * width * 0.06, height * 0.57, art_z + 0.03), Vector3(body_x - side * width * 0.20, height * 0.86, art_z + 0.03), Vector3(body_x - side * width * 0.04, height * 0.45, art_z + 0.03), shadow_color)
	if base_color.get_luminance() > 0.35:
		_add_art_triangle(root, "DragonFire", Vector3(-width * 0.02, height * 0.66, art_z + 0.08), Vector3(-width * 0.28, height * 0.53, art_z + 0.08), Vector3(-width * 0.14, height * 0.48, art_z + 0.08), fire_color)


func _build_dragon_emblem(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var color := base_color.lightened(0.35)
	_add_sphere(root, "EmblemBody", Vector3(width * 0.28, height * 0.5, maxf(0.3, depth)), Vector3(0.0, height * 0.48, depth * 0.6), color)
	_add_sphere(root, "EmblemHead", Vector3(width * 0.2, height * 0.22, maxf(0.3, depth)), Vector3(width * 0.28, height * 0.76, depth * 0.6), color)
	_add_art_triangle(root, "EmblemWingLeft", Vector3(-width * 0.04, height * 0.56, depth * 0.62), Vector3(-width * 0.48, height * 0.96, depth * 0.62), Vector3(-width * 0.32, height * 0.38, depth * 0.62), color)
	_add_art_triangle(root, "EmblemWingRight", Vector3(width * 0.04, height * 0.56, depth * 0.62), Vector3(width * 0.48, height * 0.9, depth * 0.62), Vector3(width * 0.3, height * 0.38, depth * 0.62), color)
	_add_rod_between(root, "EmblemTail", Vector3(-width * 0.08, height * 0.42, depth * 0.62), Vector3(-width * 0.46, height * 0.16, depth * 0.62), maxf(0.3, width * 0.04), appearance, accent_color)


func _build_framed_map(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.z
	var height := dimensions.y
	var thickness := maxf(0.6, dimensions.x)
	var frame := maxf(0.75, minf(width, height) * 0.045)
	_add_styled_box(root, "MapBacking", Vector3(thickness, height, width), Vector3.ZERO, appearance, accent_color, 0.74, true)
	_add_styled_box(root, "MapImage", Vector3(thickness * 0.5, height - frame * 2.0, width - frame * 2.0), Vector3(thickness * 0.35, 0.0, 0.0), appearance, base_color, 0.96)
	var land_colors := [Color("798d72"), Color("a9a27b"), Color("627f78")]
	for index in range(3):
		var patch_width := width * (0.18 + float(index % 2) * 0.04)
		var patch_height := height * 0.3
		_add_box(root, "MapLand_%d" % index, Vector3(thickness * 0.35, patch_height, patch_width), Vector3(thickness * 0.65, height * (0.24 + float(index) * 0.22), -width * 0.22 + float(index) * width * 0.22), land_colors[index], 0.95)
	for side in [-1.0, 1.0]:
		_add_styled_box(root, "MapFrameSide_%s" % side, Vector3(thickness * 1.2, height, frame), Vector3(0.0, 0.0, side * (width * 0.5 - frame * 0.5)), appearance, accent_color, 0.72, true)
	for y_sign in [-1.0, 1.0]:
		_add_styled_box(root, "MapFrameRail_%s" % y_sign, Vector3(thickness * 1.2, frame, width), Vector3(0.0, y_sign * (height * 0.5 - frame * 0.5), 0.0), appearance, accent_color, 0.72, true)


func _build_fabric_pile(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var lobe_count := 5
	for index in range(lobe_count):
		var fraction := float(index) / float(lobe_count - 1)
		var x := lerpf(-width * 0.34, width * 0.34, fraction)
		var z := sin(fraction * PI * 2.0) * depth * 0.16
		var lobe_size := Vector3(width * 0.31, height * (0.72 + float(index % 2) * 0.18), depth * 0.42)
		var lobe_color := base_color if index % 2 == 0 else accent_color
		_add_sphere(root, "FabricFold_%d" % index, lobe_size, Vector3(x, height * (0.34 + float(index % 2) * 0.12), z), lobe_color)


func _build_blanket_pile(root: Node3D, dimensions: Vector3, appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var colors := [base_color, accent_color, base_color.lightened(0.16), accent_color.darkened(0.14)]
	for fold in range(4):
		var fold_width := width * (0.8 - float(fold % 2) * 0.12)
		var fold_depth := depth * (0.58 - float(fold % 2) * 0.08)
		var fold_y := height * (0.08 + float(fold) * 0.13)
		var fold_mesh := SurfaceTool.new()
		fold_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segments_x := 8
		var segments_z := 6
		for x_index in range(segments_x):
			var u0 := float(x_index) / float(segments_x)
			var u1 := float(x_index + 1) / float(segments_x)
			for z_index in range(segments_z):
				var v0 := float(z_index) / float(segments_z)
				var v1 := float(z_index + 1) / float(segments_z)
				var x0 := (u0 - 0.5) * fold_width
				var x1 := (u1 - 0.5) * fold_width
				var z0 := (v0 - 0.5) * fold_depth
				var z1 := (v1 - 0.5) * fold_depth
				var y00 := sin(u0 * PI) * (0.65 + sin(v0 * TAU + float(fold)) * 0.2)
				var y01 := sin(u0 * PI) * (0.65 + sin(v1 * TAU + float(fold)) * 0.2)
				var y10 := sin(u1 * PI) * (0.65 + sin(v0 * TAU + float(fold)) * 0.2)
				var y11 := sin(u1 * PI) * (0.65 + sin(v1 * TAU + float(fold)) * 0.2)
				var p00 := Vector3(x0, y00, z0)
				var p01 := Vector3(x0, y01, z1)
				var p10 := Vector3(x1, y10, z0)
				var p11 := Vector3(x1, y11, z1)
				fold_mesh.add_vertex(p00)
				fold_mesh.add_vertex(p01)
				fold_mesh.add_vertex(p10)
				fold_mesh.add_vertex(p10)
				fold_mesh.add_vertex(p01)
				fold_mesh.add_vertex(p11)
		fold_mesh.generate_normals()
		var sheet := MeshInstance3D.new()
		sheet.name = "BlanketFold_%d" % fold
		sheet.mesh = fold_mesh.commit()
		sheet.position = Vector3((float(fold % 2) - 0.5) * width * 0.12, fold_y, (float(fold) - 1.5) * depth * 0.035)
		sheet.rotation.y = deg_to_rad(float(fold - 1) * 9.0)
		var cloth_material := _appearance_material(appearance, colors[fold], 0.96)
		cloth_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		sheet.material_override = cloth_material
		root.add_child(sheet)
	for lobe in range(4):
		var fraction := float(lobe) / 3.0
		var x := lerpf(-width * 0.26, width * 0.26, fraction)
		var z := sin(fraction * PI * 2.0) * depth * 0.12
		var lobe_size := Vector3(width * 0.28, height * 0.62, depth * 0.42)
		_add_sphere(root, "BlanketMound_%d" % lobe, lobe_size, Vector3(x, height * 0.33, z), colors[(lobe + 1) % colors.size()])


func _build_boxed_collectibles(root: Node3D, dimensions: Vector3, _appearance: Dictionary, base_color: Color, accent_color: Color) -> void:
	var width := dimensions.x
	var height := dimensions.y
	var depth := dimensions.z
	var columns := 4
	var rows := 3
	var package_width := width / float(columns) * 0.82
	var package_height := height * 0.76
	var package_depth := depth / float(rows) * 0.78
	var palette := [Color("d8d1c1"), Color("b68a60"), Color("a8b5b5"), Color("817d70"), Color("c4a77f")]
	for row in range(rows):
		for column in range(columns):
			var x := -width * 0.5 + width * (float(column) + 0.5) / float(columns)
			var z := -depth * 0.5 + depth * (float(row) + 0.5) / float(rows)
			var color: Color = palette[(column + row * 2) % palette.size()]
			var center := Vector3(x, height * 0.5, z)
			_add_box(root, "CollectibleBox_%d_%d" % [row, column], Vector3(package_width, package_height, package_depth), center, color, 0.84)
			_add_box(root, "CollectibleBoxFront_%d_%d" % [row, column], Vector3(package_width * 0.65, package_height * 0.46, 0.12), center + Vector3(0.0, 0.0, package_depth * 0.5 + 0.08), accent_color.lightened(0.22), 0.9)
			_add_box(root, "CollectibleBoxMark_%d_%d" % [row, column], Vector3(package_width * 0.36, package_height * 0.14, 0.12), center + Vector3(0.0, -package_height * 0.2, package_depth * 0.5 + 0.09), base_color.darkened(0.18), 0.92)


func _add_art_triangle(parent: Node3D, node_name: String, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.generate_normals()
	var triangle := MeshInstance3D.new()
	triangle.name = node_name
	triangle.mesh = surface.commit()
	var material := _material(color, 0.9).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	triangle.material_override = material
	parent.add_child(triangle)


func _add_rod_between(parent: Node3D, node_name: String, start: Vector3, finish: Vector3, radius: float, appearance: Dictionary, color: Color) -> void:
	var direction := finish - start
	var length := direction.length()
	if length <= 0.01:
		return
	var rod := MeshInstance3D.new()
	rod.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(radius * 2.0, radius * 2.0, length)
	rod.mesh = mesh
	rod.position = (start + finish) * 0.5
	var forward := Vector3.FORWARD
	var normalized_direction := direction.normalized()
	var rotation_axis := forward.cross(normalized_direction)
	var axis_dot := clampf(forward.dot(normalized_direction), -1.0, 1.0)
	if rotation_axis.length_squared() > 0.000001:
		rod.quaternion = Quaternion(rotation_axis.normalized(), acos(axis_dot))
	elif axis_dot < 0.0:
		rod.quaternion = Quaternion(Vector3.UP, PI)
	rod.material_override = _appearance_material(appearance, color, 0.72)
	parent.add_child(rod)


func _add_styled_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, appearance: Dictionary, color: Color, roughness: float = 0.8, accent: bool = false) -> MeshInstance3D:
	var selected_color := _appearance_color(appearance, "accent_color", color) if accent else color
	var mesh := _add_box(parent, node_name, size, at, selected_color, roughness)
	mesh.material_override = _appearance_material(appearance, selected_color, roughness)
	return mesh


func _appearance_color(appearance: Variant, field: String, fallback: Color) -> Color:
	if appearance is Dictionary and appearance.has(field) and appearance.get(field) is String and not String(appearance.get(field)).is_empty():
		return Color(String(appearance.get(field)))
	return fallback


func _appearance_material(appearance: Dictionary, color: Color, default_roughness: float) -> StandardMaterial3D:
	var category := String(appearance.get("material", "other")).to_lower()
	var material := MaterialLibrary.get_material(category, color, default_roughness).duplicate() as StandardMaterial3D
	match category:
		"metal":
			material.metallic = 0.72
			material.roughness = 0.38
		"glass":
			material.roughness = 0.18
		"fabric":
			material.roughness = 0.96
		"stone", "ceramic":
			material.roughness = 0.72
		"wood":
			material.roughness = 0.76
	var transparency := float(appearance.get("transparency", 0.35 if category == "glass" else 0.0))
	if transparency > 0.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 1.0 - transparency
	return material


func _build_lighting() -> void:
	var light := DirectionalLight3D.new()
	light.name = "KeyLight"
	light.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	add_child(light)
	var camera_value: Variant = _room_definition.get("camera", {})
	var camera_data: Dictionary = camera_value if camera_value is Dictionary else {}
	var floor_center := RoomDefinitionLoader.vector3_from(_room_definition.floor.center)
	var fill_position: Variant = camera_data.get("fill_position", [floor_center.x + 5.0, floor_center.y + WALL_HEIGHT, floor_center.z + 24.0])
	var lantern_position: Variant = camera_data.get("lantern_position", [floor_center.x - ROOM_WIDTH * 0.12, floor_center.y + 10.0, floor_center.z + ROOM_DEPTH * 0.33])
	var fill := OmniLight3D.new()
	fill.name = "RoomFill"
	fill.position = RoomDefinitionLoader.vector3_from(fill_position)
	fill.light_color = Color("dbe4ec")
	fill.light_energy = 1.2
	fill.omni_range = maxf(190.0, ROOM_WIDTH * 0.9)
	fill.omni_attenuation = 1.35
	add_child(fill)
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color("17212b")
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("d5dce4")
	resource.ambient_light_energy = 0.72
	resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	resource.glow_enabled = true
	resource.glow_intensity = 0.14
	resource.glow_bloom = 0.04
	resource.glow_hdr_threshold = 1.5
	environment.environment = resource
	add_child(environment)
	var lantern_fill := OmniLight3D.new()
	lantern_fill.name = "SettlementLanternFill"
	lantern_fill.position = RoomDefinitionLoader.vector3_from(lantern_position)
	lantern_fill.light_color = Color("e5a95d")
	lantern_fill.light_energy = 1.4
	lantern_fill.omni_range = 38.0
	lantern_fill.omni_attenuation = 1.5
	add_child(lantern_fill)


func _build_camera() -> void:
	var rig := StrategyCameraController.new()
	rig.name = "CameraRig"
	rig.configure_room(_room_definition)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.fov = 55.0
	camera.near = 0.1
	camera.far = 1000.0
	camera.current = true
	rig.add_child(camera)
	add_child(rig)
	var startup_mode := OS.get_environment("ROOMSCALE_VIEW_MODE")
	if not startup_mode.is_empty():
		rig.set_view_mode(clampi(int(startup_mode), 0, 2))


func _build_population() -> bool:
	var navigation := FloorNavigationController.new()
	navigation.name = "FloorNavigation"
	navigation.configure(_room_definition)
	add_child(navigation)
	var surface_navigation := SurfaceNavigationController.new()
	surface_navigation.name = "SurfaceNavigation"
	surface_navigation.configure(_room_definition, navigation)
	add_child(surface_navigation)
	var navigation_errors: Array[String] = RoomDefinitionLoader.validate_navigation(_room_definition, navigation, surface_navigation)
	if not navigation_errors.is_empty():
		for diagnostic in navigation_errors:
			push_error("ROOMDEFINITION_NAVIGATION_INVALID room=%s: %s" % [_room_definition.id, diagnostic])
		get_tree().quit(1)
		return false
	_task_coordinator = TaskCoordinatorController.new()
	_task_coordinator.name = "TaskCoordinator"
	_task_coordinator.navigation = navigation
	_task_coordinator.surface_navigation = surface_navigation
	_task_coordinator.configure_room(_room_definition)
	add_child(_task_coordinator)
	_task_coordinator.seed_population(50)
	var starts: Array[Vector3] = []
	var spawn: Dictionary = _room_definition.spawn
	var spawn_center := RoomDefinitionLoader.vector3_from(spawn.center)
	var spawn_dimensions: Array = spawn.dimensions
	var floor_height := float(_room_definition.floor.height)
	for citizen_id in range(50):
		var column := citizen_id % 10
		var row := floori(float(citizen_id) / 10.0)
		var proposed := Vector3(spawn_center.x - float(spawn_dimensions[0]) * 0.5 + 4.0 + float(column) * (float(spawn_dimensions[0]) - 8.0) / 9.0, floor_height, spawn_center.z - float(spawn_dimensions[2]) * 0.5 + 4.0 + float(row) * (float(spawn_dimensions[2]) - 8.0) / 4.0)
		var spawn_position: Vector3 = navigation.nearest_walkable_position(proposed)
		if not is_finite(spawn_position.x):
			push_error("No walkable spawn position for citizen %d" % citizen_id)
			continue
		var attempts := 0
		while _overlaps_spawn(spawn_position, starts) and attempts < 8:
			attempts += 1
			proposed += Vector3(0.0, 0.0, 4.0)
			spawn_position = navigation.nearest_walkable_position(proposed)
		starts.append(spawn_position)
		var citizen: Node3D = CitizenAgentController.new()
		citizen.initialize(citizen_id, spawn_position, navigation, _task_coordinator)
		add_child(citizen)
		_citizens.append(citizen)
	_construction_system = ConstructionSystemController.new()
	_construction_system.name = "ConstructionSystem"
	_construction_system.surface_navigation = surface_navigation
	_construction_system.configure(_task_coordinator, navigation, _citizens, self, _room_definition)
	_task_coordinator.construction_system = _construction_system
	_task_coordinator.reach_goal_updated.connect(_on_reach_goal_updated)
	_task_coordinator.task_board_updated.connect(_on_task_board_updated)
	_construction_system.project_updated.connect(_on_project_updated)
	add_child(_construction_system)
	if _citizens.size() > 0:
		get_node("CameraRig").set_citizen_focus(_citizens[0])
	print("ROOMSCALE_CITIZEN_SPAWN count=%d separate_nodes=true height=%.1fin" % [_citizens.size(), CITIZEN_HEIGHT_INCHES])
	return true


func _overlaps_spawn(candidate: Vector3, existing: Array[Vector3]) -> bool:
	for position in existing:
		if Vector2(candidate.x - position.x, candidate.z - position.z).length() < 2.0:
			return true
	return false


func _build_ui() -> void:
	var overlay := CanvasLayer.new()
	overlay.name = "Overlay"
	add_child(overlay)
	_add_ui_panel(overlay, "HudPanel", Rect2(16.0, 12.0, 570.0, 326.0), Color(0.035, 0.052, 0.068, 0.79))
	_add_ui_panel(overlay, "CameraPanel", Rect2(988.0, 16.0, 270.0, 78.0), Color(0.035, 0.052, 0.068, 0.78))
	_add_ui_panel(overlay, "ControlsPanel", Rect2(18.0, 628.0, 1244.0, 70.0), Color(0.035, 0.052, 0.068, 0.84))
	var title := _make_label("Title", Vector2(26.0, 20.0), 25, Color("fff2dc"))
	title.text = "ROOMSCALE  ·  %s" % String(_room_definition.display_name).to_upper()
	overlay.add_child(title)
	var help := _make_label("Controls", Vector2(28.0, 636.0), 14, Color("e5e6df"))
	help.text = "1 ROOM  ·  2 SETTLEMENT  ·  3 CITIZEN    |    WASD / ARROWS PAN    ·    RIGHT DRAG ORBIT    ·    WHEEL ZOOM\nClick an elevated surface, then Reach / Explore    ·    Click a citizen to inspect    ·    F12 captures this moment"
	help.custom_minimum_size = Vector2(1200.0, 52.0)
	overlay.add_child(help)
	var mode := _make_label("CameraMode", Vector2(1000.0, 28.0), 16, Color("e7c991"))
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var camera_rig := get_node("CameraRig")
	mode.text = "VIEW  %s  ·  %d in" % [camera_rig.get_view_mode_name(), roundi(camera_rig.distance)]
	overlay.add_child(mode)
	_population_label = _make_label("PopulationStatus", Vector2(28.0, 62.0), 15, Color("f3dfb8"))
	_population_label.custom_minimum_size = Vector2(530.0, 24.0)
	overlay.add_child(_population_label)
	_activity_label = _make_label("TaskStatus", Vector2(28.0, 88.0), 13, Color("dde3da"))
	_activity_label.custom_minimum_size = Vector2(530.0, 48.0)
	overlay.add_child(_activity_label)
	_goal_status_label = _make_label("GoalStatus", Vector2(28.0, 140.0), 14, Color("f2cf7e"))
	_goal_status_label.custom_minimum_size = Vector2(530.0, 42.0)
	_goal_status_label.text = "GOAL  Click %s to select it." % _goal_surface_name()
	overlay.add_child(_goal_status_label)
	_reach_button = Button.new()
	_reach_button.name = "ReachExploreButton"
	_reach_button.text = "REACH / EXPLORE"
	_reach_button.position = Vector2(28.0, 184.0)
	_reach_button.size = Vector2(238.0, 38.0)
	_reach_button.visible = false
	_reach_button.pressed.connect(issue_reach_explore)
	overlay.add_child(_reach_button)
	var capture_hint := _make_label("CaptureHint", Vector2(28.0, 232.0), 12, Color("c1c9cb"))
	capture_hint.text = "F12 captures the current interaction state."
	overlay.add_child(capture_hint)
	_project_status_label = _make_label("ProjectStatus", Vector2(28.0, 254.0), 13, Color("f4d69a"))
	_project_status_label.custom_minimum_size = Vector2(530.0, 22.0)
	overlay.add_child(_project_status_label)
	_material_status_label = _make_label("MaterialStatus", Vector2(28.0, 278.0), 12, Color("d9e0d9"))
	_material_status_label.custom_minimum_size = Vector2(530.0, 20.0)
	overlay.add_child(_material_status_label)
	_build_status_label = _make_label("BuildStatus", Vector2(28.0, 300.0), 12, Color("a8d7c4"))
	_build_status_label.custom_minimum_size = Vector2(530.0, 20.0)
	overlay.add_child(_build_status_label)
	_m6_status_label = _make_label("IntegratedStatus", Vector2(28.0, 322.0), 12, Color("c9d5ee"))
	_m6_status_label.custom_minimum_size = Vector2(530.0, 20.0)
	overlay.add_child(_m6_status_label)
	_focus_label = _make_label("CitizenFocus", Vector2(1000.0, 54.0), 15, Color("a9dad4"))
	_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_focus_label.custom_minimum_size = Vector2(255.0, 26.0)
	overlay.add_child(_focus_label)
	_inspection_label = _make_label("CitizenInspection", Vector2(1000.0, 90.0), 13, Color("d7e4db"))
	_inspection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_inspection_label.custom_minimum_size = Vector2(255.0, 72.0)
	_inspection_label.text = "CITIZEN INSPECTION\nClick a citizen"
	overlay.add_child(_inspection_label)
	_add_ui_panel(overlay, "PresentationPanel", Rect2(20, 18, 420, 74), Color(0.035, 0.052, 0.068, 0.72))
	_compact_status = _make_label("PresentationStatus", Vector2(34, 27), 16, Color("f5e3c5"))
	overlay.add_child(_compact_status)
	_apply_presentation_mode()
	_update_population_ui()

func _apply_presentation_mode() -> void:
	var overlay := get_node("Overlay")
	for child in overlay.get_children():
		if child.name in ["PresentationPanel", "PresentationStatus"]:
			child.visible = _presentation_mode
		elif child.name != "ReachExploreButton":
			child.visible = not _presentation_mode
	_reach_button.position = Vector2(20, 100) if _presentation_mode else Vector2(28, 184)



func _update_population_ui() -> void:
	if not is_instance_valid(_population_label) or not is_instance_valid(_activity_label) or not is_instance_valid(_task_coordinator):
		return
	var moving := 0
	var carriers := 0
	for citizen in _citizens:
		if citizen.state == "TRAVEL" or citizen.state == "CARRY":
			moving += 1
		if citizen.carrying:
			carriers += 1
	var summary: Dictionary = _task_coordinator.summary()
	_population_label.text = "POP %02d / 50   WALK %02d   CARRY %02d   SCALE 0.5 in" % [_citizens.size(), moving, carriers]
	var delivery_count: int = _construction_system.active_delivery_count() if is_instance_valid(_construction_system) else 0
	var builder_count: int = _construction_system.active_builder_count() if is_instance_valid(_construction_system) else 0
	_activity_label.text = "TASKS  ACTIVE %02d · READY %02d · DONE %d\nHAUL %02d · BUILD %02d   WORKSHOP / DEPOT / HOMES / FLOOR" % [summary.active, summary.available, summary.completed_total, delivery_count, builder_count]
	_reach_button.visible = _selected_surface == surface_navigation_goal_id()
	var goal: Dictionary = _task_coordinator.get_reach_goal_status()
	if goal.is_empty():
		_goal_status_label.text = "GOAL  Click %s to select." % _goal_surface_name() if _selected_surface.is_empty() else "TARGET  %s SELECTED · Choose Reach / Explore." % _goal_surface_name().to_upper()
	else:
		_goal_status_label.text = "GOAL  %s\n%s" % [String(goal.state).replace("_", " "), String(goal.message)]
	var camera_rig := get_node("CameraRig")
	_focus_label.visible = camera_rig.view_mode == 2 and _citizens.size() > 23
	if _focus_label.visible:
		var focus: Node3D = camera_rig.get_focused_citizen()
		if not is_instance_valid(focus):
			focus = _citizens[23]
		_focus_label.text = "%s  ·  %s  ·  %s" % [focus.name, focus.task_type.replace("_", " "), focus.state]
	if is_instance_valid(_selected_citizen) and is_instance_valid(_inspection_label):
		var inspection: Dictionary = _selected_citizen.get_inspection_status()
		_inspection_label.text = "CITIZEN %02d  ·  %s\nTASK %s\nTARGET (%.0f, %.0f, %.0f)" % [int(inspection.id) + 1, inspection.state, String(inspection.task).replace("_", " "), inspection.target.x, inspection.target.y, inspection.target.z]
	var m6: Dictionary = _task_coordinator.get_m6_status()
	_m6_status_label.text = "%s  ARRIVED %d · EXPLORED %d · REUSES %d/2 · LINK %s" % [_goal_surface_name().to_upper(), m6.target_arrivals, m6.target_explorations_completed, m6.autonomous_reuses_assigned, "LIVE" if m6.infrastructure_operational else "WAITING"]
	_update_project_ui()
	if is_instance_valid(_compact_status):
		var project: Dictionary = _construction_system.status()
		_compact_status.text = "ROOMSCALE  ·  %d CITIZENS\n%s   ·   F3 diagnostics" % [_citizens.size(), String(project.state).replace("_", " ") if project.created else "Explore the room"]
		if _presentation_mode:
			_focus_label.visible = false


func _on_reach_goal_updated(status: Dictionary) -> void:
	if is_instance_valid(_construction_system):
		_construction_system.on_reach_goal_updated(status)
	_update_population_ui()


func _on_task_board_updated(_status: Dictionary) -> void:
	_update_population_ui()


func _on_project_updated(_status: Dictionary) -> void:
	_update_project_ui()
	_update_population_ui()


func _update_project_ui() -> void:
	if not is_instance_valid(_project_status_label) or not is_instance_valid(_construction_system):
		return
	var project: Dictionary = _construction_system.status()
	if not bool(project.created):
		_project_status_label.text = "PROJECT  Awaiting recognized barrier"
		_material_status_label.text = "STOCKPILE  wood 4   metal 4   mechanical parts 3"
		_build_status_label.text = "BUILD  Locked until material thresholds are met"
		return
	_project_status_label.text = "PROJECT  STEAMPUNK GRAPPLE  ·  %s  ·  Site (%.0f, %.0f) in" % [String(project.state).replace("_", " "), project.site.x, project.site.z]
	var stockpile: Dictionary = project.stockpile
	var delivered: Dictionary = project.delivered
	_material_status_label.text = "MATERIALS  Stockpile W %d/4  M %d/4  P %d/3     Delivered W %d/4  M %d/4  P %d/3" % [stockpile.wood, stockpile.metal, stockpile.mechanical_parts, delivered.wood, delivered.metal, delivered.mechanical_parts]
	if not project.cable_deployed:
		_build_status_label.text = "BUILD  %s %02.0f%%  ·  Components %d / 3  ·  Cable undeployed  ·  Floor / target disconnected" % [String(project.active_stage).to_upper(), project.progress_percent, project.completed_stages]
	else:
		var traversal: Dictionary = project.traversal
		var traversal_text := String(traversal.get("state", "CABLE_DEPLOYED" )).replace("_", " ")
		if traversal.has("actual_travelled_distance"):
			traversal_text += "  %.0f in walked to %s" % [float(traversal.actual_travelled_distance), _goal_surface_name()]
		_build_status_label.text = "TRAVERSAL  CABLE DEPLOYED  ·  FLOOR ↔ TARGET CONNECTED  ·  %s" % traversal_text


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			if not select_surface_at_screen_position(mouse_button.position):
				select_citizen_at_screen_position(mouse_button.position)
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_F3:
				_presentation_mode = not _presentation_mode
				_apply_presentation_mode()
				get_viewport().set_input_as_handled()
			elif key.keycode == KEY_F12:
				capture_interaction_state()
				get_viewport().set_input_as_handled()
			elif key.keycode == KEY_ENTER and _selected_surface == surface_navigation_goal_id():
				issue_reach_explore()
				get_viewport().set_input_as_handled()


func _select_surface_under_cursor(screen_position: Vector2) -> void:
	select_surface_at_screen_position(screen_position)


func select_surface_at_screen_position(screen_position: Vector2) -> bool:
	var camera := get_node("CameraRig/Camera") as Camera3D
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_end := ray_origin + camera.project_ray_normal(screen_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 2)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and (hit.collider as Node).is_in_group("goal_surface"):
		return select_goal_surface(String((hit.collider as Node).get_meta("region_id", "")))
	return false


func select_citizen_at_screen_position(screen_position: Vector2) -> bool:
	var camera := get_node("CameraRig/Camera") as Camera3D
	var closest_distance := 28.0
	var closest: Node3D
	for citizen in _citizens:
		var marker := citizen.global_position + Vector3(0.0, CITIZEN_HEIGHT_INCHES, 0.0)
		if camera.is_position_behind(marker):
			continue
		var distance := camera.unproject_position(marker).distance_to(screen_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = citizen
	if not is_instance_valid(closest):
		return false
	_selected_citizen = closest
	_update_population_ui()
	return true


func surface_navigation_goal_id() -> String:
	var navigation := get_node_or_null("SurfaceNavigation")
	return String(navigation.goal_surface_id) if is_instance_valid(navigation) else ""


func _goal_surface_name() -> String:
	var navigation := get_node_or_null("SurfaceNavigation")
	if not is_instance_valid(navigation):
		var goal_id := String(_room_definition.get("target_surface_id", ""))
		for object_variant in _room_definition.get("objects", []):
			var object: Dictionary = object_variant
			if object.has("surface") and String(object.surface.get("region_id", "")) == goal_id:
				return String(object.get("name", object.id))
		return "elevated surface"
	var surface: Dictionary = navigation.goal_surface()
	return String(surface.get("object_name", "elevated surface"))


func select_goal_surface(surface_id: String) -> bool:
	if surface_id != surface_navigation_goal_id():
		return false
	_selected_surface = surface_id
	for region_id in _surface_outlines:
		(_surface_outlines[region_id] as MeshInstance3D).visible = String(region_id) == surface_id
	_reach_button.visible = true
	_goal_status_label.text = "TARGET  %s SURFACE SELECTED  ·  Choose Reach / Explore." % _goal_surface_name().to_upper()
	return true


func issue_reach_explore() -> Dictionary:
	if _selected_surface.is_empty():
		return {"accepted": false, "state": "NO_TARGET", "message": "Select the elevated target surface first."}
	return _task_coordinator.issue_reach_explore(_selected_surface, _citizens)


func capture_interaction_state() -> void:
	var goal: Dictionary = _task_coordinator.get_reach_goal_status()
	var state_name := "startup"
	if not goal.is_empty() and goal.state == "BARRIER_CONFIRMED":
		state_name = "surface-investigation"
	elif not goal.is_empty():
		state_name = "explorers-approaching"
	elif not _selected_surface.is_empty():
		state_name = "target-selected"
	_capture_frame_named("milestone3-%s" % state_name)


func _make_label(node_name: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.05, 0.06, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _add_ui_panel(parent: CanvasLayer, node_name: String, bounds: Rect2, fill: Color) -> void:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = bounds.position
	panel.size = bounds.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.69, 0.51, 0.29, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 8
	style.shadow_offset = Vector2(1.0, 3.0)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)


func _build_animated_gear(parent: Node3D, node_name: String, at: Vector3, radius: float, teeth: int) -> void:
	var gear_root := Node3D.new()
	gear_root.name = node_name
	gear_root.position = at
	parent.add_child(gear_root)
	_animated_gear_roots.append(gear_root)
	_add_cylinder(gear_root, "BrassWheel", radius, 0.55, Vector3.ZERO, Color("c99443"))
	_add_cylinder(gear_root, "Hub", radius * 0.29, 0.72, Vector3.ZERO, Color("6c5140"))
	for tooth_index in range(teeth):
		var angle := TAU * float(tooth_index) / float(teeth)
		var tooth := _add_box(gear_root, "Tooth%02d" % tooth_index,
			Vector3(radius * 0.45, 0.8, radius * 0.26),
			Vector3(cos(angle) * radius * 0.9, 0.0, sin(angle) * radius * 0.9), Color("dfb75e"), 0.43)
		tooth.rotation.y = -angle


func _add_steam_emitter(parent: Node3D, node_name: String, at: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = node_name
	particles.position = at
	particles.amount = 22
	particles.lifetime = 2.8
	particles.explosiveness = 0.0
	particles.randomness = 0.48
	particles.emitting = true
	particles.visibility_aabb = AABB(Vector3(-4.0, -2.0, -4.0), Vector3(8.0, 28.0, 8.0))
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	motion.emission_sphere_radius = 0.45
	motion.direction = Vector3(0.0, 1.0, 0.0)
	motion.spread = 14.0
	motion.initial_velocity_min = 1.2
	motion.initial_velocity_max = 2.6
	motion.gravity = Vector3(0.0, -0.15, 0.0)
	motion.damping_min = 0.12
	motion.damping_max = 0.34
	motion.scale_min = 0.3
	motion.scale_max = 0.7
	motion.color = Color(0.78, 0.84, 0.87, 0.55)
	particles.process_material = motion
	var puff := SphereMesh.new()
	puff.radius = 0.55
	puff.height = 1.1
	var steam_material := StandardMaterial3D.new()
	steam_material.albedo_color = Color(0.82, 0.88, 0.9, 0.5)
	steam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = steam_material
	particles.draw_pass_1 = puff
	parent.add_child(particles)


func _add_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, color: Color, roughness: float = 0.8) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = at
	item.material_override = _material(color, roughness)
	parent.add_child(item)
	return item


func _add_cylinder(parent: Node3D, node_name: String, radius: float, height: float, at: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	item.mesh = mesh
	item.position = at
	item.material_override = _material(color, 0.68)
	parent.add_child(item)
	return item


func _add_sphere(parent: Node3D, node_name: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	item.mesh = mesh
	item.scale = size
	item.position = at
	item.material_override = _material(color, 0.75)
	parent.add_child(item)
	return item


func _add_book_stack(parent: Node3D, node_name: String, at: Vector3, count: int) -> void:
	var colors := [Color("97574a"), Color("52717b"), Color("c39b5a"), Color("596950")]
	for index in range(count):
		var width := 12.0 - float(index % 2) * 2.0
		_add_box(parent, "%s%d" % [node_name, index], Vector3(width, 1.8, 9.0), at + Vector3(0.0, float(index) * 2.0, 0.0), colors[index % colors.size()], 0.76)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var key := "%s_%.2f" % [color.to_html(), roughness]
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var category := "wood" if color.r > color.b * 1.15 and roughness > 0.55 else "paint"
	if roughness < 0.55:
		category = "brass" if color.r > color.b * 1.2 else "iron"
	var material := MaterialLibrary.get_material(category, color, roughness)
	_materials[key] = material
	return material


func _capture_frame() -> void:
	var tag := OS.get_environment("ROOMSCALE_RUN_TAG")
	if tag.is_empty():
		tag = "milestone8-launch-startup"
	_capture_frame_named(tag)


func _capture_frame_named(tag: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var artifact_directory := ProjectSettings.globalize_path("res://verification")
	DirAccess.make_dir_recursive_absolute(artifact_directory)
	var image_path := "%s/%s.png" % [artifact_directory, tag]
	var result := image.save_png(image_path)
	var proof := FileAccess.open("%s/%s.log" % [artifact_directory, tag], FileAccess.WRITE)
	proof.store_line("ROOMSCALE_M3_VISIBLE_PASS")
	proof.store_line("Godot=%s" % Engine.get_version_info().string)
	proof.store_line("Room=%.0fx%.0f in; walls=%.0f in" % [ROOM_WIDTH, ROOM_DEPTH, WALL_HEIGHT])
	var room_object_names := PackedStringArray()
	for room_object_variant in _room_definition.objects:
		var room_object: Dictionary = room_object_variant
		if String(room_object.get("kind", "")) != "settlement":
			room_object_names.append(String(room_object.get("name", room_object.get("id", "object"))))
	proof.store_line("Furniture=%s" % ", ".join(room_object_names))
	proof.store_line("Camera=pan/orbit/tilt/zoom; presets=room,settlement,citizen")
	proof.store_line("Population=%d separate citizens at 0.5in scale" % _citizens.size())
	proof.store_line("TaskBoard=%s" % JSON.stringify(_task_coordinator.summary()))
	proof.store_line("SelectedSurface=%s" % _selected_surface)
	proof.store_line("Goal=%s" % JSON.stringify(_task_coordinator.get_reach_goal_status()))
	proof.store_line("Screenshot=%s" % image_path)
	proof.store_line("ImageSaveResult=%d" % result)
	print("ROOMSCALE_VISIBLE_CAPTURE path=%s result=%d" % [image_path, result])
