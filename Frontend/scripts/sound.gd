extends Node

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"
const EXTENSIONS = ["ogg", "wav", "mp3"]

# volumes in dB (0 = full volume, lower numbers = quieter)
const SFX_DB = -6.0
const MUSIC_DB = -6.0

var sounds = {}
var players = []
var next_player = 0
var music_player
var music_on = true
var music_started = false
var toggle_button

# finds assets/audio/<name>.ogg, .wav or .mp3 (missing files are skipped silently)
func _find(sound_name):
	for ext in EXTENSIONS:
		var path = "res://assets/audio/%s.%s" % [sound_name, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null

# makes the track start again by itself when it ends (supports wav, ogg, and mp3)
func _enable_loop(stream):
	if stream == null:
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	elif "loop" in stream:
		stream.loop = true

func _ready():
	# keep working while the game is paused (quiz, shop, menus)
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in ["click", "login", "correct", "wrong", "win", "lose"]:
		sounds[n] = _find(n)

	# a small pool of players so sounds can overlap
	for i in 6:
		var p = AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		players.append(p)

	# background music: looks for bg, then background, then music
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = MUSIC_DB
	music_player.stream = _find("bg")
	if music_player.stream == null:
		music_player.stream = _find("background")
	if music_player.stream == null:
		music_player.stream = _find("music")

	if music_player.stream == null:
		push_warning("Background music file not found in res://assets/audio/")
	else:
		_enable_loop(music_player.stream)

	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	# every button in the game plays the click sound automatically
	get_tree().node_added.connect(_on_node_added)
	_build_toggle()
	_hook_later()
	start_music()

func _on_node_added(node):
	if node is Button:
		if not node.pressed.is_connected(_on_click):
			node.pressed.connect(_on_click)

# also hook the buttons that were already on screen when the game started
func _hook_later():
	await get_tree().process_frame
	await get_tree().process_frame
	_hook_tree(get_tree().root)
	await get_tree().create_timer(1.0).timeout
	_hook_tree(get_tree().root)

func _hook_tree(node):
	_on_node_added(node)
	for c in node.get_children():
		_hook_tree(c)

func _on_click():
	play("click")
	start_music()

func play(sound_name):
	var s = sounds.get(sound_name)
	if s == null:
		return
	var p = players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = s
	p.pitch_scale = randf_range(0.96, 1.04)
	p.play()

# call this on launch or after the player's first click
func start_music():
	if music_started:
		return
	music_started = true
	if music_on and music_player.stream != null:
		music_player.play()

# backup loop: if the track ever ends, play it again
func _on_music_finished():
	if music_on:
		music_player.play()

# turns ONLY the music off or on; click and other sounds are not touched
func toggle_music():
	music_on = not music_on
	if music_on:
		toggle_button.text = "Music: ON"
		if music_started and music_player.stream != null and not music_player.playing:
			music_player.play()
	else:
		toggle_button.text = "Music: OFF"
		music_player.stop()

# Music ON/OFF button in the top-right corner, under Login and Info
func _build_toggle():
	var layer = CanvasLayer.new()
	layer.layer = 200
	add_child(layer)

	toggle_button = Button.new()
	toggle_button.text = "Music: ON"
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.add_theme_font_override("font", load(FONT_PATH))
	toggle_button.add_theme_font_size_override("font_size", 30)
	layer.add_child(toggle_button)

	toggle_button.anchor_left = 1.0
	toggle_button.anchor_right = 1.0
	toggle_button.anchor_top = 0.0
	toggle_button.anchor_bottom = 0.0
	toggle_button.offset_left = -330
	toggle_button.offset_right = -40
	toggle_button.offset_top = 100
	toggle_button.offset_bottom = 170
	toggle_button.pressed.connect(toggle_music)
