extends CharacterBody3D

@export var npc_type: String = ""

func _ready():
	var mat = StandardMaterial3D.new()
	match npc_type:
		"Guest":
			mat.albedo_color = Color(1.0, 0.6, 0.8)
		"Chef":
			mat.albedo_color = Color(1.0, 1.0, 1.0)
		_:
			mat.albedo_color = Color(0.5, 0.5, 0.5)
	$MeshInstance3D.material_override = mat
