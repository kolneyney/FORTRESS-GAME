extends Node2D

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"

@export var enemy_scene: PackedScene
@onready var castle = $Castle
@onready var health_label = $UI/HealthLabel
@onready var coins_label = $UI/HUD/CoinsLabel
@onready var routes = $Routes.get_children()

var type_names = ["malware", "ddos", "brute_force", "phishing", "ransomware"]

var wave = 0
var cleared = 0
var state = "break"
var break_left = 15.0
var to_spawn = 0
var clear_msg = ""

var wave_label
var call_button


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


func _ready():
	$SpawnTimer.stop()
	$SpawnTimer.timeout.connect(_on_spawn_tick)
	castle.health_changed.connect(_on_health_changed)
	castle.castle_destroyed.connect(_game_over)
	_on_health_changed(castle.health)
	$UI/HUD/QuizButton.pressed.connect($UI/QuizUI.open)
	$UI/HUD/ShopButton.pressed.connect($UI/ShopUI.open)

	# top bar: Castle HP and Coins side by side
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 60)
	top_bar.position = Vector2(30, 20)
	$UI.add_child(top_bar)
	health_label.reparent(top_bar)
	coins_label.reparent(top_bar)

	var info_button = _button("Info", 28, 60)
	info_button.custom_minimum_size = Vector2(130, 60)
	$UI.add_child(info_button)
	info_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 30)

	var info_page = preload("res://scripts/info_ui.gd").new()
	$UI.add_child(info_page)
	info_button.pressed.connect(info_page.open)

	call_button = _button("Call Wave (+1-5)", 28, 60)
	call_button.pressed.connect(_on_call_wave)
	$UI/HUD.add_child(call_button)

	wave_label = _label("", 28)
	wave_label.position = Vector2(30, 150)
	$UI.add_child(wave_label)


func _process(delta):
	coins_label.text = "Coins: %d" % GameState.coins

	if state == "break":
		break_left -= delta
		wave_label.text = "%sNext wave in %d s" % [clear_msg, ceili(break_left)]
		if break_left <= 0.0:
			start_wave()
	elif state == "fight":
		var alive = get_tree().get_nodes_in_group("enemies").size()
		wave_label.text = "Wave %d  -  enemies left: %d" % [wave, alive + maxi(to_spawn, 0)]
		if to_spawn <= 0 and alive == 0:
			var bonus = 3 + wave
			GameState.coins += bonus
			cleared += 1
			clear_msg = "Wave %d cleared! +%d coins.  " % [wave, bonus]
			state = "break"
			break_left = 10.0


func start_wave():
	wave += 1
	state = "fight"
	clear_msg = ""
	to_spawn = 4 + wave * 2
	$SpawnTimer.wait_time = maxf(0.6, 2.0 - wave * 0.1)
	$SpawnTimer.start()


func _on_spawn_tick():
	if state != "fight":
		return
	_spawn_enemy()
	to_spawn -= 1
	if to_spawn <= 0:
		$SpawnTimer.stop()


func _spawn_enemy():
	# a new enemy type unlocks every 2 waves
	var unlocked = mini(2 + floori((wave - 1) / 2.0), type_names.size())
	var type = type_names[randi() % unlocked]

	var route = routes.pick_random()
	var points = []
	for m in route.get_children():
		points.append(m.global_position)
	points.append($Gate.global_position)

	var e = enemy_scene.instantiate()
	e.threat_type = type
	e.hp_mult = 1.0 + (wave - 1) * 0.12
	e.waypoints = points
	e.target_position = castle.global_position
	$Enemies.add_child(e)
	e.global_position = points[0] + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))


# risk and reward: free coins now, but a burst of extra enemies
func _on_call_wave():
	if state == "over":
		return
	if state == "break":
		start_wave()
	var bonus = randi_range(1, 5)
	GameState.coins += bonus
	_popup("+%d" % bonus)
	var extra = 3 + wave
	for i in extra:
		if state == "over":
			return
		_spawn_enemy()
		await get_tree().create_timer(0.2, false).timeout


func _popup(text):
	var l = _label(text, 32)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	$UI.add_child(l)
	l.position = call_button.global_position + Vector2(20, -10)
	var tw = l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 40.0, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(l.queue_free)


func _on_health_changed(h):
	health_label.text = "Castle HP: %d" % h


func _game_over():
	state = "over"
	$SpawnTimer.stop()
	if cleared > GameState.best_wave:
		GameState.best_wave = cleared
	health_label.text = "GAME OVER"
	_show_game_over()


func _show_game_over():
	var layer = Control.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center = CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var title = _label("GAME OVER", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var info = _label("Waves cleared: %d     Best: %d" % [cleared, GameState.best_wave], 32)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)

	var again = _button("Try Again", 40, 80)
	again.custom_minimum_size = Vector2(320, 80)
	again.pressed.connect(_on_try_again)
	box.add_child(again)

	get_tree().paused = true


func _on_try_again():
	GameState.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
