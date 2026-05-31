import sys

with open('GameScene.gd', 'r') as f:
    content = f.read()

# Add upgrades dictionary
upgrades_dict = """# ── Virus Upgrades ──────────────────────────────────────────────────
var upgrades = {
    "email_phishing":    {"branch": "TRANSMISSION", "cost": 5,  "bought": false, "requires": ""},
    "cloud_exploit":     {"branch": "TRANSMISSION", "cost": 15, "bought": false, "requires": "email_phishing"},
    "code_obfuscation":  {"branch": "STEALTH",      "cost": 8,  "bought": false, "requires": ""},
    "fileless_malware":  {"branch": "STEALTH",      "cost": 20, "bought": false, "requires": "code_obfuscation"},
    "registry_persist":  {"branch": "RESISTANCE",   "cost": 10, "bought": false, "requires": ""},
    "anti_antivirus":    {"branch": "RESISTANCE",   "cost": 25, "bought": false, "requires": "registry_persist"},
    "keylogger":         {"branch": "PAYLOAD",      "cost": 8,  "bought": false, "requires": ""},
    "ransomware":        {"branch": "PAYLOAD",      "cost": 20, "bought": false, "requires": "keylogger"},
}

"""
content = content.replace("# ── Genetic Algorithm Population ──────────────────────────────────", upgrades_dict + "# ── Genetic Algorithm Population ──────────────────────────────────")

# Add payload bonuses in _on_turn_tick
turn_tick_payload = """	# ── STEP 4: Earn resources from infected countries ────────────
	_earn_resources(infected_countries.size())
	
	if upgrades["keylogger"]["bought"]:
		_earn_resources(infected_countries.size() * 2)
	if upgrades["ransomware"]["bought"]:
		_earn_resources(5)"""
content = content.replace("""	# ── STEP 4: Earn resources from infected countries ────────────
	_earn_resources(infected_countries.size())""", turn_tick_payload)

# Add buy_upgrade and _apply_upgrade
upgrade_logic = """
func buy_upgrade(upgrade_id: String):
	var upgrade = upgrades[upgrade_id]
	
	if upgrade["bought"]:
		show_notification("ALREADY UNLOCKED!", Color(1.0, 0.6, 0.1))
		return
	
	if upgrade["requires"] != "" and not upgrades[upgrade["requires"]]["bought"]:
		show_notification("UNLOCK PREVIOUS TIER FIRST!", Color(1.0, 0.2, 0.2))
		log_event("Requires: %s" % upgrade["requires"].replace("_", " "), "red")
		return
	
	if resources < upgrade["cost"]:
		show_notification("NEED %d RESOURCES!" % upgrade["cost"], Color(1.0, 0.2, 0.2))
		return
	
	resources -= upgrade["cost"]
	upgrade["bought"] = true
	_apply_upgrade(upgrade_id)
	log_event("UNLOCKED: %s" % upgrade_id.replace("_", " ").to_upper(), "cyan")
	show_notification("UNLOCKED: " + upgrade_id.replace("_", " ").to_upper(), Color(0.3, 0.9, 0.9))
	_update_hud()

func _apply_upgrade(id: String):
	match id:
		"email_phishing":
			virus_speed += 1.5
			log_event("+15% spread chance", "red")
		"cloud_exploit":
			virus_speed += 3.0
			log_event("Spread to 2 countries per turn!", "red")
		"code_obfuscation":
			virus_stealth += 3.0
			log_event("Detection slowed by 30%", "blue")
		"fileless_malware":
			virus_stealth += 5.0
			log_event("Bayesian signals halved!", "blue")
		"registry_persist":
			virus_resistance += 3.0
			log_event("30% patch resistance", "green")
		"anti_antivirus":
			virus_resistance += 6.0
			log_event("60% resistance + re-infection!", "green")
		"keylogger":
			log_event("+2 resources per country per turn!", "purple")
		"ransomware":
			log_event("+5 resources per turn!", "purple")

# ── CRT MONITOR UI CALLBACKS ──────────────────────────────────────
func _on_email_phishing_pressed():
	buy_upgrade("email_phishing")

func _on_cloud_exploit_pressed():
	buy_upgrade("cloud_exploit")
	
func _on_code_obfuscation_pressed():
	buy_upgrade("code_obfuscation")
	
func _on_fileless_malware_pressed():
	buy_upgrade("fileless_malware")

func _on_registry_persist_pressed():
	buy_upgrade("registry_persist")

func _on_anti_antivirus_pressed():
	buy_upgrade("anti_antivirus")

func _on_keylogger_pressed():
	buy_upgrade("keylogger")

func _on_ransomware_pressed():
	buy_upgrade("ransomware")

# ═══════════════════════════════════════════════════════════════════
# HUD BUTTON CALLBACKS"""

content = content.replace("# ═══════════════════════════════════════════════════════════════════\n# HUD BUTTON CALLBACKS", upgrade_logic)

with open('GameScene.gd', 'w') as f:
    f.write(content)

print("GameScene.gd patched.")
