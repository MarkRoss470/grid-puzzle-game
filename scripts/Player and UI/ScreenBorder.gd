extends CanvasLayer

class_name ScreenBorder

@export var container: Control

# Whether the border should be currently showing
var showing := false

# The fade progress, from 0 to 1
# 0.0 = completely transparent
# 1.0 = completely opaque
var fade_progress := 0.0

# The time for the border to fade in and out, in seconds
const fade_time := 0.2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# If fading in
	if showing and fade_progress < 1.0:
		fade_progress += delta / fade_time
		
		# If reached full opacity
		if fade_progress >= 1.0:
			fade_progress = 1.0
	
	# If fading out
	if !showing and fade_progress > 0.0:
		fade_progress -= delta / fade_time
		
		# If reached full transparency
		if fade_progress <= 0.0:
			fade_progress = 0.0
			self.visible = false
	
	# The `modulate` property clips the value of each colour drawn. 
	# Setting only the alpha part effectively sets the opacity.
	container.modulate = Color(1, 1, 1, fade_progress)

func show_border():
	self.visible = true
	showing = true


func hide_border():
	showing = false

