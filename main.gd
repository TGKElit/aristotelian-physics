extends Node2D
var viewport_width
var viewport_height

var grid_width
var cell_width
var cell_height
var grid_height
var grid_scalar = 64

var grid = []

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	viewport_width = get_viewport_rect().size.x
	viewport_height = get_viewport_rect().size.y

	grid_width = 16 * grid_scalar
	grid_height = 9 * grid_scalar
	cell_width = viewport_width / grid_width
	cell_height = viewport_height / grid_height

	for x in grid_width:
		grid.append([])
		for y in grid_height:
			var element_purity = 200
			var earth = pow(rng.randf(), element_purity)
			var water = pow(rng.randf(), element_purity)
			var air = pow(rng.randf(), element_purity)
			var fire = pow(rng.randf(), element_purity)
			
			var element_sum = earth+water+air+fire 
			
			grid[x].append({
				earth = earth / element_sum,
				water = water / element_sum,
				air = air / element_sum,
				fire = fire / element_sum
			})
	
func _draw():
	for x in grid_width:
		for y in grid_height:
			
			var color = Color(
				#red
				(0.4*grid[x][y].earth + 0*grid[x][y].water + 0.6*grid[x][y].air + grid[x][y].fire), # red
				#green
				(0.25*grid[x][y].earth +  0*grid[x][y].water + 0.8*grid[x][y].air + grid[x][y].fire*(1-rng.randf_range(0.0,0.1))), # green
				#blue
				(0.2*grid[x][y].earth + grid[x][y].water + grid[x][y].air + 0*grid[x][y].fire) # blue
			)
			draw_rect(Rect2(x * cell_width, y * cell_height, cell_width, cell_height), color)
	

func _process(_delta: float) -> void:
#	var row_weight_sums_string = ""
	for y in grid_height - 1:
		#var row_weight_sum = 0
		for x in grid_width:
			
			var earth = grid[x][y].earth
			var water = grid[x][y].water
			var air = grid[x][y].air
			var fire = grid[x][y].fire
			var earth_down = grid[x][y+1].earth
			var water_down = grid[x][y+1].water
			var air_down = grid[x][y+1].air
			var fire_down = grid[x][y+1].fire
			
			var earth_reverse = grid[x][(grid_height - 1) - y].earth
			var water_reverse = grid[x][(grid_height - 1) - y].water
			var air_reverse = grid[x][(grid_height - 1) - y].air
			var fire_reverse = grid[x][(grid_height - 1) - y].fire
			var earth_reverse_up = grid[x][(grid_height - 1) - y - 1].earth
			var water_reverse_up = grid[x][(grid_height - 1) - y - 1].water
			var air_reverse_up = grid[x][(grid_height - 1) - y - 1].air
			var fire_reverse_up = grid[x][(grid_height - 1) - y - 1].fire
			
			var earth_left = grid[x-1][y].earth
			var water_left = grid[x-1][y].water
			var air_left = grid[x-1][y].air
			var fire_left = grid[x-1][y].fire
			
			if weight(earth, water, air, fire) > weight(earth_down, water_down, air_down, fire_down):
				grid[x][y] = {
					earth = earth_down,
					water = water_down,
					air = air_down,
					fire = fire_down
				}
				grid[x][y+1] = {
					earth = earth,
					water = water,
					air = air,
					fire = fire
				}
			
			if weight(earth_reverse, water_reverse, air_reverse, fire_reverse) < weight(earth_reverse_up, water_reverse_up, air_reverse_up, fire_reverse_up):
				grid[x][(grid_height-1)-y] = {
					earth = earth_reverse_up,
					water = water_reverse_up,
					air = air_reverse_up,
					fire = fire_reverse_up
				}
				grid[x][(grid_height-1)-y-1] = {
					earth = earth_reverse,
					water = water_reverse,
					air = air_reverse,
					fire = fire_reverse
				}
				
			earth = grid[x][y].earth
			water = grid[x][y].water
			air = grid[x][y].air
			fire = grid[x][y].fire
				
			if rng.randf()*weight(earth, water, air, fire)*weight(earth_left, water_left, air_left, fire_left) / 16 < 0.05:
				grid[x][y] = {
					earth = earth_left,
					water = water_left,
					air = air_left,
					fire = fire_left
				}
				grid[x-1][y] = {
					earth = earth,
					water = water,
					air = air,
					fire = fire
				}
					
			#row_weight_sum += min(weight(earth, water, air, fire), weight(earth_down, water_down, air_down, fire_down))
			queue_redraw()
		#row_weight_sums_string += str(row_weight_sum / grid_width) + "\n"
	# $HUD.update_weight(row_weight_sums_string)
	

func weight(earth, water, air, fire) -> float:
	return 256 * earth + 2 * water + 1.5 * air + 1 * fire
