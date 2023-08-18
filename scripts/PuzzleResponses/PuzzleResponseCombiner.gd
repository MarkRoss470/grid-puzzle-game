extends Node

# Export parameters go here
@export var num_inputs: int = 2

@export var target: Node
@export var target_param: int = 0

var solved_prevs: Array[bool] = []

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func on_puzzle_solve_immediate(i: int):
	solved_prevs[i] = true
	
	# If all the inputs are true, call the target's on_puzzle_solve_immediate
	if solved_prevs.all(func(b): return b):
		target.on_puzzle_solve_immediate(target_param)

# Called on correct solution
func on_puzzle_solve(i: int):
	solved_prevs[i] = true
	
	# If all the inputs are true, call the target's on_puzzle_solve_immediate
	if solved_prevs.all(func(b): return b):
		target.on_puzzle_solve(target_param)

# Called on incorrect solution
func on_puzzle_unsolve(i: int):
	solved_prevs[i] = false
	
	target.on_puzzle_unsolve(target_param)

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in num_inputs:
		solved_prevs.push_back(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
