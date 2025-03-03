extends Node
class_name AnimationManager

# References
var combat_manager = null

# Preloaded scenes
var damage_number_scene = preload("res://src/scenes/damage_number.tscn")
var attack_flash_scene = preload("res://src/scenes/attack_flash.tscn")

# Signals
signal animation_finished(animation_name)

func _ready():
	pass

func initialize(combat_mgr):
	combat_manager = combat_mgr

	# Connect to combat signals
	combat_manager.connect("combat_started", Callable(self, "_on_combat_started"))
	combat_manager.connect("damage_dealt", Callable(self, "_on_damage_dealt"))

func play_attack_animation(attacker, defender):
	# Create attack flash effect
	var flash = attack_flash_scene.instantiate()
	defender.add_child(flash)

	# Shake the defender
	var original_pos = defender.position
	var tween = create_tween()
	tween.tween_property(defender, "position", original_pos + Vector2(2, 0), 0.05)
	tween.tween_property(defender, "position", original_pos + Vector2(-2, 0), 0.05)
	tween.tween_property(defender, "position", original_pos, 0.05)

	await tween.finished

	# Signal that the animation is done
	emit_signal("animation_finished", "attack")

func play_damage_number(unit, amount):
	# Create floating damage number
	var damage_number = damage_number_scene.instantiate()
	damage_number.position = unit.position + Vector2(0, -15)
	damage_number.set_text(str(amount))
	get_tree().current_scene.add_child(damage_number)

	# Wait for the animation to finish
	await get_tree().create_timer(0.8).timeout

	# Signal that the animation is done
	emit_signal("animation_finished", "damage_number")

# Signal handlers
func _on_combat_started(attacker, defender):
	# Play attack animation
	play_attack_animation(attacker, defender)

func _on_damage_dealt(unit, amount):
	# Show damage number
	play_damage_number(unit, amount)
