extends Node3D

# End position of the object
@export var end_position: Vector3
# End rotation of the object as Euler angles in degrees
@export var end_rotation: Vector3
# End scale of the object
@export var end_scale := Vector3(1, 1, 1)

# Calculate a Transform3D from the given position, rotation, and scale
@onready var end_basis := Basis.from_euler(end_rotation * PI / 180).scaled(end_scale)
@onready var end_transform := Transform3D(end_basis, end_position)
# Store the current transform
@onready var start_transform = transform

# The time in seconds over which to move
@export var transform_time := 1.0

var solved := false
var transform_progress := 0.0

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func on_puzzle_solve_immediate(_i: int):
	transform = end_transform
	solved = true

# Called on correct solution
func on_puzzle_solve(_i: int):
	solved = true

# Called on incorrect solution
func on_puzzle_unsolve(_i: int):
	solved = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if solved:
		transform_progress += delta / transform_time
	else:
		transform_progress -= delta / transform_time
	
	if transform_progress > 1:
		transform_progress = 1
	elif transform_progress < 0:
		transform_progress = 0
	
	transform = start_transform.interpolate_with(end_transform, transform_progress)
