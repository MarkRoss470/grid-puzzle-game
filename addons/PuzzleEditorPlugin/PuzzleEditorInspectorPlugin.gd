# EditorInspectorPlugin to load a custom editor for puzzles
extends EditorInspectorPlugin

class_name PuzzleEditorInspectorPlugin

# Editor to load
var PuzzleEditor := preload("res://addons/PuzzleEditorPlugin/PuzzleEditor.gd")

# Checks whether to check the properties of an object
func can_handle(object: Object) -> bool:
	# Check type of object - only load editor into nodes of type Puzzle
	return object is Puzzle

func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	# Only override editor for 'puzzle' property
	if path != "puzzle": return false
	# Load editor
	add_custom_control(PuzzleEditor.new())
	# Tells editor to remove default editor
	return true
	
