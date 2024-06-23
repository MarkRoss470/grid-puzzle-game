@icon("res://textures/UI/puzzle icon.svg")
extends Puzzle

class_name SymbolPuzzle

# The regions of the current state
var regions: Array[SolutionChecker.Region]
# The laser paths of the current state
var laser_paths: Array[SolutionChecker.LaserPath]

func _ready():
	super._ready()
	
	check_state()

func rotate_cell(x: int, y: int, direction: int):
	super.rotate_cell(x, y, direction)
	
	var is_solved = check_state()
	
	if is_solved:
		solve_puzzle()
	else:
		unsolve_puzzle()

func check_for_flashes(solution: SolutionChecker.Solution):
	# Flash squares in regions which have changed
	for previous_region in regions:
		# Whether the region has changed (there is an exact match for it in the new state)
		var matches := false

		for current_region in solution.regions:
			if previous_region.equals(current_region):
				matches = true
				break

		# Loop over all cells in the region
		for x in len(tiles):
			for y in len(tiles[x]):
				if previous_region.contains_cell(x * 2, y * 2):
					var icon_design: PuzzleDesignIcon = puzzle_design.icons[x][y]

					match icon_design.icon:
						PuzzleClasses.SQUARE:
							# If the region has changed, flash the square
							if !matches:
								tiles[x][y].flash(PuzzleClasses.COLOURS[icon_design.colour].lerp(Color.GRAY, 0.5), 0.5)
							# Else, stop the square from flashing
							else:
								tiles[x][y].end_flash()
	
	regions = solution.regions

	for previous_path in laser_paths:
		var matches := false
		
		for current_path in solution.laser_paths:
			if previous_path.equals(current_path):
				matches = true
				break
		
		var x = previous_path.path[0][0]
		var y = previous_path.path[0][1]
		
		var icon_design: PuzzleDesignIcon = puzzle_design.icons[x][y]
		
		if !matches:
			tiles[x][y].flash(PuzzleClasses.COLOURS[icon_design.colour].lerp(Color.GRAY, 0.5), 0.5)
		else:
			tiles[x][y].end_flash()
	
	laser_paths = solution.laser_paths

# Checks whether the puzzle is solved.
# Also checks changes in square and laser states and triggers flashes.
func check_state() -> bool:
	# Check whether the solution is valid
	var solution := SolutionChecker.check_solution(puzzle_design, current_state)
	
	check_for_flashes(solution)
	
	reset_tile_colours()
	
#	print("[")
#	for path in solution.laser_paths:
#		print("    ", path.path, ",")
#	print("]")
	
	return solution.is_valid

func reset():
	super.reset()
	
	# Call check_state twice. The first call will update `regions` and `laser_paths`
	check_state()
	# The second call will cancel all the icon flashes.
	check_state()
