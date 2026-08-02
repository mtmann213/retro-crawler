class_name CharacterProfile
extends RefCounted

const DEFAULT_NAME := "Crawler"
const MAX_NAME_LENGTH := 18

var crawler_name := DEFAULT_NAME
var class_id: StringName = CharacterClassRules.DEFAULT_CLASS_ID
var color_id: StringName = CharacterClassRules.DEFAULT_COLOR_ID


func _init(
	requested_name: String = DEFAULT_NAME,
	requested_class_id: StringName = CharacterClassRules.DEFAULT_CLASS_ID,
	requested_color_id: StringName = CharacterClassRules.DEFAULT_COLOR_ID,
) -> void:
	crawler_name = sanitize_name(requested_name)
	class_id = requested_class_id if CharacterClassRules.has_class(requested_class_id) else CharacterClassRules.DEFAULT_CLASS_ID
	color_id = requested_color_id if CharacterClassRules.has_color(requested_color_id) else CharacterClassRules.DEFAULT_COLOR_ID


func to_snapshot() -> Dictionary:
	return {
		"name": crawler_name,
		"class_id": String(class_id),
		"color_id": String(color_id),
	}


static func from_snapshot(snapshot: Dictionary) -> CharacterProfile:
	return CharacterProfile.new(
		String(snapshot.get("name", DEFAULT_NAME)),
		StringName(snapshot.get("class_id", CharacterClassRules.DEFAULT_CLASS_ID)),
		StringName(snapshot.get("color_id", CharacterClassRules.DEFAULT_COLOR_ID)),
	)


static func sanitize_name(value: String) -> String:
	var cleaned := ""
	var allowed := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 '-"
	for index: int in value.length():
		var character := value.substr(index, 1)
		if allowed.contains(character):
			cleaned += character
	cleaned = cleaned.strip_edges()
	if cleaned.is_empty():
		return DEFAULT_NAME
	return cleaned.substr(0, MAX_NAME_LENGTH)


static func validate_snapshot(snapshot: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not snapshot.get("name", "") is String:
		errors.append("Character name must be a string.")
	else:
		var name := String(snapshot.get("name", ""))
		if name.is_empty() or name.length() > MAX_NAME_LENGTH or sanitize_name(name) != name:
			errors.append("Character name is invalid.")
	var requested_class := StringName(snapshot.get("class_id", ""))
	if not CharacterClassRules.has_class(requested_class):
		errors.append("Unknown character class.")
	var requested_color := StringName(snapshot.get("color_id", ""))
	if not CharacterClassRules.has_color(requested_color):
		errors.append("Unknown character color.")
	return errors
