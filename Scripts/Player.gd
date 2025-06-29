extends CharacterBody3D

@export var move_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8
@export var role: String = "Test"

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis.z * input_dir.y + transform.basis.x * +input_dir.x).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	move_and_slide()
