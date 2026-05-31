class_name GeneticAlgorithm

var population: Array = []
var population_size: int = 10
var mutation_rate: float = 0.15
var generation: int = 0

func init_population():
	population.clear()
	generation = 0
	for i in range(population_size):
		population.append({
			"speed": randf_range(1.0, 10.0),
			"stealth": randf_range(1.0, 10.0),
			"resistance": randf_range(1.0, 10.0)
		})

func _fitness(genome: Dictionary, infected_count: int, detection_level: float, patched_count: int) -> float:
	# Fitness = how well this trait combo performs
	# Reward: more infections, lower detection
	# Penalize: high detection, few infections
	var infection_score = infected_count * genome["speed"]
	var stealth_score = -detection_level * 100.0 / max(1.0, genome["stealth"])
	var resistance_score = genome["resistance"] * patched_count * 0.5
	return infection_score + stealth_score + resistance_score

func _tournament_select(infected_count: int, detection_level: float, patched_count: int) -> Dictionary:
	var best = population[randi() % population.size()]
	var best_fit = _fitness(best, infected_count, detection_level, patched_count)
	for i in range(2):
		var candidate = population[randi() % population.size()]
		var fit = _fitness(candidate, infected_count, detection_level, patched_count)
		if fit > best_fit:
			best = candidate
			best_fit = fit
	return best

func _crossover(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
	var point = randi_range(1, 2)  # split after trait 1 or trait 2
	var keys = ["speed", "stealth", "resistance"]
	var child = {}
	for i in range(keys.size()):
		child[keys[i]] = parent_a[keys[i]] if i < point else parent_b[keys[i]]
	return child

func _mutate(genome: Dictionary) -> Dictionary:
	var result = genome.duplicate()
	if randf() < mutation_rate:
		result["speed"] = clampf(result["speed"] + randf_range(-1.5, 1.5), 1.0, 10.0)
	if randf() < mutation_rate:
		result["stealth"] = clampf(result["stealth"] + randf_range(-1.5, 1.5), 1.0, 10.0)
	if randf() < mutation_rate:
		result["resistance"] = clampf(result["resistance"] + randf_range(-1.5, 1.5), 1.0, 10.0)
	return result

func evolve(infected_count: int, detection_level: float, patched_count: int) -> Dictionary:
	generation += 1
	
	var scored = []
	for genome in population:
		scored.append({"genome": genome, "fit": _fitness(genome, infected_count, detection_level, patched_count)})
		
	scored.sort_custom(func(a, b): return a["fit"] > b["fit"])
	
	# Extract sorted population
	for i in range(population.size()):
		population[i] = scored[i]["genome"]
	
	# Elite: top 2 survive unchanged
	var next_gen: Array = [
		population[0].duplicate(),
		population[1].duplicate()
	]
	
	# Fill rest with crossover + mutation
	while next_gen.size() < population_size:
		var parent_a = _tournament_select(infected_count, detection_level, patched_count)
		var parent_b = _tournament_select(infected_count, detection_level, patched_count)
		var child = _crossover(parent_a, parent_b) if randf() < 0.7 else parent_a.duplicate()
		child = _mutate(child)
		next_gen.append(child)
	
	population = next_gen
	
	# Return the best genome
	return population[0]
