class_name ExpeditionMapPreview
extends Control

var plan: ExpeditionPlan
var _positions: Dictionary[StringName, Vector2] = {}


func present(expedition_plan: ExpeditionPlan) -> void:
	plan = expedition_plan
	_rebuild_positions()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and plan != null:
		_rebuild_positions()
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("070b0e"), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color("31536b"), false, 1.0)
	if plan == null:
		return
	for room_id: StringName in plan.rooms:
		for neighbor_id: StringName in plan.neighbors(room_id):
			if String(room_id) < String(neighbor_id):
				var critical_connection := bool(plan.rooms[room_id].critical) and bool(plan.rooms[neighbor_id].critical)
				draw_line(
					_positions[room_id], _positions[neighbor_id],
					Color("fcd34d", 0.72) if critical_connection else Color("496779", 0.72),
					2.0 if critical_connection else 1.0,
				)
	for room_id: StringName in plan.rooms:
		_draw_room(room_id)


func _draw_room(room_id: StringName) -> void:
	var room: Dictionary = plan.rooms[room_id]
	var position: Vector2 = _positions[room_id]
	var role := StringName(room.role)
	var fill := _role_color(role)
	var radius := 8.0 if bool(room.critical) else 6.0
	draw_circle(position, radius + 2.0, Color("020406", 0.82), true)
	draw_circle(position, radius, fill, true)
	draw_arc(position, radius, 0, TAU, 20, Color("d8e8f0", 0.72), 1.0)
	var label := "IN" if role == &"entrance" else "OBJ" if role == &"objective" else String(role).substr(0, 3).to_upper()
	draw_string(ThemeDB.fallback_font, position + Vector2(-12, -10), label, HORIZONTAL_ALIGNMENT_CENTER, 24, 7, Color("d8e8f0"))


func _rebuild_positions() -> void:
	_positions.clear()
	if plan == null:
		return
	var left := 32.0
	var right := maxf(size.x - 32.0, left + 1.0)
	var center_y := size.y * 0.56
	var route_count := plan.critical_route.size()
	for index: int in route_count:
		var ratio := float(index) / float(maxi(route_count - 1, 1))
		_positions[plan.critical_route[index]] = Vector2(lerpf(left, right, ratio), center_y)
	var branch_counts: Dictionary[StringName, int] = {}
	for room_id: StringName in plan.rooms:
		if bool(plan.rooms[room_id].critical):
			continue
		var anchor_id := _nearest_critical_room(room_id)
		var branch_index: int = branch_counts.get(anchor_id, 0)
		branch_counts[anchor_id] = branch_index + 1
		var side := -1.0 if branch_index % 2 == 0 else 1.0
		var tier := 1.0 + floorf(float(branch_index) / 2.0)
		var anchor: Vector2 = _positions.get(anchor_id, Vector2(size.x * 0.5, center_y))
		_positions[room_id] = Vector2(
			clampf(anchor.x + (tier - 1.0) * 18.0, 20.0, size.x - 20.0),
			clampf(center_y + side * (38.0 + (tier - 1.0) * 18.0), 18.0, size.y - 18.0),
		)


func _nearest_critical_room(origin_id: StringName) -> StringName:
	var frontier: Array[StringName] = [origin_id]
	var visited: Dictionary[StringName, bool] = {origin_id: true}
	while not frontier.is_empty():
		var current: StringName = frontier.pop_front()
		if bool(plan.rooms[current].critical):
			return current
		for neighbor_id: StringName in plan.neighbors(current):
			if not visited.get(neighbor_id, false):
				visited[neighbor_id] = true
				frontier.append(neighbor_id)
	return plan.start_room_id


func _role_color(role: StringName) -> Color:
	match role:
		&"entrance": return Color("86efac")
		&"objective": return Color("fb923c")
		&"encounter": return Color("fb7185")
		&"resource": return Color("fcd34d")
		&"discovery": return Color("c084fc")
		_: return Color("7dd3fc")
