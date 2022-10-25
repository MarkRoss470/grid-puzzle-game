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
	preload("res://textures/puzzle icons/pointer.svg"),
	preload("res://textures/puzzle icons/pointer angle.svg"),
	preload("res://textures/puzzle icons/pointer straight.svg"),
	preload("res://textures/puzzle icons/pointer triple.svg"),
	preload("res://textures/puzzle icons/pointer quadruple.svg"),
]

# Enum for cell icons
enum {
	NONE, # There is no cell. This does not mean an empty cell, which is instead represented by null
	POINTER_UP, 
	POINTER_RIGHT, 
	POINTER_DOWN, 
	POINTER_LEFT,
	POINTER_ANGLE_UP,
	POINTER_ANGLE_RIGHT,
	POINTER_ANGLE_DOWN,
	POINTER_ANGLE_LEFT,
	POINTER_STRAIGHT_UP,
	POINTER_STRAIGHT_RIGHT,
	POINTER_TRIPLE_UP,
	POINTER_TRIPLE_RIGHT,
	POINTER_TRIPLE_DOWN,
	POINTER_TRIPLE_LEFT,
	POINTER_QUADRUPLE,
}

# Indices into CELL_TEXTURES and the rotation they should have
const CELL_ICONS := [
	[0, 0], # Diamond
	[1, 0], # Pointer Up
	[1, 1], # Pointer Right
	[1, 2], # Pointer Down
	[1, 3], # Pointer Left
	[2, 0], # Pointer Angle Up
	[2, 1], # Pointer Angle Right
	[2, 2], # Pointer Angle Down
	[2, 3], # Pointer Angle Left
	[3, 0], # Pointer Straight Up
	[3, 1], # Pointer Straight Right
	[4, 0], # Pointer Triple Up
	[4, 1], # Pointer Triple Right
	[4, 2], # Pointer Triple Down
	[4, 3], # Pointer Triple Left
	[5, 0], # Pointer Quadruple
]

# Groups of icons for the puzzle editor
const ICON_GROUPS := [
	[
		NONE,
	],
	[
		POINTER_UP, 
		POINTER_RIGHT, 
		POINTER_DOWN, 
		POINTER_LEFT,
		POINTER_ANGLE_UP, 
		POINTER_ANGLE_RIGHT, 
		POINTER_ANGLE_DOWN, 
		POINTER_ANGLE_LEFT,
		POINTER_STRAIGHT_UP,
		POINTER_STRAIGHT_RIGHT,
	],
	[
		POINTER_TRIPLE_UP,
		POINTER_TRIPLE_RIGHT,
		POINTER_TRIPLE_DOWN,
		POINTER_TRIPLE_LEFT,
		POINTER_QUADRUPLE
	],
]

# Conversions from icon to group and index
const ICON_TO_GROUP := [
	[0, 0], # NONE
	[1, 0], # POINTER_UP
	[1, 1], # POINTER_RIGHT
	[1, 2], # POINTER_DOWN
	[1, 3], # POINTER_LEFT
	[1, 4], # Pointer Up-Right
	[1, 5], # Pointer Right-Down
	[1, 6], # Pointer Down-Left
	[1, 7], # Pointer Left-Up
]

# Uncomment if adding icons on edges
#enum PuzzleEdgeIcon {}
#const EDGE_TEXTURES := []

enum {WIDTH, HEIGHT, CELLS, ARR_LEN}

# What to reset a puzzle to if an invalid state is detected
const DEFAULT = [0, 0, [[]]]



# Which icons count as pointers
const POINTERS := [
	POINTER_UP, 
	POINTER_RIGHT, 
	POINTER_DOWN, 
	POINTER_LEFT,
	POINTER_ANGLE_UP,
	POINTER_ANGLE_RIGHT,
	POINTER_ANGLE_DOWN,
	POINTER_ANGLE_LEFT,
	POINTER_STRAIGHT_UP,
	POINTER_STRAIGHT_RIGHT,
	POINTER_TRIPLE_UP,
	POINTER_TRIPLE_RIGHT,
	POINTER_TRIPLE_DOWN,
	POINTER_TRIPLE_LEFT,
	POINTER_QUADRUPLE,
]

# Which directions each pointer icon points in
const POINT_DIRECTIONS := {
# Whether the pointer points    [ up,   right, down,  left ]
	POINTER_UP:                 [true,  false, false, false],
	POINTER_RIGHT:              [false, true,  false, false],
	POINTER_DOWN:               [false, false, true,  false],
	POINTER_LEFT:               [false, false, false, true ],
	POINTER_ANGLE_UP:           [true,  true,  false, false],
	POINTER_ANGLE_RIGHT:        [false, true,  true,  false],
	POINTER_ANGLE_DOWN:         [false, false, true,  true ],
	POINTER_ANGLE_LEFT:         [true,  false, false, true ],
	POINTER_STRAIGHT_UP:        [true,  false, true,  false],
	POINTER_STRAIGHT_RIGHT:     [false, true,  false, true ],
	POINTER_TRIPLE_UP:          [true,  true,  true,  false],
	POINTER_TRIPLE_RIGHT:       [false, true,  true,  true ],
	POINTER_TRIPLE_DOWN:        [true,  false, true,  true ],
	POINTER_TRIPLE_LEFT:        [true,  true,  false, true ],
	POINTER_QUADRUPLE:          [true,  true,  true,  true ],
}