class_name FloorDefinition
extends Resource

@export var content_id: StringName = &""
@export var display_name: String = ""
@export var starting_room_id: StringName = &""
@export_range(1, 99999, 1) var initial_time_seconds: int = 720
@export_range(0, 999, 1) var room_transition_cost: int = 15
@export var threshold_seconds: Array[int] = [360, 180, 60, 0]
@export var rooms: Array[RoomDefinition] = []


func get_room(room_id: StringName) -> RoomDefinition:
	for room: RoomDefinition in rooms:
		if room != null and room.content_id == room_id:
			return room
	return null


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if display_name.is_empty():
		errors.append("display_name is required.")
	if get_room(starting_room_id) == null:
		errors.append("starting_room_id must reference a room.")
	var ids: Dictionary[StringName, bool] = {}
	for room: RoomDefinition in rooms:
		if room == null:
			errors.append("rooms cannot contain null entries.")
			continue
		errors.append_array(room.validate())
		if ids.has(room.content_id):
			errors.append("Duplicate room ID %s." % room.content_id)
		ids[room.content_id] = true
	return errors
