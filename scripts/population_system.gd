extends RefCounted
## Abstract cohorts: normal production entities and needs, never a population counter.
const Citizen := preload("res://scripts/citizen_agent.gd")
const COHORT := 5
const CAP := 150
const STABILITY := 300.0
const COOLDOWN := 600.0
var stable_since := -1.0
var last_growth := -1000.0
var cohorts: Array[Dictionary] = []
var reason := "Waiting for sustained reserves and shelter"

func eligibility(state: Dictionary, emergency: bool, blocked: bool) -> String:
	if int(state.population) + COHORT > CAP: return "Population cap reached"
	if int(state.shelter) - int(state.population) < COHORT: return "Insufficient shelter for entire cohort"
	if emergency or minf(float(state.food_days), float(state.water_days)) < 2.0: return "Survival reserves unsafe"
	if int(state.urgent) > maxi(3, int(state.population * 0.25)): return "Too many urgent citizens"
	if blocked: return "Critical material project blocked"
	return ""

func evaluate(sim: Node, state: Dictionary, emergency: bool, blocked: bool) -> void:
	var why := eligibility(state, emergency, blocked)
	if why.is_empty() and not sim.development.carrying_capacity(int(state.population) + COHORT): why = "Finite source horizon below five days"
	if not why.is_empty():
		stable_since = -1
		reason = why
		sim.journal.record(sim.seconds, "growth_paused", why, state, sim.coordinator.housing_station, "growth_policy")
		return
	if stable_since < 0: stable_since = sim.seconds
	if sim.seconds - stable_since < STABILITY:
		reason = "Healthy stability window %.0f/%.0f seconds" % [sim.seconds - stable_since, STABILITY]
		return
	if sim.seconds - last_growth < COOLDOWN:
		reason = "Cohort cooldown"
		return
	var spawn: Vector3 = sim.coordinator.navigation.nearest_walkable_position(sim.coordinator.housing_station + Vector3(0, 0, 20))
	if not is_finite(spawn.x) or sim.coordinator.navigation.is_obstacle_position(spawn) or sim.coordinator.navigation.path_between(spawn, sim.coordinator.depot_station).is_empty():
		reason = "No valid settlement arrival location"
		return
	# Ensure forecasts remain healthy immediately after the whole cohort joins.
	for resource in ["food", "water"]:
		if sim.economy.forecast(resource, sim.citizens.size() + COHORT) < 2: return
	var before: int = sim.citizens.size()
	for offset in range(COHORT):
		var id: int = sim.citizens.size()
		var citizen := Citizen.new()
		citizen.needs = sim.needs.initial(id)
		sim.citizens.append(citizen)
		sim.scene.add_child(citizen)
		sim.coordinator._enqueue_for(id, 0)
		citizen.initialize(id, spawn, sim.coordinator.navigation, sim.coordinator)
		citizen.set_process(false)
	last_growth = sim.seconds
	stable_since = sim.seconds
	reason = "Cohort joined after sustained stability"
	var cohort := {"seconds": sim.seconds, "before": before, "after": sim.citizens.size(), "food_days_before": state.food_days, "water_days_before": state.water_days, "shelter": state.shelter}
	cohorts.append(cohort)
	sim.journal.record(sim.seconds, "cohort_joined", "New cohort joined: %d real citizens" % sim.citizens.size(), cohort, spawn, "cohort:%d" % cohorts.size())
