extends Node
class_name GameServer

# Server Info
const DEFAULT_PORT = 6545 # What port is set to if none is defined in arguments
const DEFAULT_SERVER_IP = "127.0.0.1" # What ip is set to if public ip is not fetched
const MAX_CONNECTIONS = 8
const DEFAULT_SERVER_NAME = "Server"
const PLAYER_AUTH_TIMEOUT = 10.0 # Time in seconds that a player has to authenticate
const HEARTBEAT_INTERVAL = 30 # Time in seconds that a heartbeat is sent

# Signal emmitted when a player is successfully validated via api
signal player_validated(id : int)

# API Client Component
var apiClientScene = preload("res://Scenes/Components/APIClient.tscn")

class PlayerInfo:
	var peer_id : int # Player's peer ID
	var named_id : String # Account ID
	var username : String # Player's username

# Player list. Dictionary that maps peer id to PlayerInfo object
# Populated with a player's data upon successful PlayerJoinToken validation
@export var players := {} # Key: Peer id; Value: PlayerInfo

# API Client instances
var api_register_server : APIClient
var api_heartbeat : APIClient
var api_close_server : APIClient

func create_server():
	
	# Set port if provided in command-line args
	var port = null
	if Globals.arguments.has("port"):
		var port_str : String = Globals.arguments["port"]
		if port_str.is_valid_int():
			port = port_str.to_int()
			if port < 0 or port > 65535:
				print("Provided port is out of valid range.")
				port = null
		else:
			print("Provided port could not be converted to int.")
	
	var peer = ENetMultiplayerPeer.new()
	# Refuse new connections until successful registration to API
	peer.refuse_new_connections = true
	# Create server
	var used_port = DEFAULT_PORT if port == null else port
	var error = peer.create_server(used_port, MAX_CONNECTIONS)
	if error:
		print("Error creating server.")
		return error
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.multiplayer_peer = peer
	
	print("Hosting server on port " + str(used_port))
	
	# Set name if provided in command-line args
	var server_name = null
	if Globals.arguments.has("server_name"):
		server_name = Globals.arguments["server_name"]
	
	# Create server registration dto
	var registerDTO = RegisterServerDTO.new()
	registerDTO.MaxPlayers = MAX_CONNECTIONS
	registerDTO.IPAddress = APIHelper.myIP if APIHelper.myIP != "" else DEFAULT_SERVER_IP
	registerDTO.Port = str(DEFAULT_PORT)
	registerDTO.Name = DEFAULT_SERVER_NAME if server_name == null else server_name
	
	# Create api clients and connect their completion signals
	create_api_clients()
	
	# Send api request to register server
	print("Sending game server registration API request...")
	api_register_server.api_request("game-servers", HTTPClient.METHOD_POST, registerDTO.save_dict())

# Remote function that allows players to send auth token
# Players should send this immediately upon conneciton
@rpc("any_peer", "reliable", "call_remote")
func _send_auth_token(token : String):
	# Get sender of RPC 
	var sender = multiplayer.get_remote_sender_id()
	print("Recieved join token from player " + str(sender))
	
	# Simple token value checks
	if token == null or token.is_empty():
		print("Invalid join token from player " + str(sender))
		disconnect_peer(sender)
		return
	# Create validate player api client
	var api_validate_player : APIClient = apiClientScene.instantiate()
	api_validate_player.delete_on_completion = true
	# Connect api request completion
	api_validate_player.response_complete.connect(_on_validate_player_complete.bind(sender))
	add_child(api_validate_player)
	# Send API request
	api_validate_player.api_request("game-servers/{id}/players/validate", HTTPClient.METHOD_POST, {"playerJoinToken":token})
	

func _on_validate_player_complete(response : APIResponse, peer_id : int):
	if response.isSuccess:
		if peer_id in multiplayer.get_peers(): # if peer is still connected
			# Populate player data with PlayerProfileDTO
			var player_info : PlayerInfo = PlayerInfo.new()
			player_info.named_id = response.result["id"]
			player_info.username = response.result["username"]
			# Add player profile to list. Key: peer_id
			players[peer_id] = player_info
			# Emit signal that peer was validated. 
			player_validated.emit(peer_id)
			print("Validation success for player " + str(peer_id) + ". Username: " + player_info.username)
			return
		else: # if peer is not connected, send disconnect dto
			print("Validation success but player " + str(peer_id) + " is no longer connected")
			return
	# validation not successful
	APIHelper.print_errors(response, "Unable to validate player " + str(peer_id))
	disconnect_peer(peer_id)

# Sends new playercount to api via patch request
func update_player_count(amount):
	send_cache_patch([get_patch_dict("playerCount", amount)])


# Creates a dictionary for a patch replace operation
func get_patch_dict(key: String, value) -> Dictionary:
	return {"op":"replace", "path":("/"+key), "value":value}

# Sends a patch update to api
func send_cache_patch(body):
	var api_player_disconnect : APIClient = apiClientScene.instantiate()
	api_player_disconnect.delete_on_completion = true
	add_child(api_player_disconnect)
	api_player_disconnect.api_request("game-servers/{id}/cache", HTTPClient.METHOD_PATCH, body)

# Patch request completed
func _cache_patch_completed(response : APIResponse):
	if response.isSuccess:
		pass
	else:
		pass

func _on_peer_connected(id):
	print(str(id) + " connected")
	# Sends playercount update to API
	update_player_count(len(multiplayer.get_peers()) + 1)
	# Create a timer that kicks player if they dont send a PlayerJoinToken
	get_tree().create_timer(PLAYER_AUTH_TIMEOUT).timeout.connect(disconnect_peer_if_unregistered.bind(id))

# Disconnects peer if they arent validated
func disconnect_peer_if_unregistered(id):
	if not players.has(id):
		disconnect_peer(id)

# kicks peer
func disconnect_peer(id):
	if id in multiplayer.get_peers():
		print("Kicking player " + str(id))
		multiplayer.multiplayer_peer.disconnect_peer(id)

# Remove from active players and send disconnect request
func _on_peer_disconnected(id):
	print("Player disconnected")
	# Sends playercount update to API
	update_player_count(len(multiplayer.get_peers()) - 1)
	# Remove from registered players
	if players.has(id):
		players.erase(id)
		
	
func _on_register_complete(response : APIResponse):
	if response.isSuccess:
		print("Server registered.")
		# Store server id
		APIHelper.server_id = response.result
		multiplayer.multiplayer_peer.refuse_new_connections = false
		# Start heartbeat timer loop
		create_heartbeat_loop()
	else:
		APIHelper.print_errors(response, "Server registration unsuccessful.")

# Create a repeating timer that sends heartbeat requests to API
func create_heartbeat_loop():
	var heartbeat_timer = Timer.new()
	heartbeat_timer.autostart = true
	heartbeat_timer.wait_time = HEARTBEAT_INTERVAL
	heartbeat_timer.timeout.connect(send_heartbeat)
	add_child(heartbeat_timer)

# Sends heartbeat API request
func send_heartbeat():
	api_heartbeat.api_request("game-servers/{id}/heartbeat", HTTPClient.METHOD_POST, {})

func _on_heartbeat_complete(response : APIResponse):
	if response.isSuccess:
		print("Heartbeat success")
	else:
		APIHelper.print_errors(response, "Heartbeat fail")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_close_server()

func _request_close_server():
	print("Sending close request...")
	api_close_server.api_request("game-servers/{id}",HTTPClient.METHOD_DELETE, {})

func _on_close_server_complete(response : APIResponse):
	if(response.isSuccess):
		print("Server removed from API.")
	else:
		APIHelper.print_errors(response, "Server could not be removed.")
	print("Quitting.")
	get_tree().quit()

# Creates API Clients and connects their completion signals
func create_api_clients():
	api_register_server = apiClientScene.instantiate()
	api_register_server.response_complete.connect(_on_register_complete)
	add_child(api_register_server)
	
	api_heartbeat = apiClientScene.instantiate()
	api_heartbeat.response_complete.connect(_on_heartbeat_complete)
	add_child(api_heartbeat)
	
	api_close_server = apiClientScene.instantiate()
	api_close_server.response_complete.connect(_on_close_server_complete)
	add_child(api_close_server)
	


