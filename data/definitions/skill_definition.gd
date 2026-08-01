class_name SkillDefinition
extends Resource

enum ActionKind {
	STRIKE,
	BRACE,
}

@export var content_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var action_kind: ActionKind = ActionKind.STRIKE
@export_range(0, 999, 1) var stamina_cost: int = 0
@export_range(0, 999, 1) var stamina_gain: int = 0
@export_range(1, 999, 1) var base_recovery: int = 100
@export_range(0.0, 1.0, 0.01) var critical_chance: float = 0.0
@export_range(1.0, 5.0, 0.05) var critical_multiplier: float = 1.5
@export var effects: Array[EffectDefinition] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if content_id.is_empty():
		errors.append("content_id is required.")
	if display_name.is_empty():
		errors.append("display_name is required.")
	if base_recovery <= 0:
		errors.append("base_recovery must be positive.")
	if action_kind == ActionKind.STRIKE and effects.is_empty():
		errors.append("Strike skills require at least one effect.")
	elif (
		action_kind == ActionKind.STRIKE
		and effects[0] != null
		and effects[0].effect_type != EffectDefinition.EffectType.DAMAGE
	):
		errors.append("Strike skills require a damage effect first.")

	for effect: EffectDefinition in effects:
		if effect == null:
			errors.append("effects cannot contain null entries.")
		else:
			for error: String in effect.validate():
					errors.append("%s: %s" % [content_id, error])

	return errors
