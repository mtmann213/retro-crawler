extends GutTest

const FLOOR := preload("res://content/floors/floor_service_level.tres")


func test_every_action_deducts_the_advertised_time() -> void:
	var state := FloorState.new(FLOOR)
	FloorClockRules.start_clock(state)
	var costs := [15, 10, 20, 5, 8, 4, 30, 60]
	var expected := FLOOR.initial_time_seconds
	for cost: int in costs:
		var events := FloorClockRules.spend_time(state, cost, "test", FLOOR.threshold_seconds)
		expected -= cost
		assert_eq(state.remaining_seconds, expected)
		assert_eq(events[0].seconds, cost)


func test_menus_and_paused_safe_room_deduct_no_time() -> void:
	var state := FloorState.new(FLOOR)
	assert_true(FloorClockRules.spend_time(state, 20, "paused", FLOOR.threshold_seconds).is_empty())
	FloorClockRules.start_clock(state)
	assert_true(FloorClockRules.spend_time(state, 0, "menu", FLOOR.threshold_seconds).is_empty())
	assert_eq(state.remaining_seconds, 720)


func test_thresholds_and_deadline_trigger_once() -> void:
	var state := FloorState.new(FLOOR)
	FloorClockRules.start_clock(state)
	var first := FloorClockRules.spend_time(state, 700, "long action", FLOOR.threshold_seconds)
	assert_eq(_event_count(first, FloorClockEvent.EventType.THRESHOLD_REACHED), 3)
	var deadline := FloorClockRules.spend_time(state, 20, "deadline", FLOOR.threshold_seconds)
	assert_eq(_event_count(deadline, FloorClockEvent.EventType.THRESHOLD_REACHED), 1)
	assert_eq(_event_count(deadline, FloorClockEvent.EventType.DEADLINE_REACHED), 1)
	assert_true(state.floor_failed)
	assert_true(FloorClockRules.spend_time(state, 10, "again", FLOOR.threshold_seconds).is_empty())


func test_room_graph_has_no_broken_references_and_mandatory_rooms_are_reachable() -> void:
	assert_true(RoomTransitionRules.validate_graph(FLOOR).is_empty())


func test_full_floor_and_optional_detour_are_traversable() -> void:
	var direct := FloorState.new(FLOOR)
	RoomTransitionRules.transition(direct, FLOOR, &"room_broken_junction")
	RoomTransitionRules.transition(direct, FLOOR, &"room_processing_hall")
	RoomTransitionRules.transition(direct, FLOOR, &"room_warden_chamber")
	assert_true(direct.boss_room_reached)
	assert_eq(direct.remaining_seconds, 675)

	var detour := FloorState.new(FLOOR)
	RoomTransitionRules.transition(detour, FLOOR, &"room_broken_junction")
	RoomTransitionRules.transition(detour, FLOOR, &"room_maintenance_cache")
	FloorClockRules.spend_time(detour, 20, "search", FLOOR.threshold_seconds)
	RoomTransitionRules.transition(detour, FLOOR, &"room_broken_junction")
	RoomTransitionRules.transition(detour, FLOOR, &"room_processing_hall")
	RoomTransitionRules.transition(detour, FLOOR, &"room_warden_chamber")
	assert_true(detour.boss_room_reached)
	assert_eq(detour.remaining_seconds, 625)
	assert_lt(detour.remaining_seconds, direct.remaining_seconds)


func test_invalid_transition_does_not_move_or_spend_time() -> void:
	var state := FloorState.new(FLOOR)
	var events := RoomTransitionRules.transition(state, FLOOR, &"room_warden_chamber")
	assert_true(events.is_empty())
	assert_eq(state.current_room_id, &"room_intake_shelter")
	assert_eq(state.remaining_seconds, 720)


func test_emergency_extraction_cannot_trigger_twice() -> void:
	var state := FloorState.new(FLOOR)
	assert_eq(FloorClockRules.emergency_extract(state).size(), 1)
	assert_true(state.extracted)
	assert_true(FloorClockRules.emergency_extract(state).is_empty())


func _event_count(events: Array[FloorClockEvent], type: FloorClockEvent.EventType) -> int:
	var count := 0
	for event: FloorClockEvent in events:
		if event.event_type == type:
			count += 1
	return count
