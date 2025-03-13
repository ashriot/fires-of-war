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
var ap = 80  # Action Points (changed from 6 to 80 per design doc)
var max_ap = 80
var movement_range = 3
var dash_range = 2  # New property for dash range

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
var has_dashed = false  # New property to track if the unit dashed
var is_selected = false

# AP costs
var dash_ap_cost = 35  # From design doc, cost per square

# Signals
signal unit_selected(unit)
signal unit_moved(unit)
signal unit_attacked(unit, target)
signal unit_damaged(unit, amount)
signal unit_died(unit)
signal unit_rested(unit)  # New signal for the Rest action

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

func dash_to(target_position, ap_spent):
	# Handle dash movement
	has_moved = true
	has_dashed = true
	ap = max(0, ap - ap_spent)
	emit_signal("unit_moved", self)

func can_move():
	return !has_moved

func can_act():
	return !has_acted

func rest():
	# Implement the Rest action
	has_acted = true

	# Calculate AP recovery based on movement state
	var ap_recovery = 0

	if not has_moved:
		# Rest without moving
		ap_recovery = 20

		# HP recovery (from the design doc)
		var hp_recovery = 5 + int(level / 5)
		heal(hp_recovery)
	elif not has_dashed:
		# Rest after moving but not dashing
		ap_recovery = 15
	else:
		# Rest after dashing
		ap_recovery = 10

	# Apply AP recovery
	ap = min(ap + ap_recovery, max_ap)

	emit_signal("unit_rested", self)
	return true

func end_turn():
	# Reset unit's turn state
	has_moved = false
	has_acted = false
	has_dashed = false  # Reset dash state

	# Recover some AP (focus)
	ap = min(ap + 20, max_ap)  # 20 focus per turn from design doc

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
