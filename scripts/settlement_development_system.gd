extends RefCounted
## Real settlement projects reuse production delivery/build tasks and economy tickets.
const FloorNavigation := preload("res://scripts/floor_navigation.gd")
const SitePlanner := preload("res://scripts/settlement_site_planner.gd")
const G := preload("res://scripts/visuals/visual_geometry.gd")
const BLUEPRINTS := {
	"shelter": {"wood": 4, "metal": 0, "work": 60.0, "shelter": 5},
	"depot": {"wood": 4, "metal": 1, "work": 70.0, "shelter": 0},
	"housing": {"wood": 10, "metal": 2, "work": 90.0, "shelter": 10},
	"workshop": {"wood": 8, "metal": 4, "work": 100.0, "shelter": 0}
}
const SIZE := Vector3(12, 7, 10)
var sim: Node
var projects: Array[Dictionary] = []
var active: Dictionary = {}
var visuals: Dictionary = {}
var workshop_count := 0
var _retry_at := 0.0
var site_reason := ""
var pending_intent: Dictionary = {}
var site_planner := SitePlanner.new()

func configure(controller: Node) -> void:
	sim = controller
	site_planner.configure(controller)

func count(kind: String) -> int:
	var total := 0
	for project in projects:
		if project.kind == kind and project.state == "COMPLETE": total += 1
	return total

func consider(state: Dictionary) -> void:
	if sim.founder_mode:
		consider_founding(state)
		return
	if not active.is_empty() or sim.seconds < _retry_at: return
	if minf(state.food_days, state.water_days) < 2 or state.urgent > maxi(3, int(state.population * 0.25)):
		if not pending_intent.is_empty(): _set_pending(String(pending_intent.get("kind", "")), "BLOCKED", "Expansion paused while food/water reserves or urgent needs are below the safe threshold", 60.0)
		return
	if state.population >= 150:
		if not pending_intent.is_empty(): _set_pending(String(pending_intent.get("kind", "")), "BLOCKED", "Supported population limit reached", 60.0)
		return
	# Finite reserve horizon restrains expansion as sources approach exhaustion.
	if not carrying_capacity(int(state.population) + 5):
		if not pending_intent.is_empty(): _set_pending(String(pending_intent.get("kind", "")), "BLOCKED", "Finite food/water reserves cannot support another expansion cohort", 60.0)
		return
	var kind := ""
	if workshop_count == 0 and count("housing") >= 1: kind = "workshop"
	elif state.shelter - state.population <= 5: kind = "housing"
	if kind.is_empty():
		pending_intent.clear()
		site_reason = ""
		return
	if not kind.is_empty() and can_supply(kind): request(kind)
	elif not kind.is_empty():
		_set_pending(kind, "BLOCKED", "Finite safe materials cannot fund another " + kind, 60.0)
		sim.journal.record(sim.seconds, "growth_paused", site_reason, state, center(), "finite_development", preload("res://scripts/event_fact_context.gd").society(sim, state))

func consider_founding(state: Dictionary) -> void:
	if not active.is_empty() or sim.seconds < _retry_at: return
	if sim.governor.emergency:
		if not pending_intent.is_empty(): _set_pending(String(pending_intent.get("kind", "")), "BLOCKED", "Expansion paused while emergency response is active", 5.0)
		return
	var kind := ""
	if not sim.has_capability("shelter"): kind = "shelter"
	elif not sim.has_capability("storage"): kind = "depot"
	elif not sim.has_capability("workshop"): kind = "workshop"
	elif state.shelter - state.population <= sim.population.cohort_size and minf(state.food_days, state.water_days) >= 2 and carrying_capacity(int(state.population) + 1): kind = "housing"
	if kind.is_empty():
		pending_intent.clear()
		site_reason = ""
		return
	if can_supply(kind): request(kind)
	else:
		_set_pending(kind, "BLOCKED", "Finite safe materials cannot fund another " + kind, 60.0)
		sim.journal.record(sim.seconds, "growth_paused", site_reason, state, center(), "finite_development", preload("res://scripts/event_fact_context.gd").society(sim, state))

func _set_pending(kind: String, lifecycle_status: String, blocker: String, retry_delay: float) -> void:
	if kind.is_empty(): return
	var previous: Dictionary = pending_intent
	var same_intent := String(previous.get("kind", "")) == kind
	var retries := int(previous.get("retry_count", 0)) + 1
	var bounded_delay := clampf(retry_delay * pow(2.0, minf(float(retries - 1), 4.0)), 5.0, 60.0)
	var history: Array = previous.get("status_history", []).duplicate(true) if same_intent else [{"lifecycle_status":"PLANNING", "at":sim.seconds}]
	if history.is_empty() or String(history[-1].get("lifecycle_status", "")) != lifecycle_status:
		history.append({"lifecycle_status":lifecycle_status, "at":sim.seconds})
	pending_intent = {"kind":kind, "lifecycle_status":lifecycle_status, "blocker":blocker, "retry_at":sim.seconds + bounded_delay, "retry_in_seconds":bounded_delay, "retry_count":retries, "retryable":true, "status_history":history.duplicate(true), "work_progress":0.0, "work_required":float(BLUEPRINTS[kind].work)}
	_retry_at = float(pending_intent.retry_at)
	site_reason = blocker

func _set_project_status(project: Dictionary, lifecycle_status: String, blocker: String = "", retry_at: float = -1.0) -> void:
	var previous := String(project.get("lifecycle_status", ""))
	var previous_blocker := String(project.get("blocker", ""))
	project.lifecycle_status = lifecycle_status
	project.blocker = blocker
	if retry_at >= 0.0: project.retry_at = retry_at
	project.updated_at = sim.seconds
	if previous != lifecycle_status:
		var history: Array = project.get("status_history", [])
		history.append({"lifecycle_status":lifecycle_status, "at":sim.seconds, "blocker":blocker})
		project.status_history = history
	elif previous_blocker != blocker and not project.get("status_history", []).is_empty():
		project.status_history[-1].blocker = blocker
	_refresh_project_label(project)

func _fundable(needed: Dictionary, project_id: String = "") -> bool:
	var totals := {"wood":float(sim.economy.available.get("wood", 0.0)), "metal":float(sim.economy.available.get("metal", 0.0))}
	for bundle in sim.resources.bundles.values():
		if totals.has(bundle.resource): totals[bundle.resource] += float(bundle.amount)
	for ticket in sim.economy.tickets.values():
		if String(ticket.owner) == project_id and ticket.resource in totals and ticket.state in ["reserved", "in_transit"]:
			totals[ticket.resource] += float(ticket.amount)
	var shortage := {"wood":maxf(0.0, float(needed.get("wood", 0.0)) - float(totals.wood)), "metal":maxf(0.0, float(needed.get("metal", 0.0)) - float(totals.metal))}
	if shortage.values().all(func(amount: Variant) -> bool: return float(amount) <= 0.00001): return true
	for candidate in sim.governor.candidates(sim, shortage):
		var state: Dictionary = sim.salvage.objects[String(candidate.id)]
		for index in range(int(state.stage), state.stages.size()):
			var yields: Dictionary = state.stages[index].yields
			for resource in shortage: shortage[resource] = maxf(0.0, float(shortage[resource]) - float(yields.get(resource, 0.0)))
		if shortage.values().all(func(amount: Variant) -> bool: return float(amount) <= 0.00001): return true
	return false

func can_supply(kind: String) -> bool:
	if not BLUEPRINTS.has(kind): return false
	return _fundable({"wood":float(BLUEPRINTS[kind].wood), "metal":float(BLUEPRINTS[kind].metal)})

func carrying_capacity(population: int) -> bool:
	for resource in ["food", "water"]:
		var total: float = sim.economy.available[resource]
		for source in sim.resources.sources.values(): total += float(source.remaining.get(resource, 0))
		if total < population * (2 if resource == "food" else 3) * 5: return false
	return true

func center() -> Vector3:
	if sim.founder_mode:
		var at: Array = sim.room_definition.start.origin
		return Vector3(float(at[0]), float(at[1]), float(at[2]))
	var result := Vector3.ZERO
	var landmarks: Dictionary = sim.room_definition.landmarks
	for at in landmarks.values(): result += Vector3(float(at[0]), float(at[1]), float(at[2]))
	return result / landmarks.size()

func obstacle(site: Vector3, id: String) -> Dictionary:
	return {"id": id, "kind": "settlement", "position": [site.x, site.y, site.z], "dimensions": [SIZE.x, SIZE.y, SIZE.z], "blocks_navigation": true, "navigation_padding": [0, 0, 0]}

func valid_site(site: Vector3, work_target: Vector3 = Vector3.INF) -> bool:
	var nav: Node = sim.coordinator.navigation
	var footprint := Rect2(Vector2(site.x - SIZE.x / 2 - 4, site.z - SIZE.z / 2 - 4), Vector2(SIZE.x + 8, SIZE.z + 8))
	if not nav.room_bounds().encloses(footprint): return false
	for object in nav.room_definition.objects:
		if float(object.position[1]) > site.y + 2 or object.kind == "rug": continue
		var angle := deg_to_rad(float(object.get("rotation_degrees", 0)))
		var half := Vector2(absf(cos(angle)) * float(object.dimensions[0]) / 2 + absf(sin(angle)) * float(object.dimensions[2]) / 2, absf(sin(angle)) * float(object.dimensions[0]) / 2 + absf(cos(angle)) * float(object.dimensions[2]) / 2)
		var occupied := Rect2(Vector2(float(object.position[0]), float(object.position[2])) - half, half * 2)
		if footprint.intersects(occupied): return false
	for project in projects:
		if site.distance_to(project.site) < 22: return false
	if sim.construction.project_created and site.distance_to(sim.construction.site_position) < 18: return false
	var anchors: Array[Vector3] = [sim.coordinator.depot_station, sim.coordinator.housing_station, sim.coordinator.work_area_station]
	anchors.append_array(sim.coordinator.workshop_stations)
	anchors.append_array(sim.coordinator.patrol_stations)
	for slot in range(sim.needs.rest_capacity): anchors.append(nav.nearest_walkable_position(sim.coordinator.housing_station + Vector3(-16 + (slot % 6) * 4, 0, 16 + (slot / 6) * 4)))
	for source in sim.resources.sources.values():
		if source.region == "FLOOR": anchors.append(source.position)
	for anchor in anchors:
		if footprint.has_point(Vector2(anchor.x, anchor.z)): return false
	var proposed: Dictionary = nav.room_definition.duplicate(true)
	proposed.objects.append(obstacle(site, "proposed_development"))
	var candidate := FloorNavigation.new()
	candidate.configure(proposed)
	candidate.refresh_navigation()
	var valid := true
	var target := work_target if work_target.is_finite() else site + Vector3(0, 0, SIZE.z / 2 + 4)
	if not candidate.is_walkable(target) or candidate.is_obstacle_position(target): valid = false
	for anchor in anchors:
		if candidate.path_between(sim.coordinator.depot_station, anchor).is_empty(): valid = false
	for citizen in sim.world_citizens():
		if citizen.global_position.y < site.y + 2 and footprint.has_point(Vector2(citizen.global_position.x, citizen.global_position.z)): valid = false
	if candidate.path_between(sim.coordinator.depot_station, target).is_empty(): valid = false
	candidate.free()
	return valid

func select_site(kind: String = "") -> Dictionary:
	if sim.founder_mode: return site_planner.preview(kind)
	var origin := center()
	var positions: Array[Vector3] = []
	for x in range(-9, 10):
		for z in range(-9, 10): positions.append(origin + Vector3(x * 16, 0, z * 16))
	positions.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		var da := a.distance_squared_to(origin)
		var db := b.distance_squared_to(origin)
		return da < db if da != db else (a.z < b.z if a.z != b.z else a.x < b.x))
	for site in positions:
		if valid_site(site): return {"valid": true, "position": site}
	return {"valid": false}

func request(kind: String) -> bool:
	if not BLUEPRINTS.has(kind) or not active.is_empty(): return false
	if sim.founder_mode:
		if kind == "depot" and not sim.has_capability("shelter"): return false
		if kind == "workshop" and not sim.has_capability("storage"): return false
		if kind == "housing" and not sim.has_capability("workshop"): return false
	var previous_intent := pending_intent.duplicate(true)
	var same_intent := String(previous_intent.get("kind", "")) == kind
	var planning_history: Array = previous_intent.get("status_history", []).duplicate(true) if same_intent else []
	if planning_history.is_empty() or String(planning_history[-1].get("lifecycle_status", "")) != "PLANNING": planning_history.append({"lifecycle_status":"PLANNING", "at":sim.seconds})
	pending_intent = {"kind":kind, "lifecycle_status":"PLANNING", "blocker":"Searching for a safe connected build site", "retry_at":sim.seconds, "retry_count":int(previous_intent.get("retry_count", 0)) if same_intent else 0, "retryable":true, "status_history":planning_history}
	var selected: Dictionary = site_planner.select(kind) if sim.founder_mode else select_site(kind)
	if not selected.valid:
		# A passing citizen or temporary route conflict never causes displacement.
		_set_pending(kind, "WAITING_FOR_SITE", String(selected.get("reason", "No safe connected build site; expansion paused")), 5.0 if sim.founder_mode else 15.0)
		sim.journal.record(sim.seconds, "growth_paused", site_reason, sim.status(), null, "", preload("res://scripts/event_fact_context.gd").society(sim, sim.status()))
		return false
	var blueprint: Dictionary = BLUEPRINTS[kind]
	var id := "%s_development_%03d" % [sim.instance_id, projects.size() + 1]
	active = {"id": id, "kind": kind, "site": selected.position, "target": selected.get("target", selected.position + Vector3(0, 0, SIZE.z / 2 + 4)), "required": {"wood": blueprint.wood, "metal": blueprint.metal}, "delivered": {"wood": 0.0, "metal": 0.0}, "work": 0.0, "required_work": float(blueprint.work) * (0.85 if workshop_count > 0 else 1.0), "state": "PLANNED", "stage":"FOUNDATION", "lifecycle_status":"PLANNING", "blocker":"", "retry_at":0.0, "status_history":pending_intent.status_history.duplicate(true), "last_progress_at":sim.seconds, "retry_count":0, "effect_applied": false, "created": sim.seconds, "completed": -1.0, "work_by_citizen": {}, "delivery_distance": 0.0}
	projects.append(active)
	pending_intent.clear()
	_retry_at = 0.0
	site_reason = ""
	_set_project_status(active, "WAITING_FOR_MATERIALS", "Materials have not been delivered")
	render(active)
	sim.journal.record(sim.seconds, "development_started", kind.capitalize() + " project " + id, active, active.site, id + ":started", preload("res://scripts/event_fact_context.gd").society(sim, active))
	active.state = "WAITING_FOR_MATERIALS"
	return true

func shortage() -> Dictionary:
	var missing := {"wood": 0.0, "metal": 0.0}
	if active.is_empty(): return missing
	for resource in missing:
		var pending := 0.0
		for ticket in sim.economy.tickets.values():
			if ticket.owner == active.id and ticket.resource == resource and ticket.state in ["reserved", "in_transit"]: pending += float(ticket.amount)
		missing[resource] = maxf(0, float(active.required[resource]) - float(active.delivered[resource]) - pending - float(sim.economy.available[resource]))
	return missing

func status_snapshot() -> Dictionary:
	if not active.is_empty():
		_refresh_active_status()
		return _status_record(active)
	if not pending_intent.is_empty():
		var pending := pending_intent.duplicate(true)
		pending["project_id"] = ""
		pending["work_percent"] = 0.0
		pending["retry_in_seconds"] = maxf(0.0, float(pending.get("retry_at", 0.0)) - sim.seconds)
		return pending
	return {"project_id":"", "kind":"", "lifecycle_status":"IDLE", "blocker":"", "work_progress":0.0, "work_required":0.0, "work_percent":0.0, "retry_at":0.0, "retry_in_seconds":0.0, "retryable":false, "worker_count":0}

func project_status(project_id: String) -> Dictionary:
	for project in projects:
		if String(project.get("id", "")) != project_id: continue
		if not active.is_empty() and String(active.id) == project_id: _refresh_active_status()
		return _status_record(project)
	var pending := status_snapshot()
	return pending if String(pending.get("project_id", "")) == project_id else {}

func _status_record(project: Dictionary) -> Dictionary:
	var result := project.duplicate(true)
	var required := float(project.get("required_work", project.get("work_required", 0.0)))
	var progress := float(project.get("work", project.get("work_progress", 0.0)))
	result["project_id"] = String(project.get("id", ""))
	result["work_progress"] = progress
	result["work_required"] = required
	result["work_percent"] = clampf(progress / required, 0.0, 1.0) if required > 0.0 else 0.0
	result["retry_in_seconds"] = maxf(0.0, float(project.get("retry_at", 0.0)) - sim.seconds)
	result["worker_count"] = _project_worker_count(project, "CONSTRUCTION_BUILD")
	result["missing_materials"] = shortage() if not active.is_empty() and String(project.get("id", "")) == String(active.get("id", "")) else _project_missing(project)
	return result

func _project_missing(project: Dictionary) -> Dictionary:
	var result := {"wood":0.0, "metal":0.0}
	for resource in result: result[resource] = maxf(0.0, float(project.get("required", {}).get(resource, 0.0)) - float(project.get("delivered", {}).get(resource, 0.0)))
	return result

func _project_worker_count(project: Dictionary, task_type: String) -> int:
	var count := 0
	for task in sim.coordinator.tasks:
		if String(task.get("project_id", "")) == String(project.get("id", "")) and String(task.get("task_type", "")) == task_type and task.get("state", "") in ["active", "reserved"]: count += 1
	return count

func _refresh_active_status() -> void:
	if active.is_empty(): return
	if active.state == "COMPLETE":
		_set_project_status(active, "COMPLETE")
		return
	if active.state in ["FAILED", "CANCELLED", "SUPERSEDED"]:
		_set_project_status(active, String(active.state), String(active.get("blocker", "")))
		return
	var remaining := _project_missing(active)
	if float(remaining.wood) <= 0.00001 and float(remaining.metal) <= 0.00001:
		var site_blocker := _completion_blocker(active) if float(active.work) >= float(active.required_work) else ""
		if not site_blocker.is_empty():
			var retry := float(active.get("retry_at", 0.0))
			if String(active.get("lifecycle_status", "")) != "WAITING_FOR_SITE" or String(active.get("blocker", "")) != site_blocker or retry <= sim.seconds: retry = sim.seconds + 5.0
			_set_project_status(active, "WAITING_FOR_SITE", site_blocker, retry)
		elif float(active.work) > 0.0:
			_set_project_status(active, "UNDER_CONSTRUCTION")
		elif _project_worker_count(active, "CONSTRUCTION_BUILD") > 0:
			var worker_retry := float(active.get("retry_at", 0.0))
			if String(active.get("lifecycle_status", "")) != "WAITING_FOR_WORKERS": worker_retry = sim.seconds + 5.0
			_set_project_status(active, "WAITING_FOR_WORKERS", "A builder is assigned; waiting for arrival at the work site", worker_retry)
		else:
			var retry := float(active.get("retry_at", 0.0))
			if String(active.get("lifecycle_status", "")) != "WAITING_FOR_WORKERS": retry = sim.seconds + 5.0
			_set_project_status(active, "WAITING_FOR_WORKERS", "Materials delivered; waiting for a builder", retry)
		return
	var current_supply := false
	for resource in remaining:
		var committed := float(sim.economy.available.get(resource, 0.0))
		for ticket in sim.economy.tickets.values():
			if String(ticket.owner) == String(active.id) and String(ticket.resource) == resource and ticket.state in ["reserved", "in_transit"]: committed += float(ticket.amount)
		if committed > 0.0: current_supply = true
	var blocker := _material_blocker(remaining)
	if not _fundable(remaining, String(active.id)):
		var retry := float(active.get("retry_at", 0.0))
		var blocked_reason := "Finite safe materials cannot cover the remaining requirements. " + blocker
		if String(active.get("lifecycle_status", "")) != "BLOCKED" or String(active.get("blocker", "")) != blocked_reason: retry = sim.seconds + 60.0
		_set_project_status(active, "BLOCKED", blocked_reason, retry)
	elif current_supply:
		_set_project_status(active, "WAITING_FOR_DELIVERY", blocker, sim.seconds + 15.0 if String(active.get("lifecycle_status", "")) != "WAITING_FOR_DELIVERY" else float(active.get("retry_at", sim.seconds + 15.0)))
	else:
		_set_project_status(active, "WAITING_FOR_MATERIALS", blocker, sim.seconds + 60.0 if String(active.get("lifecycle_status", "")) != "WAITING_FOR_MATERIALS" else float(active.get("retry_at", sim.seconds + 60.0)))

func _material_blocker(missing: Dictionary) -> String:
	var parts: Array[String] = []
	for resource in ["wood", "metal"]:
		if float(missing.get(resource, 0.0)) > 0.00001: parts.append("%.0f %s" % [float(missing[resource]), resource])
	return "Still need " + ", ".join(parts) + "."

func _completion_blocker(project: Dictionary) -> String:
	for worker in sim.world_citizens():
		if worker.global_position.y < project.site.y + 2 and absf(worker.global_position.x - project.site.x) < SIZE.x / 2 + 0.5 and absf(worker.global_position.z - project.site.z) < SIZE.z / 2 + 0.5:
			return "Waiting for citizen %d to clear the reserved footprint" % (int(worker.citizen_id) + 1)
	if sim.founder_mode:
		if String(project.get("lifecycle_status", "")) == "WAITING_FOR_SITE" and sim.seconds < float(project.get("retry_at", 0.0)): return String(project.get("blocker", "Waiting for a clear connected completion site"))
		if not site_planner.can_complete(project):
			project.retry_at = sim.seconds + 5.0
			return "Waiting for a clear connected completion site"
	return ""

func options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if active.is_empty(): return result
	for resource in active.required:
		var pending := 0.0
		for ticket in sim.economy.tickets.values():
			if ticket.owner == active.id and ticket.resource == resource and ticket.state in ["reserved", "in_transit"]: pending += float(ticket.amount)
		if float(active.delivered[resource]) + pending < float(active.required[resource]) and sim.economy.available[resource] >= 1:
			result.append({"task_type": "CONSTRUCTION_DELIVERY", "project_id": active.id, "source": sim.coordinator.depot_station, "target": active.target, "resource": resource, "amount": 1, "picked_up": false, "urgency": 0.4})
	if active.state in ["SUPPLIED", "UNDER_CONSTRUCTION"]:
		var builders := 0
		for task in sim.coordinator.tasks:
			if task.get("project_id", "") == active.id and task.task_type == "CONSTRUCTION_BUILD" and task.state in ["active", "reserved"]: builders += 1
		if builders < 2: result.append({"task_type": "CONSTRUCTION_BUILD", "project_id": active.id, "stage": 0, "source": active.target, "target": active.target, "urgency": 0.4})
	return result

func pickup(task: Dictionary) -> bool:
	if active.is_empty() or task.project_id != active.id or not sim.economy.tickets.has(task.ticket): return false
	var ticket: Dictionary = sim.economy.tickets[task.ticket]
	return ticket.owner == active.id and ticket.resource == task.resource and ticket.amount == task.amount and sim.economy.pickup(task.ticket,active.id)

func deliver(task: Dictionary, citizen: Node3D) -> bool:
	if active.is_empty() or task.project_id != active.id or citizen.global_position.distance_to(active.target) > 1.6: return false
	if not sim.economy.tickets.has(task.ticket): return false
	var ticket: Dictionary = sim.economy.tickets[task.ticket]
	if ticket.owner != active.id or ticket.resource != task.resource or ticket.amount != task.amount: return false
	if float(active.delivered[task.resource]) + float(task.amount) > float(active.required[task.resource]): return false
	if not sim.economy.deliver(task.ticket,active.id): return false
	active.delivered[task.resource] += float(task.amount)
	active.delivery_distance += citizen.travelled_distance - float(task.pickup_travelled_distance)
	if active.delivered.wood == active.required.wood and active.delivered.metal == active.required.metal:
		active.state = "SUPPLIED"
		active.last_progress_at = sim.seconds
		sim.journal.record(sim.seconds, "materials_supplied", "Materials supplied: " + String(active.id), active, active.site, String(active.id) + ":supplied", preload("res://scripts/event_fact_context.gd").society(sim, active))
	_refresh_active_status()
	return true

func work(task: Dictionary, citizen: Node3D, effort: float) -> bool:
	if active.is_empty() or task.project_id != active.id: return true
	if active.state not in ["SUPPLIED", "UNDER_CONSTRUCTION"] or effort <= 0 or citizen.global_position.distance_to(active.target) > 1.6: return false
	active.state = "UNDER_CONSTRUCTION"
	var applied_effort := minf(effort, maxf(0.0, float(active.required_work) - float(active.work)))
	if applied_effort > 0.0:
		active.work += applied_effort
		active.work_by_citizen[citizen.citizen_id] = float(active.work_by_citizen.get(citizen.citizen_id, 0)) + applied_effort
		active.last_progress_at = sim.seconds
		_refresh_project_label(active)
	var fraction: float = active.work / active.required_work
	var stage := "SHELL" if fraction >= 0.66 else ("FRAME" if fraction >= 0.25 else "FOUNDATION")
	if stage != active.stage:
		active.stage = stage
		render(active)
	if fraction < 1:
		_set_project_status(active, "UNDER_CONSTRUCTION")
		return false
	if String(active.get("lifecycle_status", "")) == "WAITING_FOR_SITE" and sim.seconds < float(active.get("retry_at", 0.0)): return false
	var completion_blocker := _completion_blocker(active)
	if not completion_blocker.is_empty():
		var retry := float(active.get("retry_at", 0.0))
		if String(active.get("lifecycle_status", "")) != "WAITING_FOR_SITE" or String(active.get("blocker", "")) != completion_blocker or retry <= sim.seconds: retry = sim.seconds + 5.0
		_set_project_status(active, "WAITING_FOR_SITE", completion_blocker, retry)
		return false
	active.state = "COMPLETE"
	active.stage = "COMPLETE"
	active.completed = sim.seconds
	active.retryable = false
	_set_project_status(active, "COMPLETE")
	for id in sim.economy.tickets.keys():
		if sim.economy.tickets[id].owner == active.id: sim.economy.consume(id, active.id, true)
	apply_effect(active)
	sim.coordinator.navigation.room_definition.objects.append(obstacle(active.site, active.id))
	sim.coordinator.navigation.refresh_navigation()
	# All existing routes must adapt to the new physical footprint.
	for worker in sim.world_citizens():
		if worker.state in ["TRAVEL", "CARRY"]: worker.replan_current_route()
	render(active)
	sim.journal.record(sim.seconds, "structure_complete", active.kind.capitalize() + " complete: " + String(active.id), active, active.site, String(active.id) + ":complete", preload("res://scripts/event_fact_context.gd").society(sim, active))
	active = {}
	pending_intent.clear()
	return true

func cancel_active(reason: String, terminal_status: String = "CANCELLED") -> bool:
	if active.is_empty() or terminal_status not in ["CANCELLED", "FAILED", "SUPERSEDED"]: return false
	var project_id := String(active.id)
	var affected: Dictionary = {}
	var task_ids: Array[int] = []
	for task in sim.coordinator.tasks:
		if String(task.get("project_id", "")) != project_id or task.get("task_type", "") not in ["CONSTRUCTION_DELIVERY", "CONSTRUCTION_BUILD"] or task.get("state", "") not in ["active", "reserved"]: continue
		task_ids.append(int(task.id))
	for task_id in task_ids:
		var task: Dictionary = sim.coordinator._find_task(task_id)
		var citizen_id := int(task.get("citizen_id", -1))
		if sim.coordinator.cancel_task(task_id, reason): affected[citizen_id] = task_id
	for citizen_id in affected:
		var citizen: Node3D = sim.citizen_for(int(citizen_id))
		if is_instance_valid(citizen): citizen.cancel_task_and_resume(int(affected[citizen_id]))
	for ticket_id in sim.economy.tickets.keys():
		if String(sim.economy.tickets[ticket_id].owner) == project_id: sim.economy.release(int(ticket_id), project_id)
	active.state = terminal_status
	active.finished_at = sim.seconds
	active.retryable = terminal_status == "FAILED"
	_set_project_status(active, terminal_status, reason)
	render(active)
	active = {}
	_retry_at = sim.seconds + 5.0 if terminal_status == "FAILED" else sim.seconds
	if terminal_status == "FAILED": _set_pending(String(projects[-1].kind), "FAILED", reason, 5.0)
	else: pending_intent.clear()
	return true

func fail_active(reason: String) -> bool:
	return cancel_active(reason, "FAILED")

func supersede_active(reason: String) -> bool:
	return cancel_active(reason, "SUPERSEDED")

func apply_effect(project: Dictionary) -> void:
	if project.effect_applied or project.state != "COMPLETE": return
	project.effect_applied = true
	if int(BLUEPRINTS[project.kind].shelter) > 0:
		sim.needs.shelter_capacity += int(BLUEPRINTS[project.kind].shelter)
		sim.needs.rest_capacity += 5 if project.kind == "shelter" else 2
		if sim.founder_mode and project.kind == "shelter": sim.coordinator.housing_station = project.target
		var housed := 0
		for citizen in sim.citizens:
			citizen.needs.sheltered = citizen.life_state == "ALIVE" and housed < sim.needs.shelter_capacity
			if citizen.life_state == "ALIVE": housed += 1
		sim.journal.record(sim.seconds, "shelter_increased", "Shelter capacity increased to %d" % sim.needs.shelter_capacity, {"project": project.id, "shelter": sim.needs.shelter_capacity}, project.site, String(project.id) + ":shelter", preload("res://scripts/event_fact_context.gd").society(sim, {"project": project.id, "shelter": sim.needs.shelter_capacity}))
	elif project.kind == "workshop":
		workshop_count = mini(workshop_count + 1, 1)
		if sim.founder_mode: sim.journal.record(sim.seconds, "advanced_available", "Workshop enables advanced construction", {}, project.site, "advanced", preload("res://scripts/event_fact_context.gd").society(sim, {}))

func render(project: Dictionary) -> void:
	var id := String(project.id)
	if visuals.has(id): visuals[id].free()
	var root := Node3D.new()
	root.name = id
	sim.scene.add_child(root)
	root.position = project.site
	root.set_meta("civilization_id", sim.instance_id)
	root.set_meta("module", project.kind)
	root.set_meta("stage", project.stage)
	root.set_meta("project_id", id)
	root.set_meta("inspectable_type", "building" if project.state == "COMPLETE" else "project")
	visuals[id] = root
	_add_project_label(root, project)
	if project.kind in ["shelter", "depot"]:
		render_primitive(root, project)
		return
	# The 12x10-inch reserved site is a yard, not a seven-inch-tall dollhouse.
	# Human-facing openings are sized for the actual half-inch citizen mesh.
	var person: float = preload("res://scripts/citizen_agent.gd").BODY_HEIGHT
	var floor_height := person * 1.8
	var floors := 2 if project.kind == "housing" else 1
	var wall_height := floor_height * floors
	var base := 0.08
	var front := 1.0
	var back := -3.0
	G.box(root, "Foundation", Vector3(12, base, 10), Vector3(0, base / 2, 0), "stone", Color("83715c"), 0.02)
	G.box(root, "AssemblyWorkpiece", Vector3(0.6, 0.2, 0.6), project.target - project.site + Vector3(0, 0.1, -0.35), "wood", Color("ac8053"), 0.04)
	# Edge strips show the real reserved footprint while the small building sits inside.
	var outline := _outline_color(project)
	for x in [-5.85, 5.85]: G.box(root, "YardEdge", Vector3(0.18, 0.10, 9.7), Vector3(x, 0.08, 0), "paint", outline, 0.01)
	for z in [-4.85, 4.85]: G.box(root, "YardEdge", Vector3(11.7, 0.10, 0.18), Vector3(0, 0.08, z), "paint", outline, 0.01)
	if project.stage == "FOUNDATION": return
	for x in [-3.9, -1.3, 1.3, 3.9]:
		for z in [back, front]: G.box(root, "Post", Vector3(0.10, wall_height, 0.10), Vector3(x, base + wall_height / 2, z), "wood", Color("b18956"), 0.01)
	for level in range(1, floors + 1):
		for z in [back, front]: G.box(root, "Beam", Vector3(8, 0.10, 0.12), Vector3(0, base + floor_height * level, z), "wood", Color("9b774d"), 0.01)
	if project.stage == "FRAME": return
	var paint := Color("8d694b") if project.kind == "housing" else Color("507278")
	G.box(root, "Back", Vector3(8, wall_height, 0.10), Vector3(0, base + wall_height / 2, back), "wood", paint, 0.01)
	for x in [-3.95, 3.95]: G.box(root, "Side", Vector3(0.10, wall_height, 4), Vector3(x, base + wall_height / 2, -1), "wood", paint, 0.01)
	if floors == 2: G.box(root, "UpperFloor", Vector3(8, 0.06, 4), Vector3(0, base + floor_height, -1), "wood", Color("9b774d"), 0.01)
	if project.stage == "SHELL": return
	G.box(root, "FrontPanel", Vector3(8, wall_height, 0.10), Vector3(0, base + wall_height / 2, front), "wood", paint, 0.01)
	# 0.70-inch doors are 1.4 citizen heights; floor-to-floor is 1.8 heights.
	for x in [-2.8, 0.0, 2.8]:
		G.box(root, "Door", Vector3(person * 0.72, person * 1.4, 0.04), Vector3(x, base + person * 0.7, front + 0.07), "wood", Color("443c32"), 0.006)
		G.box(root, "DoorLintel", Vector3(0.44, 0.045, 0.07), Vector3(x, base + person * 1.4, front + 0.08), "wood", Color("c7a46e"), 0.005)
		G.box(root, "Threshold", Vector3(0.48, 0.045, 0.24), Vector3(x, base, front + 0.18), "stone", Color("ac9979"), 0.008)
	for level in range(floors):
		for x in [-3.5, -2.1, -0.7, 0.7, 2.1, 3.5]:
			G.box(root, "Window", Vector3(0.32, 0.30, 0.025), Vector3(x, base + floor_height * level + 0.53, front + 0.065), "glass", Color("e0ba6a"), 0.008)
	var roof_y := base + wall_height + 0.14
	for side in [-1, 1]:
		var roof := G.box(root, "Roof", Vector3(8.4, 0.10, 2.25), Vector3(0, roof_y, -1 + side * 1.02), "metal", Color("47646a"), 0.01)
		roof.rotation.x = side * deg_to_rad(12)
	if project.kind == "workshop": G.box(root, "Chimney", Vector3(0.30, 0.65, 0.30), Vector3(2.8, roof_y + 0.3, -1.8), "metal", Color("697d7f"), 0.01)

func render_primitive(root: Node3D, project: Dictionary) -> void:
	# The initial outline marks the proposed site; structural geometry appears
	# only after supplied materials and actual builder effort advance the stage.
	var outline := _outline_color(project)
	for x in [-4.0,4.0]: G.box(root, "SiteOutlineX%d" % roundi(x), Vector3(0.20, 0.04, 4), Vector3(x, 0.04, -1), "paint", outline, 0.005)
	for z in [-3.0,1.0]: G.box(root, "SiteOutlineZ%d" % roundi(z), Vector3(8, 0.04, 0.20), Vector3(0, 0.04, z), "paint", outline, 0.005)
	G.box(root, "AssemblyWorkpiece", Vector3(0.6, 0.2, 0.6), project.target - project.site + Vector3(0, 0.1, -0.35), "wood", Color("ac8053"), 0.03)
	if project.stage == "FOUNDATION": return
	G.box(root, "GroundFrame", Vector3(8, 0.06, 4), Vector3(0, 0.03, -1), "wood", Color("a58154"), 0.01)
	for x in [-3.9, 3.9]:
		for z in [-2.9, 0.9]: G.box(root, "HandCutPost", Vector3(0.10, 0.95, 0.10), Vector3(x, 0.5, z), "wood", Color("aa895d"), 0.01)
	if project.stage == "FRAME": return
	G.box(root, "Back", Vector3(8, 0.9, 0.08), Vector3(0, 0.5, -2.9), "wood", Color("97714b"), 0.01)
	if project.stage == "SHELL": return
	var roof := G.box(root, "LeanToRoof", Vector3(8.3, 0.08, 4.3), Vector3(0, 1.05, -1), "wood", Color("71563d"), 0.01)
	roof.rotation.x = deg_to_rad(8)
	if project.kind == "shelter":
		for index in range(5): G.box(root, "SleepingPlace", Vector3(0.45, 0.07, 0.8), Vector3(-2.8 + index * 1.3, 0.13, -1), "canvas", Color("8a785d"), 0.01)
	else:
		for index in range(3): G.box(root, "StorageRack", Vector3(2, 0.6, 1.2), Vector3(-2.7 + index * 2.7, 0.36, -1), "wood", Color("a78550"), 0.02)


func _outline_color(project: Dictionary) -> Color:
	match String(project.get("lifecycle_status", "")):
		"BLOCKED", "FAILED": return Color("ff665d")
		"WAITING_FOR_SITE": return Color("e97543")
		"UNDER_CONSTRUCTION": return Color("56d5cb")
		"COMPLETE": return Color("9ecb74")
		"WAITING_FOR_MATERIALS", "WAITING_FOR_DELIVERY": return Color("f0c05d")
		_: return Color("f3eaa2")


func _add_project_label(root: Node3D, project: Dictionary) -> void:
	var label := Label3D.new()
	label.name = "ProjectStatusLabel"
	label.position = Vector3(0.0, 2.15, -1.0)
	label.font_size = 24
	label.pixel_size = 0.065
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("fff2d1")
	label.outline_size = 7
	label.outline_modulate = Color("171c1d")
	root.add_child(label)
	if project.state == "COMPLETE":
		label.hide()
		return
	_refresh_project_label(project)


func _refresh_project_label(project: Dictionary) -> void:
	var root: Node3D = visuals.get(String(project.get("id", "")))
	if not is_instance_valid(root): return
	var label := root.get_node_or_null("ProjectStatusLabel") as Label3D
	if label == null: return
	var progress := clampf(float(project.get("work", 0.0)) / maxf(0.001, float(project.get("required_work", 1.0))), 0.0, 1.0)
	var lifecycle := String(project.get("lifecycle_status", project.get("state", "PLANNED"))).replace("_", " ")
	var lines: Array[String] = ["%s · %s" % [String(project.get("kind", "project")).capitalize(), lifecycle], "%s · %.0f%%" % [String(project.get("stage", "PLANNED")).replace("_", " "), progress * 100.0]]
	var blocker := String(project.get("blocker", ""))
	if not blocker.is_empty() and project.state != "COMPLETE": lines.append(blocker)
	label.text = "\n".join(lines)
	label.modulate = _outline_color(project)
