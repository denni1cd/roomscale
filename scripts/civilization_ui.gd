extends Control
## Normal gameplay HUD reads authoritative civilization state.

var simulation: Node
var resources: Label
var strategy: Label
var inspection: Label
var _timer := 0.0
var object_choice: OptionButton
var object_ids: Array[String] = []
var priority_choices: Dictionary = {}
var citizen_panel: PanelContainer
var citizen_label: Label
var action_feedback := ""
var authorize: Button

func configure(controller: Node) -> void:
	simulation = controller
	name = "CivilizationHUD"
	position = Vector2(20, 18)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(485, 552)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.052, 0.068, 0.9)
	style.border_color = Color("bca36b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	resources = Label.new()
	resources.position = Vector2(14, 10)
	resources.add_theme_font_size_override("font_size", 15)
	resources.modulate = Color("f5e3c5")
	add_child(resources)
	strategy = Label.new()
	strategy.position = Vector2(14, 137)
	strategy.add_theme_font_size_override("font_size", 13)
	strategy.modulate = Color("f2cf7e")
	add_child(strategy)
	inspection = Label.new()
	inspection.position = Vector2(14, 438)
	inspection.add_theme_font_size_override("font_size", 13)
	add_child(inspection)
	var row := 0
	for family in simulation.planner.priorities:
		var label := Label.new()
		label.text = family
		label.position = Vector2(14 + (row % 2) * 235, 225 + (row / 2) * 35)
		label.add_theme_font_size_override("font_size", 14)
		add_child(label)
		var choice := OptionButton.new()
		choice.position = label.position + Vector2(106, 0)
		choice.size = Vector2(115, 30)
		for level in simulation.planner.LEVELS: choice.add_item(level)
		choice.select(int(simulation.planner.priorities[family]))
		choice.item_selected.connect(func(index: int) -> void: simulation.planner.set_priority(family, index))
		add_child(choice)
		priority_choices[family] = choice
		row += 1
	var water := Button.new()
	water.text = "Secure Water"
	water.position = Vector2(14, 305)
	water.size = Vector2(140, 32)
	water.pressed.connect(func() -> void: simulation.secure_resource("water"))
	add_child(water)
	var food := Button.new()
	food.text = "Secure Food"
	food.position = Vector2(164, 305)
	food.size = Vector2(140, 32)
	food.pressed.connect(func() -> void: simulation.secure_resource("food"))
	add_child(food)
	object_choice = OptionButton.new()
	object_choice.position = Vector2(14, 398)
	object_choice.size = Vector2(280, 32)
	for id in simulation.salvage.objects:
		object_ids.append(id)
		object_choice.add_item(String(simulation.resources.objects[id].data.get("name", id)))
	add_child(object_choice)
	authorize = Button.new()
	authorize.text = "Authorize Salvage"
	authorize.position = Vector2(305, 398)
	authorize.size = Vector2(165, 32)
	authorize.pressed.connect(func() -> void:
		if not object_ids.is_empty():
			var accepted: bool = simulation.authorize_salvage(object_ids[object_choice.selected])
			action_feedback = "Salvage authorized" if accepted else "Preserved: supports a resource or active route"
			refresh())
	add_child(authorize)
	var directives := Label.new()
	directives.name = "Directives"
	directives.position = Vector2(14, 347)
	directives.add_theme_font_size_override("font_size", 13)
	directives.modulate = Color("a9dad4")
	add_child(directives)
	var speed_row := HBoxContainer.new()
	speed_row.position = Vector2(14, 518)
	add_child(speed_row)
	for multiplier in [0.0, 1.0, 4.0, 10.0]:
		var button := Button.new()
		button.text = "Pause" if multiplier == 0 else "%dx" % int(multiplier)
		button.custom_minimum_size = Vector2(105, 28)
		button.pressed.connect(func() -> void: simulation.speed = multiplier)
		speed_row.add_child(button)
	citizen_panel = PanelContainer.new()
	citizen_panel.position = Vector2(940, 96)
	citizen_panel.add_theme_stylebox_override("panel", style)
	add_child(citizen_panel)
	citizen_label = Label.new()
	citizen_label.custom_minimum_size = Vector2(265, 178)
	citizen_label.add_theme_font_size_override("font_size", 13)
	citizen_panel.add_child(citizen_label)
	refresh()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 0.2:
		_timer = 0
		refresh()

func refresh() -> void:
	var state: Dictionary = simulation.status()
	var stock: Dictionary = simulation.economy.available
	var in_transit: float = simulation.economy.state_total("wood", "in_transit") + simulation.economy.state_total("metal", "in_transit")
	for bundle in simulation.resources.bundles.values():
		if bundle.state == "in_transit" and bundle.resource in ["wood", "metal"]: in_transit += float(bundle.amount)
	resources.text = "ROOMSCALE  ·  %d citizens  ·  Day %.2f  ·  %dx\nFood %.0f  ·  %.2f days  ·  use %d/day\nWater %.0f  ·  %.2f days  ·  use %d/day\nWood %.0f  ·  Metal %.0f  ·  %.0f materials in transit\nShelter %d/%d  ·  Rest %d/%d  ·  Urgent %d" % [state.population, state.days, int(simulation.speed), stock.food, state.food_days, state.population * 2, stock.water, state.water_days, state.population * 3, stock.wood, stock.metal, in_transit, state.shelter, state.population, state.resting, simulation.needs.rest_capacity, state.urgent]
	var reasons: Array[String] = simulation.planner.reasons.duplicate()
	reasons.sort_custom(func(a: String, b: String) -> bool: return a.contains("No authorized") and not b.contains("No authorized"))
	strategy.text = "\n".join(reasons.slice(0, 4)) if not reasons.is_empty() else ("Water reserve critical — secure a water source" if state.water_days < 1 else "Food and water reserves stable")
	if state.shelter < state.population and not strategy.text.contains("Shelter shortage"): strategy.text += "\nShelter shortage: %d citizens without housing" % (state.population - state.shelter)
	for family in priority_choices: priority_choices[family].select(int(simulation.planner.priorities[family]))
	get_node("Directives").text = "Objectives: " + (" / ".join(simulation.planner.directives.values()) if not simulation.planner.directives.is_empty() else "Choose a civilization objective")
	var project: Dictionary = simulation.construction.status()
	get_node("Directives").text += "\nTraversal: %s %.0f%% · W %d/%d M %d/%d" % [String(project.state).replace("_", " "), project.progress_percent, project.delivered.wood, project.required.wood, project.delivered.metal, project.required.metal]
	var selected: Node3D = simulation.scene.get("_selected_citizen")
	citizen_panel.visible = is_instance_valid(selected)
	if is_instance_valid(selected):
		var info: Dictionary = selected.get_inspection_status()
		citizen_label.text = " Citizen %02d · %s\n Food: %s (%.0f%%)\n Water: %s (%.0f%%)\n Fatigue: %s (%.0f%%)\n Shelter: %s · Rest slot %d\n Task: %s\n Target: (%.0f, %.0f, %.0f)" % [info.id + 1, info.state, simulation.needs.severity(info.needs.food), float(info.needs.food) * 100, simulation.needs.severity(info.needs.water), float(info.needs.water) * 100, simulation.needs.severity(info.needs.fatigue), float(info.needs.fatigue) * 100, "available" if info.needs.sheltered else "shortage", info.needs.rest_slot, String(info.task).replace("_", " "), info.target.x, info.target.y, info.target.z]
	if object_choice != null and not object_ids.is_empty():
		var id := object_ids[object_choice.selected]
		var object: Dictionary = simulation.resources.objects[id]
		var salvage: Dictionary = simulation.salvage.objects[id]
		var remaining := {}
		for index in range(int(salvage.stage), salvage.stages.size()):
			for resource in salvage.stages[index].yields: remaining[resource] = float(remaining.get(resource, 0)) + float(salvage.stages[index].yields[resource])
		inspection.text = "%s · %s · %s\n%s · stage %d/%d · work %.1fs\nRemaining yield: %s" % [String(object.data.get("name", id)), object.profile.material, "AUTHORIZED" if salvage.authorized else "PROTECTED — authorization required", salvage.state, salvage.stage, salvage.stages.size(), salvage.progress, remaining]
		authorize.disabled = simulation.salvage.depleted(id) or bool(salvage.authorized)
		if not action_feedback.is_empty(): inspection.text += "\n" + action_feedback

func select_object(object_id: String) -> bool:
	var index := object_ids.find(object_id)
	if index < 0: return false
	object_choice.select(index)
	action_feedback = ""
	refresh()
	return true
