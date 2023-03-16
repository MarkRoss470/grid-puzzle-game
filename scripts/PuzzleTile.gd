extends Spatial

class_name PuzzleTile

# What to change the colour of on hover, solve, etc
export(NodePath) var backplane_path
# What to set the image on
export(NodePath) var icon_path
var icon: Spatial

# The mesh/material to change the colour of
var backplane: CSGMesh
var mat_override: Material

# Current base and hover colours
var colour_base: Color
var colour_hover: Color

# The x and y of this cell in the puzzle
var this_x: int
var this_y: int
# The puzzle this cell is a part of
var puzzle

# Whether the mouse is over the tile at the moment
var mouse_over_tile := false

# Sets the base and hover colours of this tile
func set_colour(colour: Color, colour_h: Color):
	# Store the colours
	colour_base = colour
	colour_hover = colour_h
	
	# If mouse currently over tile, set colour to hover colour
	if mouse_over_tile:
		mat_override.set_shader_param("main_colour", colour_hover)
	# Otherwise, set colour to base colour
	else:
		mat_override.set_shader_param("main_colour", colour_base)

# Called when the mouse enters the tile
func mouse_enter():
	mouse_over_tile = true
	mat_override.set_shader_param("main_colour", colour_hover)

# Called when the mouse exits the tile
func mouse_exit():
	mouse_over_tile = false
	mat_override.set_shader_param("main_colour", colour_base)

# Called when an input related to this object occurs
func input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	# If this tile is clicked
	if event is InputEventMouseButton:
		# If it is the left mouse button and it is being pressed down rather than released
		if event.button_index == 1 and event.pressed:
			# Tell puzzle cell has been rotated
			puzzle.rotate_cell(this_x, this_y)

# Called when the node enters the scene tree for the first time.
func _ready():
	backplane = get_node(backplane_path)
	# Create a new material override so that colour changes only apply to this cell
	mat_override = backplane.get_material().duplicate()
	backplane.set_material_override(mat_override)
	mat_override.set_shader_param("main_colour", colour_base)

	icon = get_node(icon_path)
