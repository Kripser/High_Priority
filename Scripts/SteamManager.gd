extends Node

var steam_id: int = 0
var lobby_id: int = 0
var is_host: bool = false
var my_role: String = ""
var lobby_members: Array = []

signal avatar_loaded(user_id, buffer)
signal lobby_members_updated
signal player_left(steam_id)
signal game_started

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
	Steam.connect("lobby_data_update", Callable(self, "_on_lobby_data_update"))
	Steam.connect("avatar_loaded", Callable(self, "_on_avatar_loaded"))


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
# MULTIPLAYER SETUP
# ===============================

func start_as_host():
	Steam.initRelayNetworkAccess()
	await get_tree().create_timer(1.0).timeout
	var peer = SteamMultiplayerPeer.new()
	var result = peer.create_host(lobby_id)
	print("Create host result: ", result)
	multiplayer.multiplayer_peer = peer
	print("Host Multiplayer peer created")
	
func start_as_client():
	Steam.initRelayNetworkAccess()
	await get_tree().create_timer(1.0).timeout
	var peer = SteamMultiplayerPeer.new()
	peer.create_client(lobby_id, Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	print("Client multiplayer peer created")


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
	if chat_state == 8:
		emit_signal("player_left", changed_id)
		
func _on_lobby_data_update(success: int, lobby: int, member_id: int):
	if lobby != lobby_id:
		return
	var started = Steam.getLobbyData(lobby_id, "game_started")
	if started == "true" and not is_host:
		my_role = Steam.getLobbyData(lobby_id, str(steam_id))
		print("Recieved role from lobby data: ", my_role)
		start_as_client()
		get_tree().change_scene_to_file("res://Scenes/Game.tscn")
	
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

func _process(_delta):
	Steam.run_callbacks()
