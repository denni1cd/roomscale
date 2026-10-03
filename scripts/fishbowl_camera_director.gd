extends Node
## Presentation only: real-time shot pacing reads journal and production activity.
const MIN_SHOT := 8.0
const WIDE_INTERVAL := 40.0
var enabled := true
var simulation: Node
var rig: Node
var elapsed := 0.0
var wide_elapsed := 0.0
var event_id := 0
var shots := 0
var last_focus := Vector3.ZERO

func configure(sim: Node) -> void:
	simulation = sim
	rig = sim.scene.get_node("CameraRig")
	enabled = OS.get_environment("ROOMSCALE_MANUAL_CAMERA") != "1"

func _process(delta: float) -> void: advance(delta)

func valid_focus(focus: Vector3) -> bool:
	return focus.is_finite() and simulation.coordinator.navigation.room_bounds().has_point(Vector2(focus.x, focus.z))

func choose() -> Dictionary:
	var overview := {"focus": rig._room_focus, "distance": rig._room_width * 1.35, "event": event_id}
	if wide_elapsed >= WIDE_INTERVAL: return overview
	var major: Dictionary = {}
	for event in simulation.journal.events:
		if event.id > event_id and event.major and valid_focus(event.focus): major = event
	if not major.is_empty(): return {"focus": major.focus + Vector3.UP * 3, "distance": 72.0, "event": major.id}
	if not simulation.development.active.is_empty(): return {"focus": simulation.development.active.site + Vector3.UP * 3, "distance": 60.0, "event": event_id}
	for citizen in simulation.citizens:
		if citizen.task_type == "RESOURCE_COLLECT" and citizen.global_position.y > 4: return {"focus": citizen.global_position, "distance": 65.0, "event": event_id}
	for citizen in simulation.citizens:
		if citizen.task_type == "SALVAGE" and citizen.state == "WORK": return {"focus": citizen.global_position, "distance": 65.0, "event": event_id}
	return {"focus": simulation.development.center() + Vector3.UP * 4, "distance": 135.0, "event": event_id}

func advance(delta: float) -> void:
	if not enabled or not is_instance_valid(simulation): return
	elapsed += delta
	wide_elapsed += delta
	if elapsed < MIN_SHOT: return
	elapsed = 0
	var shot := choose()
	if not valid_focus(shot.focus): return
	if wide_elapsed >= WIDE_INTERVAL: wide_elapsed = 0
	event_id = int(shot.event)
	last_focus = shot.focus
	shots += 1
	rig.focus_at(shot.focus, shot.distance, 45, 0)
