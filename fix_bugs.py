import sys

with open('GameScene.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update Dot Spawning
content = content.replace("dot_renderer.add_dot(Vector2(rx, ry))", "dot_renderer.add_dot(Vector2(rx, ry), country_name)")

# 2. Update GA Mutation Rate
content = content.replace("randf_range(1.0, 5.0)", "randf_range(1.0, 3.0)")
content = content.replace("randf_range(-1.5, 1.5)", "randf_range(-0.5, 0.5)")

# 3. Update Detection Increment
old_det = """	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	detection_level = clampf(detection_level + 0.015 * stealth_mod, 0.0, 1.0)"""
new_det = """	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	if upgrades["code_obfuscation"]["bought"]:
		stealth_mod *= 0.7
	if upgrades["fileless_malware"]["bought"]:
		stealth_mod *= 0.5
	detection_level = clampf(detection_level + 0.008 * stealth_mod, 0.0, 1.0)"""
content = content.replace(old_det, new_det)
content = content.replace("detection_level = clampf(detection_level + 0.01 * stealth_mod, 0.0, 1.0)", new_det) # backup in case it was 0.01

# 4. Update Bayesian check frequency
old_bayes = """	elif detection_level >= 0.20:
		_bayesian_defense()"""
new_bayes = """	elif detection_level >= 0.20:
		if turn_count % 2 == 0:
			_bayesian_defense()"""
content = content.replace(old_bayes, new_bayes)

# 5. Hover Detection UI updates
old_hover = """			var status = ""
			if country in infected_countries:
				status = " [INFECTED]"
			elif country in patched_countries:
				status = " [PATCHED]"
			
			hover_label.text = country + status"""
new_hover = """			var status = " [SUSCEPTIBLE]"
			if country in infected_countries:
				status = " [INFECTED]"
			elif country in patched_countries:
				status = " [PATCHED]"
				
			var prob = country_detection.get(country, 0.0) * 100
			hover_label.text = country + status + "\\nP(Infected) = %.0f%%" % prob"""
content = content.replace(old_hover, new_hover)

# Write it back
with open('GameScene.gd', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated GameScene.gd bugs")
