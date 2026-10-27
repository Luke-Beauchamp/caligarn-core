# res://scripts/arena/ArenaGridManager.gd
class_name ArenaGridManager
extends Node2D

const TILE_SIZE: Vector2i = Vector2i(32, 32)
@export var grid_size: Vector2i = Vector2i(20, 12) # 640x360
@export var draw_debug_grid: bool = true

var astar_grid: AStarGrid2D
var active_debug_path: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	add_to_group("GridManager")
	_init_grid()

func _init_grid() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(Vector2i.ZERO, grid_size)
	astar_grid.cell_size = Vector2(TILE_SIZE)
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.jumping_enabled = true
	astar_grid.update()
	queue_redraw()

func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i((world_pos / Vector2(TILE_SIZE)).floor())

func tile_to_world_center(tile_coords: Vector2i) -> Vector2:
	return (Vector2(tile_coords) * Vector2(TILE_SIZE)) + (Vector2(TILE_SIZE) * 0.5)

func get_tile_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	var start_tile = world_to_tile(from_pos)
	var end_tile = world_to_tile(to_pos)
	
	if not astar_grid.is_in_boundsv(start_tile) or not astar_grid.is_in_boundsv(end_tile):
		return PackedVector2Array()

	var id_path = astar_grid.get_id_path(start_tile, end_tile)
	var world_path = PackedVector2Array()
	for tile in id_path:
		world_path.append(tile_to_world_center(tile))
	
	active_debug_path = world_path
	queue_redraw()
	return world_path

func _draw() -> void:
	if not draw_debug_grid:
		return

	# Draw subtle 32x32 grid lines
	for x in range(grid_size.x + 1):
		draw_line(Vector2(x * 32, 0), Vector2(x * 32, grid_size.y * 32), Color(1, 1, 1, 0.08))
	for y in range(grid_size.y + 1):
		draw_line(Vector2(0, y * 32), Vector2(grid_size.x * 32, y * 32), Color(1, 1, 1, 0.08))

	# Draw active navigation path line
	if active_debug_path.size() > 1:
		for i in range(active_debug_path.size() - 1):
			draw_line(active_debug_path[i], active_debug_path[i + 1], Color(0.2, 0.9, 0.4, 0.8), 2.0)
			draw_circle(active_debug_path[i], 3.0, Color(0.2, 0.9, 0.4, 0.9))
