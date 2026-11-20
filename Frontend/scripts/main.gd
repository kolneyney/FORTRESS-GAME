extends Node2D

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"
const COIN_SCRIPT = preload("res://scripts/coin_icon.gd")
const HEART_SCRIPT = preload("res://scripts/heart_icon.gd")

# seconds to shop or take the quiz before each level starts
const PREP_TIME = 20.0

# ---------------------------------------------------------------
# LEVEL TABLE - change these numbers to tune the difficulty
#   count : how many enemies spawn
#   hp    : enemy health multiplier
#   gap   : seconds between spawns
#   bonus : coins for clearing the level the first time
#   heal  : castle HP repaired at the start of the NEXT level
#   types : enemy types that can appear (repeat a name to make it more common)
# ---------------------------------------------------------------
const LEVELS = [
	{"count": 8, "hp": 1.0, "gap": 2.2, "bonus": 10, "heal": 10, "types": ["malware", "ddos"]},
	{"count": 12, "hp": 1.3, "gap": 1.9, "bonus": 10, "heal": 10, "types": ["malware", "ddos", "brute_force"]},
	{"count": 16, "hp": 1.6, "gap": 1.6, "bonus": 15, "heal": 15, "types": ["malware", "ddos", "brute_force", "phishing"]},
	{"count": 20, "hp": 2.0, "gap": 1.35, "bonus": 15, "heal": 15, "types": ["malware", "ddos", "brute_force", "phishing", "ransomware"]},
	{"count": 24, "hp": 2.5, "gap": 1.15, "bonus": 15, "heal": 15, "types": ["malware", "ddos", "brute_force", "phishing", "ransomware"]},
]

@export var enemy_scene: PackedScene
@onready var castle = $Castle
@onready var health_label = $UI/HealthLabel
@onready var coins_label = $UI/HUD/CoinsLabel
@onready var routes = $Routes.get_children()

var level = 1
var state = "break"
var break_left = PREP_TIME
var to_spawn = 0
var done_timer = 0.0
var bonus_given = 0
var heal_given = 0
var board_result = ""
var overlay
var overlay_fx
var prep_bar

var status_label
var board_page
var heart


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
	_juice(b)
	return b


# a button with a small beating heart on each side
func _heart_button(text, font_size, height):
	var b = _button(text, font_size, height)
	var s = 34.0
	for side in 2:
		var h = HEART_SCRIPT.new()
		h.icon_size = s
		b.add_child(h)
		h.anchor_top = 0.5
		h.anchor_bottom = 0.5
		h.offset_top = -s / 2.0
		h.offset_bottom = s / 2.0
		if side == 0:
			h.anchor_left = 0.0
			h.anchor_right = 0.0
			h.offset_left = 22.0
			h.offset_right = 22.0 + s
		else:
			h.anchor_left = 1.0
			h.anchor_right = 1.0
			h.offset_left = -22.0 - s
			h.offset_right = -22.0
	return b


# ---------- little animations ----------

# the button grows a little while the mouse is over it
func _juice(b):
	b.mouse_entered.connect(_hover.bind(b, 1.06))
	b.mouse_exited.connect(_hover.bind(b, 1.0))


func _hover(b, s):
	b.pivot_offset = b.size / 2.0
	var tw = b.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(b, "scale", Vector2(s, s), 0.1)


# the button pops when it is clicked
func _pop(b):
	b.pivot_offset = b.size / 2.0
	b.scale = Vector2(1.18, 1.18)
	var tw = b.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(b, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# a full-screen page zooms in with a fade every time it opens
func _watch_page(page):
	page.visibility_changed.connect(_on_page_visibility.bind(page))


func _on_page_visibility(page):
	if not page.visible:
		return
	if page.has_meta("anim"):
		var old = page.get_meta("anim")
		if old != null and old.is_valid():
			old.kill()
	page.pivot_offset = page.size / 2.0
	page.modulate.a = 0.0
	page.scale = Vector2(0.9, 0.9)
	var tw = page.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(page, "modulate:a", 1.0, 0.25)
	tw.tween_property(page, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	page.set_meta("anim", tw)


# a box pops in: the panel zooms up, then its rows appear one after another
func _pop_overlay(layer, panel):
	layer.modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(layer) or not is_instance_valid(panel):
		return

	panel.pivot_offset = panel.get_combined_minimum_size() / 2.0
	panel.scale = Vector2(0.55, 0.55)
	var tw = layer.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(layer, "modulate:a", 1.0, 0.2)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var box = panel.get_child(0)
	var i = 0
	for c in box.get_children():
		c.modulate.a = 0.0
		c.pivot_offset = c.get_combined_minimum_size() / 2.0
		c.scale = Vector2(0.8, 0.8)
		var t2 = c.create_tween()
		t2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t2.set_parallel(true)
		t2.tween_property(c, "modulate:a", 1.0, 0.25).set_delay(0.15 + i * 0.08)
		t2.tween_property(c, "scale", Vector2.ONE, 0.35).set_delay(0.15 + i * 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1


# gold coins fall behind the box
func _coin_shower(fx, count):
	var vp = get_viewport_rect().size
	for i in count:
		var c = COIN_SCRIPT.new()
		c.coin_size = randf_range(26.0, 46.0)
		c.spin = randf_range(2.0, 5.0)
		fx.add_child(c)
		c.position = Vector2(randf_range(0.0, vp.x - 50.0), -60.0)
		var tw = c.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_interval(randf_range(0.0, 0.9))
		tw.tween_property(c, "position:y", vp.y + 60.0, randf_range(1.8, 3.2))
		tw.tween_callback(c.queue_free)


func _ready():
	level = clampi(GameState.current_level, 1, LEVELS.size())

	# carry castle HP over from the previous level, then add the repair
	castle.health = maxi(GameState.castle_hp, 1)
	var gain = 0
	if GameState.pending_heal > 0:
		gain = maxi(mini(GameState.pending_heal, 100 - castle.health), 0)
		castle.health += gain
	GameState.pending_heal = 0
	GameState.castle_hp = castle.health
	GameState.level_start_hp = castle.health

	$SpawnTimer.stop()
	$SpawnTimer.timeout.connect(_on_spawn_tick)
	castle.health_changed.connect(_on_health_changed)
	castle.castle_destroyed.connect(_game_over)
	_on_health_changed(castle.health)

	# quiz and shop buttons: open the page, pop, grow on hover
	var quiz_button = $UI/HUD/QuizButton
	var shop_button = $UI/HUD/ShopButton
	quiz_button.pressed.connect($UI/QuizUI.open)
	shop_button.pressed.connect($UI/ShopUI.open)
	_juice(quiz_button)
	_juice(shop_button)
	quiz_button.pressed.connect(_pop.bind(quiz_button))
	shop_button.pressed.connect(_pop.bind(shop_button))
	_watch_page($UI/QuizUI)
	_watch_page($UI/ShopUI)

	# top bar: heart + Castle HP, then a spinning coin and the Coins label
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 60)
	top_bar.position = Vector2(30, 20)
	$UI.add_child(top_bar)

	var hp_box = HBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 12)
	top_bar.add_child(hp_box)
	heart = HEART_SCRIPT.new()
	heart.icon_size = 44.0
	heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_box.add_child(heart)
	health_label.reparent(hp_box)
	_on_health_changed(castle.health)

	var coin_box = HBoxContainer.new()
	coin_box.add_theme_constant_override("separation", 12)
	top_bar.add_child(coin_box)
	var hud_coin = COIN_SCRIPT.new()
	hud_coin.coin_size = 40.0
	hud_coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_box.add_child(hud_coin)
	coins_label.reparent(coin_box)

	# leaderboard page and its button
	board_page = preload("res://scripts/leaderboard_ui.gd").new()
	$UI.add_child(board_page)
	_watch_page(board_page)
	var board_button = _button("Leaderboard", 28, 60)
	$UI/HUD.add_child(board_button)
	board_button.pressed.connect(board_page.open)
	board_button.pressed.connect(_pop.bind(board_button))

	var info_button = _button("Info", 28, 60)
	info_button.custom_minimum_size = Vector2(130, 60)
	$UI.add_child(info_button)
	info_button.anchor_left = 1.0
	info_button.anchor_right = 1.0
	info_button.offset_left = -190
	info_button.offset_right = -40
	info_button.offset_top = 20
	info_button.offset_bottom = 80

	var info_page = preload("res://scripts/info_ui.gd").new()
	$UI.add_child(info_page)
	_watch_page(info_page)
	info_button.pressed.connect(info_page.open)
	info_button.pressed.connect(_pop.bind(info_button))

	var login_button = _button("Login", 28, 60)
	login_button.clip_text = true
	if GameState.logged_in:
		login_button.text = GameState.username
	$UI.add_child(login_button)
	login_button.anchor_left = 1.0
	login_button.anchor_right = 1.0
	login_button.offset_left = -400
	login_button.offset_right = -210
	login_button.offset_top = 20
	login_button.offset_bottom = 80

	var login_page = preload("res://scripts/auth_ui.gd").new()
	$UI.add_child(login_page)
	_watch_page(login_page)
	login_button.pressed.connect(login_page.open)
	login_button.pressed.connect(_pop.bind(login_button))
	login_page.logged_in.connect(func(n): login_button.text = n if n != "" else "Login")

	var start_page = preload("res://scripts/start_ui.gd").new()
	$UI.add_child(start_page)
	start_page.setup(login_page)

	status_label = _label("", 28)
	status_label.position = Vector2(30, 150)
	$UI.add_child(status_label)

	if gain > 0:
		_heal_popup(gain)


func _process(delta):
	coins_label.text = "Coins: %d" % GameState.coins

	if state == "break":
		break_left -= delta
		status_label.text = "Level %d / %d starts in %d s" % [level, LEVELS.size(), ceili(break_left)]
		if break_left <= 0.0:
			start_level()

	elif state == "fight":
		var alive = get_tree().get_nodes_in_group("enemies").size()
		var left = alive + maxi(to_spawn, 0)
		status_label.text = "Level %d / %d  -  enemies left: %d" % [level, LEVELS.size(), left]
		if to_spawn <= 0 and alive == 0:
			_level_complete()

	elif state == "cleared":
		done_timer -= delta
		if done_timer <= 0.0:
			state = "box"
			_show_level_box()

	elif state == "waiting":
		if level >= LEVELS.size():
			status_label.text = "All levels complete! Visit the Quiz or Shop, or play again."
		else:
			status_label.text = "Level %d cleared! Visit the Quiz or Shop, then continue." % level


func start_level():
	state = "fight"
	var cfg = LEVELS[level - 1]
	to_spawn = cfg["count"]
	$SpawnTimer.wait_time = cfg["gap"]
	$SpawnTimer.start()
	_banner("LEVEL %d" % level)


func _on_spawn_tick():
	if state != "fight":
		return
	_spawn_enemy()
	to_spawn -= 1
	if to_spawn <= 0:
		$SpawnTimer.stop()


func _spawn_enemy():
	var cfg = LEVELS[level - 1]
	var type = cfg["types"].pick_random()

	var route = routes.pick_random()
	var points = []
	for m in route.get_children():
		points.append(m.global_position)
	points.append($Gate.global_position)

	var e = enemy_scene.instantiate()
	e.threat_type = type
	e.hp_mult = cfg["hp"]
	e.waypoints = points
	e.target_position = castle.global_position
	$Enemies.add_child(e)
	e.global_position = points[0] + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))


func _level_complete():
	state = "cleared"
	done_timer = 0.7
	$SpawnTimer.stop()

	# the repair is applied at the start of the next level (see _ready)
	heal_given = LEVELS[level - 1]["heal"]

	# coins are given only the first time a level is cleared
	bonus_given = 0
	if level > GameState.best_level:
		bonus_given = LEVELS[level - 1]["bonus"]
		GameState.coins += bonus_given
		GameState.best_level = level

	# leaderboard score = coins LEFT now (coins already spent do not count)
	board_result = board_page.submit_score(GameState.coins, level)


func _on_health_changed(h):
	health_label.text = "Castle HP: %d" % h
	GameState.castle_hp = h
	# low health: the heart beats fast and the text turns red
	if h <= 30:
		health_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		if heart != null:
			heart.rate = 3.2
	else:
		health_label.remove_theme_color_override("font_color")
		if heart != null:
			heart.rate = 1.3


func _game_over():
	if state == "over" or state == "box" or state == "cleared" or state == "waiting":
		return
	state = "over"
	$SpawnTimer.stop()
	health_label.text = "DEFEATED"
	_show_defeat_box()


# ---------- pop-ups and boxes ----------

# green "+N HP" under the Castle HP label when a new level starts
func _heal_popup(gain):
	await get_tree().create_timer(0.3).timeout
	health_label.modulate = Color(0.4, 1.0, 0.5)
	create_tween().tween_property(health_label, "modulate", Color.WHITE, 1.5)

	var l = _label("+%d HP" % gain, 40)
	l.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(l)
	l.global_position = health_label.global_position + Vector2(0, 50)
	var tw = l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 30.0, 1.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.8)
	tw.chain().tween_callback(l.queue_free)


func _banner(text):
	var l = _label(text, 72)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	l.modulate.a = 0.0
	$UI.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.pivot_offset = get_viewport_rect().size / 2.0
	l.scale = Vector2(1.5, 1.5)

	var tw = l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	tw.tween_property(l, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.7)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(l.queue_free)


# builds a dark overlay with a framed panel and returns its parts
func _build_overlay(z, width):
	var layer = Control.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.z_index = z
	$UI.add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# the coin shower goes here, behind the panel
	var fx = Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fx)
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center = CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("2b1d2a")
	style.border_color = Color("d1c7b7")
	style.set_border_width_all(4)
	style.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)

	return {"layer": layer, "fx": fx, "panel": panel, "box": box}


# the level-complete and defeat boxes use this; it also pauses the game
func _make_overlay():
	get_tree().paused = true
	var o = _build_overlay(120, 780)
	overlay = o["layer"]
	overlay_fx = o["fx"]
	_pop_overlay(o["layer"], o["panel"])
	return o["box"]


func _centered(text, font_size, color):
	var l = _label(text, font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(700, 0)
	l.add_theme_color_override("font_color", color)
	return l


# a spinning coin next to a line of text
func _coin_line(text):
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	var icon = COIN_SCRIPT.new()
	icon.coin_size = 44.0
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var l = _label(text, 34)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	row.add_child(l)
	return row


func _board_text():
	match board_result:
		"saved":
			return "New best! Your coins are on the leaderboard."
		"lower":
			return "Your best leaderboard score is higher, so it stays."
		"sent":
			return "Score sent to the leaderboard."
		"guest":
			return "Log in to put your coins on the leaderboard."
	return ""


func _show_level_box():
	var last = level >= LEVELS.size()
	var box = _make_overlay()

	var title_text = "LEVEL %d COMPLETE!" % level
	if last:
		title_text = "ALL LEVELS COMPLETE!"
	box.add_child(_centered(title_text, 54, Color(1.0, 0.9, 0.3)))

	var info_text = "Castle HP: %d / 100" % castle.health
	if bonus_given > 0:
		info_text += "\nBonus: +%d coins" % bonus_given
	else:
		info_text += "\nNo coin bonus for replaying a level"
	if last:
		info_text += "\nYou defended the core!"
	else:
		var gain_now = maxi(mini(heal_given, 100 - castle.health), 0)
		if gain_now > 0:
			info_text += "\nRepair at the start of Level %d: +%d HP" % [level + 1, gain_now]
		else:
			info_text += "\nThe castle is already at full health"
	box.add_child(_centered(info_text, 28, Color.WHITE))

	box.add_child(_coin_line("Coins left: %d" % GameState.coins))
	var board_text = _board_text()
	if board_text != "":
		box.add_child(_centered(board_text, 22, Color(0.75, 0.7, 0.8)))

	if last:
		var again = _heart_button("Play Again", 36, 80)
		again.pressed.connect(_ask_start_over)
		box.add_child(again)
	else:
		var next = _heart_button("Continue to Level %d" % (level + 1), 36, 80)
		next.pressed.connect(_on_next)
		box.add_child(next)

	var restart = _heart_button("Restart Level %d" % level, 30, 64)
	restart.pressed.connect(_ask_restart)
	box.add_child(restart)

	var later = _heart_button("Close  (quiz or shop first)", 26, 64)
	later.pressed.connect(_on_close_box)
	box.add_child(later)

	_coin_shower(overlay_fx, 20 if last else 14)


func _show_defeat_box():
	var box = _make_overlay()

	box.add_child(_centered("DEFEATED", 64, Color(1.0, 0.45, 0.4)))

	var text = "You fell on level %d of %d.\nYour coins and upgrades are kept. Answer more quiz questions to earn coins, then try again!" % [level, LEVELS.size()]
	box.add_child(_centered(text, 26, Color.WHITE))

	var retry = _button("Retry Level %d" % level, 36, 80)
	retry.pressed.connect(_on_retry)
	box.add_child(retry)

	var over = _button("Start Over (Level 1)", 28, 60)
	over.pressed.connect(_ask_start_over)
	box.add_child(over)


# ---------- "are you sure?" box ----------

func _confirm(title, text, yes_text, on_yes):
	var o = _build_overlay(140, 700)
	var box = o["box"]

	box.add_child(_centered(title, 44, Color(1.0, 0.9, 0.3)))
	box.add_child(_centered(text, 26, Color.WHITE))

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)

	var yes = _button(yes_text, 30, 72)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(on_yes)
	row.add_child(yes)

	var no = _button("No, go back", 30, 72)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var layer = o["layer"]
	no.pressed.connect(func(): layer.queue_free())
	row.add_child(no)

	_pop_overlay(o["layer"], o["panel"])


func _ask_restart():
	_confirm(
		"RESTART LEVEL %d?" % level,
		"Your castle HP goes back to what it was when this level began. Your coins and towers are kept.",
		"Yes, restart",
		_on_retry
	)


func _ask_start_over():
	_confirm(
		"START OVER?",
		"You will go back to Level 1 and lose all your coins, towers and progress.",
		"Yes, start over",
		_on_start_over
	)


# ---------- after the level box is closed ----------

# close the level box so the player can use the quiz or shop, then continue
func _on_close_box():
	if overlay != null:
		overlay.queue_free()
		overlay = null
	get_tree().paused = false
	state = "waiting"
	_show_prep_bar()


# bottom bar with Restart and Continue; both bounce in
func _show_prep_bar():
	if prep_bar != null and is_instance_valid(prep_bar):
		prep_bar.queue_free()
	var last = level >= LEVELS.size()

	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 24)
	bar.z_index = 50
	$UI.add_child(bar)
	prep_bar = bar
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -502
	bar.offset_right = 502
	bar.offset_top = -170
	bar.offset_bottom = -80

	var restart = _heart_button("Restart Level %d" % level, 28, 90)
	restart.custom_minimum_size = Vector2(420, 90)
	restart.pressed.connect(_ask_restart)
	bar.add_child(restart)

	var go_text = "Continue to Level %d" % (level + 1)
	if last:
		go_text = "Play Again"
	var go = _heart_button(go_text, 36, 90)
	go.custom_minimum_size = Vector2(560, 90)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if last:
		go.pressed.connect(_ask_start_over)
	else:
		go.pressed.connect(_on_next)
	bar.add_child(go)

	# fade in, bounce each button, then pulse the Continue button gold
	bar.modulate.a = 0.0
	var fade = bar.create_tween()
	fade.tween_property(bar, "modulate:a", 1.0, 0.25)

	var i = 0
	for b in [restart, go]:
		b.pivot_offset = b.custom_minimum_size / 2.0
		b.scale = Vector2(0.5, 0.5)
		var t = b.create_tween()
		t.tween_property(b, "scale", Vector2.ONE, 0.45).set_delay(i * 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1

	var pulse = go.create_tween()
	pulse.set_loops()
	pulse.tween_property(go, "modulate", Color(1.0, 0.95, 0.6), 0.7)
	pulse.tween_property(go, "modulate", Color.WHITE, 0.7)


func _on_next():
	GameState.current_level = mini(level + 1, LEVELS.size())
	GameState.pending_heal = heal_given
	_reload()


# restart or retry: back to the HP you had when this level began, no repair
func _on_retry():
	GameState.current_level = level
	GameState.castle_hp = maxi(GameState.level_start_hp, 1)
	GameState.pending_heal = 0
	_reload()


func _on_start_over():
	GameState.new_game()
	_reload()


func _reload():
	get_tree().paused = false
	get_tree().reload_current_scene()
