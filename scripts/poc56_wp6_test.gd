extends SceneTree
## Session setup validates supported room/count paths and real civilization definitions.

const MenuScene := preload("res://scenes/setup_menu.tscn")
const RoomLoader := preload("res://scripts/room_definition.gd")
const FloorNavigation := preload("res://scripts/floor_navigation.gd")
const ConflictScenario := preload("res://scripts/conflict_scenario.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		print("POC56_WP6_CHECK_PASS " + label)
	else:
		failures.append(label)
		print("POC56_WP6_CHECK_FAIL " + label)

func run() -> void:
	var menu := MenuScene.instantiate()
	root.add_child(menu)
	await process_frame
	check(menu.definitions.has("clockwork") and menu.definitions.has("verdant") and menu.definitions.has("scavenger"), "menu lists only available validated civilization definitions")
	var one: Dictionary = menu.session_configuration()
	check(one.ok and one.room == "room_poc47" and one.count == 1 and one.civilizations == ["clockwork"] and is_equal_approx(one.speed, 0.5), "default session maps to the canonical one-society room and selected half pace")
	menu.session_choice.select(1)
	menu._refresh_society_rows(1)
	var two: Dictionary = menu.session_configuration()
	check(two.ok and two.room == "room_conflict" and two.count == 2 and two.scenario == "clockwork_vs_verdant" and two.civilizations == ["clockwork", "verdant"], "two-society setup maps to its distinct validated civilization defaults")
	menu.session_choice.select(2)
	menu._refresh_society_rows(2)
	var three: Dictionary = menu.session_configuration()
	check(three.ok and three.room == "room_conflict_c" and three.count == 3 and three.scenario == "three_party_conflict" and three.civilizations == ["clockwork", "verdant", "scavenger"], "three-society setup maps to its three distinct validated civilization defaults")
	var third_choice: OptionButton = menu.society_rows[2].choice
	var previous_id := String(third_choice.get_item_metadata(third_choice.selected))
	third_choice.set_item_metadata(third_choice.selected, "unknown_definition")
	check(not menu.session_configuration().ok, "invalid civilization selection is rejected before launch")
	third_choice.set_item_metadata(third_choice.selected, previous_id)
	menu.queue_free()
	await process_frame
	await test_conflict_definition_overrides()
	print("POC56_WP6_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func test_conflict_definition_overrides() -> void:
	OS.set_environment("ROOMSCALE_ROOM", "room_conflict")
	OS.set_environment("ROOMSCALE_ROOM_FILE", "")
	var room_result: Dictionary = RoomLoader.load_requested()
	check(room_result.ok, "shared conflict room definition loads for session validation")
	if not room_result.ok: return
	var nav: Node = FloorNavigation.new()
	nav.configure(room_result.definition)
	root.add_child(nav)
	await process_frame
	OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO", "clockwork_vs_verdant")
	OS.set_environment("ROOMSCALE_SESSION_CIVILIZATIONS", "scavenger,clockwork")
	var two := ConflictScenario.load_requested(room_result.definition, nav)
	check(two.ok and two.prepared[0].definition.id == "scavenger" and two.prepared[1].definition.id == "clockwork", "two-society menu choices enter the actual prepared definitions")
	OS.set_environment("ROOMSCALE_ROOM", "room_conflict_c")
	room_result = RoomLoader.load_requested()
	check(room_result.ok, "three-society room definition loads for session validation")
	nav.queue_free()
	await process_frame
	nav = FloorNavigation.new()
	nav.configure(room_result.definition)
	root.add_child(nav)
	await process_frame
	OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO", "three_party_conflict")
	OS.set_environment("ROOMSCALE_SESSION_CIVILIZATIONS", "verdant,scavenger,clockwork")
	var three := ConflictScenario.load_requested(room_result.definition, nav)
	var prepared_ids: Dictionary = {}
	if three.ok:
		for item in three.prepared: prepared_ids[String(item.participant.instance_id)] = String(item.definition.id)
	check(three.ok and prepared_ids.get("clockwork_alpha", "") == "verdant" and prepared_ids.get("verdant_alpha", "") == "scavenger" and prepared_ids.get("scavenger_alpha", "") == "clockwork", "three-society menu choices enter their real configured participant slots")
	OS.set_environment("ROOMSCALE_SESSION_CIVILIZATIONS", "clockwork,verdant")
	var mismatch := ConflictScenario.load_requested(room_result.definition, nav)
	check(not mismatch.ok and String(mismatch.errors[0]).contains("count does not match"), "participant count mismatch is rejected before runtime startup")
	nav.queue_free()
