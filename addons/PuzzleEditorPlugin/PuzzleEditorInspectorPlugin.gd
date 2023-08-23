@tool
# EditorInspectorPlugin to load a custom editor for puzzles
extends EditorInspectorPlugin

class_name PuzzleEditorInspectorPlugin

# Editor to load
var PuzzleEditor := preload("res://addons/PuzzleEditorPlugin/PuzzleEditor.gd")
var SingleSolutionEditor := preload("res://addons/PuzzleEditorPlugin/SingleSolutionEditor.gd")

# Checks whether to check the properties of an object
func _can_handle(object: Object) -> bool:
	# Check type of object - only load editor into nodes of type Puzzle
	return object is PuzzleDesign or object is SingleSolutionPuzzle

func _parse_begin(object):
	if object is PuzzleDesign:
		add_property_editor_for_multiple_properties(
			"puzzle",
			["width", "height", "icons"],
			PuzzleEditor.new()
		)
	
	if object is SingleSolutionPuzzle:
		add_custom_control(SingleSolutionEditor.new())
