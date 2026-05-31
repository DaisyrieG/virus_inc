import sys

with open('GameScene.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the start and end of CRTMonitor
start_idx = content.find('[node name="CRTMonitor" type="Control"')
end_idx = content.find('[connection signal="pressed" from="CanvasLayer/CRTMonitor/ColorRect/CloseBtn"')

if start_idx != -1 and end_idx != -1:
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
offset_left = -400.0
offset_top = -280.0
offset_right = 400.0
offset_bottom = 220.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("tex_comps")
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
theme_override_font_sizes/font_size = 24
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
text = "X"
flat = true

[node name="GridContainer" type="GridContainer" parent="CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -350.0
offset_top = -180.0
offset_right = 350.0
offset_bottom = 200.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/h_separation = 40
theme_override_constants/v_separation = 30
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

"""

    content = content[:start_idx] + new_crt_monitor + content[end_idx:]
    
    # We also need to fix the connections because the paths changed!
    # "CanvasLayer/CRTMonitor/ColorRect/CloseBtn" -> "CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/CloseBtn"
    # "CanvasLayer/CRTMonitor/ColorRect/GridContainer..." -> "CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer..."
    
    content = content.replace('CanvasLayer/CRTMonitor/ColorRect/', 'CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/')

    with open('GameScene.tscn', 'w', encoding='utf-8') as f:
        f.write(content)

    print("Fixed sizing and paths")
else:
    print("Could not find boundaries")
