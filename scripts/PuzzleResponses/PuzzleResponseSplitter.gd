extends Node

# Export parameters go here

# This is to get around a bug in godot where Array[Node] can't be assigned to correctly
# Should be changed when that is fixed
@export var targets: Array[Node]

@export var params: Array[int]
@export var load_on_start := false

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func on_puzzle_solve_immediate(_i: int):
	print("Splitting immediately (", self.get_path(), ")")
	print(targets)
	
	for i in len(targets):
		(func(): targets[i].on_puzzle_solve_immediate(params[i])).call_deferred()

# Called on correct solution
func on_puzzle_solve(_i: int):
	for i in len(targets):
		targets[i].on_puzzle_solve(params[i])

# Called on incorrect solution
func on_puzzle_unsolve(_i: int):
	for i in len(targets):
		targets[i].on_puzzle_unsolve(params[i])

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("savable")
	
	if load_on_start:
		on_puzzle_solve_immediate(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
