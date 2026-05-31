import sys

with open('GameScene.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure the new asset is imported
if 'IMPROVING.png' not in content:
    last_ext_idx = content.rfind('[ext_resource')
    end_of_last_ext = content.find('\n', last_ext_idx)
    
    ext_decl = '\n[ext_resource type="Texture2D" path="res://Assets/IMPROVING.png" id="tex_improving"]'
    content = content[:end_of_last_ext] + ext_decl + content[end_of_last_ext:]


start_idx = content.find('[node name="CRTMonitor" type="Control"')

if start_idx != -1:
    new_crt_monitor = """[node name="CRTMonitor" type="Control" parent="CanvasLayer"]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="DimBackground" type="ColorRect" parent="CanvasLayer/CRTMonitor"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.7)

[node name="ComputerBG" type="TextureRect" parent="CanvasLayer/CRTMonitor"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -700.0
offset_top = -500.0
offset_right = 700.0
offset_bottom = 500.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("tex_computer")
expand_mode = 1
stretch_mode = 5

[node name="ScreenOverlay" type="TextureRect" parent="CanvasLayer/CRTMonitor/ComputerBG"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -340.0
offset_top = -320.0
offset_right = 340.0
offset_bottom = 140.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("tex_improving")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 20.0
offset_bottom = 50.0
grow_horizontal = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
theme_override_font_sizes/font_size = 28
text = "VIRUS UPGRADE TERMINAL"
horizontal_alignment = 1

[node name="CloseBtn" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay"]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -40.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = 40.0
grow_horizontal = 0
theme_override_colors/font_color = Color(1, 0, 0, 1)
theme_override_font_sizes/font_size = 24
text = "X"
flat = true

[node name="GridContainer" type="GridContainer" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -280.0
offset_top = -140.0
offset_right = 280.0
offset_bottom = 200.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/h_separation = 30
theme_override_constants/v_separation = 20
columns = 2

[node name="VBoxTrans" type="VBoxContainer" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxTrans"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "TRANSMISSION
───────────"

[node name="BtnEmail" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxTrans"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> EMAIL PHISHING [5]"
flat = true
alignment = 0

[node name="BtnCloud" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxTrans"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> CLOUD EXPLOIT [15]"
flat = true
alignment = 0

[node name="VBoxStealth" type="VBoxContainer" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxStealth"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "STEALTH
───────────"

[node name="BtnObfuscation" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxStealth"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> CODE OBFUSCATION [8]"
flat = true
alignment = 0

[node name="BtnFileless" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxStealth"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> FILELESS MALWARE [20]"
flat = true
alignment = 0

[node name="VBoxResist" type="VBoxContainer" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxResist"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "RESISTANCE
───────────"

[node name="BtnRegistry" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxResist"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> REGISTRY PERSIST [10]"
flat = true
alignment = 0

[node name="BtnAntiAV" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxResist"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> ANTI-ANTIVIRUS [25]"
flat = true
alignment = 0

[node name="VBoxPayload" type="VBoxContainer" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxPayload"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "PAYLOAD
───────────"

[node name="BtnKeylogger" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxPayload"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> KEYLOGGER [8]"
flat = true
alignment = 0

[node name="BtnRansomware" type="Button" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxPayload"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> RANSOMWARE [20]"
flat = true
alignment = 0

[connection signal="pressed" from="CanvasLayer/HUD/BottomPanel/BtnSpeed" to="." method="_on_btn_speed_pressed"]
[connection signal="pressed" from="CanvasLayer/HUD/BottomPanel/BtnStealth" to="." method="_on_btn_stealth_pressed"]
[connection signal="pressed" from="CanvasLayer/HUD/BottomPanel/BtnResistance" to="." method="_on_btn_resistance_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/CloseBtn" to="CanvasLayer/CRTMonitor" method="hide"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxTrans/BtnEmail" to="." method="_on_email_phishing_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxTrans/BtnCloud" to="." method="_on_cloud_exploit_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxStealth/BtnObfuscation" to="." method="_on_code_obfuscation_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxStealth/BtnFileless" to="." method="_on_fileless_malware_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxResist/BtnRegistry" to="." method="_on_registry_persist_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxResist/BtnAntiAV" to="." method="_on_anti_antivirus_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxPayload/BtnKeylogger" to="." method="_on_keylogger_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer/VBoxPayload/BtnRansomware" to="." method="_on_ransomware_pressed"]
"""

    content = content[:start_idx] + new_crt_monitor

    with open('GameScene.tscn', 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Fixed CRT overlay successfully")
else:
    print("Could not find bounds")
