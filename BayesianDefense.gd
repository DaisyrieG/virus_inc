class_name BayesianDefense
extends RefCounted

# ═══════════════════════════════════════════════════════════════════
# BAYESIAN DEFENSE AI  
# Uses Bayes' Theorem to update suspicion per country across turns.
# Suspicion ACCUMULATES — after enough turns of infection signal,
# the AI becomes confident enough to deploy a patch.
# ═══════════════════════════════════════════════════════════════════

# How confident the AI needs to be before it patches a country
const PATCH_THRESHOLD:          float = 0.85
# Probability an infected country emits a detectable signal
const P_SIGNAL_GIVEN_INFECTED:  float = 0.70
# Probability a clean country emits a false signal (noise)
const P_SIGNAL_GIVEN_CLEAN:     float = 0.25
# How quickly suspicion decays on clean countries per turn
const SUSPICION_DECAY:          float = 0.06

# ───────────────────────────────────────────────────────────────────
# process_turn — call this once per game turn
# Returns a dict: { "patched": [...], "resisted": [...], "scanning": [...] }
# "scanning" contains countries with suspicion >= 40% (visible to player)
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
		"scanning": []   # countries AI is actively tracking
	}

	var candidates: Array = []

	for country in world_countries:
		# ── Patched countries lose suspicion slowly over time ──────
		if country in patched_countries:
			country_detection[country] = maxf(0.01, country_detection.get(country, 0.01) - 0.02)
			continue

		# ── OBSERVE: how strong is the infection signal? ───────────
		var obs = _observe_signal(country, infected_countries, virus_stealth, stealth_code_obf, stealth_fileless)

		# ── BAYES UPDATE: accumulate suspicion across turns ────────
		# prior  = suspicion from LAST turn (memory)
		# posterior = updated suspicion after observing this turn
		var prior     = country_detection.get(country, 0.05)
		var p_s_i     = P_SIGNAL_GIVEN_INFECTED * obs
		var p_s_ni    = P_SIGNAL_GIVEN_CLEAN    * obs
		var numerator = p_s_i * prior
		var evidence  = numerator + p_s_ni * (1.0 - prior)
		var posterior: float

		if evidence > 0.001:
			posterior = numerator / evidence
		else:
			posterior = prior

		# Clamp to valid probability range
		posterior = clampf(posterior, 0.01, 0.99)

		# Clean countries naturally lose suspicion each turn
		if country not in infected_countries:
			posterior = maxf(0.01, posterior - SUSPICION_DECAY)

		# Save — this becomes the prior NEXT turn (the memory effect)
		country_detection[country] = posterior

		# Track which countries are actively being scanned
		if posterior >= 0.40 and country in infected_countries:
			results["scanning"].append({
				"country": country,
				"probability": posterior
			})

		# Candidate for patching if above threshold
		if posterior >= PATCH_THRESHOLD and country in infected_countries:
			candidates.append({ "country": country, "posterior": posterior })

	# Sort by most suspicious first
	candidates.sort_custom(func(a, b): return a["posterior"] > b["posterior"])

	# ── PATCH the top N most suspicious countries ──────────────────
	var patches_done = 0
	for c in candidates:
		if patches_done >= max_patches:
			break

		var target       = c["country"]
		var confidence   = c["posterior"]

		# Resistance check — virus might survive the patch
		var resist_chance = clampf(virus_resistance * 0.06, 0.0, 0.55)
		if resist_registry:  resist_chance += 0.15
		if resist_antivirus: resist_chance += 0.25

		if randf() < resist_chance:
			results["resisted"].append(target)
			# Reset posterior: AI has to rebuild confidence
			country_detection[target] = 0.25
		else:
			results["patched"].append(target)
			# Reset posterior: country is now clean
			country_detection[target] = 0.05
			patches_done += 1

	return results

# ───────────────────────────────────────────────────────────────────
# _observe_signal — how detectable is this country this turn?
# Returns a value 0.0 (completely silent) to 1.0 (obvious infection)
# ───────────────────────────────────────────────────────────────────
func _observe_signal(
		country: String,
		infected_countries: Array,
		virus_stealth: float,
		stealth_code_obf: bool,
		stealth_fileless: bool
	) -> float:

	# Stealth stat reduces the base signal (max 65% reduction)
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.06, 0.0, 0.65)
	if stealth_code_obf: stealth_mod *= 0.65   # Code obfuscation reduces signal further
	if stealth_fileless:  stealth_mod *= 0.45  # Fileless malware almost silences the virus

	if country in infected_countries:
		# Infected country: strong signal, reduced by stealth
		return randf_range(0.55, 1.0) * stealth_mod
	else:
		# Clean country: low noise only
		return randf_range(0.0, 0.08)
