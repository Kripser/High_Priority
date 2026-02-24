extends Control


func _on_join_lobby_pressed() -> void:
	pass # Replace with function body.
	print("Steam Running: ", Steam.isSteamRunning())
	print("Steam ID: ", Steam.getSteamID())
	print("Name: ", Steam.getPersonaName())


func _on_create_lobby_pressed() -> void:
	SteamManager.create_lobby()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
