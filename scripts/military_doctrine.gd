extends RefCounted
const Roles := preload("res://scripts/combat_roles.gd")
const WEIGHTS := {"Great":4.0,"Good":3.0,"Neutral":2.0,"Bad":1.0}
const REPEAT_PENALTY := 1.25
const FRONT := ["line","heavy"]
const FIRE := ["ranged","artillery","skirmisher"]

static func compose(profile: Dictionary, count: int, stock: Dictionary = {}) -> Array[String]:
	var result: Array[String] = []
	var used := {}
	for slot in range(count):
		var best := ""
		var best_score := -INF
		for role in Roles.ORDER:
			if not profile.has(role): continue
			if not stock.is_empty() and int(stock.get(role,0)) <= int(used.get(role,0)): continue
			var score: float = WEIGHTS[profile[role].grade] - REPEAT_PENALTY * int(used.get(role,0))
			if role in FRONT and not result.any(func(r: String) -> bool: return r in FRONT): score += 1.5
			if role in FIRE and not result.any(func(r: String) -> bool: return r in FIRE): score += 1.0
			if score > best_score:
				best = role
				best_score = score
		if best.is_empty(): break
		result.append(best)
		used[best] = int(used.get(best,0))+1
	return result

static func authorized_size(population: int, policy: Dictionary) -> int:
	return mini(int(policy.get("max_force",6)),maxi(int(policy.get("min_force",2)),ceili(population*float(policy.get("force_fraction",0.25)))))
