extends SceneTree

const CapabilityRegistry := preload("res://scripts/capability_registry.gd")
const ProblemRegistry := preload("res://scripts/problem_registry.gd")
const InnovationSystem := preload("res://scripts/innovation_system.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var capability_result := CapabilityRegistry.load_default()
	_check(bool(capability_result.ok), "Shared capability registry must validate: %s" % [capability_result.errors])
	if bool(capability_result.ok):
		var expanded: Array[String] = capability_result.registry.expand(["STEAM_POWER"])
		_check(expanded.has("STEAM_POWER"), "Steam power must remain an explicit capability")
		_check(expanded.has("POWER_SOURCE"), "Steam power must satisfy generic POWER_SOURCE")

	var problem_result := ProblemRegistry.load_default()
	_check(bool(problem_result.ok), "Shared problem registry must validate: %s" % [problem_result.errors])
	var problems: Array[Dictionary] = []
	if bool(problem_result.ok):
		var first := problem_result.registry.set_problem("vertical_access", "desk_north", 0.8, {"target": "water"})
		var second := problem_result.registry.set_problem("VERTICAL_ACCESS", "desk_north", 0.9, {"target": "water"})
		_check(bool(first.ok) and bool(second.ok), "World systems must be able to report a shared problem")
		_check(int(second.problem.observation_count) == 2, "Repeated observations must preserve problem identity")
		problems = problem_result.registry.active_problems()
		_check(problems.size() == 1, "One source/problem pair must produce one active problem instance")

	var clockwork_result := InnovationSystem.create("clockwork")
	var verdant_result := InnovationSystem.create("verdant")
	_check(bool(clockwork_result.ok), "Clockwork innovation catalog must validate: %s" % [clockwork_result.errors])
	_check(bool(verdant_result.ok), "Verdant innovation catalog must validate: %s" % [verdant_result.errors])
	if bool(clockwork_result.ok) and bool(verdant_result.ok) and not problems.is_empty():
		var clockwork = clockwork_result.system
		var verdant = verdant_result.system

		_check(clockwork.viable_solutions("VERTICAL_ACCESS").is_empty(), "Clockwork must not start with an invented vertical solution")
		_check(verdant.viable_solutions("VERTICAL_ACCESS").is_empty(), "Verdant must not start with an invented vertical solution")

		var clockwork_choice: Dictionary = clockwork.preferred_research(problems)
		var verdant_choice: Dictionary = verdant.preferred_research(problems)
		_check(String(clockwork_choice.get("technology", {}).get("id", "")) == "grapple_engineering", "Vertical pressure should lead Clockwork toward grapple engineering first")
		_check(String(verdant_choice.get("technology", {}).get("id", "")) == "cultivated_vines", "The same vertical pressure should lead Verdant toward cultivated vines first")

		_check(bool(clockwork.learn_technology("grapple_engineering").ok), "Clockwork must be able to invent grapple engineering")
		var clockwork_after_grapple := _ids(clockwork.viable_solutions("VERTICAL_ACCESS"))
		_check(clockwork_after_grapple.has("grapple_route"), "Grapple engineering must make the authored grapple route viable")
		_check(not clockwork_after_grapple.has("steam_lift"), "Grapple engineering alone must not make a steam lift viable")

		_check(bool(clockwork.learn_technology("steam_engine").ok), "Clockwork must be able to invent the steam engine")
		_check(clockwork.known_capabilities().has("POWER_SOURCE"), "STEAM_POWER must satisfy the generic lift POWER_SOURCE requirement")
		_check(bool(clockwork.learn_technology("structural_engineering").ok), "Clockwork must be able to invent structural engineering")
		var clockwork_full := _ids(clockwork.viable_solutions("VERTICAL_ACCESS"))
		_check(clockwork_full.has("steam_lift"), "Cable engineering + steam power + structural engineering must make the steam lift viable")

		_check(bool(verdant.learn_technology("cultivated_vines").ok), "Verdant must be able to cultivate climbing vines")
		_check(_ids(verdant.viable_solutions("VERTICAL_ACCESS")).has("climbing_vine"), "Cultivated vines must make the Verdant climbing vine viable")
		_check(_ids(verdant.researchable_technologies()).has("accelerated_growth"), "Flexible growth must make accelerated growth researchable")
		_check(bool(verdant.learn_technology("root_architecture").ok), "Verdant must be able to invent root architecture")
		_check(bool(verdant.learn_technology("accelerated_growth").ok), "Verdant must be able to invent accelerated growth after cultivated vines")
		var verdant_full := _ids(verdant.viable_solutions("VERTICAL_ACCESS"))
		_check(verdant_full.has("climbing_tree"), "Load-bearing + accelerated growth must make the climbing tree viable")
		_check(not verdant_full.has("steam_lift"), "Verdant must never inherit Clockwork-only solutions through shared capabilities")

	var invalid := InnovationSystem.create("not_a_real_civilization")
	_check(not bool(invalid.ok), "Unknown civilizations must not silently fall back to another innovation catalog")

	if failures.is_empty():
		print("ROOMSCALE_INNOVATION_SYSTEM_PASS problems=shared capabilities=shared catalogs=clockwork,verdant deterministic=true")
		quit(0)
	else:
		push_error("ROOMSCALE_INNOVATION_SYSTEM_FAIL %s" % JSON.stringify(failures))
		quit(1)


func _ids(entries: Array) -> Array[String]:
	var result: Array[String] = []
	for entry in entries:
		if entry is Dictionary:
			result.append(String(entry.get("id", "")))
	result.sort()
	return result


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
