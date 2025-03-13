extends Node
class_name HighlightManager

var grid_manager: GridManager
var unit_manager
var highlight_cells = []
var highlight_cell_scene

# Movement highlight colors
var normal_move_color = Color(0.2, 0.7, 0.2, 0.5)  # Green for regular movement
var dash_move_color = Color(0.9, 0.6, 0.1, 0.5)    # Orange for dash movement
var attack_range_color = Color(0.7, 0.2, 0.2, 0.5) # Red for attack range

func _init():
	pass

func initialize(grid_mgr, unit_mgr, highlight_scene):
	grid_manager = grid_mgr
	unit_manager = unit_mgr
	highlight_cell_scene = highlight_scene

func show_movement_range(unit):
	# Clear any existing highlights
	clear_highlights()

	# If the unit has already moved, don't show movement range
	if unit.has_moved:
		return

	var center_pos = grid_manager.world_to_grid(unit.position)
	var base_movement_range = unit.movement_range

	# For now, we'll add a dash range of 2 to all units
	# Later we can update the Unit class to have a dash_range property
	var dash_range = 2
	var max_range = base_movement_range + dash_range

	# Get all cells in maximum range (base + dash)
	var all_cells = grid_manager.get_cells_in_range(center_pos, max_range)

	# Get just the base movement cells
	var base_cells = grid_manager.get_cells_in_range(center_pos, base_movement_range)

	# We need to check each cell to see if it's in base movement or dash range
	for cell_pos in all_cells:
		# Check if there's already a unit at this position
		var unit_at_pos = unit_manager.get_unit_at_grid_position(cell_pos)
		if not unit_at_pos:
			# Create a highlight at this position
			var highlight = highlight_cell_scene.instantiate()
			highlight.position = grid_manager.grid_to_world(cell_pos)
			highlight.set_cell_size(grid_manager.cell_size)

			# Determine color based on whether this is in base range or dash range
			if cell_pos in base_cells:
				highlight.modulate = normal_move_color
				# Store the movement type as metadata
				highlight.set_meta("move_type", "normal")
			else:
				highlight.modulate = dash_move_color
				# Store the movement type as metadata
				highlight.set_meta("move_type", "dash")

			# Store the grid position for later reference
			highlight.set_meta("grid_pos", cell_pos)

			get_parent().add_child(highlight)
			highlight_cells.append(highlight)
		elif unit_at_pos.faction != unit.faction:
			# Highlight enemies in attack range with a different color
			var highlight = highlight_cell_scene.instantiate()
			highlight.position = grid_manager.grid_to_world(cell_pos)
			highlight.set_cell_size(grid_manager.cell_size)
			highlight.modulate = attack_range_color
			get_parent().add_child(highlight)
			highlight_cells.append(highlight)

func get_movement_type(grid_pos):
	# Check highlight cells to determine if this is a normal move or dash
	for highlight in highlight_cells:
		if highlight.has_meta("grid_pos") and highlight.get_meta("grid_pos") == grid_pos:
			if highlight.has_meta("move_type"):
				return highlight.get_meta("move_type")
			return "normal"  # Default for backwards compatibility

	return "invalid"

func clear_highlights():
	# Remove all highlight cells
	for highlight in highlight_cells:
		highlight.queue_free()
	highlight_cells.clear()
