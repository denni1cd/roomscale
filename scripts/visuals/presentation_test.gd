extends SceneTree
const Grapple := preload("res://scripts/visuals/grapple_details.gd")
const Resolver := preload("res://scripts/visuals/visual_resolver.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("ROOMSCALE_NO_MENU", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_ROOM", "room_photo_luna")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "verification/poc2/candidates/primary/attempt-7/room_photo_luna.json")
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var population: Array = scene.get("_citizens")
	if population.size() != 50:
		_fail("expected 50 production citizens")
		return
	for pair in [["Workshop", "settlement_workshop"], ["Depot", "settlement_depot"], ["Housing", "settlement_housing"], ["WorkArea", "settlement_workarea"]]:
		var building := scene.get_node_or_null("Settlement/%s" % pair[0]) as Node3D
		var art_root := building.get_node_or_null("ArtPresentation") as Node3D if building != null else null
		if building == null or art_root == null or not bool(building.get_meta("accepted_art_visible", false)):
			_fail("accepted settlement presentation is missing for %s" % pair[0])
			return
		var source := String(art_root.get_meta("visual_source", ""))
		var candidate := String(art_root.get_meta("visual_asset_candidate_id", ""))
		if String(art_root.get_meta("visual_asset_id", "")) != pair[1] or source.is_empty() or not source.begins_with("res://art/") or candidate.is_empty() or source == "required_asset_failure" or source == "procedural_fallback":
			_fail("accepted settlement art did not resolve without fallback for %s: source=%s candidate=%s" % [pair[1], source, candidate])
			return
		if art_root.find_child("ResolvedAsset", false, false) == null:
			_fail("accepted settlement art scene was not instantiated for %s" % pair[1])
			return
	var required_furniture := {
		"office_chair": "office_chair-v003",
		"rocking_chair": "rocking_chair-v003",
		"hammock_with_stand": "hammock_with_stand-v005",
		"display_cabinet": "display_cabinet-v002",
	}
	var resolved_furniture: Dictionary = {}
	for item in scene.find_children("*", "Node3D", true, false):
		var asset_id := String(item.get_meta("visual_asset_id", ""))
		if not required_furniture.has(asset_id):
			continue
		var source := String(item.get_meta("visual_source", ""))
		var candidate := String(item.get_meta("visual_asset_candidate_id", ""))
		if not source.begins_with("res://art/") or candidate != String(required_furniture[asset_id]):
			_fail("promoted furniture did not resolve from its accepted Art Factory scene: id=%s source=%s candidate=%s" % [asset_id, source, candidate])
			return
		if item.find_child("ResolvedAsset", false, false) == null:
			_fail("promoted furniture scene was not instantiated for %s" % asset_id)
			return
		resolved_furniture[asset_id] = candidate
	for asset_id in required_furniture:
		if not resolved_furniture.has(asset_id):
			_fail("canonical room did not instantiate promoted furniture stable ID %s" % asset_id)
			return
	var streets := scene.get_node("Settlement/SettlementStreets")
	if not streets.find_children("*", "CollisionObject3D", true, false).is_empty():
		_fail("decorative streets must not introduce gameplay collision")
		return
	if not bool(scene.get("_presentation_mode")) or scene.get_node("Overlay/HudPanel").visible:
		_fail("normal presentation must keep the diagnostic panel compact")
		return
	scene.set("_presentation_mode", false)
	scene.call("_apply_presentation_mode")
	if not scene.get_node("Overlay/HudPanel").visible or scene.get_node("Overlay/PresentationPanel").visible:
		_fail("diagnostics must remain available through the presentation toggle")
		return
	scene.set("_presentation_mode", true)
	scene.call("_apply_presentation_mode")
	var registered_citizens := 0
	for citizen in population:
		var figure := citizen.get_node("Figure") as Node3D
		var accepted_citizen := String(figure.get_meta("visual_asset_id", "")) == "citizen"
		var body: MeshInstance3D
		if accepted_citizen:
			registered_citizens += 1
			var asset_root := figure.get_node_or_null("CitizenArtAsset") as Node3D
			if asset_root == null or String(figure.get_meta("visual_source", "")).is_empty() or String(figure.get_meta("visual_asset_candidate_id", "")).is_empty():
				_fail("accepted citizen has no resolved Art Factory source: %s" % citizen.name)
				return
			if asset_root.get_node_or_null("Body") == null or asset_root.get_node_or_null("LeftArm") == null or asset_root.get_node_or_null("RightArm") == null or asset_root.get_node_or_null("LeftLeg") == null or asset_root.get_node_or_null("RightLeg") == null:
				_fail("accepted citizen is missing a live animation pivot: %s" % citizen.name)
				return
			if asset_root.find_children("GoggleFrame*", "MeshInstance3D", true, false).size() != 2 or asset_root.find_children("GoggleLens*", "MeshInstance3D", true, false).size() != 2:
				_fail("accepted citizen is missing its paired face lenses: %s" % citizen.name)
				return
			body = asset_root.get_node("Body") as MeshInstance3D
			for role_node in ["BuilderHammer", "ExplorerPack", "RoleChest", "Parcel", "CableSafetyClip"]:
				if figure.get_node_or_null(role_node) == null:
					_fail("independently controlled role component %s missing for %s" % [role_node, citizen.name])
					return
		else:
			if figure.find_children("Goggle*", "MeshInstance3D", false, false).size() != 2:
				_fail("legacy figure face components missing for %s" % citizen.name)
				return
			body = figure.get_node("Body") as MeshInstance3D
		if figure.get_node_or_null("BuilderHammer") == null or figure.get_node_or_null("ExplorerPack") == null:
			_fail("modular role components missing for %s" % citizen.name)
			return
		var bounds := Resolver.mesh_bounds(figure)
		if bounds.end.y > 0.51 or bounds.position.y < -0.01:
			_fail("citizen exceeds half-inch envelope: %s" % bounds)
			return
		var body_material := body.material_override as StandardMaterial3D
		if body_material == null or body_material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			_fail("citizen material must respond to scene lighting")
			return
	if registered_citizens not in [0, 50]:
		_fail("citizen art override must cover the entire production population; accepted=%d" % registered_citizens)
		return
	if registered_citizens == 50:
		var animated_figure := population[0].get_node("Figure/CitizenArtAsset") as Node3D
		var body_pivot := animated_figure.get_node("Body") as MeshInstance3D
		var gait_leg := animated_figure.get_node("LeftLeg") as MeshInstance3D
		population[0].set("state", "TRAVEL")
		population[0].set("task_type", "IDLE")
		population[0].set("_animation_time", 0.1)
		population[0].call("_update_animation")
		if body_pivot.position.y < 0.23 or absf(gait_leg.rotation.x) < 0.1:
			_fail("accepted art pivots did not respond to the production gait animator")
			return
	var site := Node3D.new()
	var groups := Grapple.build(site)
	Grapple.animate(groups, 0, 0, 0.1, false, 0.0)
	if groups[0].visible or groups[1].visible or groups[2].visible:
		_fail("unbuilt details visible before real work")
		return
	Grapple.animate(groups, 0, 0, 0.5, false, 0.0)
	if not groups[0].visible or groups[1].visible or groups[2].visible:
		_fail("foundation work revealed later machinery")
		return
	Grapple.animate(groups, 1, 1, 0.5, false, 0.0)
	if not groups[0].visible or not groups[1].visible or groups[2].visible:
		_fail("winch work did not preserve staged construction")
		return
	Grapple.animate(groups, 3, -1, 0, false, 0)
	if not groups[0].visible or not groups[1].visible or not groups[2].visible:
		_fail("completed structure omitted details")
		return
	site.free()
	scene.queue_free()
	await process_frame
	print("ROOMSCALE_PRESENTATION_PASS real_population=50 lit_half_inch_citizens=true registered_art=%d accepted_settlement_assets=4 accepted_room_furniture_assets=%d no_silent_fallback=true animated_pivots=true role_components=true construction_stages=true" % [registered_citizens, resolved_furniture.size()])
	quit()

func _fail(message: String) -> void:
	push_error("ROOMSCALE_PRESENTATION_FAIL: " + message)
	quit(1)
