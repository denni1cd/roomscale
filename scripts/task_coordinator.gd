extends Node
## Shared deterministic task queue. Task dictionaries retain each lifecycle state for inspection.

signal reach_goal_updated(status: Dictionary)
signal task_board_updated(status: Dictionary)

const MAX_HISTORY := 500

var navigation: Node
var surface_navigation: Node
var construction_system: Node
var tasks: Array[Dictionary] = []
var _next_task_id := 1
var _created_count := 0
var _completed_count := 0
var _failed_count := 0

var workshop_stations: Array[Vector3] = []
var depot_station := Vector3(18.0, 0.0, 55.0)
var housing_station := Vector3(-14.0, 0.0, 66.0)
var work_area_station := Vector3(-3.0, 0.0, 77.0)
var patrol_stations: Array[Vector3] = [
	Vector3(-44.0, 0.0, 20.0), Vector3(42.0, 0.0, 22.0),
	Vector3(42.0, 0.0, 78.0), Vector3(-45.0, 0.0, 79.0)
]
var _reach_goal: Dictionary = {}
var _traversal_goal: Dictionary = {}
var _desk_arrivals := 0
var _desk_explorations_completed := 0
var _autonomous_reuse_count := 0
var _desk_exploration_tasks: Array[int] = []
var _traversal_task_ids: Array[int] = []
var _desk_waypoints: Array[Vector3] = [
	Vector3(-45.0, 30.0, -45.0), Vector3(-42.0, 30.0, -66.0),
	Vector3(-70.0, 30.0, -68.0), Vector3(-73.0, 30.0, -43.0),
	Vector3(-58.0, 30.0, -52.0),
]


func _ready() -> void:
	workshop_stations = [Vector3(-20.0, 0.0, 55.0), Vector3(-8.0, 0.0, 55.0), Vector3(-14.0, 0.0, 57.0)]


func seed_population(count: int) -> void:
	for citizen_id in range(count):
		_enqueue_for(citizen_id, 0)
	# Keep a small reserve so the live board always exposes available work.
	for offset in range(5):
		_enqueue_for(offset, 1)


func claim_for(citizen_id: int) -> Dictionary:
	for index in range(tasks.size()):
		if tasks[index].state == "available":
			tasks[index].state = "reserved"
			tasks[index].citizen_id = citizen_id
			return tasks[index].duplicate(true)
	return {}


func activate_task(task_id: int) -> void:
	for task in tasks:
		if task.id == task_id and task.state == "reserved":
			task.state = "active"
			task.started_at = Time.get_ticks_msec()
			return


func complete_task(task_id: int) -> void:
	for index in range(tasks.size()):
		if tasks[index].id == task_id and (tasks[index].state == "active" or tasks[index].state == "reserved"):
			var citizen_id: int = tasks[index].citizen_id
			var cycle: int = tasks[index].cycle + 1
			tasks[index].state = "complete"
			tasks[index].finished_at = Time.get_ticks_msec()
			_completed_count += 1
			_trim_history()
			_enqueue_for(citizen_id, cycle)
			return


func fail_task(task_id: int, reason: String) -> void:
	for index in range(tasks.size()):
		if tasks[index].id == task_id and (tasks[index].state == "active" or tasks[index].state == "reserved"):
			var citizen_id: int = tasks[index].citizen_id
			var cycle: int = tasks[index].cycle + 1
			tasks[index].state = "failed"
			tasks[index].failure_reason = reason
			_failed_count += 1
			_trim_history()
			_enqueue_for(citizen_id, cycle)
			return


func supersede_task(task_id: int, reason: String) -> void:
	for task in tasks:
		if task.id == task_id and (task.state == "active" or task.state == "reserved"):
			task.state = "cancelled"
			task.failure_reason = reason
			return


func create_construction_task(specification: Dictionary, citizen_id: int) -> Dictionary:
	var task_id := _next_task_id
	_next_task_id += 1
	_created_count += 1
	var task := specification.duplicate(true)
	task["id"] = task_id
	task["state"] = "reserved"
	task["citizen_id"] = citizen_id
	task["owner_hint"] = citizen_id
	task["cycle"] = 0
	task["progress"] = 0.0
	task["created_at"] = Time.get_ticks_msec()
	tasks.append(task)
	_trim_history()
	return task.duplicate(true)


func confirm_project_pickup(task_id: int, citizen: Node3D, resource: String) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "CONSTRUCTION_DELIVERY" or task.state != "active":
		return false
	if int(task.citizen_id) != int(citizen.citizen_id) or String(task.resource) != resource or bool(task.picked_up):
		return false
	if citizen.global_position.distance_to(task.source) > 1.6 or not construction_system.take_stock(resource, int(task.amount)):
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
	if int(task.citizen_id) != int(citizen.citizen_id) or String(task.resource) != resource or resource != carried_resource:
		return false
	if not bool(task.picked_up) or citizen.global_position.distance_to(task.target) > 1.6:
		return false
	var route: Array[Vector3] = navigation.path_between(task.source, task.target)
	var required_travel := _path_length(route) * 0.9
	if route.is_empty() or citizen.travelled_distance - float(task.pickup_travelled_distance) < required_travel:
		return false
	if not construction_system.accept_delivery(resource, int(task.amount), citizen.global_position):
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
	if not is_instance_valid(worker) or worker.state != "WORK" or worker.global_position.distance_to(task.target) > 1.6:
		return false
	var result: bool = construction_system.perform_builder_work(int(task.stage), delta)
	task.work_seconds = float(task.get("work_seconds", 0.0)) + delta
	if result:
		task.progress = 1.0
	else:
		task.progress = float(construction_system.status().stage_progress)
	task_board_updated.emit(summary())
	return result


func issue_reach_explore(surface_id: String, citizens: Array) -> Dictionary:
	if surface_id != surface_navigation.DESK_REGION:
		return {"accepted": false, "state": "REJECTED", "message": "Select the desk surface first."}
	var route_request: Dictionary = surface_navigation.route_between(
		surface_navigation.FLOOR_REGION, surface_id, Vector3(-58.0, 0.0, 0.0), Vector3(-58.0, 30.0, -52.0)
	)
	if route_request.reachable:
		return {"accepted": true, "state": "REACHABLE", "message": "A route to the desk is available."}
	var candidates: Array[Vector3] = surface_navigation.investigation_candidates()
	var options: Array[Dictionary] = []
	for citizen in citizens:
		var citizen_node := citizen as Node3D
		if not is_instance_valid(citizen_node):
			continue
		for candidate_index in range(candidates.size()):
			var investigation_path: Array[Vector3] = surface_navigation.investigation_route(citizen_node.global_position, candidate_index)
			if not investigation_path.is_empty():
				options.append({
					"citizen": citizen_node,
					"candidate_index": candidate_index,
					"path_length": _path_length(investigation_path),
				})
	options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left.path_length) < float(right.path_length))
	var selected_citizens: Dictionary = {}
	var selected_candidates: Dictionary = {}
	var assignments: Array[Dictionary] = []
	for option in options:
		var explorer: Node3D = option.citizen
		var candidate_index: int = option.candidate_index
		if selected_citizens.has(explorer.get_instance_id()) or selected_candidates.has(candidate_index):
			continue
		selected_citizens[explorer.get_instance_id()] = true
		selected_candidates[candidate_index] = true
		assignments.append({"citizen": explorer, "candidate_index": candidate_index})
		if assignments.size() == candidates.size():
			break
	if assignments.size() < candidates.size():
		return {"accepted": false, "state": "NO_INVESTIGATORS", "message": "No floor route reaches each investigation point."}
	_reach_goal = {
		"accepted": true,
		"surface": surface_id,
		"state": "EXPLORERS_EN_ROUTE",
		"route_request": route_request.duplicate(true),
		"message": "Desk is selected. Explorers are approaching the desk edge to investigate the missing route.",
		"expected_explorers": assignments.size(),
		"arrived_explorers": 0,
		"arrived_citizens": [],
		"barrier": {},
	}
	for assignment in assignments:
		var explorer: Node3D = assignment.citizen
		var candidate: Vector3 = candidates[int(assignment.candidate_index)]
		var task := _create_exploration_task(explorer.citizen_id, candidate, surface_id)
		explorer.assign_player_goal_task(task)
	reach_goal_updated.emit(get_reach_goal_status())
	return get_reach_goal_status()


func report_investigation_arrival(citizen_id: int, task_id: int, position: Vector3) -> void:
	if _reach_goal.is_empty() or _reach_goal.state != "EXPLORERS_EN_ROUTE":
		return
	if _reach_goal.arrived_citizens.has(citizen_id):
		return
	if navigation.is_obstacle_position(position):
		push_error("Investigator %d reached a blocked floor point: %s" % [citizen_id, position])
		return
	var requested_route: Dictionary = surface_navigation.route_between(
		surface_navigation.FLOOR_REGION, String(_reach_goal.surface), position, Vector3(-58.0, 30.0, -52.0)
	)
	if requested_route.reachable:
		return
	_reach_goal.arrived_citizens.append(citizen_id)
	_reach_goal.arrived_explorers = _reach_goal.arrived_citizens.size()
	if _reach_goal.arrived_explorers >= _reach_goal.expected_explorers:
		_reach_goal.state = "BARRIER_CONFIRMED"
		_reach_goal.message = "Barrier recognized: floor explorers reached the desk edge, but no navigation link reaches the elevated desk."
		_reach_goal.barrier = {
			"from": surface_navigation.FLOOR_REGION,
			"to": String(_reach_goal.surface),
			"reason": requested_route.reason,
			"recognized_after_approach": true,
			"investigated_by": _reach_goal.arrived_citizens.duplicate(),
			"approach_position": position,
		}
		reach_goal_updated.emit(get_reach_goal_status())


func get_reach_goal_status() -> Dictionary:
	return _reach_goal.duplicate(true)


func create_traversal_task(citizen: Node3D, route: Array[Vector3]) -> Dictionary:
	if not surface_navigation.has_connection("FLOOR", "DESK") or route.size() < 2:
		return {}
	var task_id := _next_task_id
	_next_task_id += 1
	_created_count += 1
	var task := {
		"id": task_id,
		"task_type": "GRAPPLE_TRAVERSAL",
		"state": "reserved",
		"citizen_id": citizen.citizen_id,
		"owner_hint": citizen.citizen_id,
		"cycle": 0,
		"source": route[0],
		"target": route[route.size() - 1],
		"target_region": "DESK",
		"path": route.duplicate(),
		"route_length": _path_length(route),
		"start_travelled_distance": citizen.travelled_distance,
		"progress": 0.0,
		"created_at": Time.get_ticks_msec(),
	}
	tasks.append(task)
	_traversal_task_ids.append(task_id)
	_traversal_goal = {"state": "TRAVERSE_IN_PROGRESS", "citizen_id": citizen.citizen_id, "task_id": task_id, "expected_route_length": task.route_length}
	return task.duplicate(true)


func report_traversal_arrival(citizen: Node3D, task_id: int) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "GRAPPLE_TRAVERSAL" or task.state != "active":
		return false
	if int(task.citizen_id) != citizen.citizen_id or String(task.target_region) != "DESK":
		return false
	if citizen.global_position.y < 29.0 or citizen.global_position.distance_to(task.target) > 1.7:
		return false
	if not surface_navigation.has_connection("FLOOR", "DESK"):
		return false
	var walked: float = citizen.travelled_distance - float(task.start_travelled_distance)
	if walked < float(task.route_length) * 0.9:
		return false
	task.state = "complete"
	task.progress = 1.0
	task.actual_travelled_distance = walked
	task.finished_at = Time.get_ticks_msec()
	_completed_count += 1
	_traversal_goal = {
		"state": "TRAVERSAL_COMPLETE",
		"citizen_id": citizen.citizen_id,
		"task_id": task_id,
		"target": citizen.global_position,
		"target_region": "DESK",
		"route_length": float(task.route_length),
		"actual_travelled_distance": walked,
	}
	_desk_arrivals += 1
	var explore_task := _create_desk_exploration_task(citizen, task_id)
	citizen.assign_desk_exploration_task(explore_task)
	task_board_updated.emit(summary())
	return true


func _create_desk_exploration_task(citizen: Node3D, traversal_id: int) -> Dictionary:
	var path: Array[Vector3] = [citizen.global_position]
	for waypoint in _desk_waypoints:
		path.append(waypoint)
	var task_id := _next_task_id
	_next_task_id += 1
	_created_count += 1
	var task := {
		"id": task_id, "task_type": "DESK_EXPLORATION", "state": "reserved",
		"citizen_id": citizen.citizen_id, "owner_hint": citizen.citizen_id, "cycle": 0,
		"source": citizen.global_position, "target": _desk_waypoints[_desk_waypoints.size() - 1],
		"target_region": "DESK", "path": path, "route_length": _path_length(path),
		"start_travelled_distance": citizen.travelled_distance, "traversal_task_id": traversal_id,
		"progress": 0.0, "created_at": Time.get_ticks_msec(), "work_seconds": 0.0,
	}
	tasks.append(task)
	_desk_exploration_tasks.append(task_id)
	return task.duplicate(true)


func begin_desk_exploration(citizen: Node3D, task_id: int) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "DESK_EXPLORATION" or task.state != "active":
		return false
	if int(task.citizen_id) != citizen.citizen_id or not surface_navigation.has_connection("FLOOR", "DESK") or citizen.global_position.y < 29.0:
		return false
	var walked: float = citizen.travelled_distance - float(task.start_travelled_distance)
	if walked < float(task.route_length) * 0.9 or citizen.global_position.distance_to(task.target) > 1.7:
		return false
	task.actual_travelled_distance = walked
	task.arrived_at = Time.get_ticks_msec()
	task.progress = 0.5
	return true


func advance_desk_exploration(citizen: Node3D, task_id: int, delta: float) -> bool:
	var task := _find_task(task_id)
	if task.is_empty() or task.task_type != "DESK_EXPLORATION" or task.state != "active":
		return false
	if int(task.citizen_id) != citizen.citizen_id or citizen.state != "WORK" or citizen.global_position.y < 29.0:
		return false
	if not surface_navigation.has_connection("FLOOR", "DESK") or construction_system == null or not construction_system.status().cable_deployed:
		return false
	task.work_seconds = float(task.work_seconds) + delta
	task.progress = minf(0.99, 0.5 + float(task.work_seconds) / 4.0 * 0.49)
	if float(task.work_seconds) < 4.0:
		return false
	task.state = "complete"
	task.finished_at = Time.get_ticks_msec()
	task.progress = 1.0
	_desk_explorations_completed += 1
	_completed_count += 1
	if _autonomous_reuse_count < 2:
		_dispatch_next_route_reuse()
	else:
		_traversal_goal["state"] = "M6_AUTONOMY_COMPLETE"
		_traversal_goal["desk_explorations_completed"] = _desk_explorations_completed
	task_board_updated.emit(summary())
	return true


func _dispatch_next_route_reuse() -> void:
	if not surface_navigation.has_connection("FLOOR", "DESK") or construction_system == null or not construction_system.status().cable_deployed:
		return
	var citizens: Array[Node3D] = []
	for child in get_parent().get_children():
		if child is Node3D and child.name.begins_with("Citizen"):
			var candidate := child as Node3D
			if candidate.task_type == "GRAPPLE_TRAVERSAL" or candidate.task_type == "DESK_EXPLORATION" or candidate.state == "ON_DESK":
				continue
			citizens.append(candidate)
	if citizens.is_empty():
		return
	citizens.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_to(Vector3(-14.0, 0.0, -52.0)) < b.global_position.distance_to(Vector3(-14.0, 0.0, -52.0)))
	var traveler := citizens[0]
	var route_request: Dictionary = surface_navigation.route_between("FLOOR", "DESK", traveler.global_position, Vector3(-58.0, 30.0, -52.0))
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
	var infrastructure_ok: bool = not construction_status.is_empty() and bool(construction_status.get("cable_deployed", false)) and surface_navigation.has_connection("FLOOR", "DESK")
	return {
		"desk_arrivals": _desk_arrivals,
		"desk_explorations_completed": _desk_explorations_completed,
		"autonomous_reuses_assigned": _autonomous_reuse_count,
		"infrastructure_operational": infrastructure_ok,
		"traversal_task_ids": _traversal_task_ids.duplicate(),
		"desk_exploration_task_ids": _desk_exploration_tasks.duplicate(),
	}


func get_traversal_goal_status() -> Dictionary:
	return _traversal_goal.duplicate(true)


func _create_exploration_task(citizen_id: int, target: Vector3, surface_id: String) -> Dictionary:
	var task_id := _next_task_id
	_next_task_id += 1
	_created_count += 1
	var task := {
		"id": task_id,
		"task_type": "DESK_INVESTIGATION",
		"state": "reserved",
		"citizen_id": citizen_id,
		"owner_hint": citizen_id,
		"cycle": 0,
		"source": Vector3.ZERO,
		"target": target,
		"target_region": surface_id,
		"progress": 0.0,
		"created_at": Time.get_ticks_msec(),
	}
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
	for task in tasks:
		match String(task.state):
			"available": available += 1
			"reserved": reserved += 1
			"active": active += 1
			"complete": complete += 1
			"failed": failed += 1
	return {
		"available": available,
		"reserved": reserved,
		"active": active,
		"complete": complete,
		"failed": failed,
		"completed_total": _completed_count,
		"failed_total": _failed_count,
		"created_total": _created_count,
	}


func get_task(task_id: int) -> Dictionary:
	for task in tasks:
		if task.id == task_id:
			return task.duplicate(true)
	return {}


func _find_task(task_id: int) -> Dictionary:
	for task in tasks:
		if int(task.id) == task_id:
			return task
	return {}


func _enqueue_for(citizen_id: int, cycle: int) -> void:
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
	var task_id := _next_task_id
	_next_task_id += 1
	_created_count += 1
	tasks.append({
		"id": task_id,
		"task_type": kind,
		"state": "available",
		"citizen_id": -1,
		"owner_hint": citizen_id,
		"cycle": cycle,
		"source": source,
		"target": target,
		"progress": 0.0,
		"created_at": Time.get_ticks_msec(),
	})
	_trim_history()


func _trim_history() -> void:
	while tasks.size() > MAX_HISTORY:
		if tasks[0].state == "complete" or tasks[0].state == "failed":
			tasks.pop_front()
		else:
			break
