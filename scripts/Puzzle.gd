extends Node3D

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
@export var puzzle: Array
# Whether the states between the start and end states need to be valid
@export var check_intermediate: bool

# Colours for puzzle's neutral state
@export var colour_base: Color = Color(0.5, 0.5, 0.5)
@export var colour_hover: Color = Color(0.8, 0.8, 0.8)
# Colours for the key cell's neutral state
@export var colour_key: Color = Color(0.7, 0.8, 0.1)
@export var colour_key_hover: Color = Color(1, 1, 0.0)

# Colours for an incorrect solution
@export var colour_incorrect_base: Color = Color(1, 0, 0)
@export var colour_incorrect_hover: Color = Color(1, 0.5, 0.5)
# Colours for an incorrect solution on the key cell
@export var colour_incorrect_key: Color = Color(0.9, 0.55, 0.05)
@export var colour_incorrect_key_hover: Color = Color(0.95, 0.75, 0.4)

# Colours for a correct solution
@export var colour_solved_base: Color = Color(0, 1, 0)
@export var colour_solved_hover: Color = Color(0.5, 1, 0.5)
# Colours for a correct solution on the key cell
@export var colour_solved_key: Color = Color(0.15, 0.1, 0.9)
@export var colour_solved_key_hover: Color = Color(0.3, 0.30, 0.85)

# What object to instance as a tile
@export var instance_path: NodePath
var instance: Node
# What object to call the on_puzzle_solve method of when the puzle is solved
@export var on_complete_path: NodePath
var on_complete: Node = null
# What parameter to pass to on_puzzle_solve
@export var on_complete_param: int
# Whether to load the puzzle immediately on startup
@export var load_on_start: bool = true

# How long each tile's animation should take
@export var tile_animation_time := 0.5
# The offset between tiles' animations
@export var tile_animation_offset := 0.1

# An array of all the tile load / unloads occuring
# Each item is of the format [direction, progress] 
var wipes := []

# Array[x][y] of the direction of cells
# 0 = up, 1 = right etc
var current_state: Array
# Whether the puzzle is solved and the solved colours should be used
var is_solved := false
# Stores references to the PuzzleTile nodes of this puzzle
var tiles: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	if not on_complete_path.is_empty():
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

func add_wipe(direction: int, timeout: float):
	if len(wipes) != 0:
		var last_wipe_time = wipes[-1][1]
		var last_wipe_direction = wipes[-1][0]
		
		# If this wipe is less than tile_animation_time seconds after the wipe before it,
		# delay it to make it so that animation issues don't occur
		# - not + in this calculation because time counts up, so to get a future time you subtract
		if timeout > last_wipe_time - tile_animation_time:
			timeout = last_wipe_time - tile_animation_time
		
		# Don't add a wipe if it has the same direction as the one before it
		if direction == last_wipe_direction:
			return
		
	wipes.append([direction, timeout])

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

# Resets the puzzle
func reset():
	# Don't reset if there are wipes ongoing
	# This prevents a reset from being queued during another wipe, 
	# leading to the puzzle spending a long time animating
	if len(wipes) != 0:
		return
	
	# Reset tiles and current state
	for x in puzzle[PuzzleClasses.WIDTH]:
		for y in puzzle[PuzzleClasses.HEIGHT]:
			current_state[x][y] = puzzle[PuzzleClasses.CELLS][x][y][PuzzleClasses.ROTATION]
	
	is_solved = false
	
	# Call puzzle unsolve callback
	if on_complete != null:
		on_complete.on_puzzle_unsolve(on_complete_param)
	
	add_wipe(-1, 0)
	add_wipe(1, -tile_animation_time)

# Loads the puzzle with animation
func load_puzzle():
	add_wipe(1, 0)
	
	if is_solved:
		solve_puzzle()

# Unloads the puzzle with animation
func unload_puzzle():
	add_wipe(-1, 0)

# Creates a new puzzle cell object
func create_tile(x: int, y: int, cell) -> PuzzleTile:
	# Create new instance of template
	var node: PuzzleTile = instance.duplicate()
	
	node.name = self.name + "-" + str(x) + "-" + str(y)
	
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
	var icon: CSGMesh3D = node.get_node(node.icon_path)
	# If the puzzle cell has an icon, set the right image
	if cell[PuzzleClasses.ICON] != PuzzleClasses.EMPTY:
		# Make copy of material
		var mat_override := icon.get_material().duplicate()
		# Set texture
		mat_override.set_shader_parameter("icon_texture", PuzzleClasses.CELL_TEXTURES[cell[0]])
		# Set colour
		mat_override.set_shader_parameter("icon_colour", PuzzleClasses.COLOURS[cell[1]])
		# Set icon to use this material
		icon.set_material_override(mat_override)
	# If the puzzle cell has no icon, hide the icon plane
	else:
		icon.set_visible(false)
	
	return node

# Called by a cell when it is clicked
# direction = 1 -> clockwise
# direction = -1 -> anti-clockwise
func rotate_cell(x: int, y: int, direction: int):
	var prev_rotation = current_state[x][y]
	
	# Add one to cell's rotation
	current_state[x][y] += (4 + direction)
	# Wrap around to 0 if reaches 4
	current_state[x][y] %= 4
	
	# Check whether the solution is valid
	var solution := SolutionChecker.check_solution(puzzle, current_state)
	
	# If intermediate states must be valid, block the move if they aren't 
	if check_intermediate:
		if not solution.is_valid:
			# Set cells to colour on incorrect solution
			for cell in solution.wrong_cells:
				if check_intermediate and cell == [puzzle[PuzzleClasses.KEY_X], puzzle[PuzzleClasses.KEY_Y]]:
					tiles[cell[0]][cell[1]].set_colour(colour_incorrect_key, colour_incorrect_key_hover)
				else:
					tiles[cell[0]][cell[1]].set_colour(colour_incorrect_base, colour_incorrect_hover)
			
			current_state[x][y] = prev_rotation
			
			return
		
		# Check whether the key cell is in the right rotation
		var key_x = puzzle[PuzzleClasses.KEY_X]
		var key_y = puzzle[PuzzleClasses.KEY_Y]
		var key_rotation = current_state[key_x][key_y]
		var target_rotation = puzzle[PuzzleClasses.KEY_TARGET_ROTATION]
		
		is_solved = key_rotation == target_rotation
	# If intermediate states don't need to be valid, then any valid state is a solution
	else:
		is_solved = solution.is_valid
	
	# Physically rotate this cell
	tiles[x][y].icon.rotate(Vector3.FORWARD, direction * PI / 2)
	
	if is_solved:
		solve_puzzle()
	else:
		# Call puzzle unsolve callback
		if on_complete != null:
			on_complete.on_puzzle_unsolve(on_complete_param)
		reset_tile_colours()

func solve_puzzle():
	is_solved = true
	
	# This will use the solved colours because is_solved is true
	reset_tile_colours()
	
	# Call puzzle solve callback
	if on_complete != null:
		on_complete.on_puzzle_solve(on_complete_param)

# Called every frame. 'delta' is the elapsed time since the previous frame.
# Handles the puzzle's load and unload animations
func _process(delta):
	# The index of a completed wipe, if there is one
	var completed_wipe = -1
	
	for i in len(wipes):
		# 1 if load, -1 if unload
		var direction = wipes[i][0]
		var prev_progress = wipes[i][1]
		var progress = prev_progress + delta
		wipes[i][1] = progress
		
		# Update rotation + scale of every tile
		for x in puzzle[PuzzleClasses.WIDTH]:
			for y in puzzle[PuzzleClasses.HEIGHT]:
				
				var tile_animation_start = (x + y) * tile_animation_offset
				var tile_animation_end = (x + y) * tile_animation_offset + tile_animation_time
				
				if prev_progress > tile_animation_end or progress < tile_animation_start:
					continue
				
				var tile = tiles[x][y]
				
				if tile == null:
					# If the tile is already null, don't load it just to unload it
					if direction == -1:
						continue
					
					# Create tile
					tile = create_tile(x, y, puzzle[PuzzleClasses.CELLS][x][y])
					# Add reference to tile to tiles
					tiles[x][y] = tile
					
					# Add tile to scene tree
					add_child(tile)
				
				# If this is the last frame of animation for the tile, set it to the finishing position
				if progress > tile_animation_end and tile_animation_end > prev_progress:
					# If this wipe is an unload, unload the tile
					if direction == -1:
						remove_child(tiles[x][y])
						tiles[x][y] = null
					# If this wipe is a load, set the tile to the right rotation and scale
					else:
						# Clear rotation
						tiles[x][y].set_rotation(Vector3(0, 0, 0))
						# Rotate to match puzzle state
						tiles[x][y].rotate(Vector3.FORWARD, current_state[x][y] * PI / 2)
						# Reset scale
						tiles[x][y].scale = Vector3(1, 1, 1)
					continue
				
				# How long this tile has been animating for
				var animation_time: float = progress - (x + y) * tile_animation_offset
				# What proportion of the animation has been completed
				var animation_proportion := animation_time / tile_animation_time
				
				if direction == -1:
					animation_proportion = 1 - animation_proportion
				
				# The tile's rotation
				var rotation := -(1 - animation_proportion) * PI

				# Clear tile's rotation
				tiles[x][y].set_rotation(Vector3(0, 0, 0))
				# Rotate to match puzzle state
				tiles[x][y].rotate(Vector3.FORWARD, current_state[x][y] * PI / 2)
				# Rotate for animation
				tiles[x][y].rotate(Vector3.RIGHT, rotation)

				# Set tile's scale
				tiles[x][y].scale = Vector3(animation_proportion, animation_proportion, animation_proportion)
	
		# If this wipe is finished, save its index
		if progress > (puzzle[PuzzleClasses.WIDTH] + puzzle[PuzzleClasses.HEIGHT]) * tile_animation_offset + tile_animation_time:
			completed_wipe = i
	
	if completed_wipe != -1:
		wipes.remove_at(completed_wipe)
	
	if len(wipes) > 0:
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
	for column in tiles:
		for tile in column:
			if tile != null:
				if is_solved:
					tile.set_colour(colour_solved_base, colour_solved_hover)
				else:
					tile.set_colour(colour_base, colour_hover)
	
	if check_intermediate:
		var key_x = puzzle[PuzzleClasses.KEY_X]
		var key_y = puzzle[PuzzleClasses.KEY_Y]
		var key_tile = tiles[key_x][key_y]
		if key_tile != null:
			if is_solved:
				key_tile.set_colour(colour_solved_key, colour_solved_key_hover)
			else:
				key_tile.set_colour(colour_key, colour_key_hover)
