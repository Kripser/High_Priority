extends CharacterBody3D

@export var move_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8
@export var role: String = ""

func _ready():
	$Hitman.visible = false
	$MeshInstance3D.visible = true

	var mat = StandardMaterial3D.new()
	match role:
		"Hitman":
			mat.albedo_color = Color(0.1, 0.1, 0.1)
		"VIP":
			mat.albedo_color = Color(1.0, 0.8, 0.0)
		"Guard":
			mat.albedo_color = Color(0.2, 0.4, 0.9)
		_:
			mat.albedo_color = Color(0.5, 0.5, 0.5)
	$MeshInstance3D.material_override = mat

func _physics_process(delta: float) -> void:
	
	if not is_multiplayer_authority():
		return
	
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
