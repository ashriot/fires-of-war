extends Node
class_name GridManager

signal path_found(path)

# Grid settings
var grid_size: Vector2i
var cell_size: float
var grid = []

func _init():
	pass

func initialize(size: Vector2i, cell_sz: float):
	grid_size = size
	cell_size = cell_sz
	_initialize_grid()

func _initialize_grid():
	# Create a grid
	grid = []
	for x in range(grid_size.x):
		var row = []
		for y in range(grid_size.y):
			# 0 means empty/walkable cell
			row.append(0)
		grid.append(row)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / cell_size), int(world_pos.y / cell_size))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * cell_size + cell_size/2, grid_pos.y * cell_size + cell_size/2)

func is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y

func set_cell_value(grid_pos: Vector2i, value: int) -> void:
	if is_valid_grid_pos(grid_pos):
		grid[grid_pos.x][grid_pos.y] = value

func get_cell_value(grid_pos: Vector2i) -> int:
	if is_valid_grid_pos(grid_pos):
		return grid[grid_pos.x][grid_pos.y]
	return -1

func get_manhattan_distance(start_pos: Vector2i, end_pos: Vector2i) -> int:
	return abs(start_pos.x - end_pos.x) + abs(start_pos.y - end_pos.y)

func find_path(start_pos: Vector2i, target_pos: Vector2i, unit_manager, max_steps: int = 3) -> Array:
	# More comprehensive path implementation
	# Returns a path with multiple steps (up to max_steps)
	var path = []

	# Check if target position has a unit - if so, we want to stop adjacent to it
	var has_unit_at_target = unit_manager.get_unit_at_grid_position(target_pos) != null

	if get_manhattan_distance(start_pos, target_pos) <= 1:
		# Already adjacent
		return path

	# Implementation of a simplified A* algorithm
	var open_set = [start_pos]
	var came_from = {}
	var g_score = {Vector2i(start_pos.x, start_pos.y): 0}
	var f_score = {Vector2i(start_pos.x, start_pos.y): get_manhattan_distance(start_pos, target_pos)}

	while not open_set.is_empty():
		# Find node with lowest f_score
		var current = open_set[0]
		var lowest_f = f_score[current]
		var current_idx = 0

		for i in range(1, open_set.size()):
			var pos = open_set[i]
			if f_score[pos] < lowest_f:
				lowest_f = f_score[pos]
				current = pos
				current_idx = i

		# Remove current from open set
		open_set.remove_at(current_idx)

		# Check if we reached the target, are adjacent to target with a unit, or reached maximum steps
		var is_adjacent_to_target = has_unit_at_target and get_manhattan_distance(current, target_pos) <= 1

		if (current == target_pos and not has_unit_at_target) or is_adjacent_to_target or g_score[current] >= max_steps:
			# Reconstruct path
			var current_pos = current
			while current_pos in came_from:
				path.push_front(current_pos)
				current_pos = came_from[current_pos]

			# Limit path length to max_steps
			if path.size() > max_steps:
				path.resize(max_steps)

			return path

		# Check neighbors
		var neighbors = [
			Vector2i(current.x + 1, current.y),
			Vector2i(current.x - 1, current.y),
			Vector2i(current.x, current.y + 1),
			Vector2i(current.x, current.y - 1)
		]

		for neighbor in neighbors:
			# Skip invalid or occupied positions (except target)
			if not is_valid_grid_pos(neighbor):
				continue

			var unit_at_pos = unit_manager.get_unit_at_grid_position(neighbor)
			if unit_at_pos != null and neighbor != target_pos:
				continue

			# Calculate tentative g_score
			var tentative_g = g_score[current] + 1

			# If this path is better than previous
			if neighbor not in g_score or tentative_g < g_score[neighbor]:
				# Update path
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + get_manhattan_distance(neighbor, target_pos)

				# Add to open set if not already there
				if neighbor not in open_set:
					open_set.append(neighbor)

	# If we get here, no path exists or is too complex
	# Fall back to simple one-step path
	var x_diff = target_pos.x - start_pos.x
	var y_diff = target_pos.y - start_pos.y

	if abs(x_diff) > abs(y_diff):
		# Move horizontally first
		var next_x = start_pos.x + (1 if x_diff > 0 else -1)
		var potential_pos = Vector2i(next_x, start_pos.y)

		# Check if space is valid and empty
		if is_valid_grid_pos(potential_pos) and unit_manager.get_unit_at_grid_position(potential_pos) == null:
			path.append(potential_pos)
	else:
		# Move vertically first
		var next_y = start_pos.y + (1 if y_diff > 0 else -1)
		var potential_pos = Vector2i(start_pos.x, next_y)

		# Check if space is valid and empty
		if is_valid_grid_pos(potential_pos) and unit_manager.get_unit_at_grid_position(potential_pos) == null:
			path.append(potential_pos)

	return path

func get_cells_in_range(center_pos: Vector2i, range_value: int) -> Array:
	var cells = []

	for x in range(center_pos.x - range_value, center_pos.x + range_value + 1):
		for y in range(center_pos.y - range_value, center_pos.y + range_value + 1):
			var pos = Vector2i(x, y)

			# Skip the center (unit's position)
			if pos == center_pos:
				continue

			# Check if the position is valid and within range
			if is_valid_grid_pos(pos):
				var manhattan_distance = get_manhattan_distance(pos, center_pos)
				if manhattan_distance <= range_value:
					cells.append(pos)

	return cells
