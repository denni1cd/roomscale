extends SceneTree
## Narrow regressions against production authorization, navigation and profiles.
const Simulation := preload("res://scripts/civilization_simulation.gd")
const Coordinator := preload("res://scripts/task_coordinator.gd")
const Navigation := preload("res://scripts/floor_navigation.gd")
const Resources := preload("res://scripts/resource_system.gd")
const Definition := preload("res://scripts/room_definition.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
	else: print("POC4_CLEANUP_CHECK_PASS " + label)

func grid_state(nav: Node) -> Array[bool]:
	var result: Array[bool] = []
	for x in range(nav.grid.region.size.x):
		for y in range(nav.grid.region.size.y): result.append(nav.grid.is_point_solid(Vector2i(x, y)))
	return result

func _run() -> void:
	var wood := Resources.derive({"kind": "table", "dimensions": [20, 20, 20]})
	check(wood.material == "wood" and wood.harvestable and wood.stages.size() == 4 and wood.stages[1].yields.has("wood"), "inferred wood derives wood stages")
	var metal := Resources.derive({"kind": "table", "dimensions": [20, 20, 20], "appearance": {"material": "metal"}})
	check(metal.material == "metal" and metal.harvestable and metal.stages.size() == 2 and metal.stages[0].yields == {"metal": 5.0}, "appearance metal derives metal stages")
	var override := Resources.derive({"kind": "table", "dimensions": [20, 20, 20], "resource_profile": {"material": "metal"}})
	check(override == metal, "explicit material override influences automatic stages")
	var custom := [{"name": "CUSTOM", "work": 3.0, "yields": {"wood": 7.0, "metal": 1.0}}]
	var explicit := Resources.derive({"kind": "table", "resource_profile": {"material": "metal", "stages": custom}})
	check(explicit.material == "metal" and explicit.stages == custom, "explicit custom stages retain precedence")
	check(not Resources.validate_profile({"material": "stone"}).is_empty(), "invalid material rejected by profile validator")
	check(not Resources.derive({"kind": "unknown"}).harvestable and not Resources.derive({"kind": "plant"}).harvestable, "unknown nonmaterial objects remain conservative")
	var canonical := Definition.load_file("res://rooms/room_poc4.json")
	check(canonical.ok, "canonical RoomDefinition remains valid")
	for object in canonical.definition.objects:
		if object.id != "chair": continue
		var profile := Resources.derive(object)
		var yields := {"wood": 0.0, "metal": 0.0}
		for stage in profile.stages:
			for resource in stage.yields: yields[resource] += float(stage.yields[resource])
		check(profile.material == "wood" and profile.stages.size() == 4 and yields == {"wood": 13.0, "metal": 4.0}, "canonical stages and total yields unchanged")
	var invalid: Dictionary = canonical.definition.duplicate(true)
	invalid.objects[0].resource_profile = {"material": "stone"}
	check(not Definition.validate(invalid).is_empty(), "invalid material rejected by RoomDefinition validator")

	# Actual obstacle rectangles block all four physical approaches. Padding-only
	# space would open if the rejected attempt leaked its proposed change.
	var item := {"id": "rejected_item", "kind": "table", "position": [0, 0, 0], "dimensions": [10, 10, 10], "blocks_navigation": true, "navigation_padding": [6, 0, 6]}
	var definition := {"id": "authorization_fixture", "dimensions": [120, 120], "floor": {"center": [0, 0, 0], "height": 0}, "objects": [item]}
	var points: Array[Vector3] = [Vector3(0, 0, 5.22), Vector3(0, 0, -5.22), Vector3(5.22, 0, 0), Vector3(-5.22, 0, 0)]
	for i in range(points.size()):
		var at := points[i]
		definition.objects.append({"id": "blocker_%d" % i, "position": [at.x, at.y, at.z], "dimensions": [2, 1, 2], "blocks_navigation": true})
	var nav := Navigation.new()
	nav.configure(definition)
	nav.refresh_navigation()
	var coordinator := Coordinator.new()
	coordinator.navigation = nav
	coordinator.depot_station = Vector3(-40, 0, -40)
	var sim := Simulation.new()
	sim.coordinator = coordinator
	sim.resources.configure({"objects": [item]})
	sim.salvage.configure(sim.resources.objects)
	var before_definition: Dictionary = nav.room_definition.duplicate(true)
	var before_obstacles: Array = nav.obstacle_rects.duplicate(true)
	var before_grid := grid_state(nav)
	var padding_point := Vector3(10, 0, 10)
	var before_path: Array[Vector3] = nav.path_between(coordinator.depot_station, padding_point)
	check(not sim.salvage.objects.rejected_item.authorized and sim.resources.objects.rejected_item.profile.protected, "object starts protected and unauthorized")
	check(nav.is_obstacle_position(padding_point) and not nav.is_walkable(padding_point), "protected padding blocks citizen access before attempt")
	check(not sim.authorize_salvage("rejected_item"), "authorization fails with all physical approaches obstructed")
	check(not sim.salvage.objects.rejected_item.authorized and sim.planner.authorized.is_empty() and sim.salvage_targets.is_empty(), "rejection preserves authorization and planner targets")
	check(nav.room_definition == before_definition and nav.obstacle_rects == before_obstacles and grid_state(nav) == before_grid, "rejection leaves definition obstacles and every grid cell unchanged")
	check(nav.is_obstacle_position(padding_point) and not nav.is_walkable(padding_point) and nav.path_between(coordinator.depot_station, padding_point) == before_path, "citizens still cannot gain rejected padding access")
	for point in points: check(nav.is_obstacle_position(point), "rejected salvage approach remains obstructed at %s" % point)
	# Remove only the fixture's blocking objects: a valid request must still commit
	# the edge-access change and authorization through production code.
	definition.objects = [item]
	nav.configure(definition)
	nav.refresh_navigation()
	check(sim.authorize_salvage("rejected_item") and sim.salvage.objects.rejected_item.authorized and sim.planner.authorized.has("rejected_item"), "valid reachable authorization still succeeds")
	check(not nav.is_obstacle_position(padding_point) and nav.is_obstacle_position(Vector3.ZERO), "successful authorization opens edge access while retaining physical obstacle")
	sim.free()
	coordinator.free()
	nav.free()
	if not failures.is_empty():
		push_error("POC4_CLEANUP_FAIL: " + str(failures))
		quit(1)
		return
	print("POC4_CLEANUP_PASS rollback=unchanged_live_navigation material_override=consistent canonical_yields=13wood_4metal")
	quit()
