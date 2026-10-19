extends SceneTree
## Vampire executable seam: selections and manual ownership without simulation mutation.
const Director = preload("res://scripts/fishbowl_camera_director.gd")
class Rig extends Node:
 signal manual_camera_input(action: String)
 var frames := 0
 var _room_focus := Vector3.ZERO
 var _room_width := 100.0
 func request_spectator_frame(_focus: Vector3, _distance: float, _tilt := 55.0, _yaw := 0.0) -> void: frames += 1
 func clear_spectator_frame() -> void: pass
class FixtureDirector extends Director:
 var fixture: Array[Dictionary] = []
 func valid_focus(focus: Vector3) -> bool: return focus.is_finite() and absf(focus.x) < 1000
 func collect_candidates() -> Array[Dictionary]: return fixture.duplicate(true)
 func resolve_target(target: Dictionary) -> Dictionary:
  if target.get("invalid", false): return {}
  return target.duplicate(true)
func _initialize() -> void:
 var d := FixtureDirector.new()
 var rig := Rig.new()
 root.add_child(rig)
 root.add_child(d)
 d.rig = rig
 d.simulation = rig
 rig.manual_camera_input.connect(d.manual_override)
 d.fixture = [candidate("low", 0, "citizen", "a"), candidate("high", 2, "event", "b"), candidate("critical", 3, "event", "c")]
 d.set_mode(d.PRIORITY)
 d.advance(4.9)
 assert(d.current_shot.is_empty(), "No premature cut")
 d.advance(0.1)
 assert(d.current_shot.key == "critical", "Critical respects minimum readable dwell")
 rig.manual_camera_input.emit("orbit")
 assert(d.mode_name() == "OFF")
 var before := rig.frames
 d.advance(120)
 assert(rig.frames == before)
 d.set_mode(d.RANDOM)
 d.set_spectator_seed(55)
 var sequence: Array = []
 for i in 12:
  d.advance(8)
  sequence.append(d.current_shot.key)
 assert(sequence.has("low"), "Random must reach routine candidates")
 assert(d.cooldowns.size() <= d.HISTORY_LIMIT)
 d.follow({"type":"citizen", "id":"7", "focus":Vector3.ONE})
 d.advance(0.1)
 assert(d.mode == d.FOLLOW)
 d.followed["invalid"] = true
 d.advance(0.1)
 assert(d.mode == d.OFF)
 assert(random_sequence(55) == random_sequence(55), "Isolated seed reproduces sequence")
 print("POC55_DIRECTOR PASS ", sequence)
 d.free()
 rig.free()
 call_deferred("live")
func candidate(key: String, priority: int, category: String, society: String) -> Dictionary:
 return {"key":key,"focus":Vector3.ZERO,"distance":20.0,"priority":priority,"class":category,"society_id":society,"event":0,"headline":key,"subtitle":"fixture","seconds":1.0,"story_key":key,"subject_key":key}
func live() -> void:
 OS.set_environment("ROOMSCALE_ROOM", "room_poc45")
 OS.set_environment("ROOMSCALE_FISHBOWL", "1")
 OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE", "1")
 var scene := (load("res://scenes/pipeline_proof.tscn") as PackedScene).instantiate()
 root.add_child(scene)
 current_scene = scene
 var sim: Node = scene.get_node("CivilizationSimulation")
 sim.set_process(false)
 var director: Node = sim.camera_director
 director.set_process(false)
 director.set_mode(director.RANDOM)
 director.set_spectator_seed(55)
 var live_trace: Array = []
 for i in 24:
  for tick in 20: sim.step()
  director.advance(8)
  live_trace.append(director.current_shot.key)
  assert(director.valid_focus(director.last_focus))
 var choices: Array = director.follow_choices()
 assert(not choices.is_empty())
 assert(director.follow(choices[0]))
 director.advance(0.1)
 assert(director.mode == director.FOLLOW)
 scene.get_node("CameraRig").manual_camera_input.emit("pan")
 assert(director.mode == director.OFF)
 director.advance(90)
 assert(director.mode == director.OFF)
 print("POC55_DIRECTOR_LIVE PASS ", live_trace)
 scene.free()
 quit()
func random_sequence(seed_value: int) -> Array:
 var d := FixtureDirector.new()
 var rig := Rig.new()
 root.add_child(rig)
 root.add_child(d)
 d.simulation = rig
 d.rig = rig
 for i in 8:
  var c := candidate("candidate%d" % i, i % 4, "citizen" if i % 2 == 0 else "project", "society%d" % (i % 3))
  c.focus = Vector3(i * 20,0,0)
  d.fixture.append(c)
 d.set_spectator_seed(seed_value)
 d.set_mode(d.RANDOM)
 var result: Array = []
 for i in 24:
  d.advance(8)
  result.append(d.current_shot.key)
 d.free()
 rig.free()
 return result
