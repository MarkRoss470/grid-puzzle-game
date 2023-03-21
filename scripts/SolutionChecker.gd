extends Node

class_name SolutionChecker

# Class representing a solution
class Solution:
	# Whether the solution is a valid puzzle state
	var is_valid: bool
	# Whether the puzzle is solved
	var is_solved: bool
	
	# An array of [x, y] coordinates of the cells which are wrong
	# This is not (necessarily) the cells which are in the wrong rotation
	# It's the cells whose rules are broken because of a cell in the wrong rotation
	var wrong_cells: Array
	
	# Simple constructor
	func _init():
		is_valid = true
		is_solved = false
		wrong_cells = []
	
	# Add a wrong cell at the given coordinates and set is_valid to false
	func add_wrong(x: int, y: int):
		is_valid = false
		wrong_cells.append([x, y])

# A region of the puzzle, delimited by pointers
class Region:
	# Which cells this array contains
	# A 2d array of bools, with dimensions twice the width and height of the puzzle
	# This is because each cell is divided into 4 when calculating regions
	var cells: Array
	
	# Creates a new region with the specified width and height.
	func _init(width: int, height: int):
		cells = []
		for x in width:
			cells.append([])
			for y in height:
				cells[x].append(false)
	
	# Gets whether the region contains the given cell
	func contains_cell(x: int, y: int) -> bool:
		return cells[x][y]
	
	# Adds the given cell to the region
	func add_cell(x: int, y: int):
		cells[x][y] = true
	
	# Gets whether all subcells are true
	func is_full() -> bool:
		for column in cells:
			for cell in column:
				if not cell:
					return false
		return true

	# Finds an subcell which is false and returns its x, y coordinates.
	# If none is found, returns an empty array
	func get_empty_cell() -> Array:
		for x in len(cells):
			for y in len(cells[x]):
				if not cells[x][y]:
					return [x, y]
		return []
		
	# Sets all the subcells to true in this Region which are true in another Region
	func fill_from(other: Region):
		for x in len(cells):
			for y in len(cells[x]):
				cells[x][y] = cells[x][y] or other.cells[x][y]
	
	# Recursively fill this region starting from the given coordinate, bounded by:
	# * true cells in `other`
	# * edges in `edges_horizontal` and `edges_vertical`
	func floodfill_from(other: Region, edges_horizontal: Array, edges_vertical: Array, x: int, y: int):
		cells[x][y] = true
		
		# Check cell to the left
		if not (x == 0 
			or edges_vertical[x][y] 
			or cells[x - 1][y]
			or other.cells[x - 1][y]
		):
			floodfill_from(other, edges_horizontal, edges_vertical, x - 1, y)
		
		# Check cell above
		if not (y == 0
			or edges_horizontal[x][y]
			or cells[x][y - 1]
			or other.cells[x][y - 1]
		):
			floodfill_from(other, edges_horizontal, edges_vertical, x, y - 1)
		
		# Check cell to the right
		if not (x == len(cells) - 1
			or edges_vertical[x + 1][y]
			or cells[x + 1][y]
			or other.cells[x + 1][y]
		):
			floodfill_from(other, edges_horizontal, edges_vertical, x + 1, y)
		
		# Check cell below
		if not (y == len(cells[0]) - 1
			or edges_horizontal[x][y + 1]
			or cells[x][y + 1]
			or other.cells[x][y + 1]
		):
			floodfill_from(other, edges_horizontal, edges_vertical, x, y + 1)
	
	# Prints a diagram representing the region
	func pretty_print():
		var lines := []
		
		for _y in len(cells[0]):
			lines.append("")
		
		for x in len(cells):
			for y in len(cells[x]):
				if cells[x][y]:
					lines[y] += "1"
				else:
					lines[y] += "0"
		
		for line in lines:
			print(line)
	
	# Whether a cell in this Region contains the given icon
	# Only checks the top-left subcell of each cell
	# Excludes the cell at the given coordinates
	# Returns the x, y coordinates of the first such cell found, or an empty array if there is none
	func contains_icon(puzzle: Array, icon: int, colour: int, exclude_x: int, exclude_y: int) -> Array:
		for x in len(puzzle):
			for y in len(puzzle[x]):
				if cells[x * 2][y * 2] and [x, y] != [exclude_x, exclude_y]:
					var puzzle_icon = puzzle[x][y]
					if puzzle_icon[PuzzleClasses.ICON] == icon and puzzle_icon[PuzzleClasses.COLOUR] == colour:
						return [x, y]
		return []

static func init_2d_array(width: int, height: int, fill) -> Array:
	var arr := []
	for x in width:
		arr.append([])
		for y in height:
			arr[x].append(fill)
	return arr

# Check the rules of cells in a puzzle
# Determines whether the player is allowed to make a certain move or not
static func check_solution(puzzle: Array, state: Array) -> Solution:
	var puzzle_cells: Array = puzzle[PuzzleClasses.CELLS]
	# A Solution to add results into
	var result = Solution.new()
	
	var regions := calculate_regions(puzzle, state)
	
	for x in len(puzzle_cells):
		for y in len(puzzle_cells[x]):
			var containing_region: Region
			for region in regions:
				if region.cells[x * 2][y * 2]:
					containing_region = region
					break
			
			match puzzle_cells[x][y][PuzzleClasses.ICON]:
				# Squares can't be in the same region as another square of the same colour
				PuzzleClasses.SQUARE:
					print(x, ", ", y, ", ")
					containing_region.pretty_print()
					if containing_region.contains_icon(puzzle_cells, PuzzleClasses.SQUARE, puzzle_cells[x][y][PuzzleClasses.COLOUR], x, y):
						result.add_wrong(x, y)
	
	var key_x = puzzle[PuzzleClasses.KEY_X]
	var key_y = puzzle[PuzzleClasses.KEY_Y]
	var key_rotation = state[key_x][key_y]
	var target_rotation = puzzle[PuzzleClasses.KEY_TARGET_ROTATION]
	
	if key_rotation == target_rotation:
		result.is_solved = true

	return result

# Pretty prints a 2d array
static func pretty_print_array(arr: Array):
	for item in arr:
		print(item)
	print()

static func calculate_regions(puzzle: Array, state: Array) -> Array:
	var regions := []
	
	# The width and height in subcells
	var width = puzzle[PuzzleClasses.WIDTH] * 2
	var height = puzzle[PuzzleClasses.HEIGHT] * 2
	
	# Which edges have a pointer blocking them
	var edges_horizontal := init_2d_array(width, height + 1, false)
	var edges_vertical := init_2d_array(width + 1, height, false)
	# Which cells have been assigned to a region
	var assigned_subcells = Region.new(width, height)
	
	# Calculate which subcell edges are filled with a pointer
	for x in width / 2:
		for y in height / 2:
			var cell = puzzle[PuzzleClasses.CELLS][x][y]
			var icon = cell[PuzzleClasses.ICON]
			var rotation = state[x][y]
			if icon in PuzzleClasses.POINTERS:
				# 4, 5, 6, 7 are used as bases rather than 0, 1, 2, 3, 4
				# This is because the % operator acts differently on negative number.
				if PuzzleClasses.POINT_DIRECTIONS[icon][(4 - rotation) % 4]:
					edges_vertical[x * 2 + 1][y * 2] = true
				if PuzzleClasses.POINT_DIRECTIONS[icon][(5 - rotation) % 4]:
					edges_horizontal[x * 2 + 1][y * 2 + 1] = true
				if PuzzleClasses.POINT_DIRECTIONS[icon][(6 - rotation) % 4]:
					edges_vertical[x * 2 + 1][y * 2 + 1] = true
				if PuzzleClasses.POINT_DIRECTIONS[icon][(7 - rotation) % 4]:
					edges_horizontal[x * 2][y * 2 + 1] = true
			# NO_CELL cells should not be assigned to any region
			elif icon == PuzzleClasses.NO_CELL:
				assigned_subcells.cells[x * 2][y * 2] = true
				assigned_subcells.cells[x * 2 + 1][y * 2] = true 
				assigned_subcells.cells[x * 2][y * 2 + 1] = true 
				assigned_subcells.cells[x * 2 + 1][y * 2 + 1] = true 
	
	# Loop until all cells have been assigned to a region
	while not assigned_subcells.is_full():
		var empty_cell = assigned_subcells.get_empty_cell()
		
		var region = Region.new(width, height)
		region.floodfill_from(assigned_subcells, edges_horizontal, edges_vertical, empty_cell[0], empty_cell[1])
		
		assigned_subcells.fill_from(region)
		regions.append(region)
	return regions
