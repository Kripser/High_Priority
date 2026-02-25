extends Node3D

const TEST_MAP = preload("res://Scenes/Maps/TestMap.tscn")
const PLAYER = preload("res://Scenes/Player.tscn")

@onready var map_container = $MapContainer
@onready var players = $Players
@onready var role_label = $HUD/RoleLabel

var peer_to_steam = {}  # peer_id -> steam_id

func _ready():
	role_label.text = "Your role: " + SteamManager.my_role

	var map = TEST_MAP.instantiate()
	map_container.add_child(map)

	SteamManager.connect("player_left", Callable(self, "_on_player_left"))

	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		# Solo host (testing): spawn immediately
		if SteamManager.lobby_members.size() == 1:
			_spawn_players({SteamManager.steam_id: 1})
	else:
		# Wait until the connection to the host is fully established before sending RPC
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_register_with_host.rpc_id(1, SteamManager.steam_id)
		else:
			multiplayer.connected_to_server.connect(func():
				_register_with_host.rpc_id(1, SteamManager.steam_id)
			)

func _on_peer_connected(peer_id: int):
	print("Peer connected: ", peer_id)

@rpc("any_peer", "reliable")
func _register_with_host(steam_id: int):
	var peer_id = multiplayer.get_remote_sender_id()
	peer_to_steam[peer_id] = steam_id
	print("Registered peer ", peer_id, " -> Steam ID ", steam_id)

	if peer_to_steam.size() >= SteamManager.lobby_members.size() - 1:
		# Build a full steam_id -> peer_id map and send it to everyone for spawning
		var steam_to_peer = {SteamManager.steam_id: 1}  # host is always peer 1
		for p_id in peer_to_steam:
			steam_to_peer[peer_to_steam[p_id]] = p_id
		_spawn_players.rpc(steam_to_peer)

@rpc("authority", "call_local", "reliable")
func _spawn_players(steam_to_peer: Dictionary):
	var spawn_points = $MapContainer.get_child(0).get_node("SpawnPoints").get_children()

	for i in range(SteamManager.lobby_members.size()):
		var member_id = SteamManager.lobby_members[i]
		var spawn_point = spawn_points[i % spawn_points.size()]

		var player = PLAYER.instantiate()
		player.position = spawn_point.global_position
		player.role = Steam.getLobbyData(SteamManager.lobby_id, str(member_id))
		player.name = str(member_id)
		players.add_child(player)

		var authority = steam_to_peer.get(member_id, 1)
		player.set_multiplayer_authority(authority)
		print("Spawned player ", member_id, " with authority peer ", authority)

func _on_player_left(left_steam_id: int):
	var player = players.get_node_or_null(str(left_steam_id))
	if player:
		player.queue_free()
		print("Removed player: ", left_steam_id)
