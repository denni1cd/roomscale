extends Node
## A* floor grid populated only from the active RoomDefinition.

const CELL_INCHES := 4.0

var grid := AStarGrid2D.new()
var obstacle_rects: Array[Dictionary] = []
var room_definition: Dictionary = {}
var _origin := Vector2.ZERO
var _floor_center := Vector3.ZERO
var _floor_height := 0.0


func configure(definition: Dictionary) -> void:
	room_definition = definition.duplicate(true)


func remove_object_obstacle(object_id: String) -> void:
	for object in room_definition.objects:
		if String(object.id) == object_id: object.blocks_navigation = false
	_rebuild_grid()


func update_object_footprint(object_id: String, world_center: Vector3, dimensions: Vector3) -> void:
	for object in room_definition.objects:
		if String(object.id) != object_id: continue
		object.position = [world_center.x, world_center.y, world_center.z]
		object.dimensions = [dimensions.x, dimensions.y, dimensions.z]
	_rebuild_grid()


func allow_object_edge_access(object_id: String) -> void:
	for object in room_definition.objects:
		if String(object.id) == object_id: object.navigation_padding = [0, 0, 0]
	_rebuild_grid()


func _ready() -> void:
	_rebuild_grid()


func _rebuild_grid() -> void:
	if room_definition.is_empty():
		push_error("Floor navigation requires a RoomDefinition before entering the scene tree.")
		return
	var dimensions: Array = room_definition.dimensions
	var width := float(dimensions[0])
	var depth := float(dimensions[1])
	_floor_center = Vector3(float(room_definition.floor.center[0]), float(room_definition.floor.center[1]), float(room_definition.floor.center[2]))
	_floor_height = float(room_definition.floor.height)
	_origin = Vector2(_floor_center.x - width * 0.5 + CELL_INCHES * 0.5, _floor_center.z - depth * 0.5 + CELL_INCHES * 0.5)
	var cells_x := maxi(1, floori((width - CELL_INCHES) / CELL_INCHES) + 1)
	var cells_z := maxi(1, floori((depth - CELL_INCHES) / CELL_INCHES) + 1)
	grid.region = Rect2i(0, 0, cells_x, cells_z)
	grid.cell_size = Vector2(CELL_INCHES, CELL_INCHES)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	grid.update()
	obstacle_rects.clear()
	for object_variant in room_definition.objects:
		var object: Dictionary = object_variant
		if not bool(object.get("blocks_navigation", false)):
			continue
		var position := _vector(object.position)
		var dimensions_array: Array = object.dimensions
		var dimensions_2d := Vector2(float(dimensions_array[0]), float(dimensions_array[2]))
		var padding_array: Array = object.get("navigation_padding", [0.0, 0.0, 0.0])
		var padding := Vector2(float(padding_array[0]), float(padding_array[2]))
		var angle := deg_to_rad(float(object.get("rotation_degrees", 0.0)))
		var local_half := dimensions_2d * 0.5 + padding
		var rotated_half := Vector2(
			absf(cos(angle)) * local_half.x + absf(sin(angle)) * local_half.y,
			absf(sin(angle)) * local_half.x + absf(cos(angle)) * local_half.y
		)
		_add_blocked_rect(Vector2(position.x, position.z), rotated_half, String(object.id))
	_mark_obstacle_cells()
	print("ROOMSCALE_FLOOR_NAV_READY room=%s grid=%dx%d cell=%.0fin obstacles=%d" % [room_definition.id, cells_x, cells_z, CELL_INCHES, obstacle_rects.size()])


func _add_blocked_rect(center: Vector2, half: Vector2, reason: String) -> void:
	obstacle_rects.append({"center": center, "half": half, "reason": reason})


func _mark_obstacle_cells() -> void:
	for rect in obstacle_rects:
		var center: Vector2 = rect.center
		var half: Vector2 = rect.half
		var left := _world_to_cell(Vector2(center.x - half.x, center.y - half.y))
		var right := _world_to_cell(Vector2(center.x + half.x, center.y + half.y))
		for x in range(maxi(left.x, 0), mini(right.x, grid.region.size.x - 1) + 1):
			for z in range(maxi(left.y, 0), mini(right.y, grid.region.size.y - 1) + 1):
				grid.set_point_solid(Vector2i(x, z), true)


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
		result.append(Vector3(position.x, _floor_height, position.y))
	if not result[-1].is_equal_approx(Vector3(finish.x, _floor_height, finish.z)):
		result.append(Vector3(finish.x, _floor_height, finish.z))
	return result


func is_walkable(position: Vector3) -> bool:
	var cell := _world_to_cell(Vector2(position.x, position.z))
	return grid.region.has_point(cell) and not grid.is_point_solid(cell)


func nearest_walkable_position(position: Vector3) -> Vector3:
	var cell := _nearest_walkable_cell(_world_to_cell(Vector2(position.x, position.z)))
	if cell.x < 0:
		return Vector3(INF, 0.0, INF)
	var world := _cell_to_world(cell)
	return Vector3(world.x, _floor_height, world.y)


func is_obstacle_position(position: Vector3) -> bool:
	for rect in obstacle_rects:
		var center: Vector2 = rect.center
		var half: Vector2 = rect.half
		if absf(position.x - center.x) <= half.x and absf(position.z - center.y) <= half.y:
			return true
	return false


func room_bounds() -> Rect2:
	var dimensions: Array = room_definition.dimensions
	return Rect2(_floor_center.x - float(dimensions[0]) * 0.5, _floor_center.z - float(dimensions[1]) * 0.5, float(dimensions[0]), float(dimensions[1]))


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(roundi((position.x - _origin.x) / CELL_INCHES), roundi((position.y - _origin.y) / CELL_INCHES))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return _origin + Vector2(float(cell.x) * CELL_INCHES, float(cell.y) * CELL_INCHES)


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


func _vector(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
