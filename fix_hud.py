import sys

with open('GameScene.tscn', 'r') as f:
    content = f.read()

old_inf_bg = """[node name="InfectionBarBG" type="TextureRect" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 55.0
offset_right = 320.0
offset_bottom = 75.0
texture = ExtResource("hud_bar_bg")"""

new_inf_bg = """[node name="InfectionBarBG" type="TextureRect" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 55.0
offset_right = 320.0
offset_bottom = 75.0
texture = ExtResource("hud_bar_bg")
expand_mode = 1"""

content = content.replace(old_inf_bg, new_inf_bg)

old_det_bar = """[node name="DetectionBar" type="TextureRect" parent="CanvasLayer/HUD/TopPanel"]"""

new_det_bg_and_bar = """[node name="DetectionBarBG" type="TextureRect" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 93.0
offset_right = 320.0
offset_bottom = 113.0
texture = ExtResource("hud_bar_bg")
expand_mode = 1

[node name="DetectionBar" type="TextureRect" parent="CanvasLayer/HUD/TopPanel"]"""

content = content.replace(old_det_bar, new_det_bg_and_bar)

with open('GameScene.tscn', 'w') as f:
    f.write(content)

print("Fixed HUD elements in GameScene.tscn")
