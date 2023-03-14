extends Node

# Makes consts accessible from other files
class_name PuzzleClasses

# Colours to be used for icons
const COLOURS := [
	Color(0, 0, 0), # Black
	Color(1, 1, 1), # White
	Color(1, 0, 0), # Red
	Color(1, 0.5, 0), # Orange
	Color(1, 1, 0), # Yellow
	Color(0, 1, 0), # Green
	Color(0, 0, 1), # Blue
	Color(1, 0, 1), # Magenta
]


# Textures to be used as icons
const CELL_TEXTURES := [
	preload("res://textures/puzzle icons/diamond.svg"), 
	preload("res://textures/puzzle icons/diamond.svg"), # TODO: have different icons
	preload("res://textures/puzzle icons/pointer.svg"),
	preload("res://textures/puzzle icons/pointer angle.svg"),
	preload("res://textures/puzzle icons/pointer straight.svg"),
	preload("res://textures/puzzle icons/pointer triple.svg"),
	preload("res://textures/puzzle icons/pointer quadruple.svg"),
]

# Enum for cell icons
enum {
	NO_CELL, # There is no cell.
	EMPTY, # An empty cell
	POINTER_SINGLE, # One pointer. 
		#A rotation of 0 means up.
	POINTER_DOUBLE_ANGLE, # Two pointers at 90 degrees from each other.
		#A rotation of 0 means up-right.
	POINTER_DOUBLE_STRAIGHT, # Two pointers at 180 degrees from each other.
		#A rotation of 0 means up-down.
	POINTER_TRIPLE, # Three pointers, each at 90 degrees from each other.
		# A rotation of 0 means up-left-down.
	POINTER_QUADRUPLE, # Four pointers, each at 90 degrees from each other.
}

# Groups of icons for the puzzle editor
const ICON_GROUPS := [
	[
		NO_CELL,
		EMPTY,
	],
	[
		POINTER_SINGLE,
		POINTER_DOUBLE_ANGLE,
		POINTER_DOUBLE_STRAIGHT,
		POINTER_TRIPLE,
		POINTER_QUADRUPLE
	],
]

# Uncomment if adding icons on edges
#enum PuzzleEdgeIcon {}
#const EDGE_TEXTURES := []

# The contents of a puzzle
enum {WIDTH, HEIGHT, KEY_X, KEY_Y, CELLS, ARR_LEN}
# The contents of a cell
enum {ICON, COLOUR, ROTATION}

# What to reset a puzzle to if an invalid state is detected
const DEFAULT = [0, 0, 0, 0, [[]]]
const DEFAULT_CELL = [EMPTY, 0, 0]

# Which icons count as pointers
const POINTERS := [
	POINTER_SINGLE,
	POINTER_DOUBLE_ANGLE,
	POINTER_DOUBLE_STRAIGHT,
	POINTER_TRIPLE,
	POINTER_QUADRUPLE,
]

# Which directions each pointer icon points in
const POINT_DIRECTIONS := {
# Whether the pointer points    [up,    right, down,  left ]
	POINTER_SINGLE:             [true,  false, false, false],
	POINTER_DOUBLE_ANGLE:       [true,  true,  false, false],
	POINTER_DOUBLE_STRAIGHT:    [true,  false, true,  false],
	POINTER_TRIPLE:             [true,  true,  true,  false],
	POINTER_QUADRUPLE:          [true,  true,  true,  true ],
}
