class_name Dijkstra
extends RefCounted

# Computes shortest paths from multiple infected source nodes to all other reachable nodes.
# This simulates the virus spreading outward from all infected countries simultaneously!
static func calculate_shortest_paths(graph: Dictionary, source_nodes: Array) -> Dictionary:
	var unvisited: Array = graph.keys().duplicate()
	var distances: Dictionary = {}
	var previous: Dictionary = {}
	
	# Initialize all distances to infinity
	for node in unvisited:
		distances[node] = INF
		previous[node] = ""
	
	# MULTI-SOURCE: Set all currently infected countries to distance 0
	# This means the algorithm will search outward from the entire "border" of the virus!
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
				
		# If we can't find a reachable node, we're done
		if current == "":
			break
			
		unvisited.erase(current)
		
		# Check all neighbors of the current node
		if graph.has(current):
			var neighbors = graph[current]
			for neighbor in neighbors.keys():
				if neighbor in unvisited:
					var weight = neighbors[neighbor]
					var alt_distance = distances[current] + weight
					
					# If we found a shorter path to the neighbor, update it
					if alt_distance < distances[neighbor]:
						distances[neighbor] = alt_distance
						previous[neighbor] = current
						
	return {"distances": distances, "previous": previous}

# Helper function to extract just the path (array of nodes) to a specific target
static func get_path_to(target: String, previous_dict: Dictionary) -> Array[String]:
	var path: Array[String] = []
	var current = target
	while current != "" and previous_dict.has(current):
		path.append(current)
		current = previous_dict[current]
	
	path.reverse()
	return path
