extends Node
## Generic citizen tasking, surface investigation, and traversal reuse.

const RoomDefinitionLoader := preload("res://scripts/room_definition.gd")

signal reach_goal_updated(status: Dictionary)
signal task_board_updated(status: Dictionary)

const MAX_HISTORY := 500
const FLOOR_REGION := "FLOOR"

var navigation: Node
var surface_navigation: Node
var construction_system: Node
var civilization: Node
var instance_id := "legacy"
var room_definition: Dictionary = {}
var tasks: Array[Dictionary] = []
var _next_task_id := 1
var _created_count := 0
var _completed_count := 0
var _failed_count := 0
var _cancelled_count := 0
var workshop_stations: Array[Vector3] = []
var depot_station := Vector3.ZERO
var housing_station := Vector3.ZERO
var work_area_station := Vector3.ZERO
var patrol_stations: Array[Vector3] = []
var _goal_region := ""
var _goal_label := "elevated surface"
var _goal_center := Vector3.ZERO
var _construction_site := Vector3.ZERO
var _reach_goal: Dictionary = {}
var _traversal_goal: Dictionary = {}
var _target_arrivals := 0
var _target_explorations_completed := 0
var _autonomous_reuse_count := 0
var _surface_exploration_tasks: Array[int] = []
var _traversal_task_ids: Array[int] = []
var _m6_completed_task_results: Dictionary = {}


func configure_room(definition: Dictionary) -> void:
	room_definition = definition.duplicate(true)
	var activities: Dictionary = room_definition.activity_stations
	workshop_stations = _vectors(activities.workshop)
	depot_station = RoomDefinitionLoader.vector3_from(room_definition.construction.depot_pickup)
	housing_station = RoomDefinitionLoader.vector3_from(activities.housing)
	work_area_station = RoomDefinitionLoader.vector3_from(activities.work_area)
	patrol_stations = _vectors(activities.patrol)
	if definition.has("start") and definition.start.infrastructure.is_empty():
		for index in range(patrol_stations.size()):
			var at: Vector3 = patrol_stations[index]
			if navigation.is_obstacle_position(at) or not navigation.room_bounds().has_point(Vector2(at.x, at.z)):
				patrol_stations[index] = navigation.nearest_walkable_position(at)
	if is_instance_valid(surface_navigation):
		_set_goal_from_surface()
	var derived: Dictionary = surface_navigation.derive_construction_site(navigation) if is_instance_valid(surface_navigation) else {}
	if bool(derived.get("valid", false)):
		_construction_site = derived.position


func _ready() -> void:
	_set_goal_from_surface()
	var derived: Dictionary = surface_navigation.derive_construction_site(navigation) if is_instance_valid(surface_navigation) else {}
	if bool(derived.get("valid", false)):
		_construction_site = derived.position


func _set_goal_from_surface() -> void:
	if not is_instance_valid(surface_navigation):
		return
	_goal_region = String(surface_navigation.goal_surface_id)
	var surface: Dictionary = surface_navigation.goal_surface()
	_goal_label = String(surface.get("object_name", "elevated surface"))
	_goal_center = surface.get("center", Vector3.ZERO)


func seed_population(count: int) -> void:
	for citizen_id in range(count):
		_enqueue_for(citizen_id, 0)
	for offset in range(5):
		_enqueue_for(offset, 1)


func claim_for(citizen_id: int) -> Dictionary:
	if is_instance_valid(civilization):
		var citizen := get_parent().get_node_or_null("Citizen%02d" % (citizen_id + 1)) as Node3D
		if not is_instance_valid(citizen) or citizen.civilization_id != instance_id or citizen.life_state != "ALIVE" or not citizen.combat_duty.is_empty(): return {}
		if is_instance_valid(citizen):
			var strategic: Dictionary = civilization.claim(citizen)
			if not strategic.is_empty(): return strategic
			if civilization.should_interrupt(citizen): return {}
	var selected: Dictionary = {}
	var best := -INF
	for task in tasks:
		if task.state != "available" or task.get("instance_id", "legacy") != instance_id: continue
		var score: float = civilization.routine_score(task, citizen_id) if is_instance_valid(civilization) else 0.0
		if selected.is_empty() and score > -INF or score > best:
			selected = task
			best = score
	if not selected.is_empty():
		selected.state = "reserved"
		selected.citizen_id = citizen_id
		selected.claimed_sim = float(civilization.seconds) if is_instance_valid(civilization) else 0.0
		if is_instance_valid(civilization): civilization.planner.record(String(selected.task_type))
		return selected.duplicate(true)
	return {}


func activate_task(task_id: int) -> void:
	var task := _find_task(task_id)
	if not task.is_empty() and task.state == "reserved":
		task.state = "active"
		task.started_at = Time.get_ticks_msec()
		task.started_sim = float(civilization.seconds) if is_instance_valid(civilization) else 0.0


func complete_task(task_id: int) -> void:
	var task := _find_task(task_id)
	if task.is_empty() or not task.state in ["active", "reserved"]:
		return
	var citizen_id := int(task.citizen_id)
	var cycle := int(task.get("cycle", 0)) + 1
	task.state = "complete"
	task.finished_at = Time.get_ticks_msec()
	_completed_count += 1
	_trim_history()
	_enqueue_for(citizen_id, cycle)
	task_board_updated.emit(summary())


func fail_task(task_id: int, reason: String) -> void:
	var task := _find_task(task_id)
	if task.is_empty() or not task.state in ["active", "reserved"]:
		return
	var citizen_id := int(task.citizen_id)
	var cycle := int(task.get("cycle", 0)) + 1
	if is_instance_valid(civilization): civilization.release(task)
	task.state = "failed"
	task.failure_reason = reason
	task.finished_at = Time.get_ticks_msec()
	_failed_count += 1
	_trim_history()
	_enqueue_for(citizen_id, cycle)
	task_board_updated.emit(summary())


func supersede_task(task_id: int, reason: String) -> void:
	cancel_task(task_id, reason)


func cancel_task(task_id: int, reason: String) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or not task.state in ["active", "reserved"]:
		return false
	if is_instance_valid(civilization): civilization.release(task)
	task.state = "cancelled"
	task.failure_reason = reason
	task.finished_at = Time.get_ticks_msec()
	_cancelled_count += 1
	_trim_history()
	task_board_updated.emit(summary())
	return true


func cancel_construction_stage(stage_index: int, keep_task_id: int = -1) -> void:
	var release_ids: Array[int] = []
	for task in tasks:
		if task.task_type == "CONSTRUCTION_BUILD" and not task.has("project_id") and int(task.get("stage", -1)) == stage_index and int(task.id) != keep_task_id and task.state in ["active", "reserved"]:
			release_ids.append(int(task.id))
	for task_id in release_ids:
		var task := _find_task(task_id)
		var citizen_id := int(task.citizen_id)
		if cancel_task(task_id, "construction stage completed by another builder"):
			var citizen := get_parent().get_node_or_null("Citizen%02d" % (citizen_id + 1))
			if is_instance_valid(citizen):
				citizen.cancel_task_and_resume(task_id)


func create_construction_task(specification: Dictionary, citizen_id: int) -> Dictionary:
	if is_instance_valid(civilization):
		var citizen: Node3D = civilization.citizen_for(citizen_id)
		if citizen == null or citizen.civilization_id != instance_id or citizen.life_state != "ALIVE" or not citizen.combat_duty.is_empty(): return {}
	var task_id := _next_task_id
	_next_task_id += 1
	_created_count += 1
	var task := specification.duplicate(true)
	task["instance_id"] = instance_id
	task["id"] = task_id
	task["state"] = "reserved"
	task["citizen_id"] = citizen_id
	task["owner_hint"] = citizen_id
	task["cycle"] = 0
	task["progress"] = 0.0
	task["created_at"] = Time.get_ticks_msec()
	task["created_sim"] = float(civilization.seconds) if is_instance_valid(civilization) else 0.0
	task["claimed_sim"] = task.created_sim
	tasks.append(task)
	_trim_history()
	return task.duplicate(true)


func confirm_project_pickup(task_id: int, citizen: Node3D, resource: String) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "CONSTRUCTION_DELIVERY" or task.state != "active":
		return false
	if citizen.civilization_id != instance_id or task.instance_id != instance_id: return false
	if int(task.citizen_id) != int(citizen.citizen_id) or String(task.resource) != resource or bool(task.picked_up):
		return false
	if citizen.global_position.distance_to(task.source) > 1.6: return false
	var accepted: bool = civilization.development.pickup(task) if task.has("project_id") else construction_system.take_stock(resource, int(task.amount), int(task.get("ticket", -1)))
	if not accepted:
		return false
	task.picked_up = true
	task.picked_up_at = Time.get_ticks_msec()
	task.pickup_travelled_distance = citizen.travelled_distance
	task.progress = 0.5
	task_board_updated.emit(summary())
	return true


func confirm_project_delivery(task_id: int, citizen: Node3D, resource: String, carried_resource: String) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "CONSTRUCTION_DELIVERY" or task.state != "active":
		return false
	if citizen.civilization_id != instance_id or task.instance_id != instance_id: return false
	if int(task.citizen_id) != int(citizen.citizen_id) or String(task.resource) != resource or resource != carried_resource:
		return false
	if not bool(task.picked_up) or citizen.global_position.distance_to(task.target) > 1.6:
		return false
	var route: Array[Vector3] = navigation.path_between(task.source, task.target)
	var required_travel := _path_length(route) * 0.9
	if route.is_empty() or citizen.travelled_distance - float(task.pickup_travelled_distance) < required_travel:
		return false
	var accepted: bool = civilization.development.deliver(task, citizen) if task.has("project_id") else construction_system.accept_delivery(resource, int(task.amount), citizen.global_position, int(task.get("ticket", -1)))
	if not accepted:
		return false
	task.delivered = true
	task.delivered_at = Time.get_ticks_msec()
	task.delivery_travelled_distance = citizen.travelled_distance - float(task.pickup_travelled_distance)
	task.progress = 1.0
	task_board_updated.emit(summary())
	return true


func advance_construction_work(task_id: int, citizen_id: int, delta: float) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "CONSTRUCTION_BUILD" or task.state != "active" or int(task.citizen_id) != citizen_id:
		return false
	var worker := get_parent().get_node_or_null("Citizen%02d" % (citizen_id + 1)) as Node3D
	if not is_instance_valid(worker) or worker.civilization_id != instance_id or worker.life_state != "ALIVE" or worker.state != "WORK" or worker.global_position.distance_to(task.target) > 1.6:
		return false
	var result: bool = civilization.development.work(task, worker, delta) if task.has("project_id") else construction_system.perform_builder_work(int(task.stage), delta, task_id)
	task.work_seconds = float(task.get("work_seconds", 0.0)) + delta
	if result:
		task.progress = 1.0
	elif task.has("project_id"):
		var active: Dictionary = civilization.development.active
		task.progress = float(active.work) / float(active.required_work) if not active.is_empty() and active.id == task.project_id else 0.0
	else:
		task.progress = float(construction_system.status().stage_progress)
	task_board_updated.emit(summary())
	return result


func issue_reach_explore(surface_id: String, citizens: Array) -> Dictionary:
	if is_instance_valid(civilization) and civilization.world_simulation != null:
		var authority: Node = civilization.world_simulation
		for runtime in authority.runtimes:
			if runtime != civilization and runtime.construction.project_created and runtime.construction.target_region == surface_id:
				return {"accepted":false,"reason":"Shared physical traversal site already committed by another society"}
	if is_instance_valid(civilization) and not civilization.has_capability("advanced_construction"):
		return {"accepted": false, "reason": "A completed workshop is required for advanced traversal"}
	if not surface_navigation.regions.has(surface_id) or surface_id == FLOOR_REGION:
		return {"accepted": false, "state": "REJECTED", "message": "Select an elevated surface first."}
	_goal_region = surface_id
	surface_navigation.goal_surface_id = surface_id
	var site: Dictionary = surface_navigation.derive_construction_site(navigation)
	if not site.get("valid", false): return {"accepted": false, "state": "NO_SITE", "message": "No clear construction site reaches this surface."}
	_construction_site = site.position
	var surface: Dictionary = surface_navigation.regions[surface_id]
	_goal_label = String(surface.get("object_name", "elevated surface"))
	_goal_center = surface.get("center", Vector3.ZERO)
	var spawn_center := RoomDefinitionLoader.vector3_from(room_definition.spawn.center)
	var route_request: Dictionary = surface_navigation.route_between(FLOOR_REGION, surface_id, spawn_center, _goal_center)
	if route_request.reachable:
		return {"accepted": true, "state": "REACHABLE", "message": "A route to %s is available." % _goal_label}
	var candidates: Array[Vector3] = surface_navigation.investigation_candidates_for(surface_id)
	var options: Array[Dictionary] = []
	var needed := mini(2, candidates.size())
	for citizen in citizens:
		var node := citizen as Node3D
		if not is_instance_valid(node) or node.civilization_id != instance_id or node.life_state != "ALIVE" or not node.combat_duty.is_empty():
			continue
		for candidate_index in range(needed):
			var route: Array[Vector3] = navigation.path_between(node.global_position, candidates[candidate_index])
			if not route.is_empty():
				options.append({"citizen": node, "candidate_index": candidate_index, "path_length": _path_length(route)})
	options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left.path_length) < float(right.path_length))
	var used_citizens: Dictionary = {}
	var used_points: Dictionary = {}
	var assignments: Array[Dictionary] = []
	for option in options:
		var explorer: Node3D = option.citizen
		var candidate_index := int(option.candidate_index)
		if used_citizens.has(explorer.get_instance_id()) or used_points.has(candidate_index):
			continue
		used_citizens[explorer.get_instance_id()] = true
		used_points[candidate_index] = true
		assignments.append({"citizen": explorer, "candidate_index": candidate_index})
		if assignments.size() == needed:
			break
	if needed < 2 or assignments.size() < needed:
		return {"accepted": false, "state": "NO_INVESTIGATORS", "message": "No floor route reaches each generated investigation point."}
	_reach_goal = {
		"accepted": true,
		"surface": surface_id,
		"label": _goal_label,
		"state": "EXPLORERS_EN_ROUTE",
		"route_request": route_request.duplicate(true),
		"message": "%s is selected. Explorers are approaching its edge to investigate the missing route." % _goal_label,
		"expected_explorers": assignments.size(),
		"arrived_explorers": 0,
		"arrived_citizens": [],
		"barrier": {},
	}
	for assignment in assignments:
		var explorer: Node3D = assignment.citizen
		var candidate: Vector3 = candidates[int(assignment.candidate_index)]
		var task := _create_investigation_task(explorer.citizen_id, candidate, surface_id)
		explorer.assign_player_goal_task(task)
	reach_goal_updated.emit(get_reach_goal_status())
	return get_reach_goal_status()


func report_investigation_arrival(citizen_id: int, task_id: int, position: Vector3) -> void:
	if _reach_goal.is_empty() or _reach_goal.state != "EXPLORERS_EN_ROUTE" or _reach_goal.arrived_citizens.has(citizen_id):
		return
	if navigation.is_obstacle_position(position):
		push_error("Investigator %d reached blocked room geometry: %s" % [citizen_id, position])
		return
	var surface_id := String(_reach_goal.surface)
	var surface: Dictionary = surface_navigation.regions[surface_id]
	var requested_route: Dictionary = surface_navigation.route_between(FLOOR_REGION, surface_id, position, surface.anchor)
	if requested_route.reachable:
		return
	_reach_goal.arrived_citizens.append(citizen_id)
	_reach_goal.arrived_explorers = _reach_goal.arrived_citizens.size()
	if _reach_goal.arrived_explorers >= _reach_goal.expected_explorers:
		_reach_goal.state = "BARRIER_CONFIRMED"
		_reach_goal.message = "Barrier recognized: floor explorers reached %s, but no navigation link reaches its elevated surface." % String(_reach_goal.label)
		_reach_goal.barrier = {
			"from": FLOOR_REGION,
			"to": surface_id,
			"reason": requested_route.reason,
			"recognized_after_approach": true,
			"investigated_by": _reach_goal.arrived_citizens.duplicate(),
			"approach_position": position,
		}
		reach_goal_updated.emit(get_reach_goal_status())


func get_reach_goal_status() -> Dictionary:
	return _reach_goal.duplicate(true)


func get_construction_site() -> Vector3:
	return _construction_site


func create_traversal_task(citizen: Node3D, route: Array[Vector3]) -> Dictionary:
	if citizen.civilization_id != instance_id or citizen.life_state != "ALIVE" or not citizen.combat_duty.is_empty(): return {}
	if not surface_navigation.has_connection(FLOOR_REGION, _goal_region) or route.size() < 2:
		return {}
	var task := _create_task_record({
		"task_type": "SURFACE_TRAVERSAL",
		"state": "reserved",
		"citizen_id": citizen.citizen_id,
		"owner_hint": citizen.citizen_id,
		"cycle": 0,
		"source": route[0],
		"target": route.back(),
		"target_region": _goal_region,
		"path": route.duplicate(),
		"route_length": _path_length(route),
		"start_travelled_distance": citizen.travelled_distance,
		"progress": 0.0,
	})
	_traversal_task_ids.append(int(task.id))
	_traversal_goal = {"state": "TRAVERSE_IN_PROGRESS", "citizen_id": citizen.citizen_id, "task_id": task.id, "expected_route_length": task.route_length, "target_region": _goal_region}
	return task


func report_traversal_arrival(citizen: Node3D, task_id: int) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "SURFACE_TRAVERSAL" or task.state != "active":
		return false
	var region := String(task.target_region)
	var required_height := float(surface_navigation.regions[region].height)
	if int(task.citizen_id) != citizen.citizen_id or citizen.global_position.y < required_height - 1.0 or citizen.global_position.distance_to(task.target) > 1.7:
		return false
	if not surface_navigation.has_connection(FLOOR_REGION, region):
		return false
	var walked: float = citizen.travelled_distance - float(task.start_travelled_distance)
	if walked < float(task.route_length) * 0.9:
		return false
	task.state = "complete"
	task.progress = 1.0
	task.actual_travelled_distance = walked
	task.finished_at = Time.get_ticks_msec()
	_completed_count += 1
	_snapshot_m6_task_result(task)
	_trim_history()
	_traversal_goal = {"state": "TRAVERSAL_COMPLETE", "citizen_id": citizen.citizen_id, "task_id": task_id, "target": citizen.global_position, "target_region": region, "route_length": float(task.route_length), "actual_travelled_distance": walked}
	_target_arrivals += 1
	var exploration_task := _create_surface_exploration_task(citizen, task_id, region)
	citizen.assign_surface_exploration_task(exploration_task)
	task_board_updated.emit(summary())
	return true


func _create_surface_exploration_task(citizen: Node3D, traversal_id: int, region: String) -> Dictionary:
	if citizen.civilization_id != instance_id or citizen.life_state != "ALIVE" or not citizen.combat_duty.is_empty(): return {}
	var path: Array[Vector3] = surface_navigation.exploration_route(citizen.global_position, region)
	var task := _create_task_record({
		"task_type": "SURFACE_EXPLORATION",
		"state": "reserved",
		"citizen_id": citizen.citizen_id,
		"owner_hint": citizen.citizen_id,
		"cycle": 0,
		"source": citizen.global_position,
		"target": path.back() if not path.is_empty() else citizen.global_position,
		"target_region": region,
		"path": path,
		"route_length": _path_length(path),
		"start_travelled_distance": citizen.travelled_distance,
		"traversal_task_id": traversal_id,
		"progress": 0.0,
		"work_seconds": 0.0,
	})
	_surface_exploration_tasks.append(int(task.id))
	return task


func begin_surface_exploration(citizen: Node3D, task_id: int) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "SURFACE_EXPLORATION" or task.state != "active":
		return false
	var region := String(task.target_region)
	var height := float(surface_navigation.regions[region].height)
	if int(task.citizen_id) != citizen.citizen_id or citizen.global_position.y < height - 1.0:
		return false
	var walked: float = citizen.travelled_distance - float(task.start_travelled_distance)
	if walked < float(task.route_length) * 0.9 or citizen.global_position.distance_to(task.target) > 1.7:
		return false
	task.actual_travelled_distance = walked
	task.arrived_at = Time.get_ticks_msec()
	task.progress = 0.5
	return true


func advance_surface_exploration(citizen: Node3D, task_id: int, delta: float) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "SURFACE_EXPLORATION" or task.state != "active":
		return false
	var region := String(task.target_region)
	var height := float(surface_navigation.regions[region].height)
	if int(task.citizen_id) != citizen.citizen_id or citizen.state != "WORK" or citizen.global_position.y < height - 1.0:
		return false
	if not surface_navigation.has_connection(FLOOR_REGION, region) or construction_system == null or not construction_system.status().cable_deployed:
		return false
	task.work_seconds = float(task.work_seconds) + delta
	task.progress = minf(0.99, 0.5 + float(task.work_seconds) / 4.0 * 0.49)
	if float(task.work_seconds) < 4.0:
		return false
	task.state = "complete"
	task.finished_at = Time.get_ticks_msec()
	task.progress = 1.0
	_target_explorations_completed += 1
	_completed_count += 1
	_snapshot_m6_task_result(task)
	_trim_history()
	if _autonomous_reuse_count < 2:
		_dispatch_next_route_reuse()
	else:
		_traversal_goal["state"] = "AUTONOMOUS_REUSE_COMPLETE"
		_traversal_goal["target_explorations_completed"] = _target_explorations_completed
	task_board_updated.emit(summary())
	return true


func _dispatch_next_route_reuse() -> void:
	if not surface_navigation.has_connection(FLOOR_REGION, _goal_region) or construction_system == null or not construction_system.status().cable_deployed:
		return
	var citizens: Array[Node3D] = []
	for child in get_parent().get_children():
		if child is Node3D and child.name.begins_with("Citizen"):
			var candidate := child as Node3D
			if candidate.task_type == "SURFACE_TRAVERSAL" or candidate.task_type == "SURFACE_EXPLORATION" or candidate.state == "ON_SURFACE":
				continue
			citizens.append(candidate)
	if citizens.is_empty():
		return
	citizens.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.global_position.distance_to(_construction_site) < b.global_position.distance_to(_construction_site))
	var traveler := citizens[0]
	var surface: Dictionary = surface_navigation.regions[_goal_region]
	var route_request: Dictionary = surface_navigation.route_between(FLOOR_REGION, _goal_region, traveler.global_position, surface.anchor)
	if not route_request.reachable:
		return
	var task := create_traversal_task(traveler, route_request.path)
	if task.is_empty():
		return
	_autonomous_reuse_count += 1
	var stored := _find_task(int(task.id))
	stored["autonomous_reuse"] = true
	stored["reuse_index"] = _autonomous_reuse_count
	_traversal_goal["reuse_index"] = _autonomous_reuse_count
	_traversal_goal["autonomous_reuse"] = true
	traveler.assign_traversal_task(stored.duplicate(true))


func get_m6_status() -> Dictionary:
	var construction_status: Dictionary = construction_system.status() if construction_system != null else {}
	var infrastructure_ok: bool = not construction_status.is_empty() and bool(construction_status.get("cable_deployed", false)) and surface_navigation.has_connection(FLOOR_REGION, _goal_region)
	return {
		"target_arrivals": _target_arrivals,
		"target_explorations_completed": _target_explorations_completed,
		"autonomous_reuses_assigned": _autonomous_reuse_count,
		"infrastructure_operational": infrastructure_ok,
		"traversal_task_ids": _traversal_task_ids.duplicate(),
		"surface_exploration_task_ids": _surface_exploration_tasks.duplicate(),
	}


func get_m6_task_result(task_id: int) -> Dictionary:
	if _m6_completed_task_results.has(task_id):
		return _m6_completed_task_results[task_id].duplicate(true)
	return get_task(task_id)


func _snapshot_m6_task_result(task: Dictionary) -> void:
	var task_id := int(task.get("id", -1))
	if task_id < 0 or (not _traversal_task_ids.has(task_id) and not _surface_exploration_tasks.has(task_id)):
		return
	_m6_completed_task_results[task_id] = task.duplicate(true)


func get_traversal_goal_status() -> Dictionary:
	return _traversal_goal.duplicate(true)


func _create_investigation_task(citizen_id: int, target: Vector3, surface_id: String) -> Dictionary:
	return _create_task_record({
		"task_type": "SURFACE_INVESTIGATION",
		"state": "reserved",
		"citizen_id": citizen_id,
		"owner_hint": citizen_id,
		"cycle": 0,
		"source": Vector3.ZERO,
		"target": target,
		"target_region": surface_id,
		"progress": 0.0,
	})


func _create_task_record(specification: Dictionary) -> Dictionary:
	var task := specification.duplicate(true)
	task["instance_id"] = instance_id
	task["id"] = _next_task_id
	_next_task_id += 1
	_created_count += 1
	task["created_at"] = Time.get_ticks_msec()
	task["created_sim"] = float(civilization.seconds) if is_instance_valid(civilization) else 0.0
	tasks.append(task)
	_trim_history()
	return task.duplicate(true)


func _path_length(path: Array[Vector3]) -> float:
	var length := 0.0
	for index in range(1, path.size()):
		length += path[index - 1].distance_to(path[index])
	return length


func summary() -> Dictionary:
	var available := 0
	var reserved := 0
	var active := 0
	var complete := 0
	var failed := 0
	var cancelled := 0
	for task in tasks:
		match String(task.state):
			"available": available += 1
			"reserved": reserved += 1
			"active": active += 1
			"complete": complete += 1
			"failed": failed += 1
			"cancelled": cancelled += 1
	return {"available": available, "reserved": reserved, "active": active, "complete": complete, "failed": failed, "cancelled": cancelled, "retained_tasks": tasks.size(), "completed_total": _completed_count, "failed_total": _failed_count, "cancelled_total": _cancelled_count, "created_total": _created_count}


func get_task(task_id: int) -> Dictionary:
	var task := _find_task(task_id)
	return task.duplicate(true) if not task.is_empty() else {}


func _find_task(task_id: int) -> Dictionary:
	for task in tasks:
		if int(task.id) == task_id:
			return task
	return {}


func _enqueue_for(citizen_id: int, cycle: int) -> void:
	if is_instance_valid(civilization):
		var citizen: Node3D = civilization.citizen_for(citizen_id)
		if citizen != null and citizen.life_state == "DEAD": return
	# An empty start has no buildings to maintain. Production resource/build tasks
	# still come through claim(); harmless patrols provide fallback activity.
	if room_definition.has("start") and room_definition.start.infrastructure.is_empty():
		for pending in tasks:
			if pending.state == "available" and int(pending.get("owner_hint", -1)) == citizen_id: return
		var target: Vector3 = patrol_stations[(citizen_id + cycle) % patrol_stations.size()]
		_create_task_record({"task_type": "FLOOR_PATROL", "state": "available", "citizen_id": -1, "owner_hint": citizen_id, "cycle": cycle, "source": target, "target": target, "progress": 0.0})
		return
	if is_instance_valid(civilization):
		for pending in tasks:
			if pending.state == "available" and int(pending.get("owner_hint", -1)) == citizen_id:
				return
	var selector := posmod(citizen_id + cycle, 5)
	var kind := ""
	var source := Vector3.ZERO
	var target := Vector3.ZERO
	match selector:
		0:
			kind = "WORKSHOP_MAINTENANCE"
			target = workshop_stations[(citizen_id + cycle) % workshop_stations.size()]
		1:
			kind = "DEPOT_RUN"
			source = depot_station
			target = workshop_stations[(citizen_id + cycle) % workshop_stations.size()]
		2:
			kind = "HOUSING_CHECK"
			target = housing_station
		3:
			kind = "WORK_AREA_JOB"
			target = work_area_station
		_:
			kind = "FLOOR_PATROL"
			target = patrol_stations[(citizen_id + cycle) % patrol_stations.size()]
	_create_task_record({"task_type": kind, "state": "available", "citizen_id": -1, "owner_hint": citizen_id, "cycle": cycle, "source": source, "target": target, "progress": 0.0})


func _trim_history() -> void:
	while tasks.size() > MAX_HISTORY:
		var removable_index := -1
		for index in range(tasks.size()):
			if tasks[index].state in ["complete", "failed", "cancelled"]:
				removable_index = index
				break
		if removable_index < 0:
			break
		tasks.remove_at(removable_index)


func _vectors(values: Array) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for value in values:
		result.append(RoomDefinitionLoader.vector3_from(value))
	return result
