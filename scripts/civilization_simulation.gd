extends Node
## Fixed production tick, autonomous self-care, and civilization state integration.

const Needs := preload("res://scripts/need_system.gd")
const Economy := preload("res://scripts/economy_system.gd")
const HUD := preload("res://scripts/civilization_ui.gd")
const Planner := preload("res://scripts/civilization_planner.gd")
const Resources := preload("res://scripts/resource_system.gd")
const Salvage := preload("res://scripts/salvage_system.gd")
const FloorNavigation := preload("res://scripts/floor_navigation.gd")
const G := preload("res://scripts/visuals/visual_geometry.gd")
const Journal := preload("res://scripts/event_journal.gd")
const Governor := preload("res://scripts/autonomous_governor.gd")
const Development := preload("res://scripts/settlement_development_system.gd")
const Population := preload("res://scripts/population_system.gd")
const CameraDirector := preload("res://scripts/fishbowl_camera_director.gd")
var camera_director: Node
var journal := Journal.new()
var governor := Governor.new()
var development: RefCounted
var population: RefCounted
const STEP := 0.1
var needs := Needs.new()
var economy := Economy.new()
var planner := Planner.new()
var resources := Resources.new()
var salvage := Salvage.new()
var bundle_visuals: Dictionary = {}
var salvage_targets: Dictionary = {}
var haul_pickups := 0
var haul_deliveries := 0
var source_visits := {"food": 0, "water": 0}
var _planner_timer := 0.0
var reach_requested: Dictionary = {}
var scene: Node3D
var coordinator: Node
var construction: Node
var citizens: Array = []
var seconds := 0.0
var speed := 1.0
var _accumulator := 0.0
var self_care_completed := {}
var hud: Control
var spectator: Control
var founder_mode := false

func has_capability(capability: String) -> bool:
	var initial: Array = scene.get("_room_definition").get("start", {}).get("infrastructure", ["workshop", "depot", "housing", "work_area"])
	match capability:
		"shelter": return "housing" in initial or development.count("shelter") + development.count("housing") > 0
		"storage": return "depot" in initial or development.count("depot") > 0
		"workshop", "advanced_construction": return "workshop" in initial or development.count("workshop") > 0
	return false

func configure(world: Node3D, config: Dictionary) -> void:
	scene = world
	coordinator = scene.get_node("TaskCoordinator")
	construction = scene.get_node("ConstructionSystem")
	citizens = scene.get("_citizens")
	founder_mode = scene.get("_room_definition").has("start") and scene.get("_room_definition").start.infrastructure.is_empty()
	needs.shelter_capacity = int(config.get("shelter_capacity", 50))
	needs.rest_capacity = mini(needs.shelter_capacity, int(config.get("rest_capacity", 12)))
	economy.configure(config.get("stock", {"food": 5000, "water": 5000, "wood": 0, "metal": 0}))
	if bool(config.get("economy_construction", false)): construction.economy = economy
	if founder_mode: construction.stockpile = {"wood":0,"metal":0,"mechanical_parts":0}
	coordinator.civilization = self
	governor.enabled = OS.get_environment("ROOMSCALE_FISHBOWL") == "1"
	speed = float(config.get("initial_speed", 10.0 if governor.enabled else 1.0))
	if governor.enabled:
		governor.mode = "OBSERVING"
		governor.reason = "Evaluating civilization state every five simulation seconds"
	development = Development.new()
	development.configure(self)
	population = Population.new()
	population.cohort_size = int(config.get("cohort_size", 5))
	if founder_mode:
		journal.record(0, "founders_arrived", "Founders arrived", {"population": citizens.size()}, coordinator.depot_station, "founders")
	resources.configure(scene.get("_room_definition"))
	salvage.configure(resources.objects)
	for object_id in salvage.objects:
		var object: Dictionary = resources.objects[object_id].data
		var at: Array = object.position
		var dims: Array = object.dimensions
		var angle := deg_to_rad(float(object.get("rotation_degrees", 0)))
		var extent_z := absf(sin(angle)) * float(dims[0]) * 0.5 + absf(cos(angle)) * float(dims[2]) * 0.5
		salvage_targets[object_id] = coordinator.navigation.nearest_walkable_position(Vector3(float(at[0]), float(at[1]), float(at[2]) + extent_z + 8))
	construction.set_process(false)
	for citizen in citizens:
		citizen.needs = needs.initial(citizen.citizen_id)
		citizen.set_process(false)
	hud = HUD.new()
	scene.get_node("Overlay").add_child(hud)
	hud.configure(self)
	if governor.enabled:
		camera_director = CameraDirector.new()
		camera_director.name = "FishbowlCameraDirector"
		scene.add_child(camera_director)
		camera_director.configure(self)
		hud.configure_fishbowl()
		hud.hide()
		spectator = preload("res://scripts/fishbowl_hud.gd").new()
		scene.get_node("Overlay").add_child(spectator)
		spectator.configure(self)
		print("ROOMSCALE_FISHBOWL_READY governor=true population=%d camera=%s room=%s speed=%s" % [citizens.size(), camera_director.enabled, scene.get("_room_definition").id, speed])
	print("ROOMSCALE_CIVILIZATION_READY speed=%s governor=%s spectator=%s" % [speed, governor.enabled, spectator != null])
	scene.get_node("Overlay/PresentationPanel").hide()
	scene.get_node("Overlay/PresentationStatus").hide()

func _process(delta: float) -> void:
	advance_elapsed_time(delta)

func advance_elapsed_time(delta: float) -> void:
	advance(delta * speed)

func advance(delta: float) -> void:
	_accumulator += delta
	while _accumulator + 0.000001 >= STEP:
		_accumulator -= STEP
		step()

func step() -> void:
	seconds += STEP
	governor.tick(self)
	_planner_timer += STEP
	if _planner_timer >= 1:
		_planner_timer = 0
		plan()
	for citizen in citizens:
		needs.decay(citizen.needs, STEP, citizen.task_type == "NEED_REST" and citizen.state == "WORK")
		citizen.advance_simulation(STEP)
	construction.advance_simulation(STEP)

func claim(citizen: Node3D) -> Dictionary:
	var ordinary_score := -INF
	for task in coordinator.tasks:
		if task.state == "available": ordinary_score = maxf(ordinary_score, planner.score(String(task.task_type), 0, citizen.global_position.distance_to(task.target)))
	var urgent := "water" if float(citizen.needs.water) >= float(citizen.needs.food) else "food"
	var care_kind := "NEED_DRINK" if urgent == "water" else "NEED_EAT"
	if float(citizen.needs[urgent]) >= 0.6 and planner.score(care_kind, float(citizen.needs[urgent]), citizen.global_position.distance_to(coordinator.depot_station)) > ordinary_score:
		var ticket := economy.reserve(urgent, 1, "citizen:%d" % citizen.citizen_id)
		if ticket > 0:
			planner.record(care_kind)
			return coordinator.create_construction_task({"task_type": care_kind, "source": coordinator.depot_station, "target": coordinator.depot_station, "resource": urgent, "ticket": ticket}, citizen.citizen_id)
	if float(citizen.needs.fatigue) >= 0.7 and planner.score("NEED_REST", float(citizen.needs.fatigue), 0) > ordinary_score:
		var slot := needs.reserve_rest(citizen.citizen_id)
		if slot >= 0:
			citizen.needs.rest_slot = slot
			planner.record("NEED_REST")
			var target: Vector3 = development.site_planner.rest_target(slot)
			return coordinator.create_construction_task({"task_type": "NEED_REST", "source": target, "target": target, "slot": slot}, citizen.citizen_id)
	var choices := work_options(citizen)
	var best: Dictionary = {}
	var best_score := ordinary_score
	for option in choices:
		var value := planner.score(String(option.task_type), float(option.get("urgency", 0.1)), citizen.global_position.distance_to(option.source))
		if value > best_score:
			best_score = value
			best = option
	if not best.is_empty():
		if best.task_type == "BUNDLE_HAUL" and not resources.reserve_bundle(int(best.bundle_id), citizen.citizen_id): return {}
		if best.task_type == "CONSTRUCTION_DELIVERY":
			var ticket := economy.reserve(String(best.resource), float(best.amount), String(best.get("project_id", "traversal")))
			if ticket < 0: return {}
			best.ticket = ticket
		if best.task_type == "RESOURCE_COLLECT" and not resources.reserve_source(String(best.source_id), String(best.resource), float(best.amount)): return {}
		planner.record(String(best.task_type))
		return coordinator.create_construction_task(best, citizen.citizen_id)
	return {}

func work_options(citizen: Node3D) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	options.append_array(development.options())
	if construction.economy != null and construction.project_created and not construction.traversal_deployed:
		for resource in ["wood", "metal"]:
			var outstanding := 0.0
			for ticket in economy.tickets.values():
				if ticket.owner == "traversal" and ticket.resource == resource and ticket.state in ["reserved", "in_transit"]: outstanding += float(ticket.amount)
			if float(construction.delivered[resource]) + outstanding < float(construction.requirements()[resource]) and float(economy.available[resource]) >= 1:
				options.append({"task_type": "CONSTRUCTION_DELIVERY", "source": construction.depot_pickup, "target": construction.site_position, "resource": resource, "amount": 1, "picked_up": false, "urgency": 0.8})
		if construction._active_stage >= 0 and construction.active_builder_count() < 2:
			options.append({"task_type": "CONSTRUCTION_BUILD", "source": construction.site_position, "target": construction.site_position, "stage": construction._active_stage, "urgency": 0.8})
	for source_id in resources.sources:
		var source: Dictionary = resources.sources[source_id]
		for resource in source.remaining:
			var target_stock := citizens.size() * (2 if resource == "food" else 3) * 3.0
			var pending := 0.0
			var collectors := 0
			for task in coordinator.tasks:
				if task.task_type == "RESOURCE_COLLECT" and task.resource == resource and task.state in ["active", "reserved"]:
					collectors += 1
					pending += float(task.amount)
			if collectors >= 8 or float(economy.available[resource]) + pending >= target_stock: continue
			if resource != "food" and not planner.directives.has(resource): continue
			if resources.source_available(source_id, resource) < 1: continue
			var route: Dictionary = coordinator.surface_navigation.route_between(region_of(citizen.global_position), String(source.region), citizen.global_position, source.position)
			if not route.reachable: continue
			options.append({"task_type": "RESOURCE_COLLECT", "source_id": source_id, "resource": resource, "amount": minf(8, resources.source_available(source_id, resource)), "source": source.position, "target": source.position, "source_region": source.region, "urgency": 0.9 if economy.forecast(resource, citizens.size()) < 1 else 0.35, "extracted": false})
	for id in salvage.objects:
		var state: Dictionary = salvage.objects[id]
		if not state.authorized or salvage.depleted(id): continue
		var workers := 0
		for task in coordinator.tasks:
			if task.task_type == "SALVAGE" and task.get("object_id", "") == id and task.state in ["active", "reserved"]: workers += 1
		if workers < 3:
			var target: Vector3 = salvage_targets[id]
			options.append({"task_type": "SALVAGE", "object_id": id, "stage": int(state.stage), "source": target, "target": target, "urgency": 0.4})
	for id in resources.bundles:
		var bundle: Dictionary = resources.bundles[id]
		if bundle.state == "available": options.append({"task_type": "BUNDLE_HAUL", "bundle_id": id, "source": bundle.position, "target": coordinator.depot_station, "resource": bundle.resource, "amount": bundle.amount, "urgency": 0.5})
	return options

func plan() -> void:
	planner.reasons.clear()
	if economy.forecast("water", citizens.size()) < 1: planner.reasons.append("Water reserve critical")
	if needs.shelter_capacity < citizens.size(): planner.reasons.append("Shelter shortage: %d citizens" % (citizens.size() - needs.shelter_capacity))
	for resource in planner.directives:
		if founder_mode:
			var accessible := false
			for available_source in resources.sources.values():
				# Fractional remnants below one unit cannot be collected by work_options.
				if available_source.region == "FLOOR" and float(available_source.remaining.get(resource, 0)) >= 1: accessible = true
			if accessible: continue
		var found := false
		for source_id in resources.sources:
			var source: Dictionary = resources.sources[source_id]
			if resources.source_available(source_id, resource) <= 0: continue
			found = true
			if source.region != "FLOOR" and not coordinator.surface_navigation.has_connection("FLOOR", String(source.region)):
				planner.reasons.append("Secure %s: source unreachable; traversal required" % String(resource).capitalize())
				if has_capability("advanced_construction") and not reach_requested.has(source.region):
					var result: Dictionary = coordinator.issue_reach_explore(String(source.region), citizens)
					if result.get("accepted", false):
						reach_requested[source.region] = true
						print("POC4_RESOURCE_REACH resource=%s source=%s region=%s" % [resource, source_id, source.region])
			break
		if not found: planner.reasons.append("No known undepleted %s source" % resource)
	if construction.economy != null and construction.project_created and construction._completed_stages < 3:
		for resource in ["wood", "metal"]:
			var missing := float(construction.requirements()[resource]) - float(construction.delivered[resource]) - economy.state_total(resource, "reserved") - economy.state_total(resource, "in_transit")
			if missing > float(economy.available[resource]):
				planner.reasons.append("Traversal waiting for %.0f %s" % [missing - float(economy.available[resource]), resource])
				var authorized := false
				for id in salvage.objects:
					if salvage.objects[id].authorized and not salvage.depleted(id): authorized = true
				if not authorized: planner.reasons.append("No authorized %s salvage source" % resource)

func work(citizen: Node3D, delta: float) -> bool:
	var task: Dictionary = coordinator.get_task(citizen.task_id)
	if citizen.global_position.distance_to(task.target) > 1.6: return false
	if citizen.task_type == "SALVAGE":
		var id := String(task.object_id)
		if distance_to_object(id, citizen.global_position) > 1.8: return false
		if int(task.stage) != int(salvage.objects[id].stage): return true
		var yields := salvage.work(id, int(task.stage), delta * needs.work_factor(citizen.needs), citizen.global_position, task.target)
		if yields.is_empty(): return false
		for resource in yields:
			var bundle := resources.create_bundle(resource, float(yields[resource]), task.target, id)
			show_bundle(bundle)
		apply_salvage_stage(id)
		if founder_mode: journal.record(seconds, "first_salvage", "First material recovered", {"object":id,"yields":yields}, citizen.global_position, "first_salvage")
		print("POC4_SALVAGE_STAGE object=%s state=%s work=%.1f yields=%s" % [id, salvage.objects[id].state, salvage.objects[id].work, yields])
		return true
	if citizen.task_type == "RESOURCE_COLLECT":
		if citizen._work_timer < float(resources.sources[task.source_id].work): return false
		var stored: Dictionary = coordinator._find_task(citizen.task_id)
		if stored.extracted: return false
		var bundle := resources.extract(String(task.source_id), String(task.resource), float(task.amount), citizen.global_position)
		if bundle < 0: return false
		stored.extracted = true
		stored.bundle_id = bundle
		resources.reserve_bundle(bundle, citizen.citizen_id)
		show_bundle(bundle)
		if not pickup_bundle(citizen): return false
		source_visits[task.resource] += 1
		if founder_mode and String(resources.sources[task.source_id].region) != "FLOOR": journal.record(seconds, "territory_reached", "Elevated resources reached", {"source":task.source_id}, citizen.global_position, "territory_reached")
		citizen.begin_resource_return(String(task.resource))
		return false
	if citizen.task_type == "NEED_REST":
		if citizen._work_timer < 15 or float(citizen.needs.fatigue) > 0.15: return false
		needs.release_rest(int(task.slot), true)
		citizen.needs.rest_slot = -1
	else:
		if citizen._work_timer < 1: return false
		if not economy.consume(int(task.ticket)): return false
		needs.satisfy(citizen.needs, String(task.resource))
	self_care_completed[citizen.citizen_id] = int(self_care_completed.get(citizen.citizen_id, 0)) + 1
	return true

func release(task: Dictionary) -> void:
	if task.has("ticket"):
		var dropped := economy.drop(int(task.ticket))
		if not dropped.is_empty():
			var at: Vector3 = citizens[int(task.citizen_id)].global_position
			show_bundle(resources.create_bundle(String(dropped.resource), float(dropped.amount), at, "interrupted_delivery"))
		else: economy.release(int(task.ticket))
	if task.has("slot"):
		needs.release_rest(int(task.slot), false)
		citizens[int(task.citizen_id)].needs.rest_slot = -1
	if task.has("bundle_id"):
		var citizen: Node3D = citizens[int(task.citizen_id)]
		resources.release_bundle(int(task.bundle_id), citizen.citizen_id, citizen.global_position)
		show_bundle(int(task.bundle_id))
	if task.task_type == "RESOURCE_COLLECT" and not task.get("extracted", false): resources.release_source(String(task.source_id), String(task.resource), float(task.amount))

func should_interrupt(citizen: Node3D) -> bool:
	return maxf(float(citizen.needs.food), float(citizen.needs.water)) >= 0.7 or float(citizen.needs.fatigue) >= 0.8

func status() -> Dictionary:
	var urgent := 0
	for citizen in citizens:
		if maxf(float(citizen.needs.food), float(citizen.needs.water)) >= 0.7: urgent += 1
	return {"days": seconds / Needs.DAY_SECONDS, "population": citizens.size(), "food_days": economy.forecast("food", citizens.size()), "water_days": economy.forecast("water", citizens.size()), "shelter": needs.shelter_capacity, "resting": needs.resting.size(), "urgent": urgent, "meals": needs.meals, "drinks": needs.drinks, "rests": needs.rests, "economy": economy.snapshot()}

func secure_resource(resource: String) -> bool:
	return planner.secure(resource)

func authorize_salvage(object_id: String) -> bool:
	var candidates := salvage_approaches(object_id)
	if candidates.is_empty() or not salvage.authorize(object_id): return false
	coordinator.navigation.allow_object_edge_access(object_id)
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(coordinator.depot_station) < b.distance_to(coordinator.depot_station))
	salvage_targets[object_id] = candidates[0]
	planner.authorized[object_id] = true
	return true

func salvage_approaches(object_id: String) -> Array[Vector3]:
	if not resources.objects.has(object_id) or not resources.objects[object_id].profile.harvestable: return []
	var object: Dictionary = resources.objects[object_id].data
	if object.has("surface"):
		var region := String(object.surface.region_id)
		if coordinator.surface_navigation.has_connection("FLOOR", region): return []
		for source in resources.sources.values():
			if source.region == region: return []
	# Validate the proposed padding change off the live grid. Rejection must leave
	# protection, obstacle geometry and every live grid cell untouched.
	var proposed_navigation := FloorNavigation.new()
	proposed_navigation.configure(coordinator.navigation.room_definition)
	proposed_navigation.allow_object_edge_access(object_id)
	var dims: Array = object.dimensions
	var origin := Vector3(float(object.position[0]), float(object.position[1]), float(object.position[2]))
	var angle := deg_to_rad(float(object.get("rotation_degrees", 0)))
	var local_points: Array[Vector3] = [Vector3(0, 0, float(dims[2]) * 0.5 + 0.22), Vector3(0, 0, -float(dims[2]) * 0.5 - 0.22), Vector3(float(dims[0]) * 0.5 + 0.22, 0, 0), Vector3(-float(dims[0]) * 0.5 - 0.22, 0, 0)]
	var candidates: Array[Vector3] = []
	for point in local_points:
		var at := origin + point.rotated(Vector3.UP, angle)
		if proposed_navigation.room_bounds().has_point(Vector2(at.x, at.z)) and not proposed_navigation.is_obstacle_position(at) and not proposed_navigation.path_between(coordinator.depot_station, at).is_empty(): candidates.append(at)
	proposed_navigation.free()
	return candidates

func distance_to_object(id: String, position: Vector3) -> float:
	var object: Dictionary = resources.objects[id].data
	var origin := Vector3(float(object.position[0]), float(object.position[1]), float(object.position[2]))
	var local := (position - origin).rotated(Vector3.UP, -deg_to_rad(float(object.get("rotation_degrees", 0))))
	return Vector2(maxf(0, absf(local.x) - float(object.dimensions[0]) * 0.5), maxf(0, absf(local.z) - float(object.dimensions[2]) * 0.5)).length()

func pickup_bundle(citizen: Node3D) -> bool:
	var task: Dictionary = coordinator._find_task(citizen.task_id)
	if not resources.pickup_bundle(int(task.bundle_id), citizen.citizen_id, citizen.global_position): return false
	task.pickup_distance = citizen.travelled_distance
	if bundle_visuals.has(int(task.bundle_id)): bundle_visuals[int(task.bundle_id)].hide()
	haul_pickups += 1
	return true

func deliver_bundle(citizen: Node3D) -> bool:
	var task: Dictionary = coordinator.get_task(citizen.task_id)
	var path: Array[Vector3] = coordinator.navigation.path_between(task.source, task.target)
	var required_distance := float(task.get("haul_route_length", coordinator._path_length(path)))
	if citizen.travelled_distance - float(task.get("pickup_distance", citizen.travelled_distance)) < required_distance * 0.9: return false
	if not resources.deliver_bundle(int(task.bundle_id), citizen.citizen_id, citizen.global_position, coordinator.depot_station, economy): return false
	if bundle_visuals.has(int(task.bundle_id)):
		bundle_visuals[int(task.bundle_id)].queue_free()
		bundle_visuals.erase(int(task.bundle_id))
	haul_deliveries += 1
	return true

func show_bundle(id: int) -> void:
	if not resources.bundles.has(id): return
	var bundle: Dictionary = resources.bundles[id]
	if not bundle_visuals.has(id):
		var root := Node3D.new()
		root.name = "ResourceBundle%d" % id
		scene.add_child(root)
		var color := Color("aa794b") if bundle.resource == "wood" else Color("91b0b4")
		G.box(root, "Bundle", Vector3(0.8, 0.3, 0.5), Vector3(0, 0.15, 0), "wood" if bundle.resource == "wood" else "iron", color, 0.03)
		bundle_visuals[id] = root
	bundle_visuals[id].global_position = bundle.position
	bundle_visuals[id].show()

func apply_salvage_stage(id: String) -> void:
	var root := scene.get_room_object(id) as Node3D
	if root == null: return
	for child in root.get_children():
		if child is Node3D: child.hide()
		if child is CollisionObject3D: child.collision_layer = 0
	var state: Dictionary = salvage.objects[id]
	root.set_meta("salvage_state", state.state)
	if salvage.depleted(id):
		if governor.enabled: journal.record(seconds, "object_depleted", "Object depleted: " + id, state, root.global_position, "depleted:" + id)
		coordinator.navigation.remove_object_obstacle(id)
		coordinator.surface_navigation.remove_object_surface(id)
		root.hide()
		return
	var object: Dictionary = resources.objects[id].data
	var dims: Array = object.dimensions
	var d := Vector3(float(dims[0]), float(dims[1]), float(dims[2]))
	var stage_root := root.get_node_or_null("SalvageStage") as Node3D
	if stage_root != null: stage_root.free()
	stage_root = Node3D.new()
	stage_root.name = "SalvageStage"
	root.add_child(stage_root)
	var height := d.y * (0.53 if String(object.kind) == "chair" else 0.9)
	var legs := 4 if int(state.stage) == 1 else 2
	for index in range(legs):
		var x := -1 if index % 2 == 0 else 1
		var z := -1 if index < 2 else 1
		G.box(stage_root, "RemainingLeg%d" % index, Vector3(d.x * 0.06, height, d.z * 0.06), Vector3(x * d.x * 0.4, height * 0.5, z * d.z * 0.35), "wood", Color("6a5140"), 0.1)
	if int(state.stage) <= 2:
		G.box(stage_root, "RemainingPanel", Vector3(d.x * (1 if int(state.stage) == 1 else 0.45), d.y * 0.05, d.z * 0.8), Vector3(0, height, 0), "wood", Color("947151"), 0.12)
	else:
		G.box(stage_root, "RemainingBrace", Vector3(d.x * 0.8, d.y * 0.04, d.z * 0.05), Vector3(0, height * 0.35, -d.z * 0.35), "wood", Color("6a5140"), 0.1)
		coordinator.surface_navigation.remove_object_surface(id)
		var local_center := Vector3(0, 0, -d.z * 0.35)
		var world_center := root.global_position + local_center.rotated(Vector3.UP, root.rotation.y)
		coordinator.navigation.update_object_footprint(id, world_center, Vector3(d.x * 0.86, d.y, d.z * 0.06))

func routine_score(task: Dictionary, citizen_id: int) -> float:
	var citizen: Node3D = citizens[citizen_id]
	return planner.score(String(task.task_type), 0, citizen.global_position.distance_to(task.target))

func region_of(position: Vector3) -> String:
	for id in coordinator.surface_navigation.regions:
		if id == "FLOOR": continue
		var region: Dictionary = coordinator.surface_navigation.regions[id]
		var local: Vector3 = (position - region.center).rotated(Vector3.UP, -deg_to_rad(float(region.rotation_degrees)))
		if absf(position.y - float(region.height)) < 1.0 and absf(local.x) <= float(region.dimensions.x) * 0.5 and absf(local.z) <= float(region.dimensions.y) * 0.5: return id
	return "FLOOR"

func route_for(citizen: Node3D, destination: Vector3) -> Array[Vector3]:
	var task: Dictionary = coordinator.get_task(citizen.task_id)
	var end_region := region_of(destination)
	if citizen.task_type == "RESOURCE_COLLECT" and not citizen.carrying: end_region = String(task.source_region)
	var route: Dictionary = coordinator.surface_navigation.route_between(region_of(citizen.global_position), end_region, citizen.global_position, destination)
	var path: Array[Vector3] = []
	if route.reachable: path.assign(route.path)
	if citizen.carrying and task.has("bundle_id"):
		coordinator._find_task(citizen.task_id)["haul_route_length"] = coordinator._path_length(path)
	return path
