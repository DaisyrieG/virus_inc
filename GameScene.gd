extends Node2D

@onready var map_sprite = $MapSprite
@onready var dot_renderer = $MapSprite/DotRenderer
@onready var hover_label = $CanvasLayer/HoverLabel
@onready var camera = $Camera2D

var color_id_image: Image
var country_colors: Dictionary = {}
var country_bboxes: Dictionary = {}
var infected_countries: Array[String] = [] # Starts empty, user clicks to infect

var hovered_country: String = ""

# Hardcoded graph of connections and their weights (difficulty to spread)
var world_graph: Dictionary = {
	"CHINA": {"RUSSIA": 2.0, "INDIA": 1.5, "KAZAKHSTAN": 1.8, "MONGOLIA": 1.0, "PHILIPPINES": 2.5},
	"RUSSIA": {"CHINA": 2.0, "KAZAKHSTAN": 1.2, "MONGOLIA": 1.5},
	"INDIA": {"CHINA": 1.5, "SAUDIARABIA": 3.0},
	"KAZAKHSTAN": {"RUSSIA": 1.2, "CHINA": 1.8},
	"MONGOLIA": {"RUSSIA": 1.5, "CHINA": 1.0},
	"PHILIPPINES": {"CHINA": 2.5},
	"SAUDIARABIA": {"INDIA": 3.0}
}

var is_dragging: bool = false
var last_mouse_pos: Vector2

var hover_sprite: Sprite2D
var country_hover_images: Dictionary = {
	"CHINA": "res://Assets/ASIAMAP_REALISTIC_CHINA.png",
	"INDIA": "res://Assets/ASIAMAP_REALISTIC_INDIA.png",
	"RUSSIA": "res://Assets/ASIAMAP_REALISTIC_RUSSIA.png",
	"MONGOLIA": "res://Assets/ASIAMAP_REALISTIC_MONGOLIA.png",
	"KAZAKHSTAN": "res://Assets/ASIAMAP_REALISTIC_MAP_KAZAKHSTAN.png",
	"PHILIPPINES": "res://Assets/ASIAMAP_REALISTIC_MAP_PHILIPPINES.png",
	"SAUDIARABIA": "res://Assets/ASIAMAP_REALISTIC_MAP_SAUDIARABIA.png"
}
var country_hover_textures: Dictionary = {}

func _ready():
	# Load the Color ID map directly as an Image to bypass texture compression artifacts
	color_id_image = Image.load_from_file("res://Assets/ColorIDMap.png")
	
	# Load country data JSON
	var file = FileAccess.open("res://Assets/country_data.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		for country_name in data.keys():
			var rgb = data[country_name]["color"]
			# The python script outputs [R, G, B] in 0-255 format
			var c = Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]))
			country_colors[c.to_html(false)] = country_name
			country_bboxes[country_name] = data[country_name]["bbox"]
			
			# Start with some initial dots for visual
			if country_name in infected_countries:
				for i in range(50):
					spawn_dot_in_country(country_name)
					
	# Preload hover textures
	for country in country_hover_images:
		var tex = load(country_hover_images[country])
		if tex:
			country_hover_textures[country] = tex
			
	# Setup hover sprite
	hover_sprite = Sprite2D.new()
	hover_sprite.centered = false
	map_sprite.add_child(hover_sprite)
	map_sprite.move_child(hover_sprite, 0) # Draw behind DotRenderer
	hover_sprite.hide()
	
	# Start infection timer
	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	timer.timeout.connect(_on_infection_tick)
	add_child(timer)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_mouse_pos = event.position
				
				# Plague Inc style: click a country to start the infection!
				if hovered_country != "" and infected_countries.size() == 0:
					infected_countries.append(hovered_country)
					print(get_node("/root/Global").virus_name + " has started infecting " + hovered_country + "!")
			else:
				is_dragging = false
		
		# Camera Zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.1
			if camera.zoom.x > 4.0:
				camera.zoom = Vector2(4.0, 4.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom /= 1.1
			if camera.zoom.x < 1.0:
				camera.zoom = Vector2(1.0, 1.0)

	elif event is InputEventMouseMotion:
		if is_dragging:
			# Pan the camera
			var delta = event.position - last_mouse_pos
			camera.position -= delta / camera.zoom
			last_mouse_pos = event.position
		
		# Check hover
		_check_hover(event.position)

func _check_hover(screen_pos: Vector2):
	if not color_id_image: return
	
	# Convert screen position to global position, then to local map sprite coordinates
	var global_mouse_pos = get_canvas_transform().affine_inverse() * screen_pos
	var local_pos = map_sprite.to_local(global_mouse_pos)
	
	# The MapSprite is centered by default, so its top-left is at -size/2
	# If MapSprite is NOT centered (centered=false), local_pos is exactly the pixel coordinate
	if local_pos.x >= 0 and local_pos.x < color_id_image.get_width() and local_pos.y >= 0 and local_pos.y < color_id_image.get_height():
		var local_pos_i = Vector2i(local_pos)
		var pixel_color = color_id_image.get_pixelv(local_pos_i)
		var html_color = pixel_color.to_html(false)
		if country_colors.has(html_color):
			var country = country_colors[html_color]
			hovered_country = country
			hover_label.text = country
			if country_hover_textures.has(country):
				hover_sprite.texture = country_hover_textures[country]
				hover_sprite.show()
			else:
				hover_sprite.hide()
			return
		else:
			# Debug logic: show what color the mouse is actually seeing if it's not empty ocean
			if html_color != "000000" and html_color != "ffffff" and html_color != "00000000":
				hover_label.text = "Color: " + html_color
				hover_sprite.hide()
				hovered_country = ""
				return
			
	hover_label.text = ""
	hover_sprite.hide()
	hovered_country = ""

func _on_infection_tick():
	if infected_countries.size() == 0:
		return
		
	# Visual dots
	var random_country = infected_countries[randi() % infected_countries.size()]
	spawn_dot_in_country(random_country)
	
	# Algorithm 1: MULTI-SOURCE DIJKSTRA'S SPREAD
	# 5% chance every tick to spread the virus.
	if randf() < 0.05:
		# We pass ALL currently infected countries as the "source".
		# Dijkstra will automatically expand outward from the entire infected border,
		# evaluating which neighbouring, uninfected country is absolutely easiest to reach.
		var dijkstra_result = Dijkstra.calculate_shortest_paths(world_graph, infected_countries)
		var distances = dijkstra_result["distances"]
		var previous = dijkstra_result["previous"]
		
		# Find the closest uninfected country
		var closest_uninfected = ""
		var min_dist = INF
		
		for country in distances:
			if country not in infected_countries and distances[country] < min_dist and distances[country] > 0:
				min_dist = distances[country]
				closest_uninfected = country
				
		if closest_uninfected != "":
			infected_countries.append(closest_uninfected)
			var spread_from = previous[closest_uninfected]
			print(get_node("/root/Global").virus_name + " has spread from " + spread_from + " to " + closest_uninfected + " using Multi-Source Dijkstra!")

func spawn_dot_in_country(country_name: String):
	var bbox = country_bboxes[country_name]
	var max_attempts = 100
	var target_color = null
	
	# Find the target color for this country to match against the Color ID map
	for html in country_colors:
		if country_colors[html] == country_name:
			target_color = html
			break
			
	if not target_color: return
	
	for i in range(max_attempts):
		var rx = randi_range(bbox[0], bbox[2])
		var ry = randi_range(bbox[1], bbox[3])
		var pcolor = color_id_image.get_pixel(rx, ry).to_html(false)
		
		if pcolor == target_color:
			dot_renderer.add_dot(Vector2(rx, ry))
			break
