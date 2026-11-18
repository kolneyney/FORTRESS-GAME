extends Control

# a small gold coin that spins (drawn in code, no image needed)
var coin_size = 32.0
var spin = 3.0
var t = 0.0


func _init():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready():
	custom_minimum_size = Vector2(coin_size, coin_size)
	t = randf() * TAU


func _process(delta):
	t += delta * spin
	queue_redraw()


func _draw():
	var center = Vector2(coin_size, coin_size) / 2.0
	var r = coin_size / 2.0 - 2.0
	var w = maxf(absf(cos(t)), 0.12)
	draw_set_transform(center, 0.0, Vector2(w, 1.0))
	draw_circle(Vector2.ZERO, r, Color(0.55, 0.38, 0.05))
	draw_circle(Vector2.ZERO, r - 3.0, Color(1.0, 0.82, 0.2))
	draw_circle(Vector2.ZERO, r - 6.0, Color(0.95, 0.7, 0.1))
	draw_rect(Rect2(-r * 0.12, -r * 0.45, r * 0.24, r * 0.9), Color(0.55, 0.38, 0.05))
	draw_rect(Rect2(-r * 0.55, -r * 0.65, r * 0.2, r * 0.45), Color(1.0, 1.0, 0.8, 0.8))
