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

var civilization_id: String = ""
var capability_registry = null
var problem_registry = null
var catalog = null
var base_capabilities: Array[String] = []
var known_technologies: Dictionary = {}
var validation_errors: Array[String] = []


static func create(civ_id: String, starting_capabilities: Array = []) -> Dictionary:
	var capability_result := CapabilityRegistry.load_default()
	var problem_result := ProblemRegistry.load_default()
	var catalog_result := InnovationCatalog.load_id(civ_id)
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
		var normalized := String(capability).strip_edges().to_upper()
		if not normalized.is_empty() and not system.base_capabilities.has(normalized):
			system.base_capabilities.append(normalized)
	system.base_capabilities.sort()
	system.validation_errors = system._validate_cross_references()
	return {"ok": system.validation_errors.is_empty(), "system": system, "errors": system.validation_errors}


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
	var technology := catalog.technology(normalized)
	if technology.is_empty():
		return {"ok": false, "error": "unknown technology: %s" % normalized}
	if known_technologies.has(normalized):
		return {"ok": true, "technology": technology, "already_known": true}
	var missing := capability_registry.missing(known_capabilities(), technology.get("requires_capabilities", []))
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
		var technology := catalog.technology(String(technology_id))
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


func research_candidates(problem_instances: Array) -> Array[Dictionary]:
	var known := known_capabilities()
	var researchable := researchable_technologies()
	var scored: Dictionary = {}
	for raw_problem in problem_instances:
		if not (raw_problem is Dictionary):
			continue
		var problem: Dictionary = raw_problem
		var problem_type := ProblemRegistry.normalize_id(String(problem.get("type", "")))
		if not problem_registry.has_problem(problem_type):
			continue
		var severity := clampf(float(problem.get("severity", 0.0)), 0.0, 1.0)
		if severity <= 0.0:
			continue
		for solution in catalog.solution_list():
			if not solution.get("addresses", []).has(problem_type):
				continue
			var missing := capability_registry.missing(known, solution.get("requires_capabilities", []))
			if missing.is_empty():
				continue
			for technology in researchable:
				var granted := capability_registry.expand(technology.get("grants", []))
				var coverage := 0
				for capability in missing:
					if granted.has(capability):
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
				entry.score += severity * float(solution.get("priority", 1.0)) * float(technology.get("priority", 1.0)) * coverage_ratio
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


func preferred_research(problem_instances: Array) -> Dictionary:
	var candidates := research_candidates(problem_instances)
	return {} if candidates.is_empty() else candidates[0].duplicate(true)


func _sort_scored(entries: Array[Dictionary], nested_technology: bool = false) -> void:
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := float(a.get("score", 0.0))
		var score_b := float(b.get("score", 0.0))
		if not is_equal_approx(score_a, score_b):
			return score_a > score_b
		var id_a := String(a.get("technology", {}).get("id", "")) if nested_technology else String(a.get("id", ""))
		var id_b := String(b.get("technology", {}).get("id", "")) if nested_technology else String(b.get("id", ""))
		return id_a < id_b
	)
