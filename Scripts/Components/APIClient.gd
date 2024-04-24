extends HTTPRequest
class_name APIClient

var custom_headers : Array[String] = []
@export var delete_on_completion = false

signal response_complete(response : APIResponse)

func _ready():
	request_completed.connect(_on_request_complete)
	

func api_request(endpoint : String, http_method : int, body):
	var json_string = JSON.stringify(body)
	var headers = APIHelper.get_headers()
	for custom_header in custom_headers:
		headers.append(custom_header)
	# Replace {id} with id of game server
	endpoint = endpoint.replace("{id}",APIHelper.server_id)
	request(APIHelper.API_URL + endpoint, headers, http_method, json_string)

func _on_request_complete(result, response_code, headers, body):
	# Handle no content response
	if response_code == HTTPClient.RESPONSE_NO_CONTENT:
		var response = APIResponse.new() 
		response.isSuccess = true
		response.statusCode = response_code
		response_complete.emit(response)
		return
	
	# Try to deserialize json body
	var json = null
	if body != null and len(body) != 0:
		json = JSON.parse_string(body.get_string_from_utf8())
	
	# Create API response to deserialize to
	var response = APIResponse.new()
	
	if json: # Deserialize to API Response object
		response = APIHelper.json_to_class(json, response)
		response_complete.emit(response)
	else: # Unable to deserialize, create error APIResponse object
		var error_response = APIResponse.new()
		error_response.errors = ["Error communicating with API."]
		error_response.isSuccess = false
		error_response.statusCode = 0
		response_complete.emit(error_response)
	
	if delete_on_completion:
		queue_free()
