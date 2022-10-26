# Used as a singleton
# Reduces memory by allowing multiple tiles to share computed textures

extends Node

class_name TextureCache

# 2D Array of textures
# [icon][colour]
var coloured_cell_textures := []

# Set up cache
func _init():
	# Pad array with nulls
	for icon in range(len(PuzzleClasses.CELL_TEXTURES)):
		coloured_cell_textures.append([])
		for _colour in range(len(PuzzleClasses.COLOURS)):
			coloured_cell_textures[icon].append(null)

func get_coloured_cell_texture(cell_icon: Array) -> Texture:
	var icon_index: int = cell_icon[0]
	var colour_index: int = cell_icon[1]
	
	# If texture has already been computed, return it now
	if coloured_cell_textures[icon_index][colour_index] != null:
		return coloured_cell_textures[icon_index][colour_index]
		
	# Convert texture to image to be able to set pixels
	var image: Image = PuzzleClasses.CELL_TEXTURES[icon_index].get_data()
	# Lock image to be able to edit it
	image.lock()
	
	# Get colour from provided index
	var colour: Color = PuzzleClasses.COLOURS[colour_index]
	
	# Loop over pixels of image
	for y in image.get_height():
		for x in image.get_width():
			# If pixel is not transparent, set colour
			if image.get_pixel(x, y).a != 0:
				image.set_pixel(x, y, colour)
	
	# Create new ImageTexture and initialise it from the modified
	var tex = ImageTexture.new()
	tex.create_from_image(image, 0)
	
	# Release image lock
	image.unlock()

	# Add texture to cache and return it
	coloured_cell_textures[icon_index][colour_index] = tex
	return tex
