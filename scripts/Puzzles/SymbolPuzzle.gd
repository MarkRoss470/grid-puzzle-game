@icon("res://textures/UI/puzzle icon.svg")
extends Puzzle

class_name SymbolPuzzle

# The regions of the current state
var regions: Array[SolutionChecker.Region]

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

# Checks whether the puzzle is solved and calls solve_puzzle or unsolve_puzzle respectively
func check_state() -> bool:
	# Check whether the solution is valid
	var solution := SolutionChecker.check_solution(puzzle_design, current_state)
	
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
	
	reset_tile_colours()
	
	return solution.is_valid
