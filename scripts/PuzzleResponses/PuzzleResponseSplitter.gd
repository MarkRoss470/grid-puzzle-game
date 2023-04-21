extends Node

# Export parameters go here

@export var target_paths: Array[NodePath]
# This is to get around a bug in godot where Array[Node] can't be assigned to correctly
# Should be changed when that is fixed
@onready var targets := target_paths.map(get_node)

@export var params: Array[int]
@export var load_on_start := false

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func load_solved(_i: int):
	for i in len(targets):
		targets[i].load_solved(params[i])

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
	if load_on_start:
		load_solved(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
