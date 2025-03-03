extends Node
class_name CombatManager

# References
var unit_manager = null

# Constants
const BASE_ATTACK_DAMAGE = 15
const CRIT_CHANCE = 0.15
const CRIT_MULTIPLIER = 1.5

# Signals
signal combat_started(attacker, defender)
signal combat_ended(attacker, defender)
signal damage_dealt(unit, amount)

func _ready():
	pass

func initialize(unit_mgr):
	unit_manager = unit_mgr

func perform_attack(attacker, defender, action_name="basic_attack"):
	emit_signal("combat_started", attacker, defender)

	# Base damage calculation
	var damage = calculate_damage(attacker, defender, action_name)

	# Apply damage to defender
	var actual_damage = defender.take_damage(damage, "melee")
	emit_signal("damage_dealt", defender, actual_damage)

	# Check for counter-attack (if defender is still alive and it's melee range)
	if defender.hp > 0 and is_melee_range(attacker, defender):
		# Counter-attack does less damage
		var counter_damage = calculate_damage(defender, attacker, "counter") * 0.7
		var actual_counter = attacker.take_damage(counter_damage, "melee")
		emit_signal("damage_dealt", attacker, actual_counter)

	emit_signal("combat_ended", attacker, defender)

	# Check if any units died
	check_for_deaths()

	return damage

func calculate_damage(attacker, defender, action_name="basic_attack"):
	var base_damage = BASE_ATTACK_DAMAGE

	# Add attribute bonuses
	base_damage += attacker.strength * 1.5

	# Random variance (±10%)
	var variance = randf_range(0.9, 1.1)
	base_damage *= variance

	# Check for critical hit
	var is_crit = randf() < CRIT_CHANCE
	if is_crit:
		base_damage *= CRIT_MULTIPLIER
		print("Critical hit!")

	# Round to integer
	return int(base_damage)

func is_melee_range(unit1, unit2):
	# Calculate grid distance between units
	var grid_pos1 = world_to_grid(unit1.position)
	var grid_pos2 = world_to_grid(unit2.position)

	var distance = abs(grid_pos1.x - grid_pos2.x) + abs(grid_pos1.y - grid_pos2.y)
	return distance <= 1

func check_for_deaths():
	# This will be handled by the unit signals, but we can add additional logic here if needed
	pass

# Utility functions
func world_to_grid(world_pos):
	var cell_size = 12  # This should match your grid size
	return Vector2i(int(world_pos.x / cell_size), int(world_pos.y / cell_size))
