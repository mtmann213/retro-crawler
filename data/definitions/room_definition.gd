class_name RoomDefinition
extends Resource

@export var content_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var connected_room_ids: Array[StringName] = []
@export var mandatory: bool = false
@export var encounter_id: StringName = &""
@export var interaction_id: StringName = &""
@export var interaction_label: String = ""
@export_range(0, 999, 1) var interaction_time_cost: int = 0
@export var map_position: Vector2 = Vector2.ZERO


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if display_name.is_empty():
		errors.append("display_name is required.")
	if connected_room_ids.has(content_id):
		errors.append("Rooms cannot connect to themselves.")
	if not interaction_id.is_empty() and interaction_label.is_empty():
		errors.append("Interactions require a label.")
	return errors
