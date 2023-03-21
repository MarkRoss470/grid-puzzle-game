extends Spatial

class_name Puzzle

"""
represents the puzzle - sets which icons go in which cells
[
	width, height,
	key_x, key_y, # The x and y positions of the key cell
	[[PuzzleCell or null; width]; height], # The cells' symbols
	target_rotation, # The target rotation of the key cell
]
"""
export(Array) var puzzle
# Colours for puzzle's neutral state
export(Color) var colour_base = Color(0.5, 0.5, 0.5)
export(Color) var colour_hover = Color(0.8, 0.8, 0.8)
# Colours for the key cell's neutral state
export(Color) var key_colour_base = Color(0.7, 0.8, 0.1)
export(Color) var key_colour_hover = Color(1, 1, 0.0)
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
export(float) var tile_animation_time := 1.0
# The offset between tiles' animations
export(float) var tile_animation_offset := 0.2
# Variables to keep track of animations
var loading_tiles_progress := -1.0
var unloading_tiles_progress := -1.0

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
	for x in puzzle[PuzzleClasses.WIDTH]:
		tiles.append([])
		current_state.append([])
		for y in puzzle[PuzzleClasses.HEIGHT]:
			tiles[x].append(null)
			current_state[x].append(puzzle[PuzzleClasses.CELLS][x][y][PuzzleClasses.ROTATION])
	
	# Load puzzles that should always be active
	if load_on_start: load_solved()

# Loads the puzzle with no animation
func load_solved():
	# Loop over columns in puzzle
	for x in puzzle[PuzzleClasses.WIDTH]:
		# Loop over cells in column
		for y in puzzle[PuzzleClasses.HEIGHT]:
			if puzzle[PuzzleClasses.CELLS][x][y][PuzzleClasses.ICON] == PuzzleClasses.NO_CELL:
				continue

			# Create new tile
			var tile = create_tile(x, y, puzzle[PuzzleClasses.CELLS][x][y])
			# Rotate to match puzzle state
			tile.rotate(Vector3.FORWARD, current_state[x][y] * PI / 2)
			# Add reference to tile to tiles
			tiles[x][y] = tile
			# Add tile to scene tree
			add_child(tile)
	reset_tile_colours()

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
	var icon: CSGMesh = node.get_node(node.icon_path)
	# If the puzzle cell has an icon, set the right image
	if cell[PuzzleClasses.ICON] != PuzzleClasses.EMPTY:
		# Make copy of material
		var mat_override := icon.get_material().duplicate()
		# Set texture
		mat_override.set_shader_param("icon_texture", PuzzleClasses.CELL_TEXTURES[cell[0]])
		# Set colour
		mat_override.set_shader_param("icon_colour", PuzzleClasses.COLOURS[cell[1]])
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
	
	var solution := SolutionChecker.check_solution(puzzle, current_state)
	
	if not solution.is_valid:
		# Set cells to colour on incorrect solution
		for cell in solution.wrong_cells:
			tiles[cell[0]][cell[1]].set_colour(colour_incorrect_base, colour_incorrect_hover)
		
		# Undo the rotation
		current_state[x][y] -= 1
		# Wrap around to 3 if reaches -1
		current_state[x][y] %= 4
		
		return
	
	# Physically rotate this cell
	tiles[x][y].icon.rotate(Vector3.DOWN, PI / 2)
	
	if solution.is_solved:
		solve_puzzle()
	else:
		# Call puzzle unsolve callback
		if on_complete != null:
			on_complete.on_puzzle_unsolve(on_complete_param)
	
	reset_tile_colours()

func solve_puzzle():
	# Set cells to colour on completion
	for column in tiles:
		for tile in column:
			if tile != null:
				tile.set_colour(colour_solved_base, colour_solved_hover)
	# Call puzzle unsolve callback
	if on_complete != null:
		on_complete.on_puzzle_solve(on_complete_param)

# Called every frame. 'delta' is the elapsed time since the previous frame.
# Handles the puzzle's load and unload animations
func _process(delta):
	var animating := false
	
	# If load animation playing
	if loading_tiles_progress != -1:
		animating = true
		
		loading_tiles_progress += delta
		# Update rotation + scale of every tile
		for x in puzzle[PuzzleClasses.WIDTH]:
			for y in puzzle[PuzzleClasses.HEIGHT]:
				
				# If there is no cell, don't create a tile
				if puzzle[PuzzleClasses.CELLS][x][y][PuzzleClasses.ICON] == PuzzleClasses.NO_CELL: continue
				
				# If animation for this tile has finished
				if loading_tiles_progress > (x + y) * tile_animation_offset + tile_animation_time:
					# Clear rotation
					tiles[x][y].set_rotation(Vector3(0, 0, 0))
					# Reset scale
					tiles[x][y].scale = Vector3(1, 1, 1)
				# If animation for this tile is still going
				elif loading_tiles_progress > (x + y) * tile_animation_offset:
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

					# Calculate how long this tile has been animating for
					var animation_time: float = loading_tiles_progress - (x + y) * tile_animation_offset
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
		animating = true
		
		unloading_tiles_progress += delta
		# Update rotation + scale of every tile
		for x in puzzle[PuzzleClasses.WIDTH]:
			for y in puzzle[PuzzleClasses.HEIGHT]:
				# Don't try to operate on non-existant tiles
				if tiles[x][y] == null: continue
				# If animation for this tile is finished, unload tile
				if unloading_tiles_progress > (x + y) * tile_animation_offset + tile_animation_time:
					remove_child(tiles[x][y])
					tiles[x][y] = null
				# If animation for this tile is still going
				elif unloading_tiles_progress > (x + y) * tile_animation_offset:
					# Calculate how long this tile has been animating for
					var animation_time: float = unloading_tiles_progress - (x + y) * tile_animation_offset
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
	
	if animating:
		reset_tile_colours()

# Callbacks for if this object is used as a PuzzleResponse
func on_puzzle_solve(_i: int):
	load_puzzle()

func on_puzzle_unsolve(_i: int):
	if on_complete != null:
		on_complete.on_puzzle_unsolve(on_complete_param)
	unload_puzzle()

# Set all the cells to their base colour
# Stops a puzzle from looking solved when it's not
func reset_tile_colours():
	# Initialise the cells to the base colour
	for x in puzzle[PuzzleClasses.WIDTH]:
		var column = tiles[x]
		for y in puzzle[PuzzleClasses.HEIGHT]:
			var tile = column[y]
			
			if tile == null: continue
			
			tile.set_colour(colour_base, colour_hover)
	
	var key_x = puzzle[PuzzleClasses.KEY_X]
	var key_y = puzzle[PuzzleClasses.KEY_Y]
	var key_tile = tiles[key_x][key_y]
	if key_tile != null:
		key_tile.set_colour(key_colour_base, key_colour_hover)
