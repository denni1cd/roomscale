extends RefCounted
## Exclusive inventory states and bounded transaction records. No stock at pickup twice.

const RESOURCES := preload("res://scripts/resource_vocabulary.gd").IDS
var instance_id := "legacy"
var available: Dictionary = {}
var initial: Dictionary = {}
var received: Dictionary = {}
var consumed: Dictionary = {}
var project_consumed: Dictionary = {}
var exported: Dictionary = {}
var tickets: Dictionary = {}
var _next_ticket := 1

func configure(stock: Dictionary) -> void:
	for resource in RESOURCES:
		if resource == "mechanical_parts" and not stock.has(resource): continue
		available[resource] = float(stock.get(resource, 0))
		initial[resource] = available[resource]
		received[resource] = 0.0
		consumed[resource] = 0.0
		project_consumed[resource] = 0.0
		exported[resource] = 0.0

func reserve(resource: String, amount: float, owner: String) -> int:
	if not available.has(resource) or amount <= 0 or not is_finite(amount) or float(available[resource]) + 0.00001 < amount:
		return -1
	available[resource] -= amount
	var id := _next_ticket
	_next_ticket += 1
	tickets[id] = {"resource": resource, "amount": amount, "owner": owner, "instance_id": instance_id, "state": "reserved"}
	return id

func _owned(id: int, expected_owner: String) -> bool:
	return tickets.has(id) and tickets[id].owner == expected_owner

func pickup(id: int, expected_owner: String) -> bool:
	if not _owned(id, expected_owner) or tickets[id].state != "reserved": return false
	tickets[id].state = "in_transit"
	return true

func deliver(id: int, expected_owner: String) -> bool:
	if not _owned(id, expected_owner) or tickets[id].state != "in_transit": return false
	tickets[id].state = "delivered"
	return true

func consume(id: int, expected_owner: String, project: bool = false) -> bool:
	if not _owned(id, expected_owner) or tickets[id].state not in ["reserved", "delivered"]: return false
	var ticket: Dictionary = tickets[id]
	if not is_finite(float(consumed[ticket.resource])+float(ticket.amount)): return false
	if project and not is_finite(float(project_consumed[ticket.resource])+float(ticket.amount)): return false
	consumed[ticket.resource] += float(ticket.amount)
	if project: project_consumed[ticket.resource] += float(ticket.amount)
	tickets.erase(id)
	return true

func release(id: int, expected_owner: String) -> bool:
	if not _owned(id, expected_owner) or tickets[id].state not in ["reserved", "in_transit", "delivered"]: return false
	var ticket: Dictionary = tickets[id]
	available[ticket.resource] += float(ticket.amount)
	tickets.erase(id)
	return true

func drop(id: int, expected_owner: String) -> Dictionary:
	if not _owned(id, expected_owner) or tickets[id].state != "in_transit": return {}
	var ticket: Dictionary = tickets[id].duplicate(true)
	exported[ticket.resource] += float(ticket.amount)
	tickets.erase(id)
	return ticket

func recover_delivered(id: int, expected_owner: String) -> Dictionary:
	if not _owned(id, expected_owner) or tickets[id].state != "delivered": return {}
	var ticket: Dictionary = tickets[id].duplicate(true)
	exported[ticket.resource] += float(ticket.amount)
	tickets.erase(id)
	return ticket

func receive(resource: String, amount: float) -> bool:
	if not can_receive(resource,amount): return false
	available[resource] += amount
	received[resource] += amount
	return true

func can_receive(resource: String, amount: float) -> bool:
	return available.has(resource) and amount > 0 and is_finite(amount) and is_finite(float(available[resource])+amount) and is_finite(float(initial[resource])+float(received[resource])+amount)

func state_total(resource: String, state: String) -> float:
	var total := 0.0
	for ticket in tickets.values():
		if ticket.resource == resource and ticket.state == state: total += float(ticket.amount)
	return total

func forecast(resource: String, population: int) -> float:
	var demand := population * (2.0 if resource == "food" else 3.0)
	return float(available.get(resource, 0)) / demand if demand > 0 else 0.0

func audit() -> Array[String]:
	var errors: Array[String] = []
	for resource in RESOURCES:
		if not available.has(resource): continue
		var total := float(available[resource]) + float(consumed[resource])
		for state in ["reserved", "in_transit", "delivered"]: total += state_total(resource, state)
		if not is_finite(total) or not is_finite(float(available[resource])) or not is_finite(float(initial[resource])) or not is_finite(float(received[resource])) or not is_finite(float(exported[resource])) or float(available[resource]) < -0.0001 or absf(total - float(initial[resource]) - float(received[resource]) + float(exported[resource])) > 0.0001:
			errors.append("%s accounting mismatch: %s" % [resource, snapshot()])
	return errors

func snapshot() -> Dictionary:
	var result := {}
	for resource in RESOURCES:
		if not available.has(resource): continue
		result[resource] = {"available": available[resource], "reserved": state_total(resource, "reserved"), "in_transit": state_total(resource, "in_transit"), "delivered": state_total(resource, "delivered"), "consumed": consumed[resource], "received": received[resource]}
	return result
