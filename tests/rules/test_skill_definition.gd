extends GutTest


func test_strike_rejects_a_non_damage_first_effect() -> void:
	var heal_effect := EffectDefinition.new()
	heal_effect.effect_type = EffectDefinition.EffectType.HEAL
	heal_effect.base_amount = 10

	var skill := SkillDefinition.new()
	skill.content_id = &"invalid_strike"
	skill.display_name = "Invalid Strike"
	skill.action_kind = SkillDefinition.ActionKind.STRIKE
	skill.effects = [heal_effect]

	assert_has(skill.validate(), "Strike skills require a damage effect first.")


func test_damage_preview_fails_safely_for_an_invalid_effect() -> void:
	var simulation := PrototypeEncounter.create_simulation()
	var strike := simulation.get_skill(&"quick_strike")
	var damage_effect := strike.effects[0]
	var heal_effect := EffectDefinition.new()
	heal_effect.effect_type = EffectDefinition.EffectType.HEAL
	heal_effect.base_amount = 10
	strike.effects = [heal_effect, damage_effect]

	assert_eq(simulation.get_damage_preview(&"quick_strike", 1, 2), Vector2i.ZERO)
	var events := simulation.resolve_action(ActionCommand.new(1, &"quick_strike", 2))
	assert_eq(events[0].event_type, CombatEvent.EventType.ACTION_REJECTED)
	assert_eq(events[0].reason, &"invalid_skill")
