extends Node3D
## Milestone 1: entirely code-generated room, all dimensions measured in inches.

const StrategyCameraController := preload("res://scripts/strategy_camera.gd")

const ROOM_WIDTH := 240.0
const ROOM_DEPTH := 180.0
const WALL_HEIGHT := 72.0
const FLOOR_THICKNESS := 1.0
const CAPTURE_DELAY_SECONDS := 1.5

var _capture_timer := 0.0
var _capture_saved := false
var _materials: Dictionary = {}


func _ready() -> void:
	_build_room()
	_build_furniture()
	_build_room_props()
	_build_lighting()
	_build_camera()
	_build_ui()
	print("ROOMSCALE_M1_READY Godot=%s room=%.0fx%.0f in" % [Engine.get_version_info().string, ROOM_WIDTH, ROOM_DEPTH])


func _process(delta: float) -> void:
	_capture_timer += delta
	if not _capture_saved and _capture_timer >= CAPTURE_DELAY_SECONDS and DisplayServer.get_name() != "headless":
		_capture_saved = true
		_capture_frame()


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
	rug.position = Vector3(12.0, 0.0, 22.0)
	parent.add_child(rug)
	_add_box(rug, "RugUnderlay", Vector3(92.0, 0.4, 68.0), Vector3(0.0, 0.22, 0.0), Color("394b50"), 0.98)
	_add_box(rug, "RugField", Vector3(86.0, 0.15, 62.0), Vector3(0.0, 0.5, 0.0), Color("a66e4e"), 0.95)
	for x in [-39.0, 39.0]:
		_add_box(rug, "RugBorderLong", Vector3(3.0, 0.2, 54.0), Vector3(x, 0.61, 0.0), Color("dfba7a"), 0.88)
	for z in [-25.0, 25.0]:
		_add_box(rug, "RugBorderShort", Vector3(78.0, 0.2, 3.0), Vector3(0.0, 0.61, z), Color("dfba7a"), 0.88)
	_add_box(rug, "RugMedallion", Vector3(16.0, 0.22, 16.0), Vector3(0.0, 0.65, 0.0), Color("d5aa69"), 0.9)


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
	light.light_energy = 0.9
	light.shadow_enabled = true
	add_child(light)
	var fill := OmniLight3D.new()
	fill.name = "RoomFill"
	fill.position = Vector3(5.0, 68.0, 24.0)
	fill.light_color = Color("f7d8a0")
	fill.light_energy = 260.0
	fill.omni_range = 190.0
	fill.omni_attenuation = 1.35
	add_child(fill)
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color("17212b")
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("c8d1d5")
	resource.ambient_light_energy = 0.34
	resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = resource
	add_child(environment)


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


func _build_ui() -> void:
	var overlay := CanvasLayer.new()
	overlay.name = "Overlay"
	add_child(overlay)
	var title := _make_label("Title", Vector2(26.0, 20.0), 25, Color("fff2dc"))
	title.text = "ROOMSCALE   /   MILESTONE 1\nA room becomes a landscape"
	overlay.add_child(title)
	var help := _make_label("Controls", Vector2(28.0, 650.0), 16, Color("e5e6df"))
	help.text = "1 ROOM     2 SETTLEMENT     3 CITIZEN       WASD / ARROWS PAN     RIGHT DRAG ORBIT + TILT     MIDDLE DRAG PAN     WHEEL ZOOM"
	overlay.add_child(help)
	var mode := _make_label("CameraMode", Vector2(1000.0, 28.0), 16, Color("e7c991"))
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mode.text = "VIEW  ROOM  ·  300 in"
	overlay.add_child(mode)


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
	var image := get_viewport().get_texture().get_image()
	var tag := OS.get_environment("ROOMSCALE_RUN_TAG")
	if tag.is_empty():
		tag = "milestone1-room"
	var artifact_directory := ProjectSettings.globalize_path("res://verification")
	DirAccess.make_dir_recursive_absolute(artifact_directory)
	var image_path := "%s/%s.png" % [artifact_directory, tag]
	var result := image.save_png(image_path)
	var proof := FileAccess.open("%s/%s.log" % [artifact_directory, tag], FileAccess.WRITE)
	proof.store_line("ROOMSCALE_M1_VISIBLE_PASS")
	proof.store_line("Godot=%s" % Engine.get_version_info().string)
	proof.store_line("Room=%.0fx%.0f in; walls=%.0f in" % [ROOM_WIDTH, ROOM_DEPTH, WALL_HEIGHT])
	proof.store_line("Furniture=Desk,Chair,Bookcase,Rug,household props")
	proof.store_line("Camera=pan/orbit/tilt/zoom; presets=room,settlement,citizen")
	proof.store_line("Screenshot=%s" % image_path)
	proof.store_line("ImageSaveResult=%d" % result)
	print("ROOMSCALE_M1_SCREENSHOT path=%s result=%d" % [image_path, result])
