class_name ActionCommand
extends RefCounted

var actor_instance_id: int
var skill_id: StringName
var target_instance_id: int


func _init(
	new_actor_instance_id: int,
	new_skill_id: StringName,
	new_target_instance_id: int,
) -> void:
	actor_instance_id = new_actor_instance_id
	skill_id = new_skill_id
	target_instance_id = new_target_instance_id
