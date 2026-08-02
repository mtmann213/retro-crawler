class_name FloorClockEvent
extends RefCounted

enum EventType { TIME_SPENT, THRESHOLD_REACHED, DEADLINE_REACHED, EXTRACTED }

var event_type: EventType
var seconds: int = 0
var remaining_seconds: int = 0
var threshold_seconds: int = -1
var description: String = ""


func _init(new_type: EventType) -> void:
	event_type = new_type
