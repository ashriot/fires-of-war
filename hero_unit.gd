extends Node2D
class_name Unit

# Basic unit class for our tactics RPG

# Unit stats
var unit_name = "Hero"
var unit_class = "Fighter"
var level = 1
var hp = 100
var max_hp = 100
var ap = 6  # Action Points
var max_ap = 6
var movement_range = 3

# Unit state
var has_moved = false
var has_acted = false

func _ready():
	pass

func move_to(target_position):
	# This will be called by the map when the unit needs to move
	# The actual movement logic is in the map script for simplicity
	pass

func end_turn():
	# Reset unit's turn state
	has_moved = false
	has_acted = false

	# Recover some AP
	ap = min(ap + 2, max_ap)

func take_damage(amount):
	hp = max(0, hp - amount)
	if hp <= 0:
		print(unit_name + " has been defeated!")
		# Handle defeat here

func get_info():
	return {
		"name": unit_name,
		"class": unit_class,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"ap": ap,
		"max_ap": max_ap,
		"movement_range": movement_range
	}
