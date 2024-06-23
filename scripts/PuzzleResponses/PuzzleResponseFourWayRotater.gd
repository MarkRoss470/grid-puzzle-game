extends Node

# Export parameters go here

## The time it takes to rotate a quarter circle
@export var rotation_time := 1.0
@export var current_rotation := 0.0

var target_rotation := 0

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func on_puzzle_solve_immediate(i: int):
	target_rotation = i
	current_rotation = i
	self.rotation = Vector3(0, current_rotation * PI / 2, 0)

# Called on correct solution
func on_puzzle_solve(i: int):
	target_rotation = i

# Called on incorrect solution
func on_puzzle_unsolve(_i: int):
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_rotation == target_rotation: return
	
	var clockwise_offset = fposmod(current_rotation - target_rotation, 4)
	var direction = 1 if clockwise_offset < 2 else -1
	
	var rotation_amount = delta / rotation_time
	if rotation_amount > abs(clockwise_offset - 2):
		current_rotation = target_rotation
	else:
		current_rotation += direction * rotation_amount
		current_rotation = fposmod(current_rotation, 4)
	
	self.rotation = Vector3(0, current_rotation * PI / 2, 0)
