extends Node

# Makes consts accessible from other files
class_name PuzzleClasses

# Colours to be used for icons
const COLOURS: Array[Color] = [
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
const CELL_TEXTURES: Array[Texture2D] = [
	preload("res://textures/puzzle icons/diamond.svg"), 
	preload("res://textures/puzzle icons/empty.jpg"), # EMPTY
	preload("res://textures/puzzle icons/pointers/pointer.svg"), # POINTER_SINGLE
	preload("res://textures/puzzle icons/pointers/pointer angle.svg"), # POINTER_DOUBLE_ANGLE
	preload("res://textures/puzzle icons/pointers/pointer straight.svg"), # POINTER_DOUBLE_STRAIGHT
	preload("res://textures/puzzle icons/pointers/pointer triple.svg"), # POINTER_TRIPLE
	preload("res://textures/puzzle icons/pointers/pointer quadruple.svg"), # POINTER_QUADRAPLE
	preload("res://textures/puzzle icons/square.svg"), # SQUARE
	preload("res://textures/puzzle icons/circle.svg"), # CIRCLE
	preload("res://textures/puzzle icons/symmetry icons/horizontal.svg"), # SYMMETRY_HORIZONTAL
	preload("res://textures/puzzle icons/symmetry icons/vertical.svg"), # SYMMETRY_VERTICAL
	
]

# Textures to be used as icons
const HINT_TEXTURES: Array[Texture2D] = [
	null, null, # Padding to make the indices match up
	preload("res://textures/puzzle icons/pointers/pointer hint.svg"), # POINTER_SINGLE
	preload("res://textures/puzzle icons/pointers/pointer angle hint.svg"), # POINTER_DOUBLE_ANGLE
	preload("res://textures/puzzle icons/pointers/pointer straight hint.svg"), # POINTER_DOUBLE_STRAIGHT
	preload("res://textures/puzzle icons/pointers/pointer triple hint.svg"), # POINTER_TRIPLE
]

# Enum for cell icons
enum {
	NO_CELL, # There is no cell.
	EMPTY, # An empty cell
	
	POINTER_SINGLE, # One pointer. 
		# A rotation of 0 means up.
	POINTER_DOUBLE_ANGLE, # Two pointers at 90 degrees from each other.
		# A rotation of 0 means up-right.
	POINTER_DOUBLE_STRAIGHT, # Two pointers at 180 degrees from each other.
		# A rotation of 0 means up-down.
	POINTER_TRIPLE, # Three pointers, each at 90 degrees from each other.
		# A rotation of 0 means up-left-down.
	POINTER_QUADRUPLE, # Four pointers, each at 90 degrees from each other.
	
	SQUARE,
	CIRCLE,
	
	SYMMETRY_HORIZONTAL,
	SYMMETRY_VERTICAL,
}

# Groups of icons for the puzzle editor
const ICON_GROUPS: Array[Array] = [
	[ # Group of special icons
		NO_CELL,
		EMPTY,
	],
	[ # Group of pointers
		POINTER_SINGLE,
		POINTER_DOUBLE_ANGLE,
		POINTER_DOUBLE_STRAIGHT,
		POINTER_TRIPLE,
		POINTER_QUADRUPLE,
	],
	[ # Group of icons which require presence / absence of other symbols in same region
		SQUARE,
		CIRCLE,
	],
	[ # Group of symmetry icons
		SYMMETRY_HORIZONTAL,
		SYMMETRY_VERTICAL,
	],
]

# Which icons shouldn't be recoloured in the editor
const DONT_RECOLOUR: Array[int] = [
	NO_CELL,
	EMPTY
]

# The contents of a puzzle
enum {
	WIDTH, HEIGHT, # The width and height of the puzzle
	CELLS, # The icons and starting rotations of the cells
	# ANOTHER_THING, # Uncomment to force reset in editor
	ARR_LEN
}

# The contents of a cell
enum {
	ICON, # The type of icon
	COLOUR, # The colour of the icon
	ROTATION # The starting rotation of the cell
}

# What to reset a puzzle to if an invalid state is detected
# Function rather than a const to prevent aliasing
static func get_default() -> Array:
	return [0, 0, [[]]]
# Gets the default value of a cell
static func get_default_cell():
	return [EMPTY, 0, 0]

# Which icons count as pointers
const POINTERS: Array[int] = [
	POINTER_SINGLE,
	POINTER_DOUBLE_ANGLE,
	POINTER_DOUBLE_STRAIGHT,
	POINTER_TRIPLE,
	POINTER_QUADRUPLE,
]

# Which icons the player can rotate
const ROTATABLE: Array[int] = [
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
