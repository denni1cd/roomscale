extends Control
## Fishbowl observer: reusable edge-anchored controls, no strategic writes.
const Adapter := preload("res://scripts/fishbowl_narrative_adapter.gd")
const Presenter := preload("res://scripts/fishbowl_event_presenter.gd")
var simulation: Node
var presenter := Presenter.new()
var diagnostics := false
var status_label: Label
var governor_label: Label
var project_label: Label
var event_label: Label
var title_label: Label
var details_label: Label
var status_panel: PanelContainer
var project_panel: PanelContainer
var event_panel: PanelContainer
var title_panel: PanelContainer
var details_panel: PanelContainer
var controls_panel: PanelContainer
var controls: HBoxContainer
var idle := 0.0
var title_age := 0.0
var refresh_age := 0.0
var last_shot := -1
var last_event := -1
var speed_buttons: Dictionary = {}
var camera_button: CheckButton
var details_button: CheckButton

func label_for(panel: Control, font_size: int = 16) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f5e3c5"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return label

func panel_at(anchor: Vector2, offsets: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	add_child(panel)
	panel.anchor_left = anchor.x
	panel.anchor_right = anchor.x
	panel.anchor_top = anchor.y
	panel.anchor_bottom = anchor.y
	panel.offset_left = offsets.position.x
	panel.offset_top = offsets.position.y
	panel.offset_right = offsets.end.x
	panel.offset_bottom = offsets.end.y
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.046, 0.052, 0.91)
	style.border_color = Color("9c8051")
	style.border_width_left = 2
	style.set_corner_radius_all(5)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func configure(sim: Node) -> void:
	simulation = sim
	name = "FishbowlHUD"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	simulation.hud.set_process(false)
	status_panel = panel_at(Vector2.ZERO, Rect2(20, 18, 1000, 58))
	status_panel.anchor_right = 1
	status_panel.offset_right = -20
	var lines := VBoxContainer.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_child(lines)
	status_label = label_for(lines, 18)
	governor_label = label_for(lines, 14)
	governor_label.add_theme_color_override("font_color", Color("dbbc7f"))
	project_panel = panel_at(Vector2(1, 1), Rect2(-324, -200, 304, 110))
	project_label = label_for(project_panel)
	event_panel = panel_at(Vector2(0, 1), Rect2(20, -182, 570, 80))
	event_label = label_for(event_panel, 17)
	event_panel.hide()
	title_panel = panel_at(Vector2.ZERO, Rect2(20, 98, 500, 66))
	title_label = label_for(title_panel, 17)
	title_label.text = "ROOMSCALE\nAutonomous Colony · Fishbowl Mode"
	controls_panel = panel_at(Vector2(0, 1), Rect2(20, -68, 585, 50))
	controls = HBoxContainer.new()
	controls_panel.add_child(controls)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.add_theme_constant_override("separation", 8)
	for multiplier in [0.0, 1.0, 4.0, 10.0]:
		var button := Button.new()
		button.text = "Pause" if multiplier == 0 else "%d×" % int(multiplier)
		button.custom_minimum_size = Vector2(65, 34)
		button.pressed.connect(func() -> void: simulation.speed = multiplier; wake(); refresh())
		controls.add_child(button)
		speed_buttons[multiplier] = button
	camera_button = CheckButton.new()
	camera_button.text = "Auto camera"
	camera_button.button_pressed = sim.camera_director.enabled
	camera_button.toggled.connect(func(active: bool) -> void: simulation.camera_director.enabled = active; title_panel.hide(); wake())
	controls.add_child(camera_button)
	details_button = CheckButton.new()
	details_button.text = "Details · F3"
	details_button.toggled.connect(set_diagnostics)
	controls.add_child(details_button)
	details_panel = panel_at(Vector2.ZERO, Rect2(20, 110, 630, 440))
	details_panel.anchor_bottom = 1
	details_panel.offset_bottom = -78
	var scroll := ScrollContainer.new()
	details_panel.add_child(scroll)
	details_label = label_for(scroll, 14)
	details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_label.custom_minimum_size.x = 580
	details_panel.hide()
	refresh()

func wake() -> void: idle = 0

func set_diagnostics(active: bool) -> void:
	diagnostics = active
	details_button.set_pressed_no_signal(active)
	details_panel.visible = active
	wake()
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		set_diagnostics(not diagnostics)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void: advance(delta)

func advance(real_delta: float) -> void:
	presenter.ingest(simulation.journal.events)
	presenter.advance(real_delta)
	idle += real_delta
	title_age += real_delta
	refresh_age += real_delta
	if not presenter.current.is_empty():
		if last_event != int(presenter.current.id):
			last_event = int(presenter.current.id)
			wake()
		event_label.text = "%s  ·  Day %.2f\n%s" % [presenter.current.headline, presenter.current.day, presenter.current.subtitle]
		event_panel.modulate.a = presenter.alpha
	event_panel.visible = not presenter.current.is_empty() and not diagnostics
	var director: Node = simulation.camera_director
	if director.shots != last_shot:
		last_shot = director.shots
		if not director.current_shot.is_empty():
			title_label.text = director.current_shot.headline + "\n" + director.current_shot.subtitle
			title_age = 0
			wake()
	if not director.current_shot.is_empty(): title_label.text = director.current_shot.headline + "\n" + director.shot_subtitle()
	title_panel.visible = title_age < 6 and not diagnostics and director.enabled and director.title_is_current()
	title_panel.modulate.a = minf(clampf(title_age / 0.3, 0, 1), clampf((6 - title_age) / 0.7, 0, 1))
	var mouse := get_global_mouse_position()
	if status_panel.get_global_rect().has_point(mouse) or controls.get_global_rect().has_point(mouse) or (project_panel.visible and project_panel.get_global_rect().has_point(mouse)) or diagnostics: wake()
	var emphasized := idle < 10 or event_panel.visible or title_panel.visible
	status_panel.modulate.a = move_toward(status_panel.modulate.a, 1.0 if emphasized else 0.76, real_delta * 0.5)
	controls_panel.modulate.a = status_panel.modulate.a
	if refresh_age >= 0.2:
		refresh_age = 0
		refresh()

func refresh() -> void:
	var s := Adapter.status(simulation)
	status_label.text = "Day %.2f   ·   Population %d/%d   ·   Food %.1fd   ·   Water %.1fd   ·   Wood %.0f   ·   Metal %.0f   ·   %s" % [s.days, s.population, s.shelter, s.food_days, s.water_days, s.wood, s.metal, "Paused" if s.speed == 0 else "%d×" % int(s.speed)]
	governor_label.text = s.governor
	var p := Adapter.project(simulation)
	project_panel.visible = not p.is_empty() and not diagnostics
	if not p.is_empty(): project_label.text = "%s\n%s · %.0f%%\nWood %d/%d · Metal %d/%d" % [p.name, p.stage, p.progress * 100, p.delivered.wood, p.required.wood, p.delivered.metal, p.required.metal]
	for multiplier in speed_buttons: speed_buttons[multiplier].modulate = Color("f3cf86") if simulation.speed == multiplier else Color.WHITE
	camera_button.set_pressed_no_signal(simulation.camera_director.enabled)
	if diagnostics:
		simulation.hud.refresh()
		var hud: Control = simulation.hud
		details_label.text = "COLONY DETAILS\n" + hud.resources.text + "\n\n" + hud.strategy.text + "\n\nPlanner: " + " / ".join(simulation.planner.reasons) + "\n" + hud.get_node("Directives").text + "\n\n" + hud.fishbowl_development.text + "\n\n" + hud.inspection.text + "\n\n" + (hud.citizen_label.text if hud.citizen_panel.visible else "Click a citizen for needs and task details.") + "\n\nAccounting: " + str(simulation.economy.snapshot()) + "\n\n"
		for event in simulation.journal.events: details_label.text += "Day %.2f · %s\n" % [event.day, event.message]
