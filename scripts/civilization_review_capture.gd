extends SceneTree
## Renderer evidence observer. Run remotely under Xvfb to leave the local desktop free.
## Production owns all elapsed-time processing, resources, labor and movement.
## This driver only performs the ordinary established-room Reach action, selects
## the fishbowl's ordinary 10x control, and fits presentation cameras.

const Evidence := preload("res://scripts/verification/evidence_io.gd")

var scene: Node3D
var sim: Node
var construction: Node
var directory := "res://verification/stabilization/runs/civilization-visual-review"
var captures: Array[Dictionary] = []
var captured: Dictionary = {}
var started := 0
var timeout_seconds := 540.0
var first_module_id := ""
var requested_civilization := ""


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	started = Time.get_ticks_msec()
	if not OS.get_environment("ROOMSCALE_REVIEW_DIR").is_empty():
		directory = OS.get_environment("ROOMSCALE_REVIEW_DIR")
	if not OS.get_environment("ROOMSCALE_REVIEW_TIMEOUT_SECONDS").is_empty():
		timeout_seconds = clampf(float(OS.get_environment("ROOMSCALE_REVIEW_TIMEOUT_SECONDS")), 10.0, 540.0)
	if DisplayServer.get_name() == "headless":
		finish(false, "Renderer evidence requires a real renderer in a virtual display")
		return
	requested_civilization = OS.get_environment("ROOMSCALE_CIVILIZATION").strip_edges().to_lower()
	if requested_civilization.is_empty():
		requested_civilization = "clockwork"
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	OS.set_environment("ROOMSCALE_MANUAL_CAMERA", "1")
	root.size = Vector2i(1600, 900)
	var error := change_scene_to_file("res://scenes/pipeline_proof.tscn")
	if error != OK:
		finish(false, "Production scene could not load: %s" % error)
		return
	await scene_changed
	scene = current_scene as Node3D
	if scene == null or not scene.is_node_ready():
		finish(false, "Production scene did not finish normal initialization")
		return
	# Wait for the normal presentation autoload; do not manually apply its style.
	for frame in range(60):
		if scene.has_meta("civilization_definition"):
			break
		await process_frame
	var definition: Dictionary = scene.get_meta("civilization_definition", {})
	if String(definition.get("id", "")) != requested_civilization:
		finish(false, "Requested civilization did not initialize its real presentation")
		return
	construction = scene.get_node("ConstructionSystem")
	sim = scene.get_node_or_null("CivilizationSimulation")
	if sim != null:
		if not sim.founder_mode or not sim.governor.enabled or sim.camera_director.enabled:
			finish(false, "Founder evidence requires the autonomous production scenario and manual camera")
			return
		# This is the same ordinary control that a player presses, not synthetic ticks.
		(sim.spectator.speed_buttons[10.0] as Button).pressed.emit()
		if float(sim.speed) != 10.0:
			finish(false, "The ordinary 10x control did not take effect")
			return
	var camera_rig := scene.get_node("CameraRig")
	if not await capture("room-scale", camera_rig.get("_room_focus") + Vector3.UP * 12, 330.0, 52.0, 0.0, null, true):
		return
	var center := settlement_center()
	if not await capture("settlement-scale", center + Vector3.UP * 3, 62.0 if sim == null else 30.0, 40.0):
		return
	if sim == null:
		var nursery := scene.get_node("Settlement/Workshop") as Node3D
		if not await capture("nursery-close", nursery.global_position + Vector3.UP * 2.5, 18.0, 28.0, 0.3):
			return
	var citizens: Array = scene.get("_citizens")
	if citizens.is_empty():
		finish(false, "Production population is empty")
		return
	if not await capture("citizen-close", citizens[0].global_position + Vector3.UP * 0.25, 1.8, 18.0, 0.3, citizens[0]):
		return
	if sim == null:
		var navigation := scene.get_node("SurfaceNavigation")
		if not scene.select_goal_surface(String(navigation.goal_surface_id)) or not bool(scene.issue_reach_explore().get("accepted", false)):
			finish(false, "Established production Reach / Explore action was rejected")
			return
	while elapsed() < timeout_seconds:
		if sim != null and not await observe_founder_modules():
			return
		if not await observe_traversal():
			return
		if missing_phases().is_empty():
			finish(true)
			return
		await create_timer(0.025).timeout
	finish(false, "Wall-clock deadline reached; unavailable phases: %s" % missing_phases())


func observe_founder_modules() -> bool:
	var projects: Array = sim.development.projects
	if projects.is_empty():
		return true
	if first_module_id.is_empty():
		first_module_id = String(projects[0].id)
	var project: Dictionary = projects[0]
	var module := scene.get_node_or_null(first_module_id) as Node3D
	if module != null:
		var stage := String(module.get_meta("stage", ""))
		var styled := requested_civilization != "verdant" or String(module.get_meta("verdant_signature", "")) == "%s:%s" % [project.kind, stage]
		var phase := "founder-module-" + stage.to_lower()
		if styled and stage in ["FOUNDATION", "FRAME", "SHELL", "COMPLETE"] and not captured.has(phase):
			if not await capture(phase, module.global_position + Vector3.UP * 1.0, 18.0, 36.0, 0.3):
				return false
	if not captured.has("earned-settlement") and sim.development.count("workshop") > 0 and sim.development.count("depot") > 0 and sim.development.count("shelter") > 0:
		if not await capture("earned-settlement", settlement_center() + Vector3.UP * 2, 100.0, 42.0):
			return false
	return true


func observe_traversal() -> bool:
	if not bool(construction.get("project_created")):
		return true
	var status: Dictionary = construction.status()
	var site: Vector3 = construction.get("site_position")
	if not captured.has("active-construction") and int(status.completed_stages) == 1 and String(status.active_stage) == "winch" and float(status.stage_progress) >= 0.2 and float(status.stage_progress) < 0.8:
		var rendered_site := scene.get_node_or_null("VerdantConstructionSite" if requested_civilization == "verdant" else "GrappleConstructionSite")
		if rendered_site != null:
			if not await capture("active-construction", site + Vector3.UP * 4, 26.0, 38.0, 0.45):
				return false
	if bool(construction.get("traversal_deployed")):
		var path: Array[Vector3] = construction.get("_deployment_path")
		if path.size() < 2:
			finish(false, "Completed production traversal has no real route")
			return false
		if requested_civilization == "verdant":
			var vine := scene.get_node_or_null("VerdantTraversal") as Node3D
			var anchor := scene.get_node_or_null("VerdantTraversal/LivingSurfaceAnchor") as Node3D
			if vine == null or anchor == null or not anchor.is_visible_in_tree():
				return true # Normal presentation cadence may lag the production tick.
			for child in vine.get_children():
				if String(child.name).begins_with("VineSegment") and not child.is_visible_in_tree():
					return true
		# Prioritize brief real motion at 10x; the persistent route can be captured later.
		if not captured.has("citizen-climbing"):
			var room: Dictionary = scene.get("_room_definition")
			var floor_y := float(room.floor.height)
			var anchor: Vector3 = construction.get("target_anchor")
			for citizen in scene.get("_citizens"):
				var path_cursor := int(citizen.get("_path_cursor"))
				var citizen_path: Array = citizen.get("_path")
				var rising := path_cursor < citizen_path.size() and absf(citizen_path[path_cursor].y - citizen.global_position.y) > 0.01
				if citizen.task_type in ["SURFACE_TRAVERSAL", "RESOURCE_COLLECT"] and citizen.state in ["TRAVEL", "CARRY"] and rising and citizen.global_position.y > floor_y + 12.0 and citizen.global_position.y < anchor.y - 3.0:
					if not await capture("citizen-climbing", citizen.global_position + Vector3.UP * 0.25, 2.2, 22.0, 0.3, citizen):
						return false
					break
		if not captured.has("traversal-whole-route"):
			var bounds := AABB(path[0], Vector3.ZERO)
			for point in path:
				bounds = bounds.expand(point)
			if not await capture("traversal-whole-route", bounds.get_center(), maxf(45.0, bounds.size.length() * 1.7), 45.0, 0.0, null, false, path):
				return false
		var upper_phase := "upper-reclamation" if requested_civilization == "verdant" else "upper-anchor"
		if not captured.has(upper_phase):
			if requested_civilization != "verdant" or bool(root.get_node("CivilizationPresentation").get("_reclamation_applied")):
				if not await capture(upper_phase, construction.get("target_anchor") + Vector3.UP * 0.5, 27.0, 34.0, 0.3):
					return false
	return true


func capture(phase: String, focus: Vector3, distance: float, tilt: float, yaw: float = 0.0, subject: Node3D = null, show_overlay: bool = false, required_points: Array[Vector3] = []) -> bool:
	# Use the ordinary pause control to preserve brief earned states while the
	# software renderer draws. Resume the same speed after the image is saved.
	# No stage, pose, citizen position or work/material value is assigned here.
	var previous_speed := float(sim.speed) if sim != null else 0.0
	if sim != null:
		(sim.spectator.speed_buttons[0.0] as Button).pressed.emit()
	var rig := scene.get_node("CameraRig")
	var camera := scene.get_node("CameraRig/Camera") as Camera3D
	rig.set_view_mode(2 if is_instance_valid(subject) else 1)
	rig.focus_at(focus, distance, tilt, yaw)
	# Capture-only fitting preserves the ordinary gameplay zoom limits elsewhere.
	rig.distance = distance
	if is_instance_valid(subject):
		rig.yaw = subject.global_rotation.y + yaw
		rig.set_citizen_focus(subject)
	rig.call("_apply_transform")
	for attempt in range(8):
		var fits := true
		for point in required_points:
			var projected := camera.unproject_position(point)
			var viewport := root.get_visible_rect().size
			if camera.is_position_behind(point) or projected.x < 30 or projected.y < 30 or projected.x > viewport.x - 30 or projected.y > viewport.y - 30:
				fits = false
		if fits:
			break
		if attempt == 7:
			finish(false, "Could not fit the whole real traversal route in the evidence camera")
			return false
		rig.distance *= 1.25
		rig.call("_apply_transform")
	var overlay := scene.get_node("Overlay") as CanvasLayer
	var overlay_was_visible := overlay.visible
	overlay.visible = show_overlay
	var project_labels: Array[Dictionary] = []
	for label_path in ["GrappleConstructionSite/ProjectSign", "VerdantConstructionSite/ProjectSign"]:
		var label := scene.get_node_or_null(label_path) as Label3D
		if label != null:
			project_labels.append({"label": label, "visible": label.visible})
			label.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	for entry in project_labels:
		if is_instance_valid(entry.label):
			entry.label.visible = bool(entry.visible)
	if image.is_empty() or image.get_width() < 1280 or image.get_height() < 720:
		overlay.visible = overlay_was_visible
		finish(false, "Renderer returned an unusable image for %s" % phase)
		return false
	var image_path := directory.path_join(phase + ".png")
	var error := Evidence.save_png(image, image_path)
	overlay.visible = overlay_was_visible
	if error != OK:
		finish(false, "Screenshot write failed for %s (error=%d)" % [phase, error])
		return false
	var receipt := snapshot()
	receipt["paused_via_time_control"] = sim != null
	receipt["resume_speed"] = previous_speed
	receipt["phase"] = phase
	receipt["image"] = phase + ".png"
	receipt["camera"] = {"focus": rig.target, "distance": rig.distance, "tilt": rig.tilt_degrees, "yaw": rig.yaw, "overlay_visible": show_overlay, "project_labels_hidden": true}
	if is_instance_valid(subject):
		receipt["subject"] = {"id": subject.get("citizen_id"), "position": subject.global_position, "state": subject.get("state"), "task": subject.get("task_type"), "task_id": subject.get("task_id"), "travelled_distance": subject.get("travelled_distance")}
	captures.append(receipt)
	captured[phase] = true
	if sim != null:
		(sim.spectator.speed_buttons[previous_speed] as Button).pressed.emit()
	print("ROOMSCALE_CIVILIZATION_REVIEW_CAPTURE phase=%s path=%s wall=%.2fs" % [phase, image_path, elapsed()])
	return true


func settlement_center() -> Vector3:
	if sim != null:
		return sim.development.center()
	var total := Vector3.ZERO
	var count := 0
	for child in scene.get_node("Settlement").get_children():
		if child is Node3D:
			total += child.global_position
			count += 1
	return total / maxf(1, count)


func snapshot() -> Dictionary:
	var state := {"wall_seconds": elapsed()}
	if not is_instance_valid(scene):
		return state
	state["room"] = String(scene.get("_room_definition").get("id", ""))
	state["civilization"] = String(scene.get_meta("civilization_definition", {}).get("id", ""))
	state["population"] = scene.get("_citizens").size()
	state["task_summary"] = scene.get_node("TaskCoordinator").summary()
	if is_instance_valid(construction):
		state["construction"] = construction.status()
		state["deployment_cursor"] = construction.get("_deployment_cursor")
		state["real_route"] = construction.get("_deployment_path")
	if sim != null:
		state["simulation_seconds"] = sim.seconds
		state["speed"] = sim.speed
		state["production"] = sim.status()
		var projects: Array[Dictionary] = []
		for project in sim.development.projects:
			projects.append({"id": project.id, "kind": project.kind, "stage": project.stage, "state": project.state, "site": project.site, "work": project.work, "required_work": project.required_work, "delivered": project.delivered.duplicate(true), "required": project.required.duplicate(true), "completed": project.completed})
		state["earned_projects"] = projects
	return state


func missing_phases() -> Array[String]:
	var required: Array[String] = ["room-scale", "settlement-scale", "citizen-close", "active-construction", "traversal-whole-route", "citizen-climbing"]
	required.append("upper-reclamation" if requested_civilization == "verdant" else "upper-anchor")
	if sim != null:
		required.append_array(["founder-module-foundation", "founder-module-frame", "founder-module-shell", "founder-module-complete", "earned-settlement"])
	var missing: Array[String] = []
	for phase in required:
		if not captured.has(phase):
			missing.append(phase)
	return missing


func elapsed() -> float:
	return float(Time.get_ticks_msec() - started) / 1000.0


func finish(passed: bool, reason: String = "") -> void:
	var receipt := {"result": "PASS" if passed else "FAIL", "reason": reason, "source_sha": OS.get_environment("GITHUB_SHA"), "engine": Engine.get_version_info().string, "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "wall_timeout_seconds": timeout_seconds, "missing_phases": missing_phases(), "final": snapshot(), "captures": captures}
	var error := Evidence.save_json(receipt, directory.path_join("receipt.json"))
	if error != OK:
		passed = false
		reason += " Receipt write failed (error=%d)" % error
	if passed:
		print("ROOMSCALE_CIVILIZATION_REVIEW_PASS civilization=%s captures=%d wall=%.2fs" % [requested_civilization, captures.size(), elapsed()])
	else:
		push_error("ROOMSCALE_CIVILIZATION_REVIEW_FAIL " + reason)
	quit(0 if passed else 1)
