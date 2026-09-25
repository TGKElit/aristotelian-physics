extends Node2D

var radius: int = 20
var circumference: float = radius * TAU
var pv_image: Image = Image.create_empty(radius + 1, int(circumference + 1), false, Image.FORMAT_RGBA8)
var pv_texture: ImageTexture

var resolution = 4
var diameter = (2 * radius + 1) * resolution - (resolution + 1) % 2
var polar_image: Image = Image.create_empty(diameter, diameter, false, Image.FORMAT_RGBA8)
var polar_texture: ImageTexture
var origo = [floor((radius+0.5) * resolution - (resolution + 1) % 2),floor((radius+0.5) * resolution) - (resolution + 1) % 2]
var position_r: float = 0
var position_theta: float = 0

var lapsed_time = 0


func pv_generator() -> void:
	for r in radius + 1:
		for c in int(circumference + 1):
			var theta
			if r == 0:
				theta = 0
			else:
				theta = float(c) / float(r)
			
			pv_image.set_pixel(r, c, Color(r/float(radius),c/float(circumference),1,1))
			if (r > ((c+1)/TAU)):
				pv_image.set_pixel(r, c, Color(c/float(circumference),int(roundf((r*pow(2, 2))/floor(r*TAU) * theta)) % 2,1-r/float(radius),(2*r+r)%4+0.5))
		
	pv_image.set_pixel(0,0, Color(1,0,0,1))
	pv_image.set_pixel(int(position_r), int(roundf(position_r * position_theta)) % max(1, int(position_r * TAU)), Color.WHITE)
	pv_texture = ImageTexture.create_from_image(pv_image)
	
func pv_to_polar() -> void:
	for x in diameter:
		x = x - origo[0]
		for y in diameter:
			y = origo[1] - y
			var r = roundf(sqrt(pow(x,2)+pow(y,2)) / resolution)
			polar_image.set_pixel(origo[0] + x, origo[1] - y, Color.WHITE)
			if r <= (radius):
				var theta = (atan2((y),(x)))
				
				if theta < 0:
					theta = theta + TAU
					
				var discretizer = 1
				if r >= 1:
					discretizer = (floor(TAU * r)/(TAU * r))
					
					# c = int_theta * r if r=1 int_theta: 0,1,2,3,4,5,6, disc = 6/6.28
					# if theta = 0.6, cont_c = 0.6 * 6/6.28 
				var c = roundf(r * (theta) * discretizer)
				if c >= floor(TAU * r):
					c -= floor(TAU * r)
					
				if r == 0:
					c = 0
				
				var source_pixel = pv_image.get_pixel(r, c)
				
				
				polar_image.set_pixel(origo[0] + x, origo[1] - y, source_pixel)
	polar_texture = ImageTexture.create_from_image(polar_image)
	

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		position_r = clampf(position_r + sign(Input.get_axis("ui_down", "ui_up")), 0 , radius)
		#if event.keycode == KEY_UP and position_r != radius:
			#position_r += 1
		#if event.keycode == KEY_DOWN and position_r != 0:
			#position_r -= 1
		if event.keycode == KEY_LEFT and position_r != 0:
			position_theta += TAU/floor(position_r * TAU)
			
			if position_r * position_theta >= floor(position_r * TAU):
				position_theta -= TAU
		if event.keycode == KEY_RIGHT and position_r != 0:
			position_theta -= TAU/floor(position_r * TAU)
			if position_theta < 0:
				position_theta += TAU
				
		
func _ready() -> void:
	
	pv_generator()
	pv_to_polar()
	

func _process(delta: float) -> void:
	lapsed_time += delta
	pv_generator()
	pv_to_polar()
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(pv_texture, Rect2(0, 0, int((1440+240)/6.0), 1440), false)
	draw_texture_rect(polar_texture, Rect2(0+int((1440+240)/6.0)+240,0, int(1440+(1440+240)/6.0)-240, 1440), false)
	
