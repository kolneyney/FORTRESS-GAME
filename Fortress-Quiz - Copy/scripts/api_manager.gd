extends Node

@onready var http_request = $HTTPRequest

func _ready():
	# Listens for the server's reply
	http_request.request_completed.connect(_on_request_completed)
	test_backend_connection()

func test_backend_connection():
	# Replace with your local FastAPI address
	var url = "http://127.0.0.1:8000/" 
	http_request.request(url)

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json_string = body.get_string_from_utf8()
		print("Backend connected successfully! Data: ", json_string)
	else:
		print("Failed to connect. Error code: ", response_code)
