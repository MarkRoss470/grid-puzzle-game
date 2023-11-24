extends CharacterBody3D

class_name CharacterController

# Player's speed in units per second
@export var walk_speed := 3.0
# Acceleration due to gravity in units per second^2
@export var gravity_acceleration := 1.0
# Player's maximum fall speed
@export var max_fall_speed := 5.0
# Speed of turning in radians per pixel
@export var mouse_sensitivity := 0.02
# Player's run speed in units per second
@export var run_speed := 10.0

# The player camera
@export var camera: Camera3D
# The node which shows that the player is in puzzle mode
@export var mode_indicator: ScreenBorder
# The audio listener
@export var listener: AudioListener3D
# The audio stream for the player's footsteps
@export var audio_player: AudioStreamPlayer

# Whether the mouse is free (when interacting with a puzzle)
# Controls whether mouse and keyboard inputs move the player
var in_puzzle_mode := false

# The vertical velocity
var y_velocity := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("savable")
	
	if SaveManager.contains_key("player"):
		var saved_state = SaveManager.get_state("player")
		
		position.x = saved_state.position[0]
		position.y = saved_state.position[1]
		position.z = saved_state.position[2]
		
		camera.rotation.x = saved_state.rotation[0]
		camera.rotation.y = saved_state.rotation[1]
		camera.rotation.z = saved_state.rotation[2]
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	Settings.register_callback("mouse_sensitivity", func(new_value):
		mouse_sensitivity = new_value
	)
	
	Settings.register_callback("movement_speed", func(new_value):
		walk_speed = new_value
	)
	
	Settings.register_callback("fullscreen", func(value):
		if value:
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			get_window().mode = Window.MODE_MAXIMIZED
	)
	
	listener.make_current()
	
	audio_player.stream_paused = true
	audio_player.volume_db = -100
	audio_player.play()

# Called on input events
# Rotation is calculated here, movement is calculated in _physics_process
func _input(event: InputEvent):
	# Turn camera on mouse motion
	if event is InputEventMouseMotion:
		# Don't turn if interacting with a puzzle
		if in_puzzle_mode: return
		
		# Calculate current up/down view angle (angle to up vector)
		var current_angle := camera.transform.basis.z.angle_to(Vector3.UP)
		# Calculate new up/down view angle from mouse motion in y axis
		var new_angle: float = current_angle + -event.relative[1] * mouse_sensitivity
		
		# Constrain new angle to within 0 - PI radians so that camera does not become upside-down
		# Small offset stops fast mouse movements from getting around this
		new_angle = min(new_angle, PI - 0.001)
		new_angle = max(new_angle, 0.001)
		
		# Apply up/down rotation
		camera.rotate_object_local(Vector3.LEFT, current_angle - new_angle)
		# Apply left/right rotation
		camera.rotate(Vector3.DOWN, event.relative[0] * mouse_sensitivity)

# Called each frame
# Movement is calculated here, rotation is calculated in _input
func _physics_process(delta: float):
	# Dont move if interacting with a puzzle
	if not in_puzzle_mode:
		# Stores direction player will move in
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
		
		# If there is resultant motion, apply it
		if direction != Vector3.ZERO:
			# Get whether the player is running
			var this_frame_speed := run_speed if Input.is_action_pressed("run") else walk_speed
			# Transform direction to face in current looking direction
			# So that movement is applied relative to the player's current facing direction
			var motion := Transform3D().looking_at(-camera.transform.basis.z, Vector3.UP) * direction
			motion.y = 0
			# Multiply motion by player's speed
			motion = motion.normalized() * this_frame_speed
			# Apply motion
			# warning-ignore:return_value_discarded
			set_velocity(motion)
			move_and_slide()
	
	# Apply acceleration due to gravity
	y_velocity = y_velocity + gravity_acceleration * delta
	y_velocity = min(y_velocity, max_fall_speed)
	
	# move_and_collide returns a truthy value only if collision occured
	# So check for that to reset velocity if a collision occured
	if move_and_collide(Vector3.DOWN * y_velocity):
		y_velocity = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# If 'free_mouse' input was just pressed, update mouse mode
	if Input.is_action_just_pressed("free_mouse"):
		# If mouse is currently free, capture it
		if in_puzzle_mode:
			# Hide the screen border
			mode_indicator.hide_border()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			in_puzzle_mode = false
			get_tree().call_group("puzzle_tiles", "mouse_exit")
		# If mouse is currently captured, free it
		else:
			# Show the screen border
			mode_indicator.show_border()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			in_puzzle_mode = true
	
	# If the player is moving, play the footsteps sound
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_backward") or Input.is_action_pressed("move_forward"):
		audio_player.volume_db = 0
		audio_player.stream_paused = false
	else:
		audio_player.stream_paused = true

func save():
	SaveManager.set_state("player", {
		"position": [position.x, position.y, position.z],
		"rotation": [camera.rotation.x, camera.rotation.y, camera.rotation.z],
	})
