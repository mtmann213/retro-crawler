class_name WalkableWorld
extends Control

signal room_entered(room_id: StringName)
signal interaction_requested
signal inventory_requested
signal interaction_proximity_changed(in_range: bool, prompt: String)
signal encounter_requested(room_id: StringName)

const PLAYER_TEXTURE := preload("res://assets/characters/crawler_topdown.png")
const MOVE_SPEED := 82.0
const INTERACTION_RADIUS := 24.0
const ENCOUNTER_RADIUS := 24.0
const ROOM_RECTS := {
	&"room_intake_shelter": Rect2(18, 78, 104, 48),
	&"room_broken_junction": Rect2(150, 78, 112, 48),
	&"room_maintenance_cache": Rect2(154, 10, 104, 46),
	&"room_processing_hall": Rect2(300, 78, 116, 48),
	&"room_warden_chamber": Rect2(458, 68, 144, 68),
}
const CORRIDORS := [
	Rect2(116, 93, 38, 18),
	Rect2(197, 52, 18, 30),
	Rect2(258, 93, 46, 18),
	Rect2(412, 93, 50, 18),
]
const ROOM_NAMES := {
	&"room_intake_shelter": "INTAKE",
	&"room_broken_junction": "JUNCTION",
	&"room_maintenance_cache": "CACHE",
	&"room_processing_hall": "PROCESSING",
	&"room_warden_chamber": "WARDEN",
}
const INTERACTION_POINTS := {
	&"room_intake_shelter": Vector2(42, 102),
	&"room_maintenance_cache": Vector2(236, 34),
	&"room_warden_chamber": Vector2(566, 102),
}
const ENCOUNTER_POINTS := {
	&"room_broken_junction": Vector2(232, 102),
	&"room_processing_hall": Vector2(382, 102),
}
const ENCOUNTER_COUNTS := {
	&"room_broken_junction": 2,
	&"room_processing_hall": 2,
}
const LOCKED_EXIT_RECTS := {
	&"room_broken_junction": [Rect2(197, 76, 18, 6), Rect2(258, 93, 6, 18)],
	&"room_processing_hall": [Rect2(412, 93, 6, 18)],
}

var player_position := Vector2(70, 102)
var current_room_id: StringName = &"room_intake_shelter"
var visited_room_ids: Dictionary[StringName, bool] = {}
var interaction_text := ""
var interaction_available := false
var encounter_available := false
var movement_enabled := true
var player_sprite := Sprite2D.new()
var _interaction_in_range := false
var _encounter_triggered := false


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	var atlas := AtlasTexture.new()
	atlas.atlas = PLAYER_TEXTURE
	atlas.region = Rect2(340, 180, 580, 770)
	player_sprite.texture = atlas
	player_sprite.scale = Vector2(0.042, 0.042)
	player_sprite.position = player_position
	player_sprite.z_index = 5
	add_child(player_sprite)
	queue_redraw()


func _process(delta: float) -> void:
	if not movement_enabled or not is_visible_in_tree() or not has_focus():
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		return
	var motion := direction.normalized() * MOVE_SPEED * delta
	var next := player_position
	var horizontal := next + Vector2(motion.x, 0)
	if _is_walkable(horizontal):
		next = horizontal
	var vertical := next + Vector2(0, motion.y)
	if _is_walkable(vertical):
		next = vertical
	player_position = next
	player_sprite.position = player_position
	_check_room_entry()
	_refresh_interaction_proximity()
	_check_encounter_proximity()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not movement_enabled or not has_focus():
		return
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		if event.is_action_pressed(action):
			# Movement keys also support menu navigation. Consume them here so
			# ui_down (S/D-pad down) cannot move focus out of the world mid-walk.
			accept_event()
			return


func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled or not is_visible_in_tree() or not has_focus():
		return
	if (event.is_action_pressed("inspect") or event.is_action_pressed("confirm")) and can_interact_here():
		interaction_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		inventory_requested.emit()
		get_viewport().set_input_as_handled()


func present(
	room_id: StringName,
	visited: Dictionary[StringName, bool],
	interaction_label: String,
	can_interact: bool,
	has_encounter: bool,
) -> void:
	visited_room_ids = visited.duplicate()
	interaction_text = interaction_label
	interaction_available = can_interact
	encounter_available = has_encounter
	_encounter_triggered = false
	if current_room_id != room_id:
		sync_to_room(room_id)
	_refresh_interaction_proximity()
	queue_redraw()


func sync_to_room(room_id: StringName, force_warp: bool = true) -> void:
	current_room_id = room_id
	_encounter_triggered = false
	if force_warp or not (ROOM_RECTS[room_id] as Rect2).has_point(player_position):
		player_position = (ROOM_RECTS[room_id] as Rect2).get_center()
		player_sprite.position = player_position
	_refresh_interaction_proximity()
	queue_redraw()


func restore_position(position: Vector2, room_id: StringName) -> void:
	current_room_id = room_id
	player_position = position if _is_walkable(position) else (ROOM_RECTS[room_id] as Rect2).get_center()
	player_sprite.position = player_position
	_refresh_interaction_proximity()
	queue_redraw()


func can_interact_here() -> bool:
	if not interaction_available or not INTERACTION_POINTS.has(current_room_id):
		return false
	return player_position.distance_to(INTERACTION_POINTS[current_room_id]) <= INTERACTION_RADIUS


func interaction_point_for_room(room_id: StringName) -> Vector2:
	return INTERACTION_POINTS.get(room_id, Vector2.INF)


func encounter_point_for_room(room_id: StringName) -> Vector2:
	return ENCOUNTER_POINTS.get(room_id, Vector2.INF)


func can_trigger_encounter() -> bool:
	if not encounter_available or not ENCOUNTER_POINTS.has(current_room_id):
		return false
	return player_position.distance_to(ENCOUNTER_POINTS[current_room_id]) <= ENCOUNTER_RADIUS


func is_progression_locked(room_id: StringName) -> bool:
	return encounter_available and current_room_id == room_id and LOCKED_EXIT_RECTS.has(room_id)


func _refresh_interaction_proximity() -> void:
	var in_range := can_interact_here()
	if in_range == _interaction_in_range:
		return
	_interaction_in_range = in_range
	interaction_proximity_changed.emit(in_range, interaction_text)


func _check_encounter_proximity() -> void:
	if _encounter_triggered or not can_trigger_encounter():
		return
	_encounter_triggered = true
	encounter_requested.emit(current_room_id)


func _check_room_entry() -> void:
	for room_id: StringName in ROOM_RECTS:
		var interior := (ROOM_RECTS[room_id] as Rect2).grow(-4.0)
		if interior.has_point(player_position) and room_id != current_room_id:
			current_room_id = room_id
			room_entered.emit(room_id)
			return


func _is_walkable(position: Vector2) -> bool:
	var inside_floor := false
	for rect: Rect2 in ROOM_RECTS.values():
		if rect.grow(-3.0).has_point(position):
			inside_floor = true
			break
	if not inside_floor:
		for corridor: Rect2 in CORRIDORS:
			if corridor.has_point(position):
				inside_floor = true
				break
	if not inside_floor:
		return false
	if is_progression_locked(current_room_id):
		for barrier: Rect2 in LOCKED_EXIT_RECTS[current_room_id]:
			if barrier.has_point(position):
				return false
	return true


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.018, 0.027, 0.04, 0.88), true)
	for corridor: Rect2 in CORRIDORS:
		draw_rect(corridor, Color("172b3b"), true)
		draw_line(corridor.position, corridor.position + Vector2(corridor.size.x, 0), Color("355c72"), 1.0)
		_draw_route_markings(corridor)
	for room_id: StringName in ROOM_RECTS:
		var rect: Rect2 = ROOM_RECTS[room_id]
		var visited: bool = visited_room_ids.get(room_id, false) or room_id == current_room_id
		var fill := Color("122536") if visited else Color("0b141e")
		draw_rect(rect, fill, true)
		draw_rect(rect, Color("7dd3fc") if room_id == current_room_id else Color("35566d"), false, 2.0 if room_id == current_room_id else 1.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(6, 13), ROOM_NAMES[room_id], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("a9c5d8") if visited else Color("536674"))
		_draw_room_details(room_id, rect, visited)
	if encounter_available and ENCOUNTER_POINTS.has(current_room_id):
		_draw_encounter_marker(current_room_id)
		_draw_locked_exits(current_room_id)
	if interaction_available and INTERACTION_POINTS.has(current_room_id):
		var marker: Vector2 = INTERACTION_POINTS[current_room_id]
		var marker_color := Color("86efac") if can_interact_here() else Color("fcd34d")
		draw_arc(marker, INTERACTION_RADIUS, 0, TAU, 32, Color(marker_color, 0.24), 1.0)
		draw_circle(marker, 5.0, marker_color)
		draw_string(ThemeDB.fallback_font, marker + Vector2(8, 3), "E / A" if can_interact_here() else "POI", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, marker_color)
		var prompt := ("E / A // " if can_interact_here() else "MOVE CLOSER // ") + interaction_text
		draw_string(ThemeDB.fallback_font, Vector2(8, size.y - 5), prompt, HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 7, marker_color)
	draw_rect(Rect2(Vector2.ZERO, size), Color("31536b"), false, 1.0)


func _draw_encounter_marker(room_id: StringName) -> void:
	var center: Vector2 = ENCOUNTER_POINTS[room_id]
	draw_arc(center, ENCOUNTER_RADIUS, 0, TAU, 32, Color("fb7185", 0.28), 1.0)
	var count: int = ENCOUNTER_COUNTS[room_id]
	for index: int in count:
		var offset := Vector2((index - (count - 1) * 0.5) * 12.0, 0)
		var hostile := center + offset
		draw_circle(hostile, 5.0, Color("7f1d2d"), true)
		draw_rect(Rect2(hostile + Vector2(-4, 4), Vector2(8, 6)), Color("fb7185"), true)
		draw_circle(hostile + Vector2(0, -1), 1.5, Color("fef2f2"), true)
	draw_string(ThemeDB.fallback_font, Vector2(8, size.y - 5), "HOSTILES // APPROACH TO ENGAGE // PROGRESSION ROUTES LOCKED", HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 7, Color("fb7185"))


func _draw_locked_exits(room_id: StringName) -> void:
	if not LOCKED_EXIT_RECTS.has(room_id):
		return
	for barrier: Rect2 in LOCKED_EXIT_RECTS[room_id]:
		draw_rect(barrier, Color("fb7185", 0.38), true)
		if barrier.size.x > barrier.size.y:
			for x: float in range(int(barrier.position.x) + 2, int(barrier.end.x), 4):
				draw_line(Vector2(x, barrier.position.y), Vector2(x, barrier.end.y), Color("fecdd3"), 1.0)
		else:
			for y: float in range(int(barrier.position.y) + 2, int(barrier.end.y), 4):
				draw_line(Vector2(barrier.position.x, y), Vector2(barrier.end.x, y), Color("fecdd3"), 1.0)


func _draw_route_markings(corridor: Rect2) -> void:
	var center := corridor.get_center()
	if corridor.size.x > corridor.size.y:
		draw_line(center - Vector2(5, 0), center + Vector2(5, 0), Color("7dd3fc", 0.55), 1.0)
		draw_line(center + Vector2(5, 0), center + Vector2(2, -2), Color("7dd3fc", 0.55), 1.0)
	else:
		draw_line(center - Vector2(0, 5), center + Vector2(0, 5), Color("7dd3fc", 0.55), 1.0)
		draw_line(center + Vector2(0, 5), center + Vector2(-2, 2), Color("7dd3fc", 0.55), 1.0)


func _draw_room_details(room_id: StringName, rect: Rect2, visited: bool) -> void:
	if not visited:
		return
	var detail := Color("52758a", 0.75)
	match room_id:
		&"room_intake_shelter":
			draw_rect(Rect2(rect.position + Vector2(7, 24), Vector2(18, 14)), detail, false, 1.0)
			draw_rect(Rect2(rect.position + Vector2(72, 25), Vector2(23, 11)), Color("29475a"), true)
			draw_circle(INTERACTION_POINTS[room_id], 8.0, Color("163649"), true)
		&"room_broken_junction":
			draw_line(rect.position + Vector2(16, 30), rect.position + Vector2(94, 30), Color("fb7185", 0.55), 2.0)
			draw_line(rect.position + Vector2(48, 21), rect.position + Vector2(64, 40), Color("fcd34d", 0.7), 1.0)
		&"room_maintenance_cache":
			draw_rect(Rect2(INTERACTION_POINTS[room_id] - Vector2(10, 9), Vector2(17, 18)), Color("27485b"), true)
			draw_line(INTERACTION_POINTS[room_id] - Vector2(8, 2), INTERACTION_POINTS[room_id] + Vector2(5, -2), detail, 1.0)
		&"room_processing_hall":
			for offset: float in [25.0, 45.0, 65.0, 85.0]:
				draw_rect(Rect2(rect.position + Vector2(offset, 25), Vector2(12, 14)), Color("213e50"), true)
			draw_line(rect.position + Vector2(16, 42), rect.position + Vector2(104, 42), detail, 2.0)
		&"room_warden_chamber":
			draw_circle(rect.get_center(), 17.0, Color("4b1f2b", 0.7), true)
			draw_arc(rect.get_center(), 21.0, 0, TAU, 24, Color("fb7185", 0.65), 2.0)
			draw_rect(Rect2(INTERACTION_POINTS[room_id] - Vector2(8, 7), Vector2(16, 14)), Color("27485b"), true)
