extends Node2D

# Grid settings
const GRID_SIZE = Vector2i(10, 10)
const CELL_SIZE = 12  # This should match your sprite size

# Unit movement
var selected_unit = null
var target_position = Vector2.ZERO
var is_moving = false
var current_path = []  # For storing the path during movement

# Preloaded scenes
var highlight_cell_scene = preload("res://src/scenes/highlight_cell.tscn") as PackedScene
var damage_number_scene = preload("res://src/scenes/damage_number.tscn") as PackedScene

# Managers and controllers
@onready var unit_manager = $Managers/UnitManager
@onready var turn_manager = $Managers/TurnManager
@onready var combat_manager = $Managers/CombatManager
@onready var game_ui = $GameUI

# New managers - will be initialized in _ready
var grid_manager: GridManager
var highlight_manager: HighlightManager
var input_handler: InputHandler
var enemy_ai: EnemyAIController
var camera_controller: CameraController

# Rest Button
var rest_button: Button

func _ready():
	# Initialize the new managers
	grid_manager = GridManager.new()
	add_child(grid_manager)
	grid_manager.initialize(GRID_SIZE, CELL_SIZE)

	highlight_manager = HighlightManager.new()
	add_child(highlight_manager)
	highlight_manager.initialize(grid_manager, unit_manager, highlight_cell_scene)

	camera_controller = CameraController.new()
	add_child(camera_controller)
	camera_controller.initialize($Camera2D)

	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.initialize(grid_manager, unit_manager, highlight_manager, turn_manager, $Camera2D)

	enemy_ai = EnemyAIController.new()
	add_child(enemy_ai)
	enemy_ai.initialize(grid_manager, unit_manager, combat_manager)

	# Initialize the original managers
	combat_manager.initialize(unit_manager)
	turn_manager.initialize(unit_manager)
	game_ui.initialize(unit_manager, turn_manager)

	# Add a player unit (hero)
	var hero = unit_manager.add_player_unit("Monk", Vector2i(1, 1), self)

	# Initialize hero with AP values from design doc
	hero.max_ap = 80
	hero.ap = 80

	# Set the hero class to Monk
	hero.set_class("Monk")

	# You could also manually add actions if needed:
	#var bounding_kick = BoundingKick.new()
	#hero.add_action(bounding_kick)
	#
	#var pummel = Pummel.new()
	#hero.add_action(pummel)

	# Create buttons for each action (simplified UI)
	create_action_buttons(hero)

	# Initialize hero with AP values from design doc
	hero.max_ap = 80
	hero.ap = 80

	# Add an enemy unit (goblin)
	var enemy = unit_manager.add_enemy_unit("Goblin", Vector2i(5, 5), self)

	# Create simple REST button
	create_rest_button()

	# Connect signals
	turn_manager.connect("phase_changed", Callable(self, "_on_phase_changed"))
	turn_manager.connect("enemy_turn_started", Callable(self, "_on_enemy_turn_started"))
	turn_manager.connect("player_turn_started", Callable(self, "_on_player_turn_started"))

	# Connect new signals
	input_handler.connect("unit_selected", Callable(self, "_on_input_unit_selected"))
	input_handler.connect("unit_moved", Callable(self, "_on_input_unit_moved"))
	input_handler.connect("unit_attacked", Callable(self, "_on_input_unit_attacked"))
	input_handler.connect("camera_moved", Callable(self, "_on_input_camera_moved"))
	input_handler.connect("turn_ended", Callable(self, "_on_input_turn_ended"))
	input_handler.connect("unit_rested", Callable(self, "_on_input_unit_rested"))

	enemy_ai.connect("enemy_turn_completed", Callable(self, "_on_enemy_turn_completed"))
	enemy_ai.connect("attack_performed", Callable(self, "_on_enemy_attack_performed"))

	# Connect unit signals to combat manager
	for unit in unit_manager.all_units:
		unit.connect("unit_attacked", Callable(self, "_on_unit_attacked"))

func create_action_buttons(unit):
	# Simple UI for actions - you'll want to improve this later
	var button_container = VBoxContainer.new()
	button_container.position = Vector2(get_viewport_rect().size.x - 100, 50)
	button_container.size = Vector2(90, 300)
	add_child(button_container)

	# Add label
	var label = Label.new()
	label.text = "ACTIONS"
	button_container.add_child(label)

	# Create a button for each action
	for action in unit.actions:
		var button = Button.new()
		button.text = action.name
		button.tooltip_text = action.description
		button.custom_minimum_size.y = 30
		button.connect("pressed", Callable(self, "_on_action_button_pressed").bind(action))
		button_container.add_child(button)

func _on_action_button_pressed(action):
	if not selected_unit:
		return

	if not action.can_use(selected_unit):
		print("Cannot use action: not enough AP or already acted")
		return

	print("Selected action: " + action.name)

	# Here you would implement action targeting
	# For simplicity, we'll just find the nearest enemy and use the action on them
	var nearest_enemy = find_nearest_enemy(selected_unit)

	if nearest_enemy:
		selected_unit.execute_action(action.id, nearest_enemy)

		# Clear highlights after action
		highlight_manager.clear_highlights()
	else:
		print("No target available")

func find_nearest_enemy(unit):
	var min_distance = 999
	var nearest = null

	for enemy in unit_manager.enemy_units:
		var dist = grid_manager.get_manhattan_distance(
			grid_manager.world_to_grid(unit.position),
			grid_manager.world_to_grid(enemy.position)
		)

		if dist < min_distance:
			min_distance = dist
			nearest = enemy

	return nearest

func create_rest_button():
	# Simple REST button in the corner
	rest_button = Button.new()
	rest_button.text = "REST"
	rest_button.position = Vector2(10, get_viewport_rect().size.y - 40)
	rest_button.size = Vector2(80, 30)
	rest_button.connect("pressed", Callable(self, "_on_rest_button_pressed"))
	add_child(rest_button)

func _on_rest_button_pressed():
	if selected_unit and selected_unit.can_act():
		_on_input_unit_rested(selected_unit)

func _on_player_turn_started():
	print("Map received player_turn_started signal")
	# Debug the state of all player units
	print("Player units at start of turn:")
	for unit in unit_manager.player_units:
		print("  " + unit.unit_name + " - has_moved: " + str(unit.has_moved) + ", has_acted: " + str(unit.has_acted))

func _process(delta):
	# We no longer need this for movement as we're using tweens
	pass

func _input(event):
	input_handler.process_input(event)

# Pathfinding movement for player units
func move_along_path(unit, path, is_dash, ap_cost):
	if path.size() == 0:
		is_moving = false
		return

	is_moving = true

	# Create a single tween for the entire movement
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)

	# Add all steps to the tween sequence
	for step in path:
		var world_target = grid_manager.grid_to_world(step)
		tween.tween_property(unit, "position", world_target, 0.2)

	# Wait for the entire movement to complete
	await tween.finished

	# Mark that the unit has moved and deduct AP if dashing
	if is_dash:
		unit.dash_to(unit.position, ap_cost)
	else:
		unit.move_to(unit.position)

	# Clear highlights and reset movement state
	highlight_manager.clear_highlights()
	is_moving = false

# Input handler signal callbacks
func _on_input_unit_selected(unit):
	selected_unit = unit
	print("Player unit selected: " + unit.unit_name)

	# Update REST button based on unit state
	rest_button.disabled = unit.has_acted

func _on_input_unit_moved(unit, target_pos, is_dash, ap_cost):
	# Don't start new movement if already moving
	if is_moving:
		return

	selected_unit = unit

	# Calculate a path to the target
	var start_grid_pos = grid_manager.world_to_grid(unit.position)
	var target_grid_pos = grid_manager.world_to_grid(target_pos)

	print("Moving unit from ", start_grid_pos, " to ", target_grid_pos)
	print("Is dash: ", is_dash, " AP cost: ", ap_cost)

	# Get path from grid manager
	var max_range = unit.movement_range
	if is_dash:
		max_range += unit.dash_range

	var path = grid_manager.find_path(start_grid_pos, target_grid_pos, unit_manager, max_range)

	# If the path is empty but we're clicking on a valid tile
	if path.size() == 0 and grid_manager.is_valid_grid_pos(target_grid_pos) and start_grid_pos != target_grid_pos:
		# Check if it's a direct line of sight and a valid destination
		var is_valid_destination = true
		var unit_at_target = unit_manager.get_unit_at_grid_position(target_grid_pos)

		if unit_at_target != null:
			is_valid_destination = false

		if is_valid_destination:
			path = [target_grid_pos]

	if path.size() > 0:
		print("Path found: ", path)
		move_along_path(unit, path, is_dash, ap_cost)
	else:
		print("No valid path found")

func _on_input_unit_attacked(attacker, defender):
	print("Attacking enemy: " + defender.unit_name)
	attacker.attack(defender)
	highlight_manager.clear_highlights()

func _on_input_unit_rested(unit):
	print(unit.unit_name + " rests")

	# Call the unit's rest function
	unit.rest()

	# Update the rest button
	rest_button.disabled = true

	# Clear any highlights
	highlight_manager.clear_highlights()

func _on_input_camera_moved(relative_motion):
	camera_controller.move_camera(relative_motion)

func _on_input_turn_ended():
	turn_manager.end_player_turn()

# Enemy AI signal callbacks
func _on_enemy_turn_started():
	enemy_ai.process_enemy_turn()

func _on_enemy_turn_completed():
	turn_manager.end_enemy_turn()

func _on_enemy_attack_performed(attacker, defender):
	_perform_attack(attacker, defender)

# Unit signal handlers
func _on_unit_attacked(attacker, defender):
	_perform_attack(attacker, defender)

func _perform_attack(attacker, defender):
	print(attacker.unit_name + " attacks " + defender.unit_name)

	# Perform the attack using the combat manager
	var damage = combat_manager.perform_attack(attacker, defender)

	# Flash the defender red
	var tween = create_tween()
	tween.tween_property(defender, "modulate", Color(1.5, 0.5, 0.5), 0.1)
	tween.tween_property(defender, "modulate", Color(1, 1, 1), 0.1)

	# Show damage number
	var damage_number = damage_number_scene.instantiate() as DamageNumber
	damage_number.set_text(str(damage))
	damage_number.position = defender.position + Vector2(0, -15)
	add_child(damage_number)

	# Check if defender died
	if defender.hp <= 0:
		await get_tree().create_timer(0.5).timeout
		defender.queue_free()
		unit_manager.remove_unit(defender)

		# Check for game over conditions
		turn_manager.check_game_over()

func _on_phase_changed(new_phase):
	print("Map _on_phase_changed called with new_phase: " + str(new_phase))

	match new_phase:
		TurnManager.GamePhase.PLAYER_TURN:
			print("Map received player phase change")
			# Make sure REST button is available for new turn
			rest_button.visible = true

		TurnManager.GamePhase.ENEMY_TURN:
			print("Map received enemy phase change")
			# Clean up player-turn state
			highlight_manager.clear_highlights()
			unit_manager.deselect_active_unit()
			selected_unit = null
			rest_button.visible = false

		TurnManager.GamePhase.VICTORY:
			print("Victory!")
			# Show victory UI or effects
			rest_button.visible = false

		TurnManager.GamePhase.DEFEAT:
			print("Defeat!")
			# Show defeat UI or effects
			rest_button.visible = false
