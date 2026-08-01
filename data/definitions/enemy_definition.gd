class_name EnemyDefinition
extends Resource

@export var content_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(1, 99, 1) var level: int = 1
@export_range(1, 9999, 1) var max_hp: int = 1
@export_range(0, 999, 1) var power: int = 0
@export_range(0, 999, 1) var defense: int = 0
@export_range(1, 999, 1) var speed: int = 1
@export var skill_ids: Array[StringName] = []
@export var ai_pattern: Array[StringName] = []
@export var loot_table_id: StringName = &""
@export_range(0, 99999, 1) var experience_reward: int = 0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("content_id is required.")
	if display_name.is_empty():
		errors.append("display_name is required.")
	if max_hp <= 0:
		errors.append("max_hp must be positive.")
	if skill_ids.is_empty():
		errors.append("Enemies require at least one skill.")
	for skill_id: StringName in ai_pattern:
		if not skill_ids.has(skill_id):
			errors.append("AI pattern references unknown skill %s." % skill_id)
	return errors
