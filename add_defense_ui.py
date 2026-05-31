import sys

with open('GameScene.gd', 'r', encoding='utf-8') as f:
    lines = f.readlines()

content = "".join(lines)

# 1. Add new variables
vars_insert = """
# ── Dynamic Defense UI ────────────────────────────────────────────
@onready var alert_badge: TextureRect = null
@onready var status_label: Label = null
@onready var patch_count_label: Label = null
@onready var defense_log: RichTextLabel = null
var total_patches: int = 0
var milestones = {"20": false, "50": false, "75": false}
"""
content = content.replace("var turn_count: int = 0\n", "var turn_count: int = 0\n" + vars_insert)

# 2. Add _setup_dynamic_ui in _ready
content = content.replace("_ga_init_population()\n", "_ga_init_population()\n\t_setup_dynamic_ui()\n")

# 3. Add UI setup and update functions at the bottom
ui_functions = """
# ═════════════════════════════════════════════════════════════════
#                     DEFENSE UI LOGIC
# ═════════════════════════════════════════════════════════════════

func _setup_dynamic_ui():
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
	hud.add_child(dp)
	
	# 2. End Screen Buttons
	if end_screen:
		var btn_restart = Button.new()
		btn_restart.text = "RESTART GAME"
		btn_restart.set_anchors_preset(Control.PRESET_CENTER)
		btn_restart.offset_top = 100
		btn_restart.offset_left = -150
		btn_restart.offset_right = 150
		btn_restart.offset_bottom = 150
		btn_restart.pressed.connect(func(): get_tree().reload_current_scene())
		end_screen.add_child(btn_restart)
		
		var btn_menu = Button.new()
		btn_menu.text = "MAIN MENU"
		btn_menu.set_anchors_preset(Control.PRESET_CENTER)
		btn_menu.offset_top = 180
		btn_menu.offset_left = -150
		btn_menu.offset_right = 150
		btn_menu.offset_bottom = 230
		btn_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://MainMenu.tscn"))
		end_screen.add_child(btn_menu)
		
	_update_defense_panel()

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
		status_label.text = "SCANNING"
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		alert_badge.texture = load("res://Assets/HUD_Alert_Low.png")
		status_label.text = "DORMANT"
		status_label.add_theme_color_override("font_color", Color.WHITE)
		
	patch_count_label.text = "Patches: %d" % total_patches

func defense_log_event(msg: String, color: String = "white"):
	if defense_log:
		defense_log.append_text("[color=%s]> %s[/color]\\n" % [color, msg])
"""
content += ui_functions

# 4. Update _end_game
old_end = """func _end_game(won: bool):
	game_over = true
	if won:
		log_event("═══ %s HAS CONQUERED THE NETWORK! ═══" % Global.virus_name, "red")
		show_notification("YOU WIN — NETWORK COMPROMISED!", Color(0.9, 0.1, 0.1))
	else:
		log_event("═══ CYBERSECURITY AI CONTAINED THE THREAT ═══", "green")
		show_notification("YOU LOSE — VIRUS CONTAINED!", Color(0.2, 0.9, 0.3))
	
	if end_screen:
		end_screen.show()"""

new_end = """func _end_game(won: bool):
	game_over = true
	if end_screen:
		var end_bg = end_screen.get_node("EndBG")
		if end_bg:
			end_bg.texture = load("res://Assets/SCREEN_Win.png") if won else load("res://Assets/SCREEN_Lose.png")
		end_screen.show()"""
content = content.replace(old_end, new_end)

# 5. Fix clear dots
old_clear = """func _clear_dots_in_country(_country: String):
	# Clear all dots and let only infected countries respawn them
	for child in dot_renderer.get_children():
		child.queue_free()"""
new_clear = """func _clear_dots_in_country(_country: String):
	dot_renderer.clear_dots_in_country(_country)"""
content = content.replace(old_clear, new_clear)

# 6. Update milestones and UI panel inside _on_turn_tick
milestone_check = """
	if detection_level >= 0.75 and not milestones["75"]:
		milestones["75"] = true
		show_notification("CRITICAL WARNING: 75% DETECTION REACHED!", Color.RED)
	elif detection_level >= 0.50 and not milestones["50"]:
		milestones["50"] = true
		show_notification("WARNING: 50% DETECTION REACHED!", Color.ORANGE)
	elif detection_level >= 0.20 and not milestones["20"]:
		milestones["20"] = true
		show_notification("DEFENSE ACTIVATED: 20% DETECTION REACHED!", Color.YELLOW)
		
	_update_defense_panel()
"""
content = content.replace("\t_check_win_lose()\n\t_update_hud()", milestone_check + "\n\t_check_win_lose()\n\t_update_hud()")

# 7. Add defense_log_event calls to _bayesian_defense
content = content.replace('log_event("Defense tried to patch %s — VIRUS RESISTED! (%.0f%%)" % [\n\t\t\t\tbest_target, resist_chance * 100], "orange")',
"""log_event("Defense tried to patch %s — VIRUS RESISTED! (%.0f%%)" % [
				best_target, resist_chance * 100], "orange")
			defense_log_event("Patch FAILED — virus resisted ✗", "orange")""")

content = content.replace("patched_countries.append(best_target)\n\t\tdetection_level = clampf(detection_level + 0.03, 0.0, 1.0)",
"""patched_countries.append(best_target)
		total_patches += 1
		defense_log_event("PATCHED %s ✓" % best_target, "green")
		detection_level = clampf(detection_level + 0.03, 0.0, 1.0)""")

# 8. Check win lose hidden virus
old_win = """func _check_win_lose():
	var rate = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	
	if rate >= WIN_THRESHOLD:
		_end_game(true)
	elif detection_level >= LOSE_THRESHOLD:
		_end_game(false)"""

new_win = """func _check_win_lose():
	if infected_countries.size() == 0 and turn_count > 1 and patched_countries.size() > 0:
		var hidden = patched_countries.pop_back()
		infected_countries.append(hidden)
		log_event("VIRUS HIDDEN! Survived in %s!" % hidden, "purple")
		defense_log_event("CRITICAL ERROR: VIRUS NOT FULLY PURGED", "red")
		
	var rate = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	
	if rate >= WIN_THRESHOLD:
		_end_game(true)
	elif detection_level >= LOSE_THRESHOLD:
		_end_game(false)"""
content = content.replace(old_win, new_win)

with open('GameScene.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added Defense Panel UI and Win/Lose logic!")
