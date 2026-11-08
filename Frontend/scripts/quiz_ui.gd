extends Control

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"
const BASE_URL = "http://127.0.0.1:8000"

var http: HTTPRequest
var current_question_id = -1
var is_loading = false
var selected_answer_index = -1
var request_type = ""

var bank_label
var streak_label
var risk_label
var question_label
var explanation_label
var hint_label
var answer_buttons = []
var bank_button
var continue_button
var leave_button

var current = {}
var answered = false
var failed = false


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


func _ready():
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_api_request_completed)
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
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title = _label(40)
	title.text = "CYBER QUIZ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var top = HBoxContainer.new()
	box.add_child(top)

	bank_label = _label(26)
	bank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	top.add_child(bank_label)

	streak_label = _label(26)
	streak_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(streak_label)

	risk_label = _label(26)
	risk_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	risk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	risk_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	top.add_child(risk_label)

	hint_label = _label(20)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.8))
	box.add_child(hint_label)

	question_label = _label(32)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.custom_minimum_size = Vector2(800, 90)
	box.add_child(question_label)

	for i in 4:
		var b = _button("", 24, 64)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_on_answer.bind(i))
		box.add_child(b)
		answer_buttons.append(b)

	explanation_label = _label(22)
	explanation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation_label.custom_minimum_size = Vector2(800, 70)
	box.add_child(explanation_label)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)

	bank_button = _button("Bank", 28, 70)
	bank_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_button.pressed.connect(_on_bank)
	row.add_child(bank_button)

	continue_button = _button("Continue", 28, 70)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.pressed.connect(_on_continue)
	row.add_child(continue_button)

	leave_button = _button("Leave quiz", 22, 50)
	leave_button.pressed.connect(_on_leave)
	box.add_child(leave_button)

	visible = false


func open():
	GameState.streak = 0
	GameState.temp_coins = 0

	answered = false
	failed = false
	selected_answer_index = -1
	current_question_id = -1

	question_label.text = "Loading question..."
	explanation_label.text = ""
	hint_label.text = "Getting your next question..."

	bank_button.visible = false
	continue_button.visible = false
	leave_button.visible = true

	for b in answer_buttons:
		b.text = ""
		b.disabled = true
		b.modulate = Color.WHITE

	_update_labels()
	visible = true

	if GameState.logged_in:
		_start_registered_quiz()
	else:
		_request_question()


func _next_reward():
	var next_streak = GameState.streak
	var next_difficulty = 1

	if next_streak <= 2:
		next_difficulty = 1
	elif next_streak <= 5:
		next_difficulty = 2
	elif next_streak <= 8:
		next_difficulty = 3
	elif next_streak <= 10:
		next_difficulty = 4
	else:
		next_difficulty = 5

	var rewards = {
		1: 10,
		2: 20,
		3: 30,
		4: 40,
		5: 50
	}

	return rewards[next_difficulty]

func _next_question():
	answered = false
	failed = false
	question_label.text = "Loading question..."

	for b in answer_buttons:
		b.disabled = true
		b.modulate = Color.WHITE

	explanation_label.text = ""
	bank_button.visible = false
	continue_button.visible = false
	leave_button.visible = GameState.temp_coins == 0
	hint_label.text = "Getting your next question..."
	_update_labels()

	_request_question()


func _on_answer(i):
	if answered or is_loading:		return

	answered = true
	is_loading = true
	selected_answer_index = i

	for b in answer_buttons:		b.disabled = true

	request_type = "answer"

	var answer_keys = ["A", "B", "C", "D"]

	var request_data = {		"question_id": current_question_id,		"answer": answer_keys[i]
	}

	var headers = ["Content-Type: application/json"]
	var endpoint = "/quiz/guest/answer"

	if GameState.logged_in:		
		headers.append("Authorization: Bearer " + GameState.token)		
		endpoint = "/quiz/answer"

	var error = http.request(		BASE_URL + endpoint,		headers,		HTTPClient.METHOD_POST,
		JSON.stringify(request_data)
	)

	if error != OK:
		is_loading = false
		answered = false

		for b in answer_buttons:
			b.disabled = false

		hint_label.text = "Could not submit your answer."
		
func _show_answer_result(i, data):
	var is_correct = data.get("correct", false)
	var correct_key = data.get("correct_answer", "")
	var answer_keys = ["A", "B", "C", "D"]
	var correct_index = answer_keys.find(correct_key)

	if correct_index >= 0:
		answer_buttons[correct_index].modulate = Color(0.5, 1.0, 0.5)

	var explanation = data.get("explanation", "")

	if is_correct:
		if GameState.logged_in:
			GameState.streak = data.get("current_streak", 0)
			GameState.temp_coins = data.get("session_coins", 0)
			GameState.coins = data.get("player_total_coins", GameState.coins)
			GameState.best_wave = data.get("best_streak", GameState.best_wave)
		else:
			GameState.streak += 1
			GameState.temp_coins += data.get("reward", 0)

		explanation_label.text = "Correct! " + explanation
		bank_button.text = "BANK  +%d coins" % GameState.temp_coins
		continue_button.text = "RISK IT  (next +%d)" % _next_reward()
		bank_button.visible = true
		continue_button.visible = true
		hint_label.text = "Bank to keep all your coins, or risk them for more. A wrong answer keeps only half."

	else:
		answer_buttons[i].modulate = Color(1.0, 0.4, 0.4)

		var at_risk_now = GameState.temp_coins
		var kept = 0

		if GameState.logged_in:
			kept = data.get("earned_coins", 0)
			GameState.coins = data.get("player_total_coins", GameState.coins)
		else:
			kept = floori(at_risk_now / 2.0)
			GameState.coins += kept

		GameState.temp_coins = 0
		GameState.streak = 0
		failed = true

		explanation_label.text = "Wrong! " + explanation
		continue_button.text = "Close"
		bank_button.visible = false
		continue_button.visible = true

		if at_risk_now > 0:
			hint_label.text = "You had %d coins at risk and kept half: +%d coins." % [at_risk_now, kept]
		else:
			hint_label.text = "No coins were at risk this time."

	leave_button.visible = false
	_update_labels()


func _on_continue():
	if failed:
		visible = false
	else:
		_next_question()



func _on_bank():
	if GameState.logged_in:
		if is_loading:
			return

		is_loading = true
		request_type = "cashout"

		var headers = [
			"Authorization: Bearer " + GameState.token
		]

		var error = http.request(
			BASE_URL + "/quiz/cashout",
			headers,
			HTTPClient.METHOD_POST
		)

		if error != OK:
			is_loading = false
			hint_label.text = "Could not bank your coins."
		return

	# Guest banking stays local
	GameState.coins += GameState.temp_coins
	GameState.temp_coins = 0
	GameState.streak = 0
	_update_labels()
	visible = false



func _on_leave():
	GameState.temp_coins = 0
	GameState.streak = 0
	visible = false


func _update_labels():
	bank_label.text = "Bank: %d" % GameState.coins
	streak_label.text = "Streak: %d" % GameState.streak
	risk_label.text = "At risk: %d" % GameState.temp_coins


func _on_visibility_changed():
	get_tree().paused = visible

func _on_api_request_completed(result, response_code, _headers, body):
	is_loading = false
	if result != HTTPRequest.RESULT_SUCCESS:
		hint_label.text = "Could not connect to the server."
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	
	if typeof(data) != TYPE_DICTIONARY:
		hint_label.text = "Invalid response from server."
		return
	if response_code != 200:
		hint_label.text = str(data.get("detail", "Something went wrong."))
		return
		
	if request_type == "cashout":
		GameState.coins = data.get(
			"player_total_coins",
			GameState.coins
		)
		GameState.temp_coins = 0
		GameState.streak = 0

		_update_labels()
		visible = false
		return

	if request_type == "start":
		_request_question()
		return
	if request_type == "question":
		answered = false
		failed = false
		current_question_id = data.get("id", -1)
		
	if request_type == "answer":
		_show_answer_result(selected_answer_index, data)
		return

	current = {
		"q": data.get("question", ""),
		"choices": [
			data.get("options", {}).get("A", ""),
			data.get("options", {}).get("B", ""),
			data.get("options", {}).get("C", ""),
			data.get("options", {}).get("D", "")
		],
		
	}
	question_label.text = current["q"]

	for i in 4:
		answer_buttons[i].text = current["choices"][i]
		answer_buttons[i].disabled = false

	hint_label.text = "Answer correctly to earn coins. A wrong answer ends the quiz and you keep half of your unbanked coins."
		
func _request_question():
	if is_loading:
		return

	is_loading = true
	request_type = "question"

	var url = BASE_URL + "/quiz/guest/question?current_streak=" + str(GameState.streak)
	var headers = []

	if GameState.logged_in:
		url = BASE_URL + "/quiz/question"
		headers = ["Authorization: Bearer " + GameState.token]

	var error = http.request(url, headers, HTTPClient.METHOD_GET)

	if error != OK:
		is_loading = false
		hint_label.text = "Could not send question request."
		

func _start_registered_quiz():
	if is_loading:
		return

	is_loading = true
	request_type = "start"

	var headers = ["Authorization: Bearer " + GameState.token]

	var error = http.request(
		BASE_URL + "/quiz/start",
		headers,
		HTTPClient.METHOD_POST
	)

	if error != OK:
		is_loading = false
		hint_label.text = "Could not start quiz session."
		
