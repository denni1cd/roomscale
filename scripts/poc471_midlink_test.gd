extends SceneTree
## Isolated production navigation fixture. Campaign links remain earned in-game.
const Floor = preload("res://scripts/floor_navigation.gd")
const Surface = preload("res://scripts/surface_navigation.gd")

func _initialize() -> void:
	call_deferred("run")

func on_link(at: Vector3, link: Array[Vector3]) -> bool:
	for index in range(link.size()-1):
		var a := link[index]
		var d := link[index+1]-a
		var t := clampf((at-a).dot(d)/d.length_squared(),0,1)
		if at.distance_to(a+d*t) < .001: return true
	return false

func run() -> void:
	var definition = {"id":"midlink_fixture","dimensions":[80,80],"floor":{"center":[0,0,0],"height":0},"target_surface_id":"TARGET","objects":[
		{"id":"platform","position":[10,0,0],"dimensions":[10,20,10],"blocks_navigation":false,"surface":{"region_id":"TARGET","height":20,"anchor":[10,20,0]}}]}
	var nav = Floor.new()
	nav.configure(definition)
	nav._rebuild_grid()
	var surfaces = Surface.new()
	surfaces.configure(definition,nav)
	var link: Array[Vector3] = [Vector3.ZERO,Vector3(0,10,0),Vector3(10,20,0)]
	var failures: Array[String] = []
	if not surfaces.connect_regions("FLOOR","TARGET",link): failures.append("Fixture link registration failed")
	for start in [Vector3(0,5,0),Vector3(4,14,0)]:
		for destination in [Vector3(20,0,20),Vector3(14,20,2)]:
			var target_region := "FLOOR" if destination.y == 0 else "TARGET"
			# Region inference can label an active climber as floor or surface.
			for inferred_region in ["FLOOR","TARGET"]:
				var route: Dictionary = surfaces.route_between(inferred_region,target_region,start,destination)
				if not route.reachable or route.path.is_empty():
					failures.append("Midlink route unavailable")
					continue
				var at: Vector3 = start
				for next in route.path:
					for sample in range(101):
						var point: Vector3 = at.lerp(next,sample/100.0)
						if point.y > .001 and point.y < 19.999 and not on_link(point,link): failures.append("Repath leaves deployed link")
					at = next
				if at.distance_to(destination) > .001: failures.append("Route does not reach requested destination")
	surfaces.free()
	nav.free()
	print("POC471_MIDLINK_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
