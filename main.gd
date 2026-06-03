extends Node2D

@export var shader_on: bool = false
@export var grid_scalar: int = 1
@export var element_purity: int = 200
@export var drift_chance: float = 0.5
@export var aspect_ratio = Vector2i(16, 9)

@export var earth: Dictionary = {
	density = 30,
	color = Color(0.38, 0.23, 0.10)
	}
@export var water: Dictionary = {
	density = 10,
	color = Color(0, 0, 1)
	}
@export var air: Dictionary = {
	density = 2,
	color = Color(0.51, 0.86, 1)
	}
@export var fire: Dictionary = {
	density = 1,
	color = Color(1, 0.9, 0.18)
	}
	
var viewport_width: float
var viewport_height: float

var grid_width: int
var grid_height: int
var cell_width: float
var cell_height: float

var grid: Array[Array]
var grid_1D: PackedFloat32Array
var index_parity: float = 0
var invocation_size = 16
var gravity_params: PackedFloat32Array = [index_parity, earth.density, water.density, air.density, fire.density, 0.0]

var rng = RandomNumberGenerator.new()
var rd: RenderingDevice
var gravity_shader
var gravity_pipeline
var gravity_grid_buffer
var gravity_params_buffer

var grid_u
var params_u

var uniform_set

func _ready() -> void:
	viewport_width = get_viewport_rect().size.x
	viewport_height = get_viewport_rect().size.y
	
	grid_width = aspect_ratio[0] * grid_scalar * invocation_size
	grid_height = aspect_ratio[1] * grid_scalar * invocation_size
	cell_width = viewport_width / grid_width
	cell_height = viewport_height / grid_height
	
	if !shader_on:
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
			
	if shader_on:
		for x in grid_width:
			for y in grid_height:
				var earth_con: float = pow(rng.randf(), element_purity)
				var water_con: float = pow(rng.randf(), element_purity)
				var air_con: float = pow(rng.randf(), element_purity)
				var fire_con: float = pow(rng.randf(), element_purity)
				var element_sum: float = earth_con + water_con + air_con + fire_con 
				
				grid_1D.append(earth_con / element_sum)
				grid_1D.append(water_con / element_sum)
				grid_1D.append(air_con / element_sum)
				grid_1D.append(fire_con / element_sum)
				grid_1D.append(0.0)
	
		
		# Compute shader setup
		rd = RenderingServer.create_local_rendering_device()
		
		var gravity_shader_file = load("res://gravity.glsl")
		var gravity_shader_spirv = gravity_shader_file.get_spirv()
		gravity_shader = rd.shader_create_from_spirv(gravity_shader_spirv)
		gravity_pipeline = rd.compute_pipeline_create(gravity_shader)
		
		var gravity_grid_pba = grid_1D.to_byte_array()
		gravity_grid_buffer = rd.storage_buffer_create(gravity_grid_pba.size(), gravity_grid_pba)
		
		grid_u = RDUniform.new()
		grid_u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		grid_u.binding = 0
		grid_u.add_id(gravity_grid_buffer)
		
		var gravity_params_pba: PackedByteArray = gravity_params.to_byte_array() 
		gravity_params_buffer = rd.storage_buffer_create(gravity_params_pba.size(), gravity_params_pba)
		
		
		params_u = RDUniform.new()
		params_u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		params_u.binding = 1
		params_u.add_id(gravity_params_buffer)
		
		uniform_set = rd.uniform_set_create([grid_u, params_u], gravity_shader, 0)
	
		
	
func _draw():
	if !shader_on:
		for x in grid_width:
			for y in grid_height:
				var color: Color = Color(earth.color, grid[x][y].earth).blend(Color(water.color, grid[x][y].water)).blend(Color(air.color, grid[x][y].air)).blend(Color(fire.color, grid[x][y].fire))
				draw_rect(Rect2(x * cell_width, y * cell_height, cell_width, cell_height), color)
	if shader_on:
		for x in grid_width:
			for y in grid_height:
				var color: Color = Color(earth.color, grid_1D[x * grid_height * 5 + y * 5 + 0]).blend(Color(water.color, grid_1D[x * grid_height * 5 + y * 5 + 1])).blend(Color(air.color, grid_1D[x * grid_height * 5 + y * 5 + 2])).blend(Color(fire.color, grid_1D[x * grid_height * 5 + y * 5 + 3]))
				draw_rect(Rect2(x * cell_width, y * cell_height, cell_width, cell_height), color)
				

func _process(delta: float) -> void:
	
	natural_movement(delta)

	#random_movement()
	
	if rng.randf()<0.1:
		spawn_cell(rng.randf()*grid_width,0,1,0,0,0)
		spawn_cell(rng.randf()*grid_width,grid_height-1,0,0,0,1)
	
	queue_redraw()
	

func weight(composition: Dictionary) -> float:
	return composition.earth * earth.density + composition.water * water.density + composition.air * air.density + composition.fire * fire.density

func natural_movement(delta):
	
	if !shader_on:
		for x in grid_width:
			alternating_sort(x, index_parity, delta)
		index_parity = 1 - index_parity
		
	if shader_on:
		gravity_params[5] = delta
		var pba = gravity_params.to_byte_array()
		rd.buffer_update(gravity_params_buffer, 0, pba.size(), pba)

		var compute_list = rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, gravity_pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		rd.compute_list_dispatch(compute_list, grid_width/8, grid_height/16, 1)
		rd.compute_list_end()
		rd.submit()
		rd.sync()
		grid_1D = rd.buffer_get_data(gravity_grid_buffer).to_float32_array()

		gravity_params[0] = 1 - gravity_params[0]
			
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
	if !shader_on:
		grid[x][y] = {
			earth = earth,
			water = water,
			air = air,
			fire = fire,
			wait_time = 0.0
		}
	if shader_on:
		grid_1D[x * grid_height * 5 + y * 5 + 0] = earth
		grid_1D[x * grid_height * 5 + y * 5 + 1] = water
		grid_1D[x * grid_height * 5 + y * 5 + 2] = air
		grid_1D[x * grid_height * 5 + y * 5 + 3] = fire
		grid_1D[x * grid_height * 5 + y * 5 + 4] = 0.0
		var pba = grid_1D.to_byte_array()
		rd.buffer_update(gravity_grid_buffer, 0, pba.size(), pba)
