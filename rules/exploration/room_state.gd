class_name RoomState
extends RefCounted

var room_id: StringName
var visited: bool = false
var encounter_completed: bool = false
var interaction_completed: bool = false


func _init(new_room_id: StringName = &"") -> void:
	room_id = new_room_id
