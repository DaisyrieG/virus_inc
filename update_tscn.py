import sys

with open('GameScene.tscn', 'r') as f:
    content = f.read()

ext_resources = '''[ext_resource type="Texture2D" path="res://Assets/HUD_BarBG.png" id="hud_bar_bg"]
[ext_resource type="Texture2D" path="res://Assets/HUD_InfectionFill.png" id="hud_infection_fill"]
[ext_resource type="Texture2D" path="res://Assets/HUD_DetectionFill.png" id="hud_detection_fill"]
[ext_resource type="Texture2D" path="res://Assets/HUD_Btn_Speed.png" id="hud_btn_speed"]
[ext_resource type="Texture2D" path="res://Assets/HUD_Btn_Stealth.png" id="hud_btn_stealth"]
[ext_resource type="Texture2D" path="res://Assets/HUD_Btn_Resistance.png" id="hud_btn_resistance"]
[ext_resource type="Texture2D" path="res://Assets/HUD_WinScreen.png" id="hud_win_screen"]
'''
content = content.replace('[ext_resource type="Script" path="res://DotRenderer.gd" id="3_dot"]', '[ext_resource type="Script" path="res://DotRenderer.gd" id="3_dot"]\n' + ext_resources)

start_idx = content.find('[node name="HUD" type="Control" parent="CanvasLayer"]')
if start_idx != -1:
    new_hud = '''[node name="HUD" type="Control" parent="CanvasLayer"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="TopPanel" type="Control" parent="CanvasLayer/HUD"]
layout_mode = 1
anchors_preset = 0
offset_left = 20.0
offset_top = 15.0
offset_right = 750.0
offset_bottom = 135.0

[node name="VirusNameLabel" type="Label" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 5.0
offset_right = 180.0
offset_bottom = 36.0
theme_override_colors/font_color = Color(0.862745, 0.12549, 0.12549, 1)
theme_override_font_sizes/font_size = 22
text = "VIRUS NAME"

[node name="TurnLabel" type="Label" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 200.0
offset_top = 7.0
offset_right = 260.0
offset_bottom = 30.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 16
text = "Turn: 0"

[node name="InfectionLabel" type="Label" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 35.0
offset_right = 150.0
offset_bottom = 58.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 16
text = "INFECTED: 0/7"

[node name="InfectionBarBG" type="TextureRect" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 55.0
offset_right = 320.0
offset_bottom = 75.0
texture = ExtResource("hud_bar_bg")

[node name="InfectionBar" type="TextureRect" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 22.0
offset_top = 57.0
offset_right = 318.0
offset_bottom = 73.0
texture = ExtResource("hud_infection_fill")
expand_mode = 1

[node name="DetectionLabel" type="Label" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 80.0
offset_right = 150.0
offset_bottom = 103.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 16
text = "DETECTION: 0%"

[node name="DetectionBar" type="TextureRect" parent="CanvasLayer/HUD/TopPanel"]
layout_mode = 0
offset_left = 22.0
offset_top = 95.0
offset_right = 318.0
offset_bottom = 111.0
texture = ExtResource("hud_detection_fill")
expand_mode = 1

[node name="BottomPanel" type="Control" parent="CanvasLayer/HUD"]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = -140.0
offset_right = 960.0
offset_bottom = -20.0
grow_vertical = 0

[node name="ResourcesLabel" type="Label" parent="CanvasLayer/HUD/BottomPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 10.0
offset_right = 160.0
offset_bottom = 33.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 18
text = "RESOURCES: 10"

[node name="BtnSpeed" type="TextureButton" parent="CanvasLayer/HUD/BottomPanel"]
layout_mode = 0
offset_left = 20.0
offset_top = 40.0
offset_right = 290.0
offset_bottom = 110.0
texture_normal = ExtResource("hud_btn_speed")

[node name="BtnStealth" type="TextureButton" parent="CanvasLayer/HUD/BottomPanel"]
layout_mode = 0
offset_left = 310.0
offset_top = 40.0
offset_right = 580.0
offset_bottom = 110.0
texture_normal = ExtResource("hud_btn_stealth")

[node name="BtnResistance" type="TextureButton" parent="CanvasLayer/HUD/BottomPanel"]
layout_mode = 0
offset_left = 610.0
offset_top = 40.0
offset_right = 880.0
offset_bottom = 110.0
texture_normal = ExtResource("hud_btn_resistance")

[node name="EndScreen" type="Control" parent="CanvasLayer"]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="EndBG" type="TextureRect" parent="CanvasLayer/EndScreen"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("hud_win_screen")

[node name="Title" type="Label" parent="CanvasLayer/EndScreen"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -50.0
offset_right = 200.0
offset_bottom = 50.0
grow_horizontal = 2
grow_vertical = 2
theme_override_font_sizes/font_size = 64
horizontal_alignment = 1
vertical_alignment = 1
text = "GAME OVER"

[connection signal="pressed" from="CanvasLayer/HUD/BottomPanel/BtnSpeed" to="." method="_on_btn_speed_pressed"]
[connection signal="pressed" from="CanvasLayer/HUD/BottomPanel/BtnStealth" to="." method="_on_btn_stealth_pressed"]
[connection signal="pressed" from="CanvasLayer/HUD/BottomPanel/BtnResistance" to="." method="_on_btn_resistance_pressed"]
'''
    content = content[:start_idx] + new_hud
    
    with open('GameScene.tscn', 'w') as f:
        f.write(content)
    print('Updated GameScene.tscn')
else:
    print('HUD node not found!')
