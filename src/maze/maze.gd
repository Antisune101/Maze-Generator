class_name Maze extends Node2D

@export var maze_node: Node2D
@export var sprite: Sprite2D

var grid_size = Vector2i(10, 10)
var cell_size = 32

var v_walls := {}
var h_walls := {}
var outer_walls: Array[Line2D] = []


func _ready() -> void:
	generate_grid()
	generate_maze()
	Globals.maze_parameters_updated.connect(generate_grid)


func generate_grid() -> void:
	for wall in maze_node.get_children():
		wall.queue_free()
	v_walls.clear()
	h_walls.clear()
	outer_walls.clear()
	
	
	# Center grid
	var max_width = get_viewport_rect().size.y - Globals.PADDING * 2
	cell_size = max_width / max(grid_size.x, grid_size.y) 
	var left = get_viewport_rect().size.x
	maze_node.global_position = Vector2(left - (max_width + Globals.PADDING), Globals.PADDING)
	sprite.global_position = maze_node.global_position
	sprite.visible = false
	# Generate walls and store them in h_walls and v_walls
	for y in grid_size.y + 1:
		for x in grid_size.y:
			if y == 0 or y == grid_size.y:
				outer_walls.append(build_wall(x, y, x+1, y))
			else:
				h_walls[Vector2i(x, y-1)] = build_wall(x, y, x+1, y)
	for y in grid_size.y:
		for x in grid_size.x + 1:
			if x == 0 or x == grid_size.x:
				outer_walls.append(build_wall(x, y, x, y+1))
			else:
				v_walls[Vector2i(x-1, y)] = build_wall(x, y, x, y+1)
	
	
	for wall in outer_walls:
		wall.default_color = Color.BLACK
		wall.width = 4


func build_wall(x1, y1, x2, y2) -> Line2D:
	var wall = Line2D.new()
	wall.width = Globals.WALL_WIDTH
	maze_node.add_child(wall)
	wall.add_point(vec_to_position(Vector2i(x1, y1)))
	wall.add_point(vec_to_position(Vector2i(x2, y2)))
	return wall


func vec_to_position(vec: Vector2i) -> Vector2:
	return Vector2(vec.x, vec.y) * cell_size


func delete_v_wall(x, y) -> void:
	v_walls[Vector2i(x, y)].queue_free()

func delete_h_wall(x, y) -> void:
	h_walls[Vector2i(x, y)].queue_free()

# Algorithm
var cells: Array[Vector2i] = []
var untraversed_cells: Array[Vector2i] = []

var travel_history: Array[Vector2i] = []

func generate_maze() -> void:
	sprite.visible = true
	for y in grid_size.y:
		for x in grid_size.x:
			cells.append(Vector2i(x, y))
	untraversed_cells = cells
	var starting_cell = cells.pick_random()
	visit_cell(starting_cell)


func visit_cell(cell: Vector2i) -> void:
	await get_tree().create_timer(.05).timeout
	sprite.position = cell * cell_size
	sprite.self_modulate = Color.GREEN
	
	travel_history.append(cell)
	untraversed_cells.erase(cell)
	if untraversed_cells.is_empty():
		print("Done :)")
		return
	if !is_cell_exhausted(cell):
		var next_cell = find_untraversed_neighbors(cell).pick_random()
		clear_path(cell, next_cell)
		visit_cell(next_cell)
	else:
		backtrack(cell)


func backtrack(cell: Vector2i) -> void:
	await get_tree().create_timer(.05).timeout
	sprite.position = cell * cell_size
	sprite.self_modulate = Color.RED
	travel_history.pop_back()
	if is_cell_exhausted(cell):
		backtrack(travel_history[-1])
	else:
		visit_cell(cell)


func clear_path(a, b) -> void:
	if a.y == 0 or b.y == 0:
		pass
		#breakpoint
	if a.x == b.x:
		var wall = a if a.y < b.y else b
		delete_h_wall(wall.x, wall.y)
	else:
		var wall = a if a.x < b.x else b
		delete_v_wall(wall.x, wall.y)

func is_cell_exhausted(cell: Vector2i) -> bool:
	return find_untraversed_neighbors(cell).is_empty()


func find_untraversed_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var x = cell.x
	var y = cell.y
	var n: Array[Vector2i] = [
		Vector2i(x+1, y),
		Vector2i(x-1, y),
		Vector2i(x, y+1),
		Vector2i(x, y-1),
	]
	n = n.filter(func(c): return c.x >= 0 && c.x < grid_size.x && c.y >= 0 && c.y < grid_size.y)
	n = n.filter(func(c): return untraversed_cells.has(c))
	return n
