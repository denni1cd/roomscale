extends Node3D
## Independent procedural citizen that follows A* waypoints and executes shared tasks.

const BODY_HEIGHT := 0.5
const WALK_SPEED := 6.5
const CitizenMeshScale := 1.0

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


func initialize(id: int, start: Vector3, floor_navigation: Node, task_system: Node) -> void:
	citizen_id = id
	name = "Citizen%02d" % (id + 1)
	position = start
	navigation = floor_navigation
	coordinator = task_system
	_build_figure()
	_assign_next_task()


func _process(delta: float) -> void:
	simulation_elapsed += delta
	_animation_time += delta
	if state == "TRAVEL" or state == "CARRY":
		_advance_path(delta)
	elif state == "WORK":
		_work_timer += delta
		_animate_work()
		if task_type == "CONSTRUCTION_BUILD":
			if coordinator.advance_construction_work(task_id, citizen_id, delta):
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
	return {"id": citizen_id, "state": state, "task": task_type, "target": _destination}


func _assign_next_task() -> void:
	var task: Dictionary = coordinator.claim_for(citizen_id)
	if task.is_empty():
		state = "IDLE"
		return
	task_id = int(task.id)
	task_type = String(task.task_type)
	_destination = task.target
	_second_destination = task.target
	_needs_second_leg = task_type == "DEPOT_RUN"
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
	_path = navigation.path_between(position, destination)
	_path_cursor = 0
	_work_timer = 0.0
	if _path.is_empty():
		coordinator.fail_task(task_id, "floor path unavailable")
		_assign_next_task()
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
	var head := _sphere(model, "Head", 0.14, Vector3(0.0, 0.385, 0.0), face)
	var hat := _cylinder(model, "ClockworkCap", 0.09, 0.05, Vector3(0.0, 0.475, 0.0), brass)
	var cap_brim := _cylinder(model, "CapBrim", 0.105, 0.018, Vector3(0.0, 0.448, 0.0), leather)
	_left_arm = _capsule(model, "LeftArm", 0.023, 0.17, Vector3(-0.105, 0.235, 0.0), leather)
	_right_arm = _capsule(model, "RightArm", 0.023, 0.17, Vector3(0.105, 0.235, 0.0), leather)
	_left_leg = _capsule(model, "LeftLeg", 0.025, 0.19, Vector3(-0.045, 0.095, 0.0), leather)
	_right_leg = _capsule(model, "RightLeg", 0.025, 0.19, Vector3(0.045, 0.095, 0.0), leather)
	_add_box(model, "Belt", Vector3(0.16, 0.035, 0.12), Vector3(0.0, 0.16, 0.0), brass)
	_cargo = _box(model, "Parcel", Vector3(0.16, 0.12, 0.14), Vector3(0.0, 0.26, -0.13), _material(Color("e0ad4e"), 0.68))
	_cargo.visible = false
	# Keep references alive and make intended scale explicit to the debugger.
	model.set_meta("body_height_inches", BODY_HEIGHT * CitizenMeshScale)
	model.set_meta("task_id", task_id)


func _update_animation() -> void:
	var walking := state == "TRAVEL" or state == "CARRY"
	if walking:
		var gait := sin(_animation_time * 11.0)
		_body.position.y = 0.23 + absf(gait) * 0.018
		_left_leg.rotation.x = gait * 0.42
		_right_leg.rotation.x = -gait * 0.42
		_left_arm.rotation.x = -gait * 0.35
		_right_arm.rotation.x = gait * 0.35
	else:
		_body.position.y = 0.23 + sin(_animation_time * 2.4) * 0.008
		_left_leg.rotation.x = 0.0
		_right_leg.rotation.x = 0.0
		if state == "WORK":
			_left_arm.rotation.x = sin(_animation_time * 9.0) * 0.68
			_right_arm.rotation.x = -sin(_animation_time * 9.0) * 0.68
		else:
			_left_arm.rotation.x = 0.0
			_right_arm.rotation.x = 0.0


func _animate_work() -> void:
	_body.rotation.z = sin(_animation_time * 7.0) * 0.06


func _set_cargo_resource(resource: String) -> void:
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
	_cargo.mesh = cargo_mesh
	_cargo.material_override = _material(color, 0.54)
	_cargo.set_meta("cargo_resource", resource)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = at
	item.material_override = material
	parent.add_child(item)
	return item


func _add_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	return _box(parent, node_name, size, at, material)


func _sphere(parent: Node3D, node_name: String, radius: float, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	item.mesh = mesh
	item.position = at
	item.material_override = material
	parent.add_child(item)
	return item


func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	item.mesh = mesh
	item.position = at
	item.material_override = material
	parent.add_child(item)
	return item


func _capsule(parent: Node3D, node_name: String, radius: float, height: float, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	item.mesh = mesh
	item.position = at
	item.material_override = material
	parent.add_child(item)
	return item
