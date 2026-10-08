extends RefCounted
## Society boards/projects share the existing room and navigation nodes.
const Simulation := preload("res://scripts/civilization_simulation.gd")
const Coordinator := preload("res://scripts/task_coordinator.gd")
const Citizen := preload("res://scripts/citizen_agent.gd")
const Construction := preload("res://scripts/construction_system.gd")
const Population := preload("res://scripts/population_system.gd")
const Definitions := preload("res://scripts/civilization_definition.gd")
const World := preload("res://scripts/world_simulation.gd")

static func start(scene: Node3D) -> Node:
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/clockwork_vs_verdant.json"))
	var room: Dictionary = scene.get("_room_definition")
	if room.get("start_slots", []).size() < scenario.participants.size():
		push_error("CONFLICT_START_INVALID: room needs generic start_slots")
		scene.get_tree().quit(1)
		return null
	var world := World.new()
	world.name = "WorldSimulation"
	scene.add_child(world)
	world.configure(scene)
	# Legacy roster has not advanced or initialized finite room state.
	for citizen in scene.get("_citizens"): citizen.free()
	scene.get("_citizens").clear()
	world.next_citizen_id = 0
	scene.get_node("TaskCoordinator").free()
	scene.get_node("ConstructionSystem").free()
	var floor_nav: Node = scene.get_node("FloorNavigation")
	var surface_nav: Node = scene.get_node("SurfaceNavigation")
	for index in range(scenario.participants.size()):
		var participant: Dictionary = scenario.participants[index]
		var slot: Dictionary = {}
		for candidate in room.start_slots:
			if candidate.id == participant.start_slot: slot = candidate
		var view: Dictionary = room.duplicate(true)
		view.spawn = slot.spawn
		view.start.origin = slot.home
		view.start.population = slot.population
		view.construction.depot_pickup = slot.home
		view.activity_stations = {"workshop":[slot.home],"housing":slot.home,"work_area":slot.home,"patrol":[slot.home]}
		var coordinator := Coordinator.new()
		coordinator.name = "TaskCoordinator" if index == 0 else "TaskCoordinator_%s" % participant.instance_id
		coordinator.instance_id = participant.instance_id
		coordinator.navigation = floor_nav
		coordinator.surface_navigation = surface_nav
		coordinator.configure_room(view)
		scene.add_child(coordinator)
		var roster: Array = []
		var starts := Population.initial_positions(view, floor_nav, int(slot.population))
		if starts.size() != int(slot.population):
			push_error("CONFLICT_START_INVALID: legal complete roster unavailable")
			scene.get_tree().quit(1)
			return null
		for at in starts:
			if world.citizens.any(func(c: Node3D) -> bool: return c.global_position.distance_to(at) < 2.0):
				push_error("CONFLICT_START_INVALID: overlapping start slots")
				scene.get_tree().quit(1)
				return null
			var id := world.allocate_citizen_id()
			coordinator._enqueue_for(id, 0)
			var citizen := Citizen.new()
			citizen.initialize(id, at, floor_nav, coordinator)
			scene.add_child(citizen)
			roster.append(citizen)
			world.citizens.append(citizen)
		var construction := Construction.new()
		construction.name = "ConstructionSystem" if index == 0 else "ConstructionSystem_%s" % participant.instance_id
		construction.surface_navigation = surface_nav
		construction.configure(coordinator, floor_nav, roster, scene, view)
		coordinator.construction_system = construction
		coordinator.reach_goal_updated.connect(construction.on_reach_goal_updated)
		scene.add_child(construction)
		var runtime := Simulation.new()
		runtime.name = "CivilizationSimulation" if index == 0 else "CivilizationRuntime_%s" % participant.instance_id
		scene.add_child(runtime)
		var config: Dictionary = room.civilization.duplicate(true)
		config.merge({"instance_id":participant.instance_id,"definition":Definitions.load_id(participant.definition_id).definition,"room_definition":view,"coordinator":coordinator,"construction":construction,"citizens":roster,"presentation":false,"autonomous":true},true)
		runtime.configure(scene, config)
		runtime.set_process(index == 0)
		if index == 0:
			scene.set("_task_coordinator",coordinator)
			scene.set("_construction_system",construction)
		world.present_home(runtime, Vector3(slot.home[0],slot.home[1],slot.home[2]))
	world.enable_conflict(scenario)
	scene.get_node("CameraRig").set_citizen_focus(world.citizens[0])
	return world.runtimes[0]
