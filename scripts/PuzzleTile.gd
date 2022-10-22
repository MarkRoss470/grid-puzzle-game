extends Spatial

class_name PuzzleTile

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(NodePath) var backplane_path

var colour_base: Color
var colour_hover: Color

var backplane: CSGMesh
var mat_override: Material

var this_x: int
var this_y: int
var puzzle

var mouse_over_tile: bool = false

func set_colour(colour: Color, colour_h: Color):
	colour_base = colour
	colour_hover = colour_h
	
	if mouse_over_tile:
		mat_override.set_shader_param("main_colour", colour_hover)
	else:
		mat_override.set_shader_param("main_colour", colour_base)

func mouse_enter():
	mouse_over_tile = true
	mat_override.set_shader_param("main_colour", colour_hover)
	
func mouse_exit():
	mouse_over_tile = false
	mat_override.set_shader_param("main_colour", colour_base)

func input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			print("Clicked")
			puzzle.rotate_cell(this_x, this_y)
			rotate(Vector3.FORWARD, PI / 2)
			
			get_node("../../Player").most_recent_puzzle = puzzle

# Called when the node enters the scene tree for the first time.
func _ready():
	backplane = get_node(backplane_path)
	mat_override = backplane.get_material().duplicate()
	backplane.set_material_override(mat_override)
	mat_override.set_shader_param("main_colour", colour_base)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



