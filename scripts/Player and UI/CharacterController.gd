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

# The node which blocks mouse events when the player is in movement mode
@export var input_blocker: Control

# Whether the mouse is free (when interacting with a puzzle)
# Controls whether mouse and keyboard inputs move the player
var in_puzzle_mode := false
# The time since the player's mode last changed
var time_since_last_change := 0.0

# The vertical velocity
var y_velocity := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	var in_test_scene := get_tree().current_scene.name == "PuzzleDesignTestScene"
	
	print(get_tree().current_scene.name, ", ", in_test_scene)
	
	if not in_test_scene:
		self.add_to_group("savable")
	
	if (not in_test_scene) and SaveManager.contains_key("player"):
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
			DisplayServer.window_set_min_size(Vector2i(1280, 720))
	)
	
	listener.make_current()
	
	audio_player.stream_paused = true
	audio_player.volume_db = -100
	audio_player.play()

# Called on input events
# Rotation is calculated here, movement is calculated in _physics_process
func _input(event: InputEvent):
	if event is InputEventMouseButton and not in_puzzle_mode:
		# Capture the mouse on left-clicks while in movement mode.
		# This recaptures the mouse if it has been uncaptured e.g. from a window or tab change
		if event.button_index == 1:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Turn camera on mouse motion
	if event is InputEventMouseMotion:
		# Don't turn if interacting with a puzzle
		if in_puzzle_mode: return
		
		# If the player switches into movement mode on web while the mouse is moving,
		# a mouse movement event is generated with the relative coordinates set to the offset that
		# the mouse moved since the last time the pointer was captured, leading to a jarring rotation.
		# 
		# To filter out this event, clamp each axis to the range [-20, 20] pixels if it's less than
		# half a second since the player switched from puzzle mode.
		if OS.get_name() == "Web" and not in_puzzle_mode and time_since_last_change < 0.5:
			event.relative[0] = min(max(event.relative[0], -20), 20)
			event.relative[1] = min(max(event.relative[1], -20), 20)
		
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
	
	if event is InputEventKey and Input.is_action_just_pressed("free_mouse"):
		# Enter or leave puzzle mode
		if in_puzzle_mode:
			leave_puzzle_mode()
		else:
			enter_puzzle_mode()

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
func _process(delta):
	time_since_last_change += delta

	# If 'free_mouse' input was just pressed, update mouse mode
	if Input.is_action_just_pressed("free_mouse"):
		# If mouse is currently free, capture it
		if in_puzzle_mode:
			enter_puzzle_mode()
		# If mouse is currently captured, free it
		else:
			leave_puzzle_mode()
	
	# If the player is moving, play the footsteps sound
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_backward") or Input.is_action_pressed("move_forward"):
		audio_player.volume_db = 0
		audio_player.stream_paused = false
	else:
		audio_player.stream_paused = true

# Enters puzzle mode - shows the screen border and frees the mouse
func enter_puzzle_mode():
	time_since_last_change = 0
	
	# Show the screen border
	mode_indicator.show_border()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	in_puzzle_mode = true
	
	# Hide the input blocker
	input_blocker.visible = false
	

# Leaves puzzle mode - hides the screen border and captures the mouse
func leave_puzzle_mode():
	time_since_last_change = 0
	
	# Hide the screen border
	mode_indicator.hide_border()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	in_puzzle_mode = false
	get_tree().call_group("puzzle_tiles", "mouse_exit")
	
	# Show the input blocker
	input_blocker.visible = true

func save():
	SaveManager.set_state("player", {
		"position": [position.x, position.y, position.z],
		"rotation": [camera.rotation.x, camera.rotation.y, camera.rotation.z],
	})
