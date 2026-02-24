extends Control

@onready var player_list = $PlayerList
@onready var start_button = $StartButton

func _ready():
	# Only host can start
	start_button.visible = SteamManager.is_host
	
	# Connect leave button
	$LeaveButton.connect("pressed", Callable(self, "_on_leave_pressed"))
	start_button.connect("pressed", Callable(self, "_on_start_pressed"))
	
	# Listen for member updates from SteamManager
	SteamManager.connect("lobby_members_updated", Callable(self, "_refresh_player_list"))
	
	$LobbyTitle.text = Steam.getFriendPersonaName(Steam.getLobbyOwner(SteamManager.lobby_id)) + "'s Lobby"
	
	_refresh_player_list()

func _refresh_player_list():
	# Clear existing entries
	print("Members array: ", SteamManager.lobby_members)
	for child in player_list.get_children():
		child.queue_free()
	
	for member_id in SteamManager.lobby_members:
	
		var hbox = HBoxContainer.new()
	
		#avatar box
		var avatar_rect = TextureRect.new()
		avatar_rect.name = "avatar_" + str(member_id)
		avatar_rect.custom_minimum_size = Vector2(32, 32)
		hbox.add_child(avatar_rect)
		
		var label = Label.new()
		label.text = Steam.getFriendPersonaName(member_id)
		hbox.add_child(label)
		
		player_list.add_child(hbox)
		
		Steam.getPlayerAvatar(Steam.AVATAR_SMALL, member_id)
	
	if not SteamManager.is_connected("avatar_loaded", Callable(self, "_on_avatar_loaded")):
		SteamManager.connect("avatar_loaded", Callable(self, "_on_avatar_loaded"))

func _on_avatar_loaded(user_id: int, buffer: Array):
	var avatar_rect = player_list.find_child("avatar_" + str(user_id), true, false)
	if avatar_rect == null:
		return
		
	var image = Image.create_from_data(32, 32, false, Image.FORMAT_RGBA8, buffer)
	var texture = ImageTexture.create_from_image(image)
	avatar_rect.texture = texture


func _on_leave_pressed():
	Steam.leaveLobby(SteamManager.lobby_id)
	SteamManager.lobby_id = 0
	SteamManager.lobby_members.clear()
	get_tree().change_scene_to_file("res://Scenes/ModeMenu.tscn")

func _on_start_pressed():
	print("Starting game...")
	# We'll hook this up later
