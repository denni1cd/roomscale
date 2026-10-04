extends "res://scripts/poc471_observer.gd"
## The prior physical observer plus settlement reservations and route witnesses.
var _geometry_stamp := ""
var placement_checks := 0
var delivery_segments := 0

func check_invariants() -> void:
	# Inspect the actual next movement before the parent updates prior positions.
	var nav: Node = sim.coordinator.navigation
	for citizen in sim.citizens:
		if citizen.task_type != "CONSTRUCTION_DELIVERY" or not previous_positions.has(citizen.citizen_id): continue
		var before: Vector3 = previous_positions[citizen.citizen_id]
		var after: Vector3 = citizen.global_position
		if before.y < .1 and after.y < .1:
			delivery_segments += 1
			if not nav._segment_is_clear(Vector2(before.x, before.z), Vector2(after.x, after.z)): violate("Construction delivery crossed blocking geometry")
	super.check_invariants()
	var planner: RefCounted = sim.development.site_planner
	var stamp := "%s:%s:%s:%s" % [previous_navigation, sim.development.projects.size(), planner.reservations.size(), sim.needs.rest_capacity]
	if stamp == _geometry_stamp: return
	_geometry_stamp = stamp
	placement_checks += 1
	var all_sites: Array = []
	for project in sim.development.projects: all_sites.append({"position": project.site, "target": project.target, "id": project.id, "reserved": false})
	for reservation in planner.reservations: all_sites.append({"position": reservation.position, "target": reservation.target, "id": "future_" + reservation.kind, "reserved": true})
	for i in range(all_sites.size()):
		var item: Dictionary = all_sites[i]
		var apron: Rect2 = planner.apron(item.position)
		if not nav.room_bounds().encloses(apron): violate("Accepted/reserved apron outside room")
		for j in range(i):
			if apron.intersects(planner.apron(all_sites[j].position)): violate("Forbidden planned/completed/reserved apron overlap")
		for object in nav.room_definition.objects:
			if object.id == item.id or object.kind == "rug" or float(object.position[1]) > item.position.y + 2: continue
			if apron.intersects(planner._occupied(object)): violate("Accepted/reserved footprint conflicts with room geometry")
		if nav.is_obstacle_position(item.target) or nav.path_between(sim.coordinator.depot_station, item.target).is_empty(): violate("Accepted project has no real reachable work target")
		var path: Array[Vector3] = nav.path_between(sim.coordinator.depot_station, item.target)
		var before: Vector3 = sim.coordinator.depot_station
		for after in path:
			if not nav._segment_is_clear(Vector2(before.x, before.z), Vector2(after.x, after.z)): violate("Accepted construction route is not physically clear")
			before = after
	var anchors: Array[Vector3] = [sim.coordinator.depot_station, sim.coordinator.housing_station, sim.coordinator.work_area_station]
	anchors.append_array(sim.coordinator.workshop_stations)
	anchors.append_array(sim.coordinator.patrol_stations)
	for slot in range(sim.needs.rest_capacity): anchors.append(planner.rest_target(slot))
	for at in anchors:
		if nav.is_obstacle_position(at) or not nav.room_bounds().has_point(Vector2(at.x, at.z)) or nav.path_between(sim.coordinator.depot_station, at).is_empty(): violate("Required activity/rest target invalid after completion")
	for citizen in sim.citizens:
		if citizen.global_position.y < .1 and nav.path_between(sim.coordinator.depot_station, citizen.global_position).is_empty(): violate("Completed construction disconnected a citizen")
	# Validate all remaining reservations together on a separate grid, never live.
	var definition: Dictionary = nav.room_definition.duplicate(true)
	for item in all_sites:
		if not nav.room_definition.objects.any(func(o): return o.id == item.id): definition.objects.append(sim.development.obstacle(item.position, item.id))
	var future := Floor.new()
	future.report_ready = false
	future.configure(definition)
	future._rebuild_grid()
	for item in all_sites:
		if future.is_obstacle_position(item.target) or future.path_between(sim.coordinator.depot_station, item.target).is_empty(): violate("Reserved sequence lost future work connectivity")
	for at in anchors:
		if future.is_obstacle_position(at) or future.path_between(sim.coordinator.depot_station, at).is_empty(): violate("Reservations poison required activity access")
	for at in planner.rest_targets:
		if future.is_obstacle_position(at) or future.path_between(sim.coordinator.depot_station, at).is_empty(): violate("Planned rest slot invalid in future settlement")
	future.free()

func check_negative() -> void:
	if config.name == "No Valid Depot Site":
		# Original NEG-03 blocks one old apron, not all geometric arrangements.
		for key in ["shelter_complete", "depot_complete", "workshop_complete", "housing_complete", "sixth_citizen", "traversal_complete", "physical_climb", "elevated_territory"]:
			if not milestones.has(key): failure += " Former fixed-apron negative missing " + key
	elif config.name == "No Complete Founding Layout":
		if not sim.development.projects.is_empty() or sim.citizens.size() != 5 or sim.has_capability("storage") or sim.development.site_reason.is_empty(): failure = "Impossible sequence bypassed spatial blockage"
	else: super.check_negative()

func snapshot() -> Dictionary:
	var result := super.snapshot()
	result.settlement_plan = {"reservations": sim.development.site_planner.reservations, "rests": sim.development.site_planner.rest_targets, "decisions": sim.development.site_planner.decisions}.duplicate(true)
	result.placement_checks = placement_checks
	result.physical_delivery_segments = delivery_segments
	return result
