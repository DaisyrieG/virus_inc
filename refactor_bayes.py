import sys

with open('GameScene.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Add the variable at the top
var_declaration = "var ga = GeneticAlgorithm.new()"
new_var_declaration = "var ga = GeneticAlgorithm.new()\nvar bayesian_ai = BayesianDefense.new()"
content = content.replace(var_declaration, new_var_declaration)

# Replace the step 3 call
old_step_3 = """	# ── STEP 3: Bayesian Defense — detect and patch ───────────────
	_bayesian_defense()"""
new_step_3 = """	# ── STEP 3: Bayesian Defense — detect and patch ───────────────
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
		show_notification("COUNTRY PATCHED: " + target, Color(0.2, 0.8, 0.2))"""
content = content.replace(old_step_3, new_step_3)

# Remove the bayesian defense section completely
start_str = "# ═══════════════════════════════════════════════════════════════════\n# BAYESIAN DEFENSE — CYBERSECURITY AI"
end_str = "# ═══════════════════════════════════════════════════════════════════\n# RESOURCE ECONOMY & UPGRADES"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + content[end_idx:]

with open('GameScene.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("Refactored GameScene.gd to use BayesianDefense.gd")
