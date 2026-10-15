extends SceneTree
const Catalog := preload("res://scripts/military_catalog.gd")
const Doctrine := preload("res://scripts/military_doctrine.gd")
const Civ := preload("res://scripts/civilization_definition.gd")
var failures: Array = []
func check(value: bool,label: String) -> void:
	if not value: failures.append(label)
func _initialize() -> void:
	var expected := {"clockwork":["artillery","heavy","ranged"],"verdant":["skirmisher","line","ranged"],"scavenger":["heavy","line","artillery"]}
	for id in expected:
		var loaded := Civ.load_id(id)
		check(loaded.ok,"valid signature profile")
		check(Doctrine.compose(loaded.definition.combat.roles,3) == expected[id],"exact doctrine " + id)
		var profile: Dictionary = loaded.definition.combat.roles.duplicate(true)
		profile.line.grade = "Great"; profile.heavy.grade = "Bad"; profile.artillery.grade = "Bad"; profile.skirmisher.grade = "Bad"
		check(Doctrine.compose(profile,3) != expected[id],"synthetic grades affect composition")
		check(Doctrine.compose(profile,3,{"ranged":2,"line":0}) == ["ranged","ranged"],"bounded stock fallback")
		loaded.definition.combat.capabilities = ["UNKNOWN"]
		check(not Civ.validate(loaded.definition).is_empty(),"unknown capability rejected")
	var expected_costs := [[1,1,6],[1,1,8],[1,3,12],[2,4,18],[1,1,6]]
	for index in Catalog.Roles.ORDER.size():
		var role: String = Catalog.Roles.ORDER[index]
		var entry: Dictionary = Catalog.EQUIPMENT[role+"_kit"]
		check(Catalog.validate_equipment(entry).is_empty(),"valid kit")
		check([entry.cost.wood,entry.cost.metal,entry.work] == [expected_costs[index][0],expected_costs[index][1],float(expected_costs[index][2])],"exact costs")
		var bad := entry.duplicate(true); bad.cost["ammo"] = 1
		check(not Catalog.validate_equipment(bad).is_empty(),"noncanonical cost rejected")
		bad = entry.duplicate(true); bad.work = NAN
		check(not Catalog.validate_equipment(bad).is_empty(),"nonfinite work rejected")
		bad = entry.duplicate(true); bad.requires = ["UNKNOWN"]
		check(not Catalog.validate_equipment(bad).is_empty(),"unknown learned gate rejected")
	check(Doctrine.WEIGHTS == {"Great":4.0,"Good":3.0,"Neutral":2.0,"Bad":1.0} and Doctrine.REPEAT_PENALTY == 1.25,"doctrine constants")
	print("ROOMSCALE_POC54_DATA_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

