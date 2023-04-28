@icon("res://textures/UI/key puzzle icon.svg")
extends Puzzle
class_name KeyPuzzle

@export var key_x := 0
@export var key_y := 0
@export var key_target_rotation := 0

func reset_tile_colours():
	super.reset_tile_colours()
	
	var key_tile = tiles[key_x][key_y]
	if key_tile != null:
		if is_solved:
			key_tile.set_colour(colour_solved_key, colour_solved_key_hover)
		else:
			key_tile.set_colour(colour_key, colour_key_hover)


func rotate_cell(x: int, y: int, direction: int):
	super.rotate_cell(x, y, direction)
	
	# Check whether the solution is valid
	var solution := SolutionChecker.check_solution(puzzle, current_state)
	
	reset_tile_colours()
	
	if not solution.is_valid:
		# Undo the rotation as it's not valid
		super.rotate_cell(x, y, -direction)
		
		# Set cells to colour on incorrect solution
		for cell in solution.wrong_cells:
			if cell == [key_x, key_y]:
				tiles[cell[0]][cell[1]].set_colour(colour_incorrect_key, colour_incorrect_key_hover)
			else:
				tiles[cell[0]][cell[1]].set_colour(colour_incorrect_base, colour_incorrect_hover)
		
		return
	
	var key_rotation = current_state[key_x][key_y]
	
	if key_rotation == key_target_rotation:
		solve_puzzle()
	else:
		unsolve_puzzle()
