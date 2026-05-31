import sys

with open('GameScene.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure we import the texture at the top
if 'path="res://Assets/COMPUTER.png"' not in content:
    # find last ext_resource
    last_ext_idx = content.rfind('[ext_resource')
    end_of_last_ext = content.find('\n', last_ext_idx)
    
    ext_decl = '\n[ext_resource type="Texture2D" path="res://Assets/COMPUTER.png" id="tex_computer"]'
    content = content[:end_of_last_ext] + ext_decl + content[end_of_last_ext:]

old_crt = """[node name="ColorRect" type="ColorRect" parent="CanvasLayer/CRTMonitor"]
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
editor_only = false"""

new_crt = """[node name="ColorRect" type="TextureRect" parent="CanvasLayer/CRTMonitor"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -500.0
offset_top = -450.0
offset_right = 500.0
offset_bottom = 450.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("tex_computer")
expand_mode = 1
stretch_mode = 5"""

content = content.replace(old_crt, new_crt)

# also shift the inner contents
content = content.replace('offset_left = 30.0\noffset_top = 20.0\noffset_right = 670.0\noffset_bottom = 50.0', 'offset_left = 180.0\noffset_top = 200.0\noffset_right = 820.0\noffset_bottom = 230.0')
content = content.replace('offset_left = 30.0\noffset_top = 70.0\noffset_right = 670.0\noffset_bottom = 450.0', 'offset_left = 180.0\noffset_top = 250.0\noffset_right = 820.0\noffset_bottom = 630.0')
content = content.replace('offset_left = 650.0\noffset_top = 10.0\noffset_right = 680.0\noffset_bottom = 40.0', 'offset_left = 780.0\noffset_top = 190.0\noffset_right = 810.0\noffset_bottom = 220.0')

with open('GameScene.tscn', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added COMPUTER.png background")
