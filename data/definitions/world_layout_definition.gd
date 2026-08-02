class_name WorldLayoutDefinition
extends Resource

@export var content_id: StringName = &""
@export var starting_position := Vector2.ZERO
@export var tile_size := Vector2i(8, 8)
@export var rooms: Array[WorldRoomDefinition] = []
@export var corridors: Array[Rect2] = []


func get_room(room_id: StringName) -> WorldRoomDefinition:
	for room: WorldRoomDefinition in rooms:
		if room != null and room.content_id == room_id:
			return room
	return null


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("World layouts require content_id.")
	if tile_size.x <= 0 or tile_size.y <= 0:
		errors.append("World layouts require a positive tile size.")
	var ids: Dictionary[StringName, bool] = {}
	var starts_in_room := false
	for room: WorldRoomDefinition in rooms:
		if room == null:
			errors.append("World layouts cannot contain null rooms.")
			continue
		errors.append_array(room.validate())
		if ids.has(room.content_id):
			errors.append("Duplicate world room %s." % room.content_id)
		ids[room.content_id] = true
		starts_in_room = starts_in_room or room.bounds.has_point(starting_position)
	if not starts_in_room:
		errors.append("World starting_position must be inside a room.")
	for corridor: Rect2 in corridors:
		if corridor.size.x <= 0 or corridor.size.y <= 0:
			errors.append("World corridors require positive bounds.")
	return errors
