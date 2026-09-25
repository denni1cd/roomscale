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
var _destination := Vector3.ZERO
var _second_destination := Vector3.ZERO
var _needs_second_leg := false
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
	_animation_time += delta
	if state == "TRAVEL" or state == "CARRY":
		_advance_path(delta)
	elif state == "WORK":
		_work_timer += delta
		_animate_work()
		if _work_timer >= 0.65 + float(citizen_id % 4) * 0.13:
			coordinator.complete_task(task_id)
			carrying = false
			_cargo.visible = false
			_assign_next_task()
	_update_animation()


func get_travelled_distance() -> float:
	return travelled_distance


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
	var remaining := Vector2(waypoint.x - position.x, waypoint.z - position.z)
	if remaining.length() <= 0.42:
		_path_cursor += 1
		if _path_cursor >= _path.size():
			_arrive_at_destination()
		return
	var direction := remaining.normalized()
	var step := minf(WALK_SPEED * delta, remaining.length())
	position.x += direction.x * step
	position.z += direction.y * step
	rotation.y = atan2(direction.x, direction.y)
	travelled_distance += step


func _arrive_at_destination() -> void:
	if _needs_second_leg and not carrying:
		carrying = true
		_cargo.visible = true
		_destination = _second_destination
		_navigate_to(_destination)
		return
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
