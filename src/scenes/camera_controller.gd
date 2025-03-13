extends Node
class_name CameraController

var camera: Camera2D
var min_bounds: Vector2
var max_bounds: Vector2
var has_bounds = false

func _init():
	pass

func initialize(cam: Camera2D):
	camera = cam

# Optional: Set limits for camera movement
func set_bounds(min_bound: Vector2, max_bound: Vector2):
	min_bounds = min_bound
	max_bounds = max_bound
	has_bounds = true

	apply_bounds()

func move_camera(relative_motion: Vector2):
	camera.position -= relative_motion

	if has_bounds:
		apply_bounds()

func focus_on_position(position: Vector2):
	camera.position = position

	if has_bounds:
		apply_bounds()

func apply_bounds():
	if camera.position.x < min_bounds.x:
		camera.position.x = min_bounds.x
	elif camera.position.x > max_bounds.x:
		camera.position.x = max_bounds.x

	if camera.position.y < min_bounds.y:
		camera.position.y = min_bounds.y
	elif camera.position.y > max_bounds.y:
		camera.position.y = max_bounds.y
