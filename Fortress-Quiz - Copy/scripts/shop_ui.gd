extends Control

@onready var box = $Center/Panel/VBoxContainer
@onready var coins_label = box.get_node("CoinsLabel")

var items = {
	"firewall": "FirewallButton",
	"antivirus": "AntivirusButton",
	"mfa": "MFAButton",
	"backup": "BackupButton",
}


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visibility_changed.connect(_on_visibility_changed)
	for d in items:
		box.get_node(items[d]).pressed.connect(_on_buy.bind(d))
	box.get_node("CloseButton").pressed.connect(close)
	visible = false


func open():
	visible = true
	_refresh()


func close():
	visible = false


func _on_buy(defense):
	GameState.buy(defense)
	_refresh()


func _refresh():
	coins_label.text = "Coins: %d" % GameState.coins
	for d in items:
		var b = box.get_node(items[d])
		var lvl = GameState.levels[d]
		if lvl >= GameState.MAX_LEVEL:
			b.text = "%s Lv %d (MAX)" % [d.capitalize(), lvl]
			b.disabled = true
		else:
			b.text = "%s Lv %d - Buy for %d" % [d.capitalize(), lvl, GameState.price_of(d)]
			b.disabled = GameState.coins < GameState.price_of(d)


func _on_visibility_changed():
	get_tree().paused = visible
