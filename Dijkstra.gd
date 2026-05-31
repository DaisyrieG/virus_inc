class_name Dijkstra
extends RefCounted

# ═══════════════════════════════════════════════════════════════════
# DIJKSTRA'S ALGORITHM — MULTI-SOURCE WITH DYNAMIC WEIGHTS
# ═══════════════════════════════════════════════════════════════════
# Computes shortest paths from all infected source nodes outward.
# 
# IMPROVEMENT over original:
# - Edge weights are now DYNAMIC — they factor in virus Speed trait
#   and per-country detection risk (from Bayesian defense).
# - Patched countries get a heavy penalty (hard to re-infect).
# - Higher Speed → lower effective weight → faster spread.
# ═══════════════════════════════════════════════════════════════════

# Main pathfinding function with dynamic weight modifiers
static func calculate_shortest_paths(
	graph: Dictionary,
	source_nodes: Array,
	virus_speed: float = 1.0,
	country_detection: Dictionary = {},   # country_name → detection probability (0-1)
	patched_countries: Array = []          # countries the defense AI has patched
) -> Dictionary:
	
	var unvisited: Array = graph.keys().duplicate()
	var distances: Dictionary = {}
	var previous: Dictionary = {}
	
	# Initialize all distances to infinity
	for node in unvisited:
		distances[node] = INF
		previous[node] = ""
	
	# MULTI-SOURCE: All currently infected countries start at distance 0
	# The algorithm searches outward from the entire infected border
	for node in source_nodes:
		if node in distances:
			distances[node] = 0.0
	
	while unvisited.size() > 0:
		var current = ""
		var min_dist = INF
		
		# Find the unvisited node with the smallest distance
		for node in unvisited:
			if distances[node] < min_dist:
				min_dist = distances[node]
				current = node
		
		# If no reachable node found, we're done
		if current == "":
			break
		
		unvisited.erase(current)
		
		# Check all neighbors of the current node
		if graph.has(current):
			var neighbors = graph[current]
			for neighbor in neighbors.keys():
				if neighbor in unvisited:
					var base_weight = neighbors[neighbor]
					
					# ── DYNAMIC WEIGHT CALCULATION ──────────────────
					var effective_weight = compute_effective_weight(
						base_weight, neighbor, virus_speed,
						country_detection, patched_countries
					)
					
					var alt_distance = distances[current] + effective_weight
					
					# If we found a shorter path, update it
					if alt_distance < distances[neighbor]:
						distances[neighbor] = alt_distance
						previous[neighbor] = current
	
	return {"distances": distances, "previous": previous}


# ═══════════════════════════════════════════════════════════════════
# DYNAMIC WEIGHT FORMULA
# ═══════════════════════════════════════════════════════════════════
# effective_weight = (base_weight / speed_factor) + detection_penalty + patch_penalty
#
# - Speed ↑  →  weight ↓  →  virus spreads faster along this edge
# - Detection ↑  →  weight ↑  →  virus avoids heavily monitored countries
# - Patched  →  huge penalty  →  virus routes around patched countries
# ═══════════════════════════════════════════════════════════════════

static func compute_effective_weight(
	base_weight: float,
	target_country: String,
	virus_speed: float,
	country_detection: Dictionary,
	patched_countries: Array
) -> float:
	
	# Speed factor: higher Speed trait = lower effective weight
	# Speed 1 → factor 1.0 (no change)
	# Speed 10 → factor 1.72 (weights divided by ~1.7, much faster spread)
	var speed_factor = 1.0 + (virus_speed - 1.0) * 0.08
	
	# Detection penalty: Bayesian defense makes suspicious countries harder to reach
	# This makes the virus "prefer" countries that aren't being watched
	var detection_penalty = 0.0
	if country_detection.has(target_country):
		detection_penalty = country_detection[target_country] * 3.0
	
	# Patch penalty: patched countries are extremely hard to re-infect
	# Resistance trait reduces this penalty
	var patch_penalty = 0.0
	if target_country in patched_countries:
		patch_penalty = 50.0  # Effectively blocks this route
	
	# Final calculation
	var effective = (base_weight / speed_factor) + detection_penalty + patch_penalty
	
	return max(0.01, effective)  # Never zero or negative


# ═══════════════════════════════════════════════════════════════════
# HELPER: Extract the full path to a specific target
# ═══════════════════════════════════════════════════════════════════

static func get_path_to(target: String, previous_dict: Dictionary) -> Array[String]:
	var path: Array[String] = []
	var current = target
	while current != "" and previous_dict.has(current):
		path.append(current)
		current = previous_dict[current]
	path.reverse()
	return path


# ═══════════════════════════════════════════════════════════════════
# HELPER: Get all reachable uninfected countries sorted by distance
# ═══════════════════════════════════════════════════════════════════

static func get_spread_targets(
	distances: Dictionary,
	infected: Array,
	patched: Array = []
) -> Array:
	var targets = []
	for country in distances:
		if country not in infected and country not in patched:
			if distances[country] < INF and distances[country] > 0:
				targets.append({"country": country, "distance": distances[country]})
	
	# Sort by distance (closest first)
	targets.sort_custom(func(a, b): return a["distance"] < b["distance"])
	return targets