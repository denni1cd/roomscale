extends SceneTree
## Headless artifact I/O regression, including an actual unwritable destination.
const Evidence := preload("res://scripts/verification/evidence_io.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var directory := "res://verification/stabilization/runs/evidence-io-%d" % Time.get_ticks_usec()
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color("123456"))
	var png := directory.path_join("proof.png")
	var json := directory.path_join("proof.json")
	var failure := ""
	if Evidence.save_png(image, png) != OK: failure = "PNG write failed"
	var restored := Image.new()
	if restored.load(png) != OK or restored.get_size() != Vector2i(2, 2): failure = "PNG not readable"
	if Evidence.save_json({"checked": true}, json) != OK or JSON.parse_string(FileAccess.get_file_as_string(json)) != {"checked": true}: failure = "JSON not readable"
	# A regular file cannot contain output files: test a real filesystem rejection.
	if Evidence.save_png(image, png.path_join("blocked.png")) == OK: failure = "Invalid PNG destination accepted"
	if Evidence.save_json({}, json.path_join("blocked.json")) == OK: failure = "Invalid JSON destination accepted"
	if Evidence.save_png(Image.new(), png) != ERR_INVALID_DATA: failure = "Empty image accepted"
	for path in [png, json, directory]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("ROOMSCALE_EVIDENCE_IO_" + ("PASS" if failure.is_empty() else "FAIL") + " " + failure)
	quit(0 if failure.is_empty() else 1)
