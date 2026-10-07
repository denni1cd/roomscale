extends SceneTree
## Main-scene contract check for civilization presentation.
## Gameplay smoke proves the shared simulation; this verifies the selected
## civilization actually changes the production scene the player sees while
## preserving production-owned Clockwork nodes that the scene still references.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	_check(error == OK, "production main scene must load")
	if error != OK:
		_finish()
		return
	# Allow the production scene to complete _ready and the presentation autoload
	# to observe it on a process tick. This does not advance or fake gameplay.
	await create_timer(0.75).timeout
	var scene := current_scene as Node3D
	_check(scene != null, "production scene must become current_scene")
	if scene == null:
		_finish()
		return
	var definition: Variant = scene.get_meta("civilization_definition", {})
	_check(definition is Dictionary and String(definition.get("id", "")) == "verdant", "active production scene must carry Verdant definition")
	var settlement := scene.get_node_or_null("Settlement") as Node3D
	_check(settlement != null, "settlement must exist")
	if settlement != null:
		var workshop := settlement.get_node_or_null("Workshop") as Node3D
		var depot := settlement.get_node_or_null("Depot") as Node3D
		var housing := settlement.get_node_or_null("Housing") as Node3D
		var work_area := settlement.get_node_or_null("WorkArea") as Node3D
		_check(workshop != null and workshop.has_node("VerdantOverlay/RootPlatform"), "Workshop must render a Growth Nursery overlay")
		_check(depot != null and depot.has_node("VerdantOverlay/WovenFloor"), "Depot must render a Seed Cache overlay")
		_check(housing != null and housing.has_node("VerdantOverlay/HomePod0"), "Housing must render Pod Homes")
		_check(work_area != null and work_area.has_node("VerdantOverlay/CultivationMat"), "Work area must render a Cultivation Circle")
		var clockwork_details := workshop.get_node_or_null("ClockworkDetails") as Node3D if workshop != null else null
		_check(clockwork_details != null and not clockwork_details.visible, "Clockwork presentation nodes must be preserved but hidden")
	var citizens: Variant = scene.get("_citizens")
	_check(citizens is Array and not citizens.is_empty(), "production population must exist")
	if citizens is Array and not citizens.is_empty():
		var citizen := citizens[0] as Node3D
		var figure := citizen.get_node_or_null("Figure") as Node3D
		_check(figure != null and figure.has_node("AcornCap"), "Verdant citizen must receive acorn/woodland headgear")
		var clockwork_cap := figure.get_node_or_null("ClockworkCap") if figure != null else null
		_check(clockwork_cap != null and not clockwork_cap.visible, "Clockwork cap must be hidden for Verdant citizen")
	_check(scene.has_node("VerdantInfluence"), "Verdant initial reclamation layer must exist")
	var overlay := scene.get_node_or_null("Overlay") as Control
	var banner := overlay.get_node_or_null("CivilizationBanner") as Label if overlay != null else null
	_check(banner != null and banner.text.contains("Verdant"), "player UI must identify Verdant")
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("ROOMSCALE_CIVILIZATION_VISUAL_PASS civilization=verdant settlement=true citizen=true influence=true ui=true ownership_preserved=true")
		quit(0)
	else:
		push_error("ROOMSCALE_CIVILIZATION_VISUAL_FAIL %s" % JSON.stringify(failures))
		quit(1)
