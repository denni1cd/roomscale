extends SceneTree
## Real production lifecycle coverage for stable targets; no simulation mutations.
const Director := preload("res://scripts/fishbowl_camera_director.gd")
const Target := preload("res://scripts/spectator_target.gd")
const Evidence := preload("res://scripts/verification/evidence_io.gd")
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
 if not value and not failures.has(label): failures.append(label)
func _initialize() -> void: call_deferred("run")
func observer(sim: Node) -> Node:
 var d := Director.new()
 root.add_child(d)
 d.configure(sim)
 d.set_process(false)
 d.set_mode(d.OFF)
 return d
func run() -> void:
 OS.set_environment("ROOMSCALE_ROOM","room_conflict_c")
 OS.set_environment("ROOMSCALE_CONFLICT","1")
 OS.set_environment("ROOMSCALE_CONFLICT_SCENARIO","three_party_conflict")
 OS.set_environment("ROOMSCALE_FISHBOWL","1")
 OS.set_environment("ROOMSCALE_MANUAL_CAMERA","1")
 OS.set_environment("ROOMSCALE_DISABLE_STARTUP_CAPTURE","1")
 var scene: Node = load("res://scenes/pipeline_proof.tscn").instantiate()
 root.add_child(scene)
 current_scene = scene
 var world: Node = scene.get_node("WorldSimulation")
 for runtime in world.runtimes: runtime.set_process(false)
 var sim: Node = world.runtimes[0]
 sim.camera_director.set_process(false)
 sim.spectator.set_process(false)
 var citizen_d := observer(sim)
 var project_d := observer(sim)
 var conflict_d := observer(sim)
 var site_d := observer(sim)
 var citizen_target: Dictionary = Target.make("citizen",sim.citizens[0].citizen_id,sim.instance_id,"CITIZEN_CLOSE")
 check(citizen_d.follow(citizen_target),"living citizen accepts FOLLOW")
 var choice_keys := {}
 for choice in citizen_d.follow_choices():
  check(not String(choice.get("display_name","")).is_empty(),"Follow choice label is readable")
  var key := str([choice.type,choice.id,choice.society_id])
  check(not choice_keys.has(key),"Follow choices use unique stable identity")
  choice_keys[key] = true
 var first_citizen: Vector3 = citizen_d.resolve_target(citizen_target).focus
 var project_target := {}
 var conflict_target := {}
 var project_ended := false
 var conflict_ended := false
 var site_ended := false
 var citizen_moved := false
 var conflict_moved := false
 var conflict_first := Vector3.ZERO
 var project_focus := Vector3.ZERO
 var timeline: Array = []
 for tick in 6200:
  world.step()
  if project_target.is_empty() and not sim.development.active.is_empty():
   project_target = Target.make("project",sim.development.active.id,sim.instance_id)
   check(project_d.follow(project_target),"active development accepts FOLLOW")
   project_focus = project_d.resolve_target(project_target).focus
   timeline.append({"tick":world.tick,"state":"project_follow","id":project_target.id})
  if conflict_target.is_empty() and world.combat.phase in ["MARCH","FIGHT"]:
   conflict_target = Target.make("conflict","site:"+world.combat.site_id,"","CONFLICT_WIDE")
   check(conflict_d.follow(conflict_target),"moving conflict accepts FOLLOW")
   check(site_d.follow(Target.make("site",world.combat.site_id)),"active strategic site accepts FOLLOW")
   conflict_first = conflict_d.resolve_target(conflict_target).focus
   timeline.append({"tick":world.tick,"state":"conflict_follow","id":conflict_target.id})
  for d in [citizen_d,project_d,conflict_d,site_d]: d.advance(0.01)
  if citizen_d.mode == citizen_d.FOLLOW:
   var found: Dictionary = citizen_d.resolve_target(citizen_target)
   check(citizen_d.last_focus.is_equal_approx(found.focus),"citizen follows current stable identity")
   if first_citizen.distance_to(found.focus) > 1.0: citizen_moved = true
  if not project_target.is_empty() and project_d.resolve_target(project_target).is_empty():
   check(project_d.mode == project_d.OFF,"completed project exits FOLLOW to OFF")
   if not project_ended: timeline.append({"tick":world.tick,"state":"project_ended_off"})
   project_ended = true
  if not conflict_target.is_empty():
   var resolved: Dictionary = conflict_d.resolve_target(conflict_target)
   if not resolved.is_empty():
    check(conflict_d.last_focus.is_equal_approx(resolved.focus),"conflict follows current participants")
    if resolved.focus.distance_to(conflict_first) > 1.0: conflict_moved = true
   else:
    check(conflict_d.mode == conflict_d.OFF,"ended conflict exits FOLLOW to OFF")
    check(site_d.mode == site_d.OFF,"ended active site exits FOLLOW to OFF")
    if not conflict_ended: timeline.append({"tick":world.tick,"state":"conflict_ended_off"})
    conflict_ended = true
    site_ended = true
  if tick % 100 == 0: await process_frame
 check(citizen_moved,"live citizen moves during tracking")
 check(conflict_moved,"live participant focus moves during tracking")
 check(project_ended and conflict_ended and site_ended,"all noncitizen target lifecycles exercised")
 var historical: Dictionary = project_d.resolve_event({"subject_type":"project","subject_id":project_target.get("id","missing"),"society_id":sim.instance_id,"focus":project_focus,"focus_valid":true})
 check(historical.get("valid",false) and historical.target.is_empty() and historical.focus == project_focus,"completed project retains historical navigation")
 check(project_d.resolve_event({"subject_type":"citizen","subject_id":999999,"focus_valid":false}).is_empty(),"absent subject never fabricates focus")
 check(not project_d.valid_focus(Vector3(NAN,0,0)),"nonfinite focus rejected")
 check(not project_d.valid_focus(Vector3(999999,0,999999)),"out of room focus rejected")
 check(not project_d.follow(Target.make("settlement",sim.instance_id,sim.instance_id)),"settlement cannot masquerade as active FOLLOW target")
 var result := {"result":"PASS" if failures.is_empty() else "FAIL","failures":failures,"timeline":timeline,"citizen_moved":citizen_moved,"conflict_moved":conflict_moved,"project_ended":project_ended,"conflict_ended":conflict_ended,"site_ended":site_ended}
 Evidence.save_json(result,"res://verification/poc55/target-lifecycles.json")
 print("POC55_TARGET_LIFECYCLES_",result.result," ",failures," ",timeline)
 for d in [citizen_d,project_d,conflict_d,site_d]: d.free()
 scene.free()
 quit(0 if failures.is_empty() else 1)


