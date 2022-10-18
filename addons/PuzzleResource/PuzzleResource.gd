tool
extends EditorPlugin

class_name PuzzleResource

# A class member to hold the dock during the plugin life cycle.
var plugin: EditorInspectorPlugin

func _enter_tree():
	plugin = preload("res://addons/PuzzleResource/PuzzleEditorPlugin.gd").new()
	print("Adding inspector plugin ", plugin)
	add_inspector_plugin(plugin)

func _exit_tree():
	print("Removing inspector plugin ", plugin)
	remove_inspector_plugin(plugin)
