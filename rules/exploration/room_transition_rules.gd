class_name RoomTransitionRules
extends RefCounted


static func transition(
	state: FloorState,
	floor_definition: FloorDefinition,
	destination_id: StringName,
) -> Array[FloorClockEvent]:
	var events: Array[FloorClockEvent] = []
	if state == null or floor_definition == null or state.floor_failed or state.extracted:
		return events
	var current := floor_definition.get_room(state.current_room_id)
	var destination := floor_definition.get_room(destination_id)
	if current == null or destination == null or not current.connected_room_ids.has(destination_id):
		return events
	if not state.clock_started:
		FloorClockRules.start_clock(state)
	events = FloorClockRules.spend_time(
		state, floor_definition.room_transition_cost, "MOVE // %s" % destination.display_name,
		floor_definition.threshold_seconds,
	)
	if state.floor_failed:
		return events
	state.current_room_id = destination_id
	state.get_room_state(destination_id).visited = true
	state.boss_room_reached = state.boss_room_reached or destination_id == &"room_warden_chamber"
	return events


static func validate_graph(floor_definition: FloorDefinition) -> PackedStringArray:
	var errors := floor_definition.validate()
	if not errors.is_empty():
		return errors
	for room: RoomDefinition in floor_definition.rooms:
		for exit_id: StringName in room.connected_room_ids:
			var destination := floor_definition.get_room(exit_id)
			if destination == null:
				errors.append("%s references missing room %s." % [room.content_id, exit_id])
			elif not destination.connected_room_ids.has(room.content_id):
				errors.append("Connection %s -> %s is not reciprocal." % [room.content_id, exit_id])
	var reachable: Dictionary[StringName, bool] = {}
	var pending: Array[StringName] = [floor_definition.starting_room_id]
	while not pending.is_empty():
		var room_id: StringName = pending.pop_front()
		if reachable.has(room_id):
			continue
		reachable[room_id] = true
		var room := floor_definition.get_room(room_id)
		if room == null:
			continue
		for exit_id: StringName in room.connected_room_ids:
			if not reachable.has(exit_id):
				pending.append(exit_id)
	for room: RoomDefinition in floor_definition.rooms:
		if room.mandatory and not reachable.has(room.content_id):
			errors.append("Mandatory room %s is unreachable." % room.content_id)
	return errors
