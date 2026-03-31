extends Node

@onready var apiurl = get_dynamic_api_url()
var old_highscore
var user_id
var user_name
var request_cookie

func _ready():
	if OS.has_feature("web"):
		user_name = get_url_param("name")
		user_id = get_url_param("userId")
		old_highscore = get_url_param("highscore").to_int()
		request_cookie = get_url_param("cookie")
		
		print("name: ", user_name) 
		print("id: ", user_id)   
		print("highscore: ", old_highscore)
		print("url: ", apiurl)
		print("cookie: ", request_cookie)
	else:
		print("fail to get player data")

func get_url_param(param_name: String) -> String:
	# This script asks JavaScript to find the parameter in the current URL
	var js_code = "new URLSearchParams(window.location.search).get('" + param_name + "')"
	var result = JavaScriptBridge.eval(js_code)
	
	# JavaScriptBridge.eval returns null if the parameter isn't found
	return str(result) if result != null else ""

func HandleScoreUpdate(NewScore : int):
	if (old_highscore < NewScore):
		send_put_request(user_id.to_int(), NewScore)
		print("Score Updated to: ", NewScore)
	else:
		print("no new high score")
	
func send_put_request(playerId: int, newScore: int):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# The URL to send the PUT request to
	var url = apiurl
	
	# The data containing the two numbers
	var data = {
		"id": playerId,
		"score": newScore
	}
	
	# Convert dictionary to JSON string
	var body = JSON.stringify(data)
	
	# Headers for the request
	var headers = ["Cookie: " + request_cookie,"Content-Type: application/json"]
	
	# Make the PUT request
	var error = http_request.request(url, headers, HTTPClient.METHOD_PUT, body)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	print("Response Code: ", response_code)
	print("Response Body: ", json)

func get_dynamic_api_url() -> String:
	if OS.has_feature("web"):
		# Access the JavaScript 'document' object
		var document = JavaScriptBridge.get_interface("document")
		
		# document.referrer is the most reliable way to get the parent URL 
		# when embedded in an iframe across different domains.
		var parent_url = document.referrer
		
		# Fallback: if referrer is empty, use the iframe's own location
		if parent_url == "":
			var window = JavaScriptBridge.get_interface("window")
			parent_url = window.location.href
			
		# Example: Replace the page URL with your API endpoint
		# If parent is 'https://example.com', this might become 'https://example.com'
		var base_url = parent_url.get_base_dir() 
		return base_url + "/api/update"
	
	return "https://fallback-url.com"
