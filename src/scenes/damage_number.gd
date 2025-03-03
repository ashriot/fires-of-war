extends Node2D
class_name DamageNumber

@onready var label := $Label as Label

func _ready():
	# Animate the damage number
	var tween = create_tween()

	# Rise up and fade out
	tween.tween_property(self, "position", position + Vector2(0, -20), 0.7)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.7)

	# Queue free after animation
	tween.tween_callback(Callable(self, "queue_free"))

func set_text(text):
	label.text = text

	if int(text) > 20:  # Arbitrary threshold for what's considered a critical hit
		label.modulate = Color(1, 0.9, 0, 1)
