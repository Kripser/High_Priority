extends Node3D

@onready var debug_camera = $DebugCamera
var debug_active = false

func _ready():
	debug_camera.look_at($Player.position + Vector3(0, 1, 0))

func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_F3 and event.pressed:
		debug_active = !debug_active
		if debug_active:
			debug_camera.make_current()
		else:
			$Player/Camera3D.make_current()
