extends Action
class_name Pummel

func _init():
	id = "pummel"
	name = "Pummel"
	description = "A melee attack that strikes multiple times"
	ap_cost = 45
	max_level = 10
	action_type = ActionType.MELEE
	range_min = 1
	range_max = 1
	hit_count = 5

	# Base stats at level 1
	damage_base = 9
	damage_scaling = 1.2  # Approximately matches the progression in the document

func execute(user, target):
	# Calculate base damage
	var base_damage = calculate_damage(user)

	# Deal damage 5 times (hit_count = 5)
	for i in range(hit_count):
		target.take_damage(base_damage, "melee")

	# Mark as acted and deduct AP
	user.has_acted = true
	user.ap -= ap_cost

	action_used.emit(self)
	return true
