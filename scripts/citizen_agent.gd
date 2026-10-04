extends Node3D
## Independent procedural citizen that follows A* waypoints and executes shared tasks.

const BODY_HEIGHT := 0.5
const WALK_SPEED := 6.5
const CitizenMeshScale := 1.0
const G := preload("res://scripts/visuals/visual_geometry.gd")
const Materials := preload("res://scripts/visuals/material_library.gd")
static var _shared_meshes: Dictionary = {}

var citizen_id := -1
var navigation: Node
var coordinator: Node
var task_id := -1
var task_type := "IDLE"
var state := "IDLE"
var carrying := false
var travelled_distance := 0.0
var simulation_elapsed := 0.0
var _destination := Vector3.ZERO
var _second_destination := Vector3.ZERO
var _needs_second_leg := false
var _delivery_resource := ""
var _path: Array[Vector3] = []
var _path_cursor := 0
var _work_timer := 0.0
var _animation_time := 0.0
var _body: MeshInstance3D
var _left_arm: MeshInstance3D
var _right_arm: MeshInstance3D
var _left_leg: MeshInstance3D
var _right_leg: MeshInstance3D
var _cargo: MeshInstance3D
var _role_tool: Node3D
var _role_pack: Node3D
var _role_badge: MeshInstance3D
var _traversal_clip: Node3D
var _fine_details: Array[Node3D] = []
var _detail_visible := true
var _lod_timer := 0.0
var needs: Dictionary = {}
var _idle_timer := 0.0


func initialize(id: int, start: Vector3, floor_navigation: Node, task_system: Node) -> void:
	citizen_id = id
	name = "Citizen%02d" % (id + 1)
	position = start
	navigation = floor_navigation
	coordinator = task_system
	_build_figure()
	_assign_next_task()


func _process(delta: float) -> void:
	_lod_timer += delta
	if _lod_timer >= 0.4:
		_lod_timer = 0.0
		refresh_visual_lod()
	simulation_elapsed += delta
	_animation_time += delta
	if not needs.is_empty():
		var civilization: Node = coordinator.civilization
		if task_type in ["WORKSHOP_MAINTENANCE", "DEPOT_RUN", "HOUSING_CHECK", "WORK_AREA_JOB", "FLOOR_PATROL"] and civilization.should_interrupt(self):
			coordinator.cancel_task(task_id, "urgent self-care")
			_assign_next_task()
		if state in ["IDLE", "ON_SURFACE"]:
			_idle_timer += delta
			if _idle_timer >= 0.5:
				_idle_timer = 0
				_assign_next_task()
	if state == "TRAVEL" or state == "CARRY":
		_advance_path(delta)
	elif state == "WORK":
		_work_timer += delta
		_animate_work()
		if task_type.begins_with("NEED_") or task_type in ["SALVAGE", "RESOURCE_COLLECT"]:
			if coordinator.civilization.work(self, delta):
				coordinator.complete_task(task_id)
				_assign_next_task()
		elif task_type == "CONSTRUCTION_BUILD":
			var effort: float = delta if needs.is_empty() else delta * coordinator.civilization.needs.work_factor(needs)
			if coordinator.advance_construction_work(task_id, citizen_id, effort):
				coordinator.complete_task(task_id)
				_assign_next_task()
		elif task_type == "SURFACE_EXPLORATION":
			if coordinator.advance_surface_exploration(self, task_id, delta):
				state = "ON_SURFACE"
		elif _work_timer >= (0.35 if task_type == "SURFACE_INVESTIGATION" else 0.65 + float(citizen_id % 4) * 0.13):
			coordinator.complete_task(task_id)
			carrying = false
			_cargo.visible = false
			_assign_next_task()
	_update_animation()


func get_travelled_distance() -> float:
	return travelled_distance

func refresh_visual_lod() -> void:
	# Camera-dependent rendering can refresh while simulation is paused.
	var camera := get_viewport().get_camera_3d()
	_detail_visible = camera == null or camera.global_position.distance_squared_to(global_position) < 144.0
	for detail in _fine_details: detail.visible = _detail_visible
	_role_tool.visible = _detail_visible and task_type in ["CONSTRUCTION_BUILD", "SALVAGE"]
	_role_pack.visible = _detail_visible and task_type in ["SURFACE_INVESTIGATION", "SURFACE_TRAVERSAL", "SURFACE_EXPLORATION"]
	_traversal_clip.visible = _detail_visible and task_type in ["SURFACE_TRAVERSAL", "RESOURCE_COLLECT"] and _path_cursor < _path.size() and absf(_path[_path_cursor].y - global_position.y) > 0.01


func assign_player_goal_task(task: Dictionary) -> void:
	if task_id > 0:
		coordinator.supersede_task(task_id, "reassigned to player Reach / Explore goal")
	task_id = int(task.id)
	task_type = String(task.task_type)
	_destination = task.target
	_second_destination = task.target
	_needs_second_leg = false
	carrying = false
	_cargo.visible = false
	_navigate_to(_destination)


func assign_project_task(task: Dictionary) -> void:
	if task_id > 0:
		coordinator.supersede_task(task_id, "reassigned to construction project")
	task_id = int(task.id)
	task_type = String(task.task_type)
	_delivery_resource = String(task.get("resource", ""))
	_needs_second_leg = task_type == "CONSTRUCTION_DELIVERY"
	carrying = false
	_cargo.visible = false
	if _needs_second_leg:
		_destination = task.source
		_second_destination = task.target
	else:
		_destination = task.target
		_second_destination = task.target
	_navigate_to(_destination)


func assign_traversal_task(task: Dictionary) -> void:
	if task_id > 0:
		coordinator.supersede_task(task_id, "assigned grapple traversal")
	task_id = int(task.id)
	task_type = String(task.task_type)
	carrying = false
	_cargo.visible = false
	_path = task.path.duplicate()
	_path_cursor = 0
	_work_timer = 0.0
	if _path.size() < 2:
		coordinator.fail_task(task_id, "grapple traversal path missing")
		state = "IDLE"
		return
	coordinator.activate_task(task_id)
	state = "TRAVEL"


func assign_surface_exploration_task(task: Dictionary) -> void:
	if task_id > 0:
		coordinator.supersede_task(task_id, "surface traversal completed; surface exploration assigned")
	task_id = int(task.id)
	task_type = String(task.task_type)
	carrying = false
	_cargo.visible = false
	_path = task.path.duplicate()
	_path_cursor = 0
	_work_timer = 0.0
	if _path.size() < 2:
		coordinator.fail_task(task_id, "surface exploration route missing")
		state = "IDLE"
		return
	coordinator.activate_task(task_id)
	state = "TRAVEL"


func cancel_task_and_resume(cancelled_task_id: int) -> void:
	if task_id != cancelled_task_id:
		return
	task_id = -1
	task_type = "IDLE"
	carrying = false
	_cargo.visible = false
	_needs_second_leg = false
	_path.clear()
	_path_cursor = 0
	_assign_next_task()


func get_inspection_status() -> Dictionary:
	return {"id": citizen_id, "state": state, "task": task_type, "target": _destination, "needs": needs.duplicate(true)}


func _assign_next_task() -> void:
	var task: Dictionary = coordinator.claim_for(citizen_id)
	if task.is_empty():
		state = "IDLE"
		return
	task_id = int(task.id)
	task_type = String(task.task_type)
	_destination = task.target
	_second_destination = task.target
	_needs_second_leg = task_type in ["DEPOT_RUN", "BUNDLE_HAUL", "CONSTRUCTION_DELIVERY"]
	_delivery_resource = String(task.get("resource", ""))
	if _needs_second_leg:
		_destination = task.source
		_second_destination = task.target
		carrying = false
		_cargo.visible = false
	else:
		carrying = false
		_cargo.visible = false
	_navigate_to(_destination)


func _navigate_to(destination: Vector3) -> void:
	_path = coordinator.civilization.route_for(self, destination) if is_instance_valid(coordinator.civilization) else navigation.path_between(position, destination)
	_path_cursor = 0
	_work_timer = 0.0
	if _path.is_empty():
		coordinator.fail_task(task_id, "floor path unavailable")
		# Failure may enqueue another unreachable routine task. Retry through the
		# existing idle timer on a later tick instead of recursively claiming work
		# until the call stack overflows. Release already ran through fail_task.
		task_id = -1
		task_type = "IDLE"
		state = "IDLE"
		_idle_timer = 0.0
		_needs_second_leg = false
		carrying = false
		_cargo.visible = false
		return
	coordinator.activate_task(task_id)
	state = "CARRY" if carrying else "TRAVEL"


func _advance_path(delta: float) -> void:
	if _path_cursor >= _path.size():
		_arrive_at_destination()
		return
	var waypoint := _path[_path_cursor]
	var remaining := waypoint - global_position
	if remaining.length() <= 0.05:
		_path_cursor += 1
		if _path_cursor >= _path.size():
			_arrive_at_destination()
		return
	var direction := remaining.normalized()
	var step := minf(WALK_SPEED * delta, remaining.length())
	global_position += direction * step
	rotation.y = atan2(direction.x, direction.z)
	travelled_distance += step


func _arrive_at_destination() -> void:
	if task_type == "SURFACE_TRAVERSAL":
		if coordinator.report_traversal_arrival(self, task_id):
			return
		else:
			coordinator.fail_task(task_id, "surface traversal arrival failed route, height, or travel validation")
			state = "IDLE"
		return
	if task_type == "SURFACE_EXPLORATION":
		if not coordinator.begin_surface_exploration(self, task_id):
			coordinator.fail_task(task_id, "surface exploration failed region, route, or infrastructure validation")
			state = "IDLE"
			return
		state = "WORK"
		_work_timer = 0.0
		return
	if _needs_second_leg and not carrying:
		if task_type == "BUNDLE_HAUL":
			if not coordinator.civilization.pickup_bundle(self):
				coordinator.fail_task(task_id, "bundle pickup validation failed")
				_assign_next_task()
				return
			_set_cargo_resource(_delivery_resource)
		if task_type == "CONSTRUCTION_DELIVERY":
			if not coordinator.confirm_project_pickup(task_id, self, _delivery_resource):
				coordinator.fail_task(task_id, "material pickup could not be verified at stockpile")
				_assign_next_task()
				return
			_set_cargo_resource(_delivery_resource)
		carrying = true
		_cargo.visible = true
		_destination = _second_destination
		_navigate_to(_destination)
		return
	if task_type in ["BUNDLE_HAUL", "RESOURCE_COLLECT"] and carrying:
		if not coordinator.civilization.deliver_bundle(self):
			coordinator.fail_task(task_id, "bundle delivery travel/ownership validation failed")
		else:
			coordinator.complete_task(task_id)
		carrying = false
		_cargo.visible = false
		_assign_next_task()
		return
	if task_type == "CONSTRUCTION_DELIVERY" and carrying:
		var carried_resource := String(_cargo.get_meta("cargo_resource", ""))
		if not coordinator.confirm_project_delivery(task_id, self, _delivery_resource, carried_resource):
			coordinator.fail_task(task_id, "carried material delivery could not be verified at build site")
			carrying = false
			_cargo.visible = false
			_assign_next_task()
			return
		coordinator.complete_task(task_id)
		carrying = false
		_cargo.visible = false
		_assign_next_task()
		return
	if task_type == "SURFACE_INVESTIGATION":
		coordinator.report_investigation_arrival(citizen_id, task_id, global_position)
	state = "WORK"
	_work_timer = 0.0


func begin_resource_return(resource: String) -> void:
	carrying = true
	_cargo.visible = true
	_set_cargo_resource(resource)
	_destination = coordinator.depot_station
	_navigate_to(_destination)


func _build_figure() -> void:
	var model := Node3D.new()
	model.name = "Figure"
	add_child(model)
	var coat_colors := [Color("a87950"), Color("638891"), Color("a96250"), Color("778d53"), Color("b29b5d")]
	var coat := _material(coat_colors[citizen_id % coat_colors.size()], 0.82)
	var brass := _material(Color("f2c65e"), 0.42)
	var leather := _material(Color("574537"), 0.8)
	var face := _material(Color("edcba2"), 0.9)
	_body = _box(model, "Body", Vector3(0.15, 0.21, 0.11), Vector3(0.0, 0.23, 0.0), coat)
	var head := _sphere(model, "Head", 0.068, Vector3(0.0, 0.395, 0.0), face)
	var hat := _cylinder(model, "ClockworkCap", 0.09, 0.05, Vector3(0.0, 0.475, 0.0), brass)
	var cap_brim := _cylinder(model, "CapBrim", 0.105, 0.018, Vector3(0.0, 0.448, 0.0), leather)
	_left_arm = _capsule(model, "LeftArm", 0.023, 0.17, Vector3(-0.105, 0.235, 0.0), leather)
	_right_arm = _capsule(model, "RightArm", 0.023, 0.17, Vector3(0.105, 0.235, 0.0), leather)
	_left_leg = _capsule(model, "LeftLeg", 0.025, 0.19, Vector3(-0.045, 0.095, 0.0), leather)
	_right_leg = _capsule(model, "RightLeg", 0.025, 0.19, Vector3(0.045, 0.095, 0.0), leather)
	_add_box(model, "Belt", Vector3(0.16, 0.035, 0.12), Vector3(0.0, 0.16, 0.0), brass)
	for side in [-1.0, 1.0]:
		var goggle := _cylinder(model, "Goggle%s" % side, 0.025, 0.018, Vector3(side * 0.031, 0.409, 0.059), brass)
		goggle.rotation.x = PI * 0.5
		var lens := _cylinder(model, "Lens%s" % side, 0.017, 0.02, Vector3(side * 0.031, 0.409, 0.07), Materials.get_material("glass", Color("204a53")))
		lens.rotation.x = PI * 0.5
		_box(model, "Boot%s" % side, Vector3(0.064, 0.045, 0.09), Vector3(side * 0.045, 0.025, 0.019), leather)
		_box(model, "ShoulderPlate%s" % side, Vector3(0.056, 0.04, 0.066), Vector3(side * 0.099, 0.307, 0.0), brass)
	_box(model, "Buckle", Vector3(0.037, 0.025, 0.016), Vector3(0, 0.173, 0.071), brass)
	_role_badge = _box(model, "RoleChest", Vector3(0.085, 0.045, 0.02), Vector3(0, 0.28, 0.065), brass)
	_traversal_clip = Node3D.new()
	_traversal_clip.name = "CableSafetyClip"
	model.add_child(_traversal_clip)
	_box(_traversal_clip, "SafetyLanyard", Vector3(0.015, 0.18, 0.015), Vector3(0.075, 0.11, 0), leather)
	var clip := _cylinder(_traversal_clip, "CableClamp", 0.018, 0.045, Vector3(0.055, 0.021, 0), Materials.get_material("iron", Color("728990")))
	clip.rotation.x = PI * 0.5
	_role_pack = _box(model, "ExplorerPack", Vector3(0.115, 0.13, 0.065), Vector3(0, 0.255, -0.089), leather)
	_role_tool = Node3D.new()
	_role_tool.name = "BuilderHammer"
	_role_tool.position = Vector3(0.12, 0.22, 0.035)
	model.add_child(_role_tool)
	_box(_role_tool, "Handle", Vector3(0.023, 0.15, 0.023), Vector3(0, 0.035, 0), leather)
	_box(_role_tool, "HammerHead", Vector3(0.13, 0.055, 0.055), Vector3(0, 0.115, 0), Materials.get_material("iron", Color("81969a")))
	_box(_role_tool, "HammerFace", Vector3(0.025, 0.065, 0.065), Vector3(0.058, 0.115, 0), brass)
	_cargo = _box(model, "Parcel", Vector3(0.16, 0.12, 0.14), Vector3(0.0, 0.26, 0.14), _material(Color("e0ad4e"), 0.68))
	_cargo.visible = false
	# Keep references alive and make intended scale explicit to the debugger.
	model.set_meta("body_height_inches", BODY_HEIGHT * CitizenMeshScale)
	model.set_meta("task_id", task_id)
	for child in model.get_children():
		if String(child.name).begins_with("Goggle") or String(child.name).begins_with("Lens") or String(child.name).begins_with("ShoulderPlate") or String(child.name).begins_with("Boot") or child.name == "Buckle":
			_fine_details.append(child)


func _update_animation() -> void:
	_left_arm.rotation = Vector3.ZERO
	_right_arm.rotation = Vector3.ZERO
	if state != "WORK":
		_body.rotation.z = 0.0
	_role_tool.visible = _detail_visible and task_type in ["CONSTRUCTION_BUILD", "SALVAGE"]
	_role_pack.visible = _detail_visible and task_type in ["SURFACE_INVESTIGATION", "SURFACE_TRAVERSAL", "SURFACE_EXPLORATION"]
	var climbing := task_type in ["SURFACE_TRAVERSAL", "RESOURCE_COLLECT"] and _path_cursor < _path.size() and absf(_path[_path_cursor].y - global_position.y) > 0.01
	_traversal_clip.visible = _detail_visible and climbing
	var builder := task_type in ["CONSTRUCTION_BUILD", "SALVAGE"]
	var explorer := task_type in ["SURFACE_INVESTIGATION", "SURFACE_TRAVERSAL", "SURFACE_EXPLORATION"]
	_role_badge.material_override = Materials.get_material("paint", Color("d4933b") if builder else (Color("498e99") if explorer else (Color("698955") if carrying else Color("887660"))))
	if task_type == "CONSTRUCTION_BUILD" and state == "WORK":
		var construction := get_parent().get_node_or_null("ConstructionSystem")
		if construction != null:
			var work_task: Dictionary = coordinator.get_task(task_id)
			var work_at: Vector3 = work_task.target if work_task.has("project_id") else construction.status().site
			var toward := work_at + Vector3(0.1, 0, -0.38) - global_position
			if Vector2(toward.x, toward.z).length() > 0.02:
				rotation.y = atan2(toward.x, toward.z)
	var walking := state == "TRAVEL" or state == "CARRY"
	if walking:
		var gait := sin(_animation_time * 11.0)
		_body.position.y = 0.23 + absf(gait) * 0.018
		_left_leg.rotation.x = gait * 0.42
		_right_leg.rotation.x = -gait * 0.42
		_left_arm.rotation.x = -gait * 0.35
		_right_arm.rotation.x = gait * 0.35
		if carrying:
			_left_arm.rotation.x = -0.85
			_right_arm.rotation.x = -0.85
		if climbing:
			_left_arm.rotation.x = -1.6 + gait * 0.55
			_right_arm.rotation.x = -1.6 - gait * 0.55
			_left_leg.rotation.x = gait * 0.75
			_right_leg.rotation.x = -gait * 0.75
	else:
		_body.position.y = 0.23 + sin(_animation_time * 2.4) * 0.008
		_left_leg.rotation.x = 0.0
		_right_leg.rotation.x = 0.0
		if state == "WORK":
			_left_arm.rotation.x = -0.7 if builder else sin(_animation_time * 9.0) * 0.68
			_right_arm.rotation.x = -1.0 + sin(_animation_time * 9.0) * 0.85 if builder else -sin(_animation_time * 9.0) * 0.68
		else:
			_left_arm.rotation.x = 0.0
			_right_arm.rotation.x = 0.0
	_role_tool.rotation.x = _right_arm.rotation.x
	_role_tool.position = _right_arm.position + Vector3(0.025, -cos(_right_arm.rotation.x) * 0.075, -sin(_right_arm.rotation.x) * 0.075)
	if task_type == "CONSTRUCTION_BUILD" and state == "WORK":
		_pose_builder()
	else:
		_left_arm.scale.y = 1.0
		_right_arm.scale.y = 1.0
		_left_arm.position = Vector3(-0.105, 0.235, 0)
		_right_arm.position = Vector3(0.105, 0.235, 0)
		_body.rotation.x = 0.0
	if task_type == "NEED_REST" and state == "WORK":
		_body.rotation.x = 0.35
		_left_leg.rotation.x = 0.4
		_right_leg.rotation.x = 0.4
		_left_arm.rotation.x = 0
		_right_arm.rotation.x = 0
	if task_type == "SALVAGE" and state == "WORK":
		var task: Dictionary = coordinator.get_task(task_id)
		var object: Dictionary = coordinator.civilization.resources.objects[String(task.object_id)].data
		var at := Vector3(float(object.position[0]), global_position.y, float(object.position[2]))
		var toward := at - global_position
		rotation.y = atan2(toward.x, toward.z)


func _pose_builder() -> void:
	# Fit the presentation to the real assembly pin without moving the agent or
	# changing task progress. The hammer head rises and returns to the workpiece.
	var construction := get_parent().get_node_or_null("ConstructionSystem")
	if construction == null:
		return
	var work_task: Dictionary = coordinator.get_task(task_id)
	var site: Vector3 = work_task.target if work_task.has("project_id") else construction.status().site
	var stroke := pow((sin(_animation_time * 9.0) + 1.0) * 0.5, 2.0)
	var head_at := site + Vector3(0.1, 0.28 + stroke * 0.22, -0.38)
	_role_tool.global_basis = global_basis * Basis(Vector3.RIGHT, PI * 0.5 - stroke * 0.45)
	_role_tool.global_position = head_at - _role_tool.global_basis * Vector3(0, 0.115, 0)
	var model := _body.get_parent() as Node3D
	var right_hand := model.to_local(_role_tool.global_position)
	var left_hand := model.to_local(site + Vector3(-0.08, 0.24, -0.32))
	_fit_work_arm(_right_arm, Vector3(0.105, 0.30, 0), right_hand)
	_fit_work_arm(_left_arm, Vector3(-0.105, 0.30, 0), left_hand)
	_body.rotation.x = 0.12 + stroke * 0.08


func _fit_work_arm(arm: Node3D, shoulder: Vector3, hand: Vector3) -> void:
	var reach := hand - shoulder
	arm.position = (shoulder + hand) * 0.5
	arm.quaternion = Quaternion(Vector3.DOWN, reach.normalized())
	arm.scale = Vector3(1, reach.length() / 0.17, 1)


func _animate_work() -> void:
	_body.rotation.z = sin(_animation_time * 7.0) * 0.06


func _set_cargo_resource(resource: String) -> void:
	for child in _cargo.get_children():
		child.free()
	var cargo_mesh := BoxMesh.new()
	var color := Color("c7a065")
	match resource:
		"wood":
			cargo_mesh.size = Vector3(0.28, 0.13, 0.23)
			color = Color("ca8547")
		"metal":
			cargo_mesh.size = Vector3(0.25, 0.16, 0.24)
			color = Color("9fb6b8")
		"mechanical_parts":
			cargo_mesh.size = Vector3(0.23, 0.18, 0.22)
			color = Color("efc257")
		"water":
			cargo_mesh.size = Vector3(0.12, 0.17, 0.12)
			color = Color("469ac1")
		"food":
			cargo_mesh.size = Vector3(0.18, 0.12, 0.17)
			color = Color("d6b072")
	_cargo.mesh = cargo_mesh
	_cargo.material_override = _material(color, 0.54)
	_cargo.set_meta("cargo_resource", resource)
	if resource == "wood":
		_cargo.mesh = null
		for index in range(3):
			G.box(_cargo, "Plank%d" % index, Vector3(0.32, 0.032, 0.065), Vector3(0, 0.065 + index * 0.032, 0), "wood", Color("9b633a"), 0.005)
		for side in [-1, 1]:
			G.box(_cargo, "Strap%d" % side, Vector3(0.025, 0.12, 0.25), Vector3(side * 0.095, 0.025, 0), "rope", Color("66533e"), 0.003)
	elif resource == "metal":
		for index in range(3):
			G.box(_cargo, "Ingot%d" % index, Vector3(0.23, 0.026, 0.21), Vector3(0, 0.08 + index * 0.026, 0), "iron", Color("667e87"), 0.01)
	elif resource == "water":
		_cargo.mesh = null
		G.cylinder(_cargo, "WaterFlask", 0.06, 0.17, Vector3(0, 0.035, 0), "ceramic", Color("469ac1"))
		G.cylinder(_cargo, "FlaskStopper", 0.035, 0.025, Vector3(0, 0.13, 0), "wood", Color("725333"))
	elif resource == "food":
		G.box(_cargo, "BreadBundle", Vector3(0.14, 0.025, 0.12), Vector3(0, 0.07, 0), "canvas", Color("d6b072"), 0.01)
	else:
		G.gear(_cargo, "CarriedGear", 0.07, Vector3(0, 0.11, 0), 8)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	return Materials.get_material("brass" if roughness < 0.5 else "leather", color, roughness)


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	item.mesh = G.rounded_box(size, minf(size.x, minf(size.y, size.z)) * 0.15)
	item.position = at
	item.material_override = material
	parent.add_child(item)
	return item


func _add_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	return _box(parent, node_name, size, at, material)


func _sphere(parent: Node3D, node_name: String, radius: float, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var key := "sphere:%s" % radius
	if not _shared_meshes.has(key):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 16
		mesh.rings = 8
		_shared_meshes[key] = mesh
	item.mesh = _shared_meshes[key]
	item.position = at
	item.material_override = material
	parent.add_child(item)
	return item


func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var key := "cylinder:%s:%s" % [radius, height]
	if not _shared_meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 16
		_shared_meshes[key] = mesh
	item.mesh = _shared_meshes[key]
	item.position = at
	item.material_override = material
	parent.add_child(item)
	return item


func _capsule(parent: Node3D, node_name: String, radius: float, height: float, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var key := "capsule:%s:%s" % [radius, height]
	if not _shared_meshes.has(key):
		var mesh := CapsuleMesh.new()
		mesh.radius = radius
		mesh.height = height
		mesh.radial_segments = 12
		mesh.rings = 4
		_shared_meshes[key] = mesh
	item.mesh = _shared_meshes[key]
	item.position = at
	item.material_override = material
	parent.add_child(item)
	return item
