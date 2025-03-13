extends Node
class_name EnemyAIController

signal enemy_turn_completed
signal attack_performed(attacker, defender)

var grid_manager: GridManager
var unit_manager
var combat_manager

func _init():
	pass

func initialize(grid_mgr, unit_mgr, combat_mgr):
	grid_manager = grid_mgr
	unit_manager = unit_mgr
	combat_manager = combat_mgr

func process_enemy_turn():
	print("Processing enemy turn")
	# Process each enemy unit's turn one at a time
	var enemy_units = unit_manager.enemy_units.duplicate()
	await take_enemy_turn(enemy_units)

	print("All enemies have moved, ending enemy turn")
	enemy_turn_completed.emit()

func take_enemy_turn(remaining_enemies):
	if remaining_enemies.size() == 0:
		# All enemies have taken their turn
		return

	var enemy = remaining_enemies.pop_front()

	# Find closest player unit
	var target = find_closest_player_unit(enemy)

	if target:
		var enemy_grid_pos = grid_manager.world_to_grid(enemy.position)
		var target_grid_pos = grid_manager.world_to_grid(target.position)
		var distance = grid_manager.get_manhattan_distance(enemy_grid_pos, target_grid_pos)

		if distance <= 1:
			# Attack if adjacent
			await perform_attack(enemy, target)
			await get_tree().create_timer(0.8).timeout
		else:
			# Move toward player, using the unit's movement range
			# Note: pass the target's position - pathfinding will handle stopping adjacent
			var path = grid_manager.find_path(enemy_grid_pos, target_grid_pos, unit_manager, enemy.movement_range)

			if path.size() > 0:
				# Move along the path (up to movement range)
				await move_along_path(enemy, path)

				# After moving, check if we can attack
				var new_enemy_pos = grid_manager.world_to_grid(enemy.position)
				var new_distance = grid_manager.get_manhattan_distance(new_enemy_pos, target_grid_pos)

				if new_distance <= 1:
					# We moved adjacent to player, attack
					await perform_attack(enemy, target)
					await get_tree().create_timer(0.8).timeout
				else:
					await get_tree().create_timer(0.3).timeout
			else:
				await get_tree().create_timer(0.3).timeout
	else:
		# No player units found
		await get_tree().create_timer(0.1).timeout

	# Process next enemy
	await take_enemy_turn(remaining_enemies)

# New function to handle moving along a path
func move_along_path(enemy, path):
	# Create a single tween for the entire movement
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)

	# Add all steps to the tween sequence
	for step in path:
		var world_target = grid_manager.grid_to_world(step)
		tween.tween_property(enemy, "position", world_target, 0.2)

	# Wait for the entire movement to complete
	await tween.finished

	# Mark that the enemy has moved
	enemy.has_moved = true

	# Brief pause after completing movement
	await get_tree().create_timer(0.1).timeout

func find_closest_player_unit(enemy_unit):
	var closest_unit = null
	var min_distance = 999

	for unit in unit_manager.player_units:
		var enemy_pos = grid_manager.world_to_grid(enemy_unit.position)
		var player_pos = grid_manager.world_to_grid(unit.position)
		var distance = grid_manager.get_manhattan_distance(enemy_pos, player_pos)

		if distance < min_distance:
			min_distance = distance
			closest_unit = unit

	return closest_unit

func perform_attack(attacker, defender):
	print(attacker.unit_name + " attacks " + defender.unit_name)

	emit_signal("attack_performed", attacker, defender)

	# Wait for animation to complete
	await get_tree().create_timer(0.5).timeout
