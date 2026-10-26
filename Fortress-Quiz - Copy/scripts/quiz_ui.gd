extends Control

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"

# d = difficulty (1 easy, 2 medium, 3 hard)
const QUESTIONS = [
	{
		"d": 1,
		"q": "What is the main purpose of a firewall?",
		"choices": [
			"Recover deleted files",
			"Create user passwords",
			"Filter and control network traffic",
			"Increase CPU speed",
		],
		"correct": 2,
		"explanation": "A firewall controls network traffic using security rules.",
	},
	{
		"d": 1,
		"q": "What does Multi-Factor Authentication (MFA) provide?",
		"choices": [
			"Multiple copies of a password",
			"More than one type of authentication factor",
			"Faster internet access",
			"Automatic file backup",
		],
		"correct": 1,
		"explanation": "MFA requires two or more factors to verify identity.",
	},
	{
		"d": 1,
		"q": "What is phishing?",
		"choices": [
			"Physically damaging a computer",
			"Tricking people into revealing sensitive information",
			"Increasing network speed",
			"Backing up files",
		],
		"correct": 1,
		"explanation": "Phishing is a social engineering attack.",
	},
	{
		"d": 1,
		"q": "What does the term malware refer to?",
		"choices": [
			"A method of encrypting a database",
			"Software used only for video editing",
			"A physical network cable",
			"Malicious software designed to harm systems",
		],
		"correct": 3,
		"explanation": "Malware is software designed to damage or gain unauthorized access.",
	},
	{
		"d": 1,
		"q": "What is a strong password most likely to contain?",
		"choices": [
			"Your name and birth year",
			"A long mix of letters, numbers and symbols",
			"The word password",
			"Only lowercase letters",
		],
		"correct": 1,
		"explanation": "Long and varied passwords are much harder to guess.",
	},
	{
		"d": 2,
		"q": "Which attack tries many passwords until the correct one is found?",
		"choices": [
			"Phishing",
			"Brute-force attack",
			"DDoS attack",
			"SQL injection",
		],
		"correct": 1,
		"explanation": "Brute force repeatedly guesses password combinations.",
	},
	{
		"d": 2,
		"q": "What is the main objective of a DDoS attack?",
		"choices": [
			"Improve server performance",
			"Encrypt a password",
			"Install an antivirus program",
			"Make a service unavailable by overwhelming it with traffic",
		],
		"correct": 3,
		"explanation": "A DDoS attack floods a service with traffic so nobody can use it.",
	},
	{
		"d": 2,
		"q": "What is the primary function of an Intrusion Detection System (IDS)?",
		"choices": [
			"Encrypt every file",
			"Replace damaged hardware",
			"Detect and alert about suspicious activity",
			"Create employee accounts",
		],
		"correct": 2,
		"explanation": "An IDS monitors activity and raises alerts.",
	},
	{
		"d": 2,
		"q": "What is antivirus software primarily designed to do?",
		"choices": [
			"Increase internet bandwidth",
			"Detect and help remove malicious software",
			"Create network cables",
			"Replace a firewall",
		],
		"correct": 1,
		"explanation": "Antivirus detects, prevents and removes malicious software.",
	},
	{
		"d": 2,
		"q": "Why should you keep your software updated?",
		"choices": [
			"Updates patch known security holes",
			"Updates make the screen brighter",
			"Updates delete your old files",
			"Updates are never important",
		],
		"correct": 0,
		"explanation": "Updates fix vulnerabilities that attackers could exploit.",
	},
	{
		"d": 3,
		"q": "A web app puts user input straight into a database query. Which attack exploits this?",
		"choices": [
			"Phishing",
			"DDoS",
			"SQL injection",
			"Brute-force attack",
		],
		"correct": 2,
		"explanation": "SQL injection happens when untrusted input ends up inside a query.",
	},
	{
		"d": 3,
		"q": "Files suddenly become encrypted and a message demands payment. What is responsible?",
		"choices": [
			"Ransomware",
			"Spyware",
			"Adware",
			"Rootkit",
		],
		"correct": 0,
		"explanation": "Ransomware locks data until the victim pays.",
	},
	{
		"d": 3,
		"q": "Which technology detects malicious traffic AND automatically blocks it?",
		"choices": [
			"IDS",
			"Antivirus",
			"VPN",
			"IPS",
		],
		"correct": 3,
		"explanation": "An IPS can take action, such as blocking the traffic.",
	},
	{
		"d": 3,
		"q": "A company uses firewalls, MFA, monitoring and backups together. Which principle is this?",
		"choices": [
			"Defense in depth",
			"Single sign-on",
			"Data compression",
			"Network segmentation",
		],
		"correct": 0,
		"explanation": "Defense in depth uses several layers so one failure is not fatal.",
	},
	{
		"d": 3,
		"q": "Which backup rule says to keep 3 copies on 2 types of media with 1 copy offsite?",
		"choices": [
			"The 3-2-1 rule",
			"The zero-trust rule",
			"The least-privilege rule",
			"The 5-4-3 rule",
		],
		"correct": 0,
		"explanation": "The 3-2-1 rule protects data even if one copy or location is lost.",
	},
]

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
var last_index = -1
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
	visible = true
	_next_question()


func _next_reward():
	return 10 * (GameState.streak + 1)


func _pick_question():
	var max_d = 1 + floori(GameState.streak / 2.0)
	if max_d > 3:
		max_d = 3
	var candidates = []
	for i in QUESTIONS.size():
		if QUESTIONS[i]["d"] <= max_d and i != last_index:
			candidates.append(i)
	last_index = candidates.pick_random()
	return QUESTIONS[last_index]


func _next_question():
	answered = false
	failed = false
	current = _pick_question()
	question_label.text = current["q"]
	for i in 4:
		answer_buttons[i].text = current["choices"][i]
		answer_buttons[i].disabled = false
		answer_buttons[i].modulate = Color.WHITE
	explanation_label.text = ""
	bank_button.visible = false
	continue_button.visible = false
	leave_button.visible = GameState.temp_coins == 0
	hint_label.text = "Answer correctly to win +%d coins. A wrong answer loses unbanked coins." % _next_reward()
	_update_labels()


func _on_answer(i):
	if answered:
		return
	answered = true
	for b in answer_buttons:
		b.disabled = true
	answer_buttons[current["correct"]].modulate = Color(0.5, 1.0, 0.5)
	if i == current["correct"]:
		GameState.streak += 1
		GameState.temp_coins += 10 * GameState.streak
		explanation_label.text = "Correct! " + current["explanation"]
		bank_button.text = "BANK  +%d coins" % GameState.temp_coins
		continue_button.text = "RISK IT  (next +%d)" % _next_reward()
		bank_button.visible = true
		continue_button.visible = true
		hint_label.text = "Bank to keep your coins, or risk them for a bigger reward."
	else:
		answer_buttons[i].modulate = Color(1.0, 0.4, 0.4)
		var lost = GameState.temp_coins
		GameState.temp_coins = 0
		GameState.streak = 0
		failed = true
		explanation_label.text = "Wrong! " + current["explanation"]
		continue_button.text = "Close"
		bank_button.visible = false
		continue_button.visible = true
		if lost > 0:
			hint_label.text = "You lost %d unbanked coins." % lost
		else:
			hint_label.text = "No coins lost this time."
	leave_button.visible = false
	_update_labels()


func _on_continue():
	if failed:
		visible = false
	else:
		_next_question()


func _on_bank():
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
