extends Spatial

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
	
func input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			print("Clicked")
			rotate(Vector3.FORWARD, PI / 2)

# Called when the node enters the scene tree for the first time.
func _ready():
	backplane = get_node(backplane_path)
	mat_override = backplane.get_material().duplicate()
	backplane.set_material_override(mat_override)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



