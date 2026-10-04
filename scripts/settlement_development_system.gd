extends RefCounted
## Real settlement projects reuse production delivery/build tasks and economy tickets.
const FloorNavigation := preload("res://scripts/floor_navigation.gd")
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

func configure(controller: Node) -> void: sim = controller

func count(kind: String) -> int:
	var total := 0
	for project in projects:
		if project.kind == kind and project.state == "COMPLETE": total += 1
	return total

func consider(state: Dictionary) -> void:
	if sim.founder_mode:
		consider_founding(state)
		return
	if not active.is_empty() or sim.seconds < _retry_at or minf(state.food_days, state.water_days) < 2 or state.urgent > maxi(3, int(state.population * 0.25)): return
	if state.population >= 150: return
	# Finite reserve horizon restrains expansion as sources approach exhaustion.
	if not carrying_capacity(int(state.population) + 5): return
	var kind := ""
	if workshop_count == 0 and count("housing") >= 1: kind = "workshop"
	elif state.shelter - state.population <= 5: kind = "housing"
	if not kind.is_empty() and can_supply(kind): request(kind)
	elif not kind.is_empty():
		_retry_at = sim.seconds + 60
		site_reason = "Finite safe materials cannot fund another " + kind
		sim.journal.record(sim.seconds, "growth_paused", site_reason, state, center(), "finite_development")

func consider_founding(state: Dictionary) -> void:
	if not active.is_empty() or sim.seconds < _retry_at or sim.governor.emergency: return
	var kind := ""
	if not sim.has_capability("shelter"): kind = "shelter"
	elif not sim.has_capability("storage"): kind = "depot"
	elif not sim.has_capability("workshop"): kind = "workshop"
	elif state.shelter - state.population <= sim.population.cohort_size and minf(state.food_days, state.water_days) >= 2 and carrying_capacity(int(state.population) + 1): kind = "housing"
	if kind.is_empty(): return
	if can_supply(kind): request(kind)
	else:
		_retry_at = sim.seconds + 60
		site_reason = "Finite safe materials cannot fund another " + kind
		sim.journal.record(sim.seconds, "growth_paused", site_reason, state, center(), "finite_development")

func can_supply(kind: String) -> bool:
	var totals := {"wood": float(sim.economy.available.wood), "metal": float(sim.economy.available.metal)}
	for bundle in sim.resources.bundles.values():
		if totals.has(bundle.resource): totals[bundle.resource] += float(bundle.amount)
	for candidate in sim.governor.candidates(sim, BLUEPRINTS[kind]):
		var state: Dictionary = sim.salvage.objects[candidate.id]
		for index in range(int(state.stage), state.stages.size()):
			for resource in totals: totals[resource] += float(state.stages[index].yields.get(resource, 0))
	return totals.wood >= BLUEPRINTS[kind].wood and totals.metal >= BLUEPRINTS[kind].metal

func carrying_capacity(population: int) -> bool:
	for resource in ["food", "water"]:
		var total: float = sim.economy.available[resource]
		for source in sim.resources.sources.values(): total += float(source.remaining.get(resource, 0))
		if total < population * (2 if resource == "food" else 3) * 5: return false
	return true

func center() -> Vector3:
	if sim.founder_mode:
		var at: Array = sim.scene.get("_room_definition").start.origin
		return Vector3(float(at[0]), float(at[1]), float(at[2]))
	var result := Vector3.ZERO
	var landmarks: Dictionary = sim.scene.get("_room_definition").landmarks
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
	for citizen in sim.citizens:
		if citizen.global_position.y < site.y + 2 and footprint.has_point(Vector2(citizen.global_position.x, citizen.global_position.z)): valid = false
	if candidate.path_between(sim.coordinator.depot_station, target).is_empty(): valid = false
	candidate.free()
	return valid

func select_site(kind: String = "") -> Dictionary:
	var origin := center()
	# Build storage around the original pickup apron. Existing goods and in-flight
	# deliveries retain their physical location; no inventory is relocated.
	var depot_site: Vector3 = sim.coordinator.depot_station - Vector3(0, 0, SIZE.z / 2 + 4)
	if sim.founder_mode and kind == "depot":
		return {"valid": true, "position": depot_site} if valid_site(depot_site, depot_site + Vector3(SIZE.x / 2 + 4, 0, 0)) else {"valid": false}
	var positions: Array[Vector3] = []
	for x in range(-9, 10):
		for z in range(-9, 10): positions.append(origin + Vector3(x * 16, 0, z * 16))
	positions.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		var da := a.distance_squared_to(origin)
		var db := b.distance_squared_to(origin)
		return da < db if da != db else (a.z < b.z if a.z != b.z else a.x < b.x))
	for site in positions:
		if sim.founder_mode and count("depot") == 0 and site.distance_to(depot_site) < 22: continue
		if sim.founder_mode and kind == "shelter" and count("depot") == 0:
			# The first shelter creates housing/rest anchors. Reserve the depot's
			# future clear apron for these anchors as well as for building footprints;
			# otherwise a completed shelter can make the fixed bootstrap depot
			# permanently invalid even though both sites were initially legal.
			var depot_apron := Rect2(Vector2(depot_site.x - SIZE.x / 2 - 4, depot_site.z - SIZE.z / 2 - 4), Vector2(SIZE.x + 8, SIZE.z + 8))
			var housing_target := site + Vector3(0, 0, SIZE.z / 2 + 4)
			var blocks_depot := depot_apron.has_point(Vector2(housing_target.x, housing_target.z))
			for slot in range(5):
				var rest_target: Vector3 = sim.coordinator.navigation.nearest_walkable_position(housing_target + Vector3(-16 + (slot % 6) * 4, 0, 16 + (slot / 6) * 4))
				if depot_apron.has_point(Vector2(rest_target.x, rest_target.z)): blocks_depot = true
			if blocks_depot: continue
		if valid_site(site): return {"valid": true, "position": site}
	return {"valid": false}

func request(kind: String) -> bool:
	if not BLUEPRINTS.has(kind) or not active.is_empty(): return false
	if sim.founder_mode:
		if kind == "depot" and not sim.has_capability("shelter"): return false
		if kind == "workshop" and not sim.has_capability("storage"): return false
		if kind == "housing" and not sim.has_capability("workshop"): return false
	_retry_at = sim.seconds + 60
	var selected := select_site(kind)
	if not selected.valid:
		# A passing founder may temporarily occupy the bootstrap footprint. Retry
		# at the next governor evaluation, without moving citizens or relaxing safety.
		if sim.founder_mode and kind in ["shelter","depot","workshop"]: _retry_at = sim.seconds + 5
		site_reason = "No safe connected build site; expansion paused"
		sim.journal.record(sim.seconds, "growth_paused", site_reason, sim.status())
		return false
	var blueprint: Dictionary = BLUEPRINTS[kind]
	var id := "development_%03d" % (projects.size() + 1)
	active = {"id": id, "kind": kind, "site": selected.position, "target": selected.position + Vector3(0, 0, SIZE.z / 2 + 4), "required": {"wood": blueprint.wood, "metal": blueprint.metal}, "delivered": {"wood": 0.0, "metal": 0.0}, "work": 0.0, "required_work": float(blueprint.work) * (0.85 if workshop_count > 0 else 1.0), "state": "PLANNED", "stage": "FOUNDATION", "effect_applied": false, "created": sim.seconds, "completed": -1.0, "work_by_citizen": {}, "delivery_distance": 0.0}
	projects.append(active)
	if sim.founder_mode and kind == "depot":
		# Stock remains on the front apron; building deliveries go to the side.
		active.target = active.site + Vector3(SIZE.x / 2 + 4, 0, 0)
	render(active)
	sim.journal.record(sim.seconds, "development_started", kind.capitalize() + " project " + id, active, active.site, id + ":started")
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
	return ticket.owner == active.id and ticket.resource == task.resource and ticket.amount == task.amount and sim.economy.pickup(task.ticket)

func deliver(task: Dictionary, citizen: Node3D) -> bool:
	if active.is_empty() or task.project_id != active.id or citizen.global_position.distance_to(active.target) > 1.6: return false
	if not sim.economy.tickets.has(task.ticket): return false
	var ticket: Dictionary = sim.economy.tickets[task.ticket]
	if ticket.owner != active.id or ticket.resource != task.resource or ticket.amount != task.amount: return false
	if float(active.delivered[task.resource]) + float(task.amount) > float(active.required[task.resource]): return false
	if not sim.economy.deliver(task.ticket): return false
	active.delivered[task.resource] += float(task.amount)
	active.delivery_distance += citizen.travelled_distance - float(task.pickup_travelled_distance)
	if active.delivered.wood == active.required.wood and active.delivered.metal == active.required.metal:
		active.state = "SUPPLIED"
		sim.journal.record(sim.seconds, "materials_supplied", "Materials supplied: " + String(active.id), active, active.site, String(active.id) + ":supplied")
	return true

func work(task: Dictionary, citizen: Node3D, effort: float) -> bool:
	if active.is_empty() or task.project_id != active.id: return true
	if active.state not in ["SUPPLIED", "UNDER_CONSTRUCTION"] or effort <= 0 or citizen.global_position.distance_to(active.target) > 1.6: return false
	active.state = "UNDER_CONSTRUCTION"
	active.work += effort
	active.work_by_citizen[citizen.citizen_id] = float(active.work_by_citizen.get(citizen.citizen_id, 0)) + effort
	var fraction: float = active.work / active.required_work
	var stage := "SHELL" if fraction >= 0.66 else ("FRAME" if fraction >= 0.25 else "FOUNDATION")
	if stage != active.stage:
		active.stage = stage
		render(active)
	if fraction < 1: return false
	# Citizens are never displaced to make room for a completed footprint.
	for worker in sim.citizens:
		if worker.global_position.y < active.site.y + 2 and absf(worker.global_position.x - active.site.x) < SIZE.x / 2 + 0.5 and absf(worker.global_position.z - active.site.z) < SIZE.z / 2 + 0.5: return false
	active.state = "COMPLETE"
	active.stage = "COMPLETE"
	active.completed = sim.seconds
	for id in sim.economy.tickets.keys():
		if sim.economy.tickets[id].owner == active.id: sim.economy.consume(id, true)
	apply_effect(active)
	sim.coordinator.navigation.room_definition.objects.append(obstacle(active.site, active.id))
	sim.coordinator.navigation.refresh_navigation()
	# All existing routes must adapt to the new physical footprint.
	for worker in sim.citizens:
		if worker.state in ["TRAVEL", "CARRY"]: worker.replan_current_route()
	render(active)
	sim.journal.record(sim.seconds, "structure_complete", active.kind.capitalize() + " complete: " + String(active.id), active, active.site, String(active.id) + ":complete")
	active = {}
	return true

func apply_effect(project: Dictionary) -> void:
	if project.effect_applied or project.state != "COMPLETE": return
	project.effect_applied = true
	if int(BLUEPRINTS[project.kind].shelter) > 0:
		sim.needs.shelter_capacity += int(BLUEPRINTS[project.kind].shelter)
		sim.needs.rest_capacity += 5 if project.kind == "shelter" else 2
		if sim.founder_mode and project.kind == "shelter": sim.coordinator.housing_station = project.target
		for citizen in sim.citizens: citizen.needs.sheltered = citizen.citizen_id < sim.needs.shelter_capacity
		sim.journal.record(sim.seconds, "shelter_increased", "Shelter capacity increased to %d" % sim.needs.shelter_capacity, {"project": project.id, "shelter": sim.needs.shelter_capacity}, project.site, String(project.id) + ":shelter")
	elif project.kind == "workshop":
		workshop_count = mini(workshop_count + 1, 1)
		if sim.founder_mode: sim.journal.record(sim.seconds, "advanced_available", "Workshop enables advanced construction", {}, project.site, "advanced")

func render(project: Dictionary) -> void:
	var id := String(project.id)
	if visuals.has(id): visuals[id].free()
	var root := Node3D.new()
	root.name = id
	sim.scene.add_child(root)
	root.position = project.site
	root.set_meta("module", project.kind)
	root.set_meta("stage", project.stage)
	visuals[id] = root
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
	for x in [-5.85, 5.85]: G.box(root, "YardEdge", Vector3(0.12, 0.10, 9.7), Vector3(x, 0.08, 0), "stone", Color("a39178"), 0.01)
	for z in [-4.85, 4.85]: G.box(root, "YardEdge", Vector3(11.7, 0.10, 0.12), Vector3(0, 0.08, z), "stone", Color("a39178"), 0.01)
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
	for x in [-4.0,4.0]: G.box(root, "SiteOutline", Vector3(0.03, 0.02, 4), Vector3(x, 0.02, -1), "paint", Color("c8b88b"), 0.005)
	for z in [-3.0,1.0]: G.box(root, "SiteOutline", Vector3(8, 0.02, 0.03), Vector3(0, 0.02, z), "paint", Color("c8b88b"), 0.005)
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
