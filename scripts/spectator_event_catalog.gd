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

const MILITARY_CONTEXT := {
	"SITE_TARGETED":"Scouts explore a shared strategic approach.",
	"FIRST_CONTACT":"Societies meet at a shared frontier.",
	"SITE_CONTESTED":"More than one society seeks control of the site.",
	"HOSTILITY_DECLARED":"Contact has escalated into active hostility.",
	"FORCE_COMMITTED":"A society commits a force to the contested frontier.",
	"READINESS_TARGET":"The society prepares equipment and citizens for deployment.",
	"KIT_BLOCKED":"Military preparation is waiting for equipment or materials.",
	"KIT_ORDERED":"Equipment makers begin preparing a combat kit.",
	"KIT_COMPLETED":"A completed combat kit is ready for the force.",
	"KIT_RESERVED":"Equipment is set aside for a mustering citizen.",
	"KIT_ISSUED":"A citizen receives equipment for military duty.",
	"KIT_RELEASED":"Reserved equipment is available again.",
	"KIT_RETURNED":"A returning citizen brings issued equipment home.",
	"KIT_LOST":"Issued equipment was lost with a fallen citizen.",
	"CITIZEN_MUSTERING":"A citizen travels to the rally point to join the force.",
	"MOBILIZATION_READY":"The equipped force has assembled and is ready to march.",
	"FORCE_DEPLOYED":"The assembled force marches toward its objective.",
	"FORCE_ARRIVED":"Forces have reached the contested ground.",
	"BATTLE_BEGINS":"Opposing forces engage at the strategic site.",
	"COMBAT_CASUALTY":"A citizen has fallen during the conflict.",
	"MORALE_BREAK":"A force loses the resolve to continue fighting.",
	"RETREAT":"A force withdraws toward its home settlement.",
	"FORCE_ELIMINATED":"No members of the committed force remain in the field.",
	"SITE_CAPTURED":"The strategic site is secured by the surviving force.",
	"CONFLICT_STOOD_DOWN":"The immediate conflict has ended and forces stand down.",
	"DEMOBILIZATION_STARTED":"Citizens begin returning home from military duty.",
	"DEMOBILIZATION_COMPLETE":"Returning citizens resume ordinary settlement life."
}

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
	return {"priority":priority, "priority_name":PRIORITY_NAMES[priority], "category":"military" if military else "colony", "framing":framing, "eligible":priority > LOW, "duration":8.0 if priority > LOW else 5.0, "story_cooldown":24.0, "subject_cooldown":24.0, "location_cooldown":16.0, "narrative_context":MILITARY_CONTEXT.get(kind, "")}
