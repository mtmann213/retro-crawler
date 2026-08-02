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
var boss_defeated: bool = false
var victory_ending: bool = false
var extraction_ending: bool = false


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


func to_snapshot() -> Dictionary:
	var room_snapshots := {}
	for room_id: StringName in rooms:
		var room_state := rooms[room_id] as RoomState
		room_snapshots[String(room_id)] = {
			"visited": room_state.visited,
			"encounter_completed": room_state.encounter_completed,
			"interaction_completed": room_state.interaction_completed,
		}
	var thresholds: Array[int] = []
	for threshold: int in triggered_thresholds:
		if triggered_thresholds[threshold]:
			thresholds.append(threshold)
	return {
		"floor_id": String(floor_id),
		"current_room_id": String(current_room_id),
		"remaining_seconds": remaining_seconds,
		"clock_started": clock_started,
		"deadline_resolved": deadline_resolved,
		"floor_failed": floor_failed,
		"extracted": extracted,
		"boss_room_reached": boss_room_reached,
		"boss_defeated": boss_defeated,
		"victory_ending": victory_ending,
		"extraction_ending": extraction_ending,
		"triggered_thresholds": thresholds,
		"rooms": room_snapshots,
	}


static func from_snapshot(definition: FloorDefinition, snapshot: Dictionary) -> FloorState:
	var state := FloorState.new(definition)
	state.current_room_id = StringName(snapshot.get("current_room_id", state.current_room_id))
	state.remaining_seconds = int(snapshot.get("remaining_seconds", state.remaining_seconds))
	state.clock_started = bool(snapshot.get("clock_started", false))
	state.deadline_resolved = bool(snapshot.get("deadline_resolved", false))
	state.floor_failed = bool(snapshot.get("floor_failed", false))
	state.extracted = bool(snapshot.get("extracted", false))
	state.boss_room_reached = bool(snapshot.get("boss_room_reached", false))
	state.boss_defeated = bool(snapshot.get("boss_defeated", false))
	state.victory_ending = bool(snapshot.get("victory_ending", false))
	state.extraction_ending = bool(snapshot.get("extraction_ending", false))
	for threshold: int in snapshot.get("triggered_thresholds", []):
		state.triggered_thresholds[threshold] = true
	var room_snapshots: Dictionary = snapshot.get("rooms", {})
	for room_id: String in room_snapshots:
		var room_state := state.get_room_state(StringName(room_id))
		if room_state == null:
			continue
		var room_snapshot: Dictionary = room_snapshots[room_id]
		room_state.visited = bool(room_snapshot.get("visited", room_state.visited))
		room_state.encounter_completed = bool(room_snapshot.get("encounter_completed", false))
		room_state.interaction_completed = bool(room_snapshot.get("interaction_completed", false))
	return state
