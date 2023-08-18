extends CanvasLayer

enum Menu {
	PAUSE,
	SETTINGS,
}

enum PauseMenuItems {
	SAVE_AND_QUIT,
	SAVE_GAME,
	SETTINGS,
	RETURN_TO_GAME,
}

enum SettingsMenuItems {
	EXIT,
}

var is_paused := false
var selected := 0
var current_menu := Menu.PAUSE

@onready
var menus: Array[VBoxContainer] = [
	$Control/Pause,
	$Control/Settings,
]

@onready
var selection_triangle := $"Control/Selection Triangle"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.visible = is_paused
	
	if Input.is_action_just_pressed("pause"):
		if !is_paused:
			pause()
		else:
			if current_menu == Menu.PAUSE:
				unpause()
			elif current_menu == Menu.SETTINGS:
				set_menu(Menu.PAUSE)
	
	# Don't process other actions unless the game is paused
	if !is_paused:
		return
	
	if Input.is_action_just_pressed("ui_down"):
		selected += 1
		if selected >= menus[current_menu].get_child_count():
			selected -= 1
		
		set_pointer_position()
		
	if Input.is_action_just_pressed("ui_up"):
		selected -= 1
		if selected < 0:
			selected += 1
		
		set_pointer_position()
	
	if Input.is_action_just_pressed("ui_accept"):
		select_item()

func pause():
	get_tree().paused = true
	is_paused = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	set_menu(Menu.PAUSE)

func unpause():
	get_tree().paused = false
	is_paused = false
	
	if get_node("/root/Node3D/Player").mouse_is_free:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_menu(menu: int):
	selected = 0
	current_menu = menu
	
	for i in len(menus):
		menus[i].visible = i == current_menu
	
	set_pointer_position()

func set_pointer_position():
	selection_triangle.reparent(menus[current_menu].get_child(selected), false)

func select_item():
	if current_menu == Menu.PAUSE:
		match selected:
			PauseMenuItems.SAVE_AND_QUIT:
				# TODO: save game first
				get_tree().quit()
			PauseMenuItems.SAVE_GAME:
				pass # TODO: save game
			PauseMenuItems.SETTINGS:
				set_menu(Menu.SETTINGS)
			PauseMenuItems.RETURN_TO_GAME:
				unpause()
	elif current_menu == Menu.SETTINGS:
		match selected:
			SettingsMenuItems.EXIT:
				set_menu(Menu.PAUSE)

func on_menu_item_mouse_entered(menu_item: int):
	selected = menu_item
	set_pointer_position()

func on_menu_item_gui_input(event: InputEvent, menu_item: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			selected = menu_item
			select_item()

