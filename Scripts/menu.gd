extends Control

# Menu.gd


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/SkyTower.tscn")


func _on_settings_pressed() -> void:
	var options = load("res://Scenes/Options.tscn").instantiate()
	get_tree().current_scene.add_child(options)


func _on_exit_pressed() -> void:
	get_tree().quit()
