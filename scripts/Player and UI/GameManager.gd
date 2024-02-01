extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	Settings.register_callback("fullscreen", func(value):
		if value:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			if OS.get_name() != "Web":
				DisplayServer.window_set_min_size(Vector2i(1280, 720))
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# If the game is not in fullscreen but the 'fullscreen' setting is set, unset the setting.
	# This means that the 'fullscreen' setting check button doesn't get out of sync with the fullscreen state
	# when the player closes fullscreen using esc on web.
	if Settings.get_setting("fullscreen"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			Settings.set_setting("fullscreen", false)

# Quits this instance of the game while launching another one.
# On web, reloads the tab.
func reload():
	if OS.get_name() == "Web":
		(func(): JavaScriptBridge.eval("window.location.reload();")).call_deferred()
		pass
	else:
		# Find the executable which is running for this game
		var executable_path = OS.get_executable_path()
		# Start a new instance of the game
		OS.create_process(executable_path, [])
		
	# Quit the current instance of the game
	get_tree().quit()
	
