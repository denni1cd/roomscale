extends SceneTree

const REGISTRY_PATH := "res://verification/poc25/final/best-current-art-showcase-registry-v089.json"
const EXPECTED := {
	"citizen": {
		"candidate_id": "citizen-v089",
		"path": "res://art/citizen/iterations/v089/generated/citizen.tscn",
		"status": "best_current_review",
	},
	"desk": {
		"candidate_id": "desk-v007",
		"path": "res://art/desk/iterations/v007/generated/desk.tscn",
		"status": "best_current_review",
	},
	"grapple": {
		"candidate_id": "grapple-v006",
		"path": "res://art/grapple/iterations/v006/generated/grapple.tscn",
		"status": "best_current_review",
	},
}


func _initialize() -> void:
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_MANUAL_CAMERA", "1")
	call_deferred("_run")


func _run() -> void:
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame
	var resolver: Variant = scene.get("_visual_resolver")
	if resolver == null:
		_fail("production scene has no visual resolver")
		return
	var registry: Variant = resolver.get("registry")
	if registry == null or not bool(registry.get("valid")) or not bool(registry.get("review_showcase")):
		_fail("production scene did not load a valid review_showcase registry")
		return
	if String(registry.get("registry_path")) != REGISTRY_PATH:
		_fail("production scene loaded a different review registry: %s" % String(registry.get("registry_path")))
		return
	var entries: Dictionary = registry.get("entries")
	for asset_id in EXPECTED:
		if not entries.has(asset_id):
			_fail("review registry omitted required best-current asset %s" % asset_id)
			return
		var expected: Dictionary = EXPECTED[asset_id]
		var entry: Dictionary = entries[asset_id]
		if String(entry.get("candidate_id", "")) != String(expected.candidate_id) or String(entry.get("status", "")) != String(expected.status):
			_fail("registry entry does not preserve the expected best-current candidate for %s: %s" % [asset_id, entry])
			return
		var resolved: Dictionary = registry.lookup(String(asset_id))
		if not String(resolved.get("resolution_error", "")).is_empty() or String(resolved.get("resolved_path", "")) != String(expected.path) or not bool(resolved.get("registry_review_only", false)):
			_fail("best-current entry failed resolution or lost its review-only marker for %s: %s" % [asset_id, resolved])
			return
	var citizens: Array = scene.get("_citizens")
	if citizens.size() != 50:
		_fail("expected all 50 production citizens, found %d" % citizens.size())
		return
	for citizen_variant in citizens:
		var citizen := citizen_variant as Node3D
		var figure := citizen.get_node_or_null("Figure") as Node3D
		var art := figure.get_node_or_null("CitizenArtAsset") as Node3D if figure != null else null
		if art == null:
			_fail("citizen has no instantiated Art Factory figure: %s" % citizen.name)
			return
		if String(figure.get_meta("visual_asset_candidate_id", "")) != "citizen-v089" or String(figure.get_meta("visual_source", "")) != String(EXPECTED.citizen.path) or not bool(figure.get_meta("visual_asset_review_only", false)):
			_fail("citizen did not resolve v089 through the review-only registry: %s candidate=%s source=%s review_only=%s" % [citizen.name, figure.get_meta("visual_asset_candidate_id", ""), figure.get_meta("visual_source", ""), figure.get_meta("visual_asset_review_only", false)])
			return
	var sightings := {"desk": 0}
	for node_variant in scene.find_children("*", "Node3D", true, false):
		var node := node_variant as Node3D
		var asset_id := String(node.get_meta("visual_asset_id", ""))
		if EXPECTED.has(asset_id):
			var expected: Dictionary = EXPECTED[asset_id]
			if String(node.get_meta("visual_source", "")) == "required_asset_failure" or String(node.get_meta("visual_source", "")) == "procedural_fallback":
				_fail("registered asset silently fell back: %s" % asset_id)
				return
			if String(node.get_meta("visual_asset_candidate_id", "")) != String(expected.candidate_id) or not bool(node.get_meta("visual_asset_review_only", false)):
				_fail("instantiated best-current asset lost its candidate or review marker: %s" % asset_id)
				return
			if asset_id == "desk":
				sightings.desk += 1
	if int(sightings.desk) < 1:
		_fail("room_photo_luna did not instantiate registered desk-v007")
		return
	var diagnostics: Array = resolver.get("diagnostics")
	if not diagnostics.is_empty():
		_fail("visual resolver reported missing assets or catalog diagnostics: %s" % diagnostics)
		return
	print("ROOMSCALE_V089_REVIEW_REGISTRY_PASS registry=review_showcase citizen=citizen-v089 count=50 desk=desk-v007 grapple=grapple-v006 review_only=true resolver_diagnostics=0")
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_V089_REVIEW_REGISTRY_FAIL: " + message)
	quit(1)
