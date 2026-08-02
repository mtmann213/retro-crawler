class_name FloorClock
extends PanelContainer

@onready var time_label: Label = %TimeLabel
@onready var state_label: Label = %StateLabel


func present(state: FloorState) -> void:
	var minutes := int(state.remaining_seconds / 60.0)
	var seconds := state.remaining_seconds % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
	if not state.clock_started:
		state_label.text = "PAUSED // LEAVE SHELTER TO START"
	elif state.deadline_resolved:
		state_label.text = "DEADLINE // EXTRACTION REQUIRED"
	elif state.remaining_seconds <= 60:
		state_label.text = "FINAL WARNING"
	elif state.remaining_seconds <= 180:
		state_label.text = "HOSTILE MODIFIERS ACTIVE"
	elif state.remaining_seconds <= 360:
		state_label.text = "POWER INSTABILITY"
	else:
		state_label.text = "SHUTDOWN COUNTDOWN"
