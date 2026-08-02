class_name FloorClockRules
extends RefCounted

const MOVE_COST := 15
const SEARCH_BASIC_COST := 10
const SEARCH_COMPLEX_COST := 20
const COMBAT_NORMAL_COST := 5
const COMBAT_HEAVY_COST := 8
const CONSUMABLE_COST := 4
const FLEE_COST := 30
const REST_COST := 60


static func start_clock(state: FloorState) -> void:
	if state != null:
		state.clock_started = true


static func spend_time(
	state: FloorState,
	seconds: int,
	description: String,
	thresholds: Array[int] = [360, 180, 60, 0],
) -> Array[FloorClockEvent]:
	var events: Array[FloorClockEvent] = []
	if state == null or seconds <= 0 or not state.clock_started or state.deadline_resolved:
		return events
	var previous := state.remaining_seconds
	state.remaining_seconds = maxi(0, previous - seconds)
	var spent := FloorClockEvent.new(FloorClockEvent.EventType.TIME_SPENT)
	spent.seconds = previous - state.remaining_seconds
	spent.remaining_seconds = state.remaining_seconds
	spent.description = description
	events.append(spent)
	var ordered := thresholds.duplicate()
	ordered.sort()
	ordered.reverse()
	for threshold: int in ordered:
		if previous > threshold and state.remaining_seconds <= threshold and not state.triggered_thresholds.get(threshold, false):
			state.triggered_thresholds[threshold] = true
			var threshold_event := FloorClockEvent.new(FloorClockEvent.EventType.THRESHOLD_REACHED)
			threshold_event.threshold_seconds = threshold
			threshold_event.remaining_seconds = state.remaining_seconds
			events.append(threshold_event)
	if state.remaining_seconds == 0 and not state.deadline_resolved:
		state.deadline_resolved = true
		state.floor_failed = true
		var deadline := FloorClockEvent.new(FloorClockEvent.EventType.DEADLINE_REACHED)
		events.append(deadline)
	return events


static func emergency_extract(state: FloorState) -> Array[FloorClockEvent]:
	var events: Array[FloorClockEvent] = []
	if state == null or state.extracted:
		return events
	state.extracted = true
	var event := FloorClockEvent.new(FloorClockEvent.EventType.EXTRACTED)
	event.remaining_seconds = state.remaining_seconds
	events.append(event)
	return events
