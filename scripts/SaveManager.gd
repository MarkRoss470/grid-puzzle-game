extends Node

const default_save_path := "res://saves/default_save.json"
const save_path := "user://save.json"

var states: Dictionary

# The time in seconds since the last time the game was saved
var time_since_last_save := 0.0
# Autosave every 2 minutes
const seconds_between_autosaves := 120.0
# Whether the save file was just deleted
var just_deleted := false

# Called when the node enters the scene tree for the first time.
func _ready():	
	# If there is already a user settings file, read it
	if FileAccess.file_exists(save_path):
		var save_file := FileAccess.open(save_path, FileAccess.READ)
		states = JSON.parse_string(save_file.get_as_text())
	# Otherwise, use the default settings
	else:
		# Read the default save
		var default_save_file := FileAccess.open(default_save_path, FileAccess.READ)
		var default_save: Dictionary = JSON.parse_string(default_save_file.get_as_text())
		states = default_save.duplicate()

# Gets whether the given key is in the save file
func contains_key(key: String) -> bool:
	return states.has(key)

# Gets the state for the given key
func get_state(key: String) -> Variant:
	return states[key]

# Sets the state for the given key
func set_state(key: String, value: Variant):
	states[key] = value

# Makes all nodes in the `savable` group save their state, then write the save file
func save_all():
	# Call the `save` method on all nodes
	get_tree().call_group("savable", "save")
	
	# Write the save file as JSON
	var save_file := FileAccess.open(save_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(states))
	
	time_since_last_save = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_since_last_save += delta
	
	if time_since_last_save > seconds_between_autosaves:
		SaveManager.save_all()

func _notification(what):
	# When the game is closing, save the state
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# If this close is the reload after the save file was reset, don't re-write the file.
		if not just_deleted:
			SaveManager.save_all()

func reset_save():
	DirAccess.remove_absolute(save_path)
	just_deleted = true
