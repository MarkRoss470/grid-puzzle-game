extends SymbolPuzzle


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()

# Checks whether the puzzle is solved.
# Also checks changes in square and laser states and triggers flashes.
func check_state() -> bool:
	print("Checking state")
	
	# Check whether the solution is valid
	var solution := SolutionChecker.check_solution(puzzle_design, current_state)
	
	check_for_flashes(solution)
	
	reset_tile_colours()
	
	for path in laser_paths:
		var path_end_coord := path.path[-1]
		var path_end_icon: PuzzleDesignIcon = puzzle_design.icons[path_end_coord.x][path_end_coord.y]
		if path_end_icon.icon == PuzzleClasses.LASER_RECEIVER:
			on_complete_param = current_state[path_end_coord.x][path_end_coord.y]
	
#	print("[")
#	for path in solution.laser_paths:
#		print("    ", path.path, ",")
#	print("]")
	
	return solution.is_valid
