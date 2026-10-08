extends RefCounted
## Semantic/material profiles and finite source state use ordinary RoomDefinition objects.

const RESOURCES := ["food", "water", "wood", "metal"]
var objects: Dictionary = {}
var sources: Dictionary = {}
var bundles: Dictionary = {}
var _next_bundle := 1
var generated := {"food": 0.0, "water": 0.0, "wood": 0.0, "metal": 0.0}
var delivered := {"food": 0.0, "water": 0.0, "wood": 0.0, "metal": 0.0}

static func derive(object: Dictionary) -> Dictionary:
	var semantic := String(object.get("kind", "unknown")).to_lower()
	var material := String(object.get("appearance", {}).get("material", "")).to_lower()
	if material.is_empty() and semantic in ["chair", "table", "desk", "bookcase", "box", "crate", "workbench"]: material = "wood"
	var explicit: Dictionary = object.get("resource_profile", {})
	# Automatic stages must use the final material; explicit stages still win
	# when the profile is merged below. Invalid overrides remain validator errors.
	if explicit.has("material"): material = String(explicit.material)
	var profile := {"material": material, "harvestable": false, "protected": true, "contents": {}, "region_id": "FLOOR", "work_seconds": 2.0, "stages": []}
	if semantic != "settlement" and material in ["wood", "metal"]:
		var dims: Array = object.get("dimensions", [1, 1, 1])
		var quantity := maxf(8, floorf(float(dims[0]) * float(dims[1]) * float(dims[2]) / 800))
		profile.harvestable = true
		if material == "wood":
			profile.stages = [
				{"name": "STRIPPED", "work": 8.0, "yields": {"metal": 2.0}},
				{"name": "PARTIAL", "work": 12.0, "yields": {"wood": floorf(quantity * 0.4), "metal": 2.0}},
				{"name": "FRAME", "work": 12.0, "yields": {"wood": floorf(quantity * 0.3)}},
				{"name": "DEPLETED", "work": 10.0, "yields": {"wood": quantity - floorf(quantity * 0.4) - floorf(quantity * 0.3)}}]
		else:
			profile.stages = [{"name": "STRIPPED", "work": 10.0, "yields": {"metal": quantity * 0.5}}, {"name": "DEPLETED", "work": 15.0, "yields": {"metal": quantity * 0.5}}]
	profile.merge(explicit, true)
	return profile

func configure(definition: Dictionary) -> void:
	for object in definition.objects:
		var profile := derive(object)
		objects[String(object.id)] = {"data": object.duplicate(true), "profile": profile}
		if not profile.contents.is_empty():
			var position: Array = object.position
			sources[String(object.id)] = {"position": Vector3(float(position[0]), float(position[1]), float(position[2])), "region": String(profile.region_id), "remaining": profile.contents.duplicate(true), "initial": profile.contents.duplicate(true), "reserved": {}, "reservations": {}, "extracted": {}, "work": float(profile.work_seconds)}

func create_bundle(resource: String, amount: float, position: Vector3, source: String) -> int:
	if not resource in RESOURCES or amount <= 0: return -1
	var id := _next_bundle
	_next_bundle += 1
	bundles[id] = {"id": id, "resource": resource, "amount": amount, "position": position, "source": source, "state": "available", "citizen_id": -1}
	generated[resource] += amount
	return id

func reserve_bundle(id: int, citizen_id: int, instance_id: String = "legacy") -> bool:
	if not bundles.has(id) or bundles[id].state != "available": return false
	bundles[id].state = "reserved"
	bundles[id].citizen_id = citizen_id
	bundles[id]["instance_id"] = instance_id
	return true

func pickup_bundle(id: int, citizen_id: int, position: Vector3) -> bool:
	if not bundles.has(id): return false
	var bundle: Dictionary = bundles[id]
	if bundle.state != "reserved" or int(bundle.citizen_id) != citizen_id or position.distance_to(bundle.position) > 1.6: return false
	bundle.state = "in_transit"
	return true

func deliver_bundle(id: int, citizen_id: int, position: Vector3, depot: Vector3, economy: RefCounted) -> bool:
	if not bundles.has(id): return false
	var bundle: Dictionary = bundles[id]
	if bundle.state != "in_transit" or int(bundle.citizen_id) != citizen_id or position.distance_to(depot) > 1.6: return false
	if bundle.get("instance_id", "legacy") != economy.instance_id: return false
	if not economy.receive(String(bundle.resource), float(bundle.amount)): return false
	delivered[bundle.resource] += float(bundle.amount)
	bundles.erase(id)
	return true

func release_bundle(id: int, citizen_id: int, position: Vector3) -> void:
	if not bundles.has(id) or int(bundles[id].citizen_id) != citizen_id: return
	if bundles[id].state == "in_transit": bundles[id].position = position
	bundles[id].state = "available"
	bundles[id].citizen_id = -1

func source_available(id: String, resource: String) -> float:
	if not sources.has(id): return 0
	return float(sources[id].remaining.get(resource, 0)) - float(sources[id].reserved.get(resource, 0))

func reserve_source(id: String, resource: String, amount: float, instance_id: String = "legacy") -> bool:
	if amount <= 0 or source_available(id, resource) < amount: return false
	sources[id].reserved[resource] = float(sources[id].reserved.get(resource, 0)) + amount
	if not sources[id].reservations.has(instance_id): sources[id].reservations[instance_id] = {}
	var owner: Dictionary = sources[id].reservations[instance_id]
	owner[resource] = float(owner.get(resource,0)) + amount
	return true

func release_source(id: String, resource: String, amount: float, instance_id: String = "legacy") -> void:
	if not sources.has(id): return
	var owner: Dictionary = sources[id].reservations.get(instance_id,{})
	var released := minf(amount,float(owner.get(resource,0)))
	owner[resource] = float(owner.get(resource,0)) - released
	sources[id].reserved[resource] = maxf(0,float(sources[id].reserved.get(resource,0)) - released)

func extract(id: String, resource: String, amount: float, position: Vector3, instance_id: String = "legacy") -> int:
	if not sources.has(id): return -1
	var source: Dictionary = sources[id]
	var owner: Dictionary = source.reservations.get(instance_id,{})
	if amount <= 0 or float(owner.get(resource,0)) < amount or float(source.reserved.get(resource, 0)) < amount or float(source.remaining.get(resource, 0)) < amount or position.distance_to(source.position) > 1.6: return -1
	source.remaining[resource] -= amount
	source.reserved[resource] -= amount
	owner[resource] -= amount
	source.extracted[resource] = float(source.extracted.get(resource, 0)) + amount
	return create_bundle(resource, amount, position, id)

func audit() -> Array[String]:
	var errors: Array[String] = []
	for resource in RESOURCES:
		var outstanding := 0.0
		for bundle in bundles.values():
			if bundle.resource == resource: outstanding += float(bundle.amount)
		if absf(float(generated[resource]) - float(delivered[resource]) - outstanding) > 0.0001: errors.append("bundle conservation: " + resource)
	for source in sources.values():
		for resource in source.initial:
			var reserved_by_owners := 0.0
			for owner in source.reservations.values(): reserved_by_owners += float(owner.get(resource,0))
			if absf(reserved_by_owners - float(source.reserved.get(resource,0))) > 0.0001: errors.append("source reservation ownership: " + resource)
			if float(source.remaining[resource]) < 0 or float(source.reserved.get(resource, 0)) > float(source.remaining[resource]) or absf(float(source.initial[resource]) - float(source.remaining[resource]) - float(source.extracted.get(resource, 0))) > 0.0001: errors.append("source conservation: " + resource)
	return errors

static func validate_profile(value: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not value is Dictionary: return ["resource_profile must be an object"]
	for flag in ["harvestable", "protected"]:
		if value.has(flag) and not value[flag] is bool: errors.append(flag + " must be boolean")
	if value.has("work_seconds") and (not _positive(value.work_seconds)): errors.append("work_seconds must be finite and positive")
	if value.has("region_id") and not value.region_id is String: errors.append("region_id must be a string")
	if value.has("contents"):
		errors.append_array(_validate_yields(value.contents))
		if value.contents is Dictionary:
			for resource in value.contents:
				if resource not in ["food", "water"]: errors.append("extractable contents support food/water; construction materials use salvage stages")
	if value.has("material") and (not value.material is String or value.material not in ["wood", "metal", ""]): errors.append("profile material must be wood or metal")
	if value.has("stages"):
		if not value.stages is Array or value.stages.is_empty(): errors.append("stages must be a nonempty array")
		else:
			for stage in value.stages:
				if not stage is Dictionary or not stage.get("name") is String or not _positive(stage.get("work")): errors.append("stage requires name and positive work")
				else:
					errors.append_array(_validate_yields(stage.get("yields")))
					if stage.get("yields") is Dictionary and stage.yields.is_empty(): errors.append("salvage stage requires a nonempty yield")
	return errors

static func _positive(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) > 0

static func _validate_yields(value: Variant) -> Array[String]:
	if not value is Dictionary: return ["contents/yields must be an object"]
	var errors: Array[String] = []
	for resource in value:
		if resource not in RESOURCES or not _positive(value[resource]): errors.append("invalid resource or amount: " + String(resource))
	return errors
