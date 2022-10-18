tool
extends Node

class_name PuzzleClasses

const COLOURS := [
	Color(0, 0, 0), #Black
	Color(1, 1, 1), #White
	Color(1, 0, 0), #Red
	Color(0, 1, 0), #Green
	Color(0, 0, 1), #Blue 
]

enum PuzzleCellIcon {}
const CELL_TEXTURES := [preload("res://textures/diamond.png"), preload("res://icon.png")]

enum PuzzleEdgeIcon {}
const EDGE_TEXTURES := []

enum {WIDTH, HEIGHT, CELLS, EDGES_HORIZONTAL, EDGES_VERTICAL, ARR_LEN}

const DEFAULT = [0, 0, [[]], [[]], [[]]]

func _ready():
	pass


