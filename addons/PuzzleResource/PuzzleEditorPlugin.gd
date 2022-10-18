extends EditorInspectorPlugin

class_name PuzzleEditorPlugin

var PuzzleEditor := preload("res://addons/PuzzleResource/PuzzleEditor.gd")

func can_handle(object: Object) -> bool:
	return object is Puzzle

func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	if path != "puzzle": return false
	add_custom_control(PuzzleEditor.new())
	#add_property_editor(path, PuzzleEditor.new())
	return true
	
