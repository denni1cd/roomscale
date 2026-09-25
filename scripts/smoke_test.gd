extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/pipeline_proof.tscn") as PackedScene
	if packed == null:
		_fail("could not load the authored 3D scene")
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("main scene did not instantiate as Node3D")
		return
	root.add_child(scene)
	await process_frame
	var required_nodes := ["Floor", "TestObject", "Camera", "KeyLight", "Overlay/StatusLabel"]
	for node_path in required_nodes:
		if scene.get_node_or_null(NodePath(node_path)) == null:
			_fail("missing code-authored node: %s" % node_path)
			return
	var test_object := scene.get_node("TestObject") as MeshInstance3D
	var material := test_object.material_override as StandardMaterial3D
	if material == null:
		_fail("test object has no generated StandardMaterial3D")
		return
	if material.albedo_color.to_html() != "e9a23bff":
		_fail("initial visible material color does not match source constant: %s" % material.albedo_color)
		return
	print("ROOMSCALE_SMOKE_PASS nodes=%d script=%s initial_color=%s" % [required_nodes.size(), scene.get_script().resource_path, material.albedo_color.to_html()])
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_SMOKE_FAIL: " + message)
	quit(1)
