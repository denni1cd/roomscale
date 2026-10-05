extends SceneTree
## Isolated geometric witness for constrained downstream packing.
const Sites := preload("res://scripts/settlement_site_planner.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	OS.set_environment("ROOMSCALE_FISHBOWL", "1")
	OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
	var scene: Node3D = (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var sim: Node = scene.get_node("CivilizationSimulation")
	sim.set_process(false)
	var planner := Sites.new()
	planner.configure(sim)
	planner._prepare()
	var witness: Array[Dictionary] = []
	for point in [Vector3(-12.99,0,41.01),Vector3(12.99,0,41.01),Vector3(-12.99,0,60.99),Vector3(12.99,0,60.99)]:
		witness.append({"kind": "shelter" if witness.is_empty() else "housing", "position": point, "target": point + Vector3(10 if point.x < 0 else -10,0,0)})
	var reasons: Array = []
	for index in range(witness.size()): reasons.append(planner._cheap_reason(witness[index].position, witness.slice(0,index)))
	var proof := planner._trial(witness,7)
	print("POC472_PACKING_WITNESS " + JSON.stringify({"candidates":planner._positions.size(),"cheap":reasons,"proof":proof,"anchors":planner._anchors}))
	var selected := planner.preview("shelter")
	print("POC472_PACKING_SEARCH " + JSON.stringify({"selected":selected,"trials":planner._trials,"rejections":planner._rejections}))
	var valid: bool = selected.valid and proof.valid and reasons.all(func(reason): return reason.is_empty()) and int(selected.get("rank",0)) > 0 and planner._trials <= planner.MAX_TRIALS and int(planner._rejections.get("downstream founding arrangement",0)) > 0
	print("POC472_PACKING_" + ("PASS" if valid else "FAIL"))
	scene.queue_free()
	quit(0 if valid else 1)
