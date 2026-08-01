class_name StatusState
extends RefCounted

var definition: StatusDefinition
var source_instance_id: int
var remaining_turns: int
var stacks: int = 1


func _init(
	new_definition: StatusDefinition,
	new_source_instance_id: int,
	duration_override: int = 0,
) -> void:
	assert(new_definition != null)
	definition = new_definition
	source_instance_id = new_source_instance_id
	remaining_turns = duration_override if duration_override > 0 else definition.base_duration
