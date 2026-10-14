extends RefCounted
## Explicit single-input/single-output depot recipes, selected by catalog opt-in.
const Vocabulary := preload("res://scripts/resource_vocabulary.gd")
const Validation := preload("res://scripts/innovation_validation.gd")
var recipes: Dictionary = {}
var errors: Array[String] = []

func _init() -> void:
	var path := "res://innovation/production_recipes.json"
	if not FileAccess.file_exists(path): errors.append("Recipe registry missing"); return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary: errors.append("Recipe registry must be an object"); return
	var ids: Array = data.keys(); ids.sort()
	for id in ids:
		var value: Variant = data[id]
		if not value is Dictionary or not Vocabulary.supports(value.get("input")) or not Vocabulary.supports(value.get("output")): errors.append("Invalid recipe resources"); continue
		var valid := true
		for field in ["input_amount","output_amount","work"]:
			if not Validation.number(value.get(field)) or value[field] <= 0: valid = false
		if not value.get("requires_workshop",true) is bool: valid = false
		if not valid: errors.append("Invalid recipe quantities"); continue
		recipes[id] = value.duplicate(true)
		recipes[id]["id"] = id

func for_resource(resource: String, allowed: Array, sim: Node) -> Dictionary:
	var ids: Array = allowed.duplicate(); ids.sort()
	for id in ids:
		if not recipes.has(id): continue
		var recipe: Dictionary = recipes[id]
		if recipe.output == resource and (not recipe.get("requires_workshop",true) or sim.has_capability("workshop")): return recipe
	return {}

func perform(sim: Node, task: Dictionary, citizen: Node3D, effort: float) -> bool:
	if not recipes.has(task.get("recipe_id","")) or not sim.economy.tickets.has(task.get("ticket",-1)): return false
	var recipe: Dictionary = recipes[task.recipe_id]
	var ticket: Dictionary = sim.economy.tickets[task.ticket]
	if recipe.get("requires_workshop",true) and not sim.has_capability("workshop"): return false
	if ticket.owner != task.fabrication_owner or ticket.instance_id != sim.instance_id or ticket.resource != recipe.input or float(ticket.amount) != float(recipe.input_amount) or ticket.state != "reserved": return false
	if not sim.economy.available.has(recipe.output) or citizen.global_position.distance_to(sim.coordinator.depot_station) > 1.6: return false
	task.work_seconds = minf(float(recipe.work),float(task.get("work_seconds",0))+effort)
	if float(task.work_seconds)+0.00001 < float(recipe.work): return false
	# Preflight output capacity before consuming input, so even extreme authored
	# quantities cannot overflow a ledger or consume input without an output.
	if not sim.resources.can_create_bundle(recipe.output,float(recipe.output_amount)) or not sim.economy.can_receive(recipe.output,float(recipe.output_amount)): return false
	if not sim.economy.consume(task.ticket,true): return false
	var bundle: int = sim.resources.create_bundle(recipe.output,float(recipe.output_amount),citizen.global_position,"fabrication:"+sim.instance_id)
	if bundle < 0: return false
	sim.resources.reserve_bundle(bundle,citizen.citizen_id,sim.instance_id)
	sim.resources.pickup_bundle(bundle,citizen.citizen_id,citizen.global_position)
	return sim.resources.deliver_bundle(bundle,citizen.citizen_id,citizen.global_position,sim.coordinator.depot_station,sim.economy)
