extends Control

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"
const COIN_SCRIPT = preload("res://scripts/coin_icon.gd")
const BASE_URL = "http://127.0.0.1:8000"
const SAVE_PATH = "user://leaderboard.json"
const MAX_ROWS = 10

# ---------------------------------------------------------------
# BACKEND SWITCH
#   false = scores are saved on this computer (works with no server)
#   true  = scores go to the backend, which must offer:
#     GET  /leaderboard        -> {"entries": [{"username": "Apple", "score": 120, "level": 3}, ...]}
#     POST /leaderboard/score  -> body {"score": 120, "level": 3}, needs the login token
# ---------------------------------------------------------------
var backend_enabled = true

var entries = []
var grid
var note_label
var status_label


func _label(text, font_size):
	var l = Label.new()
	l.text = text
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


func _coin(px):
	var c = COIN_SCRIPT.new()
	c.coin_size = px
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


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
	panel.custom_minimum_size = Vector2(900, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("2b1d2a")
	style.border_color = Color("d1c7b7")
	style.set_border_width_all(4)
	style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title_row = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 20)
	box.add_child(title_row)
	title_row.add_child(_coin(48.0))
	title_row.add_child(_label("LEADERBOARD", 52))
	title_row.add_child(_coin(48.0))

	var rule = _label("Score = coins you have left when you clear a level. Coins you spent do not count.", 22)
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule.custom_minimum_size = Vector2(820, 0)
	rule.add_theme_color_override("font_color", Color(0.75, 0.7, 0.8))
	box.add_child(rule)

	note_label = _label("", 26)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.custom_minimum_size = Vector2(820, 0)
	box.add_child(note_label)

	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)

	status_label = _label("", 20)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.65))
	box.add_child(status_label)

	var close_button = _button("Close", 30, 64)
	close_button.pressed.connect(_on_close)
	box.add_child(close_button)

	visible = false


func open():
	visible = true
	if backend_enabled:
		status_label.text = "Loading..."
		_request(HTTPClient.METHOD_GET, "/leaderboard", {}, _on_fetched)
	else:
		_load_local()
		status_label.text = "Scores are saved on this computer for now."
		_show_rows()


func _on_close():
	visible = false


# ---------- saving a score (called by main.gd when a level is cleared) ----------

# returns "guest", "saved", "lower" or "sent"
func submit_score(coins, level):
	if not GameState.logged_in:
		return "guest"
	if backend_enabled:
		_request(HTTPClient.METHOD_POST, "/leaderboard/score", {"coins": coins, "level": level}, _on_score_sent.bind(coins, level))
		return "sent"
	return _save_local_score(coins, level)


func _on_score_sent(result, code, _data, coins, level):
	# if the server could not take it, keep it on this computer instead
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_save_local_score(coins, level)


func _save_local_score(coins, level):
	_load_local()
	for e in entries:
		if str(e.get("username", "")) == GameState.username:
			if coins > int(e.get("coins", 0)):
				e["coins"] = coins
				e["level"] = level
				_write_local()
				return "saved"
			return "lower"
	entries.append({"username": GameState.username, "coins": coins, "level": level})
	_write_local()
	return "saved"


func _load_local():
	entries = []
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_ARRAY:
		entries = data


func _write_local():
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(entries))


# ---------- talking to the backend ----------

func _request(method, path, body, callback):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(result, code, _headers, bytes):
			http.queue_free()
			var data = JSON.parse_string(bytes.get_string_from_utf8())
			callback.call(result, code, data)
	)
	var headers = ["Content-Type: application/json"]
	if GameState.token != "":
		headers.append("Authorization: Bearer " + GameState.token)
	var payload = ""
	if method != HTTPClient.METHOD_GET:
		payload = JSON.stringify(body)
	var err = http.request(BASE_URL + path, headers, method, payload)
	if err != OK:
		http.queue_free()
		callback.call(HTTPRequest.RESULT_CANT_CONNECT, 0, null)


func _on_fetched(result, code, data):
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and typeof(data) == TYPE_DICTIONARY and data.has("entries"):
		entries = data["entries"]
		status_label.text = ""
	else:
		_load_local()
		status_label.text = "Server not available: showing scores saved on this computer."
	_show_rows()


# ---------- drawing the table ----------

func _cell(text, color, width, fsize, align):
	var l = _label(text, fsize)
	l.custom_minimum_size = Vector2(width, 0)
	l.horizontal_alignment = align
	l.clip_text = true
	l.add_theme_color_override("font_color", color)
	grid.add_child(l)


func _score_cell(score, color):
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(220, 0)
	row.add_theme_constant_override("separation", 10)
	row.add_child(_coin(30.0))
	var l = _label(str(score), 28)
	l.add_theme_color_override("font_color", color)
	row.add_child(l)
	grid.add_child(row)


func _show_rows():
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()

	var dim = Color(0.7, 0.65, 0.75)
	var left = HORIZONTAL_ALIGNMENT_LEFT
	_cell("Rank", dim, 90, 22, left)
	_cell("Player", dim, 360, 22, left)
	_cell("Coins left", dim, 220, 22, left)
	_cell("Best", dim, 100, 22, left)

	var sorted = entries.duplicate()
	sorted.sort_custom(func(a, b): return int(a.get("coins", 0)) > int(b.get("coins", 0)))

	var shown = mini(sorted.size(), MAX_ROWS)
	for i in shown:
		var e = sorted[i]
		var who = str(e.get("username", "?"))
		var color = Color.WHITE
		if i == 0:
			color = Color(1.0, 0.85, 0.3)
		elif i == 1:
			color = Color(0.85, 0.88, 0.95)
		elif i == 2:
			color = Color(0.9, 0.6, 0.35)
		if GameState.logged_in and who == GameState.username:
			color = Color(0.5, 1.0, 1.0)
		_cell("#%d" % (i + 1), color, 90, 28, left)
		_cell(who, color, 360, 28, left)
		_score_cell(int(e.get("coins", 0)), color)
		_cell("Lv %d" % int(e.get("level", 1)), color, 100, 28, left)

	if shown == 0:
		_cell("", dim, 90, 24, left)
		_cell("No scores yet. Log in and clear a level!", dim, 360, 24, left)
		_cell("", dim, 220, 24, left)
		_cell("", dim, 100, 24, left)

	_update_note()


func _update_note():
	if not GameState.logged_in:
		note_label.text = "You are playing as a guest. Log in to put your coins on the leaderboard."
		note_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		return

	var mine = null
	for e in entries:
		if str(e.get("username", "")) == GameState.username:
			mine = e
	if mine == null:
		note_label.text = "%s, clear a level to get on the board." % GameState.username
	else:
		note_label.text = "Your best: %d coins (level %d)" % [int(mine.get("coins", 0)), int(mine.get("level", 1))]
	note_label.add_theme_color_override("font_color", Color(0.5, 1.0, 1.0))


func _on_visibility_changed():
	get_tree().paused = visible
