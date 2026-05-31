import sys

with open('GameScene.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# Add ext_resource for the second image
if 'COMPS WITH THE IMPPROVING.png' not in content:
    last_ext_idx = content.rfind('[ext_resource')
    end_of_last_ext = content.find('\n', last_ext_idx)
    
    ext_decl = '\n[ext_resource type="Texture2D" path="res://Assets/COMPS WITH THE IMPPROVING.png" id="tex_comps"]'
    content = content[:end_of_last_ext] + ext_decl + content[end_of_last_ext:]

# We need to replace the entire CRTMonitor node
# Let's find it
start_idx = content.find('[node name="CRTMonitor"')
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

[node name="ColorRect" type="TextureRect" parent="CanvasLayer/CRTMonitor"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -400.0
offset_top = -400.0
offset_right = 400.0
offset_bottom = 400.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("tex_computer")
expand_mode = 1
stretch_mode = 5

[node name="ScreenOverlay" type="TextureRect" parent="CanvasLayer/CRTMonitor/ColorRect"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -300.0
offset_top = -250.0
offset_right = 300.0
offset_bottom = 150.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("tex_comps")
expand_mode = 1
stretch_mode = 5

[node name="Label" type="Label" parent="CanvasLayer/CRTMonitor/ColorRect"]
layout_mode = 0
offset_left = 130.0
offset_top = 170.0
offset_right = 670.0
offset_bottom = 200.0
theme_override_colors/font_color = Color(0, 1, 0, 1)
theme_override_font_sizes/font_size = 20
text = "VIRUS UPGRADE TERMINAL"
horizontal_alignment = 1

[node name="CloseBtn" type="Button" parent="CanvasLayer/CRTMonitor/ColorRect"]
layout_mode = 0
offset_left = 650.0
offset_top = 160.0
offset_right = 680.0
offset_bottom = 190.0
theme_override_colors/font_color = Color(1, 0, 0, 1)
text = "X"
flat = true

[node name="GridContainer" type="GridContainer" parent="CanvasLayer/CRTMonitor/ColorRect"]
layout_mode = 0
offset_left = 130.0
offset_top = 220.0
offset_right = 670.0
offset_bottom = 520.0
theme_override_constants/h_separation = 30
theme_override_constants/v_separation = 20
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
    content = content[:start_idx] + new_crt_monitor + content[end_idx:]

with open('GameScene.tscn', 'w', encoding='utf-8') as f:
    f.write(content)

print("Applied dual textures")
