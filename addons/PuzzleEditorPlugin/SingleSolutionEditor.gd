@tool
extends EditorProperty

const GRID_CELL_OFFSET := 40
const GRID_CELL_SIZE := 30

# Container for all editor elements
var editor_items := Panel.new()

var solution: Array
var puzzle: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	puzzle = get_edited_object()["puzzle"]
	solution = get_edited_object()["solution"]
	
	# Stops an odd bug from happening
	# Which does not occur if the array is created manually
	if solution == []:
		return
	
	var width: int = puzzle[PuzzleClasses.WIDTH]
	var height: int = puzzle[PuzzleClasses.HEIGHT]
	var puzzle_cells: Array = puzzle[PuzzleClasses.CELLS]
	
	resize_arrays(width, height)
	
	for y in height:
		var row := Container.new()
		row.name = "row-" + str(y)
		row.set_position(Vector2(0, GRID_CELL_OFFSET * y))
		
		for x in width:
			# Set up cell
			var cell := ColorRect.new()
			cell.color = Color(0.5, 0.5, 0.5)
			cell.set_size(Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE))
			cell.name = "cell-" + str(x) + "-" + str(y)
			cell.set_position(Vector2(x * GRID_CELL_OFFSET, 0))
			row.add_child(cell)
			
			cell.connect("gui_input", Callable(self, "rotate_cell").bind(x, y))
			
			# If cell has an icon, add it on top
			var cell_icon = puzzle_cells[x][y]
			if cell_icon[PuzzleClasses.ICON] != PuzzleClasses.EMPTY:
				# Set up icon
				var icon := TextureRect.new()
				icon.texture = PuzzleClasses.CELL_TEXTURES[cell_icon[PuzzleClasses.ICON]]
				# Don't change the colour of group 0 because they're special icons
				if not cell_icon[PuzzleClasses.ICON] in PuzzleClasses.DONT_RECOLOUR:
					icon.modulate = PuzzleClasses.COLOURS[cell_icon[PuzzleClasses.COLOUR]]
				
				icon.scale = Vector2(1.0 / icon.texture.get_height(), 1.0 / icon.texture.get_height()) * GRID_CELL_SIZE
				icon.name = "icon-" + str(x)
				icon.set_rotation(solution[x][y] * PI / 2)
				var icon_position := Vector2(GRID_CELL_OFFSET * x, 0)
				# Add an offset to icon_position to make icons stay in the same place when rotated
				match solution[x][y]:
					0:
						pass
					1:
						icon_position += Vector2(GRID_CELL_SIZE, 0)
					2:
						icon_position += Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
					3:
						icon_position += Vector2(0, GRID_CELL_SIZE)
				icon.set_position(icon_position)
				# Needed so that mouse events get recieved by the cell underneath
				icon.mouse_filter = MOUSE_FILTER_IGNORE
				
				row.add_child(icon)
		
		editor_items.add_child(row)
	
	add_child(editor_items)
	
	# Set the container to the right size for the grid
	var min_x = width * GRID_CELL_OFFSET
	var min_y = 50 + height * GRID_CELL_OFFSET
	editor_items.custom_minimum_size = Vector2(max(400, min_x), max(400, min_y))

func rotate_cell(event: InputEvent, x: int, y: int):
	if event is InputEventMouseButton and event.pressed:
		
		var rotation = solution[x][y]
		rotation += 1
		rotation %= 4
		solution[x][y] = rotation
		
		emit_changed("solution", solution)
		
		if puzzle[PuzzleClasses.CELLS][x][y][0] == PuzzleClasses.EMPTY:
			return
		
		var icon := editor_items.get_node("row-" + str(y) + "/icon-" + str(x))
		
		icon.set_rotation(rotation * PI / 2)
		var icon_position := Vector2(GRID_CELL_OFFSET * x, 0)
		# Add an offset to icon_position to make icons stay in the same place when rotated
		match rotation:
			0:
				pass
			1:
				icon_position += Vector2(GRID_CELL_SIZE, 0)
			2:
				icon_position += Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
			3:
				icon_position += Vector2(0, GRID_CELL_SIZE)
		icon.set_position(icon_position)
		

# Adds or removes elements from arrays in current_value to make them the right size
func resize_arrays(target_width: int, target_height: int):
	# Get current width
	var cells := solution
	var current_width := len(cells)
	
	# If array too long, slice it
	if current_width > target_width:
		cells = cells.slice(0, target_width)
	# If too short, pad with empty arrays
	elif current_width < target_width:
		for x in target_width - current_width:
			cells.append([])
	
	# Loop through all columns and resize them
	for x in target_width:
		if cells[x] == null:
			cells[x] = []
		
		# Get current height of this column
		var current_height := len(cells[x])
		# If too long, slice it
		if current_height > target_height:
			cells[x] = cells[x].slice(0, target_height)
		# If too short, pad with default cell
		elif current_height < target_height:
			for y in target_height - current_height:
				cells[x].append(0)
		
		var new_height := len(cells[x])
	
	solution = cells
	emit_changed("solution", cells)

func _update_property():
	solution = get_edited_object()["solution"]
