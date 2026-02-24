extends Node

var steam_id: int = 0
var lobby_id: int = 0
var is_host: bool = false
var my_role: String = ""
var lobby_members: Array = []
signal avatar_loaded(user_id, buffer)
signal lobby_members_updated
signal player_updated(data)
signal player_ready(steam_id)

func _ready():
	print("Initializing Steam...")
	
	var init = Steam.steamInitEx()
	print("Steam init result: ", init)

	if init["status"] != 0:
		print("Steam failed to initialize: ", init["verbal"])
		return
		
	steam_id = Steam.getSteamID()
	print("Steam initialized. Logged in as: ", Steam.getPersonaName())
	print("Steam ID: ", steam_id)

	# CONNECT SIGNALS
	Steam.connect("lobby_created", Callable(self, "_on_lobby_created"))
	Steam.connect("lobby_joined", Callable(self, "_on_lobby_entered"))
	Steam.connect("lobby_chat_update", Callable(self, "_on_lobby_chat_update"))
	Steam.connect("avatar_loaded", Callable(self, "_on_avatar_loaded"))
	Steam.connect("p2p_session_request", Callable(self, "_on_p2p_session_request"))
	Steam.connect("p2p_session_connect_fail", Callable(self, "_on_p2p_session_connect_fail"))


# ===============================
# LOBBY CREATION / JOIN
# ===============================

func create_lobby():
	print("Creating lobby...")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)

func join_lobby(id: int):
	print("Joining lobby: ", id)
	Steam.joinLobby(id)


# ===============================
# CALLBACKS (MUST EXIST)
# ===============================

func _on_lobby_created(connect_result: int, created_lobby_id: int):
	print("Lobby created callback fired")

	if connect_result != 1:
		print("Lobby creation failed")
		return

	lobby_id = created_lobby_id
	is_host = true

	print("Lobby successfully created: ", lobby_id)
	_update_lobby_members()
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")


func _on_lobby_entered(entered_lobby_id: int, permissions: int, locked: bool, response: int):
	print("Entered lobby callback fired")
	
	if response != 1:
		print("Failed to join lobby, response: ", response)
		return

	lobby_id = entered_lobby_id
	is_host = Steam.getLobbyOwner(lobby_id) == steam_id

	print("Entered lobby: ", lobby_id)
	print("Is host: ", is_host)

	_update_lobby_members()
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")


func _on_lobby_chat_update(lobby: int, changed_id: int, making_change_id: int, chat_state: int):
	print("Lobby member update")
	_update_lobby_members()
	if chat_state == 1:
		Steam.acceptP2PSessionWithUser(changed_id)
	
func _on_avatar_loaded(user_id: int, size: int, buffer: Array):
	emit_signal("avatar_loaded", user_id, buffer)


# ===============================
# HELPER
# ===============================

func _update_lobby_members():
	lobby_members.clear()

	if lobby_id == 0:
		return

	var count = Steam.getNumLobbyMembers(lobby_id)

	for i in range(count):
		var member_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		lobby_members.append(member_id)

	print("Current members: ", lobby_members)
	emit_signal("lobby_members_updated")
	
# Add these new functions:
func _on_p2p_session_request(remote_id: int):
	Steam.acceptP2PSessionWithUser(remote_id)

func _on_p2p_session_connect_fail(remote_id: int, session_error: int):
	print("P2P connection failed with: ", remote_id, " error: ", session_error)

func send_p2p_message(target_id: int, data: Dictionary):
	var message = var_to_bytes(data)
	Steam.sendP2PPacket(target_id, message, Steam.P2P_SEND_RELIABLE)

func _read_p2p_messages():
	if steam_id == 0:
		return
	var packet_size = Steam.getAvailableP2PPacketSize(0)
	while packet_size > 0:
		var packet = Steam.readP2PPacket(packet_size, 0)
		if packet and packet.has("data"):
			var data = bytes_to_var(packet["data"])
			_handle_message(data, packet["remote_steam_id"])
		packet_size = Steam.getAvailableP2PPacketSize(0)

func _handle_message(data: Dictionary, sender_id: int):
	if data.has("type"):
		match data["type"]:
			"start_game":
				my_role = data["role"]
				print("Recieved role: ", my_role)
				send_p2p_message(data["host_id"], {
					"type": "ready_ack",
					"steam_id": steam_id
				})
				get_tree().change_scene_to_file("res://Scenes/Game.tscn")
			"ready_ack":
				emit_signal("player_ready", data["steam_id"])
			
			"player_update":
				emit_signal("player_updated", data)
	

func broadcast_p2p_message(data: Dictionary):
	for member_id in lobby_members:
		if member_id != steam_id:
			send_p2p_message(member_id, data)

func _process(_delta):
	Steam.run_callbacks()
	_read_p2p_messages()
