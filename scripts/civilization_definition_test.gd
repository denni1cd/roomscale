extends SceneTree

const CivilizationDefinition := preload("res://scripts/civilization_definition.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var clockwork_result := CivilizationDefinition.load_id("clockwork")
	var verdant_result := CivilizationDefinition.load_id("verdant")
	_check(bool(clockwork_result.ok), "Clockwork definition must validate: %s" % clockwork_result.errors)
	_check(bool(verdant_result.ok), "Verdant definition must validate: %s" % verdant_result.errors)
	if bool(clockwork_result.ok) and bool(verdant_result.ok):
		var clockwork: Dictionary = clockwork_result.definition
		var verdant: Dictionary = verdant_result.definition
		_check(String(clockwork.id) == "clockwork", "Clockwork id mismatch")
		_check(String(verdant.id) == "verdant", "Verdant id mismatch")
		_check(String(clockwork.traversal_style) != String(verdant.traversal_style), "Civilizations need distinct traversal presentation")
		_check(String(clockwork.settlement_style) != String(verdant.settlement_style), "Civilizations need distinct settlement presentation")
		for resource in CivilizationDefinition.REQUIRED_RESOURCE_KEYS:
			_check(clockwork.resource_vocabulary.has(resource), "Clockwork missing shared resource slot %s" % resource)
			_check(verdant.resource_vocabulary.has(resource), "Verdant missing shared resource slot %s" % resource)
		_check(CivilizationDefinition.resource_name(verdant, "wood") == "Living Fiber", "Verdant wood vocabulary must map to Living Fiber")
		_check(CivilizationDefinition.resource_name(verdant, "metal") == "Resin", "Verdant metal vocabulary must map to Resin")
		_check(CivilizationDefinition.resource_name(verdant, "mechanical_parts") == "Growth Spores", "Verdant parts vocabulary must map to Growth Spores")
		_check(CivilizationDefinition.stage_name(verdant, "base") == "Root Bed", "Verdant base stage must present as Root Bed")
		_check(CivilizationDefinition.stage_name(verdant, "winch") == "Growth Lattice", "Verdant winch stage must present as Growth Lattice")
		_check(CivilizationDefinition.stage_name(verdant, "launcher") == "Bloom Anchor", "Verdant launcher stage must present as Bloom Anchor")
		_check(bool(verdant.world_influence.enabled), "Verdant reclamation must be enabled")
		_check(not bool(clockwork.world_influence.enabled), "Clockwork must not receive Verdant reclamation")
	var invalid := CivilizationDefinition.load_id("not_a_real_civilization")
	_check(not bool(invalid.ok), "Unknown civilization ids must be rejected")
	if failures.is_empty():
		print("ROOMSCALE_CIVILIZATION_DEFINITION_PASS ids=clockwork,verdant parity_resources=3 parity_stages=3")
		quit(0)
	else:
		push_error("ROOMSCALE_CIVILIZATION_DEFINITION_FAIL %s" % JSON.stringify(failures))
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
