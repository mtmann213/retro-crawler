class_name DungeonPlayerController
extends Node

signal direction_requested(direction: Vector2i)


func _unhandled_input(event: InputEvent) -> void:
	var direction := Vector2i.ZERO
	if event.is_action_pressed("move_up"):
		direction = Vector2i.UP
	elif event.is_action_pressed("move_down"):
		direction = Vector2i.DOWN
	elif event.is_action_pressed("move_left"):
		direction = Vector2i.LEFT
	elif event.is_action_pressed("move_right"):
		direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO:
		direction_requested.emit(direction)
