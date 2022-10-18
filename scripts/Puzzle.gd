extends Spatial

class_name Puzzle

"""[
	width, height,
	[[PuzzleCell or null; width]; height],        #cells
	[[PuzzleEdge or null; width]; height + 1],    #horizontal edges
	[[PuzzleEdge or null; width + 1]; height + 1] #vertical edges
]"""
export(Array) var puzzle

export(NodePath) var instance
export(NodePath) var on_complete

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(puzzle[PuzzleClasses.WIDTH]):
		for y in range(puzzle[PuzzleClasses.HEIGHT]):
			var tile = create_tile(x, y, puzzle[PuzzleClasses.CELLS][x][y])
			tile.transform.origin = Vector3(x, -y, 0)
			add_child(tile)
	pass # Replace with function body.

func create_tile(_x, _y, cell) -> Spatial:
	var node: Spatial = get_node(instance).duplicate()
	node.set_visible(true)
	var icon: CSGMesh = node.get_node("Icon")
	if cell != null:
		var texture := TextureCacheSingleton.get_coloured_cell_texture(cell)
		var mat_override := icon.get_material().duplicate()
		mat_override.set_shader_param("icon_texture", texture)
		icon.set_material_override(mat_override)
	else:
		icon.set_visible(false)
	node.rotate(Vector3.RIGHT, PI / 2)
	return node

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
