class_name CompanionAvatar
extends Node2D

const FOLLOW_OFFSET := Vector2(-17, 8)

var _target_position := Vector2.ZERO
var _animation_time := 0.0


func _ready() -> void:
	_target_position = position
	queue_redraw()


func follow(player_position: Vector2, delta: float) -> void:
	_animation_time += delta
	_target_position = player_position + FOLLOW_OFFSET
	position = position.lerp(_target_position, minf(delta * 7.0, 1.0))
	queue_redraw()


func snap_to(player_position: Vector2) -> void:
	_target_position = player_position + FOLLOW_OFFSET
	position = _target_position
	queue_redraw()


func _draw() -> void:
	var bob := sin(_animation_time * 3.4) * 1.2
	draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 7.0, Color("020406", 0.48), true)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	draw_line(Vector2(0, -7), Vector2(0, -10), Color("7895a8"), 1.0)
	draw_circle(Vector2(0, -11), 1.2, Color("fb923c"), true)
	draw_circle(Vector2.ZERO, 7.0, Color("172b38"), true)
	draw_arc(Vector2.ZERO, 7.0, 0, TAU, 16, Color("7dd3fc"), 1.0)
	draw_rect(Rect2(-4, -2, 8, 5), Color("0b151c"), true)
	draw_rect(Rect2(-2, -1, 1, 2), Color("86efac"), true)
	draw_rect(Rect2(1, -1, 1, 2), Color("86efac"), true)
	draw_circle(Vector2(0, 4), 1.5, Color("fcd34d"), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
