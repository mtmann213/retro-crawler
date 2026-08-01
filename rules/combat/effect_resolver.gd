class_name EffectResolver
extends RefCounted


static func resolve_effects(
	actor: CombatantState,
	target: CombatantState,
	skill: SkillDefinition,
	status_definitions: Dictionary[StringName, StatusDefinition],
	rng: RandomNumberGenerator,
) -> Array[CombatEvent]:
	var events: Array[CombatEvent] = []

	for effect: EffectDefinition in skill.effects:
		if effect == null or target.is_defeated:
			break

		match effect.effect_type:
			EffectDefinition.EffectType.DAMAGE:
				_resolve_damage(actor, target, skill, effect, rng, events)
			EffectDefinition.EffectType.HEAL:
				_resolve_heal(actor, target, effect, events)
			EffectDefinition.EffectType.APPLY_STATUS:
				_resolve_apply_status(actor, target, effect, status_definitions, rng, events)
			EffectDefinition.EffectType.REMOVE_STATUS:
				StatusResolver.remove_status(target, effect.referenced_content_id, events)
			EffectDefinition.EffectType.MODIFY_RESOURCE:
				_resolve_resource(target, effect, events)

	return events


static func _resolve_damage(
	actor: CombatantState,
	target: CombatantState,
	skill: SkillDefinition,
	effect: EffectDefinition,
	rng: RandomNumberGenerator,
	events: Array[CombatEvent],
) -> void:
	var result := DamageResolver.resolve(
		effect,
		actor.power,
		StatusResolver.get_effective_defense(target),
		rng,
		target.is_defending,
		skill.critical_chance,
		skill.critical_multiplier,
		StatusResolver.get_damage_taken_multiplier(target),
	)
	var applied_damage := target.apply_damage(result.damage)
	events.append(CombatEvent.damage_dealt(
		actor.instance_id,
		target.instance_id,
		applied_damage,
		result.critical,
	))
	if target.is_defeated:
		events.append(CombatEvent.combatant_defeated(target.instance_id))


static func _resolve_heal(
	actor: CombatantState,
	target: CombatantState,
	effect: EffectDefinition,
	events: Array[CombatEvent],
) -> void:
	var amount := maxi(0, int(round(float(effect.base_amount) + float(actor.power) * effect.scaling_ratio)))
	var applied := target.heal(amount)
	events.append(CombatEvent.healing_done(actor.instance_id, target.instance_id, applied))


static func _resolve_apply_status(
	actor: CombatantState,
	target: CombatantState,
	effect: EffectDefinition,
	status_definitions: Dictionary[StringName, StatusDefinition],
	rng: RandomNumberGenerator,
	events: Array[CombatEvent],
) -> void:
	if rng.randf() >= effect.success_chance:
		return
	var definition := status_definitions.get(effect.referenced_content_id) as StatusDefinition
	if definition != null:
		StatusResolver.apply_status(target, definition, actor.instance_id, events)


static func _resolve_resource(
	target: CombatantState,
	effect: EffectDefinition,
	events: Array[CombatEvent],
) -> void:
	if effect.base_amount >= 0:
		var gained := target.gain_resource(effect.resource_id, effect.base_amount)
		if gained > 0:
			events.append(CombatEvent.resource_changed(
				CombatEvent.EventType.RESOURCE_GAINED,
				target.instance_id,
				effect.resource_id,
				gained,
			))
	else:
		var cost := absi(effect.base_amount)
		if target.spend_resource(effect.resource_id, cost):
			events.append(CombatEvent.resource_changed(
				CombatEvent.EventType.RESOURCE_SPENT,
				target.instance_id,
				effect.resource_id,
				cost,
			))
