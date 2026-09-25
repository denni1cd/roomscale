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


func _ready() -> void:
	_apply_transform()
	set_view_mode(0)


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
		_citizen_focus = null
		var right := Vector3(cos(yaw), 0.0, sin(yaw))
		var forward := Vector3(sin(yaw), 0.0, -cos(yaw))
		var pan_scale := maxf(12.0, distance * 0.8)
		target += (right * movement.x + forward * movement.y).normalized() * pan_scale * delta
	if Input.is_key_pressed(KEY_Q):
		target.y += maxf(8.0, distance * 0.4) * delta
	if Input.is_key_pressed(KEY_E):
		target.y -= maxf(8.0, distance * 0.4) * delta
	if view_mode == 2 and is_instance_valid(_citizen_focus):
		target = _citizen_focus.global_position + Vector3(0.0, 0.25, 0.0)
	_apply_transform()


func set_view_mode(mode: int) -> void:
	view_mode = clampi(mode, 0, 2)
	match view_mode:
		0: # Room
			target = Vector3(0.0, 20.0, 0.0)
			distance = 300.0
			tilt_degrees = 52.0
		1: # Settlement: frame all four work sites and the walking floor
			target = Vector3(0.0, 3.0, 55.0)
			distance = 132.0
			tilt_degrees = 55.0
		2: # Citizen: close detail scale beside the desk
			target = Vector3(-5.0, 3.0, 53.0)
			distance = 11.0
			tilt_degrees = 48.0
			if is_instance_valid(_citizen_focus):
				target = _citizen_focus.global_position + Vector3(0.0, 0.25, 0.0)
	_apply_transform()
	var label := get_node_or_null("../Overlay/CameraMode") as Label
	if label:
		label.text = "VIEW  %s  ·  %d in" % [_mode_name(), roundi(distance)]


func orbit_by(delta: Vector2) -> void:
	yaw -= delta.x * 0.006
	tilt_degrees = clampf(tilt_degrees + delta.y * 0.20, MIN_TILT_DEGREES, MAX_TILT_DEGREES)
	_apply_transform()


func pan_by(delta: Vector2) -> void:
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


func set_citizen_focus(citizen: Node3D) -> void:
	_citizen_focus = citizen
	if view_mode == 2 and is_instance_valid(_citizen_focus):
		target = _citizen_focus.global_position + Vector3(0.0, 0.25, 0.0)
		_apply_transform()


func _apply_transform() -> void:
	position = target
	rotation = Vector3(0.0, yaw, 0.0)
	if is_instance_valid(camera):
		var tilt := deg_to_rad(tilt_degrees)
		camera.position = Vector3(0.0, sin(tilt) * distance, cos(tilt) * distance)
		camera.rotation = Vector3(-tilt, 0.0, 0.0)


func _mode_name() -> String:
	return ["ROOM", "SETTLEMENT", "CITIZEN"][view_mode]


func get_view_mode_name() -> String:
	return _mode_name()
