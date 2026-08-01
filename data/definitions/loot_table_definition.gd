class_name LootTableDefinition
extends Resource

@export var content_id: StringName = &""
@export_range(1, 99, 1) var roll_count: int = 1
@export var entries: Array[LootEntryDefinition] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if roll_count <= 0:
		errors.append("roll_count must be positive.")
	if entries.is_empty():
		errors.append("Loot tables require at least one entry.")
	for entry: LootEntryDefinition in entries:
		if entry == null:
			errors.append("entries cannot contain null entries.")
		else:
			errors.append_array(entry.validate())
	return errors
