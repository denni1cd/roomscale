extends Node
## Shared deterministic task queue. Task dictionaries retain each lifecycle state for inspection.

const MAX_HISTORY := 500

var navigation: Node
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
