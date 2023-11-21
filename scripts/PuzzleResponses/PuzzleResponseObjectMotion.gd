extends Node3D

# End position of the object
@export var end_position: Vector3
# End rotation of the object as Euler angles in degrees
@export var end_rotation: Vector3
# End scale of the object
@export var end_scale := Vector3(1, 1, 1)

# Calculate a Transform3D from the given position, rotation, and scale
@onready var end_basis := Basis.from_euler(end_rotation * PI / 180).scaled(end_scale)
@onready var end_transform := Transform3D(end_basis, end_position)
# Store the current transform
@onready var start_transform = transform

# The time in seconds over which to move
@export var transform_time := 1.0

var audio_player := AudioStreamPlayer3D.new()
@export var motion_sound: Sound = Sound.None

var solved := false
var transform_progress := 0.0

func _ready():
	audio_player.bus = "Objects"
	audio_player.panning_strength = 0.5
	
	add_child(audio_player)

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func on_puzzle_solve_immediate(_i: int):
	transform_progress = 1
	solved = true

# Called on correct solution
func on_puzzle_solve(_i: int):
	play_sound(motion_sound)
	solved = true

# Called on incorrect solution
func on_puzzle_unsolve(_i: int):
	play_sound(motion_sound)
	solved = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if solved:
		transform_progress += delta / transform_time
	else:
		transform_progress -= delta / transform_time
	
	if transform_progress > 1:
		transform_progress = 1
		audio_player.stop()
	elif transform_progress < 0:
		audio_player.stop()
		transform_progress = 0
	
	transform = start_transform.interpolate_with(end_transform, transform_progress)

func play_sound(sound: Sound):
	if sound == Sound.None: return
	
	audio_player.stream = load(sounds[sound])
	audio_player.play()

enum Sound {
	None,
	StoneDoor,
}

const sounds: Array[String] = [
	"", # No sound, placeholder path
	"res://sounds/stone door.mp3"
]
