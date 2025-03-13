extends Unit
class_name HeroUnit

# List of available actions
var actions = []

# Status effect tracking
var auto_critical_next_turn = false

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
		$HPBar.value = hp_percent

# Add an action to this unit
func add_action(action):
	actions.append(action)

# Set the class for this hero
func set_class(job_name):
	unit_class = job_name

	# Reset actions
	actions.clear()

	# Add actions based on class
	match job_name:
		"Monk":
			add_action(BoundingKick.new())
			add_action(Pummel.new())
		"Fighter":
			# Add Fighter actions when implemented
			pass
		# Add more classes as needed
		_:
			# Default actions
			pass

func execute_action(action_id, target):
	# Find the action with this ID
	for action in actions:
		if action.id == action_id:
			return action.execute(self, target)

	# If we get here, action wasn't found
	return false

# Status effect setter
func set_auto_critical(value):
	auto_critical_next_turn = value

func end_turn():
	super.end_turn()

	# Reset status effects at end of turn
	auto_critical_next_turn = false
