extends Resource
class_name Action

# Basic properties
var id: String = ""
var name: String = ""
var description: String = ""
var ap_cost: int = 0
var level: int = 1
var max_level: int = 10

# Action type
enum ActionType { MELEE, RANGED, SPELL, SUPPORT }
var action_type: ActionType = ActionType.MELEE

# Range properties
var range_min: int = 1
var range_max: int = 1
var is_aoe: bool = false
var aoe_radius: int = 0

# Movement restrictions
var can_move_before: bool = true
var can_dash_before: bool = true

# Combat properties
var damage_base: int = 10
var damage_scaling: float = 1.5  # Damage increase per level
var hit_count: int = 1
var crit_chance_bonus: float = 0.0
var impact_bonus: float = 0.0  # Additional damage on crits

# Effect properties
var applies_status: bool = false
var status_effect: String = ""
var status_chance: float = 0.0
var status_chance_scaling: float = 0.05  # Increase per level
var status_duration: int = 0

# Signals
signal action_used(action)
signal action_upgraded(action)

# Virtual function for executing the action
func execute(user, target):
	# This will be overridden by specific action implementations
	action_used.emit(self)
	return true

# Level up the action
func level_up():
	if level < max_level:
		level += 1
		action_upgraded.emit(self)
		return true
	return false

# Calculate damage with level scaling
func get_scaled_damage() -> int:
	return damage_base + int(damage_scaling * (level - 1))

# Calculate chance with level scaling
func get_scaled_chance() -> float:
	return status_chance + (status_chance_scaling * (level - 1))

# Calculate damage value based on unit stats
func calculate_damage(user):
	var damage = get_scaled_damage()

	# Apply stat bonuses based on action type
	match action_type:
		ActionType.MELEE:
			damage += user.strength * 0.5
		ActionType.RANGED:
			damage += user.agility * 0.5
		ActionType.SPELL:
			damage += user.intelligence * 0.5

	return damage

# Check if the action can be used
func can_use(user) -> bool:
	return user.ap >= ap_cost and not user.has_acted
