extends RefCounted
## Deterministic problem -> invention -> solution resolver.
##
## This class contains no Clockwork/Verdant special cases. It evaluates the
## selected civilization's authored catalog against shared problem instances and
## capabilities. Randomness is intentionally absent so identical simulation
## state produces identical innovation choices.

const CapabilityRegistry := preload("res://scripts/capability_registry.gd")
const ProblemRegistry := preload("res://scripts/problem_registry.gd")
const InnovationCatalog := preload("res://scripts/innovation_catalog.gd")
const Validation := preload("res://scripts/innovation_validation.gd")

var civilization_id: String = ""
var capability_registry = null
var problem_registry = null
var catalog = null
var base_capabilities: Array[String] = []
var known_technologies: Dictionary = {}
var validation_errors: Array[String] = []


static func create(civ_id: String, starting_capabilities: Array = [], catalog_path: String = "") -> Dictionary:
	var capability_result := CapabilityRegistry.load_default()
	var problem_result := ProblemRegistry.load_default()
	var catalog_result := InnovationCatalog.load_id(civ_id) if catalog_path.is_empty() else InnovationCatalog.load_path(catalog_path, civ_id)
	var errors: Array[String] = []
	if not bool(capability_result.ok):
		errors.append_array(capability_result.errors)
	if not bool(problem_result.ok):
		errors.append_array(problem_result.errors)
	if not bool(catalog_result.ok):
		errors.append_array(catalog_result.errors)
	if not errors.is_empty():
		return {"ok": false, "system": null, "errors": errors}
	var system := new()
	system.civilization_id = civ_id.strip_edges().to_lower()
	system.capability_registry = capability_result.registry
	system.problem_registry = problem_result.registry
	system.catalog = catalog_result.catalog
	for capability in starting_capabilities:
		var normalized := Validation.id(capability, "starting capability", errors)
		if not normalized.is_empty() and not system.base_capabilities.has(normalized):
			system.base_capabilities.append(normalized)
	system.base_capabilities.sort()
	errors.append_array(system._validate_cross_references())
	system.validation_errors = errors
	return {"ok": errors.is_empty(), "system": system if errors.is_empty() else null, "errors": errors}


func _validate_cross_references() -> Array[String]:
	var errors: Array[String] = []
	for capability in base_capabilities:
		if not capability_registry.has_capability(capability):
			errors.append("unknown starting capability: %s" % capability)
	for technology in catalog.technology_list():
		for capability in technology.get("grants", []):
			if not capability_registry.has_capability(capability):
				errors.append("technology %s grants unknown capability %s" % [technology.id, capability])
		for capability in technology.get("requires_capabilities", []):
			if not capability_registry.has_capability(capability):
				errors.append("technology %s requires unknown capability %s" % [technology.id, capability])
	for solution in catalog.solution_list():
		for problem_id in solution.get("addresses", []):
			if not problem_registry.has_problem(problem_id):
				errors.append("solution %s addresses unknown problem %s" % [solution.id, problem_id])
		for capability in solution.get("requires_capabilities", []):
			if not capability_registry.has_capability(capability):
				errors.append("solution %s requires unknown capability %s" % [solution.id, capability])
	return errors


func learn_technology(technology_id: String) -> Dictionary:
	var normalized := technology_id.strip_edges().to_lower()
	var technology: Dictionary = catalog.technology(normalized)
	if technology.is_empty():
		return {"ok": false, "error": "unknown technology: %s" % normalized}
	if known_technologies.has(normalized):
		return {"ok": true, "technology": technology, "already_known": true}
	var missing: Array[String] = capability_registry.missing(known_capabilities(), technology.get("requires_capabilities", []))
	if not missing.is_empty():
		return {"ok": false, "error": "technology %s is missing prerequisites: %s" % [normalized, missing], "missing": missing}
	known_technologies[normalized] = true
	return {"ok": true, "technology": technology, "already_known": false}


func knows_technology(technology_id: String) -> bool:
	return known_technologies.has(technology_id.strip_edges().to_lower())


func known_capabilities() -> Array[String]:
	var capabilities: Array = []
	for capability in base_capabilities:
		capabilities.append(capability)
	var technology_ids := known_technologies.keys()
	technology_ids.sort()
	for technology_id in technology_ids:
		var technology: Dictionary = catalog.technology(String(technology_id))
		for capability in technology.get("grants", []):
			capabilities.append(capability)
	return capability_registry.expand(capabilities)


func researchable_technologies() -> Array[Dictionary]:
	var known := known_capabilities()
	var result: Array[Dictionary] = []
	for technology in catalog.technology_list():
		if knows_technology(String(technology.id)):
			continue
		if capability_registry.satisfies(known, technology.get("requires_capabilities", [])):
			result.append(technology)
	return result


func viable_solutions(problem_type: String) -> Array[Dictionary]:
	var normalized := ProblemRegistry.normalize_id(problem_type)
	var known := known_capabilities()
	var result: Array[Dictionary] = []
	for solution in catalog.solution_list():
		if not solution.get("addresses", []).has(normalized):
			continue
		if capability_registry.satisfies(known, solution.get("requires_capabilities", [])):
			result.append(solution)
	return result


func solution_options(problem_instance: Dictionary) -> Array[Dictionary]:
	if not (problem_instance.get("type") is String) or not Validation.number(problem_instance.get("severity", 0.0)):
		return []
	var problem_type := ProblemRegistry.normalize_id(String(problem_instance.get("type", "")))
	var severity := clampf(float(problem_instance.get("severity", 0.0)), 0.0, 1.0)
	var result: Array[Dictionary] = []
	for solution in viable_solutions(problem_type):
		var option := solution.duplicate(true)
		option["problem_type"] = problem_type
		option["score"] = severity * float(solution.get("priority", 1.0))
		result.append(option)
	_sort_scored(result)
	return result


func solution_candidates(problem_instances: Array, applicable_solution: Callable = Callable()) -> Array[Dictionary]:
	# One strongest representative per problem type: duplicate detector/source
	# instances do not manufacture pressure. Distinct addressed types accumulate.
	var pressure := {}
	for raw in problem_instances:
		if not raw is Dictionary or not raw.get("type") is String or not Validation.number(raw.get("severity")): continue
		if raw.get("recognition_state", "RECOGNIZED") != "RECOGNIZED": continue
		var type := ProblemRegistry.normalize_id(raw.type)
		if not problem_registry.has_problem(type): continue
		var severity := clampf(float(raw.severity), 0, 1)
		if severity <= 0: continue
		var previous: Dictionary = pressure.get(type, {})
		if previous.is_empty() or severity > float(previous.severity) or (severity == float(previous.severity) and String(raw.get("source_id", "")) < String(previous.get("source_id", ""))):
			pressure[type] = raw.duplicate(true)
			pressure[type].type = type
			pressure[type].severity = severity
	var types: Array = pressure.keys()
	types.sort()
	var solutions: Array[Dictionary] = []
	var scale := 1.0
	for solution in catalog.solution_list():
		if not capability_registry.satisfies(known_capabilities(), solution.requires_capabilities): continue
		if applicable_solution.is_valid() and not applicable_solution.call(solution): continue
		solutions.append(solution)
		scale = maxf(scale, float(solution.get("priority", 1)))
	var candidates: Array[Dictionary] = []
	for solution in solutions:
		var addressed: Array[Dictionary] = []
		var score := 0.0
		for type in types:
			if solution.addresses.has(type):
				addressed.append(pressure[type])
				score += float(pressure[type].severity) * (float(solution.get("priority", 1)) / scale)
		if addressed.is_empty() or score <= 0: continue
		addressed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.severity > b.severity if a.severity != b.severity else (a.type < b.type if a.type != b.type else String(a.get("source_id", "")) < String(b.get("source_id", ""))))
		candidates.append({"id":solution.id,"solution":solution,"score":score,"problems":addressed,"problem":addressed[0]})
	_sort_scored(candidates)
	return candidates

func research_candidates(problem_instances: Array, applicable_solution: Callable = Callable()) -> Array[Dictionary]:
	var known := known_capabilities()
	var researchable := researchable_technologies()
	var technologies: Array[Dictionary] = catalog.technology_list()
	var solutions: Array[Dictionary] = []
	for solution in catalog.solution_list():
		if not applicable_solution.is_valid() or bool(applicable_solution.call(solution)): solutions.append(solution)
	var technology_scale := 1.0
	var solution_scale := 1.0
	for technology in technologies:
		technology_scale = maxf(technology_scale, float(technology.get("priority", 1.0)))
	for solution in solutions:
		solution_scale = maxf(solution_scale, float(solution.get("priority", 1.0)))
	var scored: Dictionary = {}
	var pressures: Array[Dictionary] = []
	for raw_problem in problem_instances:
		if not (raw_problem is Dictionary):
			continue
		var problem: Dictionary = raw_problem
		if problem.get("recognition_state", "RECOGNIZED") != "RECOGNIZED": continue
		if not (problem.get("type") is String) or not Validation.number(problem.get("severity", 0.0)):
			continue
		var problem_type := ProblemRegistry.normalize_id(problem.type)
		if not problem_registry.has_problem(problem_type):
			continue
		var severity := clampf(float(problem.get("severity", 0.0)), 0.0, 1.0)
		if severity <= 0.0:
			continue
		pressures.append({"type": problem_type, "severity": severity})
	# Accumulate in a canonical order, independent of source/dictionary ordering.
	pressures.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.type < b.type if a.type != b.type else a.severity < b.severity
	)
	for problem in pressures:
		var problem_type: String = problem.type
		var severity: float = problem.severity
		var problem_scores: Dictionary = {}
		for solution in solutions:
			if not solution.get("addresses", []).has(problem_type):
				continue
			var missing: Array[String] = capability_registry.missing(known, solution.get("requires_capabilities", []))
			if missing.is_empty():
				continue
			var frontiers: Array[Dictionary] = []
			var reachable := true
			for capability in missing:
				var path := _research_frontier(capability, known, technologies, {})
				if not path.reachable:
					reachable = false
					break
				frontiers.append(path.frontier)
			if not reachable:
				continue
			for technology in researchable:
				var coverage := 0
				for frontier in frontiers:
					if frontier.has(technology.id):
						coverage += 1
				if coverage == 0:
					continue
				var technology_id := String(technology.id)
				var entry: Dictionary = scored.get(technology_id, {
					"technology": technology.duplicate(true),
					"score": 0.0,
					"problems": [],
					"enables_toward": [],
				})
				var coverage_ratio := float(coverage) / float(missing.size())
				# Alternative solutions are alternatives, not additional world pressure.
				# One common scaling preserves relative priorities while bounding products.
				var contribution := severity * (float(solution.get("priority", 1.0)) / solution_scale) * (float(technology.get("priority", 1.0)) / technology_scale) * coverage_ratio
				var previous: float = problem_scores.get(technology_id, 0.0)
				entry.score += maxf(0.0, contribution - previous)
				problem_scores[technology_id] = maxf(previous, contribution)
				if not entry.problems.has(problem_type):
					entry.problems.append(problem_type)
				if not entry.enables_toward.has(String(solution.id)):
					entry.enables_toward.append(String(solution.id))
				scored[technology_id] = entry
	var result: Array[Dictionary] = []
	for technology_id in scored:
		var entry: Dictionary = scored[technology_id]
		entry.problems.sort()
		entry.enables_toward.sort()
		result.append(entry)
	_sort_scored(result, true)
	return result


func _research_frontier(capability: String, known: Array[String], technologies: Array[Dictionary], visiting: Dictionary) -> Dictionary:
	if known.has(capability):
		return {"reachable": true, "frontier": {}}
	if visiting.has(capability):
		return {"reachable": false, "frontier": {}}
	var next := visiting.duplicate()
	next[capability] = true
	var frontier: Dictionary = {}
	var reachable := false
	for technology in technologies:
		if knows_technology(technology.id) or not capability_registry.expand(technology.grants).has(capability):
			continue
		var missing: Array[String] = capability_registry.missing(known, technology.requires_capabilities)
		if missing.is_empty():
			reachable = true
			frontier[technology.id] = true
			continue
		var prerequisites: Dictionary = {}
		var viable := true
		for required in missing:
			var path := _research_frontier(required, known, technologies, next)
			if not path.reachable:
				viable = false
				break
			prerequisites.merge(path.frontier)
		if viable:
			reachable = true
			frontier.merge(prerequisites)
	return {"reachable": reachable, "frontier": frontier}


func preferred_research(problem_instances: Array, applicable_solution: Callable = Callable()) -> Dictionary:
	var candidates := research_candidates(problem_instances, applicable_solution)
	return {} if candidates.is_empty() else candidates[0].duplicate(true)


func _sort_scored(entries: Array[Dictionary], nested_technology: bool = false) -> void:
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := float(a.get("score", 0.0))
		var score_b := float(b.get("score", 0.0))
		if score_a != score_b:
			return score_a > score_b
		var id_a := String(a.get("technology", {}).get("id", "")) if nested_technology else String(a.get("id", ""))
		var id_b := String(b.get("technology", {}).get("id", "")) if nested_technology else String(b.get("id", ""))
		return id_a < id_b
	)
