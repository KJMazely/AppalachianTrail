extends Node

func _ready():
	if OS.has_feature("web"):
		var user_name = get_url_param("name")
		var user_id = get_url_param("userId")
		
		print("name: ", user_name) 
		print("id: ", user_id)   
	else:
		print("fail to get player data")

func get_url_param(param_name: String) -> String:
	# This script asks JavaScript to find the parameter in the current URL
	var js_code = "new URLSearchParams(window.location.search).get('" + param_name + "')"
	var result = JavaScriptBridge.eval(js_code)
	
	# JavaScriptBridge.eval returns null if the parameter isn't found
	return str(result) if result != null else ""
