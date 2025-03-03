extends Unit
class_name HeroUnit

func _ready():
	faction = "player"
	unit_name = "Hero"
	unit_class = "Fighter"

	# Set default sprite frame
	if has_node("Sprite2D"):
		$Sprite2D.frame = 0

	# Add visual HP bar
	if has_node("HPBar"):
		_update_hp_bar()

func _process(delta):
	# Visual indication when selected
	if is_selected:
		if has_node("Sprite2D"):
			# Add a selection effect (could be improved with a proper selection sprite)
			modulate = Color(1.2, 1.2, 1.2)  # Slightly brighter
	else:
		modulate = Color(1, 1, 1)  # Normal color

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
		$HPBar.scale.x = hp_percent
