extends RefCounted
## Strategic player replacement. Never assigns, moves or performs citizen work.
const INTERVAL := 5.0
const CRITICAL_DAYS := 1.0
const RECOVERY_DAYS := 2.0
const HOLD_SECONDS := 30.0
var enabled := false
var mode := "DISABLED"
var reason := "Manual strategic control"
var emergency := false
var evaluations := 0
var _next := 5.0
var _changed := -1000.0
var rejections: Dictionary = {}

func crisis(state: Dictionary, now: float) -> bool:
	if minf(float(state.food_days), float(state.water_days)) < CRITICAL_DAYS: emergency = true
	elif emergency and now - _changed >= HOLD_SECONDS and minf(float(state.food_days), float(state.water_days)) >= RECOVERY_DAYS: emergency = false
	return emergency

func transition(sim: Node, next_mode: String, why: String, state: Dictionary) -> void:
	if mode != next_mode:
		mode = next_mode
		_changed = sim.seconds
		sim.journal.record(sim.seconds, "governor", next_mode + ": " + why, state)
	reason = why

func tick(sim: Node) -> void:
	if not enabled or sim.seconds + 0.001 < _next: return
	_next = sim.seconds + INTERVAL
	evaluations += 1
	var state: Dictionary = sim.status()
	if sim.construction.project_created:
		sim.journal.record(sim.seconds, "traversal_complete" if sim.construction.traversal_deployed else "traversal_started", "Traversal complete" if sim.construction.traversal_deployed else "Traversal project started", sim.construction.status(), sim.construction.site_position, "traversal_state")
	for id in sim.resources.sources:
		var source: Dictionary = sim.resources.sources[id]
		for resource in source.remaining:
			if float(source.remaining[resource]) <= 0: sim.journal.record(sim.seconds, "source_exhausted", "Finite source exhausted: " + String(id) + " / " + resource, source, source.position, "exhausted:" + String(id) + ":" + resource)
	var danger := crisis(state, sim.seconds)
	for resource in ["food", "water"]:
		if float(state[resource + "_days"]) < RECOVERY_DAYS and not sim.planner.directives.has(resource):
			sim.secure_resource(resource)
			sim.journal.record(sim.seconds, "directive", "Secure " + resource.capitalize(), state, sim.coordinator.depot_station, "directive:" + resource)
	var shortage := {"wood": 0.0, "metal": 0.0}
	if sim.construction.project_created and not sim.construction.traversal_deployed:
		for resource in shortage:
			shortage[resource] = maxf(0, float(sim.construction.requirements()[resource]) - float(sim.construction.delivered[resource]) - sim.economy.state_total(resource, "reserved") - sim.economy.state_total(resource, "in_transit") - float(sim.economy.available[resource]))
	if sim.get("development") != null:
		var development_shortage: Dictionary = sim.development.shortage()
		for resource in shortage: shortage[resource] += float(development_shortage[resource])
	sim.planner.set_priority("Survival", 4 if danger else 3)
	sim.planner.set_priority("Resources", 3)
	sim.planner.set_priority("Construction", 3)
	sim.planner.set_priority("Exploration", 1)
	if float(shortage.wood) + float(shortage.metal) > 0:
		transition(sim, "MATERIALS", "Approved project needs wood/metal: " + str(shortage), state)
		authorize_safe_salvage(sim, shortage)
	elif danger:
		transition(sim, "SURVIVAL", "Reserve below safety threshold; development restrained", state)
	else:
		transition(sim, "STABLE", "Reserves recovered; assess shelter and finite carrying capacity", state)
		if sim.get("development") != null: sim.development.consider(state)
	if sim.get("population") != null: sim.population.evaluate(sim, state, danger, float(shortage.wood) + float(shortage.metal) > 0)

func candidates(sim: Node, shortage: Dictionary) -> Array[Dictionary]:
	var ranked: Array[Dictionary] = []
	rejections.clear()
	for id in sim.salvage.objects:
		var entry: Dictionary = sim.resources.objects[id]
		var object: Dictionary = entry.data
		var state: Dictionary = sim.salvage.objects[id]
		var rejection := ""
		if sim.salvage.depleted(id): rejection = "depleted"
		elif object.kind == "settlement": rejection = "settlement infrastructure"
		elif bool(object.get("resource_profile", {}).get("protected", false)): rejection = "explicitly protected"
		elif not entry.profile.contents.is_empty(): rejection = "finite resource source"
		elif object.has("surface"):
			var region := String(object.surface.region_id)
			if sim.coordinator.surface_navigation.has_connection("FLOOR", region) or region == sim.construction.target_region and sim.construction.project_created: rejection = "active traversal support"
			for source in sim.resources.sources.values():
				if source.region == region: rejection = "resource source support"
		if not rejection.is_empty():
			rejections[id] = rejection
			continue
		if sim.salvage_approaches(String(id)).is_empty():
			rejections[id] = "inaccessible to real workers"
			continue
		var useful := 0.0
		var cost := 0.0
		for index in range(int(state.stage), state.stages.size()):
			var stage: Dictionary = state.stages[index]
			cost += float(stage.work)
			for resource in shortage: useful += minf(float(shortage[resource]), float(stage.yields.get(resource, 0)))
		if useful <= 0:
			rejections[id] = "no useful shortage yield"
			continue
		var position := Vector3(float(object.position[0]), float(object.position[1]), float(object.position[2]))
		var score := useful * 100 - position.distance_to(sim.coordinator.depot_station) * 0.1 - cost * 0.2 - (50 if object.has("surface") else 0)
		ranked.append({"id": id, "score": score, "focus": position})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score if a.score != b.score else String(a.id) < String(b.id))
	return ranked

func authorize_safe_salvage(sim: Node, shortage: Dictionary) -> void:
	# Do not authorize another object while already approved yields are outstanding.
	for id in sim.salvage.objects:
		if sim.salvage.objects[id].authorized and not sim.salvage.depleted(id): return
	for bundle in sim.resources.bundles.values():
		if float(shortage.get(bundle.resource, 0)) > 0: return
	for candidate in candidates(sim, shortage):
		if sim.salvage.objects[candidate.id].authorized: continue
		if sim.authorize_salvage(String(candidate.id)):
			sim.journal.record(sim.seconds, "salvage_authorized", "Safe salvage authorized: " + String(candidate.id), {"shortage": shortage, "score": candidate.score, "rejections": rejections}, candidate.focus, "salvage:" + String(candidate.id))
			return
		rejections[candidate.id] = "workers cannot reach a valid physical edge"
