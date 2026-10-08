extends Node
## One authoritative finite room and fixed production clock. Society nodes delegate here.
const Resources := preload("res://scripts/resource_system.gd")
const Salvage := preload("res://scripts/salvage_system.gd")
const STEP := 0.1
var room_definition: Dictionary = {}
var resources := Resources.new()
var salvage := Salvage.new()
var bundle_visuals: Dictionary = {}
var runtimes: Array[Node] = []
var citizens: Array = []
var seconds := 0.0
var tick := 0
var accumulator := 0.0
var next_citizen_id := 0
var scene: Node3D
var journal := preload("res://scripts/event_journal.gd").new()
var territory := preload("res://scripts/territory_system.gd").new()
var combat := preload("res://scripts/combat_system.gd").new()
var scenario: Dictionary = {}
var scouts: Dictionary = {}
var first_contact_tick := -1
var conflict_enabled := false
var objective_marker: Node3D
var status_label: Label
var camera_phase := ""
var attack_effects: Array[Dictionary] = []
const G := preload("res://scripts/visuals/visual_geometry.gd")

func configure(root: Node3D) -> void:
	scene = root
	room_definition = root.get("_room_definition")
	citizens = root.get("_citizens")
	next_citizen_id = citizens.size()
	resources.configure(room_definition)
	salvage.configure(resources.objects)

func allocate_citizen_id() -> int:
	var id := next_citizen_id
	next_citizen_id += 1
	return id

func advance(delta: float) -> void:
	accumulator += delta
	while accumulator + 0.000001 >= STEP:
		accumulator -= STEP
		step()

func step() -> void:
	tick += 1
	seconds += STEP
	for runtime in runtimes:
		runtime.seconds = seconds
		runtime.step_society()
	if conflict_enabled:
		advance_conflict()
		combat.update()

func runtime_for(id: String) -> Node:
	for runtime in runtimes:
		if runtime.instance_id == id: return runtime
	return null

func enable_conflict(config: Dictionary) -> void:
	scenario = config
	conflict_enabled = true
	territory.configure(room_definition, journal)
	objective_marker = Node3D.new()
	objective_marker.name = "StrategicObjective"
	scene.add_child(objective_marker)
	objective_marker.position = territory.sites[scenario.strategic_site].position + Vector3(-1.2,0,0)
	G.box(objective_marker, "ControlMarker", Vector3(0.4, 0.6, 0.4), Vector3(0,0.3,0), "brass", Color("a8a395"), 0.08)
	var label := Label3D.new()
	label.text = "FRONTIER SUPPLY APPROACH"
	label.position.y = 2.5
	label.font_size = 32
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var industrial := G.gear(objective_marker,"IndustrialControl",0.65,Vector3(0,0.7,0),8)
	industrial.hide()
	var organic := Node3D.new()
	organic.name = "OrganicControl"
	objective_marker.add_child(organic)
	G.cylinder(organic,"Stem",0.055,0.7,Vector3(0,0.35,0),"wood",Color("557a3e"))
	for side in [-1.0,1.0]:
		var leaf := G.box(organic,"ControlLeaf",Vector3(0.45,0.06,0.2),Vector3(side*0.2,0.5,0),"wood",Color("6c9349"),0.06)
		leaf.rotation.z = side*0.4
	organic.hide()
	label.name = "ObjectiveLabel"
	objective_marker.add_child(label)
	status_label = Label.new()
	status_label.position = Vector2(20,20)
	status_label.add_theme_font_size_override("font_size",20)
	status_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	status_label.add_theme_constant_override("shadow_offset_x",2)
	status_label.add_theme_constant_override("shadow_offset_y",2)
	scene.get_node("Overlay").add_child(status_label)
	for index in range(4):
		var button := Button.new()
		button.text = ["Pause","1x","4x","10x"][index]
		button.position = Vector2(20 + index * 72,92)
		var rate: float = [0.0,1.0,4.0,10.0][index]
		button.pressed.connect(func() -> void: runtimes[0].speed = rate)
		scene.get_node("Overlay").add_child(button)
	for child in scene.get_node("Overlay").get_children():
		if child != status_label and not child is Button: child.hide()

func advance_conflict() -> void:
	if seconds < float(scenario.pre_contact_seconds): return
	var site_id := String(scenario.strategic_site)
	var at: Vector3 = territory.sites[site_id].position
	if scouts.size() < runtimes.size():
		for runtime in runtimes:
			if scouts.has(runtime.instance_id) or runtime.haul_deliveries == 0: continue
			for citizen in runtime.citizens:
				if not citizen.eligible_for_combat(at): continue
				var task: Dictionary = runtime.coordinator.create_construction_task({"task_type":"STRATEGIC_SCOUT","source":at,"target":at},citizen.citizen_id)
				citizen.assign_player_goal_task(task)
				scouts[runtime.instance_id] = citizen
				journal.record(seconds,"SITE_TARGETED",runtime.instance_id + " explores the shared approach",{"instance_id":runtime.instance_id},at,runtime.instance_id + ":target")
				break
	for id in scouts:
		var scout: Node3D = scouts[id]
		if scout.task_type == "STRATEGIC_SCOUT" and scout.state == "WORK" and scout.global_position.distance_to(at) < 1.6:
			territory.claim(site_id,id,seconds)
	if territory.sites[site_id].claim_state == "CONTESTED" and combat.phase == "DORMANT":
		if first_contact_tick < 0: first_contact_tick = tick
		if combat.start(self,site_id):
			for id in scouts:
				var scout: Node3D = scouts[id]
				if scout.combat_duty.is_empty():
					scout.coordinator.cancel_task(scout.task_id,"contact exploration complete")
					scout.cancel_task_and_resume(scout.task_id)

func present_home(runtime: Node, at: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = runtime.instance_id + "_Home"
	marker.position = at
	scene.add_child(marker)
	var color := Color(String(runtime.definition.palette.primary))
	G.box(marker,"SupplyCache",Vector3(1.8,0.45,1.0),Vector3(0,0.225,0),"wood",color,0.08)
	var label := Label3D.new()
	label.text = String(runtime.definition.display_name).to_upper() + " HOME / RALLY"
	label.font_size = 32
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0,3,0)
	marker.add_child(label)

func present_attack(attacker: Node3D, victim: Node3D) -> void:
	var root := Node3D.new()
	scene.add_child(root)
	var direction: Vector3 = victim.global_position - attacker.global_position
	attacker.rotation.y = atan2(direction.x,direction.z)
	var start: Vector3 = attacker.global_position + Vector3(0,0.3,0)
	var finish: Vector3 = victim.global_position + Vector3(0,0.3,0)
	var organic: bool = runtime_for(attacker.civilization_id).definition.citizen_style == "verdant_folk"
	if organic:
		for index in range(4):
			var seed := G.box(root,"SeedPollen%d" % index,Vector3(0.055,0.035,0.11),start.lerp(finish,(index+1)/5.0),"wood",Color("b0ce75"),0.015)
			seed.look_at(finish)
	else:
		var bolt := G.box(root,"BoltSpark",Vector3(0.025,0.025,start.distance_to(finish)),(start+finish)/2,"brass",Color("ffcf69"),0.01)
		bolt.look_at(finish)
	attack_effects.append({"node":root,"remaining":0.25})

func _process(delta: float) -> void:
	# Renderer timing affects only cosmetic flashes and state labels.
	for effect in attack_effects.duplicate():
		effect.remaining -= delta
		if effect.remaining <= 0:
			effect.node.queue_free()
			attack_effects.erase(effect)
	if not conflict_enabled: return
	if OS.get_environment("ROOMSCALE_MANUAL_CAMERA") != "1" and camera_phase != combat.phase:
		camera_phase = combat.phase
		var camera: Node = scene.get_node("CameraRig")
		var objective: Vector3 = territory.sites[scenario.strategic_site].position
		if combat.phase == "DORMANT": camera.set_view_mode(0)
		elif combat.phase == "MARCH": camera.focus_at(objective,75)
		elif combat.phase == "FIGHT": camera.focus_detail_at(objective + Vector3(0,0.3,0),8)
		elif combat.phase == "RETREAT": camera.focus_at((objective + runtime_for(combat.retreating_side).coordinator.housing_station)/2,80)
		elif combat.phase == "COMPLETE": camera.set_view_mode(0)
	var presenter: Node = get_tree().root.get_node("CivilizationPresentation")
	var growth_presenter: Node = get_tree().root.get_node("VerdantDevelopmentPresentation")
	for runtime in runtimes:
		if runtime.definition.citizen_style != "verdant_folk": continue
		for citizen in runtime.citizens:
			presenter._style_verdant_citizen(citizen)
			presenter._refresh_verdant_cargo(citizen)
		for module in runtime.development.visuals.values(): growth_presenter._style_module(module)
	var site: Dictionary = territory.sites[scenario.strategic_site]
	var control_color := Color("a8a395")
	if not String(site.owner_civilization_id).is_empty(): control_color = Color(String(runtime_for(site.owner_civilization_id).definition.palette.primary))
	elif site.claim_state == "CONTESTED": control_color = Color("d5814d")
	var controlled: bool = site.claim_state == "CONTROLLED"
	var owner_organic: bool = controlled and runtime_for(site.owner_civilization_id).definition.citizen_style == "verdant_folk"
	objective_marker.get_node("IndustrialControl").visible = controlled and not owner_organic
	objective_marker.get_node("OrganicControl").visible = owner_organic
	objective_marker.get_node("ObjectiveLabel").visible = scene.get_node("CameraRig").distance >= 40
	objective_marker.get_node("ControlMarker").material_override.albedo_color = control_color
	status_label.text = "CLOCKWORK %d  /  VERDANT %d     %s · %s\n%s" % [runtimes[0].living_population(),runtimes[1].living_population(),site.claim_state,combat.phase,"Shared finite world · autonomous societies" if combat.winner.is_empty() else (combat.winner + " controls the frontier; " + combat.retreating_side + " survives" if site.claim_state == "CONTROLLED" else combat.retreating_side + " retreats to home; securing site")]
