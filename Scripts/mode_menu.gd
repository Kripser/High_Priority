extends Control


func _on_join_lobby_pressed() -> void:
	var lobby_id = int($VBoxContainer/LobbyIDInput.text)
	if lobby_id == 0:
		print("Invalid lobby ID")
		return
	SteamManager.join_lobby(lobby_id)


func _on_create_lobby_pressed() -> void:
	SteamManager.create_lobby()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
