extends TileMapLayer

func _ready():
	generate_fortress()

func generate_fortress():
	var map_size = 22
	
	# Corrected 16x16 Atlas coordinates for colored_packed.png
	var water_tile = Vector2i(11, 5)       # Solid blue water
	var wall_tile = Vector2i(12, 1)        # Grey stone block
	var ground_tile = Vector2i(0, 1)       # Dark ground
	var path_tile = Vector2i(2, 0)         # Brown dirt
	var firewall_shield = Vector2i(41, 4)  # Red shield icon

	for x in range(map_size):
		for y in range(map_size):
			if x < 2 or x >= map_size - 2 or y < 2 or y >= map_size - 2:
				set_cell(Vector2i(x, y), 0, water_tile)
			elif x == 2 or x == map_size - 3 or y == 2 or y == map_size - 3:
				set_cell(Vector2i(x, y), 0, wall_tile)
			else:
				set_cell(Vector2i(x, y), 0, ground_tile)
				
	for path_y in range(12, 19):
		set_cell(Vector2i(10, path_y), 0, path_tile)
		set_cell(Vector2i(11, path_y), 0, path_tile)
		
	set_cell(Vector2i(10, 11), 0, firewall_shield)
	set_cell(Vector2i(11, 11), 0, firewall_shield)
