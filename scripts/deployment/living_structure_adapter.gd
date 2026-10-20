extends "res://scripts/deployment/climb_route_adapter.gd"
## A permanent climb structure supplies real shelter only after paid completion.

func supports(solution: Dictionary) -> bool:
	var properties: Dictionary = solution.get("properties",{})
	var capacity: Variant = properties.get("shelter_capacity",0)
	return solution.get("deployment",{}).get("adapter","") == "living_structure" and solution.deployment.get("style","") == "tree" and preload("res://scripts/innovation_validation.gd").number(capacity) and capacity > 0 and capacity <= 150 and capacity == floorf(capacity)

func prepare(sim: Node, solution: Dictionary, problem: Dictionary) -> Dictionary:
	var plan: Dictionary = super.prepare(sim, solution, problem)
	if plan.get("valid",false):
		plan.claim_key = "living_structure::" + plan.region
		# A permanent structure is one physical object, not repeatable shelter
		# credits stacked onto the same footprint by any society.
		for runtime in sim.world_simulation.runtimes:
			for project in runtime.innovation.projects:
				if project.state == "COMPLETE" and project.claim_key == plan.claim_key: return {"valid":false}
	return plan

func status(sim: Node, project: Dictionary) -> String:
	return "VALID" if sim.coordinator.surface_navigation.regions.has(project.deployment.region) else "INVALID"

func render(root: Node3D, project: Dictionary, fraction: float, color: Color) -> void:
	var marker := floori(fraction*10)
	if project.get("render_stage",-1) == marker: return
	project.render_stage = marker
	var route: Dictionary = project.solution.duplicate(true)
	route.deployment.style = "vine"
	Geometry.render(root, project.deployment.path, route, fraction, color)
	var trunk := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = 0.9; mesh.top_radius = 0.45
	mesh.height = maxf(0.2,(project.deployment.path.back().y-project.site.y)*fraction)
	trunk.mesh = mesh; trunk.position = project.site + Vector3(0,mesh.height/2,0)
	var material := StandardMaterial3D.new(); material.albedo_color = Color("6f513c")
	trunk.material_override = material; root.add_child(trunk)
	if fraction >= 1:
		var canopy := MeshInstance3D.new(); var sphere := SphereMesh.new()
		sphere.radius = 3; sphere.height = 2
		canopy.mesh = sphere; canopy.position = project.site + Vector3(0,mesh.height,0)
		var green := StandardMaterial3D.new(); green.albedo_color = Color("52863d")
		canopy.material_override = green; root.add_child(canopy)

func finish(sim: Node, project: Dictionary) -> bool:
	if project.get("effect_applied",false): return true
	var navigation: Node = sim.coordinator.surface_navigation
	if not navigation.has_connection("FLOOR",project.deployment.region) and not super.finish(sim,project): return false
	var capacity := int(project.solution.properties.shelter_capacity)
	project["effect_applied"] = true
	project["shelter_before"] = sim.needs.shelter_capacity
	sim.needs.shelter_capacity += capacity
	var housed := 0
	for citizen in sim.citizens:
		if citizen.life_state != "ALIVE": continue
		citizen.needs.sheltered = housed < sim.needs.shelter_capacity
		housed += 1
	sim.journal.record(sim.seconds, "shelter_increased", "Living structure supplies shelter", {"project":project.id,"capacity":capacity,"total":sim.needs.shelter_capacity}, project.site, project.id+":shelter", preload("res://scripts/event_fact_context.gd").society(sim, {"project":project.id,"capacity":capacity,"total":sim.needs.shelter_capacity}))
	return true
