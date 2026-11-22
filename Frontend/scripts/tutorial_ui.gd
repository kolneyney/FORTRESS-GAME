extends Control

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"
const SAVE_PATH = "user://tutorial.cfg"

# [number, short title, simple explanation]  - change the words here
const STEPS = [
	["1", "Protect the castle", "Enemies walk along the road to the fire. Do not let them reach it."],
	["2", "Answer quiz questions", "Press Quiz. A right answer gives coins. Press Bank to keep them, or risk them for more. A wrong answer loses half."],
	["3", "Buy heroes", "Press Shop. Spend coins to buy heroes and make them stronger. Heroes shoot enemies by themselves."],
	["4", "Clear 5 levels", "Defeat every enemy to finish a level. If the castle falls, try again. You keep your coins."],
	["5", "Log in", "Log in to put your name on the leaderboard. Guests can play, but they are not ranked."],
]

var note_label


func _label(text, font_size, color):
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", load(FONT_PATH))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 150

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(1000, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("2b1d2a")
	style.border_color = Color("d1c7b7")
	style.set_border_width_all(4)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title = _label("HOW TO PLAY", 56, Color(1.0, 0.9, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	for s in STEPS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		box.add_child(row)

		var num = _label(s[0], 48, Color(1.0, 0.9, 0.3))
		num.custom_minimum_size = Vector2(44, 0)
		num.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		row.add_child(num)

		var col = VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		row.add_child(col)
		col.add_child(_label(s[1], 30, Color.WHITE))

		var txt = _label(s[2], 24, Color(0.82, 0.78, 0.88))
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.custom_minimum_size = Vector2(840, 0)
		col.add_child(txt)

	note_label = _label("Tip: ALWAYS DO YOUR BEST", 22, Color(0.5, 1.0, 1.0))
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note_label)

	var go = Button.new()
	go.text = "Got it, let's play!"
	go.custom_minimum_size = Vector2(0, 80)
	go.add_theme_font_override("font", load(FONT_PATH))
	go.add_theme_font_size_override("font_size", 38)
	go.pressed.connect(_close)
	box.add_child(go)

	visible = false


# called right after the PLAY transition
func begin():
	# wait until the "DEFEND THE CORE!" banner is gone
	await get_tree().create_timer(0.8).timeout
	if GameState.logged_in and _seen(GameState.username):
		queue_free()
		return
	_open()


func _open():
	note_label.visible = not GameState.logged_in
	visible = true
	get_tree().paused = true

	await get_tree().process_frame
	pivot_offset = size / 2.0
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close():
	# only logged-in players are remembered; guests see the box again next time
	if GameState.logged_in:
		_mark_seen(GameState.username)
	get_tree().paused = false
	queue_free()


# the username is stored as a hash, so odd characters in a name cannot break the file
func _seen(user):
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return cfg.get_value("seen", user.sha256_text(), false)


func _mark_seen(user):
	var cfg = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("seen", user.sha256_text(), true)
	cfg.save(SAVE_PATH)
