extends Control

const FONT_PATH = "res://assets/fonts/PixeloidSans-lxa3y.ttf"
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

const ENEMY_INFO = {
	"malware": {
		"name": "Malware",
		"weak": "Antivirus",
		"text": "Malicious software that sneaks into a system to damage it or steal data. Steady and common, so expect plenty of it.",
	},
	"ddos": {
		"name": "DDoS",
		"weak": "Firewall",
		"text": "Floods a service with fake traffic until nobody can use it. Small and fast, and it arrives in swarms.",
	},
	"brute_force": {
		"name": "Brute Force",
		"weak": "MFA Knight",
		"text": "Guesses passwords again and again until one works. Slow, but it takes a lot of hits to stop.",
	},
	"phishing": {
		"name": "Phishing",
		"weak": "No single counter",
		"text": "Tricks people with fake messages into giving away secrets. No hero counters it directly. In real life, the best defense is knowing the signs, which is what the quiz teaches.",
	},
	"ransomware": {
		"name": "Ransomware",
		"weak": "Backup",
		"text": "Locks your files and demands payment. Huge and slow, and it hits the castle very hard if it gets through.",
	},
}

const HERO_INFO = {
	"firewall": {
		"name": "Firewall",
		"strong": "DDoS",
		"attack": "Fireballs that burn, and the flames spread to nearby enemies",
		"text": "Blocks and burns unwanted traffic. A long-range defender that keeps enemies burning while they walk.",
	},
	"antivirus": {
		"name": "Antivirus",
		"strong": "Malware",
		"attack": "A scan pulse that hurts and slows every enemy in range",
		"text": "Scans everything nearby. Every enemy inside its ring takes damage and moves at half speed.",
	},
	"mfa": {
		"name": "MFA Knight",
		"strong": "Brute Force",
		"attack": "Sword slashes that stun close enemies",
		"text": "A second lock on the door. Short range, but heavy damage, and stunned enemies cannot move.",
	},
	"backup": {
		"name": "Backup",
		"strong": "Ransomware",
		"attack": "A bundle of four bolts: fire, scan, slash and backup",
		"text": "Your safety net. It fires all four attacks at once, so every volley burns, slows and stuns.",
	},
}

var current_tab = "enemies"
var grid
var tab_enemies
var tab_heroes
var detail_icon
var detail_name
var detail_stats
var detail_text


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
	panel.custom_minimum_size = Vector2(1300, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("2b1d2a")
	style.border_color = Color("d1c7b7")
	style.set_border_width_all(4)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title = _label(44)
	title.text = "ALMANAC"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 16)
	box.add_child(tabs)

	tab_enemies = _button("Enemies", 30, 60)
	tab_enemies.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_enemies.pressed.connect(_show_tab.bind("enemies"))
	tabs.add_child(tab_enemies)

	tab_heroes = _button("Heroes", 30, 60)
	tab_heroes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_heroes.pressed.connect(_show_tab.bind("heroes"))
	tabs.add_child(tab_heroes)

	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 40)
	box.add_child(body)

	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.add_child(grid)

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(700, 460)
	right.add_theme_constant_override("separation", 14)
	body.add_child(right)

	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(180, 180)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.add_child(detail_icon)

	detail_name = _label(40)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(detail_name)

	detail_stats = _label(24)
	detail_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_stats.custom_minimum_size = Vector2(680, 0)
	detail_stats.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	right.add_child(detail_stats)

	detail_text = _label(26)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.custom_minimum_size = Vector2(680, 120)
	right.add_child(detail_text)

	var close_button = _button("Close", 30, 64)
	close_button.pressed.connect(_on_close)
	box.add_child(close_button)

	visible = false


func open():
	visible = true
	_show_tab(current_tab)


func _on_close():
	visible = false


func _show_tab(kind):
	current_tab = kind
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()

	var entries = []
	if kind == "enemies":
		entries = _enemy_entries()
	else:
		entries = _hero_entries()

	for e in entries:
		grid.add_child(_entry_button(e))

	if kind == "enemies":
		tab_enemies.modulate = Color.WHITE
		tab_heroes.modulate = Color(0.6, 0.6, 0.6)
	else:
		tab_enemies.modulate = Color(0.6, 0.6, 0.6)
		tab_heroes.modulate = Color.WHITE

	if entries.size() > 0:
		_select(entries[0])


func _atlas(spr):
	if spr == null or spr.texture == null:
		return null
	if not spr.region_enabled:
		return spr.texture
	var a = AtlasTexture.new()
	a.atlas = spr.texture
	a.region = spr.region_rect
	return a


func _enemy_entries():
	var list = []
	var inst = load("res://scenes/enemy.tscn").instantiate()
	var icon = _atlas(inst.get_node_or_null("Sprite2D"))
	inst.free()
	for key in ENEMY_INFO:
		var info = ENEMY_INFO[key]
		var t = ENEMY_SCRIPT.TYPES[key]
		var stats = "HP: %d     Speed: %d     Castle damage: %d\nWeak to: %s" % [t["hp"], int(t["speed"]), t["damage"], info["weak"]]
		list.append({
			"name": info["name"],
			"icon": icon,
			"tint": t["color"],
			"stats": stats,
			"text": info["text"],
		})
	return list


func _hero_entries():
	var list = []
	var main = get_tree().current_scene
	for key in HERO_INFO:
		var info = HERO_INFO[key]
		var icon = null
		for c in main.get_children():
			if "defense_name" in c and c.defense_name == key:
				icon = _atlas(c.get_node_or_null("Sprite2D"))
		var lvl = GameState.levels[key]
		var line = "Level: %d / %d" % [lvl, GameState.MAX_LEVEL]
		if lvl < GameState.MAX_LEVEL:
			line += "     Next upgrade: %d coins" % GameState.price_of(key)
		else:
			line += "     MAX LEVEL"
		var stats = "%s\nAttack: %s\nStrong against: %s (double damage)" % [line, info["attack"], info["strong"]]
		list.append({
			"name": info["name"],
			"icon": icon,
			"tint": Color.WHITE,
			"stats": stats,
			"text": info["text"],
		})
	return list


func _entry_button(entry):
	var b = Button.new()
	b.custom_minimum_size = Vector2(120, 120)
	b.icon = entry["icon"]
	b.expand_icon = true
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.tooltip_text = entry["name"]
	if entry["icon"] == null:
		b.text = entry["name"]
	var tint = entry["tint"]
	for n in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(n, tint)
	b.pressed.connect(_select.bind(entry))
	return b


func _select(entry):
	detail_icon.texture = entry["icon"]
	detail_icon.modulate = entry["tint"]
	detail_name.text = entry["name"]
	detail_stats.text = entry["stats"]
	detail_text.text = entry["text"]


func _on_visibility_changed():
	get_tree().paused = visible
