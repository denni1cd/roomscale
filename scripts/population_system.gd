extends RefCounted
## Abstract cohorts: normal production entities and needs, never a population counter.
const Citizen := preload("res://scripts/citizen_agent.gd")
const COHORT := 5
var cohort_size := COHORT
const CAP := 150
const STABILITY := 300.0
const COOLDOWN := 600.0
var stable_since := -1.0
var last_growth := -1000.0
var cohorts: Array[Dictionary] = []
var reason := "Waiting for sustained reserves and shelter"

# Four-inch navigation cells: choose actual cell centers in a bounded local area.
# Validate the whole group before creating any entity.
func arrival_positions(sim: Node) -> Array[Vector3]:
	var nav: Node = sim.coordinator.navigation
	var origin: Vector3 = nav.nearest_walkable_position(sim.coordinator.housing_station + Vector3(0, 0, 20))
	var points: Array[Vector3] = []
	if not origin.is_finite(): return points
	var candidates: Array[Vector3] = []
	for x in range(-4, 5):
		for z in range(-4, 5): candidates.append(origin + Vector3(x * 4, 0, z * 4))
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		var da := a.distance_squared_to(origin)
		var db := b.distance_squared_to(origin)
		return da < db if da != db else (a.z < b.z if a.z != b.z else a.x < b.x))
	for at in candidates:
		if not nav.room_bounds().has_point(Vector2(at.x, at.z)) or not nav.is_walkable(at) or nav.is_obstacle_position(at): continue
		if nav.path_between(at, sim.coordinator.depot_station).is_empty(): continue
		if points.any(func(p: Vector3) -> bool: return p.distance_to(at) < 3.99): continue
		points.append(at)
		if points.size() == cohort_size: return points
	return []

func eligibility(state: Dictionary, emergency: bool, blocked: bool) -> String:
	if int(state.population) + cohort_size > CAP: return "Population cap reached"
	if int(state.shelter) - int(state.population) < cohort_size: return "Insufficient shelter for entire cohort"
	if emergency or minf(float(state.food_days), float(state.water_days)) < 2.0: return "Survival reserves unsafe"
	if int(state.urgent) > maxi(3, int(state.population * 0.25)): return "Too many urgent citizens"
	if blocked: return "Critical material project blocked"
	return ""

func evaluate(sim: Node, state: Dictionary, emergency: bool, blocked: bool) -> void:
	var why := eligibility(state, emergency, blocked)
	if sim.founder_mode and (not sim.has_capability("workshop") or not sim.has_capability("storage")): why = "Settlement infrastructure not yet established"
	if why.is_empty() and not sim.development.carrying_capacity(int(state.population) + cohort_size): why = "Finite source horizon below five days"
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
	var positions := arrival_positions(sim)
	if positions.size() != cohort_size:
		reason = "No safe connected arrival position; new citizen waiting" if cohort_size == 1 else "No five safe connected arrival positions; entire cohort waiting"
		sim.journal.record(sim.seconds, "growth_paused", reason, state, sim.coordinator.housing_station, "arrival_blocked")
		return
	# Ensure forecasts remain healthy immediately after the whole cohort joins.
	for resource in ["food", "water"]:
		if sim.economy.forecast(resource, sim.citizens.size() + cohort_size) < 2: return
	var before: int = sim.citizens.size()
	var water_before: float = sim.economy.forecast("water", before)
	var food_before: float = sim.economy.forecast("food", before)
	var stable_seconds: float = sim.seconds - stable_since
	for offset in range(cohort_size):
		var id: int = sim.citizens.size()
		var citizen := Citizen.new()
		citizen.needs = sim.needs.initial(id)
		sim.citizens.append(citizen)
		sim.scene.add_child(citizen)
		sim.coordinator._enqueue_for(id, 0)
		citizen.initialize(id, positions[offset], sim.coordinator.navigation, sim.coordinator)
		citizen.set_process(false)
	last_growth = sim.seconds
	stable_since = sim.seconds
	reason = "Cohort joined after sustained stability"
	var cohort := {"seconds": sim.seconds, "before": before, "after": sim.citizens.size(), "food_days_before": state.food_days, "water_days_before": state.water_days, "shelter": state.shelter}
	cohort.stable_seconds = stable_seconds
	cohort.food_days_before = food_before
	cohort.water_days_before = water_before
	cohort.food_days_after = sim.economy.forecast("food", sim.citizens.size())
	cohort.water_days_after = sim.economy.forecast("water", sim.citizens.size())
	cohort.positions = positions.duplicate()
	var centroid := Vector3.ZERO
	for at in positions: centroid += at / cohort_size
	cohort.centroid = centroid
	cohorts.append(cohort)
	sim.journal.record(sim.seconds, "cohort_joined", "New cohort joined: %d real citizens" % sim.citizens.size(), cohort, centroid, "cohort:%d" % cohorts.size())
