extends Node

var username := ""
var password := ""

@export var apiClient : APIClient 

signal signed_in()

func _ready():
	# Connect request completion signal
	apiClient.response_complete.connect(_on_login_request_complete)
	
	# Attempt login
	login()

func login():
	# Get login info from command-line args
	if Globals.arguments.has("username"):
		username = Globals.arguments["username"]
	if Globals.arguments.has("password"):
		password = Globals.arguments["password"]
	
	if username == "" or password == "":
		print("Username and/or password not provided in command-line arugments.
		\n\tExample args: --headless test --username=Admin --password=Admin123$")
		return
	
	# Create login request DTO, populate it with data
	var loginRequestDTO = LoginRequestDTO.new()
	loginRequestDTO.Username = username
	loginRequestDTO.Password = password
	
	# Send login request
	print("Sending login API request...")
	apiClient.api_request("auth/login", HTTPClient.METHOD_POST,loginRequestDTO.get_dict())


func _on_login_request_complete(response : APIResponse):
	if response.isSuccess:
		APIHelper.auth_token = response.result["token"]
		print("Recieved auth token.")
		signed_in.emit()
		return
	APIHelper.print_errors(response, "Login request unsuccessful")
