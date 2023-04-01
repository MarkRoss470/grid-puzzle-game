extends EditorSpatialGizmoPlugin

func get_name():
	return "Puzzle Outline"

func has_gizmo(spatial):
	return spatial is Puzzle

func _init():
	create_material("main", Color(1, 0, 0))

func redraw(gizmo):
	# Clear the lines which were drawn last time
	gizmo.clear()
	
	# Get the width and height of the puzzle to draw the rectangle with the right dimensions
	var spatial: Puzzle = gizmo.get_spatial_node()
	var puzzle_width = spatial.puzzle[PuzzleClasses.WIDTH]
	var puzzle_height = spatial.puzzle[PuzzleClasses.HEIGHT]
	
	# Initialise an array of points
	# Each pair of points in the PoolVector3Array is one line that will be drawn
	var lines := PoolVector3Array()
	
	# Integer coords are the centres of tiles
	# So offsets of 0.5 are used to have the rectangle surround the whole puzzle
	var top_left := Vector3(-0.5, 0.5, 0)
	var top_right := Vector3(puzzle_width - 0.5, 0.5, 0)
	var bottom_left := Vector3(-0.50, -puzzle_height + 0.5, 0)
	var bottom_right := Vector3(puzzle_width - 0.5, -puzzle_height + 0.5, 0)
	
	# Add pairs of points for each side of the rectangle
	lines.push_back(top_left)
	lines.push_back(top_right)
	
	lines.push_back(top_left)
	lines.push_back(bottom_left)
	
	lines.push_back(bottom_left)
	lines.push_back(bottom_right)
	
	lines.push_back(top_right)
	lines.push_back(bottom_right)
	
	gizmo.add_lines(lines, get_material("main", gizmo), false)
