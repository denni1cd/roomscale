extends SceneTree
## Focused production floor-route regression; no citizen/project state mutation.
const Floor = preload("res://scripts/floor_navigation.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var nav = Floor.new()
	nav.configure({"id":"corner_regression","dimensions":[240,180],"floor":{"center":[0,0,0],"height":0},"objects":[{"id":"completed_shelter","position":[4,0,24],"dimensions":[12,7,10],"blocks_navigation":true}]})
	nav.refresh_navigation()
	var start = Vector3(10.16,0,19.58)
	var finish = Vector3(16,0,20)
	var paths = [nav.path_between(start,finish),nav.path_between(finish,start)]
	var failures = []
	check_paths(nav,start,finish,paths,failures)
	nav.configure({"id":"narrow_aisle_regression","dimensions":[240,180],"floor":{"center":[0,0,0],"height":0},"objects":[
		{"id":"workshop","position":[-20,0,42],"dimensions":[26,10,18],"navigation_padding":[3,0,3],"blocks_navigation":true},
		{"id":"housing","position":[-25,0,66],"dimensions":[28,7,17],"navigation_padding":[3,0,3],"blocks_navigation":true}]})
	nav.refresh_navigation()
	start = Vector3(-16.84314,0,54.03841)
	finish = Vector3(18,0,55)
	var aisle_paths = [nav.path_between(start,finish),nav.path_between(finish,start)]
	check_paths(nav,start,finish,aisle_paths,failures)
	nav.free()
	print("POC471_NAVIGATION_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify({"corner_paths":paths,"aisle_paths":aisle_paths,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func check_paths(nav: Node, start: Vector3, finish: Vector3, paths: Array, failures: Array) -> void:
	for i in range(paths.size()):
		if paths[i].is_empty():
			failures.append("Legal route rejected")
			continue
		var at = start if i == 0 else finish
		for next in paths[i]:
			for sample in range(101):
				if nav.is_obstacle_position(at.lerp(next,sample/100.0)):
					failures.append("Floor path cuts completed shelter corner")
			at = next
