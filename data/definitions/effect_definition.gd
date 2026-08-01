class_name EffectDefinition
extends Resource

enum EffectType {
	DAMAGE,
	HEAL,
	APPLY_STATUS,
	REMOVE_STATUS,
	MODIFY_RESOURCE,
	GRANT_SHIELD,
	MODIFY_TIMELINE,
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var base_amount: int = 0
@export var scaling_stat: StringName = &"power"
@export_range(0.0, 10.0, 0.05) var scaling_ratio: float = 1.0
@export_range(0.0, 10.0, 0.05) var defense_scaling: float = 1.0
@export var damage_type: StringName = &"physical"
@export var referenced_content_id: StringName = &""
@export var resource_id: StringName = &""
@export_range(0.0, 1.0, 0.01) var success_chance: float = 1.0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if base_amount < 0:
		errors.append("base_amount cannot be negative.")
	if scaling_ratio < 0.0:
		errors.append("scaling_ratio cannot be negative.")
	if defense_scaling < 0.0:
		errors.append("defense_scaling cannot be negative.")
	if success_chance < 0.0 or success_chance > 1.0:
		errors.append("success_chance must be between 0 and 1.")
	if effect_type == EffectType.APPLY_STATUS and referenced_content_id.is_empty():
			errors.append("Status effects require referenced_content_id.")
	if effect_type == EffectType.REMOVE_STATUS and referenced_content_id.is_empty():
		errors.append("Removing a status requires referenced_content_id.")
	if effect_type == EffectType.MODIFY_RESOURCE and resource_id.is_empty():
		errors.append("Resource effects require resource_id.")

	return errors
