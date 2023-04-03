@tool
extends EditorPlugin

# A class member to hold the dock during the plugin life cycle.
var inspector_plugin: EditorInspectorPlugin
var gizmo_plugin: EditorNode3DGizmoPlugin

# Called when plugin is loaded
func _enter_tree():
	# Get inspector plugin
	inspector_plugin = preload("res://addons/PuzzleEditorPlugin/PuzzleEditorInspectorPlugin.gd").new()
	print("Adding inspector plugin ", inspector_plugin)
	# Load inspector plugin
	add_inspector_plugin(inspector_plugin)
	
	gizmo_plugin = preload("res://addons/PuzzleEditorPlugin/PuzzleGizmo.gd").new()
	print("Adding gizmo plugin ", gizmo_plugin)
	add_node_3d_gizmo_plugin(gizmo_plugin)

# Called when plugin is unloaded
func _exit_tree():
	print("Removing inspector plugin ", inspector_plugin)
	# Unload inspector plugins
	remove_inspector_plugin(inspector_plugin)
	remove_node_3d_gizmo_plugin(gizmo_plugin)
