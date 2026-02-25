extends Camera3D

@export var mouse_sensitivity: float = 0.1
@export var bob_frequency: float = 8.0
@export var bob_amplitude: float = 0.05
@export var enable_bobbing: bool = true

@onready var player = get_parent()

var pitch := 0.0
var yaw := 0.0
var bob_timer := 0.0
var default_position := Vector3.ZERO

func _ready():
	default_position = position
	# Authority is set after add_child(), so defer the camera/mouse setup
	call_deferred("_setup_for_authority")

func _setup_for_authority():
	if player.is_multiplayer_authority():
		make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if not player.is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		# Accumulate rotation
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -90, 90)

		# Apply pitch to camera only
		rotation_degrees.x = pitch

		# Apply yaw to the player body
		player.rotation_degrees.y = yaw

func _process(delta: float) -> void:
	if not player.is_multiplayer_authority():
		return
	if not enable_bobbing:
		return

	var player_velocity = player.velocity
	var is_moving = Vector2(player_velocity.x, player_velocity.z).length() > 0.1
	var on_ground = player.is_on_floor()

	if is_moving and on_ground:
		bob_timer += delta * bob_frequency
		var bob_offset = Vector3(0, sin(bob_timer) * bob_amplitude, 0)
		position = default_position + bob_offset
	else:
		bob_timer = 0.0
		position = position.lerp(default_position, 10 * delta)  # smooth reset
