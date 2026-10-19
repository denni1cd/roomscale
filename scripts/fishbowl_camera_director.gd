extends Node
## Read-only presentation selection. StrategyCamera alone owns physical movement.
const Adapter := preload("res://scripts/fishbowl_narrative_adapter.gd")
const Sources := preload("res://scripts/spectator_sources.gd")
const Target := preload("res://scripts/spectator_target.gd")
const Catalog := preload("res://scripts/spectator_event_catalog.gd")
enum {OFF, FOLLOW, PRIORITY, RANDOM}
const MIN_SHOT := 8.0
const CRITICAL_DWELL := 5.0
const WIDE_INTERVAL := 40.0
const HISTORY_LIMIT := 128
var mode := PRIORITY
var enabled: bool:
 get: return mode != OFF
 set(value): set_mode(PRIORITY if value else OFF)
var simulation: Node
var rig: Node
var elapsed := 0.0
var wide_elapsed := 0.0
var real_seconds := 0.0
var event_id := 0
var shots := 0
var last_focus := Vector3.ZERO
var current_shot: Dictionary = {}
var followed: Dictionary = {}
var cooldowns: Dictionary = {}
var seen: Dictionary = {}
var society_visits: Dictionary = {}
var rng := RandomNumberGenerator.new()

func configure(sim: Node) -> void:
 simulation = sim
 rig = sim.scene.get_node("CameraRig")
 if not rig.manual_camera_input.is_connected(manual_override): rig.manual_camera_input.connect(manual_override)
 rng.seed = 5505
 set_mode(OFF if OS.get_environment("ROOMSCALE_MANUAL_CAMERA") == "1" else PRIORITY)

func set_spectator_seed(value: int) -> void: rng.seed = value
func mode_name() -> String: return ["OFF", "FOLLOW", "PRIORITY", "RANDOM"][mode]
func set_mode(value: Variant) -> void:
 var next: int = int(value) if value is int else ["OFF", "FOLLOW", "PRIORITY", "RANDOM"].find(String(value).to_upper())
 if next < OFF or next > RANDOM: next = OFF
 if next == FOLLOW and followed.is_empty(): next = OFF
 mode = next
 elapsed = 0.0
 if mode == OFF and is_instance_valid(rig): rig.clear_spectator_frame()
func manual_override(_action: String = "manual") -> void: set_mode(OFF)
func _process(delta: float) -> void: advance(delta)
func events() -> Array[Dictionary]: return Sources.events(simulation)
func valid_focus(focus: Vector3) -> bool:
 return focus.is_finite() and simulation.coordinator.navigation.room_bounds().has_point(Vector2(focus.x, focus.z))
func _world() -> Node: return simulation.get("world_simulation")
func _descriptor(type: String, id: Variant, runtime: Node, framing := "SITE_MEDIUM", label := "") -> Dictionary:
 return Target.make(type, id, String(runtime.instance_id), framing, label)
func _resolved(target: Dictionary, focus: Vector3) -> Dictionary:
 if not valid_focus(focus): return {}
 return {"valid":true,"target":target.duplicate(true),"focus":focus,"framing":target.get("framing","SITE_MEDIUM"),"distance":_distance(String(target.get("framing","SITE_MEDIUM")))}
func resolve_target(target: Dictionary) -> Dictionary:
 var type := String(target.get("type", ""))
 var id := str(target.get("id", ""))
 if type == "conflict": id = id.trim_prefix("site:")
 for runtime in Sources.runtimes(simulation):
  if not String(target.get("society_id", "")).is_empty() and String(runtime.instance_id) != String(target.society_id): continue
  if type == "citizen":
   for citizen in runtime.citizens:
    if str(citizen.citizen_id) == id and citizen.health > 0: return _resolved(target, citizen.global_position + Vector3.UP * 0.25)
  if type == "settlement": return _resolved(target, runtime.development.center() + Vector3.UP * 3)
  if type == "project":
   for project in [runtime.development.active, runtime.innovation.active, runtime.innovation.research]:
    if not project.is_empty() and str(project.get("id","")) == id:
     var position: Variant = project.get("site", project.get("target"))
     if position is Vector3: return _resolved(target, position + Vector3.UP * 2)
   if id == "traversal" and runtime.construction.project_created and not runtime.construction.traversal_deployed: return _resolved(target, runtime.construction.site_position + Vector3.UP * 3)
   for project in runtime.armory.projects.values():
    if str(project.id) == id and project.state == "BUILDING": return _resolved(target, runtime.development.center() + Vector3.UP * 2)
 var world := _world()
 if is_instance_valid(world):
  if type == "site" and world.territory.sites.has(id): return _resolved(target, world.territory.sites[id].position)
  if type == "conflict" and world.combat.site_id == id and world.combat.phase not in ["DORMANT", "COMPLETE", "ENDED", "STAND_DOWN", "STOOD_DOWN"]:
   var points: Array[Vector3] = []
   for runtime in Sources.runtimes(simulation):
    for citizen in runtime.citizens:
     if citizen.health > 0 and not citizen.combat_duty.is_empty(): points.append(citizen.global_position)
   var focus: Vector3 = world.territory.sites[id].position
   if not points.is_empty():
    focus = Vector3.ZERO
    for point in points: focus += point / points.size()
   return _resolved(target, focus)
 return {}
func resolve_event(event: Dictionary) -> Dictionary:
 var descriptors: Array[Dictionary] = []
 if not str(event.get("subject_id", "")).is_empty(): descriptors.append(Target.make(String(event.get("subject_type","citizen")), event.subject_id, String(event.get("society_id","")), "CITIZEN_CLOSE" if String(event.get("subject_type","")) == "citizen" else "SITE_MEDIUM"))
 for field in ["project_id", "site_id", "conflict_id"]:
  if not str(event.get(field, "")).is_empty(): descriptors.append(Target.make(field.trim_suffix("_id"), event[field], String(event.get("society_id","")), "CONFLICT_WIDE" if field == "conflict_id" else "SITE_MEDIUM"))
 for descriptor in descriptors:
  var found := resolve_target(descriptor)
  if not found.is_empty(): return found
 if event.get("focus_valid",false) and event.get("focus") is Vector3 and valid_focus(event.focus): return {"valid":true,"focus":event.focus,"target":{},"distance":32.0,"framing":"SITE_MEDIUM"}
 return {}
func focus_event(event: Dictionary) -> Dictionary:
 set_mode(OFF)
 var result := resolve_event(event)
 if not result.is_empty(): rig.request_spectator_frame(result.focus, result.distance)
 return result
func _follow_valid(target: Dictionary) -> bool:
 var type := String(target.get("type",""))
 if type not in ["citizen","project","site","conflict"]: return false
 if type == "site":
  var world := _world()
  if not is_instance_valid(world) or world.combat.site_id != str(target.get("id","")) or world.combat.phase in ["DORMANT","COMPLETE","STAND_DOWN"]: return false
 return not resolve_target(target).is_empty()
func follow(target: Dictionary) -> bool:
 if not _follow_valid(target): return false
 followed = target.duplicate(true)
 set_mode(FOLLOW)
 return true
func follow_target(target: Dictionary) -> bool: return follow(target)
func follow_choices() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for candidate in collect_candidates():
  if candidate.has("target") and _follow_valid(candidate.target): result.append(candidate.target)
 return result
func _distance(framing: String) -> float:
 return float({"ROOM_WIDE":250.0,"SETTLEMENT_WIDE":115.0,"CITIZEN_CLOSE":7.0,"GROUP_MEDIUM":30.0,"CONFLICT_WIDE":70.0,"CONFLICT_DETAIL":25.0}.get(framing,35.0))
func overview() -> Dictionary:
 return {"key":"overview","focus":rig._room_focus,"distance":rig._room_width * 1.15,"event":event_id,"headline":"ROOM OVERVIEW","subtitle":"Life across the room","priority":0,"class":"overview","society_id":"","story_key":"overview","subject_key":"overview"}
func _target_candidate(target: Dictionary, category: String, subtitle: String) -> Dictionary:
 var result := resolve_target(target)
 if result.is_empty(): return {}
 result.merge({"key":String(target.type)+":"+String(target.society_id)+":"+str(target.id),"event":event_id,"headline":String(target.get("display_name",category)).to_upper(),"subtitle":subtitle,"priority":0,"class":category,"society_id":target.society_id,"story_key":str(target.id),"subject_key":String(target.type)+":"+str(target.id)})
 return result
func collect_candidates() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for event in events():
  var metadata: Dictionary = Catalog.metadata(event)
  if mode != RANDOM and not metadata.get("eligible",true): continue
  var resolved := resolve_event(event)
  if resolved.is_empty(): continue
  var card := Adapter.event_card(event)
  var key := String(event.source_key)
  resolved.merge({"key":key,"event":event.id,"headline":card.get("headline",event.message),"subtitle":card.get("subtitle",""),"priority":metadata.get("priority",0),"category":metadata.get("category","colony"),"class":"event","society_id":event.get("society_id",""),"story_key":event.get("story_key",key),"subject_key":str(resolved.get("target",{})),"seconds":event.seconds})
  resolved.distance = _distance(String(metadata.get("framing","SITE_MEDIUM")))
  result.append(resolved)
 for runtime in Sources.runtimes(simulation):
  for citizen in runtime.citizens:
   if citizen.health <= 0: continue
   var target := _descriptor("citizen",citizen.citizen_id,runtime,"CITIZEN_CLOSE","Citizen %s" % citizen.citizen_id)
   var task := String(citizen.task_type)
   var category := "citizen"
   if not citizen.combat_duty.is_empty(): category = "military"
   elif task.contains("SALVAGE"): category = "salvage"
   elif task.contains("CARRY") or task.contains("HAUL") or task.contains("DELIVER"): category = "hauling"
   elif task.contains("CONSTRUCTION"): category = "construction"
   elif task.contains("RESEARCH") or task.contains("INNOVATION"): category = "research"
   elif task.contains("ARMORY"): category = "equipment"
   elif citizen.state == "WORK": category = "work"
   var shot := _target_candidate(target,category,task.replace("_"," ").capitalize())
   if not shot.is_empty():
    shot["citizen"] = citizen.citizen_id
    shot["activity_task"] = citizen.task_type
    result.append(shot)
  var projects: Array = [runtime.development.active,runtime.innovation.active,runtime.innovation.research]
  for project in runtime.armory.projects.values():
   if project.state == "BUILDING": projects.append(project)
  for project in projects:
   if project.is_empty(): continue
   var shot := _target_candidate(_descriptor("project",project.id,runtime,"SITE_MEDIUM","Active project"),"project","Construction, equipment or research in progress")
   if not shot.is_empty(): result.append(shot)
  if runtime.construction.project_created and not runtime.construction.traversal_deployed:
   var shot := _target_candidate(_descriptor("project","traversal",runtime,"SITE_MEDIUM","Traversal"),"project","Building access")
   if not shot.is_empty(): result.append(shot)
  var settlement := _target_candidate(_descriptor("settlement",runtime.instance_id,runtime,"SETTLEMENT_WIDE","Settlement"),"settlement","Working, carrying and resting")
  if not settlement.is_empty(): result.append(settlement)
 var world := _world()
 if is_instance_valid(world) and not world.combat.site_id.is_empty():
  var shot := _target_candidate(Target.make("conflict",world.combat.site_id,"","CONFLICT_WIDE","Active conflict"),"conflict","Forces and contested ground")
  if not shot.is_empty(): result.append(shot)
 result.append(overview())
 return result
func _eligible(candidate: Dictionary) -> bool:
 if not valid_focus(candidate.focus): return false
 for key in _cooldown_keys(candidate):
  if real_seconds - float(cooldowns.get(key,-1000.0)) < 20.0: return false
 return true
func _cooldown_keys(candidate: Dictionary) -> Array:
 var p: Vector3 = candidate.focus
 return ["shot:"+String(candidate.key),"story:"+str(candidate.get("story_key",candidate.key)),"subject:"+str(candidate.get("subject_key",candidate.key)),"place:%d:%d" % [roundi(p.x / 8.0),roundi(p.z / 8.0)]]
func _remember(candidate: Dictionary) -> void:
 for key in _cooldown_keys(candidate): cooldowns[key] = real_seconds
 seen[candidate.key] = real_seconds
 society_visits[str(candidate.get("society_id",""))] = real_seconds
 for history in [cooldowns,seen,society_visits]:
  while history.size() > HISTORY_LIMIT: history.erase(history.keys()[0])
func choose() -> Dictionary:
 # Sustained conflict may defer context until the next safe normal dwell.
 var world := _world()
 var sustained_conflict: bool = is_instance_valid(world) and world.combat.phase in ["MARCH","FIGHT","RETREAT","SECURE"]
 if wide_elapsed >= WIDE_INTERVAL and not sustained_conflict: return overview()
 var pool: Array[Dictionary] = []
 for candidate in collect_candidates():
  if _eligible(candidate) and (mode == RANDOM or int(candidate.priority) >= 1): pool.append(candidate)
 if pool.is_empty(): return overview()
 if mode == RANDOM:
  # First sample society, then visual class, then subject: busy event streams cannot starve quiet societies or work.
  var societies: Array = []
  for candidate in pool:
   var society := str(candidate.get("society_id",""))
   if not societies.has(society): societies.append(society)
  societies.sort_custom(func(a: String,b: String) -> bool: return float(society_visits.get(a,-1000)) < float(society_visits.get(b,-1000)))
  var society: String = societies[0]
  var classes: Array = []
  for candidate in pool:
   if str(candidate.get("society_id","")) == society and not classes.has(candidate["class"]): classes.append(candidate["class"])
  var category: String = classes[rng.randi_range(0,classes.size()-1)]
  var subset: Array[Dictionary] = []
  for candidate in pool:
   if str(candidate.get("society_id","")) == society and candidate["class"] == category: subset.append(candidate)
  return subset[rng.randi_range(0,subset.size()-1)]
 pool.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
  if int(a.priority) != int(b.priority): return int(a.priority) > int(b.priority)
  if seen.has(a.key) != seen.has(b.key): return not seen.has(a.key)
  if float(a.get("seconds",0)) != float(b.get("seconds",0)): return float(a.get("seconds",0)) > float(b.get("seconds",0))
  var a_different: bool = a.get("story_key",a.key) != current_shot.get("story_key","") and a.get("subject_key",a.key) != current_shot.get("subject_key","")
  var b_different: bool = b.get("story_key",b.key) != current_shot.get("story_key","") and b.get("subject_key",b.key) != current_shot.get("subject_key","")
  if a_different != b_different: return a_different
  if int(a.get("event",0)) != int(b.get("event",0)): return int(a.get("event",0)) < int(b.get("event",0))
  return String(a.key) < String(b.key))
 return pool[0]
func advance(delta: float) -> void:
 real_seconds += delta
 if mode == OFF or not is_instance_valid(simulation): return
 if mode == FOLLOW:
  if not _follow_valid(followed): set_mode(OFF); return
  var resolved := resolve_target(followed)
  if resolved.is_empty(): set_mode(OFF); return
  last_focus = resolved.focus
  rig.request_spectator_frame(last_focus,resolved.get("distance",35.0))
  return
 elapsed += delta
 wide_elapsed += delta
 var critical := false
 if mode == PRIORITY and elapsed >= CRITICAL_DWELL and elapsed < MIN_SHOT:
  for candidate in collect_candidates():
   if int(candidate.priority) == 3 and not seen.has(candidate.key) and _eligible(candidate): critical = true; break
 if elapsed >= MIN_SHOT or critical:
  elapsed = 0.0
  var shot := choose()
  if shot.key == "overview": wide_elapsed = 0.0
  if current_shot.get("key","") != shot.key:
   current_shot = shot
   shots += 1
   _remember(shot)
   event_id = int(shot.get("event",event_id))
 if current_shot.is_empty(): return
 var focus: Vector3 = current_shot.focus
 if current_shot.has("target") and not current_shot.target.is_empty():
  var resolved := resolve_target(current_shot.target)
  if not resolved.is_empty(): focus = resolved.focus
 if not valid_focus(focus): return
 last_focus = focus
 rig.request_spectator_frame(focus,float(current_shot.distance))
func title_is_current() -> bool:
 return not current_shot.has("target") or not resolve_target(current_shot.target).is_empty()
func shot_subtitle() -> String: return String(current_shot.get("subtitle",""))
