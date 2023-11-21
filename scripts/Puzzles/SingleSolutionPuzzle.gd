extends Puzzle

class_name SingleSolutionPuzzle

@export var solution: Array = []

func on_puzzle_solve_immediate(i: int):
	super.on_puzzle_solve_immediate(i)
	
	if is_solved:
		solve_puzzle()

func solve_puzzle():
	super.solve_puzzle()
	
	for x in puzzle_design.width:
		for y in puzzle_design.height:
			if tiles[x][y] != null:
				tiles[x][y].flash(colour_solved_base, INF)

func unsolve_puzzle():
	super.unsolve_puzzle()
	
	for x in puzzle_design.width:
		for y in puzzle_design.height:
			if tiles[x][y] != null:
				tiles[x][y].end_flash()

func rotate_cell(cell_x: int, cell_y: int, direction: int) -> bool:
	# If super.rotate_cell fails, return false immediately
	if not super.rotate_cell(cell_x, cell_y, direction):
		return false
	
	var is_correct := true
	
	var cells: Array = puzzle_design.icons
	
	for x in puzzle_design.width:
		for y in puzzle_design.height:
			match cells[x][y].icon:
				PuzzleClasses.NO_CELL, PuzzleClasses.EMPTY, PuzzleClasses.POINTER_QUADRUPLE:
					continue
				PuzzleClasses.POINTER_SINGLE, PuzzleClasses.POINTER_DOUBLE_ANGLE, PuzzleClasses.POINTER_TRIPLE:
					if solution[x][y] != current_state[x][y]:
						is_correct = false
						break
				PuzzleClasses.POINTER_DOUBLE_STRAIGHT:
					if solution[x][y] % 2 != current_state[x][y] % 2:
						is_correct = false
						break
					
		if not is_correct:
			break
	
	if is_correct:
		solve_puzzle()
	else:
		unsolve_puzzle()
	
	return true
