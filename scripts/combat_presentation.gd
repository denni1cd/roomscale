extends RefCounted
## Cosmetic geometry only. Damage, range, initiative and morale remain in CombatSystem.
const G := preload("res://scripts/visuals/visual_geometry.gd")

static func glow(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	return material

static func orb(parent: Node3D, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 12
	mesh.rings = 6
	item.mesh = mesh
	item.material_override = glow(color)
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	item.position = at
	return item

static func weapon(parent: Node3D, organic: bool, role: String = "ranged") -> Node3D:
	var root := Node3D.new()
	root.name = "RangedWeapon"
	parent.add_child(root)
	root.position = Vector3(0.08,0.24,0.10)
	if role in ["line","heavy"]:
		G.box(root,"Shield",Vector3(0.24,0.30,0.05) if role == "heavy" else Vector3(0.16,0.20,0.035),Vector3(-0.16,0.02,0.12),"wood" if organic else "iron",Color("64853c") if organic else Color("657783"),0.01)
		G.box(root,"Spear",Vector3(0.025,0.025,0.60),Vector3(0.10,0,0.20),"wood",Color("b4a476"),0.005)
		if role == "heavy": G.box(root,"Armor",Vector3(0.25,0.25,0.16),Vector3(-0.08,-0.08,-0.05),"wood" if organic else "iron",Color("597141") if organic else Color("566571"),0.02)
		return root
	if role == "artillery": root.scale = Vector3(1.7,1.5,2.2)
	elif role == "skirmisher": root.scale = Vector3.ONE * 0.7
	if organic:
		G.box(root,"LivingStock",Vector3(0.055,0.06,0.28),Vector3(0,0,0.05),"wood",Color("57482d"),0.015)
		for side in [-1.0,1.0]:
			var limb := G.box(root,"ThornBowLimb",Vector3(0.18,0.035,0.06),Vector3(side*0.11,0,0.16),"wood",Color("658b36"),0.015)
			limb.rotation.y = side * 0.45
			var leaf := G.box(root,"BowLeaf",Vector3(0.12,0.012,0.08),Vector3(side*0.09,0.035,0.11),"wood",Color("95be52"),0.015)
			leaf.rotation.y = side * 0.65
		G.box(root,"VineString",Vector3(0.34,0.012,0.012),Vector3(0,0,0.10),"rope",Color("d6dca3"),0.002)
		orb(root,Vector3(0,0.015,0.18),0.035,Color("d3ed72"))
	else:
		G.box(root,"WalnutStock",Vector3(0.065,0.075,0.26),Vector3(0,0,-0.01),"wood",Color("61402d"),0.012)
		G.box(root,"BrassReceiver",Vector3(0.10,0.09,0.15),Vector3(0,0.035,0.07),"brass",Color("cf9b42"),0.014)
		var barrel := G.cylinder(root,"SteelBarrel",0.028,0.22,Vector3(0,0.035,0.23),"iron",Color("34434c"))
		barrel.rotation.x = PI/2
		var cuff := G.cylinder(root,"MuzzleCuff",0.038,0.045,Vector3(0,0.035,0.32),"brass",Color("f0bd61"))
		cuff.rotation.x = PI/2
		G.gear(root,"WindingGear",0.048,Vector3(0.06,0.025,0.06),8).rotation.z = PI/2
		G.box(root,"Sight",Vector3(0.02,0.035,0.025),Vector3(0,0.095,0.19),"iron",Color("34434c"),0.003)
	return root

static func indicators(citizen: Node3D, organic: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "CombatIndicators"
	citizen.add_child(root)
	var ring := MeshInstance3D.new()
	ring.name = "FactionRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.20
	torus.outer_radius = 0.24
	ring.mesh = torus
	ring.position.y = 0.025
	ring.material_override = glow(Color("87c858") if organic else Color("efb754"))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	for name in ["HealthBackground","HealthFill"]:
		var bar := MeshInstance3D.new()
		bar.name = name
		var quad := QuadMesh.new()
		quad.size = Vector2(0.40,0.045) if name == "HealthFill" else Vector2(0.44,0.075)
		bar.mesh = quad
		var mat := glow(Color("91da6b") if name == "HealthFill" else Color("202b32"))
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		bar.material_override = mat
		bar.position = Vector3(0,0.65,0.005 if name == "HealthFill" else 0)
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(bar)
	return root

static func shot(scene: Node3D, start: Vector3, finish: Vector3, organic: bool) -> Dictionary:
	var root := Node3D.new()
	root.name = "SeedVolley" if organic else "BoltVolley"
	scene.add_child(root)
	var color := Color("c5ee76") if organic else Color("ffaf52")
	var projectile := Node3D.new()
	root.add_child(projectile)
	projectile.position = start
	if organic:
		orb(projectile,Vector3.ZERO,0.065,color)
		for side in [-1.0,1.0]:
			var leaf := G.box(projectile,"SeedWing",Vector3(0.14,0.025,0.06),Vector3(side*0.07,0,0),"wood",Color("7cad49"),0.015)
			leaf.rotation.y = side*0.55
	else:
		var bolt := G.box(projectile,"Bolt",Vector3(0.035,0.035,0.32),Vector3.ZERO,"iron",Color("b6c6cd"),0.004)
		bolt.material_override = glow(color)
	var trail := G.box(projectile,"ShortTrail",Vector3(0.035,0.035,0.55),Vector3(0,0,0.28),"paint",color,0.006)
	trail.material_override = glow(color)
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var particles: Array = []
	for index in range(8):
		particles.append(orb(root,start,0.022 if organic else 0.018,color))
	var flash := orb(root,start,0.13 if organic else 0.10,color)
	var smoke: Array = []
	if not organic:
		for index in range(3):
			var puff := orb(root,start,0.055,Color(0.62,0.69,0.72,0.35))
			puff.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			smoke.append(puff)
	var impact := Node3D.new()
	root.add_child(impact)
	impact.position = finish
	for index in range(7):
		var angle := TAU * index/7.0
		orb(impact,Vector3(cos(angle)*0.16,sin(angle)*0.13,0),0.035,color)
	impact.hide()
	return {"node":root,"projectile":projectile,"flash":flash,"impact":impact,"particles":particles,"smoke":smoke,"start":start,"finish":finish,"organic":organic,"age":0.0}

static func advance(effect: Dictionary, delta: float) -> bool:
	effect.age += delta
	var age: float = effect.age
	var progress := clampf(age/0.22,0,1)
	var start: Vector3 = effect.start
	var finish: Vector3 = effect.finish
	var projectile: Node3D = effect.projectile
	projectile.position = start.lerp(finish,progress)
	if effect.organic: projectile.position.y += sin(progress*PI)*0.25
	if start.distance_to(finish) > 0.01: projectile.look_at(projectile.global_position + finish-start)
	projectile.visible = age < 0.22
	var flash: Node3D = effect.flash
	flash.scale = Vector3.ONE * maxf(0.01,1-age/0.13)
	flash.visible = age < 0.13
	for index in range(effect.smoke.size()):
		var puff: Node3D = effect.smoke[index]
		puff.position = start + Vector3((index-1)*age*0.15,age*0.35,0)
		puff.scale = Vector3.ONE * (1+age*3)
		puff.material_override.albedo_color.a = maxf(0,0.35-age*0.7)
	for index in range(effect.particles.size()):
		var particle: Node3D = effect.particles[index]
		var t := clampf(progress-float(index)*0.035,0,1)
		particle.position = start.lerp(finish,t)
		if effect.organic: particle.position.y += sin(t*PI)*0.25
		particle.scale = Vector3.ONE * maxf(0.01,1-age/0.5)
	var impact: Node3D = effect.impact
	impact.visible = age >= 0.22
	impact.scale = Vector3.ONE * maxf(0.01,(age-0.22)*4)
	return age >= 0.5
