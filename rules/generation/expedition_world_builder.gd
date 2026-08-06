class_name ExpeditionWorldBuilder
extends RefCounted

const GRID_COLUMNS := 7
const ROOM_SIZE := Vector2(66.0, 38.0)
const GRID_ORIGIN := Vector2(16.0, 10.0)
const COLUMN_STEP := 88.0
const ROW_STEP := 76.0
const CORRIDOR_WIDTH := 10.0


static func build(plan: ExpeditionPlan) -> WorldLayoutDefinition:
	assert(plan != null and plan.validate().is_empty())
	var layout := WorldLayoutDefinition.new()
	layout.content_id = StringName("generated_expedition_%d" % plan.seed)
	layout.tile_size = Vector2i(8, 8)
	var slots: Dictionary[StringName, Vector2i] = {}
	var occupied: Dictionary[String, bool] = {}
	for index: int in plan.critical_route.size():
		var room_id := plan.critical_route[index]
		var column := roundi(float(index) * float(GRID_COLUMNS - 1) / float(maxi(plan.critical_route.size() - 1, 1)))
		var slot := Vector2i(column, 1)
		slots[room_id] = slot
		occupied[_slot_key(slot)] = true
	var optional_ids: Array[StringName] = []
	for room_id: StringName in plan.rooms:
		if not bool(plan.rooms[room_id].critical):
			optional_ids.append(room_id)
	optional_ids.sort()
	for room_id: StringName in optional_ids:
		var anchor_id := _placed_neighbor(plan, room_id, slots)
		var anchor_slot: Vector2i = slots.get(anchor_id, Vector2i(3, 1))
		var slot := _nearest_branch_slot(anchor_slot, occupied)
		slots[room_id] = slot
		occupied[_slot_key(slot)] = true
	for room_id: StringName in plan.rooms:
		var room := WorldRoomDefinition.new()
		var role := StringName(plan.rooms[room_id].role)
		room.content_id = room_id
		room.display_name = _display_name(role)
		room.bounds = Rect2(_slot_position(slots[room_id]), ROOM_SIZE)
		room.visual_style = _visual_style(role)
		layout.rooms.append(room)
	for room_id: StringName in plan.rooms:
		for neighbor_id: StringName in plan.neighbors(room_id):
			if String(room_id) < String(neighbor_id):
				_append_connection(layout, layout.get_room(room_id).bounds.get_center(), layout.get_room(neighbor_id).bounds.get_center())
	layout.starting_position = layout.get_room(plan.start_room_id).bounds.get_center()
	return layout


static func _placed_neighbor(
	plan: ExpeditionPlan,
	room_id: StringName,
	slots: Dictionary[StringName, Vector2i],
) -> StringName:
	for neighbor_id: StringName in plan.neighbors(room_id):
		if slots.has(neighbor_id):
			return neighbor_id
	return plan.start_room_id


static func _nearest_branch_slot(anchor: Vector2i, occupied: Dictionary[String, bool]) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := 1_000_000
	for row: int in [0, 2]:
		for column: int in GRID_COLUMNS:
			var candidate := Vector2i(column, row)
			if occupied.get(_slot_key(candidate), false):
				continue
			var score := absi(column - anchor.x) * 10 + absi(row - anchor.y) * 3
			if score < best_score:
				best = candidate
				best_score = score
	assert(best.x >= 0)
	return best


static func _slot_position(slot: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(slot.x * COLUMN_STEP, slot.y * ROW_STEP)


static func _slot_key(slot: Vector2i) -> String:
	return "%d:%d" % [slot.x, slot.y]


static func _append_connection(layout: WorldLayoutDefinition, first: Vector2, second: Vector2) -> void:
	var corner := Vector2(second.x, first.y)
	_append_axis_corridor(layout, first, corner)
	_append_axis_corridor(layout, corner, second)


static func _append_axis_corridor(layout: WorldLayoutDefinition, first: Vector2, second: Vector2) -> void:
	if is_equal_approx(first.x, second.x) and is_equal_approx(first.y, second.y):
		return
	if is_equal_approx(first.y, second.y):
		layout.corridors.append(Rect2(
			Vector2(minf(first.x, second.x), first.y - CORRIDOR_WIDTH * 0.5),
			Vector2(absf(second.x - first.x), CORRIDOR_WIDTH),
		))
	else:
		layout.corridors.append(Rect2(
			Vector2(first.x - CORRIDOR_WIDTH * 0.5, minf(first.y, second.y)),
			Vector2(CORRIDOR_WIDTH, absf(second.y - first.y)),
		))


static func _display_name(role: StringName) -> String:
	match role:
		&"entrance": return "LANDING"
		&"objective": return "OBJECTIVE"
		&"encounter": return "CONTACT"
		&"resource": return "CACHE"
		&"discovery": return "SIGNAL"
		&"hazard": return "HAZARD"
		_: return "PASSAGE"


static func _visual_style(role: StringName) -> StringName:
	match role:
		&"entrance", &"discovery": return &"shelter"
		&"encounter", &"hazard": return &"damaged"
		&"resource": return &"storage"
		&"objective": return &"warden"
		_: return &"processing"
