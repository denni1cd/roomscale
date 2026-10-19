extends RefCounted
## Factual identities only; camera and editorial policy belong to presentation.
static func society(sim: Node, facts: Dictionary = {}) -> Dictionary:
	var identity: Variant = sim.get("instance_id")
	var definition: Variant = sim.get("definition_id")
	var society_id := str(identity) if identity != null else ""
	var civilization_id := str(definition) if definition != null else ""
	var context := {"society_id":society_id,"civilization_id":civilization_id,"subject_type":"society","subject_id":society_id,"story_key":"society:"+society_id}
	for field in ["project_id","site_id","conflict_id","participants","citizen_id"]:
		if facts.has(field): context[field] = facts[field]
	if facts.has("citizen_id") and int(facts.citizen_id) >= 0:
		context.subject_type = "citizen"
		context.subject_id = str(facts.citizen_id)
	elif facts.has("project") or facts.has("solution_id"):
		context.project_id = str(facts.get("project",facts.get("solution_id","")))
	if facts.has("id") and (facts.has("site") or facts.has("required_work") or facts.has("solution")):
		context.project_id = str(facts.id)
	if context.has("project_id"):
		context.subject_type = "project"
		context.subject_id = str(context.project_id)
		context.story_key = "project:"+society_id+":"+str(context.project_id)
	return context

static func conflict(site_id: String, participants: Array = [], society_id: String = "") -> Dictionary:
	var context := {"site_id":site_id,"conflict_id":"site:"+site_id,"participants":participants.duplicate(),"subject_type":"site","subject_id":site_id,"story_key":"conflict:"+site_id}
	if not society_id.is_empty(): context.society_id = society_id
	return context
