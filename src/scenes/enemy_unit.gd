extends Unit
class_name EnemyUnit

var aggression = 0.7  # How likely the enemy is to attack vs. move (0-1)
var detection_range = 5  # How far the enemy can "see" player units

func _ready():
	faction = "enemy"
	unit_name = "Goblin"
	unit_class = "Goblin"

	# Stats based on enemy type
	strength = 8
	agility = 12
	intelligence = 4
	parry = 2
	evasion = 3
	willpower = 1

	max_hp = 75
	hp = max_hp

	# Set default sprite frame for enemy
	if has_node("Sprite2D"):
		$Sprite2D.frame = 0

	# Add visual HP bar
	if has_node("HPBar"):
		_update_hp_bar()

func take_damage(amount, damage_type="melee"):
	var actual_damage = super.take_damage(amount, damage_type)
	_update_hp_bar()
	return actual_damage

func heal(amount):
	var amount_healed = super.heal(amount)
	_update_hp_bar()
	return amount_healed

func _update_hp_bar():
	if has_node("HPBar"):
		var hp_percent = float(hp) / float(max_hp)
		$HPBar.value = hp_percent

func get_ai_action(player_units):
	# Determine what action to take based on the situation
	var closest_unit = find_closest_unit(player_units)

	if closest_unit:
		var distance = grid_distance_to(closest_unit)

		# If in attack range, attack
		if distance <= 1:
			return {
				"action": "attack",
				"target": closest_unit
			}

		# If close enough, move toward player
		elif distance <= detection_range:
			return {
				"action": "move",
				"target_unit": closest_unit
			}

	# Default - do nothing
	return {
		"action": "wait"
	}

func take_turn(player_units):
	# Get the AI's decision
	var action = get_ai_action(player_units)

	# Execute the decided action
	match action.action:
		"attack":
			if can_act():
				attack(action.target)
				return true
		"move":
			if can_move():
				# Movement is handled by the map/movement manager
				# This will emit a signal that the map can respond to
				unit_moved.emit(self)
				has_moved = true
				return true
		"wait":
			# Do nothing
			pass

	return false  # Return whether the unit did something

func find_closest_unit(units):
	var closest = null
	var min_distance = 999

	for unit in units:
		var distance = grid_distance_to(unit)
		if distance < min_distance:
			min_distance = distance
			closest = unit

	return closest

func grid_distance_to(other_unit):
	# Manhattan distance
	var my_grid_pos = Vector2i(int(position.x / 12), int(position.y / 12))
	var other_grid_pos = Vector2i(int(other_unit.position.x / 12), int(other_unit.position.y / 12))

	return abs(my_grid_pos.x - other_grid_pos.x) + abs(my_grid_pos.y - other_grid_pos.y)
