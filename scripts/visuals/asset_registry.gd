extends RefCounted
## Runtime read-only view of the offline Art Factory's accepted asset registry.

const DEFAULT_REGISTRY_PATH := "res://art/registry.json"
const REVIEW_SHOWCASE_TYPE := "poc25_best_current_showcase"
const REVIEW_SHOWCASE_MODE := "review_showcase"

var registry_path := DEFAULT_REGISTRY_PATH
var entries: Dictionary = {}
var diagnostics: Array[String] = []
var valid := true
var review_showcase := false


func _init(path_override: String = "") -> void:
	registry_path = path_override if not path_override.is_empty() else OS.get_environment("ROOMSCALE_ART_REGISTRY")
	if registry_path.is_empty():
		registry_path = DEFAULT_REGISTRY_PATH
	_load()


func _load() -> void:
	if not FileAccess.file_exists(registry_path):
		_fail("registry file is missing: %s" % registry_path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(registry_path))
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1 or not parsed.get("entries") is Dictionary:
		_fail("registry must be schema_version 1 with an entries dictionary")
		return
	var registry_type := String(parsed.get("registry_type", "production"))
	var requested_mode := OS.get_environment("ROOMSCALE_ART_REGISTRY_MODE")
	if registry_type == REVIEW_SHOWCASE_TYPE:
		if requested_mode != REVIEW_SHOWCASE_MODE:
			_fail("best-current showcase registry requires explicit review_showcase mode")
			return
		review_showcase = true
	elif requested_mode == REVIEW_SHOWCASE_MODE:
		_fail("review_showcase mode requires a best-current showcase registry")
		return
	elif registry_type != "production":
		_fail("unknown registry_type: %s" % registry_type)
		return
	entries = parsed.entries
	for asset_id in entries:
		var entry: Variant = entries[asset_id]
		if not entry is Dictionary:
			_fail("registry entry %s must be an object" % String(asset_id))
			return
		var status := String(entry.get("status", ""))
		var accepted_status := status == "accepted"
		var review_status := review_showcase and status == "best_current_review"
		if not accepted_status and not review_status:
			_fail("registry entry %s has an invalid status for this registry mode: %s" % [String(asset_id), status])
			return
		if String(entry.get("path", "")).is_empty() or String(entry.get("sha256", "")).is_empty():
			_fail("registered asset %s is missing its path or SHA-256" % String(asset_id))
			return


func lookup(asset_id: String) -> Dictionary:
	if not valid or not entries.has(asset_id):
		return {}
	var entry: Dictionary = entries[asset_id].duplicate(true)
	var source_path := String(entry.path)
	var project_path := source_path if source_path.begins_with("res://") else "res://" + source_path.trim_prefix("/")
	entry["resolved_path"] = project_path
	entry["required"] = true
	entry["registry_review_only"] = review_showcase
	if not FileAccess.file_exists(project_path):
		entry["resolution_error"] = "registered asset file does not exist: %s" % project_path
		_diagnose(asset_id, entry.resolution_error)
		return entry
	var file := FileAccess.open(project_path, FileAccess.READ)
	if file == null:
		entry["resolution_error"] = "registered asset cannot be read: %s" % project_path
		_diagnose(asset_id, entry.resolution_error)
		return entry
	var actual_hash := ""
	var extension := source_path.get_extension().to_lower()
	if extension in ["tscn", "tres", "gltf", "gdshader", "json"]:
		# Windows checkouts may convert LF to CRLF. Line endings do not change a
		# Godot text resource, so use the same canonical LF bytes as the offline registry.
		actual_hash = file.get_as_text().replace("\r\n", "\n").sha256_text()
	else:
		var hashing := HashingContext.new()
		var start_error := hashing.start(HashingContext.HASH_SHA256)
		if start_error != OK:
			entry["resolution_error"] = "SHA-256 context could not start for %s" % project_path
			_diagnose(asset_id, entry.resolution_error)
			return entry
		hashing.update(file.get_buffer(file.get_length()))
		actual_hash = hashing.finish().hex_encode()
	if actual_hash != String(entry.sha256):
		entry["resolution_error"] = "registered asset SHA-256 mismatch for %s" % project_path
		_diagnose(asset_id, entry.resolution_error)
	return entry


func _fail(message: String) -> void:
	valid = false
	_diagnose("registry", message)


func _diagnose(asset_id: String, message: String) -> void:
	var diagnostic := "ROOMSCALE_REQUIRED_VISUAL_ASSET_FAILURE asset=%s: %s" % [asset_id, message]
	diagnostics.append(diagnostic)
	push_warning(diagnostic)
