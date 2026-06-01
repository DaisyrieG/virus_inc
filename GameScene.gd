extends Node2D

# ═══════════════════════════════════════════════════════════════════
# VIRUS INC — GAME SCENE (CORRECTED FULL VERSION)
# ═══════════════════════════════════════════════════════════════════

@onready var map_sprite = $MapSprite
@onready var dot_renderer = $MapSprite/DotRenderer
@onready var hover_label = $CanvasLayer/HoverLabel
@onready var camera = $Camera2D

@onready var infection_label    = $CanvasLayer/HUD/TopPanel/InfectionLabel    if has_node("CanvasLayer/HUD/TopPanel/InfectionLabel")    else null
@onready var detection_label    = $CanvasLayer/HUD/TopPanel/DetectionLabel    if has_node("CanvasLayer/HUD/TopPanel/DetectionLabel")    else null
@onready var resources_label    = $CanvasLayer/HUD/BottomPanel/ResourcesLabel if has_node("CanvasLayer/HUD/BottomPanel/ResourcesLabel") else null
@onready var traits_label       = $CanvasLayer/HUD/BottomPanel/TraitsLabel    if has_node("CanvasLayer/HUD/BottomPanel/TraitsLabel")    else null
@onready var turn_label         = $CanvasLayer/HUD/TopPanel/TurnLabel         if has_node("CanvasLayer/HUD/TopPanel/TurnLabel")         else null
@onready var virus_name_label   = $CanvasLayer/HUD/TopPanel/VirusNameLabel    if has_node("CanvasLayer/HUD/TopPanel/VirusNameLabel")    else null
@onready var infection_bar      = $CanvasLayer/HUD/TopPanel/InfectionBar      if has_node("CanvasLayer/HUD/TopPanel/InfectionBar")      else null
@onready var detection_bar      = $CanvasLayer/HUD/TopPanel/DetectionBar      if has_node("CanvasLayer/HUD/TopPanel/DetectionBar")      else null
@onready var notification_label = $CanvasLayer/HUD/NotificationLabel if has_node("CanvasLayer/HUD/NotificationLabel") else null
@onready var event_text         = $CanvasLayer/HUD/EventLog/EventText if has_node("CanvasLayer/HUD/EventLog/EventText") else null
@onready var end_screen         = $CanvasLayer/EndScreen             if has_node("CanvasLayer/EndScreen")             else null
@onready var crt_monitor        = $CanvasLayer/CRTMonitor            if has_node("CanvasLayer/CRTMonitor")            else null

var color_id_image: Image
var country_colors: Dictionary = {}
var country_bboxes: Dictionary = {}
var hovered_country: String = ""

# ═════════════════════════════════════════════════════════════════
#                        GAME STATE
# ═════════════════════════════════════════════════════════════════
var infected_countries: Array[String] = []
var patched_countries:  Array[String] = []
var country_detection:  Dictionary    = {}
var resources:          int           = 0
var detection_level:    float         = 0.0
var turn_count:         int           = 0

var alert_badge:       TextureRect    = null
var status_label:      Label          = null
var patch_count_label: Label          = null
var defense_log:       RichTextLabel  = null
var total_patches:     int            = 0
var milestones = { "20": false, "50": false, "75": false }
var game_over:    bool = false
var game_started: bool = false

# ── Virus Traits (THESE GET MODIFIED BY UPGRADES) ─────────────────
var virus_speed:      float = 1.0
var virus_stealth:    float = 1.0
var virus_resistance: float = 1.0

var infection_sprites: Dictionary = {}

var ga_population:    Array = []
const GA_POP_SIZE:    int   = 10
const GA_MUTATION_RATE: float = 0.15
var ga_generation:    int   = 0

const TOTAL_COUNTRIES: int   = 7
const WIN_THRESHOLD:   float = 0.90
const LOSE_THRESHOLD:  float = 1.0

# ── Upgrades ──────────────────────────────────────────────────────
var upgrades = {
	"email_phishing":   { "branch": "TRANSMISSION", "cost": 5,  "bought": false, "requires": "" },
	"cloud_exploit":    { "branch": "TRANSMISSION", "cost": 15, "bought": false, "requires": "email_phishing" },
	"code_obfuscation": { "branch": "STEALTH",      "cost": 8,  "bought": false, "requires": "" },
	"fileless_malware": { "branch": "STEALTH",      "cost": 20, "bought": false, "requires": "code_obfuscation" },
	"registry_persist": { "branch": "RESISTANCE",   "cost": 10, "bought": false, "requires": "" },
	"anti_antivirus":   { "branch": "RESISTANCE",   "cost": 25, "bought": false, "requires": "registry_persist" },
	"keylogger":        { "branch": "PAYLOAD",      "cost": 8,  "bought": false, "requires": "" },
	"ransomware":       { "branch": "PAYLOAD",      "cost": 20, "bought": false, "requires": "keylogger" },
}

var world_graph: Dictionary = {
	"CHINA":       { "RUSSIA": 2.0, "INDIA": 1.5, "KAZAKHSTAN": 1.8, "MONGOLIA": 1.0, "PHILIPPINES": 2.5 },
	"RUSSIA":      { "CHINA": 2.0,  "KAZAKHSTAN": 1.2, "MONGOLIA": 1.5 },
	"INDIA":       { "CHINA": 1.5,  "SAUDIARABIA": 3.0 },
	"KAZAKHSTAN":  { "RUSSIA": 1.2, "CHINA": 1.8 },
	"MONGOLIA":    { "RUSSIA": 1.5, "CHINA": 1.0 },
	"PHILIPPINES": { "CHINA": 2.5 },
	"SAUDIARABIA": { "INDIA": 3.0 },
}

var is_dragging:   bool    = false
var last_mouse_pos: Vector2
var hover_sprite:  Sprite2D
var country_hover_images: Dictionary = {
	"CHINA":       "res://Assets/ASIAMAP_REALISTIC_CHINA.png",
	"INDIA":       "res://Assets/ASIAMAP_REALISTIC_INDIA.png",
	"RUSSIA":      "res://Assets/ASIAMAP_REALISTIC_RUSSIA.png",
	"MONGOLIA":    "res://Assets/ASIAMAP_REALISTIC_MONGOLIA.png",
	"KAZAKHSTAN":  "res://Assets/ASIAMAP_REALISTIC_MAP_KAZAKHSTAN.png",
	"PHILIPPINES": "res://Assets/ASIAMAP_REALISTIC_MAP_PHILIPPINES.png",
	"SAUDIARABIA": "res://Assets/ASIAMAP_REALISTIC_MAP_SAUDIARABIA.png",
}
var country_hover_textures: Dictionary = {}

# ═════════════════════════════════════════════════════════════════
#                           READY
# ═════════════════════════════════════════════════════════════════

func _ready():
	var color_id_tex = load("res://Assets/ColorIDMap.png")
	color_id_image = color_id_tex.get_image()

	var file = FileAccess.open("res://Assets/country_data.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		for country_name in data.keys():
			var rgb = data[country_name]["color"]
			var c   = Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]))
			country_colors[c.to_html(false)] = country_name
			country_bboxes[country_name]     = data[country_name]["bbox"]

	for country in world_graph.keys():
		country_detection[country] = 0.05

	for country in country_hover_images:
		var tex = load(country_hover_images[country])
		if tex:
			country_hover_textures[country] = tex

	hover_sprite          = Sprite2D.new()
	hover_sprite.centered = false
	map_sprite.add_child(hover_sprite)
	map_sprite.move_child(hover_sprite, 0)
	hover_sprite.hide()

	_ga_init_population()
	_setup_dynamic_ui()
	_align_crt_monitor()

	if end_screen:
		end_screen.hide()
	if virus_name_label:
		virus_name_label.text = Global.virus_name

	var dot_timer          = Timer.new()
	dot_timer.wait_time    = 0.05
	dot_timer.autostart    = true
	dot_timer.timeout.connect(_on_dot_tick)
	add_child(dot_timer)

	var turn_timer         = Timer.new()
	turn_timer.wait_time   = 3.5
	turn_timer.autostart   = true
	turn_timer.timeout.connect(_on_turn_tick)
	add_child(turn_timer)

	log_event("Click a country to start the infection...", "yellow")
	_update_hud()


# ═════════════════════════════════════════════════════════════════
#                     CRT MONITOR ALIGNMENT
# ═════════════════════════════════════════════════════════════════
func _align_crt_monitor():
	if not crt_monitor: return
	var bg = crt_monitor.get_node_or_null("ComputerBG")
	var overlay = crt_monitor.get_node_or_null("ComputerBG/ScreenOverlay")
	if bg and overlay:
		# Lock the background to exactly 1200x800 and center it programmatically
		bg.custom_minimum_size = Vector2(1200, 800)
		bg.anchor_left = 0.5
		bg.anchor_right = 0.5
		bg.anchor_top = 0.5
		bg.anchor_bottom = 0.5
		bg.offset_left = -600
		bg.offset_right = 600
		bg.offset_top = -400
		bg.offset_bottom = 400
		
		# Align the screen overlay precisely to fit the CRT monitor asset's black screen
		overlay.anchor_left = 0.0
		overlay.anchor_right = 1.0
		overlay.anchor_top = 0.0
		overlay.anchor_bottom = 1.0
		overlay.offset_left = 240
		overlay.offset_top = 60
		overlay.offset_right = -210
		overlay.offset_bottom = -390
		
		# Ensure the GridContainer fits inside perfectly
		var grid = overlay.get_node_or_null("GridContainer")
		if grid:
			grid.anchor_left = 0.5
			grid.anchor_right = 0.5
			grid.anchor_top = 0.5
			grid.anchor_bottom = 0.5
			grid.offset_left = -350
			grid.offset_right = 350
			grid.offset_top = -120
			grid.offset_bottom = 180



# ═════════════════════════════════════════════════════════════════
#                           INPUT
# ═════════════════════════════════════════════════════════════════

func _unhandled_input(event):
	if game_over:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging    = true
				last_mouse_pos = event.position
				if hovered_country != "":
					if not game_started:
						_start_infection(hovered_country)
					else:
						if crt_monitor and not crt_monitor.visible:
							crt_monitor.show()
							_refresh_terminal_buttons()
			else:
				is_dragging = false

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.1
			camera.zoom  = camera.zoom.clamp(Vector2(1, 1), Vector2(4, 4))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom /= 1.1
			camera.zoom  = camera.zoom.clamp(Vector2(1, 1), Vector2(4, 4))

	elif event is InputEventMouseMotion:
		if is_dragging:
			camera.position -= (event.position - last_mouse_pos) / camera.zoom
			last_mouse_pos   = event.position
		_check_hover(event.position)

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: buy_upgrade("email_phishing")   if not upgrades["email_phishing"]["bought"]   else buy_upgrade("cloud_exploit")
			KEY_2: buy_upgrade("code_obfuscation") if not upgrades["code_obfuscation"]["bought"] else buy_upgrade("fileless_malware")
			KEY_3: buy_upgrade("registry_persist") if not upgrades["registry_persist"]["bought"] else buy_upgrade("anti_antivirus")
			KEY_4: buy_upgrade("keylogger")        if not upgrades["keylogger"]["bought"]        else buy_upgrade("ransomware")


# ═════════════════════════════════════════════════════════════════
#                       START INFECTION
# ═════════════════════════════════════════════════════════════════

func _start_infection(country: String):
	game_started = true
	infected_countries.append(country)
	resources = 10
	log_event("%s deployed in %s!" % [Global.virus_name, country], "red")
	show_notification("VIRUS DEPLOYED: " + country, Color(0.9, 0.15, 0.15))
	_update_map_visuals()
	_update_hud()


# ═════════════════════════════════════════════════════════════════
#                   DOT TICK (visual — every 0.05 s)
# ═════════════════════════════════════════════════════════════════

func _on_dot_tick():
	if infected_countries.size() == 0 or game_over:
		return
		
	# Spawn multiple dots per tick so the virus name fills the country much faster visually
	for i in range(4):
		var random_country = infected_countries[randi() % infected_countries.size()]
		spawn_dot_in_country(random_country)


# ═════════════════════════════════════════════════════════════════
#                 MAIN GAME LOOP — EVERY 3.5 s
# ═════════════════════════════════════════════════════════════════

func _on_turn_tick():
	if not game_started or game_over:
		return

	turn_count += 1

	# ── VIRUS SIDE ────────────────────────────────────────────────
	_ga_evolve()
	_dijkstra_spread()

	var income = infected_countries.size()
	if upgrades["keylogger"]["bought"]:
		income += infected_countries.size() * 2
	if upgrades["ransomware"]["bought"]:
		income += 5
	resources += income

	# ── DETECTION RISES ───────────────────────────────────────────
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.06, 0.0, 0.6)
	if upgrades["code_obfuscation"]["bought"]:
		stealth_mod *= 0.75
	if upgrades["fileless_malware"]["bought"]:
		stealth_mod *= 0.55
	var spread_factor = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	detection_level   = clampf(detection_level + (0.012 + spread_factor * 0.015) * stealth_mod, 0.0, 1.0)

	_bayesian_defense()

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

	print("[Turn %d] Infected: %d/%d | Detection: %.0f%% | Resources: %d | SPD:%.1f STL:%.1f RES:%.1f" % [
		turn_count, infected_countries.size(), TOTAL_COUNTRIES,
		detection_level * 100, resources,
		virus_speed, virus_stealth, virus_resistance
	])


# ═════════════════════════════════════════════════════════════════
#                    DIJKSTRA SPREAD
# ═════════════════════════════════════════════════════════════════

func _dijkstra_spread():
	if infected_countries.size() == 0:
		return

	# Spread chance scales with Speed
	# Base 28% chance allows for consistent but not overwhelming early spread
	var spread_chance = 0.28 + (virus_speed - 1.0) * 0.05

	if randf() > spread_chance:
		defense_log_event("Spread attempt blocked...", "gray")
		return

	var result    = Dijkstra.calculate_shortest_paths(
		world_graph, infected_countries,
		virus_speed, country_detection, patched_countries
	)
	var distances = result["distances"]
	var previous  = result["previous"]
	# BUG FIX: Pass patched_countries so Dijkstra excludes them from spread targets.
	# Without this, patched countries appear as valid spread targets and bypass the
	# patched check, causing double-logic conflicts and incorrect spread routing.
	var targets   = Dijkstra.get_spread_targets(distances, infected_countries, patched_countries)

	if targets.size() == 0:
		return

	var max_spread = 1
	if virus_speed >= 5.0: max_spread = 2
	if virus_speed >= 9.0: max_spread = 3
	if upgrades["cloud_exploit"]["bought"]:
		max_spread += 1

	var spread_count = 0
	for target_data in targets:
		if spread_count >= max_spread:
			break

		var country = target_data["country"]
		if country in infected_countries:
			continue

		if country in patched_countries:
			var reinfect_chance = virus_resistance * 0.08
			if not upgrades["anti_antivirus"]["bought"]:
				reinfect_chance *= 0.5
			if randf() > reinfect_chance:
				continue
			patched_countries.erase(country)
			log_event("RE-INFECTED %s! Broke through defenses!" % country, "red")
			show_notification("RE-INFECTED: " + country + "!", Color(1.0, 0.3, 0.1))

		infected_countries.append(country)
		spread_count += 1

		var spread_from = previous.get(country, "unknown")
		log_event("%s spread: %s → %s" % [Global.virus_name, spread_from, country], "red")
		show_notification("INFECTED: " + country, Color(0.9, 0.15, 0.15))
		resources += 3
		_update_map_visuals()


# ═════════════════════════════════════════════════════════════════
#         BAYESIAN DEFENSE — CORRECTED VERSION
# ═════════════════════════════════════════════════════════════════

const PATCH_THRESHOLD:         float = 0.82
const P_SIGNAL_INFECTED:       float = 0.78
const P_SIGNAL_NOT_INFECTED:   float = 0.18
const BAYES_DECAY:             float = 0.10

func _bayesian_defense():
	var best_target    = ""
	var best_posterior = 0.0

	for country in world_graph.keys():
		if country in patched_countries:
			country_detection[country] = maxf(0.01, country_detection.get(country, 0.01) - 0.02)
			continue

		# ── OBSERVE: signal fires this turn? ──────────────────
		var signal_strength = _observe_signal(country)
		var signal_fired: bool = randf() < signal_strength

		# ── BAYES UPDATE ──────────────────────────────────────
		var prior   = country_detection.get(country, 0.05)
		var p_s_i:  float
		var p_s_ni: float

		if signal_fired:
			p_s_i  = P_SIGNAL_INFECTED
			p_s_ni = P_SIGNAL_NOT_INFECTED
		else:
			p_s_i  = 1.0 - P_SIGNAL_INFECTED
			p_s_ni = 1.0 - P_SIGNAL_NOT_INFECTED

		var numerator = p_s_i  * prior
		var evidence  = numerator + p_s_ni * (1.0 - prior)
		var posterior = numerator / evidence if evidence > 0.001 else prior

		posterior = clampf(posterior, 0.01, 0.99)

		if country not in infected_countries:
			posterior = maxf(0.01, posterior - BAYES_DECAY)

		country_detection[country] = posterior

		if posterior >= 0.40 and country in infected_countries:
			defense_log_event("Scanning %s... P=%.0f%%" % [country, posterior * 100], "yellow")

		if country in infected_countries and posterior > best_posterior:
			best_posterior = posterior
			best_target    = country

	if best_target == "" or best_posterior < PATCH_THRESHOLD:
		return

	var resist_chance = clampf(virus_resistance * 0.06, 0.0, 0.55)
	if upgrades["registry_persist"]["bought"]:
		resist_chance += 0.15
	if upgrades["anti_antivirus"]["bought"]:
		resist_chance += 0.25

	if randf() < resist_chance:
		log_event("Defense tried to patch %s — VIRUS RESISTED! (%.0f%%)" % [
			best_target, resist_chance * 100], "orange")
		defense_log_event("[!] %s resisted patch (%.0f%%)" % [best_target, resist_chance * 100], "orange")
		show_notification("PATCH RESISTED: " + best_target, Color(1.0, 0.6, 0.1))
		country_detection[best_target] = 0.30
		return

	infected_countries.erase(best_target)
	patched_countries.append(best_target)
	total_patches += 1
	country_detection[best_target] = 0.05

	defense_log_event("[✓] PATCHED %s! P was %.0f%%" % [best_target, best_posterior * 100], "lime")
	detection_level = clampf(detection_level + 0.04, 0.0, 1.0)

	_clear_dots_in_country(best_target)
	_update_map_visuals()

	log_event("SECURED: %s — Bayesian AI patched it! (P=%.0f%%)" % [
		best_target, best_posterior * 100], "green")
	show_notification("COUNTRY SECURED: " + best_target, Color(0.2, 0.9, 0.3))

	if infected_countries.size() == 0:
		log_event("ALL COUNTRIES PATCHED — spread faster or upgrade!", "red")
		show_notification("ALL INFECTIONS CLEARED!", Color(1, 0.2, 0.2))


func _observe_signal(country: String) -> float:
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.06, 0.0, 0.65)
	if upgrades["fileless_malware"]["bought"]:
		stealth_mod *= 0.45
	if upgrades["code_obfuscation"]["bought"]:
		stealth_mod *= 0.65

	if country in infected_countries:
		return randf_range(0.50, 0.95) * stealth_mod
	else:
		return randf_range(0.0, 0.05)


func _clear_dots_in_country(_country: String):
	dot_renderer.clear_dots_in_country(_country)


# ═════════════════════════════════════════════════════════════════
#              MAP VISUALS
# ═════════════════════════════════════════════════════════════════

func _update_map_visuals():
	for country in world_graph.keys():
		if not infection_sprites.has(country):
			var spr       = Sprite2D.new()
			spr.centered  = false
			spr.position  = Vector2.ZERO
			# BUG FIX: Use cached textures from country_hover_textures instead of
			# calling load() inside this hot-path function. load() is synchronous
			# and re-parses the resource every call — causes hitches on spread events.
			if country_hover_textures.has(country):
				spr.texture = country_hover_textures[country]
			spr.visible = false
			map_sprite.add_child(spr)
			infection_sprites[country] = spr

		var spr = infection_sprites[country]
		if country in infected_countries:
			spr.modulate = Color(1.0, 0.15, 0.15, 0.70)
			spr.visible  = true
		elif country in patched_countries:
			spr.modulate = Color(0.2, 0.5, 1.0, 0.55)
			spr.visible  = true
		else:
			spr.visible  = false

	dot_renderer.queue_redraw()


# ═════════════════════════════════════════════════════════════════
#                    GENETIC ALGORITHM
# ═════════════════════════════════════════════════════════════════

func _ga_init_population():
	ga_population.clear()
	# BUG FIX: Initialize with random diversity so selection pressure works from gen-1.
	# Starting all genomes at {1,1,1} means zero variation — no evolution happens early.
	for i in range(GA_POP_SIZE):
		ga_population.append({
			"speed":      randf_range(1.0, 4.0),
			"stealth":    randf_range(1.0, 4.0),
			"resistance": randf_range(1.0, 4.0)
		})

func _ga_fitness(g: Dictionary) -> float:
	return (infected_countries.size() * g["speed"]) \
		- (detection_level * 100.0 / maxf(1.0, g["stealth"])) \
		+ (g["resistance"] * patched_countries.size() * 0.5)

func _ga_evolve():
	ga_generation += 1
	
	# Pre-compute fitness to optimize sorting
	var scored = []
	for g in ga_population:
		scored.append({"genome": g, "fit": _ga_fitness(g)})
	scored.sort_custom(func(a, b): return a["fit"] > b["fit"])
	
	for i in range(ga_population.size()):
		ga_population[i] = scored[i]["genome"]
	
	var next: Array = [ga_population[0].duplicate(), ga_population[1].duplicate()]
	
	# Player agency: Buying upgrades increases mutation rate for faster evolution!
	var player_mutation_mod = 0.0
	for key in upgrades:
		if upgrades[key]["bought"]:
			player_mutation_mod += 0.05
	var effective_mutation = clampf(GA_MUTATION_RATE + player_mutation_mod, 0.1, 0.6)
	
	while next.size() < GA_POP_SIZE:
		var pa = _ga_pick_parent()
		var pb = _ga_pick_parent()
		
		# Proper single-point crossover
		var point = randi_range(1, 2)
		var keys = ["speed", "stealth", "resistance"]
		var child = {}
		for i in range(keys.size()):
			child[keys[i]] = pa[keys[i]] if i < point else pb[keys[i]]
			
		if randf() < effective_mutation:
			child["speed"] = clampf(child["speed"] + randf_range(-0.05, 0.12), 1.0, 10.0)
		if randf() < effective_mutation:
			child["stealth"] = clampf(child["stealth"] + randf_range(-0.05, 0.12), 1.0, 10.0)
		if randf() < effective_mutation:
			child["resistance"] = clampf(child["resistance"] + randf_range(-0.05, 0.12), 1.0, 10.0)
		next.append(child)

	ga_population = next

	if ga_generation % 5 == 0:
		var best      = ga_population[0]
		virus_speed      = maxf(virus_speed,      best["speed"])
		virus_stealth    = maxf(virus_stealth,    best["stealth"])
		virus_resistance = maxf(virus_resistance, best["resistance"])
		log_event("Gen %d — virus mutated! SPD:%.1f STL:%.1f RES:%.1f" % [
			ga_generation, virus_speed, virus_stealth, virus_resistance
		], "yellow")

func _ga_pick_parent() -> Dictionary:
	var best   = ga_population[randi() % ga_population.size()]
	var best_f = _ga_fitness(best)
	for i in range(2):
		var c = ga_population[randi() % ga_population.size()]
		var f = _ga_fitness(c)
		if f > best_f:
			best   = c
			best_f = f
	return best


# ═════════════════════════════════════════════════════════════════
#                      UPGRADE SYSTEM — CORRECTED
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

	resources  -= u["cost"]
	u["bought"] = true

	# ── THESE ARE THE ACTUAL UPGRADES THAT MODIFY GAME TRAITS ──
	match upgrade_id:
		"email_phishing":
			virus_speed = clampf(virus_speed + 1.5, 1, 10)
			log_event("EMAIL PHISHING unlocked! SPD +1.5", "red")
		"cloud_exploit":
			virus_speed = clampf(virus_speed + 3.0, 1, 10)
			log_event("CLOUD EXPLOIT unlocked! SPD +3.0 (multi-spread)", "red")
		"code_obfuscation":
			virus_stealth = clampf(virus_stealth + 3.0, 1, 10)
			log_event("CODE OBFUSCATION unlocked! STL +3.0 (detection -30%)", "cyan")
		"fileless_malware":
			virus_stealth = clampf(virus_stealth + 5.0, 1, 10)
			log_event("FILELESS MALWARE unlocked! STL +5.0 (signals halved)", "cyan")
		"registry_persist":
			virus_resistance = clampf(virus_resistance + 3.0, 1, 10)
			log_event("REGISTRY PERSIST unlocked! RES +3.0 (30% patch block)", "green")
		"anti_antivirus":
			virus_resistance = clampf(virus_resistance + 5.0, 1, 10)
			log_event("ANTI-ANTIVIRUS unlocked! RES +5.0 (60% resist + re-infect)", "green")
		"keylogger":
			log_event("KEYLOGGER unlocked! +2 res per country/turn", "purple")
		"ransomware":
			log_event("RANSOMWARE unlocked! +5 flat res/turn", "purple")

	show_notification("✓ UNLOCKED: " + upgrade_id.replace("_", " ").to_upper(), Color(0.3, 0.9, 0.9))
	_update_hud()
	_refresh_terminal_buttons()
	if crt_monitor:
		await get_tree().create_timer(0.4).timeout
		crt_monitor.hide()

func _refresh_terminal_buttons():
	var map = {
		"BtnEmail":       ["email_phishing",   "> EMAIL PHISHING"],
		"BtnCloud":       ["cloud_exploit",    "> CLOUD EXPLOIT"],
		"BtnObfuscation": ["code_obfuscation", "> CODE OBFUSCATION"],
		"BtnFileless":    ["fileless_malware", "> FILELESS MALWARE"],
		"BtnRegistry":    ["registry_persist", "> REGISTRY PERSIST"],
		"BtnAntiAV":      ["anti_antivirus",   "> ANTI-ANTIVIRUS"],
		"BtnKeylogger":   ["keylogger",        "> KEYLOGGER"],
		"BtnRansomware":  ["ransomware",       "> RANSOMWARE"],
	}
	for btn_name in map:
		var data   = map[btn_name]
		var upg_id = data[0]
		var label  = data[1]
		var upg    = upgrades[upg_id]
		var cost   = upg["cost"]
		var bought = upg["bought"]
		var afford = resources >= cost

		var base  = "CanvasLayer/CRTMonitor/ComputerBG/ScreenOverlay/GridContainer"
		var paths = [
			base + "/VBoxTrans/"   + btn_name,
			base + "/VBoxStealth/" + btn_name,
			base + "/VBoxResist/"  + btn_name,
			base + "/VBoxPayload/" + btn_name,
		]
		for path in paths:
			if has_node(path):
				var btn = get_node(path)
				if bought:
					btn.text = label + " [OWNED]"
					btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
				elif not afford:
					btn.text = (label + " [%d] (need %d more)") % [cost, cost - resources]
					btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
				else:
					btn.text = label + " [%d]" % cost
					btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
				break


# ═════════════════════════════════════════════════════════════════
#                       WIN / LOSE
# ═════════════════════════════════════════════════════════════════

func _check_win_lose():
	var rate = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	# If all countries patched and 0 infected — player loses (virus contained)
	# Also, if virus is fully eradicated before infecting all, it's a loss (no soft-lock)
	if infected_countries.size() == 0 and turn_count > 2:
		_end_game(false)
		return
	if rate >= WIN_THRESHOLD:
		_end_game(true)
		return
	if detection_level >= LOSE_THRESHOLD:
		_end_game(false)

func _end_game(won: bool):
	game_over = true

	var result_img = "res://Assets/SCREEN_Win.png" if won else "res://Assets/SCREEN_Lose.png"

	if end_screen:
		var end_bg = end_screen.get_node_or_null("EndBG")
		if end_bg:
			end_bg.texture      = load(result_img)
			end_bg.anchor_left  = 0.0; end_bg.anchor_top    = 0.0
			end_bg.anchor_right = 1.0; end_bg.anchor_bottom = 1.0
			end_bg.offset_left  = 0;   end_bg.offset_top    = 0
			end_bg.offset_right = 0;   end_bg.offset_bottom = 0
			end_bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			end_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		end_screen.show()
	else:
		var overlay         = TextureRect.new()
		overlay.texture     = load(result_img)
		overlay.anchor_left = 0.0; overlay.anchor_top    = 0.0
		overlay.anchor_right= 1.0; overlay.anchor_bottom = 1.0
		overlay.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		$CanvasLayer.add_child(overlay)

	if won:
		log_event("🏆 %s CONQUERED THE NETWORK! 🏆" % Global.virus_name, "red")
	else:
		log_event("🛑 CYBERSECURITY AI CONTAINED THE THREAT 🛑", "green")

	# Add a dynamic stats overlay to the end screen
	var stats_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.9)
	style.border_color = Color(0.8, 0.2, 0.2) if won else Color(0.2, 0.8, 0.2)
	style.border_width_left = 2; style.border_width_top = 2
	style.border_width_right = 2; style.border_width_bottom = 2
	stats_panel.add_theme_stylebox_override("panel", style)
	stats_panel.anchor_left = 0.5; stats_panel.anchor_top = 0.70
	stats_panel.anchor_right = 0.5; stats_panel.anchor_bottom = 0.70
	stats_panel.offset_left = -280; stats_panel.offset_right = 280
	stats_panel.offset_top = -30; stats_panel.offset_bottom = 30
	
	var stats_label = Label.new()
	stats_label.text = "Turn %d | Infected: %d/%d | Detection: %.0f%%\nResources: %d | SPD: %.1f | STL: %.1f | RES: %.1f" % [
		turn_count, infected_countries.size(), TOTAL_COUNTRIES, detection_level * 100,
		resources, virus_speed, virus_stealth, virus_resistance
	]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_panel.add_child(stats_label)
	$CanvasLayer.add_child(stats_panel)

	var btn_container = HBoxContainer.new()
	btn_container.anchor_left   = 0.5;  btn_container.anchor_top    = 0.82
	btn_container.anchor_right  = 0.5;  btn_container.anchor_bottom = 0.82
	btn_container.offset_left   = -180; btn_container.offset_right  = 180
	btn_container.offset_top    = -25;  btn_container.offset_bottom = 25
	btn_container.add_theme_constant_override("separation", 20)
	$CanvasLayer.add_child(btn_container)

	var btn_restart = Button.new()
	btn_restart.text = "↺  PLAY AGAIN"
	btn_restart.custom_minimum_size = Vector2(160, 44)
	btn_restart.add_theme_color_override("font_color", Color(0, 1, 0.4))
	btn_restart.pressed.connect(func(): get_tree().reload_current_scene())
	btn_container.add_child(btn_restart)

	var btn_menu = Button.new()
	btn_menu.text = "⌂  MAIN MENU"
	btn_menu.custom_minimum_size = Vector2(160, 44)
	btn_menu.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	btn_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://MainMenu.tscn"))
	btn_container.add_child(btn_menu)


# ═════════════════════════════════════════════════════════════════
#                        HUD UPDATE
# ═════════════════════════════════════════════════════════════════

func _update_hud():
	var rate = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	if infection_label:    infection_label.text    = "INFECTED: %d/%d" % [infected_countries.size(), TOTAL_COUNTRIES]
	if detection_label:    detection_label.text    = "DETECTION: %.0f%%" % [detection_level * 100]
	if resources_label:    resources_label.text    = "RESOURCES: %d" % resources
	if traits_label:       traits_label.text       = "SPD: %.1f | STL: %.1f | RES: %.1f" % [virus_speed, virus_stealth, virus_resistance]
	if turn_label:         turn_label.text         = "Turn: %d" % turn_count
	if infection_bar:
		var tween = create_tween()
		tween.tween_property(infection_bar, "scale:x", rate, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if detection_bar:
		var tween = create_tween()
		tween.tween_property(detection_bar, "scale:x", detection_level, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ═════════════════════════════════════════════════════════════════
#                  NOTIFICATION + EVENT LOG
# ═════════════════════════════════════════════════════════════════

func show_notification(message: String, color: Color = Color.RED):
	if notification_label:
		notification_label.text       = message
		notification_label.modulate   = color
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
#                     HOVER DETECTION
# ═════════════════════════════════════════════════════════════════

func _check_hover(screen_pos: Vector2):
	if not color_id_image:
		return
	var global_mouse_pos = get_canvas_transform().affine_inverse() * screen_pos
	var local_pos        = map_sprite.to_local(global_mouse_pos)

	if local_pos.x >= 0 and local_pos.x < color_id_image.get_width() \
	and local_pos.y >= 0 and local_pos.y < color_id_image.get_height():
		var local_pos_i = Vector2i(local_pos)
		var pixel_color = color_id_image.get_pixelv(local_pos_i)
		var html_color  = pixel_color.to_html(false)

		if country_colors.has(html_color):
			var country    = country_colors[html_color]
			hovered_country = country
			var prob   = country_detection.get(country, 0.0)
			var status = " [SUSCEPTIBLE]"
			if country in infected_countries:
				status = " [INFECTED] P(det)=%.0f%%" % (prob * 100)
			elif country in patched_countries:
				status = " [PATCHED]"
			hover_label.text = country + status + "\nP(Infected) = %.0f%%" % (prob * 100)
			if country_hover_textures.has(country):
				hover_sprite.texture = country_hover_textures[country]
				hover_sprite.show()
			else:
				hover_sprite.hide()
			return

	hover_label.text = ""
	hover_sprite.hide()
	hovered_country  = ""


# ═════════════════════════════════════════════════════════════════
#                      DOT SPAWNING
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
		var rx     = randi_range(bbox[0], bbox[2])
		var ry     = randi_range(bbox[1], bbox[3])
		var pcolor = color_id_image.get_pixel(rx, ry).to_html(false)
		if pcolor == target_color:
			dot_renderer.add_dot(Vector2(rx, ry), country_name)
			break


# ═════════════════════════════════════════════════════════════════
#                    UI BUTTON HANDLERS
# ═════════════════════════════════════════════════════════════════

func _on_btn_speed_pressed():
	if crt_monitor: crt_monitor.show()

func _on_btn_stealth_pressed():
	if crt_monitor: crt_monitor.show()

func _on_btn_resistance_pressed():
	if crt_monitor: crt_monitor.show()

func _on_email_phishing_pressed():   buy_upgrade("email_phishing")
func _on_cloud_exploit_pressed():    buy_upgrade("cloud_exploit")
func _on_code_obfuscation_pressed(): buy_upgrade("code_obfuscation")
func _on_fileless_malware_pressed(): buy_upgrade("fileless_malware")
func _on_registry_persist_pressed(): buy_upgrade("registry_persist")
func _on_anti_antivirus_pressed():   buy_upgrade("anti_antivirus")
func _on_keylogger_pressed():        buy_upgrade("keylogger")
func _on_ransomware_pressed():       buy_upgrade("ransomware")


# ═════════════════════════════════════════════════════════════════
#                    DEFENSE UI
# ═════════════════════════════════════════════════════════════════

func _setup_dynamic_ui():
	var dp = Panel.new()
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.03, 0.95)
	style.border_color = Color(0.0, 0.8, 0.4, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	dp.add_theme_stylebox_override("panel", style)
	
	dp.anchor_left = 1.0
	dp.anchor_right = 1.0
	dp.anchor_top = 0.0
	dp.anchor_bottom = 0.0
	dp.offset_left = -380
	dp.offset_top = 20
	dp.offset_right = -20
	dp.offset_bottom = 340
	
	var title = Label.new()
	title.text = "BAYESIAN DEFENSE AI"
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_top = 10
	title.anchor_right = 1.0
	dp.add_child(title)
	
	var sep1 = ColorRect.new()
	sep1.color = Color(0.0, 0.8, 0.4, 0.5)
	sep1.offset_left = 15
	sep1.offset_top = 40
	sep1.offset_right = 345
	sep1.offset_bottom = 42
	dp.add_child(sep1)
	
	var lbl_status_title = Label.new()
	lbl_status_title.text = "SYSTEM STATUS:"
	lbl_status_title.offset_left = 15
	lbl_status_title.offset_top = 55
	lbl_status_title.add_theme_color_override("font_color", Color(0.6, 0.8, 0.7))
	dp.add_child(lbl_status_title)
	
	status_label = Label.new()
	status_label.text = "🟢 DORMANT"
	status_label.offset_left = 150
	status_label.offset_top = 55
	status_label.add_theme_color_override("font_color", Color.WHITE)
	dp.add_child(status_label)
	
	var lbl_patch_title = Label.new()
	lbl_patch_title.text = "DEPLOYED PATCHES:"
	lbl_patch_title.offset_left = 15
	lbl_patch_title.offset_top = 85
	lbl_patch_title.add_theme_color_override("font_color", Color(0.6, 0.8, 0.7))
	dp.add_child(lbl_patch_title)
	
	patch_count_label = Label.new()
	patch_count_label.text = "0"
	patch_count_label.offset_left = 180
	patch_count_label.offset_top = 85
	patch_count_label.add_theme_color_override("font_color", Color(0, 1, 0))
	dp.add_child(patch_count_label)
	
	var sep2 = ColorRect.new()
	sep2.color = Color(0.0, 0.8, 0.4, 0.5)
	sep2.offset_left = 15
	sep2.offset_top = 115
	sep2.offset_right = 345
	sep2.offset_bottom = 117
	dp.add_child(sep2)
	
	defense_log = RichTextLabel.new()
	defense_log.bbcode_enabled = true
	defense_log.scroll_following = true
	defense_log.offset_left = 15
	defense_log.offset_top = 125
	defense_log.offset_right = 345
	defense_log.offset_bottom = 310
	dp.add_child(defense_log)
	
	var canvas = $CanvasLayer if has_node("CanvasLayer") else self
	canvas.add_child(dp)

func _update_defense_panel():
	if not status_label:
		return
	var det_pct = int(detection_level * 100)
	if detection_level >= 0.75:
		status_label.text = "🔴 MAX RESPONSE [%d%%]" % det_pct
		status_label.add_theme_color_override("font_color", Color.RED)
	elif detection_level >= 0.50:
		status_label.text = "🟠 ACTIVE HUNTING [%d%%]" % det_pct
		status_label.add_theme_color_override("font_color", Color.ORANGE)
	elif detection_level >= 0.20:
		status_label.text = "🟡 SCANNING... [%d%%]" % det_pct
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		status_label.text = "🟢 DORMANT [%d%%]" % det_pct
		status_label.add_theme_color_override("font_color", Color.WHITE)
	patch_count_label.text = str(total_patches)

func defense_log_event(msg: String, color: String = "white"):
	if defense_log:
		var time = Time.get_time_string_from_system()
		defense_log.append_text("[color=gray][%s][/color] [color=%s]%s[/color]\n" % [time, color, msg])
