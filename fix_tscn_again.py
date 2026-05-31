import sys

with open('GameScene.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix HUD
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

# Add CRT Nodes
crt_nodes = """
[node name="CRTMonitor" type="Control" parent="CanvasLayer"]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="ColorRect" type="ColorRect" parent="CanvasLayer/CRTMonitor"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -350.0
offset_top = -250.0
offset_right = 350.0
offset_bottom = 250.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.0196078, 0, 0.0588235, 0.95)

[node name="ReferenceRect" type="ReferenceRect" parent="CanvasLayer/CRTMonitor/ColorRect"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
border_color = Color(0.6, 0.2, 1, 1)
border_width = 4.0
editor_only = false

[node name="Label" type="Label" parent="CanvasLayer/CRTMonitor/ColorRect"]
layout_mode = 0
offset_left = 30.0
offset_top = 20.0
offset_right = 670.0
offset_bottom = 50.0
theme_override_colors/font_color = Color(0, 1, 0, 1)
theme_override_font_sizes/font_size = 20
text = "VIRUS UPGRADE TERMINAL"
horizontal_alignment = 1

[node name="CloseBtn" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect"]
layout_mode = 0
offset_left = 650.0
offset_top = 10.0
offset_right = 680.0
offset_bottom = 40.0
theme_override_colors/font_color = Color(1, 0, 0, 1)
text = "X"
flat = true

[node name="GridContainer" type="GridContainer" parent="CanvasLayer/CRTMonitor/ColorRect"]
layout_mode = 0
offset_left = 30.0
offset_top = 70.0
offset_right = 670.0
offset_bottom = 450.0
theme_override_constants/h_separation = 30
theme_override_constants/v_separation = 30
columns = 2

[node name="VBoxTrans" type="VBoxContainer" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxTrans"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "TRANSMISSION
───────────"

[node name="BtnEmail" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxTrans"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> EMAIL PHISHING [5]"
flat = true
alignment = 0

[node name="BtnCloud" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxTrans"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> CLOUD EXPLOIT [15]"
flat = true
alignment = 0

[node name="VBoxStealth" type="VBoxContainer" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxStealth"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "STEALTH
───────────"

[node name="BtnObfuscation" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxStealth"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> CODE OBFUSCATION [8]"
flat = true
alignment = 0

[node name="BtnFileless" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxStealth"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> FILELESS MALWARE [20]"
flat = true
alignment = 0

[node name="VBoxResist" type="VBoxContainer" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxResist"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "RESISTANCE
───────────"

[node name="BtnRegistry" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxResist"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> REGISTRY PERSIST [10]"
flat = true
alignment = 0

[node name="BtnAntiAV" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxResist"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> ANTI-ANTIVIRUS [25]"
flat = true
alignment = 0

[node name="VBoxPayload" type="VBoxContainer" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Title" type="Label" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxPayload"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "PAYLOAD
───────────"

[node name="BtnKeylogger" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxPayload"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> KEYLOGGER [8]"
flat = true
alignment = 0

[node name="BtnRansomware" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxPayload"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 1, 0, 1)
text = "> RANSOMWARE [20]"
flat = true
alignment = 0
"""

connections = """[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/CloseBtn" to="CanvasLayer/CRTMonitor" method="hide"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxTrans/BtnEmail" to="." method="_on_email_phishing_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxTrans/BtnCloud" to="." method="_on_cloud_exploit_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxStealth/BtnObfuscation" to="." method="_on_code_obfuscation_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxStealth/BtnFileless" to="." method="_on_fileless_malware_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxResist/BtnRegistry" to="." method="_on_registry_persist_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxResist/BtnAntiAV" to="." method="_on_anti_antivirus_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxPayload/BtnKeylogger" to="." method="_on_keylogger_pressed"]
[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/GridContainer/VBoxPayload/BtnRansomware" to="." method="_on_ransomware_pressed"]
"""

if "CRTMonitor" not in content:
    content = content.replace('[connection signal="pressed" from="CanvasLayer/HUD/BottomPanel/BtnSpeed" to="." method="_on_btn_speed_pressed"]', crt_nodes + '\n' + connections + '[connection signal="pressed" from="CanvasLayer/HUD/BottomPanel/BtnSpeed" to="." method="_on_btn_speed_pressed"]')

with open('GameScene.tscn', 'w', encoding='utf-8') as f:
    f.write(content)

print("Restored GameScene.tscn correctly")
