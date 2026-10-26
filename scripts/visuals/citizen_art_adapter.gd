extends RefCounted
## Resolves an accepted Art Factory citizen while preserving the live pose rig.

const AssetRegistry := preload("res://scripts/visuals/asset_registry.gd")

const RIG_PARTS := ["Body", "LeftArm", "RightArm", "LeftLeg", "RightLeg"]


static func apply(model: Node3D, preserve_names: PackedStringArray) -> Dictionary:
	var registry := AssetRegistry.new()
	if not registry.valid:
		return _fail_closed(model, preserve_names, "registry could not be read")
	if not registry.entries.has("citizen"):
		return {"registered": false}

	var entry := registry.lookup("citizen")
	var source := String(entry.get("resolved_path", ""))
	var candidate_id := String(entry.get("candidate_id", ""))
	if not String(entry.get("resolution_error", "")).is_empty():
		return _fail_closed(model, preserve_names, String(entry.resolution_error), source, candidate_id)
	var packed := load(source) as PackedScene
	if packed == null:
		return _fail_closed(model, preserve_names, "accepted citizen asset is not an instantiable PackedScene", source, candidate_id)
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return _fail_closed(model, preserve_names, "accepted citizen asset root must be Node3D", source, candidate_id)
	for part_name in RIG_PARTS:
		var part := instance.get_node_or_null(NodePath(part_name)) as MeshInstance3D
		if part == null:
			instance.free()
			return _fail_closed(model, preserve_names, "accepted citizen asset is missing rig mesh %s" % part_name, source, candidate_id)

	instance.name = "CitizenArtAsset"
	instance.set_meta("visual_asset_id", "citizen")
	instance.set_meta("visual_asset_candidate_id", candidate_id)
	instance.set_meta("visual_source", source)
	model.add_child(instance)
	for child in model.get_children():
		if child == instance or preserve_names.has(String(child.name)):
			continue
		child.queue_free()

	model.set_meta("visual_asset_id", "citizen")
	model.set_meta("visual_asset_candidate_id", candidate_id)
	model.set_meta("visual_source", source)
	var rig := {}
	for part_name in RIG_PARTS:
		rig[part_name] = instance.get_node(part_name)
	return {"registered": true, "loaded": true, "instance": instance, "rig": rig}


static func _fail_closed(
	model: Node3D,
	preserve_names: PackedStringArray,
	reason: String,
	source: String = "",
	candidate_id: String = ""
) -> Dictionary:
	for child in model.get_children():
		if preserve_names.has(String(child.name)):
			continue
		var spatial := child as Node3D
		if spatial != null:
			spatial.visible = false
		child.name = "Legacy_%s" % child.name
	var marker := Node3D.new()
	marker.name = "CitizenArtAsset"
	marker.set_meta("visual_asset_id", "citizen")
	marker.set_meta("visual_asset_candidate_id", candidate_id)
	marker.set_meta("visual_source", "required_asset_failure")
	marker.set_meta("visual_asset_error", reason)
	model.add_child(marker)
	model.set_meta("visual_asset_id", "citizen")
	model.set_meta("visual_asset_candidate_id", candidate_id)
	model.set_meta("visual_source", "required_asset_failure")
	model.set_meta("visual_asset_error", reason)
	push_warning("ROOMSCALE_REQUIRED_VISUAL_ASSET_FAILURE asset=citizen path=%s: %s" % [source, reason])
	return {"registered": true, "loaded": false, "error": reason}
