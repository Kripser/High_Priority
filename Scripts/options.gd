extends Control


func _on_button_pressed() -> void:
	pass

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
