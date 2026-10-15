extends RefCounted
## Economic equipment assets, separate from canonical materials and combat stats.
const Roles := preload("res://scripts/combat_roles.gd")
const V := preload("res://scripts/innovation_validation.gd")
const CAPABILITIES := {
	"PREPARED_FIRE":{"roles":["ranged","artillery"],"seconds":2.0,"tolerance":0.25,"interval":0.85},
	"PATHFINDER_MANEUVERS":{"angles":[0,30,-30,60,-60,90,-90]},
	"JURY_RIG_EQUIPMENT":{"metal":1,"wood":2,"work":1.25}
}
const EQUIPMENT := {
	"line_kit":{"role":"line","cost":{"wood":1,"metal":1},"work":6.0,"requires":[]},
	"ranged_kit":{"role":"ranged","cost":{"wood":1,"metal":1},"work":8.0,"requires":[]},
	"heavy_kit":{"role":"heavy","cost":{"wood":1,"metal":3},"work":12.0,"requires":[]},
	"artillery_kit":{"role":"artillery","cost":{"wood":2,"metal":4},"work":18.0,"requires":[]},
	"skirmisher_kit":{"role":"skirmisher","cost":{"wood":1,"metal":1},"work":6.0,"requires":[]}
}

static func validate_equipment(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary: return ["equipment must be an object"]
	if data.get("role") not in Roles.BASE: errors.append("unknown equipment role")
	if not V.number(data.get("work")) or data.work <= 0: errors.append("equipment work must be finite positive")
	if not data.get("cost") is Dictionary or data.cost.is_empty(): errors.append("equipment requires a bill")
	else:
		for resource in data.cost:
			if not preload("res://scripts/resource_vocabulary.gd").supports(resource) or not V.number(data.cost[resource]) or data.cost[resource] <= 0: errors.append("invalid equipment material/cost")
	if not V.string_array(data.get("requires",[])): errors.append("invalid equipment prerequisites")
	else:
		var known: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://innovation/capabilities.json"))
		# IDs are validated against the existing innovation catalog contract below.
		for requirement in data.get("requires",[]):
			if not known.capabilities.any(func(item: Dictionary) -> bool: return item.id == requirement): errors.append("unknown innovation capability " + requirement)
	return errors

static func permitted(sim: Node, role: String, equipment: Dictionary = {}) -> bool:
	var entry: Dictionary = EQUIPMENT.get(role+"_kit",{}) if equipment.is_empty() else equipment
	if entry.is_empty(): return false
	var requirements: Array = entry.get("requires",[]).duplicate()
	requirements.append_array(sim.definition.combat.roles[role].get("requires",[]))
	for requirement in requirements:
		if sim.innovation.resolver == null or not sim.innovation.resolver.known_capabilities().has(requirement): return false
	return true

static func has(sim: Node, capability: String) -> bool:
	return sim.definition.combat.get("capabilities",[]).has(capability)
