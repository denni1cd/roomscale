extends RefCounted
## Only presentation state. advance receives unscaled real seconds, never sim ticks.
const Adapter := preload("res://scripts/fishbowl_narrative_adapter.gd")
const LIMIT := 8
var cursor := 0
var pending: Array[Dictionary] = []
var current: Dictionary = {}
var age := 0.0
var seen: Array[String] = []
var alpha := 0.0

func ingest(events: Array) -> void:
	for event in events:
		if int(event.id) <= cursor: continue
		cursor = int(event.id)
		var card := Adapter.event_card(event)
		if card.is_empty() or card.key in seen: continue
		seen.append(card.key)
		while seen.size() > 128: seen.pop_front()
		pending.append(card)
		pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority > b.priority if a.priority != b.priority else a.id < b.id)
		while pending.size() > LIMIT: pending.pop_back()

func advance(real_delta: float) -> void:
	age += maxf(0, real_delta)
	if not current.is_empty() and age >= float(current.duration): current = {}
	if current.is_empty() and not pending.is_empty():
		current = pending.pop_front()
		age = 0
	alpha = 0 if current.is_empty() else minf(clampf(age / 0.35, 0, 1), clampf((float(current.duration) - age) / 0.65, 0, 1))
