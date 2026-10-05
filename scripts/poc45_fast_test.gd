extends SceneTree
const Journal := preload("res://scripts/event_journal.gd")
const Governor := preload("res://scripts/autonomous_governor.gd")
const Population := preload("res://scripts/population_system.gd")
var failures: Array[String] = []
var checks: Array[String] = []
class TraversalFixture extends RefCounted:
	var project_created := false
	var traversal_deployed := false
	var site_position := Vector3.ZERO
	var target_region := ""
	var delivered := {"wood": 0, "metal": 0}
	func requirements() -> Dictionary: return {"wood": 4, "metal": 4}
	func status() -> Dictionary: return {"project_created": project_created}
class DevelopmentFixture extends RefCounted:
	var requests := 0
	func shortage() -> Dictionary: return {"wood": 0, "metal": 0}
	func consider(_state: Dictionary) -> void: requests += 1
class StrategicFixture extends Node:
	var seconds := 5.0
	var planner := preload("res://scripts/civilization_planner.gd").new()
	var economy := preload("res://scripts/economy_system.gd").new()
	var resources := preload("res://scripts/resource_system.gd").new()
	var salvage := preload("res://scripts/salvage_system.gd").new()
	var journal := preload("res://scripts/event_journal.gd").new()
	var construction := TraversalFixture.new()
	var development := DevelopmentFixture.new()
	var population: RefCounted
	var coordinator := {"depot_station": Vector3.ZERO}
	func status() -> Dictionary: return {"food_days": economy.forecast("food", 50), "water_days": economy.forecast("water", 50), "population": 50, "shelter": 50, "urgent": 0}
	func secure_resource(resource: String) -> bool: return planner.secure(resource)
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks.append(label)
	if not value:
		failures.append(label)
		push_error("POC45_FAST_FAIL " + label)
func run() -> void:
	var journal := Journal.new()
	check(journal.record(0, "governor", "stable") and not journal.record(1, "governor", "stable"), "duplicate suppression")
	for index in range(400): journal.record(index, "cohort_joined", str(index), {}, Vector3.ZERO, "cohort:%d" % index)
	check(journal.events.size() == journal.limit and journal._states.size() <= journal.limit * 2 and journal.events[-1].major, "bounded journal, suppression and major classification")
	var governor := Governor.new()
	var state := {"food_days": 3.0, "water_days": 0.5}
	check(governor.crisis(state, 0), "critical water survival")
	state.water_days = 1.5
	check(governor.crisis(state, 60), "hysteresis retains survival between thresholds")
	state.water_days = 3
	check(not governor.crisis(state, 60), "healthy recovery exits survival")
	state.food_days = 0.2
	check(governor.crisis(state, 70), "critical food survival")
	governor._changed = 70
	state.food_days = 3
	check(governor.crisis(state, 75) and not governor.crisis(state, 105), "minimum hold cooldown")
	var strategic := StrategicFixture.new()
	strategic.economy.configure({"food": 300, "water": 100})
	var decision := Governor.new()
	decision.enabled = true
	decision.tick(strategic)
	check(strategic.planner.priorities.Survival == 4 and strategic.planner.directives.has("water") and strategic.development.requests == 0, "water action uses strategic interface and crisis suppresses development")
	var event_count: int = strategic.journal.events.size()
	decision.tick(strategic)
	check(decision.evaluations == 1 and strategic.journal.events.size() == event_count, "bounded planning frequency")
	strategic.seconds = 40
	strategic.economy.configure({"food": 300, "water": 450})
	decision.tick(strategic)
	strategic.seconds = 45
	decision.tick(strategic)
	check(not decision.emergency and strategic.planner.directives.size() == 1 and strategic.development.requests > 0, "stable reserves do not repeatedly issue emergency directives")
	strategic.seconds = 50
	strategic.economy.configure({"food": 30, "water": 450})
	decision.tick(strategic)
	check(strategic.planner.directives.has("food") and decision.emergency, "critical food issues generalized Secure Food")
	strategic.seconds = 55
	strategic.construction.project_created = true
	decision.tick(strategic)
	check(decision.mode == "MATERIALS" and decision.reason.contains("wood/metal"), "material blocker selects resource acquisition")
	strategic.free()
	var population := Population.new()
	var growth := {"population": 50, "shelter": 50, "food_days": 3.0, "water_days": 3.0, "urgent": 0}
	check(population.eligibility(growth, false, false).contains("shelter"), "growth requires whole cohort shelter")
	growth.shelter = 60
	growth.water_days = 0.5
	check(population.eligibility(growth, false, false).contains("unsafe"), "unsafe reserves reject growth")
	growth.water_days = 3
	check(population.eligibility(growth, false, false).is_empty(), "healthy cohort eligibility")
	check(not population.eligibility(growth, true, false).is_empty() and not population.eligibility(growth, false, true).is_empty(), "emergency and project deadlock reject growth")
	growth.population = 150
	check(population.eligibility(growth, false, false).contains("cap"), "hard cap")
	OS.set_environment("ROOMSCALE_ROOM", "room_poc45")
	OS.set_environment("ROOMSCALE_FISHBOWL", "0")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	# Initialize this isolated fixture before creating any economy reservations.
	sim.economy.configure({"food": 5000, "water": 5000, "wood": 30, "metal": 20})
	for tick in range(1000): sim.step()
	check(not sim.governor.enabled and sim.governor.evaluations == 0 and sim.citizens.size() == 50 and sim.salvage.total_work == 0 and sim.planner.directives.is_empty() and sim.development.projects.is_empty(), "normal mode stays manual")
	var candidates: Array[Dictionary] = sim.governor.candidates(sim, {"wood": 10, "metal": 4})
	check(not candidates.is_empty() and sim.governor.rejections.get("desk", "").contains("source"), "safe salvage ranking rejects source support")
	check(candidates == sim.governor.candidates(sim, {"wood": 10, "metal": 4}), "salvage ranking deterministic")
	var candidate_id := String(candidates[0].id)
	sim.resources.objects[candidate_id].data["resource_profile"] = {"protected": true}
	check(not sim.governor.candidates(sim, {"wood": 10, "metal": 4}).any(func(c: Dictionary) -> bool: return c.id == candidate_id), "explicit protected salvage rejected")
	sim.resources.objects[candidate_id].data.erase("resource_profile")
	var original_kind: String = sim.resources.objects[candidate_id].data.kind
	sim.resources.objects[candidate_id].data.kind = "settlement"
	check(not sim.governor.candidates(sim, {"wood": 10, "metal": 4}).any(func(c: Dictionary) -> bool: return c.id == candidate_id), "settlement infrastructure salvage rejected")
	sim.resources.objects[candidate_id].data.kind = original_kind
	sim.salvage.objects[candidate_id].stage = sim.salvage.objects[candidate_id].stages.size()
	check(not sim.governor.candidates(sim, {"wood": 10, "metal": 4}).any(func(c: Dictionary) -> bool: return c.id == candidate_id), "depleted salvage rejected")
	sim.salvage.objects[candidate_id].stage = 0
	var nav: Node = sim.coordinator.navigation
	var reachable_definition: Dictionary = nav.room_definition.duplicate(true)
	nav.room_definition.objects.append({"id": "test_access_blocker", "position": [0, 0, 0], "dimensions": [240, 10, 180], "blocks_navigation": true})
	nav.refresh_navigation()
	check(sim.governor.candidates(sim, {"wood": 10, "metal": 4}).is_empty() and sim.governor.rejections.values().has("inaccessible to real workers"), "unsafe unreachable salvage rejected")
	nav.room_definition = reachable_definition
	nav.refresh_navigation()
	var nav_before: Dictionary = nav.room_definition.duplicate(true)
	var obstacles: Array = nav.obstacle_rects.duplicate(true)
	var solid := []
	for x in range(nav.grid.region.size.x):
		for z in range(nav.grid.region.size.y): solid.append(nav.grid.is_point_solid(Vector2i(x, z)))
	check(not sim.development.valid_site(Vector3(-58, 0, -52)) and not sim.development.valid_site(Vector3(10000, 0, 0)), "collision and bounds rejection")
	check(nav.room_definition == nav_before and nav.obstacle_rects == obstacles, "rejected site does not alter definition/obstacles")
	var current := []
	for x in range(nav.grid.region.size.x):
		for z in range(nav.grid.region.size.y): current.append(nav.grid.is_point_solid(Vector2i(x, z)))
	check(current == solid, "rejected site leaves every navigation cell unchanged")
	var site1: Dictionary = sim.development.select_site()
	var site2: Dictionary = sim.development.select_site()
	check(site1.valid and site1 == site2 and sim.development.valid_site(site1.position), "deterministic derived valid build site")
	check(nav.room_definition == nav_before and nav.obstacle_rects == obstacles, "accepted site evaluation remains transactional")
	# Isolated fixture initialization; full scenarios never inject resources.
	for family in ["Survival", "Resources", "Construction"]: sim.planner.set_priority(family, 3)
	sim.planner.set_priority("Exploration", 1)
	check(sim.development.request("housing"), "generalized housing request")
	check(sim.needs.shelter_capacity == 50 and sim.development.active.work == 0, "project request creates no instant shelter or work")
	for batch in range(100):
		for tick in range(100): sim.step()
		if sim.development.count("housing") == 1: break
		await process_frame
	check(sim.development.count("housing") == 1 and sim.needs.shelter_capacity == 60, "real citizens build housing effect")
	if sim.development.count("housing") == 1:
		var project: Dictionary = sim.development.projects[0]
		check(project.delivery_distance > 10 and project.work_by_citizen.size() > 0 and project.work >= project.required_work, "physical delivery and recorded worker effort")
		check(sim.economy.project_consumed.wood == 10 and sim.economy.project_consumed.metal == 2 and sim.economy.audit().is_empty(), "real conserved development costs")
		sim.development.apply_effect(project)
		check(sim.needs.shelter_capacity == 60 and nav.is_obstacle_position(project.site) and not nav.is_walkable(project.site), "housing effect once and completed navigation obstacle")
	check(sim.development.request("workshop"), "generalized workshop request")
	var workshop_stages := {}
	for batch in range(100):
		for tick in range(100):
			sim.step()
			if not sim.development.active.is_empty(): workshop_stages[sim.development.active.stage] = true
		if sim.development.count("workshop") == 1: break
		await process_frame
	check(sim.development.workshop_count == 1 and sim.development.count("workshop") == 1, "real functional workshop")
	check(workshop_stages.has("FRAME") and workshop_stages.has("SHELL"), "workshop distinct intermediate construction stages")
	if sim.development.count("workshop") == 1:
		sim.development.apply_effect(sim.development.projects[-1])
		check(sim.development.workshop_count == 1, "workshop effect exactly once")
	var before: int = sim.citizens.size()
	var forecast: float = sim.economy.forecast("water", before)
	var now: float = sim.seconds
	sim.population.stable_since = now - 300
	sim.population.evaluate(sim, sim.status(), false, false)
	check(sim.citizens.size() == before + Population.COHORT and scene.get_node_or_null("Citizen55") != null, "whole cohort creates real citizen nodes")
	check(sim.economy.forecast("water", sim.citizens.size()) < forecast and not sim.citizens[-1].needs.is_empty(), "real needs and immediate increased demand")
	sim.population.stable_since = now - 300
	sim.population.evaluate(sim, sim.status(), false, false)
	check(sim.citizens.size() == before + Population.COHORT, "growth cooldown prevents repeated cohort")
	for tick in range(7000): sim.step()
	check(sim.self_care_completed.has(54) and sim.citizens[-1].travelled_distance > 0, "new citizens move and complete normal self care")
	check(sim.economy.audit().is_empty() and sim.resources.audit().is_empty(), "final conserved accounting")
	var director := preload("res://scripts/fishbowl_camera_director.gd").new()
	scene.add_child(director)
	director.configure(sim)
	director.set_process(false)
	var camera_before: Dictionary = sim.status().duplicate(true)
	var positions := []
	for citizen in sim.citizens: positions.append(citizen.global_position)
	director.advance(7)
	check(director.shots == 0, "camera respects minimum real-time shot duration")
	director.advance(1)
	check(director.shots == 1 and director.valid_focus(director.last_focus) and not director.valid_focus(Vector3(INF, 0, 0)), "camera chooses valid bounded focus")
	director.enabled = false
	director.advance(40)
	check(director.shots == 1, "automatic camera can be disabled")
	var after_positions := []
	for citizen in sim.citizens: after_positions.append(citizen.global_position)
	check(sim.status() == camera_before and positions == after_positions, "camera has no simulation side effects")
	for citizen in sim.citizens: citizen.refresh_visual_lod()
	check(sim.status() == camera_before, "paused camera LOD refresh does not advance simulation")
	var speed_buttons: Array = []
	for child in sim.hud.get_children():
		if child is HBoxContainer: speed_buttons = child.get_children()
	var speeds := [0.0, 1.0, 4.0, 10.0]
	for index in range(speeds.size()):
		speed_buttons[index].pressed.emit()
		var before_seconds: float = sim.seconds
		sim.advance_elapsed_time(0.5)
		check(sim.speed == speeds[index] and absf(sim.seconds - before_seconds - speeds[index] * 0.5) < 0.001, "Pause/1x/4x/10x authoritative fixed-step speed %s" % speeds[index])
	print("POC45_FAST_" + ("PASS" if failures.is_empty() else "FAIL") + " checks=" + JSON.stringify(checks) + " failures=" + str(failures))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
