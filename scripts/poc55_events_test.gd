extends SceneTree
const Journal := preload("res://scripts/event_journal.gd")
const Catalog := preload("res://scripts/spectator_event_catalog.gd")
const Presenter := preload("res://scripts/fishbowl_event_presenter.gd")
const Sources := preload("res://scripts/spectator_sources.gd")
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
	if not value: failures.append(label)
func _initialize() -> void:
	var journal := Journal.new()
	journal.configure_context("a", "verdant")
	journal.record(1, "development_started", "Build", {"id":"p", "kind":"workshop"}, Vector3.ZERO, "p", {"project_id":"p", "subject_type":"project", "subject_id":"p"})
	check(Journal.validate(journal.events[0]).is_empty(), "normalized contract valid")
	var malformed := journal.events[0].duplicate(true)
	malformed.id = "bad"
	malformed.seconds = NAN
	malformed.evidence = "not structured"
	malformed.society_id = 12
	malformed.participants = "not identities"
	malformed.camera_priority = 7
	check(Journal.validate(malformed).size() >= 6, "malformed schema and misplaced policy rejected")
	check(journal.events[0].focus_valid and journal.events[0].focus == Vector3.ZERO, "explicit world origin valid")
	journal.record(2, "unknown_future_event", "Readable future story")
	check(not journal.events[1].focus_valid, "omitted focus not fabricated")
	check(journal.events[0].society_id == "a" and journal.events[0].civilization_id == "verdant", "default society identity")
	var presenter := Presenter.new()
	var records: Array[Dictionary] = []
	Sources._append(records, journal.events, "society:a", "a", "verdant")
	Sources._append(records, journal.events, "society:b", "b", "clockwork")
	var detached := records[0].duplicate(true)
	records[0].evidence["mutated"] = true
	check(not journal.events[0].evidence.has("mutated"), "source snapshot cannot mutate authoritative history")
	records[0] = detached
	presenter.ingest(records)
	check(presenter.recent.size() == 4, "journal-local IDs never collide")
	presenter.ingest(records)
	check(presenter.recent.size() == 4, "reingestion is idempotent")
	check(presenter.recent[0].headline == "UNKNOWN FUTURE EVENT", "unknown kinds readable")
	check(presenter.recent[3].subtitle.contains("Growth Nursery"), "event-local civilization narrative")
	check(not presenter.recent[3].subtitle.contains("Workshop"), "selected profile cannot leak into event")
	var adapter := preload("res://scripts/fishbowl_narrative_adapter.gd")
	var technical := adapter.event_card({"kind":"governor", "message":"MATERIALS: shortage { wood:4.0 }", "civilization_id":"scavenger", "society_id":"scavenger_alpha"})
	check(not technical.subtitle.contains("{") and not technical.subtitle.contains("wood:"), "normal narrative hides technical dictionaries")
	var project_card := adapter.event_card({"kind":"development_started", "evidence":{"id":"scavenger_alpha_development_001", "kind":"workshop"}, "civilization_id":"scavenger"})
	check(not project_card.subtitle.contains("scavenger_alpha") and project_card.subtitle.contains("1"), "project display hides stable technical prefix")
	var groups := [[Catalog.CRITICAL,Catalog.CRITICAL_KINDS], [Catalog.HIGH,Catalog.HIGH_KINDS], [Catalog.MEDIUM,Catalog.MEDIUM_KINDS]]
	for group in groups:
		for kind in group[1]: check(Catalog.metadata({"kind":kind}).priority == group[0], "priority " + kind)
	check(not preload("res://scripts/fishbowl_narrative_adapter.gd").event_card({"kind":"future", "id":"bad", "evidence":"bad"}).is_empty(), "malformed optional data degrades safely")
	check(not Catalog.metadata({"kind":"routine_work"}).eligible, "routine not Priority interrupt")
	for i in range(300): journal.record(i, "work", str(i), {}, Vector3.ONE, str(i))
	check(journal.events.size() == 128 and journal._states.size() <= 256, "journal/suppression bounds")
	check(journal.events.back().id == 302, "monotonic ID")
	records.clear()
	Sources._append(records, journal.events, "society:a", "a", "verdant")
	presenter.ingest(records)
	check(presenter.recent.size() == 64 and presenter.pending.size() <= 8, "presentation bounds")
	check(failures.is_empty(), "all contracts")
	print("POC55_EVENTS ", JSON.stringify({"pass":failures.is_empty(), "failures":failures}))
	quit(0 if failures.is_empty() else 1)
