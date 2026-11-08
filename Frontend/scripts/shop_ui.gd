extends Control

@onready var box = $Center/Panel/VBoxContainer
@onready var coins_label = box.get_node("CoinsLabel")

var items = {
	"firewall": "FirewallButton",
	"antivirus": "AntivirusButton",
	"mfa": "MFAButton",
	"backup": "BackupButton",
}

var defense_ids = {}
var request_type = ""
var http: HTTPRequest

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_api_request_completed)
	visibility_changed.connect(_on_visibility_changed)
	for d in items:
		box.get_node(items[d]).pressed.connect(_on_buy.bind(d))
	box.get_node("CloseButton").pressed.connect(close)
	visible = false

func open():
	visible = true
	if GameState.logged_in:
		_load_defenses()
	else:
		_refresh()


func close():
	visible = false

func _on_buy(defense):
	if GameState.logged_in:
		if not defense_ids.has(defense):
			print("Defense ID not found.")
			return
		request_type = "buy_defense"
		var headers = [
			"Authorization: Bearer " + GameState.token
		]
		var url = "http://127.0.0.1:8000/defenses/buy/" + str(defense_ids[defense])
		var error = http.request(
			url,
			headers,
			HTTPClient.METHOD_POST
		)
		if error != OK:
			print("Could not purchase defense.")
	else:
		GameState.buy(defense)
		_refresh()
	
func _load_defenses():
	if not GameState.logged_in:
		return
	request_type = "load_defenses"
	var headers = [
		"Authorization: Bearer " + GameState.token
	]
	var error = http.request(
		"http://127.0.0.1:8000/defenses",
		headers,
		HTTPClient.METHOD_GET
	)
	if error != OK:
		print("Could not load defenses from backend.")

func _refresh():
	coins_label.text = "Coins: %d" % GameState.coins
	for d in items:
		var b = box.get_node(items[d])
		var lvl = GameState.levels[d]
		if lvl >= GameState.MAX_LEVEL:
			b.text = "%s Lv %d (MAX)" % [d.capitalize(), lvl]
			b.disabled = true
		else:
			b.text = "%s Lv %d - Buy for %d" % [d.capitalize(), lvl, GameState.price_of(d)]
			b.disabled = GameState.coins < GameState.price_of(d)

func _on_api_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Could not connect to server.")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		print("Invalid response from server.")
		return
	if response_code != 200:
		print(data.get("detail", "Something went wrong."))
		return
	if request_type == "load_defenses":
		GameState.coins = data.get("coins", GameState.coins)
		for defense in data.get("defenses", []):
			var defense_name = defense.get("name", "").to_lower()
			if GameState.levels.has(defense_name):
				GameState.levels[defense_name] = defense.get("level", 0)
				defense_ids[defense_name] = defense.get("id", -1)
		_refresh()
		
	elif request_type == "buy_defense":
		GameState.coins = data.get("remaining_coins", GameState.coins)
		var defense_name = data.get("defense", "").to_lower()
		if GameState.levels.has(defense_name):
			GameState.levels[defense_name] = data.get(
				"level",
				GameState.levels[defense_name]
			)
		_refresh()

func _on_visibility_changed():
	get_tree().paused = visible
