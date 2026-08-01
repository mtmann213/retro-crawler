class_name EncounterDefinition
extends Resource

@export var content_id: StringName = &""
@export var enemy_definition_ids: Array[StringName] = []
@export var possible_escape: bool = true
@export_range(0, 999, 1) var floor_time_start_cost: int = 0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if enemy_definition_ids.is_empty():
		errors.append("Encounters require at least one enemy.")
	return errors
