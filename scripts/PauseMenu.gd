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
	MOUSE_SENSITIVITY,
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

const settings := [
	"mouse_sensitivity",
]

enum SettingType {
	Slider,
}

const setting_types := [
	SettingType.Slider,
	
	null, # The EXIT option
]

@onready
var selection_triangle := $"Control/Selection Triangle"

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in len(setting_types):
		if setting_types[i] == SettingType.Slider:
			var slider: HSlider = menus[Menu.SETTINGS].get_child(i).get_child(0)
			var setting_value = Settings.get_setting(settings[i])
			slider.value = setting_value

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
	
	if current_menu == Menu.SETTINGS and setting_types[selected] == SettingType.Slider:
		# These updates triggers a value_changed event,
		# so there's no need to manually call on_menu_item_slider_input
		if Input.is_action_pressed("ui_right"):
			var slider: HSlider = menus[Menu.SETTINGS].get_child(selected).get_child(0)
			slider.value += slider.step
		
		if Input.is_action_pressed("ui_left"):
			var slider: HSlider = menus[Menu.SETTINGS].get_child(selected).get_child(0)
			slider.value -= slider.step
		
		if Input.is_action_just_pressed("reset"):
			var slider: HSlider = menus[Menu.SETTINGS].get_child(selected).get_child(0)
			var reset_value = Settings.reset_setting(settings[selected])
			slider.value = reset_value

func pause():
	get_tree().paused = true
	is_paused = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	set_menu(Menu.PAUSE)

func unpause():
	get_tree().paused = false
	is_paused = false
	
	if get_node("/root/Node3D/Player").in_puzzle_mode:
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
				SaveManager.save_all()
				get_tree().quit()
			PauseMenuItems.SAVE_GAME:
				SaveManager.save_all()
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

func on_menu_item_slider_input(value: float, menu_item: int):
	Settings.set_setting(settings[menu_item], value)
