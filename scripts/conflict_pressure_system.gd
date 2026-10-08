extends RefCounted
## Converts finite material and territorial scarcity into an inspectable conflict reason/intensity.
## Contact is not hostility: two civilizations may contest a site indefinitely without fighting.

const PEACE := 0
const COMPETITION := 1
const LIMITED_WAR := 2
const MAJOR_WAR := 3
const SURVIVAL_WAR := 4

const PEACE_THRESHOLD := 0.15
const WAR_THRESHOLD := 0.40
const MAJOR_THRESHOLD := 0.70
const SURVIVAL_THRESHOLD := 0.90
const RESOURCE_COMFORT_COVERAGE := 1.50
const SPACE_COMFORT_SATURATION := 0.60
const SPACE_CRISIS_SATURATION := 1.40

var evaluations := 0
var last_result: Dictionary = {}

static func intensity_name(value: int) -> String:
	match value:
		COMPETITION: return "COMPETITION"
		LIMITED_WAR: return "LIMITED_WAR"
		MAJOR_WAR: return "MAJOR_WAR"
		SURVIVAL_WAR: return "SURVIVAL_WAR"
	return "PEACE"

static func classify(score: float) -> int:
	if score >= SURVIVAL_THRESHOLD: return SURVIVAL_WAR
	if score >= MAJOR_THRESHOLD: return MAJOR_WAR
	if score >= WAR_THRESHOLD: return LIMITED_WAR
	if score >= PEACE_THRESHOLD: return COMPETITION
	return PEACE

static func resource_scarcity(secured_supply: float, demand: float) -> float:
	if demand <= 0: return 0.0
	var coverage := maxf(0.0, secured_supply) / demand
	return clampf((RESOURCE_COMFORT_COVERAGE - coverage) / RESOURCE_COMFORT_COVERAGE, 0.0, 1.0)

static func space_pressure(population: int, secured_capacity: float) -> float:
	if population <= 0: return 0.0
	if secured_capacity <= 0: return 1.0
	var saturation := float(population) / secured_capacity
	return clampf((saturation - SPACE_COMFORT_SATURATION) / (SPACE_CRISIS_SATURATION - SPACE_COMFORT_SATURATION), 0.0, 1.0)

static func policy_for(intensity: int) -> Dictionary:
	match intensity:
		LIMITED_WAR:
			return {"force_fraction":0.25,"min_force":2,"max_force":6,"retreat_threshold":0.70,"allow_retreat":true,"objective":"SECURE_CONTESTED_ASSET"}
		MAJOR_WAR:
			return {"force_fraction":0.50,"min_force":4,"max_force":12,"retreat_threshold":0.45,"allow_retreat":true,"objective":"BREAK_RIVAL_CONTROL"}
		SURVIVAL_WAR:
			return {"force_fraction":1.0,"min_force":2,"max_force":150,"retreat_threshold":-1.0,"allow_retreat":false,"objective":"REMOVE_EXISTENTIAL_BLOCKER"}
	return {"force_fraction":0.0,"min_force":0,"max_force":0,"retreat_threshold":1.0,"allow_retreat":true,"objective":"COEXIST"}

func evaluate(world: Node, site_id: String) -> Dictionary:
	evaluations += 1
	if not world.territory.sites.has(site_id):
		return _store({"site_id":site_id,"score":0.0,"intensity":PEACE,"intensity_name":"PEACE","cause":"NONE","resource":"","objective":"COEXIST","per_civilization":{}})
	var site: Dictionary = world.territory.sites[site_id]
	var participants: Array = site.contesting_civilizations.duplicate()
	participants.sort()
	if participants.size() < 2:
		return _store({"site_id":site_id,"score":0.0,"intensity":PEACE,"intensity_name":"PEACE","cause":"NONE","resource":"","objective":"COEXIST","per_civilization":{}})

	var benefits: Dictionary = world.scenario.get("site_benefits", site.get("benefits", {}))
	var per_civilization := {}
	for id in participants:
		per_civilization[id] = {"space":0.0,"resources":{},"secured_space":0.0}

	var best_score := 0.0
	var best_cause := "NONE"
	var best_resource := ""
	var space_value := float(benefits.get("space_capacity", 0.0))
	if space_value > 0:
		var shared_space_score := 1.0
		for id in participants:
			var runtime: Node = world.runtime_for(String(id))
			var capacity := _secured_space_capacity(world, String(id), runtime.living_population())
			var value := space_pressure(runtime.living_population(), capacity)
			per_civilization[id].space = value
			per_civilization[id].secured_space = capacity
			shared_space_score = minf(shared_space_score, value)
		if shared_space_score > best_score:
			best_score = shared_space_score
			best_cause = "SPACE"

	var resource_sources: Dictionary = benefits.get("resource_sources", {})
	var resource_weights: Dictionary = benefits.get("resource_weights", {})
	var resource_names: Array = resource_sources.keys()
	resource_names.sort()
	for resource_variant in resource_names:
		var resource := String(resource_variant)
		var source_ids: Array = resource_sources[resource] if resource_sources[resource] is Array else []
		var shared_resource_score := 1.0
		for id in participants:
			var runtime: Node = world.runtime_for(String(id))
			var demand := _resource_demand(resource, runtime.living_population())
			var secured := _secured_resource_supply(world, runtime, resource, source_ids)
			var value := resource_scarcity(secured, demand) * clampf(float(resource_weights.get(resource, 1.0)), 0.0, 1.0)
			per_civilization[id].resources[resource] = {"pressure":value,"secured_supply":secured,"demand":demand}
			shared_resource_score = minf(shared_resource_score, value)
		if shared_resource_score > best_score:
			best_score = shared_resource_score
			best_cause = "RESOURCE"
			best_resource = resource

	var intensity := classify(best_score)
	var policy := policy_for(intensity)
	var objective := String(policy.objective)
	if intensity in [LIMITED_WAR, MAJOR_WAR]:
		objective = "SECURE_TERRITORY" if best_cause == "SPACE" else "SECURE_RESOURCE_ACCESS"
	elif intensity == SURVIVAL_WAR:
		objective = "REMOVE_EXISTENTIAL_BLOCKER"
	var result := {
		"site_id":site_id,
		"score":best_score,
		"intensity":intensity,
		"intensity_name":intensity_name(intensity),
		"cause":best_cause,
		"resource":best_resource,
		"objective":objective,
		"policy":policy,
		"per_civilization":per_civilization
	}
	return _store(result)

func _store(result: Dictionary) -> Dictionary:
	last_result = result
	return result

func _resource_demand(resource: String, population: int) -> float:
	var per_person := 1.0
	if resource == "food": per_person = 2.0
	elif resource == "water": per_person = 3.0
	return maxf(1.0, float(population) * per_person)

func _secured_resource_supply(world: Node, runtime: Node, resource: String, contested_sources: Array) -> float:
	var total := float(runtime.economy.available.get(resource, 0.0))
	for state in ["reserved", "in_transit", "delivered"]:
		total += runtime.economy.state_total(resource, state)
	for source_id_variant in world.resources.sources:
		var source_id := String(source_id_variant)
		if contested_sources.has(source_id): continue
		var source: Dictionary = world.resources.sources[source_id]
		if not _source_reachable(runtime, source): continue
		total += maxf(0.0, world.resources.source_available(source_id, resource))
	return total

func _source_reachable(runtime: Node, source: Dictionary) -> bool:
	var region := String(source.get("region", "FLOOR"))
	if region == "FLOOR": return true
	return runtime.coordinator.surface_navigation.has_connection("FLOOR", region)

func _secured_space_capacity(world: Node, instance_id: String, population: int) -> float:
	var capacity := float(population) * 2.0
	for participant in world.scenario.get("participants", []):
		if String(participant.get("instance_id", "")) != instance_id: continue
		if participant.has("home_space_capacity"):
			capacity = float(participant.home_space_capacity)
		else:
			for slot in world.room_definition.get("start_slots", []):
				if String(slot.get("id", "")) == String(participant.get("start_slot", "")):
					capacity = float(slot.get("space_capacity", capacity))
					break
		break
	for site in world.territory.sites.values():
		if String(site.owner_civilization_id) != instance_id: continue
		var benefits: Dictionary = site.get("benefits", {})
		if String(site.site_id) == String(world.scenario.get("strategic_site", "")):
			benefits = world.scenario.get("site_benefits", benefits)
		capacity += float(benefits.get("space_capacity", 0.0))
	return capacity
