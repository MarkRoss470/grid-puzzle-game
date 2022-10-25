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

# How long each tile's animation should take
export(float) var tile_animation_time: float = 1
# The offset between tiles' animations
export(float) var tile_animation_offset: float = 0.2
# Variables to keep track of animations
var loading_tiles_progress: float = -1
var unloading_tiles_progress: float = -1

# Array[x][y] of the direction of cells
# 0 = up, 1 = right etc
var current_state: Array
# Stores references to the PuzzleTile nodes of this puzzle
var tiles: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	if on_complete_path != "":
		on_complete = get_node(on_complete_path)
	instance = get_node(instance_path)

	# TODO: load puzzle state from saved game
	
	# Initialise tiles and current_state
	for x in range(puzzle[PuzzleClasses.WIDTH]):
		tiles.append([])
		current_state.append([])
		for _y in range(puzzle[PuzzleClasses.HEIGHT]):
			tiles[x].append(null)
			current_state[x].append(0)
	
	# Load puzzles that should always be active
	if load_on_start: load_solved()

# Loads the puzzle with no animation
func load_solved():
	# Loop over columns in puzzle
	for x in range(puzzle[PuzzleClasses.WIDTH]):
		# Loop over cells in column
		for y in range(puzzle[PuzzleClasses.HEIGHT]):

			if puzzle[PuzzleClasses.CELLS][x][y] != null and puzzle[PuzzleClasses.CELLS][x][y][0] == PuzzleClasses.NONE: continue

			# Create new tile
			var tile = create_tile(x, y, puzzle[PuzzleClasses.CELLS][x][y])
			# Rotate to match puzzle state
			tile.rotate(Vector3.FORWARD, current_state[x][y] * PI / 2)
			# Add reference to tile to tiles
			tiles[x][y] = tile
			# Add tile to scene tree
			add_child(tile)

# Loads the puzzle with animation
func load_puzzle():
	loading_tiles_progress = 0
	unloading_tiles_progress = -1

# Unloads the puzzle with animation
func unload_puzzle():
	unloading_tiles_progress = 0
	loading_tiles_progress = -1

# Creates a new puzzle cell object
func create_tile(x: int, y: int, cell) -> PuzzleTile:
	# Create new instance of templaterotations
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
	
	node.get_node(node.rotation_indicator_path).rotate(Vector3.DOWN, current_state[x][y] * PI / 2)

	# Get the node's icon plane
	var icon: CSGMesh = node.get_node(node.icon_path)
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
			if tile != null:
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
			if tile != null:
				tile.set_colour(colour_base, colour_hover)
	
	if solution.is_correct:
		# Set cells to colour on completion
		for column in tiles:
			for tile in column:
				if tile != null:
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
# Handles the puzzle's load and unload animations
func _process(delta):
	# If load animation playing
	if loading_tiles_progress != -1:
		loading_tiles_progress += delta
		# Update rotation + scale of every tile
		for x in range(puzzle[PuzzleClasses.WIDTH]):
			for y in range(puzzle[PuzzleClasses.HEIGHT]):

				if puzzle[PuzzleClasses.CELLS][x][y] != null and puzzle[PuzzleClasses.CELLS][x][y][0] == PuzzleClasses.NONE: continue

				# If the tile is not loaded, load it
				if tiles[x][y] == null:
					# Create tile
					var tile = create_tile(x, y, puzzle[PuzzleClasses.CELLS][x][y])
					# Set the tile's scale to 0
					tile.scale = Vector3(0, 0, 0)
					# Add reference to tile to tiles
					tiles[x][y] = tile
					# Add tile to scene tree
					add_child(tile)
				
				# If animation for this tile has finished
				if loading_tiles_progress > (x + y) * tile_animation_offset + tile_animation_time:
					# Clear rotation
					tiles[x][y].set_rotation(Vector3(0, 0, 0))
					# Reset scale
					tiles[x][y].scale = Vector3(1, 1, 1)
				# If animation for this tile is still going
				elif loading_tiles_progress > (x + y) * tile_animation_offset:
					# Calculate how long this tile has been animating for
					var animation_time := loading_tiles_progress - (x + y) * tile_animation_offset
					# Calculate what proportion of the animation has been completed
					var animation_proportion := animation_time / tile_animation_time
					# Calculate tile's rotation
					var rotation := -(1 - animation_proportion) * PI

					# Clear tile's rotation
					tiles[x][y].set_rotation(Vector3(0, 0, 0))
					# Rotate for animation
					tiles[x][y].rotate(Vector3.RIGHT, rotation)

					# Set tile's scale
					tiles[x][y].scale = Vector3(animation_proportion, animation_proportion, animation_proportion)
		
		# If whole animation is finished, stop checking tiles
		if loading_tiles_progress > (puzzle[PuzzleClasses.WIDTH] + puzzle[PuzzleClasses.HEIGHT]) * tile_animation_offset + tile_animation_time:
			loading_tiles_progress = -1

	# If unload animation is playing
	elif unloading_tiles_progress != -1:
		unloading_tiles_progress += delta
		# Update rotation + scale of every tile
		for x in range(puzzle[PuzzleClasses.WIDTH]):
			for y in range(puzzle[PuzzleClasses.HEIGHT]):
				# Don't try to operate on non-existant tiles
				if tiles[x][y] == null: continue
				# If animation for this tile is finished, unload tile
				if unloading_tiles_progress > (x + y) * tile_animation_offset + tile_animation_time:
					remove_child(tiles[x][y])
					tiles[x][y] = null
				# If animation for this tile is still going
				elif unloading_tiles_progress > (x + y) * tile_animation_offset:
					# Calculate how long this tile has been animating for
					var animation_time := unloading_tiles_progress - (x + y) * tile_animation_offset
					# Calculate what proportion of the animation has been completed
					var animation_proportion := 1 - animation_time / tile_animation_time
					# Calculate tile's rotation
					var rotation := -(1 - animation_proportion) * PI

					# Clear tile's rotation
					tiles[x][y].set_rotation(Vector3(0, 0, 0))
					# Rotate for animation
					tiles[x][y].rotate(Vector3.RIGHT, rotation)

					# Set tile's scale
					tiles[x][y].scale = Vector3(animation_proportion, animation_proportion, animation_proportion)
		# If whole animation is finished, stop checking tiles
		if unloading_tiles_progress > (puzzle[PuzzleClasses.WIDTH] + puzzle[PuzzleClasses.HEIGHT]) * tile_animation_offset + tile_animation_time:
			unloading_tiles_progress = -1


# Callbacks for if this object is used as a PuzzleResponse
func on_puzzle_solve(_i: int):
	load_puzzle()

func on_puzzle_unsolve(_i: int):
	if on_complete != null:
		on_complete.on_puzzle_unsolve(on_complete_param)
	unload_puzzle()
