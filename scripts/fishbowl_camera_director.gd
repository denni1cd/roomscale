extends Node
## Presentation only: real-time shots read journal and current production activity.
const Adapter := preload("res://scripts/fishbowl_narrative_adapter.gd")
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
var current_shot: Dictionary = {}
var tracked_citizen := -1
var tracked_position := Vector3.ZERO

func configure(sim: Node) -> void:
	simulation = sim
	rig = sim.scene.get_node("CameraRig")
	enabled = OS.get_environment("ROOMSCALE_MANUAL_CAMERA") != "1"
	if sim.founder_mode and enabled:
		var focus := Vector3.ZERO
		for citizen in sim.citizens: focus += citizen.global_position / sim.citizens.size()
		current_shot = {"key":"founders", "focus":focus, "distance":22.0, "event":0, "headline":"FOUNDERS ARRIVED", "subtitle":"%d citizens · A new home begins here" % sim.citizens.size()}
		shots = 1
		rig.focus_at(focus, 22, 40, 0)
		rig._camera_transition_active = false
		rig._apply_transform()

func _process(delta: float) -> void: advance(delta)

func valid_focus(focus: Vector3) -> bool:
	return focus.is_finite() and simulation.coordinator.navigation.room_bounds().has_point(Vector2(focus.x, focus.z))

func overview() -> Dictionary:
	return {"key": "overview", "focus": rig._room_focus, "distance": rig._room_width * 1.15, "event": event_id, "headline": "COLONY OVERVIEW", "subtitle": "Day %.1f · Population %d" % [simulation.seconds / 600, simulation.citizens.size()]}

func choose() -> Dictionary:
	if wide_elapsed >= WIDE_INTERVAL: return overview()
	var major: Dictionary = {}
	var priority := 0
	for event in simulation.journal.events:
		if event.id <= event_id or not valid_focus(event.focus): continue
		if event.kind not in ["salvage_authorized", "traversal_complete", "structure_complete", "cohort_joined", "development_started", "territory_reached"]: continue
		var card := Adapter.event_card(event)
		if card.is_empty() or int(card.priority) < 3: continue
		# Old arrivals have dispersed; current activity provides a truer subject.
		if event.kind == "cohort_joined" and simulation.seconds - event.seconds > 30: continue
		if int(card.priority) > priority:
			major = event
			priority = int(card.priority)
	if not major.is_empty():
		var card := Adapter.event_card(major)
		var shot := {"key": "event:%d" % major.id, "focus": major.focus + Vector3.UP * 2, "distance": 32.0, "event": major.id, "headline": card.headline, "subtitle": card.subtitle}
		if major.kind == "cohort_joined":
			shot.focus = major.focus + Vector3.UP * 0.25
			shot.distance = 13.0
			shot.cohort_start = major.evidence.before
			shot.cohort_size = int(major.evidence.after) - int(major.evidence.before)
		elif major.kind == "salvage_authorized":
			shot.headline = "SALVAGE OPERATION"
			var id := String(major.message).get_slice(": ", 1)
			if simulation.resources.objects.has(id):
				var object: Dictionary = simulation.resources.objects[id].data
				shot.focus = major.focus + Vector3.UP * float(object.dimensions[1]) * 0.35
				shot.distance = maxf(35, float(object.dimensions[1]) * 2.1)
		return shot
	# Alternate a contextual view with actual worker detail, never move the worker.
	if not String(current_shot.get("key", "")).begins_with("citizen:"):
		for citizen in simulation.citizens:
			if citizen.state == "WORK" and citizen.task_type == "SALVAGE": return activity(citizen, "SALVAGE OPERATION", "Recovering finite construction materials")
			if citizen.state == "WORK" and citizen.task_type == "CONSTRUCTION_BUILD":
				return activity(citizen, "CONSTRUCTION AT WORK", "A citizen assembles the colony's infrastructure")
	if simulation.construction.project_created and not simulation.construction.traversal_deployed:
		return {"key": "traversal", "focus": simulation.construction.site_position + Vector3.UP * 3, "distance": 45.0, "event": event_id, "headline": "EXPEDITION TO THE DESK", "subtitle": "Building a grapple route to the water supply"}
	if not simulation.development.active.is_empty():
		var p: Dictionary = simulation.development.active
		return {"key": String(p.id), "focus": p.site + Vector3(0, 2, 3), "distance": 30.0, "event": event_id, "headline": Adapter.module_name(p).to_upper(), "subtitle": Adapter.module_name(p) + " under construction"}
	for citizen in simulation.citizens:
		if citizen.task_type == "RESOURCE_COLLECT" and citizen.global_position.y > 4:
			return activity(citizen, "EXPEDITION TO THE DESK", "Collecting water for the colony")
	for citizen in simulation.citizens:
		if citizen.task_type == "SALVAGE" and citizen.state == "WORK": return activity(citizen, "SALVAGE OPERATION", "Recovering finite construction materials")
	return {"key": "settlement", "focus": simulation.development.center() + Vector3.UP * 3, "distance": 115.0, "event": event_id, "headline": "LIFE IN THE SETTLEMENT", "subtitle": "%d citizens · Working, carrying and resting" % simulation.citizens.size()}

func activity(citizen: Node3D, headline: String, subtitle: String) -> Dictionary:
	return {"key": "citizen:%d:%s" % [citizen.citizen_id, citizen.task_type], "citizen": citizen.citizen_id, "activity_task": citizen.task_type, "focus": citizen.global_position + Vector3.UP * 0.25, "distance": 6.0, "event": event_id, "headline": headline, "subtitle": subtitle}

func advance(delta: float) -> void:
	if not enabled or not is_instance_valid(simulation): return
	elapsed += delta
	wide_elapsed += delta
	if elapsed >= MIN_SHOT:
		elapsed = 0
		var shot := choose()
		if not valid_focus(shot.focus): shot = overview()
		if wide_elapsed >= WIDE_INTERVAL: wide_elapsed = 0
		event_id = int(shot.event)
		if current_shot.get("key", "") != shot.key:
			current_shot = shot
			shots += 1
	if current_shot.is_empty(): return
	var focus: Vector3 = current_shot.focus
	var framing_distance: float = current_shot.distance
	if current_shot.has("citizen"):
		var citizen: Node3D = simulation.citizens[int(current_shot.citizen)]
		focus = citizen.global_position + Vector3.UP * 0.25
		# Match the subject's movement while easing the initial framing offset.
		# At 10x, smoothing movement itself lets a walking citizen outrun the camera.
		if tracked_citizen == int(current_shot.citizen): rig.target += focus - tracked_position
		tracked_citizen = int(current_shot.citizen)
		tracked_position = focus
	else:
		tracked_citizen = -1
	if current_shot.has("cohort_start"):
		focus = Vector3.UP * 0.25
		for index in range(int(current_shot.cohort_start), int(current_shot.cohort_start) + int(current_shot.cohort_size)): focus += simulation.citizens[index].global_position / int(current_shot.cohort_size)
		for index in range(int(current_shot.cohort_start), int(current_shot.cohort_start) + int(current_shot.cohort_size)): framing_distance = maxf(framing_distance, focus.distance_to(simulation.citizens[index].global_position) * 2.8)
	if not valid_focus(focus):
		current_shot = overview()
		focus = current_shot.focus
	last_focus = focus
	# Existing rig applies the transform; interpolate target and distance in real time.
	var weight := 1.0 - exp(-3.0 * delta)
	rig._citizen_focus = null
	rig.target = rig.target.lerp(focus, weight)
	rig.distance = lerpf(rig.distance, framing_distance, weight)
	rig.tilt_degrees = lerpf(rig.tilt_degrees, 55.0, weight)
	rig.yaw = lerp_angle(rig.yaw, 0.0, weight)
	rig._apply_transform()

func title_is_current() -> bool:
	if current_shot.has("citizen"):
		return simulation.citizens[int(current_shot.citizen)].task_type == current_shot.get("activity_task", "")
	if String(current_shot.get("key", "")).begins_with("development_"):
		return simulation.development.active.get("id", "") == current_shot.key
	return true

func shot_subtitle() -> String:
	if current_shot.get("key", "") == "overview": return "Day %.1f · Population %d" % [simulation.seconds / 600, simulation.citizens.size()]
	if current_shot.get("key", "") == "settlement": return "%d citizens · Working, carrying and resting" % simulation.citizens.size()
	return current_shot.get("subtitle", "")
