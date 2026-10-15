extends SceneTree
var failures: Array = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func ledger(e: RefCounted) -> Dictionary:
	return {"snapshot":e.snapshot(),"tickets":e.tickets.duplicate(true),"consumed":e.consumed.duplicate(),"project":e.project_consumed.duplicate(),"exported":e.exported.duplicate(),"next":e._next_ticket}
func _initialize() -> void:
	for operation in ["pickup","deliver","consume","release","drop","recover_delivered"]:
		for state in ["reserved","in_transit","delivered"]:
			var e := preload("res://scripts/economy_system.gd").new()
			e.configure({"wood":10})
			var id := e.reserve("wood",2,"project:B")
			if state != "reserved": e.pickup(id,"project:B")
			if state == "delivered": e.deliver(id,"project:B")
			var before := ledger(e)
			var rejected: Variant = e.call(operation,id,"project:A")
			check(not rejected,"wrong owner rejected " + operation + state)
			check(ledger(e) == before,"wrong owner unchanged " + operation + state)
			check(e.audit().is_empty(),"rejected audit " + operation + state)
			var legal: bool = (operation == "release" or (operation == "pickup" and state == "reserved") or (operation in ["deliver","drop"] and state == "in_transit") or (operation == "recover_delivered" and state == "delivered") or (operation == "consume" and state in ["reserved","delivered"]))
			var accepted: Variant = e.call(operation,id,"project:B")
			check((not accepted.is_empty() if accepted is Dictionary else accepted) == legal,"correct owner legal states " + operation + state)
			if not legal: check(ledger(e) == before,"illegal state unchanged " + operation + state)
			check(e.audit().is_empty(),"correct owner audit " + operation + state)
			before = ledger(e)
			check(not e.call(operation,-1,"project:B") and ledger(e) == before,"missing ticket unchanged " + operation)
	var e := preload("res://scripts/economy_system.gd").new(); e.configure({"wood":4})
	var id := e.reserve("wood",2,"project:B")
	var before := ledger(e)
	check(not e.consume(id,"project:A",true) and ledger(e) == before,"project-consumed wrong owner unchanged")
	check(e.consume(id,"project:B",true) and e.project_consumed.wood == 2 and e.consumed.wood == 2 and e.audit().is_empty(),"project consumption legal")
	print("ROOMSCALE_ECONOMY_OWNERSHIP_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

