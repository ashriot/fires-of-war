extends Node
class_name InputHandler

signal unit_selected(unit)
signal unit_moved(unit, target_position, is_dash, ap_cost)
signal unit_attacked(attacker, defender)
signal camera_moved(relative_motion)
signal turn_ended
signal unit_rested(unit)  # New signal for rest action

var grid_manager: GridManager
var unit_manager
var highlight_manager: HighlightManager
var turn_manager
var camera: Camera2D

var selected_unit = null
var dragging = false
var drag_start = Vector2.ZERO

# Movement cost constants
const DASH_AP_COST = 35  # Cost per square from design doc

func _init():
	pass

func initialize(grid_mgr, unit_mgr, highlight_mgr, turn_mgr, cam):
	grid_manager = grid_mgr
	unit_manager = unit_mgr
	highlight_manager = highlight_mgr
	turn_manager = turn_mgr
	camera = cam

func process_input(event):
	if not turn_manager: return
	# Only process input during player turn
	if turn_manager.current_phase != TurnManager.GamePhase.PLAYER_TURN:
		return

	# Camera dragging
	if event is InputEventScreenDrag or (event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_LEFT):
		if dragging:
			emit_signal("camera_moved", event.relative)

	elif event is InputEventScreenTouch:
		if event.pressed:
			# Start dragging
			dragging = true
			drag_start = event.position
		else:
			# If it was a short tap, treat it as a click
			dragging = false
			if event.position.distance_to(drag_start) < 10:
				handle_click(event.position)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start = event.position
			else:
				# If it was a short click, handle it
				dragging = false
				if event.position.distance_to(drag_start) < 10:
					handle_click(event.position)

	# Keyboard controls
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:  # End player turn
			handle_end_turn()
			return

		if event.keycode == KEY_R:  # Rest
			handle_rest()
			return

		handle_keyboard_input(event)

func handle_click(position):
	# Convert screen position to world position
	var world_position = camera.get_global_mouse_position()

	# Convert to grid coordinates
	var grid_pos = grid_manager.world_to_grid(world_position)

	# Check if the click is within the grid
	if grid_manager.is_valid_grid_pos(grid_pos):
		# Check if there's a unit at this position
		var clicked_unit = unit_manager.get_unit_at_grid_position(grid_pos)

		# If no unit is selected
		if not selected_unit:
			# If we clicked on a player unit
			if clicked_unit and clicked_unit.faction == "player" and clicked_unit.can_move():
				# Select the unit
				selected_unit = clicked_unit
				unit_manager.select_unit(clicked_unit)
				unit_selected.emit(clicked_unit)
				# Show movement range
				highlight_manager.show_movement_range(clicked_unit)

		# If a unit is already selected
		else:
			# If we clicked on an enemy, try to attack
			if clicked_unit and clicked_unit.faction == "enemy":
				var attacker_grid_pos = grid_manager.world_to_grid(selected_unit.position)
				var manhattan_distance = grid_manager.get_manhattan_distance(attacker_grid_pos, grid_pos)

				# Check if enemy is in attack range (assuming range is 1 for now)
				if manhattan_distance <= 1 and selected_unit.can_act():
					emit_signal("unit_attacked", selected_unit, clicked_unit)
					highlight_manager.clear_highlights()

			# If we clicked on another player unit, select it instead
			elif clicked_unit and clicked_unit.faction == "player" and clicked_unit != selected_unit:
				highlight_manager.clear_highlights()
				selected_unit = clicked_unit
				unit_manager.select_unit(clicked_unit)
				unit_selected.emit(clicked_unit)
				highlight_manager.show_movement_range(clicked_unit)

			# If we clicked on an empty cell within movement range
			elif not clicked_unit and selected_unit.can_move():
				# Check the movement type (normal or dash)
				var move_type = highlight_manager.get_movement_type(grid_pos)

				if move_type != "invalid":
					# Calculate AP cost
					var ap_cost = 0
					if move_type == "dash":
						ap_cost = DASH_AP_COST

					# Check if unit has enough AP
					if selected_unit.ap >= ap_cost:
						# Move the unit to the target position
						var target_position = grid_manager.grid_to_world(grid_pos)
						emit_signal("unit_moved", selected_unit, target_position, move_type == "dash", ap_cost)
						highlight_manager.clear_highlights()
					else:
						print("Not enough AP to dash!")

			# If we clicked on the same unit, deselect it
			elif clicked_unit == selected_unit:
				highlight_manager.clear_highlights()
				unit_manager.deselect_active_unit()
				selected_unit = null

func handle_keyboard_input(event):
	if not selected_unit:
		if event.keycode == KEY_SPACE:
			# Try to select a player unit
			var hero_units = unit_manager.player_units
			if hero_units.size() > 0:
				selected_unit = hero_units[0]
				selected_unit.select()
				highlight_manager.show_movement_range(selected_unit)

	elif selected_unit and selected_unit.faction == "player":
		var hero_grid_pos = grid_manager.world_to_grid(selected_unit.position)
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
			highlight_manager.clear_highlights()
			unit_manager.deselect_active_unit()
			selected_unit = null
			return

		# Check if the move is valid
		if grid_manager.is_valid_grid_pos(new_pos) and new_pos != hero_grid_pos:
			# Check the movement type (normal or dash)
			var move_type = highlight_manager.get_movement_type(new_pos)

			if move_type != "invalid":
				# Calculate AP cost
				var ap_cost = 0
				if move_type == "dash":
					ap_cost = DASH_AP_COST

				# Check if unit has enough AP
				if selected_unit.ap >= ap_cost:
					# Check if there's already a unit at the target position
					var unit_at_target = unit_manager.get_unit_at_grid_position(new_pos)
					if unit_at_target:
						if unit_at_target.faction != selected_unit.faction:
							# Attack the enemy unit
							emit_signal("unit_attacked", selected_unit, unit_at_target)
					else:
						# Move to the empty cell
						var target_position = grid_manager.grid_to_world(new_pos)
						emit_signal("unit_moved", selected_unit, target_position, move_type == "dash", ap_cost)
						highlight_manager.clear_highlights()
				else:
					print("Not enough AP to dash!")

func handle_end_turn():
	highlight_manager.clear_highlights()
	unit_manager.deselect_active_unit()
	selected_unit = null
	emit_signal("turn_ended")

func handle_rest():
	if selected_unit and selected_unit.can_act():
		emit_signal("unit_rested", selected_unit)
		highlight_manager.clear_highlights()
