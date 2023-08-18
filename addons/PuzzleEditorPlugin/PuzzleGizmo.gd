@tool
extends EditorNode3DGizmoPlugin

func get_name():
	return "Puzzle Outline"

func _has_gizmo(spatial):
	return spatial is Puzzle

func _init():
	create_material("main", Color(1, 0, 0))

func _get_gizmo_name() -> String:
	return "PuzzleOutlines"

func _redraw(gizmo):
	# Clear the lines which were drawn last time
	gizmo.clear()
	
	# Get the width and height of the puzzle to draw the rectangle with the right dimensions
	var spatial: Puzzle = gizmo.get_node_3d()
	var puzzle = spatial.puzzle
	var puzzle_width = puzzle[PuzzleClasses.WIDTH]
	var puzzle_height = puzzle[PuzzleClasses.HEIGHT]
	
	# Initialise an array of points
	# Each pair of points in the PoolVector3Array is one line that will be drawn
	var lines := PackedVector3Array()
	
	for x in puzzle_width:
		for y in puzzle_height:
			if puzzle[PuzzleClasses.CELLS][x][y][PuzzleClasses.ICON] != PuzzleClasses.NO_CELL:
	
				# Integer coords are the centres of tiles
				# So offsets of 0.5 are used to have the rectangle surround the whole puzzle
				var top_left := Vector3(x - 0.5, -y + 0.5, 0)
				var top_right := Vector3(x + 0.5, -y + 0.5, 0)
				var bottom_left := Vector3(x - 0.5, -y - 0.5, 0)
				var bottom_right := Vector3(x + 0.5, -y - 0.5, 0)
				
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
