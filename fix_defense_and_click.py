import sys

with open('GameScene.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _setup_dynamic_ui
old_setup = """func _setup_dynamic_ui():
	# 1. Defense Panel
	var dp = TextureRect.new()
	dp.texture = load("res://Assets/HUD_DefensePanel.png")
	dp.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dp.offset_left = -340
	dp.offset_top = 20
	dp.offset_right = -20
	dp.offset_bottom = 240
	dp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	alert_badge = TextureRect.new()
	alert_badge.offset_left = 15
	alert_badge.offset_top = 20
	alert_badge.offset_right = 55
	alert_badge.offset_bottom = 60
	alert_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dp.add_child(alert_badge)
	
	status_label = Label.new()
	status_label.text = "DORMANT"
	status_label.offset_left = 75
	status_label.offset_top = 20
	status_label.add_theme_color_override("font_color", Color.WHITE)
	dp.add_child(status_label)
	
	patch_count_label = Label.new()
	patch_count_label.text = "Patches: 0"
	patch_count_label.offset_left = 75
	patch_count_label.offset_top = 45
	patch_count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	dp.add_child(patch_count_label)
	
	defense_log = RichTextLabel.new()
	defense_log.bbcode_enabled = true
	defense_log.scroll_following = true
	defense_log.offset_left = 15
	defense_log.offset_top = 80
	defense_log.offset_right = 305
	defense_log.offset_bottom = 205
	dp.add_child(defense_log)
	
	var hud = $CanvasLayer/HUD if has_node("CanvasLayer/HUD") else $CanvasLayer
	hud.add_child(dp)"""

new_setup = """func _setup_dynamic_ui():
	# 1. Defense Panel
	var dp = TextureRect.new()
	dp.texture = load("res://Assets/HUD_DefensePanel.png")
	# Force anchor right
	dp.anchor_left = 1.0
	dp.anchor_right = 1.0
	dp.anchor_top = 0.0
	dp.anchor_bottom = 0.0
	dp.offset_left = -340
	dp.offset_right = -20
	dp.offset_top = 20
	dp.offset_bottom = 240
	dp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	alert_badge = TextureRect.new()
	alert_badge.offset_left = 15
	alert_badge.offset_top = 20
	alert_badge.offset_right = 65
	alert_badge.offset_bottom = 70
	alert_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	alert_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dp.add_child(alert_badge)
	
	status_label = Label.new()
	status_label.text = "DORMANT"
	status_label.offset_left = 85
	status_label.offset_top = 20
	status_label.add_theme_color_override("font_color", Color.WHITE)
	dp.add_child(status_label)
	
	patch_count_label = Label.new()
	patch_count_label.text = "Patches: 0"
	patch_count_label.offset_left = 85
	patch_count_label.offset_top = 45
	patch_count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	dp.add_child(status_label)
	dp.add_child(patch_count_label)
	
	defense_log = RichTextLabel.new()
	defense_log.bbcode_enabled = true
	defense_log.scroll_following = true
	defense_log.offset_left = 15
	defense_log.offset_top = 80
	defense_log.offset_right = 305
	defense_log.offset_bottom = 205
	dp.add_child(defense_log)
	
	var canvas = $CanvasLayer if has_node("CanvasLayer") else self
	canvas.add_child(dp)"""

content = content.replace(old_setup, new_setup)

# 2. Update _unhandled_input to open CRT monitor when clicking country
old_input = """				if hovered_country != "" and not game_started:
					_start_infection(hovered_country)"""

new_input = """				if hovered_country != "":
					if not game_started:
						_start_infection(hovered_country)
					else:
						if crt_monitor:
							crt_monitor.show()"""

content = content.replace(old_input, new_input)

with open('GameScene.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated Defense Panel and Click Input!")
