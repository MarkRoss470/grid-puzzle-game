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


# Textures to be used as icons
const CELL_TEXTURES := [
	preload("res://textures/puzzle icons/diamond.svg"), 
	preload("res://textures/puzzle icons/pointer up.svg")
]

enum PuzzleCellIcon {
	DIAMOND, 
	POINTER_UP, 
	POINTER_RIGHT, 
	POINTER_DOWN, 
	POINTER_LEFT
}
# Indices into CELL_TEXTURES and the rotation they should have
const CELL_ICONS := [
	[0, 0], # Diamond
	[1, 0], # Pointer Up
	[1, 1], # Pointer Right
	[1, 2], # Pointer Down
	[1, 3], # Pointer Left
]

# Groups of icons for the puzzle editor
const ICON_GROUPS := [
	[
		PuzzleCellIcon.DIAMOND,
	],
	[
		PuzzleCellIcon.POINTER_UP, 
		PuzzleCellIcon.POINTER_RIGHT, 
		PuzzleCellIcon.POINTER_DOWN, 
		PuzzleCellIcon.POINTER_LEFT,
	],
]

# Uncomment if adding icons on edges
#enum PuzzleEdgeIcon {}
#const EDGE_TEXTURES := []

enum {WIDTH, HEIGHT, CELLS, ARR_LEN}

# What to reset a puzzle to if an invalid state is detected
const DEFAULT = [0, 0, [[]]]



