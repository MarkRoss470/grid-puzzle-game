extends KinematicBody

class_name CharacterController

#player's speed in units per second
export var walk_speed: float = 3
#acceleration due to gravity in units per second^2
export var gravity_acceleration: float = 10
#speed of turning in radians per pixel
export var mouse_sensitivity: float = 0.02
#player's run speed in units per second
export var run_speed: float = 10
# Camera to rotate
export (NodePath) var camera_path
var camera: Camera
# Collider to move

#player's current velocity (movement due to pressed keys does not count for this)
var velocity := Vector3.ZERO

# Whether to respond to input
var respond_to_input := true

# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_window_maximized(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = get_node(camera_path)
	pass # Replace with function body.

func _input(event: InputEvent):
	# Mouse in viewport coordinates.
	var event_mouse_button := event as InputEventMouseButton
	if event_mouse_button:
		if event_mouse_button.button_index == 1:
			pass
		print("Mouse Click/Unclick at: ", event_mouse_button.position)
		return
	var event_mouse_motion := event as InputEventMouseMotion
	if event_mouse_motion:
		if not respond_to_input: return
		var y_motion := -event_mouse_motion.relative[1]
		var current_angle := camera.transform.basis.z.angle_to(Vector3.UP)
		var new_angle := current_angle + y_motion * mouse_sensitivity
		if new_angle > PI - 0.05: new_angle = PI - 0.05
		if new_angle < 0.05: new_angle = 0.05

		camera.rotate_object_local(Vector3.LEFT, current_angle - new_angle)
		camera.rotate(Vector3.DOWN, event_mouse_motion.relative[0] * mouse_sensitivity)

func _physics_process(delta: float):
	# We create a local variable to store the input direction.
	var direction := Vector3.ZERO

	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_backward"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	
	if respond_to_input and direction != Vector3.ZERO:
		
		var this_frame_speed := run_speed if Input.is_action_pressed("run") else walk_speed
		#$Pivot.look_at(translation + direction, Vector3.UP)
		direction = Transform.looking_at(-camera.transform.basis.z, Vector3.UP) * direction
		direction.y = 0
		direction = direction.normalized() * this_frame_speed
		# warning-ignore:return_value_discarded
		move_and_slide(direction)
		
	velocity += Vector3.DOWN * gravity_acceleration * delta
	if move_and_collide(velocity):
		velocity = Vector3.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("free_mouse"):
		if respond_to_input:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			respond_to_input = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			respond_to_input = true
		print(respond_to_input)
