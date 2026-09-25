extends Node
## Small inch-scale A* grid. Furniture and structures occupy blocked floor cells.

const CELL_INCHES := 4.0
const MIN_X := -118.0
const MIN_Z := -88.0
const CELLS_X := 60
const CELLS_Z := 45

var grid := AStarGrid2D.new()
var obstacle_rects: Array[Dictionary] = []


func _ready() -> void:
	grid.region = Rect2i(0, 0, CELLS_X, CELLS_Z)
	grid.cell_size = Vector2(CELL_INCHES, CELL_INCHES)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	grid.update()
	_add_blocked_rect(Vector2(0.0, 0.0), Vector2(4.0, 4.0), "wall clearance")
	_add_blocked_rect(Vector2(0.0, -89.0), Vector2(118.0, 3.0), "back wall")
	_add_blocked_rect(Vector2(-119.0, 0.0), Vector2(3.0, 86.0), "left wall")
	_add_blocked_rect(Vector2(119.0, 0.0), Vector2(3.0, 86.0), "right wall")
	# Major furniture from the generated M1 room; extents include a walking margin.
	_add_blocked_rect(Vector2(-58.0, -52.0), Vector2(38.0, 21.0), "desk")
	_add_blocked_rect(Vector2(-58.0, -20.0), Vector2(16.0, 15.0), "chair")
	_add_blocked_rect(Vector2(91.0, -63.0), Vector2(19.0, 12.0), "bookcase")
	_add_blocked_rect(Vector2(44.0, -15.0), Vector2(13.0, 11.0), "side table")
	_add_blocked_rect(Vector2(75.0, 43.0), Vector2(11.0, 10.0), "storage box")
	_add_blocked_rect(Vector2(-99.0, 12.0), Vector2(10.0, 10.0), "waste bin")
	_add_blocked_rect(Vector2(-91.0, -46.0), Vector2(10.0, 10.0), "plant pot")
	# Settlement footprints, leaving clear approaches at each entrance/work station.
	_add_blocked_rect(Vector2(-20.0, 42.0), Vector2(13.0, 9.0), "workshop")
	_add_blocked_rect(Vector2(18.0, 42.0), Vector2(12.0, 9.0), "depot")
	_add_blocked_rect(Vector2(-25.0, 66.0), Vector2(9.0, 7.0), "housing")
	_add_blocked_rect(Vector2(11.0, 66.0), Vector2(10.0, 5.0), "assembly bench")
	grid.update()
	for rect in obstacle_rects:
		var center: Vector2 = rect.center
		var half: Vector2 = rect.half
		var left := _world_to_cell(Vector2(center.x - half.x, center.y - half.y))
		var right := _world_to_cell(Vector2(center.x + half.x, center.y + half.y))
		for x in range(left.x, right.x + 1):
			for z in range(left.y, right.y + 1):
				var cell := Vector2i(x, z)
				if grid.region.has_point(cell):
					grid.set_point_solid(cell, true)
	print("ROOMSCALE_FLOOR_NAV_READY grid=%dx%d cell=%.0fin obstacles=%d" % [CELLS_X, CELLS_Z, CELL_INCHES, obstacle_rects.size()])


func _add_blocked_rect(center: Vector2, half: Vector2, reason: String) -> void:
	obstacle_rects.append({"center": center, "half": half, "reason": reason})


func path_between(start: Vector3, finish: Vector3) -> Array[Vector3]:
	var from_cell := _nearest_walkable_cell(_world_to_cell(Vector2(start.x, start.z)))
	var to_cell := _nearest_walkable_cell(_world_to_cell(Vector2(finish.x, finish.z)))
	if from_cell.x < 0 or to_cell.x < 0:
		return []
	var ids: Array[Vector2i] = grid.get_id_path(from_cell, to_cell)
	if ids.is_empty():
		return []
	var result: Array[Vector3] = []
	for id in ids:
		var position := _cell_to_world(id)
		result.append(Vector3(position.x, 0.0, position.y))
	if not result[-1].is_equal_approx(Vector3(finish.x, 0.0, finish.z)):
		result.append(Vector3(finish.x, 0.0, finish.z))
	return result


func is_walkable(position: Vector3) -> bool:
	var cell := _world_to_cell(Vector2(position.x, position.z))
	return grid.region.has_point(cell) and not grid.is_point_solid(cell)


func nearest_walkable_position(position: Vector3) -> Vector3:
	var cell := _nearest_walkable_cell(_world_to_cell(Vector2(position.x, position.z)))
	if cell.x < 0:
		return Vector3(INF, 0.0, INF)
	var world := _cell_to_world(cell)
	return Vector3(world.x, 0.0, world.y)


func is_obstacle_position(position: Vector3) -> bool:
	for rect in obstacle_rects:
		var center: Vector2 = rect.center
		var half: Vector2 = rect.half
		if absf(position.x - center.x) <= half.x and absf(position.z - center.y) <= half.y:
			return true
	return false


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(roundi((position.x - MIN_X) / CELL_INCHES), roundi((position.y - MIN_Z) / CELL_INCHES))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(MIN_X + float(cell.x) * CELL_INCHES, MIN_Z + float(cell.y) * CELL_INCHES)


func _nearest_walkable_cell(origin: Vector2i) -> Vector2i:
	if grid.region.has_point(origin) and not grid.is_point_solid(origin):
		return origin
	for radius in range(1, 10):
		for offset_x in range(-radius, radius + 1):
			for offset_z in range(-radius, radius + 1):
				if maxi(absi(offset_x), absi(offset_z)) != radius:
					continue
				var candidate := origin + Vector2i(offset_x, offset_z)
				if grid.region.has_point(candidate) and not grid.is_point_solid(candidate):
					return candidate
	return Vector2i(-1, -1)
