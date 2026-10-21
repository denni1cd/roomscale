extends RefCounted
## Read-only semantic descriptors for stable world entities.
const Development := preload("res://scripts/settlement_development_system.gd")

static func describe(sim: Node, entity_type: String, entity_id: String) -> Dictionary:
	match entity_type:
		"citizen": return _citizen(sim, entity_id)
		"project", "building": return _project(sim, entity_id, entity_type == "building")
		"furniture": return _furniture(sim, entity_id)
		"resource": return _resource(sim, entity_id)
		"site": return _site(sim, entity_id)
		"surface": return _surface(sim, entity_id)
	return {}

static func _descriptor(entity_type: String, entity_id: String, title: String, details: Array[String], focus: Vector3) -> Dictionary:
	return {"valid":true, "key":entity_type + ":" + entity_id, "type":entity_type, "id":entity_id, "title":title, "details":details, "focus":focus}

static func _citizen(sim: Node, raw_id: String) -> Dictionary:
	var citizen_id := int(raw_id)
	var citizen: Node3D = sim.citizen_for(citizen_id)
	if citizen == null and sim.world_simulation != null:
		for candidate in sim.world_simulation.citizens:
			if int(candidate.citizen_id) == citizen_id:
				citizen = candidate
				break
	if citizen == null or citizen.life_state == "DEAD": return {}
	var carry := "Nothing"
	var parcel := citizen.get_node_or_null("Figure/Parcel") as Node3D
	if citizen.carrying and parcel != null: carry = String(parcel.get_meta("cargo_resource", "supplies"))
	var info: Dictionary = citizen.get_inspection_status()
	var details: Array[String] = ["Society: %s" % citizen.civilization_id, "State: %s · Task: %s" % [citizen.state, String(citizen.task_type).replace("_", " ")], "Target: (%.0f, %.0f, %.0f)" % [info.target.x, info.target.y, info.target.z], "Carrying: %s" % carry]
	return _descriptor("citizen", raw_id, "Citizen %02d" % (citizen_id + 1), details, citizen.global_position + Vector3.UP * 0.25)

static func _project(sim: Node, project_id: String, building: bool) -> Dictionary:
	var project: Dictionary = sim.development.project_status(project_id)
	if project.is_empty():
		var runtimes: Array = sim.world_simulation.runtimes if sim.world_simulation != null else [sim]
		for runtime in runtimes:
			if runtime == sim or runtime.development == null: continue
			project = runtime.development.project_status(project_id)
			if not project.is_empty(): sim = runtime; break
	if project.is_empty(): return {}
	var name := String(project.get("kind", "Project")).capitalize()
	var percent := float(project.get("work_percent", 0.0)) * 100.0
	var required: Dictionary = project.get("required", {})
	var delivered: Dictionary = project.get("delivered", {})
	var details: Array[String] = ["Society: %s" % sim.instance_id, "State: %s · Stage: %s" % [String(project.get("lifecycle_status", project.get("state", "PLANNED"))).replace("_", " "), String(project.get("stage", "FOUNDATION"))], "Work: %.1f / %.1f seconds (%.0f%%)" % [float(project.get("work_progress", 0.0)), float(project.get("work_required", 0.0)), percent], "Materials: wood %.0f/%.0f · metal %.0f/%.0f" % [float(delivered.get("wood", 0)), float(required.get("wood", 0)), float(delivered.get("metal", 0)), float(required.get("metal", 0))], "Workers: %d" % int(project.get("worker_count", 0))]
	var blocker := String(project.get("blocker", ""))
	if not blocker.is_empty(): details.append("Blocker: " + blocker)
	var kind := "building" if building or project.get("state", "") == "COMPLETE" else "project"
	if kind == "building":
		var capacity := int(Development.BLUEPRINTS.get(project.kind, {}).get("shelter", 0))
		details[1] = "Function: %s" % ("Adds %d shelter places" % capacity if capacity > 0 else "%s infrastructure" % name.to_lower())
		details.append("Completed: %.1f simulation seconds" % float(project.get("completed", 0.0)))
	return _descriptor(kind, project_id, name, details, Vector3(project.site.x, project.site.y + 1.0, project.site.z))

static func _furniture(sim: Node, object_id: String) -> Dictionary:
	if not sim.resources.objects.has(object_id): return {}
	var object: Dictionary = sim.resources.objects[object_id]
	var salvage: Dictionary = sim.salvage.objects.get(object_id, {})
	var data: Dictionary = object.data
	var details: Array[String] = ["Type: %s · Material: %s" % [String(data.get("kind", "object")).replace("_", " "), String(object.profile.material)], "Salvage: %s · Stage %d/%d" % [String(salvage.get("state", "PROTECTED")), int(salvage.get("stage", 0)), salvage.get("stages", []).size()], "Authorization: %s · Work: %.1f seconds" % ["Authorized" if salvage.get("authorized", false) else "Protected", float(salvage.get("progress", 0.0))]]
	var remaining: Dictionary = {}
	var stages: Array = salvage.get("stages", [])
	for index in range(int(salvage.get("stage", 0)), stages.size()):
		for resource in stages[index].get("yields", {}): remaining[resource] = float(remaining.get(resource, 0.0)) + float(stages[index].yields[resource])
	details.append("Remaining finite yield: %s" % str(remaining))
	var p: Array = data.get("position", [0,0,0])
	var d: Array = data.get("dimensions", [0,0,0])
	return _descriptor("furniture", object_id, String(data.get("name", object_id)), details, Vector3(float(p[0]), float(p[1]) + float(d[1]) * 0.5, float(p[2])))

static func _resource(sim: Node, source_id: String) -> Dictionary:
	if not sim.resources.sources.has(source_id): return {}
	var source: Dictionary = sim.resources.sources[source_id]
	return _descriptor("resource", source_id, String(source.get("display_name", source.get("name", source_id.capitalize()))), ["Region: %s" % String(source.get("region", "unknown")), "Finite resource remaining: %s" % str(source.get("remaining", {})), "Status: %s" % ("Depleted" if source.get("remaining", {}).values().all(func(amount: Variant) -> bool: return float(amount) <= 0.00001) else "Available")], source.position)

static func _site(sim: Node, site_id: String) -> Dictionary:
	if sim.world_simulation == null or not sim.world_simulation.territory.sites.has(site_id): return {}
	var site: Dictionary = sim.world_simulation.territory.sites[site_id]
	return _descriptor("site", site_id, site_id.replace("_", " ").capitalize(), ["Claim: %s" % String(site.get("claim_state", "NEUTRAL")), "Owner: %s" % (String(site.get("owner_civilization_id", "")) if not String(site.get("owner_civilization_id", "")).is_empty() else "Unclaimed"), "Contesting societies: %s" % ", ".join(site.get("contesting_civilizations", [])), "Benefits: %s" % str(site.get("benefits", {}))], site.position)

static func _surface(sim: Node, region_id: String) -> Dictionary:
	var navigation: Node = sim.scene.get_node_or_null("SurfaceNavigation")
	if navigation == null or not navigation.regions.has(region_id): return {}
	var surface: Dictionary = navigation.regions[region_id]
	var route := "Connected" if navigation.has_connection("FLOOR", region_id) else "Not connected to floor"
	return _descriptor("surface", region_id, String(surface.get("object_name", region_id)), ["Type: %s" % String(surface.get("kind", "surface")).replace("_", " "), "Height: %.1f inches" % float(surface.get("height", 0.0)), "Access: %s" % route, "State: %s" % ("Selected exploration target" if region_id == navigation.goal_surface_id else "Inspectable surface")], surface.get("center", Vector3.ZERO))
