extends Node2D
@export var multi_threading: bool
@export var grid_scalar: int = 8
@export var element_purity: int = 200
@export var drift_chance: float = 0.5
@export var aspect_ratio = Vector2i(16, 9)


@export var earth: Dictionary = {
	density = 4,
	color = Color(0.4, 0.25, 0.2)
	}
@export var water: Dictionary = {
	density = 3,
	color = Color(0, 0, 1)
	}
@export var air: Dictionary = {
	density = 2,
	color = Color(0.51, 0.86, 1)
	}
@export var fire: Dictionary = {
	density = 1,
	color = Color(1, 1, 0)
	}
	
var viewport_width: float
var viewport_height: float

var grid_width: int
var grid_height: int
var cell_width: float
var cell_height: float

var grid: Array[Array]

var rng = RandomNumberGenerator.new()

var threads: Array[Thread]

func _ready() -> void:
	viewport_width = get_viewport_rect().size.x
	viewport_height = get_viewport_rect().size.y
	
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
	
	natural_movement()
	
	#random_movement()
	if rng.randf() < 0.5:
		grid[grid_width*rng.randf()][2] = {
			earth = 1.0,
			water = 0.0,
			air = 0.0,
			fire = 0.0
		}
	if rng.randf() < 1:
		grid[grid_width*rng.randf()][2] = {
			earth = 0.0,
			water = 1.0,
			air = 0.0,
			fire = 0.0
		}
	if rng.randf() < 1:
		grid[grid_width*rng.randf()][grid_height-2] = {
			earth = 0.0,
			water = 0.0,
			air = 0.0,
			fire = 1.0
		}
	
	queue_redraw()
	

func weight(composition: Dictionary) -> float:
	return composition.earth * earth.density + composition.water * water.density + composition.air * air.density + composition.fire * fire.density

func natural_movement():
	for x in grid_width:
		#vertical_movement(x)
		#alternating_sort(x, 0)
		alternating_sort(x, 1)
			
func alternating_sort(x, parity):
	for half_y in grid_height/2 - parity:
		var y = 2 * half_y + parity
		if weight(grid[x][y])>weight(grid[x][y+1]):
			var temp_xy = grid[x][y]
			grid[x][y] = grid[x][y+1]
			grid[x][y+1] = temp_xy
	


func vertical_movement(x):
	var moved: int = 0
	for y in grid_height - 1:
			
			var compositions: Array[Dictionary]
			var max_speed: int = min(round(weight(grid[x][y])/weight(grid[x][y+1])), grid_height - y - 1)
			for n in max_speed:
				compositions.append(grid[x][y+n+1])
			
			if moved > 0:
				moved -= 1
			else:
				for n in max_speed:
					if weight(grid[x][y+n])/weight(grid[x][y+n+1]) > 1:
						grid[x][y+n+1] = grid[x][y+n]
						grid[x][y+n] = compositions[n]
						moved += 1
	for y in grid_height - 1:
			
			var compositions: Array[Dictionary]
			var max_speed: int = 0#min(round(weight(grid[x][grid_height-1-y])/weight(grid[x][grid_height-1-(y+1)])), y)
			for n in max_speed:
				compositions.append(grid[x][y-(n+1)])
			
			if moved > 0:
				moved -= 1
			else:
				for n in max_speed:
					if weight(grid[x][grid_height-y-n])/weight(grid[x][grid_height-y-(n+1)]) > 1:
						grid[x][grid_height-y-(n+1)] = grid[x][grid_height-y-n]
						grid[x][grid_height-y-n] = compositions[n]
						moved += 1
			

func random_movement():
	var composition: Dictionary
	var composition_left: Dictionary
	
	
	for y in grid_height:
		for x in grid_width:
			composition = grid[x][y]
			composition_left = grid[x-1][y]
			
			if rng.randf()*weight(composition)*weight(composition_left) < 0.5:
				grid[x][y] = composition_left
				grid[x-1][y] = composition
