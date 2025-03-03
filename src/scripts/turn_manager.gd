extends Node
class_name TurnManager

# Game phases
enum GamePhase {
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

# Current game state
var current_phase = GamePhase.PLAYER_TURN
var turn_number = 1
var is_transitioning = false  # Flag to prevent double transitions

# References
var unit_manager = null

# Signals
signal phase_changed(new_phase)
signal turn_started(turn_number)
signal player_turn_started
signal enemy_turn_started
signal victory
signal defeat

func _ready():
	pass

func initialize(unit_mgr):
	unit_manager = unit_mgr

	# Start the first turn - just set things up but don't emit signals yet
	# to avoid duplicate signals
	current_phase = GamePhase.PLAYER_TURN
	emit_signal("turn_started", turn_number)
	emit_signal("phase_changed", current_phase)
	emit_signal("player_turn_started")

func start_turn():
	# Guard against duplicate calls
	if is_transitioning:
		return

	is_transitioning = true

	print("Starting new turn: " + str(turn_number + 1))
	# Increment turn number
	turn_number += 1

	# Reset all units for the new turn
	print("Resetting all units for new turn")
	unit_manager.end_all_turns()

	emit_signal("turn_started", turn_number)

	# Start with player phase - don't emit player_turn_started here
	# as set_phase will do that
	set_phase(GamePhase.PLAYER_TURN)

	is_transitioning = false

func end_player_turn():
	# Guard against duplicate calls
	if is_transitioning or current_phase != GamePhase.PLAYER_TURN:
		return

	is_transitioning = true
	set_phase(GamePhase.ENEMY_TURN)
	is_transitioning = false

func end_enemy_turn():
	print("end_enemy_turn() called - current phase: " + str(current_phase))
	# Guard against duplicate calls
	if is_transitioning:
		print("  Skipping end_enemy_turn - already transitioning")
		return

	if current_phase != GamePhase.ENEMY_TURN:
		print("  Skipping end_enemy_turn - not in enemy phase (in phase " + str(current_phase) + ")")
		return

	print("  Starting end_enemy_turn transition")
	is_transitioning = true

	# Let's explicitly call these steps instead of relying on start_turn
	# This bypasses any potential issues in start_turn
	print("  Incrementing turn number")
	turn_number += 1

	print("  Resetting all units")
	unit_manager.end_all_turns()

	print("  Emitting turn_started signal")
	emit_signal("turn_started", turn_number)

	print("  Setting phase to PLAYER_TURN")
	# This will also emit the player_turn_started signal
	set_phase(GamePhase.PLAYER_TURN)

	is_transitioning = false
	print("  Finished end_enemy_turn transition")

func set_phase(new_phase):
	print("set_phase() called - current: " + str(current_phase) + ", new: " + str(new_phase))

	# Only change if it's actually different
	if current_phase == new_phase:
		print("  Skipping set_phase - phase already set to " + str(new_phase))
		return

	print("  Changing phase from " + str(current_phase) + " to " + str(new_phase))
	current_phase = new_phase

	# Special case for PLAYER_TURN to ensure full reset
	if new_phase == GamePhase.PLAYER_TURN:
		print("  Player phase started")
		# Let the UI and other systems know player phase has started
		print("  Emitting phase_changed signal")
		emit_signal("phase_changed", new_phase)
		print("  Emitting player_turn_started signal")
		emit_signal("player_turn_started")
	else:
		print("  Emitting phase_changed signal")
		emit_signal("phase_changed", new_phase)

		if new_phase == GamePhase.ENEMY_TURN:
			print("  Enemy phase started, emitting enemy_turn_started signal")
			emit_signal("enemy_turn_started")

func check_game_over():
	# Check for victory (no enemies left)
	if unit_manager.enemy_units.size() == 0:
		set_phase(GamePhase.VICTORY)
		emit_signal("victory")
		return true

	# Check for defeat (no player units left)
	if unit_manager.player_units.size() == 0:
		set_phase(GamePhase.DEFEAT)
		emit_signal("defeat")
		return true

	return false
