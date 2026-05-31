import sys

with open('BayesianDefense.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the const
content = content.replace("const BAYES_MAX_PATCHES_PER_TURN: int = 1\n", "")

# Update signature
old_sig = "func process_turn(world_countries: Array, infected_countries: Array, patched_countries: Array, country_detection: Dictionary, virus_stealth: float, virus_resistance: float) -> Dictionary:"
new_sig = "func process_turn(world_countries: Array, infected_countries: Array, patched_countries: Array, country_detection: Dictionary, virus_stealth: float, virus_resistance: float, max_patches: int = 1) -> Dictionary:"
content = content.replace(old_sig, new_sig)

# Update the loop bound
old_bound = "var patches_this_turn = min(BAYES_MAX_PATCHES_PER_TURN, candidates.size())"
new_bound = "var patches_this_turn = min(max_patches, candidates.size())"
content = content.replace(old_bound, new_bound)

with open('BayesianDefense.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated BayesianDefense.gd")
