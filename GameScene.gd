extends Node2D

# ═══════════════════════════════════════════════════════════════════
# GAME SCENE — MAIN GAME CONTROLLER
# ═══════════════════════════════════════════════════════════════════
# Orchestrates: Dijkstra spread, Genetic Algorithm evolution,
# Bayesian Defense AI, resource economy, and win/lose conditions.
# ═══════════════════════════════════════════════════════════════════

# ── Existing Scene References ─────────────────────────────────────
@onready var map_sprite = $MapSprite
@onready var dot_renderer = $MapSprite/DotRenderer
@onready var hover_label = $CanvasLayer/HoverLabel
@onready var camera = $Camera2D

# ── HUD References (add these nodes to your CanvasLayer) ──────────
# You'll need to create these UI nodes in the editor:
@onready var infection_label = $CanvasLayer/HUD/InfectionLabel
@onready var detection_label = $CanvasLayer/HUD/DetectionLabel
@onready var resources_label = $CanvasLayer/HUD/ResourcesLabel
@onready var traits_label = $CanvasLayer/HUD/TraitsLabel
@onready var infection_bar = $CanvasLayer/HUD/InfectionBar
@onready var detection_bar = $CanvasLayer/HUD/DetectionBar
@onready var virus_name_label = $CanvasLayer/HUD/VirusNameLabel
@onready var turn_label = $CanvasLayer/HUD/TurnLabel
@onready var end_screen = $CanvasLayer/EndScreen

# ── Map Data ──────────────────────────────────────────────────────
var color_id_image: Image
var country_colors: Dictionary = {}
var country_bboxes: Dictionary = {}
var hovered_country: String = ""

# ── Game State ────────────────────────────────────────────────────
var infected_countries: Array[String] = []
var patched_countries: Array[String] = []
var country_detection: Dictionary = {}    # country → Bayesian probability (0-1)
var resources: int = 10
var detection_level: float = 0.0          # Global detection meter (0-1)
var turn_count: int = 0
var game_over: bool = false

# ── Virus Traits (evolved by Genetic Algorithm) ───────────────────
var virus_speed: float = 1.0       # 1-10: higher = faster spread
var virus_stealth: float = 1.0     # 1-10: higher = less detection
var virus_resistance: float = 1.0  # 1-10: higher = harder to patch

# ── Genetic Algorithm Population ──────────────────────────────────
var ga_population: Array = []
var ga_population_size: int = 10
var ga_mutation_rate: float = 0.15
var ga_generation: int = 0

# ── Win/Lose Thresholds ──────────────────────────────────────────
const WIN_THRESHOLD: float = 0.90     # Infect 90% of countries to win
const LOSE_THRESHOLD: float = 1.0     # Detection hits 100% = lose
const TOTAL_COUNTRIES: int = 7        # Total countries in your map

# ── Upgrade Costs ─────────────────────────────────────────────────
const SPEED_COST: int = 5
const STEALTH_COST: int = 8
const RESISTANCE_COST: int = 10

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

# ── Camera / Interaction ──────────────────────────────────────────
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


# ═══════════════════════════════════════════════════════════════════
# READY
# ═══════════════════════════════════════════════════════════════════

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
	
	# Initialize Bayesian priors for all countries
	for country in world_graph.keys():
		country_detection[country] = 0.05  # Low initial suspicion
	
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
	
	# Initialize Genetic Algorithm population
	_ga_init_population()
	
	# Hide end screen
	if end_screen:
		end_screen.hide()
	
	# Update virus name label
	if virus_name_label:
		virus_name_label.text = get_node("/root/Global").virus_name
	
	# ── GAME TICK TIMER ───────────────────────────────────────────
	# Main game loop runs every 0.05s (visual dots)
	var dot_timer = Timer.new()
	dot_timer.wait_time = 0.05
	dot_timer.autostart = true
	dot_timer.timeout.connect(_on_dot_tick)
	add_child(dot_timer)
	
	# Turn timer: every 2 seconds, run a full game turn
	var turn_timer = Timer.new()
	turn_timer.wait_time = 2.0
	turn_timer.autostart = true
	turn_timer.timeout.connect(_on_turn_tick)
	add_child(turn_timer)
	
	_update_hud()


# ═══════════════════════════════════════════════════════════════════
# INPUT HANDLING (camera + country click)
# ═══════════════════════════════════════════════════════════════════

func _unhandled_input(event):
	if game_over:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_mouse_pos = event.position
				# Click to start infection
				if hovered_country != "" and infected_countries.size() == 0:
					_start_infection(hovered_country)
			else:
				is_dragging = false
		
		# Camera Zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.1
			if camera.zoom.x > 4.0:
				camera.zoom = Vector2(4.0, 4.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom /= 1.1
			if camera.zoom.x < 1.0:
				camera.zoom = Vector2(1.0, 1.0)
	
	elif event is InputEventMouseMotion:
		if is_dragging:
			var delta = event.position - last_mouse_pos
			camera.position -= delta / camera.zoom
			last_mouse_pos = event.position
		_check_hover(event.position)
	
	# ── UPGRADE HOTKEYS ───────────────────────────────────────────
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _upgrade_trait("speed")
			KEY_2: _upgrade_trait("stealth")
			KEY_3: _upgrade_trait("resistance")


# ═══════════════════════════════════════════════════════════════════
# GAME FLOW
# ═══════════════════════════════════════════════════════════════════

func _start_infection(country: String):
	infected_countries.append(country)
	print(get_node("/root/Global").virus_name + " has started infecting " + country + "!")
	_earn_resources(5)
	_update_hud()


# ═══════════════════════════════════════════════════════════════════
# DOT TICK (visual only — every 0.05s)
# ═══════════════════════════════════════════════════════════════════

func _on_dot_tick():
	if infected_countries.size() == 0 or game_over:
		return
	var random_country = infected_countries[randi() % infected_countries.size()]
	spawn_dot_in_country(random_country)


# ═══════════════════════════════════════════════════════════════════
# TURN TICK (full game turn — every 2s)
# ═══════════════════════════════════════════════════════════════════

func _on_turn_tick():
	if infected_countries.size() == 0 or game_over:
		return
	
	turn_count += 1
	
	# ── STEP 1: Genetic Algorithm — evolve virus traits ───────────
	_ga_evolve()
	
	# ── STEP 2: Dijkstra — spread virus with dynamic weights ─────
	_dijkstra_spread()
	
	# ── STEP 3: Bayesian Defense — detect and patch ───────────────
	_bayesian_defense()
	
	# ── STEP 4: Earn resources from infected countries ────────────
	_earn_resources(infected_countries.size())
	
	# ── STEP 5: Raise global detection ────────────────────────────
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	detection_level = clampf(detection_level + 0.01 * stealth_mod, 0.0, 1.0)
	
	# ── STEP 6: Check win/lose ────────────────────────────────────
	_check_win_lose()
	
	# ── STEP 7: Update HUD ────────────────────────────────────────
	_update_hud()
	
	# Debug log
	print("[Turn %d] Infected: %d/%d | Detection: %.0f%% | Resources: %d | Speed:%.1f Stealth:%.1f Resist:%.1f" % [
		turn_count, infected_countries.size(), TOTAL_COUNTRIES,
		detection_level * 100, resources,
		virus_speed, virus_stealth, virus_resistance
	])


# ═══════════════════════════════════════════════════════════════════
# DIJKSTRA SPREAD (with dynamic weights)
# ═══════════════════════════════════════════════════════════════════

func _dijkstra_spread():
	# Spread chance scales with Speed trait
	# Speed 1 → 5% chance, Speed 10 → ~40% chance per turn
	var spread_chance = 0.05 + (virus_speed - 1.0) * 0.04
	
	if randf() < spread_chance:
		# Run Dijkstra with dynamic weights
		var result = Dijkstra.calculate_shortest_paths(
			world_graph,
			infected_countries,
			virus_speed,
			country_detection,
			patched_countries
		)
		
		# Get sorted list of spread targets
		var targets = Dijkstra.get_spread_targets(
			result["distances"], infected_countries, patched_countries
		)
		
		if targets.size() > 0:
			var target = targets[0]  # Closest uninfected country
			var country = target["country"]
			var spread_from = result["previous"][country]
			
			infected_countries.append(country)
			print("%s spread from %s → %s (dist=%.2f)" % [
				get_node("/root/Global").virus_name, spread_from, country, target["distance"]
			])
			
			# Bonus resources for new infection
			_earn_resources(3)


# ═══════════════════════════════════════════════════════════════════
# GENETIC ALGORITHM — VIRUS EVOLUTION
# ═══════════════════════════════════════════════════════════════════
# Evolves virus traits (Speed, Stealth, Resistance) each turn.
# Selection → Crossover → Mutation → Apply best genome.
# ═══════════════════════════════════════════════════════════════════

func _ga_init_population():
	ga_population.clear()
	for i in range(ga_population_size):
		ga_population.append({
			"speed": randf_range(1.0, 10.0),
			"stealth": randf_range(1.0, 10.0),
			"resistance": randf_range(1.0, 10.0)
		})

func _ga_fitness(genome: Dictionary) -> float:
	# Fitness = how well this trait combo performs
	# Reward: more infections, lower detection
	# Penalize: high detection, few infections
	var infection_score = infected_countries.size() * genome["speed"]
	var stealth_score = -detection_level * 100.0 / max(1.0, genome["stealth"])
	var resistance_score = genome["resistance"] * patched_countries.size() * 0.5
	return infection_score + stealth_score + resistance_score

func _ga_tournament_select() -> Dictionary:
	# Pick best of 3 random candidates
	var best = ga_population[randi() % ga_population.size()]
	var best_fit = _ga_fitness(best)
	for i in range(2):
		var candidate = ga_population[randi() % ga_population.size()]
		var fit = _ga_fitness(candidate)
		if fit > best_fit:
			best = candidate
			best_fit = fit
	return best

func _ga_crossover(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
	# Single-point crossover on the 3 traits
	var point = randi_range(1, 2)
	return {
		"speed": parent_a["speed"] if point >= 1 else parent_b["speed"],
		"stealth": parent_a["stealth"] if point >= 2 else parent_b["stealth"],
		"resistance": parent_a["resistance"] if point < 2 else parent_b["resistance"]
	}

func _ga_mutate(genome: Dictionary) -> Dictionary:
	var result = genome.duplicate()
	if randf() < ga_mutation_rate:
		result["speed"] = clampf(result["speed"] + randf_range(-1.5, 1.5), 1.0, 10.0)
	if randf() < ga_mutation_rate:
		result["stealth"] = clampf(result["stealth"] + randf_range(-1.5, 1.5), 1.0, 10.0)
	if randf() < ga_mutation_rate:
		result["resistance"] = clampf(result["resistance"] + randf_range(-1.5, 1.5), 1.0, 10.0)
	return result

func _ga_evolve():
	ga_generation += 1
	
	# Sort by fitness (best first)
	ga_population.sort_custom(func(a, b): return _ga_fitness(a) > _ga_fitness(b))
	
	# Elite: top 2 survive unchanged
	var next_gen: Array = [
		ga_population[0].duplicate(),
		ga_population[1].duplicate()
	]
	
	# Fill rest with crossover + mutation
	while next_gen.size() < ga_population_size:
		var parent_a = _ga_tournament_select()
		var parent_b = _ga_tournament_select()
		var child = _ga_crossover(parent_a, parent_b) if randf() < 0.7 else parent_a.duplicate()
		child = _ga_mutate(child)
		next_gen.append(child)
	
	ga_population = next_gen
	
	# Apply the best genome to the live virus traits
	var best = ga_population[0]
	virus_speed = best["speed"]
	virus_stealth = best["stealth"]
	virus_resistance = best["resistance"]


# ═══════════════════════════════════════════════════════════════════
# BAYESIAN DEFENSE — CYBERSECURITY AI
# ═══════════════════════════════════════════════════════════════════
# Updates infection probability for each country using Bayes' theorem.
# When P(Infected | Signal) > threshold, the defense patches that country.
# ═══════════════════════════════════════════════════════════════════

const BAYES_PATCH_THRESHOLD: float = 0.70
const BAYES_P_SIGNAL_INFECTED: float = 0.85       # P(S | Infected)
const BAYES_P_SIGNAL_NOT_INFECTED: float = 0.15   # P(S | Not Infected)
const BAYES_MAX_PATCHES_PER_TURN: int = 1

func _bayesian_defense():
	var candidates: Array = []
	
	for country in world_graph.keys():
		if country in patched_countries:
			continue
		
		# ── Observe signal ────────────────────────────────────────
		var signal_strength = _observe_signal(country)
		
		# ── Bayesian update ───────────────────────────────────────
		var prior = country_detection.get(country, 0.05)
		var posterior = _bayes_update(prior, signal_strength)
		country_detection[country] = posterior
		
		# Decay prior for unsuspicious countries
		if posterior < BAYES_PATCH_THRESHOLD * 0.5:
			country_detection[country] = max(0.01, posterior - 0.03)
		
		# If above threshold AND actually infected → candidate for patching
		if posterior >= BAYES_PATCH_THRESHOLD and country in infected_countries:
			candidates.append({"country": country, "posterior": posterior})
	
	# Sort by highest posterior → patch most suspicious first
	candidates.sort_custom(func(a, b): return a["posterior"] > b["posterior"])
	
	# Patch up to max per turn
	var patches_this_turn = min(BAYES_MAX_PATCHES_PER_TURN, candidates.size())
	for i in range(patches_this_turn):
		var target = candidates[i]["country"]
		
		# Resistance trait reduces patch effectiveness
		var resist_chance = clampf(virus_resistance * 0.08, 0.0, 0.8)
		if randf() < resist_chance:
			print("[Bayesian] Tried to patch %s but virus RESISTED! (%.0f%% resist)" % [
				target, resist_chance * 100
			])
			continue
		
		# Patch the country: remove from infected, add to patched
		infected_countries.erase(target)
		patched_countries.append(target)
		detection_level = clampf(detection_level + 0.05, 0.0, 1.0)
		
		print("[Bayesian] PATCHED %s | P(Infected|S) = %.2f" % [
			target, candidates[i]["posterior"]
		])

func _observe_signal(country: String) -> float:
	# Infected countries emit stronger anomaly signals
	# Stealth trait reduces signal strength
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	
	if country in infected_countries:
		return randf_range(0.5, 1.0) * stealth_mod
	else:
		return randf_range(0.0, 0.25)

func _bayes_update(prior: float, signal_strength: float) -> float:
	# Bayes' theorem:
	# P(Infected | S) = P(S|Infected) * P(Infected)
	#                    ─────────────────────────────────────────────
	#                    P(S|Infected)*P(Infected) + P(S|¬Infected)*(1-P(Infected))
	
	var p_s_given_i = lerpf(0.0, BAYES_P_SIGNAL_INFECTED, signal_strength)
	var p_s_given_ni = lerpf(0.0, BAYES_P_SIGNAL_NOT_INFECTED, signal_strength)
	
	var numerator = p_s_given_i * prior
	var evidence = numerator + p_s_given_ni * (1.0 - prior)
	
	if evidence > 0.0:
		return numerator / evidence
	return prior


# ═══════════════════════════════════════════════════════════════════
# RESOURCE ECONOMY & UPGRADES
# ═══════════════════════════════════════════════════════════════════

func _earn_resources(amount: int):
	resources += amount

func _upgrade_trait(trait_name: String):
	if game_over:
		return
	
	var cost = 0
	match trait_name:
		"speed": cost = SPEED_COST
		"stealth": cost = STEALTH_COST
		"resistance": cost = RESISTANCE_COST
	
	if resources >= cost:
		resources -= cost
		match trait_name:
			"speed":
				virus_speed = minf(virus_speed + 1.0, 10.0)
				print("[Upgrade] Speed → %.1f (cost %d)" % [virus_speed, cost])
			"stealth":
				virus_stealth = minf(virus_stealth + 1.0, 10.0)
				print("[Upgrade] Stealth → %.1f (cost %d)" % [virus_stealth, cost])
			"resistance":
				virus_resistance = minf(virus_resistance + 1.0, 10.0)
				print("[Upgrade] Resistance → %.1f (cost %d)" % [virus_resistance, cost])
		_update_hud()
	else:
		print("[Upgrade] Not enough resources! Need %d, have %d" % [cost, resources])


# ═══════════════════════════════════════════════════════════════════
# WIN / LOSE
# ═══════════════════════════════════════════════════════════════════

func _check_win_lose():
	var infection_rate = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	
	if infection_rate >= WIN_THRESHOLD:
		_end_game(true)
	elif detection_level >= LOSE_THRESHOLD:
		_end_game(false)

func _end_game(player_won: bool):
	game_over = true
	
	if player_won:
		print("══════ %s HAS CONQUERED THE NETWORK! ══════" % get_node("/root/Global").virus_name)
	else:
		print("══════ CYBERSECURITY AI CONTAINED THE THREAT ══════")
	
	# Show end screen if it exists
	if end_screen:
		end_screen.show()
		var title_node = end_screen.get_node_or_null("Title")
		if title_node:
			title_node.text = "INFECTION COMPLETE" if player_won else "SYSTEM SECURED"


# ═══════════════════════════════════════════════════════════════════
# HUD UPDATE
# ═══════════════════════════════════════════════════════════════════

func _update_hud():
	var infection_rate = float(infected_countries.size()) / float(TOTAL_COUNTRIES)
	
	if infection_label:
		infection_label.text = "Infected: %d/%d (%.0f%%)" % [
			infected_countries.size(), TOTAL_COUNTRIES, infection_rate * 100
		]
	if detection_label:
		detection_label.text = "Detection: %.0f%%" % [detection_level * 100]
	if resources_label:
		resources_label.text = "Resources: %d" % resources
	if traits_label:
		traits_label.text = "[1] Speed:%.0f  [2] Stealth:%.0f  [3] Resist:%.0f" % [
			virus_speed, virus_stealth, virus_resistance
		]
	if infection_bar:
		infection_bar.value = infection_rate
	if detection_bar:
		detection_bar.value = detection_level
	if turn_label:
		turn_label.text = "Turn: %d | Gen: %d" % [turn_count, ga_generation]


# ═══════════════════════════════════════════════════════════════════
# HOVER DETECTION (unchanged from original)
# ═══════════════════════════════════════════════════════════════════

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
			
			# Show country name + status
			var status = ""
			if country in infected_countries:
				status = " [INFECTED]"
			elif country in patched_countries:
				status = " [PATCHED]"
			else:
				status = " (P=%.0f%%)" % [country_detection.get(country, 0.0) * 100]
			
			hover_label.text = country + status
			
			if country_hover_textures.has(country):
				hover_sprite.texture = country_hover_textures[country]
				hover_sprite.show()
			else:
				hover_sprite.hide()
			return
	
	hover_label.text = ""
	hover_sprite.hide()
	hovered_country = ""


# ═══════════════════════════════════════════════════════════════════
# DOT SPAWNING (unchanged from original)
# ═══════════════════════════════════════════════════════════════════

func spawn_dot_in_country(country_name: String):
	var bbox = country_bboxes.get(country_name)
	if not bbox:
		return
	
	var max_attempts = 100
	var target_color = null
	
	for html in country_colors:
		if country_colors[html] == country_name:
			target_color = html
			break
	
	if not target_color:
		return
	
	for i in range(max_attempts):
		var rx = randi_range(bbox[0], bbox[2])
		var ry = randi_range(bbox[1], bbox[3])
		var pcolor = color_id_image.get_pixel(rx, ry).to_html(false)
		if pcolor == target_color:
			dot_renderer.add_dot(Vector2(rx, ry))
			break
