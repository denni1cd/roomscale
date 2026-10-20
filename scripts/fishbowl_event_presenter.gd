extends RefCounted
## Real-time transient alerts plus a bounded recent view of authoritative journals.
const Adapter := preload("res://scripts/fishbowl_narrative_adapter.gd")
const LIMIT := 8
const RECENT_LIMIT := 64
var cursor := 0 # Compatibility diagnostic; source_key controls ingestion.
var pending: Array[Dictionary] = []
var recent: Array[Dictionary] = []
var current: Dictionary = {}
var age := 0.0
var seen: Array[String] = []
var alpha := 0.0

func ingest(events: Array) -> void:
	for event in events:
		var source_key := String(event.get("source_key", "local:" + str(event.id)))
		if source_key in seen: continue
		seen.append(source_key)
		while seen.size() > 1024: seen.pop_front()
		cursor = maxi(cursor, int(event.id))
		var card := Adapter.event_card(event)
		if card.is_empty(): continue
		var duplicate := false
		for previous in recent:
			if previous.event.get("source_id", "local") == card.event.get("source_id", "local") and previous.key == card.key:
				duplicate = true
				break
		if duplicate: continue
		recent.push_front(card)
		while recent.size() > RECENT_LIMIT: recent.pop_back()
		# Cards retain meaningful milestones; only exact adjacent repeats are quiet.
		if not pending.is_empty() and pending.back().key == card.key: continue
		pending.append(card)
		pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority > b.priority if a.priority != b.priority else float(a.seconds) < float(b.seconds))
		while pending.size() > LIMIT: pending.pop_back()

func advance(real_delta: float) -> void:
	age += maxf(0, real_delta)
	if not current.is_empty() and age >= float(current.duration): current = {}
	if current.is_empty() and not pending.is_empty():
		current = pending.pop_front()
		age = 0
	alpha = 0 if current.is_empty() else minf(clampf(age / 0.35, 0, 1), clampf((float(current.duration) - age) / 0.65, 0, 1))
