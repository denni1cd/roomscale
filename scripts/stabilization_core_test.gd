extends SceneTree
## Isolated fixtures exercise production boundaries; campaign progression stays earned.
const Room := preload("res://scripts/room_definition.gd")
const Floor := preload("res://scripts/floor_navigation.gd")
const Surface := preload("res://scripts/surface_navigation.gd")
const Population := preload("res://scripts/population_system.gd")
const Resources := preload("res://scripts/resource_system.gd")
const World := preload("res://scripts/pipeline_proof.gd")
const Simulation := preload("res://scripts/civilization_simulation.gd")
const Coordinator := preload("res://scripts/task_coordinator.gd")
var failures: Array[String] = []

class FocusFixture extends Node3D:
	func set_citizen_focus(_citizen: Node3D) -> void: pass

class WorldFixture extends World:
	func _ready() -> void: pass

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
	else: print("STABILIZATION_CORE_CHECK_PASS " + label)

func run() -> void:
	test_profiles()
	test_return_route()
	test_initial_population()
	test_photo_population()
	test_object_identity()
	print("STABILIZATION_CORE_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func test_profiles() -> void:
	for material in ["wood", "metal"]:
		var object := {"kind": "table", "dimensions": [20,20,20], "appearance": {"material": material}}
		var expected := Resources.derive(object)
		object.appearance.material = material.to_upper()
		check(Resources.derive(object) == expected, "case-insensitive " + material + " keeps salvage stages")
	var definition: Dictionary = Room.load_file("res://rooms/room_a.json").definition
	definition.objects[1].kind = "unknown"
	definition.objects[1].resource_profile = {"harvestable": true}
	check(Room.validate(definition).any(func(error: String) -> bool: return error.contains("requires salvage stages")), "harvestable unknown material needs effective stages")
	definition.objects[1].resource_profile.stages = [{"name":"DEPLETED", "work":1, "yields":{"wood":1}}]
	check(Room.validate(definition).is_empty(), "custom stages retain unknown material support")
	definition.objects[1].appearance = {"material": []}
	check(not Room.validate(definition).is_empty(), "malformed material returns validator diagnostics")
	definition.objects[1].appearance = {"material": "wood"}
	definition.objects[1].kind = {}
	check(not Room.validate(definition).is_empty(), "malformed kind returns validator diagnostics")

func test_return_route() -> void:
	var definition := {"id":"return_fixture", "dimensions":[80,80], "floor":{"center":[0,0,0], "height":0}, "target_surface_id":"TOP", "objects":[
		{"id":"divider", "position":[0,0,0], "dimensions":[4,10,80], "blocks_navigation":true},
		{"id":"platform", "position":[20,0,0], "dimensions":[10,20,10], "blocks_navigation":false, "surface":{"region_id":"TOP", "height":20, "anchor":[20,20,0]}}]}
	var nav := Floor.new()
	nav.configure(definition)
	nav.refresh_navigation()
	var surfaces := Surface.new()
	surfaces.configure(definition, nav)
	var link: Array[Vector3] = [Vector3(20,0,0),Vector3(20,20,0)]
	check(surfaces.connect_regions("FLOOR","TOP",link), "return fixture link registered")
	var start := Vector3(22,20,2)
	var blocked := surfaces.route_between("TOP","FLOOR",start,Vector3(-20,0,0))
	check(not blocked.reachable and blocked.path.is_empty(), "surface return rejects disconnected floor destination")
	var finish := Vector3(30,0,20)
	var reachable := surfaces.route_between("TOP","FLOOR",start,finish)
	check(reachable.reachable and reachable.path.back() == finish, "surface return reaches connected destination")
	surfaces.free()
	nav.free()

func legacy_positions(definition: Dictionary, nav: Node, count: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var center: Array = definition.spawn.center
	var dimensions: Array = definition.spawn.dimensions
	for id in range(count):
		var proposed := Vector3(float(center[0]) - float(dimensions[0]) / 2 + 4 + float(id % 10) * (float(dimensions[0])-8) / 9, float(definition.floor.height), float(center[2]) - float(dimensions[2]) / 2 + 4 + floorf(float(id)/10) * (float(dimensions[2])-8) / 4)
		var at: Vector3 = nav.nearest_walkable_position(proposed)
		var attempts := 0
		while result.any(func(existing: Vector3) -> bool: return Vector2(at.x-existing.x,at.z-existing.z).length() < 2) and attempts < 8:
			attempts += 1
			proposed += Vector3(0,0,4)
			at = nav.nearest_walkable_position(proposed)
		result.append(at)
	return result

func test_initial_population() -> void:
	for room_id in ["room_a","room_b","room_poc47"]:
		var definition: Dictionary = Room.load_file("res://rooms/" + room_id + ".json").definition
		var nav := Floor.new()
		nav.configure(definition)
		nav.refresh_navigation()
		var count := int(definition.get("start",{}).get("population",50))
		check(Population.initial_positions(definition, nav, count) == legacy_positions(definition,nav,count), room_id + " canonical initial positions unchanged")
		nav.free()
	var definition := {"id":"population_fixture", "dimensions":[120,120], "floor":{"center":[0,0,0], "height":0}, "objects":[], "spawn":{"center":[0,0,0], "dimensions":[100,0,100]}, "construction":{"depot_pickup":[0,0,0]}}
	var nav := Floor.new()
	nav.configure(definition)
	nav.refresh_navigation()
	var positions := Population.initial_positions(definition,nav,150)
	check(positions.size() == 150, "150 initial citizens receive a complete roster")
	var distinct := {}
	var safe := true
	for at in positions:
		distinct[at] = true
		safe = safe and at.is_finite() and absf(at.x) < 50 and absf(at.z) < 50 and not nav.path_between(at, Vector3.ZERO).is_empty()
	check(safe, "large roster positions are bounded and connected")
	check(distinct.size() == 150, "large initial roster positions are distinct")
	definition.spawn.dimensions = [1,0,1]
	check(Population.initial_positions(definition,nav,150).is_empty(), "insufficient spawn capacity rejects the entire roster")
	nav.free()
	# Exercise the production entity creation loop with a validated room fixture.
	definition = Room.load_file("res://rooms/room_poc47.json").definition
	definition.start.population = 150
	definition.spawn = {"center":[0,0,0],"dimensions":[220,0,160]}
	check(Room.validate(definition).is_empty(), "large initial population fixture satisfies RoomDefinition")
	var world := WorldFixture.new()
	world._room_definition = definition
	var focus := FocusFixture.new()
	focus.name = "CameraRig"
	world.add_child(focus)
	root.add_child(world)
	check(world._build_population(), "production initial roster creation succeeds atomically")
	var contiguous: bool = world._citizens.size() == 150
	for id in range(world._citizens.size()): contiguous = contiguous and world._citizens[id].citizen_id == id
	check(contiguous, "production initial population IDs are contiguous")
	world.free()

func test_photo_population() -> void:
	# Authored legacy photo rooms use small spawn seed regions for 50 citizens.
	# Create all production entities atomically at distinct connected room cells.
	for path in ["res://verification/poc2/candidates/primary/attempt-7/room_photo_luna.json", "res://verification/poc2/candidates/secondary-room/fresh-context/room_hearth_living_room_fresh.json"]:
		var definition: Dictionary = Room.load_file(path).definition
		var world := WorldFixture.new()
		world._room_definition = definition
		var focus := FocusFixture.new()
		focus.name = "CameraRig"
		world.add_child(focus)
		root.add_child(world)
		var complete: bool = world._build_population() and world._citizens.size() == 50
		var positions: Array[Vector3] = []
		var nav: Node = world.get_node("FloorNavigation")
		var depot := Room.vector3_from(definition.construction.depot_pickup)
		for id in range(world._citizens.size()):
			var citizen: Node3D = world._citizens[id]
			var at: Vector3 = citizen.global_position
			complete = complete and citizen.citizen_id == id and Population._valid_initial_position(at, positions, nav, depot)
			positions.append(at)
		check(complete, String(definition.id) + " compact legacy spawn creates all50 distinct connected production citizens")
		world.free()

func test_object_identity() -> void:
	var object := {"id":"raw/object:name", "kind":"unknown", "position":[0,0,0], "dimensions":[2,2,2], "blocks_navigation":true, "resource_profile":{"harvestable":true,"stages":[{"name":"DEPLETED","work":1,"yields":{"wood":1}}]}}
	var definition := {"id":"identity_fixture", "dimensions":[40,40], "floor":{"center":[0,0,0],"height":0}, "objects":[object]}
	var world := World.new()
	var objects := Node3D.new()
	world.add_child(objects)
	world._build_room_object(objects,object)
	var rendered: Node3D = world.get_room_object(String(object.id))
	check(rendered != null and world.get_room_object("missing") == null, "raw object ID resolves independently of Node names")
	var nav := Floor.new()
	nav.configure(definition)
	nav.refresh_navigation()
	var surfaces := Surface.new()
	surfaces.configure(definition,nav)
	var coordinator := Coordinator.new()
	coordinator.navigation = nav
	coordinator.surface_navigation = surfaces
	var sim := Simulation.new()
	sim.scene = world
	sim.coordinator = coordinator
	sim.resources.configure(definition)
	sim.salvage.configure(sim.resources.objects)
	sim.salvage.authorize(String(object.id))
	sim.salvage.work(String(object.id),0,1,Vector3.ZERO,Vector3.ZERO)
	sim.apply_salvage_stage(String(object.id))
	check(not rendered.visible and not nav.is_obstacle_position(Vector3.ZERO), "salvage updates rendered root and navigation for raw object IDs")
	sim.free()
	coordinator.free()
	surfaces.free()
	nav.free()
	world.free()
