extends RefCounted
const Catalog := preload("res://scripts/military_catalog.gd")

static func update(citizen: Node3D, seconds: float, definition: Dictionary = Catalog.CAPABILITIES.PREPARED_FIRE) -> void:
	var sim: Node = citizen.coordinator.civilization
	var eligible: bool = citizen.life_state == "ALIVE" and not citizen.combat_kit.is_empty() and citizen.combat_role in definition.roles and Catalog.has(sim,"PREPARED_FIRE")
	var previous: bool = citizen.prepared
	if not eligible:
		citizen.prepared = false; citizen.preparation_started = seconds; citizen.preparation_anchor = citizen.global_position
	elif not citizen.preparation_initialized or citizen.global_position.distance_to(citizen.preparation_anchor) > float(definition.tolerance):
		citizen.preparation_initialized = true
		citizen.prepared = false
		citizen.preparation_anchor = citizen.global_position
		citizen.preparation_started = seconds
	else: citizen.prepared = seconds-citizen.preparation_started+0.000001 >= float(definition.seconds)
	if previous != citizen.prepared: sim.armory.record("ABILITY_STATE",{"id":citizen.citizen_id,"capability":"PREPARED_FIRE","prepared":citizen.prepared})

static func interval(citizen: Node3D, definition: Dictionary = Catalog.CAPABILITIES.PREPARED_FIRE) -> float:
	return float(citizen.combat_stats.interval) * (float(definition.interval) if citizen.prepared else 1.0)

static func endpoint(citizen: Node3D, desired: Vector3) -> Dictionary:
	var at: Vector3 = citizen.global_position
	var pathfinder := Catalog.has(citizen.coordinator.civilization,"PATHFINDER_MANEUVERS")
	var angles: Array = Catalog.CAPABILITIES.PATHFINDER_MANEUVERS.angles if pathfinder else [0,45,-45]
	var selected := {}
	var shortest := INF
	for angle in angles:
		var candidate: Vector3 = at+(desired-at).rotated(Vector3.UP,deg_to_rad(float(angle)))
		var route: Array[Vector3] = citizen.navigation.combat_path_between(at,candidate)
		if route.is_empty(): continue
		var length := 0.0
		var previous := at
		for point in route: length += previous.distance_to(point); previous = point
		if length < shortest:
			shortest = length
			selected = {"target":candidate,"length":length,"angle":angle,"pathfinder":pathfinder}
		if not pathfinder: break
	return selected
