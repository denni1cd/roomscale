extends RefCounted
const Geometry := preload("res://scripts/solution_deployment.gd")

func supports(solution: Dictionary) -> bool:
	return Geometry.supported(solution)

func prepare(sim: Node, _solution: Dictionary, problem: Dictionary) -> Dictionary:
	var region: String = problem.get("context",{}).get("region",problem.get("source_id",""))
	var navigation: Node = sim.coordinator.surface_navigation
	if not navigation.regions.has(region) or region == "FLOOR": return {"valid":false}
	var plan: Dictionary = Geometry.derive(navigation, sim.coordinator.navigation, region)
	if plan.get("valid",false):
		plan["target"] = plan.position
		plan["claim_key"] = region
	return plan

func status(sim: Node, project: Dictionary) -> String:
	var navigation: Node = sim.coordinator.surface_navigation
	if not navigation.regions.has(project.deployment.region): return "INVALID"
	return "SOLVED" if navigation.has_connection("FLOOR",project.deployment.region) else "VALID"

func render(root: Node3D, project: Dictionary, fraction: float, color: Color) -> void:
	var marker := floori((project.deployment.path.size()-1)*fraction)
	if project.get("render_stage",-1) == marker: return
	project.render_stage = marker
	Geometry.render(root, project.deployment.path, project.solution, fraction, color)

func finish(sim: Node, project: Dictionary) -> bool:
	return sim.coordinator.surface_navigation.connect_regions("FLOOR",project.deployment.region,project.deployment.path)
