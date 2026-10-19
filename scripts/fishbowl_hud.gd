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
var camera_button: OptionButton
var follow_button: OptionButton
var follow_targets: Array = []
var feed_rows: VBoxContainer
var feed_signature := "uninitialized"
var highlight: Node3D
var highlight_target: Dictionary = {}
var highlight_age := 0.0
var highlight_duration := 4.0
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
	project_panel = panel_at(Vector2(1, 1), Rect2(-384, -260, 364, 170) if Adapter.is_verdant() else Rect2(-324, -200, 304, 110))
	project_label = label_for(project_panel)
	event_panel = panel_at(Vector2(0, 1), Rect2(20, -630, 370, 530))
	event_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var feed_scroll := ScrollContainer.new()
	feed_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	feed_scroll.custom_minimum_size = Vector2(338, 495)
	event_panel.add_child(feed_scroll)
	feed_rows = VBoxContainer.new()
	feed_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_scroll.add_child(feed_rows)
	event_panel.show()
	title_panel = panel_at(Vector2(0.5, 0), Rect2(-220, 118 if Adapter.is_verdant() else 98, 440, 66))
	title_label = label_for(title_panel, 17)
	title_label.text = "ROOMSCALE\nAutonomous Colony · Fishbowl Mode"
	controls_panel = panel_at(Vector2(0, 1), Rect2(20, -78, 1040, 60))
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
	var director_label := Label.new()
	director_label.text = "Spectator Director"
	controls.add_child(director_label)
	camera_button = OptionButton.new()
	for mode_label in ["OFF / FREE", "FOLLOW", "PRIORITY", "RANDOM"]: camera_button.add_item(mode_label)
	camera_button.item_selected.connect(func(index: int) -> void:
		if index == 1:
			if not follow_targets.is_empty(): simulation.camera_director.follow(follow_targets[maxi(0, follow_button.selected)])
		else: simulation.camera_director.set_mode(index)
		wake(); refresh())
	controls.add_child(camera_button)
	follow_button = OptionButton.new()
	follow_button.custom_minimum_size.x = 180
	follow_button.item_selected.connect(func(index: int) -> void:
		if index < follow_targets.size(): simulation.camera_director.follow(follow_targets[index])
		wake(); refresh())
	controls.add_child(follow_button)
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
	refresh_role_labels()
	wake()
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		set_diagnostics(not diagnostics)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void: advance(delta)

func advance(real_delta: float) -> void:
	presenter.ingest(simulation.camera_director.events())
	presenter.advance(real_delta)
	camera_button.select(simulation.camera_director.mode)
	idle += real_delta
	title_age += real_delta
	refresh_age += real_delta
	refresh_feed()
	advance_highlight(real_delta)
	refresh_role_labels()
	event_panel.visible = not diagnostics
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
	status_label.text = "Day %.2f   ·   Population %d   ·   Shelter %d   ·   Food %.1fd   ·   Water %.1fd   ·   Wood %.0f   ·   Metal %.0f   ·   %s" % [s.days, s.population, s.shelter, s.food_days, s.water_days, s.wood, s.metal, "Paused" if s.speed == 0 else "%d×" % int(s.speed)]
	if Adapter.is_verdant():
		status_label.text = "Day %.2f   ·   Population %d   ·   Shelter %d   ·   Food %.1fd   ·   Water %.1fd   ·   %s\n%s %.0f   ·   %s %.0f   ·   %s %.0f" % [s.days, s.population, s.shelter, s.food_days, s.water_days, "Paused" if s.speed == 0 else "%d×" % int(s.speed), Adapter.resource_name("wood"), s.wood, Adapter.resource_name("metal"), s.metal, Adapter.resource_name("mechanical_parts"), s.mechanical_parts]
	governor_label.text = s.governor
	var p := Adapter.project(simulation)
	project_panel.visible = not p.is_empty() and not diagnostics
	if not p.is_empty(): project_label.text = "%s\n%s · %.0f%%" % [p.name, p.stage, p.progress * 100]
	if not p.is_empty() and not p.required.is_empty():
		var materials: Array[String] = []
		for resource in ["wood", "metal", "mechanical_parts"]:
			if p.required.has(resource):
				materials.append("%s %d/%d" % [Adapter.resource_name(resource), p.delivered.get(resource, 0), p.required[resource]])
		project_label.text = "%s\n%s · %.0f%%\n%s" % [p.name, p.stage, p.progress * 100, "\n".join(materials)]
	for multiplier in speed_buttons: speed_buttons[multiplier].modulate = Color("f3cf86") if simulation.speed == multiplier else Color.WHITE
	camera_button.select(simulation.camera_director.mode)
	refresh_follow_choices()
	if diagnostics:
		simulation.hud.refresh()
		var hud: Control = simulation.hud
		details_label.text = "COLONY DETAILS\n" + hud.resources.text + "\n\n" + hud.strategy.text + "\n\nPlanner: " + " / ".join(simulation.planner.reasons) + "\n" + hud.get_node("Directives").text + "\n\n" + hud.fishbowl_development.text + "\n\n" + hud.inspection.text + "\n\n" + (hud.citizen_label.text if hud.citizen_panel.visible else "Click a citizen for needs and task details.") + "\n\nAccounting: " + str(simulation.economy.snapshot()) + "\n\n"
		for event in simulation.journal.events: details_label.text += "Day %.2f · %s\n" % [event.day, event.message]
		details_label.text = Adapter.presentation_text(details_label.text)


func refresh_feed() -> void:
	var cards: Array = presenter.recent
	var signature := ""
	for card in cards:
		signature += String(card.get("source_key", card.get("key", str(card.id)))) + ";"
	# Focus can expire without a new event, so refresh disabled state each tick.
	if signature == feed_signature:
		for row in feed_rows.get_children():
			if row.has_meta("event"):
				row.disabled = not bool(simulation.camera_director.resolve_event(row.get_meta("event")).get("valid", false))
		return
	feed_signature = signature
	var feed_height := clampf(40.0 + cards.size() * 62.0, 110.0, 530.0)
	event_panel.offset_top = -100.0 - feed_height
	(event_panel.get_child(0) as ScrollContainer).custom_minimum_size.y = feed_height - 20.0
	for row in feed_rows.get_children():
		feed_rows.remove_child(row)
		row.queue_free()
	var heading := Label.new()
	heading.text = "RECENT STORIES"
	heading.add_theme_font_size_override("font_size", 16)
	feed_rows.add_child(heading)
	if cards.is_empty():
		var empty := Label.new()
		empty.text = "Watching the colony…"
		feed_rows.add_child(empty)
	for card in cards:
		var row := Button.new()
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size = Vector2(330, 62)
		row.add_theme_font_size_override("font_size", 13)
		var event: Dictionary = card.get("event", {})
		var priority := String(card.get("priority_name", ["LOW", "MEDIUM", "HIGH", "CRITICAL"][clampi(int(card.priority) - 1, 0, 3)]))
		var society := String(card.get("society_name", card.get("society_id", event.get("society_id", ""))))
		row.text = "%s · Day %.2f%s\n%s\n%s" % [priority, float(card.day), (" · " + society) if not society.is_empty() else "", card.headline, card.subtitle]
		row.add_theme_color_override("font_color", {"CRITICAL": Color("ffab9a"), "HIGH": Color("f3cf86"), "MEDIUM": Color("b9dcdd"), "LOW": Color("ced0cb")}.get(priority, Color.WHITE))
		row.set_meta("event", event)
		row.disabled = not bool(simulation.camera_director.resolve_event(event).get("valid", false))
		row.pressed.connect(func() -> void: focus_event(event))
		feed_rows.add_child(row)


func refresh_follow_choices() -> void:
	var choices: Array = simulation.camera_director.follow_choices()
	if choices == follow_targets and follow_button.item_count > 0: return
	var selected_id := ""
	if follow_button.selected >= 0 and follow_button.selected < follow_targets.size(): selected_id = str(follow_targets[follow_button.selected])
	follow_button.clear()
	follow_targets = choices
	for choice in choices:
		follow_button.add_item(String(choice.get("display_name", "%s %s" % [choice.type, choice.id])))
		if str(choice) == selected_id: follow_button.select(follow_button.item_count - 1)
	follow_button.disabled = choices.is_empty()
	camera_button.set_item_disabled(1, choices.is_empty())
	if choices.is_empty(): follow_button.add_item("No live subjects")


func focus_event(event: Dictionary) -> void:
	var resolved: Dictionary = simulation.camera_director.focus_event(event)
	if not bool(resolved.get("valid", false)): return
	show_highlight(resolved)
	wake()
	refresh()


func show_highlight(resolved: Dictionary) -> void:
	if is_instance_valid(highlight): highlight.queue_free()
	highlight = Node3D.new()
	highlight.name = "SpectatorSelectionHighlight"
	simulation.scene.add_child(highlight)
	highlight.global_position = resolved.focus
	highlight_target = resolved.get("target", {}).duplicate(true)
	highlight_age = 0.0
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45 if resolved.get("framing", "") == "CITIZEN_CLOSE" else 1.2
	torus.outer_radius = 0.65 if resolved.get("framing", "") == "CITIZEN_CLOSE" else 1.6
	ring.mesh = torus
	ring.position.y = 0.2
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffdf65")
	material.emission_enabled = true
	material.emission = Color("ffcf38")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	ring.material_override = material
	highlight.add_child(ring)



func advance_highlight(delta: float) -> void:
	if not is_instance_valid(highlight): return
	highlight_age += maxf(0.0, delta)
	if highlight_age >= highlight_duration:
		highlight.queue_free()
		highlight = null
		highlight_target.clear()
		return
	if not highlight_target.is_empty():
		var resolved: Dictionary = simulation.camera_director.resolve_target(highlight_target)
		if bool(resolved.get("valid", false)): highlight.global_position = resolved.focus
	var pulse := 1.0 + sin(highlight_age * 5.0) * 0.12
	highlight.scale = Vector3.ONE * pulse

func refresh_role_labels() -> void:
	# Role names are inspection detail; health and faction markers stay visible.
	var selected: Node = simulation.scene.get("_selected_citizen")
	var director: Node = simulation.camera_director
	var subject_id := -1
	if director.mode == director.FOLLOW and director.followed.get("type", "") == "citizen": subject_id = int(director.followed.id)
	elif director.enabled:
		subject_id = int(director.current_shot.get("citizen", -1))
		var target: Dictionary = director.current_shot.get("target", {})
		if target.get("type", "") == "citizen": subject_id = int(target.id)
	for runtime in preload("res://scripts/spectator_sources.gd").runtimes(simulation):
		for citizen in runtime.citizens:
			var role: Node3D = citizen.get_node_or_null("CombatIndicators/CombatRole")
			if role != null: role.visible = diagnostics or citizen == selected or citizen.citizen_id == subject_id
