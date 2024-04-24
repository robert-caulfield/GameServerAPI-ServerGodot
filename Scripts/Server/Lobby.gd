extends GameServer

func _ready():
	create_server()
	player_validated.connect($World.player_validated)
