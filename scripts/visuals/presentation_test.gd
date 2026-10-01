extends SceneTree
const Grapple := preload("res://scripts/visuals/grapple_details.gd")
const Resolver := preload("res://scripts/visuals/visual_resolver.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var population: Array = scene.get("_citizens")
	if population.size() != 50:
		_fail("expected 50 production citizens")
		return
	for citizen in population:
		var figure := citizen.get_node("Figure") as Node3D
		if figure.find_children("Goggle*", "MeshInstance3D", false, false).size() != 2 or figure.get_node_or_null("BuilderHammer") == null or figure.get_node_or_null("ExplorerPack") == null:
			_fail("modular role/face components missing for %s" % citizen.name)
			return
		var bounds := Resolver.mesh_bounds(figure)
		if bounds.end.y > 0.51 or bounds.position.y < -0.01:
			_fail("citizen exceeds half-inch envelope: %s" % bounds)
			return
		var body := figure.get_node("Body") as MeshInstance3D
		if (body.material_override as StandardMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			_fail("citizen material must respond to scene lighting")
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
	print("ROOMSCALE_PRESENTATION_PASS real_population=50 lit_half_inch_citizens=true role_components=true construction_stages=true")
	quit()

func _fail(message: String) -> void:
	push_error("ROOMSCALE_PRESENTATION_FAIL: " + message)
	quit(1)
