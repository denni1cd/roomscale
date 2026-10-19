extends RefCounted
## Generic presentation policy. Simulation producers publish facts, never these values.
const LOW := 0
const MEDIUM := 1
const HIGH := 2
const CRITICAL := 3
const PRIORITY_NAMES := ["LOW", "MEDIUM", "HIGH", "CRITICAL"]
const CRITICAL_KINDS := ["COMBAT_CASUALTY", "RETREAT", "MORALE_BREAK", "SITE_CAPTURED", "FORCE_ELIMINATED", "severe_crisis"]
const HIGH_KINDS := ["FIRST_CONTACT", "SITE_CONTESTED", "HOSTILITY_DECLARED", "FORCE_COMMITTED", "FORCE_DEPLOYED", "FORCE_ARRIVED", "BATTLE_BEGINS", "MOBILIZATION_READY", "technology_complete", "solution_complete", "traversal_complete", "territory_reached", "structure_complete", "founders_arrived", "advanced_available"]
const MEDIUM_KINDS := ["KIT_ORDERED", "KIT_COMPLETED", "KIT_BLOCKED", "READINESS_TARGET", "CITIZEN_MUSTERING", "KIT_LOST", "CONFLICT_STOOD_DOWN", "DEMOBILIZATION_STARTED", "DEMOBILIZATION_COMPLETE", "cohort_joined", "development_started", "salvage_authorized", "research_started", "solution_started", "first_salvage", "source_exhausted", "object_depleted", "shelter_increased", "traversal_started", "directive", "growth_paused", "problem_detected", "CONFLICT_PRESSURE_CHANGED", "SITE_TARGETED"]

static func metadata(event: Dictionary) -> Dictionary:
	var kind := String(event.get("kind", ""))
	var priority := LOW
	if kind in CRITICAL_KINDS: priority = CRITICAL
	elif kind in HIGH_KINDS: priority = HIGH
	elif kind in MEDIUM_KINDS: priority = MEDIUM
	if kind == "governor":
		if String(event.get("message", "")).begins_with("SURVIVAL"): priority = CRITICAL
		elif String(event.get("message", "")).begins_with("STABLE"): priority = MEDIUM
	var military := kind == kind.to_upper() and kind.contains("_")
	var framing := "CONFLICT_WIDE" if military else "SITE_MEDIUM"
	if String(event.get("subject_type", "")) == "citizen": framing = "CITIZEN_CLOSE"
	if kind in ["COMBAT_CASUALTY", "KIT_LOST"]: framing = "CONFLICT_DETAIL"
	return {"priority":priority, "priority_name":PRIORITY_NAMES[priority], "category":"military" if military else "colony", "framing":framing, "eligible":priority > LOW, "duration":8.0 if priority > LOW else 5.0, "story_cooldown":24.0, "subject_cooldown":24.0, "location_cooldown":16.0}
