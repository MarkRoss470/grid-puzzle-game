extends Spatial

class_name PuzzleTile

# What to change the colour of on hover, solve, etc
export(NodePath) var backplane_path
# The mesh/material to change the colour of
var backplane: CSGMesh
var mat_override: Material

# What to rotate when tile is clicked
export(NodePath) var rotation_indicator_path
var rotation_indicator: Spatial

# Current base and hover colours
var colour_base: Color
var colour_hover: Color

# The x and y of this cell in the puzzle
var this_x: int
var this_y: int
# The puzzle this cell is a part of
var puzzle

# Whether the mouse is over the tile at the moment
var mouse_over_tile: bool = false

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
		# If left click and press not release
		if event.button_index == 1 and event.pressed:
			# Tell puzzle cell has been rotated
			puzzle.rotate_cell(this_x, this_y)
			# Physically rotate this cell
			rotation_indicator.rotate(Vector3.DOWN, PI / 2)
			
			# Set this puzzle as the most recently interacted puzzle
			# So that enter_solution inputs register with this puzzle
			get_node("../../Player").most_recent_puzzle = puzzle

# Called when the node enters the scene tree for the first time.
func _ready():
	backplane = get_node(backplane_path)
	mat_override = backplane.get_material().duplicate()
	backplane.set_material_override(mat_override)
	mat_override.set_shader_param("main_colour", colour_base)

	rotation_indicator = get_node(rotation_indicator_path)
