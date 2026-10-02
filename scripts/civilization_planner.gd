extends RefCounted
## Deterministic player intent and demand-weighted scoring; no worker professions.

const LEVELS := ["Disabled", "Low", "Normal", "High", "Critical"]
var priorities := {"Survival": 3, "Resources": 2, "Construction": 2, "Exploration": 2}
var directives: Dictionary = {}
var authorized: Dictionary = {}
var reasons: Array[String] = []
var labor: Dictionary = {}

func set_priority(family: String, level: int) -> bool:
	if not priorities.has(family) or level < 0 or level >= LEVELS.size(): return false
	priorities[family] = level
	return true

func secure(resource: String) -> bool:
	if resource not in ["food", "water"]: return false
	directives[resource] = "Secure " + resource.capitalize()
	return true

func family(kind: String) -> String:
	if kind.begins_with("NEED_") or kind == "RESOURCE_COLLECT": return "Survival"
	if kind in ["SALVAGE", "BUNDLE_HAUL", "DEPOT_RUN"]: return "Resources"
	if kind.begins_with("CONSTRUCTION_") or kind == "WORKSHOP_MAINTENANCE": return "Construction"
	return "Exploration"

func score(kind: String, urgency: float, distance: float) -> float:
	var category := family(kind)
	var level := int(priorities[category])
	var emergency := kind.begins_with("NEED_") and urgency >= 0.9
	if level == 0 and not emergency: return -INF
	return level * 100.0 + urgency * 300.0 - distance * 0.12 + (1000 if emergency else 0)

func record(kind: String) -> void:
	var category := family(kind)
	labor[category] = int(labor.get(category, 0)) + 1
