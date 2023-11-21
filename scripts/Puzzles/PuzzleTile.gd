extends Node3D

class_name PuzzleTile

# What to change the colour of on hover, solve, etc
@export var backplane_path: NodePath
# What to set the image on
@export var icon_path: NodePath
var icon: CSGMesh3D
var icon_mat_override: Material

# The mesh/material to change the colour of
var backplane: CSGMesh3D
var backplane_mat_override: Material

# Current base and hover colours
var colour_base := Color(0, 0, 0)
var colour_hover := Color(0, 1, 0)

# The x and y of this cell in the puzzle
var this_x: int
var this_y: int
# The puzzle this cell is a part of
var puzzle

# Whether the mouse is over the tile at the moment
var mouse_over_tile := false

var icon_design: PuzzleDesignIcon

# The colour the tile is currently flashing
var flash_colour: Color = Color(0, 0, 0)
# The time which the cell has been flashing for
var flash_progress := 0.0
# The length in seconds of the current flash
var flash_time := 0.0

# Sets the base and hover colours of this tile
func set_colour(colour: Color, colour_h: Color):
	# Store the colours
	colour_base = colour
	colour_hover = colour_h
	
	# If mouse currently over tile, set colour to hover colour
	if mouse_over_tile:
		backplane_mat_override.next_pass.set_shader_parameter("MainColour", colour_hover)
	# Otherwise, set colour to base colour
	else:
		backplane_mat_override.next_pass.set_shader_parameter("MainColour", colour_base)

func set_icon(new_icon_design: PuzzleDesignIcon):
	# Get the node's icon plane
	icon = get_node(icon_path)
	icon_design = new_icon_design
	
	# If the puzzle cell has an icon, set the right image
	if icon_design.icon != PuzzleClasses.EMPTY:
		# Make copy of material
		icon_mat_override = icon.get_material().duplicate()
		icon_mat_override.next_pass = icon_mat_override.next_pass.duplicate()
		
		# Set texture
		icon_mat_override.next_pass.set_shader_parameter("icon_texture", PuzzleClasses.CELL_TEXTURES[icon_design.icon])
		# Set colour
		icon_mat_override.next_pass.set_shader_parameter("icon_colour", PuzzleClasses.COLOURS[icon_design.colour])
		# Set icon to use this material
		icon.set_material_override(icon_mat_override)
	# If the puzzle cell has no icon, hide the icon plane
	else:
		icon.set_visible(false)

func flash(colour: Color, time: float):
	flash_colour = colour
	flash_time = time
	flash_progress = 0
	
	icon_mat_override.next_pass.set_shader_parameter("icon_colour", flash_colour)

func end_flash():
	icon_mat_override.next_pass.set_shader_parameter("icon_colour", PuzzleClasses.COLOURS[icon_design.colour])
	flash_time = 0

# Called when the mouse enters the tile
func mouse_enter():
	mouse_over_tile = true
	backplane_mat_override.next_pass.set_shader_parameter("MainColour", colour_hover)

# Called when the mouse exits the tile
func mouse_exit():
	mouse_over_tile = false
	backplane_mat_override.next_pass.set_shader_parameter("MainColour", colour_base)

# Called when an input related to this object occurs
func input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	# If this tile is clicked
	if event is InputEventMouseButton:
		# If it is the left mouse button and it is being pressed down rather than released
		if event.button_index == 1 and event.pressed:
			# Tell puzzle cell has been rotated
			puzzle.rotate_cell(this_x, this_y, 1)
		# If it is the right mouse button and it is being pressed down rather than released
		if event.button_index == 2 and event.pressed:
			# Tell puzzle cell has been rotated
			puzzle.rotate_cell(this_x, this_y, -1)

func _process(delta):
	if mouse_over_tile and Input.is_action_just_pressed("reset"):
		puzzle.reset()
	
	if flash_time != 0:
		flash_progress += delta
		if flash_progress >= flash_time:
			end_flash()


# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("puzzle_tiles")
	
	backplane = get_node(backplane_path)
	# Create a new material override so that colour changes only apply to this cell
	backplane_mat_override = backplane.get_material().duplicate()
	backplane_mat_override.next_pass = backplane_mat_override.next_pass.duplicate()
	
	backplane.set_material_override(backplane_mat_override)
	backplane_mat_override.next_pass.set_shader_parameter("MainColour", colour_base)
