class_name WorldRoomDefinition
extends Resource

@export var content_id: StringName = &""
@export var display_name: String = ""
@export var bounds: Rect2
@export var interaction_point := Vector2.INF
@export var encounter_point := Vector2.INF
@export_range(0, 8, 1) var encounter_count: int = 0
@export var locked_exit_rects: Array[Rect2] = []
@export var visual_style: StringName = &"industrial"


func has_interaction_point() -> bool:
	return is_finite(interaction_point.x) and is_finite(interaction_point.y)


func has_encounter_point() -> bool:
	return is_finite(encounter_point.x) and is_finite(encounter_point.y)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("World rooms require content_id.")
	if display_name.is_empty():
		errors.append("World room %s requires display_name." % content_id)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		errors.append("World room %s requires positive bounds." % content_id)
	if encounter_count > 0 and not has_encounter_point():
		errors.append("World room %s has encounter_count without an encounter point." % content_id)
	return errors
