extends Node3D
## Milestone 1: entirely code-generated room, all dimensions measured in inches.

const StrategyCameraController := preload("res://scripts/strategy_camera.gd")
const FloorNavigationController := preload("res://scripts/floor_navigation.gd")
const SurfaceNavigationController := preload("res://scripts/surface_navigation.gd")
const TaskCoordinatorController := preload("res://scripts/task_coordinator.gd")
const CitizenAgentController := preload("res://scripts/citizen_agent.gd")
const ConstructionSystemController := preload("res://scripts/construction_system.gd")
const CITIZEN_HEIGHT_INCHES := 0.5

const ROOM_WIDTH := 240.0
const ROOM_DEPTH := 180.0
const WALL_HEIGHT := 72.0
const FLOOR_THICKNESS := 1.0
const CAPTURE_DELAY_SECONDS := 3.2

var _capture_timer := 0.0
var _capture_saved := false
var _materials: Dictionary = {}
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
var _desk_selection_outline: MeshInstance3D
var _reach_button: Button
var _goal_status_label: Label
var _project_status_label: Label
var _material_status_label: Label
var _build_status_label: Label
var _m6_status_label: Label
var _selected_surface := ""


func _ready() -> void:
	_build_room()
	_build_furniture()
	_build_room_props()
	_build_settlement()
	_build_lighting()
	_build_camera()
	_build_population()
	_build_ui()
	print("ROOMSCALE_M2_READY Godot=%s room=%.0fx%.0f in citizens=%d" % [Engine.get_version_info().string, ROOM_WIDTH, ROOM_DEPTH, _citizens.size()])


func _process(delta: float) -> void:
	_presentation_clock += delta
	for index in range(_animated_gear_roots.size()):
		var gear := _animated_gear_roots[index]
		gear.rotation.y += delta * (0.72 if index % 2 == 0 else -0.58)
	if is_instance_valid(_boiler_light):
		_boiler_light.light_energy = 20.0 + 5.0 * (0.5 + 0.5 * sin(_presentation_clock * 2.0))
	_capture_timer += delta
	_ui_timer += delta
	if _ui_timer >= 0.2:
		_ui_timer = 0.0
		_update_population_ui()
	var camera_rig := get_node_or_null("CameraRig") as StrategyCameraController
	var camera_settled := not is_instance_valid(camera_rig) or not camera_rig.is_camera_transition_active()
	if not _capture_saved and _capture_timer >= CAPTURE_DELAY_SECONDS and (camera_settled or _capture_timer >= 8.0) and DisplayServer.get_name() != "headless":
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


func _build_workshop(parent: Node3D) -> void:
	var shop := Node3D.new()
	shop.name = "Workshop"
	shop.position = Vector3(-20.0, 0.0, 42.0)
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
	_boiler_light.light_energy = 22.0
	_boiler_light.omni_range = 12.0
	shop.add_child(_boiler_light)


func _build_depot(parent: Node3D) -> void:
	var depot := Node3D.new()
	depot.name = "Depot"
	depot.position = Vector3(18.0, 0.0, 42.0)
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
	housing.position = Vector3(-25.0, 0.0, 66.0)
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
	area.position = Vector3(11.0, 0.0, 66.0)
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

	_add_box(room, "Floor", Vector3(ROOM_WIDTH, FLOOR_THICKNESS, ROOM_DEPTH), Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0), Color("795b43"), 0.82)
	# Fine seams give the broad floor a familiar wood-plank scale.
	for index in range(1, 20):
		var x := -ROOM_WIDTH * 0.5 + float(index) * 12.0
		_add_box(room, "FloorSeam%02d" % index, Vector3(0.18, 0.025, ROOM_DEPTH - 1.0), Vector3(x, 0.012, 0.0), Color("634b3b"), 0.92)

	# Three walls define a room while the open front keeps the furniture visible.
	_add_box(room, "WallBack", Vector3(ROOM_WIDTH, WALL_HEIGHT, 2.0), Vector3(0.0, WALL_HEIGHT * 0.5, -ROOM_DEPTH * 0.5), Color("d9c9aa"), 0.94)
	_add_box(room, "WallLeft", Vector3(2.0, WALL_HEIGHT, ROOM_DEPTH), Vector3(-ROOM_WIDTH * 0.5, WALL_HEIGHT * 0.5, 0.0), Color("c6b99f"), 0.95)
	_add_box(room, "WallRight", Vector3(2.0, WALL_HEIGHT, ROOM_DEPTH), Vector3(ROOM_WIDTH * 0.5, WALL_HEIGHT * 0.5, 0.0), Color("c6b99f"), 0.95)
	_add_box(room, "BaseboardBack", Vector3(ROOM_WIDTH, 3.0, 1.0), Vector3(0.0, 1.5, -ROOM_DEPTH * 0.5 + 1.0), Color("76583f"), 0.78)
	_add_box(room, "BaseboardLeft", Vector3(1.0, 3.0, ROOM_DEPTH), Vector3(-ROOM_WIDTH * 0.5 + 1.0, 1.5, 0.0), Color("76583f"), 0.78)
	_add_box(room, "BaseboardRight", Vector3(1.0, 3.0, ROOM_DEPTH), Vector3(ROOM_WIDTH * 0.5 - 1.0, 1.5, 0.0), Color("76583f"), 0.78)
	_build_window(room)
	_build_wall_art(room)


func _build_window(parent: Node3D) -> void:
	var z := -ROOM_DEPTH * 0.5 + 1.55
	_add_box(parent, "WindowRecess", Vector3(48.0, 27.0, 0.5), Vector3(-65.0, 48.0, z), Color("4c6570"), 0.5)
	_add_box(parent, "WindowGlass", Vector3(43.0, 22.0, 0.25), Vector3(-65.0, 48.0, z + 0.28), Color("9bb9c5"), 0.24)
	for x in [-88.0, -42.0]:
		_add_box(parent, "WindowFrameSide", Vector3(2.0, 29.0, 1.5), Vector3(x, 48.0, z + 0.8), Color("f1e8d5"), 0.52)
	for y in [33.5, 62.5]:
		_add_box(parent, "WindowFrameRail", Vector3(48.0, 2.0, 1.5), Vector3(-65.0, y, z + 0.8), Color("f1e8d5"), 0.52)
	_add_box(parent, "WindowMullionV", Vector3(1.5, 26.0, 1.2), Vector3(-65.0, 48.0, z + 1.05), Color("f1e8d5"), 0.54)
	_add_box(parent, "WindowMullionH", Vector3(45.0, 1.5, 1.2), Vector3(-65.0, 48.0, z + 1.05), Color("f1e8d5"), 0.54)


func _build_wall_art(parent: Node3D) -> void:
	var z := -ROOM_DEPTH * 0.5 + 1.5
	_add_box(parent, "PictureFrame", Vector3(23.0, 18.0, 1.4), Vector3(28.0, 48.0, z), Color("765239"), 0.55)
	_add_box(parent, "PictureMat", Vector3(19.0, 14.0, 0.35), Vector3(28.0, 48.0, z + 0.9), Color("eadfc8"), 0.82)
	_add_box(parent, "PictureLandscape", Vector3(15.0, 9.0, 0.35), Vector3(28.0, 48.0, z + 1.15), Color("608477"), 0.85)
	_add_box(parent, "PictureSun", Vector3(4.0, 4.0, 0.25), Vector3(32.0, 51.0, z + 1.4), Color("e8b85e"), 0.6)


func _build_furniture() -> void:
	var furniture := Node3D.new()
	furniture.name = "Furniture"
	add_child(furniture)
	_build_desk(furniture)
	_build_chair(furniture)
	_build_bookcase(furniture)
	_build_rug(furniture)
	_build_side_table_and_lamp(furniture)


func _build_desk(parent: Node3D) -> void:
	var desk := Node3D.new()
	desk.name = "Desk"
	desk.position = Vector3(-58.0, 0.0, -52.0)
	parent.add_child(desk)
	_add_box(desk, "DeskTop", Vector3(68.0, 3.0, 34.0), Vector3(0.0, 28.5, 0.0), Color("81593e"), 0.48)
	_add_box(desk, "DeskApronFront", Vector3(64.0, 5.0, 2.0), Vector3(0.0, 24.5, 15.0), Color("70482f"), 0.56)
	_add_box(desk, "DeskApronBack", Vector3(64.0, 5.0, 2.0), Vector3(0.0, 24.5, -15.0), Color("70482f"), 0.56)
	for x in [-30.0, 30.0]:
		for z in [-13.0, 13.0]:
			_add_box(desk, "DeskLeg", Vector3(3.0, 24.0, 3.0), Vector3(x, 12.0, z), Color("745039"), 0.58)
	# Left-side drawer bank and brass knobs.
	_add_box(desk, "DrawerBank", Vector3(15.0, 10.0, 24.0), Vector3(-18.0, 19.0, 0.0), Color("996d49"), 0.54)
	for y in [17.0, 21.0]:
		_add_box(desk, "DrawerFront", Vector3(15.3, 0.7, 11.0), Vector3(-18.0, y, 12.5), Color("b08355"), 0.5)
		_add_box(desk, "DrawerPull", Vector3(1.4, 1.4, 1.0), Vector3(-18.0, y, 13.5), Color("c79b4e"), 0.26)
	_add_book_stack(desk, "DeskBooks", Vector3(-16.0, 30.5, -6.0), 3)
	_add_box(desk, "DeskNotebook", Vector3(13.0, 0.8, 9.0), Vector3(12.0, 30.4, -8.0), Color("9a624a"), 0.78)
	_add_box(desk, "DeskPaper", Vector3(9.0, 0.25, 6.0), Vector3(12.0, 30.9, -8.0), Color("eee1c6"), 0.94)
	_add_cylinder(desk, "DeskMug", 2.7, 4.8, Vector3(24.0, 33.8, 4.0), Color("668c92"))
	_add_box(desk, "DeskLampBase", Vector3(8.0, 1.5, 7.0), Vector3(25.0, 31.8, -8.0), Color("574539"), 0.38)
	_add_cylinder(desk, "DeskLampStem", 0.8, 9.0, Vector3(25.0, 36.2, -8.0), Color("c49a51"))
	_add_box(desk, "DeskLampShade", Vector3(9.0, 5.0, 8.0), Vector3(25.0, 42.0, -8.0), Color("e6bd78"), 0.55)
	var selection_body := StaticBody3D.new()
	selection_body.name = "DeskSelectionCollider"
	selection_body.add_to_group("desk_goal_surface")
	selection_body.collision_layer = 2
	selection_body.collision_mask = 0
	var selection_shape := CollisionShape3D.new()
	var desk_surface_shape := BoxShape3D.new()
	desk_surface_shape.size = Vector3(68.0, 3.0, 34.0)
	selection_shape.shape = desk_surface_shape
	selection_shape.position = Vector3(0.0, 28.5, 0.0)
	selection_body.add_child(selection_shape)
	desk.add_child(selection_body)
	_desk_selection_outline = _add_box(desk, "DeskSelectionOutline", Vector3(69.0, 0.18, 35.0), Vector3(0.0, 30.12, 0.0), Color("e9bf59"), 0.32)
	var outline_material := _desk_selection_outline.material_override as StandardMaterial3D
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_material.albedo_color.a = 0.35
	_desk_selection_outline.visible = false


func _build_chair(parent: Node3D) -> void:
	var chair := Node3D.new()
	chair.name = "Chair"
	chair.position = Vector3(-58.0, 0.0, -20.0)
	parent.add_child(chair)
	_add_box(chair, "ChairSeat", Vector3(25.0, 3.0, 23.0), Vector3(0.0, 16.5, 0.0), Color("546d68"), 0.72)
	_add_box(chair, "ChairCushion", Vector3(22.0, 1.0, 20.0), Vector3(0.0, 18.5, 0.0), Color("819287"), 0.9)
	_add_box(chair, "ChairBack", Vector3(25.0, 30.0, 3.0), Vector3(0.0, 34.0, -10.0), Color("73513b"), 0.58)
	_add_box(chair, "ChairBackInset", Vector3(19.0, 23.0, 1.0), Vector3(0.0, 34.0, -8.0), Color("607970"), 0.84)
	for x in [-10.0, 10.0]:
		for z in [-8.5, 8.5]:
			_add_box(chair, "ChairLeg", Vector3(2.2, 16.0, 2.2), Vector3(x, 8.0, z), Color("674a37"), 0.58)
	for x in [-12.0, 12.0]:
		_add_box(chair, "ChairArm", Vector3(3.0, 3.0, 15.0), Vector3(x, 25.0, -2.0), Color("71503a"), 0.55)


func _build_bookcase(parent: Node3D) -> void:
	var shelf := Node3D.new()
	shelf.name = "Bookcase"
	shelf.position = Vector3(91.0, 0.0, -63.0)
	parent.add_child(shelf)
	_add_box(shelf, "BookcaseBack", Vector3(30.0, 63.0, 2.0), Vector3(0.0, 31.5, -6.0), Color("74503a"), 0.62)
	for x in [-15.0, 15.0]:
		_add_box(shelf, "BookcaseSide", Vector3(2.0, 64.0, 15.0), Vector3(x, 32.0, 0.0), Color("805a3d"), 0.6)
	for y in [1.5, 17.0, 32.5, 48.0, 63.0]:
		_add_box(shelf, "ShelfBoard", Vector3(32.0, 2.0, 17.0), Vector3(0.0, y, 0.5), Color("956b47"), 0.56)
	for level in range(4):
		var shelf_y := 9.0 + float(level) * 15.5
		for index in range(5):
			var book_width := 3.0 + float((index + level) % 3) * 0.65
			var x := -11.0 + float(index) * 5.3
			var colors := [Color("8d5143"), Color("4f7380"), Color("be9858"), Color("68624b")]
			_add_box(shelf, "ShelfBook", Vector3(book_width, 11.0 + float(index % 2) * 2.0, 8.0), Vector3(x, shelf_y, 1.0), colors[(index + level) % colors.size()], 0.75)
	_add_box(shelf, "TopTrim", Vector3(35.0, 3.0, 19.0), Vector3(0.0, 65.0, 0.0), Color("a47b53"), 0.48)


func _build_rug(parent: Node3D) -> void:
	var rug := Node3D.new()
	rug.name = "Rug"
	rug.position = Vector3(50.0, 0.0, -22.0)
	parent.add_child(rug)
	# Decorative weave remains under 0.1in high so half-inch citizens stay visible above it.
	_add_box(rug, "RugUnderlay", Vector3(92.0, 0.06, 68.0), Vector3(0.0, 0.03, 0.0), Color("394b50"), 0.98)
	_add_box(rug, "RugField", Vector3(86.0, 0.025, 62.0), Vector3(0.0, 0.072, 0.0), Color("a66e4e"), 0.95)
	for x in [-39.0, 39.0]:
		_add_box(rug, "RugBorderLong", Vector3(3.0, 0.025, 54.0), Vector3(x, 0.097, 0.0), Color("dfba7a"), 0.88)
	for z in [-25.0, 25.0]:
		_add_box(rug, "RugBorderShort", Vector3(78.0, 0.025, 3.0), Vector3(0.0, 0.097, z), Color("dfba7a"), 0.88)
	_add_box(rug, "RugMedallion", Vector3(16.0, 0.025, 16.0), Vector3(0.0, 0.112, 0.0), Color("d5aa69"), 0.9)


func _build_side_table_and_lamp(parent: Node3D) -> void:
	var table := Node3D.new()
	table.name = "SideTable"
	table.position = Vector3(44.0, 0.0, -15.0)
	parent.add_child(table)
	_add_box(table, "SideTableTop", Vector3(20.0, 2.5, 17.0), Vector3(0.0, 19.0, 0.0), Color("80583d"), 0.55)
	_add_box(table, "SideTableShelf", Vector3(17.0, 1.4, 14.0), Vector3(0.0, 8.0, 0.0), Color("704b35"), 0.65)
	for x in [-8.0, 8.0]:
		for z in [-6.0, 6.0]:
			_add_box(table, "SideTableLeg", Vector3(1.8, 18.0, 1.8), Vector3(x, 9.0, z), Color("765139"), 0.6)
	_add_cylinder(table, "Planter", 5.5, 7.0, Vector3(0.0, 23.8, -1.0), Color("a86549"))
	_add_cylinder(table, "PlantStem", 0.6, 13.0, Vector3(0.0, 33.0, -1.0), Color("617955"))
	_add_sphere(table, "PlantLeafLeft", Vector3(8.0, 4.5, 4.0), Vector3(-4.0, 36.0, -1.0), Color("789166"))
	_add_sphere(table, "PlantLeafRight", Vector3(8.0, 4.5, 4.0), Vector3(4.0, 39.0, -1.0), Color("8aa076"))
	_add_sphere(table, "PlantLeafTop", Vector3(6.0, 7.0, 4.0), Vector3(0.0, 42.0, -1.0), Color("6d8a60"))


func _build_room_props() -> void:
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	_add_box(props, "StorageBox", Vector3(16.0, 13.0, 13.0), Vector3(75.0, 6.5, 43.0), Color("a98254"), 0.77)
	_add_box(props, "StorageBoxLid", Vector3(17.0, 1.8, 14.0), Vector3(75.0, 14.0, 43.0), Color("c29a65"), 0.7)
	_add_cylinder(props, "WasteBin", 8.0, 13.0, Vector3(-99.0, 6.5, 12.0), Color("637674"))
	_add_cylinder(props, "WasteBinRim", 8.5, 1.5, Vector3(-99.0, 13.5, 12.0), Color("84928b"))
	_add_book_stack(props, "FloorBooks", Vector3(72.0, 1.2, 25.0), 2)
	_add_box(props, "RoomPlantPot", Vector3(10.0, 9.0, 10.0), Vector3(-91.0, 4.5, -46.0), Color("a9654a"), 0.86)
	_add_cylinder(props, "RoomPlantStem", 0.7, 24.0, Vector3(-91.0, 21.0, -46.0), Color("607958"))
	_add_sphere(props, "RoomPlantLeafA", Vector3(13.0, 5.0, 9.0), Vector3(-97.0, 30.0, -46.0), Color("7f946c"))
	_add_sphere(props, "RoomPlantLeafB", Vector3(12.0, 6.0, 9.0), Vector3(-85.0, 34.0, -46.0), Color("6f895e"))


func _build_lighting() -> void:
	var light := DirectionalLight3D.new()
	light.name = "KeyLight"
	light.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	add_child(light)
	var fill := OmniLight3D.new()
	fill.name = "RoomFill"
	fill.position = Vector3(5.0, 68.0, 24.0)
	fill.light_color = Color("f7d8a0")
	fill.light_energy = 82.0
	fill.omni_range = 190.0
	fill.omni_attenuation = 1.35
	add_child(fill)
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color("17212b")
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("d5cdbb")
	resource.ambient_light_energy = 0.34
	resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	resource.glow_enabled = true
	resource.glow_intensity = 0.14
	resource.glow_bloom = 0.04
	resource.glow_hdr_threshold = 1.5
	environment.environment = resource
	add_child(environment)
	var lantern_fill := OmniLight3D.new()
	lantern_fill.name = "SettlementLanternFill"
	lantern_fill.position = Vector3(-25.0, 10.0, 60.0)
	lantern_fill.light_color = Color("e5a95d")
	lantern_fill.light_energy = 24.0
	lantern_fill.omni_range = 38.0
	lantern_fill.omni_attenuation = 1.5
	add_child(lantern_fill)


func _build_camera() -> void:
	var rig := StrategyCameraController.new()
	rig.name = "CameraRig"
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


func _build_population() -> void:
	var navigation := FloorNavigationController.new()
	navigation.name = "FloorNavigation"
	add_child(navigation)
	var surface_navigation := SurfaceNavigationController.new()
	surface_navigation.name = "SurfaceNavigation"
	surface_navigation.floor_navigation = navigation
	add_child(surface_navigation)
	_task_coordinator = TaskCoordinatorController.new()
	_task_coordinator.name = "TaskCoordinator"
	_task_coordinator.navigation = navigation
	_task_coordinator.surface_navigation = surface_navigation
	add_child(_task_coordinator)
	_task_coordinator.seed_population(50)
	var starts: Array[Vector3] = []
	for citizen_id in range(50):
		var column := citizen_id % 10
		var row := citizen_id / 10
		var proposed := Vector3(-47.0 + float(column) * 10.4, 0.0, 17.0 + float(row) * 14.0)
		var spawn: Vector3 = navigation.nearest_walkable_position(proposed)
		if not is_finite(spawn.x):
			push_error("No walkable spawn position for citizen %d" % citizen_id)
			continue
		var attempts := 0
		while _overlaps_spawn(spawn, starts) and attempts < 8:
			attempts += 1
			proposed += Vector3(0.0, 0.0, 4.0)
			spawn = navigation.nearest_walkable_position(proposed)
		starts.append(spawn)
		var citizen: Node3D = CitizenAgentController.new()
		citizen.initialize(citizen_id, spawn, navigation, _task_coordinator)
		add_child(citizen)
		_citizens.append(citizen)
	_construction_system = ConstructionSystemController.new()
	_construction_system.name = "ConstructionSystem"
	_construction_system.configure(_task_coordinator, navigation, _citizens, self)
	_construction_system.surface_navigation = surface_navigation
	_task_coordinator.construction_system = _construction_system
	_task_coordinator.reach_goal_updated.connect(_on_reach_goal_updated)
	_task_coordinator.task_board_updated.connect(_on_task_board_updated)
	_construction_system.project_updated.connect(_on_project_updated)
	add_child(_construction_system)
	if _citizens.size() > 23:
		get_node("CameraRig").set_citizen_focus(_citizens[23])
	print("ROOMSCALE_CITIZEN_SPAWN count=%d separate_nodes=true height=%.1fin" % [_citizens.size(), CITIZEN_HEIGHT_INCHES])


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
	title.text = "ROOMSCALE  ·  A LIVING TINY ROOM"
	overlay.add_child(title)
	var help := _make_label("Controls", Vector2(28.0, 636.0), 14, Color("e5e6df"))
	help.text = "1 ROOM  ·  2 SETTLEMENT  ·  3 CITIZEN    |    WASD / ARROWS PAN    ·    RIGHT DRAG ORBIT    ·    WHEEL ZOOM\nClick the desk, then Reach / Explore    ·    Enter issues goal    ·    F12 captures this moment"
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
	_goal_status_label.text = "GOAL  Click the desk surface to select it."
	overlay.add_child(_goal_status_label)
	_reach_button = Button.new()
	_reach_button.name = "ReachExploreButton"
	_reach_button.text = "REACH / EXPLORE DESK"
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
	_update_population_ui()


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
	_reach_button.visible = _selected_surface == SurfaceNavigationController.DESK_REGION
	var goal: Dictionary = _task_coordinator.get_reach_goal_status()
	if goal.is_empty():
		_goal_status_label.text = "GOAL  Click desk to select." if _selected_surface.is_empty() else "TARGET  DESK SELECTED · Choose Reach / Explore."
	else:
		_goal_status_label.text = "GOAL  %s\n%s" % [String(goal.state).replace("_", " "), String(goal.message)]
	var camera_rig := get_node("CameraRig")
	_focus_label.visible = camera_rig.view_mode == 2 and _citizens.size() > 23
	if _focus_label.visible:
		var focus: Node3D = camera_rig.get_focused_citizen()
		if not is_instance_valid(focus):
			focus = _citizens[23]
		_focus_label.text = "%s  ·  %s  ·  %s" % [focus.name, focus.task_type.replace("_", " "), focus.state]
	var m6: Dictionary = _task_coordinator.get_m6_status()
	_m6_status_label.text = "DESK  ARRIVED %d · EXPLORED %d · REUSES %d/2 · LINK %s" % [m6.desk_arrivals, m6.desk_explorations_completed, m6.autonomous_reuses_assigned, "LIVE" if m6.infrastructure_operational else "WAITING"]
	_update_project_ui()


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
		_build_status_label.text = "BUILD  %s %02.0f%%  ·  Components %d / 3  ·  Cable undeployed  ·  Floor / desk disconnected" % [String(project.active_stage).to_upper(), project.progress_percent, project.completed_stages]
	else:
		var traversal: Dictionary = project.traversal
		var traversal_text := String(traversal.get("state", "CABLE_DEPLOYED" )).replace("_", " ")
		if traversal.has("actual_travelled_distance"):
			traversal_text += "  %.0f in walked to DESK" % float(traversal.actual_travelled_distance)
		_build_status_label.text = "TRAVERSAL  CABLE DEPLOYED  ·  FLOOR ↔ DESK CONNECTED  ·  %s" % traversal_text


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_select_surface_under_cursor(mouse_button.position)
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_F12:
				capture_interaction_state()
				get_viewport().set_input_as_handled()
			elif key.keycode == KEY_ENTER and _selected_surface == SurfaceNavigationController.DESK_REGION:
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
	if not hit.is_empty() and (hit.collider as Node).is_in_group("desk_goal_surface"):
		return select_goal_surface(SurfaceNavigationController.DESK_REGION)
	return false


func select_goal_surface(surface_id: String) -> bool:
	if surface_id != SurfaceNavigationController.DESK_REGION:
		return false
	_selected_surface = surface_id
	_desk_selection_outline.visible = true
	_reach_button.visible = true
	_goal_status_label.text = "TARGET  DESK SURFACE SELECTED  ·  Choose Reach / Explore."
	return true


func issue_reach_explore() -> Dictionary:
	if _selected_surface.is_empty():
		return {"accepted": false, "state": "NO_TARGET", "message": "Select the desk surface first."}
	return _task_coordinator.issue_reach_explore(_selected_surface, _citizens)


func capture_interaction_state() -> void:
	var goal: Dictionary = _task_coordinator.get_reach_goal_status()
	var state_name := "startup"
	if not goal.is_empty() and goal.state == "BARRIER_CONFIRMED":
		state_name = "desk-investigation"
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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
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
	proof.store_line("Furniture=Desk,Chair,Bookcase,Rug,household props")
	proof.store_line("Camera=pan/orbit/tilt/zoom; presets=room,settlement,citizen")
	proof.store_line("Population=%d separate citizens at 0.5in scale" % _citizens.size())
	proof.store_line("TaskBoard=%s" % JSON.stringify(_task_coordinator.summary()))
	proof.store_line("SelectedSurface=%s" % _selected_surface)
	proof.store_line("Goal=%s" % JSON.stringify(_task_coordinator.get_reach_goal_status()))
	proof.store_line("Screenshot=%s" % image_path)
	proof.store_line("ImageSaveResult=%d" % result)
	print("ROOMSCALE_VISIBLE_CAPTURE path=%s result=%d" % [image_path, result])
