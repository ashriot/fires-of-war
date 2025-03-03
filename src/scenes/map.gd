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

# Managers
@onready var unit_manager = $UnitManager
@onready var turn_manager = $TurnManager
@onready var combat_manager = $CombatManager
@onready var game_ui = $GameUI

# Preload the highlight cell scene
var highlight_cell_scene = preload("res://src/scenes/highlight_cell.tscn")

# Camera panning
var dragging = false
var drag_start = Vector2.ZERO

func _ready():
	# Initialize the grid
	_initialize_grid()

	# Initialize managers
	combat_manager.initialize(unit_manager)
	turn_manager.initialize(unit_manager)
	game_ui.initialize(unit_manager, turn_manager)

	# Add a player unit (hero)
	var hero = unit_manager.add_player_unit("Fighter", Vector2i(1, 1), self)

	# Add an enemy unit (goblin)
	var enemy = unit_manager.add_enemy_unit("Goblin", Vector2i(5, 5), self)

	# Connect signals
	turn_manager.connect("phase_changed", Callable(self, "_on_phase_changed"))

	# Connect unit signals to combat manager
	for unit in unit_manager.all_units:
		unit.connect("unit_attacked", Callable(self, "_on_unit_attacked"))

func _initialize_grid():
	# Create a grid
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
			selected_unit.move_to(target_position)  # Tell the unit it has moved

			# If this was a player unit and we're in player turn
			if selected_unit.faction == "player" and turn_manager.current_phase == TurnManager.GamePhase.PLAYER_TURN:
				# Keep the unit selected but clear movement highlights
				_clear_movement_highlights()

func _input(event):
	# Only process input during player turn
	if turn_manager.current_phase != TurnManager.GamePhase.PLAYER_TURN:
		return

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
		if event.keycode == KEY_E:  # End player turn
			turn_manager.end_player_turn()
			_clear_movement_highlights()
			unit_manager.deselect_active_unit()
			selected_unit = null
			return

		if not is_moving:  # Only process keyboard input if not already moving
			if not selected_unit and event.keycode == KEY_SPACE:
				# Try to select a player unit
				var hero_units = unit_manager.player_units
				if hero_units.size() > 0:
					selected_unit = hero_units[0]
					selected_unit.select()
					var hero_grid_pos = _world_to_grid(selected_unit.position)
					_show_movement_range(hero_grid_pos)

			elif selected_unit and selected_unit.faction == "player":
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
					unit_manager.deselect_active_unit()
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
						# Check if there's already a unit at the target position
						var unit_at_target = unit_manager.get_unit_at_grid_position(new_pos)
						if unit_at_target:
							if unit_at_target.faction != selected_unit.faction:
								# Attack the enemy unit
								selected_unit.attack(unit_at_target)
						else:
							# Move to the empty cell
							target_position = _grid_to_world(new_pos)
							is_moving = true
							selected_unit.has_moved = true

func _handle_click(position):
	# Convert screen position to world position
	var world_position = get_global_mouse_position()

	# Convert to grid coordinates
	var grid_pos = _world_to_grid(world_position)

	# Check if the click is within the grid
	if _is_valid_grid_pos(grid_pos):
		# Check if there's a unit at this position
		var clicked_unit = unit_manager.get_unit_at_grid_position(grid_pos)

		# If no unit is selected
		if not selected_unit:
			# If we clicked on a player unit
			if clicked_unit and clicked_unit.faction == "player" and clicked_unit.can_move():
				# Select the unit
				selected_unit = clicked_unit
				unit_manager.select_unit(clicked_unit)
				print("Player unit selected: " + clicked_unit.unit_name)
				# Show movement range
				_show_movement_range(_world_to_grid(clicked_unit.position))
			else:
				print("No selectable unit at this position")

		# If a unit is already selected
		else:
			# If we clicked on an enemy, try to attack
			if clicked_unit and clicked_unit.faction == "enemy":
				var attacker_grid_pos = _world_to_grid(selected_unit.position)
				var manhattan_distance = abs(grid_pos.x - attacker_grid_pos.x) + abs(grid_pos.y - attacker_grid_pos.y)

				# Check if enemy is in attack range (assuming range is 1 for now)
				if manhattan_distance <= 1 and selected_unit.can_act():
					print("Attacking enemy: " + clicked_unit.unit_name)
					selected_unit.attack(clicked_unit)
					_clear_movement_highlights()
				else:
					print("Enemy out of range or unit has already acted")

			# If we clicked on another player unit, select it instead
			elif clicked_unit and clicked_unit.faction == "player" and clicked_unit != selected_unit:
				_clear_movement_highlights()
				selected_unit = clicked_unit
				unit_manager.select_unit(clicked_unit)
				print("Switching to another player unit: " + clicked_unit.unit_name)
				_show_movement_range(_world_to_grid(clicked_unit.position))

			# If we clicked on an empty cell within movement range
			elif not clicked_unit and selected_unit.can_move():
				var current_grid_pos = _world_to_grid(selected_unit.position)

				# Check if the target position is within movement range
				var is_valid_move = false
				for highlight in highlight_cells:
					if _world_to_grid(highlight.position) == grid_pos:
						is_valid_move = true
						break

				if is_valid_move:
					# Move the unit to the target position
					target_position = _grid_to_world(grid_pos)
					is_moving = true
					print("Moving unit to ", grid_pos)
					_clear_movement_highlights()
				else:
					print("Cannot move to that position")

			# If we clicked on the same unit, deselect it
			elif clicked_unit == selected_unit:
				print("Deselecting unit")
				_clear_movement_highlights()
				unit_manager.deselect_active_unit()
				selected_unit = null

func _world_to_grid(world_pos):
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))

func _grid_to_world(grid_pos):
	return Vector2(grid_pos.x * CELL_SIZE + CELL_SIZE/2, grid_pos.y * CELL_SIZE + CELL_SIZE/2)

func _is_valid_grid_pos(grid_pos):
	return grid_pos.x >= 0 and grid_pos.x < GRID_SIZE and grid_pos.y >= 0 and grid_pos.y < GRID_SIZE

func _show_movement_range(center_pos):
	# Clear any existing highlights
	_clear_movement_highlights()

	# If the unit has already moved, don't show movement range
	if selected_unit and selected_unit.has_moved:
		return

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
					# Check if there's already a unit at this position
					var unit_at_pos = unit_manager.get_unit_at_grid_position(pos)
					if not unit_at_pos:  # Only highlight empty cells for movement
						# Create a highlight at this position
						var highlight = highlight_cell_scene.instantiate()
						highlight.position = _grid_to_world(pos)
						highlight.set_cell_size(CELL_SIZE)
						highlight.modulate = Color(0.2, 0.7, 0.2, 0.5)  # Green for movement
						add_child(highlight)
						highlight_cells.append(highlight)
					elif unit_at_pos.faction != selected_unit.faction:
						# Highlight enemies in attack range with a different color
						var highlight = highlight_cell_scene.instantiate()
						highlight.position = _grid_to_world(pos)
						highlight.set_cell_size(CELL_SIZE)
						highlight.modulate = Color(0.7, 0.2, 0.2, 0.5)  # Red for enemies
						add_child(highlight)
						highlight_cells.append(highlight)

func _clear_movement_highlights():
	# Remove all highlight cells
	for highlight in highlight_cells:
		highlight.queue_free()
	highlight_cells.clear()

func _process_enemy_turn():
	# Process each enemy unit's turn one at a time
	var enemy_units = unit_manager.enemy_units.duplicate()
	_take_enemy_turn(enemy_units)

func _take_enemy_turn(remaining_enemies):
	if remaining_enemies.size() == 0:
		# All enemies have taken their turn, return to player phase
		await get_tree().create_timer(0.5).timeout
		turn_manager.set_phase(TurnManager.GamePhase.PLAYER_TURN)
		return

	var enemy = remaining_enemies.pop_front()

	# Find closest player unit
	var target = _find_closest_player_unit(enemy)

	if target:
		var enemy_grid_pos = _world_to_grid(enemy.position)
		var target_grid_pos = _world_to_grid(target.position)
		var distance = abs(enemy_grid_pos.x - target_grid_pos.x) + abs(enemy_grid_pos.y - target_grid_pos.y)

		if distance <= 1:
			# Attack if adjacent
			_perform_attack(enemy, target)
			await get_tree().create_timer(0.8).timeout
			# Process next enemy
			_take_enemy_turn(remaining_enemies)
		else:
			# Move toward player
			var path = _find_path_to_player(enemy_grid_pos, target_grid_pos)

			if path.size() > 0:
				# Move along the path (just the first step)
				var move_target = path[0]
				var world_target = _grid_to_world(move_target)

				# Animate the movement
				var tween = create_tween()
				tween.tween_property(enemy, "position", world_target, 0.3)
				await tween.finished

				# Set the new position
				enemy.position = world_target

			await get_tree().create_timer(0.3).timeout
			# Process next enemy
			_take_enemy_turn(remaining_enemies)
	else:
		# No player units found, process next enemy
		await get_tree().create_timer(0.1).timeout
		_take_enemy_turn(remaining_enemies)

func _find_closest_player_unit(enemy_unit):
	var closest_unit = null
	var min_distance = 999

	for unit in unit_manager.player_units:
		var enemy_pos = _world_to_grid(enemy_unit.position)
		var player_pos = _world_to_grid(unit.position)
		var distance = abs(enemy_pos.x - player_pos.x) + abs(enemy_pos.y - player_pos.y)

		if distance < min_distance:
			min_distance = distance
			closest_unit = unit

	return closest_unit

func _find_path_to_player(start_pos, target_pos):
	# Simple implementation - just move one step closer to the player
	# In a full game, you'd implement A* pathfinding
	var path = []

	var x_diff = target_pos.x - start_pos.x
	var y_diff = target_pos.y - start_pos.y

	if abs(x_diff) > abs(y_diff):
		# Move horizontally first
		var next_x = start_pos.x + (1 if x_diff > 0 else -1)
		var potential_pos = Vector2i(next_x, start_pos.y)

		# Check if space is valid and empty
		if _is_valid_grid_pos(potential_pos) and unit_manager.get_unit_at_grid_position(potential_pos) == null:
			path.append(potential_pos)
		else:
			# Try vertical instead
			var next_y = start_pos.y + (1 if y_diff > 0 else -1)
			potential_pos = Vector2i(start_pos.x, next_y)

			if _is_valid_grid_pos(potential_pos) and unit_manager.get_unit_at_grid_position(potential_pos) == null:
				path.append(potential_pos)

	else:
		# Move vertically first
		var next_y = start_pos.y + (1 if y_diff > 0 else -1)
		var potential_pos = Vector2i(start_pos.x, next_y)

		# Check if space is valid and empty
		if _is_valid_grid_pos(potential_pos) and unit_manager.get_unit_at_grid_position(potential_pos) == null:
			path.append(potential_pos)
		else:
			# Try horizontal instead
			var next_x = start_pos.x + (1 if x_diff > 0 else -1)
			potential_pos = Vector2i(next_x, start_pos.y)

			if _is_valid_grid_pos(potential_pos) and unit_manager.get_unit_at_grid_position(potential_pos) == null:
				path.append(potential_pos)

	return path

func _perform_attack(attacker, defender):
	print(attacker.unit_name + " attacks " + defender.unit_name)

	# Perform the attack using the combat manager
	var damage = combat_manager.perform_attack(attacker, defender)

	# Flash the defender red
	var tween = create_tween()
	tween.tween_property(defender, "modulate", Color(1.5, 0.5, 0.5), 0.1)
	tween.tween_property(defender, "modulate", Color(1, 1, 1), 0.1)

	# Show damage number
	var damage_number = DamageNumber.new()
	damage_number.position = defender.position + Vector2(0, -15)
	damage_number.set_text(str(damage))
	add_child(damage_number)

	# Check if defender died
	if defender.hp <= 0:
		await get_tree().create_timer(0.5).timeout
		defender.queue_free()
		unit_manager.remove_unit(defender)

		# Check for game over conditions
		turn_manager.check_game_over()

func _on_unit_attacked(attacker, defender):
	_perform_attack(attacker, defender)

# Signal handlers
func _on_phase_changed(new_phase):
	match new_phase:
		TurnManager.GamePhase.PLAYER_TURN:
			print("Player turn started")
		TurnManager.GamePhase.ENEMY_TURN:
			print("Enemy turn started")
			_clear_movement_highlights()
			unit_manager.deselect_active_unit()
			selected_unit = null
			_process_enemy_turn()
		TurnManager.GamePhase.VICTORY:
			print("Victory!")
		TurnManager.GamePhase.DEFEAT:
			print("Defeat!")
