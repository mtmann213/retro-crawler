class_name DungeonInteractable
extends Button

signal interaction_requested(interaction_id: StringName)

@export var interaction_id: StringName = &""
@export_range(0, 999, 1) var time_cost: int = 0


func _ready() -> void:
	pressed.connect(_request_interaction)


func setup(definition: RoomDefinition, completed: bool) -> void:
	interaction_id = definition.interaction_id
	time_cost = definition.interaction_time_cost
	text = definition.interaction_label
	disabled = completed or interaction_id.is_empty()
	visible = not interaction_id.is_empty()


func _request_interaction() -> void:
	if not disabled:
		interaction_requested.emit(interaction_id)
