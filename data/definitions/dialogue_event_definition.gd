class_name DialogueEventDefinition
extends Resource

enum Presentation { ANNOUNCEMENT, DIALOGUE, ACHIEVEMENT, ENDING }

@export var content_id: StringName = &""
@export var trigger_id: StringName = &""
@export var speaker: String = "SYSTEM"
@export_multiline var text: String = ""
@export var presentation: Presentation = Presentation.ANNOUNCEMENT
@export var required_flags: Array[StringName] = []
@export var excluded_flags: Array[StringName] = []
@export var once_only: bool = true


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if trigger_id.is_empty():
		errors.append("trigger_id is required.")
	if text.is_empty():
		errors.append("text is required.")
	for flag: StringName in required_flags:
		if excluded_flags.has(flag):
			errors.append("Flag %s cannot be both required and excluded." % flag)
	return errors


func conditions_match(flags: Dictionary[StringName, bool]) -> bool:
	for flag: StringName in required_flags:
		if not flags.get(flag, false):
			return false
	for flag: StringName in excluded_flags:
		if flags.get(flag, false):
			return false
	return true
