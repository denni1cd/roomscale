extends Node
## M4 project inventory, verified deliveries, and work-driven component construction.

const RoomDefinitionLoader := preload("res://scripts/room_definition.gd")
const GrappleDetails := preload("res://scripts/visuals/grapple_details.gd")
const G := preload("res://scripts/visuals/visual_geometry.gd")
const Materials := preload("res://scripts/visuals/material_library.gd")

signal project_updated(status: Dictionary)

const RESOURCE_ORDER := ["wood", "metal", "mechanical_parts"]
const REQUIRED := {"wood": 4, "metal": 4, "mechanical_parts": 3}
const STAGES := [
	{"name": "base", "required": {"wood": 2, "metal": 1, "mechanical_parts": 0}, "work_seconds": 4.0},
	{"name": "winch", "required": {"wood": 3, "metal": 3, "mechanical_parts": 1}, "work_seconds": 5.0},
	{"name": "launcher", "required": {"wood": 4, "metal": 4, "mechanical_parts": 3}, "work_seconds": 6.0},
]

var coordinator: Node
var navigation: Node
var surface_navigation: Node
var citizens: Array = []
var scene_root: Node3D
var room_definition: Dictionary = {}
var site_position := Vector3.ZERO
var depot_pickup := Vector3.ZERO
var target_region := ""
var target_anchor := Vector3.ZERO
var stockpile := {"wood": 4, "metal": 4, "mechanical_parts": 3}
var delivered := {"wood": 0, "metal": 0, "mechanical_parts": 0}
var picked_up := {"wood": 0, "metal": 0, "mechanical_parts": 0}
var project_state := "AWAITING_BARRIER"
var project_created := false
var traversal_deployed := false
var traversal_arrival: Dictionary = {}
var _active_stage := -1
var _completed_stages := 0
var _stage_work := 0.0
var _delivery_citizen_ids: Dictionary = {}
var _construction_worker_ids: Dictionary = {}
var _stage_gate_snapshots: Array[Dictionary] = []
var _visuals: Dictionary = {}
var _site_root: Node3D
var _deployment_segments: Array[MeshInstance3D] = []
var _deployment_anchor: MeshInstance3D
var _deployment_timer := 0.0
var _deployment_cursor := 0
var _deployment_path: Array[Vector3] = []
var _detail_groups: Array[Node3D] = []
var _work_steam: GPUParticles3D


func configure(task_coordinator: Node, floor_navigation: Node, population: Array, scene: Node3D, definition: Dictionary) -> void:
	coordinator = task_coordinator
	navigation = floor_navigation
	citizens = population
	scene_root = scene
	room_definition = definition.duplicate(true)
	site_position = coordinator.get_construction_site()
	depot_pickup = RoomDefinitionLoader.vector3_from(room_definition.construction.depot_pickup)
	target_region = String(surface_navigation.goal_surface_id)
	var target_surface: Dictionary = surface_navigation.regions.get(target_region, {})
	target_anchor = target_surface.get("anchor", Vector3.ZERO)


func _process(delta: float) -> void:
	if not _detail_groups.is_empty():
		var progress := _stage_work / float(STAGES[_active_stage].work_seconds) if _active_stage >= 0 else 0.0
		GrappleDetails.animate(_detail_groups, _completed_stages, _active_stage, progress, project_state == "DEPLOYING_TRAVERSAL", delta)
		if is_instance_valid(_work_steam):
			_work_steam.emitting = (project_state == "DEPLOYING_TRAVERSAL") or (_active_stage >= 0 and _stage_work > 0.0)
	if _deployment_segments.is_empty() or traversal_deployed:
		return
	_deployment_timer += delta
	while _deployment_timer >= 0.18 and _deployment_cursor < _deployment_segments.size():
		_deployment_timer -= 0.18
		_deployment_segments[_deployment_cursor].visible = true
		_deployment_cursor += 1
	if _deployment_cursor >= _deployment_segments.size() and is_instance_valid(_deployment_anchor) and not _deployment_anchor.visible:
		_deployment_anchor.visible = true
	if _deployment_cursor >= _deployment_segments.size() and _deployment_timer >= 0.5:
		_finish_traversal_deployment()


func on_reach_goal_updated(goal: Dictionary) -> void:
	if goal.get("state", "") == "BARRIER_CONFIRMED" and not project_created:
		_create_project()


func has_project() -> bool:
	return project_created


func take_stock(resource: String, amount: int) -> bool:
	if not project_created or not stockpile.has(resource) or amount <= 0 or int(stockpile[resource]) < amount:
		return false
	stockpile[resource] = int(stockpile[resource]) - amount
	picked_up[resource] = int(picked_up[resource]) + amount
	_emit_update()
	return true


func accept_delivery(resource: String, amount: int, destination: Vector3) -> bool:
	if not project_created or not delivered.has(resource) or amount <= 0:
		return false
	if destination.distance_to(site_position) > 1.5:
		return false
	if int(delivered[resource]) + amount > int(REQUIRED[resource]):
		return false
	delivered[resource] = int(delivered[resource]) + amount
	_emit_update()
	_update_build_unlocks()
	return true


func can_builder_work(stage_index: int) -> bool:
	return project_created and stage_index == _active_stage and _active_stage >= 0 and _active_stage < STAGES.size()


func perform_builder_work(stage_index: int, delta: float, task_id: int = -1) -> bool:
	if not can_builder_work(stage_index) or delta <= 0.0:
		return stage_index < _active_stage
	_stage_work += delta
	var required_work: float = STAGES[stage_index].work_seconds
	if _stage_work + 0.0001 < required_work:
		_emit_update()
		return false
	_complete_component(stage_index, task_id)
	return true


func status() -> Dictionary:
	var current_stage_name := "complete" if _completed_stages >= STAGES.size() else "locked"
	var current_progress := 0.0
	if _active_stage >= 0 and _active_stage < STAGES.size():
		current_stage_name = String(STAGES[_active_stage].name)
		current_progress = clampf(_stage_work / float(STAGES[_active_stage].work_seconds), 0.0, 1.0)
	var total_progress := 100.0 if _completed_stages >= STAGES.size() else (float(_completed_stages) + current_progress) / float(STAGES.size()) * 100.0
	return {
		"created": project_created,
		"state": project_state,
		"required": REQUIRED.duplicate(true),
		"stockpile": stockpile.duplicate(true),
		"picked_up": picked_up.duplicate(true),
		"delivered": delivered.duplicate(true),
		"active_stage": current_stage_name,
		"stage_progress": current_progress,
		"completed_stages": _completed_stages,
		"stage_gates": _stage_gate_snapshots.duplicate(true),
		"progress_percent": total_progress,
		"site": site_position,
		"cable_deployed": traversal_deployed,
		"floor_target_connected": surface_navigation.has_connection("FLOOR", target_region) if is_instance_valid(surface_navigation) else false,
		"traversal": coordinator.get_traversal_goal_status(),
	}


func active_delivery_count() -> int:
	var count := 0
	for task in coordinator.tasks:
		if task.task_type == "CONSTRUCTION_DELIVERY" and task.state in ["active", "reserved"]:
			count += 1
	return count


func active_builder_count() -> int:
	var count := 0
	for task in coordinator.tasks:
		if task.task_type == "CONSTRUCTION_BUILD" and task.state in ["active", "reserved"]:
			count += 1
	return count


func _create_project() -> void:
	project_created = true
	project_state = "DELIVERING"
	_create_visible_project()
	var resource_jobs: Array[String] = [
		"wood", "wood", "metal", "wood", "metal", "mechanical_parts",
		"metal", "wood", "metal", "mechanical_parts", "mechanical_parts",
	]
	var candidates: Array[Dictionary] = []
	for citizen in citizens:
		var carrier := citizen as Node3D
		var path: Array[Vector3] = navigation.path_between(carrier.global_position, depot_pickup)
		if not path.is_empty():
			candidates.append({"citizen": carrier, "distance": _path_length(path)})
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left.distance) < float(right.distance))
	for index in range(mini(resource_jobs.size(), candidates.size())):
		var carrier: Node3D = candidates[index].citizen
		_delivery_citizen_ids[carrier.citizen_id] = true
		var resource := resource_jobs[index]
		var task: Dictionary = coordinator.create_construction_task({
			"task_type": "CONSTRUCTION_DELIVERY",
			"source": depot_pickup,
			"target": site_position,
			"resource": resource,
			"amount": 1,
			"picked_up": false,
		}, carrier.citizen_id)
		carrier.assign_project_task(task)
	_emit_update()


func _update_build_unlocks() -> void:
	if _active_stage >= 0 or _completed_stages >= STAGES.size():
		return
	var next_stage := _completed_stages
	if not _has_materials_for_stage(next_stage):
		return
	_start_build_stage(next_stage)


func _has_materials_for_stage(stage_index: int) -> bool:
	var threshold: Dictionary = STAGES[stage_index].required
	for resource in RESOURCE_ORDER:
		if int(delivered[resource]) < int(threshold[resource]):
			return false
	return true


func _start_build_stage(stage_index: int) -> void:
	if stage_index != _completed_stages or not _has_materials_for_stage(stage_index):
		return
	_active_stage = stage_index
	_stage_work = 0.0
	_stage_gate_snapshots.append(delivered.duplicate(true))
	project_state = "BUILDING_%s" % String(STAGES[stage_index].name).to_upper()
	_construction_worker_ids.clear()
	var builders := _nearest_available_builders(site_position, 2)
	for builder in builders:
		_construction_worker_ids[builder.citizen_id] = true
		var task: Dictionary = coordinator.create_construction_task({
			"task_type": "CONSTRUCTION_BUILD",
			"source": Vector3.ZERO,
			"target": site_position,
			"stage": stage_index,
			"material_gate": STAGES[stage_index].required.duplicate(true),
			"picked_up": false,
		}, builder.citizen_id)
		builder.assign_project_task(task)
	_emit_update()


func _complete_component(stage_index: int, completing_task_id: int) -> void:
	_stage_work = 0.0
	_completed_stages = stage_index + 1
	_active_stage = -1
	coordinator.cancel_construction_stage(stage_index, completing_task_id)
	_construction_worker_ids.clear()
	var components: Array = _visuals.get(String(STAGES[stage_index].name), [])
	for component in components:
		if is_instance_valid(component):
			component.visible = true
	if _completed_stages >= STAGES.size():
		project_state = "CONSTRUCTION_COMPLETE"
		_delivery_citizen_ids.clear()
		_construction_worker_ids.clear()
	else:
		project_state = "WAITING_FOR_MATERIALS"
	_emit_update()
	_update_build_unlocks()
	if _completed_stages >= STAGES.size():
		_deploy_traversal()


func _deploy_traversal() -> void:
	if traversal_deployed or not project_created or _completed_stages < STAGES.size():
		return
	if not is_instance_valid(surface_navigation) or not surface_navigation.regions.has(target_region):
		push_error("Grapple deployment blocked: target surface navigation is unavailable")
		return
	var launcher_tip := site_position + Vector3(0.0, 11.0, -1.6)
	var tower_base := site_position + Vector3(0.0, 0.6, -1.6)
	var cable_distance := launcher_tip.distance_to(target_anchor)
	var segment_count := clampi(ceili(cable_distance / 10.0), 8, 24)
	var cable_path: Array[Vector3] = [launcher_tip]
	for index in range(1, segment_count + 1):
		var ratio := float(index) / float(segment_count)
		var point := launcher_tip.lerp(target_anchor, ratio)
		point.y -= sin(PI * ratio) * minf(2.0, cable_distance * 0.025)
		cable_path.append(point)
	var surface_route: Array[Vector3] = [site_position, tower_base]
	for step in range(1, 5):
		surface_route.append(tower_base.lerp(launcher_tip, float(step) / 4.0))
	for point_index in range(1, cable_path.size()):
		var start := cable_path[point_index - 1]
		var finish := cable_path[point_index]
		var subdivisions := maxi(1, ceili(start.distance_to(finish) / 2.5))
		for substep in range(1, subdivisions + 1):
			surface_route.append(start.lerp(finish, float(substep) / float(subdivisions)))
	_deployment_path = surface_route
	_create_cable_visual(cable_path)
	project_state = "DEPLOYING_TRAVERSAL"
	_emit_update()


func _create_cable_visual(path: Array[Vector3]) -> void:
	var cable_root := Node3D.new()
	cable_root.name = "DeployedGrappleCable"
	scene_root.add_child(cable_root)
	var cable_material := _material(Color("263536"))
	_deployment_segments.clear()
	_deployment_cursor = 0
	_deployment_timer = 0.0
	for index in range(1, path.size()):
		var start := path[index - 1]
		var finish := path[index]
		var direction := finish - start
		var segment := MeshInstance3D.new()
		segment.name = "CableSegment%02d" % index
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.035
		mesh.bottom_radius = 0.035
		mesh.height = direction.length()
		segment.mesh = mesh
		segment.position = (start + finish) * 0.5
		segment.quaternion = Quaternion(Vector3.UP, direction.normalized())
		segment.material_override = cable_material
		segment.visible = false
		cable_root.add_child(segment)
		_deployment_segments.append(segment)
	_deployment_anchor = MeshInstance3D.new()
	_deployment_anchor.name = "SurfaceGrappleAnchor"
	var anchor_mesh := CylinderMesh.new()
	anchor_mesh.top_radius = 0.34
	anchor_mesh.bottom_radius = 0.34
	anchor_mesh.height = 0.24
	_deployment_anchor.mesh = anchor_mesh
	_deployment_anchor.position = path.back() + Vector3(0.0, 0.12, 0.0)
	_deployment_anchor.material_override = _material(Color("d8a64f"))
	_deployment_anchor.visible = false
	cable_root.add_child(_deployment_anchor)


func _finish_traversal_deployment() -> void:
	if not surface_navigation.connect_regions("FLOOR", target_region, _deployment_path):
		push_error("Grapple deployment blocked: generated route could not connect the selected surface.")
		return
	traversal_deployed = true
	var carriers: Array[Dictionary] = []
	for citizen in citizens:
		var climber := citizen as Node3D
		if _delivery_citizen_ids.has(climber.citizen_id) or _construction_worker_ids.has(climber.citizen_id) or climber.task_type == "CONSTRUCTION_BUILD":
			continue
		var floor_route: Array[Vector3] = navigation.path_between(climber.global_position, site_position)
		if not floor_route.is_empty():
			carriers.append({"citizen": climber, "floor_route": floor_route, "distance": _path_length(floor_route)})
	carriers.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left.distance) < float(right.distance))
	if carriers.is_empty():
		project_state = "CABLE_DEPLOYED_NO_CLIMBER"
		_emit_update()
		return
	var climber: Node3D = carriers[0].citizen
	var route: Array[Vector3] = carriers[0].floor_route.duplicate()
	if route.back().distance_to(site_position) > 0.1:
		route.append(site_position)
	for index in range(1, _deployment_path.size()):
		route.append(_deployment_path[index])
	var traversal_task: Dictionary = coordinator.create_traversal_task(climber, route)
	if traversal_task.is_empty():
		project_state = "CABLE_DEPLOYED_NO_CLIMBER"
		_emit_update()
		return
	climber.assign_traversal_task(traversal_task)
	project_state = "TRAVERSE_IN_PROGRESS"
	_emit_update()

func _nearest_available_builders(target: Vector3, count: int) -> Array[Node3D]:
	var candidates: Array[Dictionary] = []
	for citizen in citizens:
		var builder := citizen as Node3D
		if _delivery_citizen_ids.has(builder.citizen_id) or _construction_worker_ids.has(builder.citizen_id) or builder.task_type == "CONSTRUCTION_BUILD":
			continue
		var path: Array[Vector3] = navigation.path_between(builder.global_position, target)
		if not path.is_empty():
			candidates.append({"citizen": builder, "distance": _path_length(path)})
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left.distance) < float(right.distance))
	var result: Array[Node3D] = []
	for index in range(mini(count, candidates.size())):
		result.append(candidates[index].citizen as Node3D)
	return result


func _create_visible_project() -> void:
	_site_root = Node3D.new()
	_site_root.name = "GrappleConstructionSite"
	_site_root.position = site_position
	scene_root.add_child(_site_root)
	var work_light := OmniLight3D.new()
	work_light.name = "WorkLamp"
	work_light.position = Vector3(0, 2.8, 3)
	work_light.light_color = Color("f9d4a0")
	work_light.light_energy = 0.65
	work_light.omni_range = 12
	_site_root.add_child(work_light)
	var blueprint := _add_box(_site_root, "BlueprintFootprint", Vector3(12.0, 0.08, 9.0), Vector3(0.0, 0.08, 0.0), Color("56aac1", 0.55))
	var blueprint_material := blueprint.material_override as StandardMaterial3D
	blueprint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blueprint_material.albedo_color.a = 0.38
	_visuals["blueprint"] = blueprint
	# Open-frame foundation leaves the authoritative worker position visible.
	var base := _add_box(_site_root, "GrappleBase", Vector3(10.0, 0.12, 0.7), Vector3(0.0, 0.06, -3.5), Color("72533a"), false)
	var base_plate := _add_box(_site_root, "BrassBasePlate", Vector3(8.0, 0.12, 0.6), Vector3(0.0, 0.06, 3.5), Color("a88751"), false)
	var winch := _add_cylinder(_site_root, "WinchDrum", 2.4, 1.8, Vector3(0.0, 3.0, 0.0), Color("677977"), false)
	winch.rotation.x = PI * 0.5
	winch.position.y = 3.6
	var gear := _add_cylinder(_site_root, "WinchGear", 2.1, 0.45, Vector3(0.0, 3.0, 1.2), Color("d1a14e"), false)
	gear.rotation.x = deg_to_rad(90.0)
	gear.position.y = 3.6
	var launcher := _add_box(_site_root, "LauncherFrame", Vector3(1.3, 7.0, 1.3), Vector3(0.0, 5.0, -1.6), Color("4d6666"), false)
	var arm := _add_box(_site_root, "LauncherArm", Vector3(1.1, 5.0, 1.1), Vector3(0.0, 8.2, -1.6), Color("be9650"), false)
	arm.rotation.x = deg_to_rad(22.0)
	_visuals["base"] = [base, base_plate]
	_visuals["winch"] = [winch, gear]
	_visuals["launcher"] = [launcher, arm]
	_detail_groups = GrappleDetails.build(_site_root)
	scene_root.call("_add_steam_emitter", _detail_groups[1], "PressureSteam", Vector3(-3.0, 5.2, 0))
	_work_steam = _detail_groups[1].get_node("PressureSteam") as GPUParticles3D
	_work_steam.amount = 8
	_work_steam.emitting = false
	_add_world_label(_site_root, "ProjectSign", "GRAPPLE PROJECT", Vector3(0.0, 11.0, 3.0))
	_add_stockpile_visuals()


func _add_stockpile_visuals() -> void:
	var depot := scene_root.get_node("Settlement/Depot") as Node3D
	var stock := Node3D.new()
	stock.name = "ConstructionStockpile"
	var depot_position := RoomDefinitionLoader.vector3_from(room_definition.landmarks.depot)
	var pickup_offset := depot_pickup - depot_position
	stock.position = Vector3(0.0, 0.0, clampf(pickup_offset.z, -7.0, 7.0))
	depot.add_child(stock)
	_add_box(stock, "WoodUnitOne", Vector3(3.8, 2.1, 2.6), Vector3(-5.0, 1.1, 0.0), Color("a77442"))
	_add_box(stock, "WoodUnitTwo", Vector3(3.8, 2.1, 2.6), Vector3(-5.0, 3.3, 0.0), Color("bd8c4b"))
	_add_box(stock, "MetalIngotOne", Vector3(3.8, 1.2, 2.0), Vector3(0.0, 0.7, 0.0), Color("82999b"))
	_add_box(stock, "MetalIngotTwo", Vector3(3.8, 1.2, 2.0), Vector3(0.0, 2.0, 0.0), Color("a8b8b5"))
	_add_cylinder(stock, "MechanicalPartsCrate", 1.7, 3.0, Vector3(5.0, 1.6, 0.0), Color("a7824a"))
	_add_world_label(stock, "StockpileLabel", "WOOD · METAL · PARTS", Vector3(0.0, 6.5, 0.0))


func _emit_update() -> void:
	project_updated.emit(status())


func _path_length(path: Array[Vector3]) -> float:
	var length := 0.0
	for index in range(1, path.size()):
		length += path[index - 1].distance_to(path[index])
	return length


func _add_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, color: Color, visible: bool = true) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.material_override = _material(color)
	mesh_instance.visible = visible
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_cylinder(parent: Node3D, node_name: String, radius: float, height: float, at: Vector3, color: Color, visible: bool = true) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.material_override = _material(color)
	mesh_instance.visible = visible
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_world_label(parent: Node3D, node_name: String, value: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = value
	label.position = at
	label.font_size = 12
	label.pixel_size = 0.1
	label.modulate = Color("ffe2a5")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	return material
