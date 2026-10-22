extends SceneTree
## Launch the actual single, two-society, and three-society production compositions.

const MenuScene := preload("res://scenes/setup_menu.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_WP6_RUNTIME_CHECK_PASS " + label)
	else:
		failures.append(label)
		print("POC56_WP6_RUNTIME_CHECK_FAIL " + label)

func run() -> void:
	root.size = Vector2i(1920, 1080)
	await launch_and_check(0, "room_poc47", "", ["verdant"], 0.5)
	await launch_and_check(1, "room_conflict", "clockwork_vs_verdant", ["scavenger", "clockwork"], 1.0)
	await launch_and_check(2, "room_conflict_c", "three_party_conflict", ["verdant", "scavenger", "clockwork"], 0.5)
	print("POC56_WP6_RUNTIME_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func launch_and_check(session_index: int, expected_room: String, expected_scenario: String, expected_definitions: Array[String], expected_speed: float) -> void:
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	var menu: Control = MenuScene.instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	menu.session_choice.select(session_index)
	menu._refresh_society_rows(session_index)
	for row_index in range(expected_definitions.size()):
		var choice: OptionButton = menu.society_rows[row_index].choice
		for option in range(choice.item_count):
			if String(choice.get_item_metadata(option)) == expected_definitions[row_index]: choice.select(option)
	for option in range(menu.speed_choice.item_count):
		if is_equal_approx(float(menu.speed_choice.get_item_metadata(option)), expected_speed): menu.speed_choice.select(option)
	var configured: Dictionary = menu.session_configuration()
	check(configured.ok and configured.room == expected_room and configured.scenario == expected_scenario and configured.civilizations == expected_definitions and is_equal_approx(float(configured.speed), expected_speed), "%s real menu holds the requested valid session and speed" % expected_room)
	var start_button := find_start_button(menu)
	check(start_button != null, "%s real menu exposes its Start action" % expected_room)
	if start_button == null:
		menu.queue_free()
		await process_frame
		return
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = start_button.get_global_rect().get_center()
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	for frame in range(6): await process_frame
	var scene := current_scene
	check(scene != menu and is_instance_valid(scene), "%s actual Start click transitions into a production session" % expected_room)
	var first: Node = scene.get_node_or_null("CivilizationSimulation") if is_instance_valid(scene) else null
	check(first != null, "%s production runtime starts from its menu" % expected_room)
	if first == null:
		if is_instance_valid(scene): scene.queue_free()
		await process_frame
		return
	var world: Node = first.world_simulation
	check(world.runtimes.size() == expected_definitions.size(), "%s starts exactly %d real societies" % [expected_room, expected_definitions.size()])
	var actual_by_instance: Dictionary = {}
	var expected_total := 0
	for runtime in world.runtimes:
		actual_by_instance[String(runtime.instance_id)] = String(runtime.definition.id)
		check(is_equal_approx(runtime.speed, expected_speed), "%s applies selected initial pace to %s" % [expected_room, runtime.instance_id])
		var roster_size := int(runtime.room_definition.get("start", {}).get("population", 0))
		expected_total += roster_size
		check(roster_size > 0 and runtime.citizens.size() == roster_size and runtime.living_population() == roster_size, "%s gives %s the real configured %d-citizen roster" % [expected_room, runtime.instance_id, roster_size])
	if expected_definitions.size() == 1:
		check(first.definition.id == expected_definitions[0], "single society uses the chosen real civilization definition")
	else:
		var participant_ids: Array[String] = ["clockwork_alpha", "verdant_alpha"]
		if expected_definitions.size() == 3: participant_ids.append("scavenger_alpha")
		for index in range(participant_ids.size()):
			check(actual_by_instance.get(participant_ids[index], "") == expected_definitions[index], "%s assigns the chosen definition to participant %s" % [expected_room, participant_ids[index]])
		check(world.citizens.size() == expected_total, "%s shares one real world roster across every society" % expected_room)
	scene.queue_free()
	await process_frame

func find_start_button(node: Node) -> Button:
	if node is Button and (node as Button).text == "Start settlement": return node as Button
	for child in node.get_children():
		var found := find_start_button(child)
		if found != null: return found
	return null
