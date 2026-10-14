extends RefCounted
## Sole canonical material vocabulary. Presentation aliases are not new resources.
const IDS := ["food", "water", "wood", "metal", "mechanical_parts"]

static func supports(id: Variant) -> bool:
	return id is String and IDS.has(id)

static func requirements(construction: Dictionary) -> Dictionary:
	var result := {}
	var ids: Array = construction.keys(); ids.sort()
	for id in ids:
		if id != "work" and supports(id): result[id] = float(construction[id])
	return result
