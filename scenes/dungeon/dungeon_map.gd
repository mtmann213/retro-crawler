class_name DungeonMap
extends Control

const FLOOR: FloorDefinition = preload("res://content/floors/floor_service_level.tres")
const PATH_COLOR := Color("35506a")
const ACTIVE_COLOR := Color("7dd3fc")

var current_room_id: StringName = &""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	queue_redraw()


func present(room_id: StringName) -> void:
	current_room_id = room_id
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.035, 0.05, 0.82), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.192, 0.365, 0.478, 0.8), false, 1.0)
	for room: RoomDefinition in FLOOR.rooms:
		var from := room.map_position + Vector2(56, 19)
		for exit_id: StringName in room.connected_room_ids:
			if String(room.content_id) >= String(exit_id):
				continue
			var destination := FLOOR.get_room(exit_id)
			var to := destination.map_position + Vector2(56, 19)
			draw_line(from, to, PATH_COLOR, 5.0, false)
			draw_line(from, to, Color("152435"), 2.0, false)
	var current := FLOOR.get_room(current_room_id)
	if current != null:
		var center := current.map_position + Vector2(56, 19)
		draw_circle(center, 25.0, Color(0.49, 0.83, 0.99, 0.12))
		draw_arc(center, 25.0, 0.0, TAU, 24, ACTIVE_COLOR, 2.0, false)
