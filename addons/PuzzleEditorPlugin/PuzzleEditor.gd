extends EditorProperty

# Container for all UI elements
var container := Panel.new()
# Container for all editor elements
var editor_items := Control.new()
# Button to expand / retract the puzzle editor
var expand_button := Button.new()

# Whether the editor elements have been initialised
var initialised := false
# Whether the editor is currently expanded
var expanded := false

# The current puzzle value
var current_value = PuzzleClasses.get_default()

# The currently selected icon group
var current_icon_group := 0
# The index of the current item into the current group
var current_icon := 0
# The currently selected colour
var current_colour := 0
# The current rotation
var current_rotation := 0

var texture_cache: TextureCache = null

# Called when a new node is selected - initialisation of UI
func _init():
	texture_cache = TextureCache.new()
	
	# Set up the +/- button
	expand_button.set_anchor(MARGIN_RIGHT, 1)
	expand_button.text = "+"
	expand_button.connect("pressed", self, "on_expand_button_pressed")
	
	container.add_child(expand_button)
	container.add_child(editor_items)
	# Set the minumum size of the container to properly layout other components
	container.rect_min_size = Vector2(400, 50)
	
	# Set container as the root node
	add_child(container)

# Contants for UI layout
const WIDTH_LINE_Y := 10
const HEIGHT_LINE_Y := WIDTH_LINE_Y + 55

const KEY_X_Y := HEIGHT_LINE_Y + 55
const KEY_Y_Y := KEY_X_Y + 55
const KEY_TARGET_Y := KEY_Y_Y + 55

const ICON_GROUP_PICKER_Y := KEY_TARGET_Y + 65
const ICON_GROUP_PICKER_SIZE := 30
const ICON_GROUP_PICKER_OFFSET := 40

const ICON_PICKER_Y := ICON_GROUP_PICKER_Y + 50
const ICON_PICKER_SIZE := 30
const ICON_PICKER_OFFSET := 40

const COLOUR_PICKER_Y := ICON_PICKER_Y + 100
const COLOUR_PICKER_SIZE := 30
const COLOUR_PICKER_OFFSET := 40

const ROTATION_BUTTONS_Y := COLOUR_PICKER_Y + 100
const ROTATION_BUTTONS_SIZE := 30
const ROTATION_BUTTONS_OFFSET := 70

const GRID_Y := ROTATION_BUTTONS_Y + 50
const GRID_CELL_SIZE := 45
const GRID_EDGE_SIZE := 15
const GRID_CELL_OFFSET := GRID_CELL_SIZE + GRID_EDGE_SIZE

const ROTATE_ARROW_TEX := preload("res://textures/UI/rotate_arrow.jpg")
var ROTATE_BUTTON_SCALE := Vector2(1.0 / ROTATE_ARROW_TEX.get_height(), 1.0 / ROTATE_ARROW_TEX.get_height()) * ICON_PICKER_SIZE

func add_label_and_spinbox(name: String, label_text: String, y: float, callback: String, callback_args: Array):
	# Create label
	var label := Label.new()
	label.name = name + "_label"
	label.text = label_text
	label.set_position(Vector2(0, y))
	editor_items.add_child(label)

	# Create spinbox
	var input := SpinBox.new()
	input.name = name + "_input"
	input.set_anchor(MARGIN_LEFT, 1)
	input.set_anchor(MARGIN_RIGHT, 1)
	input.set_position(Vector2(250, y))
	input.connect("value_changed", self, callback, callback_args)
	editor_items.add_child(input)

# Sets up editor elements
func init_editor():
	initialised = true

	#reset_state()

	editor_items.set_anchor(MARGIN_LEFT, 0)
	editor_items.set_anchor(MARGIN_RIGHT, 1)
	editor_items.set_position(Vector2(10, 40))
	
	add_label_and_spinbox("width", "Width: ", WIDTH_LINE_Y, "on_dimension_change", [0])
	add_label_and_spinbox("height", "Height: ", HEIGHT_LINE_Y, "on_dimension_change", [1])
	add_label_and_spinbox("key_x", "Key X: ", KEY_X_Y, "on_key_pos_change", [0])
	add_label_and_spinbox("key_y", "Key Y: ", KEY_Y_Y, "on_key_pos_change", [1])
	add_label_and_spinbox("key_target", "Target rotation: ", KEY_TARGET_Y, "on_key_target_change", [])
	
	# Set up icon group selectors
	var icon_group_picker := Container.new()
	icon_group_picker.name = "icon_group_picker"
	icon_group_picker.set_position(Vector2(0, ICON_GROUP_PICKER_Y))

	# Add icon groups to selector	reset_state()
	for i in range(len(PuzzleClasses.ICON_GROUPS)):
		var icon_index: int = PuzzleClasses.ICON_GROUPS[i][0]

		# Set up icon
		var icon := TextureRect.new()
		icon.name = "icon_group_picker-" + str(i)
		icon.texture = texture_cache.get_coloured_cell_texture([icon_index, current_colour])
		icon.rect_scale = Vector2(1.0 / icon.texture.get_height(), 1.0 / icon.texture.get_height()) * ICON_PICKER_SIZE
		icon.set_position(Vector2(ICON_PICKER_OFFSET * i, 0))
		icon.connect("gui_input", self, "set_current_icon_group", [i])
		icon_group_picker.add_child(icon)

	editor_items.add_child(icon_group_picker)
	
	# Set up icon selectors
	var colour_picker := Container.new()
	colour_picker.name = "colour_picker"
	colour_picker.set_position(Vector2(0, COLOUR_PICKER_Y))
	
	# Add icons to selector
	for i in range(len(PuzzleClasses.COLOURS)):
		# Set up icon
		var icon := ColorRect.new()
		icon.name = "colour_picker-" + str(i)
		icon.color = PuzzleClasses.COLOURS[i]
		icon.set_size( Vector2(ICON_PICKER_SIZE, ICON_PICKER_SIZE))
		icon.set_position(Vector2(ICON_PICKER_OFFSET * i, 0))
		icon.connect("gui_input", self, "set_current_colour", [i])
		colour_picker.add_child(icon)
	
	editor_items.add_child(colour_picker)

	var rotation_buttons := Container.new()
	rotation_buttons.name = "rotation_buttons"
	rotation_buttons.set_position(Vector2(0, ROTATION_BUTTONS_Y))
	
	var rotate_left := TextureRect.new()
	rotate_left.name = "rotate_left"
	rotate_left.rect_scale = ROTATE_BUTTON_SCALE
	rotate_left.set_position(Vector2(0, 0))
	rotate_left.texture = ROTATE_ARROW_TEX
	rotate_left.connect("gui_input", self, "rotate_selection", [1])
	rotation_buttons.add_child(rotate_left)
	
	var rotate_right := TextureRect.new()
	rotate_right.name = "rotate_right"
	rotate_right.rect_scale = ROTATE_BUTTON_SCALE * Vector2(-1, 1)
	rotate_right.set_position(Vector2(ROTATION_BUTTONS_OFFSET, 0))
	rotate_right.texture = ROTATE_ARROW_TEX
	rotate_right.connect("gui_input", self, "rotate_selection", [-1])
	rotation_buttons.add_child(rotate_right)

	editor_items.add_child(rotation_buttons)

	# Set up rectangle to indicate currently selected icon
	var icon_indicator := ColorRect.new()
	icon_indicator.name = "icon_indicator"
	icon_indicator.set_position(Vector2(0, ICON_PICKER_Y + ICON_PICKER_SIZE))
	icon_indicator.set_size(Vector2(ICON_PICKER_SIZE, 10))
	editor_items.add_child(icon_indicator)

	set_current_icon_group(null, 0)
	populate_grid()
	

func on_key_pos_change(value: float, axis: int):
	current_value[PuzzleClasses.KEY_X + axis] = value
	# Save new state
	emit_changed("puzzle", current_value)

func on_key_target_change(value: float):
	current_value[PuzzleClasses.KEY_TARGET_ROTATION] = value

# Callback of icon group selectors
func set_current_icon_group(event: InputEvent, icon_group: int):
	if event == null or event is InputEventMouseButton and event.pressed:
		if event != null:
			editor_items.remove_child(editor_items.get_node("icon_picker"))
		current_icon_group = icon_group
		current_icon = 0
		editor_items.get_node("icon_indicator").set_position(Vector2(ICON_PICKER_OFFSET * current_icon, ICON_PICKER_Y + ICON_PICKER_SIZE))
		update_icons()
		
		

# Callback of icon selectors
func set_current_icon(event: InputEvent, icon: int):
	# Only respond to click events, otherwise hovering changes the icon
	if event is InputEventMouseButton and event.pressed:
		current_icon = icon
		update_ui()

# Callback of colour selectors
func set_current_colour(event: InputEvent, colour: int):
	# Only respond to click events, otherwise hovering changes the icon
	if event is InputEventMouseButton and event.pressed:
		current_colour = colour
		update_ui()

# Callback of grid cells
func set_cell_icon(event: InputEvent, x: int, y: int):
	# Only respond to click events, otherwise hovering changes the icon
	if event is InputEventMouseButton and event.pressed:
		#set cell to selected value on left click
		if event.button_index == 1:
			current_value[PuzzleClasses.CELLS][x][y] = [
				PuzzleClasses.ICON_GROUPS[current_icon_group][current_icon],
				current_colour,
				current_rotation
			]
			update_ui()
		#clear cell on right click
		elif event.button_index == 2:
			current_value[PuzzleClasses.CELLS][x][y][0] = PuzzleClasses.EMPTY
			update_ui()

# TODO: edge icons
# Adds the grid of cells to the editor
func populate_grid():
	# Set up grid container
	var grid := Container.new()
	grid.name = "grid"
	grid.set_position(Vector2(0, GRID_Y))
	
	for y in range(current_value[PuzzleClasses.HEIGHT]):
		# Set up row container
		var row := Container.new()
		row.name = "row-" + str(y)
		row.set_position(Vector2(0, GRID_CELL_OFFSET * y))

		for x in range(current_value[PuzzleClasses.WIDTH]):
			# Set up cell
			var cell := ColorRect.new()
			cell.color = Color(0.5, 0.5, 0.5)
			cell.set_size(Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE))
			cell.name = "cell-" + str(x) + "-" + str(y)
			cell.set_position(Vector2(x * GRID_CELL_OFFSET, 0))
			row.add_child(cell)
			
			cell.connect("gui_input", self, "set_cell_icon", [x, y])
			
			# If cell has an icon, add it on top
			var cell_icon = current_value[PuzzleClasses.CELLS][x][y]
			if cell_icon[PuzzleClasses.ICON] != PuzzleClasses.EMPTY:
				# Set up icon
				var icon := TextureRect.new()
				icon.texture = texture_cache.get_coloured_cell_texture([cell_icon[0], cell_icon[1]])
				icon.rect_scale = Vector2(1.0 / icon.texture.get_height(), 1.0 / icon.texture.get_height()) * GRID_CELL_SIZE
				icon.name = "icon-" + str(x) + "-" + str(y)
				icon.set_rotation(cell_icon[PuzzleClasses.ROTATION] * PI / 2)
				var icon_position := Vector2(GRID_CELL_OFFSET * x, 0)
				# Add an offset to icon_position to make icons stay in the same place when rotated
				match cell_icon[PuzzleClasses.ROTATION]:
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
func on_dimension_change(value: float, dimension: int):
	current_value[dimension] = value
	# Make sure the arrays in current_value are the right dimensions
	resize_arrays()
	update_ui()
	# Save new state
	emit_changed("puzzle", current_value)

# Callback of +/- button
func on_expand_button_pressed():
	# If open, close
	if expanded:
		# Hide editor items
		editor_items.hide()
		# Make container small to shift other proprty editors back up
		container.rect_min_size = Vector2(400, 50)
		expand_button.text = "+"
		expanded = false
	# If closed, open
	else:
		# If first time opening, initialise the editor
		if not initialised: init_editor()
		editor_items.show()
		# Load data
		update_ui()
		expand_button.text = "-"
		expanded = true

# Callback of rotate left/right buttons
# Adds the argument to current_rotation
func rotate_selection(event: InputEvent, rotation: int):
	if event is InputEventMouseButton and event.pressed:
		current_rotation += rotation
		# Makes negative rotations work properly
		current_rotation += 4
		# Wrap wrap rotation if >= 4
		current_rotation %= 4
		
		update_ui()

# Updates UI elements to match current_value
func update_ui():
	
	# Set the value of the width and height selectors
	editor_items.get_node("width_input").value = current_value[PuzzleClasses.WIDTH]
	editor_items.get_node("height_input").value = current_value[PuzzleClasses.HEIGHT]
	# Delete current grid and regenerate it
	editor_items.remove_child(editor_items.get_node("grid"))
	populate_grid()
	
	# Move the icon indicator under the right icon
	editor_items.get_node("icon_indicator").set_position(Vector2(ICON_PICKER_OFFSET * current_icon, ICON_PICKER_Y + ICON_PICKER_SIZE))
	
	update_icons()
	
	var current_group = PuzzleClasses.ICON_GROUPS[current_icon_group]
	for i in range(len(current_group)):
		var icon_index: int = current_group[i]
		var item = editor_items.get_node("icon_picker/icon_picker-" + str(i))
		# Group 0 is for special values which have UI textures
		# So they shouldn't be recoloured
		if current_icon_group != 0:
			item.texture = texture_cache.get_coloured_cell_texture([icon_index, current_colour])
		else:
			item.texture = PuzzleClasses.CELL_TEXTURES[current_group[i]]
		item.set_rotation(current_rotation * PI / 2)

	# Set the container to the right size for the grid
	var min_x = len(current_value[PuzzleClasses.CELLS]) * GRID_CELL_OFFSET
	var min_y = 50 + GRID_Y + len(current_value[PuzzleClasses.CELLS][0]) * GRID_CELL_OFFSET
	container.rect_min_size = Vector2(max(400, min_x), max(400, min_y))

# Called whenever the value changes
# Is not called when changed due to this script calling emit_changed()
# Is called after initialisation of this script
func update_property():
	# Read the current value from the property.
	var new_value = get_edited_object()["puzzle"]
	
	# If the value is invalid, reset it to a blank puzzle
	if len(new_value) != PuzzleClasses.ARR_LEN:
		new_value = PuzzleClasses.get_default()
		emit_changed("puzzle", new_value)
	
	# If the value has not changed, do not update UI
	if (new_value == current_value):
		return
	
	current_value = new_value
	
	if expanded:
		update_ui()

# Adds or removes elements from arrays in current_value to make them the right size
func resize_arrays():
	# Get the right width and height
	var target_width_cells = current_value[PuzzleClasses.WIDTH]
	var target_height_cells = current_value[PuzzleClasses.HEIGHT]
	
	# Edges have different dimensions than cells
	var targets := [
		[target_width_cells, target_height_cells], 
	]
	
	var indices := [
		PuzzleClasses.CELLS, 
	]
	
	# Loop over indices
	for j in range(len(indices)):
		# Get index into current_value
		var i = indices[j]
		# Get target width and height for this iteration
		var target_width = targets[j][0]
		var target_height = targets[j][1]
		
		# Get current width
		var current_width := len(current_value[i])
		
		# If array too long, slice it
		if current_width > target_width:
			current_value[i] = current_value[i].slice(0, target_width - 1)
		# If too short, pad with empty arrays
		elif current_width < target_width:
			for x in range(target_width - current_width):
				current_value[i].append([])
		
		# Loop through all columns and resize them
		for x in range(target_width):
			# Get current height of this column
			var current_height := len(current_value[i][x])
			# If too long, slice it
			if current_height > target_height:
				current_value[i][x] = current_value[i][x].slice(0, target_height - 1)
			# If too short, pad with default cell
			elif current_height < target_height:
				for y in range(target_height - current_height):
					current_value[i][x].append(PuzzleClasses.get_default_cell())

func update_icons():
	if editor_items.has_node("icon_picker"):
		editor_items.remove_child(editor_items.get_node("icon_picker"))

	# Set up icon selectors
	var icon_picker := Container.new()
	icon_picker.name = "icon_picker"
	icon_picker.set_position(Vector2(0, ICON_PICKER_Y))

	# Add icons to selector
	for i in range(len(PuzzleClasses.ICON_GROUPS[current_icon_group])):
		var icon_index: int = PuzzleClasses.ICON_GROUPS[current_icon_group][i]

		# Set up icon
		var icon := TextureRect.new()
		icon.name = "icon_picker-" + str(i)

		icon.texture = texture_cache.get_coloured_cell_texture([icon_index, current_colour])
		icon.rect_scale = Vector2(1.0 / icon.texture.get_height(), 1.0 / icon.texture.get_height()) * ICON_PICKER_SIZE
		icon.set_rotation(current_rotation * PI / 2)
		var icon_position := Vector2(ICON_PICKER_OFFSET * i, 0)
		# Add an offset to icon_position to make icons line up even when rotated
		match current_rotation:
			0:
				pass
			1:
				icon_position += Vector2(ICON_GROUP_PICKER_SIZE, 0)
			2:
				icon_position += Vector2(ICON_GROUP_PICKER_SIZE, ICON_GROUP_PICKER_SIZE)
			3:
				icon_position += Vector2(0, ICON_GROUP_PICKER_SIZE)
		icon.set_position(icon_position)
		icon.connect("gui_input", self, "set_current_icon", [i])
		icon_picker.add_child(icon)
	
	editor_items.add_child(icon_picker)

# Resets the puzzle's state, but not any UI.
func reset_state():
	# '[] + ' Prevents aliasing between different puzzles
	current_value = [] + PuzzleClasses.get_default()
	emit_changed("puzzle", current_value)
