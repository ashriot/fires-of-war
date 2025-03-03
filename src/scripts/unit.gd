extends Node2D
class_name Unit

# Unit identification
var unit_id = ""
var unit_name = "Unit"
var unit_class = "Fighter"
var faction = "neutral"  # "player", "enemy", "neutral"

# Unit stats
var level = 1
var hp = 100
var max_hp = 100
var ap = 6  # Action Points
var max_ap = 6
var movement_range = 3

# Combat stats
var strength = 10
var agility = 10
var intelligence = 10
var parry = 3  # Reduces melee damage
var evasion = 3  # Reduces ranged damage
var willpower = 3  # Reduces spell damage

# Unit state
var has_moved = false
var has_acted = false
var is_selected = false

# Signals
signal unit_selected(unit)
signal unit_moved(unit)
signal unit_attacked(unit, target)
signal unit_damaged(unit, amount)
signal unit_died(unit)

func _ready():
	pass

func select():
	if not is_selected:
		is_selected = true
		emit_signal("unit_selected", self)

func deselect():
	is_selected = false

func move_to(target_position):
	# Will be implemented by the map/movement manager
	has_moved = true
	emit_signal("unit_moved", self)

func can_move():
	return !has_moved

func can_act():
	return !has_acted

func end_turn():
	# Reset unit's turn state
	has_moved = false
	has_acted = false

	# Recover some AP
	ap = min(ap + 2, max_ap)

	# If the unit rested (didn't move), recover HP
	if !has_moved:
		var recovery = 5 + int(level / 5)
		heal(recovery)

func take_damage(amount, damage_type="melee"):
	var actual_damage = amount

	# Apply defense based on damage type
	match damage_type:
		"melee":
			actual_damage = max(1, amount - parry)
		"ranged":
			actual_damage = max(1, amount - evasion)
		"spell":
			actual_damage = max(1, amount - willpower)

	hp = max(0, hp - actual_damage)
	emit_signal("unit_damaged", self, actual_damage)

	if hp <= 0:
		die()

	return actual_damage

func heal(amount):
	var old_hp = hp
	hp = min(max_hp, hp + amount)
	return hp - old_hp  # Return actual amount healed

func die():
	emit_signal("unit_died", self)
	# Implementation will vary based on unit type

func attack(target, action_name="basic_attack"):
	# Will be implemented by subclasses or combat manager
	has_acted = true
	emit_signal("unit_attacked", self, target)

func get_info():
	return {
		"id": unit_id,
		"name": unit_name,
		"class": unit_class,
		"faction": faction,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"ap": ap,
		"max_ap": max_ap,
		"movement_range": movement_range,
		"str": strength,
		"agi": agility,
		"int": intelligence,
		"parry": parry,
		"evasion": evasion,
		"willpower": willpower
	}
