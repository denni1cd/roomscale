extends RefCounted
## Strategic sites, instance relations and secure holds; no floor-wide ownership grid.
const SECURE_HOLD_SECONDS := 10.0
var sites: Dictionary = {}
var relations: Dictionary = {}
var journal: RefCounted

func configure(definition: Dictionary, events: RefCounted) -> void:
	journal = events
	for anchor in definition.get("strategic_sites", []):
		sites[anchor.id] = {"site_id": anchor.id, "region_id": anchor.region_id, "position": Vector3(anchor.position[0], anchor.position[1], anchor.position[2]), "benefits":anchor.get("benefits",{}).duplicate(true), "owner_civilization_id": "", "claim_state": "NEUTRAL", "contesting_civilizations": [], "hold_progress": 0.0, "last_battle_time": -1.0}

func relation_key(a: String, b: String) -> String:
	return a + ":" + b if a < b else b + ":" + a

func claim(site_id: String, instance_id: String, seconds: float) -> void:
	var site: Dictionary = sites[site_id]
	if site.contesting_civilizations.has(instance_id): return
	site.contesting_civilizations.append(instance_id)
	site.contesting_civilizations.sort()
	site.claim_state = "CLAIMED"
	if site.contesting_civilizations.size() < 2: return
	var key := relation_key(site.contesting_civilizations[0], site.contesting_civilizations[1])
	if relations.get(key, "UNKNOWN") == "UNKNOWN":
		relations[key] = "CONTACT"
		journal.record(seconds, "FIRST_CONTACT", "Territorial encounter at " + site_id, {"participants": site.contesting_civilizations}, site.position, key + ":contact")
	site.claim_state = "CONTESTED"
	journal.record(seconds, "SITE_CONTESTED", "Strategic site contested", {"site_id": site_id}, site.position, site_id + ":contested")

func set_relation(a: String, b: String, state: String, seconds: float, site_id: String, context: Dictionary = {}) -> void:
	var key := relation_key(a, b)
	if relations.get(key, "UNKNOWN") == state: return
	relations[key] = state
	var site: Dictionary = sites[site_id]
	var data := context.duplicate(true)
	data["participants"] = [a,b]
	data["site_id"] = site_id
	if state == "HOSTILE":
		journal.record(seconds, "HOSTILITY_DECLARED", "Scarcity escalates competing claims to hostility", data, site.position, key + ":hostile")
	elif state == "COMPETITION":
		journal.record(seconds, "COMPETITION_DECLARED", "Competing claims remain below the threshold for war", data, site.position, key + ":competition")
	elif state == "CONTACT":
		journal.record(seconds, "HOSTILITY_ENDED", "Conflict pressure fell below the threshold for war", data, site.position, key + ":standdown:%d" % int(seconds))

func hold(site_id: String, winner: String, seconds: float, delta: float) -> bool:
	var site: Dictionary = sites[site_id]
	site.hold_progress += delta
	if site.hold_progress + 0.000001 < SECURE_HOLD_SECONDS: return false
	site.owner_civilization_id = winner
	site.claim_state = "CONTROLLED"
	site.contesting_civilizations = [winner]
	site.last_battle_time = seconds
	journal.record(seconds, "SITE_CAPTURED", winner + " secured " + site_id, {"site_id":site_id,"winner":winner}, site.position, site_id + ":captured")
	return true
