extends Node3D

const TEST_MAP = preload("res://Scenes/Maps/TestMap.tscn")
const PLAYER = preload("res://Scenes/Player.tscn")

@onready var map_container = $MapContainer
@onready var players = $Players
@onready var role_label = $HUD/RoleLabel

var remote_players = {}

func _ready():
	role_label.text = "Your role: " + SteamManager.my_role
	
	# Load map
	var map = TEST_MAP.instantiate()
	map_container.add_child(map)
	
	# Spawn local player
	var spawn_points = map.get_node("SpawnPoints").get_children()
	var my_index = SteamManager.lobby_members.find(SteamManager.steam_id)
	var spawn_point = spawn_points[my_index % spawn_points.size()]
	
	var player = PLAYER.instantiate()
	player.position = spawn_point.global_position
	player.role = SteamManager.my_role
	players.add_child(player)
	
	#Remote player position listening
	SteamManager.connect("player_updated", Callable(self, "_on_player_updated"))
	
func _on_player_updated(data: Dictionary):
	var remote_id = data["steam_id"]
	
	# Skip if it's our own update
	if remote_id == SteamManager.steam_id:
		return
	
	# Spawn remote player if not already spawned
	if not remote_players.has(remote_id):
		var remote_player = PLAYER.instantiate()
		# Disable input and camera for remote players
		remote_player.set_physics_process(false)
		players.add_child(remote_player)
		remote_players[remote_id] = remote_player
		print("Spawned remote player: ", remote_id)
	
	# Update remote player position and rotation
	var rp = remote_players[remote_id]
	rp.position = Vector3(data["position"]["x"], data["position"]["y"], data["position"]["z"])
	rp.rotation = Vector3(data["rotation"]["x"], data["rotation"]["y"], data["rotation"]["z"])
	
