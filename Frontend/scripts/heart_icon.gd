extends Control

# a small pixel heart that beats (drawn in code, no image needed)
var icon_size = 40.0
var rate = 1.3        # beats per second
var t = 0.0

const ROWS = [
	"011000110",
	"111101111",
	"111111111",
	"111111111",
	"011111110",
	"001111100",
	"000111000",
	"000010000",
]


func _init():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready():
	custom_minimum_size = Vector2(icon_size, icon_size)


func _process(delta):
	t += delta * rate
	queue_redraw()


func _draw():
	var px = icon_size / 9.0
	var s = 1.0 + 0.16 * pow(maxf(sin(t * TAU), 0.0), 3.0)
	draw_set_transform(Vector2(icon_size, icon_size) / 2.0, 0.0, Vector2(s, s))
	var ox = -4.5 * px
	var oy = -4.0 * px
	for y in ROWS.size():
		for x in 9:
			if ROWS[y][x] == "1":
				var col = Color(0.95, 0.2, 0.3)
				if y == 1 and (x == 1 or x == 2):
					col = Color(1.0, 0.72, 0.78)
				draw_rect(Rect2(ox + x * px, oy + y * px, px + 0.5, px + 0.5), col)
