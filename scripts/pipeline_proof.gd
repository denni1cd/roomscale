extends Node3D
## Code-authored 3D proof scene. Change the object color in code to verify edit-to-run.

const OBJECT_COLOR := Color("e9a23b")
const CAPTURE_DELAY_SECONDS := 1.25

var _capture_timer := 0.0
var _capture_saved := false


func _ready() -> void:
	_build_scene()
	print("ROOMSCALE_PIPELINE_READY Godot=%s ObjectColor=%s" % [Engine.get_version_info().string, OBJECT_COLOR.to_html()])


func _process(delta: float) -> void:
	_capture_timer += delta
	var item := get_node_or_null("TestObject") as MeshInstance3D
	if item:
		item.rotation.y += delta * 0.55
	if not _capture_saved and _capture_timer >= CAPTURE_DELAY_SECONDS and DisplayServer.get_name() != "headless":
		_capture_saved = true
		_capture_frame()


func _build_scene() -> void:
	var floor := MeshInstance3D.new()
	floor.name = "Floor"
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(10.0, 0.2, 8.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.1, 0.0)
	floor.material_override = _material(Color("283a46"), 0.88)
	add_child(floor)

	var object := MeshInstance3D.new()
	object.name = "TestObject"
	var object_mesh := BoxMesh.new()
	object_mesh.size = Vector3(1.5, 1.5, 1.5)
	object.mesh = object_mesh
	object.position = Vector3(0.0, 0.9, 0.0)
	object.material_override = _material(OBJECT_COLOR, 0.3)
	add_child(object)

	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(7.0, 5.0, 8.0)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	camera.current = true
	add_child(camera)

	var light := DirectionalLight3D.new()
	light.name = "KeyLight"
	light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	light.light_energy = 1.4
	add_child(light)

	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color("09111c")
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color("a9c6df")
	environment_resource.ambient_light_energy = 0.45
	environment.environment = environment_resource
	add_child(environment)

	var overlay := CanvasLayer.new()
	overlay.name = "Overlay"
	add_child(overlay)
	var label := Label.new()
	label.name = "StatusLabel"
	label.position = Vector2(28.0, 24.0)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("ecf5ff"))
	label.text = "ROOMSCALE  /  MILESTONE 0\nGDScript built this 3D scene at runtime\nObject material: %s" % OBJECT_COLOR.to_html()
	overlay.add_child(label)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _capture_frame() -> void:
	var image := get_viewport().get_texture().get_image()
	var tag := OS.get_environment("ROOMSCALE_RUN_TAG")
	if tag.is_empty():
		tag = "visible-run"
	var artifact_directory := ProjectSettings.globalize_path("res://verification")
	DirAccess.make_dir_recursive_absolute(artifact_directory)
	var image_path := "%s/%s.png" % [artifact_directory, tag]
	var result := image.save_png(image_path)
	var proof := FileAccess.open("%s/%s.log" % [artifact_directory, tag], FileAccess.WRITE)
	proof.store_line("ROOMSCALE_VISIBLE_PASS")
	proof.store_line("Godot=%s" % Engine.get_version_info().string)
	proof.store_line("ObjectColor=%s" % OBJECT_COLOR.to_html())
	proof.store_line("Screenshot=%s" % image_path)
	proof.store_line("ImageSaveResult=%d" % result)
	print("ROOMSCALE_SCREENSHOT path=%s result=%d color=%s" % [image_path, result, OBJECT_COLOR.to_html()])
