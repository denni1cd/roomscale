extends SceneTree
## Validate economy metadata and source placement without altering production fixtures.
const Definition := preload("res://scripts/room_definition.gd")
const FloorNavigation := preload("res://scripts/floor_navigation.gd")
const SurfaceNavigation := preload("res://scripts/surface_navigation.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var loaded := Definition.load_file("res://rooms/room_poc4.json")
	if not loaded.ok:
		push_error("POC4_CONTRACT_FAIL: valid canonical contract rejected")
		quit(1)
		return
	var definition: Dictionary = loaded.definition
	var malformed := definition.duplicate(true)
	malformed.civilization.economy_construction = "yes"
	if Definition.validate(malformed).is_empty(): failures.append("boolean construction flag")
	malformed = definition.duplicate(true)
	malformed.civilization.stock.water = -1
	if Definition.validate(malformed).is_empty(): failures.append("nonnegative stock")
	malformed = definition.duplicate(true)
	malformed.civilization.rest_capacity = 1.5
	if Definition.validate(malformed).is_empty(): failures.append("integer capacity")
	malformed = definition.duplicate(true)
	malformed.objects[-2].resource_profile.region_id = "MISSING"
	if Definition.validate(malformed).is_empty(): failures.append("known source region")
	var nav := FloorNavigation.new()
	nav.configure(definition)
	root.add_child(nav)
	var surfaces := SurfaceNavigation.new()
	surfaces.configure(definition, nav)
	root.add_child(surfaces)
	if not Definition.validate_navigation(definition, nav, surfaces).is_empty(): failures.append("valid source placement")
	malformed = definition.duplicate(true)
	malformed.objects[-2].position = [44, 30, 0]
	if Definition.validate_navigation(malformed, nav, surfaces).is_empty(): failures.append("source must lie inside declared elevated footprint")
	malformed = definition.duplicate(true)
	malformed.objects[-1].position = [-58, 0, -20]
	if Definition.validate_navigation(malformed, nav, surfaces).is_empty(): failures.append("floor source must avoid actual obstacle")
	nav.queue_free()
	surfaces.queue_free()
	await process_frame
	if not failures.is_empty():
		push_error("POC4_CONTRACT_FAIL: " + str(failures))
		quit(1)
		return
	print("POC4_CONTRACT_PASS malformed=6 valid_standard_room=true finite_stock=true source_geometry=validated")
	quit()
