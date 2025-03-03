extends Node2D

# Simple highlight sprite for showing possible movement cells
# This will be instantiated for each cell where movement is possible

var cell_size = 32

func _ready():
	# Adjust the size of the ColorRect
	$ColorRect.size = Vector2(cell_size, cell_size)
	$ColorRect.position = Vector2(-cell_size/2, -cell_size/2)

	# Set a slight animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.5)
	tween.tween_property(self, "modulate:a", 0.8, 0.5)
	tween.set_loops()

func set_cell_size(size):
	cell_size = size
	if has_node("ColorRect"):
		$ColorRect.size = Vector2(cell_size, cell_size)
		$ColorRect.position = Vector2(-cell_size/2, -cell_size/2)
