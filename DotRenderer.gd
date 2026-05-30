extends Node2D

var dots: Array[Vector2] = []
var dot_color: Color = Color(0.6, 0.0, 0.0, 0.8) # Dark red with slight transparency

func add_dot(pos: Vector2):
    dots.append(pos)
    queue_redraw()

func _draw():
    # Instead of drawing dots, we draw the actual virus name
    var font = ThemeDB.fallback_font
    var v_name = Global.virus_name
    if v_name == "":
        v_name = "VIRUS"
        
    for pos in dots:
        draw_string(font, pos, v_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, dot_color)
