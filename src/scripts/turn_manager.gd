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
	unit_manager.connect("turn_ended", Callable(self, "_on_turn_ended"))

	# Start the first turn
	start_turn()

func start_turn():
	turn_number += 1

	# Reset all units for the new turn
	unit_manager.end_all_turns()

	emit_signal("turn_started", turn_number)

	# Start with player phase
	set_phase(GamePhase.PLAYER_TURN)

func end_player_turn():
	if current_phase == GamePhase.PLAYER_TURN:
		set_phase(GamePhase.ENEMY_TURN)
		process_enemy_turn()

func process_enemy_turn():
	# Loop through all enemy units and let them take their turn
	for enemy in unit_manager.enemy_units:
		await get_tree().create_timer(0.5).timeout
		enemy.take_turn(unit_manager.player_units)

	# After all enemies have moved, go back to player turn
		await get_tree().create_timer(0.5).timeout
	set_phase(GamePhase.PLAYER_TURN)

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

func set_phase(new_phase):
	current_phase = new_phase
	emit_signal("phase_changed", new_phase)

	match new_phase:
		GamePhase.PLAYER_TURN:
			emit_signal("player_turn_started")
		GamePhase.ENEMY_TURN:
			emit_signal("enemy_turn_started")

# Signal handlers
func _on_turn_ended():
	# Check if the game is over after a turn ends
	check_game_over()
