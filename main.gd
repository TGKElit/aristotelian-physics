extends Node2D
var viewport_width: float
var viewport_height: float
var aspect_ratio: Array

var grid_width: int
var grid_height: int
var cell_width: float
var cell_height: float
var grid_scalar: int = 1

var grid: Array = []

var element_purity: int = 200

var earth: Dictionary = {
	density = 256,
	color = Color(0.4, 0.25, 0.2)
	}
var water: Dictionary = {
	density = 3,
	color = Color(0, 0, 1)
	}
var air: Dictionary = {
	density = 2,
	color = Color(0.6, 0.8, 1)
	}
var fire: Dictionary = {
	density = 1,
	color = Color(1, 1, 0)
	}

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	viewport_width = get_viewport_rect().size.x
	viewport_height = get_viewport_rect().size.y
	aspect_ratio = [16, 9]
	
	grid_width = aspect_ratio[0] * grid_scalar
	grid_height = aspect_ratio[1] * grid_scalar
	cell_width = viewport_width / grid_width
	cell_height = viewport_height / grid_height

	for x in grid_width:
		grid.append([])
		for y in grid_height:
			var earth_con: float = pow(rng.randf(), element_purity)
			var water_con: float = pow(rng.randf(), element_purity)
			var air_con: float = pow(rng.randf(), element_purity)
			var fire_con: float = pow(rng.randf(), element_purity)
			var element_sum: float = earth_con + water_con + air_con + fire_con 
			
			
			
			grid[x].append({
				earth = earth_con / element_sum,
				water = water_con / element_sum,
				air = air_con / element_sum,
				fire = fire_con / element_sum
			})
	
func _draw():
	for x in grid_width:
		for y in grid_height:
			
			var color: Color = Color(earth.color, grid[x][y].earth).blend(Color(water.color, grid[x][y].water)).blend(Color(air.color, grid[x][y].air)).blend(Color(fire.color, grid[x][y].fire))
			
			draw_rect(Rect2(x * cell_width, y * cell_height, cell_width, cell_height), color)
	

func _process(_delta: float) -> void:
#	var row_weight_sums_string = ""
	for y in grid_height - 1:
		#var row_weight_sum = 0
		for x in grid_width:
			
			var composition: Dictionary = grid[x][y]
			var composition_down: Dictionary = grid[x][y+1]
			var composition_reverse: Dictionary = grid[x][grid_height-y-1]
			var composition_reverse_up: Dictionary = grid[x][grid_height-y-2]
			var composition_left: Dictionary = grid[x-1][y]
			
			
			if weight(composition) > weight(composition_down):
				grid[x][y] = composition_down
				grid[x][y+1] = composition
			
			if weight(composition_reverse) < weight(composition_reverse_up):
				grid[x][grid_height-y-1] = composition_reverse_up
				grid[x][grid_height-y-2] = composition_reverse
				
			composition = grid[x][y]
				
			if rng.randf()*weight(composition)*weight(composition_left) / 16 < 0.05:
				grid[x][y] = composition_left
				grid[x-1][y] = composition
					
			#row_weight_sum += min(weight(earth, water, air, fire), weight(earth_down, water_down, air_down, fire_down))
			queue_redraw()
		#row_weight_sums_string += str(row_weight_sum / grid_width) + "\n"
	# $HUD.update_weight(row_weight_sums_string)
	

func weight(composition: Dictionary) -> float:
	return composition.earth * earth.density + composition.water * water.density + composition.air * air.density + composition.fire * fire.density
