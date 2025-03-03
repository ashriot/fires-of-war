extends Node2D
class_name AttackFlash

func _ready():
	# Resize the color rect to cover the parent
	if get_parent() is Node2D:
		var parent_size = Vector2(16, 16)  # Default size

		if get_parent().has_node("Sprite2D"):
			var sprite = get_parent().get_node("Sprite2D")
			var texture_size = sprite.texture.get_size()
			var frame_count = max(sprite.hframes, 1)
			parent_size = Vector2(texture_size.x / frame_count, texture_size.y)

		$ColorRect.size = parent_size
		$ColorRect.position = -parent_size / 2

	# Animate the flash
	var tween = create_tween()
	tween.tween_property($ColorRect, "color:a", 0.0, 0.2)
	tween.tween_callback(Callable(self, "queue_free"))
