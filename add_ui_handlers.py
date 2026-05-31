import sys

with open('GameScene.gd', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Add @onready var crt_monitor
for i, line in enumerate(lines):
    if line.startswith("@onready var end_screen"):
        lines.insert(i + 1, '@onready var crt_monitor = $CanvasLayer/CRTMonitor if has_node("CanvasLayer/CRTMonitor") else null\n')
        break

# Add all the button pressed methods at the bottom
methods = """
# ═════════════════════════════════════════════════════════════════
#                      UI BUTTON HANDLERS
# ═════════════════════════════════════════════════════════════════

func _on_btn_speed_pressed():
	if crt_monitor: crt_monitor.show()

func _on_btn_stealth_pressed():
	if crt_monitor: crt_monitor.show()

func _on_btn_resistance_pressed():
	if crt_monitor: crt_monitor.show()

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
"""
lines.append(methods)

with open('GameScene.gd', 'w', encoding='utf-8') as f:
    f.writelines(lines)
print("Added UI handlers to GameScene.gd")
