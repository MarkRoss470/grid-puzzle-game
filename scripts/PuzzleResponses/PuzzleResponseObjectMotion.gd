extends CharacterBody3D

# The offset from the current position to move to when activates
@export var displacement := Vector3(0, 1, 0)
# The time in seconds over which to move
@export var time := 1.0

# The speed to move at, relative to the distance and time parameters
# 1 if moving toward (or at) solved state
# -1 if moving toward (or at) unsolved state
var movement_multiplier := 1
# The starting location
var start_location: Vector3
# The calculated end location
var end_location: Vector3
# The location which is currently being moved towards
var target_location: Vector3

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func load_solved(_i: int):
	movement_multiplier = 1
	target_location = end_location
	transform.origin = end_location

# Called on correct solution
func on_puzzle_solve(_i: int):
	movement_multiplier = 1
	target_location = end_location

# Called on incorrect solution
func on_puzzle_unsolve(_i: int):
	movement_multiplier = -1
	target_location = start_location

# Called when the node enters the scene tree for the first time.
func _ready():
	# Calculate start and end locations
	start_location = transform.origin
	end_location = start_location + displacement
	
	target_location = start_location

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	# If the target is not reached
	if transform.origin != target_location:
		var current_to_destination := target_location - transform.origin
		translate(displacement * movement_multiplier * delta / time)
		
		# Dot product of two vectors is negative if they are more than 90deg apart
		# So it can be used to test if motion reached target
		# Checks if the angle `frame start location -> target -> frame end location` is acute
		
		# If motion overshot target_end, set location exactly
		if current_to_destination.dot(target_location - transform.origin) < 0:
			transform.origin = target_location
