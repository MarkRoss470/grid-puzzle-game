extends Spatial

class_name Puzzle

"""
represents the puzzle - sets which icons go in which cells
[
	width, height,
	[[PuzzleCell or null; width]; height],        #cells
]
"""
export(Array) var puzzle
# Colours for puzzle's neutral state
export(Color) var colour_base = Color(0.5, 0.5, 0.5)
export(Color) var colour_hover = Color(0.8, 0.8, 0.8)
# Colours for an incorrect solution
export(Color) var colour_incorrect_base = Color(1, 0, 0)
export(Color) var colour_incorrect_hover = Color(1, 0.5, 0.5)
# Colours for a correct solution
export(Color) var colour_solved_base = Color(0, 1, 0)
export(Color) var colour_solved_hover = Color(0.5, 1, 0.5)

# What object to instance as a tile
export(NodePath) var instance_path
var instance: Node
# What object to call the on_puzzle_solve method of when the puzle is solved
export(NodePath) var on_complete_path
var on_complete: Node = null
# What parameter to pass to on_puzzle_solve
export(int) var on_complete_param
# Whether to load the puzzle immediately on startup
export(bool) var load_on_start = true

# Array[x][y] of the direction of cells
# 0 = up, 1 = right etc
var current_state: Array
# Stores references to the PuzzleTile nodes of this puzzle
var tiles: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	if load_on_start: load_puzzle()

# Loads the puzzle into the scene
func load_puzzle():
	if on_complete_path != "":
		on_complete = get_node(on_complete_path)
	instance = get_node(instance_path)
	
	# TODO: load puzzle state from saved game
	
	# Loop over columns in puzzle
	for x in range(puzzle[PuzzleClasses.WIDTH]):
		# Pad current_state and tiles
		current_state.append([])
		tiles.append([])
		# Loop over cells in column
		for y in range(puzzle[PuzzleClasses.HEIGHT]):
			# Initialise current puzzle state
			current_state[x].append(0)
			# Create new tile
			var tile = create_tile(x, y, puzzle[PuzzleClasses.CELLS][x][y])
			# Add reference to tile to tiles
			tiles[x].append(tile)
			# Add tile to scene tree
			add_child(tile)

# Creates a new puzzle cell object
func create_tile(x: int, y: int, cell) -> PuzzleTile:
	# Create new instance of template
	var node: PuzzleTile = instance.duplicate()
	
	# Set the node's colours
	node.colour_hover = colour_hover
	node.colour_base = colour_base
	
	# Set the node's position in the puzzle
	node.this_x = x
	node.this_y = y
	
	# Set physical position of node
	node.transform.origin = Vector3(x, -y, 0)
	
	# Give the node a reference to this puzzle to report rotations to
	node.puzzle = self
	# Make the node visible
	node.set_visible(true)
	
	# Get the node's icon plane
	var icon: CSGMesh = node.get_node("Icon")
	# If the puzzle cell has an icon, set the right image
	if cell != null:
		# Get texture
		var texture := TextureCacheSingleton.get_coloured_cell_texture([PuzzleClasses.CELL_ICONS[cell[0]][0], cell[1]])
		icon.rotate(Vector3.DOWN, PuzzleClasses.CELL_ICONS[cell[0]][1] * PI / 2)
		# Make copy of material
		var mat_override := icon.get_material().duplicate()
		# Set texture
		mat_override.set_shader_param("icon_texture", texture)
		# Set icon to use this material
		icon.set_material_override(mat_override)
	# If the puzzle cell has no icon, hide the icon plane
	else:
		icon.set_visible(false)
	
	return node

# Called by a cell when it is clicked
func rotate_cell(x, y):
	# Add one to cell's rotation
	current_state[x][y] += 1
	# Wrap around to 0 if reaches 4
	current_state[x][y] %= 4
	
	# Set all the cells to the base colour
	# Stops a puzzle from looking solved when it's not
	for column in tiles:
		for tile in column:
			tile.set_colour(colour_base, colour_hover)
	
	
# Checks whether the current solution is valid
# Calls on_complete.on_puzzle_solve(on_complete_param) if it is
func check_solution():
	# Check solution
	var solution := SolutionChecker.check_solution(puzzle, current_state)
	
	#TODO: save puzzle state to saved game
	
	# Initialise the cells to the base colour
	for column in tiles:
		for tile in column:
			tile.set_colour(colour_base, colour_hover)
	
	if solution.is_correct:
		# Set cells to colour on completion
		for column in tiles:
			for tile in column:
				tile.set_colour(colour_solved_base, colour_solved_hover)
		# Call puzzle solve callback
		if on_complete != null:
			on_complete.on_puzzle_solve(on_complete_param)
	else:
		# Set cells to colour on incorrect solution
		for cell in solution.wrong_cells:
			tiles[cell[0]][cell[1]].set_colour(colour_incorrect_base, colour_incorrect_hover)
		# Call puzzle unsolve callback
		if on_complete != null:
			on_complete.on_puzzle_unsolve(on_complete_param)
