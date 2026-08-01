class_name LootEntryDefinition
extends Resource

@export var content_id: StringName = &""
@export_range(1, 9999, 1) var weight: int = 1
@export_range(1, 99, 1) var minimum_quantity: int = 1
@export_range(1, 99, 1) var maximum_quantity: int = 1
@export var required_flags: Array[StringName] = []
@export var excluded_flags: Array[StringName] = []
@export var unique: bool = false


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if weight <= 0:
		errors.append("weight must be positive.")
	if minimum_quantity <= 0 or maximum_quantity < minimum_quantity:
		errors.append("quantity range is invalid.")
	return errors
