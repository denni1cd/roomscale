extends SceneTree
## Vampire executable seam: selections and manual ownership without simulation mutation.
const Director = preload("res://scripts/fishbowl_camera_director.gd")
const Catalog = preload("res://scripts/spectator_event_catalog.gd")
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
 if not value: failures.append(label)
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
 priority_contract()
 cooldown_contract()
 assert(random_sequence(55) == random_sequence(55), "Isolated seed reproduces sequence")
 if not failures.is_empty():
  push_error("POC55_DIRECTOR_FAIL " + JSON.stringify(failures))
  quit(1)
  return
 print("POC55_DIRECTOR PASS ", sequence)
 d.free()
 rig.free()
 call_deferred("live")
func candidate(key: String, priority: int, category: String, society: String) -> Dictionary:
 var policy: Dictionary = Catalog.metadata({"kind":"COMBAT_CASUALTY"})
 return {"key":key,"focus":Vector3.ZERO,"distance":20.0,"priority":priority,"class":category,"society_id":society,"event":0,"headline":key,"subtitle":"fixture","seconds":1.0,"story_key":key,"subject_key":key,"story_cooldown":policy.story_cooldown,"subject_cooldown":policy.subject_cooldown,"location_cooldown":policy.location_cooldown}
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
 var published_events: Array[Dictionary] = director.events()
 var policy_candidates := 0
 for shot in director.collect_candidates():
  if String(shot.get("class", "")) != "event": continue
  var event: Dictionary = published_events.filter(func(item: Dictionary) -> bool: return int(item.id) == int(shot.event)).front() if published_events.any(func(item: Dictionary) -> bool: return int(item.id) == int(shot.event)) else {}
  if event.is_empty(): continue
  var policy: Dictionary = Catalog.metadata(event)
  check(shot.has("story_cooldown") and shot.has("subject_cooldown") and shot.has("location_cooldown") and shot.story_cooldown == policy.story_cooldown and shot.subject_cooldown == policy.subject_cooldown and shot.location_cooldown == policy.location_cooldown, "live event candidate resolves cooldown policy from catalog")
  policy_candidates += 1
 check(policy_candidates > 0, "live event candidates expose presentation cooldown policy")
 var choices: Array = director.follow_choices()
 assert(not choices.is_empty())
 assert(director.follow(choices[0]))
 director.advance(0.1)
 assert(director.mode == director.FOLLOW)
 scene.get_node("CameraRig").manual_camera_input.emit("pan")
 assert(director.mode == director.OFF)
 director.advance(90)
 assert(director.mode == director.OFF)
 if not failures.is_empty():
  push_error("POC55_DIRECTOR_LIVE_FAIL " + JSON.stringify(failures))
  scene.free()
  quit(1)
  return
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
func priority_contract() -> void:
 var d := FixtureDirector.new()
 var rig := Rig.new()
 root.add_child(rig)
 root.add_child(d)
 d.simulation = rig
 d.rig = rig
 var older := candidate("older",2,"event","a")
 older.seconds = 1.0
 older.focus = Vector3(30,0,0)
 var newer := candidate("newer",2,"event","b")
 newer.seconds = 2.0
 newer.focus = Vector3(60,0,0)
 d.fixture = [older,newer]
 d.set_mode(d.PRIORITY)
 var rng_before := d.rng.state
 d.advance(7.9)
 assert(d.current_shot.is_empty(), "Ordinary stories cannot cut before eight real seconds")
 d.advance(0.1)
 assert(d.current_shot.key == "newer", "Newest unseen wins equal priority")
 assert(d.rng.state == rng_before, "Priority never consumes spectator RNG")
 d.advance(8)
 assert(d.current_shot.key == "older", "Seen subject/story is cooled down")
 var critical := candidate("breaking",3,"event","c")
 critical.focus = Vector3(90,0,0)
 d.fixture.append(critical)
 d.advance(4.9)
 assert(d.current_shot.key == "older")
 d.advance(0.1)
 assert(d.current_shot.key == "breaking", "Critical may preempt only after readable dwell")
 d.free()
 rig.free()

func cooldown_contract() -> void:
 var d := FixtureDirector.new()
 var rig := Rig.new()
 root.add_child(rig)
 root.add_child(d)
 d.simulation = rig
 d.rig = rig
 d.real_seconds = 100.0
 var c := candidate("policy", 2, "event", "a")
 c.focus = Vector3(200, 0, 0)
 c.story_key = "story-policy"
 c.subject_key = "citizen:policy"
 # Deliberately distinct fixture values prove each catalog policy key controls
 # eligibility independently instead of sharing one fixed duration.
 c.story_cooldown = 30.0
 c.subject_cooldown = 11.0
 c.location_cooldown = 3.0
 var place := "place:%d:%d" % [roundi(c.focus.x / 8.0), roundi(c.focus.z / 8.0)]
 d.cooldowns["story:story-policy"] = 75.0
 check(not d._eligible(c), "Story policy blocks until its own duration elapses")
 d.cooldowns["story:story-policy"] = 69.0
 d.cooldowns["subject:citizen:policy"] = 95.0
 check(not d._eligible(c), "Subject policy has its distinct duration")
 d.cooldowns["subject:citizen:policy"] = 88.0
 d.cooldowns[place] = 98.0
 check(not d._eligible(c), "Location policy has its distinct duration")
 d.cooldowns[place] = 96.0
 d.cooldowns["shot:policy"] = 99.0
 check(d._eligible(c), "All candidate policy durations permit it after expiry")
 var catalog_policy: Dictionary = Catalog.metadata({"kind":"COMBAT_CASUALTY"})
 var from_catalog := candidate("from-catalog", 3, "event", "a")
 check(from_catalog.story_cooldown == catalog_policy.story_cooldown and from_catalog.subject_cooldown == catalog_policy.subject_cooldown and from_catalog.location_cooldown == catalog_policy.location_cooldown, "candidate fixture carries catalog policy values")
 d.free()
 rig.free()
