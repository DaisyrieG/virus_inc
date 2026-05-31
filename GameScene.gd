extends Node2D

# ═══════════════════════════════════════════════════════════════════
# VIRUS INC — GAME SCENE (THE FIGHT)
# ═══════════════════════════════════════════════════════════════════

# ── Scene References ──────────────────────────────────────────────
@onready var map_sprite = $MapSprite
@onready var dot_renderer = $MapSprite/DotRenderer
@onready var hover_label = $CanvasLayer/HoverLabel
@onready var camera = $Camera2D

# ── HUD (add these to your CanvasLayer/HUD — works without them too) ──
@onready var infection_label = $CanvasLayer/HUD/InfectionLabel if has_node("CanvasLayer/HUD/InfectionLabel") else null
@onready var detection_label = $CanvasLayer/HUD/DetectionLabel if has_node("CanvasLayer/HUD/DetectionLabel") else null
@onready var resources_label = $CanvasLayer/HUD/ResourcesLabel if has_node("CanvasLayer/HUD/ResourcesLabel") else null
@onready var traits_label = $CanvasLayer/HUD/TraitsLabel if has_node("CanvasLayer/HUD/TraitsLabel") else null
@onready var turn_label = $CanvasLayer/HUD/TurnLabel if has_node("CanvasLayer/HUD/TurnLabel") else null
@onready var virus_name_label = $CanvasLayer/HUD/VirusNameLabel if has_node("CanvasLayer/HUD/VirusNameLabel") else null
@onready var infection_bar = $CanvasLayer/HUD/InfectionBar if has_node("CanvasLayer/HUD/InfectionBar") else null
@onready var detection_bar = $CanvasLayer/HUD/DetectionBar if has_node("CanvasLayer/HUD/DetectionBar") else null
@onready var notification_label = $CanvasLayer/HUD/NotificationLabel if has_node("CanvasLayer/HUD/NotificationLabel") else null
@onready var event_text = $CanvasLayer/HUD/EventLog/EventText if has_node("CanvasLayer/HUD/EventLog/EventText") else null
@onready var end_screen = $CanvasLayer/EndScreen if has_node("CanvasLayer/EndScreen") else null
@onready var crt_monitor = $CanvasLayer/CRTMonitor if has_node("CanvasLayer/CRTMonitor") else null

# ── Map Data ──────────────────────────────────────────────────────
var color_id_image: Image
var country_colors: Dictionary = {}
var country_bboxes: Dictionary = {}
var hovered_country: String = ""

# ═════════════════════════════════════════════════════════════════
#                        GAME STATE
# ═════════════════════════════════════════════════════════════════
var infected_countries: Array[String] = []
var patched_countries: Array[String] = []
var country_detection: Dictionary = {}     # Bayesian prior per country
var resources: int = 0
var detection_level: float = 0.0           # 0 to 1 — THE ENEMY BAR
var turn_count: int = 0

# ── Dynamic Defense UI ────────────────────────────────────────────
@onready var alert_badge: TextureRect = null
@onready var status_label: Label = null
@onready var patch_count_label: Label = null
@onready var defense_log: RichTextLabel = null
var total_patches: int = 0
var milestones = {"20": false, "50": false, "75": false}
var game_over: bool = false
var game_started: bool = false             # true after player clicks first country

# ── Virus Traits (evolved by GA + player upgrades) ────────────────
var virus_speed: float = 1.0
var virus_stealth: float = 1.0
var virus_resistance: float = 1.0

# ── Genetic Algorithm ─────────────────────────────────────────────
var ga_population: Array = []
const GA_POP_SIZE: int = 10
const GA_MUTATION_RATE: float = 0.15
var ga_generation: int = 0

# ── Constants ─────────────────────────────────────────────────────
const TOTAL_COUNTRIES: int = 7
const WIN_THRESHOLD: float = 0.90          # Infect 90% to win
const LOSE_THRESHOLD: float = 1.0          # Detection 100% = lose

# ── Upgrades ──────────────────────────────────────────────────────
var upgrades = {
	"email_phishing":   {"branch": "TRANSMISSION", "cost": 5,  "bought": false, "requires": ""},
	"cloud_exploit":    {"branch": "TRANSMISSION", "cost": 15, "bought": false, "requires": "email_phishing"},
	"code_obfuscation": {"branch": "STEALTH",      "cost": 8,  "bought": false, "requires": ""},
	"fileless_malware": {"branch": "STEALTH",      "cost": 20, "bought": false, "requires": "code_obfuscation"},
	"registry_persist": {"branch": "RESISTANCE",   "cost": 10, "bought": false, "requires": ""},
	"anti_antivirus":   {"branch": "RESISTANCE",   "cost": 25, "bought": false, "requires": "registry_persist"},
	"keylogger":        {"branch": "PAYLOAD",      "cost": 8,  "bought": false, "requires": ""},
	"ransomware":       {"branch": "PAYLOAD",      "cost": 20, "bought": false, "requires": "keylogger"},
}

# ── Network Graph ─────────────────────────────────────────────────
var world_graph: Dictionary = {
	"CHINA": {"RUSSIA": 2.0, "INDIA": 1.5, "KAZAKHSTAN": 1.8, "MONGOLIA": 1.0, "PHILIPPINES": 2.5},
	"RUSSIA": {"CHINA": 2.0, "KAZAKHSTAN": 1.2, "MONGOLIA": 1.5},
	"INDIA": {"CHINA": 1.5, "SAUDIARABIA": 3.0},
	"KAZAKHSTAN": {"RUSSIA": 1.2, "CHINA": 1.8},
	"MONGOLIA": {"RUSSIA": 1.5, "CHINA": 1.0},
	"PHILIPPINES": {"CHINA": 2.5},
	"SAUDIARABIA": {"INDIA": 3.0}
}

# ── Camera / Hover ────────────────────────────────────────────────
var is_dragging: bool = false
var last_mouse_pos: Vector2
var hover_sprite: Sprite2D
var country_hover_images: Dictionary = {
	"CHINA": "res://Assets/ASIAMAP_REALISTIC_CHINA.png",
	"INDIA": "res://Assets/ASIAMAP_REALISTIC_INDIA.png",
	"RUSSIA": "res://Assets/ASIAMAP_REALISTIC_RUSSIA.png",
	"MONGOLIA": "res://Assets/ASIAMAP_REALISTIC_MONGOLIA.png",
	"KAZAKHSTAN": "res://Assets/ASIAMAP_REALISTIC_MAP_KAZAKHSTAN.png",
	"PHILIPPINES": "res://Assets/ASIAMAP_REALISTIC_MAP_PHILIPPINES.png",
	"SAUDIARABIA": "res://Assets/ASIAMAP_REALISTIC_MAP_SAUDIARABIA.png"
}
var country_hover_textures: Dictionary = {}


# ═════════════════════════════════════════════════════════════════
#                          READY
# ═════════════════════════════════════════════════════════════════

func _ready():
	# Load Color ID map
	color_id_image = Image.load_from_file("res://Assets/ColorIDMap.png")
	
	# Load country data JSON
	var file = FileAccess.open("res://Assets/country_data.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		for country_name in data.keys():
			var rgb = data[country_name]["color"]
			var c = Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]))
			country_colors[c.to_html(false)] = country_name
			country_bboxes[country_name] = data[country_name]["bbox"]
	
	# Init Bayesian priors
	for country in world_graph.keys():
		country_detection[country] = 0.05
	
	# Preload hover textures
	for country in country_hover_images:
		var tex = load(country_hover_images[country])
		if tex:
			country_hover_textures[country] = tex
	
	# Setup hover sprite
	hover_sprite = Sprite2D.new()
	hover_sprite.centered = false
	map_sprite.add_child(hover_sprite)
	map_sprite.move_child(hover_sprite, 0)
	hover_sprite.hide()
	
	# Init GA
	_ga_init_population()
	_setup_dynamic_ui()
	
	# Hide end screen
	if end_screen:
		end_screen.hide()
	
	# Virus name
	if virus_name_label:
		virus_name_label.text = Global.virus_name
	
	# ── DOT TIMER (visual — fast) ────────────────────────────────
	var dot_timer = Timer.new()
	dot_timer.wait_time = 0.05
	dot_timer.autostart = true
	dot_timer.timeout.connect(_on_dot_tick)
	add_child(dot_timer)
	
	# ── TURN TIMER (game logic — every 2s) ───────────────────────
	var turn_timer = Timer.new()
	turn_timer.wait_time = 2.0
	turn_timer.autostart = true
	turn_timer.timeout.connect(_on_turn_tick)
	add_child(turn_timer)
	
	log_event("Click a country to start the infection...", "yellow")
	_update_hud()


# ═════════════════════════════════════════════════════════════════
#                         INPUT
# ═════════════════════════════════════════════════════════════════

func _unhandled_input(event):
	if game_over:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_mouse_pos = event.position
				if hovered_country != "" and not game_started:
					_start_infection(hovered_country)
			else:
				is_dragging = false
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.1
			camera.zoom = camera.zoom.clamp(Vector2(1,1), Vector2(4,4))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom /= 1.1
			camera.zoom = camera.zoom.clamp(Vector2(1,1), Vector2(4,4))
	
	elif event is InputEventMouseMotion:
		if is_dragging:
			camera.position -= (event.position - last_mouse_pos) / camera.zoom
			last_mouse_pos = event.position
		_check_hover(event.position)
	
	# Upgrade hotkeys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: buy_upgrade("email_phishing") if not upgrades["email_phishing"]["bought"] else buy_upgrade("cloud_exploit")
			KEY_2: buy_upgrade("code_obfuscation") if not upgrades["code_obfuscation"]["bought"] else buy_upgrade("fileless_malware")
			KEY_3: buy_upgrade("registry_persist") if not upgrades["registry_persist"]["bought"] else buy_upgrade("anti_antivirus")
			KEY_4: buy_upgrade("keylogger") if not upgrades["keylogger"]["bought"] else buy_upgrade("ransomware")


# ═════════════════════════════════════════════════════════════════
#                      START INFECTION
# ═════════════════════════════════════════════════════════════════

func _start_infection(country: String):
	game_started = true
	infected_countries.append(country)
	resources = 10
	log_event("%s deployed in %s!" % [Global.virus_name, country], "red")
	show_notification("VIRUS DEPLOYED: " + country, Color(0.9, 0.15, 0.15))
	_update_hud()


# ═════════════════════════════════════════════════════════════════
#                    DOT TICK (visual — every 0.05s)
# ═════════════════════════════════════════════════════════════════

func _on_dot_tick():
	if infected_countries.size() == 0 or game_over:
		return
	var random_country = infected_countries[randi() % infected_countries.size()]
	spawn_dot_in_country(random_country)


# ═════════════════════════════════════════════════════════════════
#              THE MAIN GAME LOOP — EVERY 2 SECONDS
# ═════════════════════════════════════════════════════════════════

func _on_turn_tick():
	if not game_started or game_over:
		return
	
	turn_count += 1
	
	# ══════════════ VIRUS SIDE ══════════════
	
	# 1. Genetic Algorithm evolves the virus
	_ga_evolve()
	
	# 2. Dijkstra spreads the virus
	_dijkstra_spread()
	
	# 3. Earn resources
	var income = infected_countries.size()
	if upgrades["keylogger"]["bought"]:
		income += infected_countries.size() * 2
	if upgrades["ransomware"]["bought"]:
		income += 5
	resources += income
	
	# ══════════════ DEFENSE SIDE — THE FIGHT ══════════════
	
	# Detection rises every turn (stealth slows it down)
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	if upgrades["code_obfuscation"]["bought"]:
		stealth_mod *= 0.7
	if upgrades["fileless_malware"]["bought"]:
		stealth_mod *= 0.5
	detection_level = clampf(detection_level + 0.008 * stealth_mod, 0.0, 1.0)
	
	# Defense AI gets MORE AGGRESSIVE as detection rises
	# Below 20% — no defense (player has a head start to build up)
	# 20-50% — defense checks once per turn
	# 50-75% — defense checks twice per turn  
	# 75%+   — defense checks THREE times per turn (panic mode!)
	
	if detection_level >= 0.75:
		log_event("CRITICAL: Defense in MAXIMUM ALERT!", "red")
		_bayesian_defense()
		_bayesian_defense()
		_bayesian_defense()
	elif detection_level >= 0.50:
		log_event("WARNING: Defense increasing patrols!", "orange")
		_bayesian_defense()
		_bayesian_defense()
	elif detection_level >= 0.20:
		if turn_count % 2 == 0:
			_bayesian_defense()
	# Below 20% = free reign, no defense yet
	
	# Detection milestone warnings
	if turn_count == 1:
		log_event("Virus is spreading undetected...", "yellow")
	
	# ══════════════ CHECK WIN/LOSE ══════════════

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

	_check_win_lose()
	_update_hud()
	
	# Console log
	print("[Turn %d] Infected: %d/%d | Detection: %.0f%% | Resources: %d | SPD:%.1f STL:%.1f RES:%.1f" % [
		turn_count, infected_countries.size(), TOTAL_COUNTRIES,
		detection_level * 100, resources,
		virus_speed, virus_stealth, virus_resistance
	])


# ═════════════════════════════════════════════════════════════════
#               DIJKSTRA SPREAD (with dynamic weights)
# ═════════════════════════════════════════════════════════════════

func _dijkstra_spread():
	if infected_countries.size() == 0:
		return
	
	# Spread chance scales with Speed
	# Speed 1 → 8%, Speed 10 → 44%
	var spread_chance = 0.08 + (virus_speed - 1.0) * 0.04
	
	if randf() > spread_chance:
		return  # No spread this turn
	
	# Run Dijkstra with dynamic weights
	var result = Dijkstra.calculate_shortest_paths(
		world_graph, infected_countries,
		virus_speed, country_detection, patched_countries
	)
	var distances = result["distances"]
	var previous = result["previous"]
	
	# Get all possible targets sorted by distance
	var targets = Dijkstra.get_spread_targets(distances, infected_countries, [])
	
	if targets.size() == 0:
		return
	
	# How many countries can we infect this turn?
	# Speed 1-3 → 1, Speed 4-6 → 2, Speed 7-10 → 3
	# Cloud exploit adds +1
	var max_spread = int(clampf(virus_speed / 3.5, 1, 3))
	if upgrades["cloud_exploit"]["bought"]:
		max_spread += 1
	
	var spread_count = 0
	for target_data in targets:
		if spread_count >= max_spread:
			break
		
		var country = target_data["country"]
		
		if country in infected_countries:
			continue
		
		# Patched countries are harder to re-infect
		if country in patched_countries:
			var reinfect_chance = virus_resistance * 0.08
			if not upgrades["anti_antivirus"]["bought"]:
				reinfect_chance *= 0.5  # Half chance without upgrade
			if randf() > reinfect_chance:
				continue  # Failed to re-infect
			patched_countries.erase(country)
			log_event("RE-INFECTED %s! Broke through defenses!" % country, "red")
			show_notification("RE-INFECTED: " + country + "!", Color(1.0, 0.3, 0.1))
		
		infected_countries.append(country)
		spread_count += 1
		
		var spread_from = previous.get(country, "unknown")
		log_event("%s spread: %s → %s" % [Global.virus_name, spread_from, country], "red")
		show_notification("INFECTED: " + country, Color(0.9, 0.15, 0.15))
		resources += 3


# ═════════════════════════════════════════════════════════════════
#         BAYESIAN DEFENSE — THE AI THAT FIGHTS THE PLAYER
# ═════════════════════════════════════════════════════════════════
#
# This is the ENEMY. Every turn it:
# 1. Observes signals from each country (infected = louder signal)
# 2. Updates P(Infected | Signal) using Bayes' theorem
# 3. If probability > threshold → PATCHES the country
# 4. Patching = removes infection, country turns green again
#
# The player fights this by:
# - Buying STEALTH upgrades (reduces signal = harder to detect)
# - Buying RESISTANCE upgrades (virus survives the patch)
# - Spreading FAST enough to outrun the defense
# ═════════════════════════════════════════════════════════════════

const PATCH_THRESHOLD: float = 0.65
const P_SIGNAL_INFECTED: float = 0.85
const P_SIGNAL_NOT_INFECTED: float = 0.15

func _bayesian_defense():
	var best_target = ""
	var best_posterior = 0.0
	
	for country in world_graph.keys():
		if country in patched_countries:
			continue
		
		# ── OBSERVE: infected countries emit suspicious signals ───
		var signal_strength = _observe_signal(country)
		
		# ── BAYES UPDATE: calculate P(Infected | Signal) ─────────
		var prior = country_detection.get(country, 0.05)
		var p_s_i = lerpf(0.0, P_SIGNAL_INFECTED, signal_strength)
		var p_s_ni = lerpf(0.0, P_SIGNAL_NOT_INFECTED, signal_strength)
		var numerator = p_s_i * prior
		var evidence = numerator + p_s_ni * (1.0 - prior)
		var posterior = numerator / evidence if evidence > 0 else prior
		
		country_detection[country] = posterior
		
		# Decay non-suspicious countries
		if posterior < PATCH_THRESHOLD * 0.4:
			country_detection[country] = maxf(0.01, posterior - 0.02)
		
		# Find the most suspicious infected country
		if posterior > best_posterior and country in infected_countries:
			best_posterior = posterior
			best_target = country
	
	# ── PATCH: if confident enough, remove the infection! ────────
	if best_target != "" and best_posterior >= PATCH_THRESHOLD:
		
		# RESISTANCE CHECK — virus might survive the patch!
		var resist_chance = virus_resistance * 0.07
		if upgrades["registry_persist"]["bought"]:
			resist_chance += 0.15
		if upgrades["anti_antivirus"]["bought"]:
			resist_chance += 0.25
		
		if randf() < resist_chance:
			# VIRUS RESISTED!
			log_event("Defense tried to patch %s — VIRUS RESISTED! (%.0f%%)" % [
				best_target, resist_chance * 100], "orange")
			defense_log_event("Patch FAILED — virus resisted ✗", "orange")
			show_notification("RESISTED PATCH: " + best_target, Color(1.0, 0.6, 0.1))
			return
		
		# ── THE PATCH HAPPENS — player LOSES this country ────────
		infected_countries.erase(best_target)
		patched_countries.append(best_target)
		total_patches += 1
		defense_log_event("PATCHED %s ✓" % best_target, "green")
		detection_level = clampf(detection_level + 0.03, 0.0, 1.0)
		
		# CLEAR THE DOTS — visually show the country is cured
		_clear_dots_in_country(best_target)
		
		log_event("SECURED: %s — defense contained the virus! (P=%.0f%%)" % [
			best_target, best_posterior * 100], "green")
		show_notification("COUNTRY SECURED: " + best_target, Color(0.2, 0.9, 0.3))
		
		# Tell the player what happened
		if infected_countries.size() == 0 and patched_countries.size() > 0:
			log_event("ALL COUNTRIES PATCHED! Spread faster or upgrade resistance!", "red")
			show_notification("ALL INFECTIONS CLEARED!", Color(1, 0.2, 0.2))

func _observe_signal(country: String) -> float:
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	if upgrades["fileless_malware"]["bought"]:
		stealth_mod *= 0.5  # Fileless malware halves signal
	if upgrades["code_obfuscation"]["bought"]:
		stealth_mod *= 0.7  # Code obfuscation reduces signal
	
	if country in infected_countries:
		return randf_range(0.4, 1.0) * stealth_mod
	else:
		return randf_range(0.0, 0.2)

func _clear_dots_in_country(_country: String):
	dot_renderer.clear_dots_in_country(_country)


# ═════════════════════════════════════════════════════════════════
#                    GENETIC ALGORITHM
# ═════════════════════════════════════════════════════════════════

func _ga_init_population():
	ga_population.clear()
	for i in range(GA_POP_SIZE):
		ga_population.append({
			"speed": randf_range(1.0, 3.0),
			"stealth": randf_range(1.0, 3.0),
			"resistance": randf_range(1.0, 3.0)
		})

func _ga_fitness(g: Dictionary) -> float:
	return (infected_countries.size() * g["speed"]) \
		- (detection_level * 100.0 / maxf(1.0, g["stealth"])) \
		+ (g["resistance"] * patched_countries.size() * 0.5)

func _ga_evolve():
	ga_generation += 1
	ga_population.sort_custom(func(a, b): return _ga_fitness(a) > _ga_fitness(b))
	
	var next: Array = [ga_population[0].duplicate(), ga_population[1].duplicate()]
	
	while next.size() < GA_POP_SIZE:
		# Tournament select parents
		var pa = _ga_pick_parent()
		var pb = _ga_pick_parent()
		# Crossover
		var child = {"speed": pa["speed"], "stealth": pb["stealth"], "resistance": pa["resistance"]}
		# Mutate
		if randf() < GA_MUTATION_RATE:
			child["speed"] = clampf(child["speed"] + randf_range(-0.5, 0.5), 1.0, 10.0)
		if randf() < GA_MUTATION_RATE:
			child["stealth"] = clampf(child["stealth"] + randf_range(-0.5, 0.5), 1.0, 10.0)
		if randf() < GA_MUTATION_RATE:
			child["resistance"] = clampf(child["resistance"] + randf_range(-0.5, 0.5), 1.0, 10.0)
		next.append(child)
	
	ga_population = next
	
	# Apply best genome (GA auto-evolves ON TOP of player upgrades)
	var best = ga_population[0]
	virus_speed = maxf(virus_speed, best["speed"])
	virus_stealth = maxf(virus_stealth, best["stealth"])
	virus_resistance = maxf(virus_resistance, best["resistance"])
	
	log_event("Gen %d evolved — SPD:%.1f STL:%.1f RES:%.1f" % [
		ga_generation, virus_speed, virus_stealth, virus_resistance
	], "yellow")

func _ga_pick_parent() -> Dictionary:
	var best = ga_population[randi() % ga_population.size()]
	var best_f = _ga_fitness(best)
	for i in range(2):
		var c = ga_population[randi() % ga_population.size()]
		var f = _ga_fitness(c)
		if f > best_f:
			best = c
			best_f = f
	return best


# ═════════════════════════════════════════════════════════════════
#                    UPGRADE SYSTEM
# ═════════════════════════════════════════════════════════════════

func buy_upgrade(upgrade_id: String):
	if game_over or not upgrades.has(upgrade_id):
		return
	
	var u = upgrades[upgrade_id]
	
	if u["bought"]:
		show_notification("ALREADY UNLOCKED!", Color(1.0, 0.6, 0.1))
		return
	if u["requires"] != "" and not upgrades[u["requires"]]["bought"]:
		show_notification("UNLOCK PREVIOUS TIER FIRST!", Color(1.0, 0.2, 0.2))
		return
	if resources < u["cost"]:
		show_notification("NEED %d RESOURCES! (have %d)" % [u["cost"], resources], Color(1.0, 0.2, 0.2))
		return
	
	resources -= u["cost"]
	u["bought"] = true
	
	match upgrade_id:
		"email_phishing":
			virus_speed = clampf(virus_speed + 1.5, 1, 10)
			log_event("EMAIL PHISHING: spread chance +15%!", "red")
		"cloud_exploit":
			virus_speed = clampf(virus_speed + 3.0, 1, 10)
			log_event("CLOUD EXPLOIT: spread to multiple countries!", "red")
		"code_obfuscation":
			virus_stealth = clampf(virus_stealth + 3.0, 1, 10)
			log_event("CODE OBFUSCATION: detection slowed 30%!", "cyan")
		"fileless_malware":
			virus_stealth = clampf(virus_stealth + 5.0, 1, 10)
			log_event("FILELESS MALWARE: Bayesian signals halved!", "cyan")
		"registry_persist":
			virus_resistance = clampf(virus_resistance + 3.0, 1, 10)
			log_event("REGISTRY PERSISTENCE: 30% patch resistance!", "green")
		"anti_antivirus":
			virus_resistance = clampf(virus_resistance + 5.0, 1, 10)
			log_event("ANTI-ANTIVIRUS: 60% resistance + re-infection!", "green")
		"keylogger":
			log_event("KEYLOGGER: +2 resources per country per turn!", "purple")
		"ransomware":
			log_event("RANSOMWARE: +5 flat resources per turn!", "purple")
	
	show_notification("UNLOCKED: " + upgrade_id.replace("_", " ").to_upper(), Color(0.3, 0.9, 0.9))
	_update_hud()


# ═════════════════════════════════════════════════════════════════
#                    WIN / LOSE
# ═════════════════════════════════════════════════════════════════

func _check_win_lose():
	if infected_countries.size() == 0 and turn_count > 1 and patched_countries.size() > 0:
		var hidden = patched_countries.pop_back()
		infected_countries.append(hidden)
		log_event("VIRUS HIDDEN! Survived in %s!" % hidden, "purple")
		defense_log_event("CRITICAL ERROR: VIRUS NOT FULLY PURGED", "red")
		
	var rate = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	
	if rate >= WIN_THRESHOLD:
		_end_game(true)
	elif detection_level >= LOSE_THRESHOLD:
		_end_game(false)

func _end_game(won: bool):
	game_over = true
	if end_screen:
		var end_bg = end_screen.get_node("EndBG")
		if end_bg:
			end_bg.texture = load("res://Assets/SCREEN_Win.png") if won else load("res://Assets/SCREEN_Lose.png")
		end_screen.show()


# ═════════════════════════════════════════════════════════════════
#                    HUD UPDATE
# ═════════════════════════════════════════════════════════════════

func _update_hud():
	var rate = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	
	if infection_label:
		infection_label.text = "INFECTED: %d/%d" % [infected_countries.size(), TOTAL_COUNTRIES]
	if detection_label:
		detection_label.text = "DETECTION: %.0f%%" % [detection_level * 100]
	if resources_label:
		resources_label.text = "RESOURCES: %d" % resources
	if traits_label:
		traits_label.text = "SPD: %.0f | STL: %.0f | RES: %.0f" % [
			virus_speed, virus_stealth, virus_resistance]
	if turn_label:
		turn_label.text = "Turn: %d" % turn_count
	if infection_bar:
		infection_bar.scale.x = rate
	if detection_bar:
		detection_bar.scale.x = detection_level


# ═════════════════════════════════════════════════════════════════
#                 NOTIFICATION + EVENT LOG
# ═════════════════════════════════════════════════════════════════

func show_notification(message: String, color: Color = Color.RED):
	if notification_label:
		notification_label.text = message
		notification_label.modulate = color
		notification_label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)
	print("[!] " + message)

func log_event(message: String, color: String = "white"):
	if event_text:
		event_text.append_text("[color=%s]> %s[/color]\n" % [color, message])
	print("> " + message)


# ═════════════════════════════════════════════════════════════════
#                 HOVER DETECTION (same as before)
# ═════════════════════════════════════════════════════════════════

func _check_hover(screen_pos: Vector2):
	if not color_id_image:
		return
	var global_mouse_pos = get_canvas_transform().affine_inverse() * screen_pos
	var local_pos = map_sprite.to_local(global_mouse_pos)
	
	if local_pos.x >= 0 and local_pos.x < color_id_image.get_width() \
		and local_pos.y >= 0 and local_pos.y < color_id_image.get_height():
		var local_pos_i = Vector2i(local_pos)
		var pixel_color = color_id_image.get_pixelv(local_pos_i)
		var html_color = pixel_color.to_html(false)
		
		if country_colors.has(html_color):
			var country = country_colors[html_color]
			hovered_country = country
			
			# Show status next to country name
			var status = " [SUSCEPTIBLE]"
			if country in infected_countries:
				status = " [INFECTED]"
			elif country in patched_countries:
				status = " [PATCHED]"
				
			var prob = country_detection.get(country, 0.0) * 100
			hover_label.text = country + status + "\nP(Infected) = %.0f%%" % prob
			
			if country_hover_textures.has(country):
				hover_sprite.texture = country_hover_textures[country]
				hover_sprite.show()
			else:
				hover_sprite.hide()
			return
	
	hover_label.text = ""
	hover_sprite.hide()
	hovered_country = ""


# ═════════════════════════════════════════════════════════════════
#                 DOT SPAWNING (same as before)
# ═════════════════════════════════════════════════════════════════

func spawn_dot_in_country(country_name: String):
	var bbox = country_bboxes.get(country_name)
	if not bbox:
		return
	var target_color = null
	for html in country_colors:
		if country_colors[html] == country_name:
			target_color = html
			break
	if not target_color:
		return
	for i in range(100):
		var rx = randi_range(bbox[0], bbox[2])
		var ry = randi_range(bbox[1], bbox[3])
		var pcolor = color_id_image.get_pixel(rx, ry).to_html(false)
		if pcolor == target_color:
			dot_renderer.add_dot(Vector2(rx, ry), country_name)
			break

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
		defense_log.append_text("[color=%s]> %s[/color]\n" % [color, msg])
