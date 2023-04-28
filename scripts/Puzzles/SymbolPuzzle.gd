@icon("res://textures/UI/puzzle icon.svg")
extends Puzzle

class_name SymbolPuzzle

func rotate_cell(x: int, y: int, direction: int):
	super.rotate_cell(x, y, direction)
	
	# Check whether the solution is valid
	var solution := SolutionChecker.check_solution(puzzle, current_state)
	
	reset_tile_colours()
	
	if solution.is_valid:
		solve_puzzle()
	else:
		unsolve_puzzle()
