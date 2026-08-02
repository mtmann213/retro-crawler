class_name DialogueState
extends RefCounted

var shown_events: Dictionary[StringName, bool] = {}
var pending_events: Dictionary[StringName, bool] = {}


func to_snapshot() -> Dictionary:
	var shown: Array[String] = []
	for event_id: StringName in shown_events:
		if shown_events[event_id]:
			shown.append(String(event_id))
	var pending: Array[String] = []
	for event_id: StringName in pending_events:
		if pending_events[event_id]:
			pending.append(String(event_id))
	return {"shown_events": shown, "pending_events": pending}


static func from_snapshot(snapshot: Dictionary) -> DialogueState:
	var state := DialogueState.new()
	for event_id: String in snapshot.get("shown_events", []):
		state.shown_events[StringName(event_id)] = true
	for event_id: String in snapshot.get("pending_events", []):
		state.pending_events[StringName(event_id)] = true
	return state
