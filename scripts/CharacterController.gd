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

# Whether the mouse is free
# Controls whether mouse and keyboard inputs move the player
var mouse_is_free := false
# Which puzzle was most recently interacted with
var most_recent_puzzle: Puzzle

# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_window_maximized(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = get_node(camera_path)

# Called on input events
# Rotation is calculated here, movement is calculated in _physics_process
func _input(event: InputEvent):
	# Turn camera on mouse motion
	if event is InputEventMouseMotion:
		# Don't turn if interacting with a puzzle
		if mouse_is_free: return
		
		# Calculate current up/down view angle (angle to up vector)
		var current_angle := camera.transform.basis.z.angle_to(Vector3.UP)
		# Calculate new up/down view angle from mouse motion in y axis
		var new_angle: float = current_angle + -event.relative[1] * mouse_sensitivity
		
		# Constrain new angle to within 0 - PI radians so that camera does not become upside-down
		# Small offset stops rotation fast mouse movements from getting around this
		new_angle = min(new_angle, PI - 0.001)
		new_angle = max(new_angle, 0.001)
		
		# Apply up/down rotation
		camera.rotate_object_local(Vector3.LEFT, current_angle - new_angle)
		# Apply left/right rotation
		camera.rotate(Vector3.DOWN, event.relative[0] * mouse_sensitivity)

func _physics_process(delta: float):
	
	# Dont move if interacting with a puzzle
	if not mouse_is_free:
		# Sores direction player will move in
		var direction := Vector3.ZERO

		# Check for each move input and update direction
		if Input.is_action_pressed("move_right"):
			direction.x += 1
		if Input.is_action_pressed("move_left"):
			direction.x -= 1
		if Input.is_action_pressed("move_backward"):
			direction.z += 1
		if Input.is_action_pressed("move_forward"):
			direction.z -= 1
		
		# If resultant motion, apply it
		if direction != Vector3.ZERO:
			# Get whether the player is running
			var this_frame_speed := run_speed if Input.is_action_pressed("run") else walk_speed
			# Transform direction to face in current looking direction
			var motion := Transform.looking_at(-camera.transform.basis.z, Vector3.UP) * direction
			motion.y = 0
			# Multiply motion by player's speed
			motion = motion.normalized() * this_frame_speed
			# Apply motion
			# warning-ignore:return_value_discarded
			move_and_slide(motion)
	
	# Apply acceleration due to gravity
	velocity += Vector3.DOWN * gravity_acceleration * delta
	# move_and_collide returns a truthy value only if collision occured
	# So check for that to reset velocity if a collision occured
	if move_and_collide(velocity):
		velocity = Vector3.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# If 'free_mouse' input was just pressed this frame 
	if Input.is_action_just_pressed("free_mouse"):
		# If mouse is currently free, capture it
		if mouse_is_free:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_is_free = false
		# If mouse is currently captured, free it
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_is_free = true
	if Input.is_action_just_pressed("enter_solution"):
		if most_recent_puzzle != null:
			most_recent_puzzle.check_solution()
