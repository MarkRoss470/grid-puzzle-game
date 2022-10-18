extends Node

class_name TextureCache

var coloured_cell_textures := []

func _init():
	for icon in range(len(PuzzleClasses.CELL_TEXTURES)):
			coloured_cell_textures.append([])
			for _colour in range(len(PuzzleClasses.COLOURS)):
				coloured_cell_textures[icon].append(null)

func get_coloured_cell_texture(cell_icon: Array) -> Texture:
	var icon: int = cell_icon[0]
	var colour: int = cell_icon[1]
	if coloured_cell_textures[icon][colour] != null:
		return coloured_cell_textures[icon][colour]
	var image: Image = PuzzleClasses.CELL_TEXTURES[icon].get_data()
	image.lock()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a != 0:
				image.set_pixel(x, y, PuzzleClasses.COLOURS[colour])
	var tex = ImageTexture.new()
	tex.create_from_image(image, 0)
	coloured_cell_textures[icon][colour] = tex
	return coloured_cell_textures[icon][colour]

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
