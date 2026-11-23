extends Node

const START_COINS = 0
const SAVE_PATH = "user://gamestate.cfg"

var coins = START_COINS
var temp_coins = 0
var streak = 0
var best_wave = 0

# level progress (survives Retry and Continue while the game is open)
var current_level = 1
var best_level = 0
var castle_hp = 100
var level_start_hp = 100
var pending_heal = 0

# login info (filled in by the login page)
var token = ""
var username = ""
var logged_in = false

var levels = {"firewall": 0, "antivirus": 0, "mfa": 0, "backup": 0}
const BASE_PRICE = {"firewall": 15, "antivirus": 25, "mfa": 40, "backup": 60}
const MAX_LEVEL = 5

var _last_saved_snapshot: String = ""
var _save_timer: float = 0.0


func _ready():
	load_local_state()


func _process(delta):
	# Auto-save progress to browser storage every 1 second if anything changed
	_save_timer += delta
	if _save_timer >= 1.0:
		_save_timer = 0.0
		var current_snapshot = _make_snapshot()
		if current_snapshot != _last_saved_snapshot:
			save_local_state()
			_last_saved_snapshot = current_snapshot


func _make_snapshot() -> String:
	return str([coins, streak, best_wave, current_level, best_level, castle_hp, token, username, logged_in, levels])


func save_local_state():
	var config = ConfigFile.new()
	config.set_value("auth", "token", token)
	config.set_value("auth", "username", username)
	config.set_value("auth", "logged_in", logged_in)

	config.set_value("progress", "coins", coins)
	config.set_value("progress", "streak", streak)
	config.set_value("progress", "best_wave", best_wave)
	config.set_value("progress", "current_level", current_level)
	config.set_value("progress", "best_level", best_level)
	config.set_value("progress", "castle_hp", castle_hp)
	config.set_value("progress", "level_start_hp", level_start_hp)
	config.set_value("progress", "levels", levels.duplicate())
	config.save(SAVE_PATH)


func load_local_state():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	token = config.get_value("auth", "token", "")
	username = config.get_value("auth", "username", "")
	logged_in = config.get_value("auth", "logged_in", false)

	coins = config.get_value("progress", "coins", START_COINS)
	streak = config.get_value("progress", "streak", 0)
	best_wave = config.get_value("progress", "best_wave", 0)
	current_level = config.get_value("progress", "current_level", 1)
	best_level = config.get_value("progress", "best_level", 0)
	castle_hp = config.get_value("progress", "castle_hp", 100)
	level_start_hp = config.get_value("progress", "level_start_hp", 100)

	var saved_levels = config.get_value("progress", "levels", {})
	if typeof(saved_levels) == TYPE_DICTIONARY:
		for k in levels:
			if saved_levels.has(k):
				levels[k] = saved_levels[k]

	_last_saved_snapshot = _make_snapshot()


func new_game():
	temp_coins = 0
	streak = 0
	current_level = 1
	castle_hp = 100
	level_start_hp = 100
	pending_heal = 0
	for k in levels:
		levels[k] = 0
	save_local_state()


func reset():
	new_game()


func clear_session():
	coins = START_COINS
	best_level = 0
	best_wave = 0

	token = ""
	username = ""
	logged_in = false

	new_game()
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("gamestate.cfg"):
		dir.remove("gamestate.cfg")
	_last_saved_snapshot = _make_snapshot()


func price_of(defense):
	return BASE_PRICE[defense] * (levels[defense] + 1)


func buy(defense):
	if levels[defense] >= MAX_LEVEL:
		return false
	var cost = price_of(defense)
	if coins < cost:
		return false
	coins -= cost
	levels[defense] += 1
	save_local_state()
	return true


# no longer used by the castle, kept so older scripts do not break
func reduce_damage(amount):
	var total = 0
	for k in levels:
		total += levels[k]
	return int(round(amount * (1.0 - min(total * 0.05, 0.8))))


func load_player_progress(player_data, defense_data):
	coins = player_data.get("coins", 0)
	best_level = player_data.get("best_level", 0)
	streak = player_data.get("current_streak", 0)
	best_wave = player_data.get("best_streak", 0)
	temp_coins = 0

	for defense in defense_data.get("defenses", []):
		var defense_name = defense.get("name", "").to_lower()

		if levels.has(defense_name):
			levels[defense_name] = defense.get("level", 0)

	save_local_state()
