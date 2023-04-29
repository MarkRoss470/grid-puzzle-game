@icon("res://textures/UI/key puzzle icon.svg")
extends Puzzle
class_name KeyPuzzle

@export var key_x := 0
@export var key_y := 0
@export var key_target_rotation := 0

@export var highlight_wrong_cells := true

@export var key_hint_tile: CSGMesh3D

@export_group("Colours")

@export var key_hint_colour := Color(1.0, 1.0, 1.0)
@export var colour_incorrect_base: Color = Color(1, 0, 0)
@export var colour_incorrect_hover: Color = Color(1, 0.5, 0.5)

func _ready():
	super._ready()

func create_tile(x: int, y: int, cell) -> PuzzleTile:
	var tile := super.create_tile(x, y, cell)
	
	# If this cell is the key cell, add lines to show the target rotation
	if x == key_x and y == key_y:
		# Create new instance of template
		var key_hint := key_hint_tile.duplicate()
		key_hint.name = "key-hint-tile"
		var key_start_rotation = puzzle[PuzzleClasses.CELLS][key_x][key_y][PuzzleClasses.ROTATION]
		key_hint.rotate(Vector3.FORWARD, (key_target_rotation - key_start_rotation) * PI / 2)
		
		# Make the node visible
		key_hint.set_visible(true)
		
		# Make copy of material
		var mat_override: Material = key_hint.get_material().duplicate()
		
		# Set texture
		var key_icon = puzzle[PuzzleClasses.CELLS][key_x][key_y][0]
		mat_override.set_shader_parameter("icon_texture", PuzzleClasses.HINT_TEXTURES[key_icon])
		# Set colour
		mat_override.set_shader_parameter("icon_colour", key_hint_colour)
		# Set icon to use this material
		key_hint.set_material_override(mat_override)
		
		tile.add_child(key_hint)
	
	return tile

func rotate_cell(x: int, y: int, direction: int):
	super.rotate_cell(x, y, direction)
	
	# Check whether the solution is valid
	var solution := SolutionChecker.check_solution(puzzle, current_state)
	
	reset_tile_colours()
	
	if not solution.is_valid:
		# Undo the rotation as it's not valid
		super.rotate_cell(x, y, -direction)
		
		if highlight_wrong_cells:
			# Set cells to colour on incorrect solution
			for cell in solution.wrong_cells:
				tiles[cell[0]][cell[1]].set_colour(colour_incorrect_base, colour_incorrect_hover)
		
		return
	
	var key_rotation = current_state[key_x][key_y]
	
	var is_right_rotation: bool
	
	# Straight double pointers have 180 degree rotational symmetry,
	# so they should register as solved when upside-down
	if puzzle[PuzzleClasses.CELLS][key_x][key_y][PuzzleClasses.ICON] == PuzzleClasses.POINTER_DOUBLE_STRAIGHT:
		is_right_rotation = (key_rotation % 2) == (key_target_rotation % 2)
	else:
		is_right_rotation = key_rotation == key_target_rotation
	
	if is_right_rotation:
		solve_puzzle()
	else:
		unsolve_puzzle()
