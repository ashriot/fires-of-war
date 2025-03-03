extends Node
class_name UnitManager

# References to unit collections
var player_units = []
var enemy_units = []
var all_units = []

# Signals
signal unit_added(unit)
signal unit_removed(unit)
signal turn_ended

# Current active unit
var active_unit = null

# References to scenes
var hero_unit_scene = preload("res://src/scenes/hero_unit.tscn")
var enemy_unit_scene = preload("res://src/scenes/enemy_unit.tscn")

func _ready():
	pass

func add_player_unit(unit_class, grid_position, map_node):
	var unit = hero_unit_scene.instantiate()
	unit.unit_class = unit_class
	unit.position = _grid_to_world(grid_position)

	# Connect signals
	unit.connect("unit_selected", Callable(self, "_on_unit_selected"))
	unit.connect("unit_died", Callable(self, "_on_unit_died"))

	# Add to collections
	player_units.append(unit)
	all_units.append(unit)

	# Add to scene
	map_node.add_child(unit)

	emit_signal("unit_added", unit)
	return unit

func add_enemy_unit(unit_class, grid_position, map_node):
	var unit = enemy_unit_scene.instantiate()
	unit.unit_class = unit_class
	unit.position = _grid_to_world(grid_position)

	# Connect signals
	unit.connect("unit_died", Callable(self, "_on_unit_died"))

	# Add to collections
	enemy_units.append(unit)
	all_units.append(unit)

	# Add to scene
	map_node.add_child(unit)

	emit_signal("unit_added", unit)
	return unit

func remove_unit(unit):
	if unit in player_units:
		player_units.erase(unit)

	if unit in enemy_units:
		enemy_units.erase(unit)

	if unit in all_units:
		all_units.erase(unit)

	emit_signal("unit_removed", unit)

func get_unit_at_grid_position(grid_pos):
	for unit in all_units:
		var unit_grid_pos = _world_to_grid(unit.position)
		if unit_grid_pos == grid_pos:
			return unit
	return null

func select_unit(unit):
	if active_unit:
		active_unit.deselect()

	active_unit = unit
	if unit:
		unit.select()

func deselect_active_unit():
	if active_unit:
		active_unit.deselect()
		active_unit = null

func end_all_turns():
	for unit in all_units:
		unit.end_turn()

	emit_signal("turn_ended")

# Private utility functions
func _grid_to_world(grid_pos):
	var cell_size = 12  # This should match your grid size
	return Vector2(grid_pos.x * cell_size + cell_size/2, grid_pos.y * cell_size + cell_size/2)

func _world_to_grid(world_pos):
	var cell_size = 12  # This should match your grid size
	return Vector2i(int(world_pos.x / cell_size), int(world_pos.y / cell_size))

# Signal handlers
func _on_unit_selected(unit):
	select_unit(unit)

func _on_unit_died(unit):
	# Handle unit death
	remove_unit(unit)
	unit.queue_free()
