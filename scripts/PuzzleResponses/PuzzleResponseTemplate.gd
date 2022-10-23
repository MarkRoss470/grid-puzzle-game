extends Node

# Export parameters go here

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func load_solved(_i: int):
	pass

# Called on correct solution
func on_puzzle_solve(_i: int):
	pass

# Called on incorrect solution
func on_puzzle_unsolve(_i: int):
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
