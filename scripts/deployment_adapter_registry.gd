extends RefCounted
## Generic dispatch. Registered adapters own geometry, target validity and effects.
const PATH := "res://innovation/deployment_adapters.json"
var adapters: Dictionary = {}
var errors: Array[String] = []

func _init() -> void:
	if not FileAccess.file_exists(PATH): errors.append("Deployment registry missing"); return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary: errors.append("Deployment registry must be an object"); return
	var ids: Array = parsed.keys(); ids.sort()
	for id in ids:
		if not id is String or not parsed[id] is String or (not String(parsed[id]).begins_with("res://scripts/deployment/") or String(parsed[id]).contains("..") or not String(parsed[id]).ends_with(".gd") or not FileAccess.file_exists(parsed[id])):
			errors.append("Invalid adapter registration"); continue
		var script: Script = load(parsed[id])
		if script == null or not script.can_instantiate(): errors.append("Invalid adapter: " + id); continue
		var adapter: Variant = script.new()
		if not adapter is RefCounted:
			if adapter is Node: adapter.free()
			errors.append("Adapter must be RefCounted: " + id)
		elif not register(id,adapter): errors.append("Invalid adapter interface: " + id)

func register(id: String, adapter: RefCounted) -> bool:
	if id.is_empty() or adapters.has(id) or adapter == null: return false
	for method in ["supports","prepare","status","render","finish"]:
		if not adapter.has_method(method): return false
	adapters[id] = adapter
	return true

func adapter_for(solution: Dictionary) -> RefCounted:
	var deployment: Variant = solution.get("deployment",{})
	return adapters.get(deployment.get("adapter", "")) if deployment is Dictionary else null

func supported(solution: Dictionary) -> bool:
	var adapter := adapter_for(solution)
	return errors.is_empty() and adapter != null and adapter.supports(solution)

func prepare(sim: Node, candidate: Dictionary) -> Dictionary:
	if not supported(candidate.solution): return {"valid":false}
	return adapter_for(candidate.solution).prepare(sim, candidate.solution, candidate.problem)

func advance(sim: Node, projects: Array, delta: float) -> void:
	# Optional persistent behavior shares the production clock, never renderer time.
	for project in projects:
		if project.state != "COMPLETE": continue
		var adapter := adapter_for(project.solution)
		if adapter != null and adapter.has_method("advance"): adapter.advance(sim,project,delta)
