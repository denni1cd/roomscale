extends Control
## Validated front door for the supported production session compositions.

const Definitions := preload("res://scripts/civilization_definition.gd")
const SESSIONS := [
	{"label":"Founder room · 1 society", "room":"room_poc47", "count":1, "scenario":""},
	{"label":"Shared frontier · 2 societies", "room":"room_conflict", "count":2, "scenario":"clockwork_vs_verdant"},
	{"label":"Shared frontier · 3 societies", "room":"room_conflict_c", "count":3, "scenario":"three_party_conflict"},
]
const DEFAULTS := [["clockwork"], ["clockwork", "verdant"], ["clockwork", "verdant", "scavenger"]]

var session_choice: OptionButton
var speed_choice: OptionButton
var society_rows: Array[Dictionary] = []
var definitions: Array[String] = []
var error_label: Label
var initialized_session_choices: Dictionary = {}

func _ready() -> void:
	definitions = _available_definitions()
	_build_ui()

func _available_definitions() -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open("res://civilizations")
	if directory == null: return result
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if filename.ends_with(".json"):
			var id := filename.trim_suffix(".json")
			if Definitions.load_id(id).ok: result.append(id)
		filename = directory.get_next()
	directory.list_dir_end()
	result.sort()
	return result

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("111a20")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -430
	panel.offset_top = -290
	panel.offset_right = 430
	panel.offset_bottom = 290
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("1d2a2f")
	panel_style.border_color = Color("c29b5f")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 34
	panel_style.content_margin_right = 34
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 13)
	panel.add_child(layout)
	var title := _label("ROOMSCALE", 34, Color("f8dfb3"))
	layout.add_child(title)
	var subtitle := _label("Set up a supported settlement before the world begins.", 17, Color("c1d0cd"))
	layout.add_child(subtitle)
	var session_label := _label("ROOM / SCENARIO", 13, Color("e5c27e"))
	layout.add_child(session_label)
	session_choice = OptionButton.new()
	session_choice.custom_minimum_size = Vector2(760, 38)
	for session in SESSIONS: session_choice.add_item(String(session.label))
	session_choice.item_selected.connect(_refresh_society_rows)
	layout.add_child(session_choice)
	var society_heading := _label("SOCIETIES", 13, Color("e5c27e"))
	layout.add_child(society_heading)
	var defaults: Array = DEFAULTS[0]
	for index in range(3):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var row_label := _label("Society %d" % (index + 1), 16, Color("f0e7d7"))
		row_label.custom_minimum_size.x = 125
		row.add_child(row_label)
		var choice := OptionButton.new()
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.custom_minimum_size.y = 34
		for id in definitions:
			var loaded: Dictionary = Definitions.load_id(id)
			choice.add_item(String(loaded.definition.get("display_name", id.capitalize())))
			choice.set_item_metadata(choice.item_count - 1, id)
		var default_id := String(defaults[index] if index < defaults.size() else definitions[0] if not definitions.is_empty() else "")
		for option in range(choice.item_count):
			if String(choice.get_item_metadata(option)) == default_id: choice.select(option)
		row.add_child(choice)
		layout.add_child(row)
		society_rows.append({"row":row, "label":row_label, "choice":choice})
	var pace_row := HBoxContainer.new()
	pace_row.add_theme_constant_override("separation", 16)
	var pace_label := _label("Initial pace", 16, Color("f0e7d7"))
	pace_label.custom_minimum_size.x = 125
	pace_row.add_child(pace_label)
	speed_choice = OptionButton.new()
	for speed in [0.5, 1.0, 4.0, 10.0]: speed_choice.add_item("%.1fx" % speed if speed < 1.0 else "%.0fx" % speed)
	speed_choice.set_item_metadata(0, 0.5)
	speed_choice.set_item_metadata(1, 1.0)
	speed_choice.set_item_metadata(2, 4.0)
	speed_choice.set_item_metadata(3, 10.0)
	speed_choice.select(0)
	speed_choice.custom_minimum_size = Vector2(180, 36)
	pace_row.add_child(speed_choice)
	layout.add_child(pace_row)
	var note := _label("1x remains the deterministic reference. The 0.5x option runs the same simulation at half wall-clock pace.", 13, Color("aebdba"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(note)
	error_label = _label("", 14, Color("ff988b"))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(error_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(110, 40)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	actions.add_child(quit_button)
	var start_button := Button.new()
	start_button.text = "Start settlement"
	start_button.custom_minimum_size = Vector2(210, 40)
	start_button.pressed.connect(_start_session)
	actions.add_child(start_button)
	layout.add_child(actions)
	_refresh_society_rows(0)

func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _refresh_society_rows(index: int) -> void:
	var session_index := clampi(index, 0, SESSIONS.size() - 1)
	var count := int(SESSIONS[session_index].count)
	for row_index in range(society_rows.size()): society_rows[row_index].row.visible = row_index < count
	if initialized_session_choices.has(session_index): return
	var defaults: Array = DEFAULTS[session_index]
	for row_index in range(count):
		var choice: OptionButton = society_rows[row_index].choice
		var default_id := String(defaults[row_index])
		for option in range(choice.item_count):
			if String(choice.get_item_metadata(option)) == default_id:
				choice.select(option)
				break
	initialized_session_choices[session_index] = true

func session_configuration() -> Dictionary:
	var session: Dictionary = SESSIONS[session_choice.selected]
	var selected_ids: Array[String] = []
	for index in range(int(session.count)):
		var choice: OptionButton = society_rows[index].choice
		var id := String(choice.get_item_metadata(choice.selected))
		if not Definitions.load_id(id).ok:
			return {"ok":false, "error":"Society %d uses an invalid civilization definition." % (index + 1)}
		selected_ids.append(id)
	return {"ok":true, "room":String(session.room), "count":int(session.count), "scenario":String(session.scenario), "civilizations":selected_ids, "speed":float(speed_choice.get_item_metadata(speed_choice.selected))}

func _start_session() -> void:
	error_label.text = ""
	var configuration: Dictionary = session_configuration()
	if not configuration.ok:
		error_label.text = String(configuration.get("error", "Invalid session configuration."))
		return
	OS.set_environment("ROOMSCALE_ROOM", String(configuration.room))
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_CIVILIZATION", String(configuration.civilizations[0]))
	OS.set_environment("ROOMSCALE_INITIAL_SPEED", str(configuration.speed))
	OS.set_environment("ROOMSCALE_CONFLICT", "1" if int(configuration.count) > 1 else "0")
	OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO", String(configuration.scenario))
	OS.set_environment("ROOMSCALE_SESSION_CIVILIZATIONS", ",".join(configuration.civilizations) if int(configuration.count) > 1 else "")
	get_tree().change_scene_to_file("res://scenes/pipeline_proof.tscn")
