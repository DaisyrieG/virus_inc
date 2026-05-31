import sys
import re

with open('GameScene.gd', 'r') as f:
    content = f.read()

# Add @onready vars
onready_new = """@onready var virus_name_label = $CanvasLayer/HUD/TopPanel/VirusNameLabel
@onready var turn_label = $CanvasLayer/HUD/TopPanel/TurnLabel
@onready var notification_label = $CanvasLayer/HUD/NotificationLabel
@onready var event_text = $CanvasLayer/HUD/EventLog/EventText
@onready var traits_label = $CanvasLayer/HUD/BottomPanel/TraitsLabel"""

content = content.replace("""@onready var virus_name_label = $CanvasLayer/HUD/TopPanel/VirusNameLabel
@onready var turn_label = $CanvasLayer/HUD/TopPanel/TurnLabel""", onready_new)

# Add show_notification and log_event before _ready
notif_funcs = """# ── NOTIFICATION POPUP (fades out after 2 seconds) ────────────────
func show_notification(message: String, color: Color = Color.RED):
	if notification_label:
		notification_label.text = message
		notification_label.modulate = color
		notification_label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)

# ── EVENT LOG (scrolling text at bottom-right) ────────────────────
func log_event(message: String, color: String = "white"):
	if event_text:
		event_text.append_text("[color=%s]> %s[/color]\\n" % [color, message])

# ═══════════════════════════════════════════════════════════════════
# READY"""

content = content.replace("""# ═══════════════════════════════════════════════════════════════════
# READY""", notif_funcs)

# _start_infection
content = content.replace("""	print(get_node("/root/Global").virus_name + " has started infecting " + country + "!")""",
"""	log_event("%s started infecting %s!" % [get_node("/root/Global").virus_name, country], "red")
	show_notification("INFECTED: " + country, Color(0.9, 0.2, 0.2))""")

# _dijkstra_spread
content = content.replace("""			print("%s spread from %s → %s (dist=%.2f)" % [
				get_node("/root/Global").virus_name, spread_from, country, target["distance"]
			])""",
"""			log_event("Virus spread: %s → %s" % [spread_from, country], "red")
			show_notification("SPREADING TO: " + country, Color(0.9, 0.15, 0.15))""")

# _ga_evolve
content = content.replace("""	virus_speed = best["speed"]
	virus_stealth = best["stealth"]
	virus_resistance = best["resistance"]""",
"""	virus_speed = best["speed"]
	virus_stealth = best["stealth"]
	virus_resistance = best["resistance"]
	
	log_event("Gen %d evolved — SPD:%.1f STL:%.1f RES:%.1f" % [
		ga_generation, virus_speed, virus_stealth, virus_resistance
	], "yellow")""")

# _bayesian_defense
content = content.replace("""			print("[Bayesian] Tried to patch %s but virus RESISTED! (%.0f%% resist)" % [
				target, resist_chance * 100
			])""",
"""			log_event("Defense tried to patch %s — VIRUS RESISTED!" % target, "orange")
			show_notification("RESISTED PATCH: " + target, Color(1.0, 0.6, 0.1))""")

content = content.replace("""		print("[Bayesian] PATCHED %s | P(Infected|S) = %.2f" % [
			target, candidates[i]["posterior"]
		])""",
"""		log_event("PATCHED: %s — removed from infected!" % target, "green")
		show_notification("COUNTRY PATCHED: " + target, Color(0.2, 0.8, 0.2))""")

# _upgrade_trait
upgrade_start = """func _upgrade_trait(trait_name: String):
	if game_over:
		return
	
	var current = 0.0
	match trait_name:
		"speed": current = virus_speed
		"stealth": current = virus_stealth
		"resistance": current = virus_resistance

	if current >= 10.0:
		log_event("%s is already at MAX level!" % trait_name, "orange")
		show_notification(trait_name.to_upper() + " IS MAXED!", Color(1.0, 0.6, 0.1))
		return
"""
content = content.replace("""func _upgrade_trait(trait_name: String):
	if game_over:
		return""", upgrade_start)

content = content.replace("""				virus_speed = minf(virus_speed + 1.0, 10.0)
				print("[Upgrade] Speed → %.1f (cost %d)" % [virus_speed, cost])""",
"""				virus_speed = minf(virus_speed + 1.0, 10.0)
				log_event("Upgraded %s → Lv %.0f (-%d resources)" % [trait_name, virus_speed, cost], "cyan")
				show_notification("UPGRADED " + trait_name.to_upper(), Color(0.3, 0.9, 0.9))""")

content = content.replace("""				virus_stealth = minf(virus_stealth + 1.0, 10.0)
				print("[Upgrade] Stealth → %.1f (cost %d)" % [virus_stealth, cost])""",
"""				virus_stealth = minf(virus_stealth + 1.0, 10.0)
				log_event("Upgraded %s → Lv %.0f (-%d resources)" % [trait_name, virus_stealth, cost], "cyan")
				show_notification("UPGRADED " + trait_name.to_upper(), Color(0.3, 0.9, 0.9))""")

content = content.replace("""				virus_resistance = minf(virus_resistance + 1.0, 10.0)
				print("[Upgrade] Resistance → %.1f (cost %d)" % [virus_resistance, cost])""",
"""				virus_resistance = minf(virus_resistance + 1.0, 10.0)
				log_event("Upgraded %s → Lv %.0f (-%d resources)" % [trait_name, virus_resistance, cost], "cyan")
				show_notification("UPGRADED " + trait_name.to_upper(), Color(0.3, 0.9, 0.9))""")

content = content.replace("""		print("[Upgrade] Not enough resources! Need %d, have %d" % [cost, resources])""",
"""		log_event("Not enough resources! Need %d, have %d" % [cost, resources], "red")
		show_notification("NOT ENOUGH RESOURCES!", Color(1.0, 0.2, 0.2))""")

# _end_game
content = content.replace("""	if player_won:
		print("══════ %s HAS CONQUERED THE NETWORK! ══════" % get_node("/root/Global").virus_name)
	else:
		print("══════ CYBERSECURITY AI CONTAINED THE THREAT ══════")""",
"""	if player_won:
		log_event("=== INFECTION COMPLETE ===", "red")
		show_notification("YOU WIN — NETWORK COMPROMISED", Color(0.9, 0.1, 0.1))
	else:
		log_event("=== SYSTEM SECURED ===", "green")
		show_notification("YOU LOSE — VIRUS CONTAINED", Color(0.2, 0.8, 0.2))""")

# _on_turn_tick
content = content.replace("""	# ── STEP 5: Raise global detection ────────────────────────────
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	detection_level = clampf(detection_level + 0.01 * stealth_mod, 0.0, 1.0)
""",
"""	# ── STEP 5: Raise global detection ────────────────────────────
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	detection_level = clampf(detection_level + 0.01 * stealth_mod, 0.0, 1.0)
	
	if detection_level > 0.75:
		log_event("WARNING: Detection at %.0f%%!" % [detection_level * 100], "red")
		show_notification("CRITICAL: DETECTION %.0f%%!" % [detection_level * 100], Color(1.0, 0.2, 0.2))
	elif detection_level > 0.50:
		log_event("Caution: Detection rising — %.0f%%" % [detection_level * 100], "orange")
""")

# _update_hud
content = content.replace("""	if turn_label:
		turn_label.text = "Turn: %d" % [turn_count]""",
"""	if turn_label:
		turn_label.text = "Turn: %d" % [turn_count]
	if traits_label:
		traits_label.text = "SPD: %.0f  |  STL: %.0f  |  RES: %.0f" % [
			virus_speed, virus_stealth, virus_resistance
		]""")


with open('GameScene.gd', 'w') as f:
    f.write(content)
print("Updated GameScene.gd completely.")
