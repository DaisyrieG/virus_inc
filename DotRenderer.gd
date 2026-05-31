extends Node2D

var country_dots: Dictionary = {}
var dot_color: Color = Color(0.85, 0.05, 0.05, 0.9) # Bright red

# Pre-load a system font that renders ASCII reliably
var _font: Font = null

func _ready():
	z_index = 10
	# Use a SystemFont — this guarantees correct rendering on Windows
	var sf = SystemFont.new()
	sf.font_names = ["Courier New", "Consolas", "Lucida Console", "monospace"]
	_font = sf

func add_dot(pos: Vector2, country: String):
	if not country_dots.has(country):
		country_dots[country] = []
	
	country_dots[country].append(pos)
	
	# Cap at 200 dots per country to avoid lag
	if country_dots[country].size() > 200:
		country_dots[country].pop_front()
	queue_redraw()
		
func _draw():
	if not _font:
		return
	
	# Draw the virus name as text stamps across each infected country
	var v_name = Global.virus_name.to_upper()
	if v_name.strip_edges() == "":
		v_name = "VIRUS"
	
	for country in country_dots:
		for pos in country_dots[country]:
			# Draw a subtle dark outline for readability
			draw_string(_font, pos + Vector2(1, 1), v_name,
				HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
				Color(0.1, 0.0, 0.0, 0.6))
			# Draw the actual name in bright red
			draw_string(_font, pos, v_name,
				HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
				dot_color)
	
func clear_dots_in_country(country_name: String):
	if country_dots.has(country_name):
		country_dots[country_name].clear()
	queue_redraw()

func trigger_redraw():
	queue_redraw()
