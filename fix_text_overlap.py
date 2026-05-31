import sys

with open('GameScene.gd', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# We will replace the entire block from "func _setup_dynamic_ui():" down to just before "func defense_log_event(msg: String, color: String = "white"):"
start_str = "func _setup_dynamic_ui():"
end_str = "func defense_log_event("

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx == -1 or end_idx == -1:
    print("Could not find blocks")
    sys.exit(1)

new_code = """func _setup_dynamic_ui():
	# 1. Defense Panel
	var dp = TextureRect.new()
	dp.texture = load("res://Assets/HUD_DefensePanel.png")
	# Force anchor right
	dp.anchor_left = 1.0
	dp.anchor_right = 1.0
	dp.anchor_top = 0.0
	dp.anchor_bottom = 0.0
	dp.offset_left = -330
	dp.offset_right = -10
	dp.offset_top = 10
	dp.offset_bottom = 300
	dp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# --- MASKS TO HIDE BAKED PLACEHOLDER TEXT IN THE IMAGE ---
	var mask_color = Color(0.01, 0.08, 0.04, 1.0) # Matches the dark green background
	
	var m1 = ColorRect.new()
	m1.color = mask_color
	m1.offset_left = 85
	m1.offset_top = 18
	m1.offset_right = 300
	m1.offset_bottom = 40
	dp.add_child(m1)
	
	var m2 = ColorRect.new()
	m2.color = mask_color
	m2.offset_left = 220
	m2.offset_top = 62
	m2.offset_right = 300
	m2.offset_bottom = 85
	dp.add_child(m2)
	
	var m4 = ColorRect.new()
	m4.color = mask_color
	m4.offset_left = 10
	m4.offset_top = 135
	m4.offset_right = 310
	m4.offset_bottom = 280
	dp.add_child(m4)
	
	# --- DYNAMIC CONTENT ---
	alert_badge = TextureRect.new()
	alert_badge.offset_left = 15
	alert_badge.offset_top = 18
	alert_badge.offset_right = 55
	alert_badge.offset_bottom = 58
	alert_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	alert_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dp.add_child(alert_badge)
	
	status_label = Label.new()
	status_label.text = "DORMANT"
	status_label.offset_left = 85
	status_label.offset_top = 18
	status_label.add_theme_color_override("font_color", Color.WHITE)
	dp.add_child(status_label)
	
	patch_count_label = Label.new()
	patch_count_label.text = "0"
	patch_count_label.offset_left = 230
	patch_count_label.offset_top = 62
	patch_count_label.add_theme_color_override("font_color", Color(0, 1, 0)) # bright green
	dp.add_child(patch_count_label)
	
	defense_log = RichTextLabel.new()
	defense_log.bbcode_enabled = true
	defense_log.scroll_following = true
	defense_log.offset_left = 15
	defense_log.offset_top = 135
	defense_log.offset_right = 305
	defense_log.offset_bottom = 280
	dp.add_child(defense_log)
	
	var canvas = $CanvasLayer if has_node("CanvasLayer") else self
	canvas.add_child(dp)

func _update_defense_panel():
	if not status_label: return
	
	if detection_level >= 0.75:
		alert_badge.texture = load("res://Assets/HUD_Alert_Critical.png")
		status_label.text = "MAXIMUM RESPONSE"
		status_label.add_theme_color_override("font_color", Color.RED)
	elif detection_level >= 0.50:
		alert_badge.texture = load("res://Assets/HUD_Alert_High.png")
		status_label.text = "ACTIVE HUNTING"
		status_label.add_theme_color_override("font_color", Color.ORANGE)
	elif detection_level >= 0.20:
		alert_badge.texture = load("res://Assets/HUD_Alert_Medium.png")
		status_label.text = "SCANNING..."
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		alert_badge.texture = load("res://Assets/HUD_Alert_Low.png")
		status_label.text = "DORMANT"
		status_label.add_theme_color_override("font_color", Color.WHITE)
		
	patch_count_label.text = str(total_patches)

"""

new_file_content = content[:start_idx] + new_code + content[end_idx:]

with open('GameScene.gd', 'w', encoding='utf-8') as f:
    f.write(new_file_content)

print("Updated UI code to hide baked placeholders")
