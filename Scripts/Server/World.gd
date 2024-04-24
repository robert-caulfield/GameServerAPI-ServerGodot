extends Node3D

@onready var lobby : GameServer = get_parent()

func _ready():
	multiplayer.peer_disconnected.connect(player_disconnected)

# Create player for newly joined player
func player_validated(id : int):
	var player_instance = preload("res://Scenes/Multiplayer/Instances/Player.tscn").instantiate()
	player_instance.player_peer_id = id
	player_instance.name = str(id)
	player_instance.username = lobby.players[id].username
	# Random position
	var random_amplitude = 3
	player_instance.transform.origin = Vector3(random_amplitude * randf_range(-1,1), 0, random_amplitude * randf_range(-1,1))
	$Players.add_child(player_instance, true)

# Handle peer disconnect
func player_disconnected(id: int):
	del_player(id)

# Remove player associated with disconnected peer
func del_player(id: int):
	for child in $Players.get_children():
		if child.player_peer_id == id:
			child.queue_free()
