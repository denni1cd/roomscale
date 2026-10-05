extends RefCounted
## Checked artifact writes shared by evidence drivers; callers own failure reporting.

static func _prepare_directory(path: String) -> Error:
	var directory := ProjectSettings.globalize_path(path.get_base_dir())
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return error
	# Some platforms return OK for an existing regular file; it is not a directory.
	return OK if DirAccess.dir_exists_absolute(directory) else ERR_CANT_CREATE

static func save_png(image: Image, path: String) -> Error:
	if image == null or image.is_empty(): return ERR_INVALID_DATA
	var error := _prepare_directory(path)
	if error != OK: return error
	return image.save_png(path)

static func save_json(value: Variant, path: String) -> Error:
	var error := _prepare_directory(path)
	if error != OK: return error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	return file.get_error()
