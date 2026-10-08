extends RefCounted
## Bounded, deterministic spatial planning. Trials own cloned navigation only.
const Floor := preload("res://scripts/floor_navigation.gd")
const SIZE := Vector3(12, 7, 10)
const MAX_TRIALS := 2048
const MAX_BRANCH := 96
var sim: Node
var reservations: Array[Dictionary] = []
var rest_targets: Array[Vector3] = []
var decisions: Array[Dictionary] = []
var _positions: Array[Vector3] = []
var _anchors: Array[Vector3] = []
var _trials := 0
var _rejections: Dictionary = {}
var _alternatives: Array[Dictionary] = []
var _solution_rest: Array[Vector3] = []
var _plan_evidence: Dictionary = {}
var _considered := 0
var _failed_state := ""

func configure(controller: Node) -> void:
	sim = controller

func apron(site: Vector3) -> Rect2:
	return Rect2(Vector2(site.x - 10, site.z - 9), Vector2(20, 18))

func _occupied(object: Dictionary) -> Rect2:
	var angle := deg_to_rad(float(object.get("rotation_degrees", 0)))
	var half := Vector2(float(object.dimensions[0]), float(object.dimensions[2])) / 2
	var padding: Array = object.get("navigation_padding", [0, 0, 0])
	half += Vector2(float(padding[0]), float(padding[2]))
	half = Vector2(absf(cos(angle)) * half.x + absf(sin(angle)) * half.y, absf(sin(angle)) * half.x + absf(cos(angle)) * half.y)
	return Rect2(Vector2(float(object.position[0]), float(object.position[2])) - half, half * 2)

func _reject(reason: String, site: Vector3) -> void:
	_rejections[reason] = int(_rejections.get(reason, 0)) + 1
	var alternative := {"position": site, "reason": reason}
	if _alternatives.has(alternative): return
	var major := reason in ["downstream founding arrangement", "insufficient downstream apron coverage", "mandatory connectivity/work access"]
	if _alternatives.size() < (16 if major else 8): _alternatives.append(alternative)

func _prepare(rebuild_positions: bool = true) -> void:
	_trials = 0
	_considered = 0
	_rejections = {}
	_alternatives = []
	var nav: Node = sim.coordinator.navigation
	_anchors.assign([sim.coordinator.depot_station, sim.coordinator.housing_station, sim.coordinator.work_area_station])
	_anchors.append_array(sim.coordinator.workshop_stations)
	_anchors.append_array(sim.coordinator.patrol_stations)
	_anchors.append_array(rest_targets)
	for source in sim.resources.sources.values():
		if source.region == "FLOOR": _anchors.append(source.position)
	for id in sim.salvage_targets:
		# Protected furniture is geometry, not a required salvage activity. Its
		# unused derived target must not consume otherwise legal building space.
		var entry: Dictionary = sim.resources.objects[id]
		var object: Dictionary = entry.data
		if sim.salvage.depleted(id) or bool(object.get("resource_profile", {}).get("protected", false)) or not entry.profile.contents.is_empty(): continue
		if object.has("surface"):
			var region := String(object.surface.region_id)
			if sim.coordinator.surface_navigation.has_connection("FLOOR", region): continue
			var support := false
			for source in sim.resources.sources.values():
				if source.region == region: support = true
			if support: continue
		var at: Vector3 = sim.salvage_targets[id]
		if at.is_finite() and not nav.is_obstacle_position(at) and not nav.path_between(sim.coordinator.depot_station, at).is_empty(): _anchors.append(at)
	if sim.world_simulation != null and sim.world_simulation.runtimes.size() > 1:
		for runtime in sim.world_simulation.runtimes:
			if runtime == sim: continue
			_anchors.append(runtime.coordinator.depot_station)
			_anchors.append(runtime.coordinator.housing_station)
			_anchors.append(runtime.coordinator.work_area_station)
			_anchors.append_array(runtime.development.site_planner.rest_targets)
			for project in runtime.development.projects: _anchors.append(project.target)
		for site in sim.world_simulation.territory.sites.values(): _anchors.append(site.position)
	var traversal: Vector3 = sim.coordinator.get_construction_site()
	if traversal.is_finite() and not nav.is_obstacle_position(traversal): _anchors.append(traversal)
	for approach in sim.coordinator.surface_navigation.investigation_candidates():
		if not nav.is_obstacle_position(approach): _anchors.append(approach)
	for project in sim.development.projects: _anchors.append(project.target)
	for bundle in sim.resources.bundles.values():
		if bundle.state == "available": _anchors.append(bundle.position)
	if not rebuild_positions: return
	# Sample the actual floor grid, supplemented by obstacle and boundary edges.
	# These coordinates follow world geometry, never a founder-relative lattice.
	var xs: Array[float] = []
	var zs: Array[float] = []
	for x in range(nav.grid.region.size.x): xs.append(nav._cell_to_world(Vector2i(x, 0)).x)
	for z in range(nav.grid.region.size.y): zs.append(nav._cell_to_world(Vector2i(0, z)).y)
	var bounds: Rect2 = nav.room_bounds()
	xs.append_array([bounds.position.x + 10.01, bounds.end.x - 10.01])
	zs.append_array([bounds.position.y + 9.01, bounds.end.y - 9.01])
	for object in nav.room_definition.objects:
		if object.kind == "rug" or float(object.position[1]) > nav._floor_height + 2: continue
		var rect := _occupied(object)
		xs.append_array([rect.position.x - 10.01, rect.end.x + 10.01])
		zs.append_array([rect.position.y - 9.01, rect.end.y + 9.01])
	_positions.clear()
	var seen := {}
	for x in xs:
		for z in zs:
			var site := Vector3(x, nav._floor_height, z)
			if seen.has(site): continue
			seen[site] = true
			_positions.append(site)
	_positions.sort_custom(_rank_before)
	var legal: Array[Vector3] = []
	for site in _positions:
		_considered += 1
		var reason := _cheap_reason(site, [])
		if reason.is_empty(): legal.append(site)
		else: _reject(reason, site)
	_positions = legal

func _rank_before(a: Vector3, b: Vector3) -> bool:
	var da := a.distance_squared_to(sim.development.center())
	var db := b.distance_squared_to(sim.development.center())
	return da < db if da != db else (a.z < b.z if a.z != b.z else a.x < b.x)

func _cheap_reason(site: Vector3, chosen: Array[Dictionary]) -> String:
	var nav: Node = sim.coordinator.navigation
	var rect := apron(site)
	if not nav.room_bounds().encloses(rect): return "room boundary"
	for object in nav.room_definition.objects:
		if object.kind == "rug" or float(object.position[1]) > site.y + 2: continue
		if rect.intersects(_occupied(object)): return "room/completed geometry"
	if sim.world_simulation != null:
		for runtime in sim.world_simulation.runtimes:
			if runtime == sim: continue
			for project in runtime.development.projects:
				if rect.intersects(apron(project.site)): return "other society project apron"
			for item in runtime.development.site_planner.reservations:
				if rect.intersects(apron(item.position)): return "other society future reservation"
	for project in sim.development.projects:
		if rect.intersects(apron(project.site)): return "existing project apron"
	for item in chosen:
		if rect.intersects(apron(item.position)): return "future reservation overlap"
		if rect.has_point(Vector2(item.target.x, item.target.z)): return "reserved work access"
	for at in _anchors:
		if rect.has_point(Vector2(at.x, at.z)): return "required activity/resource/traversal access"
	if sim.construction.project_created and rect.grow(4).has_point(Vector2(sim.construction.site_position.x, sim.construction.site_position.z)): return "active traversal site"
	return ""

func _trial(chosen: Array[Dictionary], rest_count: int) -> Dictionary:
	# Count every cloned-navigation proof, including terminal rest validation.
	if _trials >= MAX_TRIALS: return {"valid": false, "reason": "navigation trial budget exhausted", "rests": []}
	_trials += 1
	var definition: Dictionary = sim.coordinator.navigation.room_definition.duplicate(true)
	for index in range(chosen.size()): definition.objects.append(sim.development.obstacle(chosen[index].position, "trial_%d" % index))
	var nav := Floor.new()
	nav.report_ready = false
	nav.configure(definition)
	nav.refresh_navigation()
	var anchors: Array[Vector3] = _anchors.duplicate()
	for item in chosen: anchors.append(item.target)
	var reason := ""
	for at in anchors:
		if nav.is_obstacle_position(at) or not nav.room_bounds().has_point(Vector2(at.x, at.z)) or nav.path_between(sim.coordinator.depot_station, at).is_empty():
			reason = "mandatory connectivity/work access"
			break
	if reason.is_empty():
		for citizen in sim.world_citizens():
			var at: Vector3 = citizen.global_position
			if at.y > nav._floor_height + 0.1: continue
			# Occupancy is checked for the immediate build at acceptance; future
			# reservations may currently have a passing citizen, who is never moved.
			if nav.is_obstacle_position(at): continue
			if nav.path_between(sim.coordinator.depot_station, at).is_empty():
				reason = "citizen disconnected by completed arrangement"
				break
	var rests: Array[Vector3] = rest_targets.duplicate()
	if reason.is_empty() and rests.size() < rest_count:
		var housing: Vector3 = sim.coordinator.housing_station
		for item in chosen:
			if item.kind == "shelter": housing = item.target
		var cells: Array[Vector3] = []
		for x in range(nav.grid.region.size.x):
			for z in range(nav.grid.region.size.y):
				var cell := Vector2i(x, z)
				if nav.grid.is_point_solid(cell): continue
				var point: Vector2 = nav._cell_to_world(cell)
				var at := Vector3(point.x, nav._floor_height, point.y)
				if rests.has(at): continue
				var reserved := false
				for item in chosen:
					if apron(item.position).has_point(point): reserved = true
				if not reserved: cells.append(at)
		cells.sort_custom(func(a: Vector3, b: Vector3) -> bool:
			var da := a.distance_squared_to(housing)
			var db := b.distance_squared_to(housing)
			return da < db if da != db else (a.z < b.z if a.z != b.z else a.x < b.x))
		for at in cells:
			if not nav.is_obstacle_position(at) and not nav.path_between(sim.coordinator.depot_station, at).is_empty(): rests.append(at)
			if rests.size() >= rest_count: break
		if rests.size() < rest_count: reason = "insufficient reachable rest access"
	nav.free()
	return {"valid": reason.is_empty(), "reason": reason, "rests": rests}

func _search(kinds: Array, chosen: Array[Dictionary], rest_count: int) -> Array[Dictionary]:
	if kinds.is_empty():
		var proof := _trial(chosen, rest_count)
		if proof.valid:
			_solution_rest.assign(proof.rests)
			return chosen
		return []
	# A small constrained domain can be pruned by a necessary area bound. The
	# union of all legal remaining aprons must cover at least N disjoint aprons.
	# This rejects central placements that waste scarce packing space before
	# spending navigation trials on equivalent doomed downstream combinations.
	if not chosen.is_empty() and not _enough_remaining_area(chosen, kinds.size()):
		_reject("insufficient downstream apron coverage", chosen[-1].position)
		return []
	var branches := 0
	for rank in range(_positions.size()):
		var site := _positions[rank]
		_considered += 1
		var reason := _cheap_reason(site, chosen)
		if not reason.is_empty():
			_reject(reason, site)
			continue
		branches += 1
		if branches > MAX_BRANCH or _trials >= MAX_TRIALS: break
		# Test all four sides; equal distances break ties by z then x.
		var targets: Array[Vector3] = [site + Vector3(10, 0, 0), site - Vector3(10, 0, 0), site + Vector3(0, 0, 9), site - Vector3(0, 0, 9)]
		targets.sort_custom(_rank_before)
		for target in targets:
			if _trials >= MAX_TRIALS: break
			_considered += 1
			var next: Array[Dictionary] = chosen.duplicate()
			next.append({"kind": kinds[0], "valid": true, "position": site, "target": target, "score": site.distance_squared_to(sim.development.center()), "rank": rank})
			var proof := _trial(next, 0)
			if not proof.valid:
				_reject(proof.reason, site)
				continue
			var result := _search(kinds.slice(1), next, rest_count)
			if not result.is_empty(): return result
			_reject("downstream founding arrangement", site)
	return []

func _enough_remaining_area(chosen: Array[Dictionary], required: int) -> bool:
	var rects: Array[Rect2] = []
	for site in _positions:
		if _cheap_reason(site, chosen).is_empty(): rects.append(apron(site))
		# Large domains use the normal bounded search; this optimization is
		# deliberately limited to compact, difficult packing arrangements.
		if rects.size() > 128: return true
	if rects.is_empty(): return false
	var xs: Array[float] = []
	for rect in rects:
		if not xs.has(rect.position.x): xs.append(rect.position.x)
		if not xs.has(rect.end.x): xs.append(rect.end.x)
	xs.sort()
	var area := 0.0
	for i in range(1, xs.size()):
		var intervals: Array[Vector2] = []
		var middle := (xs[i - 1] + xs[i]) / 2
		for rect in rects:
			if middle > rect.position.x and middle < rect.end.x: intervals.append(Vector2(rect.position.y, rect.end.y))
		intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x if a.x != b.x else a.y < b.y)
		var low := INF
		var high := -INF
		var length := 0.0
		for interval in intervals:
			if interval.x > high:
				if is_finite(low): length += high - low
				low = interval.x
				high = interval.y
			else: high = maxf(high, interval.y)
		if is_finite(low): length += high - low
		area += (xs[i] - xs[i - 1]) * length
	return area + .00001 >= required * 360.0

func preview(kind: String) -> Dictionary:
	## A certificate query cannot alter the cached plan or the live simulation.
	_prepare()
	var kinds: Array = ["shelter", "depot", "workshop", "housing"] if sim.development.projects.is_empty() else [kind]
	var layout := _search(kinds, [], 7 if kinds.size() == 4 else sim.needs.rest_capacity + (2 if kind == "housing" else 0))
	for item in layout:
		if item.kind == kind: return item
	return {"valid": false, "reason": "bounded search found no connected founding arrangement", "navigation_trials": _trials, "candidate_count": _positions.size(), "rejection_reasons": _rejections.duplicate(), "search_exhausted": _trials >= MAX_TRIALS}

func select(kind: String) -> Dictionary:
	## Retain future footprints. Moving workers can delay acceptance, never move.
	var reused := not reservations.is_empty()
	if reservations.is_empty():
		_prepare(false)
		# Search also depends on transient access anchors and citizen connectivity.
		# A collected bundle or changed rest requirement must permit a fresh retry.
		var citizens: Array[Vector3] = []
		for citizen in sim.world_citizens(): citizens.append(citizen.global_position)
		var planning_state := JSON.stringify([sim.coordinator.navigation.room_definition, kind, sim.needs.rest_capacity, _anchors, sim.development.projects, sim.construction.project_created, sim.construction.site_position, citizens]).sha256_text()
		if planning_state == _failed_state: return {"valid": false}
		_prepare()
		var kinds: Array = ["shelter", "depot", "workshop", "housing"] if sim.development.projects.is_empty() else [kind]
		reservations = _search(kinds, [], 7 if kinds.size() == 4 else sim.needs.rest_capacity + (2 if kind == "housing" else 0))
		if reservations.is_empty():
			_failed_state = planning_state
			return {"valid": false}
		_failed_state = ""
		_plan_evidence = {"considered": _considered, "navigation_trials": _trials, "rejected": _rejections.values().reduce(func(a, b): return a + b, 0), "rejection_reasons": _rejections.duplicate(), "alternatives": _alternatives.duplicate(true)}
		# Future rest locations are usable only as earned rest capacity grows.
		rest_targets.assign(_solution_rest)
	var selected: Dictionary = {}
	for item in reservations:
		if item.kind == kind:
			selected = item
			break
	if selected.is_empty(): return {"valid": false}
	var rect := apron(selected.position)
	for citizen in sim.world_citizens():
		if citizen.global_position.y < selected.position.y + 2 and rect.has_point(Vector2(citizen.global_position.x, citizen.global_position.z)): return {"valid": false}
	for citizen in sim.world_citizens():
		if citizen.state in ["TRAVEL", "CARRY", "WORK"] and citizen._destination.y < selected.position.y + 2 and rect.has_point(Vector2(citizen._destination.x, citizen._destination.z)): return {"valid": false}
	# A cached reservation is checked against the current world and active endpoints.
	_prepare(false)
	var reason := _cheap_reason(selected.position, [])
	var proof := _trial(reservations, sim.needs.rest_capacity)
	if not reason.is_empty() or not proof.valid: return {"valid": false}
	var decision := {"kind": kind, "considered": _plan_evidence.considered, "navigation_trials": _plan_evidence.navigation_trials, "validation_navigation_trials": _trials, "rejected": _plan_evidence.rejected, "rejection_reasons": _plan_evidence.rejection_reasons, "alternatives": _plan_evidence.alternatives, "selected": selected.duplicate(true), "future_reservations": reservations.duplicate(true), "connectivity": true, "downstream_feasible": true, "reused": reused, "tie_break": "squared origin distance, z, x; work side uses same order"}
	decisions.append(decision)
	reservations.erase(selected)
	return selected

func rest_target(slot: int) -> Vector3:
	## Founder rest slots are permanent clear points chosen with future footprints.
	if sim.founder_mode and slot >= 0 and slot < rest_targets.size(): return rest_targets[slot]
	return sim.coordinator.navigation.nearest_walkable_position(sim.coordinator.housing_station + Vector3(-16 + (slot % 6) * 4, 0, 16 + (slot / 6) * 4))

func can_complete(project: Dictionary) -> bool:
	## Occupants and active targets may change between acceptance and completion.
	_prepare(false)
	var rect := apron(project.site)
	for citizen in sim.world_citizens():
		if citizen.state in ["TRAVEL", "CARRY", "WORK"] and citizen._destination.y < project.site.y + 2 and rect.has_point(Vector2(citizen._destination.x, citizen._destination.z)):
			# The project's own exterior work target is legal within its apron.
			if not citizen._destination.is_equal_approx(project.target): return false
	var chosen: Array[Dictionary] = [{"kind": project.kind, "position": project.site, "target": project.target}]
	return _trial(chosen, sim.needs.rest_capacity).valid
