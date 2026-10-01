extends SceneTree
const Furniture := preload("res://scripts/visuals/furniture_recipes.gd")

func _initialize() -> void:
	call_deferred("_generate")

func _generate() -> void:
	var asset := Node3D.new()
	asset.name = "WritingDesk"
	var requirement := {"kind": "desk", "dimensions": [68, 30, 34], "color": "70503b"}
	var recipe := {"archetype": "desk", "appearance": {}}
	if not Furniture.build(asset, requirement, recipe):
		push_error("ASSET_GENERATION_FAILED: desk recipe did not resolve")
		asset.free()
		quit(1)
		return
	root.add_child(asset)
	# Noise textures generate asynchronously; export after completion.
	await create_timer(1.0).timeout
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_scene(asset, state)
	if error == OK:
		DirAccess.make_dir_recursive_absolute("res://assets/generated")
		error = document.write_to_filesystem(state, "res://assets/generated/writing_desk.glb")
	if error != OK:
		push_error("ASSET_GENERATION_FAILED writing_desk error=%s" % error)
		quit(1)
		return
	print("ROOMSCALE_ASSET_GENERATED path=assets/generated/writing_desk.glb components=%d source=AI_authored_procedural_recipe" % asset.get_child_count())
	asset.queue_free()
	await process_frame
	quit()
