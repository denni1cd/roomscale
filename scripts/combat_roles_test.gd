extends SceneTree
const Roles := preload("res://scripts/combat_roles.gd")
const Civ := preload("res://scripts/civilization_definition.gd")
var failures: Array[String] = []
var assertions := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok: failures.append(label)

func _initialize() -> void:
	var expected := [[120,3,18,1,0.6,1],[90,1,14,1.2,7,1],[180,8,24,1.5,0.6,0.7],[80,0,45,3.5,15,0.55],[80,0,11,0.9,5,1.35]]
	var matrices := {"clockwork":["Bad","Good","Neutral","Great","Neutral"],"verdant":["Neutral","Good","Bad","Neutral","Great"],"scavenger":["Good","Bad","Great","Neutral","Neutral"]}
	for index in Roles.ORDER.size():
		var role: String = Roles.ORDER[index]
		var stats: Dictionary = Roles.BASE[role]
		check(Roles.validate_stats(stats).is_empty(), role + " valid")
		for axis in range(6): check(is_equal_approx(stats[["health","armor","damage","interval","range","movement"][axis]],expected[index][axis]), role + " baseline")
		var bad := stats.duplicate(); bad.interval = 0
		check(not Roles.validate_stats(bad).is_empty(), "invalid cycle rejected")
		bad.health = NAN
		check(not Roles.validate_stats(bad).is_empty(), "nonfinite rejected")
	for id in matrices:
		var loaded := Civ.load_id(id)
		check(loaded.ok, id + " loads")
		if not loaded.ok: continue
		var definition: Dictionary = loaded.definition
		for index in Roles.ORDER.size():
			var role: String = Roles.ORDER[index]
			check(definition.combat.roles[role].grade == matrices[id][index], id + role + " grade")
			var previous := 0.0
			for grade in ["Bad","Neutral","Good","Great"]:
				var fixture := definition.duplicate(true); fixture.combat.roles[role].grade = grade
				var stats := Roles.loadout(fixture,role)
				var effect := float(stats[Roles.QUALITY_STAT[stats.behavior]])
				check(effect > previous,role + " strictly ordered grade performance axis")
				previous = effect
		var bad := definition.duplicate(true); bad.combat.roles.line.grade = "Great"
		check(not Civ.validate(bad).is_empty(),"invalid distribution rejected")
		bad = definition.duplicate(true); bad.combat.roles.erase("heavy")
		check(not Civ.validate(bad).is_empty(),"missing role rejected")
		bad = definition.duplicate(true); bad.combat.roles.line.implementation = 42
		check(not Civ.validate(bad).is_empty(),"malformed implementation rejected")
	check(Roles.damage(14,8) == 6,"armor subtracts")
	check(Roles.damage(2,8) == 1,"minimum one")
	check(Roles.damage(45,8) == 37,"artillery shared formula")
	check(ceili(180/Roles.damage(14,8)) > ceili(180/Roles.damage(14,0)),"heavy armor extends survival")
	print("ROOMSCALE_ROLES_" + ("PASS" if failures.is_empty() else "FAIL") + " assertions=%d " % assertions + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
