class_name FloorState
extends RefCounted

var floor_id: StringName
var current_room_id: StringName
var remaining_seconds: int
var clock_started: bool = false
var triggered_thresholds: Dictionary[int, bool] = {}
var rooms: Dictionary[StringName, RoomState] = {}
var deadline_resolved: bool = false
var floor_failed: bool = false
var extracted: bool = false
var boss_room_reached: bool = false


func _init(definition: FloorDefinition = null) -> void:
	if definition == null:
		return
	floor_id = definition.content_id
	current_room_id = definition.starting_room_id
	remaining_seconds = definition.initial_time_seconds
	for room: RoomDefinition in definition.rooms:
		rooms[room.content_id] = RoomState.new(room.content_id)
	get_room_state(current_room_id).visited = true


func get_room_state(room_id: StringName) -> RoomState:
	return rooms.get(room_id) as RoomState
