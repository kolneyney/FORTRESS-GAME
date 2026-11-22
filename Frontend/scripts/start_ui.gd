extends Control

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"

# stays true after the first Play, so Try Again skips this page
static var shown_once = false

var login_page
var login_open = false
var starting = false
var content
var play_button
var login_button
var status_label
var title_label
var rain
var glow_tween


# falling binary code in the background (kept light so the page stays smooth)
class Rain extends Control:
	var font
	var cols = []
	var cell = 36.0
	var chars = "01"
	var acc = 0.0
	var boost = 1.0

	func _ready():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS
		font = load("res://assets/fonts/PixeloidSans-lxa3y.ttf")
		resized.connect(_build)
		_build()

	func _build():
		cols.clear()
		var n = int(size.x / cell) + 1
		for i in n:
			cols.append({
				"y": randf() * size.y,
				"speed": randf_range(60.0, 200.0),
				"len": randi_range(5, 11),
			})

	func _process(delta):
		acc += delta
		if acc < 0.033:
			return
		var d = acc
		acc = 0.0
		for c in cols:
			c["y"] += c["speed"] * boost * d
			if c["y"] - c["len"] * cell > size.y:
				c["y"] = 0.0
				c["speed"] = randf_range(60.0, 200.0)
				c["len"] = randi_range(5, 11)
		queue_redraw()

	func _draw():
		for i in cols.size():
			var c = cols[i]
			for j in c["len"]:
				var y = c["y"] - j * cell
				if y < -cell or y > size.y:
					continue
				var a = 0.5 * (1.0 - float(j) / float(c["len"]))
				var col = Color(0.4, 1.0, 0.5, a)
				if j == 0:
					col = Color(0.85, 1.0, 0.9, 0.9)
				var idx = (i * 7 + j * 3 + int(c["y"] / cell)) % chars.length()
				draw_char(font, Vector2(i * cell, y), chars[idx], 22, col)


func _label(text, font_size):
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", load(FONT_PATH))
	l.add_theme_font_size_override("font_size", font_size)
	return l


func _button(text, font_size, height):
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, height)
	b.add_theme_font_override("font", load(FONT_PATH))
	b.add_theme_font_size_override("font_size", font_size)
	return b


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visibility_changed.connect(_on_self_visibility)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 90

	var dim = ColorRect.new()
	dim.color = Color(0.1, 0.07, 0.13, 0.94)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	rain = Rain.new()
	add_child(rain)
	rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	content = CenterContainer.new()
	add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	content.add_child(box)

	title_label = _label("FORTRESS QUIZ", 84)
	box.add_child(title_label)

	var subtitle = _label("Answer cyber questions. Defend the core.", 28)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.7, 0.8))
	box.add_child(subtitle)

	status_label = _label("", 26)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	box.add_child(status_label)

	play_button = _button("PLAY", 48, 100)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.pressed.connect(_on_play)
	box.add_child(play_button)

	login_button = _button("Login", 32, 72)
	login_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	login_button.pressed.connect(_on_login_pressed)
	box.add_child(login_button)

	# title glows slowly
	glow_tween = create_tween()
	glow_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	glow_tween.set_loops()
	glow_tween.tween_property(title_label, "modulate", Color(0.7, 1.0, 0.8), 1.3)
	glow_tween.tween_property(title_label, "modulate", Color.WHITE, 1.3)

	if shown_once:
		visible = false
	else:
		visible = true
		get_tree().paused = true


func setup(page):
	login_page = page
	login_page.logged_in.connect(func(_n): _refresh())
	login_page.visibility_changed.connect(_on_login_visibility)
	_refresh()


func _refresh():
	if GameState.logged_in:
		status_label.text = "Welcome back, %s" % GameState.username
		login_button.text = GameState.username
	else:
		status_label.text = "Not logged in: you will play as a guest"
		login_button.text = "Login"


# hide this whole page while the login page is open, so only one page is on screen
func _on_login_pressed():
	login_open = true
	visible = false
	login_page.open()


# the login page just closed (Close button or successful login): come back
func _on_login_visibility():
	if login_page.visible:
		return
	if login_open:
		login_open = false
		visible = true
		get_tree().paused = true


func _on_self_visibility():
	if rain != null:
		rain.set_process(visible)


# safety net: stay paused while this page is showing (not during the transition)
func _process(_delta):
	if visible and not starting:
		get_tree().paused = true


func _on_play():
	if starting:
		return
	starting = true
	shown_once = true
	play_button.disabled = true
	login_button.disabled = true
	get_tree().paused = false

	# part 1: the menu fades and grows, the rain rushes
	content.pivot_offset = size / 2.0
	var t1 = create_tween()
	t1.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t1.set_parallel(true)
	t1.tween_property(content, "modulate:a", 0.0, 0.4)
	t1.tween_property(content, "scale", Vector2(1.15, 1.15), 0.4)
	t1.tween_property(rain, "boost", 6.0, 0.6)
	await t1.finished

	# part 2: the page dissolves, the camera settles, a banner pops in
	_show_banner()
	_zoom_in()
	var t2 = create_tween()
	t2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t2.tween_property(self, "modulate:a", 0.0, 0.8)
	await t2.finished

	if glow_tween != null:
		glow_tween.kill()
	visible = false
	modulate = Color.WHITE
	starting = false

	var tut = preload("res://scripts/tutorial_ui.gd").new()
	get_parent().add_child(tut)
	tut.begin()
# the camera starts zoomed in and eases back to its normal zoom
func _zoom_in():
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return
	var normal = cam.zoom
	cam.zoom = normal * 1.35
	var tz = create_tween()
	tz.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tz.tween_property(cam, "zoom", normal, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# gold banner that pops in, holds, and fades out
func _show_banner():
	var layer = get_parent()
	var l = _label("DEFEND THE CORE!", 72)
	l.process_mode = Node.PROCESS_MODE_ALWAYS
	l.z_index = 95
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	l.modulate.a = 0.0
	layer.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.pivot_offset = get_viewport_rect().size / 2.0
	l.scale = Vector2(1.5, 1.5)

	var tw = l.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(l, "modulate:a", 1.0, 0.35)
	tw.tween_property(l, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.6)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(l.queue_free)
