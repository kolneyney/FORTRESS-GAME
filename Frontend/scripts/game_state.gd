extends Node

# coins you start every run with (set to 200 while testing, 0 for the real game)
const START_COINS = 0

var coins = START_COINS
var temp_coins = 0
var streak = 0
var best_wave = 0

# login info (filled in by the login page)
var token = ""
var username = ""
var logged_in = false

var levels = {"firewall": 0, "antivirus": 0, "mfa": 0, "backup": 0}
const BASE_PRICE = {"firewall": 15, "antivirus": 25, "mfa": 50, "backup": 100}
const MAX_LEVEL = 5


func reset():
	coins = START_COINS
	temp_coins = 0
	streak = 0
	for k in levels:
		levels[k] = 0


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
	return true


# no longer used by the castle, kept so older scripts do not break
func reduce_damage(amount):
	var total = 0
	for k in levels:
		total += levels[k]
	return int(round(amount * (1.0 - min(total * 0.05, 0.8))))
	
func load_player_progress(player_data, defense_data):
	coins = player_data.get("coins", 0)
	streak = player_data.get("current_streak", 0)
	best_wave = player_data.get("best_streak", 0)
	temp_coins = 0

	for defense in defense_data.get("defenses", []):
		var defense_name = defense.get("name", "").to_lower()

		if levels.has(defense_name):
			levels[defense_name] = defense.get("level", 0)
