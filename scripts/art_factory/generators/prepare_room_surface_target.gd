extends SceneTree
## Prepare an image-generated Visual Director swatch for strict texture repetition.
const TileableTexture := preload("res://scripts/art_factory/tileable_texture.gd")

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var input_path := OS.get_environment("ROOMSCALE_TEXTURE_INPUT")
	var output_path := OS.get_environment("ROOMSCALE_TEXTURE_OUTPUT")
	var blend_width := int(OS.get_environment("ROOMSCALE_TEXTURE_BLEND_WIDTH"))
	if input_path.is_empty() or output_path.is_empty():
		_fail("input and output paths are required")
		return
	var source := Image.new()
	var load_error := source.load(input_path)
	if load_error != OK:
		_fail("could not load source image, error=%d" % load_error)
		return
	source.convert(Image.FORMAT_RGBA8)
	var tiled := TileableTexture.make_tileable(source, maxi(1, blend_width))
	if tiled.is_empty():
		_fail("tileable image preparation failed")
		return
	var save_error := tiled.save_png(output_path)
	if save_error != OK:
		_fail("could not write target image, error=%d" % save_error)
		return
	print("ROOMSCALE_TEXTURE_TARGET_PASS dimensions=%dx%d edge_pixels=%d output=%s" % [tiled.get_width(), tiled.get_height(), blend_width, output_path])
	quit(0)


func _fail(message: String) -> void:
	push_error("ROOMSCALE_TEXTURE_TARGET_FAIL: " + message)
	quit(1)
