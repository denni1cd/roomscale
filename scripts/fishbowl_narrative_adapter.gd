extends RefCounted
## Deterministic translations; all numbers are read from production state.
const CivilizationDefinition := preload("res://scripts/civilization_definition.gd")

static func civilization_definition() -> Dictionary:
	# The presenter loads identity before production HUDs are configured. Reading
	# that profile also works while current_scene/scene metadata is initializing.
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var presentation := tree.root.get_node_or_null("CivilizationPresentation")
		if presentation != null:
			var selected: Dictionary = presentation.get("definition")
			if not selected.is_empty(): return selected
	var loaded := CivilizationDefinition.load_requested()
	return loaded.get("definition", {})

static func is_verdant() -> bool:
	return String(civilization_definition().get("id", "clockwork")) == "verdant"

static func resource_name(resource: String) -> String:
	return CivilizationDefinition.resource_name(civilization_definition(), resource)

static func stage_name(stage: String) -> String:
	return CivilizationDefinition.stage_name(civilization_definition(), stage)

static func traversal_name() -> String:
	return CivilizationDefinition.traversal_name(civilization_definition())

static func presentation_text(value: String) -> String:
	if not is_verdant(): return value
	var replacements := [
		["mechanical_parts", resource_name("mechanical_parts")],
		["mechanical parts", resource_name("mechanical_parts")],
		["wood", resource_name("wood")], ["metal", resource_name("metal")],
		["winch", stage_name("winch")], ["launcher", stage_name("launcher")],
		["base", stage_name("base")],
		["grapple cable", traversal_name()], ["grapple route", traversal_name()],
		["steampunk grapple", traversal_name()], ["grapple", traversal_name()],
		["cable", "vine"], ["founder shelter", "Grove Shelter"],
		["shelter module", "Grove Shelter"], ["workshop", "Growth Nursery"],
		["depot", "Seed Cache"], ["housing block", "Pod Homes"], ["housing", "Pod Homes"],
	]
	for replacement in replacements:
		var expression := RegEx.new()
		expression.compile("(?i)\\b%s\\b" % String(replacement[0]))
		value = expression.sub(value, String(replacement[1]), true)
	return value

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
	if sim.founder_mode and not sim.governor.emergency:
		if not sim.has_capability("shelter"): intent = "Establishing the first shelter"
		elif not sim.has_capability("storage"): intent = "Establishing permanent storage"
		elif not sim.has_capability("workshop"): intent = "Building the first workshop"
	return presentation_text("Governor on · %s — %s" % [modes.get(sim.governor.mode, "Assessing the colony"), intent])

static func status(sim: Node) -> Dictionary:
	return {"days": sim.seconds / 600.0, "population": sim.citizens.size(), "shelter": sim.needs.shelter_capacity, "food_days": sim.economy.forecast("food", sim.citizens.size()), "water_days": sim.economy.forecast("water", sim.citizens.size()), "wood": sim.economy.available.wood, "metal": sim.economy.available.metal, "mechanical_parts": sim.economy.available.get("mechanical_parts", 0), "speed": sim.speed, "governor": governor(sim)}

static func module_name(project: Dictionary) -> String:
	var names := {"shelter": "Founder Shelter ", "depot": "Depot ", "housing": "Housing Block ", "workshop": "Workshop "}
	if is_verdant(): names = {"shelter": "Grove Shelter ", "depot": "Seed Cache ", "housing": "Pod Homes ", "workshop": "Growth Nursery "}
	return names.get(project.get("kind", ""), "Structure ") + String(project.get("id", "")).trim_prefix("development_").trim_prefix("0").trim_prefix("0")

static func project(sim: Node) -> Dictionary:
	if not sim.development.active.is_empty():
		var p: Dictionary = sim.development.active
		var stages := {"FOUNDATION": "Laying foundations", "FRAME": "Frame construction", "SHELL": "Enclosing structure"}
		return {"name": module_name(p), "stage": "Waiting for materials" if p.state in ["PLANNED", "WAITING_FOR_MATERIALS"] else stages.get(p.stage, "Building"), "progress": float(p.work) / float(p.required_work), "delivered": p.delivered.duplicate(), "required": p.required.duplicate()}
	if sim.construction.project_created and not sim.construction.traversal_deployed:
		var p: Dictionary = sim.construction.status()
		var name := "Grapple Route"
		var stage := "Waiting for materials" if p.state == "WAITING_FOR_MATERIALS" else "Building"
		if is_verdant():
			name = CivilizationDefinition.project_name(civilization_definition())
			var active := String(p.get("active_stage", "locked"))
			if active in CivilizationDefinition.REQUIRED_STAGE_KEYS:
				stage = "%s · %s" % [stage_name(active), stage]
		return {"name": name, "stage": stage, "progress": p.progress_percent / 100.0, "delivered": p.delivered.duplicate(), "required": p.required.duplicate()}
	return {}

static func event_card(event: Dictionary) -> Dictionary:
	var kind: String = event.kind
	var evidence: Dictionary = event.get("evidence", {})
	var headline := ""
	var subtitle := ""
	var priority := 1
	match kind:
		"first_salvage":
			headline = "FIRST SALVAGE"
			subtitle = "Real room materials are ready to be hauled home."
			priority = 4
		"territory_reached":
			headline = "NEW TERRITORY REACHED"
			subtitle = "Citizens are collecting supplies from the elevated room."
			priority = 5
		"founders_arrived":
			headline = "FOUNDERS ARRIVED"
			subtitle = "%d citizens with portable supplies, ready to build a home." % int(evidence.population)
			priority = 5
		"advanced_available":
			headline = "SETTLEMENT ESTABLISHED"
			subtitle = "The completed workshop enables advanced construction."
			priority = 4
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
			headline = {"shelter":"FIRST SHELTER COMPLETE", "depot":"DEPOT ESTABLISHED", "housing":"HOUSING COMPLETE", "workshop":"WORKSHOP COMPLETE"}.get(evidence.get("kind"), "STRUCTURE COMPLETE")
			subtitle = module_name(evidence) + " is ready for the colony."
			priority = 4
		"shelter_increased":
			headline = "ROOM TO GROW"
			subtitle = "Shelter now supports %d citizens." % int(evidence.get("shelter", 0))
			priority = 3
		"cohort_joined":
			var count := int(evidence.get("after", 0)) - int(evidence.get("before", 0))
			headline = "NEW CITIZEN" if count == 1 else "NEW ARRIVALS"
			subtitle = "One citizen joined the settlement · Population %d." % int(evidence.after) if count == 1 else "Five citizens joined the settlement · Population %d." % int(evidence.get("after", 0))
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
	headline = presentation_text(headline)
	subtitle = presentation_text(subtitle)
	return {"id": event.id, "kind": kind, "headline": headline, "subtitle": subtitle, "priority": priority, "duration": 8.0 if priority >= 3 else 5.0, "key": headline + subtitle, "day": event.day}
