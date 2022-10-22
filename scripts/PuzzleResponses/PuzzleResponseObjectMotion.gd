extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(Vector3) var displacement := Vector3(0, 1, 0)
export(float) var time := 1.0

# True if moving toward (or at) solved state
# False if moving toward (or at) unsolved state
var movement_multiplier := 1
var start_location: Vector3
var end_location: Vector3
var target_location: Vector3

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
	start_location = transform.origin
	target_location = start_location
	end_location = start_location + displacement

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if transform.origin != target_location:
		var current_to_destination := target_location - transform.origin
		translate(displacement * movement_multiplier * delta / time)
		# Dot product of two vectors is negative if they are more than 90deg apart
		# So it can be used to test if motion reached target
		# Checks if vector from object to destination flips after translation 
		if current_to_destination.dot(target_location - transform.origin) < 0:
			transform.origin = target_location
