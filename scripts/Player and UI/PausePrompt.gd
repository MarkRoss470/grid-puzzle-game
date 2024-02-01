extends CanvasLayer

# The time since the start of the game
var game_time := 0.0
# The root control - this is the node whose transparency will be set.
@onready var root_control: Control = $Control

# How long the prompt should be solid for before it fades out
var SOLID_TIME := 2.5
# How long the prompt should take to fade out
var FADE_TIME := 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Startups can be laggy on web, and it's more important for the player to know
	# that there is another option besides esc.
	if OS.get_name() == "Web":
		SOLID_TIME = 5.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	game_time += delta
	update_transparency()

func _notification(what: int):
	if what == NOTIFICATION_PAUSED:
		game_time = SOLID_TIME + FADE_TIME + 1
		update_transparency()

func update_transparency():
	# The prompt never re-appears after it fades out, so delete the node once it's gone.
	if game_time >= SOLID_TIME + FADE_TIME:
		queue_free()
	# If mid-fade, calculate the right opacity and set it
	elif game_time > SOLID_TIME:
		var time_into_fade := game_time - SOLID_TIME
		var opacity := 1 - time_into_fade / FADE_TIME
		
		root_control.modulate = Color(1, 1, 1, opacity)

