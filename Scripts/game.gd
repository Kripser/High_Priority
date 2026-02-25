extends Node3D

const TEST_MAP = preload("res://Scenes/Maps/TestMap.tscn")
const PLAYER = preload("res://Scenes/Player.tscn")

@onready var map_container = $MapContainer
@onready var players = $Players
@onready var role_label = $HUD/RoleLabel

func _ready():
	role_label.text = "Your role: " + SteamManager.my_role
	
	# Load map
	var map = TEST_MAP.instantiate()
	map_container.add_child(map)
	
	#spawn players
	if SteamManager.is_host:
		SteamManager.start_as_host()
		multiplayer.peer_connected.connect(_on_peer_connected)
		
	if not SteamManager.is_host:
		SteamManager.start_as_client()
		
	SteamManager.connect("player_left", Callable(self, "_on_player_left"))
	
var connected_peers = []
func _on_peer_connected(peer_id: int):
	connected_peers.append(peer_id)
	print("Peer connected: ", peer_id, " total: ", connected_peers.size())
	# Spawn when all non-host players have connected
	if connected_peers.size() >= SteamManager.lobby_members.size() - 1:
		_spawn_players()

func _spawn_players():
	var spawn_points = $MapContainer.get_child(0).get_node("SpawnPoints").get_children()
	
	for i in range(SteamManager.lobby_members.size()):
		var member_id = SteamManager.lobby_members[i]
		var spawn_point = spawn_points[i % spawn_points.size()]
		
		var player = PLAYER.instantiate()
		player.position = spawn_point.global_position
		player.role = Steam.getLobbyData(SteamManager.lobby_id, str(member_id))
		
		# Set multiplayer authority to the owning peer
		var peer_id = multiplayer.get_peers()
		player.name = str(member_id)
		players.add_child(player, true)
		
		
		# Set authority — host is always peer 1
		if member_id == SteamManager.steam_id:
			player.set_multiplayer_authority(1)
		else:
			var steam_peer = multiplayer.multiplayer_peer
			player.set_multiplayer_authority(steam_peer.get_peer_id_from_steam64(member_id))
			
func _on_player_left(steam_id: int):
	var player = players.get_node_or_null(str(steam_id))
	if player:
		player.queue_free()
		print("Removed player: ", steam_id)
