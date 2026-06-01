class_name BayesianDefense
extends RefCounted

# ═══════════════════════════════════════════════════════════════════
# BAYESIAN DEFENSE AI - IMPROVED
# Uses Bayes' Theorem with ADAPTIVE STRATEGY to defend the network.
# ═══════════════════════════════════════════════════════════════════

# Base threshold — adjusted dynamically based on threat level
const BASE_PATCH_THRESHOLD:     float = 0.80
# Probability an infected country emits a detectable signal
const P_SIGNAL_GIVEN_INFECTED:  float = 0.75
# Probability a clean country emits a false signal (noise)
const P_SIGNAL_GIVEN_CLEAN:     float = 0.20
# How quickly suspicion decays on clean countries per turn
const SUSPICION_DECAY:          float = 0.05

# ─ IMPROVEMENT TRACKING ─
# Track infection age and patch failures for smarter decisions
var infection_age: Dictionary = {}        # How many turns each node has been infected
var patch_failures: Dictionary = {}       # How many times a patch failed per node
var last_signal_strength: Dictionary = {} # Remember signal trends

# ───────────────────────────────────────────────────────────────────
# process_turn — call this once per game turn
# IMPROVEMENTS:
# 1. Tracks infection age → older infections are more obvious
# 2. Remembers patch failures → knows which viruses are resistant
# 3. Adaptive threshold → patches more aggressively under threat
# 4. Risk scoring → prioritizes high-impact nodes
# Returns: { "patched": [...], "resisted": [...], "scanning": [...] }
# ───────────────────────────────────────────────────────────────────
func process_turn(
		world_countries: Array,
		infected_countries: Array,
		patched_countries: Array,
		country_detection: Dictionary,
		virus_stealth: float,
		virus_resistance: float,
		stealth_code_obf: bool = false,
		stealth_fileless: bool = false,
		resist_registry: bool = false,
		resist_antivirus: bool = false,
		max_patches: int = 1
	) -> Dictionary:

	var results: Dictionary = {
		"patched":  [],
		"resisted": [],
		"scanning": []
	}

	# ── UPDATE INFECTION AGE ────────────────────────────────────
	for country in infected_countries:
		if country not in infection_age:
			infection_age[country] = 0
		infection_age[country] += 1

	# ── REMOVE AGE FROM CURED NODES ─────────────────────────────
	for country in infection_age.keys():
		if country not in infected_countries:
			infection_age.erase(country)

	var candidates: Array = []

	for country in world_countries:
		# ── Patched countries lose suspicion slowly ──────────────
		if country in patched_countries:
			country_detection[country] = maxf(0.01, country_detection.get(country, 0.01) - 0.03)
			continue

		# ── OBSERVE: signal strength (improved!) ─────────────────
		var obs = _observe_signal_advanced(
			country, infected_countries, 
			virus_stealth, stealth_code_obf, stealth_fileless
		)

		# ── BAYES UPDATE: with confidence boosting ──────────────
		var prior = country_detection.get(country, 0.05)
		var p_s_i = P_SIGNAL_GIVEN_INFECTED * obs
		var p_s_ni = P_SIGNAL_GIVEN_CLEAN * obs
		var numerator = p_s_i * prior
		var evidence = numerator + p_s_ni * (1.0 - prior)
		var posterior: float

		if evidence > 0.001:
			posterior = numerator / evidence
		else:
			posterior = prior

		posterior = clampf(posterior, 0.01, 0.99)

		# ── INFECTION AGE BOOST ─────────────────────────────────
		# The longer a node stays infected, the more obvious it becomes
		if country in infected_countries:
			var age_boost = clampf(infection_age.get(country, 0) * 0.08, 0.0, 0.35)
			posterior = minf(0.99, posterior + age_boost)

		# ── Clean countries lose suspicion ──────────────────────
		if country not in infected_countries:
			posterior = maxf(0.01, posterior - SUSPICION_DECAY)

		country_detection[country] = posterior
		last_signal_strength[country] = obs

		# Track scanning activity
		if posterior >= 0.40 and country in infected_countries:
			results["scanning"].append({
				"country": country,
				"probability": posterior
			})

		# ADAPTIVE THRESHOLD: Patch if high confidence OR high threat
		var adaptive_threshold = _calculate_adaptive_threshold(
			infected_countries.size(),
			world_countries.size(),
			country
		)

		if posterior >= adaptive_threshold and country in infected_countries:
			var risk_score = _calculate_risk_score(country, infected_countries, world_countries)
			candidates.append({
				"country": country,
				"posterior": posterior,
				"risk_score": risk_score
			})

	# ── SMART PRIORITIZATION ────────────────────────────────────
	# Sort by risk first, then confidence (to catch spreading threats early)
	candidates.sort_custom(func(a, b): 
		if a["risk_score"] != b["risk_score"]:
			return a["risk_score"] > b["risk_score"]
		return a["posterior"] > b["posterior"]
	)

	# ── DYNAMIC PATCHING ────────────────────────────────────────
	# Patch more aggressively when infection is spreading
	var patches_to_deploy = max_patches
	if infected_countries.size() > world_countries.size() * 0.4:
		patches_to_deploy = int(max_patches * 1.5)  # 50% more patches when critical
	if infected_countries.size() > world_countries.size() * 0.6:
		patches_to_deploy = int(max_patches * 2.0)  # Double patches when dire

	var patches_done = 0
	for c in candidates:
		if patches_done >= patches_to_deploy:
			break

		var target = c["country"]
		var confidence = c["posterior"]

		# ── IMPROVED RESISTANCE CALCULATION ─────────────────────
		# Account for patch history - if many patches fail on this node,
		# the virus is clearly resistant. Skip it until virus evolves.
		var failures = patch_failures.get(target, 0)
		var resist_chance = clampf(virus_resistance * 0.08, 0.0, 0.75)
		
		# Each previous failure increases this node's resistance profile
		resist_chance += failures * 0.10
		
		if resist_registry:  resist_chance += 0.12
		if resist_antivirus: resist_chance += 0.18

		if randf() < resist_chance:
			results["resisted"].append(target)
			# Track this failure
			patch_failures[target] = patch_failures.get(target, 0) + 1
			# Increase suspicion when patch fails (more confidence virus is there)
			country_detection[target] = minf(0.90, country_detection[target] + 0.15)
		else:
			results["patched"].append(target)
			country_detection[target] = 0.05
			patch_failures.erase(target)  # Reset on success
			patches_done += 1

	return results

# ───────────────────────────────────────────────────────────────────
# IMPROVED SIGNAL DETECTION
# The longer a node is infected, the stronger its signal.
# Returns 0.0 (silent) to 1.0 (obvious infection)
# ───────────────────────────────────────────────────────────────────
func _observe_signal_advanced(
		country: String,
		infected_countries: Array,
		virus_stealth: float,
		stealth_code_obf: bool,
		stealth_fileless: bool
	) -> float:

	# Stealth reduces signal strength
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.065, 0.0, 0.70)
	if stealth_code_obf: stealth_mod *= 0.60
	if stealth_fileless:  stealth_mod *= 0.40

	if country in infected_countries:
		# Base signal for infection
		var base_signal = randf_range(0.60, 1.0)
		
		# Age-based signal amplification
		# Older infections leave more traces (logs, artifacts, etc)
		var age = infection_age.get(country, 0)
		var age_multiplier = 1.0 + (age * 0.05)  # +5% per turn infected
		age_multiplier = clampf(age_multiplier, 1.0, 1.40)  # Cap at 40% boost
		
		var signal = base_signal * age_multiplier * stealth_mod
		return clampf(signal, 0.3, 1.0)
	else:
		# Clean country: just noise
		return randf_range(0.0, 0.06)


# ───────────────────────────────────────────────────────────────────
# ADAPTIVE THRESHOLD — Decision making under pressure
# ───────────────────────────────────────────────────────────────────
func _calculate_adaptive_threshold(
		infected_count: int,
		total_countries: int,
		country: String
	) -> float:

	var infection_rate = float(infected_count) / float(total_countries)
	var base = BASE_PATCH_THRESHOLD
	
	# As infection spreads, lower the threshold (get desperate)
	if infection_rate > 0.7:
		base = 0.60  # Critical: patch suspected nodes
	elif infection_rate > 0.5:
		base = 0.65
	elif infection_rate > 0.3:
		base = 0.72
	
	# If this node has failed patches before, be MORE confident before trying again
	var failures = patch_failures.get(country, 0)
	if failures > 0:
		base += failures * 0.05  # Require 5% more confidence per failure
	
	return clampf(base, 0.55, 0.95)


# ───────────────────────────────────────────────────────────────────
# RISK SCORING — Which infections are most dangerous?
# Consider: how fast is this spreading? Is it a network hub?
# ───────────────────────────────────────────────────────────────────
func _calculate_risk_score(
		country: String,
		infected_countries: Array,
		world_countries: Array
	) -> float:

	var risk = 0.0
	
	# Factor 1: Infection age (spreading longer = higher risk)
	var age = infection_age.get(country, 0)
	risk += age * 2.0
	
	# Factor 2: Patch failure history (resistant strains are dangerous)
	var failures = patch_failures.get(country, 0)
	risk += failures * 5.0
	
	# Factor 3: Network position (hub nodes are high-value)
	# (Approximated by whether many neighbors are infected)
	# This would be improved by actual graph connectivity data
	# For now, we use infection density as proxy
	var infection_density = float(infected_countries.size()) / float(world_countries.size())
	risk += infection_density * 3.0
	
	return risk
