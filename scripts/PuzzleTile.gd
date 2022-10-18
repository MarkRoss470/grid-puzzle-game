extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(NodePath) var backplane_path
var backplane: CSGMesh
var mat_override: Material

func mouse_enter():
	mat_override.set_shader_param("main_colour", Color(1, 0, 0))
func mouse_exit():
	mat_override.set_shader_param("main_colour", Color(0, 1, 0))

# Called when the node enters the scene tree for the first time.
func _ready():
	backplane = get_node(backplane_path)
	mat_override = backplane.get_material().duplicate()
	backplane.set_material_override(mat_override)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
