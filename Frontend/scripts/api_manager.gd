extends Node

@onready var http_request = $HTTPRequest

const SAVE_PATH = "user://session.cfg"

# Holds the active session in memory so any script can read it
var auth_token: String = ""
var username: String = ""
var guest_coins: int = 0
var guest_hp: int = 100
var guest_level: int = 1

func _ready():
	# 1. Restore saved login or guest progress from browser storage on startup
	load_session()
	
	# 2. Listens for the server's reply
	http_request.request_completed.connect(_on_request_completed)
	test_backend_connection()

func test_backend_connection():
	var url = "https://fortress-game-bdqc.onrender.com/" 
	http_request.request(url)

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json_string = body.get_string_from_utf8()
		print("Backend connected successfully! Data: ", json_string)
	else:
		print("Failed to connect. Error code: ", response_code)

# --- Browser Persistent Storage (IndexedDB via user://) ---

func save_session() -> void:
	var config = ConfigFile.new()
	config.set_value("auth", "token", auth_token)
	config.set_value("auth", "username", username)
	config.set_value("guest", "coins", guest_coins)
	config.set_value("guest", "hp", guest_hp)
	config.set_value("guest", "level", guest_level)
	config.save(SAVE_PATH)

func load_session() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	auth_token = config.get_value("auth", "token", "")
	username = config.get_value("auth", "username", "")
	guest_coins = config.get_value("guest", "coins", 0)
	guest_hp = config.get_value("guest", "hp", 100)
	guest_level = config.get_value("guest", "level", 1)

func clear_session() -> void:
	auth_token = ""
	username = ""
	guest_coins = 0
	guest_hp = 100
	guest_level = 1
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("session.cfg"):
		dir.remove("session.cfg")
