class_name WalkableWorld
extends Control

signal room_entered(room_id: StringName)
signal interaction_requested
signal inventory_requested

const PLAYER_TEXTURE := preload("res://assets/characters/crawler_topdown.png")
const MOVE_SPEED := 82.0
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

var player_position := Vector2(70, 102)
var current_room_id: StringName = &"room_intake_shelter"
var visited_room_ids: Dictionary[StringName, bool] = {}
var interaction_text := ""
var interaction_available := false
var movement_enabled := true
var player_sprite := Sprite2D.new()


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
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled or not is_visible_in_tree() or not has_focus():
		return
	if event.is_action_pressed("inspect") or event.is_action_pressed("confirm"):
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
) -> void:
	visited_room_ids = visited.duplicate()
	interaction_text = interaction_label
	interaction_available = can_interact
	if current_room_id != room_id:
		sync_to_room(room_id)
	queue_redraw()


func sync_to_room(room_id: StringName, force_warp: bool = true) -> void:
	current_room_id = room_id
	if force_warp or not (ROOM_RECTS[room_id] as Rect2).has_point(player_position):
		player_position = (ROOM_RECTS[room_id] as Rect2).get_center()
		player_sprite.position = player_position
	queue_redraw()


func restore_position(position: Vector2, room_id: StringName) -> void:
	current_room_id = room_id
	player_position = position if _is_walkable(position) else (ROOM_RECTS[room_id] as Rect2).get_center()
	player_sprite.position = player_position
	queue_redraw()


func _check_room_entry() -> void:
	for room_id: StringName in ROOM_RECTS:
		var interior := (ROOM_RECTS[room_id] as Rect2).grow(-4.0)
		if interior.has_point(player_position) and room_id != current_room_id:
			current_room_id = room_id
			room_entered.emit(room_id)
			return


func _is_walkable(position: Vector2) -> bool:
	for rect: Rect2 in ROOM_RECTS.values():
		if rect.grow(-3.0).has_point(position):
			return true
	for corridor: Rect2 in CORRIDORS:
		if corridor.has_point(position):
			return true
	return false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.018, 0.027, 0.04, 0.88), true)
	for corridor: Rect2 in CORRIDORS:
		draw_rect(corridor, Color("172b3b"), true)
		draw_line(corridor.position, corridor.position + Vector2(corridor.size.x, 0), Color("355c72"), 1.0)
	for room_id: StringName in ROOM_RECTS:
		var rect: Rect2 = ROOM_RECTS[room_id]
		var visited: bool = visited_room_ids.get(room_id, false) or room_id == current_room_id
		var fill := Color("122536") if visited else Color("0b141e")
		draw_rect(rect, fill, true)
		draw_rect(rect, Color("7dd3fc") if room_id == current_room_id else Color("35566d"), false, 2.0 if room_id == current_room_id else 1.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(6, 13), ROOM_NAMES[room_id], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("a9c5d8") if visited else Color("536674"))
	if interaction_available:
		var marker := (ROOM_RECTS[current_room_id] as Rect2).get_center() + Vector2(0, -16)
		draw_circle(marker, 5.0, Color("fcd34d"))
		draw_string(ThemeDB.fallback_font, marker + Vector2(8, 3), "E / A", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fcd34d"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("31536b"), false, 1.0)
