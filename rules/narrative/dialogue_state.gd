class_name DialogueState
extends RefCounted

var shown_events: Dictionary[StringName, bool] = {}


func to_snapshot() -> Dictionary:
	var shown: Array[String] = []
	for event_id: StringName in shown_events:
		if shown_events[event_id]:
			shown.append(String(event_id))
	return {"shown_events": shown}


static func from_snapshot(snapshot: Dictionary) -> DialogueState:
	var state := DialogueState.new()
	for event_id: String in snapshot.get("shown_events", []):
		state.shown_events[StringName(event_id)] = true
	return state
