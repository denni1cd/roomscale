extends RefCounted
## Persistent need state. One ration satisfies .65 of a need; rates are per day.

const DAY_SECONDS := 600.0
const RATION_RELIEF := 0.65
const FOOD_PER_DAY := 2.0
const WATER_PER_DAY := 3.0
var shelter_capacity := 50
var rest_capacity := 12
var resting: Dictionary = {}
var meals := 0
var drinks := 0
var rests := 0

func initial(citizen_id: int) -> Dictionary:
	return {"food": 0.08 + (citizen_id % 10) * 0.025, "water": 0.12 + (citizen_id % 10) * 0.035, "fatigue": (citizen_id % 7) * 0.055, "sheltered": citizen_id < shelter_capacity, "rest_slot": -1}

func decay(needs: Dictionary, delta: float, is_resting: bool = false) -> void:
	needs.food = clampf(float(needs.food) + delta * RATION_RELIEF * FOOD_PER_DAY / DAY_SECONDS, 0, 1)
	needs.water = clampf(float(needs.water) + delta * RATION_RELIEF * WATER_PER_DAY / DAY_SECONDS, 0, 1)
	needs.fatigue = clampf(float(needs.fatigue) + delta * (-0.025 if is_resting else 0.0017), 0, 1)

func severity(value: float) -> String:
	return "Critical" if value >= 0.9 else ("Serious" if value >= 0.7 else ("Mild" if value >= 0.4 else "Satisfied"))

func work_factor(needs: Dictionary) -> float:
	return 0.25 if maxf(float(needs.food), float(needs.water)) >= 0.9 else (0.6 if maxf(float(needs.food), float(needs.water)) >= 0.7 else 1.0)

func satisfy(needs: Dictionary, resource: String) -> void:
	needs[resource] = maxf(0, float(needs[resource]) - RATION_RELIEF)
	if resource == "food": meals += 1
	if resource == "water": drinks += 1

func reserve_rest(citizen_id: int) -> int:
	for slot in range(rest_capacity):
		if not resting.has(slot):
			resting[slot] = citizen_id
			return slot
	return -1

func release_rest(slot: int, completed: bool) -> void:
	if resting.erase(slot) and completed: rests += 1
