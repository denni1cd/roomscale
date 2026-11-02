extends RefCounted
## Deterministic, non-destructive seam blending for generated material targets.

static func make_tileable(source: Image, blend_width: int = 48) -> Image:
	if source == null or source.is_empty():
		push_error("TILEABLE_TEXTURE_SOURCE_EMPTY")
		return Image.new()
	var width := source.get_width()
	var height := source.get_height()
	if width < 64 or height < 64 or width % 2 != 0 or height % 2 != 0:
		push_error("TILEABLE_TEXTURE_REQUIRES_EVEN_DIMENSIONS_AT_LEAST_64PX")
		return Image.new()
	var band := clampi(blend_width, 1, mini(width, height) / 4)
	var half_width := width / 2
	var half_height := height / 2
	var offset := Image.create(width, height, false, source.get_format())
	offset.blit_rect(source, Rect2i(0, 0, half_width, half_height), Vector2i(half_width, half_height))
	offset.blit_rect(source, Rect2i(half_width, 0, width - half_width, half_height), Vector2i(0, half_height))
	offset.blit_rect(source, Rect2i(0, half_height, half_width, height - half_height), Vector2i(half_width, 0))
	offset.blit_rect(source, Rect2i(half_width, half_height, width - half_width, height - half_height), Vector2i(0, 0))

	for y in range(height):
		for distance in range(band):
			var left_x := half_width - 1 - distance
			var right_x := half_width + distance
			var blend := 1.0 - float(distance) / float(band)
			var left := offset.get_pixel(left_x, y)
			var right := offset.get_pixel(right_x, y)
			var seam_value := (left + right) * 0.5
			offset.set_pixel(left_x, y, left.lerp(seam_value, blend))
			offset.set_pixel(right_x, y, right.lerp(seam_value, blend))
	for x in range(width):
		for distance in range(band):
			var top_y := half_height - 1 - distance
			var bottom_y := half_height + distance
			var blend := 1.0 - float(distance) / float(band)
			var top := offset.get_pixel(x, top_y)
			var bottom := offset.get_pixel(x, bottom_y)
			var seam_value := (top + bottom) * 0.5
			offset.set_pixel(x, top_y, top.lerp(seam_value, blend))
			offset.set_pixel(x, bottom_y, bottom.lerp(seam_value, blend))

	var result := Image.create(width, height, false, source.get_format())
	result.blit_rect(offset, Rect2i(0, 0, half_width, half_height), Vector2i(half_width, half_height))
	result.blit_rect(offset, Rect2i(half_width, 0, width - half_width, half_height), Vector2i(0, half_height))
	result.blit_rect(offset, Rect2i(0, half_height, half_width, height - half_height), Vector2i(half_width, 0))
	result.blit_rect(offset, Rect2i(half_width, half_height, width - half_width, height - half_height), Vector2i(0, 0))
	return result
