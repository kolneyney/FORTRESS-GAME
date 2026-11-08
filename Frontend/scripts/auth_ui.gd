extends Control

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"
const BASE_URL = "http://127.0.0.1:8000"

signal logged_in(username)

var mode = "login"
var busy = false

var title_label
var tabs_row
var login_tab
var register_tab
var user_input
var pass_input
var message_label
var submit_button


func _label(font_size):
	var l = Label.new()
	l.add_theme_font_override("font", load(FONT_PATH))
	l.add_theme_font_size_override("font_size", font_size)
	return l


func _button(text, font_size, height):
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_override("font", load(FONT_PATH))
	b.add_theme_font_size_override("font_size", font_size)
	return b


func _field(placeholder):
	var e = LineEdit.new()
	e.placeholder_text = placeholder
	e.custom_minimum_size = Vector2(0, 64)
	e.add_theme_font_override("font", load(FONT_PATH))
	e.add_theme_font_size_override("font_size", 28)
	return e


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visibility_changed.connect(_on_visibility_changed)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100

	var bg = ColorRect.new()
	bg.color = Color("1a1220")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("2b1d2a")
	style.border_color = Color("d1c7b7")
	style.set_border_width_all(4)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	title_label = _label(44)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	tabs_row = HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 16)
	box.add_child(tabs_row)

	login_tab = _button("Login", 28, 56)
	login_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_tab.pressed.connect(_set_mode.bind("login"))
	tabs_row.add_child(login_tab)

	register_tab = _button("New account", 28, 56)
	register_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	register_tab.pressed.connect(_set_mode.bind("register"))
	tabs_row.add_child(register_tab)

	user_input = _field("Username")
	user_input.max_length = 50
	box.add_child(user_input)

	pass_input = _field("Password")
	pass_input.secret = true
	pass_input.text_submitted.connect(_on_enter)
	box.add_child(pass_input)

	message_label = _label(22)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.custom_minimum_size = Vector2(620, 70)
	message_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.8))
	box.add_child(message_label)

	submit_button = _button("Login", 32, 70)
	submit_button.pressed.connect(_on_submit)
	box.add_child(submit_button)

	var close_button = _button("Close", 26, 56)
	close_button.pressed.connect(_on_close)
	box.add_child(close_button)

	visible = false


func open():
	pass_input.text = ""
	_set_mode("login")
	visible = true


func _on_close():
	visible = false


func _set_mode(m):
	mode = m
	message_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.8))

	if GameState.logged_in:
		title_label.text = "ACCOUNT"
		tabs_row.visible = false
		user_input.visible = false
		pass_input.visible = false
		message_label.text = "Logged in as %s" % GameState.username
		submit_button.text = "Log out"
		return

	tabs_row.visible = true
	user_input.visible = true
	pass_input.visible = true
	if mode == "login":
		title_label.text = "LOGIN"
		submit_button.text = "Login"
		message_label.text = "Enter your username and password."
		login_tab.modulate = Color.WHITE
		register_tab.modulate = Color(0.6, 0.6, 0.6)
	else:
		title_label.text = "NEW ACCOUNT"
		submit_button.text = "Create account"
		message_label.text = "Pick a username nobody else has. Password: 8+ characters with uppercase, lowercase, a number and a symbol, like Apple#1234"
		login_tab.modulate = Color(0.6, 0.6, 0.6)
		register_tab.modulate = Color.WHITE


func _show_error(text):
	message_label.text = text
	message_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))


func _on_enter(_text):
	_on_submit()


func _on_submit():
	if busy:
		return

	if GameState.logged_in:
		GameState.token = ""
		GameState.username = ""
		GameState.logged_in = false

		GameState.reset()
		GameState.best_wave = 0

		logged_in.emit("")
		_set_mode("login")
		return

	var uname = user_input.text.strip_edges()
	var pw = pass_input.text
	if uname == "":
		_show_error("Please type a username.")
		return
	if pw == "":
		_show_error("Please type a password.")
		return

	var path = "/auth/login"
	if mode == "register":
		path = "/auth/register"

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_done.bind(http, uname))

	var request_data = {
	"username": uname,
	"password": pw
}

	if mode == "register":
		request_data["guest_progress"] = {
			"coins": GameState.coins,
			"current_streak": GameState.streak,
			"best_streak": GameState.best_wave,
			"defenses": [
				{
					"name": "Firewall",
					"level": GameState.levels["firewall"]
				},
				{
					"name": "Antivirus",
					"level": GameState.levels["antivirus"]
				},
				{
					"name": "MFA",
					"level": GameState.levels["mfa"]
				},
				{
					"name": "Backup",
					"level": GameState.levels["backup"]
				}
			]
		}
	
	var body = JSON.stringify(request_data)	
	var err = http.request(BASE_URL + path, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		_show_error("Could not send the request.")
		return

	busy = true
	submit_button.disabled = true
	message_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.8))
	message_label.text = "Please wait..."


func _on_done(result, code, _headers, body, http, uname):
	http.queue_free()
	busy = false
	submit_button.disabled = false

	if result != HTTPRequest.RESULT_SUCCESS:
		_show_error("Cannot reach the server. Is the backend running?")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	if code == 200 and typeof(data) == TYPE_DICTIONARY and data.has("access_token"):
		GameState.token = data["access_token"]
		GameState.username = data.get("username", uname)

		busy = true
		submit_button.disabled = true
		message_label.text = "Loading saved progress..."

		_request_player_data()
		return

	var detail = "Something went wrong (error %d)." % code
	if typeof(data) == TYPE_DICTIONARY and data.has("detail"):
		if typeof(data["detail"]) == TYPE_STRING:
			detail = data["detail"]
		else:
			detail = "Please check your username and password."
	if detail == "Username already exists":
		detail = "That username is taken. Try another one, like %s2." % uname
	_show_error(detail)


func _on_visibility_changed():
	get_tree().paused = visible
	
func _request_player_data():
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(_on_player_data_done.bind(http))

	var headers = [
		"Authorization: Bearer " + GameState.token
	]

	var err = http.request(
		BASE_URL + "/auth/me",
		headers,
		HTTPClient.METHOD_GET
	)

	if err != OK:
		http.queue_free()
		_load_failed("Could not retrieve your account data.")


func _on_player_data_done(result, code, _headers, body, http):
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_load_failed("Could not load your saved player data.")
		return

	var player_data = JSON.parse_string(body.get_string_from_utf8())

	if typeof(player_data) != TYPE_DICTIONARY:
		_load_failed("Invalid player data received.")
		return

	_request_defenses(player_data)


func _request_defenses(player_data):
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(
		_on_defenses_done.bind(http, player_data)
	)

	var headers = [
		"Authorization: Bearer " + GameState.token
	]

	var err = http.request(
		BASE_URL + "/defenses",
		headers,
		HTTPClient.METHOD_GET
	)

	if err != OK:
		http.queue_free()
		_load_failed("Could not retrieve your defenses.")


func _on_defenses_done(result, code, _headers, body, http, player_data):
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_load_failed("Could not load your saved defenses.")
		return

	var defense_data = JSON.parse_string(body.get_string_from_utf8())

	if typeof(defense_data) != TYPE_DICTIONARY:
		_load_failed("Invalid defense data received.")
		return

	GameState.load_player_progress(player_data, defense_data)

	GameState.logged_in = true
	busy = false
	submit_button.disabled = false
	pass_input.text = ""

	logged_in.emit(GameState.username)
	visible = false


func _load_failed(error_message):
	GameState.token = ""
	GameState.username = ""
	GameState.logged_in = false

	busy = false
	submit_button.disabled = false

	_show_error(error_message)
