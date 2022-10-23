# Makes script run in editor
tool
extends Node

# Makes consts accessible from other files
class_name PuzzleClasses

# Colours to be used for icons
const COLOURS := [
	Color(0, 0, 0), # Black
	Color(1, 1, 1), # White
	Color(1, 0, 0), # Red
	Color(0, 1, 0), # Green
	Color(0, 0, 1), # Blue 
]

enum PuzzleCellIcon {DIAMOND}
const CELL_TEXTURES := [preload("res://textures/puzzle icons/diamond.svg")]

# Uncomment if adding icons on edges
#enum PuzzleEdgeIcon {}
#const EDGE_TEXTURES := []

enum {WIDTH, HEIGHT, CELLS, ARR_LEN}

# What to reset a puzzle to if an invalid state is detected
const DEFAULT = [0, 0, [[]]]



