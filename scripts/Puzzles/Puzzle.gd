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


@export_group("Puzzle")

@export var puzzle_design := PuzzleDesign.new()

@export_group("")
# What object to instance as a tile
@export var instance: PuzzleTile
# What object to call the on_puzzle_solve method of when the puzle is solved
@export var on_complete: Node
# What parameter to pass to on_puzzle_solve
@export var on_complete_param: int
# Whether to load the puzzle immediately on startup
@export var load_on_start: bool = true

# How long each tile's animation should take
@export var tile_animation_time := 0.5
# The offset between tiles' animations
@export var tile_animation_offset := 0.1

@export_group("Colours")

# Colours for puzzle's neutral state
@export var colour_base: Color = Color(0.8, 0.8, 0.8)
@export var colour_hover: Color = Color(0.7, 0.7, 0.7)

# Colours for a correct solution
@export var colour_solved_base: Color = Color(0.6, 1, 0.6)
@export var colour_solved_hover: Color = Color(0.5, 1, 0.5)


# An array of all the tile load / unloads occuring
# Each item is of the format [direction, progress] 
var wipes := []
# The direction of a queued wipe
# 0 = no wipe queued
# 1 = load
# -1 = unload
var next_wipe_direction := 0
# The direction of the most recent wipe, or the next one queued
# This is used to prevent load wipes when the puzzle is already loaded
var last_wipe_direction := -1

# Array[x][y] of the direction of cells
# 0 = up, 1 = right etc
var current_state: Array[Array]
# Whether the puzzle is solved and the solved colours should be used
var is_solved := false
# Stores references to the PuzzleTile nodes of this puzzle
var tiles: Array[Array]

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: load puzzle state from saved game
	
	self.add_to_group("puzzles")
	self.add_to_group("savable")
	
	# Initialise tiles and current_state
	for x in puzzle_design.width:
		tiles.append([])
		current_state.append([])
		for y in puzzle_design.height:
			tiles[x].append(null)
			current_state[x].append(puzzle_design.icons[x][y].rotation)
	
	# Load puzzles that should always be active
	if load_on_start: on_puzzle_solve_immediate(0)

func add_wipe(direction: int):
	last_wipe_direction = direction
	
	if len(wipes) == 0 or wipes[-1][1] > tile_animation_time:
		wipes.append([direction, 0.0])
	else:
		next_wipe_direction = direction

# Loads the puzzle with animation
func load_puzzle():
	# Don't load the puzzle if it's already loaded
	if last_wipe_direction != 1:
		add_wipe(1)
	
	if is_solved:
		solve_puzzle()

# Unloads the puzzle with animation
func unload_puzzle():
	# Don't unload the puzzle if it's already not loaded
	if last_wipe_direction != -1:
		add_wipe(-1)

# Loads the puzzle with no animation
func on_puzzle_solve_immediate(_i: int):
	# Loop over columns in puzzle
	for x in puzzle_design.width:
		# Loop over cells in column
		for y in puzzle_design.height:
			if puzzle_design.icons[x][y].icon == PuzzleClasses.NO_CELL:
				continue

			# Create new tile
			var tile = create_tile(x, y, puzzle_design.icons[x][y])
			# Rotate to match puzzle state
			tile.rotate(Vector3.FORWARD, current_state[x][y] * PI / 2)
			# Add reference to tile to tiles
			tiles[x][y] = tile
			# Add tile to scene tree
			add_child(tile)
	
	last_wipe_direction = 1
	reset_tile_colours()

# Called by a cell when it is clicked
# direction = 1 -> clockwise
# direction = -1 -> anti-clockwise

# Returns true if the rotation was successful, false if not
func rotate_cell(x: int, y: int, direction: int) -> bool:
	
	# Only icons in the ROTATABLE list should be able to be rotated
	if not puzzle_design.icons[x][y].icon in PuzzleClasses.ROTATABLE:
		return false
	
	# Update cell's rotation based on the direction
	# Add extra 4 to get around behaviour of % operator for negative numbers
	current_state[x][y] += (4 + direction)
	# Wrap around to 0 if reaches 4
	current_state[x][y] %= 4
	
	# Physically rotate this cell
	tiles[x][y].icon.rotate(Vector3.FORWARD, direction * PI / 2)
	
	return true

# Sets is_solved to true and calls the next puzzle's on_puzzle_solve callback
func solve_puzzle():
	is_solved = true
	
	# This will use the solved colours because is_solved is true
	reset_tile_colours()
	
	# Call puzzle solve callback
	if on_complete != null:
		on_complete.on_puzzle_solve(on_complete_param)

func unsolve_puzzle():
	is_solved = false
	
	# This will use the unsolved colours because is_solved is false
	reset_tile_colours()
	
	# Call puzzle solve callback
	if on_complete != null:
		on_complete.on_puzzle_unsolve(on_complete_param)

# Resets the puzzle
func reset():
	# Don't reset if there are wipes ongoing
	# This prevents a reset from being queued during another wipe, 
	# leading to the puzzle spending a long time animating
	if len(wipes) != 0:
		return
	
	# Reset tiles and current state
	for x in puzzle_design.width:
		for y in puzzle_design.height:
			current_state[x][y] = puzzle_design.icons[x][y].rotation
	
	is_solved = false
	
	# Call puzzle unsolve callback
	if on_complete != null:
		on_complete.on_puzzle_unsolve(on_complete_param)
	
	add_wipe(-1)
	add_wipe(1)

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
	if cell.icon != PuzzleClasses.EMPTY:
		# Make copy of material
		var mat_override := icon.get_material().duplicate()
		mat_override.next_pass = mat_override.next_pass.duplicate()
		
		# Set texture
		mat_override.next_pass.set_shader_parameter("icon_texture", PuzzleClasses.CELL_TEXTURES[cell.icon])
		# Set colour
		mat_override.next_pass.set_shader_parameter("icon_colour", PuzzleClasses.COLOURS[cell.colour])
		# Set icon to use this material
		icon.set_material_override(mat_override)
	# If the puzzle cell has no icon, hide the icon plane
	else:
		icon.set_visible(false)
	
	return node

# Set all the cells to their base colour
# Stops a puzzle from looking solved when it's not
func reset_tile_colours():
	# Reset the cells to the base colour
	for column in tiles:
		for tile in column:
			if tile != null:
				if is_solved:
					tile.set_colour(colour_solved_base, colour_solved_hover)
				else:
					tile.set_colour(colour_base, colour_hover)

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
		for x in puzzle_design.width:
			for y in puzzle_design.height:
				
				var tile_animation_start = (x + y) * tile_animation_offset
				var tile_animation_end = (x + y) * tile_animation_offset + tile_animation_time
				
				if prev_progress > tile_animation_end or progress < tile_animation_start:
					continue
				
				var tile = tiles[x][y]
				
				if tile == null:
					# If the tile is already null, don't load it just to unload it
					# Also don't load NO_CELL tiles
					var cell: PuzzleDesignIcon = puzzle_design.icons[x][y]
					if direction == -1 or cell.icon == PuzzleClasses.NO_CELL:
						continue
					
					# Create tile
					tile = create_tile(x, y, cell)
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
		if progress > (puzzle_design.width + puzzle_design.height) * tile_animation_offset + tile_animation_time:
			completed_wipe = i
	
	if completed_wipe != -1:
		wipes.remove_at(completed_wipe)

	if len(wipes) != 0 and wipes[-1][1] > tile_animation_time and next_wipe_direction != 0:
		wipes.append([next_wipe_direction, 0])
		next_wipe_direction = 0
	
	if len(wipes) > 0:
		reset_tile_colours()

# Callbacks for if this object is used as a PuzzleResponse
func on_puzzle_solve(_i: int):
	load_puzzle()

func on_puzzle_unsolve(_i: int):
	pass
