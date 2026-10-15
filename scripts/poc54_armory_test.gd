extends SceneTree
var failures: Array = []
func check(ok: bool,label: String) -> void:
	if not ok and not failures.has(label): failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	OS.set_environment("ROOMSCALE_ROOM","room_conflict_c"); OS.set_environment("ROOMSCALE_CONFLICT","1"); OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO","three_party_conflict"); OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE","1")
	var scene: Node3D = load("res://scenes/pipeline_proof.tscn").instantiate(); root.add_child(scene); current_scene = scene
	var world: Node = scene.get_node("WorldSimulation"); world.conflict_enabled = false
	for runtime in world.runtimes: runtime.set_process(false); runtime.governor.enabled = false
	var sim: Node = world.runtimes[0]
	# Controlled initial depot supplies; live acceptance separately begins at zero.
	sim.economy.receive("wood",20); sim.economy.receive("metal",20)
	var protected: int = sim.economy.reserve("metal",3,"unrelated_construction")
	sim.governor.evaluations = 1
	check(sim.armory.order("heavy"),"first equipment project")
	check(not sim.armory.order("line"),"one new order per evaluation")
	sim.governor.evaluations += 1
	check(sim.armory.order("ranged"),"second equipment project")
	sim.governor.evaluations += 1
	check(not sim.armory.order("line"),"two project limit")
	check(sim.economy.tickets.has(protected),"other reservations retained")
	var before: Dictionary = sim.armory.snapshot()
	for frame in range(4): await process_frame
	check(before == sim.armory.snapshot(),"wall time does no manufacturing")
	check(not sim.armory.work(sim.citizens[0],0.1),"forged labor rejected")
	var interrupted := false
	for tick in range(1800):
		world.step()
		if not interrupted:
			for citizen in sim.citizens:
				if citizen.task_type == "ARMORY_BUILD" and citizen.state == "WORK":
					var task: Dictionary = sim.coordinator.get_task(citizen.task_id)
					var project: Dictionary = sim.armory.projects[task.armory_project]
					var work: float = project.work
					citizen.needs.water = 0.95
					world.step()
					check(citizen.task_type != "ARMORY_BUILD" and project.work == work,"urgent care preempts equipment labor")
					interrupted = true
					break
		check(sim.economy.audit().is_empty(),"economic conservation")
		if sim.armory.kits.size() == 2: break
		if tick % 100 == 0: await process_frame
	check(interrupted,"urgent interruption exercised")
	check(sim.armory.kits.size() == 2,"real citizens complete both kits")
	for project in sim.armory.projects.values(): check(project.state == "COMPLETE" and project.workers.size() > 0 and project.work+0.00001 >= project.required_work,"real native citizen effort")
	for project in sim.armory.projects.values(): check(sim.armory._create_kit(project).is_empty(),"completion cannot create duplicate kit")
	check(sim.economy.project_consumed.wood >= 2 and sim.economy.project_consumed.metal >= 4,"real materials consumed")
	check(sim.economy.tickets.has(protected),"manufacturing never stole protected stock")
	sim.governor.emergency = true
	check(not sim.armory.order("line"),"crisis blocks new order")
	var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures,"armory":sim.armory.snapshot(),"economy":sim.economy.snapshot()}
	var path := OS.get_environment("ROOMSCALE_FOCUSED_RESULT")
	if not path.is_empty(): var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(result,"  ")); file.close()
	print("ROOMSCALE_POC54_ARMORY_"+result.result+" "+JSON.stringify(result))
	scene.queue_free(); quit(0 if failures.is_empty() else 1)
