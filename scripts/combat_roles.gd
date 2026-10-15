extends RefCounted
## Shared loadout catalog. No civilization identity enters combat rules.
const ORDER := ["line", "ranged", "heavy", "artillery", "skirmisher"]
const BASE := {
	"line": {"health":120.0,"armor":3.0,"damage":18.0,"interval":1.0,"range":0.6,"movement":1.0,"behavior":"screen","preferred":0.5,"reposition":1.0},
	"ranged": {"health":90.0,"armor":1.0,"damage":14.0,"interval":1.2,"range":7.0,"movement":1.0,"behavior":"ranged","preferred":5.5,"reposition":1.0},
	"heavy": {"health":180.0,"armor":8.0,"damage":24.0,"interval":1.5,"range":0.6,"movement":0.7,"behavior":"assault","preferred":0.5,"reposition":1.0},
	"artillery": {"health":80.0,"armor":0.0,"damage":45.0,"interval":3.5,"range":15.0,"movement":0.55,"behavior":"support","preferred":12.0,"reposition":2.0},
	"skirmisher": {"health":80.0,"armor":0.0,"damage":11.0,"interval":0.9,"range":5.0,"movement":1.35,"behavior":"harass","preferred":4.0,"reposition":0.7}
}
# Deliberately one role-relevant axis: monotonic strength without multiplying
# every stat, changing movement balance or inventing faction abilities.
const QUALITY := {"Great":1.20,"Good":1.10,"Neutral":1.0,"Bad":0.85}
const QUALITY_STAT := {"screen":"health","assault":"health","ranged":"damage","support":"damage","harass":"damage"}

static func validate_stats(stats: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in ["health","armor","damage","interval","range","movement","preferred","reposition"]:
		var value: Variant = stats.get(key)
		if not preload("res://scripts/innovation_validation.gd").number(value): errors.append("invalid combat stat " + key)
		elif value < 0 or (key != "armor" and value == 0): errors.append("invalid combat stat " + key)
	if stats.get("behavior", "") not in QUALITY_STAT: errors.append("unknown combat behavior")
	return errors

static func validate_profile(profile: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not profile is Dictionary: return ["combat must be an object"]
	var roles: Variant = profile.get("roles")
	if not roles is Dictionary: return ["combat.roles must be an object"]
	var counts := {"Great":0,"Good":0,"Neutral":0,"Bad":0}
	if roles.size() != ORDER.size(): errors.append("standard profile requires exactly five roles")
	for role in ORDER:
		var entry: Variant = roles.get(role)
		if not entry is Dictionary:
			errors.append("missing combat role " + role)
			continue
		if entry.get("grade") not in QUALITY: errors.append("invalid grade " + role)
		else: counts[entry.grade] += 1
		if not preload("res://scripts/innovation_validation.gd").nonempty_string(entry.get("implementation")): errors.append("missing implementation " + role)
	if counts != {"Great":1,"Good":1,"Neutral":2,"Bad":1}: errors.append("profile requires 1 Great / 1 Good / 2 Neutral / 1 Bad")
	if profile.has("composition"):
		if not profile.composition is Array or profile.composition.is_empty() or not profile.composition.all(func(role: Variant) -> bool: return role is String and role in BASE): errors.append("invalid force composition")
	if not profile.get("capabilities", []) is Array: errors.append("combat.capabilities must be an array")
	return errors

static func loadout(definition: Dictionary, role: String) -> Dictionary:
	var entry: Dictionary = definition.combat.roles[role]
	var result: Dictionary = BASE[role].duplicate(true)
	result[QUALITY_STAT[result.behavior]] *= QUALITY[entry.grade]
	result.merge({"role":role,"grade":entry.grade,"implementation":entry.implementation})
	return result

static func damage(attack: float, armor: float) -> float:
	return maxf(1.0, attack - armor)
