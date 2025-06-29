extends Camera3D

@export var mouse_sensitivity: float = 0.1
@onready var player = get_parent()

var pitch := 0.0
var yaw := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Accumulate rotation
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -90, 90)

		# Apply pitch to camera only
		rotation_degrees.x = pitch

		# Apply yaw to the player body
		player.rotation_degrees.y = yaw
