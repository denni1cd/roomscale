extends RefCounted
## Validate scenario data before replacing the scene's startup roster.
const Definitions := preload("res://scripts/civilization_definition.gd")
const Resolver := preload("res://scripts/innovation_system.gd")
const Population := preload("res://scripts/population_system.gd")
const Validation := preload("res://scripts/innovation_validation.gd")

static func load_requested(room: Dictionary, navigation: Node) -> Dictionary:
	var id := OS.get_environment("ROOMSCALE_CONFLICT_SCENARIO")
	if id.is_empty(): id = "clockwork_vs_verdant"
	var regex := RegEx.new()
	regex.compile("^[a-z0-9][a-z0-9_-]*$")
	if regex.search(id) == null: return {"ok":false,"errors":["Invalid scenario ID"]}
	var path := "res://scenarios/%s.json" % id
	if not FileAccess.file_exists(path): return {"ok":false,"errors":["Unknown scenario: " + id]}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return prepare(parsed, room, navigation)

static func prepare(value: Variant, room: Dictionary, navigation: Node) -> Dictionary:
	var errors: Array[String] = []
	if not value is Dictionary: return {"ok":false,"errors":["Scenario must be an object"]}
	var scenario: Dictionary = value
	if not Validation.nonempty_string(scenario.get("id")): errors.append("Scenario requires an ID")
	if not Validation.nonnegative_number(scenario.get("pre_contact_seconds")): errors.append("Invalid pre-contact time")
	if not scenario.get("participants") is Array or scenario.participants.size() < 2: errors.append("Scenario requires at least two participants")
	if not scenario.get("strategic_site") is String or not room.get("strategic_sites", []).any(func(site: Dictionary) -> bool: return site.id == scenario.strategic_site): errors.append("Unknown strategic site")
	if not scenario.get("site_benefits", {}) is Dictionary: errors.append("Site benefits must be an object")
	else:
		var benefits: Dictionary = scenario.get("site_benefits", {})
		if benefits.has("space_capacity") and not Validation.nonnegative_number(benefits.space_capacity): errors.append("Invalid strategic space capacity")
		for key in ["resource_sources", "resource_weights"]:
			if benefits.has(key) and not benefits[key] is Dictionary: errors.append("Invalid resource benefits")
			elif benefits.has(key):
				for resource in benefits[key]:
					if resource not in ["wood","metal","food","water","mechanical_parts"]: errors.append("Unknown benefit resource")
					if key == "resource_weights" and not Validation.nonnegative_number(benefits[key][resource]): errors.append("Invalid resource weight")
					if key == "resource_sources" and not Validation.string_array(benefits[key][resource]): errors.append("Invalid source IDs")
					elif key == "resource_sources":
						for source_id in benefits[key][resource]:
							if not room.objects.any(func(object: Dictionary) -> bool: return object.id == source_id and float(preload("res://scripts/resource_system.gd").derive(object).contents.get(resource, 0)) > 0): errors.append("Unknown source for benefit resource")
	if not errors.is_empty(): return {"ok":false,"errors":errors}
	var prepared: Array[Dictionary] = []
	var ids := {}
	var slots := {}
	var occupied: Array[Vector3] = []
	for participant in scenario.participants:
		if not participant is Dictionary or not Validation.nonempty_string(participant.get("instance_id")) or not Validation.nonempty_string(participant.get("definition_id")) or not Validation.nonempty_string(participant.get("start_slot")):
			errors.append("Participant requires string identity and slot fields")
			continue
		var identity_pattern := RegEx.new()
		identity_pattern.compile("^[a-z0-9][a-z0-9_-]*$")
		if identity_pattern.search(participant.instance_id) == null: errors.append("Invalid instance namespace")
		if ids.has(participant.instance_id) or slots.has(participant.start_slot): errors.append("Duplicate participant or start slot")
		ids[participant.instance_id] = true
		slots[participant.start_slot] = true
		if participant.has("home_space_capacity") and not Validation.nonnegative_number(participant.home_space_capacity): errors.append("Invalid home space capacity")
		var definition := Definitions.load_id(participant.definition_id)
		if not definition.ok: errors.append_array(definition.errors)
		if bool(room.civilization.get("innovation", OS.get_environment("ROOMSCALE_INNOVATION") == "1")):
			var innovation := Resolver.create(participant.definition_id, [], String(room.civilization.get("innovation_catalog_path", "")))
			if not innovation.ok: errors.append_array(innovation.errors)
			elif innovation.system.catalog.solution_list().any(func(solution: Dictionary) -> bool: return solution.has("deployment") and not preload("res://scripts/solution_deployment.gd").supported(solution)): errors.append("Unsupported deployment adapter")
		var slot: Dictionary = {}
		for candidate in room.get("start_slots", []):
			if candidate.id == participant.start_slot: slot = candidate
		if slot.is_empty():
			errors.append("Unknown start slot")
			continue
		var view := room.duplicate(true)
		view.spawn = slot.spawn
		view.start.origin = slot.home
		view.start.population = slot.population
		view.construction.depot_pickup = slot.home
		view.activity_stations = {"workshop":[slot.home],"housing":slot.home,"work_area":slot.home,"patrol":[slot.home]}
		var starts := Population.initial_positions(view, navigation, int(slot.population))
		if starts.size() != int(slot.population): errors.append("Legal complete roster unavailable")
		for at in starts:
			if occupied.any(func(point: Vector3) -> bool: return point.distance_to(at) < 2.0): errors.append("Overlapping start slots")
			occupied.append(at)
		prepared.append({"participant":participant,"slot":slot,"view":view,"starts":starts,"definition":definition.definition})
	return {"ok":errors.is_empty(),"errors":errors,"scenario":scenario,"prepared":prepared if errors.is_empty() else []}
