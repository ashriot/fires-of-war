extends Action
class_name BoundingKick

func _init():
	id = "bounding_kick"
	name = "Bounding Kick"
	description = "A leaping attack that may grant an Auto-Critical on your next turn"
	ap_cost = 10
	max_level = 9
	action_type = ActionType.MELEE
	range_min = 1
	range_max = 2
	hit_count = 2

	# Base stats at level 1
	damage_base = 11
	damage_scaling = 1.3  # Approximately matches the progression in the document

	# Auto-critical effect
	applies_status = true
	status_effect = "auto_critical"
	status_chance = 0.40  # 40% at level 1
	status_chance_scaling = 0.05  # +5% per level
	status_duration = 1  # Lasts until next turn

func execute(user, target):
	# Calculate base damage
	var base_damage = calculate_damage(user)

	# Deal damage twice (hit_count = 2)
	for i in range(hit_count):
		target.take_damage(base_damage, "melee")

	# Check for Auto-Critical chance
	if randf() <= get_scaled_chance():
		# Apply auto_critical status to the user
		print("Gained Auto-Critical for next turn!")

		# In a full implementation, you would set a property on the unit
		if user.has_method("set_auto_critical"):
			user.set_auto_critical(true)

	# Mark as acted and deduct AP
	user.has_acted = true
	user.ap -= ap_cost

	action_used.emit(self)
	return true
