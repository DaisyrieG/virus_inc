extends Node2D

var country_dots: Dictionary = {}
var dot_color: Color = Color(0.6, 0.0, 0.0, 0.8) # Dark red with slight transparency

func add_dot(pos: Vector2, country: String):
    if not country_dots.has(country):
        country_dots[country] = []
    
    country_dots[country].append(pos)
    
    # Cap at 300 dots per country
    if country_dots[country].size() > 300:
        country_dots[country].pop_front()
        
    queue_redraw()

func _draw():
    # Instead of drawing dots, we draw the actual virus name
    var font = ThemeDB.fallback_font
    var v_name = Global.virus_name
    if v_name == "":
        v_name = "VIRUS"
        
    for country in country_dots:
        for pos in country_dots[country]:
            draw_string(font, pos, v_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, dot_color)

func clear_dots_in_country(country_name: String):
    if country_dots.has(country_name):
        country_dots[country_name].clear()
    queue_redraw()
