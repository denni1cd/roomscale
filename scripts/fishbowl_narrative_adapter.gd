extends RefCounted
## Deterministic translations; all numbers are read from production state.
static func governor(sim: Node) -> String:
	if not sim.governor.enabled: return "Governor off · Manual control"
	var modes := {"OBSERVING": "Surveying the colony", "SURVIVAL": "Securing survival resources", "MATERIALS": "Gathering construction materials", "STABLE": "Colony stable"}
	var intent := "Checking reserves and shelter"
	if sim.governor.mode == "OBSERVING": intent = "Checking reserves and shelter"
	elif sim.governor.emergency: intent = "Restoring food and water reserves"
	elif not sim.development.active.is_empty(): intent = "Expanding the settlement"
	elif sim.needs.shelter_capacity - sim.citizens.size() < 5: intent = "Preparing shelter expansion"
	elif sim.population.reason.contains("horizon"): intent = "Finite supplies limit further growth"
	elif sim.development.site_reason.contains("cannot fund"): intent = "Materials limit further expansion"
	return "Governor on · %s — %s" % [modes.get(sim.governor.mode, "Assessing the colony"), intent]

static func status(sim: Node) -> Dictionary:
	return {"days": sim.seconds / 600.0, "population": sim.citizens.size(), "shelter": sim.needs.shelter_capacity, "food_days": sim.economy.forecast("food", sim.citizens.size()), "water_days": sim.economy.forecast("water", sim.citizens.size()), "wood": sim.economy.available.wood, "metal": sim.economy.available.metal, "speed": sim.speed, "governor": governor(sim)}

static func module_name(project: Dictionary) -> String:
	return ("Housing Block " if project.get("kind", "") == "housing" else "Workshop Annex ") + String(project.get("id", "")).trim_prefix("development_").trim_prefix("0").trim_prefix("0")

static func project(sim: Node) -> Dictionary:
	if not sim.development.active.is_empty():
		var p: Dictionary = sim.development.active
		var stages := {"FOUNDATION": "Laying foundations", "FRAME": "Frame construction", "SHELL": "Enclosing structure"}
		return {"name": module_name(p), "stage": "Waiting for materials" if p.state in ["PLANNED", "WAITING_FOR_MATERIALS"] else stages.get(p.stage, "Building"), "progress": float(p.work) / float(p.required_work), "delivered": p.delivered.duplicate(), "required": p.required.duplicate()}
	if sim.construction.project_created and not sim.construction.traversal_deployed:
		var p: Dictionary = sim.construction.status()
		return {"name": "Grapple Route", "stage": "Waiting for materials" if p.state == "WAITING_FOR_MATERIALS" else "Building", "progress": p.progress_percent / 100.0, "delivered": p.delivered.duplicate(), "required": p.required.duplicate()}
	return {}

static func event_card(event: Dictionary) -> Dictionary:
	var kind: String = event.kind
	var evidence: Dictionary = event.get("evidence", {})
	var headline := ""
	var subtitle := ""
	var priority := 1
	match kind:
		"governor":
			if event.message.begins_with("SURVIVAL"):
				headline = "WATER RESERVE LOW" if float(evidence.get("water_days", 3)) < 1 else "SURVIVAL RESPONSE"
				subtitle = "The colony is restoring its food and water reserves."
				priority = 5
			elif event.message.begins_with("STABLE"):
				headline = "RESERVES RECOVERED"
				subtitle = "Food and water are safe enough to consider expansion."
				priority = 4
		"directive":
			headline = String(event.message).to_upper()
			subtitle = "Citizens are finding a route to the finite supply."
			priority = 4
		"salvage_authorized":
			headline = "SALVAGE AUTHORIZED"
			subtitle = "%s will supply construction materials." % String(event.message).get_slice(": ", 1).replace("_", " ").capitalize()
			priority = 3
		"traversal_started":
			headline = "EXPEDITION TO THE DESK"
			subtitle = "A grapple route will connect the elevated supply."
			priority = 3
		"traversal_complete":
			headline = "NEW ROUTE COMPLETE"
			subtitle = "The grapple route is ready for water collectors."
			priority = 5
		"development_started":
			headline = "SETTLEMENT EXPANSION"
			subtitle = "Work began on " + module_name(evidence) + "."
			priority = 3
		"structure_complete":
			headline = "HOUSING COMPLETE" if evidence.get("kind") == "housing" else "WORKSHOP COMPLETE"
			subtitle = module_name(evidence) + " is ready for the colony."
			priority = 4
		"shelter_increased":
			headline = "ROOM TO GROW"
			subtitle = "Shelter now supports %d citizens." % int(evidence.get("shelter", 0))
			priority = 3
		"cohort_joined":
			headline = "NEW ARRIVALS"
			subtitle = "Five citizens joined the settlement · Population %d." % int(evidence.get("after", 0))
			priority = 5
		"source_exhausted":
			headline = "SOURCE EXHAUSTED"
			subtitle = String(event.message).trim_prefix("Finite source exhausted: ").replace("_", " ")
			priority = 3
		"growth_paused":
			headline = "EXPANSION PAUSED"
			subtitle = String(event.message)
		"object_depleted":
			headline = "SALVAGE COMPLETE"
			subtitle = "All usable material recovered from " + String(event.message).get_slice(": ", 1).replace("_", " ") + "."
	if headline.is_empty(): return {}
	return {"id": event.id, "kind": kind, "headline": headline, "subtitle": subtitle, "priority": priority, "duration": 8.0 if priority >= 3 else 5.0, "key": headline + subtitle, "day": event.day}
