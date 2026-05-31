extends Node2D

var country_dots: Dictionary = {}
var dot_color: Color = Color(0.85, 0.05, 0.05, 0.9) # Bright red

func add_dot(pos: Vector2, country: String):
	if not country_dots.has(country):
		country_dots[country] = []
	
	country_dots[country].append(pos)
	
	# Cap at 200 dots per country to avoid lag
	if country_dots[country].size() > 200:
		country_dots[country].pop_front()
		
func _draw():
	for country in country_dots:
		for pos in country_dots[country]:
			draw_circle(pos, 3.0, dot_color)
	
func clear_dots_in_country(country_name: String):
	if country_dots.has(country_name):
		country_dots[country_name].clear()
	queue_redraw()

func trigger_redraw():
	queue_redraw()
