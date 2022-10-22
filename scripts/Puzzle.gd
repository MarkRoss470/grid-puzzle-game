extends Spatial

class_name Puzzle

"""[
	width, height,
	[[PuzzleCell or null; width]; height],        #cells
	[[PuzzleEdge or null; width]; height + 1],    #horizontal edges
	[[PuzzleEdge or null; width + 1]; height + 1] #vertical edges
]"""
export(Array) var puzzle
export(Color) var colour_base = Color(0.5, 0.5, 0.5)
export(Color) var colour_hover = Color(0.8, 0.8, 0.8)
export(Color) var colour_on_incorrect = Color(1, 0, 0)
export(Color) var colour_solved_base = Color(0, 1, 0)
export(Color) var colour_solved_hover = Color(0.5, 1, 0.5)

# What object to instance as a tile
export(NodePath) var instance
# What object to call the on_puzzle_solve method of when the puzle is solved
export(NodePath) var on_complete
# What parameter to pass to on_puzzle_solve
export(int) var on_complete_param

# Array[x][y] of the direction of cells
# 0 = up, 1 = right etc
var current_state: Array
# Stores references to the PuzzleTile nodes of this puzzle
var tiles: Array


# Called when the node enters the scene tree for the first time.
func _ready():
	# Loop over cells in puzzle
	for x in range(puzzle[PuzzleClasses.WIDTH]):
		current_state.append([])
		tiles.append([])
		for y in range(puzzle[PuzzleClasses.HEIGHT]):
			# Initialise current puzzle state
			current_state[x].append(0)
			# Create new tile
			var tile = create_tile(x, y, puzzle[PuzzleClasses.CELLS][x][y])
			tile.transform.origin = Vector3(x, -y, 0)
			tiles[x].append(tile)
			add_child(tile)

# Creates a new puzzle cell object
func create_tile(x: int, y: int, cell) -> PuzzleTile:
	var node: PuzzleTile = get_node(instance).duplicate()
	
	node.colour_hover = colour_hover
	node.colour_base = colour_base
	
	node.this_x = x
	node.this_y = y
	node.puzzle = self
	node.set_visible(true)
	var icon: CSGMesh = node.get_node("Icon")
	if cell != null:
		var texture := TextureCacheSingleton.get_coloured_cell_texture(cell)
		var mat_override := icon.get_material().duplicate()
		mat_override.set_shader_param("icon_texture", texture)
		icon.set_material_override(mat_override)
	else:
		icon.set_visible(false)
	node.rotate(Vector3.RIGHT, PI / 2)
	return node

# Called by a cell when it is clicked
func rotate_cell(x, y):
	# Add one to cell's rotation
	current_state[x][y] += 1
	# Wrap around to 0 if reaches 4
	current_state[x][y] %= 4
	
# Checks whether the current solution is valid
# Calls on_complete.on_puzzle_solve(on_complete_param) if it is
func check_solution():
	var solved := true
	# Initialise the cells to the base colour
	for column in tiles:
			for tile in column:
				tile.set_colour(colour_base, colour_hover)
	
	
	if current_state[0][0] == 1:
		solved = false
	
	#TODO: check whether the puzzle is actually solved
	var node = get_node(on_complete)
	if solved:
		for column in tiles:
			for tile in column:
				tile.set_colour(colour_solved_base, colour_solved_hover)
		
		if node != null:
			node.on_puzzle_solve(on_complete_param)
	elif node != null:
		node.on_puzzle_unsolve(on_complete_param)
