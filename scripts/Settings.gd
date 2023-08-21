extends Node

const settings_path := "user://settings.json"
const default_settings_path := "res://saves/default_settings.json"

var default_settings: Dictionary
var settings: Dictionary
var setting_callbacks: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	# Read the default settings
	var default_settings_file := FileAccess.open(default_settings_path, FileAccess.READ)
	default_settings = JSON.parse_string(default_settings_file.get_as_text())
	
	# If there is already a user settings file, read it
	if FileAccess.file_exists(settings_path):
		var settings_file := FileAccess.open(settings_path, FileAccess.READ)
		settings = JSON.parse_string(settings_file.get_as_text())
	# Otherwise, use the default settings
	else:
		settings = default_settings.duplicate()
	
	# If there are any settings which are in default_settings but not settings, copy them over
	for key in default_settings.keys():
		if not settings.has(key):
			settings[key] = default_settings[key]
		setting_callbacks[key] = []
	
	write_settings()

# Write settings back to the file 
func write_settings():
	var settings_file := FileAccess.open(settings_path, FileAccess.WRITE)
	settings_file.store_string(JSON.stringify(settings))

# Gets the setting with the given key
func get_setting(key: String) -> Variant:
	return settings[key]

# Sets the value of the setting with the given key and writes the settings to the file
func set_setting(key: String, value: Variant):
	settings[key] = value
	for callback in setting_callbacks[key]:
		callback.call(value)
	write_settings()

# Resets the setting with the given key, and returns the new value
func reset_setting(key: String) -> Variant:
	var default_value = default_settings[key]
	set_setting(key, default_value)
	return default_value

# Registers a callback for the given setting.
# The callback is called once immediately.
func register_callback(key: String, callback: Callable):
	callback.call(settings[key])
	setting_callbacks[key].append(callback)

