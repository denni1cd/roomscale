extends SceneTree
## Real citizen/coordinator navigation-failure regression on an isolated grid fixture.
const Floor = preload("res://scripts/floor_navigation.gd")
const Coordinator = preload("res://scripts/task_coordinator.gd")
const Citizen = preload("res://scripts/citizen_agent.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fixture = Node3D.new()
	root.add_child(fixture)
	var nav = Floor.new()
	nav.configure({"id":"unreachable_fixture","dimensions":[40,40],"floor":{"center":[0,0,0],"height":0},"objects":[{"id":"blocked_floor","position":[0,0,0],"dimensions":[40,1,40],"blocks_navigation":true}]})
	fixture.add_child(nav)
	var coordinator = Coordinator.new()
	coordinator.navigation = nav
	coordinator.workshop_stations.append(Vector3.ZERO)
	coordinator.patrol_stations.append(Vector3.ZERO)
	fixture.add_child(coordinator)
	coordinator._enqueue_for(0,0)
	var citizen = Citizen.new()
	fixture.add_child(citizen)
	citizen.initialize(0,Vector3.ZERO,nav,coordinator)
	citizen.set_process(false)
	var failures = []
	if citizen.state != "IDLE" or coordinator.summary().failed_total != 1 or coordinator.summary().created_total != 2: failures.append("Unreachable route recursively claims replacement tasks")
	citizen.needs = preload("res://scripts/need_system.gd").new().initial(0)
	if failures.is_empty():
		for tick in range(10): citizen.advance_simulation(0.5)
	if citizen.position != Vector3.ZERO or citizen.state != "IDLE" or coordinator.summary().created_total != 12 or coordinator.summary().failed_total != 11 or coordinator.tasks.size() > 12: failures.append("Unreachable retry is unbounded or moves citizen")
	print("POC471_UNREACHABLE_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify({"failures":failures,"tasks":coordinator.summary(),"state":citizen.state}))
	fixture.free()
	quit(0 if failures.is_empty() else 1)
