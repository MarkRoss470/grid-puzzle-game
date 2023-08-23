@tool
extends EditorProperty

# Container for all editor elements
var editor_items := Panel.new()

# The current puzzle value
var current_value: PuzzleDesign

# The currently selected icon group
var current_icon_group := 0
# The index of the current item into the current group
var current_icon_in_group := 0
# The current selected icon
var current_icon := PuzzleDesignIcon.new()

# Called when a new node is selected - initialisation of UI
func _init():
	add_child(editor_items)

# Contants for UI layout
const WIDTH_LINE_Y := 0
const HEIGHT_LINE_Y := WIDTH_LINE_Y + 55

const ICON_GROUP_PICKER_Y := HEIGHT_LINE_Y + 65
const ICON_GROUP_PICKER_SIZE := 30
const ICON_GROUP_PICKER_OFFSET := 40

const ICON_PICKER_Y := ICON_GROUP_PICKER_Y + 50
const ICON_PICKER_SIZE := 30
const ICON_PICKER_OFFSET := 40

const COLOUR_PICKER_Y := ICON_PICKER_Y + 50
const COLOUR_PICKER_SIZE := 30
const COLOUR_PICKER_OFFSET := 40

const ROTATION_BUTTONS_Y := COLOUR_PICKER_Y + 50
const ROTATION_BUTTONS_SIZE := 30
const ROTATION_BUTTONS_OFFSET := 70

const GRID_Y := ROTATION_BUTTONS_Y + 50
const GRID_CELL_SIZE := 45
const GRID_EDGE_SIZE := 15
const GRID_CELL_OFFSET := GRID_CELL_SIZE + GRID_EDGE_SIZE

const ROTATE_ARROW_TEX := preload("res://textures/UI/rotate_arrow.jpg")

# Adds a text label and a number input next to each other at the given y position.
# Returns an array containing the label and the spinbox, in that order.
func add_label_and_spinbox(name: String, label_text: String, y: float, callback: String, callback_args: Array) -> Array:
	# Create label
	var label := Label.new()
	label.name = name + "_label"
	label.text = label_text
	label.set_position(Vector2(0, y))
	editor_items.add_child(label)

	# Create spinbox
	var input := SpinBox.new()
	input.name = name + "_input"
	input.set_position(Vector2(250, y))
	input.connect("value_changed", Callable(self, callback).bindv(callback_args))
	editor_items.add_child(input)
	
	return [label, input]

# Creates and returns a TextureRect
func create_texture_rect(name: String, texture: Texture2D, size: int, x: int, scale_x: int = 1) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = name
	rect.texture = texture
	rect.scale = Vector2(1.0 / texture.get_width(), 1.0 / texture.get_height()) * Vector2(size * scale_x, size)
	rect.set_position(Vector2(x, 0))
	return rect

# Creates and returns a ColorRect
func create_colour_rect(name: String, colour: Color, width: int, height: int, x: int) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = name
	rect.color = colour
	rect.set_size( Vector2(width, height))
	rect.set_position(Vector2(x, 0))
	return rect

# Sets up editor elements
# Only called when the + button is pressed, not at startup.
func init_editor():
	#reset_state()
	
	add_label_and_spinbox("width", "Width: ", WIDTH_LINE_Y, "on_width_change", [])
	add_label_and_spinbox("height", "Height: ", HEIGHT_LINE_Y, "on_height_change", [])
	
	# Set up icon group selectors
	var icon_group_picker := Container.new()
	icon_group_picker.name = "icon_group_picker"
	icon_group_picker.set_position(Vector2(0, ICON_GROUP_PICKER_Y))

	# Add icon groups to selector
	for i in len(PuzzleClasses.ICON_GROUPS):
		var icon_index: int = PuzzleClasses.ICON_GROUPS[i][0]
		
		var icon := create_texture_rect (
			"icon_group_picker-" + str(i),
			PuzzleClasses.CELL_TEXTURES[PuzzleClasses.ICON_GROUPS[i][0]],
			ICON_PICKER_SIZE,
			ICON_PICKER_OFFSET * i
		)
		
		icon.connect("gui_input", Callable(self, "set_current_icon_group").bind(i))
		icon_group_picker.add_child(icon)
	
	editor_items.add_child(icon_group_picker)
	
	# Set up colour selectors
	var colour_picker := Container.new()
	colour_picker.name = "colour_picker"
	colour_picker.set_position(Vector2(0, COLOUR_PICKER_Y))
	
	# Polulate colour selectors
	for i in len(PuzzleClasses.COLOURS):
		var icon := create_colour_rect (
			"colour_picker-" + str(i),
			PuzzleClasses.COLOURS[i],
			ICON_PICKER_SIZE, ICON_GROUP_PICKER_SIZE,
			ICON_GROUP_PICKER_OFFSET * i
		)
		icon.connect("gui_input", Callable(self, "set_current_colour").bind(i))
		colour_picker.add_child(icon)
	
	editor_items.add_child(colour_picker)
	
	var rotation_buttons := Container.new()
	rotation_buttons.name = "rotation_buttons"
	rotation_buttons.set_position(Vector2(0, ROTATION_BUTTONS_Y))
	
	var rotate_left := create_texture_rect ("rotate_left", ROTATE_ARROW_TEX, ROTATION_BUTTONS_SIZE, 0)
	rotate_left.connect("gui_input", Callable(self, "rotate_selection").bind(1))
	rotation_buttons.add_child(rotate_left)
	var rotate_right := create_texture_rect ("rotate_right", ROTATE_ARROW_TEX, ROTATION_BUTTONS_SIZE, ROTATION_BUTTONS_OFFSET, -1)
	rotate_right.connect("gui_input", Callable(self, "rotate_selection").bind(-1))
	rotation_buttons.add_child(rotate_right)
	
	editor_items.add_child(rotation_buttons)
	
	
	# Create the rect indicating the current icon
	var icon_indicator := create_colour_rect (
		"icon_indicator",
		Color.WHITE,
		ICON_GROUP_PICKER_SIZE, 10,
		0
	)
	editor_items.add_child(icon_indicator)
	
	populate_grid()

# Callback of icon group selectors
func set_current_icon_group(event: InputEvent, icon_group: int):
	if event is InputEventMouseButton and event.pressed:
		editor_items.remove_child(editor_items.get_node("icon_picker"))
		current_icon_group = icon_group
		current_icon_in_group = 0
		current_icon.icon = PuzzleClasses.ICON_GROUPS[icon_group][0]
		editor_items.get_node("icon_indicator").set_position(Vector2(ICON_PICKER_OFFSET * current_icon.icon, ICON_PICKER_Y + ICON_PICKER_SIZE))
		update_icons()

# Callback of icon selectors
func set_current_icon(event: InputEvent, icon: int):
	# Only respond to click events, otherwise hovering changes the icon
	if event is InputEventMouseButton and event.pressed:
		current_icon_in_group = icon
		current_icon.icon = PuzzleClasses.ICON_GROUPS[current_icon_group][current_icon_in_group]
		update_ui()

# Callback of colour selectors
func set_current_colour(event: InputEvent, colour: int):
	# Only respond to click events, otherwise hovering changes the icon
	if event is InputEventMouseButton and event.pressed:
		current_icon.colour = colour
		update_ui()

# Callback of grid cells
func set_cell_icon(event: InputEvent, x: int, y: int):
	# Only respond to click events, otherwise hovering changes the icon
	if event is InputEventMouseButton and event.pressed:
		#set cell to selected value on left click
		if event.button_index == 1:
			current_value.icons[x][y] = current_icon
			update_ui()
		#clear cell on right click
		elif event.button_index == 2:
			current_value.icons[x][y].icon = PuzzleClasses.EMPTY
			update_ui()
		
		emit_all()

# TODO: edge icons
# Adds the grid of cells to the editor
func populate_grid():
	# Set up grid container
	var grid := Container.new()
	grid.name = "grid"
	grid.set_position(Vector2(0, GRID_Y))
	
	for y in current_value.height:
		# Set up row container
		var row := Container.new()
		row.name = "row-" + str(y)
		row.set_position(Vector2(0, GRID_CELL_OFFSET * y))
		
		for x in current_value.width:
			# Set up cell
			var cell := ColorRect.new()
			cell.color = Color(0.5, 0.5, 0.5)
			cell.set_size(Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE))
			cell.name = "cell-" + str(x) + "-" + str(y)
			cell.set_position(Vector2(x * GRID_CELL_OFFSET, 0))
			row.add_child(cell)
			
			cell.connect("gui_input", Callable(self, "set_cell_icon").bind(x, y))
			
			# If cell has an icon, add it on top
			var cell_icon: PuzzleDesignIcon = current_value.icons[x][y]
			if cell_icon.icon != PuzzleClasses.EMPTY:
				# Set up icon
				var icon := TextureRect.new()
				icon.texture = PuzzleClasses.CELL_TEXTURES[cell_icon.icon]
				# Don't change the colour of group 0 because they're special icons
				if not cell_icon.icon in PuzzleClasses.DONT_RECOLOUR:
					icon.modulate = PuzzleClasses.COLOURS[cell_icon.colour]
				
				icon.scale = Vector2(1.0 / icon.texture.get_height(), 1.0 / icon.texture.get_height()) * GRID_CELL_SIZE
				icon.name = "icon-" + str(x) + "-" + str(y)
				icon.set_rotation(cell_icon.rotation * PI / 2)
				var icon_position := Vector2(GRID_CELL_OFFSET * x, 0)
				# Add an offset to icon_position to make icons stay in the same place when rotated
				match cell_icon.rotation:
					0:
						pass
					1:
						icon_position += Vector2(GRID_CELL_SIZE, 0)
					2:
						icon_position += Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
					3:
						icon_position += Vector2(0, GRID_CELL_SIZE)
				icon.set_position(icon_position)
				# Needed so that mouse events get recieved by the cell underneath
				icon.mouse_filter = MOUSE_FILTER_IGNORE
				
				row.add_child(icon)
		
		grid.add_child(row)
	
	editor_items.add_child(grid)

# Callback of width and height selectors
func on_width_change(new_width: float):
	if current_value.width != new_width:
		current_value.width = new_width
		# Make sure the arrays in current_value are the right dimensions
		resize_arrays()
		update_ui()
		# Save new state
		emit_all()


func on_height_change(new_height: float):
	if current_value.height != new_height:
		current_value.height = new_height
		# Make sure the arrays in current_value are the right dimensions
		resize_arrays()
		update_ui()
		# Save new state
		emit_all()

# Callback of rotate left/right buttons
# Adds the argument to current_rotation
func rotate_selection(event: InputEvent, rotation: int):
	if event is InputEventMouseButton and event.pressed:
		current_icon.rotation += rotation
		# Makes negative rotations work properly
		current_icon.rotation += 4
		# Wrap wrap rotation if >= 4
		current_icon.rotation %= 4
		
		update_ui()

# Updates UI elements to match current_value
func update_ui():
	# Set the value of the width and height selectors
	editor_items.get_node("width_input").value = current_value.width
	editor_items.get_node("height_input").value = current_value.height
	
	# Delete current grid and regenerate it
	editor_items.remove_child(editor_items.get_node("grid"))
	populate_grid()
	
	# Move the icon indicator under the right icon
	editor_items.get_node("icon_indicator").set_position(Vector2(ICON_PICKER_OFFSET * current_icon_in_group, ICON_PICKER_Y + ICON_PICKER_SIZE))
	
	update_icons()

	# Set the container to the right size for the grid
	var min_x = len(current_value.icons) * GRID_CELL_OFFSET
	var min_y = 50 + GRID_Y + current_value.height * GRID_CELL_OFFSET
	editor_items.custom_minimum_size = Vector2(max(400, min_x), max(400, min_y))

# Whether the call to _update_property is the first call
# Determines whether update_ui is called
var first_update = true

# Called whenever the value changes
# Is not called when changed due to this script calling emit_changed()
# Is called after initialisation of this script
func _update_property():	
	current_value = copy_puzzle_design(get_edited_object())
	
	if first_update:
		init_editor()
	
	resize_arrays()
	emit_all()
	
	update_ui()
	
	first_update = false

func emit_all():
	emit_changed("width", current_value.width)
	emit_changed("height", current_value.height)
	emit_changed("icons", copy_puzzle_design(current_value).icons)

# Adds or removes elements from arrays in current_value to make them the right size
func resize_arrays():
	# Get the right width and height
	var target_width = current_value.width
	var target_height = current_value.height
		
	# Get current width
	var cells: Array = current_value.icons
	var current_width := len(cells)
	
	# If array too long, slice it
	if current_width > target_width:
		cells = cells.slice(0, target_width)
	# If too short, pad with empty arrays
	elif current_width < target_width:
		for x in target_width - current_width:
			cells.append([])
	
	# Loop through all columns and resize them
	for x in target_width:
		# Get current height of this column
		var current_height := len(cells[x])
		# If too long, slice it
		if current_height > target_height:
			cells[x] = cells[x].slice(0, target_height)
		# If too short, pad with default cell
		elif current_height < target_height:
			for y in target_height - current_height:
				cells[x].append(PuzzleDesignIcon.new())
		
		var new_height := len(cells[x])
	
	current_value.icons = cells

func update_icons():
	if editor_items.has_node("icon_picker"):
		editor_items.remove_child(editor_items.get_node("icon_picker"))

	# Set up icon selectors
	var icon_picker := Container.new()
	icon_picker.name = "icon_picker"
	icon_picker.set_position(Vector2(0, ICON_PICKER_Y))

	# Add icons to selector
	for i in len(PuzzleClasses.ICON_GROUPS[current_icon_group]):
		var icon_index: int = PuzzleClasses.ICON_GROUPS[current_icon_group][i]

		# Set up icon
		var icon := TextureRect.new()
		icon.name = "icon_picker-" + str(i)

		icon.texture = PuzzleClasses.CELL_TEXTURES[PuzzleClasses.ICON_GROUPS[current_icon_group][i]]
		# Don't change the colour of group 0 because they're special icons
		if current_icon_group != 0:
			icon.modulate = PuzzleClasses.COLOURS[current_icon.colour]
		
		icon.scale = Vector2(1.0 / icon.texture.get_height(), 1.0 / icon.texture.get_height()) * ICON_PICKER_SIZE
		icon.set_rotation(current_icon.rotation * PI / 2)
		
		var icon_position := Vector2(ICON_PICKER_OFFSET * i, 0)
		# Add an offset to icon_position to make icons line up even when rotated
		match current_icon.rotation:
			0:
				pass
			1:
				icon_position += Vector2(ICON_GROUP_PICKER_SIZE, 0)
			2:
				icon_position += Vector2(ICON_GROUP_PICKER_SIZE, ICON_GROUP_PICKER_SIZE)
			3:
				icon_position += Vector2(0, ICON_GROUP_PICKER_SIZE)
		icon.set_position(icon_position)
		icon.connect("gui_input", Callable(self, "set_current_icon").bind(i))
		
		icon_picker.add_child(icon)
	
	editor_items.add_child(icon_picker)

# Resets the puzzle's state, but not any UI.
func reset_state():
	current_value = PuzzleDesign.new()
	emit_all()
	
# Returns a deep copy of the PuzzleDesign
func copy_puzzle_design(design: PuzzleDesign) -> PuzzleDesign:
	var new = PuzzleDesign.new()
	
	new.width = design.width
	new.height = design.height
	
	var icons_copy: Array[Array] = []
	for x in design.width:
		icons_copy.append([])
		for y in design.height:
			icons_copy[x].append(design.icons[x][y].duplicate())
	
	new.icons = icons_copy
	
	return new
