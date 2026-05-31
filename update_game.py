import sys

with open('GameScene.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Update STEP 3 & STEP 5
old_step = """	# ── STEP 3: Bayesian Defense — detect and patch ───────────────
	var defense_results = bayesian_ai.process_turn(
		world_graph.keys(),
		infected_countries,
		patched_countries,
		country_detection,
		virus_stealth,
		virus_resistance
	)
	
	for target in defense_results["resisted"]:
		log_event("Defense tried to patch %s — VIRUS RESISTED!" % target, "orange")
		show_notification("RESISTED PATCH: " + target, Color(1.0, 0.6, 0.1))
		
	for target in defense_results["patched"]:
		infected_countries.erase(target)
		patched_countries.append(target)
		detection_level = clampf(detection_level + 0.05, 0.0, 1.0)
		log_event("PATCHED: %s — removed from infected!" % target, "green")
		show_notification("COUNTRY PATCHED: " + target, Color(0.2, 0.8, 0.2))
	
	# ── STEP 4: Earn resources from infected countries ────────────
	_earn_resources(infected_countries.size())
	
	if upgrades["keylogger"]["bought"]:
		_earn_resources(infected_countries.size() * 2)
	if upgrades["ransomware"]["bought"]:
		_earn_resources(5)
	
	# ── STEP 5: Raise global detection ────────────────────────────
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	detection_level = clampf(detection_level + 0.01 * stealth_mod, 0.0, 1.0)"""

new_step = """	# ── STEP 3: Bayesian Defense — detect and patch ───────────────
	var max_patches = 0
	if detection_level > 0.75:
		max_patches = 3
	elif detection_level > 0.50:
		max_patches = 2
	elif detection_level > 0.20:
		max_patches = 1
	
	if max_patches > 0:
		var defense_results = bayesian_ai.process_turn(
			world_graph.keys(),
			infected_countries,
			patched_countries,
			country_detection,
			virus_stealth,
			virus_resistance,
			max_patches
		)
		
		for target in defense_results["resisted"]:
			log_event("Defense tried to patch %s — VIRUS RESISTED!" % target, "orange")
			show_notification("RESISTED PATCH: " + target, Color(1.0, 0.6, 0.1))
			
		for target in defense_results["patched"]:
			infected_countries.erase(target)
			patched_countries.append(target)
			dot_renderer.clear_dots_in_country(target)
			detection_level = clampf(detection_level + 0.05, 0.0, 1.0)
			log_event("SECURED: %s — defense AI contained the virus!" % target, "green")
			show_notification("COUNTRY SECURED: " + target, Color(0.2, 0.8, 0.2))
	
	# ── STEP 4: Earn resources from infected countries ────────────
	_earn_resources(infected_countries.size())
	
	if upgrades["keylogger"]["bought"]:
		_earn_resources(infected_countries.size() * 2)
	if upgrades["ransomware"]["bought"]:
		_earn_resources(5)
	
	# ── STEP 5: Raise global detection ────────────────────────────
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	detection_level = clampf(detection_level + 0.015 * stealth_mod, 0.0, 1.0)"""

if old_step in content:
    content = content.replace(old_step, new_step)
    with open('GameScene.gd', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated GameScene.gd logic")
else:
    print("Could not find old step")
