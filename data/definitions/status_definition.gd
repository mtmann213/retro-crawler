class_name StatusDefinition
extends Resource

enum TickPhase {
	START_OF_TURN,
	END_OF_ACTION,
}

@export var content_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(1, 99, 1) var base_duration: int = 1
@export_range(1, 9, 1) var maximum_stacks: int = 1
@export var tick_phase: TickPhase = TickPhase.END_OF_ACTION
@export_range(0.0, 3.0, 0.05) var defense_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.05) var speed_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.05) var damage_taken_multiplier: float = 1.0
@export_range(0, 999, 1) var periodic_damage: int = 0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if display_name.is_empty():
		errors.append("display_name is required.")
	if base_duration <= 0:
		errors.append("base_duration must be positive.")
	if maximum_stacks <= 0:
		errors.append("maximum_stacks must be positive.")
	if defense_multiplier < 0.0 or speed_multiplier < 0.0 or damage_taken_multiplier < 0.0:
		errors.append("Status multipliers cannot be negative.")
	return errors
