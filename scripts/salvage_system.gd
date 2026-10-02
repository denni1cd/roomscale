extends RefCounted
## Authorized, work-driven, once-only salvage stages; presentation follows these states.

var objects: Dictionary = {}
var stage_completions := 0
var total_work := 0.0

func configure(resource_objects: Dictionary) -> void:
	for id in resource_objects:
		var profile: Dictionary = resource_objects[id].profile
		if profile.harvestable:
			objects[id] = {"authorized": false, "stage": 0, "progress": 0.0, "state": "INTACT", "stages": profile.stages.duplicate(true), "yielded": {}, "work": 0.0}

func authorize(id: String) -> bool:
	if not objects.has(id) or int(objects[id].stage) >= objects[id].stages.size(): return false
	objects[id].authorized = true
	return true

func work(id: String, stage: int, delta: float, position: Vector3, target: Vector3) -> Dictionary:
	if not objects.has(id): return {}
	var object: Dictionary = objects[id]
	if not object.authorized or stage != int(object.stage) or stage >= object.stages.size() or delta <= 0 or position.distance_to(target) > 1.6: return {}
	object.progress += delta
	object.work += delta
	total_work += delta
	var specification: Dictionary = object.stages[stage]
	if float(object.progress) + 0.000001 < float(specification.work): return {}
	object.stage += 1
	object.progress = 0.0
	object.state = String(specification.name)
	for resource in specification.yields: object.yielded[resource] = float(object.yielded.get(resource, 0)) + float(specification.yields[resource])
	stage_completions += 1
	return specification.yields.duplicate(true)

func depleted(id: String) -> bool:
	return objects.has(id) and int(objects[id].stage) >= objects[id].stages.size()
