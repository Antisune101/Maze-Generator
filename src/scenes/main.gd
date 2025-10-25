extends Node2D


@export var maze_node: Node2D
@export var sprite: Sprite2D

const CELL_SIZE = 32
const GRID_SIZE = Vector2i(20, 20)
const LINE_WIDTH = 2

var v_walls := {}
var h_walls := {}
var outer_walls: Array[Line2D] = []


func _ready() -> void:
	# Center grid
	var center = get_viewport_rect().get_center()
	var grid_with = GRID_SIZE.x * CELL_SIZE + LINE_WIDTH
	var grid_height = GRID_SIZE.y * CELL_SIZE + LINE_WIDTH
	maze_node.global_position.x = center.x - grid_with / 2.0
	maze_node.global_position.y = center.y - grid_height / 2.0
	
	# Generate walls and store them in h_walls and v_walls
	for y in GRID_SIZE.y + 1:
		for x in GRID_SIZE.y:
			if y == 0 or y == GRID_SIZE.y:
				outer_walls.append(build_wall(x, y, x+1, y))
			else:
				h_walls[Vector2i(x, y-1)] = build_wall(x, y, x+1, y)
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x + 1:
			if x == 0 or x == GRID_SIZE.x:
				outer_walls.append(build_wall(x, y, x, y+1))
			else:
				v_walls[Vector2i(x-1, y)] = build_wall(x, y, x, y+1)
	
	
	for wall in outer_walls:
		wall.default_color = Color.BLACK
		wall.width = 4


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		generate_maze()


func init_grid() -> void:
	pass


func reset_grid() -> void:
	pass

func build_wall(x1, y1, x2, y2) -> Line2D:
	var wall = Line2D.new()
	wall.width = 2
	maze_node.add_child(wall)
	wall.add_point(vec_to_position(x1, y1))
	wall.add_point(vec_to_position(x2, y2))
	return wall

func vec_to_position(x,y) -> Vector2:
	return Vector2(x, y) * CELL_SIZE


func delete_v_wall(x, y) -> void:
	v_walls[Vector2i(x, y)].queue_free()

func delete_h_wall(x, y) -> void:
	h_walls[Vector2i(x, y)].queue_free()

# Algorithm
var cells: Array[Vector2i] = []
var untraversed_cells: Array[Vector2i] = []

var travel_history: Array[Vector2i] = []

func generate_maze() -> void:
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			cells.append(Vector2i(x, y))
	untraversed_cells = cells
	var starting_cell = cells.pick_random()
	visit_cell(starting_cell)


func visit_cell(cell: Vector2i) -> void:
	await get_tree().create_timer(.05).timeout
	sprite.position = cell * CELL_SIZE
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
	sprite.position = cell * CELL_SIZE
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
	n = n.filter(func(c): return c.x >= 0 && c.x < GRID_SIZE.x && c.y >= 0 && c.y < GRID_SIZE.y)
	n = n.filter(func(c): return untraversed_cells.has(c))
	return n
