extends Node2D

@export var grid_scalar: int = 8
@export var element_purity: int = 200
@export var drift_chance: float = 0.5
@export var aspect_ratio = Vector2i(16, 9)

@export var earth: Dictionary = {
	density = 4,
	color = Color(0.4, 0.3, 0.2)
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
	color = Color(0.85, 0.83, 0.1)
	}
	
var viewport_width: float
var viewport_height: float

var grid_width: int
var grid_height: int
var cell_width: float
var cell_height: float

var grid: Array[Array]

var rng = RandomNumberGenerator.new()

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
				fire = fire_con / element_sum,
				wait_time = 0.0
			})
	
	
	
func _draw():
	for x in grid_width:
		for y in grid_height:
			var color: Color = Color(earth.color, grid[x][y].earth).blend(Color(water.color, grid[x][y].water)).blend(Color(air.color, grid[x][y].air)).blend(Color(fire.color, grid[x][y].fire))
			draw_rect(Rect2(x * cell_width, y * cell_height, cell_width, cell_height), color)
	

func _process(delta: float) -> void:
	
	natural_movement(delta)
	
	#random_movement()
	
	if rng.randf()<0.05:
		spawn_cell(rng.randf()*grid_width,0,1,0,0,0)
		spawn_cell(rng.randf()*grid_width,grid_height-1,0,0,0,1)
	
	queue_redraw()
	

func weight(composition: Dictionary) -> float:
	return composition.earth * earth.density + composition.water * water.density + composition.air * air.density + composition.fire * fire.density

func natural_movement(delta):
	for x in grid_width:
		alternating_sort(x, 0, delta)
		alternating_sort(x, 1, delta)
			
func alternating_sort(x, parity, delta):
	for half_y in grid_height/2 - parity * ((grid_height+1)%2):
		var y: int = 2 * half_y + parity
		var faller = grid[x][y]
		var riser = grid[x][y+1]
		var speed: float = weight(faller)/weight(riser)
		
		grid[x][y].wait_time += delta
		grid[x][y+1].wait_time += delta
		
		if speed > 1 / min(grid[x][y].wait_time, grid[x][y+1].wait_time):
			
			grid[x][y] = riser
			grid[x][y+1] = faller
			
			grid[x][y].wait_time = 0.0
			grid[x][y+1].wait_time = 0.0

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

func spawn_cell(x:int, y:int, earth:float, water:float, air:float, fire:float):
	grid[x][y] = {
		earth = earth,
		water = water,
		air = air,
		fire = fire,
		wait_time = 0.0
	}
