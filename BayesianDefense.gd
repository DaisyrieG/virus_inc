class_name BayesianDefense
extends RefCounted

const BAYES_PATCH_THRESHOLD: float = 0.70
const BAYES_P_SIGNAL_INFECTED: float = 0.85
const BAYES_P_SIGNAL_NOT_INFECTED: float = 0.15
const BAYES_MAX_PATCHES_PER_TURN: int = 1

func process_turn(world_countries: Array, infected_countries: Array, patched_countries: Array, country_detection: Dictionary, virus_stealth: float, virus_resistance: float) -> Dictionary:
	var candidates: Array = []
	var results: Dictionary = {
		"patched": [],
		"resisted": []
	}
	
	for country in world_countries:
		if country in patched_countries:
			continue
			
		var signal_strength = _observe_signal(country, infected_countries, virus_stealth)
		var prior = country_detection.get(country, 0.05)
		var posterior = _bayes_update(prior, signal_strength)
		country_detection[country] = posterior
		
		if posterior < BAYES_PATCH_THRESHOLD * 0.5:
			country_detection[country] = max(0.01, posterior - 0.03)
			
		if posterior >= BAYES_PATCH_THRESHOLD and country in infected_countries:
			candidates.append({"country": country, "posterior": posterior})
			
	candidates.sort_custom(func(a, b): return a["posterior"] > b["posterior"])
	
	var patches_this_turn = min(BAYES_MAX_PATCHES_PER_TURN, candidates.size())
	for i in range(patches_this_turn):
		var target = candidates[i]["country"]
		var resist_chance = clampf(virus_resistance * 0.08, 0.0, 0.8)
		if randf() < resist_chance:
			results["resisted"].append(target)
		else:
			results["patched"].append(target)
			
	return results

func _observe_signal(country: String, infected_countries: Array, virus_stealth: float) -> float:
	var stealth_mod = 1.0 - clampf(virus_stealth * 0.07, 0.0, 0.7)
	if country in infected_countries:
		return randf_range(0.5, 1.0) * stealth_mod
	else:
		return randf_range(0.0, 0.25)

func _bayes_update(prior: float, signal_strength: float) -> float:
	var p_s_given_i = lerpf(0.0, BAYES_P_SIGNAL_INFECTED, signal_strength)
	var p_s_given_ni = lerpf(0.0, BAYES_P_SIGNAL_NOT_INFECTED, signal_strength)
	
	var numerator = p_s_given_i * prior
	var evidence = numerator + p_s_given_ni * (1.0 - prior)
	
	if evidence > 0.0:
		return numerator / evidence
	return prior
