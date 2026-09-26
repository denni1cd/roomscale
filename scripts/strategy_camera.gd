extends Node3D
class_name StrategyCamera
## Orbit/pan/tilt/zoom strategy camera; keyboard presets map to three useful scales.

const MIN_DISTANCE := 22.0
const MAX_DISTANCE := 520.0
const MIN_TILT_DEGREES := 18.0
const MAX_TILT_DEGREES := 78.0

@onready var camera: Camera3D = $Camera

var target := Vector3(0.0, 22.0, 0.0)
var yaw := 0.0
var tilt_degrees := 52.0
var distance := 300.0
var view_mode := 0
var _orbit_dragging := false
var _pan_dragging := false
var _citizen_focus: Node3D
var _citizen_focus_offset := Vector3(0.0, 0.25, 0.0)
var _camera_transition_active := false
var _room_focus := Vector3.ZERO
var _settlement_focus := Vector3(0.0, 8.0, 22.0)
var _room_width := 240.0


func _ready() -> void:
	_apply_transform()
	set_view_mode(0)


func configure_room(definition: Dictionary) -> void:
	var dimensions: Array = definition.get("dimensions", [240.0, 180.0])
	_room_width = float(dimensions[0])
	var camera_data: Dictionary = definition.get("camera", {})
	_room_focus = Vector3(float(camera_data.get("focus", [0.0, 0.0, 0.0])[0]), 0.0, float(camera_data.get("focus", [0.0, 0.0, 0.0])[2]))
	var landmarks: Dictionary = definition.get("landmarks", {})
	var average := Vector3.ZERO
	var count := 0
	for landmark in ["workshop", "depot", "housing", "work_area"]:
		if landmarks.has(landmark):
			average += Vector3(float(landmarks[landmark][0]), 0.0, float(landmarks[landmark][2]))
			count += 1
	if count > 0:
		average /= float(count)
		_settlement_focus = Vector3(average.x, 8.0, average.z)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_RIGHT:
			_orbit_dragging = button.pressed
		elif button.button_index == MOUSE_BUTTON_MIDDLE:
			_pan_dragging = button.pressed
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(0.88)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.14)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _orbit_dragging:
			orbit_by(motion.relative)
		elif _pan_dragging:
			pan_by(motion.relative)
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		match (event as InputEventKey).keycode:
			KEY_1:
				set_view_mode(0)
			KEY_2:
				set_view_mode(1)
			KEY_3:
				set_view_mode(2)


func _process(delta: float) -> void:
	var movement := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y -= 1.0
	if movement.length_squared() > 0.0:
		_camera_transition_active = true
		_citizen_focus = null
		var right := Vector3(cos(yaw), 0.0, sin(yaw))
		var forward := Vector3(sin(yaw), 0.0, -cos(yaw))
		var pan_scale := maxf(12.0, distance * 0.8)
		target += (right * movement.x + forward * movement.y).normalized() * pan_scale * delta
	if Input.is_key_pressed(KEY_Q):
		_camera_transition_active = true
		target.y += maxf(8.0, distance * 0.4) * delta
	if Input.is_key_pressed(KEY_E):
		_camera_transition_active = true
		target.y -= maxf(8.0, distance * 0.4) * delta
	if view_mode == 2 and is_instance_valid(_citizen_focus):
		var focus_target := _citizen_focus.global_position + _citizen_focus_offset
		if target.distance_to(focus_target) > 0.05:
			_camera_transition_active = true
		target = focus_target
	_apply_transform(delta)


func set_view_mode(mode: int) -> void:
	var previous_mode := view_mode
	view_mode = clampi(mode, 0, 2)
	match view_mode:
		0: # Room
			target = Vector3(_room_focus.x, 20.0, _room_focus.z)
			distance = maxf(300.0, _room_width * 1.25)
			tilt_degrees = 52.0
		1: # Settlement: frame the room-scale work sites and walking floor together
			target = _settlement_focus
			distance = maxf(132.0, _room_width * 0.55)
			tilt_degrees = 55.0
		2: # Citizen: close detail scale for citizen inspection
			target = _room_focus + Vector3(0.0, 3.0, 0.0)
			distance = 11.0
			tilt_degrees = 48.0
			if is_instance_valid(_citizen_focus):
				target = _citizen_focus.global_position + _citizen_focus_offset
	if view_mode != previous_mode:
		_camera_transition_active = true
	_apply_transform()
	var label := get_node_or_null("../Overlay/CameraMode") as Label
	if label:
		label.text = "VIEW  %s  ·  %d in" % [_mode_name(), roundi(distance)]


func orbit_by(delta: Vector2) -> void:
	yaw -= delta.x * 0.006
	tilt_degrees = clampf(tilt_degrees + delta.y * 0.20, MIN_TILT_DEGREES, MAX_TILT_DEGREES)
	_apply_transform()


func pan_by(delta: Vector2) -> void:
	_camera_transition_active = true
	_citizen_focus = null
	var right := Vector3(cos(yaw), 0.0, sin(yaw))
	var forward := Vector3(sin(yaw), 0.0, -cos(yaw))
	var scale := distance * 0.002
	target += (-right * delta.x + forward * delta.y) * scale
	_apply_transform()


func zoom_by(factor: float) -> void:
	distance = clampf(distance * factor, MIN_DISTANCE, MAX_DISTANCE)
	_apply_transform()
	var label := get_node_or_null("../Overlay/CameraMode") as Label
	if label:
		label.text = "VIEW  %s  ·  %d in" % [_mode_name(), roundi(distance)]


func set_citizen_focus(citizen: Node3D, focus_offset: Vector3 = Vector3(0.0, 0.25, 0.0)) -> void:
	_citizen_focus = citizen
	_citizen_focus_offset = focus_offset
	if view_mode == 2 and is_instance_valid(_citizen_focus):
		target = _citizen_focus.global_position + _citizen_focus_offset
		_apply_transform()


func focus_at(world_position: Vector3, desired_distance: float, desired_tilt: float = 52.0, desired_yaw: float = 0.0) -> void:
	_citizen_focus = null
	target = world_position
	distance = clampf(desired_distance, MIN_DISTANCE, MAX_DISTANCE)
	tilt_degrees = clampf(desired_tilt, MIN_TILT_DEGREES, MAX_TILT_DEGREES)
	yaw = desired_yaw
	position = target
	_camera_transition_active = false
	_apply_transform()


func get_focused_citizen() -> Node3D:
	return _citizen_focus


func is_camera_transition_active() -> bool:
	return _camera_transition_active


func _apply_transform(delta: float = 0.0) -> void:
	if _camera_transition_active and delta > 0.0:
		position = position.lerp(target, 1.0 - exp(-7.0 * delta))
		if position.distance_to(target) < 0.05:
			position = target
			_camera_transition_active = false
	elif not _camera_transition_active:
		position = target
	rotation = Vector3(0.0, yaw, 0.0)
	if is_instance_valid(camera):
		var tilt := deg_to_rad(tilt_degrees)
		camera.position = Vector3(0.0, sin(tilt) * distance, cos(tilt) * distance)
		camera.rotation = Vector3(-tilt, 0.0, 0.0)
	var label := get_node_or_null("../Overlay/CameraMode") as Label
	if label:
		label.text = "VIEW  %s  ·  %d in" % [_mode_name(), roundi(distance)]


func _mode_name() -> String:
	return ["ROOM", "SETTLEMENT", "CITIZEN"][view_mode]


func get_view_mode_name() -> String:
	return _mode_name()
