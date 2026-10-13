extends RefCounted
## Reports physical obstacles and finite opportunities without catalog knowledge.

static func vertical_access(resources: RefCounted, navigation: Node) -> Array[Dictionary]:
	var by_region: Dictionary = {}
	var source_ids: Array = resources.sources.keys()
	source_ids.sort()
	for source_id in source_ids:
		var source: Dictionary = resources.sources[source_id]
		var region: String = source.region
		if region == "FLOOR" or not navigation.regions.has(region) or navigation.has_connection("FLOOR", region):
			continue
		var valuable := false
		for amount in source.remaining.values():
			if float(amount) >= 1.0: valuable = true
		if not valuable: continue
		if not by_region.has(region):
			by_region[region] = {"type":"VERTICAL_ACCESS", "source_id":region, "severity":1.0, "context":{"region":region, "sources":[]}}
		by_region[region].context.sources.append(source_id)
	var regions := by_region.keys()
	regions.sort()
	var result: Array[Dictionary] = []
	for region in regions: result.append(by_region[region])
	return result

static func shelter(sim: Node, navigation: Node) -> Array[Dictionary]:
	var population: int = sim.living_population()
	if population <= sim.needs.shelter_capacity or population <= 0: return []
	return [{"type":"INSUFFICIENT_SHELTER","source_id":"settlement","severity":clampf(float(population-sim.needs.shelter_capacity)/population,0,1),"context":{"region":navigation.goal_surface_id}}]

static func observe(sim: Node) -> Array[Dictionary]:
	var navigation: Node = sim.coordinator.surface_navigation
	var observations := vertical_access(sim.resources,navigation)
	observations.append_array(shelter(sim,navigation))
	return observations
