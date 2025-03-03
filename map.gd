extends Node2D

# Grid settings
const GRID_SIZE = 10
const CELL_SIZE = 12  # This should match your sprite size
var grid = []

# Unit selection and movement
var selected_unit = null
var target_position = Vector2.ZERO
var is_moving = false
var highlight_cells = []

# Preload the highlight cell scene
var highlight_cell_scene = preload("res://highlight_cell.tscn")

# Camera panning
var dragging = false
var drag_start = Vector2.ZERO

func _ready():
	# Initialize the grid
	_initialize_grid()

	# Set initial hero position
	var hero = $HeroUnit
	hero.position = Vector2(1, 1) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
	target_position = hero.position

func _initialize_grid():
	# Create a 12x12 grid
	grid = []
	for x in range(GRID_SIZE):
		var row = []
		for y in range(GRID_SIZE):
			# 0 means empty/walkable cell
			row.append(0)
		grid.append(row)

func _process(delta):
	# Handle unit movement
	if is_moving and selected_unit:
		var direction = (target_position - selected_unit.position).normalized()
		var distance = selected_unit.position.distance_to(target_position)

		if distance > 5:  # If we're not very close to the target
			selected_unit.position += direction * 100 * delta
		else:
			# Snap to the target position when we're close enough
			selected_unit.position = target_position
			is_moving = false
			print("Movement completed")
			selected_unit = null

func _input(event):
	# Camera dragging
	if event is InputEventScreenDrag or (event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_LEFT):
		if dragging:
			$Camera2D.position -= event.relative

	elif event is InputEventScreenTouch:
		if event.pressed:
			# Start dragging
			dragging = true
			drag_start = event.position
		else:
			# If it was a short tap, treat it as a click
			dragging = false
			if event.position.distance_to(drag_start) < 10:
				_handle_click(event.position)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start = event.position
			else:
				# If it was a short click, handle it
				dragging = false
				if event.position.distance_to(drag_start) < 10:
					_handle_click(event.position)

	# Keyboard controls for debugging
	elif event is InputEventKey and event.pressed:
		if not is_moving:  # Only process keyboard input if not already moving
			if not selected_unit and event.keycode == KEY_SPACE:
				# Select the hero unit with spacebar
				selected_unit = $HeroUnit
				var hero_grid_pos = _world_to_grid(selected_unit.position)
				_show_movement_range(hero_grid_pos)

			elif selected_unit:
				var hero_grid_pos = _world_to_grid(selected_unit.position)
				var new_pos = hero_grid_pos

				# WASD movement
				if event.keycode == KEY_W:
					new_pos.y -= 1
				elif event.keycode == KEY_S:
					new_pos.y += 1
				elif event.keycode == KEY_A:
					new_pos.x -= 1
				elif event.keycode == KEY_D:
					new_pos.x += 1
				elif event.keycode == KEY_ESCAPE:
					# Cancel selection
					_clear_movement_highlights()
					selected_unit = null
					return

				# Check if the move is valid
				if _is_valid_grid_pos(new_pos) and new_pos != hero_grid_pos:
					var is_valid_move = false
					for highlight in highlight_cells:
						if _world_to_grid(highlight.position) == new_pos:
							is_valid_move = true
							break

					if is_valid_move:
						target_position = _grid_to_world(new_pos)
						is_moving = true
						_clear_movement_highlights()
						# Note: Don't deselect here, let _process handle it when movement completes

func _handle_click(position):
	# Convert screen position to world position
	var world_position = get_global_mouse_position()

	# Convert to grid coordinates
	var grid_pos = _world_to_grid(world_position)

	# Check if the click is within the grid
	if _is_valid_grid_pos(grid_pos):
		var hero = $HeroUnit
		var hero_grid_pos = _world_to_grid(hero.position)

		# If no unit is selected
		if not selected_unit:
			# Check if we're clicking on the hero
			if hero_grid_pos == grid_pos:
				# Select the hero
				selected_unit = hero
				print("Hero selected")
				# Show movement range
				_show_movement_range(hero_grid_pos)

		# If a unit is already selected
		else:
			# Check if the target position is within movement range
			var is_valid_move = false
			for highlight in highlight_cells:
				if _world_to_grid(highlight.position) == grid_pos:
					is_valid_move = true
					break

			if is_valid_move:
				# Move the hero to the target position
				target_position = _grid_to_world(grid_pos)
				is_moving = true
				print("Moving hero to ", grid_pos)
			else:
				# If clicking outside movement range, deselect the unit
				if grid_pos != hero_grid_pos:
					print("Deselecting - invalid move")
					selected_unit = null
				else:
					print("Clicked on already selected unit - deselecting")
					selected_unit = null

			# Clear the movement highlights
			_clear_movement_highlights()

func _world_to_grid(world_pos):
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))

func _grid_to_world(grid_pos):
	return Vector2(grid_pos.x * CELL_SIZE + CELL_SIZE/2, grid_pos.y * CELL_SIZE + CELL_SIZE/2)

func _is_valid_grid_pos(grid_pos):
	return grid_pos.x >= 0 and grid_pos.x < GRID_SIZE and grid_pos.y >= 0 and grid_pos.y < GRID_SIZE

func _show_movement_range(center_pos):
	# Clear any existing highlights
	_clear_movement_highlights()

	# Get the unit's movement range
	var unit_movement_range = selected_unit.movement_range

	# Show cells within movement range
	for x in range(center_pos.x - unit_movement_range, center_pos.x + unit_movement_range + 1):
		for y in range(center_pos.y - unit_movement_range, center_pos.y + unit_movement_range + 1):
			var pos = Vector2i(x, y)

			# Skip the center (unit's position)
			if pos == center_pos:
				continue

			# Check if the position is valid and within range
			if _is_valid_grid_pos(pos):
				var manhattan_distance = abs(pos.x - center_pos.x) + abs(pos.y - center_pos.y)
				if manhattan_distance <= unit_movement_range:
					# Create a highlight at this position
					var highlight = highlight_cell_scene.instantiate()
					highlight.position = _grid_to_world(pos)
					highlight.set_cell_size(CELL_SIZE)
					add_child(highlight)
					highlight_cells.append(highlight)

func _clear_movement_highlights():
	# Remove all highlight cells
	for highlight in highlight_cells:
		highlight.queue_free()
	highlight_cells.clear()
