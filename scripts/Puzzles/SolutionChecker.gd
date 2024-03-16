extends Node

class_name SolutionChecker

# Class representing the path of a laser beam in a solution
class LaserPath:
	# The colour of the beam
	var colour: int
	
	# Whether the path connects at the other end
	var valid: bool
	
	# The coordinates of the cells the path goes through
	var path: Array[Vector2]
	
	func equals(other: LaserPath) -> bool:
		if self.colour != other.colour: return false
		if self.valid != other.valid: return false
		return self.path == other.path

# Class representing a solution
class Solution:
	# Whether the solution is a valid puzzle state
	var is_valid: bool
	
	# An array of [x, y] coordinates of the cells which are wrong
	# This is not (necessarily) the cells which are in the wrong rotation
	# It's the cells whose rules are broken because of a cell in the wrong rotation
	var wrong_cells: Array[Array]
	
	# The regions of the puzzle
	var regions: Array[Region]
	# The paths of lasers
	var laser_paths: Array[LaserPath]
	
	# Simple constructor
	func _init():
		is_valid = true
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
	var cells: Array[Array]
	
	# The furthest filled in cell in each direction
	var bounding_box_l: int
	var bounding_box_r: int
	var bounding_box_u: int
	var bounding_box_d: int
	
	
	# Creates a new region with the specified width and height.
	func _init(width: int, height: int):
		# Set bounding box values to impossible values
		# so that they will get the right value when the first cell is added
		bounding_box_l = width
		bounding_box_r = 0
		bounding_box_u = height
		bounding_box_d = 0
		
		cells = []
		for x in width:
			cells.append([])
			for y in height:
				cells[x].append(false)
	
	# Gets whether the region contains the given sub-cell
	func contains_cell(x: int, y: int) -> bool:
		return cells[x][y]
	
	# Adds the given cell to the region
	func add_cell(x: int, y: int):
		cells[x][y] = true
		
		# Add the cell to the bounding box values
		bounding_box_l = min(bounding_box_l, x)
		bounding_box_r = max(bounding_box_r, x)
		bounding_box_u = min(bounding_box_u, y)
		bounding_box_d = max(bounding_box_d, y)
	
	# Gets whether all subcells are true
	func is_full() -> bool:
		for column in cells:
			for cell in column:
				if not cell:
					return false
		return true

	# Finds an subcell which is false and returns its x, y coordinates.
	# If none is found, returns an empty array
	func get_empty_cell() -> Array[int]:
		for x in len(cells):
			for y in len(cells[x]):
				if not cells[x][y]:
					return [x, y]
		return []
		
	# Sets all the subcells to true in this Region which are true in another Region
	func fill_from(other: Region):
		for x in len(cells):
			for y in len(cells[x]):
				if other.cells[x][y]:
					add_cell(x, y)
	
	# Recursively fill this region starting from the given coordinate, bounded by:
	# * true cells in `other`
	# * edges in `edges_horizontal` and `edges_vertical`
	func floodfill_from(other: Region, edges_horizontal: Array[Array], edges_vertical: Array[Array], x: int, y: int):
		self.add_cell(x, y)
		
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
		
		print(
			"bounding box: ",
			"left=", bounding_box_l,
			", right=", bounding_box_r,
			", up=", bounding_box_u,
			", down=", bounding_box_d
		)
	
	# Whether a cell in this Region contains the given icon
	# Only checks the top-left subcell of each cell
	# Excludes the cell at the given coordinates
	# Returns the x, y coordinates of the first such cell found, or an empty array if there is none
	func contains_icon(puzzle: Array, icon: int, colour: int, exclude_x: int, exclude_y: int) -> Array[int]:
		for x in len(puzzle):
			for y in len(puzzle[x]):
				if cells[x * 2][y * 2] and [x, y] != [exclude_x, exclude_y]:
					var puzzle_icon: PuzzleDesignIcon = puzzle[x][y]
					if puzzle_icon.icon == icon and puzzle_icon.colour == colour:
						return [x, y]
		return []
	
	# Tests the region's horizontal and vertical symmetry.
	# Returns whether the region is symmetric around each axis
	func test_symmetry() -> Array[bool]:
		var to_sub_x := bounding_box_l + bounding_box_r
		var to_sub_y := bounding_box_u + bounding_box_d
		
		var symmetrical_horizontal := true
		var symmetrical_vertical := true
		
		# TODO: lots of repeated work here, optimise if necessary
		for x in range(bounding_box_l, bounding_box_r + 1):
			for y in range(bounding_box_u, bounding_box_d + 1):
				if cells[x][y] != cells[to_sub_x - x][y]:
					symmetrical_horizontal = false
				if cells[x][y] != cells[x][to_sub_y - y]:
					symmetrical_vertical = false
		
		return [symmetrical_horizontal, symmetrical_vertical]
		
	func equals(other: Region) -> bool:
		return cells == other.cells

# Initialises a 2d array of the given dimensions with the given item
static func init_2d_array(width: int, height: int, fill: Variant) -> Array[Array]:
	var arr: Array[Array] = []
	for x in width:
		arr.append([])
		for y in height:
			arr[x].append(fill)
	return arr

# Check the rules of cells in a puzzle
# Determines whether the player is allowed to make a certain move or not
static func check_solution(puzzle: PuzzleDesign, state: Array[Array]) -> Solution:
	var puzzle_cells: Array[Array] = puzzle.icons
	# A Solution to add results into
	var result = Solution.new()
	
	var regions := calculate_regions(puzzle, state)
	
	#for region in regions:
	#	region.pretty_print()
	
	for x in len(puzzle_cells):
		for y in len(puzzle_cells[x]):
			var containing_region: Region
			for region in regions:
				if region.cells[x * 2][y * 2]:
					containing_region = region
					break
			
			match puzzle_cells[x][y].icon:
				# Squares can't be in the same region as another square of the same colour
				PuzzleClasses.SQUARE:
					if containing_region.contains_icon(puzzle_cells, PuzzleClasses.SQUARE, puzzle_cells[x][y].colour, x, y):
						result.add_wrong(x, y)
				# Circles have to be in the same region as another circle of the same colour
				PuzzleClasses.CIRCLE:
					if containing_region.contains_icon(puzzle_cells, PuzzleClasses.CIRCLE, puzzle_cells[x][y].colour, x, y):
						pass
					else:
						result.add_wrong(x, y)
				# Symmetry icons have to be in a region which is symmetrical along a given axis.
				# The icon does not have to be on the axis of symmetry.
				PuzzleClasses.SYMMETRY_HORIZONTAL:
					if not containing_region.test_symmetry()[0]:
						result.add_wrong(x, y)
				PuzzleClasses.SYMMETRY_VERTICAL:
					if not containing_region.test_symmetry()[1]:
						result.add_wrong(x, y)
				
				PuzzleClasses.LASER, PuzzleClasses.LASER_FIXED:
					var path := check_laser(puzzle, state, x, y)
					
					if !path.valid:
						result.add_wrong(x, y)
					
					# Add the path to the list even if it's not valid so that SymbolPuzzle can flash icons based on it
					result.laser_paths.append(path)
	
	result.regions = regions
	return result

# Pretty prints a 2d array
static func pretty_print_array(arr: Array[Array]):
	for item in arr:
		print(item)
	print()

static func calculate_regions(puzzle: PuzzleDesign, state: Array[Array]) -> Array[Region]:
	var regions: Array[Region] = []
	
	# The width and height in subcells
	var width = puzzle.width * 2
	var height = puzzle.height * 2
	
	# Which edges have a pointer blocking them
	var edges_horizontal := init_2d_array(width, height + 1, false)
	var edges_vertical := init_2d_array(width + 1, height, false)
	# Which cells have been assigned to a region
	var assigned_subcells = Region.new(width, height)
	
	# Calculate which subcell edges are filled with a pointer
	for x in width / 2:
		for y in height / 2:
			var cell = puzzle.icons[x][y]
			var icon = cell.icon
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

# Checks whether a laser or fixed laser icon is solved
static func check_laser(puzzle: PuzzleDesign, state: Array[Array], x: int, y: int) -> LaserPath:
	var colour = puzzle.icons[x][y].colour
	
	var search_x = x
	var search_y = y
	var search_direction = state[x][y]
	
	var i = 0
	
	var path := LaserPath.new()
	path.valid = false
	path.colour = puzzle.icons[x][y].colour
	path.path.append(Vector2(search_x, search_y))
	
	while true:
		# Protection agains infinite loops - this should never be triggered.
		# If I ever make a really really big puzzle this number might need to be increased
		# But back of the envelope this should be fine for puzzles smaller than 20x20
		i += 1
		if i == 1000: 
			push_error("Laser loop limit reached")
			push_error("x: ", x, ", y: ", y)
			push_error("search_x: ", search_x, ", search_y: ", search_y)
			return path
		
		# search_direction might have been increased below 0 or above 4 last iteration
		search_direction = (search_direction + 4) % 4
		
		# Move in the direction of search_direction and stop if the edge of the puzle is reached
		match search_direction:
			0: # UP
				search_y -= 1
				if search_y < 0: return path
			1: # RIGHT
				search_x += 1
				if search_x >= puzzle.width: return path
			2: # DOWN
				search_y +=1 
				if search_y >= puzzle.height: return path
			3: # LEFT
				search_x -= 1
				if search_x < 0: return path
		
		path.path.append(Vector2(search_x, search_y))
		
		var icon: PuzzleDesignIcon = puzzle.icons[search_x][search_y]
		# Get the rotation of the current cell
		var rotation = state[search_x][search_y]
		# Get which face the beam is entering the cell
		# e.g. relative_rotation = 0 means the beam is entering the top of the cell, 1 = right etc.
		# This is relative to the rotation of the cell itself
		var relative_rotation = (search_direction - rotation + 6) % 4
		
		# Pointers of the same colour as the beam are ignored
		if icon.icon in PuzzleClasses.POINTERS and icon.colour == colour:
			continue
		
		match icon.icon:
			# NO_CELL tiles don't transmit the beam
			PuzzleClasses.NO_CELL: return path
			# EMPTY cells transmit the beam unaltered
			PuzzleClasses.EMPTY: pass
			# Correctly coloured and rotated lasers mean the rule is followed
			PuzzleClasses.LASER, PuzzleClasses.LASER_FIXED:
				# If the lasers are the same colour and the other laser is facing toward search_direction
				if icon.colour == colour and relative_rotation == 0:
					path.valid = true
					return path
				else:
					return path
			# Single pointers need to be aligned
			PuzzleClasses.POINTER_SINGLE, PuzzleClasses.FIXED_POINTER_SINGLE:
				if not relative_rotation in [0, 2]: return path
			# Straight double pointers need to be aligned
			PuzzleClasses.POINTER_DOUBLE_STRAIGHT, PuzzleClasses.FIXED_POINTER_DOUBLE_STRAIGHT:
				if not relative_rotation in [0, 2]: return path
			# Angled double pointers change the direction of the beam
			PuzzleClasses.POINTER_DOUBLE_ANGLE, PuzzleClasses.FIXED_POINTER_DOUBLE_ANGLE:
				if relative_rotation == 0: search_direction -= 1
				elif relative_rotation == 1: search_direction += 1
				else: return path
			# Triple pointers need to be aligned
			PuzzleClasses.POINTER_TRIPLE, PuzzleClasses.FIXED_POINTER_TRIPLE:
				if not relative_rotation in [0, 2]: return path
			# Quadruple pointers don't affect the beam
			PuzzleClasses.POINTER_QUADRUPLE, PuzzleClasses.FIXED_POINTER_QUADRUPLE:
				pass
			
			# Any other cells don't transmit the beam
			_: return path
	
	# This while loop should never exit exept with a return statement so this code should never be reached
	# However it is needed for the function to type-check 
	push_error("Laser loop broken")
	return null
