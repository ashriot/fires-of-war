extends CanvasLayer
class_name GameUI

# References to UI elements
@onready var turn_label = $TurnInfo/TurnLabel
@onready var phase_label = $TurnInfo/PhaseLabel
@onready var unit_info_panel = $UnitInfoPanel
@onready var unit_name_label = $UnitInfoPanel/UnitNameLabel
@onready var unit_class_label = $UnitInfoPanel/UnitClassLabel
@onready var unit_hp_label = $UnitInfoPanel/HpLabel
@onready var unit_ap_label = $UnitInfoPanel/ApLabel
@onready var end_turn_button = $EndTurnButton

# References to game systems
var unit_manager = null
var turn_manager = null

func _ready():
	unit_info_panel.visible = false


func initialize(unit_mgr, turn_mgr):
	unit_manager = unit_mgr
	turn_manager = turn_mgr

	# Connect signals
	unit_manager.connect("unit_added", Callable(self, "_on_unit_added"))
	unit_manager.connect("unit_removed", Callable(self, "_on_unit_removed"))
	unit_manager.connect("unit_selected", Callable(self, "_on_unit_selected"))
	turn_manager.connect("phase_changed", Callable(self, "_on_phase_changed"))
	turn_manager.connect("turn_started", Callable(self, "_on_turn_started"))

	# Update UI with initial state
	update_turn_info(turn_manager.turn_number, turn_manager.current_phase)

func update_turn_info(turn_number, phase):
	turn_label.text = "Turn: " + str(turn_number)

	var phase_text = ""
	match phase:
		TurnManager.GamePhase.PLAYER_TURN:
			phase_text = "Player Phase"
			#end_turn_button.visible = true
		TurnManager.GamePhase.ENEMY_TURN:
			phase_text = "Enemy Phase"
			end_turn_button.visible = false
		TurnManager.GamePhase.VICTORY:
			phase_text = "Victory!"
			end_turn_button.visible = false
		TurnManager.GamePhase.DEFEAT:
			phase_text = "Defeat!"
			end_turn_button.visible = false

	phase_label.text = phase_text

func update_unit_info(unit):
	if unit:
		var info = unit.get_info()
		unit_name_label.text = info.name
		unit_class_label.text = "Class: " + info.class
		unit_hp_label.text = str(info.hp) + "  " + str(info.max_hp)
		unit_ap_label.text = str(info.ap) + "  " + str(info.max_ap)

		unit_info_panel.visible = true
	else:
		unit_info_panel.visible = false

# Signal handlers
func _on_unit_added(unit):
	# Connect to the unit's selection signal
	unit.connect("unit_selected", Callable(self, "_on_unit_selected"))

func _on_unit_removed(unit):
	# If the removed unit was being displayed, hide the panel
	if unit_manager.active_unit == unit:
		update_unit_info(null)

func _on_unit_selected(unit):
	update_unit_info(unit)

func _on_phase_changed(new_phase):
	update_turn_info(turn_manager.turn_number, new_phase)

func _on_turn_started(turn_number):
	update_turn_info(turn_number, turn_manager.current_phase)

func _on_end_turn_button_pressed():
	print("End turn button pressed")
	if turn_manager.current_phase == TurnManager.GamePhase.PLAYER_TURN:
		# This is the correct way to end the player's turn
		turn_manager.end_player_turn()
