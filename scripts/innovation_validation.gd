extends RefCounted
## Structural validation shared by innovation data loaders. Never coerce authoring types.

static func schema(value: Variant, errors: Array[String]) -> void:
	if not number(value) or value != 1:
		errors.append("schema_version must be the number 1")


static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func nonnegative_number(value: Variant) -> bool:
	return number(value) and float(value) >= 0

static func nonempty_string(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()

static func string_array(value: Variant) -> bool:
	return value is Array and value.all(func(member: Variant) -> bool: return nonempty_string(member))


static func id(value: Variant, label: String, errors: Array[String], lowercase: bool = false) -> String:
	if not (value is String) or value.strip_edges().is_empty():
		errors.append("%s must be a non-empty string" % label)
		return ""
	return value.strip_edges().to_lower() if lowercase else value.strip_edges().to_upper()


static func ids(value: Variant, label: String, errors: Array[String]) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		errors.append("%s must be an array" % label)
		return result
	for member in value:
		var normalized := id(member, "%s member" % label, errors)
		if not normalized.is_empty() and not result.has(normalized):
			result.append(normalized)
	result.sort()
	return result


static func numeric_field(entry: Dictionary, field: String, label: String, errors: Array[String], positive: bool = false) -> void:
	if not entry.has(field):
		return
	var value: Variant = entry[field]
	if not number(value) or value < 0 or (positive and value == 0):
		errors.append("%s %s must be a finite %s number" % [label, field, "positive" if positive else "non-negative"])


static func text_fields(entry: Dictionary, label: String, errors: Array[String]) -> void:
	for field in ["display_name", "description"]:
		if not entry.has(field):
			continue
		if not (entry[field] is String) or (field == "display_name" and entry[field].strip_edges().is_empty()):
			errors.append("%s %s must be %s" % [label, field, "a non-empty string" if field == "display_name" else "a string"])
