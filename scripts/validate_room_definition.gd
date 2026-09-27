extends SceneTree
## Standalone structural and runtime-navigation validation for RoomDefinition files.

const RoomDefinitionLoader := preload("res://scripts/room_definition.gd")
const FloorNavigationController := preload("res://scripts/floor_navigation.gd")
const SurfaceNavigationController := preload("res://scripts/surface_navigation.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var loaded: Dictionary = RoomDefinitionLoader.load_requested()
	var definition_value: Variant = loaded.get("definition", {})
	var definition: Dictionary = definition_value if definition_value is Dictionary else {}
	var errors: Array = loaded.get("errors", [])
	if not bool(loaded.get("ok", false)):
		_emit_result(false, definition, errors, [], {}, {})
		quit(1)
		return
	var floor_navigation := FloorNavigationController.new()
	floor_navigation.configure(definition)
	root.add_child(floor_navigation)
	await process_frame
	var surface_navigation := SurfaceNavigationController.new()
	surface_navigation.configure(definition, floor_navigation)
	root.add_child(surface_navigation)
	await process_frame
	var navigation_errors: Array[String] = RoomDefinitionLoader.validate_navigation(definition, floor_navigation, surface_navigation)
	var goal: Dictionary = surface_navigation.goal_surface()
	var approaches: Array[Vector3] = surface_navigation.investigation_candidates()
	var construction_site: Dictionary = surface_navigation.derive_construction_site(floor_navigation)
	var overall_errors: Array = errors.duplicate()
	overall_errors.append_array(navigation_errors)
	var derived: Dictionary = {
		"blocking_obstacles": floor_navigation.obstacle_rects.size(),
		"target_surface_id": String(goal.get("region_id", "")),
		"target_object_id": String(goal.get("object_id", "")),
		"target_object_name": String(goal.get("object_name", "")),
		"reachable_approach_count": approaches.size(),
		"construction_site_valid": bool(construction_site.get("valid", false)),
		"construction_site_position": _vector3_array(construction_site.get("position", Vector3.ZERO))
	}
	var passed := navigation_errors.is_empty()
	_emit_result(passed, definition, overall_errors, navigation_errors, derived, loaded)
	quit(0 if passed else 1)


func _emit_result(passed: bool, definition: Dictionary, errors: Array, navigation_errors: Array, derived: Dictionary, loaded: Dictionary) -> void:
	var result := {
		"ok": passed,
		"room_id": String(definition.get("id", "")),
		"schema_version": definition.get("schema_version", null),
		"candidate_path": OS.get_environment("ROOMSCALE_ROOM_FILE"),
		"structural_validation": "pass" if bool(loaded.get("ok", false)) else "fail",
		"runtime_navigation_validation": "pass" if navigation_errors.is_empty() and bool(loaded.get("ok", false)) else "fail",
		"derived": derived,
		"navigation_errors": navigation_errors,
		"errors": errors
	}
	var marker := "ROOMSCALE_VALIDATION_PASS" if passed else "ROOMSCALE_VALIDATION_FAIL"
	print("%s %s" % [marker, JSON.stringify(result)])


func _vector3_array(value: Variant) -> Array:
	if value is Vector3:
		var point: Vector3 = value
		return [point.x, point.y, point.z]
	return []
